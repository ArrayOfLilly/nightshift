//
//  FocusedNSTextField.swift
//  countdownApp
//
//  NSViewRepresentable wrapper for a plain NSTextField styled to match the
//  Alien League Bold 36pt label in CountdownDetailView.
//
//  Uses NSTextField's own first-responder lifecycle (AppKit) instead of SwiftUI
//  FocusBridge, which crashes when focus is requested before the view is attached
//  to a window (e.g. inside a NavigationLink destination with a TimelineView tick).
//
//  Font and color are set once in makeNSView so that updateNSView — called on
//  every TimelineView tick — does not recreate NSFont each second.
//

import SwiftUI
import AppKit

struct FocusedNSTextField: NSViewRepresentable {

    @Binding var text: String
    var onCommit: () -> Void

    func makeNSView(context: Context) -> NSTextField {
        let tf = NSTextField()
        tf.delegate = context.coordinator
        tf.isBordered = false
        tf.isBezeled = false
        tf.drawsBackground = false
        tf.focusRingType = .none
        tf.lineBreakMode = .byTruncatingTail
        tf.maximumNumberOfLines = 1
        // Font and color are static — set once here so updateNSView (called
        // on every TimelineView tick) does not recreate NSFont each second.
        if let font = NSFont(name: "AlienLeagueBold", size: 36)
            ?? NSFont(name: "Alien League Bold", size: 36) {
            tf.font = font
        } else {
            tf.font = NSFont.boldSystemFont(ofSize: 36)
        }
        tf.textColor = NSColor(AppTheme.dark).withAlphaComponent(0.8)
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.windowDidResignKey(_:)),
            name: NSWindow.didResignKeyNotification,
            object: nil
        )
        return tf
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        if !context.coordinator.isEditing {
            nsView.stringValue = text
        }
        // Font and color are set once in makeNSView; no work needed here.
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onCommit: onCommit)
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        @Binding var text: String
        var onCommit: () -> Void
        var isEditing: Bool = false

        init(text: Binding<String>, onCommit: @escaping () -> Void) {
            _text = text
            self.onCommit = onCommit
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }

        func controlTextDidBeginEditing(_ obj: Notification) {
            isEditing = true
            // Subtle white selection tint for active editing.
            if let tv = (obj.object as? NSTextField)?.currentEditor() as? NSTextView {
                tv.selectedTextAttributes = [
                    .backgroundColor: NSColor.white.withAlphaComponent(0.25),
                    .foregroundColor: NSColor(AppTheme.dark).withAlphaComponent(0.8)
                ]
            }
        }

        @objc func windowDidResignKey(_ notification: Notification) {
            // When the window loses focus, clear any lingering selection highlight.
            isEditing = false
            onCommit()
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let tf = obj.object as? NSTextField else { return }
            text = tf.stringValue
        }

        func controlTextDidEndEditing(_ obj: Notification) {
            isEditing = false
            // Clear selection so the inactive highlight does not remain visible
            // when the window loses focus mid-edit.
            if let tf = obj.object as? NSTextField {
                tf.currentEditor()?.selectedRange = NSRange(location: 0, length: 0)
            }
            onCommit()
        }

        func control(_ control: NSControl, textView: NSTextView,
                     doCommandBy selector: Selector) -> Bool {
            if selector == #selector(NSResponder.insertNewline(_:)) {
                onCommit()
                control.window?.makeFirstResponder(nil)
                return true
            }
            return false
        }
    }
}
