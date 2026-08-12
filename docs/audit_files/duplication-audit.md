# Duplication & Divergence Audit — countdownApp

> **Scope:** Initial audit covered `NotesSheet.swift` vs `SnippetEditSheet.swift`. Extended to the full codebase after reading `AddCountdownSheet.swift`, `CountdownDetailView.swift`, `CalculateView.swift`, and `CountdownView.swift`.

---

## 1 — Duplicated `@State` Variables & Constants

### Finding 1A: Shared state declarations

| Property | `NotesSheet.swift` | `SnippetEditSheet.swift` |
|---|---|---|
| `isEditing` | `@State private var isEditing = false` | L90: `@State private var isEditing = true` |
| `copyFeedback` | `@State private var copyFeedback = false` | L91: `@State private var copyFeedback = false` |
| Delete-alert flag | `@State private var showDeleteConfirm = false` | L92: `@State private var showDeleteAlert = false` |
| `sheetWidth` | `@State private var sheetWidth: CGFloat = 700` | L96: `@State private var sheetWidth: CGFloat = 700` |
| `windowMargin` | `private let windowMargin: CGFloat = 24` | L124: `private let windowMargin: CGFloat = 24` |

### Finding 1B: Intentional divergence — `isEditing` initial value

`NotesSheet` initialises `isEditing` to `false`; `SnippetEditSheet` initialises it to `true` (computed via `init` guard on emptiness). This is a deliberate behavioral split, but worth documenting.

---

## 2 — Duplicated Methods

### Finding 2A: `updateSheetWidth()` — word-for-word identical

| | `NotesSheet.swift` L117–126 | `SnippetEditSheet.swift` L210–219 |
|---|---|---|
| Doc comment | `/// Reads the presenting (main) window's current width and derives the sheet width from it: window width minus windowMargin, clamped to [450, 900].` | Identical |
| Body | `let windowWidth = NSApp.mainWindow?.frame.width ?? NSApp.windows.first(where: { $0.isVisible && $0.title == "countdownApp" })?.frame.width ?? 900` | Identical |
| Result | `sheetWidth = min(900, max(450, windowWidth - windowMargin))` | Identical |

---

### Finding 2B: `headerButton(icon:tint:action:)` — near-identical, two divergences

| Aspect | `NotesSheet.swift` L84–96 | `SnippetEditSheet.swift` L170–182 |
|---|---|---|
| Default `tint` param | `Color.white.opacity(0.7)` | `Color.white` |
| Background opacity | `Color.white.opacity(0.07)` | `Color.white.opacity(0.12)` |
| Rest of body | `.system(size: 15, weight: .medium)`, 36×36 frame, `cornerRadius: 8`, `.buttonStyle(.plain)`, `.focusable(false)` | Identical |

---

### Finding 2C: Copy-to-clipboard block — identical four-line pattern

| | `NotesSheet.swift` L67–71 | `SnippetEditSheet.swift` L142–146 |
|---|---|---|
| Line 1 | `NSPasteboard.general.clearContents()` | `NSPasteboard.general.clearContents()` |
| Line 2 | `NSPasteboard.general.setString(notes, forType: …)` | `NSPasteboard.general.setString(snippetBody, forType: …)` |
| Line 3 | `copyFeedback = true` | `copyFeedback = true` |
| Line 4 | `DispatchQueue.main.asyncAfter(deadline: .now()+1) { copyFeedback = false }` | Identical |

Same four-line block operating on a different binding (`notes` vs `snippetBody`) with no shared abstraction — a DRY violation (see D4).

---

### Finding 2D: Dismiss logic — intentional divergence

Both files bind the `"xmark"` header button to `dismiss()`, but `SnippetEditSheet` wraps it in a `commitSave()` guard first (L154: `commitSave(); dismiss()`). This is intentional.

---

## 3 — Duplicated Structural Layout Patterns

### Finding 3A: Top-level `body` structure — identical nesting

