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
        .frame(minWidth: 460)
    }

    // MARK: - Mode button

    @ViewBuilder
    private func modeButton(_ mode: Mode) -> some View {
        let selected = selectedMode == mode

        Button {
            selectedMode = mode
        } label: {
            Text(mode.rawValue)
                .font(AppTheme.alienLeagueBold(20))
                .foregroundStyle(Color.white)
                .opacity(selected ? 1.0 : 0.45)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppTheme.dark)
                        .opacity(selected ? 1.0 : 0.0)
                )
        }
        .buttonStyle(.plain)
        .focusable(false)
        .accessibilityLabel(mode.rawValue)
    }
}

#Preview { ContentView() }
