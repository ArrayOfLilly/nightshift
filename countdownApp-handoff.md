# countdownApp — handoff a következő chat-hez

## Working setup
- Filesystem MCP-n keresztül dolgozunk. Szerializáltan olvasd a fájlokat.
- Filesystem:write_file teljes fájl felülírással működik, NEM appendál — mindig read-then-write.
- Header/komment: angolul, semmi magyar szöveg a kódban.
- progress.md frissítése + git commit minden session végén.
- **Inner kódrepo**: `/Users/ArrayOfLilly/tools/countdownApp/countdownApp/`
  Swift forrás: `countdownApp/countdownApp/countdownApp/` alatt.
- Olvasd el először a `progress.md`-t.

## Jelenlegi állapot (Session 31 végén)

**BUG-SOUND-1 — LEZÁRVA, commitolva (`892f1ed`)**
- Root cause: Swift synthesized `Decodable` nem használja a property default értékét
  ha a kulcs hiányzik a JSON-ból — `keyNotFound`-ot dob, `try?` csendes `nil` → `items = []`.
- `CountdownItem.swift`: explicit `CodingKeys` + `init(from decoder:)` hozzáadva;
  `decodeIfPresent` + `?? default` fallback minden opcionális mezőre
  (`showRemaining ?? true`, `accentColorIndex ?? nil`, `soundEnabled ?? false`).
- Ez a minta véd jövőbeli mezők hozzáadásakor is — mindig `decodeIfPresent`-et használj
  új opcionális/defaultos mezőkhöz.

**TIME DISPLAY SIZING — LEZÁRVA, commitolva (`db5f054`)**
- `CountdownDetailView.swift`: `ZStack` + fix `frame(maxWidth: 300)` →
  `Image.overlay { GeometryReader }` — a szöveg maxWidth mindig a paradicsom
  tényleges renderelt szélességének 62%-a, soha nem lóg ki.

**SOUND-1 — LEZÁRVA, commitolva (`c04d4a6`)**
- `CountdownItem.swift`: `soundEnabled: Bool = false`
- `CountdownView.swift`: `previousActiveIDs` snapshot + `rebuildCache(playExpirySounds:)`
  + `crossingTask` diff-alapú detekálás → `NSSound(named: "Funk")?.play()`
- `CountdownDetailView.swift`: speaker toggle gomb, minden slot típuson látható

**SUN-1-C — LEZÁRVA** (commit `bf41007` + bugfix-ek)
- `SunPanel.swift`: teljes popover UI, 4 szekció
- `SunTimes.swift`, `SunTimesService.swift`, `CalculateView.swift` — ld. Session 29–30

## Következő feladat: (nyílt, user dönt)

Backlog lehetőségek:
- TTS: a slot nevét felolvassa lejáratkor (SOUND-1 bővítés)
- CoreLocation: automatikus koordináta a SunTimesService-be (SUN-1-E)
- Egyéb új feature

---

## FONTOS: CountdownItem Codable szabály

Soha ne adj hozzá új mezőt a `CountdownItem`-hez anélkül, hogy az `init(from decoder:)`-be
is felveszed `decodeIfPresent` + `?? default` fallback-kel. A synthesized Decodable
nem használja a Swift default property értékeket — hiányzó kulcs = decode fail = üres lista.

**SOUND-1 — LEZÁRVA, commitolva (`c04d4a6`)**
- `CountdownItem.swift`: `soundEnabled: Bool = false` (backward-compatible Codable)
- `CountdownView.swift`: `@State previousActiveIDs: Set<UUID>` snapshot; `rebuildCache`
  kap `playExpirySounds: Bool = false` paramétert; `crossingTask` hívja `true`-val;
  diff-alapú detektálás: `previousActiveIDs` vs `newActiveIDs` → `NSSound(named: "Funk")?.play()`;
  `import AppKit` hozzáadva.
- `CountdownDetailView.swift`: `speaker.wave.2.fill` / `speaker.slash.fill` toggle gomb
  a bottom buttons HStack-ben (a trash előtt), minden slot típuson látható,
  `.focusable(false)` megvan, írás `@Binding`-on át → automatikus persist.

