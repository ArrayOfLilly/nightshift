# countdownApp — Progress

## Session AN — 2026-08-13 (F-3 shared ComponentStepper)

### Session AN — LEZÁRVA
- [x] **F-3** — `componentStepper` 3 implementáció → shared `ComponentStepper` struct:
  - `ComponentStepper.swift` új fájl: `label`, `unit`, `value`, `onInc`, `onDec` + `foregroundColor` (default: `AppTheme.dark`) + `backgroundColor` (default: `AppTheme.dark.opacity(0.12)`)
  - `LongPressStepperButton` mindkét irányban — `AddCountdownSheet` bugfix: plain `Button` → `LongPressStepperButton` (nyomvatartásos léptetés helyreállítva)
  - `CountdownDetailView`: `private func componentStepper` törölve, 5 call site → `ComponentStepper(...)` (default színek, nincs override)
  - `CalculateView`: `private func componentStepper` törölve, 5 call site → `ComponentStepper(...)` + `foregroundColor: AppTheme.background, backgroundColor: Color.white.opacity(0.12)` override
  - `AddCountdownSheet`: `private func componentStepper` törölve (plain Button eltávolítva), 5 call site → `ComponentStepper(...)` (default színek, nincs override)
- [ ] Git commit: PENDING

**Következő session:** F-9 (magic numbers — corner radii, opacity) vagy egyéb egyeztetés alapján

---

## Session AM — 2026-08-13 (E-1 CalculationModal enum)

### Session AM — LEZARVA
- [x] **E-1** — `CalculateView` Boolean sprawl enum-ra:
  - `showSaveSheet: Bool` + `selectedDeadline: NamedDeadline?` eltavolitva
  - `private enum CalculationModal: Identifiable` bevezetve (nested, `CalculateView`-on belul):
    `case saveSheet`, `case deadlineDetail(NamedDeadline)`, `var id: String`
  - `@State private var activeModal: CalculationModal? = nil` egyetlen state
  - Ket `.sheet` modifier egysitve: `.sheet(item: $activeModal, onDismiss: loadDeadlines)`
  - 7 call site migralva: saveButton, deadlineListPopoverContent gomb,
    saveSheetContent CANCEL + SAVE, deadlineDetailContent xmark + LOAD AS TO + delete alert
  - `isRenamingDeadline` marad (D-4-re halasztva); `showDeleteDeadlineConfirm` marad
    (`.alert(isPresented:)` technikai kenyszer)
  - Build OK
- [ ] Git commit: PENDING

**Kovetkezo session:** F-3 (`componentStepper` 3 impl shared `ComponentStepper` view)

---

## Session AL — 2026-08-13 (F-7, F-8, F-1, E-1 scope fix)

### Session AL — LEZÁRVA
- [x] **E-1 scope pontosítás** — `CountdownDetailView` kihagyva (copyFeedback AJ session óta CopyButton saját state-je,
  csak `isEditing` maradt → enum nem indokolt); scope: csak `CalculateView`. `refactor-plan.md` frissítve.
- [x] **F-7** — `CalculateView.calcSaveGradient`: `Color(red: 0x59/255, green: 0x3C/255, blue: 0x73/255).opacity(0.35)`
  → `AppTheme.freeColors[7].opacity(0.35)`; fejléc komment + CALC-SAVE komment frissítve
- [x] **F-8** — `SnippetEditSheet.ProjectField`:
  - body background `Color(red: 0x86/255, ...)` → `AppTheme.freeColors[10]`
  - `suggestionList` background `Color(red: 0x52/255, ...)` → `AppTheme.freeColors[6]`
- [x] **F-1** — `WindowHelpers.swift` új fájl (`enum WindowHelpers`):
  - `windowConstrainedWidth(min:max:margin:fallback:) -> CGFloat`
  - `windowConstrainedHeight(min:max:margin:fallback:) -> CGFloat`
  - Mind az 5 call site migrálva:
    - `NotesSheet.updateSheetWidth()` → helper [450, 900]
    - `SnippetEditSheet.updateSheetSize()` → helper width [450, 900] + height [400, 680]; `windowMargin` property eltávolítva
    - `CalculateView.updateSheetWidth()` → helper [300, 520]
    - `ColorPickerSheet.onAppear` → helper [300, 420]
    - `AddCountdownSheet.onAppear` → helper [380, 560]
