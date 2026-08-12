# App Lifecycle & Data Flush on Termination Audit: countdownApp

## Scope

Audit of 20 Swift source files in a SwiftUI macOS app using both `@AppStorage` and manual
`UserDefaults.standard.set()` for data persistence. Focus is on termination behavior under
SIGKILL / force-quit / crash scenarios where buffered writes may not reach disk.

Primary files examined: `countdownAppApp.swift`, `CountdownView.swift`, `CalculateView.swift`,
`Snippet.swift`.

---

## 1. Lifecycle Hooks — applicationWillTerminate / Scene Termination

### Finding: NO lifecycle hooks of any kind are implemented.

**`countdownAppApp.swift`:**

```swift
@main
struct countdownAppApp: App {
    @StateObject private var sunService = SunTimesService()

    init() {
        Self.registerBundledFonts()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sunService)
        }
    }
}
```

- No `NSApplicationDelegateAdaptor` with `applicationWillTerminate`.
- No `.onChange(of: scenePhase)` to detect backgrounding/termination.
- No `@Environment(\.scenePhase)` binding anywhere in the codebase.
- No custom `ExitRequestEffect` or process-signal interception.

**Verdict:** The app has zero explicit shutdown logic on any termination path (graceful,
force-quit, or crash). All persistence depends entirely on side-effect mutations during
normal interaction.

---

## 2. In-Memory State NOT Immediately Persisted — Force-Quit Risk Table

### Persistence Mechanism Legend

| Mechanism | Safety Profile | Sync Behavior |
|---|---|---|
| `@AppStorage` | Kernel-backed KV store; writes on every mutation (mostly synchronous) | Safe for typed primitives; safe for force-quit |
| `.onChange(of:) → save()` | Reactive side-effect fires when observed value changes | Safe if no async gap between change and write |
| Manual button-action `save()` | Write only when user commits via UI action | **UNSAFE** — pending edits in-flight may be lost |

### State-by-state Analysis

| Risk | Type | File | State / Variable | Persistence Method | Force-Quit Safe? | Detail |
|---|---|---|---|---|---|---|
| **HIGH** | Snippet body edit | `SnippetEditSheet.swift` | `@State snippetBody`, `title`, `project` | Manual: `commitSave()` called only on X-button dismiss | NO | No `.onChange(of: snippetBody)`. Every keystroke is in-memory only. If user edits 30 lines of markdown and force-quits, all edits vanish. The checkmark button toggles VIEW/EDIT mode — it does NOT save. Only the explicit X-dismiss button calls `commitSave()`. |
| **HIGH** | Drag reorder | `CountdownView.swift` | `@State freeOrder: [UUID]` | Manual: `saveFreeOrder()` called only in `performDrop` | PARTIAL | `dropEntered` mutates `freeOrder` on every pointer-hover during drag. The final call to `saveFreeOrder` is in `performDrop`, which fires when the user releases. If force-quit occurs mid-drag (pointer held down), the reordered positions are lost — reverts to last committed freeOrder before drag began. |
| **HIGH** | Deadline rename | `CalculateView.swift` | `@State isRenamingDeadline`, `renameDraft` | Manual: RENAME button calls `saveDeadlines()` | NO | User taps pencil icon → enters rename mode (text field). While typing a new name, all keystrokes are in `@State` only. Force-quit at this point loses the rename. Only clicking RENAME persists. |
| **MED** | Countdown items | `CountdownView.swift` | `@State items: [CountdownItem]` | Reactive: `.onChange(of: items) { save() }` | MOSTLY YES | `onChange` fires on array mutation (append, replace, remove). Binding mutations from `CountdownDetailView` propagate through → `save()`. Race window is negligible on same thread; safe. Exception: see Drag reorder above where `freeOrder` has separate persistence path. |
| **MED** | Named deadlines | `CalculateView.swift` | `@State namedDeadlines: [NamedDeadline]` | Manual: only explicit `saveDeadlines()` calls | YES for actions | Save/delete/rename buttons all explicitly call `saveDeadlines()`. No ongoing in-memory draft exists outside button handlers. Only dangerous state is rename text field (see HIGH entry). |
| **LOW** | Calculate dates | `CalculateView.swift` | `@AppStorage("calculateFromDate/ToDate/DisplayMode")` | Automatic: `@AppStorage` property wrapper | YES | Three typed primitive values stored as Double / String. Safe for force-quit. |
| **LOW** | Slot notes | `NotesSheet.swift` | `@Binding var notes: String` | Via binding → parent items mutation → `onChange` | YES | Notes bind directly to `item.notes` through `@Binding`. Every keystroke in `PlainTextEditor` calls back to update the bound item, which triggers `.onChange(of: items) → save()`. Safe. |
| **LOW** | Sun times coords | `SunTimesService.swift` | `@AppStorage("sunLatitude/Longitude")` | Automatic: `@AppStorage` property wrapper | YES | Location coordinates are typed Doubles, safe for force-quit. |
| **LOW** | Sun cache data | `SunTimesService.swift` | `UserDefaults.standard.set(rawData, forKey:)` | Manual in `saveToCache()` | YES (network-bound) | Raw JSON written synchronously after network fetch completes. No async dispatch gap. Unlikely to have in-flight writes at termination unless killed mid-download, which would just mean cache miss next launch. |
| **NONE** | Mode selection | `ContentView.swift` | `@State selectedMode: Mode` | NOT persisted | N/A | UI state only — not recovered after restart anyway. No loss. |
| **NONE** | Hover feedback | Multiple files | `copyFeedback`, `hoverTask`, etc. | No persistence | N/A | Purely ephemeral UI state (checkmark icon feedback, popover show/hide). |