```swift
// NotesSheet.swift L41–50  /  SnippetEditSheet.swift L126–135  (identical)
ZStack {
    AppTheme.background.ignoresSafeArea()
    VStack(spacing: 0) {
        header
        Rectangle().fill(Color.white.opacity(0.08))
            .frame(height: 1)
            .padding(.horizontal, 24)
        contentArea
    }
}
```

---

### Finding 3B: Header row composition

| Element | `NotesSheet` L61–78 | `SnippetEditSheet` L140–158 |
|---|---|---|
| Title | `Text("NOTES")` styled with `alienLeagueBold(24)` | `TextField("Title", text: $title)` styled with `alienLeagueBold(22)` |
| Button group | Copy / Edit-toggle / Trash (always present) | Copy / Edit-toggle / Trash (guarded by `if onDelete != nil`) |
| Separator | `.fill(Color.white.opacity(0.12)).frame(width: 1, height: 22).padding(.horizontal, 6)` | Identical |
| Dismiss button | `headerButton(icon: "xmark") { dismiss() }` | `headerButton(icon: "xmark") { commitSave(); dismiss() }` |

---

### Finding 3C: `contentArea` — identical edit/view ternary structure

```swift
// NotesSheet L98–114  /  SnippetEditSheet L186–204
if isEditing {
    PlainTextEditor(
        text: $notes,               // SnippetEditSheet: $snippetBody
        font: …monospaced…,
        textColor: NSColor(AppTheme.background),
        inset: NSSize(w: 24, h: 20),
        lineSpacing: 5
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppTheme.calculateBackground)
} else if notes.isEmpty {           // SnippetEditSheet: snippetBody.isEmpty
    Button { … } label: { VStack(icon + text) … }
} else {
    MarkdownWebView(markdown: notes) // SnippetEditSheet: wrapped in extra VStack(spacing: 0)
}
```

---

### Finding 3D: Empty-state placeholder — near-identical

| Detail | `NotesSheet` L106–112 | `SnippetEditSheet` L194–201 |
|---|---|---|
| SF Symbol | `"note.text.badge.plus"` | `"doc.plaintext.fill"` |
| Icon size | `.system(size: 32)` | `.system(size: 32)` |
| Icon tint | `Color.white.opacity(0.4)` | `Color.white.opacity(0.4)` |
| Body text | `"No notes yet.\nTap to start writing."` | `"Tap to start writing."` |
| Text font | `AppTheme.alienLeague(13)` | `AppTheme.alienLeague(13)` |
| Text tint | `Color.white.opacity(0.6)` | `Color.white.opacity(0.6)` |
| Frame / button style | `.frame(maxWidth/Height: .infinity)`, `.contentShape(.rect)`, `.buttonStyle(.plain)`, `.focusable(false)` | Identical |

---

## 4 — Hardcoded Numbers Shared Across Both Files

| Constant | `NotesSheet.swift` | `SnippetEditSheet.swift` | Lines (NS / SES) |
|---|---|---|---|
| `windowMargin` | `24` | `24` | L35 / L124 |
| `sheetWidth` initial | `700` | `700` | L34 / L96 |
| Clamp floor | `max(450, …)` | `max(450, …)` | L125 / L218 |
| Clamp ceiling | `min(900, …)` | `min(900, …)` | L125 / L218 |
| Fallback window width | `900` | `900` | L124 / L217 |
| Divider opacity | `Color.white.opacity(0.08)` | `Color.white.opacity(0.08)` | L45 / L131 |
| Divider height | `height: 1` | `height: 1` | L45 / L131 |
| Header horizontal padding | `.horizontal, 24` | `.horizontal, 24` | L79–80 / L160–161 |
| Separator opacity | `Color.white.opacity(0.12)` | `Color.white.opacity(0.12)` | L73 / L152 |
| Separator size | `width: 1, height: 22` | `width: 1, height: 22` | L73 / L152 |
| Separator padding | `.padding(.horizontal, 6)` | `.padding(.horizontal, 6)` | L73 / L152 |
| Button group spacing | `spacing: 8` | `spacing: 8` | L66 / L147 |
| Header button frame | `width: 36, height: 36` | `width: 36, height: 36` | L90 / L176 |
| Corner radius | `cornerRadius: 8` | `cornerRadius: 8` | L92 / L178 |
| Icon font | `.system(size: 15, weight: .medium)` | `.system(size: 15, weight: .medium)` | L89 / L175 |
| `PlainTextEditor` inset | `NSSize(w: 24, h: 20)` | `NSSize(w: 24, h: 20)` | L101 / L189 |
| `PlainTextEditor` lineSpacing | `5` | `5` | L103 / L191 |
| Empty-state icon size | `.system(size: 32)` | `.system(size: 32)` | L108 / L196 |
| Empty-state `VStack` spacing | `spacing: 12` | `spacing: 12` | L107 / L195 |

