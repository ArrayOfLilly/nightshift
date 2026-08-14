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
- Git: **naprakész** — legutóbbi commit `515aa7e` (BF session: ENH-NOTEBADGE-1 + UX-2 + BUG-MANUAL-1)
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
- **AN session**: F-3 — `ComponentStepper.swift` új fájl (shared struct); `CountdownDetailView`, `CalculateView`, `AddCountdownSheet` — `private func componentStepper` törölve, 15 call site migrálva; `AddCountdownSheet` bugfix: plain `Button` → `LongPressStepperButton`. Git commit: `f09bd0c`
- **AM session**: E-1 — `CalculationModal` enum: `showSaveSheet: Bool` + `selectedDeadline: NamedDeadline?` eltavolitva;
  `private enum CalculationModal: Identifiable` (nested, `case saveSheet` + `case deadlineDetail(NamedDeadline)`);
  `activeModal: CalculationModal? = nil` egyetlen state; ket `.sheet` modifier egysitve;
  7 call site migralva. `isRenamingDeadline` marad (D-4), `showDeleteDeadlineConfirm` marad (`.alert` kenyszer).
  Build OK. Git commit: `dc656e3`
- **AL session**: AppTheme tokenek + WindowHelpers —
  F-7: `CalculateView.calcSaveGradient` `Color(red: 0x59/255, ...)` → `AppTheme.freeColors[7].opacity(0.35)`;
  F-8: `SnippetEditSheet.ProjectField` body bg → `AppTheme.freeColors[10]`, suggestionList bg → `AppTheme.freeColors[6]`;
  F-1: `WindowHelpers.swift` új fájl (`enum WindowHelpers`, `windowConstrainedWidth` + `windowConstrainedHeight`), mind az 5 call site migrálva (NotesSheet, SnippetEditSheet, CalculateView, ColorPickerSheet, AddCountdownSheet); `SnippetEditSheet.windowMargin` property eltávolítva. Git commit: `ca4445a`
- **AU session**: UX-1 — `AppTheme.windowMinWidth = 460`, `windowMaxWidth = 520`; `ContentView` frame constraint frissítve; git commit `37b1674`
- **AV session**: D-1 — `FocusedNSTextField.swift` új fájl; `CountdownDetailView.swift` ~110 sor (FocusedNSTextField blokk) eltávolítva; git commit `01e652f`
- **BD session**: BUG-DETAILDELETE-1 — `CountdownDetailView`: `@Environment(\.dismiss)` hozzáadva;
  delete alert destructive ágában `onDelete(); dismiss()` — view mostantól visszaugrik `CountdownView`-ra
  törlés után. Build OK. Git commit: `485e363`
- **BC session**: BUG-CHECKMARKDIRTY-1 + BUG-NOTESDISMISS-1 — `SnippetEditSheet`: `let` → `var` az
  `original*` property-ken, `commitEdit()` baseline refresh; `NotesSheet`: debounce eltávolítva,
  `originalNotes` baseline bevezetve, `handleDismiss()` egységesítve — mindkét sheet X viselkedése azonos.
- **BG session**: BUG-SUNPANEL-1 — hover trigger → click trigger a középső holdra; `hoverTask` eltávolítva;
  `.popover` a `Button`-ra kerül; `.accessibilityLabel("Sun times")`; buglist: 6 új bejegyzés (BUG-SUNPANEL-1 ✅,
  ENH-ABOUT-1, ENH-HELP-1, ENH-L10N-1, ENH-SETTINGS-1, ENH-DEVDOCS-2). Build OK. Git commit: `b0967ce`
- **BF session**: ENH-NOTEBADGE-1 + UX-2 + BUG-MANUAL-1 — `AppTheme.noteIndicator` token (narancssárga);
  `CountdownRowView` `eye.fill` badge (`!copyFeedback && !item.notes.isEmpty`);
  `AppTheme.windowMaxWidth` 520 → 600; manual: `05e` + eye badge leírás, `11b` + Notes unsaved-changes
  szekció, `17 Exit` + Snippets unsaved-changes szekció; HTML regenerálva.
  Git commit: `e6aa819` + `d1ce48c` + `515aa7e`
