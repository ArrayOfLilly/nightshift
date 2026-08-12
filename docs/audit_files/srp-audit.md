# Single Responsibility & God Views Audit — countdownApp

**Scope:** `CountdownView.swift` · `CountdownDetailView.swift` · `CalculateView.swift` ·
`NotesSheet.swift` · `SnippetEditSheet.swift` · `SharedEditorComponents.swift`

---

## File: `CalculateView.swift`

### CV-SRP-1: God View — too many responsibilities in one struct *(High)*

`CalculateView` currently owns **eight distinct concerns**:

| # | Responsibility | Key symbols |
|---|---|---|
| 1 | Date difference calculation + display | `resultParts`, `calResultParts`, `resultRow`, `modeToggle` |
| 2 | FROM / TO date stepper input | `dateStepper()`, `componentStepper()`, `adjustDate()`, `snapToMinute()` |
| 3 | Sun times hover popover | `showSunPopover`, `hoverTask`, `todaySunTimes`, `sunPopoverContent`, `fetchTodaySunTimes()` |
| 4 | Moon phase illustration | `GeometryReader` arc layout in `body` |
| 5 | Deadline persistence (save / load) | `namedDeadlines`, `loadDeadlines()`, `saveDeadlines()`, `addNamedDeadline()` |
| 6 | Deadline list popover UI | `showDeadlineListPopover`, `deadlineListPopoverContent` |
| 7 | Deadline detail sheet UI (load / rename / delete) | `selectedDeadline`, `deadlineDetailContent()` |
| 8 | Deadline rename sub-flow | `isRenamingDeadline`, `renameDraft` |

A view with eight responsibilities violates SRP at every level: logic, state, and layout
are entangled. Changes to deadline rename (Session P) required adding state vars to the
top-level view that conceptually belong only to `deadlineDetailContent`.

---

### CV-SRP-2: `deadlineDetailContent()` — four responsibilities in one function *(Medium)*

```swift
private func deadlineDetailContent(_ deadline: NamedDeadline) -> some View { … }
```

This single `@ViewBuilder` function manages:
1. **Display** — title header (static or TextField), date subtitle
2. **Rename flow** — conditional TextField + CANCEL/RENAME buttons
3. **Delete action** — `removeAll { $0.id == … }` + `saveDeadlines()`
4. **Load action** — `toInterval = deadline.date.timeIntervalSince1970`

The rename state (`isRenamingDeadline`, `renameDraft`) lives in `CalculateView` rather
than in a dedicated subview, because SwiftUI `@ViewBuilder` functions cannot own `@State`.
This is the structural pressure that forced state pollution at the parent level.

**Recommended fix:** Extract `deadlineDetailContent` into a dedicated
`struct DeadlineDetailSheet: View` with its own `@State private var isRenaming` and
`@State private var renameDraft`. The parent `CalculateView` passes a
`Binding<NamedDeadline?>` and a closure for delete. This keeps rename state local and
removes CV-SRP-1 items 7 + 8 from the parent.

---

### CV-SRP-3: `deadlineRemainingString(for:)` — formatting logic in the view *(Low)*

**Added by BUG-1 fix (remaining time display).**

```swift
private func deadlineRemainingString(for date: Date) -> String { … }
```

Pure data-formatting function (takes a `Date`, returns a `String`) with no
view-specific dependencies. Belongs in `NamedDeadline` as a computed property or
instance method, or in a shared `DateFormatting` helper.

**Recommended fix:**
```swift
// NamedDeadline.swift
extension NamedDeadline {
    func remainingString(relativeTo now: Date = Date()) -> String { … }
}
```

---

### CV-SRP-4: `deadlineDateString(_:)` — second formatter in the view *(Low)*

```swift
private func deadlineDateString(_ date: Date) -> String { … }
```

Same issue as CV-SRP-3: pure formatting, no view dependency. Duplicates the concept of
`CountdownItem.deadlineFormatted` (different format string — see duplication audit §6H).
Should move to `NamedDeadline` or a shared formatter.

---

