# Performance, Main-Thread & Concurrency Audit — countdownApp

> **Scope (Qwen pass):** `SharedEditorComponents.swift`, `CountdownView.swift`, `NotesSheet.swift`,
> `SnippetEditSheet.swift`, `CalculateView.swift`, `SunTimesService.swift`.
> **Extended (own pass):** `CountdownDetailView.swift`, `CountdownRowView.swift`,
> `AddCountdownSheet.swift`, `ColorPickerSheet.swift`, `SunPanel.swift`, `countdownAppApp.swift`.

---

## 1 — `MarkdownWebView.updateNSView`: Unconditional WKWebView Reload on Every Render Cycle

**File:** `SharedEditorComponents.swift`, lines 36–38
**Severity:** **HIGH** — jank, unnecessary IPC, scroll-position thrash.

```swift
func updateNSView(_ wv: WKWebView, context: Context) {
    reload(markdown, into: wv)          // ← fires EVERY SwiftUI render cycle
}
```

There is no guard clause comparing the current `markdown` value against a cached previous value.
On every render pass of the parent view (`NotesSheet` or `SnippetEditSheet`) — regardless of
whether the markdown text actually changed — this call executes:

- `Bundle.main.url(forResource:)` — disk lookup for `marked.min.js` on every update cycle
- `String(contentsOf: markedURL)` — reads the entire JS library from disk into memory (lines 57–58)
- `applyHighlight(raw)` — runs `NSRegularExpression` replace over the full body text (line 68)
- Four additional string replacements on escaped content (lines 69–72)
- A full `wv.loadHTMLString(_:baseURL:)` call — destroys and recreates the WKWebView DOM, loses
  scroll position, triggers JS engine re-init (line 81)

This fires not only when markdown text changes, but whenever **any** other `@State` in `NotesSheet`
or `SnippetEditSheet` changes: `copyFeedback`, `isEditing`, `showDeleteConfirm`, `sheetWidth`. A
single copy-button click fires the entire reload pipeline for no reason.

In `NotesSheet` specifically (lines 78–79), setting `copyFeedback = true` and then scheduling
`asyncAfter { copyFeedback = false }` causes two extra full WKWebView reloads in VIEW mode that
are completely gratuitous.

**Recommended fix:** add `guard markdown != _lastMarkdown else { return }` (cached via `Coordinator`
or a `context.coordinator` stored property) before calling `reload`.

---

## 2 — UserDefaults Write Patterns: No Debouncing on Keystroke Edits

**Files:** `CountdownView.swift` lines 96–97, 268–269; `NotesSheet.swift` lines 113–114
**Severity:** **HIGH** — synchronous JSON serialize + disk I/O on every mutation.

```swift
// CountdownView.swift
.onChange(of: items)     { save(); rebuildCache() }    // line 96
.onChange(of: freeOrder) { rebuildCache() }             // line 97

private func save() {                                    // line 268
    guard let data = try? JSONEncoder().encode(items) else { return }
    UserDefaults.standard.set(data, forKey: storageKey)  // line 269
}
```

```swift
// NotesSheet.swift — editor binding chain
PlainTextEditor(
    text: $notes,   // ← direct @Binding to item.notes, no draft buffer
    …
)
```

The `@Binding var notes: String` parameter comes from the parent `CountdownDetailView` and
resolves directly into an element of `items: [CountdownItem]`. Every keystroke executes this
full chain:

1. `NSTextViewDelegate.textDidChange` → writes `parent.text = tv.string`
   (`SharedEditorComponents.swift`, lines 240–245)
2. This mutates `item.notes` inside the `items` array in `CountdownView`
3. `.onChange(of: items)` fires synchronously → calls `save()`
4. `JSONEncoder().encode(items)` serialises the **entire** `items` array (all countdowns, not
   just this one) to `Data`
5. `UserDefaults.standard.set(data, forKey:)` writes to disk on the main thread

Zero debouncing, no `NSKeyValueObservation` batching, no `Timer`-based coalescing. Typing
"hello world" triggers roughly 11 full JSON-encode + UserDefaults-write cycles over ~800ms.

`SnippetEditSheet.swift` avoids this problem: lines 104–106 use local `@State` draft fields
(`$title`, `$snippetBody`, `$project`), and persistence only happens at close time via
`commitSave()` (line 259). `NotesSheet` does not follow the same pattern.

