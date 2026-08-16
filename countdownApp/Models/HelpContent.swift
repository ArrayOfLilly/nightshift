// HelpContent.swift
// countdownApp
//
// Help system data models — IconKeeper pattern.
// UI (HelpView, HelpCommands, HelpWindowID) is added in ENH-HELP-1-S2.
// Overview section content finalized in ENH-HELP-1-S4. Remaining sections
// (Countdown, Calculate, Snippets, Recovery) still carry placeholder text
// and are filled in ENH-HELP-1-S5/S6.

import SwiftUI

// MARK: - HelpItem

struct HelpItem: Identifiable {
    let id: String
    let titleKey: LocalizedStringKey
    let bodyKey: LocalizedStringKey
    let icon: String
    /// Asset name(s) in Assets.xcassets, in display order. Empty if this item has no screenshot.
    let imageNames: [String]

    init(
        id: String,
        titleKey: LocalizedStringKey,
        bodyKey: LocalizedStringKey,
        icon: String,
        imageNames: [String] = []
    ) {
        self.id = id
        self.titleKey = titleKey
        self.bodyKey = bodyKey
        self.icon = icon
        self.imageNames = imageNames
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
                icon: "star"
                // No screenshot: this item is a general description of the
                // app, not a specific UI element, so no single crop applies.
                // It briefly used the S3 geometry-test asset (timer.png) as
                // a placeholder — removed in ENH-HELP-1-S4 since it wasn't
                // an actual screenshot of anything and was confusing next
                // to real ones below.
            ),
            HelpItem(
                id: "overview.cooldowns",
                titleKey: "help.overview.cooldowns.title",
                bodyKey: "help.overview.cooldowns.body",
                icon: "clock.arrow.circlepath"
            ),
            HelpItem(
                id: "overview.schedule",
                titleKey: "help.overview.schedule.title",
                bodyKey: "help.overview.schedule.body",
                icon: "sunrise"
            ),
            HelpItem(
                id: "overview.views",
                titleKey: "help.overview.views.title",
                bodyKey: "help.overview.views.body",
                icon: "rectangle.3.group"
            ),
            HelpItem(
                id: "overview.tooltips",
                titleKey: "help.overview.tooltips.title",
                bodyKey: "help.overview.tooltips.body",
                icon: "cursorarrow"
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
                id: "countdown.expand",
                titleKey: "help.countdown.expand.title",
                bodyKey: "help.countdown.expand.body",
                icon: "rectangle.expand.vertical"
            ),
            HelpItem(
                id: "countdown.copy",
                titleKey: "help.countdown.copy.title",
                bodyKey: "help.countdown.copy.body",
                icon: "doc.on.doc"
            ),
            HelpItem(
                id: "countdown.toggle",
                titleKey: "help.countdown.toggle.title",
                bodyKey: "help.countdown.toggle.body",
                icon: "arrow.left.arrow.right"
            ),
            HelpItem(
                id: "countdown.free",
                titleKey: "help.countdown.free.title",
                bodyKey: "help.countdown.free.body",
                icon: "checkmark.circle"
            ),
            HelpItem(
                id: "countdown.notes",
                titleKey: "help.countdown.notes.title",
                bodyKey: "help.countdown.notes.body",
                icon: "note.text",
                imageNames: ["help-countdown-notes"]
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
                id: "calculate.stepper",
                titleKey: "help.calculate.stepper.title",
                bodyKey: "help.calculate.stepper.body",
                icon: "chevron.up.chevron.down"
            ),
            HelpItem(
                id: "calculate.reset",
                titleKey: "help.calculate.reset.title",
                bodyKey: "help.calculate.reset.body",
                icon: "arrow.counterclockwise"
            ),
            HelpItem(
                id: "calculate.toggle",
                titleKey: "help.calculate.toggle.title",
                bodyKey: "help.calculate.toggle.body",
                icon: "calendar",
                imageNames: ["calculated-days", "calculated-epochs"]
            ),
            HelpItem(
                id: "calculate.deadlines",
                titleKey: "help.calculate.deadlines.title",
                bodyKey: "help.calculate.deadlines.body",
                icon: "calendar"
            ),
            HelpItem(
                id: "calculate.load",
                titleKey: "help.calculate.load.title",
                bodyKey: "help.calculate.load.body",
                icon: "square.and.arrow.down"
            ),
            HelpItem(
                id: "calculate.sunpanel",
                titleKey: "help.calculate.sunpanel.title",
                bodyKey: "help.calculate.sunpanel.body",
                icon: "sun.horizon",
                imageNames: ["help-calculate-sunpanel"]
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
                id: "snippets.copy",
                titleKey: "help.snippets.copy.title",
                bodyKey: "help.snippets.copy.body",
                icon: "doc.on.doc"
            ),
            HelpItem(
                id: "snippets.edit",
                titleKey: "help.snippets.edit.title",
                bodyKey: "help.snippets.edit.body",
                icon: "pencil.and.list.clipboard"
            ),
            HelpItem(
                id: "snippets.projects",
                titleKey: "help.snippets.projects.title",
                bodyKey: "help.snippets.projects.body",
                icon: "folder"
            )
        ]
    )

    // MARK: Recovery

    static let recovery = HelpSection(
        id: "recovery",
        titleKey: "help.section.recovery.title",
        items: [
            HelpItem(
                id: "recovery.storage",
                titleKey: "help.recovery.storage.title",
                bodyKey: "help.recovery.storage.body",
                icon: "internaldrive"
            ),
            HelpItem(
                id: "recovery.banner",
                titleKey: "help.recovery.banner.title",
                bodyKey: "help.recovery.banner.body",
                icon: "exclamationmark.triangle"
            )
        ]
    )
}
