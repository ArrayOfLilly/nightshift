## SYSTEM CONTEXT & CONSTRAINTS

**Role:** You are an expert Full-Stack Developer with deep specialization in the languages present in this project. You have been provided with the current AppState of the codebase as a structured Markdown snapshot.

**Objective:** Analyze the provided code and deliver concise, accurate solutions based **only** on the existing logic, unless a specific modification is explicitly requested at function or file level.
No architectural changes are allowed unless explicitly stated.

The codebase is provided as a structured AppState snapshot with line numbers. Please cite filename and line range when referencing code.

---

### Anti-Hallucination & Quality Rules

1. **No Ghost Functions:** Do not reference methods, variables, classes, or modules that are not present in the provided context. If something appears to be missing, ask for it explicitly.
2. **Anti-Drift:** Stick to the current architectural patterns. Do not suggest major refactors or introduce new libraries unless they are critical for the fix.
3. **No Overengineering:** Prioritize readable, maintainable solutions over complex design patterns.
4. **Line References:** All source files include line numbers in the format `NNN  <code>`. When referencing code, always cite the **filename and line range** (e.g., "`Store.swift` lines 42–67").

---

### Reference Navigation

- The **Project Tree** at the top of this document shows the full directory structure.
- Each code block is preceded by a **breadcrumb path comment** (e.g., `// Path: src/models/user.go`) so you can orient yourself quickly.
- Files are listed in the order they were selected during snapshot generation.

---

### Output Contract

- Default response MUST be full code only when code is modified.
- If code is requested: return FULL FILE ONLY unless explicitly stated otherwise.
- No explanations unless explicitly requested.
- No diffs, no patches, no partial snippets.
- Preserve file structure exactly as provided.

If unsure: ask a clarification question instead of guessing.



---

### Language-Specific Rules

#### Swift

- **Concurrency:** Prefer `@MainActor` and `async/await` patterns as already present in the codebase.
- **State Management:** Respect the `ObservableObject` / `@Published` / `@StateObject` patterns used in the existing `Store` types. Do not suggest switching to a different state-management architecture.
- **Line Length:** Do not force hard line wraps in suggested code. Keep logic clean and let the editor handle soft-wrap display.
- **Optionals:** Use `guard let` / `if let` idioms. Avoid force-unwrapping (`!`) unless the surrounding code already establishes a non-nil invariant.
- **Idiomatic Swift:** Prefer value types (`struct`) over `class` where the existing code does so. Follow Swift API Design Guidelines for naming.

- Only modify code sections directly relevant to the request. Do not touch unrelated functions, even if they are adjacent.

---

> **Context size:** 1,605 lines across all provided files.  
> **Response budget:** Please keep your answer under **321 lines** to avoid truncation in the chat window.  
> If a complete solution exceeds this, provide the most critical section first and offer to continue.

---

# AppState Snapshot - ContextGen

**Projekt:** `countdownApp`  
**Teljes eleresi ut:** `/Users/ArrayOfLilly/tools/countdownApp/countdownApp/countdownApp`  
**Generalva:** 2026-08-08 21:09:27  
**Fajlok szama:** 11  
**Összes sor:** 1,605  
**Nyelvek:** .swift  
**Sorszamozas:** nem

## Könyvtarfa

```
countdownApp
├── resources
│   ├── AppIcon.icon
│   │   ├── Assets
│   │   │   └── sand-clock_16701966.png
│   │   └── icon.json
│   ├── Assets.xcassets
│   │   ├── 9moon.imageset
│   │   │   ├── 9moon.svg
│   │   │   └── Contents.json
│   │   ├── AccentColor.colorset
│   │   │   └── Contents.json
│   │   ├── ALL MOON.imageset
│   │   │   ├── ALL MOON.svg
│   │   │   └── Contents.json
│   │   ├── AppIcon.appiconset
│   │   │   └── Contents.json
│   │   ├── cat.imageset
│   │   │   ├── cat.svg
│   │   │   └── Contents.json
│   │   ├── hourglass.imageset
│   │   │   ├── Asset 1.svg
│   │   │   └── Contents.json
│   │   ├── Moon 3
│   │   │   ├── pink_moon_1.imageset
│   │   │   │   ├── Contents.json
│   │   │   │   └── pink_moon_1.svg
│   │   │   ├── pink_moon_2.imageset
│   │   │   │   ├── Contents.json
│   │   │   │   └── pink_moon_2.svg
│   │   │   ├── pink_moon_3.imageset
│   │   │   │   ├── Contents.json
│   │   │   │   └── pink_moon_3.svg
│   │   │   ├── pink_moon_4.imageset
│   │   │   │   ├── Contents.json
│   │   │   │   └── pink_moon_4.svg
│   │   │   ├── pink_moon_5.imageset
│   │   │   │   ├── Contents.json
│   │   │   │   └── pink_moon_5.svg
│   │   │   ├── pink_moon_6.imageset
│   │   │   │   ├── Contents.json
│   │   │   │   └── pink_moon_6.svg
│   │   │   ├── pink_moon_7.imageset
│   │   │   │   ├── Contents.json
│   │   │   │   └── pink_moon_7.svg
│   │   │   ├── pink_moon_8.imageset
│   │   │   │   ├── Contents.json
│   │   │   │   └── pink_moon_8.svg
│   │   │   ├── pink_moon_9.imageset
│   │   │   │   ├── Contents.json
│   │   │   │   └── pink_moon_9.svg
│   │   │   └── Contents.json
│   │   ├── Moon Cycle.imageset
│   │   │   ├── Contents.json
│   │   │   └── MOONS.svg
│   │   ├── Moon Set.imageset
│   │   │   ├── Contents.json
│   │   │   └── MOON SET.svg
│   │   ├── Moon v1
│   │   │   ├── 01 full moon.imageset
│   │   │   │   ├── Contents.json
│   │   │   │   └── full moon v1.svg
│   │   │   ├── 02 crescent moon.imageset
│   │   │   │   ├── Contents.json
│   │   │   │   └── crescent moon v1.svg
│   │   │   ├── 03 waning moon.imageset
│   │   │   │   ├── Contents.json
│   │   │   │   └── waning moon v1.svg
│   │   │   ├── 04 lunar eclipse.imageset
│   │   │   │   ├── Contents.json
│   │   │   │   └── lunar eclipse v1.svg
│   │   │   └── Contents.json
│   │   ├── Moon v2
│   │   │   ├── 01 NEW MOON.imageset
│   │   │   │   ├── Contents.json
│   │   │   │   └── NEW MOON.svg
│   │   │   ├── 02 WANING CRESCENT.imageset
│   │   │   │   ├── Contents.json
│   │   │   │   └── WANING CRESCENT.svg
│   │   │   ├── 03 LAST QUARTER.imageset
│   │   │   │   ├── Contents.json
│   │   │   │   └── LAST QUARTER.svg
│   │   │   ├── 04 WANING GIBBOUS.imageset
│   │   │   │   ├── Contents.json
│   │   │   │   └── WANING GIBBOUS.svg
│   │   │   ├── 05 FULL MOON.imageset
│   │   │   │   ├── Contents.json
│   │   │   │   └── FULL MOON.svg
│   │   │   ├── 06 WAXING GIBBONS.imageset
│   │   │   │   ├── Contents.json
│   │   │   │   └── WAXING GIBBONS.svg
│   │   │   ├── 07 FIRST QUARTER.imageset
│   │   │   │   ├── Contents.json
│   │   │   │   └── FIRST QUARTER.svg
│   │   │   ├── 08 WAXING CREASCENT.imageset
│   │   │   │   ├── Contents.json
│   │   │   │   └── WAXING CREASCENT.svg
│   │   │   └── Contents.json
│   │   ├── Phases 1.imageset
│   │   │   ├── Asset 1@4x.png
│   │   │   └── Contents.json
│   │   ├── screenshot.imageset
│   │   │   ├── Contents.json
│   │   │   └── timer.png
│   │   ├── spooky_tomato.imageset
│   │   │   ├── Contents.json
│   │   │   └── spooky_tomato.png
│   │   ├── sun.imageset
│   │   │   ├── Contents.json
│   │   │   └── sun2.svg
│   │   └── Contents.json
│   └── Font
│       ├── alienleague.ttf
│       ├── alienleaguebold.ttf
│       ├── alienleaguebolditalic.ttf
│       └── alienleagueital.ttf
├── AddCountdownSheet.swift
├── AppTheme.swift
├── CalculateView.swift
├── ColorPickerSheet.swift
├── ContentView.swift
├── countdownAppApp.swift
├── CountdownDetailView.swift
├── CountdownItem.swift
├── CountdownRowView.swift
├── CountdownView.swift
└── LongPressStepperButton.swift
```

