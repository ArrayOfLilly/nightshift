# countdownApp — Accessibility Audit (Audit 15)

**Scope:** VoiceOver focus on macOS — interactive controls, semantic labels, decorative images, dynamic content, NSViewRepresentable propagation.

---

## §1 — Missing `.accessibilityLabel` / `.accessibilityHint`

### CountdownRowView.swift

| Line Range | Element | Missing Modifier |
|---|---|---|
| 36–50 | Label tap-to-copy target (`simultaneousGesture(TapGesture(...))`) — copies label to pasteboard; no accessibility role or hint on the gesture | `.accessibilityAddTraits(.isButton)`, `.accessibilityLabel("Copy countdown name")` — gesture-only targets are invisible to VoiceOver without explicit annotation |
| 56–64 | Button toggling `showRemaining` (clock/calendar icon). Icon-only; VoiceOver announces only "Button" with no context | `.accessibilityLabel(item.showRemaining ? "Show deadline date" : "Show remaining time")` |
| 70–76 | Remaining time countdown `Text` — dynamic content updating every second; no hint about being a live timer | `.accessibilityLabel("Countdown remaining: \(item.remainingFormatted(at: now))")`, `.accessibilityAddTraits(.isStaticText)` |
| 78–84 | Deadline date display `Text`; auto-extracted by SwiftUI but no contextual label | `.accessibilityLabel("Deadline: \(item.deadlineFormatted)")` |

### CountdownDetailView.swift

| Line Range | Element | Missing Modifier |
|---|---|---|
| 148–157 | Copy label button (`doc.on.doc` icon). Icon-only | `.accessibilityLabel(copyFeedback ? "Copied" : "Copy label to clipboard")` |
| 209–226 | Show remaining / deadline toggle button — compound content (icon + text); explicit label strengthens VoiceOver output | `.accessibilityLabel(showRemaining ? "Switch to showing deadline date" : "Switch to showing remaining time")`, `.accessibilityAddTraits(.isButton)` |
| 234–250 | Color picker button (`paintbrush` icon, expired slots only). Icon-only | `.accessibilityLabel("Pick accent color for this countdown")` |
| 240–259 | Sound toggle button (`speaker.wave.2.fill` / `speaker.slash.fill`). Icon-only; VoiceOver cannot distinguish on/off | `.accessibilityLabel(item.soundEnabled ? "Sound enabled — tap to disable" : "Sound disabled — tap to enable")`, `.accessibilityAddTraits(.isButton)` |
| 262–280 | Notes button (`note.text.badge.plus` / `note.text`). Icon-only | `.accessibilityLabel(item.notes.isEmpty ? "Add notes for this countdown" : "View and edit notes for this countdown")` |
| 283–291 | Delete button (`trash` icon). Icon-only destructive action | `.accessibilityLabel("Delete countdown \"\(item.label)\"")` |

### ColorPickerSheet.swift

| Line Range | Element | Missing Modifier |
|---|---|---|
| 28–38 | Dismiss button (`xmark` icon). Icon-only close button | `.accessibilityLabel("Close color picker")` |
| 61–70+ (`swatchButton`) | Color swatch buttons — `ForEach` renders each palette color with `label: nil`. VoiceOver announces every non-AUTO swatch identically as "Button"; user cannot distinguish Amber from Teal from Navy | Each swatch needs `.accessibilityLabel(...)` — mapped human-readable name per color index (see §3) |

### CalculateView.swift

| Line Range | Element | Missing Modifier |
|---|---|---|
| 109–126 | "RESET FROM NOW" button — labeled, but no hint about what it resets | `.accessibilityHint("Reset the FROM date to the current time")` |
| 134–151 | "RESET TO NOW" button — same pattern | `.accessibilityHint("Reset the TO date to the current time")` |
| 204–226 | Mode toggle button (CAL / DAYS) — no explicit label; compound meaning lost | `.accessibilityLabel(displayMode == "days" ? "Switch to calendar mode" : "Switch to days mode")` |
| 233–255 | SAVE button (`bookmark.fill` + "SAVE") — has text label (OK); could benefit from hint | `.accessibilityHint("Save the current TO date as a named deadline")` |
| 263–285 | Chevron-down popover trigger in split Save button. Icon-only (`chevron.down`) | `.accessibilityLabel(namedDeadlines.isEmpty ? "No saved deadlines" : "Open list of saved deadlines")` |
| 374–405+ | Deadline detail sheet: pencil (rename) and trash (delete) — both icon-only | Pencil: `.accessibilityLabel("Rename this deadline")`. Trash: `.accessibilityLabel("Delete this deadline from saved list")` |
| 351–362 | "LOAD AS TO" button — has text label (OK) | `.accessibilityHint("Load this deadline as the TO date in the calculator")` |

