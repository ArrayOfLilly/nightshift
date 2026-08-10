//
//  NamedDeadline.swift
//  countdownApp
//
//  CALC-SAVE: Persisted named deadline entry saved from the Calculate View.
//  Storage: UserDefaults key "namedDeadlines", JSON-encoded [NamedDeadline] array.
//

import Foundation

struct NamedDeadline: Identifiable, Codable {
    var id:        UUID   = UUID()
    var title:     String
    var date:      Date
    var createdAt: Date   = Date()
}
