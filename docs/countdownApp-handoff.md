# countdownApp — handoff

## Working setup

- **Filesystem MCP** — fájlolvasás/írás. Szerializáltan olvasd a fájlokat.
- `Filesystem:write_file` teljes fájl felülírással működik, NEM appendál — mindig read-then-write.
- Header/komment: angolul, semmi magyar szöveg a kódban.
- **Inner kódrepo**: `/Users/ArrayOfLilly/tools/countdownApp/countdownApp/`
- **Swift forrás**: `countdownApp/countdownApp/countdownApp/` alatt
- **Docs**: `countdownApp/countdownApp/docs/` — progress.md, handoff, auditok, manual, misc mind itt
- Session elején olvasd el: `docs/progress.md` + `docs/countdownApp-handoff.md` + `Claude.md`
- Session végén: progress.md frissítése + git commit
- **`docs/history.md`**: a felhasználó kézzel archiválja ide a `progress.md` lezárt session-részeit
  időnként, hogy a `progress.md` rövid maradjon. Az áthelyezett tartalom NEM rövidül/tömörül —
  teljes részletességgel kerül át. NEM kell minden session elején elolvasni — csak akkor, ha egy
  korábbi (már archivált) session részlete valóban szükséges.
- **`docs/bughistory.md`**: ugyanez a konvenció, de a `buglist.md`-hez — a felhasználó kézzel
  átmásolja ide a lezárt, újra nem nyitandó bug/enhancement bejegyzéseket, és törli őket a
  `buglist.md`-ből. Szintén teljes részletességgel, nem tömörítve át. NEM kell minden session
  elején elolvasni — csak ha egy korábbi bug root cause-ára valóban szükség van.

---

## Következő session feladata

**Session CP (2026-08-17) LEZÁRVA:** `Localizable.xcstrings` housekeeping — 2 HU string
javítva (`"Open slot details"`, `"Open deadline details — load or delete"`: hiányzó
birtokos rag pótolva, "részletek" → "részleteinek"), és a fájl legelején lévő funkciótlan
üres `""` kulcs törölve. **MEGJEGYZÉS:** egy korábbi, ugyanaznapi munkamenet állítólag
20 VoiceOver/tooltip string HU fordítását is elvégezte, de az nincs dokumentálva sem
itt, sem a progress.md-ben — ellenőrzésre/utólagos rögzítésre szorulhat.
- Build: FELHASZNÁLÓ FELADATA

**Session CO (2026-08-16) LEZÁRVA:** **ENH-HELP-2** teljes egészében kész — mind
5 Help szekció (Overview, Countdown, Calculate, Snippets, Recovery), 25/25 item
body szövege mélyítve EN+HU-ban. Utólag (felhasználói visszajelzés alapján): a
felhasználó által már korábban Assetsbe tett 2 kép (`calculated-days`,
`calculated-epochs`) bekötve a `calculate.toggle` itemhez, `HelpItem` modell
több-képes támogatással (`imageNames: [String]`), és a screenshot bal margin
javítva (28pt, a body szöveghez igazítva, nem a címhez). Még ugyanebben a
sessionben: a tabfül váltógomb hátterszíne is javítva (`AppTheme.dark` barna
→ `AppTheme.calculateBackground` közel-fekete, csak ezen az egy gombon), majd
a `calculate.toggle` két screenshotja `imageScale: 0.75`-re kicsinyítve (a
másik 2 meglévő screenshotos item 1.0-n marad).
- Build: FELHASZNÁLÓ FELADATA (CN + CO változások együtt ellenőrizhetők)

**Következő session témája:** build ellenőrzés (CN + CO változások együtt), majd
BUG-MANUAL-1, ENH-DEVDOCS-1/2, ENH-L10N-1 maradék.

