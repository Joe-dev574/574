//
//  FoundationTests.swift
//  574Tests
//

import Foundation
import SwiftData
import Testing
@testable import _74

struct FoundationTests {
    @Test
    @MainActor
    func dataSeederCreatesRequiredFoldersOnce() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext

        DataSeeder.seed(in: context)
        DataSeeder.seed(in: context)

        let folders = try context.fetch(FetchDescriptor<Folder>(sortBy: [SortDescriptor(\.order)]))
        #expect(folders.map(\.name) == ["Inbox", "Professional", "Personal", "Junk Drawer"])
        #expect(Set(folders.map(\.name)).count == 4)
    }

    @Test
    @MainActor
    func dataSeederPurgesOnlyExpiredTrash() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext

        let expired = Note(title: "Expired")
        expired.deletedAt = Calendar.current.date(byAdding: .day, value: -31, to: .now)

        let recent = Note(title: "Recent")
        recent.deletedAt = Calendar.current.date(byAdding: .day, value: -5, to: .now)

        let active = Note(title: "Active")

        context.insert(expired)
        context.insert(recent)
        context.insert(active)
        try context.save()

        DataSeeder.seed(in: context)

        let notes = try context.fetch(FetchDescriptor<Note>(sortBy: [SortDescriptor(\.title)]))
        #expect(notes.map(\.title) == ["Active", "Recent"])
        #expect(notes.first(where: { $0.title == "Recent" })?.deletedAt != nil)
        #expect(notes.first(where: { $0.title == "Active" })?.deletedAt == nil)
    }

    @Test
    func noteAttributedContentRoundTripsThroughStoredData() {
        let note = Note(title: "Round Trip")
        let original = NSAttributedString(
            string: "Hello, 574",
            attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue]
        )

        note.attributedContent = original

        #expect(note.contentData != nil)
        #expect(note.attributedContent.string == "Hello, 574")
        #expect(note.modifiedAt >= note.createdAt)
    }

    @MainActor
    private func makeInMemoryContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: NotesPersistence.schema,
            isStoredInMemoryOnly: true
        )

        return try ModelContainer(
            for: NotesPersistence.schema,
            migrationPlan: NotesMigrationPlan.self,
            configurations: [configuration]
        )
    }
}
