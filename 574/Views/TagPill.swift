//
//  TagPill.swift
//  574
//
//  Created by Joseph DeWeese on 5/3/26.
//

import SwiftUI

/// A compact pill-shaped badge that renders a single ``Tag`` name.
struct TagPill: View {
    let tag: Tag
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        Text(tag.name)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(themeManager.current.palette.primaryText)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(themeManager.current.palette.accent.opacity(0.22))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .accessibilityLabel("Tag: \(tag.name)")
    }
}

// MARK: - Preview

#Preview {
    TagPill(tag: Tag(name: "Swift"))
        .padding()
}
