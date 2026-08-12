# countdownApp — Documentation Audit Report
# Audit #8: File Headers, Documentation & Hungarian Text

Generated: 2026-08-12 (Session R)
Source: Qwen output converted to GFM + full manual review of all 20 Swift source files,
3 test files, and spec.md.

---

## Summary table

| ID | File | Section | Severity |
|----|------|---------|----------|
| DOC-1-1 | AppTheme.swift | §1 Header stale: "12 options" | Low |
| DOC-1-2 | CountdownItem.swift | §1 `accentColorIndex` doc: "hash-based fallback" | Medium |
| DOC-1-3 | spec.md | §1 "default index 6 / #593C73 purple" | Medium |
| DOC-1-4 | CountdownDetailView.swift | §1 "Reached via NavigationLink" (minor) | Low |
| DOC-2-1 | CalculateView.swift | §2 Header omits sun/moon popover | Low |
| DOC-2-2 | CalculateView.swift | §2 Header omits dual RESET buttons | Low |
| DOC-2-3 | ContentView.swift | §2 Header says two modes, has three | Low |
| DOC-2-4 | ContentView.swift | §2 Header says "icon buttons", renders labeled text | Low |
| DOC-2-5 | countdownAppApp.swift | §2 Header omits SunTimesService wire-up | Low |
| DOC-2-6 | SharedEditorComponents.swift | §2 Header omits font @font-face injection | Low |
| DOC-4-1 | countdownAppTests.swift | §4 Hungarian author/date format | Info |
| DOC-4-2 | countdownAppUITests.swift | §4 Hungarian author/date format | Info |
| DOC-4-3 | countdownAppUITestsLaunchTests.swift | §4 Hungarian author/date format | Info |
| DOC-4-4 | Snippet.swift | §4 "sunikertek" Hungarian example string | Info |
| DOC-5-1 | CountdownItem.swift | §5 Inline: `nil = auto (hash-based fallback)` | Medium |
| DOC-5-2 | ColorPickerSheet.swift | §5 Inline: `resets to hash-based color` | Medium |
| DOC-5-3 | ColorPickerSheet.swift | §5 Inline: `opacity(0.70)` vs actual 0.60 | Low |
| DOC-5-4 | SunTimesService.swift | §5 Header: planned SUN-1-B/C (already done) | Low |
| DOC-5-5 | CountdownRowView.swift | §5 Dead param `var index: Int = 0` | Low |
| DOC-5-6 | spec.md | §5 "Two modes" (now three) | Medium |
| DOC-5-7 | spec.md | §5 "LazyVStack" (replaced by VStack, bug-23B) | Medium |
| DOC-5-8 | spec.md | §5 Moon "horizontal ScrollView" (now HStack arc) | Low |
| DOC-5-9 | spec.md | §5 "Capsule pill" for account label (no Capsule in code) | Low |
| DOC-5-10 | spec.md | §5 Data model: `accentColorIndex` #593C73 (wrong hex) | Medium |
| DOC-5-11 | SharedEditorComponents.swift | §5 Roboto Flex @font-face injected but not used in CSS | Low |
| DOC-5-12 | CountdownDetailView.swift | §5 Sound button opacity ternary is a no-op | Medium |

---

## DOC-1 — Header comments describing outdated or removed functionality