**SUN-1-C — LEZÁRVA, commitolva (`bf41007`, bugfix-ek `528cc19`, `6a5fc08`, `90b649f`, `345a96a`, `cb0af2b`, `ffcad38`)**
- `SunPanel.swift` (új): teljes popover UI, 4 szekció
- `CalculateView.swift`: placeholder lecserélve `SunPanel`-re
- `SunTimes.swift`: API format fix (12 órás AM/PM, day_length string, moonrise/moonset optional)
- `SunTimesService.swift`: print diagnosztika (maradhat, nem zavaró)
- Popover: `minWidth: 360`, vertical-only padding, purple gradient a tetején
- SUN-1-D (duotone script) — kihagyva, user döntése alapján nem kell

## Következő feladat: (nyílt, user dönt)

Backlog lehetőségek:
- TTS: a slot nevét felolvassa lejáratkor (SOUND-1 bővítés)
- CoreLocation: automatikus koordináta a SunTimesService-be (SUN-1-E)
- Egyéb új feature

---

## SOUND-1 — archívum (kész, Session 30)

### Mit csinált SOUND-1
Egy countdown slot lejáratakor (active → free átsorolás pillanatában) rendszerhang
szólal meg, ha az adott sloton be van kapcsolva. Per-slot toggle a DetailView-ban,
default OFF.

### Érintett fájlok
- `CountdownItem.swift` — új mező
- `CountdownView.swift` — lejárat detektálás + hang lejátszás
- `CountdownDetailView.swift` — toggle UI

### 1. CountdownItem.swift — új mező
```swift
var soundEnabled: Bool = false
```
A meglévő `Codable` decode backward-compatible marad: ha a JSON-ban nincs
`soundEnabled` kulcs, a Swift decoder a default értéket (`false`) használja.

### 2. Lejárat detektálás — CountdownView.swift

`@State private var previousActiveIDs: Set<UUID> = []` snapshot az aktív item
ID-kről. `rebuildCache(now:playExpirySounds:)` — ha `playExpirySounds: true`:
```swift
let newActiveIDs = Set(items.filter { !$0.isExpired(at: now) }.map { $0.id })
let justExpired = items.filter {
    previousActiveIDs.contains($0.id) && !newActiveIDs.contains($0.id)
}
for item in justExpired where item.soundEnabled {
    NSSound(named: "Funk")?.play()
}
previousActiveIDs = newActiveIDs
```
`crossingTask` hívja `rebuildCache(now: Date(), playExpirySounds: true)`-val.
Egyéb hívások (`onAppear`, `.onChange`) maradnak `playExpirySounds: false`-sal.

**Hang**: `NSSound(named: "Funk")?.play()` — beépített macOS rendszerhang,
sandbox-biztos, nem kell entitlement. Alternatívák: `"Ping"`, `"Glass"`, `"Pop"`.

**Import**: `import AppKit` a `CountdownView.swift` tetején.

### 3. CountdownDetailView.swift — toggle UI

```swift
Button {
    item.soundEnabled.toggle()
} label: {
    Image(systemName: item.soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
        .font(.system(size: 16))
        .foregroundStyle(item.soundEnabled ? AppTheme.background : AppTheme.background.opacity(0.4))
        .frame(width: 44, height: 44)
        .background(item.soundEnabled ? AppTheme.dark : AppTheme.dark.opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: 9))
}
.focusable(false)
```

---

## Korábbi állapot (Session 29 végén)

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

## Érintett fájlok (minden commitolva Session 30-ig)
- `CountdownItem.swift` — SOUND-1 (`c04d4a6`)
- `CountdownView.swift` — SOUND-1 (`c04d4a6`), beachball fixek (`07861a9`)
- `CountdownDetailView.swift` — SOUND-1 (`c04d4a6`)
- `CalculateView.swift` — CALC-1 (`525ed86`), toggle refactor (`2f99646`)
- `LongPressStepperButton.swift` — 23-D (`8b2035b`)
- `SunPanel.swift` — SUN-1-C (`bf41007`)
- `SunTimes.swift` — SUN-1-A (`86d0846`)
- `SunTimesService.swift` — SUN-1-A (`86d0846`)
