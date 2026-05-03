//
//  EditFolderView.swift
//  574
//
//  Created by Joseph DeWeese on 5/3/26.
//
import SwiftUI
import SwiftData

/// A modal sheet for editing the name and accent colour of an existing ``Folder``.
///
/// Presented from ``FolderView`` via a context-menu "Rename…" or "Change Color…" action.
/// Changes are committed to the model context on Save and discarded on Cancel.
struct EditFolderView: View {

    // MARK: - Properties

    /// The folder being edited.  Uses `@Bindable` so the text field binds directly
    /// to the `name` property and the colour picker binds to `colorName`.
    @Bindable var folder: Folder

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Folder name", text: $folder.name)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityLabel("Folder name")
                }

                Section("Accent Colour") {
                    FolderColorPicker(colorName: $folder.colorName)
                        .accessibilityLabel("Choose folder colour")
                }
            }
            .navigationTitle("Edit Folder")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .keyboardShortcut(.cancelAction)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        try? modelContext.save()
                        dismiss()
                    }
                    .disabled(folder.name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
        .frame(minWidth: 340, minHeight: 260)
    }
}

// MARK: - Preview

#Preview {
    EditFolderView(folder: Folder(name: "Work", colorName: "blue"))
        .modelContainer(for: [Folder.self], inMemory: true)
}
