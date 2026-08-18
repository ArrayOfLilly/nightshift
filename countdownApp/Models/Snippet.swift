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
    var project:   ProjectCategory  // type-safe: .general or .custom("tag")
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

    init(id: UUID = UUID(), title: String, body: String, project: ProjectCategory = .general,
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
        project   = try c.decode(ProjectCategory.self,  forKey: .project)
        createdAt = try c.decodeIfPresent(Date.self,   forKey: .createdAt) ?? Date()
        updatedAt = try c.decodeIfPresent(Date.self,   forKey: .updatedAt) ?? Date()
    }
}

// MARK: - Factory

extension Snippet {

    /// Assembles the final Snippet for persistence from the fields collected by the editor.
    /// Trims title; converts the raw project string via ProjectCategory(userEnteredName:),
    /// which maps empty/"general"/"általános" to .general and everything else to .custom.
    /// Returns nil when both title and body are blank (nothing to save).
    static func committed(
        from existing: Snippet?,
        title: String,
        body: String,
        project: String
    ) -> Snippet? {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty || !body.isEmpty else { return nil }
        var s       = existing ?? Snippet(title: "", body: "")
        s.title     = trimmedTitle
        s.body      = body
        s.project   = ProjectCategory(userEnteredName: project)
        s.updatedAt = Date()
        return s
    }
}

// MARK: - Persistence

extension Snippet {
    static func load() -> [Snippet] {
        guard let data = UserDefaults.standard.data(forKey: AppKeys.snippets) else { return [] }

        // Per-item recovery: parse as a raw JSON array so that one corrupt item
        // does not wipe the entire collection. Each element is decoded individually;
        // failures are captured as raw JSON strings and accumulated in corruptedDump.
        guard let rawArray = (try? JSONSerialization.jsonObject(with: data)) as? [Any] else {
            return []
        }

        var snippets: [Snippet] = []
        var corruptFragments: [String] = []

        for element in rawArray {
            guard let elementData = try? JSONSerialization.data(withJSONObject: element) else { continue }
            do {
                snippets.append(try JSONDecoder().decode(Snippet.self, from: elementData))
            } catch {
                if let fragment = String(data: elementData, encoding: .utf8) {
                    corruptFragments.append(fragment)
                }
            }
        }

        AppKeys.appendCorruptFragments(corruptFragments)

        // Trim leading/trailing whitespace from title.
        // Project is now a ProjectCategory — whitespace is handled at input time
        // by ProjectCategory(userEnteredName:) and is never persisted.
        let cleaned = snippets.map { s -> Snippet in
            var c = s
            c.title = s.title.trimmingCharacters(in: .whitespaces)
            return c
        }
        if cleaned.map({ $0.title }) != snippets.map({ $0.title }) {
            save(cleaned)
        }
        return cleaned
    }

    static func save(_ snippets: [Snippet]) {
        guard let data = try? JSONEncoder().encode(snippets) else { return }
        UserDefaults.standard.set(data, forKey: AppKeys.snippets)
    }
}
