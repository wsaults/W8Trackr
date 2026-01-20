//
//  SummaryView.swift
//  W8Trackr
//
//  Created by Will Saults on 4/28/25.
//

import Charts
import SwiftData
import SwiftUI

struct SummaryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showAddWeightView = false
    @State private var celebrationMilestone: Double?

    var entries: [WeightEntry]
    var completedMilestones: [CompletedMilestone]
    var preferredWeightUnit: WeightUnit
    var goalWeight: Double
    var showSmoothing: Bool

    // Derive start weight from oldest entry
    private var startWeight: Double {
        guard let oldest = entries.min(by: { $0.date < $1.date }) else {
            return goalWeight
        }
        return oldest.weightValue(in: preferredWeightUnit)
    }

    private var currentWeight: Double {
        entries.first?.weightValue(in: preferredWeightUnit) ?? goalWeight
    }

    private var milestoneProgress: MilestoneProgress? {
        guard !entries.isEmpty else { return nil }
        return MilestoneCalculator.calculateProgress(
            currentWeight: currentWeight,
            startWeight: startWeight,
            goalWeight: goalWeight,
            unit: preferredWeightUnit,
            completedMilestones: completedMilestones
        )
    }

    private var goalPrediction: GoalPrediction {
        TrendCalculator.predictGoalDate(
            entries: entries,
            goalWeight: goalWeight,
            unit: preferredWeightUnit
        )
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                VStack {
                    if entries.isEmpty {
                        EmptyStateView(
                            illustration: .startTracking,
                            title: "Begin Your Journey",
                            description: "Track your weight to see trends and progress toward your goals.",
                            actionTitle: "Log Your First Weight",
                            action: { showAddWeightView = true }
                        )
                    } else {
                        if let entry = entries.first {
                            CurrentWeightView(
                                weight: entry.weightValue(in: preferredWeightUnit),
                                weightUnit: preferredWeightUnit,
                                bodyFatPercentage: entry.bodyFatPercentage
                            )
                        }

                        ScrollView {
                            if let progress = milestoneProgress {
                                MilestoneProgressView(progress: progress) {
                                    checkForNewMilestone()
                                }
                            }

                            ChartSectionView(entries: entries, goalWeight: goalWeight, weightUnit: preferredWeightUnit, showSmoothing: showSmoothing)

                            WeeklySummaryView(entries: entries, weightUnit: preferredWeightUnit)
                                .padding(.top, 16)

                            GoalPredictionView(prediction: goalPrediction)
                                .padding(.horizontal)
                                .padding(.top, 16)

                            if !completedMilestones.isEmpty {
                                MilestoneHistoryView(milestones: completedMilestones, unit: preferredWeightUnit)
                                    .padding(.bottom, 80)
                            }
                        }
                    }
                }

                Button {
                    showAddWeightView.toggle()
                } label: {
                    Image(systemName: "plus")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .fontWeight(.bold)
                        .padding()
                        .background(AppColors.primary)
                        .clipShape(.circle)
                }
                .padding(.bottom)

                // Celebration overlay
                if let milestone = celebrationMilestone {
                    MilestoneCelebrationView(milestoneWeight: milestone, unit: preferredWeightUnit) {
                        celebrationMilestone = nil
                    }
                }
            }
            .background(AppColors.surfaceSecondary)
            .navigationTitle("Summary")
            .navigationBarTitleDisplayMode(.inline)
            .syncStatusToolbar()
            .sheet(isPresented: $showAddWeightView) {
                WeightEntryView(entries: entries, weightUnit: preferredWeightUnit)
            }
            .onAppear {
                checkForNewMilestone()
            }
            .onChange(of: entries.count) { _, _ in
                checkForNewMilestone()
            }
        }
    }

    private func checkForNewMilestone() {
        guard let progress = milestoneProgress else { return }

        // Generate all milestones between start and goal
        let allMilestones = MilestoneCalculator.generateMilestones(
            startWeight: startWeight,
            goalWeight: goalWeight,
            unit: preferredWeightUnit
        )

        // Find milestones that are crossed but not yet recorded
        let completedWeights = Set(completedMilestones.map { $0.targetWeight(in: preferredWeightUnit) })
        let isLosingWeight = goalWeight < startWeight

        for milestone in allMilestones {
            let isCrossed = isLosingWeight ? currentWeight <= milestone : currentWeight >= milestone
            if isCrossed && !completedWeights.contains(milestone) {
                // Record the completed milestone
                let completed = CompletedMilestone(
                    targetWeight: milestone,
                    unit: preferredWeightUnit,
                    startWeight: startWeight
                )
                modelContext.insert(completed)
                try? modelContext.save()

                // Trigger celebration
                celebrationMilestone = milestone
                break // Only celebrate one at a time
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 18, macOS 15, *)
#Preview(traits: .modifier(EntriesPreview())) {
    SummaryView(
        entries: WeightEntry.shortSampleData,
        completedMilestones: [],
        preferredWeightUnit: .lb,
        goalWeight: 160,
        showSmoothing: true
    )
}

@available(iOS 18, macOS 15, *)
#Preview("Empty", traits: .modifier(EmptyEntriesPreview())) {
    SummaryView(
        entries: [],
        completedMilestones: [],
        preferredWeightUnit: .lb,
        goalWeight: 160,
        showSmoothing: true
    )
}
#endif
