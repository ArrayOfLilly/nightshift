# countdownApp — Specification

## App Structure

Two modes switched via segmented control at the top:
1. **Calculate** — compute time difference between two dates/times
2. **Countdown** — list of named countdowns with deadlines

---

## Calculate Mode (COMPLETE)

- From / To date+time pickers (locale: en_US)
- Shows elapsed (past) or remaining (future) time
- Format: `Nd  Nh  Nm  Ns`

---

## Countdown Mode (COMPLETE — session 1+2)

### Screen A: List (CountdownView)
- NavigationStack root
- Plain list of countdown rows — no tomato image here
- Each row: label + ticking time (or deadline) + toggle icon + X delete
- Tapping a row → navigates to CountdownDetailView
- "+ ADD" button at bottom → AddCountdownSheet
- **Expired / free slots** (`deadline < now`): card background turns `freeGreen`
  (#34C759 approx), text + icons become white, time area shows `"FREE ✓"` in
  Alien League Bold 30pt; card has a soft green glow shadow. Deadline-date toggle
  still works on expired items (shows when the account became free), in white text.

### Screen B: Detail (CountdownDetailView)
- Full-screen "Spooky Tomato" design (matches timer.png reference):
  - Amber background (#E4A120 approx)
  - Account label at top in Alien League Bold, kerned, uppercased
  - spooky_tomato.png centered, countdown text overlaid on the tomato belly
    (y-offset +42pt positions text on the lower body of the tomato)
  - Toggle button (dark brown pill): "Show Deadline" ↔ "Show Remaining"
- Remaining view: `DD:HH:MM:SS` ticking every second via TimelineView
- Deadline view: `YYYY.MM.DD HH:mm` static

### Data Model (CountdownItem)
- `id`           UUID    — stable identity
- `label`        String  — e.g. "GPT-4 Free"
- `deadline`     Date    — when the account/resource resets
- `showRemaining` Bool   — view toggle state (persisted per item)

### Persistence
- UserDefaults + JSONEncoder / JSONDecoder
- Storage key: "countdownItems"

---

## Manual Xcode Steps Required (one-time setup)

1. In Assets.xcassets: add `spooky_tomato.png` → name it "spooky_tomato"
2. Drag font files into Xcode project (Copy if needed ✓, target membership ✓):
   - alienleague.ttf, alienleaguebold.ttf, alienleaguebolditalic.ttf, alienleagueital.ttf
3. Info.plist → "Fonts provided by application" (Array) with the 4 filenames
4. Project Navigator → Add Files → add all new .swift files
5. Verify PostScript font name in Font Book if Alien League does not render

---

## File Structure

```
countdownApp/  (Swift source root)
├── AppTheme.swift             — Spooky Tomato colors + font helpers
├── CountdownItem.swift        — Data model
├── ContentView.swift          — Root: mode picker only
├── CalculateView.swift        — Calculate mode
├── AddCountdownSheet.swift    — Sheet: add new countdown item
├── CountdownRowView.swift     — Single list row (label + time + toggle + delete)
├── CountdownView.swift        — List screen (NavigationStack root)
├── CountdownDetailView.swift  — Full-screen Spooky Tomato single-item display
└── countdownAppApp.swift      — @main entry point (unchanged)
```
