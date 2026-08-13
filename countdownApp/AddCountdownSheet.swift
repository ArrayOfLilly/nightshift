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
    @State private var sheetWidth: CGFloat = 420

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
                        .background(AppTheme.dark.opacity(AppTheme.alpha12))
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium))
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
                                ? Color.white.opacity(AppTheme.alpha75)
                                : AppTheme.background)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(label.trimmingCharacters(in: .whitespaces).isEmpty
                                ? AppTheme.dark.opacity(0.3)
                                : AppTheme.dark)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium))
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
        .frame(minWidth: sheetWidth, maxWidth: sheetWidth)
        .onAppear {
            sheetWidth = WindowHelpers.windowConstrainedWidth(min: 380, max: 560)
        }
    }

    // MARK: - Deadline stepper

    private var deadlineStepper: some View {
        HStack(spacing: 10) {
            ComponentStepper(
                label: "YEAR",
                unit: "year",
                value: String(cal.component(.year, from: deadline)),
                onInc: { adjust(.year,   by:  1) },
                onDec: { adjust(.year,   by: -1) }
            )
            ComponentStepper(
                label: "MON",
                unit: "month",
                value: Formatters.monthAbbrev.string(from: deadline).uppercased(),
                onInc: { adjust(.month,  by:  1) },
                onDec: { adjust(.month,  by: -1) }
            )
            ComponentStepper(
                label: "DAY",
                unit: "day",
                value: String(format: "%02d", cal.component(.day,    from: deadline)),
                onInc: { adjust(.day,    by:  1) },
                onDec: { adjust(.day,    by: -1) }
            )
            ComponentStepper(
                label: "HOUR",
                unit: "hour",
                value: String(format: "%02d", cal.component(.hour,   from: deadline)),
                onInc: { adjust(.hour,   by:  1) },
                onDec: { adjust(.hour,   by: -1) }
            )
            ComponentStepper(
                label: "MIN",
                unit: "minute",
                value: String(format: "%02d", cal.component(.minute, from: deadline)),
                onInc: { adjust(.minute, by:  1) },
                onDec: { adjust(.minute, by: -1) }
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(AppTheme.dark.opacity(AppTheme.alpha12))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLarge))
    }

    private func adjust(_ c: Calendar.Component, by value: Int) {
        if let d = cal.date(byAdding: c, value: value, to: deadline) { deadline = d }
    }

}
