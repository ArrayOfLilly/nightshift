# countdownApp — handoff a következő chat-hez

## Working setup
- Filesystem MCP-n keresztül dolgozunk. Szerializáltan olvasd a fájlokat.
- Filesystem:write_file teljes fájl felülírással működik, NEM appendál — mindig read-then-write.
- Header/komment: angolul, semmi magyar szöveg a kódban.
- progress.md frissítése + git commit minden session végén.
- **Inner kódrepo**: `/Users/ArrayOfLilly/tools/countdownApp/countdownApp/`
  Swift forrás: `countdownApp/countdownApp/countdownApp/` alatt.
- Olvasd el először a `progress.md`-t.

## Jelenlegi állapot (Session 28 végén)

**SUN-1-B — LEZÁRVA** (commit függőben, user buildeli)
- `countdownAppApp.swift`: `@StateObject private var sunService = SunTimesService()` +
  `.environmentObject(sunService)` — service az app élettartamára él.
- `CalculateView.swift`: `@EnvironmentObject var sunService`, hover state-ek
  (`showSunPopover`, `hoverTask: DispatchWorkItem?`, `todaySunTimes: SunTimes?`);
  `.onHover` → 0.2s `DispatchWorkItem` delay → `showSunPopover = true`; kilépéskor
  cancel + false. `.popover(isPresented: $showSunPopover)` → `sunPopoverContent`
  placeholder (sunrise/sunset időpontok ha adat megvan, ProgressView ha tölt,
  egyébként statikus szöveg). `fetchTodaySunTimes()` a `.onAppear`-ből.
- `#Preview { CalculateView() }` — ha Xcode Canvas hibát mutat (missing
  EnvironmentObject), javítás: `CalculateView().environmentObject(SunTimesService())`.

**SUN-1-A — LEZÁRVA, commitolva (`86d0846`, build-fix `fef76d5`)**
- `countdownApp.entitlements`, `SunTimes.swift`, `SunTimesService.swift` — ld. Session 27.

### Következő feladat: SUN-1-C
`SunPanel.swift` — a teljes popover UI. Cserére kerül a jelenlegi placeholder
`sunPopoverContent` a `CalculateView`-ban (vagy `SunPanel` saját View-ként
illeszt a popoverbe). Tartalom: 4 szekció az alábbi elrendezésben:
```
☀️  MORNING              🌆  EVENING
   First light               Sunset
   Dawn                      Dusk
   Sunrise                   Last light

⚖️  DAY                  🌙  MOON
   Solar noon                Moonrise
   Day length                Moonset
                             Phase + illumination
📷  GOLDEN / BLUE HOUR
   Morning golden  HH:mm–HH:mm
   Morning blue    HH:mm–HH:mm
   Evening golden  HH:mm–HH:mm
   Evening blue    HH:mm–HH:mm
```
Stílus: `AppTheme.calculateBackground` háttér, `AppTheme.background` (amber)
fontos időpontok, Alien League Bold számok, Alien League feliratok, `Color.white.opacity(0.5)`
másodlagos szöveg. Popover tetején `sun.svg` illusztráció (duotone SUN-1-D, egyelőre
színező nélkül, szürke változat is rendben). `todaySunTimes: SunTimes?` binding
vagy paraméterként jön le a `CalculateView`-ból.

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