**Recommended fix:** introduce a ~500ms debounce (`Task.sleep`-based coalescing, cancelling the
previous pending save Task on each keystroke) between `notes` mutation and the `save()` call.

---

## 3 — DispatchQueue Timing Hacks: Race-Condition-Prone Hover Popover

**File:** `CalculateView.swift`, lines 131–140
**Severity:** MEDIUM — classic enter/leave debounce race.

```swift
.onHover { inside in
    hoverTask?.cancel()                                               // line 132
    if inside {
        let task = DispatchWorkItem { showSunPopover = true }         // lines 133–134
        hoverTask = task                                              // line 135
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: task) // line 136
    } else {
        showSunPopover = false                                        // line 138
    }
}
```

This is the textbook problematic pattern for hover delays.

### Scenario A — flicker (enter → leave → re-enter → leave): safe

| Time | Event | `hoverTask` state | `showSunPopover` |
|---|---|---|---|
| T=0 | cursor enters moon arc | `nil` → new `WorkItem` scheduled at +200ms | unchanged |
| T=5ms | cursor leaves | `cancel()` → work item cancelled | `false` |
| T=0.6s | cursor re-enters | new `WorkItem` @ T+280ms | unchanged |
| T=+10ms | cursor leaves again | `cancel()` fires on the pending task | `false` |

This scenario is safe because `cancel()` is always called before each new schedule.

### Scenario B — stale open after rapid enter→leave→leave: **not fully safe**

`.onHover` closures execute as part of SwiftUI's view-update traversal. The `hoverTask?.cancel()`
call cancels the *previously scheduled* `DispatchWorkItem`. However, `DispatchWorkItem.cancel()`
on macOS does **not** prevent an already-executing closure from completing — if the 200ms
deadline has already elapsed in a previous run-loop tick before `cancel()` runs, the closure
fires anyway. Rapid flicker can therefore still produce a popover-open event that should have
been suppressed.

Also relevant: `CalculateView.swift` line 383 —

```swift
DispatchQueue.main.async { selectedDeadline = deadline }
```

Used to defer state mutation by one run-loop tick after dismissing the deadline-list popover
(`showDeadlineListPopover = false` on the preceding line), so the popover-dismiss animation
finishes before the sheet presentation begins. Works today but is fragile — a change to
`.popover` teardown timing in a future macOS release could regress this.

**Recommended fix:** replace `DispatchWorkItem` with a cancellable `Task` (see §7 below) for
cooperative cancellation.

---

## 4 — Cache Rebuilds vs. Rendering: `crossingTask` Main-Thread Stall Risk

**File:** `CountdownView.swift`, lines 154–183
**Severity:** MEDIUM — all computation runs synchronously on the main actor.

```swift
private func rebuildCache(now: Date = Date(), playExpirySounds: Bool = false) {
    let newActiveIDs = Set(items.filter { !$0.isExpired(at: now) }.map { $0.id })   // line 155

    if playExpirySounds { … }                                                       // 157–163
    previousActiveIDs = newActiveIDs                                                // line 164

    cachedEntries   = rowEntries(at: now)                                           // line 167
    cachedFreeItems = orderedFreeItems(at: now)                                      // line 168
    nextDeadline    = items.filter { … }.map { $0.deadline }.min()                   // 169–172

    crossingTask?.cancel()                                                          // line 173
    if let nd = nextDeadline {
        crossingTask = Task {
            let delay = nd.timeIntervalSinceNow                                     // 175–176
            if delay > 0 {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))    // line 178
            }
            guard !Task.isCancelled else { return }                                 // line 180
            await MainActor.run { rebuildCache(now: Date(), playExpirySounds: true) } // line 181
        }
    }
}
```

### Stall characteristics

When called from `.onChange(of: items)` (line 96), `rebuildCache` performs four sequential
array scans over the entire `items` collection on the main thread:

1. Line 155 — `items.filter { !isExpired }.map { $0.id }` → O(n)
2. Lines 167–168 — `rowEntries(at:)` calls `activeItems` (O(n) filter + sort) and
   `orderedFreeItems` (**O(n²)** — nested `first(where:)` call per `freeOrder.id`, lines 108–121)
3. Lines 169–172 — another O(n) filter + map + min