## Forraskodok

### `AddCountdownSheet.swift`  _(178 sor)_

```swift
// Path: AddCountdownSheet.swift
//
//  AddCountdownSheet.swift
//  countdownApp
//
//  Modal sheet for creating a new CountdownItem.
//  Presented from CountdownView when the user taps "+ ADD".
//

import SwiftUI

struct AddCountdownSheet: View {

    @Environment(\.dismiss) private var dismiss
    let onAdd: (CountdownItem) -> Void

    @State private var label:    String = ""
    @State private var deadline: Date   = Date()

    private var cal: Calendar { Calendar.current }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 28) {

                // ── Top bar: Cancel + Add ──────────────────────────────
                HStack {
                    Button("Cancel") { dismiss() }
                        .buttonStyle(.plain)
                        .font(AppTheme.alienLeague(15))
                        .foregroundStyle(AppTheme.dark)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(AppTheme.dark.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .focusable(false)

                    Spacer()

                    Button("Add") {
                        onAdd(CountdownItem(
                            label: label.trimmingCharacters(in: .whitespaces),
                            deadline: deadline))
                        dismiss()
                    }
                    .buttonStyle(.plain)
                    .font(AppTheme.alienLeagueBold(15))
                    .foregroundStyle(label.trimmingCharacters(in: .whitespaces).isEmpty
                                ? Color.white.opacity(0.8)
                                : AppTheme.background)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(label.trimmingCharacters(in: .whitespaces).isEmpty
                                ? AppTheme.dark.opacity(0.3)
                                : AppTheme.dark)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .disabled(label.trimmingCharacters(in: .whitespaces).isEmpty)
                    .focusable(false)
                }

                // ── Label ──────────────────────────────────────────────
                VStack(alignment: .leading, spacing: 8) {
                    Text("LABEL")
                        .font(AppTheme.alienLeagueBold(20))
                        .foregroundStyle(AppTheme.dark)
                    TextField("e.g. GPT-4 Free", text: $label)
                        .textFieldStyle(.roundedBorder)
                        .font(AppTheme.alienLeague(15))
                }
                .focusable(false)

                // ── Deadline stepper ───────────────────────────────────
                VStack(alignment: .leading, spacing: 8) {
                    Text("DEADLINE")
                        .font(AppTheme.alienLeagueBold(20))
                        .foregroundStyle(AppTheme.dark)
                    deadlineStepper
                }

                Spacer()
            }
            .padding(24)
        }
    }

    // MARK: - Deadline stepper

    private var deadlineStepper: some View {
        HStack(spacing: 10) {
            componentStepper(
                label: "YEAR",
                value: String(cal.component(.year, from: deadline)),
                onInc: { adjust(.year,   by:  1) },
                onDec: { adjust(.year,   by: -1) }
            )
            componentStepper(
                label: "MON",
                value: monthAbbrev(),
                onInc: { adjust(.month,  by:  1) },
                onDec: { adjust(.month,  by: -1) }
            )
            componentStepper(
                label: "DAY",
                value: String(format: "%02d", cal.component(.day,    from: deadline)),
                onInc: { adjust(.day,    by:  1) },
                onDec: { adjust(.day,    by: -1) }
            )
            componentStepper(
                label: "HOUR",
                value: String(format: "%02d", cal.component(.hour,   from: deadline)),
                onInc: { adjust(.hour,   by:  1) },
                onDec: { adjust(.hour,   by: -1) }
            )
            componentStepper(
                label: "MIN",
                value: String(format: "%02d", cal.component(.minute, from: deadline)),
                onInc: { adjust(.minute, by:  1) },
                onDec: { adjust(.minute, by: -1) }
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(AppTheme.dark.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func componentStepper(
        label: String,
        value: String,
        onInc: @escaping () -> Void,
        onDec: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(AppTheme.alienLeague(10))
                .foregroundStyle(AppTheme.dark.opacity(0.6))
            Button(action: onInc) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.dark)
                    .frame(width: 32, height: 22)
                    .background(AppTheme.dark.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .buttonStyle(.plain)
            .focusable(false)
            Text(value)
                .font(AppTheme.alienLeagueBold(15))
                .foregroundStyle(AppTheme.dark)
                .frame(minWidth: 36)
                .multilineTextAlignment(.center)
            Button(action: onDec) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.dark)
                    .frame(width: 32, height: 22)
                    .background(AppTheme.dark.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .buttonStyle(.plain)
            .focusable(false)
        }
        .frame(maxWidth: .infinity)
    }

    private func adjust(_ c: Calendar.Component, by value: Int) {
        if let d = cal.date(byAdding: c, value: value, to: deadline) { deadline = d }
    }

    private func monthAbbrev() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM"
        fmt.locale = Locale(identifier: "en_US")
        return fmt.string(from: deadline).uppercased()
    }
}

```

### `AppTheme.swift`  _(61 sor)_

