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
    
    @State private var selectedRange: DateRange = .oneMonth
    
    private enum DateRange: String, CaseIterable {
        case oneMonth = "1M"
        case threeMonths = "3M"
        case sixMonths = "6M"
        case oneYear = "1Y"
        case allTime = "All"
        
        var months: Int? {
            switch self {
            case .oneMonth: return 1
            case .threeMonths: return 3
            case .sixMonths: return 6
            case .oneYear: return 12
            case .allTime: return nil
            }
        }
    }
    
    private var filteredEntries: [WeightEntry] {
        guard let months = selectedRange.months else { return entries }
        
        let cutoffDate = Calendar.current.date(byAdding: .month, value: -months, to: Date()) ?? Date()
        return entries.filter { $0.date >= cutoffDate }
    }
    
    private var minWeight: Double {
        min(filteredEntries.map { $0.weightValue }.min() ?? 0, goalWeight)
    }
    
    private var maxWeight: Double {
        max(filteredEntries.map { $0.weightValue }.max() ?? 200, goalWeight)
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
    
    var body: some View {
        VStack {
            Chart {
                // Goal weight line
                RuleMark(y: .value("Goal Weight", goalWeight))
                    .foregroundStyle(.green.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [10, 5]))
                    .annotation(position: .overlay) {
                        Text("Goal: \(goalWeight, format: .number.precision(.fractionLength(1))) \(weightUnit.rawValue)")
                            .font(.caption)
                            .foregroundStyle(.green)
                            .background(Color(UIColor.systemBackground))
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
            .chartYScale(domain: (minWeight - 5)...(maxWeight + 5))
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
                AxisMarks(format: .dateTime.month().day())
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
