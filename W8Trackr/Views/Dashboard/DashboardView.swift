//
//  DashboardView.swift
//  W8Trackr
//
//  Created by Claude on 1/9/26.
//

import Charts
import SwiftData
import SwiftUI

/// Main dashboard view with redesigned layout
///
/// Layout:
/// ```
/// ┌─────────────────────────────────┐
/// │  Hero Card: Current Weight      │
/// │  + Trend arrow + change badge   │
/// ├─────────────────────────────────┤
/// │  Quick Stats Row                │
/// │  [This Week] [To Goal]          │
/// ├─────────────────────────────────┤
/// │  Milestone Progress Ring        │
/// ├─────────────────────────────────┤
/// │  Chart (swipeable ranges)       │
/// ├─────────────────────────────────┤
/// │  Goal Prediction Card           │
/// ├─────────────────────────────────┤
/// │  Milestone History (optional)   │
/// └─────────────────────────────────┘
/// ```
struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedTab: TabDestination
    @State private var celebrationMilestone: Double?
    @State private var showingShareSheet = false

    var entries: [WeightEntry]
    var completedMilestones: [CompletedMilestone]
    var preferredWeightUnit: WeightUnit
    var goalWeight: Double
    var showSmoothing: Bool
    var milestoneInterval: MilestoneInterval

    // MARK: - Computed Properties

    private var startWeight: Double {
        guard let oldest = entries.min(by: { $0.date < $1.date }) else {
            return goalWeight
        }
        return oldest.weightValue(in: preferredWeightUnit)
    }

    private var currentWeight: Double {
        entries.first?.weightValue(in: preferredWeightUnit) ?? goalWeight
    }

    private var toGoal: Double {
        currentWeight - goalWeight
    }

    private var weeklyChange: Double? {
        QuickStatsRow.calculateWeeklyChange(from: entries, unit: preferredWeightUnit)
    }

    private var milestoneProgress: MilestoneProgress? {
        guard !entries.isEmpty else { return nil }
        return MilestoneCalculator.calculateProgress(
            currentWeight: currentWeight,
            startWeight: startWeight,
            goalWeight: goalWeight,
            unit: preferredWeightUnit,
            completedMilestones: completedMilestones,
            intervalPreference: milestoneInterval
        )
    }

    private var goalPrediction: GoalPrediction {
        TrendCalculator.predictGoalDate(
            entries: entries,
            goalWeight: goalWeight,
            unit: preferredWeightUnit
        )
    }

    private var trackingDuration: String {
        guard let oldest = entries.min(by: { $0.date < $1.date }),
              let newest = entries.first else {
            return "Just started"
        }
        let days = Calendar.current.dateComponents([.day], from: oldest.date, to: newest.date).day ?? 0
        if days < 7 {
            return "\(days) days"
        } else if days < 30 {
            let weeks = days / 7
            return weeks == 1 ? "1 week" : "\(weeks) weeks"
        } else if days < 365 {
            let months = days / 30
            return months == 1 ? "1 month" : "\(months) months"
        } else {
            let years = days / 365
            return years == 1 ? "1 year" : "\(years) years"
        }
    }

    private var progressPercentage: Double {
        guard startWeight != goalWeight else { return 100 }
        let totalChange = abs(startWeight - goalWeight)
        let currentChange = abs(startWeight - currentWeight)
        return min(100, (currentChange / totalChange) * 100)
    }

    private var weightChangeFromStart: Double {
        currentWeight - startWeight
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                if entries.isEmpty {
                    emptyState
                } else {
                    dashboardContent
                }

                // Celebration overlay
                if let milestone = celebrationMilestone {
                    MilestoneCelebrationView(milestoneWeight: milestone, unit: preferredWeightUnit) {
                        // Mark milestone as shown so popup doesn't reappear
                        if let completedMilestone = completedMilestones.first(where: {
                            $0.targetWeight(in: preferredWeightUnit) == milestone
                        }) {
                            completedMilestone.celebrationShown = true
                            try? modelContext.save()
                        }
                        celebrationMilestone = nil
                    }
                }
            }
            .background(AppColors.background)
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .disabled(entries.isEmpty)
                    .accessibilityLabel("Share progress")
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareProgressSheet(
                    progressPercentage: progressPercentage,
                    weightChange: weightChangeFromStart,
                    duration: trackingDuration,
                    unit: preferredWeightUnit
                )
            }
            .onAppear {
                checkForNewMilestone()
            }
            .onChange(of: entries.count) { _, _ in
                checkForNewMilestone()
            }
        }
    }

    // MARK: - View Components

    private var emptyState: some View {
        EmptyStateView(
            illustration: .startTracking,
            title: "Begin Your Journey",
            description: "Track your weight to see trends and progress toward your goals.",
            actionTitle: "Log Your First Weight",
            action: { selectedTab = .addEntry }
        )
    }

    private var dashboardContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Goal Reached Banner (when at goal - shows at top for visibility)
                if goalPrediction.status == .atGoal {
                    GoalReachedBannerView(prediction: goalPrediction)
                }

                // Hero Card
                if let entry = entries.first {
                    HeroCardView(
                        currentWeight: entry.weightValue(in: preferredWeightUnit),
                        weightUnit: preferredWeightUnit,
                        weeklyChange: weeklyChange,
                        bodyFatPercentage: entry.bodyFatPercentage
                    )
                    .padding(.horizontal)
                }

                // Quick Stats Row
                QuickStatsRow(
                    weeklyChange: weeklyChange,
                    toGoal: toGoal,
                    weightUnit: preferredWeightUnit
                )
                .padding(.horizontal)

                // Milestone Progress
                if let progress = milestoneProgress {
                    MilestoneProgressView(progress: progress) {
                        checkForNewMilestone()
                    }
                }

                // Chart Section
                ChartSectionView(
                    entries: entries,
                    goalWeight: goalWeight,
                    weightUnit: preferredWeightUnit,
                    showSmoothing: showSmoothing
                )

                // Goal Prediction (only when NOT at goal - banner shown at top instead)
                if goalPrediction.status != .atGoal {
                    GoalPredictionView(prediction: goalPrediction)
                        .padding(.horizontal)
                }

                // Milestone History
                if !completedMilestones.isEmpty {
                    MilestoneHistoryView(milestones: completedMilestones, unit: preferredWeightUnit)
                }
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Milestone Logic

    private func checkForNewMilestone() {
        guard milestoneProgress != nil else { return }

        // First, check for any uncelebrated existing milestones
        if let uncelebrated = completedMilestones.first(where: { !$0.celebrationShown }) {
            celebrationMilestone = uncelebrated.targetWeight(in: preferredWeightUnit)
            return
        }

        let allMilestones = MilestoneCalculator.generateMilestones(
            startWeight: startWeight,
            goalWeight: goalWeight,
            unit: preferredWeightUnit,
            intervalPreference: milestoneInterval
        )

        let completedWeights = Set(completedMilestones.map { $0.targetWeight(in: preferredWeightUnit) })
        let isLosingWeight = goalWeight < startWeight

        for milestone in allMilestones {
            let isCrossed = isLosingWeight ? currentWeight <= milestone : currentWeight >= milestone
            if isCrossed && !completedWeights.contains(milestone) {
                let completed = CompletedMilestone(
                    targetWeight: milestone,
                    unit: preferredWeightUnit,
                    startWeight: startWeight
                )
                modelContext.insert(completed)

                do {
                    try modelContext.save()
                    // New milestones have celebrationShown = false, so show popup
                    celebrationMilestone = milestone
                } catch {
                    // Remove the unsaved milestone from context
                    modelContext.delete(completed)
                }
                break
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 18, macOS 15, *)
#Preview("With Data", traits: .modifier(DashboardPreview())) {
    @Previewable @State var selectedTab: TabDestination = .dashboard
    DashboardView(
        selectedTab: $selectedTab,
        entries: WeightEntry.shortSampleData,
        completedMilestones: [],
        preferredWeightUnit: .lb,
        goalWeight: 160,
        showSmoothing: true,
        milestoneInterval: .five
    )
}

@available(iOS 18, macOS 15, *)
#Preview("Empty", traits: .modifier(EmptyEntriesPreview())) {
    @Previewable @State var selectedTab: TabDestination = .dashboard
    DashboardView(
        selectedTab: $selectedTab,
        entries: [],
        completedMilestones: [],
        preferredWeightUnit: .lb,
        goalWeight: 160,
        showSmoothing: true,
        milestoneInterval: .five
    )
}
#endif
