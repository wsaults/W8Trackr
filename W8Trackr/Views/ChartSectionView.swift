//
//  ChartSectionView.swift
//  W8Trackr
//
//  Created by Will Saults on 4/28/25.
//

import Charts
import SwiftUI

enum DateRange: String, CaseIterable {
    case sevenDay = "7 Day"
    case allTime = "All"
    
    var days: Int? {
        switch self {
        case .sevenDay: return 7
        case .allTime: return nil
        }
    }
}

struct ChartSectionView: View {
    let entries: [WeightEntry]
    let goalWeight: Double
    let weightUnit: WeightUnit
    @State private var selectedRange: DateRange = .sevenDay
    
    var body: some View {
        Section {
            VStack {
                WeightTrendChartView(entries: entries, 
                                   goalWeight: goalWeight,
                                   weightUnit: weightUnit,
                                   selectedRange: selectedRange)
                    .frame(height: 300)
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(10)
                
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

#Preview {
    ChartSectionView(entries: WeightEntry.sortedSampleData, goalWeight: 160.0, weightUnit: .lb)
}
