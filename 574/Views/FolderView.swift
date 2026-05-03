//
//  FolderView.swift
//  574
//
//  Created by Joseph DeWeese on 5/3/26.
//
//  Sidebar column showing the user's folder list.
//  Folder creation is handled by NewFolderView.
//  Folder editing (rename + colour) is handled by EditFolderView.
//

import SwiftUI
import SwiftData
@MainActor
struct FolderView: View {
    // MARK: - Environment & Queries
    @Environment(\.modelContext)    private var modelContext
    @Environment(ThemeManager.self) private var themeManager
    @Query(sort: \Folder.createdAt) private var folders: [Folder]
    @Query(
        filter: #Predicate<Note> { $0.deletedAt != nil }
    ) private var trashedNotes: [Note]
    // MARK: - Bindings
    @Binding var selectedFolder: Folder?
    @Binding var showTrash: Bool
    // MARK: - State
    @State private var showingNewFolderSheet = false
    @State private var folderToEdit: Folder?
    @State private var showingThemePicker   = false
    // MARK: - Body
    var body: some View {
        List(selection: $selectedFolder) {
            Section("Folders") {
                ForEach(folders) { folder in
                    NavigationLink(value: folder) {
                        Label {
                            Text(folder.name)
                                .foregroundStyle(.primary)
                        } icon: {
                            Image(systemName: folder.name == "Junk Drawer" ? "archivebox" : "folder.fill")
                                .foregroundStyle(folder.accentColor)
                        }
                    }
                    .accessibilityLabel(folder.name)
                    .contextMenu { contextMenu(for: folder) }
                }
            }
            // Phase B — Trash row
            Section {
                Button {
                    selectedFolder = nil
                    showTrash = true
                } label: {
                    Label {
                        Text("Trash")
                            .foregroundStyle(.primary)
                    } icon: {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                    }
                }
                .buttonStyle(.plain)
                .listRowBackground(showTrash ? Color.accentColor.opacity(0.2) : Color.clear)
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(themeManager.current.palette.sidebarBackground.ignoresSafeArea())
        .navigationTitle("Folders")
        .toolbar { toolbarContent }
        .sheet(isPresented: $showingNewFolderSheet) { NewFolderView() }
        .sheet(item: $folderToEdit) { folder in EditFolderView(folder: folder) }
        .sheet(isPresented: $showingThemePicker) {
            ThemePickerView()
                .environment(themeManager)
        }
        .onChange(of: selectedFolder) { _, newValue in
            if newValue != nil { showTrash = false }
        }
    }
    // MARK: - Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button { showingNewFolderSheet = true } label: {
                Image(systemName: "folder.badge.plus")
            }
            .help("New Folder")
            .accessibilityLabel("New Folder")
            .keyboardShortcut("n", modifiers: [.command, .shift])
        }
        ToolbarItem(placement: .automatic) {
            Button { showingThemePicker = true } label: {
                Image(systemName: "paintpalette")
                    .foregroundStyle(themeManager.current.palette.accent)
            }
            .help("Workspace Theme")
            .accessibilityLabel("Choose workspace theme")
        }
    }
    // MARK: - Context Menu
    @ViewBuilder
    private func contextMenu(for folder: Folder) -> some View {
        if folder.name != "Junk Drawer" {
            Button("Rename…") { folderToEdit = folder }
            Button("Change Colour…") { folderToEdit = folder }
            Divider()
            Button("Delete", role: .destructive) { deleteFolder(folder) }
        }
    }
    // MARK: - Helpers
    private func deleteFolder(_ folder: Folder) {
        guard folder.name != "Junk Drawer" else { return }
        modelContext.delete(folder)
        try? modelContext.save()
    }
}
// MARK: - Preview
#Preview {
    FolderView(selectedFolder: .constant(nil), showTrash: .constant(false))
        .modelContainer(for: [Folder.self, Note.self], inMemory: true)
        .frame(width: 220)
}
