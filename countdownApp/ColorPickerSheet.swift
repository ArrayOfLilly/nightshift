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

    var body: some View {
        VStack(spacing: 0) {

            // ── Title ───────────────────────────────────────────────────
            Text("PICK A COLOR")
                .font(AppTheme.alienLeagueBold(20))
                .foregroundStyle(AppTheme.dark.opacity(0.85))
                .kerning(2)
                .padding(.top, 28)
                .padding(.bottom, 20)

            // ── Swatch grid ─────────────────────────────────────────────
            LazyVGrid(columns: columns, spacing: 16) {

                // "Auto" swatch — resets to hash-based color
                swatchButton(color: Color.white,
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
        .frame(minWidth: 300, minHeight: 260)
    }

    // MARK: - Swatch button

    @ViewBuilder
    private func swatchButton(color: Color, index: Int?, label: String?) -> some View {
        let isSelected = (selectedIndex == index)
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
                                lineWidth: isSelected ? 3 : 1.5
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
    }
}
