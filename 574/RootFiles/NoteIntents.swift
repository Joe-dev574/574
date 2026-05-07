//
//  NoteIntents.swift
//  574
//
//  Created by Joseph DeWeese on 5/3/26.
//
//  App Intents exposed to Siri and the Shortcuts app — Phase 1.
//
//  Intents:
//    1. CreateNoteIntent       — "New note in 574"
//    2. AddReminderToNoteIntent — "Add reminder to note in 574"
//    3. ShowTodaysNotesIntent  — "Show today's notes in 574"
//

import AppIntents
import SwiftData
import EventKit
import Foundation

// MARK: - Shared Container Helper

/// Creates a ModelContainer pointing to the same on-disk store used by the app.
/// App Intents should use the same schema and store configuration as the main app.
private func makeContainer() throws -> ModelContainer {
    try NotesPersistence.makeContainer()
}

// MARK: - 1. Create Note

/// Creates a new note in the Inbox folder.
struct CreateNoteIntent: AppIntent {

    static var title: LocalizedStringResource = "New Note in 574"
    static var description = IntentDescription("Creates a new note in your 574 inbox.")

    @Parameter(title: "Title", description: "The note's title.")
    var noteTitle: String

    static var parameterSummary: some ParameterSummary {
        Summary("Create note \(\.$noteTitle)")
    }

    @MainActor
    func perform() async throws -> some ProvidesDialog {
        let container = try makeContainer()
        let ctx       = container.mainContext

        let descriptor = FetchDescriptor<Folder>(
            predicate: #Predicate { $0.name == "Inbox" }
        )
        let inbox = try? ctx.fetch(descriptor).first

        let note = Note(title: noteTitle, folder: inbox)
        ctx.insert(note)
        try ctx.save()
        SpotlightManager.index(note)

        return .result(dialog: "Created \"\(noteTitle)\" in your inbox.")
    }
}

// MARK: - 2. Add Reminder to Note

/// Creates an EKReminder and links it to an existing note by title.
struct AddReminderToNoteIntent: AppIntent {

    static var title: LocalizedStringResource = "Add Reminder to Note"
    static var description = IntentDescription(
        "Creates a reminder and links it to a note in 574."
    )

    @Parameter(title: "Note Title", description: "Title of the note to attach the reminder to.")
    var noteTitle: String

    @Parameter(title: "Reminder", description: "What to be reminded about.")
    var reminderTitle: String

    @Parameter(title: "Due Date", description: "When the reminder is due (optional).")
    var dueDate: Date?

    static var parameterSummary: some ParameterSummary {
        Summary("Add reminder \(\.$reminderTitle) to note \(\.$noteTitle)")
    }

    @MainActor
    func perform() async throws -> some ProvidesDialog {
        // Locate the note
        let container   = try makeContainer()
        let ctx         = container.mainContext
        let searchTitle = noteTitle
        let descriptor  = FetchDescriptor<Note>(
            predicate: #Predicate { $0.title == searchTitle && $0.deletedAt == nil }
        )
        guard let note = try ctx.fetch(descriptor).first else {
            throw NoteNotFoundError(name: noteTitle)
        }

        // Create the EKReminder
        let store = EKEventStore()
        guard try await store.requestFullAccessToReminders() else {
            throw RemindersAccessDeniedError()
        }

        let reminder       = EKReminder(eventStore: store)
        reminder.title     = reminderTitle
        reminder.calendar  = store.defaultCalendarForNewReminders()
        if let due = dueDate {
            reminder.dueDateComponents = Calendar.current.dateComponents(in: .current, from: due)
        }
        try store.save(reminder, commit: true)

        // Link to note in SwiftData
        let linked = LinkedReminder(reminderIdentifier: reminder.calendarItemIdentifier)
        linked.note = note
        ctx.insert(linked)
        try ctx.save()

        let dueLine = dueDate.map { " due \(relativeDateString($0))" } ?? ""
        return .result(dialog: "Added \"\(reminderTitle)\"\(dueLine) to \"\(noteTitle)\".")
    }

    private func relativeDateString(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date)    { return "today" }
        if cal.isDateInTomorrow(date) { return "tomorrow" }
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .short
        return fmt.string(from: date)
    }
}

// MARK: - 3. Show Today's Notes

/// Opens the app so the user can browse notes modified today.
struct ShowTodaysNotesIntent: AppIntent {

    static var title: LocalizedStringResource = "Show Today's Notes"
    static var description = IntentDescription("Opens 574 and shows notes from today.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        .result()
    }
}

// MARK: - App Shortcuts

struct NoteShortcuts: AppShortcutsProvider {

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CreateNoteIntent(),
            phrases: [
                "New note in \(.applicationName)",
                "Create a note in \(.applicationName)"
            ],
            shortTitle: "New Note",
            systemImageName: "square.and.pencil"
        )
        AppShortcut(
            intent: AddReminderToNoteIntent(),
            phrases: [
                "Add reminder in \(.applicationName)",
                "Remind me in \(.applicationName)"
            ],
            shortTitle: "Add Reminder",
            systemImageName: "bell.badge.plus"
        )
        AppShortcut(
            intent: ShowTodaysNotesIntent(),
            phrases: [
                "Show today's notes in \(.applicationName)",
                "Open \(.applicationName) today"
            ],
            shortTitle: "Today's Notes",
            systemImageName: "calendar.badge.clock"
        )
    }
}

// MARK: - Errors

private struct NoteNotFoundError: LocalizedError {
    let name: String
    var errorDescription: String? { "No note found with the title \"\(name)\"." }
}

private struct RemindersAccessDeniedError: LocalizedError {
    var errorDescription: String? {
        "Reminders access was denied. Please allow access in Settings."
    }
}
