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

    init(progress: MilestoneProgress, onMilestoneReached: (() -> Void)? = nil) {
        self.progress = progress
        self.onMilestoneReached = onMilestoneReached
    }

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // Background track
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)

                // Progress arc
                Circle()
                    .trim(from: 0, to: animatedProgress)
                    .stroke(
                        progressGradient,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                // Center content
                VStack(spacing: 4) {
                    Text(progress.weightToNextMilestone, format: .number.precision(.fractionLength(1)))
                        .font(.title)
                        .fontWeight(.bold)
                    Text("\(progress.unit.rawValue) to go")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 120, height: 120)

            // Milestone label
            VStack(spacing: 2) {
                Text("Next Milestone")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 4) {
                    Text(progress.nextMilestone, format: .number.precision(.fractionLength(0)))
                        .fontWeight(.semibold)
                    Text(progress.unit.rawValue)
                }
                .font(.subheadline)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
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

    private var progressGradient: AngularGradient {
        AngularGradient(
            gradient: Gradient(colors: [.blue, .cyan, .blue]),
            center: .center,
            startAngle: .degrees(-90),
            endAngle: .degrees(270)
        )
    }
}

// MARK: - Compact variant for smaller spaces

struct MilestoneProgressCompactView: View {
    let progress: MilestoneProgress

    var body: some View {
        HStack(spacing: 12) {
            // Mini progress ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: progress.progressToNextMilestone)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(progress.weightToNextMilestone, specifier: "%.1f") \(progress.unit.rawValue) to next milestone")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("Goal: \(progress.nextMilestone, specifier: "%.0f") \(progress.unit.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

#Preview("Progress Ring") {
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