```swift
// Path: AppTheme.swift
//
//  AppTheme.swift
//  countdownApp
//
//  "Spooky Tomato" visual theme.
//  Colors sampled from timer.png reference design.
//  Fonts: Alien League family — must be registered in Info.plist before use.
//

import SwiftUI

enum AppTheme {

    // MARK: - Colors

    /// Warm amber background (the dominant color in the reference design)
    static let background         = Color(red: 0.898, green: 0.627, blue: 0.125)
    /// Dark brown used for buttons and card text
    static let dark               = Color(red: 0.165, green: 0.125, blue: 0.082)
    /// Near-black background for Calculate mode (#060503)
    static let calculateBackground = Color(red: 0x06/255, green: 0x05/255, blue: 0x03/255)
    /// Semi-transparent dark overlay for cards / rows
    static let cardSurface        = Color(red: 0.165, green: 0.125, blue: 0.082).opacity(0.20)
    /// White — used for numerals displayed on the tomato body
    static let timerText   = Color.white

    /// Free-slot card color palette (12 options, rotated by item index)
    /// 30271B · 51422E · 778005 · 4D70D8 · 293B72 · 403873
    /// 593C73 · 723F73 · 8A4273 · DD3B72 · DD114A · B70E26
    static let freeColors: [Color] = [
        Color(red: 0x30/255, green: 0x27/255, blue: 0x1B/255), // 2  #30271B dark brown
        Color(red: 0x51/255, green: 0x42/255, blue: 0x2E/255), // 1  #51422E lighter brown
        Color(red: 0x77/255, green: 0x80/255, blue: 0x05/255), // 0  #778005 olive-yellow
        Color(red: 0x4D/255, green: 0x70/255, blue: 0xD8/255), // 4  #4D70D8 blue
        Color(red: 0x29/255, green: 0x3B/255, blue: 0x72/255), // 3  #293B72 navy
        Color(red: 0x40/255, green: 0x38/255, blue: 0x73/255), // 5  #403873 dark purple
        Color(red: 0x59/255, green: 0x3C/255, blue: 0x73/255), // 6  #593C73 purple
        Color(red: 0x72/255, green: 0x3F/255, blue: 0x73/255), // 8  #723F73 mid purple
        Color(red: 0x8A/255, green: 0x42/255, blue: 0x73/255), // 7  #8A4273 magenta-purple
        Color(red: 0xDD/255, green: 0x3B/255, blue: 0x72/255), // 9  #DD3B72 pink-red
        Color(red: 0xDD/255, green: 0x11/255, blue: 0x4A/255), // 10 #DD114A hot red-pink
        Color(red: 0xB7/255, green: 0x0E/255, blue: 0x26/255), // 11 #B70E26 deep red
    ]

    /// Returns the free-slot color for the given index (cycles through freeColors)
    static func freeColor(for index: Int) -> Color {
        freeColors[index % freeColors.count]
    }

    // MARK: - Fonts
    // NOTE: If text appears in system font, verify the PostScript name in Font Book.
    // Open a .ttf with Font Book → Info tab → PostScript name.

    static func alienLeague(_ size: CGFloat) -> Font {
        Font.custom("Alien League", size: size)
    }

    static func alienLeagueBold(_ size: CGFloat) -> Font {
        Font.custom("Alien League Bold", size: size)
    }
}

```

### `CalculateView.swift`  _(251 sor)_

```swift
// Path: CalculateView.swift
//
//  CalculateView.swift
//  countdownApp
//
//  Time-difference calculator — extracted from the original ContentView.
//  From/To dates are edited via the same component stepper used in CountdownDetailView.
//  Result: quantity in alienLeagueBold (38pt), unit in alienLeague (18pt, reduced opacity).
//  Colors: dark brown (AppTheme.dark) background; amber (AppTheme.background) text/icons;
//  transparent elements use Color.white.opacity(X) — not amber-opacity.
//

import SwiftUI

struct CalculateView: View {

    @AppStorage("calculateFromDate") private var fromInterval: Double = Date().timeIntervalSince1970
    @AppStorage("calculateToDate")   private var toInterval:   Double = Date().timeIntervalSince1970

    private var fromDate: Date {
        get { Date(timeIntervalSince1970: fromInterval) }
        nonmutating set { fromInterval = newValue.timeIntervalSince1970 }
    }
    private var toDate: Date {
        get { Date(timeIntervalSince1970: toInterval) }
        nonmutating set { toInterval = newValue.timeIntervalSince1970 }
    }

    private var cal: Calendar { Calendar.current }

    var body: some View {
        ZStack {
            AppTheme.calculateBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    Text("CALCULATE")
                        .font(AppTheme.alienLeagueBold(32))
                        .foregroundStyle(AppTheme.background)
                        .kerning(4)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 20)

                    Text("FROM")
                        .font(AppTheme.alienLeague(20))
                        .foregroundStyle(Color.white.opacity(0.9))
                    dateStepper(date: Binding(
                        get: { fromDate },
                        set: { fromInterval = $0.timeIntervalSince1970 }
                    ))

                    Text("TO")
                        .font(AppTheme.alienLeague(20))
                        .foregroundStyle(Color.white.opacity(0.9))
                    dateStepper(date: Binding(
                        get: { toDate },
                        set: { toInterval = $0.timeIntervalSince1970 }
                    ))

                    Button {
                        toInterval = Date().timeIntervalSince1970
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 12, weight: .bold))
                            Text("RESET TO NOW")
                                .font(AppTheme.alienLeague(13))
                        }
                        .foregroundStyle(AppTheme.background)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.18))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .focusable(false)

                    Rectangle()
                        .fill(Color.white.opacity(0.25))
                        .frame(height: 1)
                        .padding(.vertical, 4)

                    Text(resultLabel.uppercased())
                        .font(AppTheme.alienLeague(20))
                        .foregroundStyle(Color.white.opacity(0.9))

                    resultRow

                    // ── Illustration — moon phases in a U-arc ─────────────
                    GeometryReader { geo in
                        let count = 9
                        let w = geo.size.width
                        let moonSize = (w - CGFloat(count - 1) * 12) / CGFloat(count)
                        let arcDepth: CGFloat = 28
                        HStack(spacing: 12) {
                            ForEach(0..<count, id: \.self) { i in
                                let t = CGFloat(i) / CGFloat(count - 1)
                                // U shape: parabola, 0 at edges, -1 at center
                                let arcOffset = arcDepth * (4 * t * t - 4 * t)
                                Image("pink_moon_\(i + 1)")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: moonSize)
                                    .opacity(0.85)
                                    .offset(y: -arcOffset)
                            }
                        }
                    }
                    .frame(height: 80)
                    .padding(.top, 20)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Date stepper

    @ViewBuilder
    private func dateStepper(date: Binding<Date>) -> some View {
        HStack(spacing: 10) {
            componentStepper(
                label: "YEAR",
                value: String(cal.component(.year,   from: date.wrappedValue)),
                onInc: { adjustDate(date, .year,   by:  1) },
                onDec: { adjustDate(date, .year,   by: -1) }
            )
            componentStepper(
                label: "MON",
                value: monthAbbrev(from: date.wrappedValue),
                onInc: { adjustDate(date, .month,  by:  1) },
                onDec: { adjustDate(date, .month,  by: -1) }
            )
            componentStepper(
                label: "DAY",
                value: String(format: "%02d", cal.component(.day,    from: date.wrappedValue)),
                onInc: { adjustDate(date, .day,    by:  1) },
                onDec: { adjustDate(date, .day,    by: -1) }
            )
            componentStepper(
                label: "HOUR",
                value: String(format: "%02d", cal.component(.hour,   from: date.wrappedValue)),
                onInc: { adjustDate(date, .hour,   by:  1) },
                onDec: { adjustDate(date, .hour,   by: -1) }
            )
            componentStepper(
                label: "MIN",
                value: String(format: "%02d", cal.component(.minute, from: date.wrappedValue)),
                onInc: { adjustDate(date, .minute, by:  1) },
                onDec: { adjustDate(date, .minute, by: -1) }
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func componentStepper(
        label: String,
        value: String,
        onInc: @escaping () -> Void,
        onDec: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(AppTheme.alienLeague(10))
                .foregroundStyle(Color.white.opacity(0.6))
            LongPressStepperButton(
                systemImage: "chevron.up",
                action: onInc,
                foregroundColor: AppTheme.background,
                backgroundColor: Color.white.opacity(0.12)
            )
            Text(value)
                .font(AppTheme.alienLeagueBold(15))
                .foregroundStyle(AppTheme.background)
                .frame(minWidth: 36)
                .multilineTextAlignment(.center)
            LongPressStepperButton(
                systemImage: "chevron.down",
                action: onDec,
                foregroundColor: AppTheme.background,
                backgroundColor: Color.white.opacity(0.12)
            )
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Result display

    @ViewBuilder
    private var resultRow: some View {
        let parts = resultParts
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            ForEach(parts.indices, id: \.self) { i in
                Text(parts[i].quantity)
                    .font(AppTheme.alienLeagueBold(38))
                    .foregroundStyle(AppTheme.background)
                    .monospacedDigit()
                Text(parts[i].unit)
                    .font(AppTheme.alienLeague(18))
                    .foregroundStyle(Color.white.opacity(0.5))
                    .padding(.trailing, i < parts.count - 1 ? 6 : 0)
            }
        }
        .minimumScaleFactor(0.45)
        .lineLimit(1)
    }

    // MARK: - Computed

    private var isFuture:    Bool         { toDate > fromDate }
    private var difference:  TimeInterval { abs(toDate.timeIntervalSince(fromDate)) }
    private var resultLabel: String       { isFuture ? "Remaining time:" : "Elapsed time:" }

    private struct TimePart { let quantity: String; let unit: String }

    private var resultParts: [TimePart] {
        let total   = Int(difference)
        let days    = total / 86400
        let hours   = (total % 86400) / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        return [
            TimePart(quantity: "\(days)",    unit: "d"),
            TimePart(quantity: "\(hours)",   unit: "h"),
            TimePart(quantity: "\(minutes)", unit: "m"),
            TimePart(quantity: "\(seconds)", unit: "s"),
        ]
    }

    // MARK: - Helpers

    private func adjustDate(_ binding: Binding<Date>, _ c: Calendar.Component, by value: Int) {
        if let d = cal.date(byAdding: c, value: value, to: binding.wrappedValue) {
            binding.wrappedValue = d
        }
    }

    private func monthAbbrev(from date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM"
        fmt.locale = Locale(identifier: "en_US")
        return fmt.string(from: date).uppercased()
    }
}

#Preview { CalculateView() }

```

