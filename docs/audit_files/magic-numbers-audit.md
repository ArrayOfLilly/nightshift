# Magic Numbers, Strings & Constants Audit — countdownApp

**Scope:** AppTheme.swift, CountdownView.swift, CountdownDetailView.swift, CalculateView.swift,
NotesSheet.swift, SnippetEditSheet.swift, SharedEditorComponents.swift, AddCountdownSheet.swift,
ColorPickerSheet.swift, SnippetsView.swift, SunPanel.swift.

---

## §1 — Repeated Numeric Layout Literals

### 1A — Corner Radii (26 instances, 7 files)

| Value | Count | Files & Lines |
|---|---|---|
| `cornerRadius: 8` | 14 | NotesSheet:94, SnippetEditSheet:223, CountdownView:258, CalculateView:166/280/338/443/457/471/525/540, AddCountdownSheet:36/57 |
| `cornerRadius: 7` | 7 | CountdownDetailView:206/255/270/292/309/323 (×6), SnippetsView:104 |
| `cornerRadius: 12` | 3 | CountdownDetailView:381, CalculateView:211, AddCountdownSheet:125 |
| `cornerRadius: 6` | 2 | SnippetEditSheet:63, SnippetsView:236 |
| `cornerRadius: 5` | 2 | AddCountdownSheet:145/160 (stepper chevron buttons) |

Pattern: radius-8 = action button default; radius-7 = icon-button grid (CountdownDetailView); radius-12 = stepper container.

---

### 1B — Opacity Levels

| Value | Count | Primary Use | Files |
|---|---|---|---|
| `0.04` | 1 | Alternating table row bg (CSS only) | SharedEditorComponents |
| `0.07` | 4 | Faintest button bg | NotesSheet:94, SnippetEditSheet:84, CalculateView:456, SnippetsView:103 |
| `0.08` | 9 | Thin divider lines | NotesSheet:43, SnippetEditSheet:147, CalculateView:369/398/431/505, SunPanel:240/246 |
| `0.12` | 11 | Button surface bg / stepper container | NotesSheet:84, SnippetEditSheet:195/222, CalculateView:165/210/229/240/279/337, CountdownDetailView:381, AddCountdownSheet:35 |
| `0.18` | 2 | Table border (CSS) + selectedTextAttributes (PlainTextEditor) | SharedEditorComponents |
| `0.25` | 1 | Divider (CalculateView only) | CalculateView:91 |
| `0.3` | 1 | Divider dimming | SnippetsView |
| `0.35` | 4 | Selection highlight / shadow | CountdownDetailView:160, ColorPickerSheet:70, SnippetsView:124/211, SunPanel |
| `0.5` | 8+ | Dimmed label text | CalculateView:259/363, SunPanel:192/201/214/228 |
| `0.55` | 2 | Subtitle text | CalculateView:425/499 |
| `0.6` | 4 | Stepper label text | CountdownDetailView:376, CalculateView:222, NotesSheet/SnippetEditSheet empty-state |
| `0.7` | 3 | Header button default tint | NotesSheet:75/94, SnippetEditSheet:184, SnippetsView:101 |
| `0.85` | 3 | Secondary text | CountdownDetailView:199, ColorPickerSheet:70, SnippetEditSheet:75 |
| `0.9` | 4 | Primary body text | CalculateView:70/81/97, SnippetsView:206 |

**Divergence flag:** `headerButton` bg opacity differs between NotesSheet (`0.07`) and SnippetEditSheet (`0.12`) — copy-paste mutation, should be unified.

---

### 1C — Font Sizes

