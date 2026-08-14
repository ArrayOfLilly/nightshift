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

**Státusz:** 🔴 KRITIKUS — a .onDisappear double-call elmélet megerősítve kódolvasásból (ld. BUG-SNIPPETSAVE-1
fix javaslat), ez valószínűleg a duplikációt és a beachball egy részét magyarázza. `MarkdownWebView`
ELVETVE mint gyanús terület (lásd fent, mind a 4 repró sheet-zárva állapotban történt). ÚJ fókusz:
a "NEXT SESSION" snippet adatmérete/duplikátumai + a perzisztencia útvonal főszál-blokkolása nagy
adatméret esetén. Következő lépés: `Snippet.swift` `save()`/`load()` és `AppKeys.swift` átvizsgálása,
valamint a felhasználótól kérdezni: kb hány "NEXT SESSION" című snippet látszik jelenleg a listában
(BUG-SNIPPETDUP-1 miatt felhalmozódott példányszám ellenőrzése).

---


## UX-1: Max-szélesség korlátok hiánya 🟡

**Érintett területek:**
- Főablak (ContentView / CountdownView) — nincs maximális szélesség; nagyon széles ablakban
  az elemek ízléstelenül szétfolynak
- `CalculateView` componentStepper-ek — a két chevron gomb eszelősen messze kerül egymástól
  széles ablakban; a steppernek saját `maxWidth`-re van szüksége
- `CountdownRowView` countdown elemek — hasonló probléma: a sor megnyúlik, nincs cap
- `SnippetsView` snippet sorok — kisebb prioritás, de konzisztencia miatt érdemes limitálni

**Popupok — egyenkénti ellenőrzés szükséges:**
- `AddCountdownSheet` — már van `WindowHelpers` alapú sheetWidth; ellenőrizni: tartalom
  a széles ablakban összetartja-e magát
- `ColorPickerSheet` — ellenőrizni
- `NotesSheet` — ellenőrizni
- `SnippetEditSheet` — ellenőrizni
- `DeadlineDetailSheet` — új fájl, még nem ellenőrzött
- `CalculateView` (saveSheet + deadline detail) — ellenőrizni

**Egyeztetés lezárva (AU session):**
- Főablak max szélesség: **520pt** — ez az egyetlen szükséges változás
- Megvalósítás: ContentView / WindowGroup szinten (pontosan hol: implementációkor dől el)
- ComponentStepper, CountdownRowView, SnippetsView sorok: külön cap nem kell — a főablak max elég
- Popup-ok (AddCountdownSheet, ColorPickerSheet, DeadlineDetailSheet, CalculateView sheets,
  NotesSheet, SnippetEditSheet): mind marad a jelenlegi WindowHelpers range — nem érintett
- Referencia: MBP M4 14", 1800×1169 felbontás; app ablak látható szélessége ~500–520pt-nek
  felel meg azon a kijelzőn (Claude Desktop ~900px + app a maradék jobb oldalon ~55–60%)

**Státusz:** ✅ KÉSZ — implementálva AU sessionben (`AppTheme.windowMaxWidth = 520`, commit `bc725a2`/`4bbe75e`).
Lásd UX-2 alant — az 520pt érték felülvizsgálat alatt.

---

## UX-2: Főablak max szélesség felülvizsgálata (520pt → 600pt?) 🟡

A felhasználó visszajelzése szerint a tényleges ablak szélesség 500–520pt között mozog — a jelenlegi
`windowMinWidth = 460` / `windowMaxWidth = 520` (UX-1, AU session) tartomány gyakorlatilag nem enged
érdemi átméretezést.

**Két opció, egyeztetés szükséges:**
1. `windowMaxWidth` növelése 600pt-ra — több mozgástér az átméretezésre
2. Fix 500pt szélesség, `.windowResizability` teljesen kikapcsolva — ha úgyis csak 500–520pt között van értelme,
   az átméretezhetőség feleslegessé válik