### CV-SRP-5: Inline persistence — `loadDeadlines()` / `saveDeadlines()` in view *(Medium)*

```swift
private func loadDeadlines() {
    guard let data = UserDefaults.standard.data(forKey: "namedDeadlines"),
          let decoded = try? JSONDecoder().decode([NamedDeadline].self, from: data)
    else { return }
    namedDeadlines = decoded
}
```

UserDefaults access, JSON decode, and the storage key literal `"namedDeadlines"` are all
embedded in the view. Same anti-pattern as `CountdownView` (`load()` / `save()`) and
`Snippet.swift` (`load()` / `save()`). Migrating to `NamedDeadline` static methods
(matching the `Snippet` design) would give `CalculateView` a clean
`namedDeadlines = NamedDeadline.load()` call site.

---

### CV-SRP-6: `calcSaveGradient` — shared UI constant embedded in view *(Low)*

```swift
private var calcSaveGradient: LinearGradient { … }
```

Used by three sheet/popover surfaces. Logically a design token — belongs in `AppTheme`
alongside `calculateBackground`, `dark`, `background`. Currently private to
`CalculateView`, preventing reuse by other views.

---

## File: `CountdownView.swift`

### CV2-SRP-1: Direct persistence (UserDefaults) inside the View *(Medium)*

| Lines | Category | Methods |
|---|---|---|
| 267–290 | #1 UserDefaults read/write | `save()`, `load()`, `saveFreeOrder()`, `loadFreeOrder()` |

Four methods performing complete encode→write and read→decode round-trips to
`UserDefaults.standard`. Coupled to view lifecycle via:

```swift
.onAppear { load(); loadFreeOrder(); rebuildCache() }
.onChange(of: items)     { save(); rebuildCache() }
.onChange(of: freeOrder) { rebuildCache() }
```

The delete closure (lines 82–88) also calls `save()` + `saveFreeOrder()` directly
inside a UI modifier. A `CountdownPersister` service or ViewModel should own
the source-of-truth array; the view receives bindings only.

---

### CV2-SRP-2: Date filtering / sorting / deadline-crossing logic in View methods *(Medium)*

| Lines | Category | Methods |
|---|---|---|
| 102–128 | #2 domain business logic | `activeItems(at:)`, `orderedFreeItems(at:)` |
| 154–184 | #2 + #6 mixed duties (30 lines) | `rebuildCache(now:playExpirySounds:)` |

`activeItems(at:)` / `orderedFreeItems(at:)` filter `[CountdownItem]` by expiration
status and apply custom sorting — data-layer curation that belongs in a collection
manager or ViewModel.

`rebuildCache(now:playExpirySounds:)` conflates **four** distinct responsibilities:

| Responsibility | Lines within method |
|---|---|
| Snapshot active IDs for change detection | 155, 165 |
| Sound playback on expiry crossing | 157–163 → `NSSound(named: "Funk")?.play()` |
| Cache population (`cachedEntries`, `cachedFreeItems`, `nextDeadline`) | 167–172 |
| Arm cancellation-safe sleep Task for deadline crossing | 173–183 |

No View method should be responsible for audio playback scheduling.
A `DeadlineCrossingMonitor` or `CountdownSoundService` could subscribe to
item-state changes instead.

---

### CV2-SRP-3: `@State` used for persistent application data *(Medium)*

| Lines | Property | Persistence target |
|---|---|---|
| 48 | `items: [CountdownItem]` | JSON → UserDefaults `"countdownItems"` |
| 50 | `freeOrder: [UUID]` | string UUID array → UserDefaults `"freeSlotOrder"` |
| 54–57 | `cachedEntries`, `cachedFreeItems`, `nextDeadline`, `crossingTask` | derived persisted state + async timer |
| 61 | `previousActiveIDs: Set<UUID>` | sound playback tracking across sessions |

`@State` is SwiftUI's transient UI state — it resets when the view is deallocated.
Full item lists, drag-order arrays, and cached snapshots belong in an `@Observable`
model or ViewModel that persists independently of view lifecycle.

---

