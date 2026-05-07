//
//  DevComment.swift
//  574
//

import Foundation
import SwiftData

@Model
final class DevComment {
    var id: UUID
    var content: String
    var createdAt: Date

    @Relationship var issue: DevIssue?

    init(content: String, issue: DevIssue? = nil) {
        self.id = UUID()
        self.content = content
        self.createdAt = Date()
        self.issue = issue
    }
}
