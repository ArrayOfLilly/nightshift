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
                        set: { fromInterval = snapToMinute($0).timeIntervalSince1970 }
                    ))
                    nowButton(label: "RESET FROM NOW") {
                        fromInterval = snapToMinute(Date()).timeIntervalSince1970
                    }

                    Text("TO")
                        .font(AppTheme.alienLeague(20))
                        .foregroundStyle(Color.white.opacity(0.9))
                    dateStepper(date: Binding(
                        get: { toDate },
                        set: { toInterval = snapToMinute($0).timeIntervalSince1970 }
                    ))
                    nowButton(label: "RESET TO NOW") {
                        toInterval = snapToMinute(Date()).timeIntervalSince1970
                    }

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

    // MARK: - NOW button

    @ViewBuilder
    private func nowButton(label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 12, weight: .bold))
                Text(label)
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
            binding.wrappedValue = snapToMinute(d)
        }
    }

    // CALC-2/3 fix: floor to minute boundary so seconds never bleed into the result.
    private func snapToMinute(_ date: Date) -> Date {
        Date(timeIntervalSince1970: floor(date.timeIntervalSince1970 / 60) * 60)
    }

    private func monthAbbrev(from date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM"
        fmt.locale = Locale(identifier: "en_US")
        return fmt.string(from: date).uppercased()
    }
}

#Preview { CalculateView() }
