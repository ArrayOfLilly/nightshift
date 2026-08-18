# NightShift (countdownApp) — Architecture

Developer-facing reference. For session-to-session state see `countdownApp-handoff.md`;
for development policy (what requires discussion before implementing, concurrency rules,
docs discipline) see `Claude.md`. This file documents how the app is actually built.

---

## 1. Overview

**NightShift** (repo/product name `countdownApp` — the rename to "NightShift" is formalized
in the UI but not yet in the Xcode project/bundle identifiers, see ENH-DEVDOCS-2) is a macOS
SwiftUI personal tool for managing late-night side-project development sessions:

- **Countdown tab** — tracks cooldowns of free AI model/account tiers (Claude, Codex, ChatGPT,
  DeepSeek, Qwen, Kimi, etc.) so the user knows when each one frees up again.
- **Calculate tab** — computes time until sunrise (via `SunTimesService`), i.e. how much of
  the night's work window is left, plus a general date/time delta calculator with save-able
  named deadlines.
- **Snippets tab** — markdown-bodied, project-tagged text blocks for session handoff notes
  (copy-paste into a fresh AI session).

### Entry point and scenes

`App/countdownAppApp.swift` is the `@main` entry point. It:

- Registers the bundled Alien League font files with CoreText at process scope (`registerBundledFonts()`).
- Self-heals the `AppleLanguages` override on every launch (`AppKeys.syncAppleLanguagesOverride()`).
- Declares four scenes:
  - Main `WindowGroup { ContentView() }` — fixed content size, wraps the mode switcher.
  - `Settings { SettingsView() }` — Cmd+, preferences window (language, locale, font size).
  - `WindowGroup(id: AboutWindowID.id) { AboutView() }` — custom About panel.
  - `WindowGroup(id: HelpWindowID.id) { HelpView() }` — Cmd+Shift+/ help window.
- In `#if DEBUG`, adds a "Debug" command menu (Cmd+Shift+D) that injects fake corrupted-data
  fragments for testing the recovery banners without needing real corrupt storage.

`Views/ContentView.swift` owns the top-level mode switcher (`Mode: .calculate / .countdown /
.snippets`), a custom `HStack` of buttons (not the native `Picker`, because `NSSegmentedControl`
ignores SwiftUI styling). It measures its own natural width via a `PreferenceKey`
(`ModeSwitcherWidthKey`) and feeds that into the window's `minWidth`/`maxWidth` so the window
grows correctly at larger font-size steps or longer localized labels.

---

## 2. Module responsibilities

```
App/          Entry point, scenes, centralized UserDefaults key registry, debug notifications
Components/   Small reusable view pieces shared across tabs
Models/       Codable data types + their persistence (load/save) extensions
Services/     Non-UI logic: date formatting, sun/moon time calculation, window helpers
Theme/        AppTheme — single source of design tokens (colors, fonts, radii, alpha values)
Views/        One subfolder per tab/area, plus shared top-level views (ContentView, AboutView)
```

### App/

- `AppKeys.swift` — **every** `UserDefaults` key used anywhere in the app must be declared here
  as a `static let`; raw string literals for keys are not allowed elsewhere (Claude.md rule).
  Also hosts `syncAppleLanguagesOverride()` and the recovery helper `appendCorruptFragments(_:)`.
- `countdownAppApp.swift` — see §1.
- `HelpCommands.swift` / `HelpWindowID.swift` — Help menu command + window scene identifier
  (the analogous `AboutCommands`/`AboutWindowID` live inline near `AboutView.swift`).

### Components/

Presentation-only pieces with no persistence of their own, reused across multiple Views:
`ComponentStepper` (labeled +/- stepper used by Calculate and Countdown detail screens),
`LongPressStepperButton` (the individual +/- button, supports press-and-hold repeat),
`CopyButton`, `NativeTooltip` (AppKit `NSView.toolTip` bridge — used where SwiftUI's `.help()`
tracking-area doesn't register, e.g. over a `.popover()`), `SharedEditorComponents` (markdown
editor/preview pieces used by Notes and Snippets), `HelpScreenshot` (renders a pre-cropped
screenshot asset at a consistent size inside Help items), `FocusedNSTextField`.

### Models/

Each model is a `Codable` struct with a custom `init(from:)` (see §3) plus a `Persistence`
extension providing `static func load()` / `static func save(_:)`:

