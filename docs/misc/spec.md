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
  (12-color list; default index 6 / #593C73 purple unless overridden); card shows "FREE ✓" badge
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
- `accentColorIndex` Int? — manual free-slot color override (nil = default index 6 / #593C73)

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

## Implemented Enhancements (Sessions 15–16)

### Stepper long-press repeat (Session 16)
- File: `CountdownDetailView.swift` / `CalculateView.swift` (componentStepper helper),
  `LongPressStepperButton.swift` (new).
- Each chevron button fires once on a short tap; holding it repeats the step after
  an initial delay (0.40s), then every 0.08s until released.
- Implemented via `LongPressStepperButton`, a `DragGesture(minimumDistance: 0)`-based
  view (see that file's header for why `DragGesture` was used instead of
  `LongPressGesture`).

### Calculate mode — state persistence + NOW reset (Session 16)
- File: `CalculateView.swift`.
- From/To values persist across app restarts via `@AppStorage` (stored as
  `TimeInterval`), instead of resetting to `Date()` on every open.
- A `NOW` button next to the "TO" label resets only the To value to the current
  time; From is untouched.

### Free-slot manual accent color (Session 15)
- All 12 `AppTheme.freeColors` swatches are active (previously only 1).
- `CountdownItem.accentColorIndex: Int?` — `nil` = default color (index 6, #593C73
  purple), set = user's manual choice. Backward-compatible with old saved items
  (decodes as `nil` if absent).
- `CountdownDetailView`: a paintbrush button (visible only on expired/free slots,
  placed before the trash icon) opens `ColorPickerSheet`.
- `ColorPickerSheet` (new file): 4-column `LazyVGrid`, the 12 palette colors plus
  one AUTO/reset swatch; picking a color dismisses the sheet.
- `CountdownRowView`: `itemFreeColor` uses `item.accentColorIndex` when set,
  otherwise falls back to the fixed default (index 6, #593C73).

---

## Performance — Beachballing Fix (Sessions 17–20)

Symptom: the app would beachball (main-thread stall) during sustained use, most
reproducibly when a slot switched between active/free or when free slots were
reordered by drag.

Four compounding root causes were found and fixed in `CountdownView.swift` /
`CountdownItem.swift` / `CountdownRowView.swift`:

1. **N per-row timers (Session 17).** Every `CountdownRowView` had its own
   `TimelineView(.periodic(from: .now, by: 1.0))`. With N rows, N independent
   1Hz timers each triggered a full `CountdownView.itemList` recomputation.
   Fix: a single `TimelineView` lives at the `CountdownView.itemList` level;
   `now: Date` is passed down to each row, which has no timer of its own.
2. **Eager NavigationLink destination construction (BUG-18, Session 18–19).**
   `NavigationLink { CountdownDetailView(...) }` evaluates the destination
   closure on every render pass — so every row's detail view was allocated and
   immediately deallocated on every 1Hz tick, whether or not the user had
   navigated anywhere. Fix: `NavigationLink(value:)` + `.navigationDestination
   (for: CountdownItem.self)` — the destination is now only constructed on an
   actual navigation. Required adding `Hashable` conformance to `CountdownItem`.
3. **Stale index binding after reclassification (BUG-19, Session 19).** The
   `.navigationDestination` closure captured `$items[idx]` with `idx` fixed at
   navigation time. If a deadline edit moved the item between the active/free
   lists afterward, `idx` no longer pointed at the right element and edits
   stopped propagating. Fix: a `binding(for: item)` helper that always resolves
   against the live `items` array by ID instead of a captured index.
4. **Stale row appearance after reclassification (BUG-20, Session 19).** Both
   `ForEach` loops (active/free) used the same `item.id` UUID as SwiftUI
   identity. When an item moved from free to active, SwiftUI recycled the
   existing `CountdownRowView` under that UUID instead of creating a new one,
   so the old "free" appearance (accent color, FREE badge, no toggle) stuck.
   Fix: a private `RowEntry` wrapper carries `item` + `slotKind` (`"a"`/`"f"`);
   its `id` is `"\(slotKind)-\(item.id)"`. Both lists are now rendered from one
   `ForEach(entries)`, so a reclassification changes the identity and forces a
   fresh view.

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
