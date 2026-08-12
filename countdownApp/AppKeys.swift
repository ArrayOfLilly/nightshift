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
    /// Each entry is a [String: Any] fragment serialised as JSON.
    /// Cleared when the user dismisses the recovery banner.
    static let corruptedDump = "corruptedDump"
}
