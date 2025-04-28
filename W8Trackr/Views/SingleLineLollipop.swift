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
    
    var body: some View {
        Chart {
            ForEach(entries) { entry in
                LineMark(
                    x: .value("Date", entry.date),
                    y: .value("Weight", entry.weightValue(in: .pounds))
                )
                .interpolationMethod(.catmullRom)
                
                PointMark(
                    x: .value("Date", entry.date),
                    y: .value("Weight", entry.weightValue(in: .pounds))
                )
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let weight = value.as(Double.self) {
                        Text("\(weight, format: .number.precision(.fractionLength(1))) lbs")
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(format: .dateTime.month().day())
        }
    }
}

#Preview {
    SingleLineLollipop(entries: WeightEntry.sampleData)
        .frame(height: 200)
        .padding()
}
