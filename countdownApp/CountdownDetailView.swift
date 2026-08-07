//
//  CountdownDetailView.swift
//  countdownApp
//
//  Full-screen "Spooky Tomato" single-item countdown.
//  The countdown text is overlaid on the tomato body, matching the timer.png reference.
//  Reached via NavigationLink from CountdownView.
//  Deadline is editable via component steppers (year/month/day/hour/minute).
//

import SwiftUI

struct CountdownDetailView: View {

    @Binding var item: CountdownItem
    let onDelete: () -> Void

    @State private var copyFeedback: Bool = false
    @State private var isEditing:    Bool = false
    @FocusState private var labelFocused: Bool
    /// Local to this view (not item.showRemaining, which is the row's own toggle) —
    /// the detail screen always opens showing remaining time, regardless of what the
    /// row list was last toggled to.
    @State private var showRemaining: Bool = true

    private var cal: Calendar { Calendar.current }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {

                // ── Account label — tap to edit ──
                HStack(alignment: .center, spacing: 12) {
                    if isEditing {
                        TextField("", text: $item.label)
                            .font(AppTheme.alienLeagueBold(36))
                            .foregroundStyle(AppTheme.dark.opacity(0.8))
                            .kerning(4)
                            .lineLimit(1)
                            .textFieldStyle(.plain)
                            .focused($labelFocused)
                            .onSubmit {
                                isEditing = false
                            }
                            .onChange(of: labelFocused) {
                                if !labelFocused { isEditing = false }
                            }
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
                                labelFocused = true
                            }
                    }

                    Button {
                        let trimmed = item.label.trimmingCharacters(in: .whitespaces)
                        #if os(macOS)
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(trimmed, forType: .string)
                        #else
                        UIPasteboard.general.string = trimmed
                        #endif
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

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundStyle(AppTheme.background)
                            .frame(width: 44, height: 44)
                            .background(AppTheme.dark)
                            .clipShape(RoundedRectangle(cornerRadius: 9))
                    }
                }
                .padding(.bottom, 36)
            }
        }
        .navigationTitle("")
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

            Button(action: onInc) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.dark)
                    .frame(width: 32, height: 22)
                    .background(AppTheme.dark.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .buttonStyle(.plain)

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
        let source = item.isExpired(at: Date()) ? Date() : item.deadline
        return cal.component(c, from: source)
    }

    private func adjust(_ c: Calendar.Component, by value: Int) {
        let base = item.isExpired(at: Date()) ? Date() : item.deadline
        if let newDate = cal.date(byAdding: c, value: value, to: base) {
            item.deadline = newDate
        }
    }

    private func monthAbbrev() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM"
        fmt.locale = Locale(identifier: "en_US")
        return fmt.string(from: item.deadline).uppercased()
    }
}