**Státusz:** ✅ KÉSZ — BF session: `AppTheme.windowMaxWidth = 600` (volt: 520); comment frissítve (UX-2 hivatkozás). `ContentView` érintetlen — már `AppTheme.windowMaxWidth` tokent használ (AU session).

---

## BUG-CHECKMARKDIRTY-1: SnippetEditSheet checkmark mentése után az X mégis confirm alertet mutat 🔴

Meglévő snippet szerkesztése: szöveg módosítása → checkmark (menti, VIEW módba vált) → X (bezárás) —
az X ennek ellenére felteszi a “Quit without saving / Save and quit / Cancel” confirm alertet, holott a
checkmark már elmentette a változást és nem kéne újra rákérdeznie.

**Valószínű root cause (AZ session implementáció alapján):** `originalTitle`/`originalProject`/`originalBody`
`let` property-k, csak `init`-ben beállítva (dirty baseline). A checkmark (`commitEdit()`) menti a
szöveget és `isEditing = false`-ra vált, de az `original*` baseline-t NEM frissíti — így az `isDirty`
computed var továbbra is `true`-t ad, mert a jelenlegi érték még mindig eltér az init-kori originaltól.
Ezért az utána következő X (`handleDismiss()`) feleslegesen dirty-nek látja az állapotot.

**Ellenőrzés a következő sessionben:** meg kell nézni, hogy a `commitEdit()` (checkmark ág) frissíti-e
az `original*` értékeket mentés után — ha nem, ezt kell pótolni (pl. `original* = current*` a `commitSave()`
hívása után, checkmark ágban). Megjegyzés: mivel az `original*` jelenleg `let`, ehhez `var`-ra kell váltani
— ez adatmodell-érintő változás, a Claude.md szabálya szerint egyeztetés szükséges implementáció előtt.
Hasonló root cause-t érdemes megnézni a `NotesSheet`-ben is (lásd `BUG-NOTESDISMISS-1` — ott más a hiba,
de a dirty-tracking mechanizmus rokon).

**Státusz:** ✅ KÉSZ — BC session: `let` → `var` az `original*` property-ken; `commitEdit()` checkmark ágában `originalTitle/Project/Body = title/project/snippetBody` refresh a `commitSave()` után.

---

## BUG-MANUAL-1: Manual frissítése a bezárási metódus változása miatt 🟡

Az AZ sessionben implementált pipa/X viselkedés (`NotesSheet` + `SnippetEditSheet` — pipa: ment+dismiss,
X: dirty esetén confirm alert) nincs dokumentálva a manualban. Screenshotok készülnek, utána a
`countdownApp-manual.md` érintett szekciói (Notes, Snippets szerkesztés) frissítendők.

**Függőség:** a manual frissítés (és screenshotok készítése) csak az összes többi nyitott, UI-t érintő
további változás (pl. `ENH-NOTEBADGE-1`) elkészülte után történjen — a manual mindig utolsóként jön,
hogy a screenshotok a végleges állapotot tükrözzék.

**Státusz:** NYITOTT — screenshot előkészítés alatt (felhasználó oldalán), implementáció (manual szöveg/kép) külön session

---

## ENH-DEVDOCS-1: Fejlesztői dokumentáció hiányzik 🟡

Nincs külön fejlesztői dokumentáció (architektúra áttekintés, modul felelősségek, persistence réteg,
recovery infrastruktúra, hogyan fejlesztünk egy új feature-t) — jelenleg csak a `Claude.md` (fejlesztési policy) +
`countdownApp-handoff.md` (session-állapot) létezik, ezek nem helyettesítik a termék/architektúra dokumentációt.

**Státusz:** NYITOTT — tartalom + struktúra egyeztetése szükséges, implementáció külön session

---

## BUG-TRASH-1: Editor trash gomb nem törli véglegesen a snippetet 🔴

