//
//  GoalReachedBannerView.swift
//  W8Trackr
//
//  Created by Claude on 1/20/26.
//

import SwiftUI

/// Celebratory banner displayed at top of dashboard when user has reached their goal weight
///
/// Shows a green-themed horizontal banner with checkmark icon and congratulations message.
/// Designed to be visible immediately without scrolling when the user opens the dashboard.
struct GoalReachedBannerView: View {
    let prediction: GoalPrediction

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(AppColors.success)

            VStack(alignment: .leading, spacing: 2) {
                Text("Goal Reached!")
                    .font(.headline)
                Text("Congratulations on reaching your target weight!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(AppColors.success.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("At Goal") {
    let prediction = GoalPrediction(
        predictedDate: nil,
        weeklyVelocity: 0,
        status: .atGoal,
        weightToGoal: 0.2,
        unit: .lb
    )
    return GoalReachedBannerView(prediction: prediction)
        .padding(.vertical)
}
#endif
