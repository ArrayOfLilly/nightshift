//
//  AppKeys.swift
//  countdownApp
//
//  Centralised UserDefaults key registry.
//  All UserDefaults keys used in the app must be declared here.
//  Never use raw string literals for UserDefaults keys outside this file.
//

import Foundation

enum AppKeys {
    // MARK: - Countdown items
    static let countdownItems = "countdownItems"
    static let freeSlotOrder  = "freeSlotOrder"

    // MARK: - Named deadlines
    static let namedDeadlines = "namedDeadlines"

    // MARK: - Snippets
    static let snippets = "snippets"

    // MARK: - Calculate view (AppStorage)
    static let calculateFromDate    = "calculateFromDate"
    static let calculateToDate      = "calculateToDate"
    static let calculateDisplayMode = "calculateDisplayMode"

    // MARK: - Settings
    /// BCP-47 language tag ("en", "hu") or "" for system default.
    /// Written to AppleLanguages on change; restart required.
    static let preferredLanguage = "nightshift.preferredLanguage"
    /// Locale identifier ("en_US", "hu_HU") or "" for system default.
    /// Read by Formatters.effectiveLocale at static-let init time; restart required.
    static let preferredLocale   = "nightshift.preferredLocale"
    /// Font size step: 0 = Default, 1 = Large, 2 = Larger, 3 = Largest.
    /// Applied via .dynamicTypeSize() on ContentView; no restart required.
    static let fontSizeStep      = "nightshift.fontSizeStep"

    // MARK: - Recovery
    /// Accumulates raw JSON fragments of items that failed to decode.
    /// Each entry is a single JSON-object string representing one corrupt item.
    /// Cleared when the user dismisses the recovery banner.
    static let corruptedDump = "corruptedDump"

    /// Appends raw JSON fragment strings to the corrupted-dump array in UserDefaults.
    /// Accumulates across calls — does NOT overwrite existing entries.
    static func appendCorruptFragments(_ fragments: [String]) {
        guard !fragments.isEmpty else { return }
        let defaults = UserDefaults.standard
        var current = (defaults.array(forKey: corruptedDump) as? [String]) ?? []
        current.append(contentsOf: fragments)
        defaults.set(current, forKey: corruptedDump)
    }
}

#if DEBUG
// MARK: - Debug notifications

/// NotificationCenter names used only in DEBUG builds.
/// Broadcast by the Cmd+Shift+D menu action; observed by the three banner views
/// to reload corruptedFragments without requiring a full app restart.
enum DebugNotifications {
    static let injectCorruptBanner = Notification.Name("dev.countdownApp.debug.injectCorruptBanner")
}
#endif
