//
//  LogbookHeaderView.swift
//  W8Trackr
//
//  Column header row for logbook entries showing Date, Weight, Avg, Rate, Notes labels.
//

import SwiftUI

/// Displays column headers above logbook entries for visual clarity
struct LogbookHeaderView: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Date column - matches dateColumn frame in LogbookRowView
                Text("Date")
                    .frame(width: 40, alignment: .leading)

                Spacer()

                // Weight column
                Text("Weight")

                // Moving average column
                Text("Avg")

                // Weekly rate column
                Text("Rate")

                // Notes indicator column - matches approximate width of note icon
                Text("Notes")
                    .frame(width: 24)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(AppColors.background)

            Divider()
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Header Only") {
    LogbookHeaderView()
}

#Preview("Header with Row") {
    let entry = WeightEntry(weight: 170.0, date: .now, note: "Morning")
    let rowData = LogbookRowData(
        entry: entry,
        movingAverage: 171.2,
        weeklyRate: -1.5,
        hasNote: true
    )
    return VStack(spacing: 0) {
        LogbookHeaderView()
        List {
            LogbookRowView(rowData: rowData, weightUnit: .lb) {}
        }
        .listStyle(.plain)
    }
}
#endif
