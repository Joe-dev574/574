//
//  DevLabel.swift
//  574
//

import Foundation
import SwiftData

@Model
final class DevLabel {
    var id: UUID
    var name: String
    var colorName: String?
    var createdAt: Date

    @Relationship(inverse: \DevIssue.labels) var issues: [DevIssue] = []

    init(name: String, colorName: String? = nil) {
        self.id = UUID()
        self.name = name
        self.colorName = colorName
        self.createdAt = Date()
    }
}
