//
//  ColorPickerSheet.swift
//  countdownApp
//
//  Sheet that lets the user pick an accent color for a free slot.
//  Opens from CountdownDetailView via the paintbrush button.
//  Shows all AppTheme.freeColors as circular swatches.
//  One "auto" swatch resets to the hash-based fallback (accentColorIndex = nil).
//

import SwiftUI

struct ColorPickerSheet: View {

    @Binding var selectedIndex: Int?
    @Environment(\.dismiss) private var dismiss

    // Grid: 4 columns
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 4)
    @State private var sheetWidth: CGFloat = 340

    var body: some View {
        VStack(spacing: 0) {

            // ── Title + X dismiss ────────────────────────────────────────
            ZStack(alignment: .topTrailing) {
                Text("PICK A COLOR")
                    .font(AppTheme.alienLeagueBold(20))
                    .foregroundStyle(AppTheme.dark.opacity(0.85))
                    .kerning(2)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 28)
                    .padding(.bottom, 20)

                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppTheme.dark.opacity(0.5))
                        .frame(width: 26, height: 26)
                        .background(AppTheme.dark.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .focusable(false)
                .accessibilityLabel("Close")
                .padding(.top, 12)
                .padding(.trailing, 14)
            }

            // ── Swatch grid ─────────────────────────────────────────────
            LazyVGrid(columns: columns, spacing: 16) {

                // "Auto" swatch — resets to hash-based color
                // opacity(0.70): avoids glare on the amber background
                swatchButton(color: Color.white.opacity(0.60),
                             index: nil,
                             label: "AUTO")

                // Palette swatches
                ForEach(Array(AppTheme.freeColors.enumerated()), id: \.offset) { idx, color in
                    swatchButton(color: color, index: idx, label: nil)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .frame(minWidth: sheetWidth, maxWidth: sheetWidth, minHeight: 260)
        .onAppear {
            let windowMargin: CGFloat = 24
            let windowWidth = NSApp.mainWindow?.frame.width
                ?? NSApp.windows.first(where: { $0.isVisible })?.frame.width
                ?? 600
            sheetWidth = max(300, min(420, windowWidth - windowMargin))
        }
    }

    // MARK: - Swatch button

    @ViewBuilder
    private func swatchButton(color: Color, index: Int?, label: String?) -> some View {
        let isSelected = (selectedIndex == index)
        // G-5: palette swatches (label == nil) are plain color circles with no text
        // child, so VoiceOver needs an explicit description. The "AUTO" swatch already
        // has a visible Text label that SwiftUI folds into the button's accessibility
        // label automatically, but we still normalize it here for a consistent voice.
        let accessibilityText = label.map { "\($0) color" } ?? "Color \((index ?? 0) + 1)"
        Button {
            selectedIndex = index
            dismiss()
        } label: {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 52, height: 52)
                    .shadow(color: color.opacity(0.4), radius: isSelected ? 5 : 0)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                Color.white.opacity(isSelected ? 0.85 : 0.18),
                                lineWidth: isSelected ? 2 : 1.5
                            )
                    )

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppTheme.dark.opacity(0.75))
                } else if let label {
                    Text(label)
                        .font(AppTheme.alienLeague(12))
                        .foregroundStyle(AppTheme.dark.opacity(0.85))
                        .kerning(1)
                }
            }
        }
        .buttonStyle(.plain)
        .focusable(false)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