**Buglist állapot összefoglaló** (`docs/buglist.md`) — nyitott tételek:
- **ENH-HELP-1** ✅ — KÉSZ (S1–S6 + BW session + CN session: projekt törlés + tooltipek hozzáadva)
- **ENH-HELP-2** ✅ — KÉSZ (Session CO): mind az 5 Help szekció (25/25 item) body szövege mélyítve EN+HU-ban
- **ENH-DEVDOCS-1** 🟡 — fejlesztői dokumentáció hiányzik
- **ENH-DEVDOCS-2** 🟡 — README + install.md, projektnév egyeztetés
- **ENH-DEFERRED-1** 🟢 — deferred taskok dokumentálása (lokalizáció, Settings; About már kész)
- **ENH-L10N-1** 🟢 — FOLYAMATBAN, szüneteltetve. Audit LEZÁRVA (BY+BZ+BU bővítés: #7 CalculateView, #8 SunPanel, #9 General). #1 (14 HU fordítás) commitolva `e6185ed`. Következő: #2 hiányzó xcstrings kulcsok
- **ENH-SETTINGS-1** ✅ — KÉSZ, commitolva `e6185ed` (Session CB)
- **ENH-SETTINGS-2** ✅ — KÉSZ, commitolva `e6185ed` (Session BU + CC)
- **ENH-TOOLTIP-1** ✅ — KÉSZ (Session CK): modeButton + snippetRow edit `.help()` hozzáadva; 3 xcstrings kulcs; audit megerősítette hogy minden más elem már megvolt
- **FOCUSABLE-AUDIT** ✅ — KÉSZ (Session CL): minden Button-szintű `.focusable(false)` → `.focusEffectDisabled()` cserélve 6 fájlban; szándékos kivételek megőrizve (LongPressStepperButton Image, SnippetEditSheet/AboutView/AddCountdownSheet container-szintű workaround-ok)
- **BUG-SNIPPEDITBEACHBALL-1** ✅ — LEZÁRVA (2026-08-16): `LazyVStack`→`VStack` csere (Session 23-B) megszüntette; felhasználói megerősítés alapján
- **BUG-MANUAL-1** 🟡 — újranyitva (3 frissítési ok felhalmozódott: snippet save/dismiss logika,
  project delete, app név változás) — MINDIG UTOLSÓ, mert a screenshotok csak a végleges UI
  állapotot tükrözhetik

**ENH-SETTINGS-2 ✅ KÉSZ (Session BU + CC)**

Font méret picker a Settings-ben: segmented control Default/Large/Larger/Largest.
`.dynamicTypeSize()` a `ContentView` gyökerén, azonnali hatás, restart nem szükséges.
Érintett fájlok (Session BU): `AppKeys.swift`, `SettingsView.swift`, `countdownAppApp.swift`.

Session BU végén kiderült (élő teszteléskor), hogy a `Font.custom()` (alienLeague/alienLeagueBold)
hívások nem reagálnak `.dynamicTypeSize()`-ra — ez az `AppTheme.fontScale` pattern-nel lett megoldva
(Session BU), de a `ContentView` gyerek nézetei (`CalculateView`, `CountdownView`, `SnippetsView`)
még nem figyelték a `fontSizeStep`-et, így nem frissültek élőben. **Session CC** ezt zárta le: mindhárom
nézetbe bekerült egy saját `@AppStorage(AppKeys.fontSizeStep)` subscription (részletek:
`docs/progress.md` Session CC szekció). Ugyanebben a session-ben, felhasználói visszajelzés
alapján az is kiderült, hogy Largest lépésnél a módváltó fülek címei nem fértek ki az ablakban —
`ContentView.swift` mostantól `PreferenceKey`-alapú élő méréssel dinamikusan szélesíti az
ablak `minWidth`/`maxWidth` értékeit a mért fülcím-szélességhez igazítva.
**Git commit: `e6185ed`** — Session CA + BU + CB + CC együtt commitolva (2026-08-15, Session BU session).

**Session BV (2026-08-15) elvégezve:** ENH-L10N-1 #8 (SunPanel) LEZÁRVA — `SunPanel.swift`
4 helper `String` → `LocalizedStringKey`; xcstrings +21 SunPanel kulcs (5 section header +
16 row label). `"FROM"` hu: `KEZDÉS`, `"TO"` hu: `BEFEJEZÉS`.

**Következő session:** ENH-L10N-1 maradék — #2 (egyéb hiányzó xcstrings kulcsok), #3 (kód-szintű
hibák), #5 (`SunTimesService.swift`), #6 (`CalculateView.swift` maradék audit), #9 (`ContentView`
General tab). Vagy egyeztetés alapján más prioritás.

**ENH-L10N-1 folytatása mikorra marad** — ha visszaérünk rá: `docs/buglist.md` ENH-L10N-1
szekció, #2 pont (eredeti 4 + új kb. 13 hiányzó kulcs xcstrings-be felvétele), majd #3
(4 kód-szintű hiba), majd #6 (`CalculateView.swift` + `SnippetEditSheet.swift` maradék
audit), plusz #5 (`SunTimesService.swift` nyitott kérdés).

