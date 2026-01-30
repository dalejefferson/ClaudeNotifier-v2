//
//  ColorPalette.swift
//  ClaudeNotifier
//

import SwiftUI

struct ColorPalette: Identifiable, Equatable {
    let id: String
    let name: String

    // Core colors
    let background: Color
    let surface: Color
    let primary: Color
    let secondary: Color

    // Text colors
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color

    // Status colors (semantic - same across themes for consistency)
    let success: Color
    let warning: Color
    let critical: Color
    let info: Color
    let active: Color

    // Border/divider
    let border: Color

    static let warmProfessional = ColorPalette(
        id: "warm-professional",
        name: "Warm Professional",
        background: Color(hex: "#F5F2F2"),
        surface: Color(hex: "#FFFFFF"),
        primary: Color(hex: "#FEB05D"),
        secondary: Color(hex: "#5A7ACD"),
        textPrimary: Color(hex: "#2B2A2A"),
        textSecondary: Color(hex: "#6B6868"),
        textTertiary: Color(hex: "#9E9A9A"),
        success: Color(hex: "#34C759"),
        warning: Color(hex: "#FFB84D"),
        critical: Color(hex: "#E85454"),
        info: Color(hex: "#5A7ACD"),
        active: Color(hex: "#FEB05D"),
        border: Color(hex: "#E8E4E4")
    )

    static let coolElegance = ColorPalette(
        id: "cool-elegance",
        name: "Cool Elegance",
        background: Color(hex: "#EEEEEE"),
        surface: Color(hex: "#FFFFFF"),
        primary: Color(hex: "#6594B1"),
        secondary: Color(hex: "#DDAED3"),
        textPrimary: Color(hex: "#213C51"),
        textSecondary: Color(hex: "#4A6A80"),
        textTertiary: Color(hex: "#7A9AAE"),
        success: Color(hex: "#5EC985"),
        warning: Color(hex: "#F5C86B"),
        critical: Color(hex: "#E87878"),
        info: Color(hex: "#6594B1"),
        active: Color(hex: "#DDAED3"),
        border: Color(hex: "#D4D4D4")
    )

    static let natureInspired = ColorPalette(
        id: "nature-inspired",
        name: "Nature Inspired",
        background: Color(hex: "#F6F3C2"),
        surface: Color(hex: "#FFFFFF"),
        primary: Color(hex: "#4B9DA9"),
        secondary: Color(hex: "#91C6BC"),
        textPrimary: Color(hex: "#2D4A4D"),
        textSecondary: Color(hex: "#5A7A7D"),
        textTertiary: Color(hex: "#8AA8AB"),
        success: Color(hex: "#91C6BC"),
        warning: Color(hex: "#E8B84D"),
        critical: Color(hex: "#E37434"),
        info: Color(hex: "#4B9DA9"),
        active: Color(hex: "#E37434"),
        border: Color(hex: "#D4E8E0")
    )

    static let warmCoral = ColorPalette(
        id: "warm-coral",
        name: "Warm Coral",
        background: Color(hex: "#FFEAD3"),
        surface: Color(hex: "#FFFFFF"),
        primary: Color(hex: "#D25353"),
        secondary: Color(hex: "#EA7B7B"),
        textPrimary: Color(hex: "#4A2828"),
        textSecondary: Color(hex: "#7A5050"),
        textTertiary: Color(hex: "#A88080"),
        success: Color(hex: "#5EC985"),
        warning: Color(hex: "#F5B84D"),
        critical: Color(hex: "#9E3B3B"),
        info: Color(hex: "#6B9ED4"),
        active: Color(hex: "#EA7B7B"),
        border: Color(hex: "#F0D8C8")
    )

    static let vintageMauve = ColorPalette(
        id: "vintage-mauve",
        name: "Vintage Mauve",
        background: Color(hex: "#FFDAB3"),
        surface: Color(hex: "#FFFFFF"),
        primary: Color(hex: "#574964"),
        secondary: Color(hex: "#C8AAAA"),
        textPrimary: Color(hex: "#3A3040"),
        textSecondary: Color(hex: "#6A5A68"),
        textTertiary: Color(hex: "#9A8A98"),
        success: Color(hex: "#7DB88F"),
        warning: Color(hex: "#FFDAB3"),
        critical: Color(hex: "#C86B6B"),
        info: Color(hex: "#7A8AC8"),
        active: Color(hex: "#9F8383"),
        border: Color(hex: "#E0D4D4")
    )

    static let allPalettes: [ColorPalette] = [
        .warmProfessional,
        .coolElegance,
        .natureInspired,
        .warmCoral,
        .vintageMauve
    ]