### CV2-SRP-4: God View — 7 orthogonal concerns *(High)*

| Responsibility | Where it appears |
|---|---|
| UI layout (`NavigationStack`, `TimelineView`, `ScrollView`, `ForEach`) | lines 66–263 |
| Persistence (4 UserDefaults methods) | lines 267–290 |
| Sound playback on expiry crossing | lines 157–163 (`NSSound`) |
| Deadline-crossing Task scheduling | lines 173–183 |
| Drag-and-drop reorder state management | lines 219–232, `FreeSlotDropDelegate` at 294–321 |
| Date-filtering / sorting helpers | lines 102–128 |
| Binding-factory for safe item access | lines 132–141 |

Current line count: **324**. The minimal SRP-compliant version would own only `body`,
a single binding to an upstream ViewModel, delegating persistence, sound, Task
scheduling, and drag-order tracking out of the struct.

---

## File: `CountdownDetailView.swift`

### CDV-SRP-1: Pasteboard operations + feedback timer in button action closure *(Low)*

| Lines | Category | Detail |
|---|---|---|
| 192–199 | #6 — multiple unrelated actions in one closure | pasteboard write + feedback scheduling |

```swift
Button {
    let trimmed = item.label.trimmingCharacters(in: .whitespaces)
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(trimmed, forType: .string)
    copyFeedback = true
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
        copyFeedback = false
    }
} label: { … }
```

Three separate operations in one closure: text trimming (string utility), system
pasteboard mutation, and visual-feedback timing. Same pattern duplicated identically
in `NotesSheet` (lines 76–79) and `SnippetEditSheet` (lines 185–188) — see
duplication audit §6F/7A.

---

### CDV-SRP-2: Date-arithmetic helpers embedded in the View *(Medium)*

| Lines | Category | Method |
|---|---|---|
| 448–450 | #2 | `component(_:)` — Calendar component extraction |
| 452–463 | #2 + mutation | `adjust(_:by:)` — calendar arithmetic **and** model write |
| 465–470 | #2 | `monthAbbrev()` — `DateFormatter` instantiation for UI display |

```swift
private func adjust(_ c: Calendar.Component, by value: Int) {
    var base = localDeadline
    if item.isExpired(at: Date()) {
        base = Date()
        localDeadline = base
        item.deadline = base       // ← writes through @Binding to model
    }
    if let newDate = cal.date(byAdding: c, value: value, to: base) {
        localDeadline = newDate
        item.deadline = newDate    // ← also writes through @Binding
    }
}
```

Calendar date-component arithmetic and an expired-item business rule (reset deadline
to `now` upon editing) both live inside a View method. The `monthAbbrev()` helper
re-creates a `DateFormatter` on every call — wasteful and outside view concerns.
Should live in a `DateAdjuster` or ViewModel, or be a static cached formatter.

---

### CDV-SRP-3: Business logic inside `.onAppear` *(Low)*

| Lines | Category | Detail |
|---|---|---|
| 332–340 | #2 | expired-item deadline reset on navigation entry |

```swift
.onAppear {
    if item.isExpired(at: Date()) {
        let now = Date()
        item.deadline = now
        localDeadline = now
    } else {
        localDeadline = item.deadline
    }
}
```

Checking expiry status and resetting the deadline is domain business logic, not
presentational initialization. Should be triggered by a
`CountdownViewModel.prepareForEditing(_:)` method that normalizes item state
before the view appears.

---

## File: `NotesSheet.swift`

### NS-SRP-1: Pasteboard operations + async feedback timer in button closure *(Low)*

| Lines | Category | Detail |
|---|---|---|
| 76–79 | #6 — multiple unrelated actions | `NSPasteboard` write + `DispatchQueue.main.asyncAfter` |

Same anti-pattern as `CountdownDetailView` CDV-SRP-1 (lines 192–199) and
`SnippetEditSheet` SES-SRP-1 (lines 185–188). Identical copy-feedback block
duplicated 3×; see duplication audit §6F for the shared `CopyButton` helper proposal.

---

### NS-SRP-2: Window geometry inspection for sheet sizing *(Low)*

