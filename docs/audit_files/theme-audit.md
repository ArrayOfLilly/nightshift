# countdownApp Theme Centralization Audit

**Files Audited:** `AppTheme.swift`, `SharedEditorComponents.swift`, `CountdownDetailView.swift`,
`NotesSheet.swift`, `SnippetEditSheet.swift`, `CalculateView.swift`

---

## 1. Colors: AppTheme.swift vs markdownCSS (SharedEditorComponents.swift)

### 1A. CSS hex values that DUPLICATE AppTheme.swift colors

| File | Line(s) ~ | CSS Value | AppTheme Equivalent | Notes |
|------|-----------|-----------|---------------------|-------|
| `SharedEditorComponents.swift` | ~130 in `markdownCSS` | `background: #060503` | `AppTheme.calculateBackground = Color(red: 0x06/255, green: 0x05/255, blue: 0x03/255)` | Exact match. |
| `SharedEditorComponents.swift` | ~133 in `markdownCSS` | `color: #F5A623` (h1/h2/h3, code, pre, mark, links) | `AppTheme.background = Color(red: 0.898, green: 0.627, blue: 0.125)` → hex ≈ `#E4A020` | Close but NOT identical — CSS is brighter/more orange. Visual mismatch possible. |
| `SharedEditorComponents.swift` | ~134 in `markdownCSS` | `color: rgba(255,255,255,0.85)` | Approximates `AppTheme.timerText = Color.white` at reduced opacity. No direct AppTheme token for white-85%. | — |

---

### 1B. CSS colors that are ORPHANED / hardcoded (not defined in AppTheme)

| File | Line(s) ~ | CSS Value | Used For | Recommendation |
|------|-----------|-----------|----------|----------------|
| `SharedEditorComponents.swift` | ~134 | `color: rgba(255,255,255,0.85)` | Body text color | No AppTheme equivalent for "primary text". Orphaned. |
| `SharedEditorComponents.swift` | ~145 | `background: rgba(255,255,255,0.08)` | `<code>` inline background | Hardcoded white-alpha; no token. |
| `SharedEditorComponents.swift` | ~147 | `background: rgba(255,255,255,0.07)` | `<pre>` block background | Hardcoded white-alpha; no token. |
| `SharedEditorComponents.swift` | ~147 | `border-left: 3px solid #F5A623` | `<pre>` accent border | Duplicate of F5A623 heading color — hardcoded twice in same CSS block. |
| `SharedEditorComponents.swift` | ~149 | `background: none; color: #F5A623` | `pre code` override | Third repetition of F5A623 in CSS. |
| `SharedEditorComponents.swift` | ~150 | `background: rgba(245,166,35,0.35)` | `<mark>` highlight background | Same base as F5A623 with alpha — no token. |
| `SharedEditorComponents.swift` | ~150 | `color: #fff` | `<mark>` text color | Same intent as `timerText` but not connected to it. |
| `SharedEditorComponents.swift` | ~153 | `border: 1px solid rgba(255,255,255,0.18)` | Table borders | Hardcoded white-alpha. |
| `SharedEditorComponents.swift` | ~154 | `background: rgba(255,255,255,0.04)` | Even table row stripe | Hardcoded white-alpha. |

---

### 1C. Gap Analysis Summary

The CSS defines roughly **six opaque + six alpha-blended white** color values that have no representation
in `AppTheme.swift`. There is zero programmatic bridge: the HTML/CSS injected into WKWebView at runtime
cannot read Swift `Color` constants, but a developer-defined token map should exist so values stay
synchronized by convention.

Currently changing `AppTheme.background` (the amber) will **not** propagate to markdown headlines, code
blocks, pre-blocks, link colors, or mark highlights rendered in the web view.

---

## 2. Inline Hardcoded Colors in Swift UI Files (Bypass AppTheme)

### 2A. `CountdownDetailView.swift`

