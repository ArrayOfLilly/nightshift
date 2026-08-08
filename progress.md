# countdownApp — Progress

## Session 22 — 2026-08-08

### In progress
- **Kulcs infó a usertől**: a beachball eddig mindig **több óra háttérben futás** után jelentkezett, nem a kattintgatás mennyiségétől függően — app indítás után azonnali intenzív kattintgatás/rendezgetés NEM vált ki hangot. Ez arra utal, hogy a felhalmozódás inkább az idő (== a `TimelineView` 1Hz tick száma) függvénye, nem a user-interakció mennyiségéé.
- **TEMP DEBUG bevezetve** — `CountdownView.swift`: `TimelineView(.periodic(from: .now, by: 1.0))` → `by: 0.01` (100× gyorsabb tick), hogy órákat percekbe sűrítsünk teszt céljából. **VISSZA KELL ÁLLÍTANI 1.0-ra a teszt után** — keresd a "TEMP DEBUG" kommentet a fájlban.
- Terv: ezzel a build-del futtatni Time Profilert ~10-20 percig (ez ekvivalens sok órányi valós tickel), és megnézni, jelentkezik-e a hang gyorsabban. Ha igen → erős bizonyíték, hogy a tick-szám maga a felhalmozódás forrása (pl. SwiftUI AttributeGraph / NavigationStack belső cache nem ürül hosszú futás alatt).

### Open tasks
- [ ] Time Profiler felvétel a felgyorsított build-del (0.01s tick), 10-20 perc, majd hang esetén backtrace elemzés.
- [ ] Ha megvan az eredmény: TimelineView interval VISSZAállítása 1.0-ra, commit.
- [ ] (Session 21-ből még nyitva) Korábbi 2 elkülönítő teszt (csak reorder / csak deadline-váltás) már kevésbé releváns, mivel órás időtáv kell hozzájuk — előbb a felgyorsított tick-teszt fut, az gyorsabb választ ad.
- Files changed: `CountdownView.swift` (TEMP, revert pending)

---

## Session 22 — 2026-08-08

### 🎯 FINDING — root cause candidate located

**Trigger nem a drag/deadline-váltás maga volt, hanem egy sima SCROLL kb. 1 perccel a matatás (active/free váltogatás + reorder) UTÁN.** Előtte semmi gyanús, utána semmi gyanús — egyetlen tű a szénakazalban.

Backtrace a Severe Hang pillanatában (innermost → outward):
```
AG::Subgraph::foreach_ancestor<AG::Subgraph::propagate_dirty_flags()::$_0>
AG::Subgraph::propagate_dirty_flags()
AG::Graph::propagate_dirty(AG::AttributeID)
AG::Graph::value_set(AG::data::ptr<AG::Node>, AGSwiftMetadata...)
LazyLayoutViewCache.updateItemPhase(_:)
LazyLayoutViewCache.updateItemPhases()
protocol witness for GraphMutation.apply() in conformance LazyL...
specialized GraphHost.runTransaction(_:do:id:)
GraphHost.flushTransactions()
... NSHostingView begin-transaction / Update.ensure / NSRunLoop observer flush ...
```

**Értelmezés**: a scroll a `LazyVStack`/`LazyLayoutViewCache` belső "item phase" trackingjét (mely elemek jelennek meg/tűnnek el) triggereli — ez normális, MINDEN scroll ezt csinálja. Ez egy `GraphMutation`-t indít, ami a SwiftUI AttributeGraph-ban `propagate_dirty` → `foreach_ancestor`-t hív, hogy az ÖSSZES érintett ős-node-ot dirty-nek jelölje. **Az hogy ez a lépés akad be** (nem maga a scroll logika) arra utal, hogy az ancestor-halmaz, amit be kell járni, kórosan nagy/mély.

**Munkahipotézis a következő session-nek**: a BUG-20 fix (Session 19) szándékosan MEGVÁLTOZTATJA a RowEntry identity-t (`"a-UUID"` ↔ `"f-UUID"`) minden active↔free átsoroláskor, hogy a SwiftUI friss view-t építsen a helyes megjelenéssel. Ez azt jelenti: minden egyes átsoroláskor egy ÚJ AttributeGraph subgraph jön létre a régi helyett. **Gyanú**: a régi subgraph-ok AttributeGraph-oldali könyvelése (nem feltétlen a Swift ARC-retain, hanem az AG saját belső gráf-node nyilvántartása) nem ürül ki tökéletesen minden reclassification után — így minden active↔free váltás egy kicsit növeli az ancestor-halmazt, és elég sok váltás után BÁRMILYEN, akár teljesen független graph-mutation (mint egy scroll) hosszú `foreach_ancestor` bejárást fizet meg.

Ez magyarázza mindent, amit eddig láttunk:
- Miért nem gond azonnal indítás után (kevés váltás történt még).
- Miért nem a passzív tick-szám a hibás (a 87 "szimulált" perc sima háttérfutás nem generált átsorolást, csak tick-eket — ezért volt negatív az eredmény).
- Miért egy LÁTSZÓLAG független művelet (scroll) váltja ki, nem közvetlenül a váltás/reorder maga.

### Next steps (következő session)
- [ ] Igazolás: Allocations vagy Leaks instrument-tel megnézni, hogy az AG::Graph node-szám (vagy a process memória) monoton nő-e minden active↔free váltással, sosem csökken.
- [ ] Ha igazolódik: keresni egy BUG-20-fixet, ami NEM cserél teljes ForEach identity-t reclassificationkor (ami friss subgraph-ot épít), hanem valahogy MEGTARTJA az identity-t és csak egy belső flag/verzió-számláló bumpolásával kényszerít ki tartalom-frissítést a meglévő subgraph-on belül. Ez trükkösebb SwiftUI-manipuláció, alaposabban meg kell tervezni, hogy a free/active vizuális frissülés (amit BUG-20 eredetileg megoldott) ne törjön el újra.
- [ ] Alternatíva, ha a fenti túl kockázatos: explicit periodic "graph reset" workaround (pl. a NavigationStack/lista view-t időnként force-recreate-elni egy id()-cserével) — hack, de működhet tüneti kezelésként.
- Files changed: nincs kód-változás ebben a körben, csak diagnózis.

