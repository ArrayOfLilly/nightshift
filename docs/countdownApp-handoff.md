# countdownApp — handoff

## Working setup

- **Filesystem MCP** — fájlolvasás/írás. Szerializáltan olvasd a fájlokat.
- `Filesystem:write_file` teljes fájl felülírással működik, NEM appendál — mindig read-then-write.
- Header/komment: angolul, semmi magyar szöveg a kódban.
- **Inner kódrepo**: `/Users/ArrayOfLilly/tools/countdownApp/countdownApp/`
- **Swift forrás**: `countdownApp/countdownApp/countdownApp/` alatt
- **Docs**: `countdownApp/countdownApp/docs/` — progress.md, handoff, auditok, manual, misc mind itt
- Session elején olvasd el: `docs/progress.md` + `docs/countdownApp-handoff.md` + `Claude.md`
- Session végén: progress.md frissítése + git commit

---

## Jelenlegi állapot

- Audit pipeline: **mind a 16 kész** ✅ — `docs/audit_files/`
- Manual: **kész** ✅ — `docs/manual/countdownApp-manual.md`, Data Recovery szekció (18/18b/18c screenshotok) hozzáadva (AD session)
- Git: **naprakész** — legutóbbi commit `963f387` (AI session, G-5 Csoport 3, G kategória lezárva)
- `Claude.md` megírva a gyökérbe
- `refactor-plan.md` teljes findings listával (7 kategória, A–G, 35+ finding)
- **Z session**: Codable model fix, `AppKeys` bevezetve minden persistence path-on
- **AA-a session**: Per-item recovery (Snippet + CalculateView) + Amber fix (`AppTheme.background` → `#F5A623`, `amberHex` szinkron, `markdownCSS` computed var) — commit `2dd8900`
- **AA-b session**: `CountdownView.load()` per-item recovery + notes-elágazás
- **AB session**: Banner UI (mindhárom view) + `FocusedNSTextField.Coordinator` deinit (NC-1..4 fix) + `AppDelegate` lifecycle hook
- **AC session**: DEBUG Cmd+Shift+D trigger — commit `e2c3666`
- **AD session**: Manual Data Recovery szekció + image groups — `manual_build.py` group parser, 9 group a manualban, 03b/03c+03d 2+1 layout, path fix
- **AE session**: Swift concurrency cleanup — B-2 `SnippetEditSheet` copyFeedback DispatchQueue→Task, B-3 `CalculateView` hoverTask DispatchWorkItem→Task, A-4 `SnippetEditSheet` `.onDisappear` auto-save — commit `f7f774d`
- **AF session**: Performance + concurrency — B-2 maradék (`SnippetsView` copy), C-1 MarkdownWebView guard, C-2 NotesSheet debounce, C-3 orderedFreeItems O(n), C-4 `Formatters.swift` (DateFormatter centralizálás + lokalizáció deferred task dokumentálva)
- **AG session**: G kategória részben — G-1 `CountdownDetailView` ScrollView+GeometryReader (Spacer-centerozás megőrizve rövid abaknál scroll), G-2 `SnippetEditSheet` din. `sheetHeight` (cap 680, floor 400, ugyanaz a minta mint sheetWidth), G-3 `SunPanel` ScrollView+maxHeight 600, G-4 `CalculateView` deadline list popover ScrollView+maxHeight 320 (header fix marad). G-5 (accessibility labels, ~10 fájl) áthalasztva következő sessionra
- **AH session**: G-5 accessibility — Csoport 1: `LongPressStepperButton`, `CountdownDetailView`,
  `ColorPickerSheet`, `AddCountdownSheet` (commit `0fd05b0`). Csoport 2: `SnippetEditSheet`, `NotesSheet`
  (commit `b5a046d`).
- **AI session**: G-5 Csoport 3 — `CalculateView` (componentStepper unit param, 10 stepper label,
  saveButton chevron, deadlineDetailContent xmark/pencil/trash), `CountdownRowView` (toggle),
  `SnippetsView` (3 gomb), `CountdownView` (nincs teendő). Build OK. **G-5 és G kategória LEZÁRVA ✅**
  (commit `963f387`)
