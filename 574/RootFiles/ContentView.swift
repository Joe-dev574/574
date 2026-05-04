//
//  ContentView.swift
//  574
//
//  Created by Joseph DeWeese on 5/3/26.
//

import SwiftUI
import SwiftData
import CoreSpotlight


struct ContentView: View {
    // MARK: - Environment
    @Environment(\.modelContext)  private var modelContext
    @Environment(ThemeManager.self) private var themeManager
    // MARK: - State
    @State private var selectedFolder:  Folder?
    @State private var selectedNote:    Note?
    @State private var selectedProject: Project?
    @State private var showTrash: Bool = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    // MARK: - Body
    var body: some View {
        Group {
#if os(macOS)
            macLayout
#else
            iOSLayout
#endif
        }
        .preferredColorScheme(themeManager.current.palette.isDark ? .dark : .light)
    }
    // MARK: - macOS Layout
#if os(macOS)
    private var macLayout: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            FolderView(selectedFolder: $selectedFolder, showTrash: $showTrash, selectedProject: $selectedProject)
                .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 280)
        } content: {
            if showTrash {
                TrashView(selectedNote: $selectedNote)
                    .navigationSplitViewColumnWidth(min: 240, ideal: 280, max: 360)
            } else {
                NoteListView(selectedFolder: selectedFolder, filterProject: selectedProject, selectedNote: $selectedNote)
                    .navigationSplitViewColumnWidth(min: 240, ideal: 280, max: 360)
            }
        } detail: {
            if let note = selectedNote {
                NoteDetailView(note: note, selectedNote: $selectedNote)
                    .id(note.id)
            } else {
                emptyDetailState
            }
        }
        .navigationSplitViewStyle(.balanced)
        .onContinueUserActivity(CSSearchableItemActivityIdentifier, perform: openFromSpotlight)
        .onChange(of: selectedFolder) { _, newValue in
            if newValue != nil { showTrash = false; selectedProject = nil }
        }
        .onChange(of: showTrash) { _, newValue in
            if newValue { selectedFolder = nil; selectedProject = nil }
        }
        .onChange(of: selectedProject) { _, newValue in
            if newValue != nil { selectedFolder = nil; showTrash = false }
        }
    }
#endif

    // MARK: - iOS Layout
#if os(iOS)
    private var iOSLayout: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            FolderView(selectedFolder: $selectedFolder, showTrash: $showTrash, selectedProject: $selectedProject)
        } content: {
            if showTrash {
                TrashView(selectedNote: $selectedNote)
            } else {
                NoteListView(selectedFolder: selectedFolder, filterProject: selectedProject, selectedNote: $selectedNote)
            }
        } detail: {
            if let note = selectedNote {
                NoteDetailView(note: note, selectedNote: $selectedNote)
                    .id(note.id)
            } else {
                emptyDetailState
            }
        }
        .onContinueUserActivity(CSSearchableItemActivityIdentifier, perform: openFromSpotlight)
        .onChange(of: selectedFolder) { _, newValue in
            if newValue != nil { showTrash = false; selectedProject = nil }
        }
        .onChange(of: showTrash) { _, newValue in
            if newValue { selectedFolder = nil; selectedProject = nil }
        }
        .onChange(of: selectedProject) { _, newValue in
            if newValue != nil { selectedFolder = nil; showTrash = false }
        }
    }
#endif

    // MARK: - Shared Empty Detail State
    private var emptyDetailState: some View {
        ContentUnavailableView {
            Label("No Note Selected", systemImage: "note.text")
        } description: {
            Text("Select a note from the list or tap + to create one.")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    // MARK: - Spotlight Handoff (unchanged)
    private func openFromSpotlight(_ activity: NSUserActivity) {
        guard
            let id   = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
            let uuid = UUID(uuidString: id)
        else { return }
        let descriptor = FetchDescriptor<Note>(predicate: #Predicate { $0.id == uuid && $0.deletedAt == nil })
        guard let note = try? modelContext.fetch(descriptor).first else { return }
        selectedFolder  = note.folder
        selectedProject = nil
        selectedNote    = note
        showTrash       = false
    }
}
// MARK: - Preview
#Preview {
    ContentView()
        .modelContainer(for: [Note.self, Folder.self, Tag.self, Project.self], inMemory: true)
}
