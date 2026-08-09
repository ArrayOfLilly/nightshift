//
//  SunTimes.swift
//  countdownApp
//
//  Data model for sunrisesunset.io daily results.
//  Time strings arrive as "h:mm:ss a" (12-hour AM/PM); day_length as "H:MM:SS".
//  Both are combined with the "date" and "timezone" fields into concrete Date values.
//  moonrise/moonset can be null (no moon above horizon that day) -> stored as Date?.
//

import Foundation

/// A begin/end time pair, used for golden hour and blue hour windows.
struct TimeWindow: Codable, Equatable {
    let begin: Date
    let end: Date
}

/// Sun and moon timing data for a single calendar day, at a specific location.
struct SunTimes: Codable, Equatable {
    // Sun
    let firstLight: Date        // astronomical twilight begin
    let dawn: Date              // civil twilight begin
    let sunrise: Date
    let solarNoon: Date
    let sunset: Date
    let dusk: Date              // civil twilight end
    let lastLight: Date         // astronomical twilight end
    let dayLength: Int          // seconds (parsed from "H:MM:SS" string)

    // Golden / blue hour
    let goldenHourMorning: TimeWindow
    let blueHourMorning: TimeWindow
    let goldenHourEvening: TimeWindow
    let blueHourEvening: TimeWindow

    // Moon — nil means moon does not rise/set that calendar day
    let moonrise: Date?
    let moonset: Date?
    let moonPhase: String
    let moonIllumination: Double // 0-100 (%)

    /// The calendar day this record represents (yyyy-MM-dd, as returned by the API).
    let date: String
}

// MARK: - Decoding from the raw API response

extension SunTimes {

    /// Raw shape of one entry in the sunrisesunset.io `results` array.
    /// Field names match the API's snake_case JSON keys exactly.
    struct RawDay: Decodable {
        let date: String
        let timezone: String

        let first_light: String
        let dawn: String
        let sunrise: String
        let solar_noon: String
        let sunset: String
        let dusk: String
        let last_light: String
        let day_length: String

        let golden_hour_morning: RawWindow
        let blue_hour_morning: RawWindow
        let golden_hour_evening: RawWindow
        let blue_hour_evening: RawWindow

        let moonrise: String?   // null when moon doesn't rise that day
        let moonset: String?    // null when moon doesn't set that day
        let moon_phase: String
        let moon_illumination: Double
    }

    struct RawWindow: Decodable {
        let begin: String
        let end: String
    }

    /// Parses "H:MM:SS" or "HH:MM:SS" day-length string into total seconds.
    private static func parseDayLength(_ s: String) -> Int? {
        let parts = s.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return parts[0] * 3600 + parts[1] * 60 + parts[2]
    }

    /// Combines a time string ("7:28:47 AM" 12-hour or "07:28:47" 24-hour) with a
    /// "yyyy-MM-dd" date string and an IANA timezone into a concrete Date.
    /// Tries 12-hour (h:mm:ss a) first, falls back to 24-hour (HH:mm:ss).
    private static func combine(dateString: String, timeString: String, timeZone: TimeZone) -> Date? {
        let combined = "\(dateString) \(timeString)"
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.timeZone = timeZone
        for format in ["yyyy-MM-dd h:mm:ss a", "yyyy-MM-dd HH:mm:ss"] {
            fmt.dateFormat = format
            if let date = fmt.date(from: combined) { return date }
        }
        return nil
    }

    /// Builds a SunTimes value from one raw API day entry.
    /// Returns nil if any required (non-optional) field fails to parse.
    static func build(from raw: RawDay) -> SunTimes? {
        guard let tz = TimeZone(identifier: raw.timezone) else { return nil }

        func d(_ time: String) -> Date? {
            combine(dateString: raw.date, timeString: time, timeZone: tz)
        }

        func dOpt(_ time: String?) -> Date? {
            guard let t = time else { return nil }
            return combine(dateString: raw.date, timeString: t, timeZone: tz)
        }

        func window(_ w: RawWindow) -> TimeWindow? {
            guard let b = d(w.begin), let e = d(w.end) else { return nil }
            return TimeWindow(begin: b, end: e)
        }

        guard
            let firstLight        = d(raw.first_light),
            let dawn              = d(raw.dawn),
            let sunrise           = d(raw.sunrise),
            let solarNoon         = d(raw.solar_noon),
            let sunset            = d(raw.sunset),
            let dusk              = d(raw.dusk),
            let lastLight         = d(raw.last_light),
            let dayLengthSeconds  = Self.parseDayLength(raw.day_length),
            let goldenHourMorning = window(raw.golden_hour_morning),
            let blueHourMorning   = window(raw.blue_hour_morning),
            let goldenHourEvening = window(raw.golden_hour_evening),
            let blueHourEvening   = window(raw.blue_hour_evening)
        else { return nil }

        return SunTimes(
            firstLight:        firstLight,
            dawn:              dawn,
            sunrise:           sunrise,
            solarNoon:         solarNoon,
            sunset:            sunset,
            dusk:              dusk,
            lastLight:         lastLight,
            dayLength:         dayLengthSeconds,
            goldenHourMorning: goldenHourMorning,
            blueHourMorning:   blueHourMorning,
            goldenHourEvening: goldenHourEvening,
            blueHourEvening:   blueHourEvening,
            moonrise:          dOpt(raw.moonrise),
            moonset:           dOpt(raw.moonset),
            moonPhase:         raw.moon_phase,
            moonIllumination:  raw.moon_illumination,
            date:              raw.date
        )
    }
}

/// Top-level response wrapper for a full-year sunrisesunset.io request.
struct SunTimesYearResponse: Decodable {
    let results: [SunTimes]
    let status: String?

    private struct RawResults: Decodable {
        let results: [SunTimes.RawDay]
        let status: String?
    }

    init(from decoder: Decoder) throws {
        let raw = try RawResults(from: decoder)
        self.results = raw.results.compactMap { SunTimes.build(from: $0) }
        self.status = raw.status
    }
}