- `CountdownItem` — a single cooldown/deadline slot (label, deadline, `notes`, `soundEnabled`,
  manual `accentColorIndex`). Helpers for expiry/remaining-time formatting live on the struct itself.
- `Snippet` — title/body/project-tagged text block. `project` is a `ProjectCategory`, not a raw
  `String` (see below). `Snippet.committed(from:title:body:project:)` is the single factory used
  by the edit sheet to build a persistable value from raw editor state.
- `NamedDeadline` — a saved "TO" date from the Calculate tab.
- `ProjectCategory` — `enum { case general, case custom(String) }`. Introduced (Session CU) to
  stop storing the English literal `"General"` as if it were just another project tag; encodes
  as the canonical, locale-independent key `"default_general"`. Legacy JSON containing the raw
  strings `"General"` / `"general"` decodes as `.general` (lazy migration, no bulk rewrite).
  `.localizedName` is UI-only and must never be persisted; `init(userEnteredName:)` is how
  free-form TextField input gets converted back into a category.

### Services/

- `Formatters.swift` — shared `DateFormatter` instances (`monthAbbrev`, `deadline`,
  `deadlineCompact`); reads a private `effectiveLocale` derived from `AppKeys.preferredLocale`
  at static-let init time (so a locale change takes effect after restart, not live).
- `SunTimes.swift` / `SunTimesService.swift` — sunrise/sunset/moon-phase calculation consumed
  by `SunPanel` (Calculate tab); `SunTimesService` is the `@StateObject` injected as an
  `environmentObject` from `countdownAppApp`.
- `WindowHelpers.swift` — small AppKit/NSWindow utility helpers.

### Theme/

`AppTheme.swift` is the single source of truth for colors, the two custom font families
(Alien League decorative / semantic system fonts), corner radii, and the alpha-value tokens
(`alpha50`, `alpha75`, `alpha90`, …) used for opacity throughout the UI instead of raw literals.

### Views/

One folder per tab (`Calculate/`, `Countdown/`, `Snippets/`), plus `Help/` and `Settings/`.
Each tab folder holds its main list/detail view and any sheets specific to that tab (e.g.
`AddCountdownSheet`, `ColorPickerSheet`, `NotesSheet` under `Countdown/`; `DeadlineDetailSheet`,
`SunPanel` under `Calculate/`; `SnippetEditSheet` under `Snippets/`). `ContentView.swift` and
`AboutView.swift` sit at the top level since they're not owned by any single tab.

---

## 3. Persistence layer

All persistent state lives in `UserDefaults.standard`, addressed exclusively through
`AppKeys` constants — there is no file-based or Core Data storage anywhere in the app.
Every persisted collection (`[CountdownItem]`, `[Snippet]`, `[NamedDeadline]`) is JSON-encoded
as a single `Data` blob under one key; there is no per-item key or database.

**The rule that matters most (Claude.md, "Adatmodell szabályok"):** synthesized `Decodable`
does **not** fall back to a property's default value when a JSON key is simply absent — it
throws `keyNotFound`. Combined with `try?` at the decode call site, a single missing/renamed
field would silently turn into `nil` and wipe the entire array. Every model therefore has a
**custom `init(from decoder:)`** that uses `decodeIfPresent(...) ?? default` for every field
that was added after the type's original release. Adding a field to `CountdownItem`, `Snippet`,
or `NamedDeadline` **without** doing this is the single most direct way to cause data loss —
see §5.

`CalculateView`'s own working state (`calculateFromDate`, `calculateToDate`,
`calculateDisplayMode`) is simpler: plain `@AppStorage` properties, since those are scalars,
not `Codable` collections, and don't go through the array-decode path described above.

---

## 4. Recovery infrastructure

Because a whole-array decode failure would previously wipe all items if even one element was
corrupt, `CountdownItem.load()`, `Snippet.load()`, and `NamedDeadline.load()` all follow the
same **per-item recovery** pattern instead of decoding the array directly:

