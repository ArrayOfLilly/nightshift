
//
//  Formatters.swift
//  countdownApp
//
//  Centralised static DateFormatter instances.
//
//  LOCALIZATION NOTE (deferred):
//  The app currently targets a single display language (English) with the user's
//  system locale for date input. Future localization will require at minimum two
//  formatter variants: one for display strings (English labels) and one for
//  date/time formatting (user's preferred locale/calendar). Additional settings
//  will be needed to let the user choose independently — e.g. English UI text
//  with Hungarian date format (dd.MM.yyyy) is a known use case. When that work
//  begins, this file is the single place to introduce locale-aware variants;
//  all call sites already reference these constants, so no grep-and-replace will
//  be needed across the codebase.
//
//  Current convention:
//  - Formatters that produce UI-visible date/time strings use Locale("en_US") or
//    Locale("en_US_POSIX") to keep output consistent regardless of device locale.
//  - `deadlineFormatter` intentionally uses the system locale so the deadline
//    display in CountdownItem matches the user's regional date preference.
//

import Foundation

enum Formatters {

    // MARK: - Month abbreviation

    /// Three-letter month abbreviation in English, uppercased at call site.
    /// Used by CountdownDetailView and CalculateView component steppers.
    static let monthAbbrev: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        f.locale = Locale(identifier: "en_US")
        return f
    }()

    // MARK: - Deadline display

    /// "yyyy.MM.dd HH:mm" — deadline label in CountdownItem and CountdownDetailView.
    /// Uses system locale (intentional): the user's regional date preference applies here.
    static let deadline: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy.MM.dd HH:mm"
        return f
    }()

    /// "yyyy MMM dd  HH:mm" uppercased — compact deadline string in CalculateView saved-deadlines list.
    static let deadlineCompact: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy MMM dd  HH:mm"
        f.locale = Locale(identifier: "en_US")
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
