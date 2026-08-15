# countdownApp — Progress

## Session BW — 2026-08-15 (ENH-HELP-1 hiányzó xcstrings: 4 countdown item — LEZÁRVA)

### Session BW — LEZÁRVA
- [x] `docs/progress.md`, `docs/countdownApp-handoff.md` elolvasva
- [x] `Models/HelpContent.swift`, `Localizable.xcstrings` elolvasva — felfedeztük, hogy
  a `HelpContent.countdown` 4 item (`expand`, `copy`, `toggle`, `free`) hiányzik az xcstrings-ből;
  ENH-HELP-1 ✅ KÉSZ volt jelölve, de ez a 4×2=8 kulcs sosem lett beírva
- [x] `Views/Countdown/CountdownRowView.swift`, `CountdownView.swift`, `CountdownDetailView.swift`
  elolvasva — pontos feature leíráshoz (label-pill tap → clipboard copy+COPIED feedback;
  clock/calendar toggle → showRemaining per item; row tap → NavigationLink → full-screen detail;
  expired → FREE ✓ + amber glow + drag-to-reorder free section)
- [x] **`Localizable.xcstrings`** módosítva — 8 kulcs hozzáadva (`Filesystem:edit_file`, 3 insertion
  egy hívásban):
  - `help.countdown.copy.title`: "Copying the label"
  - `help.countdown.copy.body`: label-pill tap → clipboard, COPIED feedback, detail view copy button
  - `help.countdown.expand.title`: "Opening an item"
  - `help.countdown.expand.body`: row tap → full-screen detail (stepper, toggle, notes, sound, delete)
  - `help.countdown.free.title`: "Free slots"
  - `help.countdown.free.body`: deadline elérve → amber + FREE ✓, drag-reorder, expiry chime
  - `help.countdown.toggle.title`: "Time display toggle"
  - `help.countdown.toggle.body`: clock/calendar gomb → remaining↔deadline date, per-item mentve
- [ ] Build + vizuális ellenőrzés Help ablakban: **FELHASZNÁLÓ FELADATA**
- [ ] Git commit: **FELHASZNÁLÓ FELADATA**
  (javasolt üzenet: `ENH-HELP-1: add missing xcstrings for countdown expand/copy/toggle/free`)
- [x] **`Views/Help/HelpView.swift`** módosítva (UI méret + font + padding):
  - frame: `minWidth/maxWidth 560 → 640`, `minHeight 480 → 560`
  - item title font: `.system(.body, weight: .semibold)` → `.title3.semibold`
  - item body font: `.subheadline` → `.body`
  - HelpItemRow outer padding: `.vertical 4` → `.vertical 12`
  - screenshot maxWidth: `460 → 560`, screenshot padding: `.vertical 10 → .vertical 16`
- [x] **`App/countdownAppApp.swift`** módosítva: `helpWindow defaultSize 560×520 → 640×620`
- [x] **`Views/Help/HelpView.swift`** módosítva (hierárchia):
  - Section header: `.headline` → `.title2.bold`
  - VStack spacing: `6 → 10`
  - Body text: `.padding(.leading, 28)` — ikon szélességéhez indentálva, nem folyik egybe a címmel
- [x] `docs/progress.md` frissítve (ez a szekció)

**Következő session:** ENH-DEVDOCS-2 (README + install.md) vagy BUG-MANUAL-1 — egyeztetés alapján.

---

## Session BS — 2026-08-15 (ENH-HELP-1-S4 javítás: HelpScreenshot root cause fix + focusRect precíz remérés — LEZÁRVA)

### Session BS — LEZÁRVA
- [x] `docs/progress.md`, `docs/countdownApp-handoff.md` elolvasva
- [x] Felhasználó erős elégedetlensége a Session BR outputjával: "nincsen fix szélessége, ronda, alig van
  benne tartalom, a képek se stimmelnek — 2 db, az egyik nem is az, a másik nem ott"
- [x] `Views/Help/HelpView.swift`, `Models/HelpContent.swift`, `Components/HelpScreenshot.swift` elolvasva
  (jelenlegi állapot)
- [x] Mindkét S4-es screenshot asset (`help-calculate-sunpanel`, `help-countdown-notes`) forrás PNG-je
  átmásolva Claude gépére (`Filesystem:copy_file_user_to_claude`) és vizuálisan megvizsgálva
  pixelpontos cropping teszttel (Python/PIL)
