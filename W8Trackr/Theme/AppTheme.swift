//
//  AppTheme.swift
//  W8Trackr
//
//  Central theme definition providing spacing, typography, and corner radii.
//

import SwiftUI

/// Central theme namespace for W8Trackr's design system
enum AppTheme {

    // MARK: - Spacing Scale

    /// Consistent spacing values based on 4pt grid
    enum Spacing {
        /// 4pt - Tight spacing for inline elements
        static let xxs: CGFloat = 4

        /// 8pt - Small spacing for related elements
        static let xs: CGFloat = 8

        /// 12pt - Default spacing between elements
        static let sm: CGFloat = 12

        /// 16pt - Standard padding, section spacing
        static let md: CGFloat = 16

        /// 24pt - Larger gaps between sections
        static let lg: CGFloat = 24

        /// 32pt - Major section separation
        static let xl: CGFloat = 32

        /// 48pt - Screen-level padding, hero spacing
        static let xxl: CGFloat = 48
    }

    // MARK: - Typography Scale

    /// Font styles following iOS guidelines with custom weights
    enum Typography {
        /// Hero numbers (current weight display)
        static let heroNumber = Font.system(size: 48, weight: .bold, design: .rounded)

        /// Large titles
        static let largeTitle = Font.largeTitle.weight(.bold)

        /// Section titles
        static let title = Font.title2.weight(.semibold)

        /// Card titles, list headers
        static let headline = Font.headline.weight(.semibold)

        /// Primary body text
        static let body = Font.body

        /// Secondary body text
        static let bodySecondary = Font.body.weight(.regular)

        /// Labels, small titles
        static let subheadline = Font.subheadline.weight(.medium)

        /// Captions, timestamps
        static let caption = Font.caption

        /// Smallest text, footnotes
        static let footnote = Font.footnote
    }

    // MARK: - Corner Radii

    /// Consistent corner radius values
    enum CornerRadius {
        /// 4pt - Subtle rounding for inline elements
        static let xs: CGFloat = 4

        /// 8pt - Small cards, chips
        static let sm: CGFloat = 8

        /// 12pt - Standard cards, buttons
        static let md: CGFloat = 12

        /// 16pt - Large cards, modals
        static let lg: CGFloat = 16

        /// 24pt - Hero cards, bottom sheets
        static let xl: CGFloat = 24

        /// Full circle (for circular elements, set to half of width/height)
        static let full: CGFloat = 9999
    }

    // MARK: - Shadows

    /// Shadow definitions for elevation
    enum Shadow {
        /// Subtle shadow for cards
        static let card = ShadowStyle(
            color: Color.black.opacity(0.08),
            radius: 8,
            x: 0,
            y: 4
        )

        /// Elevated shadow for floating elements
        static let elevated = ShadowStyle(
            color: Color.black.opacity(0.12),
            radius: 16,
            x: 0,
            y: 8
        )

        /// Prominent shadow for FABs, modals
        static let prominent = ShadowStyle(
            color: Color.black.opacity(0.16),
            radius: 24,
            x: 0,
            y: 12
        )
    }

    // MARK: - Animation

    /// Standard animation durations
    enum Animation {
        /// Quick micro-interactions
        static let fast: Double = 0.15

        /// Standard transitions
        static let normal: Double = 0.25

        /// Slower, more dramatic transitions
        static let slow: Double = 0.4

        /// Standard spring animation
        static var spring: SwiftUI.Animation {
            .spring(response: 0.4, dampingFraction: 0.75)
        }

        /// Bouncy spring for celebrations
        static var bouncy: SwiftUI.Animation {
            .spring(response: 0.5, dampingFraction: 0.6)
        }
    }
}

// MARK: - Shadow Style Helper

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - View Extensions

extension View {
    /// Apply a card shadow from the theme
    func cardShadow() -> some View {
        let shadow = AppTheme.Shadow.card
        return self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }

    /// Apply an elevated shadow from the theme
    func elevatedShadow() -> some View {
        let shadow = AppTheme.Shadow.elevated
        return self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }

    /// Apply the prominent shadow for FABs
    func prominentShadow() -> some View {
        let shadow = AppTheme.Shadow.prominent
        return self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }

    /// Apply standard card styling (background, corner radius, shadow)
    func cardStyle() -> some View {
        self
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md))
            .cardShadow()
    }
}
