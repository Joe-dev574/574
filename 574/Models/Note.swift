//
//  Note.swift
//  574

//  Created by Joseph DeWeese on 5/2/26.
//  Copyright © 2026 IndieGrind. All rights reserved.
//
//  Production SwiftData schema — Phase 0.
//  All six model types are defined here so the schema stays in one place.
//  Migrations are handled via VersionedSchema / SchemaMigrationPlan (Phase 1+).
//

import Foundation
import SwiftData

// MARK: - Note

/// The core content model representing a single note.
///
/// Rich text is stored as archived `NSAttributedString` bytes in ``contentData``
/// and surfaced via the ``attributedContent`` computed property, which handles
/// all encoding and decoding transparently.
///
/// Related system objects (reminders, calendar events, and file attachments) are
/// stored as separate child models so they can be fetched and synced independently.
@Model
final class Note {

    // MARK: Stored Properties

    var id: UUID
    var title: String

    /// NSAttributedString archived via NSKeyedArchiver (secure, CloudKit-compatible).
    var contentData: Data?

    var createdAt: Date
    var modifiedAt: Date

    /// Set when the note is moved to the trash.  `nil` means the note is active.
    /// Notes are permanently deleted by `DataSeeder` after 30 days in the trash.
    var deletedAt: Date?

    /// Pinned notes sort to the top of every list.
    var isPinned: Bool = false

    /// When `true` the editor is gated behind device authentication (LocalAuthentication).
    var isLocked: Bool = false

    // MARK: Relationships

    /// The folder that contains this note.  `nil` means the note is unfiled.
    @Relationship(deleteRule: .nullify)
    var folder: Folder?

    var tags: [Tag] = []
    var attachments: [Attachment] = []

    @Relationship(deleteRule: .cascade)
    var linkedReminders: [LinkedReminder] = []

    @Relationship(deleteRule: .cascade)
    var linkedCalendarEvents: [LinkedCalendarEvent] = []

    // MARK: Init

    init(
        title: String = "New Note",
        contentData: Data? = nil,
        folder: Folder? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.contentData = contentData
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.folder = folder
    }

    // MARK: Computed — Rich Text

    /// The note's body as an `NSAttributedString`.
    ///
    /// Getting decodes ``contentData`` using `NSKeyedUnarchiver`.
    /// Setting archives the value back into ``contentData`` and updates ``modifiedAt``.
    var attributedContent: NSAttributedString {
        get {
            guard let data = contentData,
                let attr = try? NSKeyedUnarchiver.unarchivedObject(
                    ofClass: NSAttributedString.self,
                    from: data
                )
            else {
                return NSAttributedString(string: "")
            }
            return attr
        }
        set {
            contentData = try? NSKeyedArchiver.archivedData(
                withRootObject: newValue,
                requiringSecureCoding: true
            )
            modifiedAt = Date()
        }
    }
}
