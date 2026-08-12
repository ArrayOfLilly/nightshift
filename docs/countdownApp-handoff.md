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
- Manual: kész, `docs/manual/`
- Git commit: **PENDING** (Session Q–AA-b)
- `Claude.md` megírva a gyökérbe
- `refactor-plan.md` **teljes findings listával** (7 kategória, A–G, 35+ finding)
- **Z session kész**: Codable model fix (`Snippet`, `NamedDeadline`, `CountdownItem.id`), `AppKeys` bevezetve minden persistence path-on
- **AA-a session kész**: Per-item recovery infrastruktúra — `Snippet.load()` + `CalculateView.loadDeadlines()` + `AppKeys.appendCorruptFragments`
- **AA-b session kész**: `CountdownView.load()` per-item recovery + notes-alapú elágazás
- **AB session kész**: Banner UI (mindhárom view) + `FocusedNSTextField.Coordinator` deinit fix + `countdownAppApp.swift` lifecycle hook

---

## Következő session feladata

### Amber döntés (F-6)

CSS `#F5A623` vs SwiftUI `AppTheme.background` `#E5A020` — vizuálisan összehasonlítani és dönteni.
Ha `#F5A623` nyeri → `AppTheme.background` frissítés + `markdownCSS` computed property-vé alakítás.

### Git commit (PENDING)

```bash
cd /Users/ArrayOfLilly/tools/countdownApp/countdownApp
git add -A
git commit -m "Session Z+AA-a: Codable fix + per-item recovery infrastruktúra (Snippet, CalculateView)"
```

---

## Recovery infrastruktúra — áttekintés

### AppKeys.appendCorruptFragments(_ fragments: [String])
- Shared helper — `AppKeys.swift`-ben, az `AppKeys.corruptedDump` kulcshoz közel
- Akkumulál, nem felülír — minden call hozzáappendál

### Load path státusz
| Path | Recovery | Dump |
|------|----------|------|
| `Snippet.load()` | ✅ per-item | ✅ AppKeys.corruptedDump |
| `CalculateView.loadDeadlines()` | ✅ per-item | ✅ AppKeys.corruptedDump |
| `CountdownView.load()` | ✅ per-item + notes-elágazás | ✅ notes esetén |

### Banner státusz
| View | Banner | Dismiss |
|------|--------|---------|
| `SnippetsView` | ✅ kész | ✅ kész |
| `CalculateView` | ✅ kész | ✅ kész |
| `CountdownView` | ✅ kész | ✅ kész |

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

---

## Kritikus tudás

- `CountdownItem` — custom `init(from decoder:)`-rel; `Snippet` és `NamedDeadline` szintén (Z session óta).
  **Soha ne adj hozzá mezőt `decodeIfPresent` + default nélkül.**
- `AppTheme.swift` — shared design token forrás.
- `freeOrder` `.onChange` csak `rebuildCache()`-t hív, `saveFreeOrder()`-t nem — szándékos, de
  latens footgun (OWN-LC-2).
- Font PostScript nevek: `AlienLeague` / `AlienLeagueBold` — centralizálva `AppTheme.swift`-ben.
- `FocusedNSTextField.Coordinator` — **observer leak** (NC-1..4): `deinit` hiányzik, zombie
  Coordinator-ok minden ablakváltáskor `onCommit()`-ot futtatnak. Fix: AB session (B-1).
- `markdownCSS` amber (`#F5A623`) ≠ `AppTheme.background` (#E5A020) — vizuális eltérés a
  WKWebView renderelt tartalmában. **Vizuális döntés függőben:** a CSS amber szebb, 90%+
  valószínűséggel `AppTheme.background` → `#F5A623` lesz. AB session előtt dönteni.
