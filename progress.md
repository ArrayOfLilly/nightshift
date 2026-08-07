# countdownApp — Progress

## Session 15 — 2026-08-07

### Completed
- **Free-slot kézi színválasztó implementálva** — `AppTheme.swift`, `CountdownItem.swift`,
  `CountdownDetailView.swift`, `CountdownRowView.swift`, `ColorPickerSheet.swift` (új fájl).
  - `AppTheme.freeColors`: mind a 11 szín uncommentálva (korábban csak 1 aktív volt).
  - `CountdownItem`: `accentColorIndex: Int?` mező hozzáadva (nil = auto hash-fallback,
    backward compatible Codable decode).
  - `CountdownDetailView`: `showColorPicker: Bool` state + ecset (`paintbrush`) gomb a
    trash elé, csak expired slotokon látható; `.sheet(isPresented:)` nyitja a picker sheetet.
  - `CountdownRowView`: `itemFreeColor` mostantól `item.accentColorIndex`-et használja,
    ha set; egyébként marad a hash-alapú fallback.
  - `ColorPickerSheet` (új fájl): sheet view, 4 oszlopos `LazyVGrid` a 12 swatchnak
    (11 palettaszín + 1 AUTO/reset). Kiválasztás után dismiss. Tematika: amber háttér,
    Alien League Bold cím, `.focusable(false)` minden gombon.
- **spec.md frissítve** — Free-slot kézi színválasztó szekció "implementált"-ra átírva.
- Files changed: `AppTheme.swift`, `CountdownItem.swift`, `CountdownDetailView.swift`,
  `CountdownRowView.swift`, `ColorPickerSheet.swift` (új)

### Open tasks
- None.

---

## Session 14 — 2026-08-07

### Completed
- **CalculateView háttérszín** — `AppTheme.swift`, `CalculateView.swift`.
  Új `AppTheme.calculateBackground = #060503` (majdnem fekete, minimális meleg tinta).
  `AppTheme.dark` érintetlen — csak a CalculateView `.ignoresSafeArea()` háttere váltott.
- Files changed: `AppTheme.swift`, `CalculateView.swift`

### Open tasks
- None.

---

## Session 13 — 2026-08-07

### Completed
- **CRASH FIX — FocusBridge további források** — `CountdownView.swift`, `AddCountdownSheet.swift`.
  Két további focusable elem maradt:
  1. `NavigationLink` macOS-on Button-ként vesz részt a key view loopban — a CountdownView
     aktív és free sorainál egyik sem kapott `.focusable(false)`-t. Fix: mindkét
     NavigationLink-re hozzáadva.
  2. Az `AddCountdownSheet` stepper 10 chevron gombja szintén maradt `.focusable(false)`
     nélkül. Fix: hozzáadva mindkettőre.
- Files changed: `CountdownView.swift`, `AddCountdownSheet.swift`

### Open tasks
- None.

---

## Session 12 — 2026-08-07

### Completed
- **CRASH FIX — FocusBridge a CountdownRowView toggle gombjától** —
  `CountdownRowView.swift`.
  A toggle gomb `.buttonStyle(.plain)` volt, de `.focusable(false)` nem — így benne
  maradt a SwiftUI key view loopban. A `TimelineView(.periodic(from: .now, by: 1.0))`
  másodpercenként újrarendereli az összes aktív sort, ami másodpercenként triggerelte
  a FocusBridge-et minden látható toggle gombra → KeyViewProxy window-mismatch crash.
  Fix: `.focusable(false)` hozzáadva a toggle Button-hoz.
- Files changed: `CountdownRowView.swift`

### Open tasks
- None.

---

