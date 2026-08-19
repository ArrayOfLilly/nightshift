## Session D1 — 2026-08-19 (Privacy Policy .md fájlok — KÉSZ)

### Session D1 — KÉSZ
Privacy Policy xcstrings tartalom (18 kulcs, EN+HU mind teljes) alapján létrehozva
2 standalone dokumentum:
- `docs/privacy-policy.md` — EN változat
- `docs/privacy-policy-hu.md` — HU változat

Mindkét fájl tartalmaz: intro (Your Privacy Matters / Az adataid védelme fontos),
local data szekció bullet listával (5 item), network access szekció, no tracking szekció,
contact szekció (mailto link), footer (Last updated: 2026 / Utoljára frissítve: 2026).

A tartalom kizárólag a `Localizable.xcstrings` privacy.* kulcsaiból generálva —
nem kézzel írva, ezért automatikusan tükrözi az app szövegét.

Build: N/A (csak dokumentáció). Git commit: FELHASZNÁLÓ FELADATA.

**Következő session:** Release folyamat (GitHub Actions? manuális .dmg? App Store? —
egyeztetés a felhasználóval), majd `BUG-SNIPPETPROJECTGENERAL-1` build-megerősítés
ja CZ/CY build-ek ellenőrzése, ha az még nem történt meg.

---

## Session D0 — 2026-08-19 (ENH-PRIVACY-1: PrivacyPolicyView 2 build hiba — KÉSZ)

### Session D0 — KÉSZ
Privacy policy munka közben (`PrivacyPolicyView.swift`) két független build hiba:

1. **65. sor** — `.foregroundStyle(.accentColor)`: `Type 'ShapeStyle' has no member 'accentColor'`.
   Régi `.accentColor(_:)` view modifier / `Color.accentColor` névütközés — `ShapeStyle`-nak
   nincs ilyen statikus tagja. Javítás: `.foregroundStyle(Color.accentColor)`, ugyanaz a minta,
   amit a fájl másik része (`PolicySection`, kb. 103. sor) már helyesen használt.
2. **126. sor** — `ForEach(items, id: \.self)` ahol `items: [LocalizedStringKey]`:
   `Generic struct 'ForEach' requires that 'LocalizedStringKey' conform to 'Hashable'`.
   `LocalizedStringKey` nem `Hashable`. Javítás: `PolicyBulletList.items` típusa
   `[LocalizedStringKey]` → `[String]` (a hívó oldal már String literalokat adott át,
   nem kellett változtatni), a megjelenítésnél `Text(key)` →
   `Text(String(localized: String.LocalizationValue(key)))` — ugyanaz a dinamikus
   lokalizációs minta, amit a kódbázis már használ máshol (pl. `ContentView.modeButton`).

**Érintett fájl:** `Views/PrivacyPolicyView.swift` (2 célzott csere, `Filesystem:edit_file`).
xcstrings tartalom nem változott.

Build: FELHASZNÁLÓ FELADATA. Git commit: FELHASZNÁLÓ FELADATA.

**Következő session:** ha build megerősíti, folytatás a privacy policy munkával (pl.
ENH-PRIVACY-1 hu/en xcstrings tartalom átnézése, ha még nem teljes), majd vissza a korábbi
napirendre (ld. CZ/CY alatt).

---

## Session CZ — 2026-08-19 (BUG-XCSTRINGS-SYMBOLCLASH-1: xcstrings szimbólumütközés — KÉSZ)

### Session CZ — KÉSZ
Privacy policy munka közben Xcode hiba: "day"/"DAY", "hour"/"HOUR", "year"/"YEAR" xcstrings
kulcsok ugyanazt a generált Swift szimbólumot eredményezték volna.

**Diagnózis:** Xcode 26 `STRING_CATALOG_GENERATE_SYMBOLS = YES` (fő target Debug+Release) —
a kulcsok automatikus Swift-szimbólum-generálása a nagybetűs kulcsokat (`"DAY"`) camelCase-eli,
ami ugyanarra a szimbólumnévre fut ki, mint a kisbetűs `"day"` — innen mindhárom ütközés.
A kódbázis sehol nem használ generált szimbólumot, mindenhol `String(localized:)` mintát követ —
a funkció felesleges volt itt.

**Javítás:** `project.pbxproj` — `STRING_CATALOG_GENERATE_SYMBOLS = YES` → `NO` a fő
(com.arrayoflilly.nightshift) target mindkét configjában (Debug + Release), így illeszkedik
a Tests/UITests targetekhez, amik már eddig is `NO`-n álltak. `Filesystem:edit_file`-lal,
célzott cserével, 2 külön hívással (a két YES előfordulás nem volt egyedi kontextusban
megkülönböztethető első körben, dryRun-nal ellenőrizve melyik sor cserélődik).

**Érintett fájl:** `countdownApp.xcodeproj/project.pbxproj` (2 sor). xcstrings tartalom
NEM változott — a kulcsok ("day"/"DAY" stb.) érintetlenek maradtak.

Build: FELHASZNÁLÓ FELADATA — ellenőrizendő, hogy a hiba eltűnt és a lokalizáció
(String(localized:) hívások) továbbra is helyesen működik. Git commit: FELHASZNÁLÓ FELADATA.

**Következő session:** ha build megerősíti, vissza a privacy policy munkára, majd a korábbi
napirendre (ld. CY alatt: BUG-SNIPPETPROJECTGENERAL-1 build-ellenőrzés).

---

## Session CY — 2026-08-19 (BUG-SNIPPETPROJECTGENERAL-1: "default.General" projektnév hiba — KÓD JAVÍTVA)

### Session CY — KÓD JAVÍTVA, build FELHASZNÁLÓ FELADATA
Felhasználói bugjelzés: SnippetsView-ban "General" helyett "default.General" jelenik meg, és ABC
rendben a "d" betűnél szerepel (nem utolsóként, ahogy `.general`-nek kellene).

**Diagnózis:** `ProjectCategory.swift`, `SnippetsView.swift`, `Snippet.swift` átnézve — a jelenlegi
kód (canonical key `"default_general"`, `projectKeys` `.general`-t utoljára rendezi) önmagában
helyes. A hiba forrása régi/hibás adat a felhasználó `UserDefaults`-jában: egy vagy több snippet
`project` mezője szó szerint `"default.General"` (PONT, nem aláhúzás) — valószínűleg a CU
session (`ProjectCategory` bevezetése) körüli átmeneti/hibás build írta. A jelenlegi decoder
ezt a változatot nem ismeri fel legacy formának, így `.custom("default.General")`-ként
dekódolódik — innen a nyers felirat és a "d" betűs ABC-pozíció.

