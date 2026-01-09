//
//  OnboardingView.swift
//  W8Trackr
//
//  Onboarding flow container with step navigation
//

import SwiftUI
import SwiftData

enum OnboardingStep: Int, CaseIterable {
    case welcome
    case goal
    case firstWeight
    case complete
}

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("preferredWeightUnit") private var preferredWeightUnit: WeightUnit = Locale.current.measurementSystem == .metric ? .kg : .lb
    @AppStorage("goalWeight") private var goalWeight: Double = 170.0

    @State private var currentStep: OnboardingStep = .welcome
    @State private var enteredWeight: Double = 0
    @State private var showConfetti = false

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

                    GoalStepView(
                        weightUnit: preferredWeightUnit,
                        goalWeight: $goalWeight,
                        onContinue: { advanceStep() }
                    )
                    .tag(OnboardingStep.goal)

                    FirstWeightStepView(
                        weightUnit: preferredWeightUnit,
                        enteredWeight: $enteredWeight,
                        onContinue: {
                            saveFirstEntry()
                            advanceStep()
                        }
                    )
                    .tag(OnboardingStep.firstWeight)

                    CompletionStepView(
                        showConfetti: $showConfetti,
                        onFinish: { completeOnboarding() }
                    )
                    .tag(OnboardingStep.complete)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentStep)

                stepIndicator
                    .padding(.bottom, 30)
            }

            if showConfetti {
                ConfettiView()
                    .allowsHitTesting(false)
            }
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color.blue.opacity(0.1),
                Color.purple.opacity(0.05),
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
                    .fill(step == currentStep ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .scaleEffect(step == currentStep ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3), value: currentStep)
            }
        }
    }

    private func advanceStep() {
        guard let nextStep = OnboardingStep(rawValue: currentStep.rawValue + 1) else { return }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentStep = nextStep
        }
        if nextStep == .complete {
            triggerConfetti()
        }
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
        withAnimation {
            showConfetti = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation {
                showConfetti = false
            }
        }
    }

    private func completeOnboarding() {
        hasCompletedOnboarding = true
        onComplete()
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
            }
        }
    }

    private func createParticles(in size: CGSize) {
        let colors: [Color] = [.blue, .purple, .pink, .orange, .yellow, .green]

        for _ in 0..<50 {
            let startX = CGFloat.random(in: 0...size.width)
            let particle = ConfettiParticle(
                position: CGPoint(x: startX, y: -20),
                color: colors.randomElement() ?? .blue,
                size: CGFloat.random(in: 6...12)
            )
            particles.append(particle)
        }

        // Animate particles falling
        for i in particles.indices {
            let delay = Double.random(in: 0...0.5)
            let duration = Double.random(in: 1.5...2.5)

            withAnimation(.easeIn(duration: duration).delay(delay)) {
                particles[i].position.y = size.height + 50
                particles[i].position.x += CGFloat.random(in: -100...100)
            }

            withAnimation(.easeIn(duration: duration * 0.8).delay(delay + duration * 0.5)) {
                particles[i].opacity = 0
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    let color: Color
    let size: CGFloat
    var opacity: Double = 1.0
}

#Preview {
    OnboardingView(onComplete: {})
}
