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
//  SOUND-1: Sound toggle button added to the bottom button row (all slot types).
//  speaker.wave.2.fill when enabled, speaker.slash.fill when disabled.
//  Writes directly to item.soundEnabled via @Binding, propagated to CountdownView
//  and persisted automatically via the existing .onChange(of: items) → save() chain.
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

                    // ── Sound toggle — all slot types ──────────────────────
                    // SOUND-1: toggles item.soundEnabled; persists via @Binding →
                    // CountdownView.items → .onChange(of: items) → save().
                    Button {
                        item.soundEnabled.toggle()
                    } label: {
                        Image(systemName: item.soundEnabled
                              ? "speaker.wave.2.fill"
                              : "speaker.slash.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(item.soundEnabled
                                            ? AppTheme.background
                                            : AppTheme.background.opacity(0.4))
                            .frame(width: 44, height: 44)
                            .background(item.soundEnabled
                                        ? AppTheme.dark
                                        : AppTheme.dark.opacity(0.45))
                            .clipShape(RoundedRectangle(cornerRadius: 9))
                    }
                    .focusable(false)

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