- [x] **Root cause #1 ("nem ott" / "nem az" panasz)**: mindkét S4-es `focusRect` becslés téves volt
  — pixelpontosan újramérve a forrás PNG-ken (mindkettő 1144×2358):
  - `countdown.notes`: a régi `CGRect(x:0.82, y:0.15, w:0.15, h:0.15)` az ablak tetején (toolbar/naptár
    ikon terület) vágott ki egy régiót; az eye badge valójában a "belvarosba@gmail.com" sor jobb
    szélén van, ~75%-nál lentebb a képben
  - `calculate.sunpanel`: a régi `CGRect(x:0.1, y:0.5, w:0.8, h:0.35)` a teljes popup alsó felét +
    egy nagy üres fekete sávot vágott ki a 9-fázisú holdcsík helyett, ami valójában csak egy vékony
    sáv ~75-83%-nál
- [x] **Root cause #2 ("ronda", torzított/levágott képek)**: a `HelpScreenshot` a `focusRect`-et mindig
  egy FIX `CGSize(460,220)` dobozba "cover" módban (mindkét tengelyen skálázva, túllógás levágva)
  illesztette. Egy 9 elemből álló széles-alacsony holdcsík (~4.8:1 arány) vagy egy keskeny email+badge
  sáv (~5:1 arány) nem fér bele torzítás/durva vágás nélkül egy ~2.1:1 arányú dobozba — ez a komponens
  tervezési hibája volt, nem csak a focusRect becslésé
- [x] **`Components/HelpScreenshot.swift`** átírva: `targetSize: CGSize` paraméter → `maxWidth: CGFloat`;
  a magasságot mostantól a `focusRect` valós aránya határozza meg (nincs "cover"+vágás, nincs torzítás —
  pontosan az jelenik meg, amit a `focusRect` kijelöl, fix szélességgel skálázva)
- [x] **`Views/Help/HelpView.swift`** módosítva:
  - `HelpScreenshot(...)` hívás `targetSize:` → `maxWidth: 460`
  - **"nincs fix szélessége" panasz fix**: `List` `.frame(minWidth: 520, minHeight: 480)` →
    `.frame(minWidth: 560, maxWidth: 560, minHeight: 480)` — a szélesség mostantól ténylegesen
    fixált (nem csak minimum), a magasság szabadon nőhet a jövőbeli S5/S6 tartalommal; 560 egyezik
    a `countdownAppApp.swift` `helpWindow` scene `.defaultSize(width: 560, ...)` értékével
- [x] **`Models/HelpContent.swift`** módosítva:
  - `overview.what` — eltávolítva az `imageName: "screenshot"` (timer.png teszt asset) + a hozzá
    tartozó `focusRect`; ez egy S3-as geometria-teszt maradványa volt, sosem lett valós tartalomra
    cserélve, és nem is illik egy általános "mi ez az app" leíráshoz — most szöveg-only, mint a
    másik 3 overview item
  - `countdown.notes.focusRect` → `CGRect(x:0.13, y:0.75, w:0.36, h:0.035)` (email+eye badge sáv)
  - `calculate.sunpanel.focusRect` → `CGRect(x:0.09, y:0.75, w:0.79, h:0.08)` (9-fázisú holdcsík)
- [x] Végeredmény Python/PIL szimulációval ellenőrizve (a tényleges SwiftUI komponens logikáját
  reprodukálva) — mindkét kép tiszta, torzítás- és vágásmentes, a helyes tartalmat mutatja
- [ ] Build + vizuális ellenőrzés Xcode-ban: **FELHASZNÁLÓ FELADATA**
- [ ] Git commit: **FELHASZNÁLÓ FELADATA** (javasolt üzenet: `ENH-HELP-1-S4 fix: HelpScreenshot
  fit-width redesign, corrected focusRect for sunpanel/notes, removed stale overview.what test image,
  locked Help window width`)
- [x] `docs/progress.md` frissítve (ez a szekció)

