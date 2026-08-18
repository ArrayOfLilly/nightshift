//
//  CountdownDetailView.swift
//  countdownApp
//
//  Full-screen "Spooky Tomato" single-item countdown.
//  The countdown text is overlaid on the tomato body, matching the timer.png reference.
//  Reached via NavigationLink from CountdownView.
//  Deadline is editable via component steppers (year/month/day/hour/minute).
//
//  Label editing uses FocusedNSTextField (FocusedNSTextField.swift) — see that
//  file for the rationale (AppKit first-responder vs. SwiftUI FocusBridge crash).
//
//  SOUND-1: Sound toggle button added to the bottom button row (all slot types).
//  speaker.wave.2.fill when enabled, speaker.slash.fill when disabled.
//  Writes directly to item.soundEnabled via @Binding, propagated to CountdownView
//  and persisted automatically via the existing .onChange(of: items) → save() chain.
//
//  TIME DISPLAY SIZING: The remaining/deadline text is overlaid on the tomato image
//  via .overlay { GeometryReader } so its maxWidth always tracks the actual rendered
//  image width. The text can never overflow the tomato body regardless of window size.
//  The tomato body fills ~62 % of the image width; minimumScaleFactor allows further
//  shrinking before layout gives up.
//
//  SLOT-NOTES: Notes button opens NotesSheet as a sheet.
//  Icon-only state indicator (no opacity dimming — user preference):
//  note.text.badge.plus when notes are empty (signals "additive/add mode"),
//  note.text when notes are non-empty. Both states full AppTheme.background/
//  AppTheme.dark opacity. Writes item.notes via @Binding → auto-persisted.
//

import SwiftUI
import AppKit

// MARK: - CountdownDetailView

struct CountdownDetailView: View {

    @Binding var item: CountdownItem
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var isEditing: Bool = false
    @State private var showColorPicker: Bool = false
    @State private var showNotes: Bool = false
    @State private var showDeleteConfirm: Bool = false
    /// Local to this view (not item.showRemaining, which is the row's own toggle) —
    /// the detail screen always opens showing remaining time, regardless of what the
    /// row list was last toggled to.
    @State private var showRemaining: Bool = true
    /// Local mirror of item.deadline — drives immediate stepper visual feedback.
    @State private var localDeadline: Date = Date()

