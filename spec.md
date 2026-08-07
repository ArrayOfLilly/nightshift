# countdownApp — Specification

## App Structure

Two modes switched via a custom HStack tab bar (ContentView):
- **Calculate** — compute time difference between two dates/times (clock icon)
- **Countdown** — list of named countdowns with deadlines (@ icon)

Selected tab: filled dark Circle behind icon; unselected: icon at opacity 0.45.
Default tab on launch: Countdown.

---

## Calculate Mode (COMPLETE)

- Dark brown (`AppTheme.dark`) background; amber (`AppTheme.background`) text/icons
- Transparent elements use `Color.white.opacity(X)` (NOT amber-opacity)
- From / To date+time pickers via component stepper (YEAR/MON/DAY/HOUR/MIN)
- Shows elapsed (past) or remaining (future) time
- Format: `Nd  Nh  Nm  Ns`
- Moon phase illustration strip at bottom: pink moon series from `Assets.xcassets/Moon 3/`
  (`pink_moon_1`–`pink_moon_9`, 9 images), horizontal `ScrollView`

---

## Countdown Mode (COMPLETE — sessions 1–6)

### Screen A: List (CountdownView)
- NavigationStack root; amber background
- ScrollView + LazyVStack (spacing 10); NOT a native List
- Rows sorted: active (not expired) first by deadline ASC, expired (free) after
- **Manual reorder of free slots** (Session 7): expired rows support drag-to-reorder;
  manual order takes priority over alphabetical fallback
- Each row: CountdownRowView — taps → CountdownDetailView
- "+ ADD" button at bottom → AddCountdownSheet
- **Free slots** (`deadline < now`): per-item accent color from `AppTheme.freeColors`
  (11-color list, index = `abs(item.id.hashValue) % 11`); card shows "FREE ✓" badge
  right of the label pill; colored glow shadow; no time text shown
- **Active slots**: `cardSurface` background; toggle button (calendar/clock icon) right
  of label pill; time or deadline below

### CountdownRowView layout (actual code)
- Outer: `VStack(alignment: .leading, spacing: 6)` with `.padding(16)` and accent bg
- Top HStack:
  - Left: dark pill (`AppTheme.dark` bg, `RoundedRectangle(cornerRadius: 5)`) containing
    label text (`Color.white.opacity(0.8)`) + `simultaneousGesture` copy tap
  - Right: "FREE ✓" text (expired) OR toggle button (non-expired)
- Toggle button: `RoundedRectangle(cornerRadius: 7)`, `Color.white.opacity(0.12)` bg,
  `AppTheme.dark.opacity(0.85)` fg icon, frame 42×28
- Bottom (non-expired only): time/date text on the accent background below the pill

### Free-slot deadline editing (Session 8 fix)
- On `.onAppear`, if the item is expired, `item.deadline` is snapped to `Date()` once;
  from then on the stepper reads/writes `item.deadline` directly (no more per-call
  `Date()` fallback while expired, which previously discarded edits that didn't clear
  the "still in the past" threshold in one step)