| Line ~ | Code Snippet | Issue |
|--------|-------------|-------|
| 279–280 | `.foregroundStyle(expired ? Color.red : AppTheme.timerText)` | `Color.red` is a SwiftUI system red — completely outside the "Spooky Tomato" palette. No dark theme override possible. |

---

### 2B. `NotesSheet.swift`

| Line ~ | Code Snippet | Issue |
|--------|-------------|-------|
| 50 | `Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1)` | Hardcoded white-0.08 divider; no token. |
| 74 | `.background(Color.white.opacity(0.07))` inside `headerButton` | White-0.07 button bg — no token. |
| 86 | `Rectangle().fill(Color.white.opacity(0.12)).frame(width: 1, height: 22)` | White-0.12 vertical separator — no token. |
| 93 | `tint: copyFeedback ? AppTheme.background : Color.white.opacity(0.7)` | White-0.7 icon tint — no token. |
| 108 | `.foregroundStyle(Color.white.opacity(0.4))` | Hardcoded white-0.4 empty-state icon. |
| 110 | `.foregroundStyle(Color.white.opacity(0.6))` | Hardcoded white-0.6 empty-state placeholder text. |

---

### 2C. `SnippetEditSheet.swift`

| Line ~ | Code Snippet | Issue |
|--------|-------------|-------|
| 45 | `.foregroundStyle(Color.white)` — ProjectField TextField text | Pure white hardcoded. |
| 57 | `.foregroundStyle(Color.white.opacity(0.45))` — chevron icon | Hardcoded white-0.45. |
| 75 | `.background(Color(red: 0x86/255, green: 0x54/255, blue: 0x86/255))` — ProjectField input bg | **Direct hex duplication.** `#865486` exists in `AppTheme.freeColors[10]` but re-encoded as raw RGB. Divergence risk if palette entry changes. |
| 98 | `.background(Color(red: 0x52/255, green: 0x35/255, blue: 0x54/255))` — suggestion popover bg | **Direct hex duplication.** `#523554` exists in `AppTheme.freeColors[6]` but re-encoded. Same divergence risk. |
| 103 | `.fill(Color.white.opacity(0.07))` — divider between items | Hardcoded white-0.07. |
| 121 | `.foregroundStyle(Color.white.opacity(0.85))` — suggestion item text | Same numeric value as `markdownCSS` body text — coincidence or intentional? |
| 164–165 | `Divider().fill(Color.white.opacity(0.08))` | Same white-0.08 as NotesSheet, re-duplicated. |
| 172 | `tint: copyFeedback ? AppTheme.background : Color.white.opacity(0.7)` | White-0.7 duplicate from NotesSheet. |
| 190 | `.background(Color.white.opacity(0.12))` inside `headerButton` | White-0.12 — **inconsistency**: NotesSheet uses 0.07 for the same UI element (header icon button bg). |
| 216 | `.foregroundStyle(Color.white.opacity(0.4))` empty-state icon | Hardcoded white-0.4 — copied pattern from NotesSheet. |
| 218 | `.foregroundStyle(Color.white.opacity(0.6))` empty-state placeholder | Hardcoded white-0.6 — same as NotesSheet. |

---

### 2D. `CalculateView.swift` (Extensive — highest concentration of hardcoded colors)

