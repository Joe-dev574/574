import Foundation
import SwiftData

@Model
final class DevLabel {
    var id: UUID
    var name: String
    var colorName: String?
    var createdAt: Date

    @Relationship var issues: [DevIssue] = []

    init(name: String, colorName: String? = nil) {
        self.id = UUID()
        self.name = name
        self.colorName = colorName
        self.createdAt = Date()
    }
}