- [ ] Git commit: PENDING

**Következő session:** E-1 (`CalculateView` Boolean sprawl → `enum CalculationModalState`) — egyeztetés alapján

---

## Session AJ — 2026-08-13 (F-2 copy button + F-5 opacity + B-2 maradék)

### Session AJ — LEZÁRVA
- [x] **CopyButton.swift** — új shared komponens (`B+X` pattern):
  - `struct CopyButton<Label: View>` — `value: String`, `defaultAccessibilityLabel`, `copiedAccessibilityLabel`,
    `feedbackDuration: Duration = .milliseconds(1000)`, `@ViewBuilder label: (Bool) -> Label`
  - Saját `@State private var isCopied` — eltűnik a hívó view-ból
  - `.buttonStyle(.plain)` + `.focusable(false)` + `.accessibilityLabel` a komponensben
  - `performCopy()`: NSPasteboard write + `Task { .sleep(feedbackDuration) }` egységesítve
- [x] **CountdownDetailView.swift** — `@State private var copyFeedback` eltávolítva;
  copy Button → `CopyButton(value:...) { isCopied in ... }`, delay 1200ms → 1000ms
- [x] **NotesSheet.swift** — `@State private var copyFeedback` eltávolítva;
  headerButton copy hívás → `CopyButton`; `headerButton` bg 0.07 → 0.12 (F-5 side-fix)
- [x] **SnippetEditSheet.swift** — `@State private var copyFeedback` eltávolítva;
  headerButton copy hívás → `CopyButton`
- [x] **CountdownRowView.swift** — `DispatchQueue.main.asyncAfter` → `Task { .sleep(1000ms) }`
  (B-2 straggler — az AF sessionban kimaradt ez a call site); delay 1200ms → 1000ms
- [x] Git commit: `cb76608`

---

## Session AK — 2026-08-13 (F-4, E-4, E-2, F-10 — kis fixek)

### Session AK — LEZÁRVA
- [x] **F-4** — `monthAbbrev()` lokális implementációk eltávolítva (mind a 3):
  - `AddCountdownSheet`: inline `DateFormatter` eltávolítva, call site → `Formatters.monthAbbrev.string(from: deadline).uppercased()`
  - `CountdownDetailView`: thin wrapper eltávolítva, call site → `Formatters.monthAbbrev.string(from: localDeadline).uppercased()`
  - `CalculateView`: thin wrapper eltávolítva, call site → `Formatters.monthAbbrev.string(from: date.wrappedValue).uppercased()`
  - `Formatters.monthAbbrev` az egyetlen implementáció (C-4 session óta)
- [x] **E-4** — `FocusedNSTextField.updateNSView` font+color recreation per-second:
  - Font és textColor áthelyezve `makeNSView`-ba (egyszer, view létrehozáskor)
  - `updateNSView` mostantól csak `stringValue` frissítést végez — AppKit layout pass 1Hz tikkenként megszűnt
- [x] **E-2** — `namedDeadlines` stale read:
  - `showSaveSheet` sheet: `onDismiss: loadDeadlines` hozzáadva
  - `selectedDeadline` sheet: `onDismiss: loadDeadlines` hozzáadva
  - Save/edit/delete után a lista mindig frissül sheet bezárásakor
- [x] **F-10** — delete-confirm alert flag nevek egységesítve:
  - `SnippetEditSheet`: `showDeleteAlert` → `showDeleteConfirm` (3 hely)
  - `SnippetsView`: `showDeleteProjectAlert` → `showDeleteProjectConfirm` (3 hely)
  - Konvenció: `showDelete<Entity?>Confirm` wszerte
- [x] Git commit: `550afe9`

**Következő session:** E-1 (Boolean sprawl → enum), F-1 (`updateSheetWidth` helper), F-3 (`componentStepper` unifikáció), F-7/F-8 (AppTheme tokenek) — egyeztetés alapján

---

## Session AI — 2026-08-13 (G-5 Csoport 3 — G kategória lezárva)