| Line ~ | Code Snippet | Issue |
|--------|-------------|-------|
| 81–82, 96, 105 | `.foregroundStyle(Color.white.opacity(0.9))` — section header labels | Used in at least 3 places. No token. |
| 108–110 | `.fill(Color.white.opacity(0.25))` — horizontal rule | Heavier than the 0.08/0.12 dividers elsewhere. |
| 161, 174 | `.background(Color.white.opacity(0.12))` — NOW button, stepper card, modeToggle, saveButton | White-0.12 used ~5 times in different roles (button vs card) — no token. |
| 207–208 | `.foregroundStyle(Color.white.opacity(0.6))` — stepper labels (YEAR/MON/DAY/HOUR/MIN) | Hardcoded white-0.6 label tint. |
| 230 | `.foregroundStyle(Color.white.opacity(0.5))` — result unit text suffixes | Hardcoded white-0.5. |
| 288–290 | `Color(red: 0x59/255, green: 0x3C/255, blue: 0x73/255).opacity(0.35)` — calcSaveGradient top | **Hex duplication.** `#593C73` is `AppTheme.freeColors[7]`. Re-encoded with `.opacity(0.35)`. |
| 328–329 | `.foregroundStyle(Color.white.opacity(0.5))` / `.opacity(0.35)` — deadline list items | White-0.5 / white-0.35 hardcoded for opacity differentiation. |
| 373–374 | `.foregroundStyle(Color.white.opacity(0.55))` — save sheet date subtitle | Unique value not seen elsewhere. |
| 401–402 | `.background(Color.white.opacity(0.1))` — TextField bg in save form | White-0.1 for input fields. No token. |
| 422–423 | `.foregroundStyle(Color.white.opacity(0.5)).background(Color.white.opacity(0.07))` — CANCEL button | Two distinct hardcoded alphas on one element. |
| 468–484 | `.background(Color.white.opacity(0.1))`, `(0.08)`, `(0.2)` — deadline detail sheet | Seven more unique white-alpha values in detail sheet alone. |

**Total distinct `Color.white.opacity(X)` values found across all four UI files:**
`0.04`, `0.07`, `0.08`, `0.10`, `0.12`, `0.18`, `0.25`, `0.35`, `0.40`, `0.45`, `0.50`, `0.55`, `0.60`, `0.70`, `0.85`, `0.90`

**Total distinct hardcoded hex RGB constructors outside AppTheme:** 4 (`#865486`, `#523554`, `#F5A623`×3 in CSS only, `#593C73`)

---

## 3. Font Definition Consistency

### 3A. AppTheme.swift — Central Definitions

```swift
static func alienLeague(_ size: CGFloat) -> Font {
    Font.custom("Alien League", size: size)
}

static func alienLeagueBold(_ size: CGFloat) -> Font {
    Font.custom("Alien League Bold", size: size)
}
```

Both use named constant strings. ✓ Correct pattern.

---

### 3B. PostScript Name Inconsistency (CSS vs Swift)

| File | Location | Font String Used | Notes |
|------|----------|-----------------|-------|
| `AppTheme.swift` | `alienLeagueBold()` | `"Alien League Bold"` | Baseline reference. |
| `SharedEditorComponents.swift` | `markdownCSS` h1/h2/h3 (~line 137) | `'AlienLeagueBold', 'Alien League Bold'` | Two fallback names. Second matches AppTheme. First (no space) may fail depending on Info.plist registration. |
| `CountdownDetailView.swift` | ~line 91 (`NSTextField` init) | `"AlienLeagueBold"` (NSFont name param, no space) | If PostScript name is truly `"Alien League Bold"` (with space), this lookup fails silently and falls back to `boldSystemFont(ofSize: 36)`. The fallback on line ~95 masks the bug. |

The string `"AlienLeagueBold"` (no space) appears in at least 2 locations and is a likely mismatch. If Font Book / system registry requires the spaced variant, text in NSTextField and markdown headings silently degrades to system fonts.

---

### 3C. System Fonts Used Without Central Definition