---

## Session 21 — 2026-08-08

### Completed
- **Font bundling végre lezárva** (Session 1 óta nyitott manual step) — a 4 `.ttf` fizikailag áthelyezve a kinti `/Users/ArrayOfLilly/tools/countdownApp/` gyökérből a `countdownApp/countdownApp/resources/Font/` alá; a projekt Xcode 16 file-system-synchronized group-ot használ, tehát a pbxproj automatikusan felvette target membership-pel (nem kellett manuális pbxproj szerkesztés).
  `countdownAppApp.swift`: `init()`-ben `CTFontManagerRegisterFontsForURL(_:.process:_)` hívás mind a 4 fontra (`Bundle.main.url(forResource:withExtension:)`, subdirectory fallback "Font"-ra is). `.process` scope = nem telepíti rendszerszinten, csak a futó app processzének regisztrálja. Ez független attól, hogy a Font Book-ban telepítve van-e a font — eddig valószínűleg CSAK azért működött a betűtípus, mert a user telepítette Font Book-ba, nem mert be volt csomagolva.
  (Info.plist `ATSApplicationFontsPath` NEM kellett — a projekt `GENERATE_INFOPLIST_FILE=YES`-t használ fizikai Info.plist nélkül, és a szinkronizált resource-csoport miatt a path-flattening kiszámíthatatlan lett volna; a runtime `CTFontManagerRegisterFontsForURL` megbízhatóbb és debug-olható (print log, ha egy font nem található).)

- **Beachball nyomozás — új infó + egy konkrét fix**: Time Profiler trace-t kaptunk (17 item, 4:19 perces felvétel, micro-hangok → Severe Hang a végén). A backtrace SwiftUI belső layout engine-ben (`UnaryLayoutEngine.sizeThatFits`, `PlacementContext.proposedSize.getter`, `AGGraphGetInputValue`) mutat aktív, valódi munkát — NEM deadlock/lock-wait. Kulcs infó a usertől: **app indítás után azonnal ugyanaz a kattintgatás NEM okoz hangot** — csak `hosszabb interakció/sok váltás UTÁN`. Ez inkább felhalmozódásra/torlódásra utal, mint egyszeri drága műveletre.
  `CountdownRowView.swift` átnézve — nincs benne Timer, Combine subscription, NotificationCenter observer, tehát nem klasszikus retain-cycle onnan.
  `CountdownView.swift` újraátnézve: a `FreeSlotDropDelegate.dropEntered` **minden egyes drag-hover eseménynél** (nem csak drop végén) `freeOrder = ids`-t írt, ami a régi `.onChange(of: freeOrder) { saveFreeOrder() }` miatt **szinkron UserDefaults írást váltott ki minden pointer-mozgásnál** egy drag közben — ha a drag sok hover-eseményt generál gyors egymásutánban, ez főszálon torlódó munkát jelent.
  **Fix**: `saveFreeOrder()` leválasztva a `freeOrder` mutációjáról. `FreeSlotDropDelegate` kapott egy `onCommit: () -> Void` closure-t, amit csak `performDrop`-ban (drop VÉGÉN) hív meg — a `.onChange(of: freeOrder)` modifier törölve. A törlés (delete) ág explicit hívja `saveFreeOrder()`-t is (korábban az onChange intézte).
  **Ez valószínűleg csak részleges fix** — a live-reorder-preview (a `freeOrder = ids` maga, minden hover-nél) továbbra is minden hover-eseménynél teljes ForEach re-diff-et vált ki; ezt szándékosan nem bántottam (UX-döntés, nagyobb átalakítás kéne). A "aktív/free váltás" trigger (RowEntry identity csere `a-`/`f-` prefix miatt, ld. BUG-20) külön gyanús marad — AttributeGraph subgraph teardown/rebuild overhead-jét nem tudom bizonyítani statikus kódolvasásból.

### Open tasks
- [ ] Teszt: PUSZTÁN reorder (semmilyen active/free váltás nélkül) okoz-e még hangot a UserDefaults-debounce fix után?
- [ ] Teszt: PUSZTÁN deadline-szerkesztéssel kiváltott active↔free váltás (drag nélkül) okoz-e hangot?
- [ ] Ha igen a 2. kérdésre: RowEntry identity csere overhead-jét kellene profilozni (Instruments "SwiftUI" instrument, vagy Point of Interest jelölők a reclassification körül).
- Files changed: `countdownAppApp.swift`, `CountdownView.swift`, `resources/Font/*.ttf` (moved)

---

## Session 20 — 2026-08-08

