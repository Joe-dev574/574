//
//  Project.swift
//  574
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class Project {
    var id: UUID
    var name: String
    var iconData: Data?
    var colorName: String?
    var createdAt: Date

    // NEW - for drag-and-drop reordering
    var order: Int = 0

    @Relationship(deleteRule: .nullify, inverse: \Note.project)
    var notes: [Note] = []

    // Developer Module
    @Relationship(inverse: \DevIssue.project)
    var devIssues: [DevIssue] = []

    init(name: String, colorName: String? = nil, iconData: Data? = nil, order: Int = 0) {
        self.id = UUID()
        self.name = name
        self.colorName = colorName
        self.iconData = iconData
        self.createdAt = Date()
        self.order = order
    }

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
// MARK: - Developer Module Extension (Milestone 1)

extension Project {

    /// Linear-style workflow states for this project.
    /// Default states match Linear. Can be customized per project later.
    var devStates: [String] {
        get { ["Backlog", "Todo", "In Progress", "In Review", "Done"] }
        set { /* TODO: persist custom states in Phase 2 */ }
    }

    }

