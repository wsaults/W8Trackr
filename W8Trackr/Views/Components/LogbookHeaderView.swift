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
            HStack(spacing: LogbookLayout.columnSpacing) {
                // Date column - matches dateColumn frame in LogbookRowView
                Text("Date")
                    .frame(width: LogbookLayout.dateColumnWidth, alignment: .leading)

                Spacer()

                // Weight column
                Text("Weight")
                    .frame(width: LogbookLayout.weightColumnWidth, alignment: .trailing)

                // Moving average column
                Text("Avg")
                    .frame(width: LogbookLayout.avgColumnWidth, alignment: .trailing)

                // Weekly rate column
                Text("Rate")
                    .frame(width: LogbookLayout.rateColumnWidth, alignment: .trailing)

                // Notes indicator column - matches approximate width of note icon
                Text("Notes")
                    .frame(width: LogbookLayout.notesColumnWidth, alignment: .center)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal)
            .padding(.vertical, LogbookLayout.headerVerticalPadding)
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

#Preview("Header with Empty Row") {
    let entry = WeightEntry(weight: 170.0, date: .now)
    let rowData = LogbookRowData(
        entry: entry,
        movingAverage: nil,
        weeklyRate: nil,
        hasNote: false
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