### Completed
- **Session 19 BUG-20 fix commitolva** — a `RowEntry` identity fix (`CountdownItem.swift`, `CountdownView.swift`) korábban csak a working tree-ben volt, most bekerült a git history-ba a doksi-frissítésekkel együtt.
- **Header cleanup** — `countdownAppApp.swift`: az Xcode-generált Hungarian "Created by Ildikó Kasza on 2026. 08. 06.." sor lecserélve angol leíró kommentre, a projekt többi fájljának header-konvenciójához igazítva. Teljes .swift grep (á/é/í/ó/ö/ő/ú/ü/ű) lefuttatva — ez volt az egyetlen találat.
- **AppTheme.swift doc-hiba javítva** — a `freeColors` tömb feletti komment 11-et írt, a tömbben ténylegesen 12 szín van (30271B, 51422E, 778005, 4D70D8, 293B72, 403873, 593C73, 723F73, 8A4273, DD3B72, DD114A, B70E26); komment frissítve 12-re.
- **spec.md pontatlanságok javítva + angolra egységesítve**:
  - „Jövőbeli ötletek” (mixed HU) szekció → „Implemented Enhancements” + „Performance — Beachballing Fix” szekciókra cserélve, teljesen angolul, BUG-18/19/20 + Session 17 (N per-row timer) root cause-okkal dokumentálva.
  - Színpaletta: mindenhol 11 → 12-re javítva (Countdown Mode szekció, Data Model, Implemented Enhancements).
  - Fallback szín leírás javítva: NEM hash-alapú, hanem fix default index 6 (#593C73 lila) — a tényleges CountdownRowView.swift kód alapján ellenőrizve.
  - `CountdownItem.accentColorIndex` mező hozzáadva a Data Model listához (korábban hiányzott a spec-ből).
- **countdownApp-manual.md ellenőrizve** — tartalmilag pontos, nincs javítás szükséges (már helyesen "twelve accent colors" / "#593C73" szerepel benne).
- **Git commit** (inner repo, /Users/ArrayOfLilly/tools/countdownApp/countdownApp): BUG-20 fix + header/doc cleanup egy commitban.
- Files changed: countdownAppApp.swift, AppTheme.swift, spec.md, progress.md

### Open tasks
- None.

---

## Session 19 — 2026-08-08

### Completed
- **BUG-18 FIX — NavigationLink destination eager construction minden TimelineView ticknél** —
  `CountdownItem.swift`, `CountdownView.swift`.
  Root cause: a `ForEach`-en belüli `NavigationLink { CountdownDetailView(...) }` szintaxis
  a destination closure-t minden render-passnál kiértékeli. A `TimelineView` 1 Hz-en tickel,
  tehát másodpercenként az összes sor `CountdownDetailView`-ja létrejött és azonnal
  megsemmisült — még ha a user nem navigált sehova.
  Fix:
  1. `CountdownItem`: `Hashable` conformance hozzáadva (`NavigationLink(value:)` feltétele).
  2. `CountdownView`: Mindkét `ForEach`-ben `NavigationLink(value:)` pattern.
  3. `CountdownView`: `.navigationDestination(for: CountdownItem.self)` a NavigationStack-re.
  Eredmény: nincs per-tick `CountdownDetailView` allokáció.

- **BUG-19 FIX — Free slot nem kerül át active-ba deadline változtatás után** —
  `CountdownView.swift`.
  Root cause: a `.navigationDestination` closure-ban `$items[idx]` direct subscript
  binding volt, ahol az `idx` a navigálás pillanatában lett rögzítve. Ha az `items`
  tömb ezután mutálódott (deadline frissítés → active/free átsorolás), az `idx` stale
  maradt — a módosítás nem propagálódott az `activeItems`/`orderedFreeItems` számításhoz.
  Fix: `.navigationDestination` closure-ban `$items[idx]` helyett `binding(for: item)`
  helper — ez mindig ID alapján keres a live `items` tömbben, sosem stale.

- **BUG-20 FIX — Átsorolt slot megjelenése nem frissül (free→active vizuális stale)** —
  `CountdownView.swift`.
  Root cause: a két `ForEach` ugyanazt az `item.id` UUID-t használta SwiftUI identity-ként.
  Amikor egy item átkerült a free listából az active listába, a SwiftUI az azonos UUID
  alapján recycle-özte a `CountdownRowView`-t — nem hozta létre újra, így a free megjelenés
  (accent color, FREE ✓ badge, nincs toggle gomb / countdown) megmaradt.
  Fix: `RowEntry` private wrapper struct hozzáadva (`item` + `slotKind: "a"/"f"`),
  `id` computed property = `"a-UUID"` / `"f-UUID"`. A két `ForEach` egyetlen
  `ForEach(entries)` hívásra cserélve `RowEntry` elemekkel — átsoroláskor az ID
  megváltozik, a SwiftUI új view-t hoz létre a helyes megjelenéssel.
- Files changed: `CountdownItem.swift`, `CountdownView.swift`

### Open tasks
- None.

---

## Session 18 — 2026-08-08

### Diagnosed (not yet fixed)

- **PERF — NavigationLink destination allokálódik minden TimelineView ticknél** — `CountdownView.swift`.
  Root cause: a `ForEach`-en belüli `NavigationLink { CountdownDetailView(...) }` szintaxis
  a destination closure-t minden render-passnál kiértékeli. A `TimelineView` 1 Hz-en
  tickel, tehát másodpercenként az összes aktív és free sor `CountdownDetailView`-ja
  létrejön és azonnal megsemmisül — még ha a user nem navigál sehova.
  Az `sample` trace-ből bizonyítható:
    assignWithCopy for CountdownDetailView   <- allokáció minden ticknél
    LocationBox.__deallocating_deinit        <- azonnal deallokál
    swift_getTypeByMangledName               <- generic típusmetadata re-resolve
      Demangler::demangleType
        NavigationLink.body.getter
  Ez önmagában nem okoz beachballt (a trace 98%-a idle mach_msg), de felesleges
  folyamatos allokáció/deallokáció + Swift runtime demangling minden ticknél.

  Fix terv: NavigationLink<Label, Destination> destination closure lecserélése
  .navigationDestination(isPresented:) + @State var selectedItem: CountdownItem?
  kombinációra — CountdownDetailView csak navigáláskor konstruálódik.
  Alternatíva: NavigationLink(value:) + .navigationDestination(for:);
  ehhez CountdownItem-nek Hashable conformance kell.

### Open tasks
- [ ] BUG-18: NavigationLink destination eager construction fix (CountdownView.swift)

---

## Session 17 — 2026-08-08

### Completed
- **PERF FIX — beachballing a CountdownView-ban** — `CountdownRowView.swift`, `CountdownView.swift`.
  Root cause: minden `CountdownRowView` saját `TimelineView(.periodic(from: .now, by: 1.0))`-t
  tartalmazott. N sor = N timer, mindegyik másodpercenként triggerelte a SwiftUI render-ciklust
  és a `CountdownView.itemList` újraszámolását (`activeItems` + `orderedFreeItems` sortokkal),
  ami main thread torlódást okozott beachballinggal.
  Fix: a `TimelineView` felkerült a `CountdownView.itemList` szintjére (egyetlen timer),
  `ctx.date` lekerül `now: Date` paraméterként minden `CountdownRowView`-hoz.
  `CountdownRowView.body` egyszerűen `rowContent(at: now)`-t hív, nincs saját timer.
- **FOCUS FIX — AddCountdownSheet TextField** — `AddCountdownSheet.swift`.
  A `TextField` hiányzó `.focusable(false)`-t kapott; sheet megnyitásakor a FocusBridge
  window-mismatch hibát okozhatott.
- **UI — holdak U-ív alakban** — `CalculateView.swift`.
  A 9 `pink_moon` kép korábban egyenes `HStack`-ben volt. Most `GeometryReader` +
  parabolaoffset: `t = i / 8` (0…1), `arcOffset = arcDepth * (4t² - 4t)` → a szélső
  holdak fent, a középső (5-ös) lent, látványos U-ív. `arcDepth = 28pt`, `frame(height: 80)`.
- Files changed: `CountdownRowView.swift`, `CountdownView.swift`, `AddCountdownSheet.swift`, `CalculateView.swift`

### Open tasks
- None.

---

## Session 16 — 2026-08-07

### Completed
- **Stepper long-press repeat** — `LongPressStepperButton.swift` (új fájl),
  `CountdownDetailView.swift`, `CalculateView.swift`.
  Új `LongPressStepperButton` struct: `DragGesture(minimumDistance: 0)` alapú,
  `onChanged` → azonnali első lépés + `Timer` indítása `initialDelay` (0.40s) után,
  lejárt timer `startRepeating()`-et hív amely `repeatInterval` (0.08s) ütemben
  ismétli az action-t; `onEnded` → timer invalidate. Rövid tap = 1 lépés, nyomva
  tartás = gyorsuló ismétlés. Mindkét view `componentStepper` helpere `Button` →
  `LongPressStepperButton` cserére frissítve, szín paraméterei igazítva.
- **Calculate oldal — állapotmegőrzés** — `CalculateView.swift`.
  `@State` Date páros → `@AppStorage("calculateFromDate/ToDate")` Double
  (TimeInterval). Computed `fromDate`/`toDate` property-k wrap-elik a storage-t,
  `adjustDate` binding-ja érintetlen. Az utoljára beállított From/To értékek
  megmaradnak újraindítás után.
- **Calculate oldal — NOW reset gomb** — `CalculateView.swift`.
  A „TO" felirat mellé inline `NOW` gomb kerül (`arrow.counterclockwise` ikon +
  szöveg, `Color.white.opacity(0.12)` háttér, amber fg), amely `toInterval =
  Date().timeIntervalSince1970`-re állítja a To értéket. From-ot nem érinti.