For N ≈ 50 items this is sub-millisecond and invisible. For N ≈ 500, `orderedFreeItems`'s nested
loop can stall at ~3–8ms — enough for a frame drop on the 60Hz `TimelineView` tick.

### `crossingTask` correctness: ✅ CLEAN — no race conditions found

- Always cancelled before reassignment (line 173)
- Uses structured `Task { }` (not `Task.detached`), inheriting the main-actor context
- Checks `Task.isCancelled` after sleep completes (line 180)
- Re-enters via `await MainActor.run { }` — guarantees main-thread `@State` access
- Edge case (deadline already in the past, `delay ≤ 0`): sleep is skipped, `MainActor.run`
  fires synchronously — correct.

**Recommended fix:** replace the nested `first(where:)` loop in `orderedFreeItems` with a
`Dictionary<UUID, CountdownItem>` lookup, reducing O(n²) → O(n).

---

## 5 — Background-Thread → SwiftUI State Access Patterns

### `SunTimesService.swift` — ✅ CLEAN

Marked `@MainActor` (line 10). All async methods (`sunTimes`, `loadYear`, `fetchYear`) preserve
main-actor isolation. No background-thread state mutation observed.

### `CalculateView.swift`, lines 376–383

```swift
Button {
    showDeadlineListPopover = false
    DispatchQueue.main.async { selectedDeadline = deadline }   // lines 382–383
} label: { … }
```

Defensive but unnecessary — popover body closures are already main-actor on macOS. The extra
dispatch hop adds latency without fixing an actual thread-safety issue (`@State` mutation was
already main-thread-only).

### `CountdownView.swift`, lines 82–88 (delete callback) — ✅ CLEAN

```swift
.navigationDestination(for: CountdownItem.self) { item in
    CountdownDetailView(item: binding(for: item)) {
        let id = item.id
        items.removeAll { $0.id == id }
        freeOrder.removeAll { $0 == id }
        save()
        saveFreeOrder()
    }
}
```

Runs inside SwiftUI's main-thread button-action context. No `@MainActor` annotation needed —
correct as written.

### `CountdownView.swift`, lines 76–79 (add-item callback) — ✅ CLEAN

```swift
.sheet(isPresented: $showAddSheet) {
    AddCountdownSheet { newItem in
        items.append(newItem)
    }
}
```

Sheet dismissal + button actions execute on the main actor. No issue.

---

## 6 — Memory / Closure Captures: Strong vs. Weak Reference Audit

### `CountdownView.swift`, `crossingTask` (lines 175–183) — ✅ CLEAN

The `Task` closure captures no strong references to `self`; it only reads `nd` (a local copy of
`nextDeadline`), sleeps, then dispatches to the main actor to call a method. `rebuildCache` does
not capture `self` in any inner closure, so there's no retain-cycle risk. Cancellation via
`crossingTask?.cancel()` depends on the `@State` property staying alive during presentation —
guaranteed by SwiftUI's view lifecycle.

### `CalculateView.swift`, line 35 — ✅ CLEAN

```swift
@State private var hoverTask: DispatchWorkItem?
```

`DispatchWorkItem` captures strongly by default, but the closure only mutates `showSunPopover`
(a `@State` property, not `self`). No retain cycle. The WorkItem persists for the 200ms timeout
only — fine for short-lived UI feedback.

### `SharedEditorComponents.swift`, `Coordinator` class (line 43, line 241) — ✅ CLEAN

```swift
final class Coordinator: NSObject, WKNavigationDelegate {
    var parent: MarkdownWebView            // ← STRONG reference
```

The `Coordinator` holds a strong reference to its parent `NSViewRepresentable` instance. The
parent is recreated when input properties change; `makeCoordinator()` creates the `Coordinator`
without any back-reference path from `parent` to `Coordinator`, so no cycle. The
`NSTextViewDelegate` `Coordinator` (line 241) follows the same clean pattern.

---

## 7 — Swift Concurrency Modernization Opportunities

### `CalculateView.swift` — `DispatchWorkItem` hover delay (lines 34–36, 131–140)

**Current:**

```swift
@State private var hoverTask: DispatchWorkItem?

.onHover { inside in
    hoverTask?.cancel()
    if inside {
        let task = DispatchWorkItem { showSunPopover = true }
        hoverTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: task)
    } else {
        showSunPopover = false
    }
}
```