### Session AI — LEZÁRVA
- [x] **CalculateView.swift** — `componentStepper` új `unit: String` param; mind a 10
      `LongPressStepperButton` hívás `accessibilityLabel`-t kapott (`"Increase/Decrease year/month/day/hour/minute"`);
      `saveButton` chevron.down: `"Show saved deadlines"`; `deadlineDetailContent` xmark: `"Close"`,
      pencil: `"Rename deadline"`, trash: `"Delete deadline"`
- [x] **CountdownRowView.swift** — calendar/clock toggle: dinamikus label
      (`"Switch to date display"` / `"Switch to remaining time"`)
- [x] **SnippetsView.swift** — `"+"` gomb: `"New snippet"`; sectionHeader Menu chevron.down: `"Project options"`;
      snippetRow copy gomb: `"Copy snippet"`
- [x] **CountdownView.swift** — ellenőrizve, nincs icon-only gomb label nélkül (addButton szöveges)
- [x] Build OK — első build ellenőrzés az AH session óta ✅
- [x] Git commit: `963f387`
- **G-5 LEZÁRVA** — ezzel a **G kategória teljes** ✅

---

## Session AH — 2026-08-13 (G-5 accessibility — prep, egyeztetés alatt)

### Session AH — folyamatban
- [x] Claude.md, progress.md, countdownApp-handoff.md, refactor-plan.md elolvasva
- [x] Mind a 10 érintett fájl elolvasva (CountdownDetailView, SnippetEditSheet, NotesSheet,
      CalculateView, CountdownRowView, ColorPickerSheet, AddCountdownSheet, SnippetsView,
      CountdownView, LongPressStepperButton), icon-only gombok tételesen leltározva:
  - `LongPressStepperButton` — maga a shared chevron gomb komponens (CountdownDetailView +
    CalculateView component stepperjei ezt használják) → egy fix helyben mindkét call site-ot fedi
  - `CountdownDetailView`: copy (label), paintbrush (color picker), sound toggle, notes, trash —
    5 gomb (a "Show Deadline/Remaining" gombnak már van szöveges label, nem érintett)
  - `SnippetEditSheet`: `ProjectField` chevron.down, `headerButton` 4× (copy, edit-toggle, trash, xmark)
  - `NotesSheet`: `headerButton` 4× (copy, edit-toggle, trash, xmark) — azonos minta mint SnippetEditSheet
  - `CalculateView`: saveButton split jobb fele (chevron.down), deadlineDetailContent xmark/pencil/trash — 4 gomb
    (nowButton és LOAD AS TO gombnak már van szöveges label)
  - `CountdownRowView`: calendar/clock toggle gomb — 1 gomb
  - `ColorPickerSheet`: xmark dismiss, + palette swatch-ok (színkör, nincs szöveges jelzés) — accessibilityLabel
    a swatch színéhez/névhez kell
  - `AddCountdownSheet`: componentStepper chevron up/down (plain Button, nem LongPressStepperButton — F-3 finding) — 2 gomb minta
  - `SnippetsView`: "+" új snippet gomb, sectionHeader Menu chevron.down, snippetRow copy gomb — 3 gomb minta
  - `CountdownView`: nincs icon-only gomb accessibilityLabel nélkül a saját szintjén (addButton szöveges,
    banner gombok szövegesek) — az érintettség csak a beágyazott CountdownRowView-n és NavigationLink-eken
    keresztül jön
- [x] Egyeztetés lezárva: **3 csoport**, sessionenként:
  - **Csoport 1** (ez a session): CountdownDetailView, ColorPickerSheet, AddCountdownSheet, LongPressStepperButton
  - **Csoport 2**: SnippetEditSheet, NotesSheet
  - **Csoport 3**: CalculateView, CountdownRowView, SnippetsView, CountdownView
- [x] Egyeztetés lezárva: **label konvenció vegyes** — rövid akciószó ha egyértelmű ("Copy label", "Close"),
  kontextusos ha több hasonló gomb van egy view-ban (pl. stepper +/−: "Increase year"/"Decrease year";
  color swatch-ok: "Color 1", "Color 2"…)
