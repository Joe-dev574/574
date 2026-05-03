//
//  EventKitManager.swift
//  574
//
//  Created by Joseph DeWeese on 5/3/26.
//
//  Production unified EventKit manager — Phase 0 / Phase 1 milestone.
//
//  Responsibilities
//  ────────────────
//  • Requests full-access permissions (required for write operations on macOS 14+ / iOS 17+).
//  • Provides full CRUD for both Reminders and Calendar events.
//  • Links every created item to a ``Note`` via a ``LinkedReminder`` or
//    ``LinkedCalendarEvent`` SwiftData record for bidirectional sync.
//  • Natural-language date parsing stub (Phase 1 implementation).
//
//  Required Info.plist keys
//  ────────────────────────
//  NSCalendarsFullAccessUsageDescription
//  NSRemindersFullAccessUsageDescription
//

import Foundation
import EventKit
import SwiftData
import Observation

/// Singleton manager for all EventKit (Reminders + Calendar) operations.
///
/// Acquire the shared instance and call the async methods from any `@MainActor`
/// context.  All mutations are committed immediately (`commit: true`) so changes
/// appear in system apps without delay.
@MainActor
@Observable
final class EventKitManager {

    // MARK: - Shared Instance

    static let shared = EventKitManager()

    // MARK: - Private Properties

    private let eventStore = EKEventStore()

    // MARK: - Init

    private init() {}

    // MARK: - Authorisation

    /// Requests full write access for the specified entity type.
    ///
    /// Uses the modern `requestFullAccessToEvents()` / `requestFullAccessToReminders()`
    /// API introduced in macOS 14 / iOS 17.  Earlier APIs are deprecated.
    ///
    /// - Parameter entityType: `.event` for Calendar, `.reminder` for Reminders.
    /// - Returns: `true` if the user granted access.
    /// - Throws: An `EKError` if the system rejects the request.
    private func requestFullAccess(for entityType: EKEntityType) async throws -> Bool {
        switch entityType {
        case .event:    return try await eventStore.requestFullAccessToEvents()
        case .reminder: return try await eventStore.requestFullAccessToReminders()
        @unknown default: return false
        }
    }

    // MARK: - DateComponents Helper

    /// Converts a `Date` into `DateComponents` using the current calendar and time zone.
    private func dateComponents(from date: Date) -> DateComponents {
        Calendar.current.dateComponents(in: .current, from: date)
    }

    // MARK: - Reminder Fetch Helper