### AddCountdownSheet.swift

| Line Range | Element | Missing Modifier |
|---|---|---|
| 59–63+ (component stepper chevron buttons) | Inc/Dec stepper buttons use `Button(action:) { Image(systemName: "chevron.up") }`. Icon-only; no label explaining what is being incremented or decremented | `.accessibilityLabel("\(label) increment")` / `.accessibilityLabel("\(label) decrement")` on each chevron button |

### NotesSheet.swift

| Line Range | Element | Missing Modifier |
|---|---|---|
| 81–96+ (`headerButton` calls) | Copy, Edit-Toggle, Delete, Dismiss buttons — all icon-only; four separate controls with no labels | Copy: `.accessibilityLabel(copyFeedback ? "Copied" : "Copy notes to clipboard")`. Toggle: `.accessibilityLabel(isEditing ? "Switch to view mode" : "Switch to edit mode")`. Trash: `.accessibilityLabel("Delete all notes")`. Xmark: `.accessibilityLabel("Close notes sheet")` |

### SnippetsView.swift

| Line Range | Element | Missing Modifier |
|---|---|---|
| 78–87 | Add snippet button (`plus` icon). Icon-only | `.accessibilityLabel("Add a new snippet")` |
| 133–148 | Section header menu trigger (`chevron.down` on project name row). Icon-only context menu | `.accessibilityLabel("Menu for \(project) snippets — rename or delete project")` |
| 161–195+ (`snippetRow`) | Row-edit tap target (`contentShape Rectangle`). No VoiceOver label on the tap area; only child `Text` nodes exposed; the row as an interactive unit isn't announced | `.accessibilityLabel("Edit snippet: \(snippet.title)")`, `.accessibilityAddTraits(.isButton)` on the outer HStack or Button |
| 185–200+ (copy button per row) | Copy-per-row button (`doc.on.doc` icon). Icon-only | `.accessibilityLabel(copied ? "Copied" : "Copy snippet body to clipboard")` |

### SnippetEditSheet.swift

| Line Range | Element | Missing Modifier |
|---|---|---|
| 135–148+ (`headerButton` calls) | Copy, Edit-Toggle, Trash, Dismiss — same icon-only pattern as NotesSheet | Same label set as NotesSheet (see above) |
| 94 (`ProjectField` chevron dropdown button) | Dropdown trigger is an icon-only `chevron` button | `.accessibilityLabel("Choose a project from suggestions")` |
| 103 (suggestion list items) | Each suggestion `Button` has text content but no hint about its action | `.accessibilityHint("Select this project name for the snippet")` on each |

### CountdownView.swift

| Line Range | Element | Missing Modifier |
|---|---|---|
| 207–218 | "+ ADD" button — has text "add" from `Text` view, but VoiceOver may not clearly associate the action | `.accessibilityLabel("Add a new countdown")`, `.accessibilityHint("Opens a dialog to create a new countdown entry")` |
| 175–198 | `NavigationLink` wrapping `CountdownRowView`. Row content exposed via child but link-target relationship is implicit | `.accessibilityHint("Tap to view countdown detail")` on each `NavigationLink` |

### ContentView.swift

`modeButton` already has `.accessibilityLabel(mode.rawValue)` ✅ — properly covered, no finding.

---

## §2 — Countdown Values: Semantic vs. Non-Semantic Text

### CountdownRowView.swift

| Line Range | Severity | Detail |
|---|---|---|
| 70–76 | ⚠️ Partial | Remaining time is a plain `Text()` — SwiftUI auto-extracts the string for VoiceOver. No explicit `.accessibilityLabel` means VO reads whatever string is rendered at that frozen second with no semantic context ("timer" vs. "static label"). No `.accessibilityAddTraits(.isStaticText)` to clarify that this updates dynamically. |
| 78–84 | ⚠️ Partial | Deadline date `Text(item.deadlineFormatted)` — same concern: auto-extract works but no contextual label distinguishes "deadline" from "remaining". |

### CountdownDetailView.swift

