//
//  GoalPredictionView.swift
//  W8Trackr
//
//  Created by Claude on 1/9/26.
//

import SwiftUI

// MARK: - Supporting Types

/// Represents the status of a goal prediction
enum PredictionStatus: Equatable {
    case onTrack(Date)
    case atGoal
    case wrongDirection
    case tooSlow
    case insufficientData
    case noData

    var iconName: String {
        switch self {
        case .onTrack: return "target"
        case .atGoal: return "checkmark.circle.fill"
        case .wrongDirection: return "arrow.up.right"
        case .tooSlow: return "tortoise.fill"
        case .insufficientData, .noData: return "chart.line.uptrend.xyaxis"
        }
    }

    var isPositive: Bool {
        switch self {
        case .onTrack, .atGoal: return true
        case .wrongDirection, .tooSlow, .insufficientData, .noData: return false
        }
    }
}

/// Model for goal prediction data
struct GoalPrediction {
    let predictedDate: Date?
    let weeklyVelocity: Double
    let status: PredictionStatus
    let weightToGoal: Double
    let unit: WeightUnit
}

/// Displays goal date prediction based on current weight trend
///
/// Shows different states:
/// - On track: Shows predicted goal date with encouraging message
/// - At goal: Celebration message
/// - Wrong direction: Warning with current trend info
/// - Insufficient data: Encouragement to keep logging
struct GoalPredictionView: View {
    let prediction: GoalPrediction

    private var formattedDate: String? {
        guard let date = prediction.predictedDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private var formattedVelocity: String {
        let absVelocity = abs(prediction.weeklyVelocity)
        let direction = prediction.weeklyVelocity < 0 ? "losing" : "gaining"
        return String(format: "%.1f %@/week (%@)", absVelocity, prediction.unit.rawValue, direction)
    }

    private var daysUntilGoal: Int? {
        guard let date = prediction.predictedDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: date).day
    }

    private var weeksUntilGoal: Int? {
        guard let days = daysUntilGoal else { return nil }
        return days / 7
    }

    private var accessibilityDescription: String {
        switch prediction.status {
        case .onTrack:
            let goalWeight = abs(prediction.weightToGoal)
            let unitStr = prediction.unit.rawValue
            if let date = formattedDate {
                return "Goal prediction: You're on track to reach your goal of \(String(format: "%.1f", goalWeight)) \(unitStr) by \(date), losing \(String(format: "%.1f", abs(prediction.weeklyVelocity))) \(unitStr) per week"
            }
            return "Goal prediction: You're on track to reach your goal"
        case .atGoal:
            return "You've reached your goal weight! Congratulations on reaching your target weight. Keep up the great work maintaining it!"
        case .wrongDirection:
            let direction = prediction.weightToGoal > 0 ? "gaining" : "losing"
            let goal = prediction.weightToGoal > 0 ? "lose" : "gain"
            return "Trend alert: Currently \(direction) weight. Your goal requires you to \(goal) weight. Current rate: \(String(format: "%.1f", abs(prediction.weeklyVelocity))) \(prediction.unit.rawValue) per week \(direction)"
        case .tooSlow:
            return "Goal prediction: At current pace of \(String(format: "%.1f", abs(prediction.weeklyVelocity))) \(prediction.unit.rawValue) per week, reaching your goal would take over 2 years"
        case .insufficientData:
            return "Goal tracking: Keep logging! Log your weight for at least 7 days to see when you'll reach your goal"
        case .noData:
            return "Goal tracking: Start tracking. Add weight entries to see your goal prediction"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: prediction.status.iconName)
                    .foregroundStyle(prediction.status.isPositive ? AppColors.success : .secondary)
                    .font(.title3)

                Text(headerText)
                    .font(.headline)
            }