    /// Wraps the callback-based `EKEventStore.fetchReminders` in an async/await interface.
    private func fetchReminders(matching predicate: NSPredicate) async throws -> [EKReminder] {
        try await withCheckedThrowingContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: reminders ?? [])
            }
        }
    }

    // MARK: - Reminders: Fetch Linked

    /// Fetches all `EKReminder` objects whose identifiers are stored in `note.linkedReminders`.
    ///
    /// Results are sorted by due date (ascending, undated reminders last).
    /// Stale links (reminders deleted from the system Reminders app) are silently omitted.
    ///
    /// - Parameter note: The ``Note`` whose linked reminders should be loaded.
    /// - Returns: An array of matching `EKReminder` objects, sorted by due date.
    /// - Throws: An access-denied error (code 401) or an `EKError`.
    func fetchLinkedReminders(for note: Note) async throws -> [EKReminder] {
        guard try await requestFullAccess(for: .reminder) else {
            throw NSError(
                domain: "EventKitManager",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: NSLocalizedString(
                    "Reminders access was denied. Please enable it in System Settings.",
                    comment: "Error shown when Reminders permission is missing")])
        }

        let identifiers = Set(note.linkedReminders.compactMap(\.reminderIdentifier))
        guard !identifiers.isEmpty else { return [] }

        let predicate = eventStore.predicateForReminders(in: nil)
        let all       = try await fetchReminders(matching: predicate)
        let linked    = all.filter { identifiers.contains($0.calendarItemIdentifier) }

        // Sort by due date ascending; undated reminders are placed at the end.
        return linked.sorted { lhs, rhs in
            let ld = lhs.dueDateComponents.flatMap { Calendar.current.date(from: $0) }
            let rd = rhs.dueDateComponents.flatMap { Calendar.current.date(from: $0) }
            switch (ld, rd) {
            case let (l?, r?): return l < r
            case (nil, _?):    return false
            case (_?, nil):    return true
            case (nil, nil):   return false
            }
        }
    }

    // MARK: - Reminders: Full CRUD

    /// Creates a new Reminders item and links it to `note` in SwiftData.
    ///
    /// - Parameters:
    ///   - title: The reminder title (required, non-empty).
    ///   - dueDate: Optional due date.  Natural-language parsing is added in Phase 1.
    ///   - priority: 0–9, where higher values indicate higher urgency.
    ///   - note: The ``Note`` to associate with this reminder.
    ///   - context: The `ModelContext` used to persist the ``LinkedReminder`` record.
    /// - Returns: The newly saved ``EKReminder``.
    /// - Throws: ``EKError`` on save failure or a domain error if access is denied.
    @discardableResult
    func createReminder(
        title: String,
        dueDate: Date? = nil,
        priority: Int = 0,
        in note: Note,
        context: ModelContext
    ) async throws -> EKReminder {
        guard try await requestFullAccess(for: .reminder) else {
            throw NSError(
                domain: "EventKitManager",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: NSLocalizedString(
                    "Reminders access was denied. Please enable it in System Settings.",
                    comment: "Error shown when Reminders permission is missing")])
        }

        let reminder = EKReminder(eventStore: eventStore)
        reminder.title    = title
        reminder.priority = priority
        if let dueDate { reminder.dueDateComponents = dateComponents(from: dueDate) }
        reminder.calendar = eventStore.defaultCalendarForNewReminders()

        try eventStore.save(reminder, commit: true)

        let linked = LinkedReminder(reminderIdentifier: reminder.calendarItemIdentifier)
        linked.note = note
        context.insert(linked)
        try context.save()

        return reminder
    }

    /// Updates an existing Reminders item identified by its calendar item identifier.
    ///
    /// - Parameters:
    ///   - identifier: `EKReminder.calendarItemIdentifier` stored in ``LinkedReminder``.
    ///   - title: New title, or `nil` to leave unchanged.
    ///   - dueDate: New due date, or `nil` to leave unchanged.
    ///   - completed: New completion state, or `nil` to leave unchanged.
    func updateReminder(
        identifier: String,
        title: String?   = nil,
        dueDate: Date?   = nil,
        completed: Bool? = nil
    ) async throws {
        guard try await requestFullAccess(for: .reminder) else { return }

        let predicate = eventStore.predicateForReminders(in: nil)
        let reminders = try await fetchReminders(matching: predicate)
        guard let reminder = reminders.first(where: { $0.calendarItemIdentifier == identifier }) else {
            return
        }

        if let title     { reminder.title = title }
        if let dueDate   { reminder.dueDateComponents = dateComponents(from: dueDate) }
        if let completed { reminder.isCompleted = completed }

        try eventStore.save(reminder, commit: true)
    }

    /// Deletes the Reminders item with the given identifier.
    func deleteReminder(identifier: String) async throws {
        guard try await requestFullAccess(for: .reminder) else { return }

        let predicate = eventStore.predicateForReminders(in: nil)
        let reminders = try await fetchReminders(matching: predicate)
        guard let reminder = reminders.first(where: { $0.calendarItemIdentifier == identifier }) else {
            return
        }
        try eventStore.remove(reminder, commit: true)
    }

    // MARK: - Calendar Events: Full CRUD

    /// Creates a new calendar event and links it to `note` in SwiftData.
    ///
    /// - Parameters:
    ///   - title: The event title.
    ///   - startDate: The event start.
    ///   - endDate: The event end (must be ≥ `startDate`).
    ///   - note: The ``Note`` to associate with this event.
    ///   - context: The `ModelContext` used to persist the ``LinkedCalendarEvent`` record.
    /// - Returns: The newly saved ``EKEvent``.
    @discardableResult
    func createEvent(
        title: String,
        startDate: Date,
        endDate: Date,
        in note: Note,
        context: ModelContext
    ) async throws -> EKEvent {
        guard try await requestFullAccess(for: .event) else {
            throw NSError(
                domain: "EventKitManager",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: NSLocalizedString(
                    "Calendar access was denied. Please enable it in System Settings.",
                    comment: "Error shown when Calendar permission is missing")])
        }

        let event       = EKEvent(eventStore: eventStore)
        event.title     = title
        event.startDate = startDate
        event.endDate   = endDate
        event.calendar  = eventStore.defaultCalendarForNewEvents
        try eventStore.save(event, span: .thisEvent)

        let linked = LinkedCalendarEvent(eventIdentifier: event.calendarItemIdentifier)
        linked.note = note
        context.insert(linked)
        try context.save()

        return event
    }

    // MARK: - Calendar Events: Fetch Linked

    /// Fetches all `EKEvent` objects whose identifiers are stored in `note.linkedCalendarEvents`.
    ///
    /// Uses `EKEventStore.calendarItem(withIdentifier:)` for O(1) lookup — no date-range scan needed.
    /// Stale links (events deleted from Calendar.app) are silently omitted.
    ///
    /// - Parameter note: The ``Note`` whose linked events should be loaded.
    /// - Returns: Events sorted by start date ascending.
    /// - Throws: An access-denied error (code 401) or an `EKError`.
    func fetchLinkedEvents(for note: Note) async throws -> [EKEvent] {
        guard try await requestFullAccess(for: .event) else {
            throw NSError(
                domain: "EventKitManager",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: NSLocalizedString(
                    "Calendar access was denied. Please enable it in System Settings.",
                    comment: "Error shown when Calendar permission is missing")])
        }
        let identifiers = note.linkedCalendarEvents.compactMap(\.eventIdentifier)
        guard !identifiers.isEmpty else { return [] }
        return identifiers
            .compactMap { eventStore.calendarItem(withIdentifier: $0) as? EKEvent }
            .sorted { $0.startDate < $1.startDate }
    }

    /// Removes the calendar event with the given identifier from Calendar.app.
    func deleteEvent(identifier: String) async throws {
        guard try await requestFullAccess(for: .event) else { return }
        guard let event = eventStore.calendarItem(withIdentifier: identifier) as? EKEvent else { return }
        try eventStore.remove(event, span: .thisEvent)
    }

    // MARK: - Natural Language Date Parsing (Phase 1 Stub)

    /// Parses a natural-language date string into a `Date` using `NSDataDetector`.
    ///
    /// Examples: `"tomorrow at 3pm"`, `"next Friday"`, `"in 2 hours"`.
    ///
    /// - Parameters:
    ///   - string: The string to parse.
    ///   - referenceDate: The date relative to which "tomorrow" etc. are resolved (default: now).
    /// - Returns: The first detected date, or `nil` if none was found.
    static func parseNaturalDate(_ string: String, relativeTo referenceDate: Date = Date()) -> Date? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        return detector?
            .matches(in: string, range: NSRange(string.startIndex..., in: string))
            .first?.date
    }
}