Az editorban (`SnippetEditSheet` feltételezhetően, pontosítandó) a trash gomb látszólag törli a snippetet,
de a törlés után visszakerül (feltehetően auto-save / `.onDisappear` / dirty-state interakció miatt).

**Státusz:** ✅ KÉSZ — BE session: `shouldSaveOnDisappear = false` a delete alert destructive ágában,
`.onDisappear` nem hívja `commitSave()`-t törlés után. Git commit: `6dfb0ab`

---

## BUG-DETAILDELETE-1: CountdownDetailView törlés után nem navigál vissza 🔴

`CountdownDetailView`-n egy countdown item törlésekor a nézet nem csukódik be / navigál vissza automatikusan
a `CountdownView`-ra — a felhasználó egy már nem létező item részletein marad, ami használhatatlan állapot.

**Státusz:** ✅ KÉSZ — BD session: `@Environment(\.dismiss)` hozzáadva `CountdownDetailView`-ba;
delete alert destructive ágában `onDelete(); dismiss()` — navigáció visszaugrik `CountdownView`-ra.
Git commit: `485e363`

---

## BUG-NOTESDISMISS-1: NotesSheet X gomb ment szó nélkül, nem követi a SnippetEditSheet dirty-check mintát 🔴

Az AZ sessionben a `SnippetEditSheet`-ben implementált pipa/X viselkedés (X gomb: dirty állapotban
confirm alert “Cancel” / “Quit without saving” / “Save and quit”, tiszta állapotban egyszerű dismiss)
nem került át a `NotesSheet`-be — ott az X továbbra is szó nélkül menti és bezárja a lapot, ahelyett
hogy ugyanazt a dirty-check + confirm alert logikát követné.

Megjegyzés: a `progress.md` BA session bejegyzése tévesen állította, hogy a `NotesSheet` már helyesen
implementálva volt (“nem érintett, már helyes volt”) — ezt a következő sessionben felül kell vizsgálni
a tényleges kód alapján, nem a korábbi feljegyzés alapján.

**Státusz:** ✅ KÉSZ — BC session: debounce eltávolítva; `originalNotes` baseline (`.onAppear` +
`commitEdit()` refresh); `handleDismiss()` `draft == originalNotes`; "Quit without saving" visszaállít.

---

## ENH-NOTEBADGE-1: Vizuális jelzés a countdown itemen, ha van hozzá note 🟢

Jelenleg a `CountdownRowView` (és feltételezhetően `CountdownDetailView` címe is) nem jelzi vizuálisan,
hogy az adott countdown itemhez tartozik-e note. Felhasználói megfogalmazás: kell valami jelzés a név
mögé, pici badge — szín: **orangered**; forma: dot/szem-ikon/note-ikon — pontos választás még nyitott,
ha `item.notes` nem üres.

**Fontos sorrend:** ez a változás a manual (`BUG-MANUAL-1`) előtt valósítandó meg — a manual screenshotok
csak a végleges UI állapotot tükrözik, így a note badge-nek már látszania kell rajtuk mielőtt a manual
frissítés (és az ahhoz tartozó screenshotok) elkészülnek. Általánosabban: a manual mindig utolsóként
következik, miután minden más, UI-t érintő változás (bugfix vagy enhancement) már elkészült.

**Egyeztetendő részletek a következő sessionben:**
- Szín: **orangered** lezárva; `AppTheme`-ben nincs még orangered token — új szín bevezetése szükséges
  (Claude.md szabály: `enum AppKeys`-hez hasonlóan át kell gondolni, hova kerüljön — valószínűleg
  `AppTheme` új static color property-je)
- Forma: egyszerű dot, vagy szem-ikon (👁️-szerű), vagy note-ikon (📝-szerű) — SF Symbols közül kell
  választani, ha ikon a választás
- Méret, pozíció a név mellett/mögött
- Csak `CountdownRowView`-n, vagy `CountdownDetailView` fejlécén is jelenjen meg?
- Feltétel: `item.notes` nem üres string (trim-elve?) vagy csak nem-nil, ha a mező opcionális

