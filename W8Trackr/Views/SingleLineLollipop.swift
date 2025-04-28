//
//  SingleLineLollipop.swift
//  W8Trackr
//
//  Created by Will Saults on 4/28/25.
//

import Charts
import SwiftUI

struct SingleLineLollipop: View {
    let entries: [WeightEntry]
    
    private var minWeight: Double {
        entries.map { $0.weightValue }.min() ?? 0
    }
    
    private var maxWeight: Double {
        entries.map { $0.weightValue }.max() ?? 200
    }
    
    var body: some View {
        Chart {
            ForEach(entries) { entry in
                LineMark(
                    x: .value("Date", entry.date),
                    y: .value("Weight", entry.weightValue)
                )
                .interpolationMethod(.catmullRom)
                
                PointMark(
                    x: .value("Date", entry.date),
                    y: .value("Weight", entry.weightValue)
                )
            }
        }
        .chartYScale(domain: (minWeight - 5)...(maxWeight + 5))
        .chartYAxis {
            AxisMarks(preset: .extended, position: .leading) { value in
                AxisValueLabel {
                    if let weight = value.as(Double.self) {
                        Text("\(weight, format: .number.precision(.fractionLength(1))) lbs")
                    }
                }
                AxisGridLine()
                AxisTick()
            }
        }
        .chartXAxis {
            AxisMarks(format: .dateTime.month().day())
        }
    }
}

#Preview {
    SingleLineLollipop(entries: WeightEntry.sortedSampleData)
        .padding()
}
