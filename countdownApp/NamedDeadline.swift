//
//  NamedDeadline.swift
//  countdownApp
//
//  CALC-SAVE: Persisted named deadline entry saved from the Calculate View.
//  Storage: UserDefaults key AppKeys.namedDeadlines, JSON-encoded [NamedDeadline] array.
//

import Foundation

struct NamedDeadline: Identifiable, Codable {
    var id:        UUID   = UUID()
    var title:     String
    var date:      Date
    var createdAt: Date   = Date()

    // MARK: - Codable
    //
    // Swift synthesized Decodable does NOT fall back to a property's default value
    // when the key is absent — it throws keyNotFound, which `try?` silently turns
    // into nil, leaving the decoded array empty. Custom init(from:) ensures that
    // optional/defaulted fields decode gracefully from JSON written by older builds.

    enum CodingKeys: String, CodingKey {
        case id, title, date, createdAt
    }

    init(id: UUID = UUID(), title: String, date: Date, createdAt: Date = Date()) {
        self.id        = id
        self.title     = title
        self.date      = date
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let c      = try decoder.container(keyedBy: CodingKeys.self)
        id        = try c.decodeIfPresent(UUID.self,   forKey: .id)        ?? UUID()
        title     = try c.decode(String.self,           forKey: .title)
        date      = try c.decode(Date.self,             forKey: .date)
        createdAt = try c.decodeIfPresent(Date.self,   forKey: .createdAt) ?? Date()
    }
}

// MARK: - Persistence

extension NamedDeadline {

    /// Load all saved deadlines from UserDefaults.
    ///
    /// Per-item recovery: one corrupt element does not wipe the entire list.
    /// Failed elements are captured as raw JSON strings and forwarded to
    /// `AppKeys.appendCorruptFragments`.
    static func load() -> [NamedDeadline] {
        guard let data = UserDefaults.standard.data(forKey: AppKeys.namedDeadlines) else { return [] }
        guard let rawArray = (try? JSONSerialization.jsonObject(with: data)) as? [Any] else { return [] }

        var deadlines: [NamedDeadline] = []
        var corruptFragments: [String] = []

        for element in rawArray {
            guard let elementData = try? JSONSerialization.data(withJSONObject: element) else { continue }
            do {
                deadlines.append(try JSONDecoder().decode(NamedDeadline.self, from: elementData))
            } catch {
                if let fragment = String(data: elementData, encoding: .utf8) {
                    corruptFragments.append(fragment)
                }
            }
        }

        AppKeys.appendCorruptFragments(corruptFragments)
        return deadlines
    }

    static func save(_ deadlines: [NamedDeadline]) {
        guard let data = try? JSONEncoder().encode(deadlines) else { return }
        UserDefaults.standard.set(data, forKey: AppKeys.namedDeadlines)
    }
}