- **spec.md frissítve** — mindkét szekció implementáltra átírva.
- Files changed: `LongPressStepperButton.swift` (új), `CountdownDetailView.swift`,
  `CalculateView.swift`

### Open tasks
- None.

---

## Session 15 — 2026-08-07

### Completed
- **Free-slot kézi színválasztó implementálva** — `AppTheme.swift`, `CountdownItem.swift`,
  `CountdownDetailView.swift`, `CountdownRowView.swift`, `ColorPickerSheet.swift` (új fájl).
  - `AppTheme.freeColors`: mind a 11 szín uncommentálva (korábban csak 1 aktív volt).
  - `CountdownItem`: `accentColorIndex: Int?` mező hozzáadva (nil = auto hash-fallback,
    backward compatible Codable decode).
  - `CountdownDetailView`: `showColorPicker: Bool` state + ecset (`paintbrush`) gomb a
    trash elé, csak expired slotokon látható; `.sheet(isPresented:)` nyitja a picker sheetet.
  - `CountdownRowView`: `itemFreeColor` mostantól `item.accentColorIndex`-et használja,
    ha set; egyébként marad a hash-alapú fallback.
  - `ColorPickerSheet` (új fájl): sheet view, 4 oszlopos `LazyVGrid` a 12 swatchnak
    (11 palettaszín + 1 AUTO/reset). Kiválasztás után dismiss. Tematika: amber háttér,
    Alien League Bold cím, `.focusable(false)` minden gombon.
- **spec.md frissítve** — Free-slot kézi színválasztó szekció "implementált"-ra átírva.
- Files changed: `AppTheme.swift`, `CountdownItem.swift`, `CountdownDetailView.swift`,
  `CountdownRowView.swift`, `ColorPickerSheet.swift` (új)

### Open tasks
- None.

---

## Session 14 — 2026-08-07

### Completed
- **CalculateView háttérszín** — `AppTheme.swift`, `CalculateView.swift`.
  Új `AppTheme.calculateBackground = #060503` (majdnem fekete, minimális meleg tinta).
  `AppTheme.dark` érintetlen — csak a CalculateView `.ignoresSafeArea()` háttere váltott.
- Files changed: `AppTheme.swift`, `CalculateView.swift`

