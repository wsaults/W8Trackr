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

    /// Currently selected entry for tap overlay display
    @State private var selectedEntry: WeightEntry?
    /// X position for the selection indicator line
    @State private var selectionX: CGFloat?
    /// Current zoom scale (1.0 = no zoom, 2.0 = 2x zoom, etc.)
    @State private var zoomScale: CGFloat = 1.0
    /// Base zoom scale before current gesture
    @State private var baseZoomScale: CGFloat = 1.0

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
        case .thirtyDay:
            return .dateTime.day().month(.abbreviated)
        case .ninetyDay, .oneEightyDay:
            return .dateTime.month(.abbreviated)
        case .oneYear, .allTime:
            return .dateTime.month(.abbreviated).year()
        }
    }

    private var xAxisStride: Calendar.Component {
        switch selectedRange {
        case .sevenDay:
            return .day
        case .thirtyDay:
            return .weekOfYear
        case .ninetyDay:
            return .weekOfYear
        case .oneEightyDay:
            return .month
        case .oneYear, .allTime:
            return .month
        }
    }

    // MARK: - Zoom Support

    /// Date range of filtered entries
    private var dateRange: (start: Date, end: Date)? {
        let sorted = filteredEntries.sorted { $0.date < $1.date }
        guard let first = sorted.first?.date, let last = sorted.last?.date else { return nil }
        return (first, last)
    }

    /// Visible domain length in seconds, adjusted for zoom
    private var visibleDomainLength: TimeInterval {
        guard let range = dateRange else { return 7 * 24 * 3600 }
        let totalDuration = range.end.timeIntervalSince(range.start)
        // Clamp zoom between 1x and 10x
        let clampedZoom = min(max(zoomScale, 1.0), 10.0)
        return totalDuration / clampedZoom
    }

    /// Whether chart is zoomed in
    private var isZoomed: Bool {
        zoomScale > 1.05
    }

    // MARK: - Weight Trend Prediction

    /// Calculates a 1-day weight prediction using Ordinary Least Squares (OLS) linear regression.
    ///
    /// ## Algorithm
    /// Uses simple linear regression to fit a line through historical weight data points,
    /// then extrapolates 1 day into the future. This provides a short-term trend indicator
    /// without overconfident long-range predictions.
    ///
    /// ## Mathematical Formula
    /// Given n data points (x₁, y₁), ..., (xₙ, yₙ) where:
    /// - x = days since first entry (normalized for numerical stability)
    /// - y = weight in user's preferred unit
    ///
    /// The regression line y = mx + b is calculated as:
    /// ```
    /// slope (m)     = (n∑xy - ∑x∑y) / (n∑x² - (∑x)²)
    /// intercept (b) = (∑y - m∑x) / n
    /// ```
    ///
    /// Prediction: y_future = m × (x_last + 1) + b
    ///
    /// ## Input Requirements
    /// - **Minimum entries**: 2 (required for regression line)
    /// - **Minimum time span**: 1 hour between first and last entry
    /// - **Data source**: `filteredEntries` (respects current date range filter)
    ///
    /// ## Output
    /// Returns a tuple of (predictedDate, predictedWeight) or nil if prediction is not possible.
    /// - `predictedDate`: 1 day after the most recent entry
    /// - `predictedWeight`: Extrapolated weight in user's preferred unit
    ///
    /// ## Edge Cases Handled
    /// - Returns `nil` if fewer than 2 entries exist
    /// - Returns `nil` if time span is less than 1 hour (prevents unstable predictions)
    /// - Returns `nil` if denominator is zero (all entries on same day, or numerical edge case)
    /// - Returns `nil` if date calculation fails
    ///
    /// ## Confidence Considerations
    /// This is a simple linear model with inherent limitations:
    /// - **No confidence interval**: Does not account for data variance or prediction uncertainty
    /// - **Assumes linearity**: Weight loss/gain is rarely perfectly linear over time
    /// - **Short horizon**: Only predicts 1 day ahead to minimize extrapolation error
    /// - **Sensitive to outliers**: A single unusual reading can skew the prediction
    /// - **No plateau detection**: Cannot detect weight loss stalls or rebounds
    ///
    /// For production use, consider R² calculation or prediction intervals for confidence indication.
    private var prediction: (date: Date, weight: Double)? {
        let sorted = filteredEntries.sorted { $0.date < $1.date }
        guard sorted.count >= 2 else { return nil }

        // Require a minimum span of one hour between first and last entry
        // This prevents unstable predictions from entries clustered in a short time
        guard let firstDate = sorted.first?.date,
              let lastDate = sorted.last?.date,
              lastDate.timeIntervalSince(firstDate) >= 3600 else {
            return nil
        }

        // Convert timestamps to days since first entry (recentering improves numerical stability)
        let firstTime = firstDate.timeIntervalSince1970
        let xs = sorted.map { ($0.date.timeIntervalSince1970 - firstTime) / 86400.0 }
        let ys = sorted.map { convertWeight($0.weightValue) }

        // Calculate regression sums for OLS formula
        let n = Double(xs.count)
        let sumX  = xs.reduce(0, +)                              // ∑x
        let sumY  = ys.reduce(0, +)                              // ∑y
        let sumXX = xs.reduce(0) { $0 + $1 * $1 }                // ∑x²
        let sumXY = zip(xs, ys).reduce(0) { $0 + $1.0 * $1.1 }   // ∑xy

        // Denominator of slope formula: n∑x² - (∑x)²
        // Zero denominator occurs when all x values are identical (division by zero)
        let denom = n * sumXX - sumX * sumX
        guard denom != 0 else { return nil }

        // OLS coefficients
        let slope     = (n * sumXY - sumX * sumY) / denom      // weight change per day
        let intercept = (sumY - slope * sumX) / n               // y-intercept (adjusted for recentering)

        // Predict 1 day ahead from the last data point
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
                // Selection indicator line
                if let entry = selectedEntry {
                    RuleMark(x: .value("Selected", entry.date))
                        .foregroundStyle(.gray.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                }

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
            .chartScrollableAxes(isZoomed ? .horizontal : [])
            .chartXVisibleDomain(length: visibleDomainLength)
            .animation(.easeInOut, value: selectedRange)
            .padding(.bottom)
            .accessibilityChartDescriptor(self)
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            MagnificationGesture()
                                .onChanged { scale in
                                    zoomScale = baseZoomScale * scale
                                }
                                .onEnded { scale in
                                    baseZoomScale = min(max(baseZoomScale * scale, 1.0), 10.0)
                                    zoomScale = baseZoomScale
                                }
                        )
                        .simultaneousGesture(
                            TapGesture()
                                .onEnded { _ in
                                    // Handled by onTapGesture below
                                }
                        )
                        .onTapGesture { location in
                            handleChartInteraction(at: location, proxy: proxy, geometry: geometry)
                        }
                        .onLongPressGesture(minimumDuration: 0.3) {
                            // Reset zoom on long press
                            withAnimation(.easeOut(duration: 0.2)) {
                                zoomScale = 1.0
                                baseZoomScale = 1.0
                            }
                        }
                }
            }

            // Selection overlay callout
            if let entry = selectedEntry {
                SelectionCallout(
                    entry: entry,
                    weightUnit: weightUnit,
                    onDismiss: { selectedEntry = nil }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }

            // Zoom indicator
            if isZoomed {
                HStack {
                    Spacer()
                    Text("\(zoomScale, format: .number.precision(.fractionLength(1)))×")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                .padding(.trailing, 8)
            }
        }
        .padding(.horizontal)
        .animation(.easeOut(duration: 0.15), value: selectedEntry?.id)
        .onChange(of: selectedRange) { _, _ in
            // Reset zoom when changing date range
            zoomScale = 1.0
            baseZoomScale = 1.0
            selectedEntry = nil
        }
    }

    /// Finds the nearest entry to a touch point on the chart
    private func handleChartInteraction(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        let plotFrame = geometry[proxy.plotFrame!]
        let xPosition = location.x - plotFrame.origin.x

        guard let date: Date = proxy.value(atX: xPosition) else { return }

        // Find the closest entry to the tapped date
        let sorted = filteredEntries.sorted { $0.date < $1.date }
        guard !sorted.isEmpty else { return }

        let closest = sorted.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
        selectedEntry = closest
        selectionX = xPosition
    }
}

