//
//  SingleLineLollipop.swift
//  W8Trackr
//
//  Created by Will Saults on 4/28/25.
//

import Charts
import SwiftUI

struct SingleLineLollipop: View {
    let entries: [WeightEntry]
    let goalWeight: Double
    let weightUnit: WeightUnit
    
    @State private var selectedRange: DateRange = .sevenDay
    
    private enum DateRange: String, CaseIterable {
        case sevenDay = "7 Day"
//        case thirtyDay = "30 Day"
//        case ninetyDay = "90 Day"
//        case oneYear = "1 Year"
        case allTime = "All"
        
        var days: Int? {
            switch self {
            case .sevenDay: return 7
//            case .thirtyDay: return 30
//            case .ninetyDay: return 90
//            case .oneYear: return 365
            case .allTime: return nil
            }
        }
    }
    
    private var filteredEntries: [WeightEntry] {
        guard let days = selectedRange.days else { return entries }
        
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return entries.filter { $0.date >= cutoffDate }
    }
    
    private var yAxisPadding: Double { 5.0 }
    
    private var minWeight: Double {
        (filteredEntries.map { $0.weightValue }.min() ?? goalWeight) - yAxisPadding
    }
    
    private var maxWeight: Double {
        (filteredEntries.map { $0.weightValue }.max() ?? goalWeight) + yAxisPadding
    }
    
    // Group entries by date, maintaining the full WeightEntry objects
    private var entriesByDay: [Date: [WeightEntry]] {
        Dictionary(grouping: filteredEntries) { entry in
            Calendar.current.startOfDay(for: entry.date)
        }
    }
    
    // Calculate average weight for each day for the line
    private var dailyAverages: [DailyAverage] {
        entriesByDay.map { date, entries in
            let avgWeight = entries.reduce(0.0) { $0 + $1.weightValue } / Double(entries.count)
            return DailyAverage(date: date, weight: avgWeight)
        }.sorted { $0.date < $1.date }
    }
    
    private var dateFormatForRange: Date.FormatStyle {
        switch selectedRange {
        case .sevenDay:
            return .dateTime.day()
//        case .thirtyDay:
//            return .dateTime.day()
//        case .ninetyDay:
//            return .dateTime.month(.abbreviated).day()
//        case .oneYear:
//            return .dateTime.month(.abbreviated).year()
        case .allTime:
            return .dateTime.month(.abbreviated).year()
        }
    }

    private var xAxisStride: Calendar.Component {
        switch selectedRange {
        case .sevenDay:
            return .day
//        case .thirtyDay:
//            return .day
//        case .ninetyDay:
//            return .month
//        case .oneYear:
//            return .month
        case .allTime:
            return .month
        }
    }
    
    var body: some View {
        VStack {
            Chart {
                // Goal weight line
                if goalWeight > 0 {
                    RuleMark(y: .value("Goal Weight", goalWeight))
                        .foregroundStyle(.green.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [10, 5]))
                        .annotation(position: .overlay) {
                            Text("Goal: \(goalWeight, format: .number.precision(.fractionLength(1))) \(weightUnit.rawValue)")
                                .font(.caption)
                                .foregroundStyle(.green)
                                .background(Color(UIColor.systemBackground))
                        }
                }
                
                // Draw line using daily averages
                ForEach(dailyAverages) { average in
                    LineMark(
                        x: .value("Date", average.date),
                        y: .value("Weight", average.weight)
                    )
                    .interpolationMethod(.catmullRom)
                }
                
                // Plot all individual points
                ForEach(filteredEntries) { entry in
                    PointMark(
                        x: .value("Date", Calendar.current.startOfDay(for: entry.date)),
                        y: .value("Weight", entry.weightValue)
                    )
                }
            }
            .chartYScale(domain: minWeight...maxWeight)
            .chartYAxis {
                AxisMarks(preset: .extended, position: .leading) { value in
                    AxisValueLabel {
                        if let weight = value.as(Double.self) {
                            Text("\(weight, format: .number.precision(.fractionLength(1))) \(weightUnit.rawValue)")
                        }
                    }
                    AxisGridLine()
                    AxisTick()
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: xAxisStride)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: dateFormatForRange)
                }
            }
            .animation(.smooth, value: selectedRange)
            .padding(.bottom)
            
            Picker("Date Range", selection: $selectedRange) {
                ForEach(DateRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
        }
    }
}

private struct DailyAverage: Identifiable {
    let id = UUID()
    let date: Date
    let weight: Double
}

#Preview {
    SingleLineLollipop(entries: WeightEntry.sortedSampleData, goalWeight: 160.0, weightUnit: .lb)
        .padding()
}
