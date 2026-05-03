//
//  LinkedReminder.swift
//  574
//
//  Created by Joseph DeWeese on 5/3/26.
//

import SwiftData
import Foundation


// MARK: - LinkedReminder

/// A lightweight record that links a ``Note`` to a system Reminders item.
///
/// The `reminderIdentifier` matches `EKReminder.calendarItemIdentifier` and is used
/// by ``EventKitManager`` to perform bidirectional sync.
@Model
final class LinkedReminder {
    
    // MARK: Stored Properties
    
    var id: UUID
    
    /// `EKReminder.calendarItemIdentifier` for round-trip lookup via EventKit.
    var reminderIdentifier: String?
    
    var createdAt: Date
    
    /// The note that owns this reminder link.
    var note: Note?
    
    // MARK: Init
    
    init(reminderIdentifier: String? = nil) {
        self.id = UUID()
        self.reminderIdentifier = reminderIdentifier
        self.createdAt = Date()
    }
}