**Javítás:** `Models/ProjectCategory.swift` `init(from decoder:)` — a nyers stringet
összehasonlítás előtt normalizáljuk (`lowercased()`, majd `_` és `.` eltávolítva); így
`"default_general"`, `"General"`, `"general"`, `"default.General"`, `"default.general"` mind
`.general`-re migrál a következő betöltéskor — nincs szükség kézi `UserDefaults` törlésre/
migrációra, a meglévő lazy decode-time migration mintát követi, csak szélesebb felismeréssel.

**Érintett fájl:** `Models/ProjectCategory.swift` (1 függvény, `Filesystem:edit_file`-lal).
`docs/buglist.md` új bejegyzés: `BUG-SNIPPETPROJECTGENERAL-1`.

Build: FELHASZNÁLÓ FELADATA — élesben ellenőrizendő, hogy a "General" szekció most helyesen
"General" felirattal és utolsóként jelenik-e meg. Git commit: FELHASZNÁLÓ FELADATA.

**Következő session:** ha a build megerősíti a javítást, `BUG-SNIPPETPROJECTGENERAL-1` → ✅ KÉSZ
a buglist.md-ben, git commit. Ha nem (pl. további ismeretlen malformed variant van az adatban),
akkor a további variant feltérképezése szükséges. Ezután vissza a korábbi napirendre:
screenshot alt-szövegek HU fordítása, PDF-ek frissítése, vagy BUG-MANUAL-TEXT maradék 3 tétele.

---

## Session CX — 2026-08-19 (ENH-DEVDOCS-2: README + install.md — KÉSZ)

### Session CX — KÉSZ
ENH-DEVDOCS-2 lezárva. 4 fájl létrehozva a repo gyökerében:
- `README.md` — EN, publikus GitHub, személyes hangvétel ("I built this for myself because...")
- `README-hu.md` — HU változat
- `install.md` — EN, .dmg drag-to-Applications + build-from-source
- `install-hu.md` — HU változat

Egyeztetett döntések: NightShift projektnév végleges, Bundle ID `com.arraoyoflilly.nightshift`
(már kész volt, nem kellett Xcode rename). README framing: éjszakai side project fejlesztés,
ingyenes AI-fiókok cooldown-kezelése, napkelte mint kemény határ. Install: .dmg (Releases link)
+ Xcode build-from-source, first-launch Gatekeeper megjegyzéssel, adattárolás-megjegyzéssel.
Nyelv: EN+HU (mint a manualnál).

Build: N/A (csak dokumentáció). Git commit: FELHASZNÁLÓ FELADATA.

---

## Session CW folytatás — 2026-08-19 (HU manual: megjegyzés az angol screenshotokról — KÉSZ)

### Session CW folytatás — KÉSZ
Felhasználói kérdés: érdemes-e magyar screenshotokat készíteni a HU manualhoz.
Egyeztetve: nem éri meg (a képek Illustratorban kézzel maszkolt egységes méretre
hozott anyagok, újrakészítésük aránytalan és minden jövőbeli UI-változásnál
duplikálna munkát). Helyette egy rövid megjegyzés került a
`docs/manual/nightshiftApp-manual-hu.md` elejére, közvetlenül a bevezető bekezdés
után, a Fülsor szekció előtt:

> **Megjegyzés:** a kézikönyv képernyőképei angol nyelvű felhasználói felületet
> mutatnak; a szöveg a magyar felületet írja le.

`manual_build.py nightshift_hu` újrafuttatva, a `nightshiftApp-manual-hu.html`
frissítve a megjegyzéssel.

**Következő session:** ha a felhasználó kéri, PDF-ek frissítése a HTML-ekből, vagy
BUG-MANUAL-TEXT maradék 3 tétele, vagy ENH-DEVDOCS-2.

---

## Session CW — 2026-08-19 (HU manual terminológia-javítás + manual_build.py nightshift_hu — KÉSZ)

### Session CW — KÉSZ
Felhasználói kérés: a manual véglegesítése — angol a kód alapján (már megvolt, csak
spot-check), magyar a `Localizable.xcstrings` fordítási terminológiáját tükrözve (a
felhasználó által kiemelt példa: 3 szekciónév — Kalkuláció, Időzítő, Gyorsszövegek),
végül `manual_build.py` paraméterezhetővé tétele a HU build-hez (a `nightshift_hu`
variant már létezett a scriptben, de törött volt — ld. lent).

**Módszer:** `python3` a `Localizable.xcstrings`-ből (JSON) kulcsonként kiolvasta a
tényleges `hu` fordítást minden, a manualban bold/UI-elemként szereplő angol tokenre —
nem feltételezés, hanem a fájlból közvetlenül. `MacOS-MCP:Shell` használva a
fájlolvasáshoz/kereséshez (grep, python), mert a Filesystem MCP nem tud tartalom szerint
keresni egy 94KB-os xcstrings-ben — ez csak olvasás/keresés volt, minden tényleges .md és
.py fájlírás a `Filesystem:edit_file`-lal történt.

**`docs/manual/nightshiftApp-manual-hu.md` — talált és javított eltérések a valós HU UI-tól:**
- 3 fő szekciónév + Fülsor táblázat: Calculate/Countdown/Snippets (angolul hagyva) →
  **Kalkuláció / Időzítő / Gyorsszövegek** (`## H2` címek + táblázat cellák + az összes
  futószövegbeli előfordulás, kivéve a screenshot alt-szövegeket/fájlneveket, azok
  szándékosan angolul maradtak, mivel a képfájlnevek ténylegesen angolok)
- Gombfeliratok, amik eddig angolul maradtak a fordított szövegben, most a tényleges
  xcstrings HU értékre cserélve: SAVE→**MENTÉS**, CANCEL→**MÉGSE**, RESET FROM NOW→
  **MOSTANTÓL**, RESET TO NOW→**MOSTANÁIG**, DAYS→**PONTOS**, CAL→**NAPTÁR**,
  FROM→**KEZDÉS**, TO→**BEFEJEZÉS**, LOAD AS TO→**BETÖLTÉS**, RENAME→**ÁTNEVEZÉS**,
  +ADD→**+ ÚJ**, FREE ✓→**SZABAD ✓**, Delete→**Törlés**, Cancel→**Mégse**,
  Quit without saving→**Kilépés mentés nélkül**, Save and quit→**Mentés és kilépés**,
  YEAR/MON/DAY/HOUR/MIN→ÉV/HÓNAP/NAP/ÓRA/PERC, COPIED→MÁSOLVA