- [x] `LongPressStepperButton.swift` — `accessibilityLabel: String = ""` param + `.accessibilityLabel()` + `.accessibilityAddTraits(.isButton)` (default üres, call site-onként feltöltve; CalculateView call site-ok még hátra, Csoport 3)
- [x] `CountdownDetailView.swift` — copy ("Copy label"/"Label copied"), paintbrush ("Pick color"),
  sound toggle ("Mute/Unmute sound"), notes ("Add/View notes"), trash ("Delete countdown");
  `componentStepper` új `unit` param → LongPressStepperButton "Increase/Decrease \(unit)" mind az 5 stepperre
- [x] `ColorPickerSheet.swift` — xmark dismiss ("Close"); `swatchButton` új `accessibilityText`
  (palette swatch → "Color N", AUTO → "AUTO color") + `.accessibilityAddTraits(.isSelected)` kiválasztott swatch-on
- [x] `AddCountdownSheet.swift` — saját (nem shared) `componentStepper` új `unit` param,
  plain chevron Button-ok "Increase/Decrease \(unit)" (F-3 duplikáció érintetlen hagyva, csak label hozzáadva)

### Csoport 1 — LEZÁRVA
- G-5 részlegesen kész: CountdownDetailView, ColorPickerSheet, AddCountdownSheet, LongPressStepperButton
- Build ellenőrzés NEM történt (nincs xcodebuild futás ebben a sessionben) — következő sessionben
  vagy manuálisan ajánlott ellenőrizni
- [x] Git commit: `0fd05b0`

**Csoport 2 következő session feladata:** SnippetEditSheet + NotesSheet (azonos `headerButton` minta:
copy/checkmark, edit-toggle pencil/checkmark, trash, xmark — mindegyik 4×; SnippetEditSheet-ben
még a `ProjectField` chevron.down gombja is)

## Csoport 2 — 2026-08-13 (ugyanaz a session, folytatás)

- [x] `NotesSheet.swift` — `headerButton` új `label: String` param, mind a 4 hívás címkézve:
  "Copy notes"/"Notes copied", "Edit notes"/"Done editing", "Delete notes", "Close"
- [x] `SnippetEditSheet.swift` — `ProjectField` chevron.down → "Show project suggestions";
  `headerButton` ugyanaz a `label` param minta: "Copy snippet"/"Snippet copied", "Edit snippet"/"Done editing",
  "Delete snippet", "Close"

### Csoport 2 — LEZÁRVA
- G-5 további 2 fájl kész: SnippetEditSheet, NotesSheet
- Build ellenőrzés NEM történt
- [x] Git commit: `b5a046d`

**Csoport 3 (következő session) — utolsó G-5 rész:** CalculateView (+ itt kell pótolni az 5 dateStepper
`LongPressStepperButton` `accessibilityLabel` hívását is, ugyanaz a minta mint CountdownDetailView-ban:
"Increase/Decrease \(unit)"), CountdownRowView, SnippetsView, CountdownView. G-5 ezután teljesen kész,
G kategória lezárul.

---

## Session AG — 2026-08-13 (G kategória — layout/accessibility rész: G-1–G-4)

### Session AG — státusz
- [x] **G-1** — `CountdownDetailView` nincs ScrollView, rövid ablakban clipping
  - `body` szétválasztva: `ZStack` most `GeometryReader { outerGeo in ScrollView { detailContent.frame(minHeight: outerGeo.size.height) } }`
  - Eredeti tartalom `detailContent` computed property-be kiemelve, változatlan
  - Spacer-alapú centerezés megmarad, ha elég magas az ablak; rövid ablaknál scroll jelenik meg clipping helyett
  - `.navigationTitle` + `.onAppear` a `body`-ban maradt, a ZStack köré kerültek
- [x] **G-2** — `SnippetEditSheet` fix 680pt minHeight, kis kijelzőn clipping
  - Egyeztetés: dinamikus clamp választva (nem ScrollView, nem skip)
  - `sheetMinHeight` computed property → `@State sheetHeight: CGFloat = 680`
  - `updateSheetWidth()` → `updateSheetSize()` — mind width, mind height számítása egy helyen
  - `sheetHeight = min(680, max(400, windowHeight - windowMargin))` — ugyanaz a clamp-mintázat mint sheetWidth-nél (450–900)
  - Fejléc komment frissítve (elavult "fixed height" állítás korrigálva)
