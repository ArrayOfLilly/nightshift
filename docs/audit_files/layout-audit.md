# countdownApp — Layout Rigidity & Clipping Audit Report

## 1. Fixed frame(width:) / frame(height:) or rigid minWidth/minHeight constraints

---

### 1.0 ContentView.swift — Window minimum width floor (by design, listed for completeness)

| Line | Code | Dimension | Risk |
|------|------|-----------|------|
| ~65 | `.frame(minWidth: 460)` | minWidth: **460pt** | Design-intentional. App contractual minimum window size. |

---

### 1.1 CalculateView.swift — Moon phases HStack with dynamically computed moonSize inside fixed-height GeometryReader

| Line | Code | Dimension | Risk |
|------|------|-----------|------|
| ~129 | `let moonSize = (w - CGFloat(count - 1) * 12) / CGFloat(count)` | Computed, always fits | ✅ Safe — derived from GeometryReader width and spacing:12. At minimum window width 460pt minus horizontal padding (28×2), each moon icon ≈ (404 − 96) / 9 = **32pt**. Functional but tight. |
| ~157 | `.frame(height: 80)` | height: **80pt** fixed | ⚠️ RISK — GeometryReader wrapping the moon phases HStack has fixed height 80pt. With `arcDepth = 28`, some moons offset upward by up to 28pt. At large text scales where icons might get larger, vertical space could be insufficient. Risk is moderate since this area contains only images, no text. |

---

### 1.2 CalculateView.swift — Deadline list popover with clamped width

| Line | Code | Dimension | Risk |
|------|------|-----------|------|
| ~350–361 | `.frame(width: popoverWidth)` + `popoverWidth = min(320, max(220, windowWidth - 48))` | Clamped to **[220, 320pt]** | ✅ Safe — dynamically calculated from window width on each `.onAppear`. |

---

### 1.3 CalculateView.swift — Save sheet fixed-width pattern

| Line | Code | Dimension | Risk |
|------|------|-----------|------|
| ~448 | `.frame(minWidth: sheetWidth, maxWidth: sheetWidth)` | min = max = **sheetWidth** (dynamic) | ✅ Safe — `updateSheetWidth()` clamps to [300, 520] and subtracts 24pt margin. |

---

### 1.4 CalculateView.swift — Deadline detail sheet fixed-width pattern

| Line | Code | Dimension | Risk |
|------|------|-----------|------|
| ~568 | `.frame(minWidth: sheetWidth, maxWidth: sheetWidth)` | min = max = **sheetWidth** (dynamic) | ✅ Safe — same dynamic `updateSheetWidth()` pattern. |

---

### 1.5 CalculateView.swift — Component stepper value text with fixed minWidth

| Line | Code | Dimension | Risk |
|------|------|-----------|------|
| ~243 | `.frame(minWidth: 36)` | minWidth: **36pt** on value Text | ✅ Safe — 36pt is a minimum, allows growth for wider numbers at large text scales. Not rigid. |


---

### 1.6 CountdownDetailView.swift — Tomato image with hard maxWidth/maxHeight cap

| Line | Code | Dimension | Risk |
|------|------|-----------|------|
| ~305–306 | `.frame(maxWidth: 500, maxHeight: 500)` | maxWidth/maxHeight: **500pt** | ✅ Safe — constrains upper bound only. Image scales down freely via `.scaledToFit()`. No clipping risk from this constraint alone. |

---

### 1.7 CountdownDetailView.swift — NSTextField fixed height for label editing

| Line | Code | Dimension | Risk |
|------|------|-----------|------|
| ~72 | `.frame(height: 36)` | height: **36pt** | ⚠️ RISK — `FocusedNSTextField` renders inside an NSViewRepresentable. NSTextField uses font size 36pt. At large Accessibility text scales (200%+), the effective line height could exceed 36pt, causing vertical clipping of the editable text field content. |

---

### 1.8 SunPanel.swift — Popover with rigid minWidth constraint

| Line | Code | Dimension | Risk |
|------|------|-----------|------|
| ~27 | `.frame(minWidth: 360)` | minWidth: **360pt** | 🔴 HIGH RISK — The SunPanel popover has a hard `minWidth: 360` constraint. If the host window is at its minimum 460pt and the popover is triggered near the right edge, a 360pt-wide popover cannot fit in the remaining horizontal space, causing the popover to be clipped or pushed off-screen. SunPanel content has multiple HStack/Spacer layouts that assume at least several hundred points of width. |

