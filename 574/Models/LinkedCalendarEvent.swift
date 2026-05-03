//
//  LinkedCalendarEvent.swift
//  574
//
//  Created by Joseph DeWeese on 5/3/26.
//


// MARK: - LinkedCalendarEvent

import SwiftData
import Foundation

/// A lightweight record that links a ``Note`` to a system Calendar event.
///
/// The `eventIdentifier` matches `EKEvent.calendarItemIdentifier` and is used
/// by ``EventKitManager`` to perform bidirectional sync.
@Model
final class LinkedCalendarEvent {

    // MARK: Stored Properties

    var id: UUID

    /// `EKEvent.calendarItemIdentifier` for round-trip lookup via EventKit.
    var eventIdentifier: String?

    var createdAt: Date

    /// The note that owns this event link.
    var note: Note?

    // MARK: Init

    init(eventIdentifier: String? = nil) {
        self.id = UUID()
        self.eventIdentifier = eventIdentifier
        self.createdAt = Date()
    }
}