- Kisebb pontosítások a manual saját (nem xcstrings-ből idézett) parafrázisaiban, hogy
  pontosan illeszkedjenek a valós fordított UI-labelhez: "Felület nyelve" →
  "**Felhasználói felület nyelve**" (a tényleges Settings picker label), "Hátralévő idő"
  → "Hátralévő idő megjelenítése" (a tényleges toggle pill szöveg)
- Nyelvtani javítás: "A Countdown" → "Az Időzítő" (hangrend miatt "Az")
- **Ellenőrizve, HOGY NEM változott (már egyezett az xcstrings-szel):** Beállítások,
  Nyelv, Megjelenés, Betűméret, Dátum- és számformátum, Alapértelmezett/Nagy/Nagyobb/
  Legnagyobb, Általános, AUTO, English (US)/Magyar (HU) (ezek a nyelv-választó saját,
  nem lokalizált, hardcoded label-jei — helyesen angolul/natív névvel maradnak)

**`docs/manual_build.py` — javítva:**
- A `nightshift_hu` variant korábban törött volt: hibás behúzás a dict-ben + egy önálló
  `ż` karakter a `_VARIANTS` dict lezárása után (valószínűleg elgépelés egy korábbi,
  dokumentálatlan próbálkozásból) — ez `NameError`-t dobott volna minden futtatáskor,
  függetlenül a variant paramétertől. Eltávolítva, a dict újraindentálva a másik két
  variant stílusához igazítva.
- `page_break_h2` a `nightshift_hu`-nál eddig angol H2 címeket listázott
  (`{"Calculate", "Countdown", "Snippets", ...}`), miközben a HU `.md`-ben (a fenti
  javítás után) a tényleges H2-ek magyarul vannak — frissítve
  `{"Kalkuláció", "Időzítő", "Gyorsszövegek", "Beállítások", "Adathelyreállítás",
  "Tippek"}`-re. (Enélkül a HU PDF-ben egyetlen fejezet sem tört volna oldalt.)
- Új `"lang"` mező mindhárom varianthoz (`en`/`en`/`hu`) — a kimeneti HTML
  `<html lang="...">` attribútuma eddig hardcoded `"en"` volt a HU buildnél is.
- Docstring frissítve a 3. usage sorral (`nightshift_hu`).

**Tesztelve:** mindhárom variant (`countdown`, `nightshift`, `nightshift_hu`) lefuttatva
`python3 manual_build.py <variant>` — mind hibamentesen írta ki a HTML-t, nem volt
"image not found" warning egyiknél sem. `class="chapter"` előfordulások száma: 6 és 6
(EN és HU manual) — a HU oldaltörések most már ténylegesen működnek.

**Angol manual (`nightshiftApp-manual.md`) — task (a):** teljes egészében átolvasva,
spot-check jelleggel összevetve `ContentView.swift` Mode enummal, a Calculate/Countdown/
Snippets/Settings/Recovery funkciókkal a korábbi sessionök (CN–CV) jegyzetei alapján —
nem talált eltérést, naprakésznek tűnik. **Nem történt** soronkénti, minden Swift fájlra
kiterjedő újra-ellenőrzés (idő/token-korlát miatt) — ha ez szükséges, külön session.

**Nem történt még:** a `.pdf` fájlok (3 db a `docs/manual/`-ban) nem lettek
újragenerálva a HTML-ekből — azok külön (feltehetően kézi Print to PDF) lépés, a
felhasználó feladata, ha kéri.

**Következő session:** ha a felhasználó kéri, a screenshot alt-szövegek/képaláírások HU
fordítása is végigvihető (jelenleg pl. "Countdown lista", "Calculate nézet" formában
maradtak a képek `alt` szövegében és a fájlnevek előtti leíró szövegben — ezek nem
UI-elemek, csak leíró címkék, ezért alacsonyabb prioritásúak, de a teljes konzisztencia
kedvéért javíthatók). Vagy: PDF-ek frissítése a HTML-ekből. Vagy: BUG-MANUAL-TEXT
maradék 3 tétele (ld. buglist).

---

## Session CV folytatás — 2026-08-18 (Manual Fülsor hiba + BUG-MANUAL folyamat-javítás — KÉSZ)

### Session CV folytatás — KÉSZ
Felhasználói jelzés: a HU manual "Fülsor" szekciója ikon+sötét-kör UI-t ír le, ami nem
egyezik a tényleges `ContentView.swift`-tel (szöveglabelek, lekerekített téglalap háttér).
Git history (`git log --all -p -- countdownApp/Views/ContentView.swift`) megerősítette:
a `symbolName` bevezetve, de a `modeButton` sosem használta ténylegesen renderelésre —
felhasználó szerint ~70 commitból csak 2-3-ban élt ez az átmeneti állapot, mégis a manual
ezt őrizte, több későbbi manual-frissítés ellenére is.