| Line Range | Severity | Detail |
|---|---|---|
| 293–315 (`timeDisplay`) | ⚠️ Partial | The large countdown display ("02:14:33" or "EXPIRED") is overlaid on the tomato image via `.overlay { GeometryReader }`. VoiceOver will see the `Text` node (not a decorative draw layer), but absolute positioning inside a `GeometryReader` can cause some VO configurations to fail to associate it with the image context. No explicit label like "Timer remaining: 2 hours 14 minutes" — raw digits only. |
| 305–311 | ⚠️ Partial | Same overlay concern for deadline date display mode: `.accessibilityLabel("Deadline is \(item.deadlineFormatted)")` would make the semantic relationship explicit. |

---

## §3 — ColorPickerSheet Swatches: VoiceOver Indistinguishability

| File | Line Range | Finding | Detail |
|---|---|---|---|
| `ColorPickerSheet.swift` | 47–53 | ❌ NOT distinguishable | `ForEach(Array(AppTheme.freeColors.enumerated()), id: \.offset)` passes `label: nil` to every palette swatch. VoiceOver announces all 14 color buttons identically as **"Button"**. The only differentiator is positional ("item 3 of 15"). A user cannot hear "Blue", "Olive Yellow", or "Deep Red". |
| `ColorPickerSheet.swift` | 44–46 | ✅ Partially OK | The AUTO swatch passes `label: "AUTO"` — distinguishable because it contains visible text that VoiceOver reads. |

**Remediation — suggested label mapping for `AppTheme.freeColors`:**

| Index | Hex | Suggested Label |
|---|---|---|
| 0 | `#30271B` | Dark brown |
| 1 | `#51422E` | Brown |
| 2 | `#778005` | Olive yellow |
| 3 | `#4D70D8` | Blue |
| 4 | `#293B72` | Navy |
| 5 | `#403873` | Dark purple |
| 6 | `#523554` | Red-purple |
| 7 | `#593C73` | Purple |
| 8 | `#723F73` | Mid purple |
| 9 | `#8A4273` | Magenta-purple |
| 10 | `#865486` | Light magenta |
| 11 | `#DD3B72` | Pink-red |
| 12 | `#DD114A` | Hot pink |
| 13 | `#B70E26` | Deep red |

---

## §4 — Custom NSViewRepresentable: Accessibility Tree Propagation

### FocusedNSTextField (CountdownDetailView.swift)

| Line Range | Severity | Detail |
|---|---|---|
| 28–75+ | ⚠️ Risk | NSTextField has built-in VO support via NSAccessibility protocol. However: (1) No explicit `tf.accessibilityLabel = "Countdown name"` is set — with default field behavior, VoiceOver may announce just "Text Field". (2) Custom first-responder logic can interfere with VO focus synchronization if the editor is active while VO tries to navigate away. |

### MarkdownWebView (SharedEditorComponents.swift)

| Line Range | Severity | Detail |
|---|---|---|
| 17–80+ | ❌ CRITICAL | WKWebView renders HTML/markdown inside a WebKit view. macOS VoiceOver does **not** automatically crawl the DOM content of an embedded `WKWebView`. The rendered markdown is completely invisible to VoiceOver users. There is no `.accessibilityLabel()` bridge, no NSAccessibility attribute injection, and no fallback text-to-speech for web-rendered content. All Notes and Snippet VIEW-mode content reaches VO as an empty placeholder or "Web View" with zero semantic content. |

**Mitigations for MarkdownWebView:**
- Bridge option: after `didFinish` navigation, evaluate JS to extract `document.body.innerText` and set it as `.accessibilityLabel` on the `WKWebView` wrapper (`NSView`) via `setAccessibilityLabel`.
- Structural option: expose a hidden `Text` in SwiftUI that mirrors the raw markdown text; `.accessibilityHidden(false)` on it, `.accessibilityHidden(true)` on the WKWebView wrapper.

### PlainTextEditor (SharedEditorComponents.swift)

| Line Range | Severity | Detail |
|---|---|---|
| 142–205+ | ⚠️ Partial | NSTextView has native NSAccessibility support and text IS exposed via AppKit's internal AX framework. Lower risk than MarkdownWebView. Strengthening options: `tv.accessibilityLabel("Notes editor")` and verify that `tv.isAccessibilityElement() == true` is not overridden. |

---

## §5 — Decorative Images Without `.accessibilityHidden(true)`

