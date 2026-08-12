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
