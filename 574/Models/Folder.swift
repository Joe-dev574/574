//
//  Folder.swift
//  574
//
//  Created by Joseph DeWeese on 5/3/26.
//


import Foundation
import SwiftData
import SwiftUI

// MARK: - Folder

/// A named container for organising notes in the sidebar.
///
/// Every ``Note`` belongs to at most one folder; a `nil` folder means the note
/// is in the implicit "All Notes" bucket.  The special "Junk Drawer" folder
/// acts as the app's catch-all for unfiled notes.
///
/// - Important: Do not delete the "Junk Drawer" or "Inbox" system folders.
@Model
final class Folder {
    
    // MARK: Stored Properties
    
    var id: UUID
    var name: String
    var createdAt: Date
    
    /// A colour token string (`"blue"`, `"red"`, etc.) used for the sidebar icon tint.
    /// `nil` means the default accent colour is used.
    var colorName: String?
    
    /// Notes contained in this folder.  Deleting the folder cascades to its notes.
    @Relationship(deleteRule: .cascade, inverse: \Note.folder)
    var notes: [Note]
    
    // MARK: Init
    
    init(name: String, colorName: String? = nil) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.colorName = colorName
        self.notes = []
    }
    
    // MARK: Computed
    
    /// The SwiftUI `Color` that corresponds to ``colorName``, following Apple HIG sidebar tinting.
    var accentColor: Color {
        switch colorName {
        case "blue":   return .blue
        case "red":    return .red
        case "green":  return .green
        case "orange": return .orange
        case "purple": return .purple
        case "yellow": return .yellow
        default:       return .primary
        }
    }
}