| File | Line Range | Element | Finding |
|---|---|---|---|
| `CountdownDetailView.swift` | 189–193 | `Image("spooky_tomato")` — large tomato container image framing the timer display; countdown digits are overlaid on it | ❌ Missing `.accessibilityHidden(true)`. Semantic content (time values) is in the overlay `Text`; the image is decorative. Without it, VO announces the raw asset name "spooky_tomato". |
| `CalculateView.swift` | 158–179+ | Moon phase images: `ForEach(0..<count)` rendering `Image("pink_moon_\(i + 1)")`. Nine decorative illustrations in a U-arc | ❌ Missing `.accessibilityHidden(true)` on all 9. VO announces "pink_moon_1", "pink_moon_2", … — pure decoration. Alternative: if they carry semantic meaning (passage of time), give meaningful labels "New moon", "First quarter", etc. |
| `SunPanel.swift` | 47–53 | `Image("sun")` — decorative sun icon at the top of the popover | ❌ Missing `.accessibilityHidden(true)`. Will be announced as "sun", redundant since section headers already say "MORNING", "EVENING", etc. |
| `SnippetsView.swift` | 107–113 | Empty-state `Image(systemName: "doc.plaintext")` inside a Button with explanatory text | ⚠️ `.accessibilityHidden(true)` on the image; parent Button label covers intent. |
| `SnippetEditSheet.swift` | 188+ | Empty edit state `Image(systemName: "doc.plaintext.fill")` — same pattern | ⚠️ `.accessibilityHidden(true)` to reduce VO noise; parent button text is sufficient. |
| `NotesSheet.swift` | 91+ | Empty notes state `Image(systemName: "note.text.badge.plus")` inside button with text | ⚠️ `.accessibilityHidden(true)` to avoid redundant announcement alongside "No notes yet. Tap to start writing." |

---

## §6 — Dynamic Content Without Sort Priority / Live Region

### CountdownView.swift — TimelineView ticking

| Line Range | Severity | Detail |
|---|---|---|
| 160–201 (`itemList`) | ⚠️ Low–Medium | Every-second `TimelineView` tick updates all countdown rows. macOS SwiftUI has no `.accessibilityLiveRegion()` (iOS-only). VO will not announce new values each second — expected behavior, not a bug. However: no `.accessibilitySortPriority` ensures the timer value is announced before static labels when VO focuses a row. Recommendation: add `.accessibilitySortPriority(1)` on the remaining-time `Text` in `CountdownRowView`. |

### CountdownDetailView.swift — TimelineView ticking

| Line Range | Severity | Detail |
|---|---|---|
| 190–204 (TimelineView + overlay) | ⚠️ Low–Medium | Main detail-screen timer updates every second via `TimelineView`. The overlaid `Text` has no sort priority relative to the label above or steppers below. When VO pans into this region, there is no guarantee which element leads. Add `.accessibilitySortPriority(1)` on the time display content, or group the tomato image + time display with `.accessibilityElement(children: .contain)` and a combined label: `"Countdown timer showing \(item.remainingFormatted(at: now))"`. |

### CalculateView.swift — Result updates

| Line Range | Severity | Detail |
|---|---|---|
| 228–246 (`resultRow`) | ⚠️ Low–Medium | Computed result row updates whenever FROM or TO dates change. No macOS SwiftUI equivalent of `.accessibilityLiveRegion`. VO users won't know the result changed unless they navigate back to it. Suggested mitigation: `.accessibilitySortPriority(1)` on the entire `resultRow` HStack plus `.accessibilityLabel("Calculation result")` on a wrapper to give VO users a clear navigation landmark. |

---

## Summary

| # | Category | Total Findings | Severity |
|---|---|---|---|
| 1 | Missing `.accessibilityLabel` / `.accessibilityHint` | ~28 controls across 9 files | 🔴 HIGH — VoiceOver cannot identify purpose of gesture-only/icon-only targets |
| 2 | Countdown values as non-semantic text | 3 instances (CountdownRowView ×2, CountdownDetailView ×1) | ⚠️ MEDIUM — Values exposed but lack contextual labels and sort priority |
| 3 | Color swatches indistinguishable by VoiceOver | 14 palette buttons all announced as "Button" | 🔴 HIGH — Choice between colors completely opaque to screen reader users |
| 4 | NSViewRepresentable accessibility propagation gaps | 2 (MarkdownWebView: opaque; FocusedNSTextField: unlabeled) | 🔴 CRITICAL for MarkdownWebView — all rendered notes/snippets invisible to VO |
| 5 | Decorative images without `.accessibilityHidden(true)` | ~9 instances across 5 files | ⚠️ MEDIUM — Noise and confusion from raw asset/filename announcements |
| 6 | Dynamic content without sort priority / live region | 3 (CountdownView, CountdownDetailView, CalculateView) | 🟡 LOW–MEDIUM — macOS SwiftUI lacks liveRegion; sortPriority can help reading order |