**Státusz:** ✅ KÉSZ — BF session: `AppTheme.noteIndicator` token (orangered, `Color(red: 1.0, green: 0.27, blue: 0.0)`); `CountdownRowView` label box belsejében `note.text` SF Symbol ikon (`system(size: 10, weight: .medium)`), `if !item.notes.isEmpty`, `.accessibilityHidden(true)`.

---

## BUG-SUNPANEL-1: SunPanel popover bezárul egérelhúzásra 🔴

A `CalculateView` holdsor `.onHover` triggerrel nyitotta a `SunPanel` popovert, és `showSunPopover = false`-ra
állított amikor az egér elhagyta a holdsort — a popover nem maradt nyitva, amint a felhasználó a tartalomra
mozgatta az egeret.

**Root cause:** hover-alapú trigger + `onHover { inside in ... showSunPopover = inside }` mintája nem egyeztethető
össze a macOS popover „kívülre kattintva zár" viselkedésével. A popover bezárult mielőtt a felhasználó
bármit olvashatott volna.

**Fix (BG session):**
- `hoverTask: Task<Void, Never>?` `@State` eltávolítva
- `.onHover` blokk eltávolítva az egész holdsorról
- Középső hold (index 4, `pink_moon_5`) `Button` wrappérbe csomagolva: kattintásra `showSunPopover.toggle()`
- `.popover(isPresented: $showSunPopover)` átkerült a középső hold `Button`-jára
- Nem-középső holdak változatlanok (sima `Image`)
- `.accessibilityLabel("Sun times")` a középső holdra

**Státusz:** ✅ KÉSZ — BG session: click trigger, `hoverTask` eltávolítva. Build OK.

---

## ENH-ABOUT-1: About ablak 🟡

iconKeeper mintájára: verzió, szerző, attribution. Attribution itt: `images` (nem Freepik/Megnific mint az iconKeepernél).
Verzió beállítása is szükséges (összeegyeztetni az `Info.plist`-tel).

**Státusz:** NYITOTT — egyeztetés szükséges implementáció előtt (iconKeeper About forráskódja referencia)

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

### Nyitott egyeztetési pontok (még NINCS döntés, következő sessionben tisztázandó)

1. **L10n bevezetése ehhez kapcsolódva** — a felhasználó jelezte hogy az EGÉSZ appot lokalizálni akarja
   (nem csak a Help-et), tehát ez összefonja az `ENH-L10N-1` és `ENH-HELP-1` döntéseket. Két út:
   - **A)** `LocalizedStringKey` + `Localizable.xcstrings` LETREHOZVA MOST, kitöltve (legalább EN,
     esetleg HU is) — teljesen az IconKeeper mintán, azonnal működő lokalizációs alap
   - **B)** `LocalizedStringKey` használat MOST, de az `xcstrings` tartalma (fordítások) LATER —
     addig a nézet üres label-eket renderelne tartalom nélkül, ez kockázatos
   - A "plain String" opció (nem lokalizált, csak sima String a modellben) korábban már ELVETVE,
     mert az egész app lokalizációs iránya ellene szól — a döntés A vagy B között áll
2. **`imageName` mező kelljen-e a `HelpItem`-be MOST**, vagy later adódjon hozzá (IconKeeperben nincs
   ilyen mező, NightShiftnél viszont explicit igény van screenshot-alapú magyarázatra bizonyos itemeknél)
3. **Keresés mélysége**: elég-e az IconKeeper-mintájú `id`-alapú keyword szűrés, vagy kell egy külön
   `searchTokens: [String]` mező a `HelpItem`-ben (hu/en kulcsszólista), hogy a keresés ne csak az
   angol azonosítóra találjon, hanem magyar kifejezésekre is

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

**Státusz:** NYITOTT — tervezés folyában (BJ/BK sessionek), 4 egyeztetési pont vár felhasználói döntésre
mielőtt implementáció kezdődhetne. Következő lépés: a felhasználó válaszol a fenti 4 pontra, azután
HelpItem/HelpSection modell + HelpView + HelpCommands implementáció jöhet.

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

