// HelpScreenshot.swift
// countdownApp
//
// Displays a pre-cropped screenshot asset at a fixed width inside a Help
// List row. Height is derived from each asset's known pixel dimensions
// (aspect ratio is scale-factor-independent).
//
// History:
//   ENH-HELP-1-S3 — Canvas crop with focusRect
//   ENH-HELP-1-S4 — fit-width redesign
//   ENH-HELP-1-S4 (this) — pre-cropped assets (incl. rounding), Canvas for display

import SwiftUI

struct HelpScreenshot: View {
    let imageName: String
    /// Fixed display width. Height is derived from the asset's pixel
    /// aspect ratio — no distortion, no clipping of content.
    let maxWidth: CGFloat

    /// Known pixel dimensions of each help screenshot asset.
    /// Aspect ratio is scale-factor-independent, so raw pixel w/h is fine.
    private static let pixelSizes: [String: CGSize] = [
        "help-countdown-notes":    CGSize(width: 1104, height: 208),
        "help-calculate-sunpanel": CGSize(width: 1020, height: 1202),
        "calculated-days":         CGSize(width: 460, height: 197),
        "calculated-epochs":       CGSize(width: 460, height: 197),
    ]

    private var displayHeight: CGFloat {
        guard let px = Self.pixelSizes[imageName], px.width > 0 else {
            return maxWidth * 0.5
        }
        return maxWidth * px.height / px.width
    }

    var body: some View {
        let h = displayHeight
        Canvas { context, size in
            let resolved = context.resolve(Image(imageName))
            context.draw(resolved, in: CGRect(origin: .zero, size: size))
        }
        .frame(width: maxWidth, height: h)
    }
}