| Size | Count | Where Used | Files |
|---|---|---|---|
| `56` | 1 | EXPIRED value display | CountdownDetailView:389 |
| `44` | 1 | Deadline display | CountdownDetailView:398 |
| `38` | 2 | Result quantity | CalculateView:269 |
| `36` | 4 | FocusedNSTextField font | CountdownDetailView:74/75/76 |
| `32` | 5 | Section title text | CountdownView:167, CalculateView:80, ColorPickerSheet, SnippetsView |
| `24` | 3 | Subtitle / detail header | NotesSheet:63, CountdownDetailView:195 |
| `22` | 1 | SnippetEditSheet title TextField | SnippetEditSheet:163 |
| `20` | 5 | Section header / label text | CalculateView:74/85/97, AddCountdownSheet:63/75, ColorPickerSheet:38, SnippetsView:92 |
| `18` | 1 | Result unit label | CalculateView:275 |
| `15` | 10+ | Body-level UI text (buttons, stepper values) | CountdownDetailView, CalculateView:161/226/287/333/387/444, AddCountdownSheet:34/140, NotesSheet, SnippetEditSheet |
| `14` | 6+ | Markdown body text (CSS), SnippetsView preview | SharedEditorComponents CSS, SnippetsView |
| `13` | 8+ | Small labels / secondary buttons | CalculateView:159/291/331/418/453/468, SunPanel:206, NotesSheet, SnippetEditSheet |
| `12` | 7+ | Captions, CSS code font | SharedEditorComponents CSS, CalculateView:142, ColorPickerSheet:82 |
| `11` | 5+ | Section headers, popover text | SunPanel, CalculateView, SnippetsView, AddCountdownSheet |
| `10` | 4 | componentStepper label (YEAR/MON/DAY/HOUR/MIN) | CountdownDetailView:376, CalculateView:222, AddCountdownSheet:133 |

**Critical:** Size `15` is the most duplicated (10+ instances across 6 files). Size `10` appears in three
separate `componentStepper` implementations with zero shared abstraction.

---

### 1D — Frame Width/Height 32 (icon button size)

`.frame(width: 32, height: 32)` — 8+ instances: CountdownDetailView:197/268/290/292/305/321, SnippetsView:104.
Every icon button in CountdownDetailView's bottom bar uses the identical 32×32 frame with no named constant.

---

### 1E — Padding `.horizontal, 24`

`.padding(.horizontal, 24)` — 6+ instances: NotesSheet:45/80, SnippetEditSheet:132/197,
CountdownDetailView:78/210, AddCountdownSheet:70. Primary content margin for sheets and detail views.

---

## §2 — Hardcoded Color Literals Outside AppTheme

### 2A — Purple #593C73 Gradient Start Color (3× including AppTheme)

| File | Line | Code | Notes |
|---|---|---|---|
| AppTheme.swift | ~28 | `Color(red: 0x59/255, green: 0x3C/255, blue: 0x73/255)` | Only legitimate definition (freeColors[7]) |
| CalculateView.swift | 348 | same RGB `.opacity(0.35)` in `calcSaveGradient` | Standalone duplicate of freeColors[7] |
| SunPanel.swift | 37 | same RGB `.opacity(0.35)` in body gradient | Identical to CalculateView duplicate |

Both non-AppTheme uses are for the shared calc-save/sun-times gradient. Should reference `AppTheme.freeColors[7]`
directly — currently a palette change requires editing 3 files.

---

### 2B — SnippetEditSheet ProjectField Colors (hardcoded RGB)

| Line | Code | Hex | Already in freeColors? |
|---|---|---|---|
| 62 | `Color(red: 0x86/255, green: 0x54/255, blue: 0x86/255)` | #865486 | ✅ freeColors[10] |
| 89 | `Color(red: 0x52/255, green: 0x35/255, blue: 0x54/255)` | #523554 | ✅ freeColors[6] |

Both are re-encoded inline as RGB instead of referencing the palette. Should use `AppTheme.freeColors[10/6]`
or dedicated named AppTheme constants (`projectFieldBackground`, `suggestionListBackground`).

---

### 2C — Amber Color Mismatch: CSS vs AppTheme

`AppTheme.background` is `Color(red: 0.898, green: 0.627, blue: 0.125)` ≈ **#E5A020**.
`markdownCSS` uses **#F5A623** throughout (6 instances) — a slightly different amber.
If the reference design uses #F5A623 as the canonical amber, AppTheme.background is off by ~16 points
on the red channel. These need to be reconciled. See §5A for the full CSS color analysis.

---

## §3 — Hardcoded Font Name Strings Outside AppTheme

