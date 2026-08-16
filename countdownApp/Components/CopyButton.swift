//
//  CopyButton.swift
//  countdownApp
//
//  Generic copy-to-clipboard button that owns the NSPasteboard write,
//  the feedback Task, and the isCopied state.
//
//  The caller supplies a @ViewBuilder label closure that receives `isCopied`
//  so it can switch icons, tints, or any other visual detail — the component
//  owns the logic, the call site owns the presentation.
//
//  Usage:
//      CopyButton(
//          value: someString,
//          defaultAccessibilityLabel: "Copy label",
//          copiedAccessibilityLabel: "Label copied"
//      ) { isCopied in
//          Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
//              .frame(width: 32, height: 32)
//              // ... caller-owned styling ...
//      }
//

import SwiftUI
import AppKit

struct CopyButton<Label: View>: View {

    let value: String
    let defaultAccessibilityLabel: String
    let copiedAccessibilityLabel: String
    var feedbackDuration: Duration = .milliseconds(1000)
    @ViewBuilder let label: (_ isCopied: Bool) -> Label

    @State private var isCopied = false

    var body: some View {
        Button { performCopy() } label: { label(isCopied) }
            .buttonStyle(.plain)
            .focusEffectDisabled()
            .accessibilityLabel(isCopied ? copiedAccessibilityLabel : defaultAccessibilityLabel)
            .help(isCopied ? copiedAccessibilityLabel : defaultAccessibilityLabel)
    }

    private func performCopy() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
        isCopied = true
        Task {
            try? await Task.sleep(for: feedbackDuration)
            isCopied = false
        }
    }
}
