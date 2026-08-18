//
//  ContentView.swift
//  countdownApp
//
//  Root view. Owns the mode switcher (Calculate / Countdown / Snippets).
//  All mode-specific logic lives in CalculateView and CountdownView.
//  Mode switcher is a custom HStack of icon buttons (NOT the native segmented
//  Picker) so size, padding, and color are fully controllable — the native
//  macOS NSSegmentedControl ignores SwiftUI font/padding/foregroundStyle
//  modifiers on its label content.
//  Placeholder icons ("clock" / "at") can be swapped for custom assets later.
//

import SwiftUI

struct ContentView: View {

    enum Mode: String, CaseIterable, Identifiable {
        case calculate = "Calculate"
        case countdown = "Countdown"
        case snippets  = "Snippets"
        var id: String { rawValue }

        /// SF Symbol placeholder — swap for a custom icon asset if desired.
        var symbolName: String {
            switch self {
            case .calculate: return "clock"
            case .countdown: return "at"
            case .snippets:  return "doc.plaintext"
            }
        }
    }

    @State private var selectedMode: Mode = .countdown
    @AppStorage(AppKeys.fontSizeStep) private var fontSizeStep: Int = 0

    // ENH-SETTINGS-2 window-width fix: natural (unclamped) width of the mode switcher row,
    // measured live via ModeSwitcherWidthKey below. At larger font-size steps the switcher
    // labels grow wider than the base windowMinWidth, so this feeds back into the window's
    // frame instead of a hardcoded per-step pixel table — it also stays correct automatically
    // if the labels are ever localized (ENH-L10N-1 #9), since Hungarian labels are a different
    // length than the English ones.
    @State private var modeSwitcherWidth: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {

            // ── Mode switcher (custom, not native Picker) ────────────────────
            HStack(spacing: 20) {
                ForEach(Mode.allCases) { mode in
                    modeButton(mode)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            // .fixedSize forces this row to always report its true intrinsic width to the
            // GeometryReader below, even on a render pass where the window is still narrower
            // than the content wants (e.g. right after switching to a larger font-size step,
            // before the .frame(minWidth:) below has caught up).
            .fixedSize(horizontal: true, vertical: false)
            .background(
                GeometryReader { geo in
                    Color.clear.preference(key: ModeSwitcherWidthKey.self, value: geo.size.width)
                }
            )

            Divider()

            // ── Active mode ────────────────────────────────────────────────
            Group {
                switch selectedMode {
                case .calculate: CalculateView()
                case .countdown: CountdownView()
                case .snippets:  SnippetsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onPreferenceChange(ModeSwitcherWidthKey.self) { modeSwitcherWidth = $0 }
        .frame(
            // +40pt slack above the measured switcher width so the window stays freely
            // resizable even when modeSwitcherWidth alone would otherwise pin min == max.
            minWidth: max(AppTheme.windowMinWidth, modeSwitcherWidth),
            maxWidth: max(AppTheme.windowMaxWidth, modeSwitcherWidth + 40)
        )
    }

    // MARK: - Mode button

    @ViewBuilder
    private func modeButton(_ mode: Mode) -> some View {
        let selected = selectedMode == mode
        // Pre-localize the mode name itself before interpolating it into "Switch to %@" —
        // interpolating mode.rawValue directly would insert the raw English case name
        // (e.g. "Countdown") verbatim even in the Hungarian locale, since String.LocalizationValue
        // string interpolation does not recursively localize a plain String argument.
        let localizedModeName = String(localized: String.LocalizationValue(mode.rawValue))

        Button {
            selectedMode = mode
        } label: {
            Text(LocalizedStringKey(mode.rawValue))
                .font(AppTheme.alienLeagueBold(20))
                .foregroundStyle(Color.white)
                .opacity(selected ? 1.0 : AppTheme.alpha50)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.radiusMedium)
                        // Same near-black as calculateBackground (#060503) — not the usual
                        // AppTheme.dark brown. Elsewhere in the app AppTheme.dark sits on
                        // an explicit AppTheme.background (amber) fill set by each mode's own
                        // view, where brown reads fine. This mode-switcher row, above the
                        // Divider, has no such fill — it sits directly on the window's native
                        // macOS background (dark in Dark Mode), where the brown read as muddy.
                        // Deliberately scoped to just this button; AppTheme.dark stays
                        // unchanged everywhere else in the app. alpha90 (0.90) is the theme's
                        // strongest/near-opaque tint token.
                        .fill(AppTheme.calculateBackground.opacity(AppTheme.alpha90))
                        .opacity(selected ? 1.0 : 0.0)
                )
        }
        .buttonStyle(.plain)
        .focusEffectDisabled()
        .accessibilityLabel(LocalizedStringKey(mode.rawValue))
        .help(String(localized: String.LocalizationValue("Switch to \(localizedModeName)")))
    }
}

// MARK: - Mode switcher width measurement

/// Reports the natural (unclamped) width of the mode switcher row via a PreferenceKey, so
/// ContentView's window frame can grow at larger font-size steps (ENH-SETTINGS-2) instead of
/// clipping the Calculate/Countdown/Snippets labels. `reduce` keeps the largest reported value
/// in case of multiple contributors (not expected here, but keeps the key well-formed).
private struct ModeSwitcherWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

#Preview { ContentView() }