| Lines | Category | Method |
|---|---|---|
| 151–156 | AppKit host introspection in View | `updateSheetWidth()` |

```swift
private func updateSheetWidth() {
    let windowWidth = NSApp.mainWindow?.frame.width
        ?? NSApp.windows.first { $0.title == "countdownApp" }?.frame.width
        ?? 600
    sheetWidth = max(450, min(900, windowWidth - windowMargin))
}
```

Reading `NSApp.mainWindow` is a host-app concern, not a SwiftUI rendering concern.
Sheet width should be driven by SwiftUI's layout environment (e.g., `GeometryReader`
at the parent level passing `maxWidth` down as a parameter). Identical pattern
duplicated in `SnippetEditSheet` — see duplication audit for the shared fix.

---

## File: `SnippetEditSheet.swift`

### SES-SRP-1: Pasteboard + feedback — same dual anti-pattern as NotesSheet *(Low)*

| Lines | Category | Detail |
|---|---|---|
| 185–188 | #6 Pasteboard + feedback in action closure | Identical `NSPasteboard` / `asyncAfter` block |
| 273–278 | #5 Window geometry inspection | Duplicate of `NotesSheet`:151–156 — same `NSApp.mainWindow` lookup |

See NS-SRP-1 and NS-SRP-2 above; both issues are triplicated across the codebase.

---

### SES-SRP-2: Model-mutation `commitSave()` inside the View *(Medium)*

| Lines | Category | Method |
|---|---|---|
| 282–290 | #3 business logic in view helper | `commitSave()` — model construction + trimming + default fallback + timestamp |

```swift
private func commitSave() {
    guard !title.isEmpty || !snippetBody.isEmpty else { return }
    var s = snippet ?? Snippet(title: "", body: "", project: "")
    s.title     = title.trimmingCharacters(in: .whitespaces)
    s.body      = snippetBody
    s.project   = project.trimmingCharacters(in: .whitespaces).isEmpty
                  ? "General" : project.trimmingCharacters(in: .whitespaces)
    s.updatedAt = Date()
    onSave(s)
}
```

Business rules — validation (`!title.isEmpty`), default-value logic (`"General"`
fallback), and timestamp mutation (`updatedAt = Date()`) — execute inside the View.
A ViewModel's `commit()` method should perform these steps; the view delegates to it.

---

## File: `SharedEditorComponents.swift`

### SEC-SRP-1: Inline HTML / full-document string construction in NSViewRepresentable *(Medium)*

| Lines | Category | Detail |
|---|---|---|
| 53–82 | #3 Raw HTML/JS document assembly | `reload(_:into:)` — reads JS from bundle, builds complete HTML doc as interpolated string, performs multiple escape passes |
| 118–122 | #3 Markdown→HTML transform via regex | `applyHighlight(_:)` — `==text==` → `<mark>$1</mark>` |
| 124–126 | #3 Fallback HTML wrapper | `fallbackHTML(_:fontFaceCSS:)` — constructs raw HTML string |
| 131–159 | #3 Inline CSS (~30 lines) as file-level constant | `let markdownCSS = …` — full CSS stylesheet as a Swift string literal |

A Representable assembling doctype, meta tags, script injection, style embedding, and
text escaping is far beyond UI rendering. Recommended: a dedicated
`MarkdownRendererService` that (1) loads the JS library once at startup, (2) constructs
HTML from templates or a bundled HTML file, (3) accepts markdown and returns fully-formed
HTML. The Representable then simply calls `renderer.html(from: markdown)`.

---

### SEC-SRP-2: Bundle resource lookups for font files inside the View component *(Low)*

| Lines | Category | Method |
|---|---|---|
| 53–56 | #4 JS library file lookup | `Bundle.main.url(forResource: "marked.min", withExtension: "js")` |
| 86–99 | #4 Font-file check + @font-face CSS generation | `mozillaHeadlineFontFaceCSS()` — bundle inspection + CSS string construction |
| 103–116 | #4 Same pattern for second font | `robotoFlexFontFaceCSS()` |