- **AJ session**: F-2 + F-5 side-fix + B-2 straggler —
  `CopyButton.swift` új shared komponens (`@ViewBuilder label: (Bool) -> Label`);
  `CountdownDetailView`, `NotesSheet`, `SnippetEditSheet` — `@State copyFeedback` eltávolítva,
  `CopyButton`-ra migrálva, delay 1000ms egységesítve;
  `NotesSheet.headerButton` bg 0.07 → 0.12 (F-5 lezárva);
  `CountdownRowView` — `DispatchQueue` → Task (B-2 lezárva). Git commit: `cb76608`
- **AK session**: kis fixek —
  F-4: `monthAbbrev()` lokális impl. eltávolítva mind a 3 fájlból (AddCountdownSheet inline fmt, CountdownDetailView és CalculateView thin wrapper), call site-ok `Formatters.monthAbbrev` direkt hívással;
  E-4: `FocusedNSTextField` font+color → `makeNSView`-ba, `updateNSView` csak stringValue (1Hz AppKit pass megszűnt);
  E-2: `loadDeadlines` `onDismiss`-ben mindkét CalculateView sheet-en;
  F-10: `showDeleteAlert` → `showDeleteConfirm` (SnippetEditSheet), `showDeleteProjectAlert` → `showDeleteProjectConfirm` (SnippetsView). Git commit: `550afe9`
- **AN session**: F-3 — `ComponentStepper.swift` új fájl (shared struct); `CountdownDetailView`, `CalculateView`, `AddCountdownSheet` — `private func componentStepper` törölve, 15 call site migrálva; `AddCountdownSheet` bugfix: plain `Button` → `LongPressStepperButton`. Git commit: TODO
- **AM session**: E-1 — `CalculationModal` enum: `showSaveSheet: Bool` + `selectedDeadline: NamedDeadline?` eltavolitva;
  `private enum CalculationModal: Identifiable` (nested, `case saveSheet` + `case deadlineDetail(NamedDeadline)`);
  `activeModal: CalculationModal? = nil` egyetlen state; ket `.sheet` modifier egysitve;
  7 call site migralva. `isRenamingDeadline` marad (D-4), `showDeleteDeadlineConfirm` marad (`.alert` kenyszer).
  Build OK. Git commit: TODO
- **AL session**: AppTheme tokenek + WindowHelpers —
  F-7: `CalculateView.calcSaveGradient` `Color(red: 0x59/255, ...)` → `AppTheme.freeColors[7].opacity(0.35)`;
  F-8: `SnippetEditSheet.ProjectField` body bg → `AppTheme.freeColors[10]`, suggestionList bg → `AppTheme.freeColors[6]`;
  F-1: `WindowHelpers.swift` új fájl (`enum WindowHelpers`, `windowConstrainedWidth` + `windowConstrainedHeight`), mind az 5 call site migrálva (NotesSheet, SnippetEditSheet, CalculateView, ColorPickerSheet, AddCountdownSheet); `SnippetEditSheet.windowMargin` property eltávolítva. Git commit: `4fd8eef`

---

## Következő session feladata

- **D-4 ✅ KÉSZ** (AP session)
- **D-3 ✅ KÉSZ** (AQ session)
- **E-1 ✅ KÉSZ** (AM session)
- **F-3 ✅ KÉSZ** (AN session)
- **F-9 ✅ KÉSZ** (AO session)
- **F-1 ✅ KÉSZ** (AL session), **F-7 ✅ KÉSZ** (AL session), **F-8 ✅ KÉSZ** (AL session)
- **F-2 ✅ KÉSZ** (AJ session), **F-4 ✅ KÉSZ** (AK session), **F-5 ✅ KÉSZ** (AJ session side-fix), **F-6 ✅ KÉSZ** (AA-a session)
- **E-2 ✅ KÉSZ** (AK session), **E-4 ✅ KÉSZ** (AK session), **F-10 ✅ KÉSZ** (AK session)
- Manual PDF újragenerálása (`manual_build.py` futtatása) ha szükséges

---

## Recovery infrastruktúra — áttekintés

