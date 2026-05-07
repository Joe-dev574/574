//
//  Tag.swift
//  574
//

import Foundation
import SwiftData

@Model
final class Tag {
    var id: UUID
    var name: String
    var createdAt: Date

    /// All notes that carry this tag.
    var notes: [Note] = []

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
    }
}
