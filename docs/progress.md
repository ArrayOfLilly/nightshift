# countdownApp — Progress

## Session BC — 2026-08-13 (BUG-CHECKMARKDIRTY-1 + BUG-NOTESDISMISS-1)

### Session BC — LEZÁRVA
- [x] Claude.md, progress.md, countdownApp-handoff.md, buglist.md elolvasva
- [x] `SnippetEditSheet.swift` + `NotesSheet.swift` elolvasva — root cause megerősítve
- [x] **BUG-CHECKMARKDIRTY-1** — `SnippetEditSheet`: `let` → `var` az `originalTitle/Project/Body`
  property-ken; `commitEdit()` checkmark ágában `originalTitle = title` / `originalProject = project` /
  `originalBody = snippetBody` refresh a `commitSave()` után — X ezután clean state-et lát, nem mutat
  felesleges confirm alertet
- [x] **BUG-NOTESDISMISS-1 + NotesSheet UX egységesítés** — `NotesSheet`: debounce (`debounceTask` state +
  `.onChange(of: draft)` blokk) eltávolítva; `originalNotes: String` state hozzáadva; `.onAppear`
  `originalNotes = notes` baseline; `commitEdit()` checkmark ágában `originalNotes = draft` refresh;
  `handleDismiss()` `draft == originalNotes` check (volt: `draft == notes`); "Quit without saving"
  `notes = originalNotes` visszaállítással; delete alert `originalNotes = ""` reset
- [x] `docs/buglist.md` — BUG-CHECKMARKDIRTY-1 és BUG-NOTESDISMISS-1 ✅ KÉSZ státuszra frissítve
- [x] `docs/progress.md` + `docs/countdownApp-handoff.md` frissítve
- Git commit: PENDING

**Következő session:** BUG-TRASH-1 🔴 (editor trash visszateszi a törölt snippetet) vagy
BUG-DETAILDELETE-1 🔴 (CountdownDetailView törlés után nem navigál vissza) — egyeztetés alapján

---

## Session BB — 2026-08-13 (pending commit hash-ek rendezése + mappastruktúra ellenőrzés + buglist bővítés)

### Session BB — LEZÁRVA
- [x] `git log` alapján ellenőrizve: AN (F-3), AM (E-1), AO (F-9), AL (F-1/F-7/F-8), AS (D-5), Z+AA-b+AB,
  Q–Y sessionok `progress.md`-ben “Git commit: PENDING/TODO” jelziként szerepeltek, de a kód valójában már
  commitolva volt — mind a 9 hely frissítve tényleges hash-ekkel (`f09bd0c`, `dc656e3`, `822f154`, `ca4445a`,
  `37b1674`, `ebe890a`, `678bea6`, `25f7591`)
- [x] `countdownApp-handoff.md` — AL session tévesen `4fd8eef`-et mutatott (az AK docs commit, nem AL) →
  javítva `ca4445a`-ra; AN/AM/AO “TODO” jelzések frissítve; AS “PENDING” frissítve
- [x] Uncommitted doc-only változások (BA sessionből maradt, AY commit hash + “Következő session feladata”
  szinkronizálás) — beleépítve ebbe a session commitba