- **ENH-DEVDOCS-2** 🟡 — README + install.md (Distribution csomag); projektnév egyeztetés
- **BUG-MANUAL-1** 🟡 — manual frissítés (snippet save/dismiss logika, project delete, app név)

---

## Buglist

- `docs/buglist.md` — UX-1 (max-szélesség korlátok) bejegyzve (AT session)

---

## Az app koncepciója — NightShift

Az app neve **NightShift** (nem "countdownApp" — az csak a repo/projekt technikai neve marad,
amíg az ENH-DEVDOCS-2 alatt formalizáljuk az átnevezést; a UI-ban már most is "NightShift Help"
szerepel a S2 óta létező `help.menu.item` kulcsban).

Használati forgatókönyv, ami minden Help-szövegnek/UX döntésnek keretet ad:

- A felhasználó **éjjel** fejleszt side projekteket, ingyenes AI modellekkel (mert nappal mást
  csinál). Amikor kezd világosodni, aludni kell — az app ezt a napi ablakot menedzseli.
- **Calculate fül** — a side project deadline-jai ide kerülnek; a sun time (napkelte) mondja meg,
  meddig lehet aznap még dolgozni. Ez nem általános "time distance calculator", hanem
  konkrétan az éjszakai munkaablak végének a jelzése.
- **Countdown fül** — NEM általános célú countdown lista. Az egyes ingyenes AI modell/account
  cooldownjait tartja nyilván (pl. Claude, Codex, ChatGPT, DeepSeek, Qwen/QLM, Kimi, stb.) —
  amikor melyik szolgáltatás szabadul fel újra.
- **Snippets fül** — session-átadásra való: ha egy munkamenetet át akar adni (más eszköz/session),
  ide menti a handoffot/egyéb infot.
- **Notes** (countdown itemeken) — ha helyben kell folytatni egy megszakított munkát, ide írja fel
  a felhasználó a folytatáshoz szükséges emlékeztetőt; a jegyzet meglétét a számára láthatóvá
  teszi a létező `noteIndicator` (eye.fill badge) a countdown soron.

**Hatás a Help tartalomra (ENH-HELP-1-S4)**: az Overview szekció jelenlegi 2 itemje túl általános
("personal time-management tool") — nem tükrözi ezt a konkrét használati mintát. Az S4 során a
tartalmat erre alapozva kell újraírni, nem az eredeti IconKeeper-mintát követve szó szerint.

---

## Kritikus tudás

- `CountdownItem`, `Snippet`, `NamedDeadline` — custom `init(from decoder:)`. **Soha ne adj hozzá mezőt `decodeIfPresent` + default nélkül.**
- `AppTheme.swift` — shared design token forrás. `amberHex` a CSS/WebView szinkron kulcs.
- `freeOrder` `.onChange` csak `rebuildCache()`-t hív, `saveFreeOrder()`-t nem — szándékos, latens footgun (OWN-LC-2).
- Font PostScript nevek: `AlienLeague` / `AlienLeagueBold` — centralizálva `AppTheme.swift`-ben.
- `DebugNotifications.injectCorruptBanner` — csak `#if DEBUG`, `AppKeys.swift` alján.

---

## Swift fájlok (teljes lista, mappastruktúra szerint — BB session frissítés)

```
App/AppKeys.swift
App/countdownAppApp.swift
App/HelpWindowID.swift
App/HelpCommands.swift
Components/ComponentStepper.swift
Components/CopyButton.swift
Components/FocusedNSTextField.swift
Components/HelpScreenshot.swift
Components/LongPressStepperButton.swift
Components/SharedEditorComponents.swift
Models/CountdownItem.swift
Models/NamedDeadline.swift
Models/Snippet.swift
Services/Formatters.swift
Services/SunTimes.swift
Services/SunTimesService.swift
Services/WindowHelpers.swift
Theme/AppTheme.swift
Views/ContentView.swift
Views/AboutView.swift
Views/Help/HelpView.swift
Views/Calculate/CalculateView.swift
Views/Calculate/DeadlineDetailSheet.swift
Views/Calculate/SunPanel.swift
Views/Countdown/AddCountdownSheet.swift
Views/Countdown/ColorPickerSheet.swift
Views/Countdown/CountdownDetailView.swift
Views/Countdown/CountdownRowView.swift
Views/Countdown/CountdownView.swift
Views/Countdown/NotesSheet.swift
Views/Snippets/SnippetEditSheet.swift
Views/Snippets/SnippetsView.swift
```
