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
        // Get all days including the latest entry
        let allDays = entriesByDay.map { $0.key }
        guard let latestEntry = filteredEntries.max(by: { $0.date < $1.date }) else {
            return []
        }

        return entriesByDay.map { date, entries in
            let avgWeight = entries.reduce(0.0) { $0 + $1.weightValue } / Double(entries.count)
            return DailyAverage(date: date, weight: convertWeight(avgWeight))
        }
        .sorted { $0.date < $1.date }
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
    
    // Update prediction calculation
    private var prediction: (date: Date, weight: Double)? {
        guard filteredEntries.count >= 2 else { return nil }
        
        // Get the dates sorted
        let sortedEntries = filteredEntries.sorted { $0.date < $1.date }
        
        // Check if entries span at least 2 days
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: sortedEntries.first?.date ?? Date())
        let endDate = calendar.startOfDay(for: sortedEntries.last?.date ?? Date())
        
        guard calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0 >= 1 else {
            return nil
        }
        
        let xValues = sortedEntries.map { $0.date.timeIntervalSince1970 }
        let yValues = sortedEntries.map { convertWeight($0.weightValue) }
        
        // Calculate linear regression
        let n = Double(xValues.count)
        let sumX = xValues.reduce(0, +)
        let sumY = yValues.reduce(0, +)
        let sumXY = zip(xValues, yValues).map(*).reduce(0, +)
        let sumXX = xValues.map { $0 * $0 }.reduce(0, +)
        
        let slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX)
        let intercept = (sumY - slope * sumX) / n
        
        // Predict next day
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: sortedEntries.last?.date ?? Date()) ?? Date()
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
        let isIndividualEntry: Bool
    }
    
    private var chartData: [ChartEntry] {
        // Get all entries sorted by date
        let sortedEntries = filteredEntries.sorted { $0.date < $1.date }
        
        var data: [ChartEntry] = []
        
        // Add daily averages for the trend line first
        data.append(contentsOf: dailyAverages.map {
            ChartEntry(
                date: $0.date,
                weight: $0.weight,
                isPrediction: false,
                showPoint: false,
                isIndividualEntry: false
            )
        })
        
        // Add the last actual point to both the trend line and individual points
        if let lastEntry = sortedEntries.last {
            data.append(ChartEntry(
                date: lastEntry.date,
                weight: convertWeight(lastEntry.weightValue),
                isPrediction: false,
                showPoint: false,
                isIndividualEntry: false
            ))
        }
        
        // Add all individual points
        data.append(contentsOf: sortedEntries.map { entry in
            ChartEntry(
                date: entry.date,
                weight: convertWeight(entry.weightValue),
                isPrediction: false,
                showPoint: true,
                isIndividualEntry: true
            )
        })
        
        // Add prediction line if available
        if let prediction = prediction,
           let lastEntry = sortedEntries.last {
            // Add the last actual point as part of prediction line
            data.append(ChartEntry(
                date: lastEntry.date,
                weight: convertWeight(lastEntry.weightValue),
                isPrediction: true,
                showPoint: false,
                isIndividualEntry: false
            ))
            // Add the prediction point
            data.append(ChartEntry(
                date: prediction.date,
                weight: prediction.weight,
                isPrediction: true,
                showPoint: false,
                isIndividualEntry: false
            ))
        }
        
        return data
    }
    
    var body: some View {
        VStack {
            Chart {
                // Goal weight line remains the same
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

                // Draw actual trend line first
                ForEach(chartData.filter { !$0.isPrediction && !$0.isIndividualEntry }) { entry in
                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("Weight", entry.weight)
                    )
                    .foregroundStyle(by: .value("Type", "Average"))
                    .interpolationMethod(.catmullRom)
                }
                
                // Draw prediction line
                ForEach(chartData.filter { $0.isPrediction }) { entry in
                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("Weight", entry.weight)
                    )
                    .foregroundStyle(by: .value("Type", "Predicted"))
                    .interpolationMethod(.catmullRom)
                }
                
                // Draw all points last
                ForEach(chartData.filter { $0.showPoint }) { entry in
                    PointMark(
                        x: .value("Date", entry.date),
                        y: .value("Weight", entry.weight)
                    )
                    .foregroundStyle(by: .value("Type", entry.isPrediction ? "Predicted" : (entry.isIndividualEntry ? "Entry" : "Average")))
                }
            }
            .chartForegroundStyleScale([
                "Entry": Color.blue,
                "Average": Color.blue.opacity(0.5),
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
