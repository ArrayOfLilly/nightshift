# countdownApp — Bug & Enhancement List

Minden bejegyzés egyeztetés után kerül implementációra.
Prioritás-jelzés: 🔴 kritikus, 🟡 fontos, 🟢 nice-to-have

---

## ENH-HELP-2: Help menü szövegei nem elég részletesek

A felhasználó visszajelzése szerint az ENH-HELP-1-ben (KÉSZ) felépített Help tartalom
lényegében megvan, de a body szövegek túl rövidek/felszínesek — minden szekció
bővebb, részletesebb szöveget kell kapjon.

**Scope:** csak Localizable.xcstrings EN+HU help.*.body értékek mélyítése, item-enként
1-3 mondattal bővítve konkrét részletekkel (mi történik, mikor hasznos, mi a
kapcsolódó viselkedés). HelpContent.swift struktúra (item lista, ikonok, screenshotok)
változatlan maradt.

**Haladás:**
- Overview (5/5) kész — Session CO
- Countdown (8/8) kész — Session CO
- Calculate (6/6) kész — Session CO
- Snippets (4/4) kész — Session CO
- Recovery (2/2) kész — Session CO

**Státusz:** ✅ KÉSZ (Session CO, 2026-08-16) — mind az 5 szekció, 25/25 item bővítve.
Build ellenőrzés felhasználó feladata.

---

## UX-SUNPANEL-ICONS: SunPanel szekciócímek ikonijai félrevezetőek 🟢

A SunPanel négy szekciójának fejléce emoji-val jelölt napszakokat (Session CI-ben megoldva SF Symbols-szel):

**Eredeti (félrevezető emoji-k):**
- `⚖️  DAY` — balance/mérlege? (napra nem illeszkedik)
- `🌆  EVENING` — city silhuette/napernyő? (este nem ezt szimbolizálja)

**Megoldva SF Symbols-szel (Session CI) — egységes set:**
- `sun.min` (MORNING) — félnap, napkelte után
- `sun.min` (EVENING) — félnap, napnyugta körül
- `sun.max.fill` (DAY) — teljes nap
- `moon` (MOON) — egyszerű hold
- `camera.aperture` (GOLDEN/BLUE HOUR) — meglevő fotoapertúra

`SunPanel.swift` `sectionHeader` helper módosítva: `(icon: String, title: LocalizedStringKey)` paraméterek,
`HStack` + `Image(systemName:)` + `Text()` kombináció.

**Státusz:** ✅ KÉSZ (implementaóló session: CI)

---

## UX-SNIPPETS-PROJECT-AUTOCOMPLETE: Snippet project field nem szűr az existing projectek alapján 🟢

A `SnippetEditSheet`-ben a Project mező egy `ProjectField` komponens (custom TextField + popover dropdown):
- A mező tetején egy `TextField` (*User types here*) + `ChevronDown` gomb a popover-hez
- A popover egy lista az összes `existingProjects`-ből — **korrigálva Session CI-ben** ✅

Probléma (előtte): Ha pl. a meglévő projektek: `["AI Research", "Swift Dev", "Rust Utils"]`, és a felhasználó
bekezd gépelni "swift"-et, a popover továbbra is mind a 3 projektet mutatja, nem csak az
"Swift Dev"-et.

**Megoldva (Session CI):** `ProjectField`-ben egy `filteredSuggestions` computed var:
```swift
private var filteredSuggestions: [String] {
    text.isEmpty ? suggestions : suggestions.filter { $0.localizedCaseInsensitiveContains(text) }
}
```
A popover `ForEach` a `suggestions` helyett `filteredSuggestions`-t iterálja — élő szajtás begépeléskor.

**Státusz:** ✅ KÉSZ (implementaóló session: CI)

---

## BUG-SNIPPEDITBEACHBALL-1: Meglévő snippet szerkesztésekor becsukás után beachballing 🔴 KRITIKUS

Meglévő snippet szerkesztéskor, a szerkesztés után az ablak bezárása (X gomb, "Save and quit" választás) után az alkalmazás beachballing (spinning wait cursor) állapotba kerül, ami gyakorlatilag teljes lefagyást jelent — a felhasználónak kényszerített kilépésre kell lépnie.

**Reprodukálási módok (felhasználó tapasztalata alapján):**
1. Szerkesztés nélküli snippet (untitled, General kategória) megnyitása → cím + projekt hozzáadása → X → "Save and quit" → **beachballing**
2. Meglévő snippet (van címe, projekt isméretlen) megnyitása → body szerkesztése → X → "Save and quit" → **beachballing**