    private var cal: Calendar { Calendar.current }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            // G-1: ScrollView + minHeight so short windows scroll instead of
            // clipping the tomato/buttons; the Spacer-driven centered layout
            // is preserved whenever the window is tall enough.
            GeometryReader { outerGeo in
                ScrollView {
                    detailContent
                        .frame(minHeight: outerGeo.size.height)
                }
            }
        }
            .navigationTitle("")
            .onAppear {
            let now = Date()
            item.resetIfExpired(at: now)
            localDeadline = item.deadline
        }
    }

    private var detailContent: some View {
            VStack(spacing: 0) {

                // ── Account label — tap to edit ──
                HStack(alignment: .center, spacing: 12) {
                    if isEditing {
                        FocusedNSTextField(text: $item.label) {
                            isEditing = false
                        }
                            .frame(height: 36)
                            .padding(.bottom, 2)
                            .overlay(alignment: .bottom) {
                            Rectangle()
                                .frame(height: 1.5)
                                .foregroundStyle(AppTheme.dark.opacity(AppTheme.alpha35))
                        }
                    } else {
                        Text(item.label.isEmpty ? String(localized: "countdown.label.placeholder") : item.label.uppercased())
                            .font(AppTheme.alienLeagueBold(24))
                            .foregroundStyle(AppTheme.dark.opacity(AppTheme.alpha75))
                            .kerning(4)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .onTapGesture {
                            isEditing = true
                        }
                    }

                    CopyButton(
                        value: item.label.trimmingCharacters(in: .whitespaces),
                        defaultAccessibilityLabel: String(localized: "Copy label"),
                        copiedAccessibilityLabel: String(localized: "Label copied")
                    ) { isCopied in
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(AppTheme.dark.opacity(AppTheme.alpha90))
                            .frame(width: 32, height: 32)
                            .background(AppTheme.dark.opacity(0.18))
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium))
                    }
                }
                    .padding(.horizontal, 24)
                    .padding(.top, 28)

                Spacer()

                // ── Tomato + overlaid time ────────────────────────────────
                TimelineView(.periodic(from: .now, by: 1.0)) { ctx in
                    Image("spooky_tomato")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 500, maxHeight: 500)
                        .overlay {
                        GeometryReader { geo in
                            let bodyWidth = min(geo.size.width, geo.size.height) * 0.62
                            timeDisplay(at: ctx.date, maxWidth: bodyWidth)
                                .position(
                                x: geo.size.width / 2,
                                y: geo.size.height / 2 + 42
                            )
                        }
                    }
                }

                Spacer()

                // ── Deadline stepper ──────────────────────────────────────
                deadlineStepper
                    .padding(.bottom, 16)

                // ── Bottom buttons ────────────────────────────────────────
                HStack(spacing: 20) {
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
                            .padding(.vertical, 9)
                            .background(AppTheme.dark)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium))
                    }
                        .buttonStyle(.plain)
                        .focusEffectDisabled()
                        .help(showRemaining ? String(localized: "Show the exact deadline date instead of the countdown") : String(localized: "Show the remaining time until the deadline"))

                    HStack(spacing: 8) {
                        // ── Color picker — only for free (expired) slots ──
                        if item.isExpired(at: Date()) {
                            Button {
                                showColorPicker = true
                            } label: {
                                Image(systemName: "paintbrush")
                                    .foregroundStyle(AppTheme.background)
                                    .frame(width: 32, height: 32)
                                    .background(AppTheme.dark)
                                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium))
                            }
                                .buttonStyle(.plain)
                                .focusEffectDisabled()
                                .accessibilityLabel(Text("Pick color"))
                                .help(String(localized: "Change the accent color of this free slot"))
                                .sheet(isPresented: $showColorPicker) {
                                ColorPickerSheet(selectedIndex: $item.accentColorIndex)
                            }
                        }

                        // ── Sound toggle — all slot types ──────────────────────
                        Button {
                            item.soundEnabled.toggle()
                        } label: {
                            Image(systemName: item.soundEnabled
                                ? "speaker.wave.2.fill"
                            : "speaker.slash.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(item.soundEnabled
                                ? AppTheme.background : AppTheme.background.opacity(1.0))
                                .frame(width: 32, height: 32)
                                .background(item.soundEnabled
                                ? AppTheme.dark : AppTheme.dark.opacity(1.0))
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium))
                        }
                            .buttonStyle(.plain)
                            .focusEffectDisabled()
                            .accessibilityLabel(item.soundEnabled ? Text("Mute sound") : Text("Unmute sound"))
                            .help(item.soundEnabled ? String(localized: "Disable the expiry sound for this slot") : String(localized: "Play a sound when this slot's deadline is reached"))

                        // ── Notes — all slot types (SLOT-NOTES) ───────────────
                        // note.text.fill + amber tint when non-empty; dim when empty.
                        Button {
                            showNotes = true
                        } label: {
                            Image(systemName: item.notes.isEmpty ?  "note.text.badge.plus" : "note.text" )
                                .font(.system(size: 16))
                                .foregroundStyle(item.notes.isEmpty
                            ? AppTheme.background.opacity(1.0) : AppTheme.background)
                                .frame(width: 32, height: 32)
                                .background(item.notes.isEmpty
                                            ? AppTheme.dark.opacity(1.0) : AppTheme.dark)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium))
                        }
                            .buttonStyle(.plain)
                            .focusEffectDisabled()
                            .accessibilityLabel(item.notes.isEmpty ? Text("Add notes") : Text("View notes"))
                            .help(item.notes.isEmpty ? String(localized: "Open the note editor to add notes to this slot") : String(localized: "View and edit the markdown notes for this slot"))
                            .sheet(isPresented: $showNotes) {
                            NotesSheet(slotLabel: item.label, notes: $item.notes)
                        }
                    }

                    Button { showDeleteConfirm = true } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(AppTheme.background)
                            .frame(width: 32, height: 32)
                            .background(AppTheme.dark)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium))
                    }
                        .buttonStyle(.plain)
                        .focusEffectDisabled()
                        .accessibilityLabel(Text("Delete countdown"))
                        .help(String(localized: "Permanently remove this countdown slot"))
                        .alert("Delete \"\(item.label)\"?", isPresented: $showDeleteConfirm) {
                            Button("Delete", role: .destructive) { onDelete(); dismiss() }
                            Button("Cancel", role: .cancel) { }
                        } message: {
                            Text("This slot will be permanently removed.")
                        }
                }
                    .padding(.bottom, 36)
            }
    }

    // MARK: - Deadline stepper

    private var deadlineStepper: some View {
        HStack(spacing: 10) {
            ComponentStepper(
                label: "YEAR",
                unit: "year",
                value: String(component(.year)),
                onInc: { adjust(.year, by: 1) },
                onDec: { adjust(.year, by: -1) }
            )
            ComponentStepper(
                label: "MON",
                unit: "month",
                value: Formatters.monthAbbrev.string(from: localDeadline).uppercased(),
                onInc: { adjust(.month, by: 1) },
                onDec: { adjust(.month, by: -1) }
            )
            ComponentStepper(
                label: "DAY",
                unit: "day",
                value: String(format: "%02d", component(.day)),
                onInc: { adjust(.day, by: 1) },
                onDec: { adjust(.day, by: -1) }
            )
            ComponentStepper(
                label: "HOUR",
                unit: "hour",
                value: String(format: "%02d", component(.hour)),
                onInc: { adjust(.hour, by: 1) },
                onDec: { adjust(.hour, by: -1) }
            )
            ComponentStepper(
                label: "MIN",
                unit: "minute",
                value: String(format: "%02d", component(.minute)),
                onInc: { adjust(.minute, by: 1) },
                onDec: { adjust(.minute, by: -1) }
            )
        }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(AppTheme.dark.opacity(AppTheme.alpha12))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLarge))
            .padding(.horizontal, 24)
    }

    // MARK: - Time display

    @ViewBuilder
    private func timeDisplay(at now: Date, maxWidth: CGFloat) -> some View {
        let w = maxWidth > 0 ? maxWidth : 280
        if showRemaining {
            let expired = item.isExpired(at: now)
            Text(expired ? String(localized: "EXPIRED") : item.remainingFormatted(at: now))
                .font(AppTheme.alienLeagueBold(56))
                .foregroundStyle(expired ? Color.red : AppTheme.timerText)
                .monospacedDigit()
                .minimumScaleFactor(0.3)
                .lineLimit(1)
                .frame(maxWidth: w)
                .multilineTextAlignment(.center)
        } else {
            Text(item.deadlineFormatted)
                .font(AppTheme.alienLeague(44))
                .foregroundStyle(AppTheme.timerText)
                .minimumScaleFactor(0.3)
                .lineLimit(1)
                .frame(maxWidth: w)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Helpers

    private func component(_ c: Calendar.Component) -> Int {
        cal.component(c, from: localDeadline)
    }

    private func adjust(_ c: Calendar.Component, by value: Int) {
        item.adjustDeadline(c, by: value)
        localDeadline = item.deadline
    }

}
