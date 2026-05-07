//
//  _74App.swift
//  574
//
//  Created by Joseph DeWeese on 5/3/26.
//
//  Application entry point.
//  • Initialises the SwiftData ModelContainer with CloudKit sync enabled.
//  • Seeds default folders ("Inbox", "Work", "Personal", "Junk Drawer") on first launch.
//  • MenuBarExtra and App Intents are implemented in Phase 1.
//
import SwiftUI
import SwiftData


// MARK: - Schema Versions

// MARK: - Schema Versions (simplified for now — only current version)

enum NoteSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [
            Note.self,
            Folder.self,
            Tag.self,
            Attachment.self,
            LinkedReminder.self,
            LinkedCalendarEvent.self,
            Project.self
        ]
    }
}

enum NotesMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [NoteSchemaV1.self] }
    static var stages: [MigrationStage] { [] }   // No stages = no duplicates
}


@main
struct _74App: App {
    // MARK: - Container
    let container: ModelContainer
    let themeManager = ThemeManager()
    // MARK: - Init
    init() {
        do {
            container = try NotesPersistence.makeContainer()
            print("✅ ModelContainer created successfully")
        } catch {
            fatalError("❌ Failed to create ModelContainer: \(error)")
        }
        
        DataSeeder.seed(in: container.mainContext)
    }
    // MARK: - Scene
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
        .environment(themeManager)
        .commands { InspectorCommands() }
        
#if os(macOS)
        // Native macOS Settings window (Cmd + ,)
        Settings {
            SettingsView()
        }
#endif
        
#if os(macOS)
        MenuBarExtra("IndieGrind", systemImage: "note.text") {
            QuickCaptureView()
                .modelContainer(container)
        }
        .menuBarExtraStyle(.window)
#endif
    }
}
// MARK: - Data Seeder (unchanged)
@MainActor
enum DataSeeder {
    static func seed(in context: ModelContext) {
        seedFolders(in: context)
        purgeExpiredTrash(in: context)
    }
    private static func seedFolders(in context: ModelContext) {
        let descriptor = FetchDescriptor<Folder>()
        let existing   = (try? context.fetch(descriptor)) ?? []
        
        let required: [(name: String, color: String?, order: Int)] = [
            ("Inbox",        nil, 0),
            ("Professional", "blue", 1),
            ("Personal",     "green", 2),
            ("Junk Drawer",  "orange", 3)
        ]
        
        var didInsert = false
        for folder in required where !existing.contains(where: { $0.name == folder.name }) {
            let newFolder = Folder(name: folder.name, colorName: folder.color, order: folder.order)
            context.insert(newFolder)
            didInsert = true
        }
        if didInsert { try? context.save() }
    }
    private static func purgeExpiredTrash(in context: ModelContext) {
        let cutoff = Date.now.addingTimeInterval(-30 * 24 * 60 * 60)
        let descriptor = FetchDescriptor<Note>(
            predicate: #Predicate { note in
                note.deletedAt != nil && note.deletedAt! < cutoff
            }
        )
        guard let expired = try? context.fetch(descriptor), !expired.isEmpty else { return }
        for note in expired {
            SpotlightManager.deindex(note)
            context.delete(note)
        }
        try? context.save()
    }
}