**Lehetséges root cause-ok — kódellenőrzés eredménye (BN session, SnippetEditSheet.swift + Snippet.swift + SnippetsView.swift elolvasva):**
- CÁFOLVA — betöltési hurok: `Snippet.save()` NEM hív `load()`-ot, az `onSave` callback-ek sem (`SnippetsView.swift`, mindkét `.sheet` closure). Nincs save→load→save ciklus.
- CÁFOLVA — Swift 6 concurrency isolation: a kód sima SwiftUI @State/View, nincs explicit background thread vagy nem-izolált closure a persistence úton. Nem valószínű root cause.
- RÉSZBEN MEGERŐSÍTVE — .onDisappear double-call: a showDismissConfirm alert "Save and quit" ága (SnippetEditSheet.swift) ténylegesen NEM állítja shouldSaveOnDisappear = false-ra commitSave() előtt (ellentétben a "Quit without saving" ággal és a delete-alerttel, ahol ez megvan) → dismiss() után .onDisappear másodszor is lefuttatja commitSave()-t. Ez megerősíti/azonosítja BUG-SNIPPETSAVE-1 root cause-át, és emellett ez a duplikáció valódi oka is (ld. BUG-SNIPPETDUP-1 frissítve lent) — de önmagában két gyors, szinkron UserDefaults.set() hívás nem indokolna teljes beachballt/hangot.
- ÚJ, MÉG NEM MAGYARÁZOTT reprodukálás (felhasználó jelentése, BN session): app inaktívból aktívba vált, eközben a snippet sheet/menü már nyitva volt (nem az X/Save and quit útvonal), a felhasználó még NEM görgetett, csak rákattintott valamire — azonnali beachball. Ez a 3 fenti elmélet egyikével sem magyarázható közvetlenül. Gyanús, még NEM ellenőrzött terület: MarkdownWebView (VIEW mód, SharedEditorComponents.swift — WKWebView-alapú, ott még nem néztünk kódot) JS-bridge/render állapota ablak-deaktiválás/aktiválás után, vagy a ProjectField popover state. Ez a repró külön ellenőrzést igényel — lehet, hogy ÖNÁLLÓ hiba, nem a dirty-save hurok variánsa.

**HARMADIK reprodukálás (felhasználó jelentése, BN session folytatás):** Meglévő snippet szerkesztése →
checkmark → X (sheet bezárva, nincs hibaüzenet/repró ekkor) → felhasználó átváltott a böngészőre (app
inaktívvá vált) → visszakattintott az app ablakára → **azonnali beachball**. Fontos különbség az előző
(inaktív→aktív) reprótól: itt a snippet sheet MÁR be volt zárva, mielőtt az app inaktívvá vált — tehát
nem a nyitva hagyott sheet/MarkdownWebView az egyetlen gyanús eset, hanem maga a főablak (app-szintű)
reaktiválása a checkmark+X utáni állapotban. Ez arra utal, hogy a gyanú nem korlátozódhat kizárólag a
MarkdownWebView-ra nyitott sheet esetén — lehet, hogy egy, a commitSave()/dismiss() folyamat által
indított aszinkron munka (pl. save I/O, WKWebView teardown, vagy egyéb) csak akkor akad el/blokkol,
amikor az app NSApplication-szinten inaktívvá, majd újra aktívvá válik közben még fut/befejezetlen.

**NEGYEDIK pontosítás (felhasználó jelentése, BN session folytatás — mind a 4 eddigi eset újraértékelve):**
Mind a **4** eddig ismert reprónál a snippet sheet **már zárva volt**, amikor a beachball bekövetkezett —
NINCS olyan eset, ahol a sheet még nyitva lett volna a beachballkor. A négy eset közül:
- **2 eset**: a beachball **közvetlenül a bezáráskor** történt (X után azonnal)
- **2 eset**: a beachball **később, ablak-reaktiváláskor** jelentkezett (böngészőre váltás után vissza az
  appra kattintva), semmi speciális nem történt közben
- **Mind a 4 esetben közös**: a felhasználó mindig ugyanazt a snippetet szerkesztette — a **"NEXT SESSION"**
  nevű snippetet. Ez erős gyanút vet fel, hogy nem általános, minden snippetre érvényes hiba, hanem
  valami ehhez a KONKRÉT snippethez kötődő tulajdonság (pl. tartalom mérete/hossza, gyakori
  újraszerkesztése — esetleg BUG-SNIPPETDUP-1 miatt felhalmozódott duplikátumok ebből a snippetből,
  ami megnagyobbítja a `UserDefaults`-ban tárolt JSON méretét és lassabbá/blokkolóvá teheti a
  `synchronize`/JSON encode-decode műveletet).

**Fontos következtetés:** mivel a sheet MINDIG zárva volt már a beachballkor, a `MarkdownWebView`
(SharedEditorComponents.swift) VALÓSZÍNŰLEG NEM érintett — ELVETVE mint elsődleges gyanús terület.
Új prioritás: (1) a "NEXT SESSION" snippet tartalmának/méretének/duplikátumszámának ellenőrzése
(összefüggés BUG-SNIPPETDUP-1-gyel — ha ez a snippet többször duplikálódott, a tárolt adatméret is
 megnőtt), (2) `commitSave()` / `Snippet.save()` perzisztencia útvonalának átvizsgálása nagy adatméret
 esetére (szinkron `UserDefaults.set` + `synchronize` főszálon blokkolhat, ha a JSON nagy), (3) az
 `countdownAppApp.swift` AppDelegate lifecycle hook még mindig releváns lehet, mert megmagyarázná,
 miért csak ABLAK-REAKTIVÁLÁSKOR kerül felszínre egy már korábban elindított/függőben lévő lassaú
 művelet (pl. ha egy async/queued munka csak akkor fut le a főszálon, amikor az app újra aktiválódik).

