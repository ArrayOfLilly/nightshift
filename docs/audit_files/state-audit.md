# Audit 7 — SwiftUI State Management & Lifecycle

> Generated: 2026-08-12 | Source: Qwen output, GFM-converted by Claude

---

## Summary

| # | Section | Severity | Primary Files |
|---|---------|----------|---------------|
| 1 | `@State` Boolean Flag Sprawl | Medium | CountdownDetailView, CalculateView, NotesSheet, SnippetEditSheet |
| 2 | Sheet Lifecycle & State Leakage | Medium–High | CountdownDetailView, NotesSheet, SnippetEditSheet, CalculateView |
| 3 | `.focusable(false)` Sprawl | Low | All button-heavy views (23 occurrences) |
| 4 | `NSViewRepresentable` `updateNSView` Completeness | Low–High | SharedEditorComponents, CountdownDetailView |
| 5 | Identity Tracking — `ForEach` Keys | Low–Medium | CountdownView, CalculateView, SnippetEditSheet |

---

## 1. `@State` Variable Sprawl — Boolean Flag Proliferation

### 1a. CountdownDetailView.swift

Lines 123–125: Four independent `@State` booleans governing unrelated UI concerns in a single view body:

```swift
@State private var copyFeedback:    Bool = false   // line 123 — clipboard feedback flash
@State private var isEditing:       Bool = false   // line 124 — label edit mode toggle
@State private var showColorPicker: Bool = false   // line 125 — child .sheet() presentation
```