- [x] Mappastruktúra (Nyitott teendők #2) ellenőrizve `find` paranccsal: mind a 27 Swift fájl már
  végleges alkönyvtárban van (`App/`, `Components/`, `Models/`, `Services/`, `Theme/`, `Views/` +
  `Views/Calculate/`, `Views/Countdown/`, `Views/Snippets/`) — **nincs hátralévő munka**, csak dokumentáció
  frissítés volt szükséges (handoff.md fájllista frissítve, `CopyButton.swift` + `DeadlineDetailSheet.swift`
  hozzáadva a listához — korábban hiányoztak)
- [x] `docs/buglist.md` — 6 új bejegyzés felhasználói visszajelzés alapján (mind csak dokumentálva,
  implementáció nem történt): `BUG-MANUAL-1` (manual frissítés bezárási metódus miatt),
  `ENH-DEVDOCS-1` (fejlesztői dokumentáció hiányzik), `BUG-TRASH-1` (editor trash visszateszi a törölt
  snippetet), `BUG-DETAILDELETE-1` (CountdownDetailView törlés után nem navigál vissza), `UX-2` (max
  ablakszélesség 520→600pt felülvizsgálat, alternatíva fix 500pt), `ENH-DEFERRED-1` (lokalizáció +
  Settings/About/Help menü deferred dokumentálása); `UX-1` státusz ✅ KÉSZ-re javítva (ténylegesen
  implementálva volt AU sessionben, buglist.md ezt nem tükrözte)
- Git commit: `d612afe`, `9c9010f`

**Utólagos kiegészítés (ugyanaz a session, folytatás a felhasználó újabb visszajelzése után):**
- [x] `BUG-NOTESDISMISS-1` 🔴 felvéve `docs/buglist.md`-be — a `NotesSheet` X gombja továbbra is szó
  nélkül ment+dismiss, NEM követi a `SnippetEditSheet` (AZ session) dirty-check + confirm alert mintáját.
  Ez ellentmond a BA session bejegyzésének, amely tévesen állította, hogy a `NotesSheet` már helyes —
  a következő sessionben a tényleges kódot kell ellenőrizni, nem a korábbi feljegyzést készpénznek venni
- [x] `countdownApp-handoff.md` “Következő session feladata” listája bővítve 7. pontként

**Következő session:** prioritás felülvizsgálva — `BUG-TRASH-1`, `BUG-DETAILDELETE-1`, `BUG-NOTESDISMISS-1`
mind 🔴 kritikus használhatósági hibák, elsőként ezek közül érdemes választani

**További utólagos kiegészítés:**
- [x] `ENH-NOTEBADGE-1` 🟢 felvéve `docs/buglist.md`-be — vizuális jelzés (pl. pink dot badge a név mellett)
  a countdown itemen, ha van hozzá note; részletek (pozíció, szín, hol jelenjen meg) egyeztetendők
- [x] `countdownApp-handoff.md` “Következő session feladata” listája bővítve 8. pontként

---

## Session BA — 2026-08-13 (ellenőrzés + dokumentáció szinkronizálás)

### Session BA — LEZÁRVA
- [x] Claude.md, progress.md, countdownApp-handoff.md elolvasva
- [x] `NotesSheet.swift` + `SnippetEditSheet.swift` elolvasva — az AZ session implementációja teljes és helyes:
  - `NotesSheet`: `handleDismiss()` debounce flush + dirty check + alert; `commitEdit()` flush + VIEW mód; alert: "Cancel" / "Quit without saving" / "Save and quit" ✅
  - `SnippetEditSheet`: `originalTitle`/`originalProject`/`originalBody` `let` property-k; `isDirty` computed var; `shouldSaveOnDisappear` guard; `handleDismiss()` + `commitEdit()` azonos minta ✅
- [x] Kódváltozás: **nincs** — feladat már implementálva volt az AZ sessionban
- [x] `countdownApp-handoff.md` frissítve: "Következő session feladata" szekció az AZ lezárását tükrözi
- Nincs git commit (dokumentáció-only session, kódváltozás nélkül)

**Következő session:** Inline HTML/CSS string literálok (`SharedEditorComponents.swift`) VAGY mappastruktúra — egyeztetés alapján

---

## Session AZ — 2026-08-13 (SnippetEditSheet editor button behavior)

### Session AZ — LEZÁRVA
- [x] **SnippetEditSheet** — pipa/X viselkedés implementálva:
  - `originalTitle`, `originalProject`, `originalBody` — `let` property-k, dirty baseline az `init`-ben
  - `isDirty` — computed var: bármely mező eltér az originaltól
  - `shouldSaveOnDisappear` — `@State`, false-ra állítva discard-dismiss előtt (megelőzi az `.onDisappear` auto-save-et)
  - `commitEdit()` — checkmark (EDIT): `commitSave()` + `isEditing = false`; pencil (VIEW): `isEditing = true`
  - `handleDismiss()` — clean: `shouldSaveOnDisappear = false` + `dismiss()`; dirty: `showDismissConfirm = true`
  - `showDismissConfirm` alert: "Cancel" / "Quit without saving" (`shouldSaveOnDisappear=false` + dismiss) / "Save and quit"
  - Fejléc komment frissítve (Session AZ save/dismiss logic dokumentálva)
- [x] **NotesSheet** — nem érintett, már helyes volt (C-2/AF session: debounce, handleDismiss, showDismissConfirm alert)
- [x] Git commit: `1124b32` (a commit egyben tartalmazza a korábban uncommitted mappastruktúra rename-eket is)

**Következő session:** Inline HTML/CSS string literálok (`SharedEditorComponents.swift`) VAGY mappastruktúra Xcode projektfájl frissítés — egyeztetés alapján

---

## Session AY — 2026-08-13 (tervezés + egyeztetés, nincs implementáció)

### Session AY — LEZÁRVA
- [x] Három téma egyeztetve, implementáció külön sessionokba halasztva:
  1. **Inline HTML/CSS string literálok** — döntés folyamatban (következő session előtt)
  2. **Mappastruktúra** — fájlrendszer szintű mappák (nem Xcode virtuális groupok); struktúra tervezés következő session
  3. **Bug: pipa ment / X csak dismiss** — `NotesSheet` + `SnippetEditSheet`:
     - Pipa: ment + dismiss (EDIT módban)
     - X: dirty state esetén confirm alert ("Quit without saving" / "Cancel" / "Save and quit"); tiszta state esetén egyszerű dismiss
     - Dirty: NotesSheet → `draft != notes`; SnippetEditSheet → bármely mező (`title`, `project`, `snippetBody`) eltér az eredetitől
- Nincs git commit (dokumentáció-only session)

**Következő session:** mappastruktúra implementáció VAGY pipa/X bug fix — egyeztetés alapján

---

## Session AX — 2026-08-13 (refactor-plan szinkronizálás)

### Session AX — LEZÁRVA
- [x] `refactor-plan.md` teljes felülírás: minden finding bejelölve kész, T1–T5 tervezési kérdések lezárva
  - F-3, F-9, G-5/Csoport 3 korábban `TODO`/`NYITOTT` volt a planban, git szerint mind commitolva
  - UX-1 és D-1 (FocusedNSTextField SRP) bejegyezve mint "Egyéb lezárt findingek"
  - Státusz: `TELJES — minden finding lezárva ✅`
- [x] Git commit: `c3eb562`

**Következő session:** új fejlesztési irány — egyeztetés alapján

---

## Session AW — 2026-08-13 (D-2 lezárása — nem szükséges)

### Session AW — LEZÁRVA
- [x] **D-2** — `CountdownViewModel` bevezetésének megítélése:
  - D-5 és D-1 után a View-ban maradó felelősségek mind View-természetűek:
    sheet state koordináció (`showColorPicker`, `showNotes`, `showDeleteConfirm`),
    `showRemaining` toggle, `localDeadline` mirror (stepper visual feedback),
    `isEditing` inline label szerkesztés, `component(_:)` thin cal wrapper,
    `adjust(_:by:)` View-szinkronizáció (domain logika D-5-ben kiemelve),
    `timeDisplay(at:maxWidth:)` + `deadlineStepper` pure rendering
  - Domain logika nem maradt a View-ban — D-2 eredeti motivációja megszűnt
  - ViewModel bevezetése AI slop lenne: nincs legalább két konkrét használati hely,
    és a View elég kis és fókuszált
  - **D-2 → nem szükséges** — D kategória lezárva ✅
- [x] `docs/progress.md` + `docs/countdownApp-handoff.md` frissítve
- Nincs git commit (dokumentáció-only session, kódváltozás nélkül)

**D kategória státusz:** D-4 ✅, D-3 ✅, D-5 ✅, D-1 ✅, D-2 → nem szükséges — **D kategória LEZÁRVA ✅**

---

## Session AV — 2026-08-13 (D-1 FocusedNSTextField kiemelés)

### Session AV — LEZÁRVA
- [x] **D-1** — `FocusedNSTextField` kiemelése saját fájlba (SRP):
  - `FocusedNSTextField.swift` új fájl; láthatóság `private` → `internal` (egész app egy module)
  - `CountdownDetailView.swift` — `FocusedNSTextField` blokk eltávolítva (~110 sor); fejléc-komment frissítve (`FocusedNSTextField.swift`-re hivatkozik)
  - Build OK
- [x] Git commit: `01e652f`

**Következő session:** D-2 szükségességének megítélése — egyeztetéssel

---

## Session AU — 2026-08-13 (UX-1 egyeztetés + implementáció)

### Session AU — LEZÁRVA
- [x] UX-1 egyeztetés befejezve: főablak max szélesség **520pt**, minden más marad
- [x] `docs/buglist.md` — UX-1 megközelítés szekció frissítve (egyeztetés lezárva, referencia kijelző dokumentálva)
- [x] **UX-1 implementáció**:
  - `AppTheme.swift` — új `// MARK: - Window` szekció: `windowMinWidth = 460`, `windowMaxWidth = 520`
  - `ContentView.swift` — `.frame(minWidth: 460)` → `.frame(minWidth: AppTheme.windowMinWidth, maxWidth: AppTheme.windowMaxWidth)`
- [x] progress.md + handoff.md frissítve
- [x] Git commit: `37b1674` (AT session-ben együtt committolva)

---

## Session AT — 2026-08-13 (D-5 commit + UX-1 buglist)

### Session AT — LEZÁRVA
- [x] D-5 git commit (volt PENDING): `CountdownItem` mutating funcok, `Snippet` factory,
  `CountdownDetailView` + `SnippetEditSheet` lecsökkentett logika
- [x] `docs/buglist.md` új fájl — UX-1 bejegyzés (max-szélesség korlátok hiánya):
  főablak, componentStepper-ek, CountdownRowView sorok, SnippetsView sorok, popupok egyenkénti audit
- [x] progress.md + handoff.md frissítve
- [x] Git commit: `37b1674`

**Következő session:** D-1 (`CountdownDetailView` kiemelés) — egyeztetéssel, vagy UX-1 implementáció (egyeztetés után)

---

## Session AR — 2026-08-13 (D-3 bugfix: stale save() call)

### Session AR — LEZÁRVA
- [x] **D-3 bugfix** — `CountdownView.swift:91` `Cannot find 'save' in scope`:
  - `.navigationDestination` delete callback-jében `save()` hívás maradt a D-3 refaktor után,
    ahol a `private func save()` törlésre került
  - Fix: `save()` → `CountdownItem.save(items)` (egy sor, surgical edit_block)
- [x] Git commit: `3f25353`

**Következő session:** D-5, D-1, D-2 — egyeztetéssel

---

## Session AQ — 2026-08-13 (D-3 static load/save)

### Session AQ — LEZÁRVA
- [x] **D-3** — static load/save metódusok a modell fájlokban:
  - `CountdownItem.swift` — `extension Persistence`: `static func load(dumpPolicy: (Any) -> Bool = { _ in true }) -> [CountdownItem]` + `static func save(_ items:)`;
    `dumpPolicy` closure: a hívó dönt, melyik corrupt elem kerül dump-ba — `CountdownView` a notes-predikátumot adja át, az összes többi caller az alapértelmezett (mindig dump)
  - `NamedDeadline.swift` — `extension Persistence`: `static func load() -> [NamedDeadline]` + `static func save(_ deadlines:)`;
    Snippet-minta: per-item recovery, corrupt fragmentek → `AppKeys.appendCorruptFragments`
  - `CountdownView.swift` — `private func save()` + `private func load()` törölve;
    `.onAppear`: `items = CountdownItem.load { notes-predikátum }`;
    `.onChange(of: items)`: `CountdownItem.save(items)`;
    `storageKey` property törölve (már nem kell)
  - `CalculateView.swift` — `private func loadDeadlines()` + `private func saveDeadlines()` törölve;
    `.onAppear`: `namedDeadlines = NamedDeadline.load()`;
    `onDismiss` closure: `namedDeadlines = NamedDeadline.load()`;
    `onDelete`/`onRename`: `NamedDeadline.save(namedDeadlines)`;
    `addNamedDeadline`: `NamedDeadline.save(namedDeadlines)`
- [x] Git commit: `c2570aa`

**Következő session:** D-5, D-1, D-2 — egyeztetéssel

---

## Session AN — 2026-08-13 (F-3 shared ComponentStepper)

### Session AN — LEZÁRVA
- [x] **F-3** — `componentStepper` 3 implementáció → shared `ComponentStepper` struct:
  - `ComponentStepper.swift` új fájl: `label`, `unit`, `value`, `onInc`, `onDec` + `foregroundColor` (default: `AppTheme.dark`) + `backgroundColor` (default: `AppTheme.dark.opacity(0.12)`)
  - `LongPressStepperButton` mindkét irányban — `AddCountdownSheet` bugfix: plain `Button` → `LongPressStepperButton` (nyomvatartásos léptetés helyreállítva)
  - `CountdownDetailView`: `private func componentStepper` törölve, 5 call site → `ComponentStepper(...)` (default színek, nincs override)
  - `CalculateView`: `private func componentStepper` törölve, 5 call site → `ComponentStepper(...)` + `foregroundColor: AppTheme.background, backgroundColor: Color.white.opacity(0.12)` override
  - `AddCountdownSheet`: `private func componentStepper` törölve (plain Button eltávolítva), 5 call site → `ComponentStepper(...)` (default színek, nincs override)
- [x] Git commit: `f09bd0c`

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
- [x] Git commit: `dc656e3`

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
- [x] Git commit: `ca4445a`

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
- [x] Git commit: `ebe890a`

## Session AA-b — 2026-08-12 (CountdownView.load() per-item recovery + notes-elágazás)

### Session AA-b — LEZÁRVA
- [x] `CountdownView.load()` — per-item recovery implementálva (`edit_block`, csak a `load()` metódus érintett)
  - Raw JSON array parse → elemenkénti `do/catch` decode
  - Corrupt elem: notes-alapú elágazás runtime, per-item:
    - `notes` kulcs jelen és nem üres → `AppKeys.appendCorruptFragments` (dump-ba kerül)
    - `notes` hiányzik vagy üres → csendes eldobás, semmi dump
  - Minta: `Snippet.load()` és `CalculateView.loadDeadlines()` struktúrája követve
- [x] Load path táblázat: `CountdownView.load()` ✅ per-item + ✅ notes-elágazás
- [x] Git commit: `678bea6`

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
- [x] Git commit: `25f7591` (Session Q–X összevont commit)

---

## Session X — 2026-08-12 (Handoff + refactor-plan váz + Claude.md)

### Session X — LEZÁRVA
- [x] `Claude.md` megírva a gyökérbe
- [x] `docs/refactor-plan.md` létrehozva
- [x] `docs/countdownApp-handoff.md` frissítve
- [x] Git commit: `25f7591`

---

## Session W — 2026-08-12 (Audit 16 + docs átszervezés)

### Session W — LEZÁRVA
- [x] Audit 16 (lifecycle-audit.md) ✅
- [x] SESSION_HANDOFF.md + countdownApp-handoff.md összevonva
- [x] docs/ áthelyezve inner repóba
- [x] progress.md archiválva → history.md
- [x] Git commit: `25f7591`

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
- [x] Git commit: `822f154`

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
- [x] D-4 implementáció: AP session

---

## Session AP — 2026-08-13 (D-4 DeadlineDetailSheet)

### Session AP — LEZÁRVA
- [x] **D-4** — `deadlineDetailContent()` → `struct DeadlineDetailSheet: View`:
  - `DeadlineDetailSheet.swift` új fájl: `deadline`, `onLoad`, `onDelete`, `onRename` paraméterek;
    saját `@State`: `isRenaming`, `renameDraft`, `showDeleteConfirm`, `sheetWidth`;
    `@Environment(\.dismiss)` az X gombhoz (nincs explicit onDismiss callback)
  - `AppTheme.calcSaveGradient` — új `LinearGradient` static token a `// MARK: - Gradients` szekcióban;
    `DeadlineDetailSheet` + `deadlineListPopoverContent` + `saveSheetContent` mind ezt használja
  - `CalculateView` — eltávolítva: `isRenamingDeadline`, `renameDraft`, `showDeleteDeadlineConfirm` @State-ek;
    `deadlineDetailContent()` @ViewBuilder func; `calcSaveGradient` private var;
    sheet switch case frissítve: `DeadlineDetailSheet(deadline:onLoad:onDelete:onRename:)`
- [x] Git commit: `d46824d`

**Következő session:** D-3

---

## Session AU — 2026-08-13 (WindowHelpers magic number tokenizálás)

### Session AU — LEZÁRVA
- [x] **Window tokenek** — `AppTheme.swift` `// MARK: - Window` szekció bővítve:
  - `windowSheetMargin: CGFloat = 24` — margin default a `WindowHelpers` függvényekhez
  - `windowFallbackWidth: CGFloat = 600` — width fallback ha a főablak nem elérhető
  - `windowFallbackHeight: CGFloat = 800` — height fallback ha a főablak nem elérhető
- [x] **WindowHelpers.swift** — `margin` és `fallback` default paraméterek `AppTheme` tokenekre cserélve
- [x] **Elavult `max` értékek javítva** — 3 call site ahol a `max` meghaladta vagy nem tükrözte a főablak korlátját:
  - `SnippetEditSheet`: `max: 900` → `AppTheme.windowMaxWidth`, height `max: 680` → `600`; komment frissítve
  - `NotesSheet`: `max: 900` → `AppTheme.windowMaxWidth`; komment frissítve
  - `AddCountdownSheet`: `max: 560` → `AppTheme.windowMaxWidth`
- [x] Git commit: `4bbe75e`

---

## Session AQ+AR+AP+AS — 2026-08-13 (D-5)

### Session AS — LEZÁRVA
- [x] **D-5** — Domain logika kiemelése a View-kból (SRP):
  - `CountdownItem` — `mutating func resetIfExpired(at now: Date)` + `mutating func adjustDeadline(_ component: Calendar.Component, by value: Int)` (új `// MARK: - Deadline mutations` szekció a struct-on belül)
  - `Snippet` — `static func committed(from:title:body:project:) -> Snippet?` (új `// MARK: - Factory` extension a Persistence extension előtt)
  - `CountdownDetailView` — `.onAppear` lecsökkent: `item.resetIfExpired(at: now)` + `localDeadline = item.deadline`; `adjust(_:by:)` lecsökkent: `item.adjustDeadline(c, by: value)` + `localDeadline = item.deadline`
  - `SnippetEditSheet` — `commitSave()` lecsökkent: `Snippet.committed(from:title:body:project:)` hívás
  - View-kban nulla domain/business logika vagy dátumszámítás nem maradt; `cal` property megmaradt a `component(_:)` helper miatt (query, nem mutáció)
- [x] Git commit: `37b1674` (AT session-ben zárva, lásd AT bejegyzés)


## Session AY — 2026-08-13 (Inline HTML/CSS kiemelés — Nyitott teendők #1)

### Session AY — LEZÁRVA
- [x] **Nyitott teendők #1** — `SharedEditorComponents.swift` inline HTML/CSS string literálok kiemelve:
  - `resources/markdown-template.html` — új bundle resource, `{{THEME_AMBER}}`, `{{FONT_FACE_CSS}}`,
    `{{MARKDOWN_CSS}}`, `{{MARKED_JS}}`, `{{ESCAPED_MARKDOWN}}` placeholder-ekkel; `:root { --theme-amber }`
  - `resources/markdown-style.css` — új bundle resource, teljes markdown CSS kiemelve; `var(--theme-amber)`
    a korábbi Swift-interpolált `\(AppTheme.amberHex)` helyett (rgba(245,166,35,…) a `mark`-ban literál marad)
  - `SharedEditorComponents.swift`:
    - globális `markdownCSS` computed var törölve
    - `reload(_:into:)` guard bővítve `templateURL`/`cssURL`/`templateHTML`/`markdownCSS` (local let) betöltéssel;
      HTML összeállítás `templateHTML.replacingOccurrences` placeholder-cserével (Swift oldal 0 HTML/CSS)
    - `fallbackHTML(_:fontFaceCSS:)` — inline minimál CSS-re cserélve (nem a bundle markdown-style.css-ből olvas,
      mert ez a path pont a bundle-olvasási hiba esete)
  - Project: file-system-synchronized group (`countdownApp.xcodeproj` — `FileSystemSynchronizedRootGroup`),
    a `resources/` mappába rakott új fájlok automatikusan bundle resource-ok, nincs `.pbxproj` szerkesztés
  - Build: NEM futtatva ebben a sessionben (nincs hozzáférés Xcode buildhez az MCP-n keresztül) — **következő
    session elején ellenőrizendő**
- [x] Build OK, CSS bundle betöltés működik
- [x] Git commit: `6314c6a` (lásd session végi commit — entitlements fix + window resize fix is benne)

**Következő session:** Nyitott teendők #2 (mappastruktúra) — egyeztetéssel kezd

---

## Session AY (folyt.) — build hiba fix: CODE_SIGN_ENTITLEMENTS stale path

- [x] Build hiba: `countdownApp.entitlements could not be opened` — a `.pbxproj`-ban
  `CODE_SIGN_ENTITLEMENTS = countdownApp/countdownApp.entitlements` maradt egy korábbi session
  óta, miközben a fájl ténylegesen `countdownApp/App/countdownApp.entitlements`-be lett átmozgatva
  (mappastruktúra-rendezés, project-file-sync group nem szinkronizálja az explicit build setting path-okat)
- [x] Fix: `CODE_SIGN_ENTITLEMENTS` mindkét configban (Debug + Release) →
  `countdownApp/App/countdownApp.entitlements` — fájl a helyén marad, path frissítve hozzá
  (nem a gyökérbe mozgatás, mert az App/ szervezés szándékos volt)
- [x] Git commit: `6314c6a`

---

## Session AY (folyt. 2) — window resize bug fix: .windowResizability(.contentSize)

- [x] Hiba: ablak natív macOS resize (pl. Fill & Arrange menü) hatására jóval `AppTheme.windowMaxWidth`
  (520pt) fölé nőtt; a `ContentView.frame(maxWidth:)` csak a SwiftUI tartalmat korlátozta, magát az
  NSWindow-t nem — üres terület maradt a keskeny tartalom mellett
- [x] Fix: `countdownAppApp.swift` — `.windowResizability(.contentSize)` hozzáadva a `WindowGroup`
  Scene-hez; az ablak átméretezhető tartománya mostantól a `ContentView` `frame(minWidth:maxWidth:)`-jéből
  származik, fizikailag nem nőhet 520pt fölé
- [x] Git commit: `6314c6a`
