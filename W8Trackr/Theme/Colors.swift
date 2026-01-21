//
//  Colors.swift
//  W8Trackr
//
//  Defines the app's color palette with support for light and dark modes.
//

import SwiftUI

/// Semantic color definitions for W8Trackr's playful theme
enum AppColors {

    // MARK: - Primary Colors

    /// Warm coral - main interactive elements, FAB buttons
    static let primary = Color("AppPrimary")

    /// Darker coral for pressed/focused states
    static let primaryDark = Color("PrimaryDark")

    // MARK: - Secondary Colors

    /// Soft teal - secondary actions, chart averages
    static let secondary = Color("AppSecondary")

    /// Darker teal for pressed states
    static let secondaryDark = Color("SecondaryDark")

    // MARK: - Accent Colors

    /// Vibrant purple - celebrations, achievements, milestones
    static let accent = Color("Accent")

    // MARK: - Semantic Colors

    /// Fresh green - success states, goal achieved, positive trends
    static let success = Color("Success")

    /// Amber - warnings, attention needed
    static let warning = Color("Warning")

    /// Soft red - errors, negative trends (gentler than pure red)
    static let error = Color("Error")

    // MARK: - Background Colors

    /// Warm off-white (light) / deep navy (dark) - main background
    static let background = Color("Background")

    /// Card/surface background - slightly elevated from background
    static let surface = Color("Surface")

    /// Subtle background for sections, groupings
    static let surfaceSecondary = Color("SurfaceSecondary")

    // MARK: - Text Colors

    /// Primary text - high contrast
    static let textPrimary = Color("TextPrimary")

    /// Secondary text - labels, captions
    static let textSecondary = Color("TextSecondary")

    /// Tertiary text - hints, placeholders
    static let textTertiary = Color("TextTertiary")

    // MARK: - Chart Colors

    /// Chart line for actual weight data points
    static let chartEntry = Color("ChartEntry")

    /// Chart line for averaged/trend data
    static let chartAverage = Color("ChartAverage")

    /// Chart line for smoothed trendline (blue)
    static let chartTrend = Color("ChartTrend")

    /// Chart line for predicted values
    static let chartPredicted = Color("ChartPredicted")

    /// Goal line on charts
    static let chartGoal = Color("ChartGoal")
}

// MARK: - Color Hex Extension

extension Color {
    /// Initialize a Color from a hex string (e.g., "#FF6B6B" or "FF6B6B")
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Fallback Colors (Used when assets not loaded)

extension AppColors {
    /// Fallback colors using hex values directly - use when color assets aren't available
    enum Fallback {
        // Primary: Warm coral/orange
        static let primary = Color(hex: "#FF6B6B")
        static let primaryDark = Color(hex: "#E85555")

        // Secondary: Soft teal
        static let secondary = Color(hex: "#4ECDC4")
        static let secondaryDark = Color(hex: "#3DBDB5")

        // Accent: Vibrant purple
        static let accent = Color(hex: "#9B59B6")

        // Semantic
        static let success = Color(hex: "#2ECC71")
        static let warning = Color(hex: "#F39C12")
        static let error = Color(hex: "#E74C3C")

        // Background (Light mode)
        static let backgroundLight = Color(hex: "#FFF9F5")
        static let backgroundDark = Color(hex: "#1A1A2E")

        // Surface
        static let surfaceLight = Color(hex: "#FFFFFF")
        static let surfaceDark = Color(hex: "#252540")

        // Text (Light mode)
        static let textPrimaryLight = Color(hex: "#2C3E50")
        static let textPrimaryDark = Color(hex: "#F5F5F5")

        // Chart colors
        static let chartEntry = Color(hex: "#FF6B6B")
        static let chartAverage = Color(hex: "#FF6B6B").opacity(0.5)
        static let chartTrend = Color(hex: "#4A90D9")
        static let chartPredicted = Color(hex: "#FFA07A")
        static let chartGoal = Color(hex: "#2ECC71")
    }
}
