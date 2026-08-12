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
- Git commit: **PENDING** (Session Q–W + docs átszervezés)
- `Claude.md` megírva a gyökérbe

---

## Következő session feladata

### 1. Git commit

```bash
cd /Users/ArrayOfLilly/tools/countdownApp/countdownApp
git add -A
git commit -m "Session Q–W: auditok 6–16 + bugfixek + manual + docs átszervezés + Claude.md"
```

### 2. Refaktor tervezés

Dokumentum: `docs/refactor-plan.md` — már létezik, váz megvan.

Munkamenet: olvasd el a `refactor-plan.md`-t, majd az auditokat **egyenként, szükség szerint**
— ne töltsd be az összeset egyszerre. Az auditra csak akkor van szükség, ha az adott finding
konkrétan napirendre kerül.

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

- `CountdownItem` — egyedüli modell custom `init(from decoder:)`-rel; `Snippet` és `NamedDeadline` synthesized Codable → bármely új mező hozzáadásakor az egész tömb `[]`-re esik. Soha ne adj hozzá mezőt `decodeIfPresent` + default nélkül.
- `AppTheme.swift` — shared design token forrás.
- `freeOrder` `.onChange` csak `rebuildCache()`-t hív, `saveFreeOrder()`-t nem — szándékos, de latens footgun.
- Font PostScript nevek: `AlienLeague` / `AlienLeagueBold` — centralizálva `AppTheme.swift`-ben.