**Modernized (structured concurrency):**

```swift
@State private var hoverTask: Task<Void, Never>?

.onHover { inside in
    hoverTask?.cancel()
    if inside {
        hoverTask = Task {
            do {
                try await Task.sleep(nanoseconds: 200_000_000)
                showSunPopover = true
            } catch { /* cancelled — no-op */ }
        }
    } else {
        showSunPopover = false
    }
}
```

Benefits: cancellation is cooperative rather than fire-and-forget, structured, and the compiler
can verify task lifecycle. This also closes the race window described in §3 Scenario B.

### `CalculateView.swift`, lines 382–383 — deferred state set via `DispatchQueue.main.async`

Cosmetic cleanup only — the one-run-loop-tick defer is deliberate UI timing, not a correctness
issue. Low priority.

### `NotesSheet.swift` line 79 & `SnippetEditSheet.swift` line 188 — copy-feedback `asyncAfter` timers

```swift
DispatchQueue.main.asyncAfter(deadline: .now() + 1) { copyFeedback = false }
```

Acceptable one-shot UI feedback timers with trivial closures. Modernizing to `Task.sleep` would
add complexity without meaningful safety gain for a boolean flag toggling off after exactly 1s.
Low priority.

### `CountdownView.swift` — `crossingTask` is **already modern**

Uses `Task { await Task.sleep(...) }` correctly (§4). No legacy `DispatchQueue` usage remains in
this critical path — this is the pattern to copy elsewhere in the codebase.

---

## Summary Matrix (Qwen scope)

| Issue | File | Lines | Severity | Category |
|---|---|---|---|---|
| Unconditional WKWebView reload on every render | `SharedEditorComponents.swift` | 36–38, 53–81 | **HIGH** | Performance / jank |
| UserDefaults write per-keystroke (`NotesSheet` → `CountdownView.save()`) | `CountdownView.swift` + `NotesSheet.swift` | 96, 268–269 + 113–114 | **HIGH** | Main-thread I/O stall |
| `DispatchWorkItem` hover debounce race | `CalculateView.swift` | 35, 131–140 | **MEDIUM** | Race condition |
| O(n²) `orderedFreeItems` in `rebuildCache` | `CountdownView.swift` | 108–121, 167–168 | **MEDIUM** | Main-thread stall risk |
| `DispatchQueue.main.async` defer, popover→sheet | `CalculateView.swift` | 382–383 | LOW | Concurrency cleanliness |
| `crossingTask` — correctly implemented structured concurrency | `CountdownView.swift` | 173–183 | ✅ CLEAN | Reference pattern |
| `@State` closure captures — no strong-reference cycles found | multiple files | — | ✅ CLEAN | Memory safety |
| `SunTimesService` `@MainActor` isolation | `SunTimesService.swift` | 10, 50–90 | ✅ CLEAN | Threading safety |

### Recommended action priority (Qwen scope)

1. **Guard-clause `MarkdownWebView.updateNSView`** — skip `reload()` when `markdown` hasn't changed.
2. **Debounce notes persistence** — coalesce keystroke-driven `save()` calls (~500ms).
3. **Migrate `DispatchWorkItem` hover debounce** to `Task.sleep` for cooperative cancellation.
4. **Optimise `orderedFreeItems`** — `Dictionary<UUID, CountdownItem>` lookup instead of nested
   `first(where:)`, O(n²) → O(n).

---

## 8 — Extended findings (own pass): 6 files not covered by Qwen

### 8A — `LongPressStepperButton.swift`: Timer discipline — ✅ CLEAN, cross-referenced everywhere

Not one of the six target files, but directly relevant since it's the shared stepper component
used by `CountdownDetailView`, `CalculateView`, and (partially — see 8B) `AddCountdownSheet`:

```swift
let t = Timer(timeInterval: initialDelay, repeats: false) { [self] _ in
    startRepeating()
}
RunLoop.main.add(t, forMode: .common)
timer = t
```