## BUG-PROJECTRENAME-1: Project átnevezéskor a snippetek Project mezője nem frissül 🔴

Projekt átnevezésekor az addig alá tartozó snippetek helyesen az új projekt alá kerülnek (asszociáció korrekt), de a snippet `project` mezőjének megjelenített/tárolt neve nem frissül az új névre — kézzel kell minden érintett snippetet átszerkeszteni.

**Root cause:** `SnippetsView.deleteProject(_:)` / `renameProject(_:to:)` — a projekt-snippet kapcsolat név-string alapú (nincs stabil ID). Átnevezéskor a `renameProject` map-pel frissíti a snippetek `project` mezőjét, de az eredeti kód nem tette ezt meg. Fix: az `editTarget` state `Snippet` value snapshot helyett `EditTarget: Identifiable { let id: UUID }` — a sheet closure az aktuális `snippets` tömbből keresi fel az ID alapján a snippetet, így egy átnevezés a tap és a sheet-open között is helyesen tükröződik. A `renameProject(_:to:)` a `snippets` tömböt map-peli és a `project` mezőt az új névre állítja minden érintett snippetnél.

**Fix (BM session):**
- `SnippetsView`: `editTarget: EditTarget?` (volt: `Snippet?`) — ID-only snapshot
- `renameProject(_:to:)` — map + project field update minden érintett snippetnél
- Build OK

**Státusz:** ✅ KÉSZ — BM session

---

## BUG-PROJECTDELETE-1: Project törléskor a hozzá tartozó snippetek elvesznek / nem kerülnek Generalba 🔴

Projekt törlésekor az addig az adott projekt alatt lévő snippeteknek a General alá kellene kerülniük, de ez jelenleg nem történik meg. Felhasználói megjegyzés: az eredeti (jelenlegi) viselkedés az ő korábbi döntése volt, de utólag rossz döntésnek bizonyult — a kívánt viselkedés mostantól: törléskor automatikus átmozgatás Generalba, adatvesztés nélkül.

**Root cause:** `SnippetsView.deleteProject(_:)` — `snippets.removeAll { $0.project == project }` helyett a snippeteket "General"-ba kellene mozgatni. Kontrast: `renameProject` helyesen mapol, csak a célprojekt neve másik.

**Fix (BL session):**
- `deleteProject` — `removeAll` helyett `map` + "General" project-eset
- Minta: `renameProject` funkció, csak target = "General"
- Adatvesztés nélkül, összes snippet megtartva
- Build OK

**Státusz:** ✅ KÉSZ — BL session

---

## BUG-SNIPPETSAVE-1: Snippet módosítás mentés (save and quit) csak az első módosítást őrzi meg 🔴

Meglévő snippet szerkesztésekor: módosítás → checkmark (menti, estado frissül) → újra módosítás → X → "Save and quit" — a végeredményben az utolsó módosítás elveszik; a snippet csak az előző checkmarkolt állapotot őrzi meg.

**Root cause (felhasználó által azonosított, erősítendő):**

A "Save and quit" ág a dismiss alertban:
```swift
Button("Save and quit") { commitSave(); dismiss() }
```

Ez `commitSave()`-t hív és rögtön `dismiss()`-t is hív. A mentés elméletileg megtörténik, de valódi probléma máshol van: a `.onDisappear` hook:
```swift
.onDisappear { if shouldSaveOnDisappear { commitSave() } }
```

A "Save and quit" ágban `shouldSaveOnDisappear` **`true` marad** (nem állítja senki `false`-ra), ezért a `dismiss()` után az `.onDisappear` **másodszor is meghívja a `commitSave()`-t**. Ezt követően már a sheet el van tüntetve, és a jelenlegi State értékek (`title/project/snippetBody`) nem feltétlenül ugyanazok, mint az alert megjelenésekor voltak (SwiftUI lifecycle sajátossága). Az `.onDisappear`-ben a `commitSave()` a jelenlegi State értékeket használja — de `dismiss()` után a SwiftUI-nak jogában áll módosítani a view state-et a dismiss folyamat közben.

