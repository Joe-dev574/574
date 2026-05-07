//
//  NewFolderView.swift
//  574
//
//  Created by Joseph DeWeese on 5/3/26.
//

import SwiftUI
import SwiftData

struct NewFolderView: View {

    @Environment(\.dismiss)         private var dismiss
    @Environment(\.modelContext)    private var modelContext
    @Environment(ThemeManager.self) private var themeManager

    @State private var name: String = ""
    @State private var colorName: String? = nil
    @FocusState private var nameFocused: Bool

    private var palette: ThemePalette { themeManager.current.palette }

    private var resolvedColor: Color {
        switch colorName {
        case "blue":   return .blue
        case "red":    return .red
        case "green":  return .green
        case "orange": return .orange
        case "purple": return .purple
        case "yellow": return .yellow
        default:       return .accentColor
        }
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {

            // Header
            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                    .foregroundStyle(palette.secondaryText)
                Spacer()
                Text("New Folder")
                    .font(.headline)
                    .foregroundStyle(palette.primaryText)
                Spacer()
                Button("Create") { createFolder() }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                    .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider().opacity(0.5)

            // Live folder icon preview
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(resolvedColor.opacity(0.15))
                    .frame(width: 84, height: 84)
                Image(systemName: "folder.fill")
                    .font(.system(size: 42, weight: .medium))
                    .foregroundStyle(resolvedColor)
            }
            .padding(.top, 28)
            .padding(.bottom, 28)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: colorName)

            // Name field
            VStack(alignment: .leading, spacing: 8) {
                Text("NAME")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.secondaryText)
                    .padding(.horizontal, 20)

                TextField("Folder name…", text: $name)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .focused($nameFocused)
                    .foregroundStyle(palette.primaryText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(palette.primaryText.opacity(0.07))
                    )
                    .padding(.horizontal, 20)
                    .onSubmit { if isValid { createFolder() } }
            }

            // Colour picker
            VStack(alignment: .leading, spacing: 10) {
                Text("COLOR")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.secondaryText)
                    .padding(.horizontal, 20)

                FolderColorPicker(colorName: $colorName)
                    .padding(.horizontal, 8)
            }
            .padding(.top, 22)

            Spacer(minLength: 20)
        }
        .background(palette.listBackground.ignoresSafeArea())
        .onAppear { nameFocused = true }
        .frame(minWidth: 340, minHeight: 340)
    }

    private func createFolder() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let folder = Folder(name: trimmed, colorName: colorName)
        modelContext.insert(folder)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    NewFolderView()
        .modelContainer(for: [Folder.self, Note.self], inMemory: true)
}