### `ColorPickerSheet.swift`  _(87 sor)_

```swift
// Path: ColorPickerSheet.swift
//
//  ColorPickerSheet.swift
//  countdownApp
//
//  Sheet that lets the user pick an accent color for a free slot.
//  Opens from CountdownDetailView via the paintbrush button.
//  Shows all AppTheme.freeColors as circular swatches.
//  One "auto" swatch resets to the hash-based fallback (accentColorIndex = nil).
//

import SwiftUI

struct ColorPickerSheet: View {

    @Binding var selectedIndex: Int?
    @Environment(\.dismiss) private var dismiss

    // Grid: 4 columns
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 4)

    var body: some View {
        VStack(spacing: 0) {

            // ── Title ───────────────────────────────────────────────────
            Text("PICK A COLOR")
                .font(AppTheme.alienLeagueBold(20))
                .foregroundStyle(AppTheme.dark.opacity(0.85))
                .kerning(2)
                .padding(.top, 28)
                .padding(.bottom, 20)

            // ── Swatch grid ─────────────────────────────────────────────
            LazyVGrid(columns: columns, spacing: 16) {

                // "Auto" swatch — resets to hash-based color
                swatchButton(color: AppTheme.background, index: nil, label: "AUTO")

                // Palette swatches
                ForEach(Array(AppTheme.freeColors.enumerated()), id: \.offset) { idx, color in
                    swatchButton(color: color, index: idx, label: nil)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .frame(minWidth: 300, minHeight: 260)
    }

    // MARK: - Swatch button

    @ViewBuilder
    private func swatchButton(color: Color, index: Int?, label: String?) -> some View {
        let isSelected = (selectedIndex == index)
        Button {
            selectedIndex = index
            dismiss()
        } label: {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 52, height: 52)
                    .shadow(color: color.opacity(0.6), radius: isSelected ? 8 : 0)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                AppTheme.dark.opacity(isSelected ? 0.85 : 0.18),
                                lineWidth: isSelected ? 3 : 1.5
                            )
                    )

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppTheme.dark.opacity(0.75))
                } else if let label {
                    Text(label)
                        .font(AppTheme.alienLeague(9))
                        .foregroundStyle(AppTheme.dark.opacity(0.75))
                        .kerning(1)
                }
            }
        }
        .buttonStyle(.plain)
        .focusable(false)
    }
}

```

### `ContentView.swift`  _(86 sor)_

```swift
// Path: ContentView.swift
//
//  ContentView.swift
//  countdownApp
//
//  Root view. Owns the mode switcher (Calculate / Countdown).
//  All mode-specific logic lives in CalculateView and CountdownView.
//  Mode switcher is a custom HStack of icon buttons (NOT the native segmented
//  Picker) so size, padding, and color are fully controllable — the native
//  macOS NSSegmentedControl ignores SwiftUI font/padding/foregroundStyle
//  modifiers on its label content.
//  Placeholder icons ("clock" / "at") can be swapped for custom assets later.
//

import SwiftUI

struct ContentView: View {

    enum Mode: String, CaseIterable, Identifiable {
        case calculate = "Calculate"
        case countdown = "Countdown"
        var id: String { rawValue }

        /// SF Symbol placeholder — swap for a custom icon asset if desired.
        var symbolName: String {
            switch self {
            case .calculate: return "clock"
            case .countdown: return "at"
            }
        }
    }

    @State private var selectedMode: Mode = .countdown

    var body: some View {
        VStack(spacing: 0) {

            // ── Mode switcher (custom, not native Picker) ────────────────────
            HStack(spacing: 20) {
                ForEach(Mode.allCases) { mode in
                    modeButton(mode)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            Divider()

            // ── Active mode ────────────────────────────────────────────────
            Group {
                switch selectedMode {
                case .calculate: CalculateView()
                case .countdown: CountdownView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Mode button

    @ViewBuilder
    private func modeButton(_ mode: Mode) -> some View {
        let selected = selectedMode == mode

        Button {
            selectedMode = mode
        } label: {
            Text(mode.rawValue)
                .font(AppTheme.alienLeagueBold(20))
                .foregroundStyle(Color.white)
                .opacity(selected ? 1.0 : 0.45)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppTheme.dark)
                        .opacity(selected ? 1.0 : 0.0)
                )
        }
        .buttonStyle(.plain)
        .focusable(false)
        .accessibilityLabel(mode.rawValue)
    }
}

#Preview { ContentView() }

```

