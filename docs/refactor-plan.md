# countdownApp — Refactor Plan

## Státusz: FINDINGS ÖSSZEGYŰJTVE — prioritizálás egyeztetés alatt

Az összes 16 audit elolvasva (Session Y, 2026-08-12). Az alábbi lista tételesen tartalmazza
a findingeket, csoportosítva — de **prioritizálás még nem történt meg**; ezt egyeztetés után
rögzítjük.

Audit forrás: `docs/audit_files/` (16 fájl)
Döntési elv: `Claude.md`

---

## A — KRITIKUS: Adatvesztés (Codable + Storage)

Ezek azonnal, bármely más fejlesztés előtt kezelendők — bármely sémaváltoztatás
előtt kötelező fix.

### A-1: `Snippet` és `NamedDeadline` — synthesized Codable, nincs custom `init(from:)`
- **Hatás:** Bármely JSON kulcs hiánya a teljes tömböt törli (`[]`), visszafordíthatatlanul.
- **Érintett fájlok:** `Snippet.swift`, `NamedDeadline.swift`
- **Fix:** custom `init(from decoder:)` + `CodingKeys` enum + `decodeIfPresent` minden
  opcionális/default-os mezőn (minta: `CountdownItem.swift`)

### A-2: `try?` → silent data loss minden persistence úton
- **Érintett helyek:**
  - `CountdownView.load()` / `save()` — teljes countdown lista
  - `CalculateView.loadDeadlines()` / `saveDeadlines()` — named deadlines
  - `Snippet.load()` / `save()` — snippetek
- **Hatás:** Decode hiba → `[]` (visszafordíthatatlan veszteség), encode hiba → UserDefaults
  stale marad (néma eltérés a memória és a disk között)
- **Fix — Per-item partial recovery (T1 döntés):**
  - JSON array-t elemenként decode-olunk; hibás elem → skip a live adatból
  - A raw `[String: Any]` fragment → `AppKeys.corruptedDump` UserDefaults kulcsra mentve
    (JSON array, akkumulálva)
  - App induláskor / view megjelenésekor: ha `corruptedDump` nem üres → perzisztens banner
    az érintett view tetején, explicit Dismiss gombbal (törli a kulcsot)
  - Banner: "N item could not be loaded" + **"Copy raw data"** gomb (pretty-printed JSON
    a vágólapra) — a user kézzel visszafejtheti a tartalmat
  - **Recovery scope modell szerint:**
    - `Snippet` — mindig banner + raw dump (projekt kontextus, kritikus)
    - `NamedDeadline` — mindig banner + raw dump
    - `CountdownItem` notes-szal — banner + raw dump (a notes tartalma értékes)
    - `CountdownItem` notes nélkül — per-item skip, log, banner nélkül
  - A döntés runtime, per-item: corrupt CountdownItem raw fragmentjét megvizsgáljuk,
    van-e nem-üres `notes` kulcs — ha igen, dump-ba kerül, ha nem, csendesen eldobjuk

### A-3: `CountdownItem.id` — `decode()` instead of `decodeIfPresent`
- **Érintett fájl:** `CountdownItem.swift`, sor 73
- **Hatás:** Régebbi JSON-ban `id` kulcs hiánya az egész items tömböt törli
- **Fix:** `decodeIfPresent(UUID.self, forKey: .id) ?? UUID()`

### A-4: `SnippetEditSheet` — nincs auto-save; force-quit elveszti a szerkesztést
- **Érintett fájlok:** `SnippetEditSheet.swift`
- **Hatás:** A body szerkesztés csak lokális `@State`, csak az explicit dismiss-gomb ment
- **Fix:** `.onChange(of: snippetBody)` → debounced `Snippet.save()`

### A-5: Nincs lifecycle hook — `UserDefaults.synchronize()` sosem hívódik
- **Érintett fájl:** `countdownAppApp.swift`
- **Hatás:** Force-quit / SIGKILL esetén a buffered writes elveszhetnek
- **Fix:** `NSApplicationDelegateAdaptor` + `applicationWillTerminate` → `synchronize()`;
  vagy `.onChange(of: scenePhase)` background/inactive detekció

