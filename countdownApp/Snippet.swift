//
//  Snippet.swift
//  countdownApp
//
//  Data model for master-prompt snippets.
//  Snippets are project-tagged, markdown-bodied text blocks
//  intended for fast copy-paste into AI sessions.
//  Storage: UserDefaults key "snippets", JSON-encoded [Snippet].
//

import Foundation

struct Snippet: Identifiable, Codable {
    var id: UUID       = UUID()
    var title: String
    var body: String
    var project: String          // free-form tag — "countdownApp", "sunikertek", etc.
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}

// MARK: - Persistence

extension Snippet {
    static let storageKey = "snippets"

    static func load() -> [Snippet] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
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
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
