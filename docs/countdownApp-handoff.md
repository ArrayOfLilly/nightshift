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
- Git commit: **PENDING** (Session Q–Z)
- `Claude.md` megírva a gyökérbe
- `refactor-plan.md` **teljes findings listával** (7 kategória, A–G, 35+ finding)
- **Z session kész**: Codable model fix (`Snippet`, `NamedDeadline`, `CountdownItem.id`), `AppKeys` bevezetve minden persistence path-on

---

## Következő session feladata

### 0. AA session — Recovery infrastruktúra (A-2 fix)

Z session lezárva. A Codable model fix kész:
- `AppKeys.swift` ✅ (már meglévő)
- `Snippet.swift` ✅ custom Codable
- `NamedDeadline.swift` ✅ custom Codable
- `CountdownItem.id` ✅ decodeIfPresent
- Minden UserDefaults kulcs → `AppKeys.*` ✅

**AA-a session scope:**
- `Snippet.load()` — per-item recovery + corrupt dump (`AppKeys.corruptedDump`)
- `CalculateView.loadDeadlines()` — ugyanaz
- Corrupt dump: `[String]` (JSON-serialized fragment-ek), akkumulálva (nem felülírva)

**AA-b session scope:**
- `CountdownView.load()` — per-item recovery + notes-alapú elágazás
  - notes-szal → dump + banner; notes nélkül → csendes eldobás

### 1. Git commit

```bash
cd /Users/ArrayOfLilly/tools/countdownApp/countdownApp
git add docs/refactor-plan.md docs/progress.md docs/countdownApp-handoff.md
git commit -m "Session Y: audit összesítés, refactor-plan findings (A–G)"
```

(Session Q–X commit-ja még mindig PENDING — vagy összevonni, vagy külön.)

### 2. Refaktor prioritizálás és session-bontás egyeztetése

Dokumentum: `docs/refactor-plan.md` — teljes findings lista, 5 nyílt tervezési kérdéssel (T1–T5).

Egyeztetési kérdések implementáció előtt:
- **T1**: partial decode scope — elég `do/catch` + log, vagy per-item recovery is?
- **T2**: `CountdownViewModel` mikor — Codable fixek után azonnal, vagy külön phase?
- **T3**: `enum CalculationModalState` bevezethető-e a jelenlegi `CalculateView` struktúrában,
  vagy csak a D-1/D-4 szétválasztással együtt?
- **T4**: `markdownCSS` computed property-vé alakítás kockázata?
- **T5**: session-bontás javaslat: A+B track / C+E track / D track (3 session)?

### 3. Javasolt első track: A+B (Codable + Observer leak)

Ha az egyeztetés után a prioritizálás A+B első → session scope:
- `Snippet.swift`: custom `init(from decoder:)` + `CodingKeys`
- `NamedDeadline.swift`: ugyanaz
- `CountdownItem.swift`: `id` → `decodeIfPresent`
- `CountdownView`, `CalculateView`, `Snippet`: `try?` → `do/catch` (legalább log)
- `enum AppKeys` bevezetése
- `FocusedNSTextField.Coordinator`: `deinit { removeObserver(self) }`
- `countdownAppApp.swift`: `applicationWillTerminate` + `synchronize()`

---

## Swift fájlok (teljes lista)

```
AddCountdownSheet.swift
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

- `CountdownItem` — egyedüli modell custom `init(from decoder:)`-rel; `Snippet` és `NamedDeadline`
  synthesized Codable → bármely új mező hozzáadásakor az egész tömb `[]`-re esik.
  **Soha ne adj hozzá mezőt `decodeIfPresent` + default nélkül.**
- `AppTheme.swift` — shared design token forrás.
- `freeOrder` `.onChange` csak `rebuildCache()`-t hív, `saveFreeOrder()`-t nem — szándékos, de
  latens footgun (OWN-LC-2).
- Font PostScript nevek: `AlienLeague` / `AlienLeagueBold` — centralizálva `AppTheme.swift`-ben.
- `FocusedNSTextField.Coordinator` — **observer leak** (NC-1..4): `deinit` hiányzik, zombie
  Coordinator-ok minden ablakváltáskor `onCommit()`-ot futtatnak. Fix: B-1.
- `markdownCSS` amber (`#F5A623`) ≠ `AppTheme.background` (#E5A020) — vizuális eltérés a
  WKWebView renderelt tartalmában. **Vizuális döntés függőben:** a CSS amber szebb, 90%+
  valószínűséggel `AppTheme.background` → `#F5A623` lesz (az egész UI-t érinti). Következő
  session elején kipróbálni és dönteni — utána a `markdownCSS` computed property-vé alakítása
  és az interpoláció triviális.