### A-6: `enum AppKeys` hiányzik — UserDefaults kulcsok szétszórva, typo-veszélyes
- **Érintett fájlok:** `CalculateView.swift` (inline literálok), `CountdownView.swift` (instance let)
- **Fix:** Centralizált `enum AppKeys` minden manual UserDefaults kulcshoz

---

## B — MAGAS: Memory Leak és Concurrency

### B-1: `FocusedNSTextField.Coordinator` — NotificationCenter observer leak (KRITIKUS)
- **Érintett fájl:** `CountdownDetailView.swift`, sor 61
- **Hatás:** Minden megnyitott+bezárt detail view egy zombie Coordinator-t hagy; minden
  ablakváltáskor `onCommit()` fut elavult bindingra
- **Fix:** `deinit { NotificationCenter.default.removeObserver(self) }` a Coordinator-hoz

### B-2: `copyFeedback` timer — `@State` outlives view teardown
- **Érintett fájlok:** `CountdownDetailView`, `NotesSheet`, `SnippetEditSheet` (3×)
- **Hatás:** DispatchQueue async block fut teardown után
- **Fix:** `Task { try await Task.sleep(...) }` + `.task` modifier vagy `.onDisappear` cancel

### B-3: `hoverTask: DispatchWorkItem` — race condition és legacy API
- **Érintett fájl:** `CalculateView.swift`
- **Fix:** `Task<Void, Never>` + cooperative `Task.isCancelled` check (kód a performance-audit-ban)

---

## C — MAGAS: Performance

### C-1: `MarkdownWebView.updateNSView` — feltétel nélküli full WKWebView reload minden render cikluson
- **Érintett fájl:** `SharedEditorComponents.swift`, sor 36–38
- **Hatás:** Disk I/O + DOM teardown minden `@State` változásra, pl. `copyFeedback` toggle
- **Fix:** `guard markdown != context.coordinator.lastMarkdown else { return }`

### C-2: UserDefaults write per-keystroke (`NotesSheet` → `CountdownView.save()`)
- **Érintett fájlok:** `CountdownView.swift`, `NotesSheet.swift`
- **Hatás:** JSON-encode + disk write minden leütésre (az egész items tömb minden alkalommal)
- **Fix:** ~500ms debounce (`Task.sleep`-alapú koalescálás)

### C-3: `orderedFreeItems` — O(n²) nested loop `rebuildCache`-ben
- **Érintett fájl:** `CountdownView.swift`, sorok 108–121
- **Fix:** `Dictionary<UUID, CountdownItem>` lookup → O(n)

### C-4: `DateFormatter` ad-hoc példányosítás — 6+ helyen, egyes esetekben render loop-ban
- **Érintett fájlok:** `AddCountdownSheet`, `CountdownDetailView`, `CalculateView`,
  `CountdownItem`, `SunPanel` (13×/render `SunPanel`-ben)
- **Fix:** static/cached `DateFormatter`-ek, `AppTheme` vagy dedicated helpers-ben

---

## D — KÖZEPES: SRP / God Views

### D-1: `CalculateView` — 8 felelősség egy structban (~500+ sor)
- Dátumszámítás, stepper input, sun popover, hold phase, deadline persistence,
  deadline list popover, deadline detail sheet, rename sub-flow
- **Javasolt irány:** `DeadlineDetailSheet` subview (saját `@State`), `NamedDeadline.load/save` static

### D-2: `CountdownView` — 7 felelősség (324 sor)
- Layout, persistence (4 UserDefaults metódus), sound playback, Task scheduling,
  drag-drop, filtering/sorting, binding-factory
- **Javasolt irány:** `CountdownViewModel` (@Observable) a persistence + domain logic-hoz

### D-3: Persistence metódusok View-ban mindenhol
- `CountdownView.load/save/saveFreeOrder/loadFreeOrder`
- `CalculateView.loadDeadlines/saveDeadlines`
- `Snippet.load/save` (static — ez az elfogadhatóbb forma)
- **Javasolt irány:** Static metódusok az egyes modelleken (Snippet-minta kiterjesztve)

### D-4: `deadlineDetailContent()` — 4 felelősség egy `@ViewBuilder` függvényben
- Display, rename flow, delete action, load action — egybegyúrva, mert `@ViewBuilder`
  nem owolhat `@State`-et
