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

    // MARK: - Cached Chart Data
    // Recomputed only when entries/settings change — NOT on every scroll frame.
    // Previously, computed properties recalculated EMA trends and Y-axis bounds
    // on every frame during scrolling, causing jank.

    @State private var cachedData = PreparedChartData.empty
    @State private var cachedYMin: Double = 0
    @State private var cachedYMax: Double = 200

    /// Lightweight fingerprint of entry data for change detection.
    /// O(n) hash combining is far cheaper than rerunning EMA every scroll frame.
    private var dataFingerprint: Int {
        var hasher = Hasher()
        for entry in entries {
            hasher.combine(entry.weightValue)
            hasher.combine(entry.date)
        }
        return hasher.finalize()
    }

    private struct PreparedChartData {
        let smoothed: [ChartEntry]
        let predictions: [ChartEntry]
        let points: [ChartEntry]
        let dateDomain: ClosedRange<Date>

        static let empty = PreparedChartData(
            smoothed: [], predictions: [], points: [],
            dateDomain: Date()...Date()
        )
    }

    /// Recomputes all chart data and caches it in @State.
    /// Called on appear and when inputs change — never during scroll.
    private func recomputeChartData() {
        let sortedEntries = entries.sorted { $0.date < $1.date }

        let trend = TrendCalculator.exponentialMovingAverage(entries: entries, span: 10)

        var smoothed: [ChartEntry] = []
        if showSmoothing {
            smoothed = trend.map { point in
                ChartEntry(
                    date: point.date,
                    weight: point.smoothedWeight(in: weightUnit),
                    isPrediction: false,
                    showPoint: false,
                    isIndividualEntry: false,
                    isSmoothed: true
                )
            }
        }

        let points = sortedEntries.map { entry in
            ChartEntry(
                date: entry.date,
                weight: entry.weightValue(in: weightUnit),
                isPrediction: false,
                showPoint: true,
                isIndividualEntry: true,
                isSmoothed: false
            )
        }

        let predictions = makePredictionPoints(trend: trend)

        let dateDomain: ClosedRange<Date>
        if let firstDate = sortedEntries.first?.date,
           let lastDate = sortedEntries.last?.date {
            let predictionEnd = Calendar.current.date(byAdding: .day, value: 14, to: lastDate) ?? lastDate
            dateDomain = firstDate...predictionEnd
        } else {
            dateDomain = Date()...Date()
        }

        cachedData = PreparedChartData(
            smoothed: smoothed,
            predictions: predictions,
            points: points,
            dateDomain: dateDomain
        )

        // Stable Y-axis from ALL data, not just visible entries.
        // This eliminates per-frame Y-axis domain changes that forced full chart re-layouts.
        let allWeights = points.map(\.weight) + smoothed.map(\.weight) + predictions.map(\.weight)
        if let minVal = allWeights.min(), let maxVal = allWeights.max() {
            cachedYMin = minVal - yAxisPadding
            cachedYMax = maxVal + yAxisPadding
        }
    }

    private var initialScrollPosition: Date {
        guard let mostRecentDate = entries.max(by: { $0.date < $1.date })?.date else {
            return Date()
        }
        // Offset backward so recent entries appear on the right side of the viewport
        let offsetSeconds = visibleDomainSeconds * 0.8
        return mostRecentDate.addingTimeInterval(-offsetSeconds)
    }

    private func convertWeight(_ weight: Double) -> Double {
        WeightUnit.lb.convert(weight, to: weightUnit)
    }

    private var yAxisPadding: Double {
        weightUnit == .kg ? 2.0 : 5.0
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
        return days * 86400
    }

    private var selectedEntry: ChartEntry? {
        guard let selected = selectedDate else { return nil }
        return cachedData.points
            .min(by: { abs($0.date.timeIntervalSince(selected)) < abs($1.date.timeIntervalSince(selected)) })
    }

    // Holt's Double Exponential Smoothing prediction
    // Generates prediction points anchored to trendline endpoint
    private func makePredictionPoints(trend: [TrendPoint]) -> [ChartEntry] {
        guard let holtResult = TrendCalculator.calculateHolt(entries: entries) else {
            return []
        }

        // Use last smoothed point for visual continuity with trendline
        let lastSmoothed = trend.last
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

    // MARK: - Views

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
                // Goal weight line
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

                // Smoothed trend line
                ForEach(cachedData.smoothed) { entry in
                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("Weight", entry.weight)
                    )
                    .foregroundStyle(by: .value("Type", "Trend"))
                    .interpolationMethod(.monotone)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                }

                // Prediction line
                ForEach(cachedData.predictions) { entry in
                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("Weight", entry.weight)
                    )
                    .foregroundStyle(by: .value("Type", "Predicted"))
                    .interpolationMethod(.monotone)
                }

                // Data points
                ForEach(cachedData.points) { entry in
                    PointMark(
                        x: .value("Date", entry.date),
                        y: .value("Weight", entry.weight)
                    )
                    .foregroundStyle(by: .value("Type", entry.isIndividualEntry ? "Entry" : "Average"))
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
            .chartYScale(domain: cachedYMin...cachedYMax)
            .chartXScale(domain: cachedData.dateDomain)
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
            .padding(.bottom)
            .accessibilityChartDescriptor(self)
        }
        .padding(.horizontal)
        .onAppear {
            recomputeChartData()
            scrollPosition = initialScrollPosition
        }
        .onChange(of: dataFingerprint) { _, _ in recomputeChartData() }
        .onChange(of: weightUnit) { _, _ in recomputeChartData() }
        .onChange(of: showSmoothing) { _, _ in recomputeChartData() }
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
