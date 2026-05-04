//
//  FolderView.swift
//  574
//
//  Created by Joseph DeWeese on 5/3/26.
//
//  Sidebar column: Folders, Projects, and Trash.
//  Folder rows use large rounded-square icons.
//  Project rows show app-icon-style hero images (ProjectIconView).
//

import SwiftUI
import SwiftData

@MainActor
struct FolderView: View {

    // MARK: - Environment & Queries

    @Environment(\.modelContext)    private var modelContext
    @Environment(ThemeManager.self) private var themeManager
    @Query(sort: \Folder.createdAt)  private var folders: [Folder]
    @Query(sort: \Project.createdAt) private var projects: [Project]
    @Query(filter: #Predicate<Note> { $0.deletedAt != nil }) private var trashedNotes: [Note]

    // MARK: - Bindings

    @Binding var selectedFolder:  Folder?
    @Binding var showTrash:       Bool
    @Binding var selectedProject: Project?

    // MARK: - State

    @State private var showingNewFolderSheet  = false
    @State private var showingNewProjectSheet = false
    @State private var folderToEdit: Folder?
    @State private var showingThemePicker = false

    // MARK: - Body

    var body: some View {
        List(selection: $selectedFolder) {

            // MARK: Folders
            Section("Folders") {
                ForEach(folders) { folder in
                    NavigationLink(value: folder) {
                        folderRow(folder)
                    }
                    .accessibilityLabel(folder.name)
                    .contextMenu { folderContextMenu(for: folder) }
                }
            }

            // MARK: Projects
            Section("Projects") {
                ForEach(projects) { project in
                    Button {
                        selectedProject = project
                        selectedFolder  = nil
                        showTrash       = false
                    } label: {
                        projectRow(project)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(
                        selectedProject?.id == project.id
                            ? Color.accentColor.opacity(0.18)
                            : Color.clear
                    )
                    .contextMenu { projectContextMenu(for: project) }
                }

                Button {
                    showingNewProjectSheet = true
                } label: {
                    Label("New Project", systemImage: "plus.circle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            // MARK: Trash
            Section {
                Button {
                    selectedFolder  = nil
                    selectedProject = nil
                    showTrash       = true
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.red.opacity(0.12))
                                .frame(width: 34, height: 34)
                            Image(systemName: "trash.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.red)
                        }
                        Text("Trash")
                            .font(.system(.body, weight: .medium))
                            .foregroundStyle(.primary)
                        Spacer(minLength: 0)
                        if !trashedNotes.isEmpty {
                            Text("\(trashedNotes.count)")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 3)
                }
                .buttonStyle(.plain)
                .listRowBackground(showTrash ? Color.accentColor.opacity(0.18) : Color.clear)
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(themeManager.current.palette.sidebarBackground.ignoresSafeArea())
        .navigationTitle("Folders")
        .toolbar { toolbarContent }
        .sheet(isPresented: $showingNewFolderSheet)  { NewFolderView() }
        .sheet(isPresented: $showingNewProjectSheet) { NewProjectView() }
        .sheet(item: $folderToEdit) { folder in EditFolderView(folder: folder) }
        .sheet(isPresented: $showingThemePicker) {
            ThemePickerView()
                .environment(themeManager)
        }
        .onChange(of: selectedFolder) { _, newValue in
            if newValue != nil {
                showTrash       = false
                selectedProject = nil
            }
        }
        .onChange(of: selectedProject) { _, newValue in
            if newValue != nil {
                selectedFolder = nil
                showTrash      = false
            }
        }
    }

    // MARK: - Row Views

    private func folderRow(_ folder: Folder) -> some View {
        let noteCount = folder.notes.filter { $0.deletedAt == nil }.count
        return HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(folder.accentColor.opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: folder.name == "Junk Drawer" ? "archivebox.fill" : "folder.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(folder.accentColor)
            }
            Text(folder.name)
                .font(.system(.body, weight: .medium))
                .foregroundStyle(.primary)
            Spacer(minLength: 0)
            if noteCount > 0 {
                Text("\(noteCount)")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 3)
    }

    private func projectRow(_ project: Project) -> some View {
        let noteCount = project.notes.filter { $0.deletedAt == nil }.count
        return HStack(spacing: 12) {
            ProjectIconView(project: project, size: 34)
            Text(project.name)
                .font(.system(.body, weight: .medium))
                .foregroundStyle(.primary)
            Spacer(minLength: 0)
            if noteCount > 0 {
                Text("\(noteCount)")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 3)
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

    // MARK: - Context Menus

    @ViewBuilder
    private func folderContextMenu(for folder: Folder) -> some View {
        if folder.name != "Junk Drawer" {
            Button("Rename…")        { folderToEdit = folder }
            Button("Change Colour…") { folderToEdit = folder }
            Divider()
            Button("Delete", role: .destructive) { deleteFolder(folder) }
        }
    }

    @ViewBuilder
    private func projectContextMenu(for project: Project) -> some View {
        Button("Delete", role: .destructive) { deleteProject(project) }
    }

    // MARK: - Helpers

    private func deleteFolder(_ folder: Folder) {
        guard folder.name != "Junk Drawer" else { return }
        if selectedFolder?.id == folder.id { selectedFolder = nil }
        modelContext.delete(folder)
        try? modelContext.save()
    }

    private func deleteProject(_ project: Project) {
        if selectedProject?.id == project.id { selectedProject = nil }
        modelContext.delete(project)
        try? modelContext.save()
    }
}

// MARK: - Preview

#Preview {
    FolderView(
        selectedFolder:  .constant(nil),
        showTrash:       .constant(false),
        selectedProject: .constant(nil)
    )
    .modelContainer(for: [Folder.self, Note.self, Project.self], inMemory: true)
    .frame(width: 220)
}
