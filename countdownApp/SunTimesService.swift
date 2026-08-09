//
//  SunTimesService.swift
//  countdownApp
//
//  Fetches and caches a full year of sun/moon timing data from sunrisesunset.io.
//  One network call per calendar year; results are cached in UserDefaults so the
//  app can run fully offline afterwards. Location is manual for now (@AppStorage);
//  CoreLocation-based auto-detection is planned for a later session (SUN-1-B/C).
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class SunTimesService: ObservableObject {

    // MARK: - Manual coordinates (Budapest default)

    @AppStorage("sunLatitude") var latitude: Double = 47.4979
    @AppStorage("sunLongitude") var longitude: Double = 19.0402

    // MARK: - Published state

    @Published private(set) var yearData: [SunTimes] = []
    @Published private(set) var isLoading = false
    @Published private(set) var lastError: String?

    private var currentYearInMemory: Int?
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Public API

    /// Returns the sun/moon data for the given date's calendar day, loading the
    /// containing year from cache or network first if it isn't already in memory.
    func sunTimes(for date: Date) async -> SunTimes? {
        let year = Calendar.current.component(.year, from: date)
        if currentYearInMemory != year {
            await loadYear(year)
        }
        let day = Self.dayString(from: date)
        return yearData.first { $0.date == day }
    }

    /// Loads a full year of data, preferring the UserDefaults cache and only
    /// hitting the network if no cache entry exists for that year.
    func loadYear(_ year: Int) async {
        if let cached = loadFromCache(year: year) {
            yearData = cached
            currentYearInMemory = year
            return
        }
        await fetchYear(year)
    }

    /// Forces a network fetch for the given year, overwriting any existing cache.
    /// Called by loadYear() on a cache miss (e.g. year change), and can also be
    /// called directly to force-refresh (e.g. after the coordinates change).
    func fetchYear(_ year: Int) async {
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        guard let url = Self.buildURL(year: year, latitude: latitude, longitude: longitude) else {
            lastError = "Invalid request URL"
            return
        }

        do {
            let (data, _) = try await session.data(from: url)
            let decoder = JSONDecoder()
            let response = try decoder.decode(SunTimesYearResponse.self, from: data)
            yearData = response.results
            currentYearInMemory = year
            saveToCache(rawData: data, year: year)
        } catch {
            lastError = error.localizedDescription
        }
    }

    // MARK: - Cache (UserDefaults, one JSON blob per year)

    private func cacheKey(forYear year: Int) -> String {
        "sunTimesCache_\(year)"
    }

    private func loadFromCache(year: Int) -> [SunTimes]? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey(forYear: year)) else {
            return nil
        }
        guard let response = try? JSONDecoder().decode(SunTimesYearResponse.self, from: data) else {
            return nil
        }
        return response.results
    }

    private func saveToCache(rawData: Data, year: Int) {
        UserDefaults.standard.set(rawData, forKey: cacheKey(forYear: year))
    }

    // MARK: - URL building

    private static func buildURL(year: Int, latitude: Double, longitude: Double) -> URL? {
        var components = URLComponents(string: "https://api.sunrisesunset.io/json")
        components?.queryItems = [
            URLQueryItem(name: "lat", value: String(latitude)),
            URLQueryItem(name: "lng", value: String(longitude)),
            URLQueryItem(name: "date_start", value: "\(year)-01-01"),
            URLQueryItem(name: "date_end", value: "\(year)-12-31"),
            URLQueryItem(name: "timezone", value: "auto")
        ]
        return components?.url
    }

    /// Formats a Date as "yyyy-MM-dd" using the device calendar's own components
    /// (no timezone conversion) so it matches the plain "date" field the API returns.
    private static func dayString(from date: Date) -> String {
        let cal = Calendar.current
        let year = cal.component(.year, from: date)
        let month = cal.component(.month, from: date)
        let day = cal.component(.day, from: date)
        return String(format: "%04d-%02d-%02d", year, month, day)
    }
}
