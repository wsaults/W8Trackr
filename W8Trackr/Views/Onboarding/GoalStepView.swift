//
//  GoalStepView.swift
//  W8Trackr
//
//  Goal weight input screen for onboarding
//

import SwiftUI

struct GoalStepView: View {
    var weightUnit: WeightUnit
    @Binding var goalWeight: Double

    var onContinue: () -> Void

    @State private var showContent = false
    @State private var lightFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    @State private var mediumFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    @ScaledMetric(relativeTo: .largeTitle) private var weightFontSize: CGFloat = 64

    private var isValidGoal: Bool {
        weightUnit.isValidWeight(goalWeight)
    }

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            VStack(spacing: 12) {
                Text("Set Your Goal")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("What's your target weight?")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .offset(y: showContent ? 0 : 20)
            .opacity(showContent ? 1.0 : 0.0)

            Spacer()
                .frame(height: 20)

            // Weight input
            VStack(spacing: 20) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    TextField("Goal", value: $goalWeight, format: .number.precision(.fractionLength(1)))
                        .font(.system(size: weightFontSize, weight: .medium))
                        .keyboardType(.decimalPad)
                        .fixedSize()
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(isValidGoal ? Color.primary : Color.red)

                    Text(weightUnit.rawValue)
                        .font(.title)
                        .foregroundStyle(.secondary)
                }

                // Adjustment buttons
                HStack(spacing: 40) {
                    AdjustButton(systemName: "minus.circle.fill") {
                        mediumFeedbackGenerator.impactOccurred()
                        goalWeight = max(weightUnit.minWeight, goalWeight - 1.0)
                    }

                    AdjustButton(systemName: "plus.circle.fill") {
                        mediumFeedbackGenerator.impactOccurred()
                        goalWeight = min(weightUnit.maxWeight, goalWeight + 1.0)
                    }
                }
            }
            .scaleEffect(showContent ? 1.0 : 0.95)
            .opacity(showContent ? 1.0 : 0.0)

            Spacer()

            Button(action: onContinue) {
                Text("Continue")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isValidGoal ? Color.blue : Color.gray)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(!isValidGoal)
            .padding(.horizontal, 30)
            .opacity(showContent ? 1.0 : 0.0)

            Spacer()
                .frame(height: 60)
        }
        .onAppear {
            // Set default based on unit
            if goalWeight == 170.0 && weightUnit == .kg {
                goalWeight = 75.0
            }
            animateEntrance()
        }
    }

    private func animateEntrance() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2)) {
            showContent = true
        }
    }
}

// MARK: - Adjust Button

private struct AdjustButton: View {
    let systemName: String
    let action: () -> Void
    @ScaledMetric(relativeTo: .title) private var buttonIconSize: CGFloat = 44

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: buttonIconSize))
                .foregroundStyle(.blue)
        }
    }
}

#Preview {
    GoalStepView(weightUnit: .lb, goalWeight: .constant(170.0), onContinue: {})
}
