//
//  NoteCardView.swift
//  574
//
//  Created by Joseph DeWeese on 5/3/26.
//

import SwiftUI
import SwiftData

/// A premium card-style list cell that elegantly summarises a single ``Note``.
///
/// Features:
/// - Sophisticated rounded semibold typography
/// - Faithful rich-text preview (preserves bold/italic/etc.)
/// - Subtle bottom fade on long content
/// - Clean tag display (max 4 pills + "+N more")
/// - Refined card with depth, breathing room, and modern shadows
/// - Excellent accessibility support
///
/// Used exclusively inside ``NoteListView``.
struct NoteCardView: View {

    // MARK: - Properties

    /// The note to render.
    let note: Note

    @Environment(ThemeManager.self) private var themeManager

    // MARK: - Constants (easy to tweak later)

    private let cardCornerRadius: CGFloat = 10
    private let cardPadding: CGFloat = 12
    private let verticalSpacing: CGFloat = 10
    private let maxVisibleTags = 4

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: verticalSpacing) {
            titleRow
            if !note.attributedContent.string.isEmpty {
                contentPreview
            }
            bottomRow
        }
        .padding(cardPadding)
        .background(cardBackground)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        // VoiceOver treats the entire card as one logical item
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint("Double-tap to open note")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Subviews

    private var titleRow: some View {
        Text(note.title.isEmpty ? "Untitled Note" : note.title)
            .font(.system(.headline, design: .rounded, weight: .semibold))
            .foregroundStyle(note.title.isEmpty ? .secondary : .primary)
            .lineLimit(2)
    }

    private var contentPreview: some View {
        Text(AttributedString(note.attributedContent))
            .font(.caption)
            .foregroundStyle(.primary.opacity(0.85))
            .lineLimit(5)
            .lineSpacing(1.3)
            .multilineTextAlignment(.leading)
            .truncationMode(.tail)
            // Elegant fade at bottom when content is long
            .overlay(
                LinearGradient(
                    colors: [.clear, themeManager.current.palette.cardBackground],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 32)
                .padding(.top, 52),
                alignment: .bottom
            )
    }

    private var bottomRow: some View {
        HStack(alignment: .center) {
            if !note.tags.isEmpty {
                tagStrip
            }
            Spacer(minLength: 0)
            Text(note.modifiedAt, style: .relative)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.tertiary)
        }
    }

    private var tagStrip: some View {
        HStack(spacing: 6) {
            let visibleTags = Array(note.tags.prefix(maxVisibleTags))
            ForEach(visibleTags) { tag in
                TagPill(tag: tag)
            }
            if note.tags.count > maxVisibleTags {
                Text("+\(note.tags.count - maxVisibleTags)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(.tertiary.opacity(0.15)))
            }
        }
    }

    private var cardBackground: some View {
        let card = themeManager.current.palette.cardBackground
        let isDark = themeManager.current.palette.isDark
        return RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
            .fill(card.gradient)
            .shadow(color: .black.opacity(isDark ? 0.25 : 0.07), radius: 10, y: 4)
            .shadow(color: .black.opacity(isDark ? 0.15 : 0.04), radius: 3, y: 2)
    }

    // MARK: - Accessibility

    private var accessibilityDescription: String {
        var parts: [String] = []
        parts.append(note.title.isEmpty ? "Untitled Note" : note.title)

        let preview = note.attributedContent.string.prefix(140)
        if !preview.isEmpty {
            parts.append(String(preview))
        }

        if !note.tags.isEmpty {
            let tagNames = note.tags.map(\.name).joined(separator: ", ")
            parts.append("Tags: \(tagNames)")
        }

        return parts.joined(separator: ". ")
    }
}

// MARK: - Previews

#Preview("Note Card Variations") {
    ScrollView {
        VStack(spacing: 20) {
            NoteCardView(note: makeTestNote(
                title: "Q2 Planning Meeting",
                content: "Discussed new product roadmap and assigned action items to the team."
            ))

            NoteCardView(note: makeTestNote(
                title: "Personal Ideas for Garden Redesign",
                content: "Need to research native plants and find a good spot for the new water feature.",
                tags: [
                    Tag(name: "home"),
                    Tag(name: "garden"),
                    Tag(name: "ideas")
                ]
            ))

            NoteCardView(note: makeTestNote(
                title: "",
                content: "Just a quick brain dump of random thoughts while walking the dog."
            ))

            NoteCardView(note: makeTestNote(
                title: "Long note with many tags",
                content: "This note has quite a bit of content to test the truncation and fade effect...",
                tags: (1...7).map { i in Tag(name: "tag\(i)") }
            ))
        }
        .padding()
    }
    .modelContainer(for: [Note.self, Tag.self, Folder.self], inMemory: true)
}

// MARK: - Preview Helpers

/// Creates a fully-populated test `Note` that works with the real model.
private func makeTestNote(
    title: String,
    content: String = "",
    tags: [Tag] = []
) -> Note {
    let note = Note(title: title)

    if !content.isEmpty {
        // Create NSAttributedString so rich-text preview works
        note.attributedContent = NSAttributedString(string: content)
    }

    note.tags = tags
    // modifiedAt is already set by the model

    return note
}