### Open tasks
- None.

---

## Session 13 — 2026-08-07

### Completed
- **CRASH FIX — FocusBridge további források** — `CountdownView.swift`, `AddCountdownSheet.swift`.
  Két további focusable elem maradt:
  1. `NavigationLink` macOS-on Button-ként vesz részt a key view loopban — a CountdownView
     aktív és free sorainál egyik sem kapott `.focusable(false)`-t. Fix: mindkét
     NavigationLink-re hozzáadva.
  2. Az `AddCountdownSheet` stepper 10 chevron gombja szintén maradt `.focusable(false)`
     nélkül. Fix: hozzáadva mindkettőre.
- Files changed: `CountdownView.swift`, `AddCountdownSheet.swift`

### Open tasks
- None.

---

## Session 12 — 2026-08-07

### Completed
- **CRASH FIX — FocusBridge a CountdownRowView toggle gombjától** —
  `CountdownRowView.swift`.
  A toggle gomb `.buttonStyle(.plain)` volt, de `.focusable(false)` nem — így benne
  maradt a SwiftUI key view loopban. A `TimelineView(.periodic(from: .now, by: 1.0))`
  másodpercenként újrarendereli az összes aktív sort, ami másodpercenként triggerelte
  a FocusBridge-et minden látható toggle gombra → KeyViewProxy window-mismatch crash.
  Fix: `.focusable(false)` hozzáadva a toggle Button-hoz.
- Files changed: `CountdownRowView.swift`

### Open tasks
- None.

---

## Session 11.2 — 2026-08-07

### Completed
- **CRASH FIX (complete) — FocusBridge KeyViewProxy window-mismatch** —
  `CountdownDetailView.swift`.
  Session 10's fix was incomplete: it removed `@FocusState` (correct) but left two
  additional FocusBridge triggers intact.

  **Trigger 1 — `makeFirstResponder` async dispatch in `FocusedNSTextField.updateNSView`:**
  Calling `nsView.window?.makeFirstResponder(nsView)` (even via `DispatchQueue.main.async`)
  causes AppKit to notify SwiftUI's hosting infrastructure via the responder-chain
  observation path. SwiftUI then calls `FocusBridge.moveFocus`, which tries to validate
  a `KeyViewProxy` that is not yet attached to any window → "different window (null)".
  Fix: removed the `makeFirstResponder` dispatch and the `didRequestFocus` Coordinator
  property entirely.

  **Trigger 2 — focusable `Button` elements in the key view loop:**
  `.buttonStyle(.plain)` on macOS does NOT remove focusability. All 13 buttons in
  CountdownDetailView participated in the SwiftUI key view loop.
  Fix: added `.focusable(false)` to every button in CountdownDetailView.
- Files changed: `CountdownDetailView.swift`

### Open tasks
- None.

---

## Session 11.1 — 2026-08-07

### Completed
- **BUG FIX — stepper nincs vizuális visszajelzés szerkesztés közben** —
  `CountdownDetailView.swift`.
  Root cause: `@Binding var item` write (`item.deadline = newDate`) eljut a CountdownView-ba
  és frissíti `items[idx]`-et, de macOS NavigationStack destination esetén SwiftUI nem
  garantálja az azonnali re-rendert a detail view-ban. A stepper értékek csak kilépés
  után frissültek.
  Fix: `@State private var localDeadline: Date` hozzáadva mint lokális tükör.
  `component()` és `monthAbbrev()` ebből olvas (azonnali @State re-render).
  `adjust()` mindkettőt írja. `.onAppear` mindkettőt szinkronizálja.
- Files changed: `CountdownDetailView.swift`

### Open tasks
- None.

---

## Session 10 — 2026-08-07

### Completed
- **CRASH FIX (partial) — FocusBridge KeyViewProxy window-mismatch** — `CountdownDetailView.swift`:
  root cause: `@FocusState private var labelFocused: Bool` inside a NavigationLink
  destination on macOS causes SwiftUI's `FocusBridge` to attempt AppKit first-responder
  assignment on every render pass before the view is attached to a window.
  Fix: removed `@FocusState` entirely; replaced with `FocusedNSTextField`
  (`NSViewRepresentable` wrapping `NSTextField`).
- Files changed: `CountdownDetailView.swift`

### Open tasks
- None.

---

## Session 9 — 2026-08-07

### Completed
- **Moon strip responsive sizing** — `CalculateView.swift`: replaced `GeometryReader` +
  `ScrollView` with plain `HStack(spacing: 12)`, `.frame(maxWidth: .infinity)` per image.
- **Free-slot deadline stepper — defensive adjust() fix** — `CountdownDetailView.swift`:
  added second snap guard directly inside `adjust()`.
- Files changed: `CalculateView.swift`, `CountdownDetailView.swift`

### Open tasks
- None.

---

## Session 8 — 2026-08-07

### Decisions (user, closed — no further action)
- **Swipe-to-delete in list**: not needed — delete stays DetailView-only. Closed.
- **Tap-to-edit label in list**: intentional as-is. Closed.

### Completed
- **CalculateView moon strip replaced** — pink moon series, horizontal ScrollView.
- **BUG FIX — free-slot deadline uneditable in DetailView**: `.onAppear` snaps
  `item.deadline = Date()` once if expired; `component()`/`adjust()` read/write directly.
- Files changed: `CalculateView.swift`, `CountdownDetailView.swift`

---

## Session 7 — 2026-08-07

### Completed
- **Free slot manual reorder implemented** — CountdownView.swift teljesen atirva:
  `freeOrder [UUID]`, `draggingID`, `activeItems(at:)`, `orderedFreeItems(at:)`,
  `binding(for:)`, `.onDrag`/`.onDrop`, `FreeSlotDropDelegate`, `saveFreeOrder()`/`loadFreeOrder()`.
