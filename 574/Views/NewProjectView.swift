//
//  NewProjectView.swift
//  574
//
//  Created by Joseph DeWeese on 5/3/26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
#if os(iOS)
import PhotosUI
#endif

// MARK: - ProjectIconView (unchanged — good as-is)
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

// MARK: - NewProjectView (Improved)

struct NewProjectView: View {

    @Environment(\.dismiss)         private var dismiss
    @Environment(\.modelContext)    private var modelContext
    @Environment(ThemeManager.self) private var themeManager

    @State private var name: String = ""
    @State private var colorName: String? = "blue"
    @State private var iconData: Data? = nil

    @FocusState private var nameFocused: Bool

#if os(iOS)
    @State private var photosItem: PhotosPickerItem? = nil
#else
    @State private var isImportingImage = false   // for .fileImporter
#endif

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

    var body: some View {
        VStack(spacing: 0) {
            // Header
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
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 12)

            Divider()

            // Hero Icon + Picker
            Button {
#if os(macOS)
                isImportingImage = true
#else
                // iOS PhotosPicker is triggered via the modifier below
#endif
            } label: {
                heroIconPreview
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(Circle().fill(Color.secondary))
                            .offset(x: 6, y: 6)
                    }
            }
            .buttonStyle(.plain)
            .padding(.top, 32)
            .padding(.bottom, 24)

            // Name
            VStack(alignment: .leading, spacing: 8) {
                Text("PROJECT NAME")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 24)

                TextField("Project name…", text: $name)
                    .textFieldStyle(.plain)
                    .font(.title2)
                    .focused($nameFocused)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.primary.opacity(0.08))
                    )
                    .padding(.horizontal, 24)
            }

            // Accent Color
            VStack(alignment: .leading, spacing: 12) {
                Text("ACCENT COLOR")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 24)

                FolderColorPicker(colorName: $colorName)
                    .padding(.horizontal, 12)
            }
            .padding(.top, 28)

            Spacer(minLength: 40)
        }
        .background(themeManager.current.palette.listBackground.ignoresSafeArea())
        .onAppear { nameFocused = true }
        .frame(minWidth: 380, minHeight: 460)   // nicer size
#if os(macOS)
        .fileImporter(
            isPresented: $isImportingImage,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                do {
                    if url.startAccessingSecurityScopedResource() {
                        iconData = try Data(contentsOf: url)
                        url.stopAccessingSecurityScopedResource()
                    }
                } catch {
                    print("Failed to load image: \(error)")
                }
            }
        }
#else
        .photosPicker(isPresented: $showingImagePicker, selection: $photosItem, matching: .images)  // you still need to declare @State private var showingImagePicker = false for iOS if not already
        .onChange(of: photosItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self) {
                    iconData = data
                }
            }
        }
#endif
    }

    // MARK: - Hero Preview
    @ViewBuilder
    private var heroIconPreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(iconData == nil ? previewColor : Color.clear)
                .frame(width: 120, height: 120)

            if let data = iconData {
#if os(macOS)
                if let ns = NSImage(data: data) {
                    Image(nsImage: ns)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                }
#else
                if let ui = UIImage(data: data) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                }
#endif
            } else {
                Text(name.prefix(1).uppercased())
                    .font(.system(size: 52, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: iconData != nil)
        .animation(.easeInOut, value: colorName)
    }

    private func createProject() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let project = Project(name: trimmed, colorName: colorName, iconData: iconData)
        modelContext.insert(project)
        try? modelContext.save()
        dismiss()
    }
}
