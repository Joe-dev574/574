//
//  Tag.swift
//  574
//
//  Created by Joseph DeWeese on 5/3/26.
//

import Foundation
import SwiftData

// MARK: - Tag

/// A free-form keyword label that can be applied to any number of notes.
///
/// Tags are many-to-many: one note can have many tags and one tag can appear on
/// many notes.
@Model
final class Tag {

    // MARK: Stored Properties

    var id: UUID
    var name: String
    var createdAt: Date

    /// All notes that carry this tag.
    var notes: [Note] = []

    // MARK: Init

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
    }
}
