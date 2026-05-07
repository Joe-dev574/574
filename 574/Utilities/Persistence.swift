//
//  Persistence.swift
//  574
//
//  Shared SwiftData schema and container configuration.
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
        
        // === Developer Module (Milestone 1) ===
        DevIssue.self,
        DevLabel.self,
        DevComment.self
    ])

    static func makeContainer(
        cloudKitDatabase: ModelConfiguration.CloudKitDatabase = .automatic
    ) throws -> ModelContainer {
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,           // Safe for development
            cloudKitDatabase: .none
        )

        return try ModelContainer(
            for: schema,
            migrationPlan: NotesMigrationPlan.self,
            configurations: [configuration]
        )
    }
}