**ÖTÖDIK frissítés (felhasználó jelentése, külön session):** a felhasználó egy általános, app-szintű
beachball/hang hibát korábban javított a `LazyVStack` → `VStack` cserével (lásd `countdownApp-handoff.md`
"beachball/hang fix" bejegyzés). A felhasználó szerint ez a csere a snippet-editing beachball jelenséget
is megszüntette — azóta nem tapasztalta újra. Ez ELLENTMOND a "NEXT SESSION" adatméret/duplikátum
elméletnek mint kizárólagos oknak: ha a `LazyVStack`→`VStack` csere (ami feltehetően egy lista-renderelési,
nem persistence-útvonalbeli hiba volt) megszüntette a jelenséget, akkor a root cause valószínűbben a
lista-renderelés (`LazyVStack` lazy-load + WKWebView/MarkdownWebView instantiation race ablak-reaktiváláskor)
volt, nem a JSON encode/decode mérete. MEGERŐSÍTÉS MÉG SZÜKSÉGES: a felhasználó nem tesztelte szisztematikusan
(csak azt figyelte meg, hogy a csere óta nem jött elő), úgyhogy a bug egyelőre NEM zárható le automatikusan.

**Státusz:** ✅ KÉSZ — a `LazyVStack` → `VStack` csere (Session 23-B) megszüntette a jelenséget; azóta
nem reprodukálható. Lezárva felhasználói megerősítés alapján (2026-08-16).

---

## BUG-MANUAL-TEXT: Manual leíró szövege elavult 🟡

A pipa/X bezárási viselkedés (`NotesSheet` + `SnippetEditSheet` — pipa: ment+dismiss,
X: dirty esetén confirm alert) BF sessionben dokumentálva lett a manualban (`05e` eye badge,
`11b` Notes unsaved-changes, `17 Exit` Snippets unsaved-changes; git `515aa7e`) — EZ A RÉSZ
KÉSZ volt.

**Szabály (Session CV óta, `Claude.md` "Manual — szöveg vs. screenshot"):** a leíró szöveg
azonnal javítandó abban a sessionben, ami elavulttá teszi — nem várja meg a screenshot-batch-et.
Ez a lista a szabály bevezetése ELŐTT felhalmozódott, még nem javított tételeket tartja nyilván.

**Nyitott tételek:**
- **BUG-SNIPPETSAVE-1 + BUG-SNIPPETDUP-1** (BN session) — a save/dismiss logika változott
  (`shouldSaveOnDisappear`, snippet `@State` upsert) — a manual Snippets szerkesztés szekciója
  ezt még nem tükrözi
- **BUG-PROJECTDELETE-1** (BL session) — project törlés viselkedése változott (General alá
  mozgatás adatvesztés helyett) — nincs a manualban
- **App név változás** (BH+BJ session) — `countdownApp`/`NightShift` átnevezés (Display Name,
  Bundle ID, PRODUCT_NAME) — a manual szövege még a régi nevet tükrözheti (screenshotoktól
  függetlenül is ellenőrizendő szöveg-szinten)

**Lezárt tételek:**
- **Fülsor / Tab Bar ikonok** — ✅ JAVÍTVA (Session CV, EN+HU): a manual ikon+sötét-kör UI-t írt
  le (Óra/@/Idézőjel, kör az aktív fül mögött), miközben a tényleges `ContentView.swift` csak
  szöveglabeleket renderel, lekerekített téglalap háttérrel — az ikon+kör UI git history szerint
  csak átmenetileg, ~70 commitból 2-3-ban élt, sosem lett a végleges megoldás, a manual mégis ezt
  őrizte. Mindkét manual fájl (`nightshiftApp-manual.md`, `nightshiftApp-manual-hu.md`) "Tab Bar"
  / "Fülsor" szekciója frissítve a tényleges UI-ra.

**Státusz:** RÉSZBEN NYITOTT — 3 régi tétel maradt (snippet save/dismiss, project delete,
app név), ezek szöveg-szintű javítása nem screenshot-függő, tehát elvégezhető külön, a
screenshot-batch-től függetlenül, bármelyik következő sessionben.

---

## BUG-MANUAL-SCREENSHOTS: Manual screenshotjai a végleges UI-ra várnak 🟡

A manual screenshotjai csak akkor készülnek/frissülnek, ha az érintett UI-terület már stabil —
nem érdemes egy még változó nézetről ismételten újrakészíteni őket. Ez szándékosan batch-elt,
a legvégén elintézendő feladat (`Claude.md` "Manual — szöveg vs. screenshot").

**Függőség:** a screenshot-frissítés csak az összes többi nyitott, UI-t érintő további változás
(pl. `ENH-HELP-1` már kész, de ha jön még UI-módosítás) elkészülte után történjen.

**Státusz:** NYITOTT — várakozik a végleges UI-állapotra

---

## ENH-DEVDOCS-1: Fejlesztői dokumentáció hiányzik 🟡

Nincs külön fejlesztői dokumentáció (architektúra áttekintés, modul felelősségek, persistence réteg,
recovery infrastruktúra, hogyan fejlesztünk egy új feature-t) — jelenleg csak a `Claude.md` (fejlesztési policy) +
`countdownApp-handoff.md` (session-állapot) létezik, ezek nem helyettesítik a termék/architektúra dokumentációt.

