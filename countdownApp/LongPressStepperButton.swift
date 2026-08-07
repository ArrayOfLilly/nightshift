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
