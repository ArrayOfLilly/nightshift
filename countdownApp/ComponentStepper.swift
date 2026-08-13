//
//  ComponentStepper.swift
//  countdownApp
//
//  A labeled date-component stepper: unit label above, value text in the middle,
//  LongPressStepperButton for increment and decrement.
//  Used in AddCountdownSheet, CountdownDetailView, and CalculateView.
//

import SwiftUI

struct ComponentStepper: View {

    let label: String
    let unit: String
    let value: String
    let onInc: () -> Void
    let onDec: () -> Void
    var foregroundColor: Color = AppTheme.dark
    var backgroundColor: Color = AppTheme.dark.opacity(0.12)

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(AppTheme.alienLeague(10))
                .foregroundStyle(foregroundColor.opacity(0.6))
            LongPressStepperButton(
                systemImage: "chevron.up",
                action: onInc,
                foregroundColor: foregroundColor,
                backgroundColor: backgroundColor,
                accessibilityLabel: "Increase \(unit)"
            )
            Text(value)
                .font(AppTheme.alienLeagueBold(15))
                .foregroundStyle(foregroundColor)
                .frame(minWidth: 36)
                .multilineTextAlignment(.center)
            LongPressStepperButton(
                systemImage: "chevron.down",
                action: onDec,
                foregroundColor: foregroundColor,
                backgroundColor: backgroundColor,
                accessibilityLabel: "Decrease \(unit)"
            )
        }
        .frame(maxWidth: .infinity)
    }
}