**"Alig van tartalom" panasz — nem hiba, hanem várt állapot**: az Overview szekció jelenleg 4 itemet
tartalmaz, a Countdown/Calculate/Snippets/Recovery szekciók tartalma is még minimális — ez pontosan a
tervnek megfelelő: a `docs/countdownApp-handoff.md` "Következő session" listája szerint a teljes
tartalom-bővítés az **ENH-HELP-1-S5/S6** feladata, ami még nem történt meg. A jelenlegi sparse hatás
nagy részét valószínűleg a szélesség- és kép-hibák okozták (üres tér, félrevágott képek) — ezek
javítása után érdemes újra megnézni, mennyire tűnik "üresnek".

**Következő session:** build után vizuális ellenőrzés (ha a `focusRect` finomítás még mindig nem
tökéletes, további pixel-remérés szükséges lehet), utána ENH-HELP-1-S5 (Countdown + Calculate szekció
valós tartalma) vagy ENH-DEVDOCS-2.

---

## Session BR — 2026-08-15 (ENH-HELP-1-S4: HelpItemRow text wrapping fix + 2 screenshot asset — LEZÁRVA)

### Session BR — LEZÁRVA
- [x] `docs/progress.md`, `docs/countdownApp-handoff.md`, `docs/buglist.md` (ENH-HELP-1 szekció) elolvasva
- [x] `Views/Help/HelpView.swift` elolvasva (S3 output, jelenlegi állapot)
- [x] `Models/HelpContent.swift` elolvasva (S1–S3 output)
- [x] **Felhasználó észrevétele:** a Help overview items szövegei egy sorban jelennek meg, nincsen
  word wrapping/tördelés, ergo tagolatlan hatás — valójában az `Localizable.xcstrings` EN
  szövegei teljesen helyesek és értelmes hosszúsággúak, a probléma a UI layout-ban van
- [x] **`Views/Help/HelpView.swift`** módosítva — `HelpItemRow` VStack text wrapping javítása:
  - `Text(item.bodyKey)` mezőhöz `.lineLimit(nil)` hozzáadása (explicit word wrapping engedélyezés)
  - `VStack(alignment: .leading, spacing: 6)` omlóhoz `.frame(maxWidth: .infinity, alignment: .leading)`
    hozzáadása (List context-ban explicit szélességi constraint szükséges)
  - Hatás: szövegek szóköz/word-wrapped megjelennek a rendelkezésre álló szélességen belül
  - Fájl header frissítve S4 tag hozzáadásával
- [x] Git commit: `35b343e` (`ENH-HELP-1-S4: HelpItemRow text wrapping fix (lineLimit + frame maxWidth)`)
- [x] **Screenshot asszetek becsatolása:**
  - Felhasználó már importálta Xcode-ban: `04 Calculate View - Sun and Moon Data.png` +
    `05e CountDown View - Existing note.png` az `Assets.xcassets`-be
  - Átnevezve: `help-calculate-sunpanel.imageset`, `help-countdown-notes.imageset`
  - Xcode automatikusan az `Assets.xcassets/countdownApp/resources/` alá helyezte őket
- [x] **`Models/HelpContent.swift`** módosítva:
  - `calculate.sunpanel` item kiegészítve: `imageName: "help-calculate-sunpanel"`,
    `focusRect: CGRect(x: 0.1, y: 0.5, width: 0.8, height: 0.35)` → moon strip-et célozza
    (9 hold fázisok, középsőre kattintható); y=0.5 az image alsó felétől indul, h=0.35 a szalag
    magassága
  - `countdown.notes` item kiegészítve: `imageName: "help-countdown-notes"`,
    `focusRect: CGRect(x: 0.82, y: 0.15, width: 0.15, height: 0.15)` → eye badge-et célozza
    (expanded countdown sorban, jobb felső sarok, apró terület)
  - Megjegyzés: focusRect-ek becslés alapján kitöltve; build után vizuális ellenőrzés + finomítás szükséges
    ha a régió nem találja meg helyesen a moon strip / eye badge-et
- [x] Git commit: `87a3c7d` (`ENH-HELP-1-S4: HelpContent - add imageName + focusRect for sunpanel and notes items`)
  — commit egyben az imageset Contents.json + képfájlokat is hozzáadott az `Assets.xcassets`-hez
- [x] `docs/progress.md` frissítve (ez a szekció)

**Megjegyzés:** S4 3/4-e kész — az imageName + focusRect becslésből készült (nem vizuális ellenőrzés
után), build-es finetuning szükséges. Overview szekció test szövegei már teljesek (Localizable.xcstrings),
a screenshot geom komponens (S3) működik, szöveg wrapping működik (S4 text fix). Ezek után S5-ös
Countdown + Calculate szekció tartalmát lehet finalizálni, vagy build után egy gyors test-futás.