| File | Line ~ | Code Snippet | Issue |
|------|--------|-------------|-------|
| `CountdownDetailView.swift` | ~127–128 | `.font(.system(size: 16, weight: .medium))` — copy button icon | Hardcoded sys font. Not themed. |
| `CountdownDetailView.swift` | ~253–254 | `.font(.system(size: 16))` — sound toggle icon | Same pattern. No central token. |
| `CountdownDetailView.swift` | ~270 | `.font(.system(size: 16))` — notes button icon | Same. |
| `NotesSheet.swift` | ~73–74 | `.font(.system(size: 15, weight: .medium))` — header buttons | Hardcoded. |
| `NotesSheet.swift` | ~105 | `.font(.system(size: 32))` — empty-state icon | Unusually large for SFSymbol. |
| `SnippetEditSheet.swift` | ~92–93 | `.font(.system(size: 15, weight: .medium))` — header buttons | Same as NotesSheet. |
| `SnippetEditSheet.swift` | ~206 | `.font(.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular))` — PlainTextEditor font param | System monospace at default size. Not themed with Mozilla Headline or any custom font. Deliberate (code-like editing) but undocumented. |
| `SnippetEditSheet.swift` | ~214 | `.font(.system(size: 32))` — empty-state icon | Hardcoded 32pt. |
| `CalculateView.swift` | multiple (~178, 200+) | `.font(.system(size: 11, weight: .bold))`, `(9, .bold)`, `(14)`, `(12, .bold)`, etc. | Over a dozen hardcoded system font sizes: 9, 10, 11, 12, 13, 14. No central token or scale system for SFSymbol text. |

---

### 3D. Font Size Scattering — No Central Scale System

All six files specify font sizes as inline `CGFloat` literals to `.font(...)` calls.

| Point Size | Occurrences (File, approximate location) |
|-----------|------------------------------------------|
| 9 | CalculateView save-button chevron icon (~310) |
| 10 | CountdownDetailView componentStepper labels; SnippetEditSheet tag icon; CalculateView date stepper labels |
| 11 | CalculateView popover header, deadline list items |
| 12 | CalculateView LOAD AS TO icon, NOW button icon |
| 13 | Many locations — placeholder text, button labels across all files |
| 14 | CalculateView component stepper value, deadline date strings |
| 15 | Component stepper values (2 locations), result unit text, header buttons |
| 16 | Icon buttons in CountdownDetailView (~3) and sound/notes toggles |
| 18 | Result unit labels in CalculateView |
| 20 | "FROM"/"TO" labels, "Remaining time:" label; alienLeague headers in save sheet |
| 22 | Title TextField in SnippetEditSheet header |
| 24 | Account label (non-edit), NOTES header |
| 32 | Empty-state large icons (NotesSheet, SnippetEditSheet) |
| 36 | FocusedNSTextField label editing size |
| 38 | Result quantity numbers in CalculateView |
| 44 | Deadline display text overlay (~line 291) |
| 56 | Remaining-time display on tomato body (largest font in app) |

---

## 4. Spacing, Padding, and Corner Radii — Decentralized Layout Dimensions

### 4A. Corner Radius Values

| Radius | Where Used | File(s) | Notes |
|--------|-----------|---------|-------|
| `7` | Action icon buttons (32×32 bg) via `.clipShape(RoundedRectangle(cornerRadius: 7))` | `CountdownDetailView` (~5 locations) | **Inconsistency:** DetailView = 7, Sheets = 8 for same category of element. |
| `8` | Header icon buttons (36×36 bg) | `NotesSheet` headerButton, `SnippetEditSheet` headerButton, `CalculateView` NOW/modeToggle/save buttons | Consistent across sheets and calc view; differs from DetailView's 7. |
| `12` | Stepper container cards (outer rounded rect) | `CountdownDetailView` deadlineStepper, `CalculateView` dateStepper | Consistent between the two identical card patterns. |
| `6` | TextField input fields (ProjectField, Save sheet form) | `SnippetEditSheet` ~59, various `CalculateView` form fields | Consistent for text inputs. |

---

### 4B. Padding Values — No Central System

| Value | Usage Pattern | Files |
|-------|-------------|-------|
| `4` (vertical) | resultRow spacing between time units | `CalculateView` |
| `6` | Vertical padding around TextField; horizontal sep margin | `NotesSheet`, `SnippetEditSheet`, `CalculateView` |
| `8` | NOW button vertical, modeToggle/save buttons, componentStepper internal spacing | Multiple |
| `10` | Deadline popover list item padding, TextField internal | `CalculateView`, `SnippetEditSheet` |
| `12` | Button horizontal padding; header bottom margin; empty-state icon-to-text gap | Most files |
| `14` | Header top/bottom margins in snippets form | `SnippetEditSheet` |
| `16` | NOW button horizontal; divider offset; resultRow leading-trailing | All files |
| `20` | Stepper outer card padding; popover list item padding; sheet body top | Multiple |
| `24` | Sectional outer margins on almost every view; window edge margins; header horizontal | Every file, 30+ occurrences |
| `28` | CalculateView main outer section padding; save form body | `CalculateView` only |
| `30` | CalculateView bottom outer | Unique to `CalculateView` |
| `36` | DetailView button row bottom padding | `CountdownDetailView` unique |
| `40` | CSS body bottom padding in `markdownCSS` | `SharedEditorComponents` only |

