//
//  WeightTrendChartView.swift
//  W8Trackr
//
//  Created by Will Saults on 4/28/25.
//

import Charts
import SwiftUI

struct WeightTrendChartView: View {
    let entries: [WeightEntry]
    let goalWeight: Double
    let weightUnit: WeightUnit
    let selectedRange: DateRange
    
    private var filteredEntries: [WeightEntry] {
        guard let days = selectedRange.days else { return entries }
        
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return entries.filter { $0.date >= cutoffDate }
    }
    
    private func convertWeight(_ weight: Double) -> Double {
        switch weightUnit {
        case .kg:
            return weight * 0.453592 // Convert lb to kg
        case .lb:
            return weight
        }
    }
    
    private var yAxisPadding: Double {
        weightUnit == .kg ? 2.0 : 5.0
    }
    
    private var minWeight: Double {
        let dataMin = filteredEntries.map { convertWeight($0.weightValue) }.min() ?? 0
        let goalMin = goalWeight > 0 ? goalWeight : Double.infinity
        return min(dataMin, goalMin) - yAxisPadding
    }
    
    private var maxWeight: Double {
        let dataMax = filteredEntries.map { convertWeight($0.weightValue) }.max() ?? 0
        let goalMax = goalWeight > 0 ? goalWeight : 0
        return max(dataMax, goalMax) + yAxisPadding
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
            let avgWeight = entries.reduce(0.0) { $0 + convertWeight($1.weightValue) } / Double(entries.count)
            return DailyAverage(date: date, weight: avgWeight)
        }.sorted { $0.date < $1.date }
    }
    
    private var dateFormatForRange: Date.FormatStyle {
        switch selectedRange {
        case .sevenDay:
            return .dateTime.day()
        case .allTime:
            return .dateTime.month(.abbreviated).year()
        }
    }

    private var xAxisStride: Calendar.Component {
        switch selectedRange {
        case .sevenDay:
            return .day
        case .allTime:
            return .month
        }
    }
    
    // Add prediction calculation
    private var prediction: (date: Date, weight: Double)? {
        guard filteredEntries.count >= 2 else { return nil }
        
        let xValues = filteredEntries.map { $0.date.timeIntervalSince1970 }
        let yValues = filteredEntries.map { convertWeight($0.weightValue) }
        
        // Calculate linear regression
        let n = Double(xValues.count)
        let sumX = xValues.reduce(0, +)
        let sumY = yValues.reduce(0, +)
        let sumXY = zip(xValues, yValues).map(*).reduce(0, +)
        let sumXX = xValues.map { $0 * $0 }.reduce(0, +)
        
        let slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX)
        let intercept = (sumY - slope * sumX) / n
        
        // Predict next day
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let tomorrowInterval = tomorrow.timeIntervalSince1970
        let predictedWeight = slope * tomorrowInterval + intercept
        
        return (tomorrow, predictedWeight)
    }
    
    private struct ChartEntry: Identifiable {
        let id = UUID()
        let date: Date
        let weight: Double
        let isPrediction: Bool
        let showPoint: Bool
    }
    
    private var chartData: [ChartEntry] {
        var data = dailyAverages.map { ChartEntry(date: $0.date, weight: $0.weight, isPrediction: false, showPoint: true) }
        
        // Add prediction line if available
        if let prediction = prediction,
           let lastActual = dailyAverages.last {
            // Add the last actual point as part of prediction line but don't show its point
            data.append(ChartEntry(date: lastActual.date, weight: lastActual.weight, isPrediction: true, showPoint: false))
            // Add the prediction point and show it
            data.append(ChartEntry(date: prediction.date, weight: prediction.weight, isPrediction: true, showPoint: true))
        }
        
        return data
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
                
                // Draw prediction line first (in background)
                ForEach(chartData.filter { $0.isPrediction }) { entry in
                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("Weight", entry.weight)
                    )
                    .foregroundStyle(by: .value("Type", "Predicted"))
                }
                
                // Draw actual line second
                ForEach(chartData.filter { !$0.isPrediction }) { entry in
                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("Weight", entry.weight)
                    )
                    .foregroundStyle(by: .value("Type", "Actual"))
                }
                
                // Draw all points last (on top)
                ForEach(chartData) { entry in
                    if entry.showPoint {
                        PointMark(
                            x: .value("Date", entry.date),
                            y: .value("Weight", entry.weight)
                        )
                        .foregroundStyle(by: .value("Type", entry.isPrediction ? "Predicted" : "Actual"))
                    }
                }
            }
            .chartForegroundStyleScale([
                "Actual": Color.blue,
                "Predicted": Color.orange
            ])
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
            .animation(.easeInOut, value: selectedRange)
            .padding(.bottom)
        }
        .padding(.horizontal)
    }
}

private struct DailyAverage: Identifiable {
    let id = UUID()
    let date: Date
    let weight: Double
}

#Preview {
    WeightTrendChartView(entries: WeightEntry.sortedSampleData, goalWeight: 160.0, weightUnit: .lb, selectedRange: .sevenDay)
        .padding()
}