**Következő session:** ENH-HELP-1-S5 (Countdown + Calculate szekció) vagy S4 finalizálás (focusRect
finomítás build után), majd S5/S6.

---

## Session BN — 2026-08-14 (BUG-SNIPPETSAVE-1 + BUG-SNIPPETDUP-1 implementálva; BUG-SNIPPEDITBEACHBALL-1 valószínűleg megoldva mellékhatásként — LEZÁRVA)

### Session BN — LEZÁRVA
- [x] `docs/progress.md`, `docs/countdownApp-handoff.md`, `docs/buglist.md` elolvasva
- [x] `SnippetEditSheet.swift`, `Snippet.swift`, `SnippetsView.swift` elolvasva
- [x] Felhasználó külső elemzése (másik session/eszköz) megerősítette a root cause-okat — azonos
  konklúzió, azonos javasolt fix
- [x] **BUG-SNIPPEDITBEACHBALL-1** — felhasználó jelezte: egy korábbi, általános app-szintű hang/beachball
  hibát már javított (`LazyVStack` → `VStack` csere), és ezóta a snippet-editing beachball sem jött elő.
  "NEXT SESSION" adatméret-elmélet ELVETVE mint kizárólagos ok. Státusz 🟡 VALÓSZÍNŰLEG MEGOLDVA
  (nem megerősítve, alacsonyabb prioritás, ld. buglist.md)
- [x] **BUG-SNIPPETSAVE-1** — IMPLEMENTÁLVA: `SnippetEditSheet.swift` "Save and quit" ág elé
  `shouldSaveOnDisappear = false` a `commitSave()` elé
- [x] **BUG-SNIPPETDUP-1** — IMPLEMENTÁLVA: `SnippetEditSheet.snippet` `let` → `@State private var`;
  `commitSave()` sikeres mentés után `self.snippet = s`; `SnippetsView.showNewSheet` `onSave`
  closure `append` → id-alapú upsert (szükséges volt, különben a sheet-fix után is duplikálna)
- [x] Build: felhasználó saját gépén futtatva, OK
- [x] Git commit: `c8b3d5e`
- [x] `docs/buglist.md` — mindhárom bug frissítve (SAVE-1 ✅, DUP-1 ✅, BEACHBALL-1 🟡)
- [x] `docs/progress.md` + `docs/countdownApp-handoff.md` frissítve

**Következő session:** ENH-DEVDOCS-1 🟡 (fejlesztői dokumentáció) vagy ENH-HELP-1 🟡 (Help menü, 4
 nyitott egyeztetési pont a buglist.md-ben) — egyeztetés alapján. BUG-SNIPPEDITBEACHBALL-1
 megerősítése több használat után, mielőtt ✅ KÉSZ-re zárnánk.

---

## Session BO — 2026-08-14 (ENH-HELP-1-S1: adatmodell + xcstrings — LEZÁRVA)

### Session BO — LEZÁRVA
- [x] `docs/progress.md`, `docs/countdownApp-handoff.md`, `docs/buglist.md` (ENH-HELP-1 szekció) elolvasva
- [x] **`Models/HelpContent.swift`** létrehozva — `HelpItem` (id, titleKey, bodyKey, icon, imageName?, focusRect?)
  + `HelpSection` struct-ok; `HelpContent` enum 5 szekcióval, 11 itemmel (IconKeeper minta)
- [x] **`Localizable.xcstrings`** létrehozva — 27 kulcs (5 section title + 11×2 title+body), EN placeholder
  szöveg kitöltve; forrás nyelv: `"en"`
- [ ] Xcode project-be felvétel + build: **FELHASZNÁLÓ FELADATA** (mindkét fájl: HelpContent.swift +
  Localizable.xcstrings hozzáadása az Xcode target-hez)
- [ ] Git commit: **FELHASZNÁLÓ FELADATA** (`ENH-HELP-1-S1: HelpContent model + Localizable.xcstrings`)
- [x] `docs/buglist.md` ENH-HELP-1 frissítve (S1 ✅, státusz FOLYAMATBAN)
- [x] `docs/progress.md` frissítve

