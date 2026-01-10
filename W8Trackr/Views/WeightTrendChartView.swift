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

    // MARK: - Memoized Data Processing
    // All computed properties reference these cached values to avoid redundant sorting/filtering

    /// Filtered entries based on selected date range
    private var filteredEntries: [WeightEntry] {
        guard let days = selectedRange.days else { return entries }
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return entries.filter { $0.date >= cutoffDate }
    }

    /// Single sorted source - all other properties should reference this instead of re-sorting
    private var sortedFilteredEntries: [WeightEntry] {
        filteredEntries.sorted { $0.date < $1.date }
    }

    private func convertWeight(_ weight: Double) -> Double {
        WeightUnit.lb.convert(weight, to: weightUnit)
    }

    private var yAxisPadding: Double {
        weightUnit == .kg ? 2.0 : 5.0
    }

    /// Single-pass computation of weight range for Y-axis bounds
    private var weightRange: (min: Double, max: Double) {
        guard !sortedFilteredEntries.isEmpty else {
            let goal = goalWeight > 0 ? goalWeight : 150.0
            return (goal - yAxisPadding, goal + yAxisPadding)
        }

        var minW = Double.infinity
        var maxW = -Double.infinity

        for entry in sortedFilteredEntries {
            let weight = convertWeight(entry.weightValue)
            minW = Swift.min(minW, weight)
            maxW = Swift.max(maxW, weight)
        }

        // Include goal weight in range
        if goalWeight > 0 {
            minW = Swift.min(minW, goalWeight)
            maxW = Swift.max(maxW, goalWeight)
        }

        return (minW - yAxisPadding, maxW + yAxisPadding)
    }

    private var minWeight: Double { weightRange.min }
    private var maxWeight: Double { weightRange.max }

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

    /// Date range of filtered entries (uses cached sorted entries)
    private var dateRange: (start: Date, end: Date)? {
        guard let first = sortedFilteredEntries.first?.date,
              let last = sortedFilteredEntries.last?.date else { return nil }
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

    // MARK: - Weight Trend Prediction (Holt's Double Exponential Smoothing)

    /// Holt's Double Exponential Smoothing prediction
    /// Returns start point (last smoothed value) and end point (forecast)
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
        let sorted = sortedFilteredEntries
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
        // Use cached sorted entries
        let sortedEntries = sortedFilteredEntries

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
                "Trend": Color.blue,
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

        // Find the closest entry to the tapped date (uses cached sorted entries)
        let sorted = sortedFilteredEntries
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
        // Use cached sorted entries
        let sorted = sortedFilteredEntries

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
