
//
//  Formatters.swift
//  countdownApp
//
//  Centralised static DateFormatter instances.
//
//  LOCALIZATION NOTE (ENH-SETTINGS-1 — implemented):
//  The user can override the display locale independently of the UI language via
//  Settings → Date & Number Format (AppKeys.preferredLocale). The override is
//  read once at static-let initialisation time; a restart is required for changes
//  to take effect (consistent with the language override behaviour).
//
//  Convention:
//  - `monthAbbrev`, `deadline`, `deadlineCompact` use effectiveLocale so they
//    respect the user's locale preference.
//  - `time` keeps Locale("en_US_POSIX") — 24-hour output is locale-independent
//    and must not vary by locale setting.
//

import Foundation

enum Formatters {

    // MARK: - Effective locale

    /// Resolves the user's preferred locale from UserDefaults (AppKeys.preferredLocale).
    /// Falls back to Locale.current when no override is set (empty string).
    /// Called once per formatter at static-let initialisation; restart required for changes.
    private static var effectiveLocale: Locale {
        let tag = UserDefaults.standard.string(forKey: AppKeys.preferredLocale) ?? ""
        return tag.isEmpty ? Locale.current : Locale(identifier: tag)
    }

    // MARK: - Month abbreviation

    /// Month abbreviation ("MMM") in the user's effective locale, uppercased at call site.
    /// Used by CountdownDetailView and CalculateView component steppers.
    static let monthAbbrev: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        f.locale = effectiveLocale
        return f
    }()

    // MARK: - Deadline display

    /// "yyyy.MM.dd HH:mm" — deadline label in CountdownItem and CountdownDetailView.
    /// Uses effectiveLocale (user's preferred locale or system default).
    static let deadline: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy.MM.dd HH:mm"
        f.locale = effectiveLocale
        return f
    }()

    /// "yyyy MMM dd  HH:mm" uppercased — compact deadline string in CalculateView saved-deadlines list.
    /// Uses effectiveLocale so month abbreviation follows the user's locale preference.
    static let deadlineCompact: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy MMM dd  HH:mm"
        f.locale = effectiveLocale
        return f
    }()

    // MARK: - Time display

    /// "HH:mm" — sun/moon time rows in SunPanel.
    /// POSIX locale ensures 24-hour output regardless of device settings.
    static let time: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
}