/// Callout view showing selected entry details
private struct SelectionCallout: View {
    let entry: WeightEntry
    let weightUnit: WeightUnit
    let onDismiss: () -> Void

    private var formattedWeight: String {
        let weight = entry.weightValue(in: weightUnit)
        return weight.formatted(.number.precision(.fractionLength(1)))
    }

    private var formattedDate: String {
        entry.date.formatted(date: .abbreviated, time: .shortened)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(formattedWeight) \(weightUnit.rawValue)")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let note = entry.note, !note.isEmpty {
                    Text(note)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss")
            .accessibilityHint("Close the weight details popup")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Selected weight: \(formattedWeight) \(weightUnit.rawValue), recorded \(formattedDate)")
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

// MARK: - Previews

#if DEBUG
@available(iOS 18, macOS 15, *)
#Preview("7 Day Range", traits: .modifier(EntriesPreview())) {
    WeightTrendChartView(
        entries: WeightEntry.sortedSampleData,
        goalWeight: 160.0,
        weightUnit: .lb,
        selectedRange: .sevenDay,
        showSmoothing: true
    )
    .frame(height: 300)
    .padding()
}

@available(iOS 18, macOS 15, *)
#Preview("All Time Range", traits: .modifier(EntriesPreview())) {
    WeightTrendChartView(
        entries: WeightEntry.sortedSampleData,
        goalWeight: 160.0,
        weightUnit: .lb,
        selectedRange: .allTime,
        showSmoothing: true
    )
    .frame(height: 300)
    .padding()
}

