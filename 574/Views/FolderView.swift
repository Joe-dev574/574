//
//  FolderView.swift
//  574
//
//  Created by Joseph DeWeese on 5/3/26.
//

import SwiftUI
import SwiftData

@MainActor
struct FolderView: View {

    // MARK: - Environment & Queries
    @Environment(\.modelContext)    private var modelContext
    @Environment(ThemeManager.self) private var themeManager

    @Query(sort: \Folder.order)  private var folders: [Folder]
    @Query(sort: \Project.order) private var projects: [Project]
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
    @State private var showingSettings = false
    @State private var profileImage: Image? = Image(systemName: "person.circle.fill")

    // MARK: - Palette shortcut
    private var palette: ThemePalette { themeManager.current.palette }

    // MARK: - Body
    var body: some View {
        List(selection: $selectedFolder) {

            // Profile hero header
            Section {
                HStack {
                    Button { showingSettings = true } label: {
                        profileImage?
                            .resizable()
                            .scaledToFill()
                            .frame(width: 48, height: 48)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())

            // MARK: Folders
            Section("Folders") {
                ForEach(folders) { folder in
                    NavigationLink(value: folder) {
                        folderRow(folder)
                    }
                    .accessibilityLabel(folder.name)
                    .contextMenu { folderContextMenu(for: folder) }
                }
                .onMove { source, destination in
                    reorder(items: folders, from: source, to: destination)
                }
            }

            // MARK: Projects
            Section("Projects") {
                Button {
                    showingNewProjectSheet = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(palette.secondaryText)
                        Text("New Project")
                            .font(.headline)
                            .foregroundStyle(palette.primaryText)
                        Spacer()
                    }
                    .padding()
                    .background(palette.primaryText.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))

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
                .onMove { source, destination in
                    reorder(items: projects, from: source, to: destination)
                }
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
                            .foregroundStyle(palette.primaryText)
                        Spacer(minLength: 0)
                        if !trashedNotes.isEmpty {
                            Text("\(trashedNotes.count)")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(palette.secondaryText)
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
        .background(palette.sidebarBackground.ignoresSafeArea())
        .navigationTitle("Folders")
        .toolbar { toolbarContent }
        .sheet(isPresented: $showingNewFolderSheet)  { NewFolderView() }
        .sheet(isPresented: $showingNewProjectSheet) { NewProjectView() }
        .sheet(item: $folderToEdit) { folder in EditFolderView(folder: folder) }
        .sheet(isPresented: $showingThemePicker) {
            ThemePickerView().environment(themeManager)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .onChange(of: selectedFolder) { _, newValue in
            if newValue != nil { showTrash = false; selectedProject = nil }
        }
        .onChange(of: selectedProject) { _, newValue in
            if newValue != nil { selectedFolder = nil; showTrash = false }
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
                .foregroundStyle(palette.primaryText)
            Spacer(minLength: 0)
            if noteCount > 0 {
                Text("\(noteCount)")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(palette.secondaryText)
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
                .foregroundStyle(palette.primaryText)
            Spacer(minLength: 0)
            if noteCount > 0 {
                Text("\(noteCount)")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(palette.secondaryText)
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
                    .foregroundStyle(palette.accent)
            }
            .help("Workspace Theme")
        }
        ToolbarItem(placement: .automatic) {
            Button { showingSettings = true } label: {
                Image(systemName: "gear")
            }
            .help("Settings")
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

    // MARK: - Reorder / Delete

    private func reorder<T: PersistentModel & Identifiable>(
        items: [T], from source: IndexSet, to destination: Int
    ) {
        var reordered = items
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, item) in reordered.enumerated() {
            if let f = item as? Folder  { f.order = index }
            else if let p = item as? Project { p.order = index }
        }
        try? modelContext.save()
    }

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
