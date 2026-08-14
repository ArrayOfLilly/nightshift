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

**Buglist állapot összefoglaló** (`docs/buglist.md`) — nyitott tételek:
- **ENH-HELP-1** 🟡 — S1 KÉSZ (BO), S2 KÉSZ (BP), S3 KÉSZ (BQ, commit `857ceae`), **S4 következik**
  (valós tartalom + valós screenshotok)
- **ENH-DEVDOCS-1** 🟡 — fejlesztői dokumentáció hiányzik
- **ENH-DEVDOCS-2** 🟡 — README + install.md, projektnév egyeztetés
- **ENH-DEFERRED-1** 🟢 — deferred taskok dokumentálása (lokalizáció, Settings; About már kész)
- **ENH-L10N-1** 🟢, **ENH-SETTINGS-1** 🟢 — deferred, ENH-HELP-1 S1 részben előreviszi (xcstrings)
- **BUG-MANUAL-1** 🟡 — újranyitva (3 frissítési ok felhalmozódott: snippet save/dismiss logika,
  project delete, app név változás) — MINDIG UTOLSÓ, mert a screenshotok csak a végleges UI
  állapotot tükrözhetik

**Következő session jelöltek:**
- **ENH-HELP-1-S4** 🟡 — Help rendszer, 4/6 session: valós title/body szövegek az Overview
  szekcióhoz (`Localizable.xcstrings` EN placeholder → végleges szöveg), valós countdownApp
  screenshot asset(ek) becsatolása a `screenshot`/timer.png teszt asset helyett. S1–S3 KÉSZ
  (commit `857ceae`).
- **ENH-DEVDOCS-2** — README + install.md (Distribution csomag); projektnév egyeztetés

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
