# countdownApp — handoff a következő chat-hez

## Working setup
- Filesystem MCP-n keresztül dolgozunk. Szerializáltan olvasd a fájlokat.
- Filesystem:write_file teljes fájl felülírással működik, NEM appendál — mindig read-then-write.
- Header/komment: angolul, semmi magyar szöveg a kódban.
- progress.md frissítése + git commit minden session végén.
- **Inner kódrepo**: `/Users/ArrayOfLilly/tools/countdownApp/countdownApp/`
  Swift forrás: `countdownApp/countdownApp/countdownApp/` alatt.
- Olvasd el először a `progress.md`-t.

## Jelenlegi állapot (Session 27 végén)

**SUN-1-A — LEZÁRVA, commitolva (`86d0846`)**
- `countdownApp.entitlements` létrehozva (app-sandbox + network.client +
  files.user-selected.read-only) — korábban NEM volt entitlements fájl a
  projektben, Xcode auto-generálta a sandbox beállításokból, hálózati
  engedély nélkül. `project.pbxproj`: `CODE_SIGN_ENTITLEMENTS` hozzáadva
  a fő target Debug+Release configjához.
- `SunTimes.swift` — `TimeWindow` + `SunTimes` modell, végleges mezőlista,
  `RawDay`/`RawWindow` decode + `Date`-építés date+time+timezone mezőkből.
- `SunTimesService.swift` — `@MainActor ObservableObject`, `@AppStorage`
  koordináták (Budapest default), évenkénti UserDefaults cache, cache-first
  betöltés + hálózati fallback. CoreLocation még NEM bekötve.
- **Nincs még Xcode build-teszt** — a chat nem tud fordítani, a usernek
  kell ellenőriznie, hogy a projekt fordul-e és az entitlements rendben
  van-e (App Sandbox + hálózati hívás ne bukjon el runtime-ban).

### Következő feladat: SUN-1-B
CalculateView integráció + hover trigger + popover — `.onHover` a meglévő
hold-strip területe felett, 0.2s delay, popover (nem sheet). A `SunTimesService`
példányosítása/bekötése a `CalculateView`-ba, `sunTimes(for: Date())` hívás
az aktuális napra. Még nincs saját UI (`SunPanel.swift` — az SUN-1-C).

---

## Korábbi állapot (Session 26 végén)

**Beachball fix — LEZÁRVA, commitolva (`07861a9`)**
- 23-A: `dropEntered` guard (`if ids != freeOrder`)
- 23-B: `LazyVStack` → `VStack` — végleges fix (nem temp), igazolva Instruments-szel
- 23-C: `cachedEntries` / `cachedFreeItems` / `crossingTask` — ForEach lecsatolva a tick-ről
- TimelineView tick: `1.0s` (visszaállítva)
- Nincs több TEMP flag a kódban

**CalculateView fixek — commitolva (`e3648e1`, `922e299`)**
- CALC-2/3: `snapToMinute()` — minden Date-write percre kerekít
- CALC-4: `RESET FROM NOW` + `RESET TO NOW` gombok
- CALC-1: `DAYS` / `CAL` toggle, `@AppStorage("calculateDisplayMode")`

**23-D — LEZÁRVA (`8b2035b`)**
`LongPressStepperButton.swift` — timer double-registration fix.

## Következő session: SUN-1-A

### Mit csinál SUN-1-A (egy session)
1. **Entitlements ellenőrzése** — megkeresni az `.entitlements` fájlt, ellenőrizni hogy benne van-e `com.apple.security.network.client`. Ha nincs, hozzáadni. (`com.apple.security.personal-information.location` — CoreLocation — SUN-1-A-ban még NEM kell, csak ellenőrzés.)
2. **`SunTimes.swift`** — adatmodell:
   - `TimeWindow: Codable { let begin: Date; let end: Date }`
   - `SunTimes: Codable` — lásd mezőlista lent
   - JSON decode logika: az API `"HH:MM:SS"` 24 órás formátumban adja az időpontokat (nem ISO 8601), a `date` mező adja a napot (`"YYYY-MM-DD"`), a `timezone` IANA zónát — parse-oláskor ezeket össze kell rakni egy `Date`-té. Stratégia: `DateFormatter` locale-független, `"HH:mm:ss"` format, `timeZone = TimeZone(identifier: timezone)`.
3. **`SunTimesService.swift`** — hálózati service:
   - API: `https://api.sunrisesunset.io/json?lat=XX&lng=YY&date_start=YYYY-01-01&date_end=YYYY-12-31&timezone=auto`
   - Egy hívás az egész évre, response: `{ "results": [ { "date": "...", "sunrise": "...", ... }, ... ] }`
   - `UserDefaults` cache: kulcs `"sunTimesCache_YYYY"` — a teljes éves JSON string; évváltáskor (cache kulcs évszáma != aktuális év) újratölti
   - Koordináta: `@AppStorage("sunLatitude")` Double + `@AppStorage("sunLongitude")` Double, default Budapest: `47.4979, 19.0402`
   - CoreLocation még NEM — kézi koordináta először