### `CountdownDetailView.swift`  _(391 sor)_

```swift
// Path: CountdownDetailView.swift
//
//  CountdownDetailView.swift
//  countdownApp
//
//  Full-screen "Spooky Tomato" single-item countdown.
//  The countdown text is overlaid on the tomato body, matching the timer.png reference.
//  Reached via NavigationLink from CountdownView.
//  Deadline is editable via component steppers (year/month/day/hour/minute).
//
//  Label editing uses FocusedNSTextField (NSViewRepresentable) instead of SwiftUI
//  TextField + @FocusState. @FocusState inside a NavigationLink destination on macOS
//  causes FocusBridge to attempt first-responder assignment before the view is
//  attached to a window, producing a KeyViewProxy/window-mismatch crash on every
//  render pass (toggle, TimelineView tick, etc.). NSTextField manages its own
//  first-responder lifecycle through AppKit and does not go through FocusBridge.
//

import SwiftUI
import AppKit

// MARK: - NSViewRepresentable label text field

/// A plain NSTextField wrapper that:
/// - matches the Alien League Bold 36pt / kerning-4 / dark-0.8 style
/// - requests first responder via the AppKit window directly (no SwiftUI FocusBridge)
/// - calls `onCommit` on Return key or focus loss
private struct FocusedNSTextField: NSViewRepresentable {

    @Binding var text: String
    var onCommit: () -> Void

    func makeNSView(context: Context) -> NSTextField {
        let tf = NSTextField()
        tf.delegate = context.coordinator
        tf.isBordered = false
        tf.isBezeled = false
        tf.drawsBackground = false
        tf.focusRingType = .none
        tf.lineBreakMode = .byTruncatingTail
        tf.maximumNumberOfLines = 1
        return tf
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        // Only push text when the field is not being edited to avoid caret jumping.
        if !context.coordinator.isEditing {
            nsView.stringValue = text
        }
        // Apply style every update (font objects are cheap to recreate).
        if let font = NSFont(name: "AlienLeagueBold", size: 36)
            ?? NSFont(name: "Alien League Bold", size: 36) {
            nsView.font = font
        } else {
            nsView.font = NSFont.boldSystemFont(ofSize: 36)
        }
        nsView.textColor = NSColor(AppTheme.dark).withAlphaComponent(0.8)
        // NOTE: Do NOT call makeFirstResponder here.
        // Calling it — even async — causes AppKit to notify SwiftUI's hosting
        // infrastructure, which triggers FocusBridge.moveFocus on a KeyViewProxy
        // that is not yet attached to a window, producing the
        // "different window (null)" crash. The user clicked the label to enter
        // edit mode, so clicking into the NSTextField to type is acceptable UX.
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onCommit: onCommit)
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        @Binding var text: String
        var onCommit: () -> Void
        var isEditing: Bool = false

        init(text: Binding<String>, onCommit: @escaping () -> Void) {
            _text = text
            self.onCommit = onCommit
        }

        func controlTextDidBeginEditing(_ obj: Notification) {
            isEditing = true
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let tf = obj.object as? NSTextField else { return }
            text = tf.stringValue
        }

        func controlTextDidEndEditing(_ obj: Notification) {
            isEditing = false
            onCommit()
        }

        func control(_ control: NSControl, textView: NSTextView,
                     doCommandBy selector: Selector) -> Bool {
            if selector == #selector(NSResponder.insertNewline(_:)) {
                onCommit()
                control.window?.makeFirstResponder(nil)
                return true
            }
            return false
        }
    }
}

// MARK: - CountdownDetailView

struct CountdownDetailView: View {

    @Binding var item: CountdownItem
    let onDelete: () -> Void

    @State private var copyFeedback:   Bool = false
    @State private var isEditing:      Bool = false
    @State private var showColorPicker: Bool = false
    /// Local to this view (not item.showRemaining, which is the row's own toggle) —
    /// the detail screen always opens showing remaining time, regardless of what the
    /// row list was last toggled to.
    @State private var showRemaining:  Bool = true
    /// Local mirror of item.deadline — drives immediate stepper visual feedback.
    /// @Binding writes propagate to CountdownView but don't guarantee an immediate
    /// re-render of this destination view on macOS NavigationStack.
    @State private var localDeadline: Date = Date()

    private var cal: Calendar { Calendar.current }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {

                // ── Account label — tap to edit ──
                HStack(alignment: .center, spacing: 12) {
                    if isEditing {
                        FocusedNSTextField(text: $item.label) {
                            isEditing = false
                        }
                        .frame(height: 44)
                        .padding(.bottom, 2)
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .frame(height: 1.5)
                                .foregroundStyle(AppTheme.dark.opacity(0.35))
                        }
                    } else {
                        Text(item.label.isEmpty ? "Countdown" : item.label.uppercased())
                            .font(AppTheme.alienLeagueBold(36))
                            .foregroundStyle(AppTheme.dark.opacity(0.8))
                            .kerning(4)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .onTapGesture {
                                isEditing = true
                            }
                    }

                    Button {
                        let trimmed = item.label.trimmingCharacters(in: .whitespaces)
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(trimmed, forType: .string)
                        copyFeedback = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            copyFeedback = false
                        }
                    } label: {
                        Image(systemName: copyFeedback ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(AppTheme.dark.opacity(0.85))
                            .frame(width: 36, height: 36)
                            .background(AppTheme.dark.opacity(0.18))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)

                Spacer()

                // ── Tomato + overlaid time ────────────────────────────────
                TimelineView(.periodic(from: .now, by: 1.0)) { ctx in
                    ZStack(alignment: .center) {
                        Image("spooky_tomato")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 500, maxHeight: 500)

                        timeDisplay(at: ctx.date)
                            .offset(y: 42)
                    }
                }

                Spacer()

                // ── Deadline stepper (always visible) ────────────────────────
                deadlineStepper
                    .padding(.bottom, 16)

                // ── Bottom buttons ────────────────────────────────────────
                HStack(spacing: 12) {
                    Button {
                        showRemaining.toggle()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: showRemaining ? "calendar" : "clock")
                            Text(showRemaining ? "Show Deadline" : "Show Remaining")
                                .font(AppTheme.alienLeague(15))
                        }
                        .foregroundStyle(AppTheme.background)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 13)
                        .background(AppTheme.dark)
                        .clipShape(RoundedRectangle(cornerRadius: 9))
                    }
                    .focusable(false)

                    // ── Color picker — only for free (expired) slots ──
                    if item.isExpired(at: Date()) {
                        Button {
                            showColorPicker = true
                        } label: {
                            Image(systemName: "paintbrush")
                                .foregroundStyle(AppTheme.background)
                                .frame(width: 44, height: 44)
                                .background(AppTheme.dark)
                                .clipShape(RoundedRectangle(cornerRadius: 9))
                        }
                        .focusable(false)
                        .sheet(isPresented: $showColorPicker) {
                            ColorPickerSheet(selectedIndex: $item.accentColorIndex)
                        }
                    }

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundStyle(AppTheme.background)
                            .frame(width: 44, height: 44)
                            .background(AppTheme.dark)
                            .clipShape(RoundedRectangle(cornerRadius: 9))
                    }
                    .focusable(false)
                }
                .padding(.bottom, 36)
            }
        }
        .navigationTitle("")
        .onAppear {
            // Free slots have a stale, long-past deadline. Snap it to "now" once on
            // entry so the stepper starts from a sane base.
            if item.isExpired(at: Date()) {
                let now = Date()
                item.deadline  = now
                localDeadline  = now
            } else {
                localDeadline = item.deadline
            }
        }
    }

    // MARK: - Deadline stepper

    private var deadlineStepper: some View {
        HStack(spacing: 10) {
            componentStepper(
                label: "YEAR",
                value: String(component(.year)),
                onInc: { adjust(.year,  by:  1) },
                onDec: { adjust(.year,  by: -1) }
            )
            componentStepper(
                label: "MON",
                value: monthAbbrev(),
                onInc: { adjust(.month, by:  1) },
                onDec: { adjust(.month, by: -1) }
            )
            componentStepper(
                label: "DAY",
                value: String(format: "%02d", component(.day)),
                onInc: { adjust(.day,   by:  1) },
                onDec: { adjust(.day,   by: -1) }
            )
            componentStepper(
                label: "HOUR",
                value: String(format: "%02d", component(.hour)),
                onInc: { adjust(.hour,  by:  1) },
                onDec: { adjust(.hour,  by: -1) }
            )
            componentStepper(
                label: "MIN",
                value: String(format: "%02d", component(.minute)),
                onInc: { adjust(.minute, by:  1) },
                onDec: { adjust(.minute, by: -1) }
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(AppTheme.dark.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private func componentStepper(
        label: String,
        value: String,
        onInc: @escaping () -> Void,
        onDec: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(AppTheme.alienLeague(10))
                .foregroundStyle(AppTheme.dark.opacity(0.6))

            LongPressStepperButton(
                systemImage: "chevron.up",
                action: onInc,
                foregroundColor: AppTheme.dark,
                backgroundColor: AppTheme.dark.opacity(0.12)
            )

            Text(value)
                .font(AppTheme.alienLeagueBold(15))
                .foregroundStyle(AppTheme.dark)
                .frame(minWidth: 36)
                .multilineTextAlignment(.center)

            LongPressStepperButton(
                systemImage: "chevron.down",
                action: onDec,
                foregroundColor: AppTheme.dark,
                backgroundColor: AppTheme.dark.opacity(0.12)
            )
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Time display

    @ViewBuilder
    private func timeDisplay(at now: Date) -> some View {
        if showRemaining {
            let expired = item.isExpired(at: now)
            Text(expired ? "EXPIRED" : item.remainingFormatted(at: now))
                .font(AppTheme.alienLeagueBold(56))
                .foregroundStyle(expired ? Color.red : AppTheme.timerText)
                .monospacedDigit()
                .minimumScaleFactor(0.45)
                .lineLimit(1)
                .frame(maxWidth: 300)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        } else {
            Text(item.deadlineFormatted)
                .font(AppTheme.alienLeague(44))
                .foregroundStyle(AppTheme.timerText)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .frame(maxWidth: 300)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
    }

    // MARK: - Helpers

    private func component(_ c: Calendar.Component) -> Int {
        cal.component(c, from: localDeadline)
    }

    private func adjust(_ c: Calendar.Component, by value: Int) {
        // If the item is still expired, snap the base to now before applying the delta.
        var base = localDeadline
        if item.isExpired(at: Date()) {
            base = Date()
            localDeadline = base
            item.deadline  = base
        }
        if let newDate = cal.date(byAdding: c, value: value, to: base) {
            localDeadline = newDate   // immediate @State re-render
            item.deadline  = newDate  // propagate to CountdownView via @Binding
        }
    }

    private func monthAbbrev() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM"
        fmt.locale = Locale(identifier: "en_US")
        return fmt.string(from: localDeadline).uppercased()
    }
}

```

