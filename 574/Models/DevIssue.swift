import Foundation
import SwiftData

@Model
final class DevIssue {
    var id: UUID
    var title: String
    var contentData: Data?
    
    // Store as String to satisfy @Model macro
    var statusRaw: String = "backlog"
    var priority: Int = 2
    var createdAt: Date
    var updatedAt: Date
    var dueDate: Date?

    @Relationship var project: Project?
    @Relationship var linkedNote: Note?
    var labels: [DevLabel] = []
    @Relationship(deleteRule: .cascade) var comments: [DevComment] = []

    init(title: String = "New Issue", project: Project? = nil, linkedNote: Note? = nil) {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.updatedAt = Date()
        self.project = project
        self.linkedNote = linkedNote
    }

    // Computed property for nice enum API
    var status: DevIssueStatus {
        get { DevIssueStatus(rawValue: statusRaw) ?? .backlog }
        set { statusRaw = newValue.rawValue }
    }

    var attributedContent: NSAttributedString {
        get {
            guard let data = contentData,
                  let attr = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSAttributedString.self, from: data)
            else { return NSAttributedString(string: "") }
            return attr
        }
        set {
            contentData = try? NSKeyedArchiver.archivedData(withRootObject: newValue, requiringSecureCoding: true)
            updatedAt = Date()
        }
    }
}

enum DevIssueStatus: String, CaseIterable, Codable {
    case backlog
    case todo
    case inProgress
    case inReview
    case done
}