---

### 4C. Fixed Frame Dimensions — Hardcoded Everywhere

| Dimension | Usage | File(s) |
|-----------|-------|--------|
| Sheet height `520` | NotesSheet fixed content area | `NotesSheet` |
| Sheet height `680` | SnippetEditSheet fixed content area + CalculateView save/detail sheets | `SnippetEditSheet`, `CalculateView` |
| Sheet width range `[450, 900]` | Dynamic width clamped to this band | `NotesSheet`, `SnippetEditSheet` (`CalculateView` uses `[300, 520]` for save sheets) |
| Tomato max `500×500` | Image frame | `CountdownDetailView` |
| Button icon frames: `32×32` | Action icons throughout detail view | `CountdownDetailView` |
| Button icon frames: `36×36` | Action icons throughout sheet headers | `NotesSheet`, `SnippetEditSheet` |
| Button icon frames: `40×38` | Deadline detail load/rename/trash buttons | `CalculateView` only — yet another size variant |
| Divider: `height: 1` | Content separators | Every file |
| Window margin `24` (private let CGFloat) | Sheet sizing constraint | `NotesSheet` (~37), `SnippetEditSheet` (~140), `CalculateView` (~567) — same value hardcoded 3 times independently |

---

### 4D. Spacing Values on HStack/VStack/Layout Containers

| Value | Usage | Files |
|-------|-------|-------|
| `0` | Almost every header, contentArea wrapper, button rows — explicit zero everywhere | Pervasive |
| `4` | ComponentStepper internal VStack; resultRow HStack; SnippetEditSheet ProjectField+tag row | Multiple |
| `6` | Header inner items; NOW button icon-to-text; save-button segments | Multiple |
| `8` | Header action groups; toggle icon-to-text; bottom button group | Multiple |
| `10` | Stepper rows (YEAR/MON/DAY/HOUR/MIN) in both DetailView and CalculateView — identical value, independently typed | Both files |
| `12` | Account label HStack; empty-state icon-to-text; form action buttons | Multiple |
| `16` | Deadline detail action row spacing (LOAD/rename/trash) | `CalculateView` only |
| `20` | Bottom button row major separator | `CountdownDetailView` |
| `24` | Main content sections in CalculateView outer VStack | `CalculateView` only |

---

## 5. Impact of Theme Changes — Every Location Requiring Manual Update

### 5A. If `AppTheme.background` (amber) changes

**Direct references — auto-update:**
- `CountdownDetailView.swift` — all button bg (dark) + fg style for toggle labels, timer text non-expired state
- `SnippetEditSheet.swift` — header button tint on copy feedback; save form TextField
- `CalculateView.swift` — "CALCULATE" title, NOW buttons, stepper values, result qty, modeToggle, saveButton, deadline list remaining text
- `NotesSheet.swift` — no direct `.background` references (uses white-alpha for content styling)

**Locations that WON'T auto-update:**

| File | What Contains the Amber | How It's Defined | Lines ~ |
|------|------------------------|-----------------|---------|
| `SharedEditorComponents.swift → markdownCSS` | h1/h2/h3 headings, code inline & block, links, pre border-left, mark highlight | `#F5A623` (CSS hex) | Multiple within CSS string literal (~136–150) |
| All files | Any element intended to match "amber" but defined as `Color.white.opacity(X)` rather than a direct token — the overall UI reads amber-dominant through layering, but individual highlights will NOT shift if background color changes hue | `Color.white.opacity(0.5–0.9)` patterns | Pervasive — 40+ locations |