**Praktikus forgatókönyv:**
1. Checkmark: `commitSave()` lefut, `originalTitle/Project/Body` frissül (BC session fix miatt), `isEditing = false`
2. Újabb módosítás: `snippetBody` változik (még egyszer azelőtt, hogy az X-re kattint)
3. X → "Save and quit": `commitSave()` + `dismiss()`
4. `.onDisappear`: `commitSave()` **újra lefut** — de a `snippetBody` state már esetleg nem reliably a step 2-es érték (vagy üres, vagy egy korábbi state-érték, amit SwiftUI állított meg az .onDisappear futása előtt)

**Ajánlott fix:**
A "Save and quit" ágban `shouldSaveOnDisappear = false` hozzáadása a `commitSave()` előtt — pontosan mint a "Quit without saving" ágban (`shouldSaveOnDisappear = false`), csak ott `commitSave()` nincs. Ez meg szünteti a double-call-t és garantálja, hogy az utolsó beírt érték ténylegesen mentésre kerül (csak egyszer).

**Root cause — MEGERŐSÍTVE (BN session, kódolvasás):** `SnippetEditSheet.swift`, `showDismissConfirm` alert:
```swift
Button("Save and quit") { commitSave(); dismiss() }
```
nincs `shouldSaveOnDisappear = false` előtte (ellentétben a "Quit without saving" és a delete-alert ágakkal, ahol ez megvan) → `.onDisappear { if shouldSaveOnDisappear { commitSave() } }` a `dismiss()` után MÉG EGYSZER lefut. A gyanú pontosan igazolódott — ez az egysoros fix hiányzik, semmi más nem tér el a leírt elmélettől. Ez a bug egyben **BUG-SNIPPETDUP-1** valódi (determinisztikus) root cause-ának is része új snippetnél, ld. ott.

**Státusz:** 🔴 NYITOTT, ROOT CAUSE MEGERŐSÍTVE — fix: egy sor (`shouldSaveOnDisappear = false` a "Save and quit" ágban, a `commitSave()` elé). Implementáció + build test egyeztetésre vár.

---

## BUG-SNIPPETDUP-1: Új snippet néha duplikáltan jön létre (ugyanaz a tartalom kétszer) 🔴

Új snippet létrehozásakor előfordult, hogy két (vagy több), különböző állapotú snippet jött létre ugyanabból a szerkesztési munkamenetből (pl. a módosítás előtti és utáni változat külön bejegyzésként).

**Root cause — MEGERŐSÍTVE és ÚJRAÉRTELMEZVE (BN session, kódolvasás: `SnippetEditSheet.swift` + `Snippet.swift` + `SnippetsView.swift`).**
Ez NEM flaky/gyors-kattintás hiba, hanem determinisztikus, szerkezeti bug új snippet esetén:

- `SnippetEditSheet.snippet` egy `let Snippet?` — új snippetnél `nil`-lel inicializálva, és **soha nem frissül** a sheet élettartama alatt, még az első sikeres mentés után sem.
- `commitSave()` mindig `Snippet.committed(from: snippet, ...)`-et hív, ahol `snippet` új bejegyzésnél MINDIG `nil` marad.
- `Snippet.committed(from: nil, ...)` (`Snippet.swift`) ága: `var s = existing ?? Snippet(title: "", body: "", project: "")` — mivel `existing` = `nil`, **minden egyes hívás új `UUID()`-t generál**.
- `SnippetsView.swift`, `showNewSheet` sheet `onSave` closure:
  ```swift
  SnippetEditSheet(snippet: nil, ..., onSave: { new in
      snippets.append(new)   // MINDIG append, nincs id-alapján upsert (szemben a meglevő snippet szerkesztés ágával, ott firstIndex(where:) van)
      Snippet.save(snippets)
  }, onDelete: nil)
  ```
