//
//  NoteListView.swift
//  574
//
//  Created by Joseph DeWeese on 5/3/26.
//
//  The middle column of the three-pane layout.
//  Shows a filtered list of ``NoteCardView`` cells and a toolbar button
//  to create new notes.
//

import SwiftUI
import SwiftData

/// The note-list column that sits between the folder sidebar and the detail editor.
///
/// When `selectedFolder` is `nil`, all notes are shown ("All Notes").
/// When a folder is selected, only notes belonging to that folder are shown.
///
/// Note creation via the `+` button places the new note in the selected folder,
/// falling back to "Inbox", then "Junk Drawer" if neither is available.
struct NoteListView: View {

    // MARK: - Environment & Queries

    @Environment(\.modelContext)    private var modelContext
    @Environment(ThemeManager.self) private var themeManager
    @Query(filter: #Predicate<Note> { $0.deletedAt == nil },
           sort: \Note.modifiedAt, order: .reverse)
    private var allNotes: [Note]
    @Query(sort: \Folder.createdAt) private var folders: [Folder]

    // MARK: - Properties

    /// The folder whose notes should be displayed.  `nil` shows all notes.
    let selectedFolder: Folder?

    /// When non-nil, shows only notes belonging to this project.
    var filterProject: Project? = nil

    /// The currently selected note, shared with ``ContentView`` and ``NoteDetailView``.
    @Binding var selectedNote: Note?

    // MARK: - State

    @State private var searchQuery: String = ""

    // MARK: - Computed

    /// Notes filtered by project/folder and current search query,
    /// sorted by modification date descending.
    private var notes: [Note] {
        let base: [Note]
        if let project = filterProject {
            base = allNotes.filter { $0.project?.id == project.id }
        } else if let folder = selectedFolder {
            base = allNotes.filter { $0.folder?.id == folder.id }
        } else {
            base = allNotes
        }

        let trimmed = searchQuery.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return base }
        let lower = trimmed.lowercased()
        return base.filter {
            $0.title.lowercased().contains(lower) ||
            $0.attributedContent.string.lowercased().contains(lower)
        }
    }

    private var junkDrawer: Folder? {
        folders.first { $0.name == "Junk Drawer" }
    }

    // MARK: - Body

    var body: some View {
        List(selection: $selectedNote) {
            ForEach(notes) { note in
                NavigationLink(value: note) {
                    NoteCardView(note: note)
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .contextMenu { noteContextMenu(for: note) }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(themeManager.current.palette.listBackground.ignoresSafeArea())
        .navigationTitle(filterProject?.name ?? selectedFolder?.name ?? "All Notes")
        .searchable(text: $searchQuery, prompt: "Search notes…")
        .toolbar { toolbarContent }
        .overlay { emptyState }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button(action: createNewNote) {
                Image(systemName: "square.and.pencil")
                    .font(.title2)
            }
            .buttonStyle(.borderedProminent)
            .help("New Note")
            .accessibilityLabel("Create new note")
            .keyboardShortcut("n", modifiers: .command)
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        if notes.isEmpty {
            if !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
                ContentUnavailableView.search(text: searchQuery)
            } else {
                ContentUnavailableView {
                    Label("No Notes", systemImage: "note.text")
                } description: {
                    Text("Tap the pencil button to create your first note.")
                } actions: {
                    Button("New Note", action: createNewNote)
                        .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func noteContextMenu(for note: Note) -> some View {
        Button("Delete Note", role: .destructive) { deleteNote(note) }
            .accessibilityLabel("Delete \(note.title.isEmpty ? "Untitled Note" : note.title)")
    }

    // MARK: - Actions

    /// Creates a new note and selects it, placing it in the best available folder
    /// and assigning it to the current project if one is active.
    private func createNewNote() {
        let inbox  = folders.first { $0.name == "Inbox" }
        let target = selectedFolder ?? inbox ?? junkDrawer
        let note   = Note(title: "", folder: target, project: filterProject)
        modelContext.insert(note)
        try? modelContext.save()
        selectedNote = note
    }

    /// Soft-deletes `note` by setting its `deletedAt` timestamp.
    /// The note disappears from all lists immediately but can be restored from Trash.
    private func deleteNote(_ note: Note) {
        SpotlightManager.deindex(note)
        if selectedNote?.id == note.id { selectedNote = nil }
        note.deletedAt = Date()
        try? modelContext.save()
    }
}

// MARK: - Preview

#Preview {
    NoteListView(selectedFolder: nil, selectedNote: .constant(nil))
        .modelContainer(for: [Note.self, Folder.self, Tag.self], inMemory: true)
        .frame(width: 280)
}