| ID | File | Lines | Quoted text | Issue |
|----|------|-------|-------------|-------|
| DOC-1-1 | AppTheme.swift | 29 | `/// Free-slot card color palette (12 options, rotated by item index)` | Header states 12 options. Actual `freeColors` array has **14 entries** (indices 0–13). The inline hex list also omits indices 10 (`#865486`) and 11 (`#DD3B72`). |
| DOC-1-2 | CountdownItem.swift | ~30 | `/// nil = auto (hash-based fallback). Only meaningful for free (expired) slots.` | No hash-based color computation exists anywhere in the codebase. The actual fallback is **fixed index 6** (`AppTheme.freeColor(for: item.accentColorIndex ?? 6)`). CountdownRowView: `AppTheme.freeColor(for: item.accentColorIndex ?? 6)`. |
| DOC-1-3 | spec.md | ~41, ~80 | `default index 6 / #593C73 purple` | **Index 6 in `AppTheme.freeColors` is `#523554` (dark red-purple)**. The color `#593C73` is at index **7**. Both occurrences in spec.md are wrong. |
| DOC-1-4 | CountdownDetailView.swift | 15 | `// Reached via NavigationLink from CountdownView.` | The navigation mechanism changed to `NavigationLink(value:)` + `.navigationDestination(for:)` (BUG-18 fix). Technically still "reached via NavigationLink", so this is a minor inaccuracy about implementation details rather than a fully stale description. Low severity. |

---

## DOC-2 — Header comments omitting key features added to the file

| ID | File | Lines | Quoted / missing text | Issue |
|----|------|-------|----------------------|-------|
| DOC-2-1 | CalculateView.swift | 4–19 | Header lists "CALC-SAVE" as the last feature | Header omits the **sun/moon popover** (SUN-1-B/C). File contains `@EnvironmentObject SunTimesService`, `showSunPopover` state, `.onHover` trigger on the moon strip, and full `sunPopoverContent` + `fetchTodaySunTimes()` — a substantial subsystem absent from the header. |
| DOC-2-2 | CalculateView.swift | 4–19 | (same header) | Header omits the **dual "RESET FROM NOW" / "RESET TO NOW" buttons**. Both `nowButton(label:)` calls appear, each resetting only its respective FROM or TO date. The spec described a single "NOW" button; implementation diverged to give both fields independent reset controls. |
| DOC-2-3 | ContentView.swift | 4 | `// Root view. Owns the mode switcher (Calculate / Countdown / Snippets).` | The header's first line does mention three modes correctly in the current file. However the sentence `// All mode-specific logic lives in CalculateView and CountdownView.` omits `SnippetsView`. Minor but inconsistent with the mode list above it. |
| DOC-2-4 | ContentView.swift | 7–9 | `// Mode switcher is a custom HStack of icon buttons (NOT the native segmented Picker)` | Header says "icon buttons" with "Placeholder icons". The implementation renders **text labels** (`Text(mode.rawValue)`) inside pill buttons, not icon-only symbols. Icons (`symbolName`) are computed but never rendered in `modeButton()`. |
| DOC-2-5 | countdownAppApp.swift | 4–13 | `// Registers the bundled Alien League font files with CoreText at launch` | Header omits that `SunTimesService` is instantiated as `@StateObject` and injected globally via `.environmentObject(sunService)` on `ContentView`. This is a non-trivial architectural decision not mentioned. |
| DOC-2-6 | SharedEditorComponents.swift | 4–8 | `// MarkdownWebView and PlainTextEditor are used by both NotesSheet … and SnippetEditSheet` | Header omits that the file also contains `mozillaHeadlineFontFaceCSS()` and `robotoFlexFontFaceCSS()`, which load bundled variable `.ttf` font files and inject `@font-face` blocks into every WKWebView page load. |

---

## DOC-3 — Swift files lacking header documentation

All 20 main Swift source files and 3 test target files have multi-line header comments. **No files are missing headers.**

| File | Header present? |
|------|-----------------|
| countdownAppApp.swift | Yes |
| ContentView.swift | Yes |
| CalculateView.swift | Yes |
| CountdownItem.swift | Yes |
| CountdownView.swift | Yes |
| CountdownDetailView.swift | Yes |
| CountdownRowView.swift | Yes |
| AddCountdownSheet.swift | Yes |
| ColorPickerSheet.swift | Yes |
| LongPressStepperButton.swift | Yes |
| AppTheme.swift | Yes |
| SunTimes.swift | Yes |
| SunPanel.swift | Yes |
| SunTimesService.swift | Yes |
| NamedDeadline.swift | Yes |
| NotesSheet.swift | Yes |
| Snippet.swift | Yes |
| SnippetsView.swift | Yes |
| SnippetEditSheet.swift | Yes |
| SharedEditorComponents.swift | Yes |
| countdownAppTests.swift | Yes (Xcode template) |
| countdownAppUITests.swift | Yes (Xcode template) |
| countdownAppUITestsLaunchTests.swift | Yes (Xcode template) |