**Státusz:** ✅ KÉSZ (Session CV, 2026-08-18) — `docs/architecture.md` létrehozva, 5 szekció
(Overview, Module responsibilities, Persistence layer, Recovery infrastructure, Adding a new
feature), angol nyelven, a valós Swift forrás (Models/, App/, Services/, Views/) alapján írva.
Git commit: FELHASZNÁLÓ FELADATA.

---

## ENH-HELP-1: Help menü 🟡

iconKeeper mintájára. Tartalom: a manual anyaga, de megvágott képekkel (csak az érintett terület látszik,
nem a teljes képernyő). Képek csak ott, ahol valóban nem magától értetődő a feature (pl. notes badge,
középső holdacska mint SunPanel trigger).

### IconKeeper referencia minta (BJ/BK sessionek közt gyűjtve, `IconKeeperApp.swift` alapján)

- **`HelpItem`**: `id: String`, `titleKey: LocalizedStringKey`, `bodyKey: LocalizedStringKey`, `icon: String`
- **`HelpSection`**: `id: String`, `titleKey: LocalizedStringKey`, `items: [HelpItem]`
- **`HelpCommands`**: külön `Commands` struct (`@Environment(\.openWindow)` mert kell az env),
  `CommandGroup(replacing: .help)`, gomb label `NSLocalizedString("help.menu.item", ...)`,
  `.keyboardShortcut("/", modifiers: [.command, .shift])`
- **Help ablak**: külön `WindowGroup(id: HelpWindowID.id) { NavigationStack { HelpView() } }`,
  `.windowResizability(.contentMinSize)`, `.defaultSize(width: 560, height: 520)`, `.windowStyle(.titleBar)`;
  `HelpWindowID` enum `static let id = "..."` mintára (NightShiftnél pl. `"nightshift-help"`)
- **Keresés**: IconKeeperben az `id` mező alapján szűr, keyword-alapú, NEM full-text
- Az About ablak ugyanezt a mintát követi (`AboutWindowID`, `AboutCommands`) — NightShiftnél az About
  már kész (ld. BH session), tehát a Help window scene bevezetése ahhoz hasonló mintát követhet

### Egyeztetési pontok — LEZÁRVA (döntések megszülettek)

1. **L10n**: **A) opció választva** — `LocalizedStringKey` használat MOST, és a `Localizable.xcstrings`
   TARTALOM is MOST kerül kitöltésre (legalább EN, esetleg HU is) — IconKeeper mintán, azonnal
   működő lokalizációs alap. Ez egyben `ENH-L10N-1` első lépése is (a Help-en túl a többi nézet
   lokalizációja külön feladat marad).
2. **`imageName` mező**: **IGEN, MOST bekerül** a `HelpItem`-be (opcionális, `String?`), a négyedik
   pont (`focusRect`) is vele együtt — lásd lent.
3. **Keresés**: **IconKeeper-mintás `id`-alapú keyword szűrés**, NEM kell külön `searchTokens`
   mező — elegendő az angol azonosítóra szűrni.
4. **Screenshot megjelenítés**: **elfogadva a `HelpScreenshot` + normalizált `focusRect: CGRect?`
   irány** (lásd lent, már részletesen kidolgozva) — teljes méretű screenshotok az
   `Assets.xcassets`-ben, a kivágás pozíciója/mérete számokban tárolva, nem kézzel vágva.

**Következő lépés:** mind a 4 döntés lezárva — implementáció kezdhető, 6 session-méretű darabra
bontva (lásd alant "Implementációs terv").

### Implementációs terv — 6 session (free tier ~20k token/session)

- ✅ **ENH-HELP-1-S1 — Adatmodell + xcstrings váz** (KÉSZ — BO session): `HelpItem`/`HelpSection` struct-ok
  (`Models/HelpContent.swift` új fájl); `Localizable.xcstrings` létrehozása a Help kulcsokkal
  (EN szöveg, HU ha belefér), MEG NEM töltött tartalommal (üres section-lista vagy 1 placeholder
  item szekciónként, hogy fordítson). Nincs UI még.
- **ENH-HELP-1-S2 — Window + Commands + HelpView váz**: `HelpWindowID` enum, `HelpCommands`
  (`CommandGroup(replacing: .help)`, `Cmd+Shift+/`), `helpWindow` scene `countdownAppApp.swift`-ben
  (IconKeeper minta: `WindowGroup(id:)` + `NavigationStack` + `.windowResizability(.contentMinSize)`
  + `.defaultSize(560, 520)`); `HelpView.swift` új fájl — lista nézet szekciók/itemek szerint,
  id-alapú keyword keresés (`.searchable`). Az S1 placeholder tartalommal működik, még üres/vázlatos.
- **ENH-HELP-1-S3 — HelpScreenshot komponens**: `Components/HelpScreenshot.swift` —
  `focusRect: CGRect` (normalized) alapú kivágás/scale/offset számítás, egységes `targetSize`.
  Tesztelés 1 valós screenshottal (bármelyik már meglévő `Assets.xcassets` képpel), hogy a
  geometria helyes legyen, mielőtt minden Help itemre alkalmazzuk.