- **AY session**: Nyitott teendők #1 — inline HTML/CSS kiemelés `SharedEditorComponents.swift`-ből:
  `resources/markdown-template.html` + `resources/markdown-style.css` új bundle resource-ok (placeholder csere
  + `var(--theme-amber)`); globális `markdownCSS` var törölve; `reload(_:into:)` bundle-ből olvas +
  `replacingOccurrences` placeholder-cserével; `fallbackHTML` inline minimál CSS-re cserélve.
  Project file-system-synchronized group, nincs `.pbxproj` szerkesztés szükséges.
  + build hiba fix: `CODE_SIGN_ENTITLEMENTS` stale path (`countdownApp/countdownApp.entitlements` →
  `countdownApp/App/countdownApp.entitlements`, Debug + Release).
  + window resize bug fix: `.windowResizability(.contentSize)` a `WindowGroup`-on (natív macOS resize
  addig túlnyújthatta az NSWindow-t a `ContentView.frame(maxWidth:)` fölé).
  Build OK, user verifikálta. Git commit: `6314c6a`

---

## Következő session feladata

**Nyitott teendők #2 — mappastruktúra: LEZÁRVA (BB session)** — `countdownApp/countdownApp/` alatt mind
  a 27 Swift fájl már a végleges alkönyvtárakban van (`App/` 2, `Components/` 5, `Models/` 3, `Services/` 4,
  `Theme/` 1, `Views/` 1 + `Views/Calculate/` 3 + `Views/Countdown/` 6 + `Views/Snippets/` 2), file-system-synchronized
  Xcode group, nincs teendő. Lásd lent frissített fájllista.

**Buglist — 8 bejegyzés (`docs/buglist.md`), mind egyeztetésre vár implementáció előtt — fontos sorrend:
a manual (`BUG-MANUAL-1`) MINDIG UTOLSÓ, mert screenshotjai csak a végleges UI állapotot tükrözhetik:**

1. ~~**BUG-TRASH-1**~~ ✅ KÉSZ (BE session) — `shouldSaveOnDisappear = false` a delete alert destructive
   ágában; `.onDisappear` nem hívja `commitSave()`-t törlés után. Git commit: `6dfb0ab`
2. ~~**BUG-DETAILDELETE-1**~~ ✅ KÉSZ (BD session) — `@Environment(\.dismiss)` + `dismiss()` a delete alert
   destructive ágában; navigáció visszaugrik `CountdownView`-ra törlés után. Git commit: `485e363`
3. ~~**BUG-NOTESDISMISS-1**~~ ✅ KÉSZ (BC session) — debounce eltávolítva, `originalNotes` baseline, X viselkedés egységes
4. ~~**BUG-CHECKMARKDIRTY-1**~~ ✅ KÉSZ (BC session) — `let` → `var`, `commitEdit()` baseline refresh
5. ~~**ENH-NOTEBADGE-1**~~ ✅ KÉSZ (BF session) — `AppTheme.noteIndicator` (orangered); `CountdownRowView` `note.text` badge `if !item.notes.isEmpty`
6. ~~**UX-2**~~ ✅ KÉSZ (BF session) — `AppTheme.windowMaxWidth` 520 → 600
7. **ENH-DEVDOCS-1** 🟡 — fejlesztői dokumentáció hiányzik, megírandó
8. **ENH-DEFERRED-1** 🟢 — deferred taskok dokumentálása: lokalizáció, UI nyelv, input nyelv/locale-ok külön
   kezelése; ehhez Settings menü + About + Help menü (még egyik sincs megvalósítva)
9. ~~**BUG-MANUAL-1**~~ ✅ KÉSZ (BF session) — `05e` + eye badge, `11b` + Notes unsaved-changes, `17 Exit` + Snippets unsaved-changes; HTML regenerálva. Git: `515aa7e`

**Buglist** — nyitott: ENH-DEVDOCS-1 🟡, ENH-DEFERRED-1 🟢, ENH-ABOUT-1 🟡, ENH-HELP-1 🟡,
ENH-L10N-1 🟢, ENH-SETTINGS-1 🟢, ENH-DEVDOCS-2 🟡 (nem bugok — feature/deferred/docs)

**Következő session jelöltek:**
- **ENH-ABOUT-1** — iconKeeper About forráskódja szükséges referenciának
- **ENH-HELP-1** — iconKeeper Help megvalósítása szükséges referenciának
- **ENH-DEVDOCS-2** — README + install.md (Distribution csomag); projektnév egyeztetés

---

## Buglist

- `docs/buglist.md` — UX-1 (max-szélesség korlátok) bejegyzve (AT session)

