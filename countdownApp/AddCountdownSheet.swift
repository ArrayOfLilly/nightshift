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