### AppKeys.appendCorruptFragments(_ fragments: [String])
- `AppKeys.swift`-ben, a `corruptedDump` kulcs mellett
- `#if DEBUG` alatt itt van `DebugNotifications.injectCorruptBanner` is
- Akkumulál, nem felülír

### Load path státusz
| Path | Recovery | Dump |
|------|----------|------|
| `Snippet.load()` | ✅ per-item | ✅ AppKeys.corruptedDump |
| `CalculateView.loadDeadlines()` | ✅ per-item | ✅ AppKeys.corruptedDump |
| `CountdownView.load()` | ✅ per-item + notes-elágazás | ✅ notes esetén |

### Banner státusz
| View | Banner | Dismiss | Debug trigger |
|------|--------|---------|---------------|
| `SnippetsView` | ✅ | ✅ | ✅ .onReceive |
| `CalculateView` | ✅ | ✅ | ✅ .onReceive |
| `CountdownView` | ✅ | ✅ | ✅ .onReceive |

---

## Kritikus tudás

- `CountdownItem`, `Snippet`, `NamedDeadline` — custom `init(from decoder:)`. **Soha ne adj hozzá mezőt `decodeIfPresent` + default nélkül.**
- `AppTheme.swift` — shared design token forrás. `amberHex` a CSS/WebView szinkron kulcs.
- `freeOrder` `.onChange` csak `rebuildCache()`-t hív, `saveFreeOrder()`-t nem — szándékos, latens footgun (OWN-LC-2).
- Font PostScript nevek: `AlienLeague` / `AlienLeagueBold` — centralizálva `AppTheme.swift`-ben.
- `DebugNotifications.injectCorruptBanner` — csak `#if DEBUG`, `AppKeys.swift` alján.

---

## Swift fájlok (teljes lista)

```
AddCountdownSheet.swift
AppKeys.swift
ComponentStepper.swift
AppTheme.swift
Formatters.swift
CalculateView.swift
ColorPickerSheet.swift
ContentView.swift
CountdownDetailView.swift
CountdownItem.swift
CountdownRowView.swift
CountdownView.swift
LongPressStepperButton.swift
NamedDeadline.swift
NotesSheet.swift
WindowHelpers.swift
SharedEditorComponents.swift
Snippet.swift
SnippetEditSheet.swift
SnippetsView.swift
SunPanel.swift
SunTimes.swift
SunTimesService.swift
countdownAppApp.swift
```
- **AO session**: F-9 — `AppTheme` corner radii tokenek (`radiusSmall/Medium/Large`), alpha tokenek (`alpha08`…`alpha90`); 14 fájl érintett; CSS border-radius értékek (markdownCSS) érintetlenek. Git commit: TODO
- **AP session**: D-4 — `DeadlineDetailSheet.swift` új fájl; `AppTheme.calcSaveGradient` új token;
  `CalculateView`: `isRenamingDeadline`/`renameDraft`/`showDeleteDeadlineConfirm` state-ek + `deadlineDetailContent()` func + `calcSaveGradient` private var eltávolítva. Git commit: `d46824d`
- **AQ session**: D-3 — static load/save a modell fájlokban:
  `CountdownItem.swift` + `NamedDeadline.swift`: `extension Persistence` (load/save static metódusok, Snippet-minta);
  `CountdownItem.load(dumpPolicy:)`: closure param a notes-alapú corrupt dump döntéshez;
  `CountdownView`: `save()`/`load()` private func + `storageKey` eltávolítva, call site-ok direkt static hívásokra;
  `CalculateView`: `loadDeadlines()`/`saveDeadlines()` eltávolítva, call site-ok direkt static hívásokra. Git commit: `c2570aa`

## D kategória — sorrend és döntések

- **Motiváció:** fejleszthetőség + olvashatóság (nem testability-első)
- **Sorrend:** D-4 → D-3 → D-5 → D-1 → D-2
- **D-3 irány:** static load/save a modell fájlokban (Snippet-minta) — CountdownItem, NamedDeadline
- **D-2 megjegyzés:** szükségességét D-3 után újra ítéljük — lehet hogy a maradék logika már elég kis méretű
- **D-4 ✅ KÉSZ** (AP session)
- **Következő:** D-3 — static load/save metódusok `CountdownItem` + `NamedDeadline` modell fájlokba
