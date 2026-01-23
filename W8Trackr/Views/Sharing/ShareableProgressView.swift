//
//  ShareableProgressView.swift
//  W8Trackr
//
//  Fixed-size SwiftUI view designed for rendering to a shareable image.
//  Uses fixed font sizes (not Dynamic Type) since this is for image generation.
//

import SwiftUI

/// A view designed to be rendered to a shareable progress image.
/// Fixed size of 600x315 (1.91:1 ratio optimal for social media).
struct ShareableProgressView: View {
    let progressPercentage: Double
    let weightChange: Double?  // nil = privacy mode (hide exact weights)
    let duration: String
    let unit: WeightUnit

    var body: some View {
        ZStack {
            // Background gradient
            AppGradients.celebration

            VStack(spacing: 16) {
                // App branding
                Text("W8Trackr")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.8))

                Spacer()

                // Progress percentage - large display
                Text(progressPercentage, format: .percent.precision(.fractionLength(0)))
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)

                // Subtitle
                Text("of my goal")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.white.opacity(0.9))

                // Weight change (only shown if not privacy mode)
                if let change = weightChange {
                    Text(weightChangeText(for: change))
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.9))
                }

                Spacer()

                // Duration
                Text(duration)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.white.opacity(0.7))
            }
            .padding(24)
        }
        .frame(width: 600, height: 315)
    }

    /// Formats the weight change with sign and unit
    private func weightChangeText(for change: Double) -> String {
        let sign = change >= 0 ? "+" : ""
        let formattedValue = change.formatted(.number.precision(.fractionLength(1)))
        return "\(sign)\(formattedValue) \(unit.displayName)"
    }
}

#Preview {
    VStack(spacing: 20) {
        ShareableProgressView(
            progressPercentage: 0.5,
            weightChange: -12.5,
            duration: "3 months",
            unit: .lb
        )

        ShareableProgressView(
            progressPercentage: 0.75,
            weightChange: nil,  // Privacy mode
            duration: "6 months",
            unit: .kg
        )
    }
    .padding()
    .background(Color.gray.opacity(0.3))
}
