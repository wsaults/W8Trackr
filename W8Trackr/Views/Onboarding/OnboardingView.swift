//
//  OnboardingView.swift
//  W8Trackr
//
//  Onboarding flow container with step navigation
//

import ConfettiSwiftUI
import SwiftUI
import SwiftData

enum OnboardingStep: Int, CaseIterable {
    case welcome
    case unitPreference
    case tour
    case goal
    case firstWeight
    case complete
}

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("preferredWeightUnit") private var preferredWeightUnit: WeightUnit = Locale.current.measurementSystem == .metric ? .kg : .lb
    @AppStorage("goalWeight") private var goalWeight: Double = 170.0

    @State private var currentStep: OnboardingStep = .welcome
    @State private var previousStep: OnboardingStep = .welcome
    @State private var enteredWeight: Double = 0
    @State private var confettiTrigger: Int = 0
    @State private var isGoalValid = false
    @State private var isWeightValid = false

    var onComplete: () -> Void

    var body: some View {
        ZStack {
            backgroundGradient

            VStack {
                if currentStep != .complete {
                    skipButton
                }

                TabView(selection: $currentStep) {
                    WelcomeStepView(onContinue: { advanceStep() })
                        .tag(OnboardingStep.welcome)

                    UnitPreferenceStepView(
                        weightUnit: $preferredWeightUnit,
                        onContinue: { advanceStep() }
                    )
                    .tag(OnboardingStep.unitPreference)

                    FeatureTourStepView(onContinue: { advanceStep() })
                        .tag(OnboardingStep.tour)

                    GoalStepView(
                        weightUnit: preferredWeightUnit,
                        goalWeight: $goalWeight,
                        isValid: $isGoalValid,
                        onContinue: { advanceStep() }
                    )
                    .tag(OnboardingStep.goal)

                    FirstWeightStepView(
                        weightUnit: preferredWeightUnit,
                        enteredWeight: $enteredWeight,
                        isValid: $isWeightValid,
                        onContinue: {
                            saveFirstEntry()
                            advanceStep()
                        }
                    )
                    .tag(OnboardingStep.firstWeight)

                    CompletionStepView(onFinish: { completeOnboarding() })
                        .tag(OnboardingStep.complete)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.8), value: currentStep)
                .onChange(of: currentStep) { oldStep, newStep in
                    // Revert invalid forward navigation
                    if newStep.rawValue > oldStep.rawValue {
                        if oldStep == .goal && !isGoalValid {
                            currentStep = oldStep
                            return
                        }
                        if oldStep == .firstWeight && !isWeightValid {
                            currentStep = oldStep
                            return
                        }
                    }
                    // Track valid step for future reference
                    previousStep = newStep
                    // Trigger confetti when reaching complete
                    if newStep == .complete {
                        triggerConfetti()
                    }
                }

                stepIndicator
                    .padding(.bottom, 30)
            }
            .confettiCannon(trigger: reduceMotion ? .constant(0) : $confettiTrigger, num: reduceMotion ? 0 : 50, radius: 400)
        }
        .ignoresSafeArea(.keyboard)
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                AppColors.primary.opacity(0.1),
                AppColors.accent.opacity(0.05),
                Color.clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var skipButton: some View {
        HStack {
            Spacer()
            Button("Skip") {
                completeOnboarding()
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding()
        }
    }

    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(OnboardingStep.allCases, id: \.rawValue) { step in
                Circle()
                    .fill(step == currentStep ? AppColors.primary : AppColors.surfaceSecondary)
                    .frame(width: 8, height: 8)
                    .scaleEffect(step == currentStep ? 1.2 : 1.0)
                    .animation(reduceMotion ? nil : .spring(response: 0.3), value: currentStep)
            }
        }
    }

    private func advanceStep() {
        guard let nextStep = OnboardingStep(rawValue: currentStep.rawValue + 1) else { return }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentStep = nextStep
        }
        // Note: confetti is triggered in onChange when reaching complete
    }

    private func saveFirstEntry() {
        guard enteredWeight > 0 else { return }
        let entry = WeightEntry(
            weight: enteredWeight,
            unit: preferredWeightUnit
        )
        modelContext.insert(entry)
        try? modelContext.save()
    }

    private func triggerConfetti() {
        confettiTrigger += 1
    }

    private func completeOnboarding() {
        hasCompletedOnboarding = true
        onComplete()
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
