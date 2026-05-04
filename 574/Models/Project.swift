//
//  Project.swift
//  574
//
//  Created by Joseph DeWeese on 5/3/26.
//

import Foundation
import SwiftData
import SwiftUI

/// A named container for grouping notes by project, displayed with an
/// app-icon-style hero image in the sidebar.
///
/// Deleting a project does **not** delete its notes; the notes become
/// unaffiliated (their `project` reference is nullified).
@Model
final class Project {

    // MARK: Stored Properties

    var id: UUID
    var name: String

    /// JPEG/PNG bytes of the user-chosen icon image.  `nil` → initial fallback.
    var iconData: Data?

    /// Colour token string used as the icon background when `iconData` is nil.
    var colorName: String?

    var createdAt: Date

    // MARK: Relationships

    @Relationship(deleteRule: .nullify, inverse: \Note.project)
    var notes: [Note] = []

    // MARK: Init

    init(name: String, colorName: String? = nil, iconData: Data? = nil) {
        self.id = UUID()
        self.name = name
        self.colorName = colorName
        self.iconData = iconData
        self.createdAt = Date()
    }

    // MARK: Computed

    /// Solid accent colour for icon backgrounds and tints.
    /// Always returns a visible (non-`.primary`) colour.
    var accentColor: Color {
        switch colorName {
        case "blue":   return .blue
        case "red":    return .red
        case "green":  return .green
        case "orange": return .orange
        case "purple": return .purple
        case "yellow": return .yellow
        default:       return .accentColor
        }
    }
}
