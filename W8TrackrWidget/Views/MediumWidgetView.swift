//
//  MediumWidgetView.swift
//  W8TrackrWidget
//
//  Created by Claude on 1/22/26.
//

import SwiftUI
import WidgetKit

/// Medium widget: Progress toward goal weight
/// Shows current weight, goal, and progress visualization
struct MediumWidgetView: View {
    let entry: WeightWidgetEntry

    var body: some View {
        if entry.currentWeight == nil {
            EmptyStateView()
        } else if entry.goalWeight == nil {
            NoGoalView()
        } else {
            contentView
                .widgetURL(URL(string: "w8trackr://"))
        }
    }

    private var contentView: some View {
        HStack(spacing: 16) {
            // Left side: Current weight (hero)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "scalemass.fill")
                        .font(.caption2)
                    Text("W8Trackr")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.secondary)

                Spacer()

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(entry.currentWeight ?? 0)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.6)

                    Text(entry.weightUnit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Trend
                HStack(spacing: 4) {
                    Image(systemName: entry.trend.systemImage)
                        .font(.caption)
                    Text(trendText)
                        .font(.caption2)
                }
                .foregroundStyle(entry.trend == .unknown ? .secondary : .primary)
            }

            Divider()

            // Right side: Progress
            VStack(alignment: .trailing, spacing: 8) {
                Text("Goal: \(entry.goalWeight ?? 0) \(entry.weightUnit)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                // Progress percentage
                if let progress = entry.progressPercent {
                    Text(progressText(progress))
                        .font(.system(size: 28, weight: .semibold, design: .rounded))

                    // Remaining
                    Text(remainingText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("--")
                        .font(.title)
                        .foregroundStyle(.secondary)
                }

                // Simple progress bar
                ProgressBarView(progress: entry.progressPercent ?? 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var trendText: String {
        switch entry.trend {
        case .up: return String(localized: "Up")
        case .down: return String(localized: "Down")
        case .neutral: return String(localized: "Steady")
        case .unknown: return "-"
        }
    }

    private func progressText(_ progress: Double) -> String {
        let percent = Int(min(max(progress, 0), 1) * 100)
        return "\(percent)%"
    }

    private var remainingText: String {
        guard let current = entry.currentWeight,
              let goal = entry.goalWeight else {
            return ""
        }

        let diff = abs(current - goal)
        let toGo = String(localized: "to go")
        return "\(diff) \(entry.weightUnit) \(toGo)"
    }
}

/// Simple progress bar for medium widget
struct ProgressBarView: View {
    let progress: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(.secondary.opacity(0.3))

                // Progress fill
                RoundedRectangle(cornerRadius: 4)
                    .fill(.blue)
                    .frame(width: geometry.size.width * min(max(progress, 0), 1))
            }
        }
        .frame(height: 6)
    }
}
