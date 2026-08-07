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

    @State private var fromDate: Date = Date()
    @State private var toDate:   Date = Date()

    private var cal: Calendar { Calendar.current }

    var body: some View {
        ZStack {
            AppTheme.calculateBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // ── Title ─────────────────────────────────────────────
                    Text("CALCULATE")
                        .font(AppTheme.alienLeagueBold(32))
                        .foregroundStyle(AppTheme.background)
                        .kerning(4)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 20)

                    // ── From ──────────────────────────────────────────────
                    Text("FROM")
                        .font(AppTheme.alienLeague(20))
                        .foregroundStyle(Color.white.opacity(0.9))
                    dateStepper(date: $fromDate)

                    // ── To ────────────────────────────────────────────────
                    Text("TO")
                        .font(AppTheme.alienLeague(20))
                        .foregroundStyle(Color.white.opacity(0.9))
                    dateStepper(date: $toDate)

                    // ── Divider ───────────────────────────────────────────
                    Rectangle()
                        .fill(Color.white.opacity(0.25))
                        .frame(height: 1)
                        .padding(.vertical, 4)

                    // ── Result label ──────────────────────────────────────
                    Text(resultLabel.uppercased())
                        .font(AppTheme.alienLeague(20))
                        .foregroundStyle(Color.white.opacity(0.9))

                    // ── Result value (quantity large, unit small) ─────────
                    resultRow

                    // ── Illustration — pink moon phase series (Moon 3) ─────
                    // Each image gets an equal share of the available width (maxWidth: .infinity
                    // inside an HStack distributes space evenly on macOS without GeometryReader).
                    HStack(spacing: 12) {
                        ForEach(1...9, id: \.self) { i in
                            Image("pink_moon_\(i)")
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .opacity(0.85)
                        }
                    }
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
            Button(action: onInc) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.background)
                    .frame(width: 32, height: 22)
                    .background(Color.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .buttonStyle(.plain)
            Text(value)
                .font(AppTheme.alienLeagueBold(15))
                .foregroundStyle(AppTheme.background)
                .frame(minWidth: 36)
                .multilineTextAlignment(.center)
            Button(action: onDec) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.background)
                    .frame(width: 32, height: 22)
                    .background(Color.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .buttonStyle(.plain)
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
