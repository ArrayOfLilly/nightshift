## Session CG — 2026-08-15 (BUG-KNOWNREGIONS-1 + tabnév-átírás — LEZÁRVA)

### Session CG — LEZÁRVA
- [x] Felhasználói pontosítás: a Session CF-es `AppleLanguages`-elmélet téves nyomon volt —
  a probléma nem "elveszett szinkronizáció", hanem hogy **soha, sehol** nem jelent meg
  magyar szöveg, még az első sikeres futtatásnál sem
- [x] **Root cause megtalálva**: `countdownApp.xcodeproj/project.pbxproj` — a projekt
  `knownRegions` listája csak `en` és `Base`-t tartalmazta, a `hu` nem volt regisztrálva
  támogatott régióként. Emiatt függetlenül attól, hogy az `AppleLanguages` mit tartalmaz
  vagy a Localizable.xcstrings-ben milyen HU fordítások vannak, a rendszer soha nem is
  próbálta meg a magyar lokalizációt használni, mert az app szintjén nem volt bejelentve,
  hogy támogatja — ez az igazi (és elsődleges) oka annak, hogy a fordítások soha nem
  jelentek meg, nem a Session CF-ben azonosított `AppleLanguages`-újraírási hiányosság
  (az utóbbi valódi bug marad, csak nem ez volt a fő gyökérok)
- [x] **`countdownApp.xcodeproj/project.pbxproj`** — `knownRegions` listához `hu` hozzáadva
  (`en`, `hu`, `Base`)
- [x] **Tabnév-átírás** (felhasználói visszajelzés: a jelenlegi fordítások mesterségesek,
  senki nem mondaná így magyarul) — `Localizable.xcstrings`, HU értékek frissítve:
  - `Calculate` → `Kalkuláció`, `CALCULATE` → `KALKULÁCIÓ`
  - `Countdown` → `Időzítő`
  - `Snippets` → `Gyorsszövegek`, `SNIPPETS` → `GYORSSZÖVEGEK`
  (a `help.section.*` és `ACCOUNT COOLDOWN` kulcsok érintetlenek maradtak, más szöveg-
  környezethez tartoznak)
- [ ] **Xcode: Product > Clean Build Folder (Cmd+Shift+K)** ajánlott a `knownRegions`
  változás után, majd teljes újraépítés + teljes quit/relaunch: **FELHASZNÁLÓ FELADATA**
- [ ] Git commit: **FELHASZNÁLÓ FELADATA**

