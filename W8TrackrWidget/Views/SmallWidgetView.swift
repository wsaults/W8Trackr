//
//  SmallWidgetView.swift
//  W8TrackrWidget
//
//  Created by Claude on 1/22/26.
//

import SwiftUI
import WidgetKit

/// Small widget: Current weight + trend arrow
/// Weight is hero element - large and bold
struct SmallWidgetView: View {
    let entry: WeightWidgetEntry

    var body: some View {
        if entry.currentWeight == nil {
            EmptyStateView()
        } else {
            contentView
                .widgetURL(URL(string: "w8trackr://"))
        }
    }

    private var contentView: some View {
        VStack(alignment: .leading, spacing: 4) {
            // App identifier
            HStack(spacing: 4) {
                Image(systemName: "scalemass.fill")
                    .font(.caption2)
                Text("W8Trackr")
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .foregroundStyle(.secondary)

            Spacer()

            // Weight - hero element
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(entry.currentWeight ?? 0)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.6)

                Text(entry.weightUnit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Trend indicator (neutral colors per CONTEXT.md)
            HStack(spacing: 4) {
                Image(systemName: entry.trend.systemImage)
                    .font(.caption)

                Text(trendText)
                    .font(.caption2)
            }
            .foregroundStyle(trendColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var trendText: String {
        switch entry.trend {
        case .up: return "Trending up"
        case .down: return "Trending down"
        case .neutral: return "Holding steady"
        case .unknown: return "Not enough data"
        }
    }

    /// Neutral colors per CONTEXT.md - no red/green judgment
    private var trendColor: Color {
        switch entry.trend {
        case .up, .down: return .primary
        case .neutral, .unknown: return .secondary
        }
    }
}