### Completed
- **CRASH FIX (complete) — FocusBridge KeyViewProxy window-mismatch** —
  `CountdownDetailView.swift`.
  Session 10's fix was incomplete: it removed `@FocusState` (correct) but left two
  additional FocusBridge triggers intact.

  **Trigger 1 — `makeFirstResponder` async dispatch in `FocusedNSTextField.updateNSView`:**
  Calling `nsView.window?.makeFirstResponder(nsView)` (even via `DispatchQueue.main.async`)
  causes AppKit to notify SwiftUI's hosting infrastructure via the responder-chain
  observation path. SwiftUI then calls `FocusBridge.moveFocus`, which tries to validate
  a `KeyViewProxy` that is not yet attached to any window → "different window (null)".
  Fix: removed the `makeFirstResponder` dispatch and the `didRequestFocus` Coordinator
  property entirely. The user already tapped the label to enter edit mode; clicking into
  the NSTextField to type is acceptable UX.

  **Trigger 2 — focusable `Button` elements in the key view loop:**
  `.buttonStyle(.plain)` on macOS does NOT remove focusability. All 13 buttons in
  CountdownDetailView (copy, 10× stepper chevrons, toggle, delete) participated in the
  SwiftUI key view loop. When the NavigationLink destination is first rendered before
  being attached to a window, SwiftUI attempts to assign the initial key view loop first
  responder via FocusBridge → same "different window (null)" error.
  Fix: added `.focusable(false)` to every button in CountdownDetailView.
- Files changed: `CountdownDetailView.swift`

### Open tasks
- None.

---

## Session 11.1 — 2026-08-07

### Completed
- **BUG FIX — stepper nincs vizuális visszajelzés szerkesztés közben** —
  `CountdownDetailView.swift`.
  Root cause: `@Binding var item` write (`item.deadline = newDate`) eljut a CountdownView-ba
  és frissíti `items[idx]`-et, de macOS NavigationStack destination esetén SwiftUI nem
  garantálja az azonnali re-rendert a detail view-ban. A stepper értékek csak kilépés
  után frissültek (amikor CountdownView újrarenderelte a sort és visszajött a binding).
  Fix: `@State private var localDeadline: Date` hozzáadva mint lokális tükör.
  `component()` és `monthAbbrev()` ebből olvas (azonnali @State re-render).
  `adjust()` mindkettőt írja: `localDeadline` a vizuális visszajelzésért,
  `item.deadline` a binding-on keresztüli perzisztenciáért.
  `.onAppear` mindkettőt szinkronizálja (snap + sima eset).
- Files changed: `CountdownDetailView.swift`

### Open tasks
- None.

---

## Session 10 — 2026-08-07

### Completed
- **CRASH FIX (partial) — FocusBridge KeyViewProxy window-mismatch** — `CountdownDetailView.swift`:
  root cause: `@FocusState private var labelFocused: Bool` inside a NavigationLink
  destination on macOS causes SwiftUI's `FocusBridge` to attempt AppKit first-responder
  assignment on every render pass (TimelineView tick, toggle, layout) before the view is
  attached to a window — producing `Setting KeyViewProxy as first responder but it is in
  a different window (null)`. The crash triggered on any state change, including the
  "Show Remaining / Show Deadline" toggle.
  Fix: removed `@FocusState` entirely; replaced the SwiftUI `TextField + .focused()`
  combo with `FocusedNSTextField` (`NSViewRepresentable` wrapping `NSTextField`). AppKit
  manages its own first-responder lifecycle and does not go through FocusBridge. First
  responder was requested via `DispatchQueue.main.async { nsView.window?.makeFirstResponder }`
  — but this itself triggered FocusBridge (see Session 11 fix above).
- Files changed: `CountdownDetailView.swift`

### Open tasks
- None.

---

## Session 9 — 2026-08-07

### Completed
- **Moon strip responsive sizing** — `CalculateView.swift`: macOS-only app; replaced
  `GeometryReader` + `ScrollView` approach with a plain `HStack(spacing: 12)` where each
  image has `.frame(maxWidth: .infinity)`. SwiftUI distributes the available width equally
  among all 9 images automatically — no manual calculation, no padding mismatch, resizes
  correctly as the macOS window changes size.