---

## D kategória előzmény

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

## Swift fájlok (teljes lista, mappastruktúra szerint — BB session frissítés)

```
App/AppKeys.swift
App/countdownAppApp.swift
Components/ComponentStepper.swift
Components/CopyButton.swift
Components/FocusedNSTextField.swift
Components/LongPressStepperButton.swift
Components/SharedEditorComponents.swift
Models/CountdownItem.swift
Models/NamedDeadline.swift
Models/Snippet.swift
Services/Formatters.swift
Services/SunTimes.swift
Services/SunTimesService.swift
Services/WindowHelpers.swift
Theme/AppTheme.swift
Views/ContentView.swift
Views/Calculate/CalculateView.swift
Views/Calculate/DeadlineDetailSheet.swift
Views/Calculate/SunPanel.swift
Views/Countdown/AddCountdownSheet.swift
Views/Countdown/ColorPickerSheet.swift
Views/Countdown/CountdownDetailView.swift
Views/Countdown/CountdownRowView.swift
Views/Countdown/CountdownView.swift
Views/Countdown/NotesSheet.swift
Views/Snippets/SnippetEditSheet.swift
Views/Snippets/SnippetsView.swift
```
- **AO session**: F-9 — `AppTheme` corner radii tokenek (`radiusSmall/Medium/Large`), alpha tokenek (`alpha08`…`alpha90`); 14 fájl érintett; CSS border-radius értékek (markdownCSS) érintetlenek. Git commit: `822f154`
- **AP session**: D-4 — `DeadlineDetailSheet.swift` új fájl; `AppTheme.calcSaveGradient` új token;
  `CalculateView`: `isRenamingDeadline`/`renameDraft`/`showDeleteDeadlineConfirm` state-ek + `deadlineDetailContent()` func + `calcSaveGradient` private var eltávolítva. Git commit: `d46824d`
- **AT session**: D-5 commit lezárva; `docs/buglist.md` létrehozva — UX-1 (max-szélesség korlátok) bejegyzve.
- **AS session**: D-5 — `CountdownItem`: `mutating func resetIfExpired(at:)` + `mutating func adjustDeadline(_:by:)`;
  `Snippet`: `static func committed(from:title:body:project:) -> Snippet?` factory;
  `CountdownDetailView`: `.onAppear` + `adjust(_:by:)` lecsökkentve modellhívásra;
  `SnippetEditSheet`: `commitSave()` lecsökkentve `Snippet.committed(from:...)` hívásra. Git commit: `37b1674` (AT session-ben zárva)
- **AR session**: D-3 bugfix — `CountdownView.swift` `.navigationDestination` delete callbackben
  `save()` → `CountdownItem.save(items)` (stale call, D-3 refaktor lefelejtett call site). Git commit: `3f25353`
- **AQ session**: D-3 — static load/save a modell fájlokban:
  `CountdownItem.swift` + `NamedDeadline.swift`: `extension Persistence` (load/save static metódusok, Snippet-minta);
  `CountdownItem.load(dumpPolicy:)`: closure param a notes-alapú corrupt dump döntéshez;
  `CountdownView`: `save()`/`load()` private func + `storageKey` eltávolítva, call site-ok direkt static hívásokra;
  `CalculateView`: `loadDeadlines()`/`saveDeadlines()` eltávolítva, call site-ok direkt static hívásokra. Git commit: `c2570aa`

## D kategória — sorrend és döntések

- **Motiváció:** fejleszthetőség + olvashatóság (nem testability-első)
- **Sorrend:** D-4 → D-3 → D-5 → D-1 → D-2
- **D-3 irány:** static load/save a modell fájlokban (Snippet-minta) — CountdownItem, NamedDeadline
- **D-2 döntés (AW session):** nem szükséges — D-3+D-5+D-1 után domain logika nincs a View-ban;
  a maradó felelősségek (sheet state, toggle, localDeadline mirror, isEditing, thin wrapperek, pure rendering)
  mind View-természetűek; ViewModel két konkrét használati hely nélkül AI slop lenne
- **D-4 ✅ KÉSZ** (AP session) | **D-3 ✅ KÉSZ** (AQ session) | **D-5 ✅ KÉSZ** (AS session)
- **D-1 ✅ KÉSZ** (AV session) | **D-2 → nem szükséges** (AW session)
- **D kategória LEZÁRVA ✅**