- Files changed: `CountdownView.swift`

---

## Session 6 — 2026-08-07

### Completed
- Pencil icon removed; toggle kör hozzáadva; pill vertical padding csökkentve.

---

## Session 5 — 2026-08-07

### Completed
- Pill vastagság, toggle gomb, detail nézet alapértelmezett, tab váltó, ikon-hozzárendelés,
  AddCountdownSheet focus ring, account name pill, alapértelmezett nézet.

---

## Session 4 — 2026-08-07

### Completed
- Per-account free color → single color; FREE ✓ badge; deadline szerkesztés stepper;
  alapértelmezett deadline Date(); macOS build fixek; TextField foregroundColor fix;
  Paradicsom méret 420px; Account label 36pt.

---

## Session 3 — 2026-08-07

### Completed
- FREE SLOT HIGHLIGHT: freeGreen, zöld háttér, fehér fg, glow shadow, "FREE ✓" badge.

---

## Session 1+2 — 2026-08-07

### Completed
- Calculate mode; Countdown mode architektúra: CountdownView, CountdownDetailView,
  CountdownRowView, AddCountdownSheet, CountdownItem (Codable, Equatable, Identifiable).

### Manual Xcode steps STILL NEEDED
- [x] Assets.xcassets: add spooky_tomato.png (name: "spooky_tomato") — done (session unknown, verified working Session 20)
- [x] Fonts bundled + registered at runtime — done Session 21 (see above; moved to resources/Font/, CTFontManagerRegisterFontsForURL in countdownAppApp.swift; no Info.plist key needed)
- [x] Project Navigator: Add Files — done (Xcode 16 file-system-synchronized group, automatic)
- [x] Verify Alien League PostScript name in Font Book — superseded Session 21 (font now bundle-registered, Font Book install no longer required)

---

## Session 23 — 2026-08-08

### Diagnosztika — Allocations + külső statikus elemzés

**Allocations eredmény (Mark Generation teszt):**
- Gen C (baseline): 2,39 KiB / 41 obj
- Gen D (15 active→free váltás után): 12,29 MiB / 48 896 obj — nagy ugrás
- Gen E (15 free→active váltás után): 2,97 MiB / 18 976 obj — részleges visszaesés
- Következtetés: monoton felhalmozódás NEM igazolódott. Az AG-subgraph akkumuláció hipotézis (Session 22) nem bizonyított.

**Gemini statikus elemzés — 3 valós találat:**

1. `binding(for:)` minden ticknél új Binding struct (CountdownView.swift ~line 110):
   Minden ticknél az összes sorhoz új Binding<CountdownItem> példány. SwiftUI nem tudja
   equality-check-elni → minden sor subgraphja potenciálisan dirty → propagate_dirty torlódás.
   VALÓSZÍNŰLEG A FŐ OK.

2. `.onDrop(delegate:)` minden ticknél új FreeSlotDropDelegate (CountdownView.swift ~line 173):
   A delegate struct ($freeOrder, $draggingID Bindingekkel) minden ticknél újra létrejön.
   Overhead valós, a "AppKit subgraph explosion" magyarázat spekulatív.

3. RowEntry identity csere ("a-UUID"/"f-UUID"): ismert (BUG-20), másodlagos gyanú.

4. LongPressStepperButton Timer double-add (LongPressStepperButton.swift ~line 48):
   Valós bug (timer leak), de nem beachball-forrás.

### Tervezett fixek (külön sessionökre bontva, prioritás sorrendben)

- Session 23-A: binding(for:) kiváltása — stabil Binding generálás TimelineView-on belül.
- Session 23-B: onDrop delegate kiemelése a tick-loopból.
- Session 23-C (opcionális): RowEntry identity alternatíva ha A+B nem elég.
- Session 23-D: LongPressStepperButton timer double-add fix.
- Minden session végén: TimelineView tick visszaállítása 1.0-ra + commit, ha fix tesztelve.

### Open tasks
- [ ] ChatGPT statikus elemzés beérkezése + összehasonlítás Gemini-vel.
- [ ] Session 23-A: binding(for:) fix.
- [ ] Session 23-B: onDrop delegate fix.
- [ ] Session 23-C: RowEntry identity alternatíva (ha szükséges).
- [ ] Session 23-D: Timer double-add fix.
- [ ] TimelineView tick visszaállítása 1.0-ra és commit.

---

## Session 23-A terv — 2026-08-08

### Diagnózis összefoglaló (Gemini + ChatGPT alapján)

A beachball root cause: a `TimelineView` minden ticknél (`0.01s` / normálisan `1s`)
meghívja `rowEntries(at:)` + `orderedFreeItems(at:)` függvényeket, amelyek új array-t
adnak vissza → `ForEach(entries)` minden ticknél teljes diff-et futtat →
`LazyLayoutViewCache.updateItemPhases()` minden ticknél dolgozik.
Ez önmagában 1Hz-en kezelhető. De sok active↔free váltás után a LazyVStack belső
layout cache-e egyre több "phase transition" historyt halmoz, és amikor scroll érkezik
(`LazyLayoutViewCache.updateItemPhases` → `AG::Subgraph::foreach_ancestor`),
a teljes ancestor-bejárás drágává válik.

### Tervezett fix — `cachedEntries` szétválasztás

**Probléma:** `rowEntries()` és `orderedFreeItems()` a `TimelineView` closure-on BELÜL
fut, minden tick újraszámolja az összes item osztályozását és rendezését, és új
array-t ad a `ForEach`-nek — még akkor is ha SEMMI sem változott.