- [x] **G-3** — `SunPanel` 360pt minWidth + popover edge clipping risk
  - `body` külső `VStack` → `ScrollView { VStack {...} }`, `.frame(minWidth: 360, maxHeight: 600)`
  - Popover hívási hely (`CalculateView.sunPopoverContent`) változatlan, nincs érintett API
- [x] **G-4** — `CalculateView` deadline list popover, nincs ScrollView, sok deadline esetén unreachable items
  - `deadlineListPopoverContent`: belső `VStack` (ForEach lista) → `ScrollView { VStack {...} }.frame(maxHeight: 320)`
  - Header ("SAVED DEADLINES" + divider) a ScrollView-n kívül maradt (fixen látszik, csak a lista görgethető)
  - `popoverWidth` számítás, `.onAppear` változatlan
- [ ] **G-5** — accessibility: icon-only gombok `.accessibilityLabel` nélkül — áthalasztva következő sessionra (több fájlt érint: CountdownDetailView, SnippetEditSheet, NotesSheet, CalculateView, CountdownRowView, ColorPickerSheet, AddCountdownSheet, SnippetsView, CountdownView, LongPressStepperButton)

### Session AG — LEZÁRVA (G-1–G-4)

## Session AE — 2026-08-13 (B-2, B-3, A-4 — Swift concurrency cleanup)

### Session AE — LEZÁRVA
- [x] **B-2** — `copyFeedback` timer: `DispatchQueue.main.asyncAfter` → `Task { try? await Task.sleep(...) }`
  - `CountdownDetailView.swift` — már Task volt (korábbi session), nem érintett
  - `NotesSheet.swift` — már Task volt (korábbi session), nem érintett
  - `SnippetEditSheet.swift` — javítva: `DispatchQueue.main.asyncAfter(deadline: .now() + 1)` → `Task { .sleep(1000ms) }`
- [x] **B-3** — `hoverTask: DispatchWorkItem?` → `Task<Void, Never>?` (`CalculateView.swift`)
  - Property típus cserélve
  - `onHover` blokk: `DispatchWorkItem` + `DispatchQueue.main.asyncAfter` → `Task { .sleep(200ms) + isCancelled check }`
- [x] **A-4** — `SnippetEditSheet` — `.onDisappear { commitSave() }` hozzáadva
  - Fedezi az Esc / system dismiss eseteket (az xmark gomb már hívta `commitSave()`-t)
  - Per-keystroke write nem vezettünk be (debounce egyeztetés nélkül nem kerül be)
- [x] Git commit: `f7f774d`

---

## Session AD — 2026-08-13 (Manual — data recovery szekció + image groups)

### Session AD — LEZÁRVA
- [x] Amber döntés: már lezárva (AA-a session, commit `2dd8900`) — handoff elavult szekciója törölve
- [x] `countdownApp-manual.md` — "Data Recovery" szekció hozzáadva (18/18b/18c screenshotok)
- [x] `manual_build.py` — `SCREENSHOTS_DIR` fix (abszolút path), `<!-- group -->` parser + `.img-group` CSS
- [x] 9 image group beillesztve a manualba (2 képes és 3 képes csoportok)
- [x] 03b standalone + 03c+03d pair (modal sheets olvashatóság)
- [x] 11+12 group, felesleges `---` törölve a Snippets előtt
- [x] Git commitok: `946fc91`, `7656791`, `e427e0c`, `e6acc75`, `5888c03`, `6642535`

---

## Session AC — 2026-08-13 (Debug trigger — corrupt banner screenshot)

### Session AC — LEZÁRVA
- [x] `AppKeys.swift` — `DebugNotifications.injectCorruptBanner` notification name (`#if DEBUG`)
- [x] `countdownAppApp.swift` — `CommandMenu("Debug")` + Cmd+Shift+D shortcut, 3 fake fragment inject + broadcast
- [x] `SnippetsView`, `CalculateView`, `CountdownView` — `.onReceive(injectCorruptBanner)` → `corruptedFragments` reload
- [x] Release buildből teljes kizárás: `#if DEBUG` minden érintett ponton
- [x] Git commit: `e2c3666`