### Finding 4A: `minHeight` differs — inconsistent documentation

| File | Code | Line | Comment says |
|---|---|---|---|
| `NotesSheet` | `.frame(…, minHeight: 520)` | L56 | "Empty / EDIT mode: 360pt. VIEW mode with content: 520pt." |
| `SnippetEditSheet` | `private var sheetMinHeight: CGFloat { 680 }` | L124 / L142 | "Empty / EDIT mode: 520pt. VIEW mode with content: 680pt." |

Both comments describe two dynamic height modes, but both files use a single fixed value. The comments are misleading in both cases (see D7).

---

## 5 — Behavioral Divergences That Appear Unintentional

| # | Divergence | `NotesSheet.swift` | `SnippetEditSheet.swift` | Why It May Be Unintentional |
|---|---|---|---|---|
| D1 | Default `tint` on `headerButton()` | `Color.white.opacity(0.7)` (L83) | `Color.white` (L169) | Both files call the helper with explicit `.opacity(0.7)` on the copy button; the `SnippetEditSheet` default is brighter but effectively unused. One of these defaults is dead code. |
| D2 | Header button background opacity | `Color.white.opacity(0.07)` (L91) | `Color.white.opacity(0.12)` (L177) | Buttons look visually different between the two sheets — almost certainly a copy-paste mutation oversight. |
| D3 | `MarkdownWebView` wrapping | Bare `.frame(maxW/maxH: .infinity)` (L114) | Wrapped in extra `VStack(spacing: 0)` before `.frame()` (L201–203) | The `SnippetEditSheet` wrapper was added in Session G to resolve an overload ambiguity that equally applies to `NotesSheet`. Asymmetrical patch. |
| D4 | Copy target | Copies `notes` (L68) | Copies `snippetBody` (L143) | Functionally correct per file, but the identical four-line pasteboard block operates on a different binding with no shared abstraction — DRY violation. |
| D5 | Delete semantics | Sets `notes = ""` via binding mutation (L59) | Calls `onDelete?(id)` then `dismiss()` (L138–140) | Same alert UI and button roles, fundamentally different deletion logic. A shared `confirmDelete(action:)` helper could unify the alert chrome while delegating to file-specific actions. |
| D6 | `.focusable(false)` placement | Applied to individual subviews only | Also applied at `body` level (L142) | `NotesSheet` has no top-level `.focusable(false)`; `SnippetEditSheet` does. Tab-navigation focus behavior may differ between the two sheets. |
| D7 | Height comment accuracy | "Empty / EDIT: 360pt. VIEW: 520pt" (L19–20) — but code uses single fixed `520` | "Empty / EDIT: 520pt. VIEW: 680pt" (L19–20) — but code uses single fixed `680` | Neither file dynamically resizes. Both comments describe a two-mode height that doesn't exist in code. |


---

## 6 — Cross-File Duplication (Full Codebase Scan)

### Finding 6A: `componentStepper` — three independent implementations

The YEAR/MON/DAY/HOUR/MIN component stepper is reimplemented from scratch in three files. Structure is identical (label above, up-chevron, value text, down-chevron, `frame(maxWidth: .infinity)`), but the chevron buttons differ:

