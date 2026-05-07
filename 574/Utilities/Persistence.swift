//
//  Persistence.swift
//  574
//

import SwiftData

enum NotesPersistence {
    
    static let schema = Schema([
        Note.self,
        Folder.self,
        Tag.self,
        Attachment.self,
        LinkedReminder.self,
        LinkedCalendarEvent.self,
        Project.self,
        DevIssue.self,
        DevLabel.self,
        DevComment.self
    ])

    static func makeContainer(
        cloudKitDatabase: ModelConfiguration.CloudKitDatabase = .none   // ← Development mode (no CloudKit)
    ) throws -> ModelContainer {
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )

        return try ModelContainer(
            for: schema,
            migrationPlan: NotesMigrationPlan.self,
            configurations: [configuration]
        )
    }
}