---

## DOC-4 — Non-English text in identifiers, variable names, or comments

**Verdict: no Hungarian or other non-English identifiers or variable names anywhere in the codebase.**
Non-English content is confined to Xcode-generated author attribution lines (test files only) and one
doc-comment example string. The "Created by Ildikó Kasza" line is present in exactly **3 files** — the
test target files — because the 20 main Swift source files have fully custom headers that omit the
Xcode-generated author line entirely.

| ID | File | Lines | Quoted text | Language | Issue |
|----|------|-------|-------------|----------|-------|
| DOC-4-1 | countdownAppTests.swift | 5 | `//  Created by Ildikó Kasza on 2026. 08. 06..` | Hungarian given name + date punctuation convention | Xcode auto-generated; low severity. |
| DOC-4-2 | countdownAppUITests.swift | 5 | `//  Created by Ildikó Kasza on 2026. 08. 06..` | Hungarian given name + date punctuation convention | Same as above. |
| DOC-4-3 | countdownAppUITestsLaunchTests.swift | 5 | `//  Created by Ildikó Kasza on 2026. 08. 06..` | Hungarian given name + date punctuation convention | Same as above. |
| DOC-4-4 | Snippet.swift | ~15 | `// free-form tag — "countdownApp", "sunikertek", etc.` | Hungarian word `sunikertek` (approx. "solar gardens") | Used only as a doc comment illustration; identifier `project` is English. Low severity. |

Note on `SunTimesService.swift` default coordinates (47.4979, 19.0402): the `// MARK: - Manual coordinates (Budapest default)` comment explicitly names the city in English — not a non-English comment, and the coordinate values are numbers.

---

## DOC-5 — Obsolete inline comments describing deprecated logic or removed code paths

### DOC-5-1 — CountdownItem.swift: `nil = auto (hash-based fallback)`

```swift
/// Manually selected color index into AppTheme.freeColors.
/// nil = auto (hash-based fallback). Only meaningful for free (expired) slots.
var accentColorIndex: Int? = nil
```

**Issue:** The phrase "hash-based fallback" describes a color-selection algorithm that does not exist.
There is no `Hashable`-derived computation anywhere in the codebase. The actual nil fallback
is a **hardcoded index 6**:

```swift
// CountdownRowView.swift
private var itemFreeColor: Color {
    AppTheme.freeColor(for: item.accentColorIndex ?? 6)
}
```

**Fix:** Replace with `nil = auto (index-6 default, #523554 dark red-purple)`.

---

### DOC-5-2 — ColorPickerSheet.swift: `resets to hash-based color`

```swift
// "Auto" swatch — resets to hash-based color
// opacity(0.70): avoids glare on the amber background
swatchButton(color: Color.white.opacity(0.60), index: nil, label: "AUTO")
```

**Issues (two in three lines):**

1. `// "Auto" swatch — resets to hash-based color` — same stale claim as DOC-5-1. No hash is
   computed. Setting `accentColorIndex = nil` causes CountdownRowView to use `?? 6`.

2. `// opacity(0.70)` — the actual code passes `Color.white.opacity(0.60)`, not 0.70. The
   comment and the code are inconsistent.

**Fix:** Replace comment with `// "Auto" swatch — resets to index-6 default; opacity 0.60 to reduce glare on amber`.

---

### DOC-5-3 — SunTimesService.swift: stale issue IDs in planned-feature note

```swift
//  CoreLocation-based auto-detection is planned for a later session (SUN-1-B/C).
```