**Következő session:** ENH-HELP-1-S2 — HelpWindowID enum + HelpCommands struct + helpWindow scene
(`countdownAppApp.swift`) + `Views/Help/HelpView.swift` váz, `.searchable` id-alapú szűréssel.

---

## Session BP — 2026-08-14 (ENH-HELP-1-S2: HelpWindowID + HelpCommands + HelpView váz — LEZÁRVA)

### Session BP — LEZÁRVA
- [x] `docs/progress.md`, `docs/countdownApp-handoff.md`, `docs/buglist.md` (ENH-HELP-1 szekció) elolvasva
- [x] `countdownAppApp.swift` elolvasva (helpWindow scene + AboutCommands minta megértéséhez)
- [x] `Views/AboutView.swift` elolvasva (AboutWindowID + AboutCommands minta)
- [x] `Models/HelpContent.swift` elolvasva (S1 output, struktúra-ellenőrzés)
- [x] **`App/HelpWindowID.swift`** létrehozva — `enum HelpWindowID`, `static let id = "nightshift-help"`
- [x] **`App/HelpCommands.swift`** létrehozva — `struct HelpCommands: Commands`,
  `CommandGroup(replacing: .help)`, `Cmd+Shift+/`, `@Environment(\.openWindow)`
- [x] **`Views/Help/HelpView.swift`** létrehozva — `HelpView` (`.searchable`, id-alapú keyword szűrés,
  `filteredSections`), `HelpItemRow` private struct (Label + body text + screenshot placeholder comment)
- [x] **`Views/Help/` mappa** létrehozva (Filesystem MCP `create_directory`)
- [x] **`countdownAppApp.swift`** módosítva:
  - `.commands { ... }` blokkba `HelpCommands()` beillesztve (AboutCommands() után)
  - `helpWindow` scene hozzáadva: `WindowGroup(id: HelpWindowID.id) { NavigationStack { HelpView() } }`
    `.windowResizability(.contentMinSize)` + `.defaultSize(width: 560, height: 520)`
- [x] **`Localizable.xcstrings`** frissítve: `"help.menu.item"` kulcs hozzáadva (EN: "NightShift Help")
- [ ] Xcode project-be felvétel (3 új fájl): **FELHASZNÁLÓ FELADATA**
  - `App/HelpWindowID.swift`
  - `App/HelpCommands.swift`
  - `Views/Help/HelpView.swift`
- [ ] Build: **FELHASZNÁLÓ FELADATA**
- [ ] Git commit: **FELHASZNÁLÓ FELADATA** (`ENH-HELP-1-S2: HelpWindowID + HelpCommands + HelpView`)
- [x] `docs/buglist.md` ENH-HELP-1 frissítve (S2 ✅)
- [x] `docs/progress.md` + `docs/countdownApp-handoff.md` frissítve

**Következő session:** ENH-HELP-1-S3 — `Components/HelpScreenshot.swift` (focusRect-alapú kivágás/scale
komponens), 1 valós screenshottal tesztelve.

---

## Session BQ — 2026-08-14 (ENH-HELP-1-S3: HelpScreenshot komponens + HelpView bekötés — LEZÁRVA)

### Session BQ — LEZÁRVA
- [x] `docs/progress.md`, `docs/countdownApp-handoff.md`, `Claude.md` elolvasva
- [x] `Views/Help/HelpView.swift` elolvasva (jelenlegi állapot, S2 output)
- [x] `Models/HelpContent.swift` elolvasva (HelpItem struktúra, imageName/focusRect mezők)
- [x] `resources/Assets.xcassets` listázva — `screenshot.imageset` (timer.png) választva teszt assetnek
- [x] **`Components/HelpScreenshot.swift`** létrehozva — v1: `GeometryReader` +
  `Image(imageName).resizable().scaledToFill()`, majd `.scaleEffect(x: 1/focusRect.width,
  y: 1/focusRect.height, anchor: UnitPoint(focusRect.midX, focusRect.midY))`
- [x] **Vizuális ellenőrzés (felhasználó screenshot)** — a `scaledToFill()` már önmagában
  aránytorzítva illesztette a képet a konténerhez (ismeretlen intrinsic aspect vs. targetSize
  aspect), a rákövetkező `scaleEffect` ezt tovább torzította → a render **nyújtott/torzított**
  régiót mutatott a `focusRect`-nek megfelelő helyett (megerősítve felhasználói screenshot
  összehasonlítással: "torzítva és megnövelve" vs. "ha csak vágva lenne")