- **Javasolt fix:** `struct DeadlineDetailSheet: View` saját `@State`-tel

### D-5: Business logic view metódusokban
- `CountdownDetailView.adjust(_:by:)` — calendar arithmetic + model write
- `SnippetEditSheet.commitSave()` — validáció + default logic + timestamp
- `CountdownDetailView.onAppear` — expiry reset domain logic

---

## E — KÖZEPES: State Management

### E-1: `@State` Boolean sprawl — mutually exclusive állapotok külön flag-ekkel
- `CalculateView`: `showSaveSheet` + `showDeadlineListPopover` + `selectedDeadline`
  → javasolt: `enum CalculationModalState`
- ~~`CountdownDetailView`: `copyFeedback` + `isEditing` → `enum LabelInteraction`~~
  Az AJ session óta `copyFeedback` a `CopyButton` saját state-je — `CountdownDetailView`-ban
  már csak `isEditing` maradt, enum bevezetése nem indokolt. Scope: csak `CalculateView`.
- **Hatás:** lehetetlen state kombinációk kompilációs hibák helyett runtime bugok

### E-2: `CalculateView.namedDeadlines` — stale read, nincs refresh ha tab switch — ✅ KÉSZ (AK session)
- `onDismiss: loadDeadlines` mindkét sheet-en (saveSheet + selectedDeadline); save/edit/delete után mindig frissül

### E-3: `SnippetEditSheet.onDisappear` — nincs `commitSave` external dismiss esetén — ✅ KÉSZ (AE session, A-4)
- `.onDisappear { commitSave() }` hozzáadva, commit `f7f774d`

### E-4: `SM-4a` — `FocusedNSTextField.updateNSView` font recreation per-second (TimelineView) — ✅ KÉSZ (AK session)
- Font+textColor áthelyezve `makeNSView`-ba; `updateNSView` csak stringValue-t frissít

---

## F — ALACSONY: Duplication és Magic Numbers

### F-1: `updateSheetWidth()` — 5 implementáció, 3 különböző clamp tartomány — ✅ KÉSZ (AL session)
- `WindowHelpers.swift` új fájl: `windowConstrainedWidth(min:max:margin:fallback:)` + `windowConstrainedHeight(min:max:margin:fallback:)`
- Mind az 5 call site (`NotesSheet`, `SnippetEditSheet`, `CalculateView`, `ColorPickerSheet`, `AddCountdownSheet`) helper-re migrálva
- `SnippetEditSheet.updateSheetSize()` width+height is helperrel

### F-2: Copy-to-clipboard block — ✅ KÉSZ (AJ session)
- `CopyButton.swift` — `struct CopyButton<Label: View>`, `@ViewBuilder label: (Bool) -> Label`
- `CountdownDetailView`, `NotesSheet`, `SnippetEditSheet` → `CopyButton`-ra migrálva, delay 1000ms
- `CountdownRowView` — `simultaneousGesture` (nem button, más UX), `DispatchQueue` → Task (B-2 fix)

### F-3: `componentStepper` — 3 implementáció (AddCountdownSheet-ben visszaesés: plain Button, nem LongPress)
- **Fix:** shared `ComponentStepper` view, `LongPressStepperButton`-nal

### F-4: `monthAbbrev()` — 3 implementáció, static helper kellene — ✅ KÉSZ (AK session)
- Lokális implementációk eltávolítva (AddCountdownSheet inline fmt, CountdownDetailView + CalculateView thin wrapper); call site-ok `Formatters.monthAbbrev` direkt hívással

### F-5: `headerButton()` — NotesSheet vs SnippetEditSheet bg opacity eltérés — ✅ KÉSZ (AJ session side-fix)
- `NotesSheet.headerButton` bg 0.07 → 0.12 (SnippetEditSheet értékre egységesítve)

### F-6: `markdownCSS` — `#F5A623` nem egyezik `AppTheme.background` (#E5A020) amberrel — ✅ KÉSZ (AA-a session)
- `AppTheme.background` → `#F5A623`, `amberHex` szinkron kulcs bevezetve, `markdownCSS` computed var lett, commit `2dd8900`

### F-7: `#593C73` purple gradient — ✅ KÉSZ (AL session)
- `CalculateView.calcSaveGradient`: `Color(red: 0x59/255, ...)` → `AppTheme.freeColors[7].opacity(0.35)`
- Header komment frissítve

