//
//  AddWeightView.swift
//  W8Trackr
//
//  Created by Will Saults on 5/9/25.
//

import SwiftUI

struct CurrentWeightView: View {
    let weight: Double
    let weightUnit: WeightUnit
    let bodyFatPercentage: Decimal?

    init(weight: Double, weightUnit: WeightUnit, bodyFatPercentage: Decimal? = nil) {
        self.weight = weight
        self.weightUnit = weightUnit
        self.bodyFatPercentage = bodyFatPercentage
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(weight, format: .number.precision(.fractionLength(1)))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text(weightUnit.rawValue)
            }
            Text("Current Weight")
                .font(.footnote)

            if let bodyFat = bodyFatPercentage {
                HStack(spacing: 4) {
                    Text(NSDecimalNumber(decimal: bodyFat).doubleValue, format: .number.precision(.fractionLength(1)))
                        .fontWeight(.semibold)
                    Text("% body fat")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(10)
        .padding()
    }
}

#Preview {
    CurrentWeightView(weight: 175, weightUnit: .lb)
}