- **Free-slot deadline stepper — defensive adjust() fix** — `CountdownDetailView.swift`:
  added second snap guard directly inside `adjust()`: if `item.isExpired` at call time, snap
  `base = Date()` before applying the delta. This is a fallback for cases where `.onAppear`
  did not fire (macOS NavigationLink timing edge case). Both `.onAppear` and `adjust()` now
  independently guarantee a sane base, so the stepper is reliably editable from first tap.
- Files changed: `CalculateView.swift`, `CountdownDetailView.swift`

### Open tasks
- None.

---

## Session 8 — 2026-08-07

### Decisions (user, closed — no further action)
- **Swipe-to-delete in list**: not needed — was tried before and deliberately removed;
  delete stays DetailView-only. Closed.
- **Tap-to-edit label in list**: intentional as-is — tapping the label in the list
  copies it; editing stays DetailView-only. Closed.

### Completed
- **CalculateView moon strip replaced** — the 4-image fixed HStack ("01 full moon" …
  "04 lunar eclipse", Moon v1 set) swapped for the pink moon series in
  `Assets.xcassets/Moon 3/` (`pink_moon_1` … `pink_moon_9`, 9 images). Now rendered in
  a horizontal `ScrollView` (`HStack(spacing: 18)`, `ForEach(1...9)`, frame width 90,
  opacity 0.85) since 9 elements no longer fit a fixed-width Spacer-separated HStack.
- **BUG FIX — free-slot deadline uneditable in DetailView**: root cause was
  `component(_:)` / `adjust(_:by:)` in `CountdownDetailView.swift` recomputing
  `Date()` as the base on *every* call while the item was still expired, instead of
  once — so any adjustment that didn't push the deadline into the future in a single
  step (e.g. decrementing, or small increments) was silently discarded on the next
  render. Fix: added `.onAppear` that snaps `item.deadline = Date()` once if the item
  is expired on entry; `component()`/`adjust()` now read/write `item.deadline`
  directly, no more per-call `Date()` fallback. Free and active slots now behave
  identically once inside DetailView.
- Files changed: `CalculateView.swift`, `CountdownDetailView.swift`

### Open tasks
- None carried forward from Session 7 (both closed by user decision above).

---

## Session 7 — 2026-08-07

### Completed
- **Free slot manual reorder implemented** — CountdownView.swift teljesen atirva:
  - `@State private var freeOrder: [UUID]` — kezi sorrend tarolasa
  - `@State private var draggingID: UUID?` — aktiv huzas kovetese
  - `activeItems(at:)` — nem-lejart elemek deadline ASC sorrendben
  - `orderedFreeItems(at:)` — lejart elemek `freeOrder` alapjan, hianyzok ABC-vel kozvetve
  - `binding(for:)` helper — computed list sorokhoz Binding<CountdownItem>
  - `.onDrag` + `.onDrop(of: [.plainText], delegate:)` minden szabad soron
  - `FreeSlotDropDelegate` (private struct) — `dropEntered` live preview, `performDrop` cleanup
  - `saveFreeOrder()` / `loadFreeOrder()` — UserDefaults "freeSlotOrder" key, invalid UUID-k szurve
  - Active sorok: drag nincs, automatikus sorrend marad
  - Design nem valtozot — CountdownRowView erintetlen, csak mozgato elemek kerultek be
- **spec.md frissitve** — Manual Free-Slot Reorder szekcioval, freeSlotOrder persistence key felveve
- **progress.md frissitve** — Session 7 completed dokumentalva
- **Git commit** — inner Xcode project repo (Session 7 drag-to-reorder implementacio)

### Open tasks (next session)
- Swipe-to-delete alternativa (ha kell a listaban is)
- Tap-to-edit label (jelenleg csak CountdownDetailView-ban szerkesztheto)