Line 129: A fifth boolean duplicated from the list-row model (`item.showRemaining` is ignored; local state owns this view's display):

```swift
@State private var showRemaining: Bool = true      // line 129
```

**Anti-pattern:** `isEditing` + `copyFeedback` are two mutually independent toggle flags that never interact. A single enum would reduce combinatorial state space from 4 possible states to exactly 3 valid states and encode semantic constraints in the type system:

```swift
enum LabelInteraction { case idle, editing, copied }
```

---

### 1b. CalculateView.swift — Worst Offender

Lines 32–41: Eight `@State` properties, three of which are pure presentation booleans for distinct popover/sheet targets:

```swift
@State private var showSunPopover            = false
@State private var hoverTask: DispatchWorkItem?
@State private var todaySunTimes: SunTimes?  = nil

@State private var namedDeadlines:           [NamedDeadline] = []
@State private var showSaveSheet:            Bool            = false
@State private var saveTitleDraft:           String          = ""
@State private var showDeadlineListPopover:  Bool            = false
@State private var selectedDeadline:         NamedDeadline?  = nil
```

**Anti-pattern:** `showSaveSheet`, `showDeadlineListPopover`, and `selectedDeadline` represent three mutually exclusive UI modal states. Only one can be presented at a given moment. These should collapse into a single enum:

```swift
enum CalculationModalState {
    case none
    case saveNew(titleDraft: String)
    case deadlineList
    case detail(NamedDeadline)
}
```

This collapses 3 booleans + 1 string + 1 optional into one property, eliminating impossible state combinations. The `hoverTask: DispatchWorkItem?` is also a presentation-concern leak — it should live in the `.onHover` closure as a local variable, not at struct scope.

---

### 1c. NotesSheet.swift — Duplicated Boolean Triplet

Lines 25–27: Three independent presentation booleans:

```swift
@State private var isEditing         = false   // view/edit mode toggle
@State private var copyFeedback      = false   // clipboard confirmation flash
@State private var showDeleteConfirm = false   // .alert() presentation
```

**Anti-pattern:** `isEditing` directly gates the VIEW/EDIT content switch. Combined with `copyFeedback`, this is a 4-state boolean pair that a state enum would constrain to 3 valid states.

---

### 1d. SnippetEditSheet.swift — Duplicated Triplet Plus Data Drafts

Lines 103–109: Six `@State` declarations:

```swift
@State private var title:            String          // draft
@State private var project:          String          // draft
@State private var snippetBody:      String          // draft
@State private var isEditing:        Bool = true
@State private var copyFeedback:     Bool = false
@State private var showDeleteAlert:  Bool = false
```

Line 37 (nested `ProjectField` struct):

```swift
@State private var showSuggestions = false           // dropdown popover
```

**Anti-pattern:** The three draft strings (`title`, `project`, `snippetBody`) could be a single local `SnippetDraft` struct. Combined with the presentation booleans, `SnippetEditSheet` has 7 `@State` properties where 2 (one enum + one draft struct) would suffice.

---

### Summary Table — Boolean Flag Count per View

| File | Presentation Booleans | `@State` Total | Could Be Enum? |
|------|-----------------------|----------------|----------------|
| CountdownDetailView.swift | 4 (`copyFeedback`, `isEditing`, `showColorPicker`, `showRemaining`) | 5 | `copyFeedback` + `isEditing` → enum |
| CalculateView.swift | 3 (`showSaveSheet`, `showDeadlineListPopover`, `showSunPopover`) | 8 | `saveSheet` + `deadlineListPopover` + `selectedDeadline` → enum |
| NotesSheet.swift | 3 (`isEditing`, `copyFeedback`, `showDeleteConfirm`) | 3 | `isEditing` + `copyFeedback` → enum |
| SnippetEditSheet.swift | 5 (`isEditing`, `copyFeedback`, `showDeleteAlert`, `showSuggestions` nested) | 7 | all 4 presentation bools → enum; draft strings → struct |

---

## 2. Sheet Lifecycle & State Leakage

### SM-2a: CountdownDetailView.swift — `localDeadline` Mutation Without Reset

**Lines 133, 294–303:** `localDeadline` is a `@State` mirror of `item.deadline` used for immediate stepper feedback:

```swift
// Line 133
@State private var localDeadline: Date = Date()

// Lines 294–303 — onAppear
.onAppear {
    if item.isExpired(at: Date()) {
        let now = Date()
        item.deadline = now        // <-- mutates @Binding prop
        localDeadline = now
    } else {
        localDeadline = item.deadline
    }
}
```

**Finding:** When a free (expired) slot enters the detail view, `.onAppear` writes `Date()` into both `item.deadline` AND `localDeadline`. This is **intentional design**: a FREE slot's deadline is in the past and meaningless for further editing; resetting to "now" gives the user a sensible starting point for the stepper. The mutation propagates to persistence via `CountdownView`'s `.onChange(of: items) { save() }`.

**Note (post-audit correction):** Qwen flagged this as a data loss bug. It is not — the behavior is by design. No action required.

**Severity: None (intended behavior).**

---

### SM-2b: CountdownDetailView.swift — `copyFeedback` Timer Outlives View Teardown

**Lines 172–174:**

```swift
copyFeedback = true
DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
    copyFeedback = false    // runs 1.2s later
}
```

**Finding:** If the user triggers copy then immediately navigates back, the dispatched block fires against a potentially torn-down `@State` storage wrapper. SwiftUI's `@State` storage is tied to the view instance lifecycle; writing `copyFeedback = false` on deallocated storage can produce no-op writes in Release builds but may trigger assertion failures under memory pressure.

**Severity: Low** — SwiftUI typically guards this, but represents wasted main-thread work.

---

### SM-2c: NotesSheet.swift — Same `copyFeedback` Leakage as SM-2b

**Lines 61–62:**

```swift
copyFeedback = true
DispatchQueue.main.asyncAfter(deadline: .now() + 1) { copyFeedback = false }
```

Identical pattern to `CountdownDetailView`. No `.onDisappear` cancellation. Same stale-write risk if sheet dismisses within the 1-second window.

**Severity: Low**

---

### SM-2d: SnippetEditSheet.swift — `copyFeedback` Leakage + Missing `commitSave` on Dismiss

**Lines 166–167:** Copy timer leakage identical to SM-2b/2c:

```swift
copyFeedback = true
DispatchQueue.main.asyncAfter(deadline: .now() + 1) { copyFeedback = false }
```

**Lines 190–193 (header dismiss button):** The X-mark button calls `commitSave(); dismiss()`. However, if system-initiated dismissal occurs (keyboard shortcuts, force-quit), `commitSave()` is bypassed entirely. There is no `.onDisappear` hook to flush draft state (`title`, `project`, `snippetBody`) into persistence.

**Severity: Medium — data loss path exists if dismissal is external to the explicit button action.**

---

### SM-2e: CalculateView.swift — `hoverTask` Never Cancelled on Disappear

**Lines 33, 126–130:**

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

**Finding:** When `CalculateView` disappears (tab switch), a pending `DispatchWorkItem` in `hoverTask` will execute on the main queue against torn-down view state, setting `showSunPopover = true` for a non-visible view. SwiftUI suppresses this, but it is unnecessary dispatch budget.

**Severity: Low — no crash expected, but leaked dispatch work.**

---

### SM-2f: CalculateView.swift — `namedDeadlines` Loaded Once on Appear, Never Refreshed

**Line 146, Lines 564–570:**

```swift
.onAppear { loadDeadlines() }

private func loadDeadlines() {
    guard let data    = UserDefaults.standard.data(forKey: "namedDeadlines"),
          let decoded = try? JSONDecoder().decode([NamedDeadline].self, from: data)
    else { return }
    namedDeadlines = decoded
}
```

**Finding:** `loadDeadlines()` is called only in `.onAppear`. If `CalculateView` sits idle (not deallocated, just hidden in a tab), then external mutations to UserDefaults `"namedDeadlines"` produce a stale in-memory copy. Re-showing the tab via navigation doesn't re-trigger `.onAppear` because the view instance is still alive. The user sees an outdated deadline list with no indication of staleness.

**Severity: Medium — stale read is silent, no invalidation mechanism.**

---

## 3. `.focusable(false)` Sprawl — Repeated Per-Button Application

### Distribution Across Audited Files

| File | Occurrences | Lines |
|------|-------------|-------|
| CountdownView.swift | 3 | 157, 177, 200 |
| CountdownDetailView.swift | 5 | 185, 241, 254, 279, 288 |
| CalculateView.swift | 9 | 169, 283, 309, 332, 395, 451, 465, 528, 543 |
| NotesSheet.swift | 2 | 88, 119 |
| SnippetEditSheet.swift | 4 | 55, 81, 204, 234 |
| SharedEditorComponents.swift | 0 | — |
| **Total** | **23** | |

### SM-3a: CalculateView.swift — Densest Cluster

Nine occurrences across the file. Nearly every custom `Button` receives `.focusable(false)` immediately after `.buttonStyle(.plain)`. This compound pattern indicates a missing `ButtonStyle` abstraction:

```swift
struct NonFocusablePlainButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .buttonStyle(.plain)
            .focusable(false)
    }
}
```

This would reduce 23 lines of decorator boilerplate to single-modifier calls. If a fourth button-related modifier is added later (e.g., `.keyboardShortcut`), it can be centralized instead of patched into 23 locations.

### SM-3b: `headerButton` Helper — Partially Abstracted But Incomplete

**NotesSheet.swift lines 75–89 and SnippetEditSheet.swift lines 197–210:** Both files define an identical `headerButton(icon:tint:action:)` helper that internally applies `.buttonStyle(.plain)` and `.focusable(false)`. This abstraction is correct for header buttons but was NOT applied consistently to non-header buttons in either file, and `CalculateView.swift` has no equivalent helper despite applying the same compound modifier 9 times inline.

---

## 4. `NSViewRepresentable` `updateNSView` Completeness

### SM-4a: MarkdownWebView — No Guard Against Redundant Reloads

**SharedEditorComponents.swift lines 36–38:**

```swift
func updateNSView(_ wv: WKWebView, context: Context) {
    reload(markdown, into: wv)    // unconditional reload
}
```

**Finding:** Every SwiftUI state refresh that propagates through the view tree triggers `updateNSView`, which calls `reload(markdown:into:)` unconditionally. The `reload` function reads `marked.min.js` from disk via `Bundle.main.url(forResource:)`, loads JS with `String(contentsOf:)`, performs regex escaping, constructs a full HTML string, and calls `wv.loadHTMLString()`. This is expensive I/O + DOM teardown/rebuild on every host-view state change — even when `markdown` hasn't changed.

When `MarkdownWebView` is used inside `NotesSheet`/`SnippetEditSheet`, toggling `copyFeedback` from `true → false` can trigger `updateNSView` even though the markdown string is identical. Compare with `PlainTextEditor` at line 161 which correctly guards:

```swift
guard let tv = sv.documentView as? NSTextView, tv.string != text else { return }
```

`MarkdownWebView` has no equivalent content-equality check before calling `reload`.

**Severity: High — disk I/O and full DOM reload on every parent state tick where markdown is unchanged.**

---

### SM-4b: FocusedNSTextField — Font Recreation Every `updateNSView` Call

**CountdownDetailView.swift lines 60–67:**

```swift
func updateNSView(_ nsView: NSTextField, context: Context) {
    if !context.coordinator.isEditing {
        nsView.stringValue = text
    }
    // Apply style every update (font objects are cheap to recreate).
    if let font = NSFont(name: "AlienLeagueBold", size: 36)
        ?? NSFont(name: "Alien League Bold", size: 36) {
        nsView.font = font
    } else {
        nsView.font = NSFont.boldSystemFont(ofSize: 36)
    }
    nsView.textColor = NSColor(AppTheme.dark).withAlphaComponent(0.8)
}
```

**Finding:** The comment claims font objects are cheap to recreate. However, `CountdownDetailView` lives inside a `TimelineView`-driven context (tick every 1 second). Every tick triggers recomposition cascading into `updateNSView`. The unconditional font + color assignment triggers AppKit layout recalculation on the `NSTextField` every second, regardless of whether any style parameters changed.

**Severity: Low-Medium — cosmetic perf issue, not a correctness bug.**

---

### SM-4c: PlainTextEditor `updateNSView` — Correct Guard but Inextensible for Style Changes

**SharedEditorComponents.swift lines 160–162:**

```swift
func updateNSView(_ sv: NSScrollView, context: Context) {
    guard let tv = sv.documentView as? NSTextView, tv.string != text else { return }
    tv.string = text
}
```

**Finding:** The `tv.string != text` guard correctly prevents redundant string writes. However, `font:`, `textColor:`, and `inset:` are passed as plain parameters (not `@Binding`). Since these never change after initial setup in current call sites, this is technically correct today. If a future requirement demands dynamic font or color changes, the guard would block style updates because `tv.string == text` returns early even when font differs.

**Severity: Low — correct today; architectural fragility for future edits.**

---

## 5. Identity Tracking — `ForEach` Keys and `.id()` Usage

### SM-5a: CountdownView.swift — `RowEntry` Correct, but Full Array Rebuilt Every Tick

**Lines 20–23, 148:** The `RowEntry` wrapper is well-designed:

```swift
private struct RowEntry: Identifiable {
    let item:     CountdownItem
    let slotKind: String        // "a" = active, "f" = free
    var id: String { "\(slotKind)-\(item.id)" }    // prefixed UUID
}
```

The prefix strategy correctly forces SwiftUI to recreate `CountdownRowView` when an item transitions between active↔free, because `"a-UUID₁" ≠ "f-UUID₁"`.

**Finding:** Every `TimelineView` tick (currently `by: 0.01` — TEMP DEBUG 100× accelerated interval), `rowEntries(at:)` rebuilds the entire `[RowEntry]` array from scratch. Even when no countdown state changed, a brand-new Swift Array allocation occurs every 10ms. With N items, this is O(N) hash-key lookups per tick × 100 ticks/second.

**Severity: Medium — correctness fine, but unnecessary allocation in TimelineView's periodic block.**

---

### SM-5b: CalculateView.swift `resultRow` — Index-Based `ForEach` on Computed Array

**Lines 231–232:**

```swift
ForEach(parts.indices, id: \.self) { i in
    Text(parts[i].quantity)
```

**Finding:** `parts` is a computed property (`calResultParts` or `resultParts`). When switching between `"cal"` and `"days"` mode, the array length CAN change (6 → 4 or vice versa). If `calResultParts` trims leading-zero components (lines 527–529), the effective array can have variable length within the same mode. Index-based identity means element at index 2 in a 6-element array has the same identity as element at index 2 in a 4-element array, even though they represent different time units. This causes SwiftUI to reuse the `Text` view without re-rendering style/content.

**Severity: Medium — visual glitch risk when `calResultParts` returns arrays of differing lengths.**

---

### SM-5c: CalculateView.swift `deadlineListPopoverContent` — ForEach on `namedDeadlines`

**Lines ~279:** `ForEach(namedDeadlines)` — `NamedDeadline` conforms to `Identifiable` via `id: UUID`, so identity is correct and stable. No issue.

Note: The `async` dispatch at line ~377 for popover-then-detail-sheet sequencing is correct — the popover must close before a detail sheet opens on macOS.

**Severity: None.**

---

### SM-5d: SnippetEditSheet.swift `ProjectField` — `ForEach` on `suggestions` with `id: \.self`

**Line ~67:**

```swift
ForEach(suggestions, id: \.self) { s in
```

**Finding:** `suggestions` is `[String]`. Using the string value as the identity key is correct only if all project names are unique. If two projects share the exact same name, SwiftUI emits a runtime warning about duplicate `ForEach` keys. There is no uniqueness guard on the `existingProjects` input parameter. This works under normal conditions but is fragile if project deduplication upstream fails.

**Severity: Low — data integrity dependency, not a structural bug.**

---

*End of Audit 7*

---

## Post-fix findings — Session Q (BUG-DEADLINE-1/2)

### BUG-DEADLINE-1: `CalculateView` — `showDeleteDeadlineConfirm` (új @State bool)

A BUG-DEADLINE-1 fix hozzáad egy 9. `@State` property-t a `CalculateView`-hoz (`showDeleteDeadlineConfirm: Bool`). Ez az SM-1b finding kontextusában értékelendő: a 3 mutually exclusive modal state enum-ba (`CalculationModalState`) ez **nem** illeszkedne természetesen (a delete confirm az aktív detail sheet felett jelenik meg, nem helyettesíti azt), tehát a bool-flag megközelítés itt indokolt — az `.alert` SwiftUI idiómájában `Bool`-t vár. Nincs új finding, de a sprawl-szám nő: 8 → 9 @State property.

### BUG-DEADLINE-2: padding(.top, 46) — layout-függőség

A rename TextField `padding(.top, 46)` értéke az X gomb pozíciójától (`padding(.top, 12)`) és méretétől (`26pt`) függ implicit módon (12 + 26 + 8 = 46). Ha az X gomb layout-ja változik, a 46-ot manuálisan kell követni. Nincs lifecycle/state finding, de az SM-4a (MarkdownWebView redundant reload) mintájához hasonlóan dokumentálandó implicit layout coupling.
