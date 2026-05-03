//
//  QuickCaptureView.swift
//  574
//
//  Created by Joseph DeWeese on 5/3/26.
//
//  macOS MenuBarExtra quick note capture — Phase 1.
//  Appears as a window panel anchored to the menu bar icon.
//  Creates a note in the Inbox folder and resets for the next capture.
//

#if os(macOS)
import SwiftUI
import SwiftData

struct QuickCaptureView: View {

    // MARK: - Environment & Queries

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Folder.createdAt) private var folders: [Folder]

    // MARK: - State

    @State private var title: String = ""
    @State private var bodyText: String = ""
    @State private var didSave: Bool = false
    @FocusState private var titleFocused: Bool

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerRow
            Divider()
            inputFields
            Divider()
            actionRow
        }
        .frame(width: 320)
        .onAppear { titleFocused = true }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "note.text")
                .foregroundStyle(.orange)
                .font(.callout)
            Text("Quick Capture")
                .font(.system(.subheadline, weight: .semibold))
            Spacer()
            if didSave {
                Label("Saved", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Input Fields

    private var inputFields: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Title…", text: $title)
                .textFieldStyle(.plain)
                .font(.body.weight(.medium))
                .focused($titleFocused)
                .accessibilityLabel("Note title")
                .onSubmit { titleFocused = false }

            TextField("Add a quick note…", text: $bodyText, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.callout)
                .lineLimit(3...5)
                .foregroundStyle(.secondary)
                .accessibilityLabel("Note body")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: - Action Row

    private var actionRow: some View {
        HStack {
            Text("⌘↩ to save")
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Spacer()
            Button("Save") { save() }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .tint(.orange)
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                .keyboardShortcut(.return, modifiers: .command)
                .accessibilityLabel("Save note")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Save

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else { return }

        let inbox = folders.first { $0.name == "Inbox" }
        let note  = Note(title: trimmedTitle, folder: inbox)

        let trimmedBody = bodyText.trimmingCharacters(in: .whitespaces)
        if !trimmedBody.isEmpty {
            note.attributedContent = NSAttributedString(string: trimmedBody)
        }

        modelContext.insert(note)
        try? modelContext.save()
        SpotlightManager.index(note)

        withAnimation(.easeInOut(duration: 0.2)) { didSave = true }
        title        = ""
        bodyText     = ""
        titleFocused = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { didSave = false }
        }
    }
}

// MARK: - Preview

#Preview {
    QuickCaptureView()
        .modelContainer(for: [Note.self, Folder.self, Tag.self], inMemory: true)
}
#endif