**Gyökérok azonosítva:** a `BUG-MANUAL-1` addigi szabálya ("manual mindig legutoljára, egy
batch-ben, hogy a screenshotok véglegesek legyenek") a screenshotokra indokolt logikát a
leíró szövegre is ráterjesztette — pedig a szöveg semmilyen screenshot-függőséget nem
igényel, azonnal javítható lenne.

**Egyeztetve és elvégezve:**
- `Claude.md` — új alszekció "Manual (docs/manual/*.md) — szöveg vs. screenshot" a
  "Docs karbantartás" alatt: leíró szöveg AZONNAL javítandó az érintett sessionben (mint
  progress.md/handoff.md), screenshotok maradnak batch-elt, végén elintézendő feladatnak
- `docs/buglist.md` — `BUG-MANUAL-1` kettéválasztva:
  - `BUG-MANUAL-TEXT` — szöveg-szintű elavulások (3 régi tétel: snippet save/dismiss,
    project delete, app név — még nyitva; Fülsor tétel lezárva)
  - `BUG-MANUAL-SCREENSHOTS` — screenshot-frissítés, változatlanul a végére várva
- Mindhárom manual `.md` fájl "Tab Bar"/"Fülsor" szekciója javítva a tényleges UI-ra
  (szöveglabelek, lekerekített háttér, nincs ikon/kör): `nightshiftApp-manual-hu.md`,
  `nightshiftApp-manual.md`, `countdownApp-manual.md` (régi branding-variáns, konzisztencia
  miatt is javítva)

**Nem történt meg:** `.html`/`.pdf` manual-verziók regenerálása (`manual_build.py`) — ezek
még a régi tartalmat tükrözik, a felhasználó nem kérte kifejezetten.

**Következő session:** `BUG-MANUAL-TEXT` maradék 3 tétele (snippet save/dismiss logika,
project delete, app név) — screenshot-függetlenül javítható bármikor. Vagy ENH-DEVDOCS-2,
vagy build ellenőrzés.

---

## Session CV — 2026-08-18 (ENH-DEVDOCS-1: fejlesztői dokumentáció — KÉSZ)

### Session CV — KÉSZ
`docs/progress.md`, `docs/countdownApp-handoff.md`, `docs/buglist.md` (ENH-DEVDOCS-1/2),
`Claude.md` elolvasva, majd a teljes Swift forrásfa (`Filesystem:directory_tree`) és a
kulcsfájlok (`AppKeys.swift`, `CountdownItem.swift`, `Snippet.swift`, `NamedDeadline.swift`,
`ProjectCategory.swift`, `countdownAppApp.swift`, `ContentView.swift`, `CountdownView.swift`)
átnézve, hogy a doc a valós kódot tükrözze, nem a buglist elavult feltételezéseit.

**Egyeztetés (felhasználóval):** egy fájl (`docs/architecture.md`), angol nyelven (a Swift
kód kommentjeivel egyező konvenció).

**Létrehozva:** `docs/architecture.md` — 5 szekció:
- Overview (NightShift koncepció, 3 tab, entry point + 4 scene)
- Module responsibilities (App/Components/Models/Services/Theme/Views mappák szerepe)
- Persistence layer (UserDefaults + AppKeys registry, `decodeIfPresent` szabály, `@AppStorage`
  a Calculate view saját state-jéhez)
- Recovery infrastructure (per-item decode recovery mintája mindhárom modellben,
  `corruptedDump` akkumuláció, banner UI, DEBUG injection)
- Adding a new feature (gyakorlati checklist: modul-választás, persistence szabályok,
  concurrency, lokalizáció, tooltip/accessibility, Claude.md egyeztetési kötelezettség, docs)

**Munkamódszer:** szekvenciális írás (Desktop Commander:write_file, ~20-25 soros chunkokban,
rewrite majd append módban) — a `Filesystem:write_file` eszköz ebben a sessionben nem volt
betölthető (`tool_search` nem találta), Desktop Commander helyettesítette.

**Filesystem MCP állapot:** ebben a sessionben működött (`Filesystem:read_text_file`,
`read_multiple_files`, `directory_tree` mind sikeresek) — a korábbi `filesystem-mcp-debug.md`-ben
dokumentált silent-fail probléma legalább ideiglenesen/részlegesen megoldódott. Írásra viszont
csak Desktop Commander volt elérhető ebben a sessionben.

**Következő session:** `docs/buglist.md` ENH-DEVDOCS-1 → ✅ KÉSZ jelölése, git commit,
majd ENH-DEVDOCS-2 (README + install.md) vagy build ellenőrzés (CU + korábbi nyitott sessionök).

---

## Session CU — 2026-08-18 (ProjectCategory enum implementáció — KÉSZ)

### Session CU — KÉSZ
Előző session (#59 végeredmény: nyers "General" string storage-id) helyett profi megoldás:
`ProjectCategory` enum bevezetése, ami megkülönbözteti a rendszer-alapértelmezettet
a felhasználó által adotttól.

**Beszélt architektú ra (előző sessionből örökölt döntések):**
- Canonical storage key: `"default_general"` (`.general` case encode-ként)
- Lazy decode-time migration: `"General"` / `"general"` → `.general` automatikusan
- `.general` nem nevezhető át, nem törölhető (chevron elrejtve UI-ban)
- `init(userEnteredName:)` konvertál TextField inputból
- Új fájl: `Models/ProjectCategory.swift` (már elkészült előző sessionben)

**Végrehajtott módosítások:**
- [x] `Models/ProjectCategory.swift` — elkészült előző sessionben, teljes és korrekt
- [x] `Models/Snippet.swift` — `project: String` → `project: ProjectCategory`;
  custom `init(from:)` — `decode(ProjectCategory.self)`; memberwise init —
  `project: ProjectCategory = .general`; `committed()` — `ProjectCategory(userEnteredName:)`
  használata, raw `"General"` eltűnt; `isGeneralProject` törölve (enum pattern match
  váltja); `load()` whitespace cleanup — project trim eltávolítva (a Codable kezeli)
- [x] `Views/Snippets/SnippetsView.swift` — state-ek `ProjectCategory`-ra;
  `projectKeys: [ProjectCategory]`; `rows(for:)` — `ProjectCategory` param;
  `sectionHeader` — `.general`-nál chevron elrejtve, `.custom`-nál rename+delete menü;
  `renameProject` — `ProjectCategory(userEnteredName:)` használata;
  `deleteProject` — `.general` enum case (nem raw string)
- [x] `Views/Snippets/SnippetEditSheet.swift` — `existingProjects: [ProjectCategory]`;
  init: `snippet?.project.localizedName ?? ""`; `ProjectField` suggestions:
  `existingProjects.map { $0.localizedName }`

**Statikus kod-átnézés IGEN, build/futtatás NEM — FELHASZNÁLÓ FELADATA.**

**Következő session:** build+teszt; ha hiba: debug. Ha rendben: git commit,
majd teljes repó grep `"General"` literálokra (adat-réteg ellenőrzés).

---

## Session CQ folytatás — 2026-08-18 (újonnan azonosított fájlok audit-köre — LEZÁRVA)

### Session CQ folytatás — LEZÁRVA
Ez a kör a `countdownApp-handoff.md`-ben korábban azonosított, még nem auditált fájllistát
zárta le (App/, Components/, Models/, Services/ mappák egy része) — a fenti CQ-bejegyzésben
leírt ComponentStepper/SunPanel/CalculateView munkától FÜGGETLEN fájlokon.

**Munkamódszer:** 1 fájlon megyünk végig — elolvasás, xcstrings-ellenőrzés (grep/olvasás),
valódi kódhibák kigyűjtése, mentés, azonnali dokumentálás a `countdownApp-handoff.md`-ben.

- [x] `App/countdownAppApp.swift` — TISZTA (DEBUG-only menüpontok, nem igényelnek fordítást)
- [x] `App/HelpCommands.swift` — TISZTA (`help.menu.item` már helyesen kódolva és fordítva)
- [x] `Components/CopyButton.swift` — TISZTA (mindhárom hívóhely `String(localized:)`-tel ad át)
- [x] `Components/NativeTooltip.swift` — TISZTA (egyetlen hívóhely, helyesen kódolva)
- [x] `Components/SharedEditorComponents.swift` — TISZTA (nincs felhasználó felé mutató string)
- [x] `Components/HelpScreenshot.swift` — TISZTA (nincs felhasználó felé mutató string)
- [x] `Models/CountdownItem.swift` — TISZTA (tiszta adatmodell)
- [x] `Models/NamedDeadline.swift` — TISZTA (tiszta adatmodell)
- [x] `Models/Snippet.swift` — **VALÓDI KÓDHIBA TALÁLVA ÉS JAVÍTVA**: a `"General"` alapértelmezett
  projekttag literál volt, a `SnippetsView.sectionHeader` `Text(project.uppercased())`-je nyersen
  rajzolta volna ki, HU nyelven is angolul jelent volna meg. Első javítási kísérlet
  (`String(localized:)` íráskor) törte a "General mindig utoljára" rendezést HU nyelven — a
  felhasználó jelezte, újratervezés: `Snippet.project` mostantól a nyers `"General"` literált
  tárolja mint kanonikus, locale-független storage-id; új `Snippet.isGeneralProject(_:)` helper;
  `SnippetsView.projectKeys`/`sectionHeader` ezt használja, a fordítás csak megjelenítéskor
  történik. ÚJ xcstrings kulcs: `"General"` → `"Általános"` (korábban nem létezett, ellenőrizve).
  Build/futtatás nem történt, csak statikus kód-átnézés — a felhasználó nézze meg élesben.
- [x] `Services/Formatters.swift` — TISZTA (csak DateFormatter minta-stringek, nem UI szöveg)

**Az újonnan azonosított fájlok listája TELJES, nincs több hátralévő fájl ebben a körben.**

**Dokumentáció:** `countdownApp-handoff.md` #56-59 (a #56-58 egy köztes, később felülírt
próbálkozás volt, #59 a végleges megoldás), `docs/buglist.md` ENH-L10N-1 #4 pont frissítve.

**Következő session:** teljes `Localizable.xcstrings` + repó gyors ellenőrzése olyan literál
mintákra, amiket a #59-es hiba felfedett (adat-réteg literál, nem csak View-string — a `Models/`
mappa is rejthet ilyet), majd build+teszt (még mindig FELHASZNÁLÓ FELADATA).

---

## Session CQ — 2026-08-18 (ENH-L10N-1: új audit-kör indult — FOLYAMATBAN)

### Session CQ — FOLYAMATBAN
Felhasználói visszajelzés: annak ellenére, hogy `docs/buglist.md` az ENH-L10N-1-et
✅ KÉSZ-nek jelöli (Session CH lezárás), a felhasználó a kódban továbbra is bőven
lát lokalizálatlan stringeket (pl. stepper, accessibility labelek) — új, kézi
fájlonkénti audit-kör indult. A meglévő, kézzel átírt magyar fordítások NEM
módosulnak, csak az eddig hiányzó/lokalizálatlan stringek kerülnek pótlásra.

**Munkamódszer (felhasználó kérése):** egyszerre egy fájlon megyünk végig — átnézés,
fordítás egyeztetése, mentés, dokumentálás — session-határokon át folytatva.

- [x] `Components/ComponentStepper.swift` átnézve — **TISZTA**, nincs teendő.
  `label` és `unit` is `String(localized: String.LocalizationValue(...))`-on megy
  át, `accessibilityLabel` és `.help()` szövege is xcstrings-kulcsot használ
  (korábbi Session CH javítás, megerősítve élesben).
- [x] `Components/LongPressStepperButton.swift` átnézve — **TISZTA**, nincs saját
  hardcoded string; az `accessibilityLabel` paraméterként érkezik, a hívó fél
  (`ComponentStepper`) már lokalizálva adja át.
- [x] `Views/Calculate/SunPanel.swift` — **FONTOS KORREKCIÓ**: a `docs/buglist.md`
  audit ELAVULT volt. A teljes `Localizable.xcstrings` tényleges (nem
  másodkézből származó) átolvasása megmutatta, hogy a SunPanel összes
  sor-labelje (First light, Dawn, Sunrise, Sunset, Dusk, Last light, Solar noon,
  Day length, Moonrise, Moonset, Phase, Illumination, Morning/Evening
  golden/blue, Sun times, Sun times unavailable, LOADING, NO DATA) **MÁR megvan
  és le van fordítva** — ezekhez NEM nyúltunk. **TANULSÁG: `docs/buglist.md`-re
  nem szabad támaszkodni, mindig a tényleges fájlokat (Swift + xcstrings) kell
  ellenőrizni.**
- [x] `Views/Calculate/CalculateView.swift` teljes átnézve — valódi hiányok
  azonosítva:
  - **Hiányzó xcstrings kulcsok (megerősítve, a teljes xcstrings átnézése után
    sehol nem találhatók):** `"YEAR"`, `"MON"`, `"HOUR"`, `"MIN"` (stepper
    label-ek, nagybetűs) és `"year"`, `"month"`, `"day"`, `"hour"`, `"minute"`
    (accessibility unit nevek, kisbetűs — egyik sem létezik, még a "day" sem,
    holott a nagybetűs "DAY" már megvan). Nincs "WEEK" sehol a fájlban —
    valószínűleg félreemlékezés volt a felhasználó részéről.
  - **Megoldás forrása**: `help.calculate.stepper.body` xcstrings-érték már
    tartalmazza a szándékolt HU feliratokat: "ÉV, HÓNAP, NAP, ÓRA, PERC".
  - **Gyanús kódhiba (nem fordítás-hiány!):** két hely
    (`.accessibilityLabel("Sun times")` és `.accessibilityLabel("Show saved
    deadlines")`) string literált ad át az `.accessibilityLabel()`-nek, aminek
    NINCS `LocalizedStringKey` túlterhelése (csak `Text` vagy nyers
    `StringProtocol`) — valószínűleg sosem megy át lokalizáción, annak
    ellenére, hogy a kulcsok már léteznek és le vannak fordítva. Hasonló a
    korábban már javított `Text(String)` vs `Text(LocalizedStringKey)`
    hibához a ComponentStepper-ben.

**Következő session:** a fenti hiányzó kulcsok felvétele (fordítás
egyeztetés alatt a felhasználóval), a két accessibilityLabel kódhiba javítása,
majd `AddCountdownSheet.swift` + `CountdownDetailView.swift` átnézése (ugyanaz
a ComponentStepper mintát használják, valószínűleg ugyanezek a hiányok).

---

## Session CP — 2026-08-17 (ENH-L10N-1: xcstrings housekeeping — LEZÁRVA)

### Session CP — LEZÁRVA
Felhasználói kérés: `Localizable.xcstrings` 2 HU string javítása (birtokos rag hiányzott) +
üres kulcs törlése.
- [x] `"Open slot details"` HU értéke: `"Slot részletek megnyitása"` →
  `"Slot részleteinek megnyitása"`
- [x] `"Open deadline details — load or delete"` HU értéke:
  `"Határidő részletek megnyitása — betöltés vagy törlés."` →
  `"Határidő részleteinek megnyitása — betöltés vagy törlés."`
- [x] Üres `""` kulcs (funkciótlan, comment/localizations nélküli string catalog
  bejegyzés a fájl legelején, `"strings"` alatt közvetlenül) törölve
- [x] Mindhárom módosítás `Filesystem:edit_file`-lal, célzott cserével (nem teljes fájl felülírás)
- [ ] Build: FELHASZNÁLÓ FELADATA
- [ ] Git commit: FELHASZNÁLÓ FELADATA

**Megjegyzés:** ez a session egy korábbi, ugyanaznapi (2026-08-17) munkamenet folytatása,
amely a 20 VoiceOver/tooltip string HU fordítását és a `ContentView.swift`
`modeButton()` javítását végezte el — ez a `progress.md` nem tartalmazta ezt a
korábbi részt (session-határon veszett el a dokumentáció, mielőtt leírásra került
volna), DE a felhasználó megerősítette, hogy ez a kódban ténylegesen megvan.

**Következő session:** build ellenőrzés (CP + korábbi nyitott CN/CO változások együtt),
majd BUG-MANUAL-1, ENH-DEVDOCS-1/2, ENH-L10N-1 maradék (#2 hiányzó xcstrings kulcsok).

---

## Session CO — 2026-08-16 (calculate.toggle screenshotok kicsinyítése — LEZÁRVA)

### Session CO legutóbbi rész — LEZÁRVA
Felhasználói visszajelzés: a két új `calculate.toggle` screenshot (`calculated-days`,
`calculated-epochs`) túl nagynak tűnt a többi Help screenshothoz képest.
- [x] `HelpItem` új mező: `imageScale: CGFloat = 1.0` — szorzó a megosztott 560pt
  screenshot szélességre, item-szinten felülbirálható
- [x] `calculate.toggle` — `imageScale: 0.75` beállítva (a másik 2 meglévő
  screenshotos item, `countdown.notes` és `calculate.sunpanel`, változatlanul
  1.0-n marad)
- [x] `HelpView.swift` `HelpItemRow` — `HelpScreenshot(maxWidth: 560 * item.imageScale)`
- [ ] Build: FELHASZNÁLÓ FELADATA

**Következő session:** build ellenőrzés (CN + CO teljes változás-halmaz), majd
BUG-MANUAL-1, ENH-DEVDOCS-1/2, ENH-L10N-1 maradék.

---

## Session CO — 2026-08-16 (Tabfül gomb háttérszín javítás — LEZÁRVA)

### Session CO még későbbi rész — LEZÁRVA
Felhasználói visszajelzés: a kijelölt tabfül gomb (`Calculate`/`Countdown`/`Snippets`
váltó) háttere `AppTheme.dark` (szürkésbarna `#2A2015`) volt, ami "ronda" volt.
Utólag pontosítva: NEM az amber téma ellen ütközött — a mode switcher sor a
`Divider()` felett van, nincs ott `AppTheme.background` (amber) fill állítva
(azt csak az egyes mód-nézetek [`CountdownDetailView` stb.] állítják be a saját
tartalmi területükre), így ez a sor közvetlenül a natív macOS ablakháttéren ül
(sötét Dark Mode-ban) — ez ellen ütközött csúnyán a barna.
- [x] Egyeztetve: közel-fekete irányba menjen, mint a Calculate mód háttere
- [x] `ContentView.swift` `modeButton` — háttér `AppTheme.dark` →
  `AppTheme.calculateBackground` (`#060503`, ugyanaz a szín amit a Calculate
  fület már használja) — **csak ezen az egy gombon**, `AppTheme.dark` globálisan
  változatlan marad (43 másik hely használja más gombokon/sheeteken, azokat nem
  érintette a felhasználó visszajelzése)
- [x] Opacity: kezérileg 0.9-et kért a felhasználó, majd pontosította — NE
  hardcoded legyen, hanem a téma legnagyobb opacity tokenje. Használt token:
  `AppTheme.alpha90` (0.90, "Near-opaque elements — selected states and
  high-contrast labels"), a téma legmagasabb alpha értéke.
  `.fill(AppTheme.calculateBackground.opacity(AppTheme.alpha90))`
- [ ] Build: FELHASZNÁLÓ FELADATA

**Következő session:** build ellenőrzés (CN + CO teljes változás-halmaz), majd
BUG-MANUAL-1, ENH-DEVDOCS-1/2, ENH-L10N-1 maradék.

---

## Session CO — 2026-08-16 (ENH-HELP-2 utólagos javítás: hiányzó screenshotok + margin — LEZÁRVA)

### Session CO utólagos rész — LEZÁRVA
Felhasználói visszajelzés után (ENH-HELP-2 lezárása után, még ugyanebben a
sessionben):
- [x] **Hiányzó screenshotok popótolva**: a felhasználó korábban két képet tett be
  az Assetsbe (`calculated-days.imageset`, `calculated-epochs.imageset`,
  `countdownApp/resources/Assets.xcassets/` alatt, 460×197px), amelyek nem
  kerültek be a Help tartalomba — most bekötve a `calculate.toggle` itemhez
  (DAYS/CAL váltógomb, mindkét állapot képe)
- [x] **`HelpItem` modell bővítve**: `imageName: String?` (egyetlen kép) →
  `imageNames: [String]` (több kép egy item alatt). A hasznalaton kívüli
  `focusRect: CGRect?` mező eltávolítva (dead code volt, sehol nem használták
  a pre-cropped assets bevezetése óta)
  - `countdown.notes`: `imageNames: ["help-countdown-notes"]`
  - `calculate.sunpanel`: `imageNames: ["help-calculate-sunpanel"]`
  - `calculate.toggle`: `imageNames: ["calculated-days", "calculated-epochs"]` (új)
- [x] **`HelpScreenshot.swift`**: `pixelSizes` szótár kiegészítve a 2 új asset
  méretével (460×197)
- [x] **`HelpView.swift` `HelpItemRow`**: több screenshot egymás alatt (`VStack`,
  12pt spacing), és a bal margin `.padding(.leading, 28)`-ra javítva — eddig a
  screenshot a cím/ikon szintjéhez (0pt) igazodott, mostantól a body szöveg
  bal széléhez (28pt), ahogy a felhasználó kérte
- [x] **`AppTheme.swift`**: `helpWindowMinWidth` komment frissítve a +28pt
  leading padding említésével (a tényleges 640pt érték nem változott, még
  belefér 628pt tartalom szélesség mellett is)
- [ ] Build: FELHASZNÁLÓ FELADATA

**Következő session:** build ellenőrzés (CN + CO teljes változás-halmaz), majd
BUG-MANUAL-1, ENH-DEVDOCS-1/2, ENH-L10N-1 maradék.

---

## Session CO — 2026-08-16 (ENH-HELP-2: Help szekciók bővítése — LEZÁRVA)

### Session CO — LEZÁRVA
- [x] `docs/progress.md`, `docs/countdownApp-handoff.md` elolvasva
- [x] `Models/HelpContent.swift` elolvasva (25 item, 5 szekció áttekintve)
- [x] **Új feladat felvéve: ENH-HELP-2** — a felhasználó szerint a Help menü nem elég
  részletes; kérése: minden szekció bővebb szöveget kapjon (nem új item, hanem a
  meglévő body szövegek mélyítése)
- [x] **Overview szekció (5/5 item) kész** — `what`, `cooldowns`, `schedule`, `views`, `tooltips`
- [x] **Countdown szekció (8/8 item) kész** — `add`, `copy`, `edit`, `expand`, `free`,
  `notes`, `reorder`, `toggle`
- [x] **Calculate szekció (6/6 item) kész** — `deadlines`, `load`, `reset`, `stepper`,
  `sunpanel`, `toggle`
- [x] **Snippets szekció (4/4 item) kész** — csak `Localizable.xcstrings` EN+HU
  `body` értékek bővítve, `HelpContent.swift` nem változott:
  - `copy` — használati példa (átadási jegyzet gyors újrafelhasználása)
  - `edit` — kiegészítve: markdown szövegszerkesztő említése
  - `projects` — kiegészítve: célja (side projektek jegyzeteinek elkülönítése)
  - `what` — használati példa (session handoff jegyzet AI kódoláshoz)
- [x] **Recovery szekció (2/2 item) kész** — csak `Localizable.xcstrings` EN+HU
  `body` értékek bővítve:
  - `banner` — kiegészítve: ritka szegleteset, csak sérült tároláskor
  - `storage` — kiegészítve: nincs eszközök közötti átvitel, nincs automatikus mentés
- [x] **ENH-HELP-2 TELJES EGÉSZÉBEN KÉSZ** — mind az 5 szekció, 25/25 item bővítve
- [ ] Build: FELHASZNÁLÓ FELADATA

**Következő session:** ENH-HELP-2 lezárva, nincs folytatás ezen a témán. Build
ellenőrzés (CN + CO változások együtt), majd BUG-MANUAL-1, ENH-DEVDOCS-1/2,
ENH-L10N-1 maradék.

---

## Session CN — 2026-08-16 (Help: projekt törlés + tooltipek — LEZÁRVA)

### Session CN — LEZÁRVA
- [x] `docs/progress.md`, `docs/countdownApp-handoff.md` elolvasva
- [x] `Models/HelpContent.swift`, `Localizable.xcstrings` elolvasva (teljes Help tartalom áttekintve)
- [x] **Érintett fájlok**: `Models/HelpContent.swift`, `Localizable.xcstrings`
- [x] **`HelpContent.swift`**: 2 új `HelpItem` hozzáadva:
  - `snippets.projects` (`folder` ikon) — projekt törlés → General viselkedés
  - `overview.tooltips` (`cursorarrow` ikon) — hover tooltip-ek ismertetése
- [x] **`Localizable.xcstrings`**: 4 új kulcs beillesztve EN+HU-val:
  - `"help.snippets.projects.body"` / `"help.snippets.projects.title"`
  - `"help.overview.tooltips.body"` / `"help.overview.tooltips.title"`
- [ ] Build: **FELHASZNÁLÓ FELADATA**

**Snippets.projects tartalom (EN):** "Snippets are grouped by project. Tap the chevron next to a project name to rename or delete the group. Deleting a project does not remove any snippets — they are moved to General automatically."

**Overview.tooltips tartalom (EN):** "Hover the mouse over any button to see a short description of what it does. Most interactive elements throughout the app have a tooltip."

**Megjegyzés:** A manual frissítése (BUG-MANUAL-1) a felhasználó feladata (projekt törlés + tooltipek ott is dokumentálandók).

**Következő session:** build ellenőrzés, BUG-MANUAL-1 (ha a felhasználó átadja), ENH-DEVDOCS-1/2, vagy ENH-L10N-1 maradék.

---

## Session CM — 2026-08-16 (Countdown tooltip javítás — LEZÁRVA)

### Session CM — LEZÁRVA
- [x] `Claude.md`, `docs/progress.md`, `docs/countdownApp-handoff.md` elolvasva
- [x] **Érintett fájlok**: `CountdownRowView.swift`, `CountdownView.swift`, `Localizable.xcstrings`
- [x] **`CountdownRowView.swift`**: label pill HStack-re `.help(String(localized: "Copy text"))` hozzáadva (`.simultaneousGesture` után)
- [x] **`CountdownView.swift`**: mindkét NavigationLink-re (free + active ág) `.help(String(localized: "Open slot details"))` hozzáadva (`.focusEffectDisabled()` után)
- [x] **`Localizable.xcstrings`**: 2 új kulcs EN+HU-val:
  - `"Copy text"` → `"Szöveg másolása"`
  - `"Open slot details"` → `"Slot részletek megnyitása"`
- [x] Git commit `e73d7ec`: `CM: tooltip .help() for countdown row NavigationLink and label pill`
- [x] Git commit `81cd2a3`: `CM2: fix moon button tooltip — .help() after .popover() so hover is not swallowed`
- [x] Git commit `811fe05`: `CM3: moon tooltip — .help() on wrapper VStack outside popover; remove pill and clock/cal .help()`
- [x] Git commit `7d067b9`: `CM4: remove trivial .help() from reset and save buttons in CalculateView`
  - `nowButton` helper: `helpText` paraméter eltávolítva, `.help()` törölve
  - SAVE gomb: `.help()` törölve
- [x] Git commit `d094b79`: `CM5: NativeTooltip — AppKit NSView.toolTip for moon button, bypasses .help() tracking area issue`
  - `Components/NativeTooltip.swift` új fájl: `NSViewRepresentable` alapú `.nativeTooltip()` View extension; transzparens `NSView` overlay-ként regisztrálja az `NSView.toolTip`-et AppKit-en direkt
  - `CalculateView.swift`: moon VStack wrapper `.help()` → `.nativeTooltip()` cserélve
- [x] Git commit `941731e`: `CM6: nativeTooltip padding param — expand tracking area around moon button`
  - `NativeTooltip.swift`: `padding: CGFloat = 0` paraméter hozzáadva — negatív padding-gel az NSView overlay nagyobb mint a layout frame, így a tracking area kiterjed a hold körüli területre is
  - `CalculateView.swift`: `.nativeTooltip(..., padding: 16)` — **MŰKÖDIK**
  - `CalculateView.swift`: moon gomb Button-t `VStack(spacing:0)`-ba csomagolva; `.help()` és `.offset()` a VStack-ra kerültek, `.popover()` a Button-on maradt — a popover tracking area így nem nyeli el a hover eventeket
  - `CountdownRowView.swift`: pill `.help("Copy text")` és clock/cal gomb `.help()` eltávolítva — a NavigationLink `.help("Open slot details")`-je mindkettőn felülírt volna
- [ ] Build: **FELHASZNÁLÓ FELADATA**

**Megjegyzés:** Eye badge (`eye.fill` Image) szándékosan kimaradt — nem interaktív elem, `.help()` nem regisztrál AppKit NSToolTip-et sima Image-en.

**Következő session:** egyeztetés alapján — BUG-MANUAL-1, ENH-DEVDOCS-1/2, ENH-L10N-1, vagy Calculate tooltip javítások (LongPressStepperButton hold, SavedDeadlines row).

---

## Session CL — 2026-08-16 (focusable(false) → focusEffectDisabled() audit — LEZÁRVA)

### Session CL — LEZÁRVA
- [x] `docs/progress.md`, `docs/countdownApp-handoff.md`, `docs/buglist.md` elolvasva
- [x] **Teljes audit**: minden Swift fájl átnézve `.focusable(false)` előfordulásokra
- [x] **Döntés**: Button-ökön `.focusable(false)` → `.focusEffectDisabled()` (macOS 14+, target macOS 26.5)
  - `.focusEffectDisabled()`: benne hagyja az elemet a Tab sorrendben, eltávolítja a focus gyűrűt, NEM zavarja az NSToolTip regisztrációt
  - `.focusable(false)`: kiveszi az elemet az AppKit focus chain-ből → sporadikus tooltip elmaradás lehetséges
  - **Kivétel (szándékos `.focusable(false)` marad):**
    - `LongPressStepperButton` Image-en: nem Button, DragGesture-s Image, kizárás az AppKit focus chain-ből szándékos
    - `SnippetEditSheet` sheet container `.focusable(false)`: Session K-s workaround — AppKit first-responder elkerülés Title TextField-en
    - `AboutView` gyökerén `.focusable(false)`: About ablak-szintű, szándékos
    - `AddCountdownSheet` LABEL VStack `.focusable(false)`: TextField-et tartalmazó VStack, AppKit workaround, marad
- [x] **6 fájl módosítva** (Filesystem:edit_file, sebészeti cserék):
  - `Views/Countdown/NotesSheet.swift` — `headerButton` helper + üres állapot Button: 2 csere
  - `Views/Countdown/ColorPickerSheet.swift` — X gomb + swatch buttonok: 2 csere; X gomb `.help("Close")` → `.help(String(localized: "Close this color picker"))` javítva
  - `Views/Snippets/SnippetsView.swift` — `sectionHeader` Menu: 1 csere
  - `Views/ContentView.swift` — `modeButton`: 1 csere
  - `Views/Countdown/AddCountdownSheet.swift` — Cancel + Add gombok: 2 csere
  - `Views/AboutView.swift` — `infoRow` Button: 1 csere
- [x] Git commit `87afdbb`: `CL: focusable(false) → focusEffectDisabled() on all Button targets`
- [ ] Build: **FELHASZNÁLÓ FELADATA**

**Megjegyzés:** `CalculateView.swift` és `DeadlineDetailSheet.swift` már az előző session (CK előtt) teljesen rendbe volt hozva — az ottani Button-ök már `.focusEffectDisabled()` voltak. `CountdownDetailView.swift`, `CountdownView.swift`, `SnippetEditSheet.swift` (headerButton helper) is már kész volt.

**Következő session:** egyeztetés alapján — lehetséges témák: BUG-SNIPPEDITBEACHBALL-1 megerősítése, ENH-DEVDOCS-1/2, BUG-MANUAL-1.


---

## Session CK — 2026-08-15 (ENH-TOOLTIP-1 lezárva — LEZÁRVA)

### Session CK — LEZÁRVA
- [x] `docs/progress.md`, `docs/countdownApp-handoff.md`, `docs/buglist.md` elolvasva
- [x] **Teljes audit**: minden érintett Swift fájl átnézve — a `.help()` modifier szinte mindenhol
  már megvolt korábbi sessionokból (CH és előzők). Valódi hiányok:
  - `ContentView.swift` `modeButton` — nem volt `.help()`
  - `SnippetsView.swift` `snippetRow` edit button — nem volt `.help()`
- [x] **`Localizable.xcstrings`** — 3 új kulcs beillesztve EN+HU-val:
  - `"Switch to Calculate"` → `"Váltás a Kalkulációra"`
  - `"Switch to Countdown"` → `"Váltás az Időzítőre"`
  - `"Switch to Snippets"` → `"Váltás a Gyorsszövegekre"`
- [x] **`Views/ContentView.swift`** — `modeButton`-ra `.help(String(localized: String.LocalizationValue("Switch to \(mode.rawValue)")))` hozzáadva; az interpolált string exact match az xcstrings kulcsokra
- [x] **`Views/Snippets/SnippetsView.swift`** — `snippetRow` edit button-ra `.help(String(localized: "Open this snippet to view or edit its content"))` hozzáadva
- [x] Git commit `05c1460`: `ENH-TOOLTIP-1: modeButton .help() + snippetRow edit .help() + 3 xcstrings keys`
- [x] `docs/progress.md`, `docs/countdownApp-handoff.md`, `docs/buglist.md` frissítve
- [ ] Build: **FELHASZNÁLÓ FELADATA**

**Következő session:** egyeztetés alapján (BUG-SNIPPEDITBEACHBALL-1 megerősítése, ENH-DEVDOCS-1/2, BUG-MANUAL-1).