### `CountdownItem.swift`  _(54 sor)_

```swift
// Path: CountdownItem.swift
//
//  CountdownItem.swift
//  countdownApp
//
//  Data model for a single countdown entry.
//  Codable  → persisted to UserDefaults as JSON
//  Equatable → required for SwiftUI onChange(of:) on the items array
//  Hashable  → required for NavigationLink(value:) pattern (BUG-18 fix)
//

import Foundation

struct CountdownItem: Identifiable, Codable, Equatable, Hashable {

    var id       = UUID()
    var label    : String        // e.g. "GPT-4 Free"
    var deadline : Date          // when the account/resource resets
    var showRemaining: Bool = true  // true = show DD:HH:MM:SS  |  false = show deadline date
    /// Manually selected color index into AppTheme.freeColors.
    /// nil = auto (hash-based fallback). Only meaningful for free (expired) slots.
    var accentColorIndex: Int? = nil

    // MARK: - Helpers called from the view with a live Date reference
    // (views pass Date() from a TimelineView so the display updates every second)

    func isExpired(at now: Date) -> Bool {
        deadline < now
    }

    func remaining(at now: Date) -> TimeInterval {
        max(0, deadline.timeIntervalSince(now))
    }

    /// "02:14:33" or "03:02:14:33" (days prefix only when > 0)
    func remainingFormatted(at now: Date) -> String {
        let total = Int(remaining(at: now))
        let d = total / 86400
        let h = (total % 86400) / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if d > 0 {
            return String(format: "%02d:%02d:%02d:%02d", d, h, m, s)
        } else {
            return String(format: "%02d:%02d:%02d", h, m, s)
        }
    }

    /// "2026.08.10 14:00"
    var deadlineFormatted: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy.MM.dd HH:mm"
        return f.string(from: deadline)
    }
}

```

### `CountdownRowView.swift`  _(103 sor)_

