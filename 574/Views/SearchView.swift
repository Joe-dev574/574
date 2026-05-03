//
//  SearchView.swift
//  574
//
//  Created by Joseph DeWeese on 5/3/26.
//
//  Full-text search across all notes.
//  Phase 1: in-memory filter on title + body text.
//  Phase 3+: replaced by Spotlight/CoreSpotlight index.
//

import SwiftUI
import SwiftData

/// A searchable list of all notes, filtered by title and body content.
///
/// Used as the Search tab on iOS. On macOS, search lives in the toolbar of ``NoteListView``.
struct SearchView: View {

    // MARK: - Queries & State

    @Query(filter: #Predicate<Note> { $0.deletedAt == nil },
           sort: \Note.modifiedAt, order: .reverse)
    private var allNotes: [Note]

    @State private var query: String = ""
    @State private var selectedNote: Note?

    // MARK: - Computed

    private var results: [Note] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return [] }
        let lower = trimmed.lowercased()
        return allNotes.filter {
            $0.title.lowercased().contains(lower) ||
            $0.attributedContent.string.lowercased().contains(lower)
        }
    }

    // MARK: - Body

    var body: some View {
        List {
            if query.trimmingCharacters(in: .whitespaces).isEmpty {
                emptyPrompt
            } else if results.isEmpty {
                ContentUnavailableView.search(text: query)
            } else {
                ForEach(results) { note in
                    NavigationLink(value: note) {
                        NoteCardView(note: note)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .navigationTitle("Search")
        .searchable(text: $query, prompt: "Search notes…")
        .navigationDestination(for: Note.self) { note in
            NoteDetailView(note: note, selectedNote: $selectedNote)
        }
    }

    // MARK: - Empty Prompt

    private var emptyPrompt: some View {
        ContentUnavailableView {
            Label("Search Your Notes", systemImage: "magnifyingglass")
        } description: {
            Text("Type to search by title or content.")
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SearchView()
    }
    .modelContainer(for: [Note.self, Folder.self, Tag.self], inMemory: true)
}