| String | File | Lines | Context |
|---|---|---|---|
| `"AlienLeagueBold"` | CountdownDetailView.swift | 74 | `NSFont(name:)` — AppKit necessity, no SwiftUI bridge |
| `"Alien League Bold"` | CountdownDetailView.swift | 75 | Fallback name for same font |
| `'AlienLeagueBold'`, `'Alien League Bold'` | SharedEditorComponents (CSS) | 143 | h1/h2/h3 font-family |
| `'Mozilla Headline'` | SharedEditorComponents (CSS) | 93, 137 | @font-face definition + body font-family |
| `'Roboto Flex'` | SharedEditorComponents (CSS) | 110 | @font-face definition |
| `'Menlo'`, `'Monaco'`, `'Courier New'` | SharedEditorComponents (CSS) | 150, 153 | `code` and `pre code` rules — **duplicated** |
| `'Helvetica Neue'` | SharedEditorComponents (CSS) | 137 | body font-family fallback |

The `NSFont(name:)` usage in CountdownDetailView is an AppKit necessity (SwiftUI `Font.custom` doesn't bridge
to `NSFont`). However, PostScript name strings could be centralized as `AppTheme.alienLeagueBoldPSName` static
strings. The CSS monospace font stack appears **twice** (`code` and `pre code`) — a named CSS custom property
or Swift string interpolation would eliminate the duplication.

---

## §4 — UserDefaults Key Strings

| Key String | File | Lines | Centralized? |
|---|---|---|---|
| `"countdownItems"` | CountdownView.swift | 63 | ✅ `let storageKey` local constant |
| `"freeSlotOrder"` | CountdownView.swift | 64 | ✅ `let freeOrderKey` local constant |
| `"calculateFromDate"` | CalculateView.swift | 27 | ❌ inline `@AppStorage` string |
| `"calculateToDate"` | CalculateView.swift | 28 | ❌ inline `@AppStorage` string |
| `"calculateDisplayMode"` | CalculateView.swift | 29 | ❌ inline `@AppStorage` string |
| `"namedDeadlines"` | CalculateView.swift | 554, 562 | ❌ inline string, used twice |
| `"snippets"` | Snippet.swift | 25 | ✅ `static let storageKey` |

Three `@AppStorage` keys and one `forKey:` string in CalculateView are bare string literals.
A shared `StorageKeys` enum would prevent typo-driven data corruption and enable compile-time verification.

---

## §5 — markdownCSS: Hardcoded Values in SharedEditorComponents.swift

`markdownCSS` is a global `let` string (~line 132). Being a non-computed constant it cannot reference Swift
values — all theme values are re-stated as raw CSS literals, fully disconnected from AppTheme.

### 5A — Hex Colors in CSS (6 hex + 1 rgba amber)