- **ENH-HELP-1-S4 — Tartalom: Overview + Countdown szekció**: valós `HelpItem` bejegyzések +
  xcstrings szöveg feltöltése erre a 2 szekcióra; screenshotok kiválasztása/`focusRect` beállítása
  ahol szükséges (csak non-obvious feature-öknél).
- **ENH-HELP-1-S5 — Tartalom: Calculate + Snippets szekció**: ua. mint S4, erre a 2 szekcióra.
- **ENH-HELP-1-S6 — Tartalom: Recovery szekció + lezárás**: Recovery szekció tartalma; build teszt
  a teljes Help rendszerre; `docs/buglist.md` ENH-HELP-1 → ✅ KÉSZ; git commit.

Sorrend kötelező (S1→S6), mert mindegyik az előzőre épül. Közben bármikor megszakítható
 és folytatható session-határon (docs frissítés mindig az adott S-lezárásakor).

### Screenshot megjelenítés — tervezett irány (még NEM végleges, 4. egyeztetési pont)

A felhasználó felé javasolt megoldás (CSS `object-position` + `object-fit: cover` SwiftUI-megfelelője):

- A screenshotok **teljes méretben** kerülnek be az `Assets.xcassets`-be — NEM előre kézzel vágott részletek
- A "melyik rész látszódjon" döntés **kódba** kerül, mint egy normalizált fókusz-rect: `CGRect` 0–1 közötti
  x/y/width/height értékekkel, a kép relátív koordinátáiban (pl. `CGRect(x: 0.3, y: 0.1, width: 0.4, height: 0.3)`)
- Új komponens: **`HelpScreenshot`** (munkanév; a vázlatban `MaskedScreenshot` is felmerült) —
  `imageName: String`, `focusRect: CGRect` (normalized), `targetSize: CGSize` (egységes méret minden
  help képnek); `GeometryReader` + `Image(imageName).resizable().scaledToFill()` + a `focusRect`-ből
  számolt `scaleEffect`/`.offset`, hogy pont a kijelölt rész töltse ki a `targetSize`-t; `.clipShape` lekerekítve
- Előnyök: mindig egységes méretű kivágás help-elemenként függetlenül az eredeti screenshot arányától;
  nincs pixelbe égetett kivágás (ha a UI változik, csak a számokat kell finomhangolni, nem újra vágni);
  nincs minőségvesztés/duplikált asset (ugyanabból a screenshotból több help-item is kivághat más-más részt)
- `HelpItem` modellben: az `imageName` mező mellett egy `focusRect: CGRect?` mező is kellene (opcionális,
  csak azoknak az itemeknek ahol van screenshot)
- **Alternatíva** (ha a felhasználó inkább kézzel vágja meg képszerkesztőben): akkor NEM kell `focusRect`,
  hanem egy külön `help-screenshots` mappa/névkonvenció kellene az előre vágott képeknek — ez a két út
  egymást kizárja, döntés szükséges

**Státusz:** ✅ KÉSZ — S1–S6 mind lezárva:
- S1 (BO): `Models/HelpContent.swift` + `Localizable.xcstrings` váz
- S2 (BP): `HelpWindowID` + `HelpCommands` + `HelpView` + `countdownAppApp.swift`
- S3 (BQ): `Components/HelpScreenshot.swift` Canvas-alapú komponens
- S4 (BR/BS/BT/BU): valós tartalom (Overview + Countdown + Calculate szekciók), screenshotok
  kézzel vágva és lekerekítve, HelpScreenshot egyszerűsítve (pre-cropped assets)
- S5/S6 (BV): Recovery szekció valós tartalma (`recovery.storage` + `recovery.banner`),
  régi `recovery.backup` placeholder eltávolítva

---

## ENH-L10N-1: Lokalizáció HU/EN 🟢 ✅ KÉSZ

Elkülönített locales és UI nyelv. iconKeeper mintájára. Kapcsolódik: ENH-SETTINGS-1 (Settings menü
ahol a language/locale választható).

**LEZÁRVA (Session CH)** — a maradék #2/#3/#5/#6/#9 pontok a tényleges kódon átvizsgálva és javítva:
- `AboutView.swift`, `CountdownView.swift`, `SnippetsView.swift`, `CalculateView.swift`: interpolált
  stringek a meglévő xcstrings formátum-kulcsokra állítva
- `ComponentStepper.swift`: valódi bug — `label: String` + `Text(label)` sosem lokalizált (a `String`
  overload verbatim renderel), a YEAR/MON/DAY/HOUR/MIN kulcsok megvoltak, de nem futottak le soha
- `ColorPickerSheet.swift`, `SnippetEditSheet.swift`: hiányzó accessibility label lokalizáció + 5 új
  xcstrings kulcs (`%@ color`, `Color %d`, `Delete snippet`, `Edit snippet`, `Snippet copied`)