### Key Insight: Asymmetric Persistence Model

The app mixes three safety classes without defense in depth:

1. `@AppStorage` primitives — fire-and-forget safe (lat/long, calculate dates)
2. `onChange`-reactive arrays — mostly safe but only for the exact property observed (`items` in `CountdownView`)
3. Manual-commit edits — `SnippetEditSheet` has no reactive safety at all; changes are purely local `@State` until explicit user dismissal

The asymmetry matters: a user editing snippet body text (HIGH risk) faces MORE data loss
than one adding a countdown item (MED/LOW risk), despite both being "important" content.

---

## 3. DispatchQueue.async Write Operations — Termination Race Conditions

### Finding: NO background-queue or async dispatch wraps any UserDefaults write.

Audit of all `DispatchQueue`, `async/await`, and `Task` usage across the codebase:

**`CountdownDetailView.swift`** — `DispatchQueue.main.asyncAfter` for `copyFeedback = false`
→ UI-only `@State`. No data write. Safe.

**`CalculateView.swift`** — `DispatchWorkItem { showSunPopover = true }` and
`DispatchQueue.main.asyncAfter` for popover toggle
→ UI-only. No data write. Safe.

**`CalculateView.swift`** — `DispatchQueue.main.async { selectedDeadline = deadline }`
in deadline popover click handler
→ UI navigation state. No data write. Safe.

**`SnippetsView.swift`** — `DispatchQueue.main.asyncAfter` for copy button feedback timer
→ UI-only feedback. Safe.

**`CountdownView.swift`** — `crossingTask = Task { ... await MainActor.run { rebuildCache(...) } }`
→ Calls `rebuildCache()` which updates cached UI state and plays expiry sounds.
Does NOT write to UserDefaults directly. Safe.