- [x] **`Components/HelpScreenshot.swift`** javítva (v2, még ugyanebben a session-ben) — a
  `scaledToFill`+`scaleEffect` kombináció eldobva. Új megközelítés: `NSImage(named:)?.size` a
  valós intrinsic méret lekérdezésére → `cropRect` számítás pont-térben a `focusRect`-ből →
  **egyetlen egyenletes (nem x/y-független) `scale` faktor** = `max(targetSize.width/cropRect.width,
  targetSize.height/cropRect.height)` → `ZStack(alignment: .topLeading)` + `.offset(-cropRect.minX*scale,
  -cropRect.minY*scale)` a pozicionáláshoz. Eredmény: tiszta vágás + egyenletes nagyítás, nulla
  torzítás. Ha a `focusRect` aránya nem egyezik a `targetSize` arányával, a többlet jobbra/lentre
  vágódik (top-leading anchor) — dokumentálva a fájl fejlécében
  `.clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium))` lekerekítéshez (változatlan)
- [x] **`Views/Help/HelpView.swift`** módosítva: `HelpItemRow`-ban a screenshot placeholder comment
  kicserélve valós `HelpScreenshot(imageName:focusRect:targetSize:)` hívásra
  (`targetSize: CGSize(width: 460, height: 220)`); fájl header frissítve (S2, S3 tag)
- [x] **`Models/HelpContent.swift`** módosítva: `overview.what` item kiegészítve
  `imageName: "screenshot"` + `focusRect: CGRect(x: 0.15, y: 0.2, width: 0.5, height: 0.4)` —
  geometria teszteléséhez, build után vizuálisan ellenőrizhető
- [x] Xcode project-be felvétel: **nem szükséges** — a target file system synchronized group
  automatikusan felveszi az új fájlokat
- [x] Build: OK (felhasználó megerősítette)
- [x] Git commit: `857ceae` (`ENH-HELP-1-S3: HelpScreenshot component + HelpView wiring`)
- [x] `docs/progress.md` frissítve
- [x] `docs/countdownApp-handoff.md` frissítve

**Következő session:** ENH-HELP-1-S4 — valós tartalom (title/body szövegek) az Overview szekcióhoz,
valós screenshot asset(ek) becsatolása a teszt `screenshot` asset helyett.

---

---

## Session BT — 2026-08-15 (ENH-HELP-1-S4 kép-megjelenítés egyszerűsítés — LEZÁRVA)

### Session BT — LEZÁRVA
- [x] `docs/progress.md`, `docs/countdownApp-handoff.md` elolvasva
- [x] `Components/HelpScreenshot.swift`, `Views/Help/HelpView.swift` elolvasva (Session BS output)
- [x] **Kontextus**: a felhasználó kézzel vágta ki a képeket (nem a `focusRect` logika vágja) —
  a képek az `Assets.xcassets`-ben az eredeti névvel találhatók (`help-calculate-sunpanel`,
  `help-countdown-notes`), de már a helyes méretre vágva
- [x] **Kérés**: ne vágj/maszkolj kódból; az arányuk eltér, csak a szélességük legyen azonos;
  alattuk/felettük több padding, mint volt
- [x] **`Components/HelpScreenshot.swift`** teljesen átírva — az egész focusRect/Canvas/NSImage
  crop logika eltávolítva; `focusRect: CGRect` paraméter törölve; új törzs:
  `Image(imageName).resizable().scaledToFit().frame(width: maxWidth).clipShape(…)` —
  a SwiftUI maga számolja a megjelenítési magasságot az intrinsic image arányból; nincs vágás,
  nincs torzítás, különböző arányú képek azonos szélességen
- [x] **`Views/Help/HelpView.swift`** módosítva — `HelpItemRow`-ban:
  - `if let imageName = item.imageName, let focusRect = item.focusRect` → `if let imageName = item.imageName`
    (focusRect binding törlése — már nem használjuk)
  - `HelpScreenshot(imageName:focusRect:maxWidth:)` → `HelpScreenshot(imageName:maxWidth:460)`
  - `.padding(.vertical, 10)` hozzáadva a screenshot-hoz (volt: 0 explicit, az outer VStack
    `.padding(.vertical, 4)` adta az egyetlen tért — most a kép külön 10pt-et kap felül és alul)
