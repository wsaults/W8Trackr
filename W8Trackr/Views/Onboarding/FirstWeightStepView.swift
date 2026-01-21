//
//  FirstWeightStepView.swift
//  W8Trackr
//
//  Initial weight entry screen for onboarding
//

import SwiftUI

struct FirstWeightStepView: View {
    var weightUnit: WeightUnit
    @Binding var enteredWeight: Double

    var onContinue: () -> Void

    @State private var showContent = false
    @State private var lightFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    @State private var mediumFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    @ScaledMetric(relativeTo: .largeTitle) private var weightFontSize: CGFloat = 64

    private var isValidWeight: Bool {
        weightUnit.isValidWeight(enteredWeight)
    }

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            VStack(spacing: 12) {
                Text("Your Current Weight")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Let's log your starting point")
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
                    TextField("Weight", value: $enteredWeight, format: .number.precision(.fractionLength(1)))
                        .font(.system(size: weightFontSize, weight: .medium))
                        .keyboardType(.decimalPad)
                        .fixedSize()
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(isValidWeight ? Color.primary : Color.red)

                    Text(weightUnit.rawValue)
                        .font(.title)
                        .foregroundStyle(.secondary)
                }

                // Adjustment buttons
                HStack(spacing: 24) {
                    WeightAdjustmentButton(amount: 1.0, unitLabel: weightUnit.rawValue, isIncrease: false) {
                        mediumFeedbackGenerator.impactOccurred()
                        enteredWeight = max(weightUnit.minWeight, enteredWeight - 1.0)
                    }

                    WeightAdjustmentButton(amount: 0.1, unitLabel: weightUnit.rawValue, isIncrease: false) {
                        lightFeedbackGenerator.impactOccurred()
                        enteredWeight = max(weightUnit.minWeight, enteredWeight - 0.1)
                    }

                    WeightAdjustmentButton(amount: 0.1, unitLabel: weightUnit.rawValue, isIncrease: true) {
                        lightFeedbackGenerator.impactOccurred()
                        enteredWeight = min(weightUnit.maxWeight, enteredWeight + 0.1)
                    }

                    WeightAdjustmentButton(amount: 1.0, unitLabel: weightUnit.rawValue, isIncrease: true) {
                        mediumFeedbackGenerator.impactOccurred()
                        enteredWeight = min(weightUnit.maxWeight, enteredWeight + 1.0)
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
                    .background(isValidWeight ? AppColors.primary : AppColors.surfaceSecondary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(!isValidWeight)
            .padding(.horizontal, 30)
            .opacity(showContent ? 1.0 : 0.0)

            Spacer()
                .frame(height: 60)
        }
        .onAppear {
            // Set default starting weight based on unit
            if enteredWeight == 0 {
                enteredWeight = weightUnit.defaultWeight
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

#Preview {
    FirstWeightStepView(weightUnit: .lb, enteredWeight: .constant(180.0), onContinue: {})
}