- Eredmény: ha egy új snippet sheeten belifogy többször checkmarkol (pl. checkmark #1 a cím/kategória felvételéhez, aztán céruza → body szerkesztés → checkmark #2), MINDEN checkmark egy új, külön UUID-jű snippetet appendel — nem ugyanazt frissíti. Ugyanez történik akkor is, ha csak EGY checkmark van, de a **BUG-SNIPPETSAVE-1** double-call hibája miatt a `.onDisappear` még egyszer lefuttatja `commitSave()`-t — ez is egy MEGA új UUID-jű példányt hoz létre, tehát a két hiba összeadódik.
- Ez pontosan illeszkedik a felhasználó legutóbbi leírására: "Új snippet, check, módosítás után újra check, 2-t ment belőle, a módosítás előttit is, meg az utánit is, külön."

**Ajánlott fix (egyeztetésre vár, több lehetséges irány):**
1. `SnippetEditSheet.snippet`-et `let`-ről `@State private var snippet: Snippet?`-re váltani, és `commitSave()`-ben az első sikeres mentés után `self.snippet = s` — ezáltal a következő `commitSave()` hívás már `existing`-ként látja és update-eli, nem újat hoz létre.
2. VAGY: a `SnippetsView` `showNewSheet` `onSave` closure-át is id-alapján upsert-elni (mint a meglevő szerkesztés ágnál), így ha ugyanaz a `Snippet` állítólag "új" UUID-vel jönne, az legalább az ID egyezése alapján szűrhető — de ez nem oldja meg a valódi hibát (még mindig különböző UUID-k jönnek létre), csak tapasztó megoldás lenne.
**Javasolt: 1-es opció, mert ez szünteti meg a tényleges okot.** Emellett **BUG-SNIPPETSAVE-1** fix-je (`shouldSaveOnDisappear = false` a "Save and quit" ágban) is szükséges — a két hiba együtt adja a teljes képet, együtt érdemes javítani és tesztelni.

**Státusz:** 🔴 KRITIKUS, ROOT CAUSE MEGERŐSÍTVE és DETERMINISZTIKUSNAK BIZONYULT (nem flaky) — fix irány egyeztetésre vár, azután implementáció + build test

---

## BUG-DISPLAYNAME-1: Tab Display Name-ek összekeveredtek átnevezés után 🔴

Három tab, három Display Name várt lenne, de a tényleges állapot: 1. Calculate Tab → "NightShift", 2. Countdown Tab → "Countdown", 3. Snippets Tab → "NightShift". A Snippets Tab helyesen nem "NightShift"-et kéne mutasson. Felhasználói megjegyzés: átnevezés előtt is hibás volt az állapot, csak akkor a Snippets Tab helyén "Countdown" szerepelt (ami szintén hibás volt) — ezért nem tűnt fel korábban, mert nem volt annyira feltűnő az ismétlődés.

**Root cause:** a macOS ablak title bar a `WindowGroup` aktív view-jának `.navigationTitle`-jéből olvassa a nevet. Ha nincs ilyen, a `CFBundleName` = `"NightShift"` jelenik meg alapértelmezettként. A `CountdownView` egy `NavigationStack`-be van csomagolva (ezért volt ott `.navigationTitle("Countdown")`), de a `CalculateView` és `SnippetsView` nem — ezért azok `"NightShift"`-et mutattak.

**Fix (BM session):**
- `CalculateView` gyökerébe: `.navigationTitle("Calculate")` (NavigationStack nélkül — macOS-on a modifier önállóan is hat a title bar-ra)
- `SnippetsView` gyökerébe: `.navigationTitle("Snippets")` (ugyanaz a minta)
- `CountdownView` és `ContentView` érintetlen
- Build OK

**Státusz:** ✅ KÉSZ — BM session

---