---

### 1.9 SunPanel.swift — Sun icon fixed height

| Line | Code | Dimension | Risk |
|------|------|-----------|------|
| ~36 | `.frame(height: 100)` | height: **100pt** on sun icon | ✅ Safe — image-only area, no text. Fixed decorative element. |

---

### 1.10 NotesSheet.swift — Sheet with dynamic width + fixed minHeight

| Line | Code | Dimension | Risk |
|------|------|-----------|------|
| ~59 | `.frame(minWidth: sheetWidth, maxWidth: sheetWidth, minHeight: 520)` | minHeight: **520pt** | ⚠️ MODERATE RISK — `minHeight: 520` is hard-coded for all modes (VIEW and EDIT). On smaller MacBook displays or secondary screens, the sheet can overflow vertically and be partially hidden behind the dock or go off-screen. |

---

### 1.11 SnippetEditSheet.swift — Sheet with dynamic width + fixed minHeight

| Line | Code | Dimension | Risk |
|------|------|-----------|------|
| ~48 | `private var sheetMinHeight: CGFloat { 680 }` | minHeight: **680pt** | 🔴 HIGH RISK — Demands a minimum height of 680pt. At small window sizes or on smaller displays (e.g., MacBook Air 13"), a 680pt sheet may be cut off by the dock or go entirely off-screen. There is no runtime height adjustment. |
| ~125 | `.frame(minWidth: sheetWidth, maxWidth: sheetWidth, minHeight: sheetMinHeight)` | minHeight: **680pt** | 🔴 HIGH RISK — `updateSheetWidth()` handles width dynamically (clamped [450, 900]), but height is a hard 680pt constant. |


---

### 1.12 SnippetEditSheet.swift — ProjectField suggestion popover with fixed minWidth

| Line | Code | Dimension | Risk |
|------|------|-----------|------|
| ~57 | `.frame(width: 36)` on chevron button | width: **36pt** | ✅ Safe — small icon button. |
| ~82 | `.frame(minWidth: 320)` on suggestionList popover | minWidth: **320pt** | ⚠️ MODERATE RISK — Project suggestion dropdown has rigid `minWidth: 320`. Positioned near the top of an already-wide sheet; horizontal overflow is unlikely but possible on edge cases. |

---

### 1.13 AddCountdownSheet.swift — Sheet with dynamic width, no minHeight

| Line | Code | Dimension | Risk |
|------|------|-----------|------|
| ~67 | `.frame(minWidth: sheetWidth, maxWidth: sheetWidth)` | no minHeight | ⚠️ MODERATE RISK (different) — Unlike NotesSheet and SnippetEditSheet, AddCountdownSheet does NOT set `minHeight`. Sheet auto-sizes to content. With long label text or at large text scales, total height could grow beyond what fits on screen. Adaptive but unbounded. |

---

### 1.14 ColorPickerSheet.swift — Sheet with dynamic width + fixed minHeight

| Line | Code | Dimension | Risk |
|------|------|-----------|------|
| ~60 | `.frame(minWidth: sheetWidth, maxWidth: sheetWidth, minHeight: 260)` | minHeight: **260pt** | ✅ Safe — 260pt is a modest minimum. Color grid content fits well within this height even at large text scales since swatches are icon-only circles with minimal text. |

---

### 1.15 ColorPickerSheet.swift — Swatch circle fixed diameter

| Line | Code | Dimension | Risk |
|------|------|-----------|------|
| ~82–83 | `.frame(width: 52, height: 52)` on Circle swatches | 52×52pt | ✅ Safe — icon-only UI element, no text inside. Scales uniformly regardless of text scale settings. |

---

## 2. Missing minimumScaleFactor on primary text labels

---

### 2.0 ContentView.swift — Mode button text

| Line | Code | Font Size | Risk |
|------|------|-----------|------|
| ~73 | `.font(AppTheme.alienLeagueBold(20))` on mode button label | **20pt** | ⚠️ MODERATE RISK — No `minimumScaleFactor` or `lineLimit`. At +200% Accessibility text scale, three buttons ("CALCULATE", "COUNTDOWN", "SNIPPETS") could overflow their allocated HStack space. Parent has `.padding(.horizontal, 16)` but no scrollable or clamping container. |

---

### 2.1 CalculateView.swift — Title text

| Line | Code | Font Size | Risk |
|------|------|-----------|------|
| ~87–89 | `Text("CALCULATE")` → `.font(AppTheme.alienLeagueBold(32))` | **32pt** | ⚠️ MODERATE RISK — No `minimumScaleFactor`. Centered with `maxWidth: .infinity`, room to grow, but at high scales the padded container (horizontal: 28) might produce horizontal scroll within the ScrollView rather than shrinking gracefully. |


---

### 2.2 CalculateView.swift — Result row (has minimumScaleFactor)

| Line | Code | Font Size | Risk |
|------|------|-----------|------|
| ~256–264 | resultRow: quantity at **38pt**, unit at **18pt** | 38pt / 18pt | ✅ Has `.minimumScaleFactor(0.45).lineLimit(1)` — safe for large text scale overflow. |

---

### 2.3 CountdownDetailView.swift — Label display text (non-editing mode)

| Line | Code | Font Size | Risk |
|------|------|-----------|------|
| ~164–167 | `Text(item.label.uppercased())` → `.font(AppTheme.alienLeagueBold(24))` | **24pt** | ⚠️ MODERATE RISK — Has `.lineLimit(1).truncationMode(.tail)` but NO `minimumScaleFactor`. At very large text scales (>150%), label width could exceed available HStack space (also includes a 32pt copy button), causing aggressive truncation to the point of illegibility. |

---

### 2.4 CountdownDetailView.swift — Toggle button text

| Line | Code | Font Size | Risk |
|------|------|-----------|------|
| ~185 | `Text(showRemaining ? "Show Deadline" : "Show Remaining")` → `.font(AppTheme.alienLeague(15))` | **15pt** | ⚠️ MODERATE RISK — No `minimumScaleFactor`, no `lineLimit`. At +200% text scale, button text can expand beyond the padded frame (.horizontal 24), causing the bottom HStack row to grow wider and potentially overflow off-screen on narrow windows. |

---

### 2.5 CountdownRowView.swift — Label in row header

| Line | Code | Font Size | Risk |
|------|------|-----------|------|
| ~30–34 | `Text(...)` → `.font(AppTheme.alienLeague(14))` + `.lineLimit(1)` | **14pt** | ✅ Has `.lineLimit(1)`, label area uses `maxWidth: .infinity`. Truncation is reasonable. No `minimumScaleFactor` so at extreme scales it truncates to ellipsis. |

---

### 2.6 CountdownRowView.swift — Remaining time display

| Line | Code | Font Size | Risk |
|------|------|-----------|------|
| ~57–61 | `Text(item.remainingFormatted(at: now))` → `.font(AppTheme.alienLeagueBold(24))` | **24pt** | ✅ Has `.minimumScaleFactor(0.6).lineLimit(1)` — properly protected. |

---

### 2.7 CountdownRowView.swift — Deadline display (non-remaining mode)

| Line | Code | Font Size | Risk |
|------|------|-----------|------|
| ~64–68 | `Text(item.deadlineFormatted)` → `.font(AppTheme.alienLeague(20))` + `.lineLimit(1)` | **20pt** | ⚠️ MODERATE RISK — Has `.lineLimit(1)` but no `minimumScaleFactor`. Deadline format ("2026.08.10 14:00", ~14 chars) could still clip to ellipsis before the date is readable at +200% Accessibility scale. Consider `.minimumScaleFactor(0.7)`. |

---

### 2.8 NotesSheet.swift — Header title

| Line | Code | Font Size | Risk |
|------|------|-----------|------|
| ~62–66 | `Text("NOTES")` → `.font(AppTheme.alienLeagueBold(24))` + `.kerning(2)` | **24pt** | ✅ Safe — "NOTES" is 5 chars, has `Spacer()` on one side. Will not overflow. |


---

### 2.9 NotesSheet.swift — Empty state placeholder text

| Line | Code | Font Size | Risk |
|------|------|-----------|------|
| ~113–117 | `Text("No notes yet.\nTap to start writing.")` → `.font(AppTheme.alienLeague(13))` | **13pt** | ⚠️ LOW RISK — Multi-line text without `lineLimit`. Could grow taller but is centered in an unbounded area. At +200% scale, two lines might become 3–4 lines visually — cosmetic rather than clipping. |

---

### 2.10 SnippetEditSheet.swift — Title TextField

| Line | Code | Font Size | Risk |
|------|------|-----------|------|
| ~156–158 | `TextField("Title", text: $title)` → `.font(AppTheme.alienLeagueBold(22))` | **22pt** | ✅ Safe — TextField uses `Spacer()` on the right side, gets full available width. macOS TextFields auto-truncate or scroll horizontally. |

---

### 2.11 SnippetsView.swift — Header title

| Line | Code | Font Size | Risk |
|------|------|-----------|------|
| ~86–88 | `Text("SNIPPETS")` → `.font(AppTheme.alienLeagueBold(20))` | **20pt** | ✅ Safe — 8 chars, has `Spacer()`. Not at risk. |

---

### 2.12 SnippetsView.swift — Section header project name

| Line | Code | Font Size | Risk |
|------|------|-----------|------|
| ~136–140 | `Text(project.uppercased())` → `.font(AppTheme.alienLeagueBold(11))` + `.kerning(2)` | **11pt** | ⚠️ LOW RISK — No `lineLimit` but has `Spacer()` on one side. Long project names at large text scales could push the menu button off-screen within the HStack. Cosmetic; no `.fixedSize(horizontal: false)` to prevent growth. |

---

### 2.13 SnippetsView.swift — Row title and body preview

| Line | Code | Font Size | Risk |
|------|------|-----------|------|
| ~184–186 | `Text(snippet.title)` → `.font(AppTheme.alienLeague(14))` + `.lineLimit(1)` | **14pt** | ⚠️ LOW RISK — Has `.lineLimit(1)`. At extreme scales could truncate. No `minimumScaleFactor` but row titles are typically short and have `maxWidth: .infinity`. Truncation behavior is reasonable. |
| ~189–192 | Body preview → `.font(.system(size: 11, design: .monospaced))` + `.lineLimit(2)` | **11pt** | ✅ Safe — Monospace body preview has `.lineLimit(2)`. |

---

### 2.14 AddCountdownSheet.swift — Label TextField section title

| Line | Code | Font Size | Risk |
|------|------|-----------|------|
| ~62–65 | `Text("LABEL")` / `Text("DEADLINE")` → `.font(AppTheme.alienLeagueBold(20))` | **20pt** | ✅ Safe — Short fixed labels, left-aligned VStack. No overflow risk. |

---

### 2.15 AddCountdownSheet.swift — Cancel & Add button labels

| Line | Code | Font Size | Risk |
|------|------|-----------|------|
| ~37–38 | `Button("Cancel")` / `Button("Add")` → `.font(AppTheme.alienLeague(15))` / `.alienLeagueBold(15)` | **15pt** | ✅ Safe — Very short button labels. Buttons auto-size to content width. No overflow risk. |

---

### 2.16 ColorPickerSheet.swift — Title text and "AUTO" label

| Line | Code | Font Size | Risk |
|------|------|-----------|------|
| ~34–37 | `Text("PICK A COLOR")` → `.font(AppTheme.alienLeagueBold(20))` + `.kerning(2)` | **20pt** | ✅ Safe — Centered, short text. |
| ~95–98 | `Text(label)` → `.font(AppTheme.alienLeague(12))` (only "AUTO") | **12pt** | ✅ Safe — Only 4 chars, rendered inside a fixed-width circle. |


---

## 3. ScrollView omissions where content could overflow container at minimum window size

---

### 3.0 ContentView.swift — Mode switcher tabs

| Line | Code | Container | Risk |
|------|------|-----------|------|
| ~52–62 | HStack with ForEach(Mode.allCases) → modeButton(mode) | Not in ScrollView | ✅ Safe — Only 3 fixed tabs. At minimum window width (460pt) buttons will compress without issue. Active content area uses `.frame(maxWidth: .infinity, maxHeight: .infinity)`. |

---

### 3.1 CalculateView.swift — Entire content already in ScrollView

| Line | Code | Container | Risk |
|------|------|-----------|------|
| ~84–176 | `ScrollView { VStack(...) {...} }` wrapping entire CalculateView body | ScrollView ✅ | ✅ All content is scrollable. Moon phases GeometryReader has `.padding(.bottom, 40)` inside the ScrollView so it remains accessible via scrolling. |

---

### 3.2 CountdownDetailView.swift — No ScrollView on main body

| Line | Code | Container | Risk |
|------|------|-----------|------|
| ~156–227 | `VStack(spacing: 0)` wrapping label, Spacer, tomato TimelineView, Spacer, deadlineStepper, HStack buttons | **NO ScrollView** | 🔴 HIGH RISK — CountdownDetailView body is a plain VStack with no ScrollView. **(a)** On narrow or short windows, the tomato image (~500pt max), deadline stepper (~100pt), and bottom buttons row (~60pt) plus header/padding could clip either the top label or bottom buttons on a short window (e.g., 500–600pt tall). **(b)** At large text scales where font sizes increase but the tomato and stepper remain fixed size, bottom button labels ("Show Deadline" / "Show Remaining") expand while layout height stays fixed — content could go off-screen if the window is resized vertically short. |

---

### 3.3 CountdownView.swift — Has ScrollView around item list

| Line | Code | Container | Risk |
|------|------|-----------|------|
| ~186–205 | `ScrollView { VStack(spacing: 10) {...} }` | ScrollView ✅ | ✅ Entire countdown item list is scrollable. "ADD" button is placed outside the ScrollView in the outer VStack — correct UX for an always-visible FAB-equivalent. |

---

### 3.4 NotesSheet.swift — Content area has no internal ScrollView (uses WKWebView / NSScrollView)

| Line | Code | Container | Risk |
|------|------|-----------|------|
| ~102–126 | `contentArea` → PlainTextEditor or MarkdownWebView with `.frame(maxWidth: .infinity, maxHeight: .infinity)` | No SwiftUI ScrollView | ⚠️ MODERATE RISK — VIEW mode: MarkdownWebView has internal scrolling via WKWebView. EDIT mode: PlainTextEditor wraps NSTextView inside NSScrollView (`hasVerticalScroller = true`). Both modes have internal scrolling. However, at large text scales or on small displays where the 520pt minHeight exceeds available vertical screen space, the sheet can be partially cut off by the dock — this is a macOS window sizing limitation, not a SwiftUI layout issue. |

---

### 3.5 SnippetEditSheet.swift — Same as NotesSheet (internal scrolling)

| Line | Code | Container | Risk |
|------|------|-----------|------|
| ~172–196 | `contentArea` → PlainTextEditor or MarkdownWebView with `.frame(maxWidth: .infinity, maxHeight: .infinity)` | No SwiftUI ScrollView | ⚠️ MODERATE RISK — Same architecture as NotesSheet. Both editor/preview modes have internal scrolling via NSViewRepresentable NSScrollView or WKWebView. The 680pt minHeight is the primary concern (see §1.11) rather than missing ScrollView. |

---

### 3.6 AddCountdownSheet.swift — No ScrollView, but content fits

| Line | Code | Container | Risk |
|------|------|-----------|------|
| ~29–59 | VStack with Cancel/Add bar, Label field, Deadline stepper, Spacer | **NO ScrollView** | ⚠️ LOW RISK — Sheet auto-sizes to content height (no minHeight set). At minimum width 380pt and typical content height (~250–300pt), well within any window. The deadlineStepper HStack with 5 columns at minimumScaleFactor could expand horizontally but has `maxWidth: .infinity` distribution. |

---

### 3.7 ColorPickerSheet.swift — No ScrollView, grid content is compact

| Line | Code | Container | Risk |
|------|------|-----------|------|
| ~25–60 | VStack with title bar + LazyVGrid of color swatches | **NO ScrollView** | ✅ Safe — Grid has 4 columns of 52pt circles. Total height under 300pt. With minHeight: 260, sheet comfortably fits its own minimum bounds without scrolling. |

---

### 3.8 SnippetsView.swift — Has ScrollView for snippet list

| Line | Code | Container | Risk |
|------|------|-----------|------|
| ~109–125 | `ScrollView { LazyVStack(alignment: .leading, spacing: 0) {...} }` | ScrollView ✅ | ✅ Empty state uses `maxWidth: .infinity, maxHeight: .infinity`. Populated list is scrollable. Section headers and snippet rows are inside the ScrollView. No overflow risk. |

---

### 3.9 CalculateView.swift — Deadline popover has no ScrollView

| Line | Code | Container | Risk |
|------|------|-----------|------|
| ~281–362 | `deadlineListPopoverContent` → VStack with ForEach over saved deadlines | **NO ScrollView** in popover | ⚠️ MODERATE RISK — "SAVED DEADLINES" popover lists all namedDeadline entries without a ScrollView. If the user saves many deadlines (10+), the popover grows beyond typical popover heights; items near the bottom may become unreachable. Consider wrapping the ForEach in a ScrollView with a vertical height cap. |