**Következő session:** ha a `knownRegions` fix után is hiányzik a HU szöveg, további
 vizsgálandó: Xcode Scheme > Run > Options > App Language beállítás (nem "System
 Language"-re állítva?), illetve DerivedData teljes törlése. Ezután ENH-L10N-1
 folytatása (#6, #5).

---

## Session CF — 2026-08-15 (BUG-APPLELANG-1: AppleLanguages elveszett szinkronizáció javítva — LEZÁRVA)

### Session CF — LEZÁRVA
- [x] Felhasználói jelzés: xcstrings JSON-javítás + Xcode build után a teljes UI angolra
  esett vissza, holott a Nyelv beállításban továbbra is "Magyar" volt kiválasztva
- [x] **Root cause**: `SettingsView.swift` `applyLanguageOverride(_:)` csak a Picker
  `.onChange`-én belül írta ki a rendszerszintű `AppleLanguages` UserDefaults kulcsot —
  induláskor soha nem szinkronizálódott újra a már elmentett `AppKeys.preferredLanguage`
  érték alapján. Ha az `AppleLanguages` bármi miatt elveszett (pl. friss app-container
  egy új Xcode build után), a Picker továbbra is helyesen "Magyar"-t mutatott (mert a
  saját `preferredLanguage` kulcs megőrződött), de a tényleges UI néma csöndben angolra
  esett vissza — és így is maradt, amíg valaki ténylegesen át nem váltotta a Pickert
  (mert csak egy valódi value-change váltja ki az újraírást)
- [x] **`App/AppKeys.swift`** — új megosztott `static func syncAppleLanguagesOverride()`
  hozzáadva: a perziszált `preferredLanguage` alapján írja (vagy törli) az
  `AppleLanguages` kulcsot
- [x] **`App/countdownAppApp.swift`** — `init()`-ben `AppKeys.syncAppleLanguagesOverride()`
  hívás bekerült a font-regisztráció elé, hogy minden induláskor öngyógyító módon
  újra szinkronizálódjon (a jelenlegi futtatás még nem látja azonnal a hatást — az
  `AppleLanguages` változás csak következő induláskor érvényesül, ahogy azt a
  Settings-beli figyelmeztetés is jelzi —, de attól kezdve tartósan helyes marad,
  még ha az `AppleLanguages` külső ok miatt újra elvész is)
- [x] **`Views/Settings/SettingsView.swift`** — duplikált `applyLanguageOverride(_:)`
  függvény eltávolítva, a Picker `.onChange` mostantól a megosztott
  `AppKeys.syncAppleLanguagesOverride()`-ot hívja
- [ ] Build + teszt (teljes quit + újraindítás, mert az `AppleLanguages` változás csak
  akkor lép életbe): **FELHASZNÁLÓ FELADATA**
- [ ] Git commit: **FELHASZNÁLÓ FELADATA**

**Következő session:** ENH-L10N-1 folytatása (#6, #5) vagy egyeztetés alapján más
 prioritás.

---

## Session CE — 2026-08-15 (ENH-L10N-1 #3: kód-szintű lokalizáció — LEZÁRVA)

### Session CE — LEZÁRVA
- [x] `docs/progress.md`, `docs/countdownApp-handoff.md` elolvasva
- [x] **`Views/ContentView.swift`** — `modeButton`-ban `Text(mode.rawValue)` →
  `Text(LocalizedStringKey(mode.rawValue))`
- [x] **`Views/Countdown/CountdownDetailView.swift`**:
  - label-fallback → új `countdown.label.placeholder` xcstrings kulcs használva
    (EN: `Countdown`, HU: `Megnevezés`) — a meglévő `"Countdown"` kulcs (`Visszaszámlálás`)
    változatlanul a tab/screen cím számára marad foglalva
  - `"EXPIRED"` → `String(localized: "EXPIRED")`
  - `CopyButton` `"Copy label"`/`"Label copied"` → `String(localized:)`
- [x] **`Views/Countdown/CountdownRowView.swift`** — `"COPIED"` → `String(localized: "COPIED")`
- [x] **`Views/Calculate/CalculateView.swift`**:
  - `"RESET FROM NOW"` / `"RESET TO NOW"` (nowButton label param) → `String(localized:)`
  - `resultLabel` (`"Remaining time:"` / `"Elapsed time:"`) → `String(localized:)`
  - `"< 1M"` → `String(localized: "< 1M")`
  - `"Name..."` TextField placeholder → `String(localized: "Name...")`
  - `"SAVE DEADLINE"` / `"SAVED DEADLINES"` — **változtatás nélkül marad**: már `Text()`
    string-literalként szerepeltek, ami automatikusan az xcstrings-ből lokalizál
    (`LocalizedStringKey` init) — nem követett explicit `String(localized:)` hívást igényelt
- [x] **`Components/ComponentStepper.swift`** — `accessibilityLabel: "Increase \(unit)"` /
  `"Decrease \(unit)"` → `String(localized: "Increase \(localizedUnit)")` mintára;
  új privát `localizedUnit` computed var lokalizálja a `unit` paramétert
  (`String.LocalizationValue(unit)` — xcstrings-ben már léteznek a `year`/`month`/`day`/
  `hour`/`minute` kulcsok) mielőtt interpolálja
- [x] **`Views/Countdown/NotesSheet.swift`** — 5 accessibility string (`"Copy notes"`,
  `"Notes copied"`, `"Done editing"`, `"Edit notes"`, `"Delete notes"`) → `String(localized:)`
  (a `"Close"` label érintetlen marad, nem volt a kérés része)
- [x] **`Views/AboutView.swift`** — `infoRow` függvény `label` paramétere `String` →
  `LocalizedStringKey`; `Text(label.uppercased())` → `Text(label).textCase(.uppercase)`
  (a `.uppercased()` string-metódus nem alkalmazható `LocalizedStringKey`-re, ezért
  SwiftUI naiv `.textCase(.uppercase)` modifier váltotta ki) — a hívási oldalon
  (`"Developer"`, `"Images"`) nem kellett változtatni, a string literal automatikusan a
  megfelelő (LocalizedStringKey) overloadra illik
- [x] **`Views/Snippets/SnippetsView.swift`** — `Text(snippet.title.isEmpty ? "Untitled" : ...)` →
  `Text(snippet.title.isEmpty ? String(localized: "Untitled") : snippet.title)`
- [x] **`Localizable.xcstrings`** — új `countdown.label.placeholder` kulcs beillesztve
  (EN: `Countdown`, HU: `Megnevezés`), a meglévő `"Countdown"` kulcs után
- [ ] Build + JSON validáció: **FELHASZNÁLÓ FELADATA**
- [ ] Git commit: **FELHASZNÁLÓ FELADATA**

**Következő session:** ENH-L10N-1 folytatása — #6 (`CalculateView.swift` +
`SnippetEditSheet.swift` maradék audit) és #5 (`SunTimesService.swift` nyitott kérdés),
vagy egyeztetés alapján más prioritás (ENH-DEVDOCS-2, BUG-MANUAL-1).

---

## Session CD — 2026-08-15 (ENH-L10N-1 #2: xcstrings kulcsok + HU fordítások — LEZÁRVA)

### Session CD — LEZÁRVA
- [x] `docs/progress.md`, `docs/countdownApp-handoff.md`, `docs/buglist.md` elolvasva
- [x] **`Views/Snippets/SnippetsView.swift`** — `deleteProjectMessage` szövegjavítás:
  - régi: `"This will permanently delete all \(count) snippet\(count == 1 ? "" : "s") in \"\(projectToDelete)\"."`
  - új: `String(format: String(localized: "All snippets in \"%@\" will be moved to General."), projectToDelete)`
  - ok: a `deleteProject()` függvény `updated.project = "General"` mozgat, NEM töröl — a régi szöveg félrevezető volt
- [x] **`Localizable.xcstrings`** — 12 meglévő Settings kulcshoz HU fordítás hozzáadva:
  `Adjusts text size throughout the app. Takes effect immediately.` → `Beállítja az app szövegméretét. Azonnal érvényes.`
  `Appearance` → `Megjelenés`
  `Default` → `Alapértelmezett`
  `Font Size` → `Betűméret`
  `Interface Language` → `Felületi nyelv`
  `Language` → `Nyelv`
  `Large` → `Nagy`
  `Larger` → `Nagyobb`
  `Largest` → `Legnagyobb`
  `Restart NightShift to apply language changes.` → `A nyelvi módosítások alkalmazásához indítsd újra a NightShiftet.`
  `System Default` → `Rendszer alapértelmezett`
  `Date & Number Format` → `Dátum- és számformátum`
- [x] **`Localizable.xcstrings`** — `Name...` HU frissítve: `Név...` → `Megnevezés...`
- [x] **`Localizable.xcstrings`** — 28 teljesen új kulcs beillesztve EN+HU-val:
  `< 1M` (EN+HU: `< 1MIN`), `All snippets in "%@" will be moved to General.` (HU: `A(z) „%1$@" összes snippetje az Általánosba kerül.`),
  `COPIED`→`MÁSOLVA`, `Copy label`→`Felirat másolása`, `Copy notes`→`Másolás`,
  `DAY`→`NAP`, `day`→`nap`, `Delete notes`→`Törlés`, `Developer`→`Fejlesztő`,
  `Done editing`→`Kész`, `Edit notes`→`Szerkesztés`, `Elapsed time:`→`Eltelt idő:`,
  `EXPIRED`→`LEJÁRT`, `HOUR`→`ÓRA`, `hour`→`óra`, `Images`→`Képek`,
  `Label copied`→`Felirat másolva`, `MIN`→`MIN`, `minute`→`perc`,
  `MON`→`HÓ`, `month`→`hónap`, `Notes copied`→`Másolva`,
  `Remaining time:`→`Hátralévő idő:`, `RESET FROM NOW`→`MOSTANTÓL`,
  `RESET TO NOW`→`MOSTANÁIG`, `Untitled`→`Névtelen`,
  `YEAR`→`ÉV`, `year`→`év`
- [ ] `Countdown` label-fallback kulcs (CountdownDetailView): HU döntés `Megnevezés` — de a meglévő
  `"Countdown"` kulcs (`Visszaszámlálás`) már foglalt a tab/screen cím számára. Megoldás: új kulcs
  kell (pl. `"Countdown label placeholder"`), de ez csak a #3 kód-szintű változtatással együtt értelmes
  — **KÖVETKEZŐ SESSION feladata** (CalculateView + CountdownDetailView kód-szintű lokalizáció)
- [ ] Build + JSON validáció: **FELHASZNÁLÓ FELADATA** (Xcode megnyitásakor automatikusan rendezi a kulcsokat)
- [ ] Git commit: **FELHASZNÁLÓ FELADATA**

**Következő session:** ENH-L10N-1 #3 — kód-szintű javítások:
- `ContentView.swift`: `Text(mode.rawValue)` → `Text(LocalizedStringKey(mode.rawValue))`
- `CountdownDetailView.swift`: `"Countdown"` label fallback → új kulcs + HU `Megnevezés`
- `CountdownRowView.swift`: `"COPIED"` hardcoded → `String(localized: "COPIED")`
- `CountdownDetailView.swift`: `"EXPIRED"` hardcoded → `String(localized: "EXPIRED")`
- `CalculateView.swift`: 7 hardcoded string (`RESET FROM NOW`/`TO`, `Remaining time:`, `Elapsed time:`, `SAVE DEADLINE`, `SAVED DEADLINES`, `< 1M`, `Name...`) → `String(localized:)` / `LocalizedStringKey`
- `ComponentStepper.swift`: `accessibilityLabel: "Increase \(unit)"` → `String(localized:)` format
- `NotesSheet.swift`: 5 accessibility string → `String(localized:)`
- `AboutView.swift`: `"Developer"` / `"Images"` infoRow label-ek → `LocalizedStringKey`
- `SnippetsView.swift`: `"Untitled"` → `String(localized: "Untitled")`

---

## Session CC — 2026-08-15 (ENH-SETTINGS-2 dinamikus átméretezés folytatása — LEZÁRVA)

### Session CC — LEZÁRVA
- [x] `docs/progress.md`, `docs/countdownApp-handoff.md` elolvasva — Session BU-ban megkezdett, de
  session-limit miatt félbeszakadt „dinamikus átméretezés" javítás folytatása
- [x] Root cause megerősítve: `ContentView.swift`-ben már megvolt a `@AppStorage(AppKeys.fontSizeStep)`
  fix (a Session BU utáni, dokumentálatlan munkából), de ez önmagában nem terjedt át a gyerek
  view-okra — sem `CalculateView`, sem `CountdownView`, sem `SnippetsView` nem figyelte a
  `fontSizeStep`-et, ezért a bennük lévő `AppTheme.alienLeague()`/`alienLeagueBold()` hívások nem
  reagáltak élőben a Settings-beli betűméret-váltásra (csak fülváltás/sheet-újranyitás után)
- [x] `Views/Calculate/CalculateView.swift` — `@AppStorage(AppKeys.fontSizeStep) private var
  fontSizeStep: Int = 0` hozzáadva (nem használt közvetlenül, csak a subscription miatt kell)
- [x] `Views/Countdown/CountdownView.swift` — ugyanaz a minta hozzáadva
- [x] `Views/Snippets/SnippetsView.swift` — ugyanaz a minta hozzáadva (bár korábbi megfigyelés
  szerint ez a fül már működött; a fix itt a konzisztencia/megbízhatóság miatt került be, nem
  hibajavításként)
- [x] `App/countdownAppApp.swift` ellenőrizve — a `.dynamicTypeSize(fontSizeStep.asDynamicTypeSize)`
  sor változatlan marad, a fejléckomment helyesen dokumentálja, hogy ez csak a semantic fontokra hat

**Utólagos kiegészítés (ugyanebben a session-ben, felhasználói visszajelzés után):** Largest
(step 3) betűméretnél a módváltó fülek címei (Calculate/Countdown/Snippets) nem fértek ki az
ablakban — az ablak szélessége (`AppTheme.windowMinWidth`/`windowMaxWidth`) fix érték volt,
nem követte a betűméretet.
- [x] `Views/ContentView.swift` — dinamikus ablakszélesség-mérés bevezetve: `ModeSwitcherWidthKey`
  (`PreferenceKey`) + `GeometryReader` a módváltó HStack `.background`-jében méri a sor valós,
  természetes szélességét (`.fixedSize(horizontal: true, vertical: false)` garantálja, hogy ne
  nyírja le a mérést, ha a jelenlegi ablak még szűkebb, mint amennyit a tartalom igényelne);
  `@State private var modeSwitcherWidth` tárolja; a gyökér `.frame(minWidth:maxWidth:)` mostantól
  `max(AppTheme.windowMinWidth, modeSwitcherWidth)` / `max(AppTheme.windowMaxWidth,
  modeSwitcherWidth + 40)` — a +40pt ráadja azt, hogy az ablak Largest-nél is szabadon tovább
  legyen húzható, ne zárja le pontosan a mért szélességre (min == max eset elkerülése)
- [x] **Szándékosan NEM hardcoded pixel-táblát** (pl. `fontScaleFactors` mintájára egy
  `[0, 20, 45, 80]` jellegű lépésenkénti konstans) választottam, hanem élő mérést — ez akár a
  jelenlegi angol címkékre, akár a későbbi HU lokalizációra (ENH-L10N-1 #9, ahol a magyar
  címkék hossza más lesz) automatikusan helyes marad, nem kell kézzel újrahangolni
- [x] Build + vizuális ellenőrzés: OK
- [x] Git commit: `e6185ed` (Session BU + CB + CC + CA együtt)

**Technikai megjegyzés (font subscription):** a `ContentView`-ban lévő `switch selectedMode {
case .calculate: CalculateView() ... }` konstrukcióban a paraméter nélküli gyerek view-ok
(nincs külső stored property, minden state `@State`/`@AppStorage` boxban van) nem feltétlenül
rendelődnek újra pusztán attól, hogy a szülő body-ja lefut — saját observation nélkül a gyerek
view "változatlannak" tűnhet a SwiftUI diffing számára. Ezért minden olyan view-nak, ami
`AppTheme.alienLeague()`-t közvetlenül a saját body-jában használja és nem sheet/popover-ként
frissen példányosítva jelenik meg minden megnyitáskor, szüksége van a saját
`@AppStorage(fontSizeStep)` subscription-jére.

**Következő session:** ENH-L10N-1 folytatása (#2 hiányzó xcstrings kulcsok) — vagy egyeztetés
alapján más prioritás. A 14 HU fordítás (Session CA) és az ENH-SETTINGS-1+2 továbbra sincs
commitolva — ellenőrizni a felhasználónál session elején.

---

## Session CB — 2026-08-15 (ENH-SETTINGS-1: Settings menü implementálva — LEZÁRVA)

### Session CB — LEZÁRVA
- [x] `docs/progress.md`, `docs/countdownApp-handoff.md`, `docs/buglist.md` elolvasva
- [x] iconKeeper `IconKeeperApp.swift` + `Views/SettingsView.swift` elolvasva (natív Settings scene
  + Language/Locale picker minta)
- [x] `countdownAppApp.swift`, `Services/Formatters.swift`, `App/AppKeys.swift` elolvasva
- [x] **`App/AppKeys.swift`** módosítva — 2 új kulcs a Settings szekcióban:
  - `preferredLanguage = "nightshift.preferredLanguage"` (BCP-47 tag, "" = rendszer default)
  - `preferredLocale   = "nightshift.preferredLocale"` (locale identifier, "" = rendszer default)
- [x] **`Services/Formatters.swift`** módosítva:
  - fejléc localization note frissítve (ENH-SETTINGS-1 implementálva)
  - `effectiveLocale: Locale` private static var hozzáadva — UserDefaults-ból olvassa
    az `AppKeys.preferredLocale`-t, fallback: `Locale.current`
  - `monthAbbrev`, `deadline`, `deadlineCompact` → `f.locale = effectiveLocale`
    (korábban: `en_US`/rendszer locale/`en_US`)
  - `time` formatter → változatlan (POSIX, 24h-os)
- [x] **`Views/Settings/` mappa** létrehozva (Filesystem MCP `create_directory`)
- [x] **`Views/Settings/SettingsView.swift`** létrehozva — 2 section (kártyás layout,
  iconKeeper stílusban):
  - Interface Language: Picker (System Default / English / Magyar); `@AppStorage(preferredLanguage)`;
    `onChange` → `applyLanguageOverride()` → `UserDefaults.set(["en"/"hu"], "AppleLanguages")`
    vagy `removeObject` ha system default
  - Date & Number Format: Picker (System Default / English (US) / Magyar (HU));
    `@AppStorage(preferredLocale)` — értéket tárolja, Formatters olvassa restart után
  - Restart advisory: megjelenik ha bármelyik beállítás nem default
  - `supportedLanguages`: `Locale.localizedString(forLanguageCode:)` alapján dinamikus
  - `supportedLocales`: statikus lista (`en_US`, `hu_HU`)
- [x] **`App/countdownAppApp.swift`** módosítva — `Settings { SettingsView() }` scene
  hozzáadva `.defaultSize(width: 480, height: 360)` után a többi scene előtt
- [ ] Xcode: `Views/Settings/SettingsView.swift` hozzáadása a targethez (synchronized group
  esetén automatikus, de ellenőrizni kell)
- [x] Build + vizuális ellenőrzés: OK
- [x] Git commit: `e6185ed` (Session BU + CB + CC + CA együtt)

**Technikai megjegyzések:**
- A natív `Settings { }` scene automatikusan adja az App menu → Preferences (Cmd+,) menüpontot —
  nincs szükség custom `SettingsWindowID`/`SettingsCommands` struktúrákra
- Language change azonnal bekerül a `UserDefaults["AppleLanguages"]`-ba, de csak restart után
  hat az xcstrings-re (macOS az app launch-kor olvassa)
- Locale change csak restart után hat, mert a `Formatters` static let-jei egyszer init-elődnek
  az első hozzáféréskor; a `effectiveLocale` var ezért kerül meghívásra az init-ben, nem
  futásidőben
- Az `ENH-L10N-1` szerinti 14 HU fordítás (Localizable.xcstrings, Session CA) és az
  `ENH-SETTINGS-1` egymástól függetlenül tesztelhetők — a language picker már most is vált,
  a fordítások pedig ott vannak az xcstrings-ben (build+teszt felhasználó feladata maradt)

**Következő session:** ENH-L10N-1 folytatása (#2 hiányzó xcstrings kulcsok) vagy ENH-DEVDOCS-2
— egyeztetés alapján. BUG-MANUAL-1 mindig utolsó.

---

# countdownApp — Progress

## Session CA — 2026-08-15 (ENH-L10N-1 #1: 14 HU fordítás pótolva xcstrings-ben — LEZÁRVA)

### Session CA — LEZÁRVA
- [x] `docs/progress.md`, `docs/countdownApp-handoff.md`, `docs/buglist.md` elolvasva
- [x] **`Localizable.xcstrings`** módosítva — mind a 14, buglist.md #1 alatt listázott HU-gap
kulcs kapott fordítást: Snippets, SNIPPETS, Sun times unavailable, Switch to date display,
Switch to remaining time, Tap + to add a snippet., Tap to start writing., This cannot be undone.,
This clears the notes for this slot. This cannot be undone., This deadline will be permanently
removed., Title, Unsaved changes, Version %@ (%@), You have unsaved changes. What would you like to do?
- [x] Python szkripttel ellenőrizve: JSON valid, mind a 14 kulcsnak van HU bejegyzése
- [x] Build + Xcode-os ellenőrzés: OK
- [x] Git commit: `e6185ed` (Session BU + CB + CC + CA együtt)
- [x] `docs/buglist.md` ENH-L10N-1 #1 pontja lezárva
- [x] `docs/progress.md` frissítve

**HANDOFF**: következő session témája **ENH-SETTINGS-1** (nem ENH-L10N-1 folytatása).
**A 14 HU fordítás még nincs commitolva.**

---

## Session BZ — 2026-08-15 (ENH-L10N-1 audit befejezve — LEZÁRVA)

### Session BZ — LEZÁRVA
- [x] `docs/progress.md`, `docs/countdownApp-handoff.md`, `docs/buglist.md` elolvasva
- [x] `Components/ComponentStepper.swift` elolvasva — új találat: `accessibilityLabel: "Increase \(unit)"` / `"Decrease \(unit)"` — plain interpoláció, `String(localized:)` kell
- [x] Teljes, összesített ENH-L10N-1 hiánylista összeállítva — felváltja a BY session részleges listáját
- [x] `docs/buglist.md` ENH-L10N-1 szekció frissítve
- [x] `docs/countdownApp-handoff.md` + `docs/progress.md` frissítve

#### Teljes hiánylista (BY+BZ audit összesítve) — lásd buglist.md ENH-L10N-1 szekció

**Következő session (akkor):** ENH-L10N-1 #1 (14 HU fordítás pótlása xcstrings-be) — Session CA elvégezte.

---

## Session BY — 2026-08-15 (Lokalizáció audit — LEZÁRVA)

### Session BY — LEZÁRVA
- [x] `docs/progress.md`, `docs/countdownApp-handoff.md`, `docs/buglist.md` elolvasva
- [x] `Localizable.xcstrings`, `ContentView.swift`, `AboutView.swift`, `SnippetsView.swift`, `CountdownView.swift` elolvasva
- [x] 14 HU gap, 4 hiányzó xcstrings kulcs, 3 kód-szintű hiba felmérve
- [x] Részleges audit (Countdown sub-views, Calculate, SnippetEditSheet még nem volt) — BZ session pótolta
- [x] `docs/progress.md` frissítve

---

## Session BX — 2026-08-15 (Help ablak max-szélesség fix + szekció cím padding fix — LEZÁRVA)

### Session BX — LEZÁRVA
- [x] `Theme/AppTheme.swift` módosítva — `helpWindowMinWidth: 640`, `helpWindowMaxWidth: 900`
- [x] `Views/Help/HelpView.swift` módosítva — frame min/max, section header padding `.horizontal 16`
- [ ] Build + git commit: **FELHASZNÁLÓ FELADATA**

---

## Session BW — 2026-08-15 (ENH-HELP-1: 4 hiányzó countdown xcstrings — LEZÁRVA)

### Session BW — LEZÁRVA
- [x] `Localizable.xcstrings` módosítva — 8 kulcs: help.countdown.copy/expand/free/toggle title+body
- [x] `Views/Help/HelpView.swift` módosítva (méret, font, padding, hierárchia)
- [x] `App/countdownAppApp.swift` módosítva: helpWindow defaultSize 640×620
- [x] Git commit: `3f9ed21`

---

## Session BV — 2026-08-15 (ENH-HELP-1-S5/S6: Recovery szekció + lezárás — LEZÁRVA)

### Session BV — LEZÁRVA
- [x] `Models/HelpContent.swift` módosítva — recovery.storage + recovery.banner (recovery.backup törölve)
- [x] `Localizable.xcstrings` módosítva — recovery kulcsok frissítve
- [x] `docs/buglist.md` ENH-HELP-1 → ✅ KÉSZ
- [ ] Build + git commit: **FELHASZNÁLÓ FELADATA**
  (javasolt üzenet: `ENH-HELP-1-S5/S6: Recovery section content, close out ENH-HELP-1`)

---

## Session BU — 2026-08-15 (ENH-HELP-1-S4 képek finalizálva — LEZÁRVA)

### Session BU — LEZÁRVA
- [x] Képek kézzel újravágva és lekerekítve (felhasználó)
- [x] `HelpScreenshot.swift` kód-oldali lekerekítés eltávolítva (macOS List kontextusban nem működött)
- [ ] Git commit: **FELHASZNÁLÓ FELADATA**

---

## Session BT — 2026-08-15 (ENH-HELP-1-S4 kép-megjelenítés egyszerűsítés — LEZÁRVA)

### Session BT — LEZÁRVA
- [x] `Components/HelpScreenshot.swift` teljesen átírva — focusRect/Canvas/NSImage crop logika eltávolítva; `Image.resizable().scaledToFit().frame(width: maxWidth)`
- [x] `Views/Help/HelpView.swift` módosítva — focusRect binding törölve, `.padding(.vertical, 10)` a screenshot-hoz
- [ ] Build + git commit: **FELHASZNÁLÓ FELADATA**

---

## Session BV — 2026-08-15 (ENH-L10N-1: SunPanel lokalizáció + FROM/TO fordítás — LEZÁRVA)

### Session BV — LEZÁRVA
- [x] `Views/Calculate/SunPanel.swift`: 4 helper szignatúra `String` → `LocalizedStringKey`
  (`sectionHeader`, `timeRow`, `labelRow`, `windowRow`) — `Text(stringVar)` eddig verbatim
  futott, most lokalizál
- [x] `Localizable.xcstrings`: 21 új SunPanel kulcs hozzáadva (5 section header emoji-val:
  `☀️  MORNING`/`🌆  EVENING`/`⚖️  DAY`/`🌙  MOON`/`📷  GOLDEN / BLUE HOUR`;
  16 row label: `Dawn`/`Dusk`/`First light`/`Last light`/`Sunrise`/`Sunset`/`Solar noon`/
  `Day length`/`Moonrise`/`Moonset`/`Phase`/`Illumination`/`Morning golden`/`Morning blue`/
  `Evening golden`/`Evening blue`) — mind hu-ra lefordítva
- [x] `Localizable.xcstrings`: `"FROM"` hu fordítás `-TÓL` → `KEZDÉS`; `"TO"` hu fordítás
  `-IG` → `BEFEJEZÉS`; mindkét entry kapott comment-et
- [ ] Build + git commit: **FELHASZNÁLÓ FELADATA**

---

## Session BU — 2026-08-15 (ENH-SETTINGS-2 + L10N audit bővítés + ENH-TOOLTIP-1 dokumentálás — LEZÁRVA)

### Session BU — LEZÁRVA
- [x] **ENH-SETTINGS-2** implementálva (3 fájl):
  - `App/AppKeys.swift`: `fontSizeStep` kulcs hozzáadva (`"nightshift.fontSizeStep"`, Int, default 0)
  - `Views/Settings/SettingsView.swift`: `fontSizeSection` computed var hozzáadva (segmented picker: Default/Large/Larger/Largest, `textformat.size` ikon, azonnali hatás), `@AppStorage(fontSizeStep)` state hozzáadva, header komment frissítve
  - `App/countdownAppApp.swift`: `@AppStorage(fontSizeStep)` hozzáadva, `.dynamicTypeSize(fontSizeStep.asDynamicTypeSize)` a `ContentView`-ra, `private extension Int { var asDynamicTypeSize: DynamicTypeSize }` a fájl végén
- [x] **ENH-L10N-1 audit bővítve** (`docs/buglist.md`):
  - `#7` — `CalculateView.swift` lefordítatlan saját stringek: "RESET FROM NOW"/"RESET TO NOW", "Remaining time:"/"Elapsed time:", "SAVE DEADLINE", "SAVED DEADLINES", "EXPIRED", "< 1M", "Name..."
  - `#8` — `SunPanel.swift` lefordítatlan label-ek: összes timeRow/labelRow/windowRow hívás label paramétere, section fejlécek; helper-ek `String` -> `LocalizedStringKey` átállítás szükséges
  - `#9` — `ContentView.swift` "General" tab label: `modeButton` `Text(mode.rawValue)` -> `Text(LocalizedStringKey(mode.rawValue))` javítás (#3 pont kibővítve)
- [x] **ENH-TOOLTIP-1** dokumentálva (`docs/buglist.md`): új bejegyzés, érintett elem-típusok, `.help()` implementációs irány, xcstrings kulcsok szükségessége
- [x] **SettingsView.swift tab-refactor**: `ScrollView` → `TabView` (Language + Appearance tab), `LanguageTab`/`AppearanceTab` private struct-ok, `Form + .formStyle(.grouped)`, `countdownAppApp.swift` `.defaultSize` 440×260-ra frissítve
- [x] **Font méret fix**: `AppTheme.alienLeague()` / `alienLeagueBold()` explicit `Font.custom()` hívások nem reagálnak `.dynamicTypeSize()`-ra — javítva: `AppTheme.fontScale` static var (`UserDefaults` alapú, 1.0/1.15/1.30/1.45), `alienLeague(size * fontScale)` pattern; a `@AppStorage` változás újrarenderi a teljes view hierarchiát
- [x] **Restart advisory fix**: `Section footer` macOS-on nem jelenik meg — átírva külön `if restartNeeded { Section { HStack... } }` blokkra; frame height dinamikus (190/240)
- [ ] Build + git commit: **FELHASZNÁLÓ FELADATA**

---

## Session BS — 2026-08-15 (ENH-HELP-1-S4 javítás: HelpScreenshot root cause fix — LEZÁRVA)

### Session BS — LEZÁRVA
- [x] `Components/HelpScreenshot.swift` átírva (v2): `NSImage.size` alapú valós intrinsic méret, egységes scale faktor, `ZStack` + offset
- [x] `Views/Help/HelpView.swift` módosítva: frame `maxWidth: 560` fixálva
- [x] `Models/HelpContent.swift` módosítva: corrected focusRect-ek, overview.what teszt image eltávolítva
- [ ] Build + git commit: **FELHASZNÁLÓ FELADATA**

---

## Session BR — 2026-08-15 (ENH-HELP-1-S4: text wrapping fix + 2 screenshot asset — LEZÁRVA)

### Session BR — LEZÁRVA
- [x] `Views/Help/HelpView.swift` módosítva — `.lineLimit(nil)` + `.frame(maxWidth: .infinity)`
- [x] `Models/HelpContent.swift` módosítva — sunpanel + notes imageName/focusRect
- [x] Git commit: `35b343e`, `87a3c7d`

---

## Session BQ — 2026-08-14 (ENH-HELP-1-S3: HelpScreenshot komponens — LEZÁRVA)

### Session BQ — LEZÁRVA
- [x] `Components/HelpScreenshot.swift` létrehozva (v1→v2 ugyanebben a session-ben)
- [x] `Views/Help/HelpView.swift` módosítva — HelpScreenshot bekötve
- [x] `Models/HelpContent.swift` módosítva — teszt focusRect
- [x] Git commit: `857ceae`

---

## Session BP — 2026-08-14 (ENH-HELP-1-S2: HelpWindowID + HelpCommands + HelpView váz — LEZÁRVA)

### Session BP — LEZÁRVA
- [x] `App/HelpWindowID.swift`, `App/HelpCommands.swift`, `Views/Help/HelpView.swift` létrehozva
- [x] `countdownAppApp.swift` módosítva — HelpCommands + helpWindow scene
- [x] `Localizable.xcstrings` frissítve — help.menu.item

---

## Session BO — 2026-08-14 (ENH-HELP-1-S1: adatmodell + xcstrings — LEZÁRVA)

### Session BO — LEZÁRVA
- [x] `Models/HelpContent.swift` létrehozva — HelpItem/HelpSection/HelpContent
- [x] `Localizable.xcstrings` létrehozva — 27 kulcs EN placeholder szöveggel

---

## Session BN — 2026-08-14 (BUG-SNIPPETSAVE-1 + BUG-SNIPPETDUP-1 — LEZÁRVA)

### Session BN — LEZÁRVA
- [x] `SnippetEditSheet.swift`: `shouldSaveOnDisappear = false` a "Save and quit" ágba
- [x] `Snippet.swift`: `let` → `@State private var`; `commitSave()` után `self.snippet = s`
- [x] `SnippetsView.swift`: `append` → id-alapú upsert
- [x] Git commit: `c8b3d5e`

---
