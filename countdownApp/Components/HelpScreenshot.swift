// HelpScreenshot.swift
// countdownApp
//
// Cropped screenshot view for Help items. Displays the region of an
// Assets.xcassets image defined by a normalized (0–1) focusRect, uniformly
// scaled (no distortion) to cover a fixed targetSize.
//
// The image's real intrinsic size is read via NSImage(named:) so the crop
// rect can be computed in actual point space; a single uniform scale factor
// (not independent x/y scaling) is then applied, so the result is always a
// plain crop + zoom — never a stretch. If focusRect's aspect ratio doesn't
// match targetSize's aspect ratio, the overflow is trimmed from the
// bottom/right edge (top-left anchored) — pick a focusRect with a matching
// aspect ratio for an exact, centered frame.
//
// ENH-HELP-1-S3

import SwiftUI
import AppKit

struct HelpScreenshot: View {
    let imageName: String
    /// Normalized (0–1) crop region in image space. width/height must be > 0.
    let focusRect: CGRect
    let targetSize: CGSize

    private var imageSize: CGSize {
        NSImage(named: imageName)?.size ?? targetSize
    }

    var body: some View {
        let size = imageSize
        let cropRect = CGRect(
            x: focusRect.minX * size.width,
            y: focusRect.minY * size.height,
            width: focusRect.width * size.width,
            height: focusRect.height * size.height
        )
        let scale = max(targetSize.width / cropRect.width, targetSize.height / cropRect.height)

        ZStack(alignment: .topLeading) {
            Image(imageName)
                .resizable()
                .frame(width: size.width * scale, height: size.height * scale)
                .offset(x: -cropRect.minX * scale, y: -cropRect.minY * scale)
        }
        .frame(width: targetSize.width, height: targetSize.height)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium, style: .continuous))
    }
}