**Használat:** DEBUG build → navigálj a kívánt view-ra → Cmd+Shift+D → banner megjelenik 3 fake itemmel → screenshot → Dismiss → újra triggelhető

---

## Session AB — 2026-08-13 (Recovery Banner UI + lifecycle fixes)

### Session AB — LEZÁRVA
- [x] **Task 2** — `FocusedNSTextField.Coordinator` deinit fix (`CountdownDetailView.swift`)
  - `deinit { NotificationCenter.default.removeObserver(self) }` hozzáadva a `Coordinator`-hoz
  - Fix: NC-1..4 observer leak — zombie Coordinator-ok többé nem futtatnak `onCommit()`-ot ablakváltás után
- [x] **Task 3** — `countdownAppApp.swift` lifecycle hook
  - `AppDelegate: NSObject, NSApplicationDelegate` bevezetve (`@MainActor final class`)
  - `@NSApplicationDelegateAdaptor(AppDelegate.self)` az `App` struct-ban
  - `applicationWillTerminate` → `UserDefaults.standard.synchronize()`
- [x] **Task 1** — Banner UI mindhárom érintett view-ban
  - `@State private var corruptedFragments: [String]` — lokális state, `.onAppear`-ban töltve
  - `corruptionBanner` private property: ikon + "N item(s) could not be loaded" + "Copy raw data" + "Dismiss"
  - "Copy raw data": pretty-printed JSON vágólapra (`NSPasteboard`), fallback: raw string
  - "Dismiss": törli `AppKeys.corruptedDump`-ot, `corruptedFragments = []`
  - `SnippetsView`: banner a `VStack` tetején (headerBar előtt)
  - `CalculateView`: banner `.overlay(alignment: .top)` — ScrollView miatt overlay pattern
  - `CountdownView`: banner a `VStack` tetején (itemList előtt)
  - Banner szín: `CountdownView` → dark sötétvörös (`#4A0000` 85%), többi → `#8B0000` 75%
- [ ] Git commit (Session Z+AA-a+AA-b+AB összevonva, PENDING)

## Session AA-b — 2026-08-12 (CountdownView.load() per-item recovery + notes-elágazás)

### Session AA-b — LEZÁRVA
- [x] `CountdownView.load()` — per-item recovery implementálva (`edit_block`, csak a `load()` metódus érintett)
  - Raw JSON array parse → elemenkénti `do/catch` decode
  - Corrupt elem: notes-alapú elágazás runtime, per-item:
    - `notes` kulcs jelen és nem üres → `AppKeys.appendCorruptFragments` (dump-ba kerül)
    - `notes` hiányzik vagy üres → csendes eldobás, semmi dump
  - Minta: `Snippet.load()` és `CalculateView.loadDeadlines()` struktúrája követve
- [x] Load path táblázat: `CountdownView.load()` ✅ per-item + ✅ notes-elágazás
- [ ] Git commit (Session Z+AA-a+AA-b összevonva, PENDING)

**AB következő:**
- Banner UI (`SnippetsView`, `CalculateView`, `CountdownView`)
- `FocusedNSTextField.Coordinator` — deinit observer leak fix
- `countdownAppApp.swift` — `NSApplicationDelegateAdaptor` + `applicationWillTerminate` → `synchronize()`

---

## Session AA-a — 2026-08-12 (Recovery infrastruktúra — Snippet + CalculateView + amber fix)

### Session AA-a — LEZÁRVA
- [x] `AppKeys.swift` — `appendCorruptFragments(_ fragments: [String])` static helper hozzáadva
- [x] `Snippet.load()` — per-item recovery: raw JSON array → elemenkénti `do/catch` decode →
       corrupt elem → fragment string → `AppKeys.appendCorruptFragments`
- [x] `CalculateView.loadDeadlines()` — ugyanaz `NamedDeadline`-ra
- [x] **Amber fix (F-6)**:
  - `AppTheme.background` → `#F5A623` (volt: `#E5A020`), hex literal stílusra átírva
  - `AppTheme.amberHex = "#F5A623"` — CSS/WebView szinkron kulcs
  - `markdownCSS` global `let` → computed `var`, 5× `#F5A623` → `\(AppTheme.amberHex)`
- [x] Git commit: `2dd8900` (recovery infra) + amber commit következik

