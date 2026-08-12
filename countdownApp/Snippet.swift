//
//  Snippet.swift
//  countdownApp
//
//  Data model for master-prompt snippets.
//  Snippets are project-tagged, markdown-bodied text blocks
//  intended for fast copy-paste into AI sessions.
//  Storage: UserDefaults key AppKeys.snippets, JSON-encoded [Snippet].
//

import Foundation

struct Snippet: Identifiable, Codable {
    var id:        UUID   = UUID()
    var title:     String
    var body:      String
    var project:   String          // free-form tag — "countdownApp", "sunikertek", etc.
    var createdAt: Date   = Date()
    var updatedAt: Date   = Date()

    // MARK: - Codable
    //
    // Swift synthesized Decodable does NOT fall back to a property's default value
    // when the key is absent — it throws keyNotFound, which `try?` silently turns
    // into nil, leaving the decoded array empty. Custom init(from:) ensures that
    // optional/defaulted fields decode gracefully from JSON written by older builds.

    enum CodingKeys: String, CodingKey {
        case id, title, body, project, createdAt, updatedAt
    }

    init(id: UUID = UUID(), title: String, body: String, project: String,
         createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id        = id
        self.title     = title
        self.body      = body
        self.project   = project
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let c      = try decoder.container(keyedBy: CodingKeys.self)
        id        = try c.decodeIfPresent(UUID.self,   forKey: .id)        ?? UUID()
        title     = try c.decode(String.self,           forKey: .title)
        body      = try c.decode(String.self,           forKey: .body)
        project   = try c.decode(String.self,           forKey: .project)
        createdAt = try c.decodeIfPresent(Date.self,   forKey: .createdAt) ?? Date()
        updatedAt = try c.decodeIfPresent(Date.self,   forKey: .updatedAt) ?? Date()
    }
}

// MARK: - Persistence

extension Snippet {
    static func load() -> [Snippet] {
        guard let data = UserDefaults.standard.data(forKey: AppKeys.snippets),
              let list = try? JSONDecoder().decode([Snippet].self, from: data)
        else { return [] }
        // Trim leading/trailing whitespace from project and title.
        // Repairs any previously saved snippets with accidental whitespace.
        let cleaned = list.map { s -> Snippet in
            var c = s
            c.project = s.project.trimmingCharacters(in: .whitespaces)
            c.title   = s.title.trimmingCharacters(in: .whitespaces)
            return c
        }
        // Persist the cleaned data so UserDefaults is also repaired.
        if cleaned.map({ $0.project }) != list.map({ $0.project }) ||
           cleaned.map({ $0.title })   != list.map({ $0.title }) {
            save(cleaned)
        }
        return cleaned
    }

    static func save(_ snippets: [Snippet]) {
        guard let data = try? JSONEncoder().encode(snippets) else { return }
        UserDefaults.standard.set(data, forKey: AppKeys.snippets)
    }
}
