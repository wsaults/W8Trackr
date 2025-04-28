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
    
    private var minWeight: Double {
        min(entries.map { $0.weightValue }.min() ?? 0, goalWeight)
    }
    
    private var maxWeight: Double {
        max(entries.map { $0.weightValue }.max() ?? 200, goalWeight)
    }
    
    // Group entries by date, maintaining the full WeightEntry objects
    private var entriesByDay: [Date: [WeightEntry]] {
        Dictionary(grouping: entries) { entry in
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
        Chart {
            // Goal weight line
            RuleMark(y: .value("Goal Weight", goalWeight))
                .foregroundStyle(.green.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [10, 5]))
                .annotation(position: .leading) {
                    Text("Goal: \(goalWeight, format: .number.precision(.fractionLength(1))) lbs")
                        .font(.caption)
                        .foregroundStyle(.green)
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
            ForEach(entries) { entry in
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
                        Text("\(weight, format: .number.precision(.fractionLength(1))) lbs")
                    }
                }
                AxisGridLine()
                AxisTick()
            }
        }
        .chartXAxis {
            AxisMarks(format: .dateTime.month().day())
        }
    }
}

// Helper struct for daily averages
private struct DailyAverage: Identifiable {
    let id = UUID()
    let date: Date
    let weight: Double
}

#Preview {
    SingleLineLollipop(entries: WeightEntry.sortedSampleData, goalWeight: 160.0)
        .padding()
}