**AA-b következő:**
- `CountdownView.load()` — per-item recovery + notes-alapú elágazás
  - notes-szal → dump + banner flag; notes nélkül → csendes eldobás

---

## Session Z — 2026-08-12 (Codable model fix)

### Session Z — LEZÁRVA
- [x] `AppKeys.swift` — már létezett, tartalom helyes, semmi teendő
- [x] `Snippet.swift` — custom `init(from decoder:)` + `CodingKeys` + `storageKey` → `AppKeys.snippets`
- [x] `NamedDeadline.swift` — custom `init(from decoder:)` + `CodingKeys` + persistence key → `AppKeys.namedDeadlines`
- [x] `CountdownItem.swift` — `id` decode: `decode()` → `decodeIfPresent(... ) ?? UUID()`
- [x] `CountdownView.swift` — `storageKey`/`freeOrderKey` inline literálok → `AppKeys.*`
- [x] `CalculateView.swift` — `@AppStorage` kulcsok + `loadDeadlines`/`saveDeadlines` → `AppKeys.*`
- [x] Git commit: `0844aa2`
- [x] AA session kettévágva: AA-a (Snippet + CalculateView) / AA-b (CountdownView + notes-elágazás)

---

## Session Y — 2026-08-12 (Audit összesítés + refactor-plan findings)

### Session Y — LEZÁRVA
- [x] Mind a 16 audit fájl elolvasva egyenként
- [x] `docs/refactor-plan.md` teljes findings listával feltöltve — 7 kategória (A–G), 35+ finding tételesen
- [x] `docs/countdownApp-handoff.md` frissítve
- [ ] Git commit (Session Q–Y)

---

## Session X — 2026-08-12 (Handoff + refactor-plan váz + Claude.md)

### Session X — LEZÁRVA
- [x] `Claude.md` megírva a gyökérbe
- [x] `docs/refactor-plan.md` létrehozva
- [x] `docs/countdownApp-handoff.md` frissítve
- [ ] Git commit (Session Q–X)

---

## Session W — 2026-08-12 (Audit 16 + docs átszervezés)

### Session W — LEZÁRVA
- [x] Audit 16 (lifecycle-audit.md) ✅
- [x] SESSION_HANDOFF.md + countdownApp-handoff.md összevonva
- [x] docs/ áthelyezve inner repóba
- [x] progress.md archiválva → history.md
- [ ] Git commit (Session Q–W)

---

## Session V — 2026-08-12 (Manual képek)

### Session V — LEZÁRVA
- [x] `countdownApp-manual.md` — 28 screenshot beillesztve

---

## Session U — 2026-08-12 (Audit 14–15 + Manual build script)

### Session U — LEZÁRVA
- [x] Audit 14 (js-injection-audit.md) ✅
- [x] Audit 15 (accessibility-audit.md) ✅
- [x] Manual teljesen újraírva
- [x] `manual_build.py` megírva

---

## Session T — 2026-08-12 (Audit 12–13)

### Session T — LEZÁRVA
- [x] Audit 12 (storage-audit.md) ✅
- [x] Audit 13 (layout-audit.md) ✅

---

## Session Q+R+S — 2026-08-12 (Audit 6–11 + BUG-DEADLINE-1/2)

### LEZÁRVA
- [x] Audit 6–11 ✅
- [x] BUG-DEADLINE-1 — delete saved deadline confirm alert
- [x] BUG-DEADLINE-2 — rename TextField `.padding(.top, 46)` fix

---

## Session P — 2026-08-12 (CALC-SAVE polish + Audit 1–4)

### LEZÁRVA (commit `cb1623a`)
- [x] `CalculateView.swift` — rename mód, pencil gomb, X dismiss, sheetWidth fix
- [x] Audit 1–4 ✅
- [x] Build OK, git commit: `cb1623a`

---

*Session B–O: lásd `docs/history.md`*

## Session AF — 2026-08-13 (B-2 maradék, C-1, C-2, C-3, C-4 — performance + concurrency)

