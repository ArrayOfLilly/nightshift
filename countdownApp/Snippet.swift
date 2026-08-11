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
        return list
    }

    static func save(_ snippets: [Snippet]) {
        guard let data = try? JSONEncoder().encode(snippets) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
