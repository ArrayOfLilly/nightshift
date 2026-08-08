# countdownApp — Progress

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
- [ ] Assets.xcassets: add spooky_tomato.png (name: "spooky_tomato")
- [ ] Drag 4 alienleague .ttf into Xcode (Copy + target membership)
- [ ] Info.plist: "Fonts provided by application" array with 4 filenames
- [ ] Project Navigator: Add Files → select all new .swift files
- [ ] Verify Alien League PostScript name in Font Book
