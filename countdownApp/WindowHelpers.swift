//
//  WindowHelpers.swift
//  countdownApp
//
//  Shared window geometry helpers for sheets and popovers.
//
//  NSApp.mainWindow is preferred over keyWindow: once a sheet is presented,
//  the sheet's own child window can become key while the content window
//  stays main. The title-filtered fallback handles the edge case where
//  mainWindow is nil at the point of first appearance.
//

import AppKit

enum WindowHelpers {

    /// Width of the presenting window, clamped to [min, max], with `margin`
    /// subtracted so the sheet never overhangs the window edges.
    static func windowConstrainedWidth(
        min: CGFloat,
        max: CGFloat,
        margin: CGFloat = 24,
        fallback: CGFloat = 600
    ) -> CGFloat {
        let width = NSApp.mainWindow?.frame.width
            ?? NSApp.windows.first(where: { $0.isVisible && $0.title == "countdownApp" })?.frame.width
            ?? fallback
        return Swift.min(max, Swift.max(min, width - margin))
    }

    /// Height of the presenting window, clamped to [min, max], with `margin`
    /// subtracted so the sheet never overhangs the window edges.
    static func windowConstrainedHeight(
        min: CGFloat,
        max: CGFloat,
        margin: CGFloat = 24,
        fallback: CGFloat = 800
    ) -> CGFloat {
        let height = NSApp.mainWindow?.frame.height
            ?? NSApp.windows.first(where: { $0.isVisible && $0.title == "countdownApp" })?.frame.height
            ?? fallback
        return Swift.min(max, Swift.max(min, height - margin))
    }
}