4. **progress.md frissítése + git commit**

### Végleges mezőlista (SunTimes.swift)

**Nap:**
- `firstLight: Date` ← `"first_light"` (csillagászati szürkület kezdete)
- `dawn: Date` ← `"dawn"` (polgári szürkület)
- `sunrise: Date` ← `"sunrise"`
- `solarNoon: Date` ← `"solar_noon"`
- `sunset: Date` ← `"sunset"`
- `dusk: Date` ← `"dusk"` (polgári szürkület vége)
- `lastLight: Date` ← `"last_light"` (csillagászati szürkület vége)
- `dayLength: Int` ← `"day_length"` (másodpercben)

**Golden/Blue hour (user fia hajnalokat fotóz — fontos szekció):**
- `goldenHourMorning: TimeWindow` ← `"golden_hour_morning"` `{begin, end}`
- `blueHourMorning: TimeWindow` ← `"blue_hour_morning"` `{begin, end}`
- `goldenHourEvening: TimeWindow` ← `"golden_hour_evening"` `{begin, end}`
- `blueHourEvening: TimeWindow` ← `"blue_hour_evening"` `{begin, end}`

**Hold:**
- `moonrise: Date` ← `"moonrise"`
- `moonset: Date` ← `"moonset"`
- `moonPhase: String` ← `"moon_phase"` (pl. "Waning Crescent")
- `moonIllumination: Double` ← `"moon_illumination"` (0–100, %-ban jelenik meg)

**Kihagyott mezők:** `nautical_twilight_begin/end`, `golden_hour` (top-level redundáns),
`moon_phase_value`, `sun_altitude/azimuth`, `utc_offset`, `timezone`, `date`,
`moon_always_up/down`, `elevation`, `sun_status`.

### Tervezett UI szekciók (SUN-1-C-ben implementálandó, most csak referencia)
```
☀️  MORNING              🌆  EVENING
   First light               Sunset
   Dawn                      Dusk
   Sunrise                   Last light

⚖️  DAY                  🌙  MOON
   Solar noon                Moonrise
   Day length                Moonset
                             Phase: Waning Crescent
📷  GOLDEN / BLUE HOUR       19.5% illuminated
   Morning golden  05:56–06:51
   Morning blue    05:45–05:56
   Evening golden  19:35–20:30
   Evening blue    20:30–20:41
```

### Session bontás (SUN-1-A után)
- **SUN-1-B**: CalculateView integráció + hover trigger (`.onHover` a meglévő hold-strip területén, 0.2s delay, popover)
- **SUN-1-C**: `SunPanel.swift` UI — 4 szekció, Alien League font, amber/dark stílus; popover tetején `sun.svg` illusztráció; stílus: spooky tomato képernyő vizuális nyelve (mély sötét háttér, amber/sárga kontrasz, Alien League betűk)
- **SUN-1-D**: sun.svg duotone Python script

### Popover + sun.svg koncepció (végleges)
- **Trigger**: `.onHover` a meglévő hold-strip felett (NEM új nap-grafika a CalculateView-ban)
- **Popover felépítése**: tetején `sun.svg` illusztráció, alatta a sunrise/sunset adatok
- **Stílus**: spooky tomato képernyő vizuális nyelve — mély sötét háttér, amber/sárga kontrasztos elemek, Alien League betűk
- **sun.svg duotone**: a jelenlegi szürke (~206 `.cls-N` fill) → amber/sárga skálára; célszín: `AppTheme.amber`
  - Sötét vég = sötét amber, világos vég = világos sárga
  - **Fehér háttér probléma**: a sun.svg-nek fehér háttere van, ceruzával rajzolt vonalak. Ha mindent amber skálára interpolálunk, a fehér háttér sárga lesz — nem jó. Megoldás: lightness küszöb (pl. > 240) felett `fill="transparent"` — de ez kipróbálással dől el, a küszöb hangolható. Alternatíva: küszöb felett a popover háttérszínét kapja (`#060503`).
- **Popover háttér**: sötét — `#060503` (AppTheme.calculateBackground) vagy mélyebb fekete

## Érintett fájlok (minden commitolva Session 25-ig)
- `CalculateView.swift` — CALC-1 (`525ed86`), toggle refactor (`2f99646`)
- `LongPressStepperButton.swift` — 23-D (`8b2035b`)
- `CountdownView.swift` — beachball fixek (`07861a9`)
