//
//  NoteDetailView.swift
//  574
//
//  Created by Joseph DeWeese on 5/3/26.
//
//  The detail pane for a selected note.
//  Auto-saves on every change.  The "Done" button commits the save and
//  clears the selection, dismissing the editor.
//

import SwiftUI
import SwiftData

/// The detail pane that displays and edits a single ``Note``.
///
/// Shown in the trailing column of the three-pane layout when a note is selected.
/// Auto-saves on title and content changes.  The checkmark button commits
/// the final save and clears the selection so the user can pick another note.
///
/// - Note: Pass `selectedNote` as a binding so the Done button can deselect.
struct NoteDetailView: View {

    // MARK: - Properties

    /// The note being edited.  `@Bindable` allows text fields to bind directly
    /// to SwiftData model properties.
    @Bindable var note: Note

    /// Clears the selection when the user taps Done, returning the editor to its
    /// empty state.  Use `.constant(nil)` in previews and SearchView.
    @Binding var selectedNote: Note?

    // MARK: - Environment

    @Environment(\.modelContext)    private var modelContext
    @Environment(ThemeManager.self) private var themeManager

    // MARK: - Queries
    
    @Query(sort: \Folder.createdAt) private var folders: [Folder]
    @Query(sort: \Tag.name) private var existingTags: [Tag]

    // MARK: - State

    @State private var newTagName: String = ""
    @State private var showRemindersPanel: Bool = false

    /// Becomes `true` the moment any content changes so the Done button lights up.
    @State private var hasUnsavedChanges = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            topBar
            tagBar
            Divider()
            RichTextEditorView(attributedText: $note.attributedContent)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onChange(of: note.attributedContent) { _, _ in
                    hasUnsavedChanges = true
                }
        }
        // Use the native SwiftUI inspector API so the panel is a proper
        // resizable trailing column managed by NavigationSplitView — the
        // HStack approach fought the split-view layout constraints.
        .background(themeManager.current.palette.editorBackground.ignoresSafeArea())
        .inspector(isPresented: $showRemindersPanel) {
            NoteRemindersPanel(note: note)
                .inspectorColumnWidth(min: 220, ideal: 264, max: 340)
        }
        .navigationTitle(note.title.isEmpty ? "Untitled Note" : note.title)
        .onDisappear {
            save()
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 12) {
            // Title field
            TextField("Untitled Note", text: $note.title)
                .font(.headline)
                .textFieldStyle(.plain)
                .accessibilityLabel("Note title")
                .onChange(of: note.title) { _, _ in
                    hasUnsavedChanges = true
                    save()
                }

            Spacer()

            folderPicker
            remindersPanelToggle
            doneButton
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: - Folder Picker

    private var folderPicker: some View {
        Menu {
            ForEach(folders) { folder in
                Button {
                    note.folder = folder
                    save()
                } label: {
                    Label(folder.name, systemImage: folder.name == "Junk Drawer" ? "archivebox" : "folder.fill")
                }
                .accessibilityLabel("Move to \(folder.name)")
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: note.folder?.name == "Junk Drawer" ? "archivebox" : "folder.fill")
                Text(note.folder?.name ?? "Inbox")
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.caption)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.windowBackgroundColor).opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .help("Move to folder")
        .accessibilityLabel("Move to folder: \(note.folder?.name ?? "Inbox")")
    }

    // MARK: - Reminders Panel Toggle

    /// Bell button that shows/hides the ``NoteRemindersPanel``.
    /// The icon is filled and tinted orange when the panel is open, or shows
    /// a badge dot when there are linked reminders but the panel is closed.
    private var remindersPanelToggle: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                showRemindersPanel.toggle()
            }
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: showRemindersPanel ? "bell.fill" : "bell")
                    .font(.title3)
                    .foregroundStyle(showRemindersPanel ? .orange : .secondary)
                    .contentTransition(.symbolEffect(.replace))

                // Badge dot when panel is closed and note has any linked items
                if !showRemindersPanel && (!note.linkedReminders.isEmpty || !note.linkedCalendarEvents.isEmpty) {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 7, height: 7)
                        .offset(x: 2, y: -2)
                }
            }
        }
        .buttonStyle(.plain)
        .help(showRemindersPanel ? "Hide reminders" : "Show reminders")
        .accessibilityLabel(showRemindersPanel ? "Hide reminders panel" : "Show reminders panel")
        .keyboardShortcut("r", modifiers: [.command, .option])
    }

    // MARK: - Done Button

    private var doneButton: some View {
        Button {
            save()
            hasUnsavedChanges = false
            selectedNote = nil
        } label: {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
        }
        .buttonStyle(.borderedProminent)
        .tint(hasUnsavedChanges ? .accentColor : .secondary)
        .help("Mark as done and close editor")
        .accessibilityLabel("Done")
        .accessibilityHint("Saves the note and closes the editor")
        .keyboardShortcut(.return, modifiers: [.command, .shift])
    }

    // MARK: - Tag Bar

    private var tagBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(note.tags) { tag in
                    TagPill(tag: tag)
                        .onTapGesture { removeTag(tag) }
                        .accessibilityHint("Tap to remove tag")
                }

                TextField("Add tag…", text: $newTagName)
                    .textFieldStyle(.plain)
                    .frame(minWidth: 60)
                    .accessibilityLabel("Add tag")
                    .onSubmit { addTag() }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
    }

    // MARK: - Helpers

    /// Persists the current model context state and updates the Spotlight index.
    private func save() {
        try? modelContext.save()
        SpotlightManager.index(note)
    }

    /// Creates a new ``Tag`` and appends it to the note.
    private func addTag() {
        let trimmed = newTagName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let normalized = trimmed.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        guard !note.tags.contains(where: {
            $0.name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current) == normalized
        }) else {
            newTagName = ""
            return
        }

        let tag = existingTags.first(where: {
            $0.name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current) == normalized
        }) ?? {
            let tag = Tag(name: trimmed)
            modelContext.insert(tag)
            return tag
        }()

        note.tags.append(tag)
        save()
        newTagName = ""
    }

    /// Removes `tag` from the note (does not delete the Tag record itself).
    private func removeTag(_ tag: Tag) {
        note.tags.removeAll { $0.id == tag.id }
        save()
    }
}

// MARK: - Preview

#Preview {
    NoteDetailView(note: Note(title: "Sample Note"), selectedNote: .constant(nil))
        .modelContainer(for: [Note.self, Folder.self, Tag.self], inMemory: true)
        .frame(width: 600, height: 500)
}
