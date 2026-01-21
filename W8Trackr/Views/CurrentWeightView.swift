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

    private var accessibilityDescription: String {
        var description = "Current weight: \(weight.formatted(.number.precision(.fractionLength(1)))) \(weightUnit.displayName)"
        if let bodyFat = bodyFatPercentage {
            let bodyFatValue = NSDecimalNumber(decimal: bodyFat).doubleValue
            description += ", \(bodyFatValue.formatted(.number.precision(.fractionLength(1)))) percent body fat"
        }
        return description
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(weight, format: .number.precision(.fractionLength(1)))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text(weightUnit.displayName)
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
        .clipShape(.rect(cornerRadius: 10))
        .padding()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }
}

#if DEBUG
@available(iOS 18, macOS 15, *)
#Preview("Pounds") {
    CurrentWeightView(weight: 175.5, weightUnit: .lb, bodyFatPercentage: 18.5)
}

@available(iOS 18, macOS 15, *)
#Preview("Kilograms") {
    CurrentWeightView(weight: 79.8, weightUnit: .kg, bodyFatPercentage: 18.5)
}

@available(iOS 18, macOS 15, *)
#Preview("Large Weight (300+ lb)") {
    CurrentWeightView(weight: 325.0, weightUnit: .lb)
}

@available(iOS 18, macOS 15, *)
#Preview("Small Weight (< 100 lb)") {
    CurrentWeightView(weight: 92.5, weightUnit: .lb)
}
#endif
