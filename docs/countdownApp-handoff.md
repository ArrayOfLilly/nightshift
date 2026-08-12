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
- Manual: **kész** ✅ — `docs/manual/countdownApp-manual.md`, Data Recovery szekció (18/18b/18c screenshotok) hozzáadva (AD session)
- Git: **naprakész** — legutóbbi commit `f7f774d` (AE session)
- `Claude.md` megírva a gyökérbe
- `refactor-plan.md` teljes findings listával (7 kategória, A–G, 35+ finding)
- **Z session**: Codable model fix, `AppKeys` bevezetve minden persistence path-on
- **AA-a session**: Per-item recovery (Snippet + CalculateView) + Amber fix (`AppTheme.background` → `#F5A623`, `amberHex` szinkron, `markdownCSS` computed var) — commit `2dd8900`
- **AA-b session**: `CountdownView.load()` per-item recovery + notes-elágazás
- **AB session**: Banner UI (mindhárom view) + `FocusedNSTextField.Coordinator` deinit (NC-1..4 fix) + `AppDelegate` lifecycle hook
- **AC session**: DEBUG Cmd+Shift+D trigger — commit `e2c3666`
- **AD session**: Manual Data Recovery szekció + image groups — `manual_build.py` group parser, 9 group a manualban, 03b/03c+03d 2+1 layout, path fix
- **AE session**: Swift concurrency cleanup — B-2 `SnippetEditSheet` copyFeedback DispatchQueue→Task, B-3 `CalculateView` hoverTask DispatchWorkItem→Task, A-4 `SnippetEditSheet` `.onDisappear` auto-save — commit `f7f774d`
- **AF session**: Performance + concurrency — B-2 maradék (`SnippetsView` copy), C-1 MarkdownWebView guard, C-2 NotesSheet debounce, C-3 orderedFreeItems O(n), C-4 `Formatters.swift` (DateFormatter centralizálás + lokalizáció deferred task dokumentálva)

---

## Következő session feladata

- `refactor-plan.md` nyitott findingek: E-* (state management), F-* (duplication), G-* (layout)
- C kategória teljesen lezárva; B, C kategóriák kész
- Manual PDF újragenerálása (`manual_build.py` futtatása) ha szükséges

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
Formatters.swift
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
