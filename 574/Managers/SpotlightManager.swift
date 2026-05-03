//
//  SpotlightManager.swift
//  574
//
//  Created by Joseph DeWeese on 5/3/26.
//
//  Indexes Note objects in CoreSpotlight so they appear in system search.
//  Call index(_:) on every save and deindex(_:) before deletion.
//

import CoreSpotlight
import UniformTypeIdentifiers
import Foundation

/// Namespace for CoreSpotlight indexing of ``Note`` objects.
///
/// All methods fire-and-forget — the index operation completes asynchronously
/// in the background and never blocks the caller.
enum SpotlightManager {

    private static let domain = "com.indiegrind.574.note"

    // MARK: - Index

    /// Adds or updates the Spotlight entry for `note`.
    static func index(_ note: Note) {
        let attrs = CSSearchableItemAttributeSet(contentType: UTType.text)
        attrs.title = note.title.isEmpty ? "Untitled Note" : note.title
        let body = note.attributedContent.string
        if !body.isEmpty {
            attrs.contentDescription = String(body.prefix(500))
        }
        attrs.contentCreationDate     = note.createdAt
        attrs.contentModificationDate = note.modifiedAt
        if let folderName = note.folder?.name {
            attrs.keywords = [folderName]
        }

        let item = CSSearchableItem(
            uniqueIdentifier: note.id.uuidString,
            domainIdentifier: domain,
            attributeSet: attrs
        )
        item.expirationDate = .distantFuture

        CSSearchableIndex.default().indexSearchableItems([item]) { _ in }
    }

    // MARK: - Deindex

    /// Removes the Spotlight entry for `note`.
    static func deindex(_ note: Note) {
        CSSearchableIndex.default().deleteSearchableItems(
            withIdentifiers: [note.id.uuidString]) { _ in }
    }
}
