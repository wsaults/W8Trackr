//
//  LargeWidgetView.swift
//  W8TrackrWidget
//
//  Created by Claude on 1/22/26.
//

import Charts
import SwiftUI
import WidgetKit

/// Large widget: Sparkline chart of last 7 days
/// Shows weight trend visualization with filled area chart
struct LargeWidgetView: View {
    let entry: WeightWidgetEntry

    var body: some View {
        if entry.currentWeight == nil {
            EmptyStateView()
        } else {
            contentView
                .widgetURL(URL(string: "w8trackr://"))
        }
    }

    private var contentView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "scalemass.fill")
                        .font(.caption)
                    Text("W8Trackr")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.secondary)

                Spacer()

                // Current weight (smaller than small widget, since chart is hero)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(entry.currentWeight ?? 0)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))

                    Text(entry.weightUnit)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // Trend arrow
                    Image(systemName: entry.trend.systemImage)
                        .font(.caption)
                        .foregroundStyle(entry.trend == .unknown ? .secondary : .primary)
                }
            }

            // Chart - hero element for large widget
            if entry.chartData.count >= 2 {
                SparklineChartView(data: entry.chartData, unit: entry.weightUnit)
                    .frame(maxHeight: .infinity)
            } else {
                // Not enough data for chart
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("Add more weigh-ins to see your trend")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Footer: 7-day summary
            if entry.chartData.count >= 2 {
                HStack {
                    Text("Last 7 days")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Spacer()

                    if let change = weeklyChange {
                        Text(change)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var weeklyChange: String? {
        guard entry.chartData.count >= 2,
              let first = entry.chartData.first,
              let last = entry.chartData.last else {
            return nil
        }

        let diff = last.weight - first.weight
        let sign = diff >= 0 ? "+" : ""
        return "\(sign)\(diff.formatted(.number.precision(.fractionLength(1)))) \(entry.weightUnit)"
    }
}

/// Sparkline chart with filled area gradient (like Apple Fitness widgets)
struct SparklineChartView: View {
    let data: [WeightWidgetEntry.ChartDataPoint]
    let unit: String

    var body: some View {
        Chart(data) { point in
            // Area fill with gradient (per CONTEXT.md: filled area chart like Apple Fitness)
            AreaMark(
                x: .value("Date", point.date),
                y: .value("Weight", point.weight)
            )
            .foregroundStyle(
                .linearGradient(
                    colors: [.blue.opacity(0.4), .blue.opacity(0.1), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)

            // Line on top
            LineMark(
                x: .value("Date", point.date),
                y: .value("Weight", point.weight)
            )
            .foregroundStyle(.blue)
            .lineStyle(StrokeStyle(lineWidth: 2))
            .interpolationMethod(.catmullRom)

            // Point markers
            PointMark(
                x: .value("Date", point.date),
                y: .value("Weight", point.weight)
            )
            .foregroundStyle(.blue)
            .symbolSize(20)
        }
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(position: .trailing) { value in
                if let weight = value.as(Double.self) {
                    AxisValueLabel {
                        Text("\(Int(weight))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .chartYScale(domain: yAxisDomain)
    }

    /// Calculate Y axis domain with padding
    private var yAxisDomain: ClosedRange<Double> {
        let weights = data.map(\.weight)
        let minWeight = weights.min() ?? 0
        let maxWeight = weights.max() ?? 100
        let padding = (maxWeight - minWeight) * 0.1
        // Ensure minimum range to avoid division issues with flat data
        let adjustedPadding = max(padding, 1.0)
        return (minWeight - adjustedPadding)...(maxWeight + adjustedPadding)
    }
}
