//
//  WeightAdjustmentButton.swift
//  W8Trackr
//
//  Reusable weight adjustment button with plus/minus icons and increment labels.
//

import SwiftUI

/// A reusable button for incrementing or decrementing weight values.
///
/// Displays a plus or minus icon with the increment amount shown below.
/// Large increments (>=1.0) use filled icons with primary color,
/// small increments (<1.0) use outline icons with secondary color.
struct WeightAdjustmentButton: View {
    /// The increment amount (e.g., 1.0 or 0.1)
    let amount: Double

    /// The unit label to use for accessibility (e.g., "lb" or "kg")
    let unitLabel: String

    /// Whether this button increases (true) or decreases (false) the weight
    let isIncrease: Bool

    /// Action to perform when button is tapped
    let action: () -> Void

    @ScaledMetric(relativeTo: .title) private var iconSize: CGFloat = 44
    @ScaledMetric(relativeTo: .caption) private var labelSize: CGFloat = 12

    /// Whether this is a large increment (>=1.0 uses filled icon)
    private var isLargeIncrement: Bool {
        amount >= 1.0
    }

    /// The SF Symbol name based on increase/decrease and increment size
    private var iconName: String {
        if isIncrease {
            return isLargeIncrement ? "plus.circle.fill" : "plus.circle"
        } else {
            return isLargeIncrement ? "minus.circle.fill" : "minus.circle"
        }
    }

    /// The color based on increment size
    private var iconColor: Color {
        isLargeIncrement ? AppColors.primary : AppColors.secondary
    }

    /// The formatted label text (e.g., "+1" or "-0.1")
    private var labelText: String {
        let sign = isIncrease ? "+" : "-"
        let formatted = amount.formatted(.number.precision(.fractionLength(amount < 1 ? 1 : 0)))
        return "\(sign)\(formatted)"
    }

    /// The accessibility label describing the button's action
    private var accessibilityLabelText: String {
        let action = isIncrease ? "Increase" : "Decrease"
        let unitName = unitLabel == "lb" ? "pound" : "kilogram"
        let plural = amount == 1.0 ? "" : "s"
        let formattedAmount = amount.formatted(.number.precision(.fractionLength(amount < 1 ? 1 : 0)))
        return "\(action) by \(formattedAmount) \(unitName)\(plural)"
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: iconName)
                    .font(.system(size: iconSize))
                    .foregroundStyle(iconColor)

                Text(labelText)
                    .font(.system(size: labelSize, weight: .medium))
                    .foregroundStyle(iconColor)
            }
        }
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint("Double-tap to adjust weight")
    }
}

// MARK: - Previews

#if DEBUG
#Preview("All Button States") {
    HStack(spacing: 24) {
        WeightAdjustmentButton(amount: 1.0, unitLabel: "lb", isIncrease: false) {}
        WeightAdjustmentButton(amount: 0.1, unitLabel: "lb", isIncrease: false) {}
        WeightAdjustmentButton(amount: 0.1, unitLabel: "lb", isIncrease: true) {}
        WeightAdjustmentButton(amount: 1.0, unitLabel: "lb", isIncrease: true) {}
    }
    .padding()
}

#Preview("Kilogram Unit") {
    HStack(spacing: 24) {
        WeightAdjustmentButton(amount: 1.0, unitLabel: "kg", isIncrease: false) {}
        WeightAdjustmentButton(amount: 0.1, unitLabel: "kg", isIncrease: false) {}
        WeightAdjustmentButton(amount: 0.1, unitLabel: "kg", isIncrease: true) {}
        WeightAdjustmentButton(amount: 1.0, unitLabel: "kg", isIncrease: true) {}
    }
    .padding()
}

#Preview("Large Dynamic Type") {
    HStack(spacing: 24) {
        WeightAdjustmentButton(amount: 1.0, unitLabel: "lb", isIncrease: false) {}
        WeightAdjustmentButton(amount: 0.1, unitLabel: "lb", isIncrease: true) {}
    }
    .padding()
    .environment(\.sizeCategory, .accessibilityExtraExtraLarge)
}
#endif
