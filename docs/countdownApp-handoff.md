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

---

## Jelenlegi állapot

- Audit pipeline: **mind a 16 kész** ✅ — `docs/audit_files/`
- Manual: kész, `docs/manual/` — **banner screenshot + szöveg hiányzik** (AD session feladata)
- Git: **naprakész** — legutóbbi commit `d94a372` (AC session docs)
- `Claude.md` megírva a gyökérbe
- `refactor-plan.md` teljes findings listával (7 kategória, A–G, 35+ finding)
- **Z session**: Codable model fix, `AppKeys` bevezetve minden persistence path-on
- **AA-a+AA-b session**: Per-item recovery — `Snippet.load()`, `CalculateView.loadDeadlines()`, `CountdownView.load()`
- **AB session**: Banner UI (mindhárom view) + `FocusedNSTextField.Coordinator` deinit (NC-1..4 fix) + `AppDelegate` lifecycle hook
- **AC session**: DEBUG Cmd+Shift+D trigger — corrupt banner screenshothoz

---

## Következő session feladata (AD)

### 1. Manual — banner screenshot + leírás

- Build & Run DEBUG
- Navigálj mindhárom view-ra (Countdown, Calculate, Snippets)
- Cmd+Shift+D → banner megjelenik → screenshot mentése
- `docs/manual/` mappába beilleszteni a screenshotokat
- Manual szöveg kiegészítése: recovery banner viselkedés, Copy raw data, Dismiss

### 2. Amber döntés (F-6)

- `AppTheme.background` jelenleg `#E5A020`; a `markdownCSS` WKWebView CSS-ben `#F5A623` van
- Vizuálisan összehasonlítani a kettőt — valószínűleg `#F5A623` nyeri
- Ha igen: `AppTheme.swift` → `background` hex → `#F5A623` + `amberHex` szinkron ellenőrzés
- `markdownCSS` már computed `var` (AA-a session óta), `amberHex`-et használja — csak `AppTheme.background` hex kell frissíteni

---

## Recovery infrastruktúra — áttekintés

### AppKeys.appendCorruptFragments(_ fragments: [String])
- `AppKeys.swift`-ben, a `corruptedDump` kulcs mellett
- `#if DEBUG` alatt itt van `DebugNotifications.injectCorruptBanner` is
- Akkumulál, nem felülír

### Load path státusz
| Path | Recovery | Dump |
|------|----------|------|
| `Snippet.load()` | ✅ per-item | ✅ AppKeys.corruptedDump |
| `CalculateView.loadDeadlines()` | ✅ per-item | ✅ AppKeys.corruptedDump |
| `CountdownView.load()` | ✅ per-item + notes-elágazás | ✅ notes esetén |

### Banner státusz
| View | Banner | Dismiss | Debug trigger |
|------|--------|---------|---------------|
| `SnippetsView` | ✅ | ✅ | ✅ .onReceive |
| `CalculateView` | ✅ | ✅ | ✅ .onReceive |
| `CountdownView` | ✅ | ✅ | ✅ .onReceive |

---

## Kritikus tudás

- `CountdownItem`, `Snippet`, `NamedDeadline` — custom `init(from decoder:)`. **Soha ne adj hozzá mezőt `decodeIfPresent` + default nélkül.**
- `AppTheme.swift` — shared design token forrás. `amberHex` a CSS/WebView szinkron kulcs.
- `freeOrder` `.onChange` csak `rebuildCache()`-t hív, `saveFreeOrder()`-t nem — szándékos, latens footgun (OWN-LC-2).
- Font PostScript nevek: `AlienLeague` / `AlienLeagueBold` — centralizálva `AppTheme.swift`-ben.
- `DebugNotifications.injectCorruptBanner` — csak `#if DEBUG`, `AppKeys.swift` alján.

---

## Swift fájlok (teljes lista)

```
AddCountdownSheet.swift
AppKeys.swift
AppTheme.swift
CalculateView.swift
ColorPickerSheet.swift
ContentView.swift
CountdownDetailView.swift
CountdownItem.swift
CountdownRowView.swift
CountdownView.swift
LongPressStepperButton.swift
NamedDeadline.swift
NotesSheet.swift
SharedEditorComponents.swift
Snippet.swift
SnippetEditSheet.swift
SnippetsView.swift
SunPanel.swift
SunTimes.swift
SunTimesService.swift
countdownAppApp.swift
```
