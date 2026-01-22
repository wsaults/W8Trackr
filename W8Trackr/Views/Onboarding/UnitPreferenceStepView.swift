//
//  UnitPreferenceStepView.swift
//  W8Trackr
//
//  Unit selection screen for onboarding
//

import SwiftUI

struct UnitPreferenceStepView: View {
    @Binding var weightUnit: WeightUnit
    var onContinue: () -> Void

    @State private var showContent = false
    @ScaledMetric(relativeTo: .title) private var unitIconSize: CGFloat = 32

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            VStack(spacing: 12) {
                Text("Choose Your Unit")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("How do you prefer to track your weight?")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .offset(y: showContent ? 0 : 20)
            .opacity(showContent ? 1.0 : 0.0)

            Spacer()
                .frame(height: 20)

            // Unit selection cards
            VStack(spacing: 16) {
                UnitOptionCard(
                    unit: .lb,
                    isSelected: weightUnit == .lb,
                    iconSize: unitIconSize
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        weightUnit = .lb
                    }
                }

                UnitOptionCard(
                    unit: .kg,
                    isSelected: weightUnit == .kg,
                    iconSize: unitIconSize
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        weightUnit = .kg
                    }
                }
            }
            .padding(.horizontal, 30)
            .scaleEffect(showContent ? 1.0 : 0.95)
            .opacity(showContent ? 1.0 : 0.0)

            Spacer()

            Button(action: onContinue) {
                Text("Continue")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.primary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .accessibilityHint("Proceed to next step")
            .padding(.horizontal, 30)
            .padding(.bottom, 20)
            .opacity(showContent ? 1.0 : 0.0)
        }
        .onAppear {
            animateEntrance()
        }
    }

    private func animateEntrance() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2)) {
            showContent = true
        }
    }
}

// MARK: - Unit Option Card

private struct UnitOptionCard: View {
    let unit: WeightUnit
    let isSelected: Bool
    let iconSize: CGFloat
    let action: () -> Void

    private var unitTitle: String {
        switch unit {
        case .lb: return "Pounds"
        case .kg: return "Kilograms"
        }
    }

    private var unitIcon: String {
        switch unit {
        case .lb: return "scalemass"
        case .kg: return "scalemass.fill"
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: unitIcon)
                    .font(.system(size: iconSize))
                    .foregroundStyle(isSelected ? .white : AppColors.primary)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(isSelected ? AppColors.primary : AppColors.primary.opacity(0.1))
                    )

                HStack {
                    Text(unitTitle)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text("(\(unit.rawValue))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(AppColors.primary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? AppColors.primary : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(unitTitle) (\(unit.rawValue))")
        .accessibilityHint("Select \(unit.rawValue) as your preferred weight unit")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

#Preview {
    UnitPreferenceStepView(weightUnit: .constant(.lb), onContinue: {})
}