| File | Chevron widget | `foregroundColor` / `backgroundColor` theme |
|---|---|---|
| `AddCountdownSheet.swift` | Plain `Button` with inline styling | `AppTheme.dark` / `AppTheme.dark.opacity(0.12)` |
| `CountdownDetailView.swift` | `LongPressStepperButton` (long-press repeat) | `AppTheme.dark` / `AppTheme.dark.opacity(0.12)` |
| `CalculateView.swift` | `LongPressStepperButton` | `AppTheme.background` / `Color.white.opacity(0.12)` |

`AddCountdownSheet` silently regressed `LongPressStepperButton` — the user can't long-press to accelerate stepping when creating a new item, but can in `CountdownDetailView` and `CalculateView`.

---

### Finding 6B: `dateStepper` / `deadlineStepper` wrapper — three files

The outer container (HStack of `componentStepper` calls, padded rounded-rect background) is copied verbatim across all three files. Padding and corner radius are identical; only the background color token differs (theme variant):

| File | Background | Outer `.padding(.horizontal, …)` |
|---|---|---|
| `AddCountdownSheet.swift` | `AppTheme.dark.opacity(0.12)` | none (parent handles it) |
| `CountdownDetailView.swift` | `AppTheme.dark.opacity(0.12)` | `.padding(.horizontal, 24)` added outside |
| `CalculateView.swift` | `Color.white.opacity(0.12)` | none |

---

### Finding 6C: `monthAbbrev()` — three files, same implementation

```swift
// AddCountdownSheet.swift — uses self.deadline
// CountdownDetailView.swift — uses self.localDeadline
// CalculateView.swift — takes `from date: Date` parameter (only variation)
private func monthAbbrev() -> String {
    let fmt = DateFormatter()
    fmt.dateFormat = "MMM"
    fmt.locale = Locale(identifier: "en_US")
    return fmt.string(from: <date>).uppercased()
}
```

`CalculateView` is the only one that parameterises the date — the other two close over a local property. A single static helper `monthAbbrev(from:)` would cover all three.

---

### Finding 6D: `private var cal: Calendar { Calendar.current }` — three files

| File | Declaration |
|---|---|
| `AddCountdownSheet.swift` | `private var cal: Calendar { Calendar.current }` |
| `CountdownDetailView.swift` | `private var cal: Calendar { Calendar.current }` |
| `CalculateView.swift` | `private var cal: Calendar { Calendar.current }` |

Identical computed property. A file-private or internal extension on `View` would eliminate all three.

---

### Finding 6E: `adjust()` / `adjustDate()` — three divergent signatures

All three files contain a calendar-component adjustment helper, but the signatures differ:

| File | Signature | Writes to |
|---|---|---|
| `AddCountdownSheet.swift` | `adjust(_ c: Component, by: Int)` | `deadline` (single `@State`) |
| `CountdownDetailView.swift` | `adjust(_ c: Component, by: Int)` | `localDeadline` + `item.deadline` (dual write) |
| `CalculateView.swift` | `adjustDate(_ binding: Binding<Date>, _ c: Component, by: Int)` | passed `Binding<Date>` |

`CalculateView`'s version is the most reusable (binding-based); the other two are scope-locked.

---

### Finding 6F: Copy-to-clipboard block — three files, minor divergences

| File | Source string | Feedback delay | Icon change on feedback |
|---|---|---|---|
| `NotesSheet.swift` | `notes` | 1.0 s | No |
| `SnippetEditSheet.swift` | `snippetBody` | 1.0 s | No |
| `CountdownDetailView.swift` | `item.label.trimmingCharacters(in: .whitespaces)` | 1.2 s | Yes (`doc.on.doc` → `checkmark`) |

`CountdownDetailView` is the most complete version (icon feedback, trim). The 1.2 s vs 1.0 s divergence is almost certainly accidental.

---

### Finding 6G: `try?` persistence pattern — four locations

The silent `try?`-based save/load pattern flagged in the Codable audit (S-5, S-6, ND-4) also appears in `CountdownView` and `CalculateView`:

