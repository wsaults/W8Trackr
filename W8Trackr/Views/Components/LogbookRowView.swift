//
//  LogbookRowView.swift
//  W8Trackr
//
//  Reusable row component for logbook entries with compact layout.
//

import SwiftUI

/// Displays a single logbook entry row with date, weight, moving average, weekly rate, and notes indicator
struct LogbookRowView: View {
    let rowData: LogbookRowData
    let weightUnit: WeightUnit
    var onEdit: (() -> Void)?

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()

    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()

    var body: some View {
        HStack(spacing: 12) {
            // Date column: Day number and weekday abbreviation
            dateColumn

            Spacer()

            // Weight value
            weightColumn

            // Moving average (when available)
            if rowData.movingAverage != nil {
                movingAverageColumn
            }

            // Weekly rate with direction arrow (when available)
            if rowData.weeklyRate != nil {
                weeklyRateColumn
            }

            // Notes indicator
            if rowData.hasNote {
                notesIndicator
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            onEdit?()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Swipe right to edit, swipe left to delete")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Column Views

    private var dateColumn: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(Self.dayFormatter.string(from: rowData.entry.date))
                .font(.headline)
            Text(Self.weekdayFormatter.string(from: rowData.entry.date))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: 40, alignment: .leading)
    }

    private var weightColumn: some View {
        Text(rowData.entry.weightValue(in: weightUnit), format: .number.precision(.fractionLength(1)))
            .font(.body.monospacedDigit())
            .bold()
    }

    private var movingAverageColumn: some View {
        Group {
            if let avg = rowData.movingAverage {
                Text(avg, format: .number.precision(.fractionLength(1)))
                    .font(.body.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var weeklyRateColumn: some View {
        Group {
            if let rate = rowData.weeklyRate {
                HStack(spacing: 2) {
                    Image(systemName: rowData.weightChangeDirection.symbol)
                        .foregroundStyle(rowData.weightChangeDirection.color)
                    Text(abs(rate), format: .number.precision(.fractionLength(1)))
                        .font(.caption.monospacedDigit())
                }
            }
        }
    }

    private var notesIndicator: some View {
        Image(systemName: "note.text")
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        var components: [String] = []

        // Date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        components.append(dateFormatter.string(from: rowData.entry.date))

        // Weight
        let weight = rowData.entry.weightValue(in: weightUnit)
        components.append("\(weight.formatted(.number.precision(.fractionLength(1)))) \(weightUnit.rawValue)")

        // Moving average
        if let avg = rowData.movingAverage {
            components.append("7-day average \(avg.formatted(.number.precision(.fractionLength(1))))")
        }

        // Weekly rate
        if let rate = rowData.weeklyRate {
            let direction = rate < 0 ? "down" : rate > 0 ? "up" : "stable"
            components.append("\(abs(rate).formatted(.number.precision(.fractionLength(1)))) \(weightUnit.rawValue) \(direction) this week")
        }

        // Note
        if rowData.hasNote {
            components.append("has note")
        }

        return components.joined(separator: ", ")
    }
}

// MARK: - Previews

#if DEBUG
#Preview("With All Data") {
    let entry = WeightEntry(weight: 170.0, date: .now, note: "Morning weigh-in")
    let rowData = LogbookRowData(
        entry: entry,
        movingAverage: 171.2,
        weeklyRate: -1.5,
        hasNote: true
    )
    return List {
        LogbookRowView(rowData: rowData, weightUnit: .lb) {}
    }
}

#Preview("Without Moving Average") {
    let entry = WeightEntry(weight: 170.0, date: .now)
    let rowData = LogbookRowData(
        entry: entry,
        movingAverage: nil,
        weeklyRate: nil,
        hasNote: false
    )
    return List {
        LogbookRowView(rowData: rowData, weightUnit: .lb) {}
    }
}

#Preview("Gaining Weight") {
    let entry = WeightEntry(weight: 172.5, date: .now)
    let rowData = LogbookRowData(
        entry: entry,
        movingAverage: 171.0,
        weeklyRate: 2.3,
        hasNote: false
    )
    return List {
        LogbookRowView(rowData: rowData, weightUnit: .lb) {}
    }
}

#Preview("Stable") {
    let entry = WeightEntry(weight: 170.1, date: .now)
    let rowData = LogbookRowData(
        entry: entry,
        movingAverage: 170.0,
        weeklyRate: 0.05,
        hasNote: false
    )
    return List {
        LogbookRowView(rowData: rowData, weightUnit: .lb) {}
    }
}
#endif
