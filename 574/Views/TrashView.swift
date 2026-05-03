//
//  TrashView.swift
//  574
//
//  Created by Joseph DeWeese on 5/3/26.
//

import SwiftUI
import SwiftData
struct TrashView: View {
    // MARK: - Environment
    @Environment(\.modelContext)    private var modelContext
    @Environment(ThemeManager.self) private var themeManager
    // MARK: - Queries
    @Query(
        filter: #Predicate<Note> { $0.deletedAt != nil },
        sort: \Note.deletedAt, order: .reverse
    ) private var trashedNotes: [Note]
    // MARK: - State
    @State private var showingEmptyTrashConfirmation = false
    @Binding var selectedNote: Note?
    // MARK: - Body
    var body: some View {
        List(selection: $selectedNote) {
            ForEach(trashedNotes) { note in
                TrashNoteRow(note: note)
                    .contextMenu { contextMenu(for: note) }
                    .swipeActions(edge: .trailing) {
                        Button("Restore", systemImage: "arrow.uturn.backward") {
                            restore(note)
                        }
                        .tint(.blue)
                        Button("Delete Forever", systemImage: "trash", role: .destructive) {
                            deleteForever(note)
                        }
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(themeManager.current.palette.listBackground.ignoresSafeArea())
        .navigationTitle("Trash")
        .toolbar { toolbarContent }
        .overlay { emptyState }
        .confirmationDialog("Empty Trash?", isPresented: $showingEmptyTrashConfirmation) {
            Button("Empty Trash", role: .destructive) { emptyTrash() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone. \(trashedNotes.count) note\(trashedNotes.count == 1 ? "" : "s") will be permanently deleted.")
        }
    }
    // MARK: - Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button("Empty Trash", systemImage: "trash") {
                showingEmptyTrashConfirmation = true
            }
            .disabled(trashedNotes.isEmpty)
            .tint(.red)
        }
    }
    // MARK: - Empty State
    @ViewBuilder
    private var emptyState: some View {
        if trashedNotes.isEmpty {
            ContentUnavailableView {
                Label("Trash is Empty", systemImage: "trash")
            } description: {
                Text("Deleted notes appear here for 30 days.")
            }
        }
    }
    // MARK: - Context Menu
    @ViewBuilder
    private func contextMenu(for note: Note) -> some View {
        Button("Restore", systemImage: "arrow.uturn.backward") { restore(note) }
        Button("Delete Forever", systemImage: "trash", role: .destructive) { deleteForever(note) }
    }
    // MARK: - Actions
    private func restore(_ note: Note) {
        note.deletedAt = nil
        SpotlightManager.index(note)
        try? modelContext.save()
    }
    private func deleteForever(_ note: Note) {
        SpotlightManager.deindex(note)
        modelContext.delete(note)
        try? modelContext.save()
        if selectedNote?.id == note.id { selectedNote = nil }
    }
    private func emptyTrash() {
        for note in trashedNotes {
            SpotlightManager.deindex(note)
            modelContext.delete(note)
        }
        try? modelContext.save()
    }
}
// MARK: - TrashNoteRow
private struct TrashNoteRow: View {
    let note: Note
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.title.isEmpty ? "Untitled Note" : note.title)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(1)
            HStack {
                if let folder = note.folder {
                    Label(folder.name, systemImage: "folder.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(note.deletedAt ?? Date(), style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}
// MARK: - Preview
#Preview {
    NavigationStack {
        TrashView(selectedNote: .constant(nil))
    }
    .modelContainer(for: [Note.self, Folder.self], inMemory: true)
}