| File | Function | Pattern |
|---|---|---|
| `CountdownView.swift` | `save()` | `guard let data = try? JSONEncoder().encode(items) else { return }` |
| `CountdownView.swift` | `load()` | `guard … let decoded = try? JSONDecoder().decode([CountdownItem].self …) else { return }` |
| `CalculateView.swift` | `saveDeadlines()` | `if let data = try? JSONEncoder().encode(namedDeadlines)` |
| `CalculateView.swift` | `loadDeadlines()` | `guard … let decoded = try? JSONDecoder().decode([NamedDeadline].self …) else { return }` |

Same risk as S-5/ND-4: any decode error silently wipes the array. `CountdownView.load()` is the highest-severity instance — it controls the primary item list.

---

### Finding 6H: `deadlineDateString()` / `deadlineFormatted` — two implementations

| File | Format | Location |
|---|---|---|
| `CountdownItem.swift` | `"yyyy.MM.dd HH:mm"` (dots, no locale override) | `var deadlineFormatted: String` (computed property) |
| `CalculateView.swift` | `"yyyy MMM dd  HH:mm"` (spaces + month abbrev, `en_US` locale, `.uppercased()`) | `func deadlineDateString(_ date: Date) -> String` |

Different output for the same conceptual operation. Probably intentional (list row vs calculator display), but undocumented and could drift further.


---

## 7 — Additional Findings from Full Codebase Scan

### Finding 7A: Copy-to-clipboard — negyedik instance, `CountdownRowView`-ban

`CountdownRowView.swift` tartalmaz egy 4. pasteboard blokkot, amely két szempontból is eltér a többi háromtól:

| File | Source string | Delay | Icon feedback | Platform fork |
|---|---|---|---|---|
| `NotesSheet.swift` | `notes` | 1.0 s | No | No |
| `SnippetEditSheet.swift` | `snippetBody` | 1.0 s | No | No |
| `CountdownDetailView.swift` | `item.label.trimmingCharacters(…)` | 1.2 s | Yes (`checkmark`) | No |
| `CountdownRowView.swift` | `item.label.trimmingCharacters(…)` | 1.2 s | No (text: "COPIED") | **Yes** — `#if os(macOS)` / `UIPasteboard` |

`CountdownRowView` az egyetlen, amely iOS-ra is fel van készítve (`UIPasteboard.general.string`). A többi három macOS-only `NSPasteboard`-ot használ és nem tartalmaz platform-feltételt — ha iOS támogatás kerül hozzájuk, mindháromban külön kell majd javítani.

---

### Finding 7B: `DateFormatter` ad-hoc példányosítás — hat helyen

Minden formázó-hívás új `DateFormatter`-t hoz létre, cacheing nélkül:

| File | Function | Format |
|---|---|---|
| `AddCountdownSheet.swift` | `monthAbbrev()` | `"MMM"` |
| `CountdownDetailView.swift` | `monthAbbrev()` | `"MMM"` |
| `CalculateView.swift` | `monthAbbrev(from:)` | `"MMM"` |
| `CalculateView.swift` | `deadlineDateString(_:)` | `"yyyy MMM dd  HH:mm"` |
| `CountdownItem.swift` | `var deadlineFormatted` | `"yyyy.MM.dd HH:mm"` |
| `SunPanel.swift` | `timeString(_:)` | `"HH:mm"` |

`DateFormatter` példányosítás viszonylag drága; a `timeString(_:)` a `SunPanel`-ben minden egyes sor renderelésénél hívódhat. Érdemes statikus/cached formázókat használni.

---

### Fájlok, amelyekben nincs duplication finding

| File | Megjegyzés |
|---|---|
| `ContentView.swift` | Önálló, nincs megosztható logika |
| `AppTheme.swift` | Shared konstansok — épp ő az, ami eliminálja a duplikációt |
| `ColorPickerSheet.swift` | Egyedi logika, nincs párhuzamos implementáció |
| `LongPressStepperButton.swift` | Shared component — helyesen kiszervezve |
| `SunPanel.swift` | Önálló; `timeRow`/`labelRow` belül DRY |
| `SunTimes.swift` | Önálló dekódoló logika |
| `SunTimesService.swift` | Önálló service |
| `countdownAppApp.swift` | App entry point |
| `SharedEditorComponents.swift` | Helyesen kiszervezett shared editor |

