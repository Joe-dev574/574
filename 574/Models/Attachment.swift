//
//  Attachment.swift
//  574
//
//  Created by Joseph DeWeese on 5/3/26.
//

import Foundation
import SwiftData

// MARK: - Attachment

/// A file, image, PDF, audio, or video resource attached to a ``Note``.
///
/// Full pipeline (inline display, QuickLook, drag-and-drop) is implemented in Phase 4.
@Model
final class Attachment {

    // MARK: Stored Properties

    var id: UUID
    var fileName: String
    var mimeType: String

    /// Raw file bytes.  For large files this may be replaced with a file bookmark in Phase 4.
    var fileData: Data?

    var createdAt: Date

    /// The note that owns this attachment.
    @Relationship(deleteRule: .nullify)
    var note: Note?

    // MARK: Init

    init(fileName: String, mimeType: String, fileData: Data? = nil) {
        self.id = UUID()
        self.fileName = fileName
        self.mimeType = mimeType
        self.fileData = fileData
        self.createdAt = Date()
    }
}
