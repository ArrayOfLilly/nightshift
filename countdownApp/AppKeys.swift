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