```swift
// Path: CountdownRowView.swift
//
//  CountdownRowView.swift
//  countdownApp
//
//  Receives `now: Date` from the parent CountdownView's single TimelineView —
//  no per-row timer. This avoids N concurrent timers hammering the main thread.
//

import SwiftUI

struct CountdownRowView: View {

    @Binding var item: CountdownItem
    var now: Date = Date()
    var index: Int = 0
    @State private var copyFeedback: Bool = false

    private var itemFreeColor: Color {
        AppTheme.freeColor(for: item.accentColorIndex ?? 6)
    }

    var body: some View {
        rowContent(at: now)
    }

    @ViewBuilder
    private func rowContent(at now: Date) -> some View {
        let expired = item.isExpired(at: now)
        let accentColor: Color = expired ? itemFreeColor : AppTheme.cardSurface

        VStack(alignment: .leading, spacing: 6) {

            HStack(alignment: .center, spacing: 10) {

                HStack(spacing: 8) {
                    Text(copyFeedback ? "COPIED" : (item.label.isEmpty ? "—" : item.label))
                        .font(AppTheme.alienLeague(14))
                        .foregroundStyle(Color.white.opacity(copyFeedback ? 0.5 : 0.8))
                        .lineLimit(1)
                    Spacer(minLength: 8)
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.dark)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .simultaneousGesture(TapGesture().onEnded {
                    let trimmed = item.label.trimmingCharacters(in: .whitespaces)
                    #if os(macOS)
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(trimmed, forType: .string)
                    #else
                    UIPasteboard.general.string = trimmed
                    #endif
                    copyFeedback = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { copyFeedback = false }
                })

                if expired {
                    Text("FREE ✓")
                        .font(AppTheme.alienLeagueBold(13))
                        .foregroundStyle(Color.white.opacity(0.9))
                } else {
                    Button { item.showRemaining.toggle() } label: {
                        Image(systemName: item.showRemaining ? "calendar" : "clock")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppTheme.dark.opacity(0.85))
                            .frame(width: 42, height: 28)
                            .background(Color.white.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                }
            }

            if !expired {
                if item.showRemaining {
                    Text(item.remainingFormatted(at: now))
                        .font(AppTheme.alienLeagueBold(24))
                        .foregroundStyle(AppTheme.dark.opacity(0.95))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .padding(.leading, 4)
                } else {
                    Text(item.deadlineFormatted)
                        .font(AppTheme.alienLeague(20))
                        .foregroundStyle(AppTheme.dark.opacity(0.9))
                        .lineLimit(1)
                        .padding(.leading, 4)
                }
            }
        }
        .padding(16)
        .background(accentColor)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(
            color: expired ? itemFreeColor.opacity(0.55) : .clear,
            radius: 10, x: 0, y: 0
        )
    }
}

```

### `CountdownView.swift`  _(261 sor)_

```swift
// Path: CountdownView.swift
//
//  CountdownView.swift
//  countdownApp
//
//  Countdown list screen.
//  Single TimelineView ticks every second at the top level;
//  `now` is passed down to each CountdownRowView — no per-row timers.
//  Active rows: sorted by deadline ASC (automatic).
//  Free (expired) rows: manually reorderable via drag-to-reorder;
//    freeOrder [UUID] drives render order, persisted to UserDefaults "freeSlotOrder".
//
//  BUG-18 fix: NavigationLink(value:) + .navigationDestination(for:) pattern.
//  CountdownDetailView is only constructed on navigation, not on every TimelineView tick.
//
//  BUG-19 fix: .navigationDestination closure uses binding(for:) helper instead of
//  $items[idx] direct subscript. The idx captured at navigation time becomes stale
//  when items mutate (deadline change → active/free reclassification); binding(for:)
//  always resolves against the live items array by ID.
//
//  BUG-20 fix: RowEntry wrapper carries a slotKind ("a" / "f") alongside the item.
//  ForEach uses RowEntry.listID (= "a-UUID" / "f-UUID") as identity. Without the
//  prefix both ForEach loops share the same UUID identity space — SwiftUI recycles
//  the view when an item moves free→active (same UUID, different list), so
//  CountdownRowView keeps the stale free appearance. The prefix forces a new view
//  identity on reclassification.
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - RowEntry

private struct RowEntry: Identifiable {
    let item:     CountdownItem
    let slotKind: String        // "a" = active, "f" = free
    var id: String { "\(slotKind)-\(item.id)" }
}

struct CountdownView: View {

    @State private var items:        [CountdownItem] = []
    @State private var showAddSheet: Bool = false
    @State private var freeOrder:    [UUID] = []
    @State private var draggingID:   UUID?  = nil

    private let storageKey   = "countdownItems"
    private let freeOrderKey = "freeSlotOrder"

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                VStack(spacing: 0) {
                    itemList
                    addButton
                }
            }
            .navigationTitle("Countdown")
            .sheet(isPresented: $showAddSheet) {
                AddCountdownSheet { newItem in
                    items.append(newItem)
                }
            }
            .navigationDestination(for: CountdownItem.self) { item in
                CountdownDetailView(item: binding(for: item)) {
                    let id = item.id
                    items.removeAll { $0.id == id }
                    freeOrder.removeAll { $0 == id }
                    save()
                    saveFreeOrder()
                }
            }
        }
        .onAppear {
            load()
            loadFreeOrder()
        }
        .onChange(of: items) { save() }
    }

    // MARK: - Sorted item lists

    private func activeItems(at now: Date) -> [CountdownItem] {
        items
            .filter { !$0.isExpired(at: now) }
            .sorted { $0.deadline < $1.deadline }
    }

    private func orderedFreeItems(at now: Date) -> [CountdownItem] {
        let expired = items.filter { $0.isExpired(at: now) }
        var result: [CountdownItem] = []
        for id in freeOrder {
            if let item = expired.first(where: { $0.id == id }) {
                result.append(item)
            }
        }
        let positioned = Set(result.map { $0.id })
        let remaining = expired
            .filter { !positioned.contains($0.id) }
            .sorted { $0.label.localizedCaseInsensitiveCompare($1.label) == .orderedAscending }
        result.append(contentsOf: remaining)
        return result
    }

    private func rowEntries(at now: Date) -> [RowEntry] {
        let active = activeItems(at: now).map { RowEntry(item: $0, slotKind: "a") }
        let free   = orderedFreeItems(at: now).map { RowEntry(item: $0, slotKind: "f") }
        return active + free
    }

    // MARK: - Binding helper

    private func binding(for item: CountdownItem) -> Binding<CountdownItem> {
        Binding(
            get: { self.items.first { $0.id == item.id } ?? item },
            set: { updated in
                if let idx = self.items.firstIndex(where: { $0.id == updated.id }) {
                    self.items[idx] = updated
                }
            }
        )
    }

    // MARK: - Subviews

    // ⚠️ TEMP DEBUG (Session 22, 2026-08-08) — tick interval sped up 100× to
    // compress hours of real-time TimelineView ticks into minutes, to test
    // whether the beachball is caused by tick COUNT accumulating over long
    // background runtime rather than by user interaction. REVERT to 1.0
    // before normal use — search "TEMP DEBUG" to find this.
    private var itemList: some View {
        TimelineView(.periodic(from: .now, by: 0.01)) { ctx in
            let now     = ctx.date
            let entries = rowEntries(at: now)
            let free    = orderedFreeItems(at: now)

            ScrollView {
                LazyVStack(spacing: 10) {

                    Text("ACCOUNT COOLDOWN")
                        .font(AppTheme.alienLeagueBold(32))
                        .foregroundStyle(AppTheme.dark)
                        .kerning(4)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 20)
                        .padding(.bottom, 4)

                    ForEach(entries) { entry in
                        let item = entry.item
                        let isFree = entry.slotKind == "f"

                        if isFree {
                            NavigationLink(value: item) {
                                CountdownRowView(item: binding(for: item), now: now)
                            }
                            .buttonStyle(.plain)
                            .focusable(false)
                            .onDrag {
                                draggingID = item.id
                                return NSItemProvider(object: item.id.uuidString as NSString)
                            }
                            .onDrop(
                                of: [.plainText],
                                delegate: FreeSlotDropDelegate(
                                    targetItem: item,
                                    freeItems:  free,
                                    freeOrder:  $freeOrder,
                                    draggingID: $draggingID,
                                    onCommit:   saveFreeOrder
                                )
                            )
                        } else {
                            NavigationLink(value: item) {
                                CountdownRowView(item: binding(for: item), now: now)
                            }
                            .buttonStyle(.plain)
                            .focusable(false)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
            }
        }
    }

    private var addButton: some View {
        Button {
            showAddSheet = true
        } label: {
            Text("+ ADD")
                .font(AppTheme.alienLeagueBold(15))
                .foregroundStyle(AppTheme.background)
                .padding(.horizontal, 36)
                .padding(.vertical, 12)
                .background(AppTheme.dark)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .focusable(false)
        .padding(.vertical, 18)
    }

    // MARK: - Persistence

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func load() {
        guard
            let data    = UserDefaults.standard.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode([CountdownItem].self, from: data)
        else { return }
        items = decoded
    }

    private func saveFreeOrder() {
        let strings = freeOrder.map { $0.uuidString }
        UserDefaults.standard.set(strings, forKey: freeOrderKey)
    }

    private func loadFreeOrder() {
        guard let strings = UserDefaults.standard.stringArray(forKey: freeOrderKey) else { return }
        let validIDs = Set(items.map { $0.id })
        freeOrder = strings.compactMap { UUID(uuidString: $0) }.filter { validIDs.contains($0) }
    }
}

// MARK: - Drop delegate

private struct FreeSlotDropDelegate: DropDelegate {

    let targetItem: CountdownItem
    let freeItems:  [CountdownItem]
    @Binding var freeOrder:  [UUID]
    @Binding var draggingID: UUID?
    let onCommit: () -> Void

    func dropUpdated(info: DropInfo) -> DropProposal? { DropProposal(operation: .move) }
    func performDrop(info: DropInfo) -> Bool {
        draggingID = nil
        onCommit()
        return true
    }

    func dropEntered(info: DropInfo) {
        guard
            let from = draggingID,
            from != targetItem.id,
            let fi = freeItems.firstIndex(where: { $0.id == from }),
            let ti = freeItems.firstIndex(where: { $0.id == targetItem.id })
        else { return }
        var ids = freeItems.map { $0.id }
        ids.move(fromOffsets: IndexSet(integer: fi), toOffset: ti > fi ? ti + 1 : ti)
        freeOrder = ids
    }
}

#Preview { CountdownView() }

```