---

## 8 — Post-fix findings (BUG-1: Saved Deadlines remaining time)

### Finding 8A: `deadlineRemainingString(for:)` partially duplicates `calResultParts` logic

| | `calResultParts` (existing) | `deadlineRemainingString(for:)` (new) |
|---|---|---|
| Location | `CalculateView.swift`, computed property | `CalculateView.swift`, private func |
| Components | `[.year, .month, .day, .hour, .minute, .second]` | `[.year, .month, .day, .hour, .minute]` |
| Filter | first non-zero index onward | all non-zero |
| Output | `[TimePart]` struct array (for result display rows) | `String` (compact inline, top 2 components) |
| Format | `"\(qty)"` + `"\(unit)"` as separate Text views | `"\(qty)\(unit)"` joined with space |

The `cal.dateComponents → filter non-zero → format components` skeleton is identical. The output shapes differ
(array of structs vs compact string), so a single function can't replace both, but a shared
`calComponents(from:to:) -> [(value: Int, unit: String)]` helper could eliminate the dateComponents +
zip + filter duplication and serve both call sites.

**Severity:** Low — same file, no cross-file spread, logically cohesive. Relevant if more remaining-time
display surfaces are added later.


---

## 9 — Post-fix findings — Session P: Deadline Rename (CalculateView.swift)

### Finding 9A: Rename button pair duplicates save button pair (same file)

`deadlineDetailContent` rename mode renders a CANCEL + RENAME button pair that is
structurally identical to the CANCEL + SAVE pair in `saveSheetContent`. Every styling
decision is mirrored:

| Attribute | `saveSheetContent` (CANCEL/SAVE) | rename mode (CANCEL/RENAME) |
|---|---|---|
| Cancel font | `alienLeague(13)` white 0.5 | `alienLeague(13)` white 0.5 |
| Cancel bg | `white.opacity(0.07)` | `white.opacity(0.07)` |
| Confirm font | `alienLeagueBold(13)` | `alienLeagueBold(13)` |
| Confirm fg | `AppTheme.calculateBackground` | `AppTheme.calculateBackground` |
| Confirm bg | `AppTheme.background` | `AppTheme.background` |
| Corner radius | `8` | `8` |
| Padding H/V | `16` / `8` | `16` / `8` |
| Disabled guard | `saveTitleDraft.trimmingCharacters(in: .whitespaces).isEmpty` | `renameDraft.trimmingCharacters(in: .whitespaces).isEmpty` |

Only the button labels (`SAVE` / `RENAME`) and action bodies differ. A shared
`@ViewBuilder confirmButtonPair(cancelAction:confirmLabel:confirmAction:isDisabled:)` helper
would eliminate the duplication and enforce visual consistency.

---

### Finding 9B: `isRenamingDeadline` + `renameDraft` mirrors `showSaveSheet` + `saveTitleDraft`

Both pairs follow the same "bool flag + draft string" pattern for a
"type-text-then-confirm" flow, within the same view:

| | Save flow | Rename flow |
|---|---|---|
| Flag | `@State var showSaveSheet: Bool` | `@State var isRenamingDeadline: Bool` |
| Draft | `@State var saveTitleDraft: String` | `@State var renameDraft: String` |
| Entry point | left segment of split SAVE button | pencil icon button in detail sheet |
| Trim guard | `trimmingCharacters(in: .whitespaces).isEmpty` | identical |
| Reset on dismiss | `showSaveSheet = false` (sheet lifecycle) | `.onDisappear { isRenamingDeadline = false }` |

The two flows are semantically distinct (create vs rename) but structurally isomorphic.
This is not an immediate refactoring priority — both are contained within `CalculateView` —
but worth noting if CALC-SAVE grows a third "text entry" flow.


---

## 10 — Post-fix findings — Session P (cont.): X dismiss + dynamic popover width (CalculateView.swift)

### Finding 10A: Inline popover-width calculation — third instance of window-width pattern

`deadlineListPopoverContent` `.onAppear` block:

