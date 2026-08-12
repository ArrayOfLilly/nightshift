//
//  CountdownItem.swift
//  countdownApp
//
//  Data model for a single countdown entry.
//  Codable  → persisted to UserDefaults as JSON
//  Equatable → required for SwiftUI onChange(of:) on the items array
//  Hashable  → required for NavigationLink(value:) pattern (BUG-18 fix)
//
//  SLOT-NOTES: Each item carries a free-form `notes` String (default "").
//  The custom init(from:) uses decodeIfPresent so existing JSON without the
//  key continues to decode cleanly — the field simply defaults to "".
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
    /// Play a system sound when this slot expires (active → free transition).
    /// Default false — backward-compatible: missing key in JSON decodes as false.
    var soundEnabled: Bool = false
    /// Free-form notes/handoff text for this slot. Stored as raw markdown.
    /// Default "" — backward-compatible: missing key in JSON decodes to empty string.
    var notes: String = ""

    // MARK: - Codable
    //
    // Swift synthesized Decodable does NOT fall back to a property's default value
    // when the key is absent — it throws keyNotFound, which `try?` silently turns
    // into nil, leaving `items = []`. Custom init(from:) is required so that
    // optional/defaulted fields gracefully decode to their defaults when loading
    // JSON written by older builds.

    enum CodingKeys: String, CodingKey {
        case id, label, deadline, showRemaining, accentColorIndex, soundEnabled, notes
    }

    init(id: UUID = UUID(), label: String, deadline: Date,
         showRemaining: Bool = true, accentColorIndex: Int? = nil,
         soundEnabled: Bool = false, notes: String = "") {
        self.id               = id
        self.label            = label
        self.deadline         = deadline
        self.showRemaining    = showRemaining
        self.accentColorIndex = accentColorIndex
        self.soundEnabled     = soundEnabled
        self.notes            = notes
    }

    init(from decoder: Decoder) throws {
        let c             = try decoder.container(keyedBy: CodingKeys.self)
        id               = try c.decodeIfPresent(UUID.self,   forKey: .id) ?? UUID()
        label            = try c.decode(String.self, forKey: .label)
        deadline         = try c.decode(Date.self,   forKey: .deadline)
        showRemaining    = try c.decodeIfPresent(Bool.self,   forKey: .showRemaining)    ?? true
        accentColorIndex = try c.decodeIfPresent(Int.self,    forKey: .accentColorIndex) ?? nil
        soundEnabled     = try c.decodeIfPresent(Bool.self,   forKey: .soundEnabled)     ?? false
        notes            = try c.decodeIfPresent(String.self, forKey: .notes)            ?? ""
    }

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
