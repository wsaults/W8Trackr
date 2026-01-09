//
//  Gradients.swift
//  W8Trackr
//
//  Defines gradient styles for cards, backgrounds, and visual elements.
//

import SwiftUI

/// Pre-defined gradients for W8Trackr's playful visual style
enum AppGradients {

    // MARK: - Primary Gradients

    /// Warm coral gradient - FAB buttons, primary CTAs
    /// Direction: Top-left to bottom-right
    static let primary = LinearGradient(
        colors: [Color(hex: "#FF6B6B"), Color(hex: "#FFA07A")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Vertical variant of primary gradient
    static let primaryVertical = LinearGradient(
        colors: [Color(hex: "#FF6B6B"), Color(hex: "#FFA07A")],
        startPoint: .top,
        endPoint: .bottom
    )

    // MARK: - Secondary Gradients

    /// Teal gradient - secondary elements, chart backgrounds
    static let secondary = LinearGradient(
        colors: [Color(hex: "#4ECDC4"), Color(hex: "#44B3AA")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Accent Gradients

    /// Purple celebration gradient - achievements, milestones
    static let celebration = LinearGradient(
        colors: [Color(hex: "#9B59B6"), Color(hex: "#8E44AD")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Success gradient - goal achieved states
    static let success = LinearGradient(
        colors: [Color(hex: "#2ECC71"), Color(hex: "#27AE60")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Background Gradients

    /// Subtle warm background gradient (light mode)
    static let backgroundWarm = LinearGradient(
        colors: [Color(hex: "#FFF9F5"), Color(hex: "#FFF5EE")],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Deep navy background gradient (dark mode)
    static let backgroundDeep = LinearGradient(
        colors: [Color(hex: "#1A1A2E"), Color(hex: "#16213E")],
        startPoint: .top,
        endPoint: .bottom
    )

    // MARK: - Card Gradients

    /// Subtle shimmer for card highlights
    static let cardShimmer = LinearGradient(
        colors: [
            Color.white.opacity(0.0),
            Color.white.opacity(0.1),
            Color.white.opacity(0.0)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Frosted glass effect overlay
    static let frostedOverlay = LinearGradient(
        colors: [
            Color.white.opacity(0.2),
            Color.white.opacity(0.1)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Progress Gradients

    /// Weight loss progress (coral to green)
    static let progressPositive = LinearGradient(
        colors: [Color(hex: "#FF6B6B"), Color(hex: "#2ECC71")],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Neutral progress indicator
    static let progressNeutral = LinearGradient(
        colors: [Color(hex: "#4ECDC4"), Color(hex: "#4ECDC4").opacity(0.6)],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// MARK: - Gradient Helpers

extension AppGradients {
    /// Create a radial gradient from primary colors for spotlight effects
    static func primaryRadial(center: UnitPoint = .center) -> RadialGradient {
        RadialGradient(
            colors: [Color(hex: "#FF6B6B"), Color(hex: "#FFA07A").opacity(0.3)],
            center: center,
            startRadius: 0,
            endRadius: 200
        )
    }

    /// Angular gradient for circular progress indicators
    static var angularProgress: AngularGradient {
        AngularGradient(
            colors: [Color(hex: "#FF6B6B"), Color(hex: "#FFA07A"), Color(hex: "#FF6B6B")],
            center: .center
        )
    }
}
