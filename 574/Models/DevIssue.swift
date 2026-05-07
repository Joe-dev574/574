//
//  DevIssue.swift
//  574
//
//  Created by Joseph DeWeese on 5/7/26.
//

import Foundation
import SwiftData

/// Linear-style issue / task model.
/// Fully integrated with existing Note, Project, and EventKit systems.
@Model
final class DevIssue {

    // MARK: - Stored Properties

    var id: UUID
    var title: String

    /// Rich-text description stored the same way as Note.attributedContent
    var contentData: Data?

    var status: DevIssueStatus = DevIssueStatus.backlog
    var priority: Int = 2          // 0 = None, 1 = Urgent, 2 = High, 3 = Medium, 4 = Low
    var createdAt: Date
    var updatedAt: Date
    var dueDate: Date?

    // MARK: - Relationships

    @Relationship(deleteRule: .nullify)
    var project: Project?

    @Relationship(deleteRule: .nullify)
    var linkedNote: Note?

    var labels: [DevLabel] = []

    @Relationship(deleteRule: .cascade)
    var comments: [DevComment] = []

    // MARK: - Init

    init(
        title: String = "New Issue",
        project: Project? = nil,
        linkedNote: Note? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.updatedAt = Date()
        self.project = project
        self.linkedNote = linkedNote
    }

    // MARK: - Computed Rich Text (same pattern as Note)

    var attributedContent: NSAttributedString {
        get {
            guard let data = contentData,
                  let attr = try? NSKeyedUnarchiver.unarchivedObject(
                      ofClass: NSAttributedString.self,
                      from: data
                  )
            else {
                return NSAttributedString(string: "")
            }
            return attr
        }
        set {
            contentData = try? NSKeyedArchiver.archivedData(
                withRootObject: newValue,
                requiringSecureCoding: true
            )
            updatedAt = Date()
        }
    }
}

// MARK: - Status Enum (Linear-style)

enum DevIssueStatus: String, CaseIterable, Codable {
    case backlog    = "Backlog"
    case todo       = "Todo"
    case inProgress = "In Progress"
    case inReview   = "In Review"
    case done       = "Done"

    var systemImage: String {
        switch self {
        case .backlog:    return "tray"
        case .todo:       return "circle"
        case .inProgress: return "arrow.triangle.2.circlepath"
        case .inReview:   return "eye"
        case .done:       return "checkmark.circle.fill"
        }
    }

    var colorName: String {
        switch self {
        case .backlog:    return "gray"
        case .todo:       return "blue"
        case .inProgress: return "orange"
        case .inReview:   return "purple"
        case .done:       return "green"
        }
    }
}
