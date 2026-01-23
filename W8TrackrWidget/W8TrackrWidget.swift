//
//  W8TrackrWidget.swift
//  W8TrackrWidget
//
//  Created by Claude on 1/22/26.
//

import SwiftUI
import WidgetKit

@main
struct W8TrackrWidgetBundle: WidgetBundle {
    var body: some Widget {
        WeightWidget()
    }
}

struct WeightWidget: Widget {
    let kind: String = "WeightWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeightWidgetProvider()) { entry in
            WeightWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Weight Tracker")
        .description("See your current weight and progress at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct WeightWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: WeightWidgetEntry

    var body: some View {
        // Placeholder - views implemented in Plan 22-02
        Text(entry.currentWeight.map { "\($0)" } ?? "No data")
    }
}
