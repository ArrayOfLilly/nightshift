// HelpContent.swift
// countdownApp
//
// Help system data models — IconKeeper pattern.
// UI (HelpView, HelpCommands, HelpWindowID) is added in ENH-HELP-1-S2.
// Real string content is filled in ENH-HELP-1-S4 through S6.

import SwiftUI

// MARK: - HelpItem

struct HelpItem: Identifiable {
    let id: String
    let titleKey: LocalizedStringKey
    let bodyKey: LocalizedStringKey
    let icon: String
    /// Asset name in Assets.xcassets. Nil if this item has no screenshot.
    let imageName: String?
    /// Normalized focus rect (0–1) for HelpScreenshot crop. Nil when imageName is nil.
    let focusRect: CGRect?

    init(
        id: String,
        titleKey: LocalizedStringKey,
        bodyKey: LocalizedStringKey,
        icon: String,
        imageName: String? = nil,
        focusRect: CGRect? = nil
    ) {
        self.id = id
        self.titleKey = titleKey
        self.bodyKey = bodyKey
        self.icon = icon
        self.imageName = imageName
        self.focusRect = focusRect
    }
}

// MARK: - HelpSection

struct HelpSection: Identifiable {
    let id: String
    let titleKey: LocalizedStringKey
    let items: [HelpItem]
}

// MARK: - HelpContent

/// Static catalog of all help sections and items.
/// Keyword search (ENH-HELP-1-S2) filters by item.id — no separate searchTokens needed.
enum HelpContent {
    static let sections: [HelpSection] = [
        overview,
        countdown,
        calculate,
        snippets,
        recovery
    ]

    // MARK: Overview

    static let overview = HelpSection(
        id: "overview",
        titleKey: "help.section.overview.title",
        items: [
            HelpItem(
                id: "overview.what",
                titleKey: "help.overview.what.title",
                bodyKey: "help.overview.what.body",
                icon: "star",
                // Geometry test asset for HelpScreenshot (ENH-HELP-1-S3).
                // Real countdownApp screenshots are added in ENH-HELP-1-S4 through S6.
                imageName: "screenshot",
                focusRect: CGRect(x: 0.15, y: 0.2, width: 0.5, height: 0.4)
            ),
            HelpItem(
                id: "overview.views",
                titleKey: "help.overview.views.title",
                bodyKey: "help.overview.views.body",
                icon: "rectangle.3.group"
            )
        ]
    )

    // MARK: Countdown

    static let countdown = HelpSection(
        id: "countdown",
        titleKey: "help.section.countdown.title",
        items: [
            HelpItem(
                id: "countdown.add",
                titleKey: "help.countdown.add.title",
                bodyKey: "help.countdown.add.body",
                icon: "plus.circle"
            ),
            HelpItem(
                id: "countdown.edit",
                titleKey: "help.countdown.edit.title",
                bodyKey: "help.countdown.edit.body",
                icon: "pencil"
            ),
            HelpItem(
                id: "countdown.notes",
                titleKey: "help.countdown.notes.title",
                bodyKey: "help.countdown.notes.body",
                icon: "note.text"
            ),
            HelpItem(
                id: "countdown.reorder",
                titleKey: "help.countdown.reorder.title",
                bodyKey: "help.countdown.reorder.body",
                icon: "arrow.up.arrow.down"
            )
        ]
    )

    // MARK: Calculate

    static let calculate = HelpSection(
        id: "calculate",
        titleKey: "help.section.calculate.title",
        items: [
            HelpItem(
                id: "calculate.deadlines",
                titleKey: "help.calculate.deadlines.title",
                bodyKey: "help.calculate.deadlines.body",
                icon: "calendar"
            ),
            HelpItem(
                id: "calculate.sunpanel",
                titleKey: "help.calculate.sunpanel.title",
                bodyKey: "help.calculate.sunpanel.body",
                icon: "sun.horizon"
            )
        ]
    )

    // MARK: Snippets

    static let snippets = HelpSection(
        id: "snippets",
        titleKey: "help.section.snippets.title",
        items: [
            HelpItem(
                id: "snippets.what",
                titleKey: "help.snippets.what.title",
                bodyKey: "help.snippets.what.body",
                icon: "doc.text"
            ),
            HelpItem(
                id: "snippets.edit",
                titleKey: "help.snippets.edit.title",
                bodyKey: "help.snippets.edit.body",
                icon: "pencil.and.list.clipboard"
            )
        ]
    )

    // MARK: Recovery

    static let recovery = HelpSection(
        id: "recovery",
        titleKey: "help.section.recovery.title",
        items: [
            HelpItem(
                id: "recovery.backup",
                titleKey: "help.recovery.backup.title",
                bodyKey: "help.recovery.backup.body",
                icon: "externaldrive"
            )
        ]
    )
}