1. Deserialize the top-level `Data` as a raw `[Any]` via `JSONSerialization` (not `JSONDecoder`).
2. Re-serialize and decode **each element individually** with `JSONDecoder().decode(Type.self, from:)`.
3. An element that decodes successfully is appended to the result array.
4. An element that fails is captured as its raw JSON string and collected into `corruptFragments`.
5. After the loop, `AppKeys.appendCorruptFragments(_:)` **appends** (does not overwrite) those
   fragments into the `AppKeys.corruptedDump` UserDefaults array — fragments from `CountdownItem`,
   `Snippet`, and `NamedDeadline` loads all accumulate into the same dump.

`CountdownItem.load(dumpPolicy:)` additionally takes a predicate so callers can decide whether
a given corrupt raw element is worth surfacing at all — `CountdownView` only dumps fragments
whose raw JSON has a non-empty `notes` field, on the theory that an item with no notes and a
broken deadline isn't worth alarming the user about.

**Banner UI:** each list view (`CountdownView`, and equivalently `SnippetsView`) reads
`AppKeys.corruptedDump` into a local `@State private var corruptedFragments: [String]` on
`.onAppear`, and renders a `corruptionBanner` at the top of the list whenever it's non-empty.
The banner offers:
- **Copy raw data** — pretty-prints and copies the fragments to the pasteboard so the user can
  inspect/manually recover the data.
- **Dismiss** — clears `AppKeys.corruptedDump` and the local state.

**Debug support:** in `#if DEBUG` builds only, `countdownAppApp.swift` adds a Cmd+Shift+D menu
item that calls `AppKeys.appendCorruptFragments(_:)` with three fake fragments and posts
`DebugNotifications.injectCorruptBanner`, which the banner-owning views observe via
`.onReceive(...)` to refresh immediately — this exists purely so the banner can be screenshotted
or manually tested without needing to hand-corrupt real `UserDefaults` data.

---

## 5. Adding a new feature

This section is a practical checklist, not a replacement for `Claude.md` — read that first.
`Claude.md`'s "Egyeztetés implementáció előtt" list is binding: new files/types, model changes,
persistence changes, new `@State`/`@StateObject`, new lifecycle hooks, and new dependencies all
require discussion before writing code, not after.

1. **Decide which module owns it** using §2 above. A new tab-specific sheet goes under that
   tab's `Views/<Tab>/` folder; a piece reused by 2+ tabs goes in `Components/`; non-UI logic
   goes in `Services/`.
2. **If it touches persisted data:**
   - Add the `UserDefaults` key to `AppKeys.swift` — never a raw string literal elsewhere.
   - If it's a new field on `CountdownItem`, `Snippet`, or `NamedDeadline`, add it with a
     default value and decode it with `decodeIfPresent(...) ?? default` in that type's
     `init(from:)` — see §3. Do **not** rely on the synthesized `Codable` for these three types.
   - If it's a genuinely new persisted collection, follow the same load/save + per-item-recovery
     shape used by the three existing models (§4) rather than inventing a new pattern.
3. **If it touches concurrency:** new code should use `@MainActor` on views/view-models,
   `async/await` (not `DispatchQueue.main.async`), and `.task(id:)` instead of a bare `Task`
   where the task's lifetime should track the view. Existing pre-Swift-6.3 code is not being
   retrofitted as a side effect of unrelated changes — flag concurrency warnings you notice
   rather than fixing them inline.
4. **Localization:** new user-facing strings need an `Localizable.xcstrings` entry (EN, and HU
   where practical) and must reach the UI through something that actually localizes —
   `Text(LocalizedStringKey(...))` or `String(localized:)`, not a bare `Text(someString)` or
   string interpolation of a raw `String`, which silently skips localization (this exact class
   of bug has recurred several times — `ComponentStepper`, `ContentView.modeButton`,
   accessibility labels — see `docs/buglist.md` ENH-L10N-1).
5. **Tooltips/accessibility:** interactive elements get a `.help(...)` (routed through
   `String(localized:)`) and, where relevant, an `.accessibilityLabel(...)`. Prefer
   `.focusEffectDisabled()` over `.focusable(false)` on `Button`s so the element stays in the
   Tab order and doesn't lose native tooltip registration (see `FOCUSABLE-AUDIT` in `buglist.md`
   for why this distinction matters).
6. **Before writing any code that falls under the Claude.md discussion list, stop and ask.**
7. **End of session:** update `docs/progress.md` (new entry) and `docs/countdownApp-handoff.md`
   (current state), then git commit — see `Claude.md`, "Docs karbantartás".