Uses unscheduled `Timer(...)` + manual `RunLoop.main.add(_:forMode: .common)` instead of
`Timer.scheduledTimer`, explicitly to avoid double-registration across `.default` and `.common`
run-loop modes (documented in the file header — this was the Session 23-D fix). `[self]` capture
is safe here because `LongPressStepperButton` is a `struct` (value type) — no retain-cycle risk,
capturing a copy rather than a reference. `stopTimer()` always calls `invalidate()` on both drag
end and before starting the repeat phase. No leaked timers found.

### 8B — `AddCountdownSheet.swift`: stepper regression removes long-press repeat *(cross-ref, not new)*

Already flagged in the duplication audit (Finding 6A) as a DRY issue, but it's also a
**performance-adjacent UX regression**: `AddCountdownSheet`'s `componentStepper` uses a plain
`Button(action: onInc)` instead of `LongPressStepperButton`, so adjusting the year field by, say,
50 requires 50 discrete taps instead of one press-and-hold. Not a main-thread stall, but a real
throughput regression relative to `CountdownDetailView` / `CalculateView`.

`monthAbbrev()` in the same file instantiates a new `DateFormatter()` on every call (line ~163)
— called once per render pass of the MON stepper cell. `DateFormatter` init is not free
(locale/calendar/timezone resolution), but at this call frequency (re-render only, not per
keystroke) it's a low-severity, not a stall risk. Same pattern flagged codebase-wide in the
duplication audit §7B.

### 8C — `CountdownDetailView.swift`: `TimelineView` re-render scope — mostly fine, one caveat

```swift
TimelineView(.periodic(from: .now, by: 1.0)) { ctx in
    Image("spooky_tomato")
        .resizable()
        .scaledToFit()
        .frame(maxWidth: 500, maxHeight: 500)
        .overlay { GeometryReader { … timeDisplay(at: ctx.date, maxWidth: bodyWidth) … } }
}
```

Single-item detail screen with its own 1Hz `TimelineView` (separate from `CountdownView`'s
shared timeline — appropriate here since only one item is showing). Every tick re-evaluates
`timeDisplay(at:maxWidth:)`, which calls `item.remainingFormatted(at:)` — not read in this pass,
but worth a follow-up check that `remainingFormatted` isn't itself instantiating a `DateFormatter`
per call (see `CountdownItem.swift`, out of scope for this pass).

The copy-button closure (`NSPasteboard` write + `asyncAfter` feedback reset, lines ~192–199) is
the same low-priority pattern already covered in §7 (`NotesSheet`/`SnippetEditSheet` copy
buttons) — trivial 1.2s one-shot timer, no action needed.

`monthAbbrev()` here also re-creates a `DateFormatter()` per call (same as 8B) — called from
`deadlineStepper`'s `componentStepper(label: "MON", value: monthAbbrev(), …)` on every body
evaluation, i.e. every `adjust()`-triggered re-render, not just once. Low severity, same fix
category as §2C/§7B in the duplication/magic-numbers audits.

### 8D — `CountdownRowView.swift`: ✅ CLEAN — the reference pattern for row-level rendering

```swift
//  Receives `now: Date` from the parent CountdownView's single TimelineView —
//  no per-row timer. This avoids N concurrent timers hammering the main thread.
```

