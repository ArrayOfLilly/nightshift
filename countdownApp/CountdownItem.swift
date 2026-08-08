//
//  CountdownItem.swift
//  countdownApp
//
//  Data model for a single countdown entry.
//  Codable  → persisted to UserDefaults as JSON
//  Equatable → required for SwiftUI onChange(of:) on the items array
//  Hashable  → required for NavigationLink(value:) pattern (BUG-18 fix)
//

import Foundation

struct CountdownItem: Identifiable, Codable, Equatable, Hashable {

    var id       = UUID()
    var label    : String        // e.g. "GPT-4 Free"
    var deadline : Date          // when the account/resource resets
    var showRemaining: Bool = true  // true = show DD:HH:MM:SS  |  false = show deadline date
    /// Manually selected color index into AppTheme.freeColors.
    /// nil = auto (hash-based fallback). Only meaningful for free (expired) slots.
    var accentColorIndex: Int? = nil

    // MARK: - Helpers called from the view with a live Date reference
    // (views pass Date() from a TimelineView so the display updates every second)

    func isExpired(at now: Date) -> Bool {
        deadline < now
    }

    func remaining(at now: Date) -> TimeInterval {
        max(0, deadline.timeIntervalSince(now))
    }

    /// "02:14:33" or "03:02:14:33" (days prefix only when > 0)
    func remainingFormatted(at now: Date) -> String {
        let total = Int(remaining(at: now))
        let d = total / 86400
        let h = (total % 86400) / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if d > 0 {
            return String(format: "%02d:%02d:%02d:%02d", d, h, m, s)
        } else {
            return String(format: "%02d:%02d:%02d", h, m, s)
        }
    }

    /// "2026.08.10 14:00"
    var deadlineFormatted: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy.MM.dd HH:mm"
        return f.string(from: deadline)
    }
}
