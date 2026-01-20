//
//  ChartSectionView.swift
//  W8Trackr
//
//  Created by Will Saults on 4/28/25.
//

import Charts
import SwiftUI

enum DateRange: String, CaseIterable {
    case oneWeek = "1W"
    case oneMonth = "1M"
    case threeMonth = "3M"
    case sixMonth = "6M"
    case oneYear = "1Y"
    case allTime = "All"

    var days: Int? {
        switch self {
        case .oneWeek: return 7
        case .oneMonth: return 30
        case .threeMonth: return 90
        case .sixMonth: return 180
        case .oneYear: return 365
        case .allTime: return nil
        }
    }
}

struct ChartSectionView: View {
    let entries: [WeightEntry]
    let goalWeight: Double
    let weightUnit: WeightUnit
    let showSmoothing: Bool
    @State private var selectedRange: DateRange = .oneWeek

    var body: some View {
        Section {
            VStack {
                WeightTrendChartView(entries: entries,
                                   goalWeight: goalWeight,
                                   weightUnit: weightUnit,
                                   selectedRange: selectedRange,
                                   showSmoothing: showSmoothing)
                    .frame(height: 300)
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .clipShape(.rect(cornerRadius: 10))
                
                Picker("Date Range", selection: $selectedRange) {
                    ForEach(DateRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
            }
            .padding(.horizontal)
        } header: {
            HStack {
                Text("Weight Chart")
                    .font(.title2)
                Spacer()
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 18, macOS 15, *)
#Preview("Default", traits: .modifier(EntriesPreview())) {
    ScrollView {
        ChartSectionView(
            entries: WeightEntry.sortedSampleData,
            goalWeight: 160.0,
            weightUnit: .lb,
            showSmoothing: true
        )
    }
}

@available(iOS 18, macOS 15, *)
#Preview("Empty", traits: .modifier(EmptyEntriesPreview())) {
    ScrollView {
        ChartSectionView(
            entries: [],
            goalWeight: 160.0,
            weightUnit: .lb,
            showSmoothing: true
        )
    }
}

@available(iOS 18, macOS 15, *)
#Preview("Short Data (7 days)", traits: .modifier(ShortSamplePreview())) {
    ScrollView {
        ChartSectionView(
            entries: WeightEntry.shortSampleData,
            goalWeight: 160.0,
            weightUnit: .lb,
            showSmoothing: true
        )
    }
}

@available(iOS 18, macOS 15, *)
#Preview("Kilograms", traits: .modifier(EntriesPreview())) {
    ScrollView {
        ChartSectionView(
            entries: WeightEntry.shortSampleData,
            goalWeight: 72.5,
            weightUnit: .kg,
            showSmoothing: true
        )
    }
}

@available(iOS 18, macOS 15, *)
#Preview("No Smoothing", traits: .modifier(EntriesPreview())) {
    ScrollView {
        ChartSectionView(
            entries: WeightEntry.sortedSampleData,
            goalWeight: 160.0,
            weightUnit: .lb,
            showSmoothing: false
        )
    }
}
#endif