**Fix lényege:** a ForEach inputját (`[RowEntry]`) leválasztani a tick-ről.
Az entries-t csak akkor kell újraszámolni, amikor ténylegesen változik valami:
- `items` mutál (deadline szerkesztés, törlés, hozzáadás)
- `freeOrder` mutál (drag reorder)
- Egy item deadline-ja átlép (active→free osztályozás változik)

**Implementáció:**

1. Új `@State` változók:
   ```swift
   @State private var cachedEntries:   [RowEntry]       = []
   @State private var cachedFreeItems: [CountdownItem]  = []
   @State private var nextDeadline:    Date?             = nil
   ```

2. `rebuildEntries(now:)` helper — kiszámítja az entries-t és a nextDeadline-t
   (a legközelebbi még-aktív deadline, amikor az entries legközelebb változni fog):
   ```swift
   private mutating func rebuildEntries(now: Date) {
       cachedEntries   = rowEntries(at: now)
       cachedFreeItems = orderedFreeItems(at: now)
       nextDeadline    = items
           .filter { !$0.isExpired(at: now) }
           .map { $0.deadline }
           .min()
   }
   ```

3. A `TimelineView` closure-on BELÜL csak `now`-t használ megjelenítésre;
   az entries-t a cached state-ből veszi. Plusz: ha `nextDeadline` átlépett,
   triggerel egy rebuild-et:
   ```swift
   TimelineView(.periodic(from: .now, by: 0.01)) { ctx in
       let now = ctx.date
       // Deadline crossing check — cheap, no array alloc
       if let nd = nextDeadline, now >= nd {
           rebuildEntries(now: now)
       }
       ScrollView {
           LazyVStack { ForEach(cachedEntries) { ... } }
       }
   }
   ```

4. `.onChange(of: items)` és `.onChange(of: freeOrder)` meghívja `rebuildEntries`-t.

5. `.onAppear` után is `rebuildEntries` fut.

**Eredmény:** `ForEach(cachedEntries)` csak akkor kap új array-t, ha tényleg változás
történt — nem minden ticknél. A `LazyVStack` diff futása ritka esemény lesz,
nem folyamatos 100Hz-es munka.

### Érintett fájl
- `CountdownView.swift` — a `@State` változók, `rebuildEntries()`, `itemList`, `.onChange`, `.onAppear`

### Kockázatok
- A `mutating` nem működik `View`-n — `rebuildEntries` nem lehet mutating,
  helyette `cachedEntries = ...` direkten a closure-ban. Ellenőrizni kell, hogy
  a SwiftUI state-update a TimelineView closure-ból helyesen triggerel-e re-rendert.
- `nextDeadline` check: ha pontosan a tick határán lép át, egy tickkel késhet.
  Ez UX szempontból irreleváns (max 0.01s / 1s késés).

### Implementáció előtt ellenőrizni
- `CountdownItem.isExpired(at:)` definíciója — hogy a deadline check pontos legyen.

---

## Session 24 — 2026-08-08

### CalculateView bug list (new, not yet planned)

**CALC-1 — No years/months/weeks granularity**
The result only shows days, hours, minutes, seconds. No years/months/weeks breakdown.
Not yet planned — future enhancement.

**CALC-2 — Seconds not settable but always visible in result** ✅ FIXED Session 24
**CALC-3 — From = To still shows non-zero difference** ✅ FIXED Session 24
**CALC-4 — No "NOW" reset for From; "NOW" reset for To behaves incorrectly** ✅ FIXED Session 24

Fix: `snapToMinute()` helper floors any Date to minute boundary.
`adjustDate` snaps on every stepper write. Both NOW buttons snap.
NOW button added to FROM label; standalone "RESET TO NOW" button removed.

**CALC-1 — No years/months/weeks granularity** — partially planned, see below.

### CALC-1 implementation plan

**Concept:** two display modes for the result, toggled by the user.
- **DAYS mode** (current): fixed, context-free `d h m s` breakdown. Always shown by default.
- **CAL mode** (new): calendar-aware `y mo d h m s` via `cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: fromDate, to: toDate)`. Leading zero components hidden (e.g. if 0 years and 0 months, show only `d h m s`).

**Toggle:**
- Placed below the result row.
- Two buttons styled like the RESET FROM/TO NOW buttons (same font, padding, background, cornerRadius).
- Labels: `DAYS` and `CAL`.
- Active button: stronger background (e.g. `Color.white.opacity(0.35)`) or amber fill.
- `@AppStorage("calculateDisplayMode")` persists the selection (`"days"` / `"cal"`).

**Implementation notes:**
- `resultParts` stays as-is for DAYS mode.
- New `calResultParts` computed var uses `Calendar.current.dateComponents` between `fromDate` and `toDate` (order-aware: always from the earlier to the later, sign tracked separately via existing `isFuture`).
- `resultRow` switches between the two based on mode.
- Weeks excluded (confusing alongside years/months).

---

### Completed

**23-A FIX — dropEntered guard** — `CountdownView.swift`, `FreeSlotDropDelegate.dropEntered`.
Egysoros fix: `freeOrder = ids` → `if ids != freeOrder { freeOrder = ids }`.
Hatás: drag hover minden egyes pointer-mozgásánál NEM mutálja `freeOrder`-t, ha az order
ténylegesen nem változott → nincs felesleges ForEach diff + LazyVStack reconciliation.

**23-B DIAG — LazyVStack → VStack csere** — `CountdownView.swift`, `itemList`.
`LazyVStack(spacing: 10)` → `VStack(spacing: 10)` (TEMP DIAG kommenttel ellátva).
Cél: ha a beachball eltűnik → `LazyLayoutViewCache.updateItemPhases()` igazolt tettes
→ 23-C (cachedEntries refaktor) indokolt. Ha nem tűnik el → más az ok.

