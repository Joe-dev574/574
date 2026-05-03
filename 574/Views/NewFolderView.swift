//
//  NewFolderView.swift
//  574
//
//  Created by Joseph DeWeese on 5/3/26.
//

import SwiftUI
import SwiftData

/// A modal sheet for creating a new ``Folder`` with a name and optional accent colour.
///
/// Presented from ``FolderView`` via the toolbar `+` button.
/// Mirrors the layout of ``EditFolderView`` for visual consistency.
struct NewFolderView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // MARK: - State

    @State private var name: String = ""
    @State private var colorName: String? = nil

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Folder name", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityLabel("Folder name")
                }

                Section("Accent Colour") {
                    FolderColorPicker(colorName: $colorName)
                        .accessibilityLabel("Choose folder colour")
                }
            }
            .navigationTitle("New Folder")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .keyboardShortcut(.cancelAction)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let trimmed = name.trimmingCharacters(in: .whitespaces)
                        let folder = Folder(name: trimmed, colorName: colorName)
                        modelContext.insert(folder)
                        try? modelContext.save()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
        .frame(minWidth: 340, minHeight: 260)
    }
}

// MARK: - Preview

#Preview {
    NewFolderView()
        .modelContainer(for: [Folder.self, Note.self], inMemory: true)
}
