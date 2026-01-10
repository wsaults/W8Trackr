//
//  WeightTrendChartView.swift
//  W8Trackr
//
//  Created by Will Saults on 4/28/25.
//

import Accessibility
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
        guard filteredEntries.max(by: { $0.date < $1.date }) != nil else {
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
            span: 10
        )
    }
    
    private var dateFormatForRange: Date.FormatStyle {
        switch selectedRange {
        case .sevenDay:
            return .dateTime.day()
        case .thirtyDay, .ninetyDay:
            return .dateTime.day().month(.abbreviated)
        case .oneEightyDay, .oneYear:
            return .dateTime.month(.abbreviated)
        case .allTime:
            return .dateTime.month(.abbreviated).year()
        }
    }

    private var xAxisStride: Calendar.Component {
        switch selectedRange {
        case .sevenDay:
            return .day
        case .thirtyDay:
            return .weekOfYear
        case .ninetyDay, .oneEightyDay:
            return .month
        case .oneYear, .allTime:
            return .month
        }
    }
    
    // Holt's Double Exponential Smoothing prediction
    // Returns start point (last smoothed value) and end point (forecast)
    private var prediction: (startDate: Date, startWeight: Double, endDate: Date, endWeight: Double)? {
        guard let holtResult = TrendCalculator.calculateHolt(entries: filteredEntries) else {
            return nil
        }

        let daysAhead = 1
        let predictedWeight = holtResult.forecast(daysAhead: daysAhead)

        guard let predictedDate = Calendar.current.date(
            byAdding: .day, value: daysAhead, to: holtResult.lastDate
        ) else { return nil }

        return (
            startDate: holtResult.lastDate,
            startWeight: convertWeight(holtResult.level),
            endDate: predictedDate,
            endWeight: convertWeight(predictedWeight)
        )
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

    // MARK: - Accessibility

    private var chartAccessibilitySummary: String {
        let sorted = filteredEntries.sorted { $0.date < $1.date }
        guard !sorted.isEmpty else {
            return "No weight data available"
        }

        let count = sorted.count
        let latestWeight = convertWeight(sorted.last!.weightValue)
        let formattedLatest = latestWeight.formatted(.number.precision(.fractionLength(1)))

        var summary = "Weight trend chart showing \(count) \(count == 1 ? "entry" : "entries"). "
        summary += "Most recent weight: \(formattedLatest) \(weightUnit.rawValue). "

        if sorted.count >= 2 {
            let firstWeight = convertWeight(sorted.first!.weightValue)
            let change = latestWeight - firstWeight
            let changeFormatted = abs(change).formatted(.number.precision(.fractionLength(1)))
            let direction = change > 0 ? "gained" : (change < 0 ? "lost" : "maintained")

            if change != 0 {
                summary += "You have \(direction) \(changeFormatted) \(weightUnit.rawValue) over this period. "
            }
        }

        if goalWeight > 0 {
            let remaining = latestWeight - goalWeight
            let remainingFormatted = abs(remaining).formatted(.number.precision(.fractionLength(1)))
            if remaining > 0 {
                summary += "Goal weight: \(goalWeight.formatted(.number.precision(.fractionLength(1)))) \(weightUnit.rawValue), \(remainingFormatted) \(weightUnit.rawValue) to go."
            } else if remaining < 0 {
                summary += "You are \(remainingFormatted) \(weightUnit.rawValue) below your goal of \(goalWeight.formatted(.number.precision(.fractionLength(1)))) \(weightUnit.rawValue)."
            } else {
                summary += "You have reached your goal weight!"
            }
        }

        return summary
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
                    weight: point.smoothedWeight(in: weightUnit),
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

        // Add prediction line if available (starts from last smoothed value)
        if let prediction = prediction {
            // Add the last smoothed point as start of prediction line
            data.append(ChartEntry(
                date: prediction.startDate,
                weight: prediction.startWeight,
                isPrediction: true,
                showPoint: false,
                isIndividualEntry: false,
                isSmoothed: false
            ))
            // Add the predicted point
            data.append(ChartEntry(
                date: prediction.endDate,
                weight: prediction.endWeight,
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
                AxisMarks(values: .stride(by: xAxisStride)) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: dateFormatForRange)
                }
            }
            .animation(.easeInOut, value: selectedRange)
            .padding(.bottom)
            .accessibilityChartDescriptor(self)
        }
        .padding(.horizontal)
    }
}

// MARK: - AXChartDescriptorRepresentable

extension WeightTrendChartView: AXChartDescriptorRepresentable {
    func makeChartDescriptor() -> AXChartDescriptor {
        let sorted = filteredEntries.sorted { $0.date < $1.date }

        // Create date axis
        let minDate = sorted.first?.date ?? Date()
        let maxDate = sorted.last?.date ?? Date()

        let dateAxis = AXNumericDataAxisDescriptor(
            title: "Date",
            range: minDate.timeIntervalSince1970...maxDate.timeIntervalSince1970,
            gridlinePositions: []
        ) { value in
            let date = Date(timeIntervalSince1970: value)
            return date.formatted(date: .abbreviated, time: .omitted)
        }

        // Create weight axis
        let weightAxis = AXNumericDataAxisDescriptor(
            title: "Weight (\(weightUnit.rawValue))",
            range: minWeight...maxWeight,
            gridlinePositions: []
        ) { value in
            "\(value.formatted(.number.precision(.fractionLength(1)))) \(self.weightUnit.rawValue)"
        }

        // Create data points
        let dataPoints = sorted.map { entry in
            AXDataPoint(
                x: entry.date.timeIntervalSince1970,
                y: convertWeight(entry.weightValue),
                label: "\(entry.date.formatted(date: .abbreviated, time: .omitted)): \(convertWeight(entry.weightValue).formatted(.number.precision(.fractionLength(1)))) \(weightUnit.rawValue)"
            )
        }

        let series = AXDataSeriesDescriptor(
            name: "Weight entries",
            isContinuous: true,
            dataPoints: dataPoints
        )

        return AXChartDescriptor(
            title: "Weight Trend",
            summary: chartAccessibilitySummary,
            xAxis: dateAxis,
            yAxis: weightAxis,
            additionalAxes: [],
            series: [series]
        )
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
