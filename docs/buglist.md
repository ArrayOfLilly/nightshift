# countdownApp — Bug & Enhancement List

Minden bejegyzés egyeztetés után kerül implementációra.
Prioritás-jelzés: 🔴 kritikus, 🟡 fontos, 🟢 nice-to-have

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

**Státusz:** 🟡 VALÓSZÍNŰLEG MEGOLDVA (nem megerősítve) — a `LazyVStack` → `VStack` csere (általános
hang-fix, lásd handoff.md) feltehetően megszüntette ezt a jelenséget is, mellékhatásként. A korábbi
.onDisappear double-call elmélet (ld. BUG-SNIPPETSAVE-1) továbbra is valós, önálló hiba (duplikációt okoz),
de már NEM tekintjük elsődleges beachball-gyanúsnak. "NEXT SESSION" adatméret-elmélet ELVETVE mint fő ok.
Következő lépés: felhasználói megerősítés több session/reprodukálási kísérlet után, mielőtt ✅ KÉSZ-re
zárnánk. Addig NYITOTT marad, de alacsonyabb prioritással.

---

## BUG-MANUAL-1: Manual frissítése a bezárási metódus változása miatt 🟡

Az AZ sessionben implementált pipa/X viselkedés (`NotesSheet` + `SnippetEditSheet` — pipa: ment+dismiss,
X: dirty esetén confirm alert) BF sessionben dokumentálva lett a manualban (`05e` eye badge, `11b` Notes
unsaved-changes, `17 Exit` Snippets unsaved-changes; git `515aa7e`) — EZ A RÉSZ KÉSZ volt.

**ÚJRANYITVA:** azóta több olyan változás történt, ami újra elavulttá teszi a manualt:
- **BUG-SNIPPETSAVE-1 + BUG-SNIPPETDUP-1** (BN session) — a save/dismiss logika változott
  (`shouldSaveOnDisappear`, snippet `@State` upsert) — a manual Snippets szerkesztés szekciója
  ezt még nem tükrözi
- **BUG-PROJECTDELETE-1** (BL session) — project törlés viselkedése változott (General alá
  mozgatás adatvesztés helyett) — nincs a manualban
- **App név változás** (BH+BJ session) — `countdownApp`/`NightShift` átnevezés (Display Name,
  Bundle ID, PRODUCT_NAME) — a manual screenshotjai/szövege még a régi nevet tükrözhetik

**Függőség:** a manual frissítés (és screenshotok készítése) csak az összes többi nyitott, UI-t
érintő további változás (pl. `ENH-HELP-1`) elkészülte után történjen — a manual mindig utolsóként
jön, hogy a screenshotok a végleges állapotot tükrözzék.

**Státusz:** NYITOTT (újranyitva) — 3 frissítési ok felhalmozódott (snippet save/dismiss logika,
project delete, app név), ezeket egyben, a legvégén érdemes elintézni

---

## ENH-DEVDOCS-1: Fejlesztői dokumentáció hiányzik 🟡

Nincs külön fejlesztői dokumentáció (architektúra áttekintés, modul felelősségek, persistence réteg,
recovery infrastruktúra, hogyan fejlesztünk egy új feature-t) — jelenleg csak a `Claude.md` (fejlesztési policy) +
`countdownApp-handoff.md` (session-állapot) létezik, ezek nem helyettesítik a termék/architektúra dokumentációt.

**Státusz:** NYITOTT — tartalom + struktúra egyeztetése szükséges, implementáció külön session

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

**Státusz:** 🟡 FOLYAMATBAN — S1 KÉSZ (BO session): `Models/HelpContent.swift` + `Localizable.xcstrings`
létrehozva (5 szekció, 11 item, EN placeholder szöveg). S2 következik (HelpWindowID + HelpCommands +
HelpView váz).

---

## ENH-L10N-1: Lokalizáció HU/EN 🟢

Elkülönített locales és UI nyelv. iconKeeper mintájára. Kapcsolódik: ENH-SETTINGS-1 (Settings menü
ahol a language/locale választható).

**Státusz:** NYITOTT — deferred, egyeztetés előtt nem indul el

---

## ENH-SETTINGS-1: Settings menü — UI Language, Locales 🟢

UI Language és locale-választék a Settings menüben. iconKeeper mintájára. Előfeltétel: ENH-L10N-1.

**Státusz:** NYITOTT — deferred, egyeztetés előtt nem indul el

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