**Issue:** SUN-1-B (hover-triggered sun popover state) and SUN-1-C (full `SunPanel` popover UI)
are **complete and in production**. The planned-but-unimplemented feature is **SUN-1-E**
(CoreLocation auto-detection, replacing the manual `@AppStorage` lat/lng fields).

**Fix:** `// CoreLocation-based auto-detection is planned (SUN-1-E); current coordinates are manual @AppStorage.`

---

### DOC-5-4 — CountdownRowView.swift: unused `index` parameter

```swift
var index: Int = 0
```

**Issue:** `index` is declared as a stored property with a default of `0` but is **never read
anywhere in the view body**. It does not appear in `rowContent(at:)`, any computed property,
or any method. The property has no documenting comment explaining its intent or whether it
was removed as part of a refactor.

**Fix:** Remove the property, or if it was kept for a future use, add a comment explaining why.

---

### DOC-5-5 — spec.md: "Two modes switched via a custom HStack tab bar"

**Location:** spec.md, App Structure section (~line 2)

```
Two modes switched via a custom HStack tab bar (ContentView):
- Calculate — compute time difference between two dates/times (clock icon)
- Countdown — list of named countdowns with deadlines (@ icon)
```

**Issue:** The app ships a **third mode: Snippets** (`doc.plaintext` symbol, `SnippetsView`).
ContentView.Mode has three cases: `.calculate`, `.countdown`, `.snippets`. The spec was not
updated when SNIPPETS was added (Session C).

---

### DOC-5-6 — spec.md: "ScrollView + LazyVStack"

**Location:** spec.md, Screen A: List section (~line 38)

```
ScrollView + LazyVStack (spacing 10); NOT a native List
```

**Issue:** Bug-23B (2026-08-08) permanently replaced `LazyVStack` with `VStack`.
`LazyVStack` triggered `LazyLayoutViewCache.updateItemPhases()` on scroll, causing a severe
hang via ancestor walk after active↔free reclassification. The fix is permanent and the
`VStack` comment in `CountdownView.swift` confirms it. spec.md was not updated.

**Current code:**

```swift
VStack(spacing: 10) { // 23-B fix: LazyVStack causes LazyLayoutViewCache.updateItemPhases()
                       // scroll-triggered ancestor walk → Severe Hang. VStack is permanent fix.
```

---

### DOC-5-7 — spec.md: moon strip as "horizontal ScrollView"

**Location:** spec.md, Calculate Mode section (~line 21)

```
Moon phase illustration strip at bottom: pink moon series from Assets.xcassets/Moon 3/
(pink_moon_1–pink_moon_9, 9 images), horizontal ScrollView
```

**Issue:** The current implementation uses a **GeometryReader + HStack with computed U-arc
offsets** (no ScrollView):

```swift
GeometryReader { geo in
    let count = 9
    let moonSize = (geo.size.width - CGFloat(count - 1) * 12) / CGFloat(count)
    let arcDepth: CGFloat = 28
    HStack(spacing: 12) {
        ForEach(0..<count, id: \.self) { i in
            let t = CGFloat(i) / CGFloat(count - 1)
            let arcOffset = arcDepth * (4 * t * t - 4 * t)
            Image("pink_moon_\(i + 1)") ...
                .offset(y: -arcOffset)
        }
    }
    .onHover { ... }   // sun popover trigger
}
```

The strip is also an `.onHover` target for the sun popover — a feature not mentioned in the
spec at all.

---

### DOC-5-8 — spec.md: "account label inside dark Capsule pill"

**Location:** spec.md, Screen B: Detail section (~line 59)

```
Account label at top in Alien League Bold, kerned, uppercased, inside dark Capsule pill
```

**Issue:** The current `CountdownDetailView` renders the label as a plain `Text` view
(or `FocusedNSTextField` in edit mode). There is no `Capsule` shape, no pill wrapper,
no background on the label itself — only the outer `HStack` with padding:

