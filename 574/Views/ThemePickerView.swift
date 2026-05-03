
//  ThemePickerView.swift
//  574
//
//  Workspace theme picker — shown from the gear button in the sidebar toolbar.

import SwiftUI

struct ThemePickerView: View {

    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.dismiss)         private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 140, maximum: 180), spacing: 14)]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(AppTheme.allCases) { theme in
                        ThemeCard(
                            theme: theme,
                            isSelected: themeManager.current == theme
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                themeManager.current = theme
                            }
                        }
                    }
                }
                .padding(18)
            }
        }
        .frame(minWidth: 340, idealWidth: 380)
        .presentationDetents([.medium, .large])
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "paintpalette.fill")
                .foregroundStyle(themeManager.current.palette.accent)
                .font(.title3)
            VStack(alignment: .leading, spacing: 1) {
                Text("Workspace Theme")
                    .font(.headline)
                Text("Active: \(themeManager.current.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }
}

// MARK: - Theme Card

private struct ThemeCard: View {

    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                miniPreview
                footer
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.primary.opacity(isSelected ? 0.08 : (isHovered ? 0.05 : 0.03)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        isSelected ? theme.palette.accent : Color.primary.opacity(0.08),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        .animation(.easeInOut(duration: 0.1), value: isHovered)
    }

    // Three-column miniature layout
    private var miniPreview: some View {
        let p = theme.palette
        return HStack(spacing: 2) {
            // Sidebar
            ZStack(alignment: .topLeading) {
                p.sidebarBackground
                VStack(alignment: .leading, spacing: 4) {
                    Capsule()
                        .fill(p.accent.opacity(0.9))
                        .frame(height: 3)
                        .padding(.leading, 4)
                        .padding(.top, 6)
                    ForEach(0..<3, id: \.self) { _ in
                        Capsule()
                            .fill(p.secondaryText.opacity(0.4))
                            .frame(height: 3)
                            .padding(.leading, 4)
                    }
                }
            }
            .frame(width: 24)

            // Note list
            ZStack(alignment: .top) {
                p.listBackground
                VStack(spacing: 3) {
                    ForEach(0..<2, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(p.cardBackground)
                            .frame(height: 15)
                            .padding(.horizontal, 3)
                    }
                }
                .padding(.top, 4)
            }
            .frame(width: 38)

            // Editor
            ZStack(alignment: .topLeading) {
                p.editorBackground
                VStack(alignment: .leading, spacing: 4) {
                    ForEach([0.9, 0.5, 0.35, 0.5], id: \.self) { opacity in
                        Capsule()
                            .fill(p.primaryText.opacity(opacity))
                            .frame(height: 3)
                            .padding(.horizontal, 5)
                            .padding(.top, opacity == 0.9 ? 6 : 0)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: 64)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
    }

    private var footer: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(theme.palette.accent)
                .frame(width: 7, height: 7)
            Text(theme.rawValue)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? .primary : .secondary)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(theme.palette.accent)
            }
        }
    }
}

#Preview {
    ThemePickerView()
        .environment(ThemeManager())
        .frame(width: 380, height: 400)
}