⚠️ TEMP DEBUG (TimelineView 0.01s tick) még aktív — ne állítsd vissza!
⚠️ TEMP DIAG (VStack) még aktív — visszaállítás LazyVStack-re 23-C után.

### 23-B EREDMÉNY — IGAZOLVA
4 perc valós futás (0.01s tick) = ~6.7 óra szimulált idő. Korábbi Severe Hang határ: "több óra".
Eredmény: **NEM volt Severe Hang.** 39 db "Potential Interaction Delay" (38–204ms) — normális.
Konklúzió: `LazyLayoutViewCache.updateItemPhases()` volt a fő tettes.
→ **23-C (cachedEntries refaktor) indokolt és soron következő.**

### Open tasks
- [x] 23-A: dropEntered guard — KÉSZ
- [x] 23-B: LazyVStack → VStack diag — KÉSZ, IGAZOLT
- [x] 23-C: cachedEntries szétválasztás — KÉSZ
- [ ] 23-D: LongPressStepperButton timer double-add fix (önálló)
- [x] TimelineView tick visszaállítása 1.0-ra — KÉSZ
- [x] VStack véglegesítve (LazyVStack visszaállítás visszavonva) — KÉSZ, igazolva
- Files changed: `CountdownView.swift` (23-A guard + 23-B VStack permanent + 23-C cachedEntries + 1.0s tick)

### 23-B VÉGLEGES KONKLÚZIÓ (Session 23 zárása)
A LazyVStack visszaállítása Severe Hangot okozott azonnal a tesztelés során (Instruments
képernyőképekkel igazolva). A VStack nem temp diagnosztika, hanem a végleges fix.
Root cause megerősítve: `LazyLayoutViewCache.updateItemPhases()` scroll-trigger →
`AG::Subgraph::foreach_ancestor` walk → Severe Hang, active↔free reclassification
ciklusok után. VStack-nél ez a mechanizmus nem létezik.
Commit ready: minden TEMP flag eltávolítva, kód production állapotban.

---

## SUN-1 — Sunrise/sunset sheet (tervezett, nem implementált)

### Koncepció
A CalculateView hold-képei fölött hover („onHover‟) egy sheetet nyit,
amely a mai nap napfelkeltét és naplementejét mutatja, a te időzítési
use case-edhez igazítva (mikor lehet csendben fejleszteni, mikor kezd zavarni
a kötelező munka).

### API
`https://sunrisesunset.io/api/` — ingyenes, évente előre letölthető.
Paraméterek: `lat`, `lng`, `date`, `timezone`.
Releváns mezők a response-ból:
- `astronomical_twilight_begin` — legkorábbi csend+sötét pont
- `nautical_twilight_begin`
- `civil_twilight_begin` — innen kezd zavarni a világosodás
- `sunrise`
- `solar_noon`
- `sunset`
- `civil_twilight_end`
- `astronomical_twilight_end`

### Lokáció
Két forrás, user választ a sheeten egy gombbal:
- **Automatikus**: CoreLocation (`CLLocationManager`), engedély kéréssel.
- **Kézi**: koordináta mező a sheeten (lat/lng), `@AppStorage`-ban mentve.
Az utoljára használt koordináta megmarad; ha egyszer kézi, nem kell újra.

### Cache stratégia
`UserDefaults`-ban tárolt JSON — a lekérdezett napok adatait cache-eli,
nem kérdez le nálkül semmit. Lazán tölt: csak az aktuális nap szükséges
elsősorban; a cache-be mentés után napokért már nem hív API-t.

### Sheet UI (kezdeti)
- Háttér: a holdak látszanak mögötte (blur vagy opacity).
- Tartalom: időpontok listája, app-stílusban (Alien League font, amber/dark színek).
- Trigger: `.onHover` a holdak területén.

### Későbbi bővítés (backlog)
- Vizuális idővonal/ív ahol látszik hol tart most a nap a nap folyamán.

### Konszenzus (Gemini + ChatGPT, teljes kód alapján)

Nem AG-leak, hanem pathológikus invalidáció/reconciliation pattern:
- Timeline tick → új RowEntry array → ForEach diff → LazyLayoutViewCache munka minden ticknél
- dropEntered → freeOrder mutation minden hover-eventnél → felesleges state churn
- Scroll → LazyLayoutViewCache.updateItemPhases() → foreach_ancestor walk → beachball

### Végrehajtási sorrend

**23-A — dropEntered guard (triviális, 1 sor)**
CountdownView.swift, FreeSlotDropDelegate.dropEntered:
  if ids != freeOrder { freeOrder = ids }
Eddig minden hover-eventnél mutálta freeOrder-t, még ha az order nem változott.
Ez felesleges ForEach diff + LazyVStack reconciliation minden drag-mozdulatnál.

**23-B — LazyVStack → VStack diagnosztika**
Ideiglenesen VStack-ra cserélni. Ha eltűnik a beachball: igazolt hogy
LazyLayoutViewCache a tettes, és a cachedEntries refaktor (23-C) indokolt.
Ha nem tűnik el: a probléma máshol van (identity churn, binding overhead).

**23-C — cachedEntries szétválasztás (ha 23-B igazolja)**
rowEntries() és orderedFreeItems() kiemelése a TimelineView closure-ból.
@State cachedEntries + @State cachedFreeItems + nextDeadline check.
Csak .onChange(of: items) + .onChange(of: freeOrder) + deadline crossing triggerel rebuild-et.
Részletes terv: lásd "Session 23-A terv" bejegyzés feljebb.

**23-D — LongPressStepperButton timer double-add (önálló, kisebb)**
Timer.scheduledTimer + RunLoop.main.add(..., .common) kettős regisztráció fix.

**Minden session végén:** TimelineView tick visszaállítása 1.0-ra + commit.