This is explicitly documented in the file header and verified in the code: `now: Date = Date()`
is a plain parameter, not a `@State` or its own `TimelineView`. For N countdown rows, there is
exactly one 1Hz tick source (`CountdownView`'s shared `TimelineView`), not N independent timers.
This is the correct pattern and should be treated as the model for any future per-row live-updating
UI in the app.

The copy-feedback closure (`NSPasteboard`/`UIPasteboard` write + `asyncAfter`, lines ~48–58) is
the fourth instance of the same trivial copy-feedback timer pattern (see duplication audit
§6F/§7A) — no new performance concern, just the existing duplication.

### 8E — `ColorPickerSheet.swift`: `.onAppear` window-width read — same pattern as §7's sheet-width helpers, not a stall

```swift
.onAppear {
    let windowMargin: CGFloat = 24
    let windowWidth = NSApp.mainWindow?.frame.width
        ?? NSApp.windows.first(where: { $0.isVisible })?.frame.width
        ?? 600
    sheetWidth = max(300, min(420, windowWidth - windowMargin))
}
```

Runs once per sheet presentation (`.onAppear`, not per render), so no repeated main-thread cost.
`NSApp.windows.first(where:)` iterates all app windows once — negligible for the small window
count this app has. Not a performance issue; already flagged as an SRP concern (host introspection
in a View) in the SRP audit (`CPS-SRP-1`), not a performance one.

### 8F — `SunPanel.swift`: `timeString(_:)` — new `DateFormatter` per row, called up to 13× per popover render

```swift
private func timeString(_ date: Date) -> String {
    let fmt = DateFormatter()
    fmt.dateFormat = "HH:mm"
    fmt.locale = Locale(identifier: "en_US_POSIX")
    return fmt.string(from: date)
}
```

Called from `timeRow(label:date:)` and `windowRow(label:window:)`, both invoked repeatedly across
`morningSection`, `eveningSection`, `daySection`, `goldenBlueSection` — up to **13 separate
`DateFormatter` instantiations** on a single `SunPanel` render (3 + 3 + 1 + 4×2 window calls).
This already appears in the duplication audit (§7B) as a DRY finding; from a performance
standpoint the severity is still low (SunPanel renders once per hover-triggered popover open, not
per frame), but it's the worst single-render `DateFormatter` instantiation count in the codebase.
If `SunPanel` is ever driven by something that re-renders more frequently (e.g. a live clock),
this would need a cached/static formatter first.

### 8G — `countdownAppApp.swift`: font registration at launch — ✅ CLEAN, one-time cost, correctly scoped

```swift
init() {
    Self.registerBundledFonts()
}

private static func registerBundledFonts() {
    let fileNames = ["alienleague", "alienleaguebold", "alienleagueital", "alienleaguebolditalic"]
    for name in fileNames {
        let url = Bundle.main.url(forResource: name, withExtension: "ttf")
            ?? Bundle.main.url(forResource: name, withExtension: "ttf", subdirectory: "Font")
        …
        CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error)
    }
}
```

Runs exactly once at app `init()`, registering 4 font files at `.process` scope (not system-wide,
correctly avoids polluting Font Book). Four `Bundle.main.url(forResource:)` disk lookups plus four
`CTFontManagerRegisterFontsForURL` calls at launch — genuinely negligible, and appropriately
placed (not inside any view body or render loop). No concurrency concerns: runs synchronously
before `WindowGroup` is constructed, single-threaded, no shared mutable state. This is the
correct place and pattern for one-time app-launch setup.

---

## Updated summary — new rows from extended pass

| ID | File | Symbol / Area | Finding | Severity |
|---|---|---|---|---|
| PERF-8A | `LongPressStepperButton.swift` | `Timer` + `RunLoop.main.add` | Clean — correct double-registration avoidance | ✅ CLEAN |
| PERF-8B | `AddCountdownSheet.swift` | plain `Button` stepper (no long-press) | Throughput regression vs. other steppers (cross-ref duplication §6A) | Low |
| PERF-8B | `AddCountdownSheet.swift` | `monthAbbrev()` | Per-render `DateFormatter()` instantiation | Low |
| PERF-8C | `CountdownDetailView.swift` | `TimelineView` 1Hz tick | Scoped correctly to single-item screen | ✅ CLEAN |
| PERF-8C | `CountdownDetailView.swift` | `monthAbbrev()` | Per-render `DateFormatter()` instantiation (every `adjust()`) | Low |
| PERF-8D | `CountdownRowView.swift` | shared `now:` param, no per-row timer | Reference-quality pattern | ✅ CLEAN |
| PERF-8E | `ColorPickerSheet.swift` | `.onAppear` window-width read | One-shot per presentation, not a stall (SRP concern only) | ✅ CLEAN (perf) |
| PERF-8F | `SunPanel.swift` | `timeString(_:)` | Up to 13 `DateFormatter` instantiations per popover render | Low–Medium |
| PERF-8G | `countdownAppApp.swift` | `registerBundledFonts()` | One-time launch cost, correctly scoped | ✅ CLEAN |

**Overall assessment of the extended 6 files:** no HIGH or MEDIUM main-thread-stall issues found.
The dominant recurring pattern is the same `DateFormatter()`-per-call cost already documented
codebase-wide in the duplication/magic-numbers audits (§7B / §5) — worth a single shared,
cached-formatter fix rather than six separate ones. `LongPressStepperButton`, `CountdownRowView`,
and `countdownAppApp` are all clean reference implementations worth preserving as-is.