```swift
let windowWidth = NSApp.mainWindow?.frame.width
    ?? NSApp.windows.first(where: { $0.isVisible })?.frame.width
    ?? 600
popoverWidth = min(320, max(220, windowWidth - 48))
```

This is a third implementation of the "read main window width → subtract margin → clamp" pattern,
after `NotesSheet.updateSheetWidth()` and `SnippetEditSheet.updateSheetWidth()` (Finding 2A).
Differences vs the sheet versions:

| | `NotesSheet` / `SnippetEditSheet` | `deadlineListPopoverContent` |
|---|---|---|
| Form | Named private method `updateSheetWidth()` | Inline `.onAppear` closure |
| Clamp floor | `max(450, …)` | `max(220, …)` |
| Clamp ceiling | `min(900, …)` | `min(320, …)` |
| Margin | `windowMargin = 24` (named constant) | `48` (magic literal — see audit 3 §10B) |
| Fallback | `?? 900` | `?? 600` |
| Target | `sheetWidth: CGFloat` state var | `popoverWidth: CGFloat` state var |

Three slightly divergent copies of the same structural idea. A shared helper
`windowConstrainedWidth(min:max:margin:fallback:) -> CGFloat` would unify all three.

---

### Finding 10B: X dismiss button — fourth instance of xmark dismiss pattern

The X button overlay in `deadlineDetailContent` is the fourth xmark dismiss button
in the codebase. Compare across all instances:

| File | Symbol | Frame | Corner radius | BG opacity | FG opacity | Font size |
|---|---|---|---|---|---|---|
| `NotesSheet.swift` | `headerButton(icon: "xmark")` | 36×36 | 8 | 0.07 | 0.7 | 15, medium |
| `SnippetEditSheet.swift` | `headerButton(icon: "xmark")` | 36×36 | 8 | 0.12 | 1.0 | 15, medium |
| `saveSheetContent` (implicit) | — | — | — | — | — | — |
| `deadlineDetailContent` | inline `Button` | 26×26 | 6 | 0.08 | 0.5 | **11**, medium |

The `deadlineDetailContent` X button is noticeably smaller (26×26 vs 36×36) and
dimmer (fg 0.5 vs 0.7–1.0). This may be intentional (the detail sheet is compact),
but if it's not a deliberate size decision, the inconsistency is a DRY/design-language gap.
A shared `dismissButton(action:)` helper (similar to `headerButton`) would enforce visual
consistency across all four dismiss locations.

---

## 11 — Post-fix findings — Session P (BUG-WIDTH-CALC / BUG-WIDTH-COLOR / BUG-WIDTH-ADD / BUG-DELETE-CONFIRM / BUG-COLOR-NODISMISS)

### Finding 11A: `updateSheetWidth()` — negyedik + ötödik instance, inline változatokkal

A Session N-ben dokumentált `updateSheetWidth()` duplikáció (Finding 2A: NotesSheet vs SnippetEditSheet)
ma három újabb helyen jelent meg, részben eltérő formában:

| File | Forma | Clamp floor | Clamp ceiling | Margin | Fallback |
|---|---|---|---|---|---|
| `NotesSheet.swift` | named method `updateSheetWidth()` | 450 | 900 | 24 (named `windowMargin`) | 900 |
| `SnippetEditSheet.swift` | named method `updateSheetWidth()` | 450 | 900 | 24 (named `windowMargin`) | 900 |
| `CalculateView.swift` (új) | named method `updateSheetWidth()` | 300 | 520 | 24 (named `windowMargin`) | 600 |
| `ColorPickerSheet.swift` (új) | inline `.onAppear` closure | 300 | 420 | 24 (magic literal) | 600 |
| `AddCountdownSheet.swift` (új) | inline `.onAppear` closure | 380 | 560 | 24 (magic literal) | 600 |

Az inline változatoknál a `24` margin már nem névvel szerepel — visszacsúszott magic literállá.
Öt implementáció, három eltérő clamp tartomány, két eltérő forma. A Finding 2A-ban javasolt
`windowConstrainedWidth(min:max:margin:fallback:)` helper most még inkább indokolt.

