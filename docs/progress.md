# countdownApp — Progress

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