---

## Session 6 — 2026-08-07

### Completed
- **Pencil icon removed** — `Image(systemName: "pencil")` + foregroundStyle + frame torolve
- **Toggle kor hozzaadva** — toggle gomb `.background(AppTheme.dark).clipShape(Circle())` keretbe kerult,
  ikon szine `AppTheme.background` (amber), meret 28x28
- **Pill vertical padding csokkentve** — `.padding(.vertical, 8)` -> `.padding(.vertical, 4)`

### Open tasks (next session — carried forward)
- Swipe-to-delete alternativa (ha kell a listaban is)
- Tap-to-edit label (jelenleg mindig szerkesztheto TextField)

---

## Session 5 — 2026-08-07

### Completed (handoff continuation, follow-up fixes)
- **Pill vastagsag csokkentve** -- CountdownRowView: `.padding(14)` -> `.padding(4)`
- **Toggle gomb kikerult a pill-bol** -- navigacios link mellett, accent szinen ul
- **Detail nezet alapertelmezett remaining time** -- lokalis `@State showRemaining = true`
- **Teljes sor egy pill-be vonva** -- label, copy, toggle, ceruza mind sotet pill-en
- **Row label pill korrigalva** -- `RoundedRectangle(cornerRadius: 10)`, label + copy ikon
- **CountdownRowView label pill (elso verzio)** -- Capsule(), feherrel, kesobb korrigalva
- **Add gomb disabled kontraszt** -- disabled: `Color.white.opacity(0.8)`, enabled: amber
- **Tab valto lecserelve** -- nativ Picker -> sajat HStack modeButton-okkal
- **Ikon-hozzarendeles felcserelve** -- calculate: clock, countdown: at
- **CountdownRowView label pill** -- sotet pill, `AppTheme.dark` hatter, konzisztens DetailView-val

### Completed (earlier sub-sessions)
- **AddCountdownSheet focus ring eltavolitva** -- `.focusable(false)`
- **Account name pill visszaallitva** -- `.padding(.horizontal, 20)` + `.padding(.vertical, 10)`
- **Countdown lett az alapertelmezett nezet** -- `selectedMode` init `.countdown`

---

## Session 4 — 2026-08-07

### Completed
- Per-account free color → single color `#593C73` (AppTheme.freeColor)
- FREE ✓ badge inline a label sorában (egy sor, nem kettő)
- Deadline szerkesztés: ceruza gomb → 5 komponenses stepper CountdownDetailView-ban
- Alapértelmezett deadline: Date() (most), nem +24h
- macOS build fixek: navigationBarTitleDisplayMode, toolbarBackground, onChange deprecated signature
- TextField foregroundColor fix (foregroundStyle nem működik macOS TextFielden)
- Paradicsom méret: 300 → 420px; Account label méret: 28 → 36pt

---

## Session 3 — 2026-08-07

### Completed
- FREE SLOT HIGHLIGHT: `AppTheme.freeGreen`, zold hatter, feher fg, glow shadow, "FREE ✓" badge
- Files changed: `AppTheme.swift`, `CountdownRowView.swift`, `spec.md`, `progress.md`

---

## Session 1+2 — 2026-08-07

### Completed
- Calculate mode: mukodik (date/time diff, from/to pickers)
- Countdown mode architektura: CountdownView, CountdownDetailView, CountdownRowView,
  AddCountdownSheet, CountdownItem model (Codable, Equatable, Identifiable)

### Manual Xcode steps STILL NEEDED
- [ ] Assets.xcassets: add spooky_tomato.png (name: "spooky_tomato")
- [ ] Drag 4 alienleague .ttf into Xcode (Copy + target membership)
- [ ] Info.plist: "Fonts provided by application" array with 4 filenames
- [ ] Project Navigator: Add Files → select all new .swift files
- [ ] Verify Alien League PostScript name in Font Book