---

### Finding 11B: `showDeleteConfirm` — ötödik "bool flag + alert" instance a codebase-ben

A `BUG-DELETE-CONFIRM` fix hozzáadta `@State private var showDeleteConfirm: Bool = false`-t
a `CountdownDetailView`-hoz. Ez az ötödik "bool trigger → `.alert`" minta a projektben:

| File | Flag | Alert témája |
|---|---|---|
| `NotesSheet.swift` | `showDeleteConfirm` | Notes törlés megerősítés |
| `SnippetEditSheet.swift` | `showDeleteAlert` | Snippet törlés megerősítés |
| `SnippetsView.swift` | `showRenameAlert` | Projekt átnevezés |
| `SnippetsView.swift` | `showDeleteProjectAlert` | Projekt törlés megerősítés |
| `CountdownDetailView.swift` (új) | `showDeleteConfirm` | Slot törlés megerősítés |

A flag neve eltér (`showDeleteConfirm` vs `showDeleteAlert`) — a `NotesSheet` és `CountdownDetailView`
`showDeleteConfirm`-et használ, a `SnippetEditSheet` `showDeleteAlert`-et. Nem funkcionális probléma,
de elnevezési inkonzisztencia.

---

### Finding 11C: X dismiss gomb — ötödik instance (ColorPickerSheet)

A `BUG-COLOR-NODISMISS` fix hozzáadott egy X gombot a `ColorPickerSheet`-hez. Ez az ötödik
xmark dismiss gomb a projektben — a Finding 10B-ben már dokumentált négy mellé:

| File | Frame | Corner radius | BG | FG | Font size | Téma |
|---|---|---|---|---|---|---|
| `NotesSheet` `headerButton` | 36×36 | 8 | white 0.07 | white 0.7 | 15, medium | sötét (amber bg) |
| `SnippetEditSheet` `headerButton` | 36×36 | 8 | white 0.12 | white 1.0 | 15, medium | sötét (amber bg) |
| `deadlineDetailContent` (CalculateView) | 26×26 | 6 | white 0.08 | white 0.5 | 11, medium | sötét (gradient bg) |
| `saveSheetContent` — nincs X gomb | — | — | — | — | — | — |
| `ColorPickerSheet` (új) | 26×26 | 6 | dark 0.08 | dark 0.5 | 11, medium | **amber bg** |

A `ColorPickerSheet` X gombja amber háttéren `AppTheme.dark`-ot használ (helyesen), míg a többi
sötét hátterű sheeten `Color.white`-ot. Stilisztikailag helyes, de a két variáns dokumentálása
szükséges ha közös `dismissButton(action:)` helper kerül bevezetésre — a téma-érzékeny
változatot kell általánosítani (`foregroundStyle` paraméterrel).


---

### Finding 11D: `showDeleteDeadlineConfirm` — hatodik delete-confirm bool-flag instance (Session Q)

A `BUG-DEADLINE-1` fix hozzáadott egy új delete-confirm flag + `.alert` párost a `CalculateView`-ba.
Ez a hatodik instance a projektben:

| File | Flag neve | Mit töröl |
|---|---|---|
| `NotesSheet.swift` | `showDeleteConfirm` | Notes szöveg törlése |
| `SnippetEditSheet.swift` | `showDeleteAlert` | Snippet törlése |
| `SnippetsView.swift` | `showRenameAlert` | Projekt átnevezés (nem törlés, de alert-minta) |
| `SnippetsView.swift` | `showDeleteProjectAlert` | Projekt törlése |
| `CountdownDetailView.swift` | `showDeleteConfirm` | Slot törlése |
| `CalculateView.swift` (új) | `showDeleteDeadlineConfirm` | Saved deadline törlése |

Elnevezési inkonzisztencia folytatódik: `showDeleteDeadlineConfirm` egyedi nevet kapott (ütközés
elkerülése miatt, mert `CalculateView`-ban már nem volt `showDeleteConfirm`), de a minta
egységesítése (`showDeleteConfirm` mindenhol, helyi scope-ban) refaktor-téma marad.
