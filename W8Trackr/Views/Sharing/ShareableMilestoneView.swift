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

            // Decorative sparkles in corners
            VStack {
                HStack {
                    Text("✨")
                        .font(.system(size: 32))
                        .opacity(0.8)
                    Spacer()
                    Text("🎉")
                        .font(.system(size: 36))
                        .opacity(0.9)
                }
                Spacer()
                HStack {
                    Text("🎉")
                        .font(.system(size: 36))
                        .opacity(0.9)
                    Spacer()
                    Text("✨")
                        .font(.system(size: 32))
                        .opacity(0.8)
                }
            }
            .padding(20)

            // Main content
            VStack(spacing: 8) {
                // Trophy with glow effect
                ZStack {
                    // Glow behind trophy
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(Color.yellow.opacity(0.4))
                        .blur(radius: 20)

                    Image(systemName: "trophy.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.yellow, Color.orange],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .yellow.opacity(0.5), radius: 8, y: 4)
                }

                // Milestone text
                Text("MILESTONE REACHED!")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(Color.white)
                    .tracking(2)

                // Weight display - big and bold
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(milestoneWeight, format: .number.precision(.fractionLength(0)))
                        .font(.system(size: 96, weight: .black, design: .rounded))
                    Text(unit.rawValue)
                        .font(.system(size: 40, weight: .bold))
                        .padding(.bottom, 8)
                }
                .foregroundStyle(Color.white)
                .shadow(color: .black.opacity(0.3), radius: 4, y: 2)

                // App branding at bottom
                Text("W8Trackr")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.7))
                    .padding(.top, 4)
            }
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
