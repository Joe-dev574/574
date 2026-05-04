
//  AppTheme.swift
//  574
//
//  Full workspace theme system.
//  Add new themes here — the picker renders them automatically.

import SwiftUI
import Observation

// MARK: - Palette

struct ThemePalette {
    let sidebarBackground: Color
    let listBackground:    Color
    let editorBackground:  Color
    let toolbarBackground: Color
    let cardBackground:    Color
    let primaryText:       Color
    let secondaryText:     Color
    let accent:            Color
    let separator:         Color
    let isDark:            Bool

    /// Derived muted text — 60 % opacity of secondaryText.
    /// Use wherever `.tertiary` would normally appear.
    var tertiaryText: Color { secondaryText.opacity(0.6) }
}

// MARK: - Themes

enum AppTheme: String, CaseIterable, Identifiable {
    case xcodeDefault  = "Xcode"
    case vscodeDark    = "VS Code"
    case atomOneDark   = "Atom"
    case zed           = "Zed"
    case nord          = "Nord"
    case dracula       = "Dracula"
    case solarized     = "Solarized"
    case githubLight   = "GitHub"

    var id: String { rawValue }

    var palette: ThemePalette {
        switch self {
        case .xcodeDefault:
            return ThemePalette(
                sidebarBackground: Color(hex: "1E2228"),
                listBackground:    Color(hex: "242830"),
                editorBackground:  Color(hex: "292D35"),
                toolbarBackground: Color(hex: "191C22"),
                cardBackground:    Color(hex: "2E3340"),
                primaryText:       Color(hex: "D4D4D4"),
                secondaryText:     Color(hex: "8E8E93"),
                accent:            Color(hex: "4C9BE8"),
                separator:         Color(hex: "3A3F4B"),
                isDark: true
            )
        case .vscodeDark:
            return ThemePalette(
                sidebarBackground: Color(hex: "1E1E1E"),
                listBackground:    Color(hex: "252526"),
                editorBackground:  Color(hex: "1E1E1E"),
                toolbarBackground: Color(hex: "333333"),
                cardBackground:    Color(hex: "2D2D2D"),
                primaryText:       Color(hex: "D4D4D4"),
                secondaryText:     Color(hex: "858585"),
                accent:            Color(hex: "0078D4"),
                separator:         Color(hex: "3E3E42"),
                isDark: true
            )
        case .atomOneDark:
            return ThemePalette(
                sidebarBackground: Color(hex: "21252B"),
                listBackground:    Color(hex: "282C34"),
                editorBackground:  Color(hex: "282C34"),
                toolbarBackground: Color(hex: "1D2026"),
                cardBackground:    Color(hex: "2C313A"),
                primaryText:       Color(hex: "ABB2BF"),
                secondaryText:     Color(hex: "636D83"),
                accent:            Color(hex: "61AFEF"),
                separator:         Color(hex: "3A3F4A"),
                isDark: true
            )
        case .zed:
            return ThemePalette(
                sidebarBackground: Color(hex: "1C1C1E"),
                listBackground:    Color(hex: "232326"),
                editorBackground:  Color(hex: "1C1C1E"),
                toolbarBackground: Color(hex: "151517"),
                cardBackground:    Color(hex: "2A2A2D"),
                primaryText:       Color(hex: "CECECE"),
                secondaryText:     Color(hex: "808080"),
                accent:            Color(hex: "1FA8A0"),
                separator:         Color(hex: "323236"),
                isDark: true
            )
        case .nord:
            return ThemePalette(
                sidebarBackground: Color(hex: "2E3440"),
                listBackground:    Color(hex: "3B4252"),
                editorBackground:  Color(hex: "2E3440"),
                toolbarBackground: Color(hex: "252A33"),
                cardBackground:    Color(hex: "434C5E"),
                primaryText:       Color(hex: "ECEFF4"),
                secondaryText:     Color(hex: "9199A6"),
                accent:            Color(hex: "88C0D0"),
                separator:         Color(hex: "434C5E"),
                isDark: true
            )
        case .dracula:
            return ThemePalette(
                sidebarBackground: Color(hex: "1E1F29"),
                listBackground:    Color(hex: "282A36"),
                editorBackground:  Color(hex: "1E1F29"),
                toolbarBackground: Color(hex: "191A23"),
                cardBackground:    Color(hex: "343746"),
                primaryText:       Color(hex: "F8F8F2"),
                secondaryText:     Color(hex: "6272A4"),
                accent:            Color(hex: "BD93F9"),
                separator:         Color(hex: "44475A"),
                isDark: true
            )
        case .solarized:
            return ThemePalette(
                sidebarBackground: Color(hex: "002B36"),
                listBackground:    Color(hex: "073642"),
                editorBackground:  Color(hex: "002B36"),
                toolbarBackground: Color(hex: "001F27"),
                cardBackground:    Color(hex: "0D4455"),
                primaryText:       Color(hex: "93A1A1"),
                secondaryText:     Color(hex: "657B83"),
                accent:            Color(hex: "268BD2"),
                separator:         Color(hex: "0D4455"),
                isDark: true
            )
        case .githubLight:
            return ThemePalette(
                sidebarBackground: Color(hex: "F6F8FA"),
                listBackground:    Color(hex: "FFFFFF"),
                editorBackground:  Color(hex: "FFFFFF"),
                toolbarBackground: Color(hex: "EAEEF2"),
                cardBackground:    Color(hex: "F6F8FA"),
                primaryText:       Color(hex: "1F2328"),
                secondaryText:     Color(hex: "636C76"),
                accent:            Color(hex: "0969DA"),
                separator:         Color(hex: "D0D7DE"),
                isDark: false
            )
        }
    }
}

// MARK: - Color Hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        self.init(
            red:   Double((int >> 16) & 0xFF) / 255,
            green: Double((int >>  8) & 0xFF) / 255,
            blue:  Double( int        & 0xFF) / 255
        )
    }
}

// MARK: - Theme Manager

@Observable
final class ThemeManager {
    var current: AppTheme {
        didSet { UserDefaults.standard.set(current.rawValue, forKey: "com.574.theme") }
    }

    init() {
        let stored = UserDefaults.standard.string(forKey: "com.574.theme") ?? ""
        self.current = AppTheme(rawValue: stored) ?? .xcodeDefault
    }
}