- [x] `Models/HelpContent.swift` **nem változott** — `HelpItem.focusRect` opcionális mező marad
  a modellben (nem okoz gondot, csak nincs a rendereléshez használva)
- [ ] Build + vizuális ellenőrzés: **FELHASZNÁLÓ FELADATA**
- [ ] Git commit: **FELHASZNÁLÓ FELADATA**
  (javasolt üzenet: `ENH-HELP-1-S4: HelpScreenshot simplified — pre-cropped images, scaledToFit, more padding`)
- [x] `docs/progress.md` frissítve (ez a szekció)

**Következő session:** ENH-HELP-1-S5 (Countdown + Calculate szekció valós tartalma) vagy
ENH-DEVDOCS-2 — build utáni megbeszélés alapján.

---

## Session BU — 2026-08-15 (ENH-HELP-1-S4 képek finalizálva — LEZÁRVA)

### Session BU — LEZÁRVA
- [x] `docs/progress.md`, `docs/countdownApp-handoff.md` elolvasva
- [x] Képek (`help-countdown-notes`, `help-calculate-sunpanel`) kézzel újravágva és
  lekerekítve (felhasználó) — a kód nem alkalmaz semmilyen clip/mask/cornerRadius-t,
  a lekerekítés a képfájlban van; sárga ~8px, sötét ~12px sarokrádiusz
- [x] `HelpScreenshot.swift` kód-oldali lekerekítési kísérletek (`clipShape`, `mask`,
  Canvas `context.clip`) mind csendben kudarcot vallottak macOS List kontextusban —
  végül eltávolítva, megoldás: képben van a lekerekítés
- [x] Vizuális eredmény: rendben (screenshot megerősítve)
- [ ] Git commit: **FELHASZNÁLÓ FELADATA**
  (javasolt üzenet: `ENH-HELP-1-S4: finalize help screenshots — hand-rounded assets, no code clipping`)
- [x] `docs/progress.md` frissítve (ez a szekció)

**Következő session:** ENH-HELP-1-S5 (Countdown + Calculate szekció valós tartalma)
vagy ENH-DEVDOCS-2.

---

## Session BV — 2026-08-15 (ENH-HELP-1-S5/S6: Recovery szekció + lezárás — LEZÁRVA)

### Session BV — LEZÁRVA
- [x] `docs/progress.md`, `docs/countdownApp-handoff.md` elolvasva
- [x] `docs/buglist.md` (ENH-HELP-1 szekció), `Models/HelpContent.swift`,
  `Localizable.xcstrings`, `docs/manual/countdownApp-manual.md` elolvasva
- [x] Megállapítás: Calculate + Snippets xcstrings tartalom már ki volt töltve korábbi
  sessionökben — S5/S6 valójában csak a Recovery szekció valós tartalma + lezárás
- [x] **`Models/HelpContent.swift`** módosítva — Recovery szekció:
  - régi `recovery.backup` (1 item, placeholder szöveg) → törölve
  - `recovery.storage` + `recovery.banner` (2 új item) beillesztve
  - ikonok: `internaldrive` + `exclamationmark.triangle`
- [x] **`Localizable.xcstrings`** módosítva:
  - `help.recovery.backup.title` + `.body` → törölve
  - `help.recovery.storage.title`: "Local storage"
  - `help.recovery.storage.body`: UserDefaults, lokális tárolás, nincs cloud sync
  - `help.recovery.banner.title`: "Recovery banner"
  - `help.recovery.banner.body`: startup hiba → banner, Copy Raw Data előbb dismiss-szel
  - Forrás: `docs/manual/countdownApp-manual.md` Data Recovery szekciója
- [x] **`docs/buglist.md`** ENH-HELP-1 státusza → ✅ KÉSZ (S1–S6 lezárva)
- [ ] Build + vizuális ellenőrzés: **FELHASZNÁLÓ FELADATA**
- [ ] Git commit: **FELHASZNÁLÓ FELADATA**
  (javasolt üzenet: `ENH-HELP-1-S5/S6: Recovery section content, close out ENH-HELP-1`)
- [x] `docs/progress.md` frissítve (ez a szekció)

**Következő session:** ENH-DEVDOCS-2 (README + install.md) vagy BUG-MANUAL-1 — egyeztetés alapján.