    // MARK: - Dark Mode Variants

    static let warmProfessionalDark = ColorPalette(
        id: "warm-professional-dark",
        name: "Warm Professional",
        background: Color(hex: "#1C1B1B"),
        surface: Color(hex: "#2B2A2A"),
        primary: Color(hex: "#FEB05D"),
        secondary: Color(hex: "#7A9AED"),
        textPrimary: Color(hex: "#F5F2F2"),
        textSecondary: Color(hex: "#D0CDCD"),
        textTertiary: Color(hex: "#B8B5B5"),
        success: Color(hex: "#4AD97A"),
        warning: Color(hex: "#FFD080"),
        critical: Color(hex: "#FF6B6B"),
        info: Color(hex: "#7A9AED"),
        active: Color(hex: "#FEB05D"),
        border: Color(hex: "#4D4A4A")
    )

    static let coolEleganceDark = ColorPalette(
        id: "cool-elegance-dark",
        name: "Cool Elegance",
        background: Color(hex: "#1A2530"),
        surface: Color(hex: "#243A4D"),
        primary: Color(hex: "#7AA8C8"),
        secondary: Color(hex: "#E8C0E0"),
        textPrimary: Color(hex: "#F0F0F0"),
        textSecondary: Color(hex: "#C8E0F0"),
        textTertiary: Color(hex: "#A8C8D8"),
        success: Color(hex: "#6ED995"),
        warning: Color(hex: "#FFD88B"),
        critical: Color(hex: "#F08888"),
        info: Color(hex: "#7AA8C8"),
        active: Color(hex: "#E8C0E0"),
        border: Color(hex: "#3A5A70")
    )

    static let natureInspiredDark = ColorPalette(
        id: "nature-inspired-dark",
        name: "Nature Inspired",
        background: Color(hex: "#1A2424"),
        surface: Color(hex: "#2A4245"),
        primary: Color(hex: "#5DB8C5"),
        secondary: Color(hex: "#A8D8D0"),
        textPrimary: Color(hex: "#F8F5D0"),
        textSecondary: Color(hex: "#D0E8E0"),
        textTertiary: Color(hex: "#B0D0D0"),
        success: Color(hex: "#A8D8D0"),
        warning: Color(hex: "#F0C860"),
        critical: Color(hex: "#F08848"),
        info: Color(hex: "#5DB8C5"),
        active: Color(hex: "#F08848"),
        border: Color(hex: "#3D5A5D")
    )

    static let warmCoralDark = ColorPalette(
        id: "warm-coral-dark",
        name: "Warm Coral",
        background: Color(hex: "#2A1818"),
        surface: Color(hex: "#3D2525"),
        primary: Color(hex: "#E86868"),
        secondary: Color(hex: "#F09090"),
        textPrimary: Color(hex: "#FFF0E0"),
        textSecondary: Color(hex: "#E8D0C0"),
        textTertiary: Color(hex: "#D0B8A8"),
        success: Color(hex: "#6ED995"),
        warning: Color(hex: "#FFD080"),
        critical: Color(hex: "#C85050"),
        info: Color(hex: "#80B0E0"),
        active: Color(hex: "#F09090"),
        border: Color(hex: "#5A3838")
    )

    static let vintageMauveDark = ColorPalette(
        id: "vintage-mauve-dark",
        name: "Vintage Mauve",
        background: Color(hex: "#1E1820"),
        surface: Color(hex: "#302838"),
        primary: Color(hex: "#A090B0"),
        secondary: Color(hex: "#D8C0C0"),
        textPrimary: Color(hex: "#FFE8C8"),
        textSecondary: Color(hex: "#D8D0D8"),
        textTertiary: Color(hex: "#C0B0B8"),
        success: Color(hex: "#90D0A0"),
        warning: Color(hex: "#FFE0B0"),
        critical: Color(hex: "#D88080"),
        info: Color(hex: "#90A0D8"),
        active: Color(hex: "#B8A0A0"),
        border: Color(hex: "#4A3A48")
    )

    /// Returns the dark variant of a given palette
    static func darkVariant(of palette: ColorPalette) -> ColorPalette {
        switch palette.id {
        case "warm-professional":
            return .warmProfessionalDark
        case "cool-elegance":
            return .coolEleganceDark
        case "nature-inspired":
            return .natureInspiredDark
        case "warm-coral":
            return .warmCoralDark
        case "vintage-mauve":
            return .vintageMauveDark
        default:
            return .warmProfessionalDark
        }
    }
}