**`SunTimesService.swift`** — `func fetchYear(_ year: Int) async { ... saveToCache(...) }`
→ Network fetch is async. `saveToCache` writes synchronously on the caller context.
If killed mid-download, no partial write occurs (function hasn't reached `saveToCache` yet).
If killed after data is parsed but before `saveToCache`, in-memory year data is lost but
no corrupted file is produced — next launch reloads from network. Acceptable risk.

**Summary:** Zero `DispatchQueue.global(qos:)` or background-dispatched writes exist.
All UserDefaults mutations execute on the main synchronization context (either directly
or via `@AppStorage`/`onChange`). No async-write termination race condition found.

---

## 4. UserDefaults.standard.synchronize() — Explicit Flush Check

### Finding: `synchronize()` is NEVER called anywhere in the codebase.

The entire app relies on macOS automatic UserDefaults synchronization. Apple documents:

> "You should call `synchronize` only when you want to ensure that any pending changes
> are written to disk. For example, you might call it before your app exits."

The automatic sync interval is undocumented and implementation-dependent (historically
~1–5 seconds between flushes). Under SIGKILL:

- Writes buffered in the `NSUserDefaultsBackingStore` have not been `fsync`'d to disk.
- The property list file at `~/Library/Preferences/<bundle-id>.plist` may be stale.
- `@AppStorage` writes share the same backing store, so they face identical risk.

**Impact assessment:** In practice, macOS flushes frequently enough that recent writes
(within the last ~30 seconds) are usually on disk. But there is **NO guarantee** for
force-quit scenarios. An app termination within seconds of a large JSON encode
(the `items` array in `CountdownView` or `namedDeadlines` in `CalculateView` could be
several KB when encoded) may leave the previous version persisted instead of current state.

### Recommendations

| Priority | Action | Rationale |
|---|---|---|
| **HIGH** | Add `.onChange(of: scenePhase) → detect .background/.inactive` and call `UserDefaults.standard.synchronize()` | Covers all 3 data paths (`countdownItems`, `namedDeadlines`, `snippets`) in one lifecycle hook. Minimal code change. |
| **MEDIUM** | Wrap `SnippetEditSheet` with auto-save via `.onChange(of: snippetBody)` | Eliminates the HIGH-risk unsaved-edit scenario for the most destructive case (long-form text editing). |
| **LOW** | `task(id:) { await MainActor.run { save() } }` pattern on view disappearance as belt-and-suspenders | Defense-in-depth: if `onChange` fires but `synchronize` hasn't flushed, explicit save on teardown provides a second write opportunity. |
| **LOW** | Add `NSFileWrapper` or file-based backup for large JSON payloads (>10 KB) | `UserDefaults` has undocumented size limits; large countdown arrays could hit performance issues at sync time. File-based persistence with `FileHandle.synchronize()` gives more control over `fsync` timing. |

---

## 5. Own Findings — Code Verification

*Verified by direct file read after Qwen audit.*

### OWN-LC-1: `Snippet.load()` has a side-effectful write inside load path

**File:** `Snippet.swift`, `static func load()`

```swift
let cleaned = list.map { s -> Snippet in
    var c = s
    c.project = s.project.trimmingCharacters(in: .whitespaces)
    c.title   = s.title.trimmingCharacters(in: .whitespaces)
    return c
}
if cleaned.map({ $0.project }) != list.map({ $0.project }) ||
   cleaned.map({ $0.title })   != list.map({ $0.title }) {
    save(cleaned)
}
return cleaned
```

This pattern is unique in the codebase — the only place where a `load()` call also
conditionally triggers a `save()`. The intent is to repair previously-persisted
whitespace. From a lifecycle perspective: if the app is launched and immediately
force-quit before the `onChange` system gets a chance to flush, this on-load repair
write is the write at highest risk. If the repair write is interrupted (extremely
unlikely in practice — load happens at `.onAppear`, not late in app lifetime), the
plist could have a partial write. Low severity, but architecturally unusual.

**Recommendation:** Add a comment noting the intentional load-and-repair pattern so
future readers don't misread it as a bug.

### OWN-LC-2: `CountdownView` — `freeOrder` change does NOT trigger `save()`

**File:** `CountdownView.swift`, body modifiers:

```swift
.onChange(of: items)     { save(); rebuildCache() }
.onChange(of: freeOrder) { rebuildCache() }
```

`freeOrder` mutations trigger `rebuildCache()` but NOT `saveFreeOrder()`. The only
path that calls `saveFreeOrder()` is `performDrop` (drop commit). This is intentional
design (avoid redundant writes on every hover during drag), but it means: if `freeOrder`
is mutated by any code path other than drag-drop in the future, the mutation will
silently not persist. The asymmetry between the two `onChange` handlers is a latent
maintenance footgun.

**Recommendation:** Add a comment to the `freeOrder` `onChange` block explicitly
noting that `saveFreeOrder()` is intentionally omitted here and is handled exclusively
by `performDrop`.

---

## Appendix: All UserDefaults Keys and Their Write Paths

| Key | Data Type | Written By | Trigger | Explicit Sync? |
|---|---|---|---|---|
| `countdownItems` | `[CountdownItem]` JSON | `CountdownView.save()` | `.onChange(of: items)` | No |
| `freeSlotOrder` | `[String]` UUIDs | `CountdownView.saveFreeOrder()` | Drop commit (`performDrop`) | No |
| `calculateFromDate` | Double | `@AppStorage` automatic | Any mutation of `fromInterval` | Auto (no sync guarantee) |
| `calculateToDate` | Double | `@AppStorage` automatic | Any mutation of `toInterval` | Auto (no sync guarantee) |
| `calculateDisplayMode` | String | `@AppStorage` automatic | Toggle button | Auto (no sync guarantee) |
| `namedDeadlines` | `[NamedDeadline]` JSON | `CalculateView.saveDeadlines()` | Add / rename / delete button actions | No |
| `snippets` | `[Snippet]` JSON | `Snippet.save(snippets)` | Snippet CRUD operations via save callbacks | No |
| `sunLatitude` | Double | `@AppStorage` automatic | (Manual coord entry — planned) | Auto (no sync guarantee) |
| `sunLongitude` | Double | `@AppStorage` automatic | (Manual coord entry — planned) | Auto (no sync guarantee) |
| `sunTimesCache_<year>` | Data (JSON) | `SunTimesService.saveToCache()` | After successful network fetch | No |