---

### 5B. If `AppTheme.dark` changes

**Direct references — auto-update:**
- `CountdownDetailView` — label text (opacity-modified), all button backgrounds, card surface overlay
- `NotesSheet` — "NOTES" header title foregroundStyle; copy-button tint when not feedbacking
- `SnippetEditSheet` — Title TextField text; tag icon tint at opacity 0.55
- `CalculateView` — zero direct references (uses `calculateBackground` and white-alphas instead)

**Manual updates needed:**

| File | Issue | Lines ~ |
|------|-------|---------|
| `SharedEditorComponents.swift → PlainTextEditor` | `.foregroundColor: NSColor(AppTheme.background)` used as *selected text foreground* — selection highlight tint is amber, NOT dark. If dark changes and amber stays, or vice versa, selection styling may appear wrong-color in edit mode. Likely intentional (amber-on-dark selection) but a semantic mislabeling risk. | ~165–167 |

---

### 5C. If `AppTheme.calculateBackground` (#060503) changes

**Direct references — auto-update:**
- `CalculateView.swift` — root background `.ignoresSafeArea()`
- `NotesSheet.swift` — PlainTextEditor content area background in edit mode
- `SnippetEditSheet.swift` — same pattern as NotesSheet
- `CalculateView.swift` — `calcSaveGradient` bottom stop uses the token directly ✓

**Manual updates needed:**

| File | Issue | Lines ~ |
|------|-------|---------|
| `SharedEditorComponents.swift → markdownCSS` | CSS `body { background: #060503; }` must be updated manually. Zero programmatic link. Markdown rendered in WKWebView will show old dark after theme change until CSS string is edited. | ~128 |

---

### 5D. If any entry in `AppTheme.freeColors` changes (e.g., index 7 `#593C73`)

| File | Issue | Lines ~ |
|------|-------|---------|
| `SnippetEditSheet.swift` — ProjectField background | `Color(red: 0x86/255, green: 0x54/255, blue: 0x86/255)` duplicates `freeColors[10]` as hardcoded RGB | ~75 |
| `SnippetEditSheet.swift` — suggestion popover background | `Color(red: 0x52/255, green: 0x35/255, blue: 0x54/255)` duplicates `freeColors[6]` as hardcoded RGB | ~98 |
| `CalculateView.swift` — calcSaveGradient top color | `Color(red: 0x59/255, green: 0x3C/255, blue: 0x73/255).opacity(0.35)` duplicates `freeColors[7]` as hardcoded RGB + opacity modifier | ~288 |

No programmatic reference from these three locations to the `freeColors` array. A palette swap requires finding and updating all four files (AppTheme + 3 UI files) manually.

---

### 5E. Summary of Manual-Touch Points by Theme Constant

| What Changes | Auto-Updates | Needs Manual Update | Files to Touch Manually |
|-------------|-------------|---------------------|------------------------|
| `AppTheme.background` (amber) | ~20 `.foregroundStyle`/`.background` calls | `markdownCSS` (~5 hex refs); 40+ `Color.white.opacity(X)` calls that create amber-feeling through layering | `SharedEditorComponents.swift`; all four UI files for opacity values |
| `AppTheme.dark` (brown) | ~12 calls | PlainTextEditor selection tint semantic risk | None required if dark is used correctly; review PlainTextEditor selection logic |
| `AppTheme.calculateBackground` (#060503) | 3 files (ignoresSafeArea + edit mode bg + gradient bottom) | markdownCSS body background (1 CSS line) | `SharedEditorComponents.swift` (~128) |
| `AppTheme.freeColors` array entries | Slot rotation logic; `ColorPickerSheet` | ProjectField bg, popover bg, calcSaveGradient top — all re-encoded as raw RGB | `SnippetEditSheet.swift` (×2); `CalculateView.swift` (×1) |
