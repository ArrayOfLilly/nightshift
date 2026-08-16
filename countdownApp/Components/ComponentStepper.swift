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
    var backgroundColor: Color = AppTheme.dark.opacity(AppTheme.alpha12)

    /// `unit` is passed as a lowercase xcstrings key ("year", "month", "day", "hour",
    /// "minute") from call sites — localize it before interpolating into the
    /// accessibility label so both the label and the unit itself are translated.
    private var localizedUnit: String { String(localized: String.LocalizationValue(unit)) }

    /// `label` is passed as an uppercase xcstrings key ("YEAR", "MON", "DAY", "HOUR",
    /// "MIN") from call sites. `Text(_ content: String)` renders a plain `String` verbatim
    /// (no xcstrings lookup) — only the `LocalizedStringKey` initializer localizes, so the
    /// key must be resolved explicitly here for the HU translation to actually appear.
    private var localizedLabel: String { String(localized: String.LocalizationValue(label)) }

    var body: some View {
        VStack(spacing: 4) {
            Text(localizedLabel)
                .font(AppTheme.alienLeague(10))
                .foregroundStyle(foregroundColor.opacity(AppTheme.alpha60))
            LongPressStepperButton(
                systemImage: "chevron.up",
                action: onInc,
                foregroundColor: foregroundColor,
                backgroundColor: backgroundColor,
                accessibilityLabel: String(localized: "Increase \(localizedUnit)")
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
                accessibilityLabel: String(localized: "Decrease \(localizedUnit)")
            )
        }
        .frame(maxWidth: .infinity)
        // ENH-TOOLTIP-1: .help() on the VStack rather than on LongPressStepperButton,
        // because DragGesture(minimumDistance:0) on the chevron Image absorbs hover
        // events and prevents the tooltip from firing on the button itself.
        // The VStack is gesture-free so hover is detected reliably.
        .help(String(format: String(localized: "Increase or decrease %@"), localizedUnit))
    }
}
