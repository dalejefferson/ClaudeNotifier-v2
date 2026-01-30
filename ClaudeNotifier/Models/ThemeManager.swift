//
//  ThemeManager.swift
//  ClaudeNotifier
//

import SwiftUI
import Combine

@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @AppStorage("selectedPaletteId") private var storedPaletteId: String = "warm-professional"
    @AppStorage("isDarkMode") private var storedIsDarkMode: Bool = false

    @Published private(set) var palette: ColorPalette
    @Published private(set) var isDarkMode: Bool = false

    /// Returns the effective palette (dark variant if dark mode is enabled)
    var effectivePalette: ColorPalette {
        isDarkMode ? ColorPalette.darkVariant(of: palette) : palette
    }

    var currentPaletteId: String {
        get { storedPaletteId }
        set {
            storedPaletteId = newValue
            palette = ColorPalette.allPalettes.first { $0.id == newValue } ?? .warmProfessional
        }
    }

    private init() {
        let savedId = UserDefaults.standard.string(forKey: "selectedPaletteId") ?? "warm-professional"
        self.palette = ColorPalette.allPalettes.first { $0.id == savedId } ?? .warmProfessional
        self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
    }

    func setPalette(_ newPalette: ColorPalette) {
        storedPaletteId = newPalette.id
        palette = newPalette
    }

    func toggleDarkMode() {
        storedIsDarkMode.toggle()
        isDarkMode = storedIsDarkMode
    }

    func setDarkMode(_ enabled: Bool) {
        storedIsDarkMode = enabled
        isDarkMode = enabled
    }
}