### F-8: `SnippetEditSheet` ProjectField/popover colors — ✅ KÉSZ (AL session)
- `ProjectField` body background: `Color(red: 0x86/255, ...)` → `AppTheme.freeColors[10]`
- `suggestionList` background: `Color(red: 0x52/255, ...)` → `AppTheme.freeColors[6]`

### F-9: Magic corner radii (26 instance, 7 fájl), opacity értékek (35+ instance) → `AppTheme` tokenek

### F-10: Delete-confirm alert flags — 6 instance különböző névvel (`showDeleteConfirm` vs `showDeleteAlert`) — ✅ KÉSZ (AK session)
- `SnippetEditSheet`: `showDeleteAlert` → `showDeleteConfirm`; `SnippetsView`: `showDeleteProjectAlert` → `showDeleteProjectConfirm`; konvenció: `showDelete<Entity?>Confirm`

---

## G — LAYOUT / Accessibility

### G-1: `CountdownDetailView` — nincs ScrollView, rövid ablakban clipping — ✅ KÉSZ (AG session)
- `body` GeometryReader+ScrollView-ba csomagolva, tartalom `detailContent`-be kiemelve, Spacer-centerozás megőrizve
### G-2: `SnippetEditSheet` — 680pt minHeight, kis kijelzőn levágódik — ✅ KÉSZ (AG session)
- `sheetHeight` din. számított (`min(680, max(400, windowHeight - margin))`), sheetWidth mintára
### G-3: `SunPanel` — 360pt minWidth + polover edge clipping kockázat — ✅ KÉSZ (AG session)
- `body` ScrollView-ba csomagolva, `.frame(minWidth: 360, maxHeight: 600)`
### G-4: `CalculateView` deadline popover — nincs ScrollView, sok deadline esetén unreachable items — ✅ KÉSZ (AG session)
- Lista ScrollView-ba csomagolva, `.frame(maxHeight: 320)`, header fix marad
### G-5: Accessibility: icon-only gombok wszerte `.accessibilityLabel` nélkül — RÉSZBEN KÉSZ (AH session, Csoport 1–2/3)
- Sok fájlt érint, 3 csoportra bontva:
  - **Csoport 1 — ✅ KÉSZ**: `LongPressStepperButton` (shared komponens, `accessibilityLabel` param),
    `CountdownDetailView`, `ColorPickerSheet`, `AddCountdownSheet` — commit `0fd05b0`
  - **Csoport 2 — ✅ KÉSZ**: `SnippetEditSheet`, `NotesSheet` — commit `b5a046d`
  - **Csoport 3 — NYITOTT**: `CalculateView` (+ `LongPressStepperButton` call site-ok itt), `CountdownRowView`,
    `SnippetsView`, `CountdownView`

---

## Nyílt tervezési kérdések

*(Ezekre egyeztetés szükséges implementáció előtt)*

**T1 — Partial decode vs. array-wipe: meddig menjünk el?**
A-2 fix-hez: elég a `do/catch` + log, vagy per-item partial recovery is kell?
Per-item decode egy for-loop + `try?` kombinációval lehetséges, de komplexebb.

**T2 — `CountdownViewModel` scope: mikor?**
D-2 (CountdownView god view) megoldása ViewModel-lel nagyobb refaktor.
Érdemes-e most elkezdeni, vagy a Codable fixek után jövő sessionra halasztani?

**T3 — `enum CalculationModalState` bevezethető-e `CalculateView` jelenlegi belső
struktúrájában, vagy csak a D-1/D-4 szétválasztással együtt van értelme?**

**T4 — `markdownCSS` computed property-vé alakítása: mekkora kockázat?**
A CSS string jelenleg globális `let` konstans — computed property-vé alakítás
minden render cikluson újra futtatja az interpolációt (de ez csak string concat,
nem számottevő).

**T5 — Session határ: melyik fixing track fér egy sessionba?**
Javaslat: A + B egyben (Codable + observer leak) → egy session; C + részleges E
másik; D (god view refaktor) önálló session(ök).

---

## Következő lépés

Prioritizálás és session-bontás egyeztetése — **implementáció előtt**.