```swift
Text(item.label.isEmpty ? "Countdown" : item.label.uppercased())
    .font(AppTheme.alienLeagueBold(24))
    .foregroundStyle(AppTheme.dark.opacity(0.8))
    .kerning(4)
```

---

### DOC-5-9 — spec.md: Data Model `accentColorIndex` wrong hex

**Location:** spec.md, Data Model section (~line 78)

```
accentColorIndex Int? — manual free-slot color override (nil = default index 6 / #593C73)
```

**Issue:** Same as DOC-1-3. Index 6 in `AppTheme.freeColors` is `#523554` (dark red-purple),
not `#593C73`. The color `#593C73` (purple) is at index 7.

---

### DOC-5-10 — SharedEditorComponents.swift: Roboto Flex injected but not in CSS font-family

```swift
let fontFaceCSS = mozillaHeadlineFontFaceCSS() + robotoFlexFontFaceCSS()
```

```css
body {
    font-family: 'Mozilla Headline', 'Helvetica Neue', sans-serif;
    ...
}
```

**Issue:** `robotoFlexFontFaceCSS()` generates a `@font-face` block that is included in every
page load, but `'Roboto Flex'` does not appear in the `body { font-family }` stack or anywhere
else in `markdownCSS`. The @font-face block loads the font file from the bundle at runtime
for a font that CSS never requests. No comment explains whether Roboto Flex is reserved for
future use or is a leftover from an earlier iteration (Session L: Roboto Flex was replaced by
Mozilla Headline as the body font in Session O).

**Fix (documentation):** Add an inline comment: `// robotoFlexFontFaceCSS() retained but not
currently referenced in markdownCSS body font-family; reserved for future use or remove.`

---

### DOC-5-11 — CountdownDetailView.swift: sound button opacity ternary is a no-op

```swift
// ── Sound toggle — all slot types ──────────────────────
Button { item.soundEnabled.toggle() } label: {
    Image(systemName: item.soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
        .foregroundStyle(item.soundEnabled
            ? AppTheme.background : AppTheme.background.opacity(1.0))
        .frame(width: 32, height: 32)
        .background(item.soundEnabled
            ? AppTheme.dark : AppTheme.dark.opacity(1.0))
```

**Issue:** `Color.opacity(1.0)` is identical to the color itself. Both ternary branches
produce the **same visual result** — the button looks identical whether sound is on or off.
The icon (`speaker.wave.2.fill` / `speaker.slash.fill`) changes, but color/background do not.

The same pattern appears on the notes button immediately below:

```swift
.foregroundStyle(item.notes.isEmpty
    ? AppTheme.background.opacity(1.0) : AppTheme.background)
.background(item.notes.isEmpty
    ? AppTheme.dark.opacity(1.0) : AppTheme.dark)
```

**Root cause:** These were likely edited to remove dimming (user preference: "no opacity
dimming — state via icon swap only", Session 36) but the ternary structure was left intact
instead of being simplified to a single constant value. The comments `// SLOT-NOTES` and
`// SOUND-1` in the header still correctly describe the features, but the remaining ternary
code is misleading dead branching.

**Fix:** Replace both ternary pairs with the constant value:

```swift
.foregroundStyle(AppTheme.background)
.background(AppTheme.dark)
```

---

## Notes

- **spec.md is intentionally not kept in sync** with implementation details during rapid
  development. The findings above (DOC-5-5 through DOC-5-9) document divergences but none
  are blocking. A spec update pass is recommended after the audit pipeline completes.
- All DOC-5 findings are documentation/comment issues only; none require logic changes
  except DOC-5-11 (no-op ternary cleanup) and DOC-5-4 (dead parameter removal).
- The "hash-based fallback" description (DOC-1-2, DOC-5-1, DOC-5-2) appears in three
  separate locations and should be corrected together in one pass to avoid confusion
  when reading the freeColors audit (audit #9).
