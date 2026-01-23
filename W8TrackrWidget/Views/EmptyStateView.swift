//
//  EmptyStateView.swift
//  W8TrackrWidget
//
//  Created by Claude on 1/22/26.
//

import SwiftUI
import WidgetKit

/// Empty state view when no weight entries exist
struct EmptyStateView: View {
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(spacing: family == .systemSmall ? 4 : 8) {
            Image(systemName: "scalemass")
                .font(family == .systemSmall ? .title2 : .largeTitle)
                .foregroundStyle(.secondary)

            Text("Add your first weigh-in", comment: "Widget empty state prompt")
                .font(family == .systemSmall ? .caption2 : .caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .widgetURL(URL(string: "w8trackr://"))
    }
}

/// View when no goal is set (for medium widget progress)
struct NoGoalView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "target")
                .font(.title)
                .foregroundStyle(.secondary)

            Text("Set a goal to track progress", comment: "Widget no goal state prompt")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .widgetURL(URL(string: "w8trackr://"))
    }
}
