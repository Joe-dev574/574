//
//  NewProjectView.swift
//  574
//
//  Created by Joseph DeWeese on 5/3/26.
//

import SwiftUI
import SwiftData
#if os(iOS)
import PhotosUI
#endif

// MARK: - ProjectIconView

/// App-icon-style rounded-square icon for a ``Project``.
/// Shows the user's chosen photo scaled to fill; falls back to a
/// coloured rounded square with the project's initial letter.
struct ProjectIconView: View {
    let project: Project
    let size: CGFloat

    private var cornerRadius: CGFloat { size * 0.225 }

    var body: some View {
        Group {
            if let data = project.iconData, let img = loadImage(data) {
                img
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    project.accentColor
                    Text(project.name.first.map(String.init) ?? "P")
                        .font(.system(size: size * 0.42, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    private func loadImage(_ data: Data) -> Image? {
#if os(macOS)
        guard let ns = NSImage(data: data) else { return nil }
        return Image(nsImage: ns)
#else
        guard let ui = UIImage(data: data) else { return nil }
        return Image(uiImage: ui)
#endif
    }
}

// MARK: - NewProjectView

struct NewProjectView: View {

    // MARK: - Environment

    @Environment(\.dismiss)         private var dismiss
    @Environment(\.modelContext)    private var modelContext
    @Environment(ThemeManager.self) private var themeManager

    // MARK: - State

    @State private var name: String = ""
    @State private var colorName: String? = "blue"
    @State private var iconData: Data? = nil
    @State private var showingImagePicker = false
    @FocusState private var nameFocused: Bool

#if os(iOS)
    @State private var photosItem: PhotosPickerItem? = nil
#endif

    // MARK: - Computed

    private var previewColor: Color {
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

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {

            // Header bar
            HStack {
                Button("Cancel") { dismiss() }
                    .foregroundStyle(.secondary)
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Text("New Project")
                    .font(.headline)
                Spacer()
                Button("Create") { createProject() }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                    .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider().opacity(0.5)

            // Hero icon picker
            Button { showingImagePicker = true } label: {
                heroIconPreview
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(6)
                            .background(Circle().fill(Color.secondary))
                            .offset(x: 4, y: 4)
                    }
            }
            .buttonStyle(.plain)
            .padding(.top, 28)
            .padding(.bottom, 28)

            // Name field
            VStack(alignment: .leading, spacing: 8) {
                Text("NAME")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 20)

                TextField("Project name…", text: $name)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .focused($nameFocused)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.primary.opacity(0.07))
                    )
                    .padding(.horizontal, 20)
                    .onSubmit { if isValid { createProject() } }
            }

            // Accent colour (used as icon background when no image is chosen)
            VStack(alignment: .leading, spacing: 10) {
                Text("ACCENT COLOUR")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 20)

                FolderColorPicker(colorName: $colorName)
                    .padding(.horizontal, 8)
            }
            .padding(.top, 22)

            Spacer(minLength: 20)
        }
        .background(themeManager.current.palette.listBackground.ignoresSafeArea())
        .onAppear { nameFocused = true }
        .frame(minWidth: 340, minHeight: 380)
#if os(macOS)
        .onChange(of: showingImagePicker) { _, show in
            guard show else { return }
            showingImagePicker = false
            pickImageMacOS()
        }
#else
        .photosPicker(isPresented: $showingImagePicker, selection: $photosItem, matching: .images)
        .onChange(of: photosItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self) {
                    iconData = data
                }
            }
        }
#endif
    }

    // MARK: - Hero Icon Preview

    @ViewBuilder
    private var heroIconPreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(iconData == nil ? previewColor : Color.clear)
                .frame(width: 96, height: 96)

            if let data = iconData {
#if os(macOS)
                if let ns = NSImage(data: data) {
                    Image(nsImage: ns)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 96, height: 96)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                }
#else
                if let ui = UIImage(data: data) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 96, height: 96)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                }
#endif
            } else {
                Text(name.first.map(String.init) ?? "")
                    .font(.system(size: 42, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .animation(.easeInOut(duration: 0.15), value: name)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: colorName)
        .animation(.easeInOut(duration: 0.2), value: iconData != nil)
    }

    // MARK: - Actions

#if os(macOS)
    private func pickImageMacOS() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url,
           let data = try? Data(contentsOf: url) {
            iconData = data
        }
    }
#endif

    private func createProject() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let project = Project(name: trimmed, colorName: colorName, iconData: iconData)
        modelContext.insert(project)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    NewProjectView()
        .modelContainer(for: [Project.self, Note.self, Folder.self], inMemory: true)
}
