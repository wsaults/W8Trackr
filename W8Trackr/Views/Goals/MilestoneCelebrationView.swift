//
//  MilestoneCelebrationView.swift
//  W8Trackr
//
//  Created by Claude on 1/8/26.
//

import ConfettiSwiftUI
import SwiftUI
import UIKit

struct MilestoneCelebrationView: View {
    let milestoneWeight: Double
    let unit: WeightUnit
    let onDismiss: () -> Void

    @State private var showContent = false
    @State private var confettiTrigger: Int = 0
    @ScaledMetric(relativeTo: .largeTitle) private var trophySize: CGFloat = 60

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            // Celebration card
            VStack(spacing: 20) {
                // Trophy icon with animation
                Image(systemName: "trophy.fill")
                    .font(.system(size: trophySize))
                    .foregroundStyle(.yellow)
                    .scaleEffect(showContent ? 1.0 : 0.5)
                    .opacity(showContent ? 1.0 : 0)

                VStack(spacing: 8) {
                    Text("Milestone Reached!")
                        .font(.title)
                        .fontWeight(.bold)

                    HStack(spacing: 4) {
                        Text(milestoneWeight, format: .number.precision(.fractionLength(0)))
                            .font(.largeTitle)
                            .fontWeight(.heavy)
                        Text(unit.rawValue)
                            .font(.title2)
                    }
                    .foregroundStyle(AppColors.primary)

                    Text("Keep up the great work!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .opacity(showContent ? 1.0 : 0)
                .offset(y: showContent ? 0 : 20)

                Button {
                    dismiss()
                } label: {
                    Text("Continue")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.primary)
                        .foregroundStyle(.white)
                        .clipShape(.rect(cornerRadius: 12))
                }
                .accessibilityLabel("Continue")
                .accessibilityHint("Dismiss celebration and return to dashboard")
                .opacity(showContent ? 1.0 : 0)
                .padding(.top, 8)
            }
            .padding(24)
            .background(Color(UIColor.systemBackground))
            .clipShape(.rect(cornerRadius: 20))
            .shadow(radius: 20)
            .padding(40)
            .scaleEffect(showContent ? 1.0 : 0.8)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Milestone reached! You've hit \(Int(milestoneWeight)) \(unit.rawValue). Keep up the great work!")
        }
        .confettiCannon(trigger: $confettiTrigger, num: 50, radius: 400)
        .onAppear {
            // Announce milestone to VoiceOver
            UIAccessibility.post(
                notification: .announcement,
                argument: "Congratulations! You've reached \(Int(milestoneWeight)) \(unit.rawValue) milestone!"
            )
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showContent = true
            }
            // Trigger confetti after animation starts
            Task {
                try? await Task.sleep(for: .milliseconds(300))
                confettiTrigger += 1
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeIn(duration: 0.2)) {
            showContent = false
        }
        Task {
            try? await Task.sleep(for: .milliseconds(200))
            onDismiss()
        }
    }
}

// MARK: - History View

struct MilestoneHistoryView: View {
    let milestones: [CompletedMilestone]
    let unit: WeightUnit

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Milestones Achieved")
                .font(.headline)
                .padding(.horizontal)

            if milestones.isEmpty {
                Text("No milestones completed yet. Keep going!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else {
                ForEach(milestones.sorted { $0.achievedDate > $1.achievedDate }, id: \.achievedDate) { milestone in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppColors.success)

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Text(milestone.targetWeight(in: unit), format: .number.precision(.fractionLength(0)))
                                    .fontWeight(.semibold)
                                Text(unit.rawValue)
                            }
                            Text(milestone.achievedDate, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.horizontal)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Milestone \(Int(milestone.targetWeight(in: unit))) \(unit.rawValue), achieved \(milestone.achievedDate.formatted(date: .abbreviated, time: .omitted))")
                }
            }
        }
        .padding(.vertical)
        .background(Color(UIColor.systemBackground))
        .clipShape(.rect(cornerRadius: 10))
        .padding(.horizontal)
    }
}

#Preview("Celebration") {
    MilestoneCelebrationView(milestoneWeight: 175, unit: .lb) { }
}

#Preview("History") {
    MilestoneHistoryView(
        milestones: [
            CompletedMilestone(targetWeight: 195, unit: .lb, achievedDate: Date().addingTimeInterval(-86400 * 30), startWeight: 200),
            CompletedMilestone(targetWeight: 190, unit: .lb, achievedDate: Date().addingTimeInterval(-86400 * 20), startWeight: 200),
            CompletedMilestone(targetWeight: 185, unit: .lb, achievedDate: Date().addingTimeInterval(-86400 * 10), startWeight: 200)
        ],
        unit: .lb
    )
}
