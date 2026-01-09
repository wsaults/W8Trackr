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
    let showSmoothing: Bool
    
    private var filteredEntries: [WeightEntry] {
        guard let days = selectedRange.days else { return entries }
        
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return entries.filter { $0.date >= cutoffDate }
    }
    
    private func convertWeight(_ weight: Double) -> Double {
        WeightUnit.lb.convert(weight, to: weightUnit)
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
        guard let _ = filteredEntries.max(by: { $0.date < $1.date }) else {
            return []
        }

        return entriesByDay.map { date, entries in
            let avgWeight = entries.reduce(0.0) { $0 + $1.weightValue } / Double(entries.count)
            return DailyAverage(date: date, weight: convertWeight(avgWeight))
        }
        .sorted { $0.date < $1.date }
    }

    // Calculate smoothed trend using exponential moving average
    private var smoothedTrend: [TrendPoint] {
        TrendCalculator.exponentialMovingAverage(
            entries: filteredEntries,
            span: 10,
            convertWeight: convertWeight
        )
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
    
    // Improved prediction calculation: recentered days-based regression
    private var prediction: (date: Date, weight: Double)? {
        let sorted = filteredEntries.sorted { $0.date < $1.date }
        guard sorted.count >= 2 else { return nil }

        // Require a minimum span of one hour between first and last entry
        guard let firstDate = sorted.first?.date,
              let lastDate = sorted.last?.date,
              lastDate.timeIntervalSince(firstDate) >= 3600 else {
            return nil
        }

        // Convert timestamps to days since first entry
        let firstTime = firstDate.timeIntervalSince1970
        let xs = sorted.map { ($0.date.timeIntervalSince1970 - firstTime) / 86400.0 }
        let ys = sorted.map { convertWeight($0.weightValue) }

        // Calculate regression sums
        let n = Double(xs.count)
        let sumX  = xs.reduce(0, +)
        let sumY  = ys.reduce(0, +)
        let sumXX = xs.reduce(0) { $0 + $1 * $1 }
        let sumXY = zip(xs, ys).reduce(0) { $0 + $1.0 * $1.1 }

        let denom = n * sumXX - sumX * sumX
        guard denom != 0 else { return nil }

        let slope     = (n * sumXY - sumX * sumY) / denom      // weight change per day
        let intercept = (sumY - slope * sumX) / n               // starting weight

        // Predict 1 day ahead (adjustable via `daysAhead`)
        let daysAhead = 1.0
        guard let lastX = xs.last else { return nil }
        let futureX = lastX + daysAhead
        let predictedWeight = slope * futureX + intercept

        guard let predictedDate = Calendar.current.date(
            byAdding: .day, value: Int(daysAhead),
            to: lastDate
        ) else { return nil }

        return (predictedDate, predictedWeight)
    }
    
    private struct ChartEntry: Identifiable {
        let id = UUID()
        let date: Date
        let weight: Double
        let isPrediction: Bool
        let showPoint: Bool
        let isIndividualEntry: Bool
        let isSmoothed: Bool
    }
    
    private var chartData: [ChartEntry] {
        // Get all entries sorted by date
        let sortedEntries = filteredEntries.sorted { $0.date < $1.date }

        var data: [ChartEntry] = []

        // Add daily averages for the trend line (when smoothing is off)
        if !showSmoothing {
            data.append(contentsOf: dailyAverages.map {
                ChartEntry(
                    date: $0.date,
                    weight: $0.weight,
                    isPrediction: false,
                    showPoint: false,
                    isIndividualEntry: false,
                    isSmoothed: false
                )
            })

            // Add the last actual point to both the trend line and individual points
            if let lastEntry = sortedEntries.last {
                data.append(ChartEntry(
                    date: lastEntry.date,
                    weight: convertWeight(lastEntry.weightValue),
                    isPrediction: false,
                    showPoint: false,
                    isIndividualEntry: false,
                    isSmoothed: false
                ))
            }
        }

        // Add smoothed trend line (when smoothing is on)
        if showSmoothing {
            data.append(contentsOf: smoothedTrend.map { point in
                ChartEntry(
                    date: point.date,
                    weight: point.weight,
                    isPrediction: false,
                    showPoint: false,
                    isIndividualEntry: false,
                    isSmoothed: true
                )
            })
        }

        // Add all individual points
        data.append(contentsOf: sortedEntries.map { entry in
            ChartEntry(
                date: entry.date,
                weight: convertWeight(entry.weightValue),
                isPrediction: false,
                showPoint: true,
                isIndividualEntry: true,
                isSmoothed: false
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
                isIndividualEntry: false,
                isSmoothed: false
            ))
            // Add the prediction point
            data.append(ChartEntry(
                date: prediction.date,
                weight: prediction.weight,
                isPrediction: true,
                showPoint: false,
                isIndividualEntry: false,
                isSmoothed: false
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

                // Draw smoothed trend line (when smoothing is on)
                ForEach(chartData.filter { $0.isSmoothed }) { entry in
                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("Weight", entry.weight)
                    )
                    .foregroundStyle(by: .value("Type", "Trend"))
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                }

                // Draw actual daily average line (when smoothing is off)
                ForEach(chartData.filter { !$0.isPrediction && !$0.isIndividualEntry && !$0.isSmoothed }) { entry in
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
                "Trend": Color.purple,
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

#Preview("Without Smoothing") {
    WeightTrendChartView(entries: WeightEntry.sortedSampleData, goalWeight: 160.0, weightUnit: .lb, selectedRange: .sevenDay, showSmoothing: false)
        .padding()
}

#Preview("With Smoothing") {
    WeightTrendChartView(entries: WeightEntry.sortedSampleData, goalWeight: 160.0, weightUnit: .lb, selectedRange: .sevenDay, showSmoothing: true)
        .padding()
}