            // Main content based on status
            switch prediction.status {
            case .onTrack(let date):
                onTrackContent(date: date)
            case .atGoal:
                atGoalContent
            case .wrongDirection:
                wrongDirectionContent
            case .tooSlow:
                tooSlowContent
            case .insufficientData:
                insufficientDataContent
            case .noData:
                noDataContent
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private var headerText: String {
        switch prediction.status {
        case .atGoal:
            return "Goal Reached!"
        case .onTrack:
            return "Goal Prediction"
        case .wrongDirection:
            return "Trend Alert"
        case .tooSlow:
            return "Goal Prediction"
        case .insufficientData, .noData:
            return "Goal Tracking"
        }
    }

    private var backgroundColor: Color {
        switch prediction.status {
        case .atGoal:
            return AppColors.success.opacity(0.1)
        case .onTrack:
            return AppColors.primary.opacity(0.1)
        case .wrongDirection:
            return AppColors.warning.opacity(0.1)
        case .tooSlow:
            return AppColors.surfaceSecondary
        case .insufficientData, .noData:
            return AppColors.surfaceSecondary.opacity(0.5)
        }
    }

    // MARK: - Content Views

    @ViewBuilder
    private func onTrackContent(date: Date) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if let formatted = formattedDate {
                HStack(alignment: .firstTextBaseline) {
                    Text("Reaching goal by")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(formatted)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
            }

            if let weeks = weeksUntilGoal, weeks > 0 {
                Text("About \(weeks) \(weeks == 1 ? "week" : "weeks") away")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if let days = daysUntilGoal {
                Text("\(days) \(days == 1 ? "day" : "days") to go!")
                    .font(.caption)
                    .foregroundStyle(AppColors.success)
            }

            // Velocity info
            HStack(spacing: 4) {
                Image(systemName: prediction.weeklyVelocity < 0 ? "arrow.down" : "arrow.up")
                    .font(.caption2)
                Text(formattedVelocity)
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var atGoalContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Congratulations!")
                .font(.subheadline)
                .foregroundStyle(AppColors.success)

            Text("You've reached your target weight. Keep up the great work maintaining it!")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var wrongDirectionContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            let direction = prediction.weightToGoal > 0 ? "gaining" : "losing"
            let goal = prediction.weightToGoal > 0 ? "lose" : "gain"

            Text("Currently \(direction) weight")
                .font(.subheadline)
                .foregroundStyle(AppColors.warning)

            Text("Your goal requires you to \(goal) weight. The prediction will update as your trend changes.")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Show current velocity
            HStack(spacing: 4) {
                Image(systemName: prediction.weeklyVelocity < 0 ? "arrow.down" : "arrow.up")
                    .font(.caption2)
                Text(formattedVelocity)
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var tooSlowContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Goal is far away")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("At your current pace, reaching your goal would take over 2 years. Consider adjusting your approach.")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Show current velocity
            HStack(spacing: 4) {
                Image(systemName: prediction.weeklyVelocity < 0 ? "arrow.down" : "arrow.up")
                    .font(.caption2)
                Text(formattedVelocity)
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var insufficientDataContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Keep logging!")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Log your weight for at least 7 days to see when you'll reach your goal.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var noDataContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Start tracking")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Add weight entries to see your goal prediction.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("On Track") {
    let prediction = GoalPrediction(
        predictedDate: Calendar.current.date(byAdding: .day, value: 45, to: Date()),
        weeklyVelocity: -1.5,
        status: .onTrack(Calendar.current.date(byAdding: .day, value: 45, to: Date())!),
        weightToGoal: 10.0,
        unit: .lb
    )
    return GoalPredictionView(prediction: prediction)
        .padding()
}

#Preview("At Goal") {
    let prediction = GoalPrediction(
        predictedDate: nil,
        weeklyVelocity: 0,
        status: .atGoal,
        weightToGoal: 0.2,
        unit: .lb
    )
    return GoalPredictionView(prediction: prediction)
        .padding()
}

#Preview("Wrong Direction") {
    let prediction = GoalPrediction(
        predictedDate: nil,
        weeklyVelocity: 0.8,
        status: .wrongDirection,
        weightToGoal: 15.0,
        unit: .lb
    )
    return GoalPredictionView(prediction: prediction)
        .padding()
}

#Preview("Too Slow") {
    let prediction = GoalPrediction(
        predictedDate: nil,
        weeklyVelocity: -0.1,
        status: .tooSlow,
        weightToGoal: 50.0,
        unit: .lb
    )
    return GoalPredictionView(prediction: prediction)
        .padding()
}

#Preview("Insufficient Data") {
    let prediction = GoalPrediction(
        predictedDate: nil,
        weeklyVelocity: 0,
        status: .insufficientData,
        weightToGoal: 0,
        unit: .lb
    )
    return GoalPredictionView(prediction: prediction)
        .padding()
}
#endif
