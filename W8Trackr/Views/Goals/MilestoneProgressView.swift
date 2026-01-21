//
//  MilestoneProgressView.swift
//  W8Trackr
//
//  Created by Claude on 1/8/26.
//

import SwiftUI
import SwiftData

struct MilestoneProgressView: View {
    let progress: MilestoneProgress
    let onMilestoneReached: (() -> Void)?

    @State private var animatedProgress: Double = 0
    @ScaledMetric(relativeTo: .body) private var barHeight: CGFloat = 12

    init(progress: MilestoneProgress, onMilestoneReached: (() -> Void)? = nil) {
        self.progress = progress
        self.onMilestoneReached = onMilestoneReached
    }

    var body: some View {
        VStack(spacing: 12) {
            // Header row: "Next Milestone" label left, milestone weight + unit right
            HStack {
                Text("Next Milestone")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                HStack(spacing: 4) {
                    Text(progress.nextMilestone, format: .number.precision(.fractionLength(0)))
                        .fontWeight(.semibold)
                    Text(progress.unit.rawValue)
                }
                .font(.subheadline)
            }

            // Linear progress bar
            progressBar

            // Labels row: previous milestone left, "X.X to go" center, next milestone right
            HStack {
                Text(progress.previousMilestone, format: .number.precision(.fractionLength(0)))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                HStack(spacing: 4) {
                    Text(progress.weightToNextMilestone, format: .number.precision(.fractionLength(1)))
                        .fontWeight(.semibold)
                    Text("\(progress.unit.rawValue) to go")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                Spacer()
                Text(progress.nextMilestone, format: .number.precision(.fractionLength(0)))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md))
        .cardShadow()
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Next milestone \(Int(progress.nextMilestone)) \(progress.unit.rawValue). \(Int(animatedProgress * 100)) percent complete. \(progress.weightToNextMilestone.formatted(.number.precision(.fractionLength(1)))) \(progress.unit.rawValue) remaining.")
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animatedProgress = progress.progressToNextMilestone
            }
        }
        .onChange(of: progress.progressToNextMilestone) { _, newValue in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedProgress = newValue
            }
            // Trigger celebration when milestone reached
            if newValue >= 1.0 {
                onMilestoneReached?()
            }
        }
    }

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(AppColors.surfaceSecondary)
                // Filled progress
                Capsule()
                    .fill(AppGradients.progressPositive)
                    .frame(width: max(0, geometry.size.width * animatedProgress))
            }
        }
        .frame(height: barHeight)
    }
}

// MARK: - Compact variant for smaller spaces

struct MilestoneProgressCompactView: View {
    let progress: MilestoneProgress

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(progress.weightToNextMilestone, specifier: "%.1f") \(progress.unit.rawValue) to next milestone")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("Goal: \(progress.nextMilestone, specifier: "%.0f") \(progress.unit.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // Compact progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(AppColors.surfaceSecondary)
                        Capsule()
                            .fill(AppColors.primary)
                            .frame(width: geometry.size.width * progress.progressToNextMilestone)
                    }
                }
                .frame(height: 6)
            }

            Spacer()
        }
        .padding()
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md))
        .cardShadow()
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Next milestone \(Int(progress.nextMilestone)) \(progress.unit.rawValue). \(Int(progress.progressToNextMilestone * 100)) percent complete. \(progress.weightToNextMilestone.formatted(.number.precision(.fractionLength(1)))) \(progress.unit.rawValue) remaining.")
    }
}

#Preview("Linear Progress") {
    let progress = MilestoneProgress(
        currentWeight: 178,
        nextMilestone: 175,
        previousMilestone: 180,
        goalWeight: 160,
        unit: .lb,
        completedMilestones: [195, 190, 185, 180]
    )
    return MilestoneProgressView(progress: progress)
}

#Preview("Compact") {
    let progress = MilestoneProgress(
        currentWeight: 178,
        nextMilestone: 175,
        previousMilestone: 180,
        goalWeight: 160,
        unit: .lb,
        completedMilestones: []
    )
    return MilestoneProgressCompactView(progress: progress)
}