### Session AF — LEZÁRVA
- [x] **B-2 maradék** — `SnippetsView` inline copy gomb: `DispatchQueue.main.asyncAfter` → `Task { .sleep(1000ms) }`
- [x] **C-1** — `MarkdownWebView.updateNSView` feltétel nélküli reload:
  - `Coordinator.lastMarkdown: String` property hozzáadva
  - `updateNSView`: `guard markdown != context.coordinator.lastMarkdown else { return }` + `lastMarkdown` update
  - Hatás: WKWebView reload csak valódi markdown-változáskor fut (pl. `copyFeedback` toggle nem triggerel újratöltést)
- [x] **C-2** — `NotesSheet` per-keystroke write debounce:
  - `@State private var draft: String` lokális buffer bevezetése
  - `PlainTextEditor` a `$draft`-ra bind-ol (volt: `$notes`)
  - `.onAppear`: `draft = notes` inicializálás
  - `.onChange(of: draft)`: 500 ms debounce Task → `notes = newValue`
  - Copy gomb és delete alert `draft`-aware
  - Komment frissítve a fájl fejlécében
- [x] **C-3** — `orderedFreeItems` O(n²) → O(n):
  - `Dictionary(uniqueKeysWithValues:)` lookup `expired.first(where:)` helyett
- [x] **C-4** — `DateFormatter` centralizálás: `Formatters.swift` új fájl
  - `Formatters.monthAbbrev` — `"MMM"`, en_US (CountdownDetailView, CalculateView)
  - `Formatters.deadline` — `"yyyy.MM.dd HH:mm"`, system locale (CountdownItem)
  - `Formatters.deadlineCompact` — `"yyyy MMM dd  HH:mm"`, en_US (CalculateView list)
  - `Formatters.time` — `"HH:mm"`, en_US_POSIX (SunPanel)
  - Érintett fájlok: `CountdownItem`, `CountdownDetailView`, `CalculateView`, `SunPanel`
  - Lokalizációs deferred task dokumentálva `Formatters.swift` fejlécében
- [x] Git commit: `5c7760b`


---

## Session AO — 2026-08-13 (F-9 corner radii + opacity tokenek)

### Session AO — LEZÁRVA
- [x] **F-9** — Magic numbers → `AppTheme` tokenek:
  - `AppTheme` — 3 corner radius token: `radiusSmall = 5` (összevon: 5, 6), `radiusMedium = 7` (összevon: 7, 8), `radiusLarge = 12` (összevon: 12, 14)
  - `AppTheme` — 8 alpha token: `alpha08` (0.07, 0.08), `alpha12` (0.10, 0.12), `alpha25`, `alpha35`, `alpha50` (0.45, 0.50), `alpha60` (0.55, 0.60), `alpha75` (0.70, 0.80), `alpha90` (0.85, 0.90)
  - 14 érintett fájl: AddCountdownSheet, CalculateView, ColorPickerSheet, ComponentStepper, ContentView, CountdownDetailView, CountdownRowView, CountdownView, LongPressStepperButton, NotesSheet, SnippetEditSheet, SnippetsView, SunPanel, AppTheme
  - Nem tokenizált maradékok (szándékos): 0.2, 0.3, 0.4, 0.05, 0.15, 0.18, 0.95 — egyedi vagy nincs összevonási pár; ColorPickerSheet ternáris 0.18 szintén marad
  - CSS border-radius értékek (SharedEditorComponents.swift markdownCSS) érintetlenek — külön WebView világ, nem szinkronizálható SwiftUI tokenekkel
- [ ] Git commit: PENDING

**Következő session:** D kategória (SRP / god views) — egyeztetéssel kezd


---

## Session AO — D kategória tervezés (egyeztetés)

- [x] D kategória sorrendje és motivációja egyeztetve:
  - Cél: fejleszthetőség + olvashatóság (nem testability-első)
  - Sorrend: **D-4 → D-3 → D-5 → D-1 → D-2**
  - D-2 (`CountdownViewModel`) szükségességét D-3 után újra ítéljük meg — lehet hogy D-3 után
    a View-ban maradó logika már annyira kis méretű, hogy külön ViewModel nem indokolt
  - D-3 irány megerősítve: static load/save metódusok a modell fájlokban (`Snippet`-minta kiterjesztve)
    `CountdownItem`, `NamedDeadline` — a View csak hívja őket
- [ ] D-4 implementáció: következő session

