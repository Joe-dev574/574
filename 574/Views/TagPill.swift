//
//  TagPill.swift
//  574
//
//  Created by Joseph DeWeese on 5/3/26.
//


import SwiftUI

/// A compact pill-shaped badge that renders a single ``Tag`` name.
///
/// Use this view wherever a tag needs to be represented inline —
/// for example, inside ``NoteCardView`` or the tag strip in ``NoteDetailView``.
///
/// ```swift
/// TagPill(tag: myTag)
/// ```
struct TagPill: View {

    // MARK: - Properties

    /// The tag whose name this pill displays.
    let tag: Tag

    // MARK: - Body

    var body: some View {
        Text(tag.name)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.orange.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .accessibilityLabel("Tag: \(tag.name)")
    }
}

// MARK: - Preview

#Preview {
    TagPill(tag: Tag(name: "Swift"))
        .padding()
}

