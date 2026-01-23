//
//  ProgressImageGenerator.swift
//  W8Trackr
//
//  @MainActor wrapper around ImageRenderer for generating shareable images.
//

import SwiftUI
import UIKit

/// Generates shareable progress images using ImageRenderer.
/// Must be called on the main thread - ImageRenderer requires main actor.
@MainActor
enum ProgressImageGenerator {

    /// Standard size for shareable images (1.91:1 ratio for social media)
    static let imageSize = CGSize(width: 600, height: 315)

    /// Generates a progress summary image for sharing.
    /// - Parameters:
    ///   - progressPercentage: Current progress toward goal (0.0 to 1.0+)
    ///   - weightChange: Net weight change in the user's preferred unit
    ///   - duration: Tracking duration description (e.g., "3 months")
    ///   - showWeights: Whether to show exact weight values (false = privacy mode)
    ///   - unit: Weight unit for display
    /// - Returns: UIImage suitable for sharing, or nil if rendering fails
    static func generateProgressImage(
        progressPercentage: Double,
        weightChange: Double,
        duration: String,
        showWeights: Bool,
        unit: WeightUnit
    ) -> UIImage? {
        let view = ShareableProgressView(
            progressPercentage: progressPercentage,
            weightChange: showWeights ? weightChange : nil,
            duration: duration,
            unit: unit
        )

        let renderer = ImageRenderer(content: view)
        renderer.scale = UIScreen.main.scale

        return renderer.uiImage
    }

    /// Generates a milestone celebration image for sharing.
    /// - Parameters:
    ///   - milestoneWeight: The milestone weight that was achieved
    ///   - unit: Weight unit for display
    /// - Returns: UIImage suitable for sharing, or nil if rendering fails
    static func generateMilestoneImage(
        milestoneWeight: Double,
        unit: WeightUnit
    ) -> UIImage? {
        let view = ShareableMilestoneView(
            milestoneWeight: milestoneWeight,
            unit: unit
        )

        let renderer = ImageRenderer(content: view)
        renderer.scale = UIScreen.main.scale

        return renderer.uiImage
    }
}
