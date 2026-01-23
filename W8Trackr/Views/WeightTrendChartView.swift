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

    @State private var scrollPosition: Date = Date()
    @State private var selectedDate: Date?

    private var initialScrollPosition: Date {
        guard let mostRecentDate = entries.max(by: { $0.date < $1.date })?.date else {
            return Date()
        }
        // Offset backward so recent entries appear on the right side of the viewport
        // This positions the most recent entry ~80% across the visible domain
        let offsetSeconds = visibleDomainSeconds * 0.8
        return mostRecentDate.addingTimeInterval(-offsetSeconds)
    }

    private var chartDateDomain: ClosedRange<Date> {
        guard let firstDate = entries.min(by: { $0.date < $1.date })?.date,
              let lastDate = entries.max(by: { $0.date < $1.date })?.date else {
            return Date()...Date()
        }
        // Extend to include 14-day prediction
        let predictionEnd = Calendar.current.date(byAdding: .day, value: 14, to: lastDate) ?? lastDate
        return firstDate...predictionEnd
    }

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

    /// Entries currently visible in the scroll viewport
    private var visibleEntries: [WeightEntry] {
        let visibleEnd = scrollPosition.addingTimeInterval(visibleDomainSeconds)
        return entries.filter { $0.date >= scrollPosition && $0.date <= visibleEnd }
    }

    /// Smoothed trend points currently visible in the scroll viewport
    private var visibleTrendPoints: [TrendPoint] {
        let visibleEnd = scrollPosition.addingTimeInterval(visibleDomainSeconds)
        return smoothedTrend.filter { $0.date >= scrollPosition && $0.date <= visibleEnd }
    }

    /// Fallback weight range when no data is visible (e.g., scrolled into prediction area)
    private var fallbackWeightRange: (min: Double, max: Double) {
        // Use the most recent entry as fallback
        if let lastEntry = entries.max(by: { $0.date < $1.date }) {
            let weight = lastEntry.weightValue(in: weightUnit)
            return (weight - yAxisPadding, weight + yAxisPadding)
        }
        return (0, 100) // Ultimate fallback
    }

    private var minWeight: Double {
        // Use visible entries for dynamic Y-axis as user scrolls
        // Goal line is drawn but doesn't affect viewport bounds
        let entryWeights = visibleEntries.map { $0.weightValue(in: weightUnit) }
        let trendWeights = visibleTrendPoints.map { $0.smoothedWeight(in: weightUnit) }
        let allWeights = entryWeights + trendWeights

        // Fall back to last known weight if scrolled past all data
        guard let minVal = allWeights.min() else {
            return fallbackWeightRange.min
        }
        return minVal - yAxisPadding
    }

    private var maxWeight: Double {
        // Use visible entries for dynamic Y-axis as user scrolls
        // Goal line is drawn but doesn't affect viewport bounds
        let entryWeights = visibleEntries.map { $0.weightValue(in: weightUnit) }
        let trendWeights = visibleTrendPoints.map { $0.smoothedWeight(in: weightUnit) }
        let allWeights = entryWeights + trendWeights

        // Fall back to last known weight if scrolled past all data
        guard let maxVal = allWeights.max() else {
            return fallbackWeightRange.max
        }
        return maxVal + yAxisPadding
    }
    
    // Calculate smoothed trend using exponential moving average
    // Uses ALL entries for consistent trendline across scroll positions
    private var smoothedTrend: [TrendPoint] {
        TrendCalculator.exponentialMovingAverage(
            entries: entries,
            span: 10
        )
    }
    
    private var dateFormatForRange: Date.FormatStyle {
        switch selectedRange {
        case .oneWeek:
            return .dateTime.day()
        case .oneMonth, .threeMonth, .sixMonth, .oneYear:
            return .dateTime.month(.abbreviated)
        case .allTime:
            return .dateTime.month(.abbreviated).year()
        }
    }

    private var xAxisStride: Calendar.Component {
        switch selectedRange {
        case .oneWeek:
            return .day
        case .oneMonth:
            return .weekOfYear
        case .threeMonth, .sixMonth:
            return .month
        case .oneYear, .allTime:
            return .month
        }
    }

    private var visibleDomainSeconds: TimeInterval {
        let days: Double
        switch selectedRange {
        case .oneWeek:
            days = 10
        case .oneMonth:
            days = 35
        case .threeMonth:
            days = 45
        case .sixMonth:
            days = 60
        case .oneYear:
            days = 90
        case .allTime:
            days = 120
        }
        return days * 86400 // seconds per day
    }

    private var selectedEntry: ChartEntry? {
        guard let selected = selectedDate else { return nil }
        return chartData
            .filter { !$0.isPrediction && $0.showPoint }
            .min(by: { abs($0.date.timeIntervalSince(selected)) < abs($1.date.timeIntervalSince(selected)) })
    }

    // Holt's Double Exponential Smoothing prediction
    // Generates prediction points anchored to trendline endpoint
    private var predictionPoints: [ChartEntry] {
        guard let holtResult = TrendCalculator.calculateHolt(entries: entries) else {
            return []
        }

        // Use last smoothed point for visual continuity with trendline
        let lastSmoothed = smoothedTrend.last
        let startWeight = lastSmoothed?.smoothedWeight ?? holtResult.level
        let startDate = lastSmoothed?.date ?? holtResult.lastDate

        var points: [ChartEntry] = []

        // Starting point anchored to trendline endpoint
        points.append(ChartEntry(
            date: startDate,
            weight: convertWeight(startWeight),
            isPrediction: true,
            showPoint: false,
            isIndividualEntry: false,
            isSmoothed: false
        ))

        // Future points using Holt's trend slope from smoothed endpoint
        for daysAhead in [7, 14] {
            guard let futureDate = Calendar.current.date(
                byAdding: .day, value: daysAhead, to: startDate
            ) else { continue }

            let futureWeight = convertWeight(startWeight + Double(daysAhead) * holtResult.trend)

            points.append(ChartEntry(
                date: futureDate,
                weight: futureWeight,
                isPrediction: true,
                showPoint: false,
                isIndividualEntry: false,
                isSmoothed: false
            ))
        }

        return points
    }
    
    private struct ChartEntry: Identifiable {
        var id: String {
            let timestamp = Int(date.timeIntervalSince1970)
            if isSmoothed {
                return "smoothed-\(timestamp)"
            } else if isPrediction {
                return "prediction-\(timestamp)"
            } else {
                return "entry-\(timestamp)"
            }
        }

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
        let latestWeight = sorted.last!.weightValue(in: weightUnit)
        let formattedLatest = latestWeight.formatted(.number.precision(.fractionLength(1)))

        var summary = "Weight trend chart showing \(count) \(count == 1 ? "entry" : "entries"). "
        summary += "Most recent weight: \(formattedLatest) \(weightUnit.displayName). "

        if sorted.count >= 2 {
            let firstWeight = sorted.first!.weightValue(in: weightUnit)
            let change = latestWeight - firstWeight
            let changeFormatted = abs(change).formatted(.number.precision(.fractionLength(1)))
            let direction = change > 0 ? "gained" : (change < 0 ? "lost" : "maintained")

            if change != 0 {
                summary += "You have \(direction) \(changeFormatted) \(weightUnit.displayName) over this period. "
            }
        }

        if goalWeight > 0 {
            let remaining = latestWeight - goalWeight
            let remainingFormatted = abs(remaining).formatted(.number.precision(.fractionLength(1)))
            if remaining > 0 {
                summary += "Goal weight: \(goalWeight.formatted(.number.precision(.fractionLength(1)))) \(weightUnit.displayName), \(remainingFormatted) \(weightUnit.displayName) to go."
            } else if remaining < 0 {
                summary += "You are \(remainingFormatted) \(weightUnit.displayName) below your goal of \(goalWeight.formatted(.number.precision(.fractionLength(1)))) \(weightUnit.displayName)."
            } else {
                summary += "You have reached your goal weight!"
            }
        }

        return summary
    }

    private var chartData: [ChartEntry] {
        // Get ALL entries sorted by date for full historical scrolling
        let sortedEntries = entries.sorted { $0.date < $1.date }

        var data: [ChartEntry] = []

        // Add smoothed trend line (when smoothing is on)
        // Uses EWMA-smoothed TrendPoints instead of simple daily averages
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
                weight: entry.weightValue(in: weightUnit),
                isPrediction: false,
                showPoint: true,
                isIndividualEntry: true,
                isSmoothed: false
            )
        })

        // Add prediction points (14-day forecast)
        data.append(contentsOf: predictionPoints)

        return data
    }

    @ViewBuilder
    private var selectionDisplay: some View {
        if let entry = selectedEntry {
            HStack {
                Text(entry.date, format: .dateTime.month().day())
                Spacer()
                Text("\(entry.weight, format: .number.precision(.fractionLength(1))) \(weightUnit.displayName)")
                    .bold()
            }
            .font(.caption)
            .foregroundStyle(AppColors.textSecondary)
            .padding(.horizontal)
        }
    }

    var body: some View {
        VStack {
            selectionDisplay
            Chart {
                // Goal weight line remains the same
                if goalWeight > 0 {
                    RuleMark(y: .value("Goal Weight", goalWeight))
                        .foregroundStyle(AppColors.chartGoal.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [10, 5]))
                        .annotation(position: .overlay) {
                            Text("Goal: \(goalWeight, format: .number.precision(.fractionLength(1))) \(weightUnit.displayName)")
                                .font(.caption)
                                .foregroundStyle(AppColors.chartGoal)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
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
                    .interpolationMethod(.monotone)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                }

                // Draw prediction line
                ForEach(chartData.filter { $0.isPrediction }) { entry in
                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("Weight", entry.weight)
                    )
                    .foregroundStyle(by: .value("Type", "Predicted"))
                    .interpolationMethod(.monotone)
                }
                
                // Draw all points last
                ForEach(chartData.filter { $0.showPoint }) { entry in
                    PointMark(
                        x: .value("Date", entry.date),
                        y: .value("Weight", entry.weight)
                    )
                    .foregroundStyle(by: .value("Type", entry.isPrediction ? "Predicted" : (entry.isIndividualEntry ? "Entry" : "Average")))
                }

                // Selection indicator
                if let entry = selectedEntry {
                    RuleMark(x: .value("Selected", entry.date))
                        .foregroundStyle(AppColors.textSecondary.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1))

                    PointMark(
                        x: .value("Date", entry.date),
                        y: .value("Weight", entry.weight)
                    )
                    .symbol(.circle)
                    .symbolSize(100)
                    .foregroundStyle(AppColors.accent)
                }
            }
            .chartForegroundStyleScale([
                "Entry": AppColors.accent,
                "Trend": AppColors.chartTrend,
                "Predicted": AppColors.chartPredicted
            ])
            .chartYScale(domain: minWeight...maxWeight)
            .chartXScale(domain: chartDateDomain)
            .chartYAxis {
                AxisMarks(preset: .extended, position: .leading) { value in
                    AxisValueLabel {
                        if let weight = value.as(Double.self) {
                            Text("\(weight, format: .number.precision(.fractionLength(1))) \(weightUnit.displayName)")
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
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
            .chartScrollableAxes(.horizontal)
            .chartXVisibleDomain(length: visibleDomainSeconds)
            .chartScrollPosition(x: $scrollPosition)
            .chartXSelection(value: $selectedDate)
            .animation(.snappy, value: selectedRange)
            .animation(.easeInOut(duration: 0.15), value: scrollPosition)
            .padding(.bottom)
            .accessibilityChartDescriptor(self)
        }
        .padding(.horizontal)
        .onAppear {
            scrollPosition = initialScrollPosition
        }
    }
}

// MARK: - AXChartDescriptorRepresentable

// @preconcurrency suppresses Sendable warnings for Accessibility module
// AXChartDescriptorRepresentable is always called on main thread
extension WeightTrendChartView: @preconcurrency AXChartDescriptorRepresentable {
    func makeChartDescriptor() -> AXChartDescriptor {
        // Filter entries based on selected date range
        let filteredEntries: [WeightEntry]
        if let days = selectedRange.days {
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
            filteredEntries = entries.filter { $0.date >= cutoffDate }
        } else {
            filteredEntries = entries
        }

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

        // Compute weight range from sorted entries
        let weights = sorted.map { $0.weightValue(in: weightUnit) }
        let yAxisPadding = weightUnit == .kg ? 2.0 : 5.0
        let minWeightValue = (weights.min() ?? 0) - yAxisPadding
        let maxWeightValue = (weights.max() ?? 100) + yAxisPadding

        // Create weight axis
        let unit = weightUnit
        let weightAxis = AXNumericDataAxisDescriptor(
            title: "Weight (\(unit.displayName))",
            range: minWeightValue...maxWeightValue,
            gridlinePositions: []
        ) { value in
            "\(value.formatted(.number.precision(.fractionLength(1)))) \(unit.displayName)"
        }

        // Create data points
        let dataPoints = sorted.map { entry in
            AXDataPoint(
                x: entry.date.timeIntervalSince1970,
                y: entry.weightValue(in: unit),
                label: "\(entry.date.formatted(date: .abbreviated, time: .omitted)): \(entry.weightValue(in: unit).formatted(.number.precision(.fractionLength(1)))) \(unit.displayName)"
            )
        }

        let series = AXDataSeriesDescriptor(
            name: "Weight entries",
            isContinuous: true,
            dataPoints: dataPoints
        )

        // Compute accessibility summary inline
        let summary: String
        if let firstEntry = sorted.first, let lastEntry = sorted.last {
            let firstWeight = firstEntry.weightValue(in: unit)
            let lastWeight = lastEntry.weightValue(in: unit)
            let change = lastWeight - firstWeight

            let trend: String
            if change > 0.1 {
                trend = "increased"
            } else if change < -0.1 {
                trend = "decreased"
            } else {
                trend = "remained stable"
            }

            summary = "Weight \(trend) from \(firstWeight.formatted(.number.precision(.fractionLength(1)))) to \(lastWeight.formatted(.number.precision(.fractionLength(1)))) \(unit.displayName) over \(sorted.count) entries"
        } else {
            summary = "No weight data available"
        }

        return AXChartDescriptor(
            title: "Weight Trend",
            summary: summary,
            xAxis: dateAxis,
            yAxis: weightAxis,
            additionalAxes: [],
            series: [series]
        )
    }
}

#Preview("Without Smoothing") {
    WeightTrendChartView(entries: WeightEntry.sortedSampleData, goalWeight: 160.0, weightUnit: .lb, selectedRange: .oneWeek, showSmoothing: false)
        .padding()
}

#Preview("With Smoothing") {
    WeightTrendChartView(entries: WeightEntry.sortedSampleData, goalWeight: 160.0, weightUnit: .lb, selectedRange: .oneWeek, showSmoothing: true)
        .padding()
}
