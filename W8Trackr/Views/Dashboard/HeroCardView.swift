//
//  HeroCardView.swift
//  W8Trackr
//
//  Created by Claude on 1/9/26.
//

import SwiftUI

/// Hero card displaying current weight with trend indicator and change badge
///
/// Layout:
/// ```
/// ┌──────────────────────────────────┐
/// │     Current Weight               │
/// │        175.5 lb                  │
/// │        ↓ -2.3 this week          │
/// └──────────────────────────────────┘
/// ```
struct HeroCardView: View {
    let currentWeight: Double
    let weightUnit: WeightUnit
    let weeklyChange: Double?
    let bodyFatPercentage: Decimal?
    let trendDirection: TrendDirection

    /// Hero weight display scales with Dynamic Type
    @ScaledMetric(relativeTo: .largeTitle) private var heroFontSize: CGFloat = 56

    enum TrendDirection {
        case up
        case down
        case neutral

        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "arrow.right"
            }
        }

        var color: Color {
            switch self {
            case .up: return AppColors.warning
            case .down: return AppColors.success
            case .neutral: return AppColors.secondary
            }
        }
    }

    init(
        currentWeight: Double,
        weightUnit: WeightUnit,
        weeklyChange: Double? = nil,
        bodyFatPercentage: Decimal? = nil
    ) {
        self.currentWeight = currentWeight
        self.weightUnit = weightUnit
        self.weeklyChange = weeklyChange
        self.bodyFatPercentage = bodyFatPercentage

        // Determine trend direction
        if let change = weeklyChange {
            if change < -0.1 {
                self.trendDirection = .down
            } else if change > 0.1 {
                self.trendDirection = .up
            } else {
                self.trendDirection = .neutral
            }
        } else {
            self.trendDirection = .neutral
        }
    }

    private var formattedWeight: String {
        currentWeight.formatted(.number.precision(.fractionLength(1)))
    }

    private var formattedChange: String? {
        guard let change = weeklyChange else { return nil }
        let sign = change > 0 ? "+" : ""
        return "\(sign)\(change.formatted(.number.precision(.fractionLength(1))))"
    }

    private var accessibilityDescription: String {
        var description = "Current weight: \(formattedWeight) \(weightUnit.rawValue)"

        if let changeText = formattedChange {
            let direction = trendDirection == .down ? "down" : trendDirection == .up ? "up" : "stable"
            description += ". \(direction) \(changeText) \(weightUnit.rawValue) this week"
        }

        if let bodyFat = bodyFatPercentage {
            let bodyFatValue = NSDecimalNumber(decimal: bodyFat).doubleValue
            description += ". Body fat: \(bodyFatValue.formatted(.number.precision(.fractionLength(1)))) percent"
        }

        return description
    }

    private var trendGradient: LinearGradient {
        switch trendDirection {
        case .down:
            return AppGradients.success  // Green - losing weight
        case .up:
            return AppGradients.warning  // Amber - gaining weight
        case .neutral:
            return AppGradients.primary  // Coral - maintaining
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            // Label
            Text("Current Weight")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white.opacity(0.9))

            // Main weight display
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(formattedWeight)
                    .font(.system(size: heroFontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(weightUnit.rawValue)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white.opacity(0.8))
            }

            // Trend indicator
            if let changeText = formattedChange {
                HStack(spacing: 6) {
                    Image(systemName: trendDirection.icon)
                        .font(.caption)
                        .fontWeight(.bold)

                    Text("\(changeText) \(weightUnit.rawValue) this week")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.white.opacity(0.2))
                .clipShape(Capsule())
            }

            // Body fat (if available)
            if let bodyFat = bodyFatPercentage {
                let bodyFatValue = NSDecimalNumber(decimal: bodyFat).doubleValue
                HStack(spacing: 4) {
                    Text(bodyFatValue.formatted(.number.precision(.fractionLength(1))))
                        .fontWeight(.semibold)
                    Text("% body fat")
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(trendGradient)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: (trendDirection == .down ? AppColors.success : trendDirection == .up ? AppColors.warning : AppColors.primary).opacity(0.3), radius: 10, x: 0, y: 5)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Losing Weight") {
    HeroCardView(
        currentWeight: 175.5,
        weightUnit: .lb,
        weeklyChange: -2.3
    )
    .padding()
}

#Preview("Gaining Weight") {
    HeroCardView(
        currentWeight: 72.5,
        weightUnit: .kg,
        weeklyChange: 0.8
    )
    .padding()
}

#Preview("With Body Fat") {
    HeroCardView(
        currentWeight: 180.0,
        weightUnit: .lb,
        weeklyChange: -1.5,
        bodyFatPercentage: 22.5
    )
    .padding()
}

#Preview("No Change Data") {
    HeroCardView(
        currentWeight: 165.0,
        weightUnit: .lb
    )
    .padding()
}
#endif
