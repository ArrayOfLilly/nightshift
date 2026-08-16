//
//  NativeTooltip.swift
//  countdownApp
//
//  Registers an NSView.toolTip directly via AppKit, bypassing SwiftUI's .help()
//  modifier. SwiftUI's .help() relies on the responder chain and hover tracking
//  areas; these are unreliable when a .popover() presenter, DragGesture, or
//  GeometryReader sits in the same view hierarchy and swallows hover events.
//
//  Usage:
//      anyView
//          .nativeTooltip("Tooltip text here")
//
//  Implementation: an invisible NSViewRepresentable is placed as an overlay
//  with .allowsHitTesting(false) so it never intercepts clicks. The NSView
//  sets toolTip on appear and updates it if the string changes.
//

import SwiftUI
import AppKit

// MARK: - NSViewRepresentable

private struct TooltipNSView: NSViewRepresentable {

    let tooltip: String

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.toolTip = tooltip
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if nsView.toolTip != tooltip {
            nsView.toolTip = tooltip
        }
    }
}

// MARK: - View modifier

private struct NativeTooltipModifier: ViewModifier {

    let tooltip: String
    /// Extra padding (points) added around the view's layout frame so the
    /// tracking area is larger than the nominal SwiftUI frame. Useful when
    /// the visible element is offset or clipped relative to its layout rect.
    let padding: CGFloat

    func body(content: Content) -> some View {
        content.overlay(
            TooltipNSView(tooltip: tooltip)
                .padding(-padding)
                .allowsHitTesting(false)
        )
    }
}

// MARK: - View extension

extension View {
    /// Registers a tooltip via AppKit's NSView.toolTip directly, bypassing
    /// SwiftUI's .help() tracking-area mechanism. Use this where .help() is
    /// unreliable due to a .popover() presenter or gesture absorbing hover events.
    ///
    /// - Parameters:
    ///   - tooltip: The tooltip string to display.
    ///   - padding: Extra hit area in points around the layout frame (default 0).
    func nativeTooltip(_ tooltip: String, padding: CGFloat = 0) -> some View {
        modifier(NativeTooltipModifier(tooltip: tooltip, padding: padding))
    }
}
