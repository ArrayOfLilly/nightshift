// HelpCommands.swift
// countdownApp
//
// Registers the Help menu entry — replaces the default system Help menu item
// with a single "NightShift Help" button (Cmd+Shift+/).
// Mirrors the AboutCommands pattern (AboutView.swift).
//
// Architectural role:
// - Pure Commands struct; no store or service access
// - Inserted via .commands { HelpCommands() } in countdownAppApp.swift
// - Opens the help window via @Environment(\.openWindow) + HelpWindowID.id
//
// ENH-HELP-1-S2

import SwiftUI

// MARK: - Commands

struct HelpCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .help) {
            Button(NSLocalizedString("help.menu.item", comment: "Help menu item label")) {
                openWindow(id: HelpWindowID.id)
            }
            .keyboardShortcut("/", modifiers: [.command, .shift])
        }
    }
}