Three separate bundle resource lookups per render cycle. Font and JS-library
availability should be resolved once (e.g., at app startup via a
`ResourceProvider`) and passed in as pre-loaded data. The Representable's job
is presenting, not filesystem discovery.

---

## Summary

| ID | File | Symbol / Area | Violation | Severity |
|---|---|---|---|---|
| CV-SRP-1 | `CalculateView.swift` | `struct CalculateView` | 8 responsibilities | **High** |
| CV-SRP-2 | `CalculateView.swift` | `deadlineDetailContent()` | 4 responsibilities | **Medium** |
| CV-SRP-3 | `CalculateView.swift` | `deadlineRemainingString(for:)` | formatting in view | Low |
| CV-SRP-4 | `CalculateView.swift` | `deadlineDateString(_:)` | formatting in view | Low |
| CV-SRP-5 | `CalculateView.swift` | `loadDeadlines()` / `saveDeadlines()` | persistence in view | **Medium** |
| CV-SRP-6 | `CalculateView.swift` | `calcSaveGradient` | design token in view | Low |
| CV2-SRP-1 | `CountdownView.swift` | `save()` / `load()` / `saveFreeOrder()` / `loadFreeOrder()` | persistence in view | **Medium** |
| CV2-SRP-2 | `CountdownView.swift` | `rebuildCache(now:playExpirySounds:)` | 4 responsibilities (30 lines) | **Medium** |
| CV2-SRP-3 | `CountdownView.swift` | 6 `@State` props | persistent data in transient state | **Medium** |
| CV2-SRP-4 | `CountdownView.swift` | `struct CountdownView` | 7 responsibilities (324 lines) | **High** |
| CDV-SRP-1 | `CountdownDetailView.swift` | copy button closure | pasteboard + feedback in action | Low |
| CDV-SRP-2 | `CountdownDetailView.swift` | `adjust(_:by:)` / `monthAbbrev()` | date logic + mutation in view | **Medium** |
| CDV-SRP-3 | `CountdownDetailView.swift` | `.onAppear` block | business logic in lifecycle hook | Low |
| NS-SRP-1 | `NotesSheet.swift` | copy button closure | pasteboard + feedback in action | Low |
| NS-SRP-2 | `NotesSheet.swift` | `updateSheetWidth()` | AppKit host introspection in view | Low |
| SES-SRP-1 | `SnippetEditSheet.swift` | copy closure + `updateSheetWidth()` | same dual anti-pattern | Low |
| SES-SRP-2 | `SnippetEditSheet.swift` | `commitSave()` | model mutation + business rules in view | **Medium** |
| SEC-SRP-1 | `SharedEditorComponents.swift` | `reload()` / `markdownCSS` / `applyHighlight()` | HTML/CSS construction in Representable | **Medium** |
| SEC-SRP-2 | `SharedEditorComponents.swift` | `mozillaHeadlineFontFaceCSS()` / `robotoFlexFontFaceCSS()` | bundle lookups per render cycle | Low |

> **Note (pre-seeded):** `SnippetsView.swift` is listed in the audit scope but not
> covered by this Qwen run. No SRP findings identified independently; the main risk
> is the `commitSave`-equivalent logic that lives in `SnippetEditSheet` rather than
> in `SnippetsView` — already captured as SES-SRP-2.

---

## Post-fix findings — Session P (BUG-WIDTH-CALC / BUG-WIDTH-COLOR / BUG-WIDTH-ADD / BUG-DELETE-CONFIRM / BUG-COLOR-NODISMISS)

### BUG-WIDTH-CALC: `CalculateView` — `updateSheetWidth()` + `sheetWidth` state

**Codable impact:** none.
**New SRP findings:**

Három új violation — mind a meglévő NS-SRP-2 / SES-SRP-1 mintájára:

| ID | File | Symbol | Violation | Severity |
|---|---|---|---|---|
| CV-SRP-7 | `CalculateView.swift` | `updateSheetWidth()` | AppKit host introspection (`NSApp.mainWindow`) in View, ugyanaz mint NS-SRP-2 | Low |
| CV-SRP-8 | `CalculateView.swift` | `@State private var sheetWidth` | presentational sizing state a View-ban — should be environment/preference | Low |