### Screen B: Detail (CountdownDetailView)
- Full-screen "Spooky Tomato" design (matches timer.png reference):
  - Amber background (#E4A120 approx)
  - Account label at top in Alien League Bold, kerned, uppercased, inside dark Capsule pill
  - spooky_tomato.png centered (500px), countdown text overlaid on the tomato belly
  - Toggle button (dark brown pill): "Show Deadline" ↔ "Show Remaining"
  - Always opens with remaining time (local `@State`, independent of row toggle state)
- Remaining view: `DD:HH:MM:SS` ticking every second via TimelineView
- Deadline view: `YYYY.MM.DD HH:mm` static
- Delete (trash icon, `AppTheme.dark` bg) in the detail view; no delete in list rows

### Data Model (CountdownItem)
- `id`            UUID    — stable identity
- `label`         String  — e.g. "GPT-4 Free"
- `deadline`      Date    — when the account/resource resets
- `showRemaining` Bool    — row-level toggle state (persisted per item)

### Persistence
- UserDefaults + JSONEncoder / JSONDecoder
- Key `"countdownItems"` → `[CountdownItem]` JSON
- Key `"freeSlotOrder"` → `[String]` (UUID strings); loaded after items; invalid IDs pruned

---

## Manual Free-Slot Reorder (Session 7)

- Only expired rows are reorderable (active rows keep auto-sort by deadline ASC)
- Mechanism: `.onDrag` + `.onDrop(of: [.plainText], delegate:)` on each free row
- `FreeSlotDropDelegate` (private struct in CountdownView): reorders `freeOrder` in
  `dropEntered` for live preview; clears `draggingID` on `performDrop`
- `freeOrder: [UUID]` drives render order; IDs not in `freeOrder` append alphabetically
- Saved to UserDefaults on every `freeOrder` change; loaded (with item-validity filter) on appear

---

## Jövőbeli ötletek

### Stepper long-press repeat (IMPLEMENTÁLT — Session 16)
- Érintett fájl: `CountdownDetailView.swift` (componentStepper helper)
- Jelenlegi viselkedés: minden chevron gomb egyetlen `Button`, egyet lép kattintásra.
- Kívánt viselkedés: nyomva tartásra ismételje a lépést, de az első kattintás
  (rövid tap) még mindig csak egyet lépjen — tehát a standard "initial delay then
  repeat" pattern.
- Javasolt implementáció: cseréljük a `Button`-t egy `simultaneousGesture`-t használó
  nézetté, amely `.onLongPressGesture(minimumDuration:, pressing:perform:)` segítségével
  indít egy `Timer.scheduledTimer`-t (pl. 0.4s initial delay után, majd ~0.1s interval),
  és `onEnded` / `pressing == false` állapotban törli a timert.
  Alternatíva: külön `LongPressStepperButton` `@ViewBuilder` komponens, hogy a
  `componentStepper` helper tiszta maradjon.
- Az initial delay értéke nincs meghatározva — kb. 0.4–0.5s szokásos (macOS
  kulcsismétlési késedelemhez hasonló), de kísérletezni kell.

### Calculate oldal — állapotmegőrzés + Reset gomb (IMPLEMENTÁLT — Session 16)
- Érintett fájl: `CalculateView.swift`
- Jelenlegi viselkedés: a From/To stepper értékek minden megnyitáskor resetelnek
  (nincs perzisztencia).
- Kívánt viselkedés 1 — állapotmegőrzés: az utoljára beállított From és To értékek
  megmaradjanak alkalmazás-újraindítás után is. Javasolt: `@AppStorage` vagy
  `UserDefaults` a két `Date` érték TimeInterval-ként tárolva.
- Kívánt viselkedés 2 — Reset gomb: a To stepper alatt (vagy mellette) legyen egy
  reset gomb, amely a To értékét `Date()` (now)-ra állítja. Vizuálisan illeszkedjen
  a meglévő stepper designhoz (dark bg, amber ikon/szöveg, RoundedRectangle).
  From értéket NE érintse a reset.

### Free-slot kézi színválasztó (IMPLEMENTÁLT — Session 15)
- `AppTheme.freeColors`: mind a 12 szín aktív (778005 · 51422E · 30271B · 293B72 ·
  4D70D8 · 403873 · 593C73 · 8A4273 · 723F73 · DD3B72 · DD114A · B70E26).
- `CountdownItem.accentColorIndex: Int?` — nil = auto hash-fallback, set = kézi szín.
- `CountdownDetailView`: paintbrush gomb (trash előtt, csak expired slotokon) nyit
  egy `ColorPickerSheet`-et.
- `ColorPickerSheet` (új fájl): 4 oszlopos LazyVGrid, 11 paletta + AUTO swatch,
  kiválasztás után dismiss. Amber háttér, Alien League Bold cím.
- `CountdownRowView`: `itemFreeColor` `accentColorIndex`-et preferálja, hash-fallback marad.

---

## Manual Xcode Steps Required (one-time setup)

1. In Assets.xcassets: add `spooky_tomato.png` → name it "spooky_tomato"
2. Add moon phase images: "01 full moon", "02 crescent moon", "03 waning moon", "04 lunar eclipse"
3. Drag font files into Xcode project (Copy if needed ✓, target membership ✓):
   - alienleague.ttf, alienleaguebold.ttf, alienleaguebolditalic.ttf, alienleagueital.ttf
4. Info.plist → "Fonts provided by application" (Array) with the 4 filenames
5. Project Navigator → Add Files → add all new .swift files
6. Verify PostScript font name in Font Book if Alien League does not render

---

## File Structure

```
countdownApp/  (Swift source root)
├── AppTheme.swift             — Spooky Tomato colors + font helpers
├── CountdownItem.swift        — Data model
├── ContentView.swift          — Root: mode picker (custom HStack tab bar)
├── CalculateView.swift        — Calculate mode (dark bg, amber text)
├── AddCountdownSheet.swift    — Sheet: add new countdown item
├── CountdownRowView.swift     — Single list row (label pill + time + toggle + FREE badge)
├── CountdownView.swift        — List screen (NavigationStack root, drag-to-reorder)
├── ColorPickerSheet.swift       — Sheet: free-slot accent color picker
├── LongPressStepperButton.swift — Reusable chevron button with tap + hold-to-repeat
├── CountdownDetailView.swift  — Full-screen Spooky Tomato single-item display
└── countdownAppApp.swift      — @main entry point (unchanged)
```
