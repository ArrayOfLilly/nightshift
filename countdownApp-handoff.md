# countdownApp — handoff a következő chat-hez

## Working setup
- Filesystem MCP-n keresztül dolgozunk. Szerializáltan olvasd a fájlokat.
- Header/komment: angolul, semmi magyar szöveg a kódban.
- progress.md frissítése + git commit minden session végén.
- **Inner kódrepo**: `/Users/ArrayOfLilly/tools/countdownApp/countdownApp/`
  Swift forrás: `countdownApp/countdownApp/countdownApp/` alatt.
- Olvasd el először a `progress.md`-t.

## Jelenlegi állapot (Session 25 végén)

**Beachball fix — LEZÁRVA, commitolva (`07861a9`)**
- 23-A: `dropEntered` guard (`if ids != freeOrder`)
- 23-B: `LazyVStack` → `VStack` — végleges fix (nem temp), igazolva Instruments-szel
- 23-C: `cachedEntries` / `cachedFreeItems` / `crossingTask` — ForEach lecsatolva a tick-ről
- TimelineView tick: `1.0s` (visszaállítva)
- Nincs több TEMP flag a kódban

**CalculateView fixek — commitolva (`e3648e1`, `922e299`)**
- CALC-2/3: `snapToMinute()` — minden Date-write percre kerekít
- CALC-4: `RESET FROM NOW` + `RESET TO NOW` gombok a stepperek alatt, eredeti stílusban

**CALC-1 — Calendar-aware result mode — kész (Session 25)**
- `DAYS` / `CAL` toggle a result row alatt; `@AppStorage("calculateDisplayMode")` menti.
- `calResultParts`: `Calendar.dateComponents` earlier→later, vezető nullák elrejtve.
- `modeToggle` + `modeButton` helpers hozzáadva `CalculateView.swift`-hez.

**23-D — még nyitva (LongPressStepperButton timer double-add)**
`LongPressStepperButton.swift` — `Timer.scheduledTimer` + `RunLoop.main.add(..., .common)`
kettős regisztráció. Nem beachball-forrás, önálló bug.

## Következő session: 23-D vagy SUN-1

- **23-D** (közepes): `LongPressStepperButton.swift` — `Timer.scheduledTimer` + `RunLoop.main.add`
  kettős regisztráció kijavítása.
- **SUN-1** (backlog): sunrise/sunset sheet a CalculateView holdjai fölé.

## Érintett fájlok (commit pending)
- `CalculateView.swift` — CALC-1 (Session 25)
- `LongPressStepperButton.swift` — 23-D (alacsony prioritás)