- `ContentView.swift` (#9): ellenőrizve, már korábban helyesen `LocalizedStringKey`
- `SunTimesService.swift` (#5): `lastError` sosem jelenik meg a UI-n — nincs teendő
- Build: SIKERES (xcodebuild). Git commit: `a0e9f17`.

### 1) HU fordítás hiányzik xcstrings-ből (14 kulcs, EN megvan) — ✅ KÉSZ (Session CA)
~~"Snippets", "SNIPPETS", "Sun times unavailable", "Switch to date display",
"Switch to remaining time", "Tap + to add a snippet.", "Tap to start writing.",
"This cannot be undone.", "This clears the notes for this slot. This cannot be undone.",
"This deadline will be permanently removed.", "Title", "Unsaved changes",
"Version %@ (%@)", "You have unsaved changes. What would you like to do?"~~
Mind a 14 kulcs HU fordítása beírva az xcstrings-be (Session CA) — build+vizuális ellenőrzés
még **FELHASZNÁLÓ FELADATA**.

### 2) Xcstrings-ből teljesen hiányzó stringek (nincs kulcs se EN-re se HU-ra)
- `AboutView.swift`: "Developer", "Images" (infoRow label-ek)
- `SnippetsView.swift`: "Untitled" (snippet cím fallback), `"This will permanently delete all
  %lld snippet%@ in \"%@\"."` (deleteProjectMessage, plural form)
- `CountdownDetailView.swift`: "Countdown" (üres label fallback), "Copy label"/"Label copied"
  (CopyButton accessibility), "EXPIRED"
- `CountdownRowView.swift`: "COPIED" (copy feedback)
- `AddCountdownSheet.swift` + `CountdownDetailView.swift` + `CalculateView.swift`
  (mindhárom a közös `ComponentStepper`-t hívja, mindenhol ismétlődik): "YEAR"/"MON"/"DAY"/
  "HOUR"/"MIN" display label-ek + "year"/"month"/"day"/"hour"/"minute" accessibility unit nevek
- `NotesSheet.swift`: "Copy notes", "Notes copied", "Done editing", "Edit notes", "Delete notes"
- `ColorPickerSheet.swift`: swatch accessibility formátum "(\(color)) color" — alacsony prioritás
- `SunPanel.swift`: "First light", "Dawn", "Sunrise" stb. napszak-adatcímkék — alacsony prioritás

### 3) Kód-szintű hiba (xcstrings kulcs megvan/kellene, de a Swift kód nem megfelelően használja)
- `ContentView.swift` `modeButton`: `Text(mode.rawValue)` → `Text(LocalizedStringKey(mode.rawValue))`
- `AboutView.swift`: `"Version \(version) (\(build))"` → `String(localized: "Version %@ (%@)", ...)`
- `CountdownView.swift` + `SnippetsView.swift` corruption banner:
  `"\(count) item\(count == 1 ? \"\" : \"s\") could not be loaded"` →
  `String(localized: "%lld item%@ could not be loaded", ...)`
- `ComponentStepper.swift`: `accessibilityLabel: "Increase \(unit)"` / `"Decrease \(unit)"` →
  `String(localized:)` formátum kellene

### 4) Ellenőrizve, rendben (nincs teendő)
`AddCountdownSheet.swift` Cancel/Add/LABEL/DEADLINE/placeholder, `DeadlineDetailSheet.swift`
Close/CANCEL/RENAME/Rename deadline/Delete deadline, `ColorPickerSheet.swift` "PICK A COLOR"+close,
`SunPanel.swift` LOADING/NO DATA, `SharedEditorComponents.swift`, `CopyButton.swift` (belső
HTML/CSS/JS ill. hívó-adott accessibility label, nincs saját hardcoded string).

**FRISSÍTVE (Session CQ, 2026-08-18):** `Snippet.swift` `"General"` default projektnév — a korábbi
döntés ("adat-default, nem UI chrome, marad lokalizálatlan") ÉRVÉNYTELENÍTVE. A `sectionHeader`
(`SnippetsView.swift`) `Text(project.uppercased())`-je ténylegesen kirajzolja a tárolt projekt-tag
literált, tehát a "General" mindig angolul jelent volna meg HU nyelven is — ez valódi kódhiba volt,
nem szándékos adat-default. Megoldás: `Snippet.project` továbbra is a nyers `"General"` literált
tárolja (kanonikus, locale-független storage-id), de `SnippetsView.sectionHeader` a megjelenítés
pillanatában `String(localized: "General")`-re fordítja, ha `Snippet.isGeneralProject(_:)` igaz —
más (felhasználó által megadott) projekttagek változatlanul nyersen jelennek meg. ÚJ xcstrings kulcs:
`"General"` → `"Általános"`. Ld. `countdownApp-handoff.md` #56-59.

### 5) Nyitott kérdés
`SunTimesService.swift` "Invalid request URL" (`lastError`) — tisztázandó, megjelenik-e valaha
a UI-n; ha igen, lokalizálandó.

### 6) Még nem (teljesen) auditált fájlok
`CalculateView.swift` saját stringjei (a ComponentStepper-től független rész), `SnippetEditSheet.swift`
teljes fájl (csak a "Title" mező lett eddig ellenőrizve).

### 7) CalculateView — lefordítatlan saját stringek (audit eredménye, Session BT+)
- `"RESET FROM NOW"` / `"RESET TO NOW"` — nowButton label, hardcoded
- `"Remaining time:"` / `"Elapsed time:"` — resultLabel computed var, hardcoded (megjelenik a
  modeToggle felett mint section header)
- `"SAVE DEADLINE"` — saveSheetContent header, hardcoded
- `"SAVED DEADLINES"` — deadlineListPopoverContent fejléc, hardcoded
- `"EXPIRED"` — deadlineRemainingString visszatérési értéke, hardcoded (ld. ENH-L10N-1 #2-ben
  is szerepel `CountdownDetailView` alatt — egységesítendő)
- `"< 1M"` — deadlineRemainingString fallback, hardcoded
- `"Name..."` — TextField placeholder a save sheet-ben, hardcoded

### 8) SunPanel.swift — lefordítatlan label-ek (audit eredménye, Session BT+)
Az összes sor-label `timeRow`/`labelRow`/`windowRow` hívásokban hardcoded angol string:
- Section fejlécek: `"☀️  MORNING"`, `"🌆  EVENING"`, `"⚖️  DAY"`, `"🌙  MOON"`,
  `"📷  GOLDEN / BLUE HOUR"`
- Morning: `"First light"`, `"Dawn"`, `"Sunrise"`
- Evening: `"Sunset"`, `"Dusk"`, `"Last light"`
- Day: `"Solar noon"`, `"Day length"`
- Moon: `"Moonrise"`, `"Moonset"`, `"Phase"`, `"Illumination"`
- Golden/Blue: `"Morning golden"`, `"Morning blue"`, `"Evening golden"`, `"Evening blue"`
- Loading/no-data: `"LOADING"`, `"NO DATA"` — ezek Alien League dekoratív szövegek,
  az xcstrings `SunPanel.swift` `LOADING`/`NO DATA` kulcsai már megvannak (audit #4 szerint rendben),
  de a Swift kód nem `LocalizedStringKey`-t, hanem sima `String`-et ad át `Text()`-nek. Ellenőrizendő.

**Megjegyzés:** a `sectionHeader`/`timeRow`/`labelRow`/`windowRow` helper-ek jelenleg
`label: String` típusú paramétert vesznek át, nem `LocalizedStringKey`-t — az összes hívóban
egyszerre kell átállítani.

### 9) ContentView / General — lefordítatlan string
- `ContentView.swift` tab label: a `"General"` szó (ha szerepel valahol mint hardcoded szöveg)
  — ellenőrzendő, hogy `modeButton` `Text(mode.rawValue)` hívásán keresztül jön-e (ld. #3 pont:
  `LocalizedStringKey(mode.rawValue)` javítás szükséges), vagy külön hardcoded előfordulás is van.

**Státusz:** NYITOTT — audit kész, implementáció még nem kezdődött el. Részletek:
`docs/progress.md` Session BY + BZ szekció.

---

## ENH-SETTINGS-1: Settings menü — UI Language, Locales 🟢

UI Language és locale-választék a Settings menüben. iconKeeper mintájára.

### Implementáció (Session CB) ✅

- **`App/AppKeys.swift`**: `preferredLanguage` + `preferredLocale` kulcsok hozzáadva
- **`Services/Formatters.swift`**: `effectiveLocale` private static var; `monthAbbrev`,
  `deadline`, `deadlineCompact` most `effectiveLocale`-t használ (restart után hat)
- **`Views/Settings/SettingsView.swift`** (új fájl, új `Views/Settings/` mappa):
  - Interface Language picker: System Default / English / Magyar
    → `@AppStorage(preferredLanguage)`, `onChange` → `UserDefaults["AppleLanguages"]`
  - Date & Number Format picker: System Default / English (US) / Magyar (HU)
    → `@AppStorage(preferredLocale)`, Formatters olvassa restart után
  - Restart advisory ha bármelyik beállítás nem default
- **`App/countdownAppApp.swift`**: `Settings { SettingsView() }` native scene hozzáadva

**Státusz:** ✅ KÉSZ (implementálva Session CB) — build+teszt+commit felhasználó feladata

---

## ENH-SETTINGS-2: Font méret állítható a Settings-ben 🟢

A UI szövegmérete jelenleg fix, túl kicsi. A felhasználó igénye: a Settings-ből állítható
legyen a betűméret, legalább 3-4 lépésben.

### Tervezett implementáció (3 fájl, ~30 sor, restart NEM szükséges)

**Megközelítés:** SwiftUI `.dynamicTypeSize()` environment modifier a `ContentView` gyökerén,
`@AppStorage`-ból vezérelve. Semantic fontok (`.body`, `.headline`, `.caption` stb.)
automatikusan skálázódnak. `Font.custom("Alien League", size: Y)` fixed méretű hívások
**nem** reagálnak a Dynamic Type-ra — ez szándékos: a dekoratív számok/címek mérete fix marad,
csak a szöveges tartalom nő. **`AppTheme.swift` módosítás nem szükséges.**

**Lépések:**

1. **`App/AppKeys.swift`** — 1 sor:
   ```swift
   static let fontSizeStep = "nightshift.fontSizeStep"  // Int, default 0
   ```

2. **`Views/Settings/SettingsView.swift`** — új `fontSizeSection` (~30 sor):
   - `@AppStorage(AppKeys.fontSizeStep) private var fontSizeStep: Int = 0`
   - Segmented picker: Default (0) / Large (1) / Larger (2) / Largest (3)
   - Ikon: `textformat.size`
   - **Nincs restart advisory** — azonnal hat

3. **`App/countdownAppApp.swift`** — 3 sor módosítás:
   ```swift
   @AppStorage(AppKeys.fontSizeStep) private var fontSizeStep: Int = 0
   // ContentView-ra:
   ContentView().environmentObject(sunService).dynamicTypeSize(fontSizeStep.asDynamicTypeSize)
   ```
   + extension (fájl aljára):
   ```swift
   private extension Int {
       var asDynamicTypeSize: DynamicTypeSize {
           switch self {
           case 1: return .xLarge
           case 2: return .xxLarge
           case 3: return .xxxLarge
           default: return .large
           }
       }
   }
   ```

**Érintett fájlok:** `AppKeys.swift`, `SettingsView.swift`, `countdownAppApp.swift` —
`AppTheme.swift` és egyetlen view sem igényel módosítást.

**Státusz:** ✅ KÉSZ (implementálva Session BT) — build+teszt+commit felhasználó feladata

---

## ENH-TOOLTIP-1: Tooltip minden interaktív elemhez 🟢

Minden interaktív vagy módosítható elemnek legyen `.help()` tooltip-je — ez a macOS standard
accessibility/discoverability pattern. Az aktuális kód sehol nem használ `.help()` modifiert.

**Érintett elem-típusok (teljesség igénye nélkül):**
- `ComponentStepper` increment/decrement gombok — pl. "Increase year by 1" / "Decrease year by 1"
- `CopyButton` — pl. "Copy to clipboard"
- `modeToggle` (CAL/DAYS) — pl. "Switch to calendar display" / "Switch to days display"
- `saveButton` bal fele (SAVE) — pl. "Save current TO date as a named deadline"
- `saveButton` jobb fele (▾) — pl. "Show saved deadlines"
- SunPanel trigger (középső hold) — pl. "Show sun and moon times"
- Countdown soron a delete/edit/notes gombok
- ColorPickerSheet swatchok — accessibility (már van `accessibilityLabel`, `.help()` külön kell)
- Notes edit/done/delete/copy gombok
- Snippet sheet checkmark / X / delete gombok

**Implementációs irány:**
- `.help("...")` modifer az érintett `Button`/stepper-gomb nézeteken belül
- A szöveg lokalizálandó (`String(localized:)` vagy `LocalizedStringKey`) — de a tooltip
  tartalom kizárólag EN/HU kell (többi nyelv nincs tervezve)
- `ComponentStepper.swift`-ben a increment/decrement `LongPressStepperButton` hívásain belül
  kell elhelyezni — ott van a `unit` paraméter, ami az accessibility label alapja is

**Státusz:** ✅ KÉSZ (Session CK, commit `05c1460`) — teljes audit elvégezve; az összes scope-beli
elem rendelkezett `.help()`-pel (korábbi sessionokból), kivéve:
- `ContentView.swift` `modeButton` → `.help()` hozzáadva, 3 új xcstrings kulcs (`Switch to Calculate/Countdown/Snippets`, HU fordításokkal)
- `SnippetsView.swift` snippetRow edit button → `.help(String(localized: "Edit snippet"))` hozzáadva

---

## ENH-SETTINGS-3: Betűtípus választható a Settings Appearance tabján 🟢 DEFERRED

Az Alien League font (jelenleg dekoratív számokhoz/címekhez fix) opcionálisan ki-/bekapcsolható
legyen, vagy alternatív fontok közül lehessen választani az Appearance tabban.

**Gondolat:** az Alien League erős vizuális karakter — egyes felhasználóknak túl "nehéz" lehet,
mások szeretnék mindenütt. Lehetséges irányok:
- Toggle: Alien League on/off (off esetén system font a dekoratív helyeken is)
- Picker: pl. "Alien League" / "System" / esetleg egy harmadik opció

**Státusz:** DEFERRED — nem most, az ENH-SETTINGS-2 (méret) elegendő egyelőre

---

## ENH-DEVDOCS-2: Distribution csomag 🟡

- `install.md` (EN, GitHub-ra feltölve)
- README: sideproject management tool framing — development on a budget, ingyenes accountok felszabadítása,
  hajnali fejlesztési szokás (első fény = húzás aludni), context management sessionok között (snippets).
  Jobb projektnevet is ki kell találni (a "countdownApp" csak munkacím).

**Státusz:** NYITOTT — README szöveg + install.md megírása külön session; projektnév egyeztetés szükséges

---

## ENH-DEFERRED-1: Deferred taskok dokumentálása (lokalizáció, Settings, About, Help) 🟢

Több deferred téma nincs formálisan dokumentálva:
- **Lokalizáció**: UI nyelv és input nyelv/locale-ok külön kezelése (a `Formatters.swift` fejléc már említi
  deferred taskként, de nincs részletes terv)
- **Settings menü**: jelenleg nincs — szükséges lenne a lokalizációs beállításokhoz és egyéb jövőbeli
  opciókhoz
- **About**: termék-infó (verzió, szerző, stb.) nincs
- **Help menü**: nincs

**Státusz:** NYITOTT — csak dokumentálás, nincs implementációs döntés; scope + prioritás egyeztetése szükséges

---