`CalculateView.updateSheetWidth()` szó szerint megismétli a `NotesSheet.updateSheetWidth()` és
`SnippetEditSheet.updateSheetWidth()` (NS-SRP-2, SES-SRP-1) kódját, különböző clamp értékekkel.
Mindhárom instance ugyanazt az AppKit introspection anti-mintát hordozza.

---

### BUG-WIDTH-COLOR: `ColorPickerSheet` — inline `.onAppear` width calculation

| ID | File | Symbol | Violation | Severity |
|---|---|---|---|---|
| CPS-SRP-1 | `ColorPickerSheet.swift` | `.onAppear` inline closure | AppKit host introspection a View lifecycle hookban | Low |

Az inline forma (nem named method) ugyanolyan SRP violation mint a többi sheeten — a View
a saját prezentációs szélességét számítja ki AppKit window-olvasással. A `ColorPickerSheet`
ezentúl öt szélességszámítás-instance egyike (NS, SES, CV, CPS, ACS).

---

### BUG-WIDTH-ADD: `AddCountdownSheet` — inline `.onAppear` width calculation

| ID | File | Symbol | Violation | Severity |
|---|---|---|---|---|
| ACS-SRP-1 | `AddCountdownSheet.swift` | `.onAppear` inline closure | AppKit host introspection a View lifecycle hookban | Low |

Azonos az CPS-SRP-1-gyel. Az `AddCountdownSheet` eddig nem szerepelt az SRP audit scope-jában
(a Qwen audit a 6 eredeti fájlra korlátozódott). Ez az első finding benne.

---

### BUG-DELETE-CONFIRM: `CountdownDetailView` — `.alert` + `showDeleteConfirm`

**SRP értékelés:** a `showDeleteConfirm: Bool` state és a `.alert` modifier a View-ban marad —
ez elfogadható SwiftUI idiómáját követi. A törlési döntés (és annak megerősítése) presentációs
logika; az `onDelete()` closure-t meghívó tényleges törlési művelet a szülő View-ban van
(CountdownView), a CDV csak jelzi a szándékot. Nincs új SRP finding.

---

### BUG-COLOR-NODISMISS: `ColorPickerSheet` — X gomb hozzáadása

**SRP értékelés:** a `dismiss()` hívás az `@Environment(\.dismiss)` privát propertyből — ez
a SwiftUI lifecycle management standard módja. Nincs új SRP finding.

---

### Frissített summary (új sorok)

| ID | File | Symbol / Area | Violation | Severity |
|---|---|---|---|---|
| CV-SRP-7 | `CalculateView.swift` | `updateSheetWidth()` | AppKit host introspection in view | Low |
| CV-SRP-8 | `CalculateView.swift` | `@State sheetWidth` | presentational sizing state in view | Low |
| CPS-SRP-1 | `ColorPickerSheet.swift` | `.onAppear` width calc | AppKit host introspection in view | Low |
| ACS-SRP-1 | `AddCountdownSheet.swift` | `.onAppear` width calc | AppKit host introspection in view | Low |


---

### BUG-DEADLINE-1: `CalculateView` — `showDeleteDeadlineConfirm` + `.alert` (Session Q)

**SRP értékelés:** Azonos minta mint BUG-DELETE-CONFIRM (CountdownDetailView) — a `showDeleteDeadlineConfirm: Bool` state és a `.alert` presentációs logika, a tényleges törlés (`namedDeadlines.removeAll`) az alert confirm closure-ban van, ami elfogadható mivel a persistence (`saveDeadlines()`) és a sheet dismiss (`selectedDeadline = nil`) is helyi felelősség. Nincs új SRP finding.

### BUG-DEADLINE-2: `CalculateView` — rename TextField padding (Session Q)

**SRP értékelés:** Layout literal módosítás (`padding(.top, 28)` → `46`). Nem vezet be új felelősséget. Nincs új SRP finding.
