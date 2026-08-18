//
//  ProjectCategory.swift
//  countdownApp
//
//  Type-safe representation of a snippet project tag.
//  .general is the system-default bucket; .custom carries user-authored names.
//
//  Storage: .general encodes as "default_general" (language-independent).
//  Legacy "General" / "general" strings already in JSON decode as .general —
//  lazy migration, no bulk rewrite on load.
//

import Foundation

enum ProjectCategory: Equatable, Hashable {
    case general
    case custom(String)

    /// Language-independent key written to persistent storage for the system default project.
    static let canonicalGeneralKey = "default_general"

    /// Localized display string — UI only, never persisted.
    var localizedName: String {
        switch self {
        case .general:
            return String(localized: "General", defaultValue: "General")
        case .custom(let name):
            return name
        }
    }

    /// Converts free-form user input (TextField, suggestion dropdown) to a category.
    /// Empty input, "general" (any case), the canonical storage key, or the current
    /// locale's translation of "General" all map to .general.
    init(userEnteredName: String) {
        let trimmed = userEnteredName.trimmingCharacters(in: .whitespacesAndNewlines)
        let localizedGeneral = String(localized: "General", defaultValue: "General")
        if trimmed.isEmpty
            || trimmed.lowercased() == "general"
            || trimmed == Self.canonicalGeneralKey
            || trimmed.lowercased() == localizedGeneral.lowercased() {
            self = .general
        } else {
            self = .custom(trimmed)
        }
    }
}

// MARK: - Codable

extension ProjectCategory: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        // "default_general" — current canonical form.
        // "General" / "general" — legacy form written by builds before this enum existed.
        if raw == Self.canonicalGeneralKey || raw.lowercased() == "general" {
            self = .general
        } else {
            self = .custom(raw)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .general:
            try container.encode(Self.canonicalGeneralKey)
        case .custom(let name):
            try container.encode(name)
        }
    }
}