### `LongPressStepperButton.swift`  _(84 sor)_

```swift
// Path: LongPressStepperButton.swift
//
//  LongPressStepperButton.swift
//  countdownApp
//
//  A chevron button that fires once on a short tap, then repeats while held down.
//  Behaviour: tap → single step; hold (≥ initialDelay) → repeat every repeatInterval.
//  Used in CountdownDetailView and CalculateView component steppers.
//
//  Implementation: DragGesture(minimumDistance: 0) is used instead of
//  TapGesture + LongPressGesture because combining those two on macOS causes the
//  long-press to swallow the tap. DragGesture fires onChanged on first touch (distance 0
//  counts) which lets us start the timer immediately, and onEnded / value.translation
//  lets us cancel it cleanly.
//

import SwiftUI

struct LongPressStepperButton: View {

    let systemImage: String
    let action: () -> Void

    /// Seconds before auto-repeat kicks in.
    var initialDelay:    Double = 0.40
    /// Seconds between repeated steps while held.
    var repeatInterval:  Double = 0.08

    // Visual styling — same defaults as the existing chevron buttons.
    var foregroundColor: Color = AppTheme.dark
    var backgroundColor: Color = AppTheme.dark.opacity(0.12)

    @State private var timer: Timer? = nil
    @State private var isPressed: Bool = false

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(foregroundColor)
            .frame(width: 32, height: 22)
            .background(isPressed ? backgroundColor.opacity(2) : backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard timer == nil else { return }
                        isPressed = true
                        // Fire immediately on touch-down (single step).
                        action()
                        // After initialDelay, start repeating.
                        let t = Timer.scheduledTimer(
                            withTimeInterval: initialDelay,
                            repeats: false
                        ) { [self] _ in
                            startRepeating()
                        }
                        RunLoop.main.add(t, forMode: .common)
                        timer = t
                    }
                    .onEnded { _ in
                        stopTimer()
                    }
            )
            .focusable(false)
    }

    private func startRepeating() {
        // Cancel the initial-delay timer (it already fired), start repeat timer.
        timer?.invalidate()
        let t = Timer.scheduledTimer(
            withTimeInterval: repeatInterval,
            repeats: true
        ) { _ in
            action()
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        isPressed = false
    }
}

```

### `countdownAppApp.swift`  _(49 sor)_

```swift
// Path: countdownAppApp.swift
//
//  countdownAppApp.swift
//  countdownApp
//
//  App entry point. Single WindowGroup wrapping ContentView,
//  which owns the Calculate / Countdown mode switcher.
//
//  Registers the bundled Alien League font files with CoreText at launch
//  (process scope only — no system-wide install), so Font.custom("Alien
//  League", …) resolves from inside the app bundle instead of depending
//  on the font being separately installed in Font Book.
//

import SwiftUI
import CoreText

@main
struct countdownAppApp: App {

    init() {
        Self.registerBundledFonts()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    private static func registerBundledFonts() {
        let fileNames = ["alienleague", "alienleaguebold", "alienleagueital", "alienleaguebolditalic"]
        for name in fileNames {
            let url = Bundle.main.url(forResource: name, withExtension: "ttf")
                ?? Bundle.main.url(forResource: name, withExtension: "ttf", subdirectory: "Font")
            guard let fontURL = url else {
                print("⚠️ countdownApp: font not found in bundle: \(name).ttf")
                continue
            }
            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error) {
                let underlying = error?.takeRetainedValue().localizedDescription ?? "unknown error"
                // Already-registered is not a real failure (e.g. also present in Font Book).
                if !underlying.contains("already") {
                    print("⚠️ countdownApp: failed to register \(name).ttf — \(underlying)")
                }
            }
        }
    }
}

```