@available(iOS 18, macOS 15, *)
#Preview("Minimal Data (3 entries)", traits: .modifier(MinimalEntriesPreview())) {
    let calendar = Calendar.current
    let today = Date()
    let minimalEntries = [
        WeightEntry(weight: 175.0, date: today),
        WeightEntry(weight: 176.5, date: calendar.date(byAdding: .day, value: -2, to: today)!),
        WeightEntry(weight: 178.0, date: calendar.date(byAdding: .day, value: -5, to: today)!)
    ]

    WeightTrendChartView(
        entries: minimalEntries,
        goalWeight: 170.0,
        weightUnit: .lb,
        selectedRange: .sevenDay,
        showSmoothing: true
    )
    .frame(height: 300)
    .padding()
}

@available(iOS 18, macOS 15, *)
#Preview("Empty Data", traits: .modifier(EmptyEntriesPreview())) {
    WeightTrendChartView(
        entries: [],
        goalWeight: 160.0,
        weightUnit: .lb,
        selectedRange: .sevenDay,
        showSmoothing: true
    )
    .frame(height: 300)
    .padding()
}

@available(iOS 18, macOS 15, *)
#Preview("Metric (kg)", traits: .modifier(EntriesPreview())) {
    WeightTrendChartView(
        entries: WeightEntry.shortSampleData,
        goalWeight: 72.5,
        weightUnit: .kg,
        selectedRange: .sevenDay,
        showSmoothing: true
    )
    .frame(height: 300)
    .padding()
}

@available(iOS 18, macOS 15, *)
#Preview("No Smoothing", traits: .modifier(EntriesPreview())) {
    WeightTrendChartView(
        entries: WeightEntry.sortedSampleData,
        goalWeight: 160.0,
        weightUnit: .lb,
        selectedRange: .sevenDay,
        showSmoothing: false
    )
    .frame(height: 300)
    .padding()
}
#endif
