# countdownApp — handoff a következő chat-hez

## Working setup
- Filesystem MCP-n keresztül dolgozunk. Szerializáltan olvasd a fájlokat.
- Header/komment: angolul, semmi magyar szöveg a kódban.
- progress.md frissítése + git commit minden session végén.
- **Inner kódrepo**: `/Users/ArrayOfLilly/tools/countdownApp/countdownApp/`
  Swift forrás: `countdownApp/countdownApp/countdownApp/` alatt.
- Olvasd el először a `progress.md`-t.

## Jelenlegi állapot (Session 24 végén)

**Beachball fix — LEZÁRVA, commitolva (`07861a9`)**
- 23-A: `dropEntered` guard (`if ids != freeOrder`)
- 23-B: `LazyVStack` → `VStack` — végleges fix (nem temp), igazolva Instruments-szel
- 23-C: `cachedEntries` / `cachedFreeItems` / `crossingTask` — ForEach lecsatolva a tick-ről
- TimelineView tick: `1.0s` (visszaállítva)
- Nincs több TEMP flag a kódban

**CalculateView fixek — commitolva (`e3648e1`, `922e299`)**
- CALC-2/3: `snapToMinute()` — minden Date-write percre kerekít
- CALC-4: `RESET FROM NOW` + `RESET TO NOW` gombok a stepperek alatt, eredeti stílusban

**23-D — még nyitva (LongPressStepperButton timer double-add)**
`LongPressStepperButton.swift` — `Timer.scheduledTimer` + `RunLoop.main.add(..., .common)`
kettős regisztráció. Nem beachball-forrás, önálló bug.

## Következő session: CALC-1 implementáció

Részletes terv a `progress.md` Session 24 „CALC-1 implementation plan" szekciójában.

**Röviden:**
- Két eredmény mód, toggle-lal váltható, a result row alá helyezve.
- `DAYS` gomb (alapértelmezett): jelenlegi `d h m s` számolás, változatlan.
- `CAL` gomb: `cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from:, to:)`,
  vezető nullás komponensek elrejtve.
- Toggle gombok stílusa: mint a RESET FROM/TO NOW gombok (spacing 6, 12pt ikon,
  padding 16/8, cornerRadius 8). Aktív gomb: `Color.white.opacity(0.35)` háttér.
- Mentés: `@AppStorage("calculateDisplayMode")` (`"days"` / `"cal"`).
- Hetek kizárva.

## Érintett fájlok
- `CalculateView.swift` — CALC-1 célfájl
- `LongPressStepperButton.swift` — 23-D (alacsony prioritás)
