//
//  ShareableMilestoneView.swift
//  W8Trackr
//
//  Fixed-size SwiftUI view for sharing milestone achievements.
//  Uses fixed font sizes (not Dynamic Type) since this is for image generation.
//

import SwiftUI

/// A view designed to be rendered to a shareable milestone image.
/// Fixed size of 600x315 (1.91:1 ratio optimal for social media).
struct ShareableMilestoneView: View {
    let milestoneWeight: Double
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

                // Trophy icon
                Image(systemName: "trophy.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.yellow)

                // Milestone text
                Text("Milestone Reached!")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Color.white)

                // Weight display
                HStack(spacing: 8) {
                    Text(milestoneWeight, format: .number.precision(.fractionLength(0)))
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                    Text(unit.rawValue)
                        .font(.system(size: 32, weight: .medium))
                }
                .foregroundStyle(Color.white)

                Spacer()
            }
            .padding(24)
        }
        .frame(width: 600, height: 315)
    }
}

#Preview {
    VStack(spacing: 20) {
        ShareableMilestoneView(
            milestoneWeight: 175,
            unit: .lb
        )

        ShareableMilestoneView(
            milestoneWeight: 80,
            unit: .kg
        )
    }
    .padding()
    .background(Color.gray.opacity(0.3))
}