| CSS Value | Lines | What It Styles | AppTheme Equivalent |
|---|---|---|---|
| `#060503` | 134 | body background | ≈ AppTheme.calculateBackground — verify exact hex |
| `#F5A623` | 142 | h1/h2/h3 color | ≈ AppTheme.background amber — but ~16 pt off (#E5A020 vs #F5A623), see §2C |
| `#F5A623` | 150 | inline code text | same |
| `#F5A623` | 151 | pre block left border | same |
| `#F5A623` | 153 | pre code text | same |
| `rgba(245,166,35,0.35)` | 154 | mark highlight background | same amber in RGBA form — inconsistent with hex form above |
| `#F5A623` | 158 | link text | same |

**⚠ Critical:** `#F5A623` appears 6× but does not exactly match `AppTheme.background`. Convert `markdownCSS`
to a computed property or function that interpolates `AppTheme.amberHex: String`.

---

### 5B — rgba() White/Amber Opacity Tints in CSS (6 instances)

| CSS Value | Line | Use Case | Parallel in SwiftUI? |
|---|---|---|---|
| `rgba(255,255,255,0.85)` | 135 | body text color | — |
| `rgba(255,255,255,0.08)` | 150 | inline code background | ✅ mirrors `Color.white.opacity(0.08)` dividers |
| `rgba(255,255,255,0.07)` | 151 | pre block background | ✅ mirrors `Color.white.opacity(0.07)` button bg |
| `rgba(245,166,35,0.35)` | 154 | mark highlight background | amber tint — see §5A |
| `rgba(255,255,255,0.18)` | 156 | th/td border | same value in PlainTextEditor `selectedTextAttributes` |
| `rgba(255,255,255,0.04)` | 157 | alternating row background | — |

The `0.08`/`0.07` CSS opacities mirror identical SwiftUI `Color.white.opacity()` values used in the rest of
the codebase — same design language, zero connection.

---

### 5C — CSS Pixel/Unit Values (complete listing)

| Value | Where | Purpose |
|---|---|---|
| `14px` | body | font-size |
| `1.65` | body | line-height |
| `20px 24px 40px` | body | padding (top / horizontal / bottom) |
| `1.2em` | h1/h2/h3 | margin-top |
| `0.4em` | h1/h2/h3 | margin-bottom |
| `1px` | h1/h2/h3 | letter-spacing |
| `20px` | h1 | font-size |
| `16px` | h2 | font-size |
| `14px` | h3 | font-size (same value as body — semantically different) |
| `0.8em` | p | margin-bottom |
| `1.4em` | ul, ol | padding-left |
| `0.8em` | ul, ol | margin-bottom |
| `0.2em` | li | margin-bottom |
| `4px` | code | border-radius |
| `1px 5px` | code | padding |
| `12px` | code | font-size |
| `3px` | pre | border-left width |
| `6px` | pre | border-radius |
| `12px 14px` | pre | padding |
| `0.9em` | pre | margin-bottom |
| `3px` | mark | border-radius |
| `0 3px` | mark | padding |
| `1px` | th, td | border width |
| `6px 10px` | th, td | padding |
| `0.9em` | table | margin-bottom |

No CSS custom properties (`--var`) are used anywhere. Any typography or spacing change requires editing the
raw string literal.

---

### 5D — Font Filename Strings (bundle resource lookups)

| String | Lines | Note |
|---|---|---|
| `"MozillaHeadline-VariableFont_wdth,wght.ttf"` | 90 | `mozillaHeadlineFontFaceCSS()` |
| `"RobotoFlex-VariableFont_GRAD,XOPQ,XTRA,YOPQ,YTAS,YTDE,YTFI,YTLC,YTUC,opsz,slnt,wdth,wght.ttf"` | 107 | `robotoFlexFontFaceCSS()` — 90+ char string, typo = silent empty CSS |

---

### 5E — PlainTextEditor Magic Numbers [extended analysis — Qwen did not cover]

| Value | Location | Context |
|---|---|---|
| `lineSpacing: CGFloat = 0` | PlainTextEditor parameter default | Silent "no spacing" default — both call sites pass `5`, making `0` a dead default |
| `NSColor.white.withAlphaComponent(0.18)` | `selectedTextAttributes` in `makeNSView` | Same `0.18` as CSS `th/td` border — coincidence or shared design token? |
| `lineFragmentPadding = 0` | `makeNSView` | Intentional zero-inset, but undocumented |

`lineSpacing: CGFloat = 0` — both callers (NotesSheet, SnippetEditSheet) explicitly pass `lineSpacing: 5`.
The default `0` is never used in practice; a named `PlainTextEditorDefaults.lineSpacing: CGFloat = 5` constant
would document intent and eliminate the literal `5` at both call sites.

---

## §6 — System Sound Name "Funk"

| Location | Line | Form | Runtime? |
|---|---|---|---|
| CountdownView.swift | 31 | `NSSound(named: "Funk")` — comment | No |
| CountdownView.swift | 152 | `NSSound(named: "Funk")` — comment | No |
| CountdownView.swift | 162 | `NSSound(named: "Funk")?.play()` | **Yes** |

One runtime string literal. A `CountdownSounds.expiry = "Funk"` constant would prevent typos and make the
sound choice discoverable.

---

## §7 — Aggregate Severity Ranking

| Category | Total Instances | Files Affected | Highest-Risk Value | Priority |
|---|---|---|---|---|
| Corner radius (all values) | 26 | 7 | `cornerRadius: 8` (14×) | Medium |
| Opacity 0.07–0.12 range (dividers/btn bg) | 35+ | 7 | `opacity(0.12)` and `0.08` | Medium |
| Font size 15 | 10+ | 6+ | `.alienLeague(15)` | Medium |
| `headerButton` bg divergence (0.07 vs 0.12) | 2 | 2 | NotesSheet vs SnippetEditSheet | **High** |
| Amber hex #F5A623 in CSS vs AppTheme | 6 | 1 | `markdownCSS` — disconnected from SwiftUI theme | **High** |
| `#060503` vs AppTheme.calculateBackground | 1 | 1 | body background — unverified match | High |
| Purple #593C73 RGB literal | 3 (incl. AppTheme) | 3 | gradient start color | High |
| SnippetEditSheet ProjectField colors | 2 | 1 | freeColors[10/6] re-encoded as RGB | Medium |
| UserDefaults key strings | 4 inline | 2 | CalculateView `@AppStorage` keys | **High** |
| componentStepper font 10pt (3 separate impls) | 4 | 3 | No shared abstraction | High |
| System sound name "Funk" | 1 runtime | 1 | expiry notification | Low |
| CSS pixel/unit values (no CSS vars) | 25+ | 1 | Full typography system unconnected | Medium |
| CSS monospace font stack duplicated | 2 | 1 | `code` + `pre code` rules | Low |
| Font filename strings (typo risk) | 2 | 1 | 90-char Roboto Flex filename | Low |
| `lineSpacing: CGFloat = 0` dead default | 1 | 1 | PlainTextEditor | Low |

**Top 5 centralization targets by effort/savings ratio:**

1. **Opacity tier constants** (`dividerTint = 0.08`, `buttonBgTint = 0.12`) — eliminates 35+ duplicates across 7 files
2. **`cornerRadius: 8` → `AppTheme.buttonRadius`** — eliminates 14 magic numbers
3. **CSS amber → `AppTheme.amberHex` interpolation** — fixes theme disconnect, `markdownCSS` becomes computed property
4. **Purple gradient → `AppTheme.freeColors[7]`** — synchronizes palette across 3 files
5. **`StorageKeys` enum** — prevents typo-driven UserDefaults data corruption in CalculateView

---

## §8 — Post-fix magic numbers (BUG-1: Saved Deadlines remaining time)

### 8A — Unit suffix string literals in `deadlineRemainingString(for:)`

| Literal | Context | Named constant? |
|---|---|---|
| `"Y"` | year suffix in compact display | ❌ |
| `"MO"` | month suffix | ❌ |
| `"D"` | day suffix | ❌ |
| `"H"` | hour suffix | ❌ |
| `"M"` | minute suffix | ❌ |
| `"EXPIRED"` | past-deadline sentinel string | ❌ |
| `"< 1M"` | sub-minute edge-case display string | ❌ |

7 new string literals, none named. Note: these unit suffixes differ from the stepper label strings
(`"YEAR"`, `"MON"`, `"DAY"`, `"HOUR"`, `"MIN"`) — they are display-only abbreviations for the popover row.
A `DeadlineDisplayUnits` enum or `NamedDeadline` static strings would centralize them.

---

### 8B — New magic number: `spacing: 2`

`VStack(alignment: .trailing, spacing: 2)` in the updated popover row — micro-spacing value not previously
in the codebase. The existing codebase uses `spacing: 4`, `6`, `8`, `10`, `12`, `16`, `20`, `24` but not `2`.
New category, single instance. Low priority, but worth a named constant if more 2pt gaps appear.

---

### 8C — New instances of existing documented categories

| Category | Existing §ref | New instance location | Net count delta |
|---|---|---|---|
| `opacity(0.35)` | §1F | `Color.white.opacity(0.35)` — expired deadline foreground in popover row | +1 |
| Font size `11` | §1C | `.font(AppTheme.alienLeague(11))` — date subtitle in popover row VStack | +1 |


---

## §9 — Post-fix findings — Session P: Deadline Rename + Popover Width (CalculateView.swift)

### 9A — New magic numbers: popover width bounds

`deadlineListPopoverContent` previously used `.frame(minWidth: 320)` with no upper bound.
The fix introduces two new literals:

| Literal | Location | Prior codebase presence |
|---|---|---|
| `minWidth: 260` | `deadlineListPopoverContent .frame(…)` | ❌ New value |
| `maxWidth: 340` | `deadlineListPopoverContent .frame(…)` | ❌ New value |

Neither `260` nor `340` appears elsewhere. The original `320` was already undocumented (§8 context).
All three are magic numbers; a named constant (e.g. `deadlinePopoverWidth`) would centralize the
range. For now, three distinct undocumented literals control the popover width.

---

### 9B — New magic number: TextField vertical padding `6`

The rename `TextField` in `deadlineDetailContent` uses `.padding(.vertical, 6)`:

```swift
TextField("Name...", text: $renameDraft)
    .padding(.horizontal, 14)
    .padding(.vertical, 6)
```

`.padding(.vertical, 6)` does not appear elsewhere in the codebase (existing vertical paddings:
`8`, `10`, `12`, `14`, `20`, `24`, `28`). The `.horizontal, 14` matches `saveSheetContent`'s
TextField padding — the vertical divergence (`6` vs `10` in the save sheet) is a likely
copy-paste inconsistency rather than a deliberate choice.

**Recommended fix:** change `.padding(.vertical, 6)` → `.padding(.vertical, 10)` to match
`saveSheetContent` TextField styling.

---

### 9C — No new instances of undocumented categories

All other literals in the rename UI (`cornerRadius: 8`, `spacing: 12/16`, `padding .horizontal 16/28`,
`padding .vertical 8/24`, `opacity 0.07/0.1/0.5`) are already documented in §1–§7.


---

## §10 — Post-fix findings — Session P (cont.): X dismiss + dynamic popover width (CalculateView.swift)

### 10A — New magic numbers: popover width calculation literals

`.onAppear` width clamp in `deadlineListPopoverContent`:

| Literal | Role | Prior codebase presence |
|---|---|---|
| `280` | `popoverWidth` initial value | ❌ New |
| `220` | clamp floor | ❌ New |
| `320` | clamp ceiling | Previously `minWidth: 320` on same view — repurposed |
| `48` | window margin for popover | ❌ New — sheets use named `windowMargin = 24`; popover doubles it inline |
| `600` | fallback window width | ❌ New — sheets use `900` as fallback |

The `48` margin is particularly notable: it is exactly `2 × windowMargin` (the named constant
in `NotesSheet` / `SnippetEditSheet`) but appears as a raw literal. If the popover intentionally
needs a larger margin than sheets, a named `popoverMargin` constant would document the intent.
As written, the relationship to `windowMargin = 24` is invisible.

---

### 10B — New magic numbers: X dismiss button styling

| Literal | Location | Prior codebase presence |
|---|---|---|
| `size: 11` | `Image(systemName: "xmark").font(.system(size: 11, …))` | ❌ New — existing icon sizes: 9, 12, 14, 15, 16 |
| `width: 26, height: 26` | dismiss button frame | ❌ New — existing frames: 20, 28, 32, 36, 40, 44 |
| `cornerRadius: 6` | button clip shape | ✅ Documented §1A (SnippetEditSheet, SnippetsView) |
| `.top, 12` | overlay padding | ✅ Existing value |
| `.trailing, 14` | overlay padding | ⚠️ Appears once as leading padding on SAVE button; first trailing-only use |

`size: 11` and `26×26` are new categories. If the intent is a "compact dismiss" button
smaller than the standard `36×36 headerButton`, a named size constant
(e.g. `compactDismissButtonSize: CGFloat = 26`) would make the decision explicit.

---

## §11 — Post-fix findings — Session P (BUG-WIDTH-CALC / BUG-WIDTH-COLOR / BUG-WIDTH-ADD / BUG-DELETE-CONFIRM / BUG-COLOR-NODISMISS)

### 11A — Új magic numbers: sheet width clamp értékek (5 fájl)

| Literal | File | Forma | Prior codebase presence |
|---|---|---|---|
| `300` clamp floor | `CalculateView.swift` `updateSheetWidth()` | named method | ❌ Új (sheets: 450) |
| `520` clamp ceiling | `CalculateView.swift` `updateSheetWidth()` | named method | ❌ Új (sheets: 900) |
| `600` fallback | `CalculateView.swift` `updateSheetWidth()` | named method | ✅ Már §10A-ban: popover fallback |
| `300` clamp floor | `ColorPickerSheet.swift` `.onAppear` | magic literal | ❌ Új |
| `420` clamp ceiling | `ColorPickerSheet.swift` `.onAppear` | magic literal | ❌ Új |
| `24` margin | `ColorPickerSheet.swift` `.onAppear` | **magic literal** | ⚠️ Visszacsúszás — `NotesSheet`/`SnippetEditSheet`-ben `windowMargin` nevű konstans |
| `600` fallback | `ColorPickerSheet.swift` `.onAppear` | magic literal | ✅ Már §10A-ban |
| `380` clamp floor | `AddCountdownSheet.swift` `.onAppear` | magic literal | ❌ Új |
| `560` clamp ceiling | `AddCountdownSheet.swift` `.onAppear` | magic literal | ❌ Új |
| `24` margin | `AddCountdownSheet.swift` `.onAppear` | **magic literal** | ⚠️ Visszacsúszás — névtelen |
| `600` fallback | `AddCountdownSheet.swift` `.onAppear` | magic literal | ✅ Már §10A-ban |
| `400` initial value | `CalculateView.swift` `@State sheetWidth` | init érték | ❌ Új |
| `340` initial value | `ColorPickerSheet.swift` `@State sheetWidth` | init érték | ❌ Új |
| `420` initial value | `AddCountdownSheet.swift` `@State sheetWidth` | init érték | ❌ Új |

Az öt sheet-width implementáció összesen 7 eltérő clamp-értéket vezet be (300, 380, 420, 450, 520, 560, 900),
mind dokumentálás nélkül. A §10A-ban javasolt `windowConstrainedWidth(min:max:margin:fallback:)` helper
most az összes eltérést egy hívásban kezelné, a `windowMargin` visszacsúszó literálokkal együtt.

---

### 11B — `ColorPickerSheet` X gomb: azonos új literálok mint §10B-ben

A `BUG-COLOR-NODISMISS` X gomb pontosan megismétli a `deadlineDetailContent` §10B-ben dokumentált
compact dismiss értékeit:

| Literal | `deadlineDetailContent` | `ColorPickerSheet` (új) | Prior presence |
|---|---|---|---|
| `size: 11` | ✅ §10B | ✅ új instance | §10B óta: 2× |
| `width: 26, height: 26` | ✅ §10B | ✅ új instance | §10B óta: 2× |
| `cornerRadius: 6` | ✅ §1A | ✅ | §1A-ban dokumentált |
| `opacity(0.08)` bg | ✅ §1B | ✅ | §1B-ban dokumentált |
| `opacity(0.5)` fg | ✅ §1B | ✅ | §1B-ban dokumentált |

`size: 11` és `26×26` immár 2× jelennek meg — a `compactDismissButtonSize: CGFloat = 26`
konstans bevezetése most még inkább indokolt mint §10B-ben.

---

### 11C — `showDeleteConfirm` alert: új string literálok

A `BUG-DELETE-CONFIRM` alert három új string literált vezet be:

| String | Forma | Kategória |
|---|---|---|
| `"Delete \"\(item.label)\"?"` | interpolált alert title | ❌ Új — a `NotesSheet` `"Clear Notes?"` fix titelt használ |
| `"Delete"` | destructive gomb label | ✅ Megegyezik `NotesSheet` + `SnippetEditSheet` gomb labelével |
| `"This slot will be permanently removed."` | alert message | ❌ Új — nincs analóg máshol |

Az alert title formátuma eltér a `NotesSheet`-étől (fix string vs interpolált) — ez szándékos
(a slot neve megjelenik a dialógban), de dokumentálandó divergencia.


---

### 11D — BUG-DEADLINE-1/2: új literálok (Session Q)

**BUG-DEADLINE-1** (CalculateView delete-confirm alert):

| String / érték | Forma | Megjegyzés |
|---|---|---|
| `"Delete \"\(deadline.title)\"?"` | interpolált alert title | Konzisztens CountdownDetailView mintájával |
| `"Delete"` | destructive gomb label | ✅ Egységes az összes alert-tel |
| `"This deadline will be permanently removed."` | alert message | Eltér a slot verziótól ("slot" → "deadline") — szándékos |

**BUG-DEADLINE-2** (CalculateView rename TextField top padding):

| Érték | Fájl | Sor | Levezetés |
|---|---|---|---|
| `46` | `CalculateView.swift` | `deadlineDetailContent` TextField | 12pt (X top) + 26pt (X height) + 8pt (gap) = 46pt — számított, nem önkényes |

A 46pt levezetett értéke kommentben dokumentálva a kódban. Ha az X gomb pozíciója
(`padding(.top, 12)`) vagy mérete (`26×26`) változik, a 46-ot is frissíteni kell — ez
egy implicit függőség két egymástól független layout literál között.
