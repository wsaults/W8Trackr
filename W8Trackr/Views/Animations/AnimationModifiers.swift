//
//  AnimationModifiers.swift
//  W8Trackr
//
//  Created by Claude on 1/9/26.
//

import SwiftUI

// MARK: - Spring Number Animation

/// Animates number changes with a spring effect
struct SpringNumberModifier: AnimatableModifier {
    var number: Double

    var animatableData: Double {
        get { number }
        set { number = newValue }
    }

    func body(content: Content) -> some View {
        content
            .overlay {
                Text(number, format: .number.precision(.fractionLength(1)))
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
    }
}

/// View that animates number changes with spring physics
struct AnimatedNumber: View {
    let value: Double
    let format: FloatingPointFormatStyle<Double>
    let font: Font
    let fontWeight: Font.Weight

    @State private var displayedValue: Double = 0

    init(
        value: Double,
        precision: Int = 1,
        font: Font = .largeTitle,
        fontWeight: Font.Weight = .bold
    ) {
        self.value = value
        self.format = .number.precision(.fractionLength(precision))
        self.font = font
        self.fontWeight = fontWeight
    }

    var body: some View {
        Text(displayedValue, format: format)
            .font(font)
            .fontWeight(fontWeight)
            .contentTransition(.numericText(value: displayedValue))
            .onAppear {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                    displayedValue = value
                }
            }
            .onChange(of: value) { _, newValue in
                withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                    displayedValue = newValue
                }
            }
    }
}

// MARK: - Badge Unlock Animation

/// Animated badge reveal for achievements
struct BadgeUnlockView: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let onDismiss: () -> Void

    /// Badge icon size scales with Dynamic Type
    @ScaledMetric(relativeTo: .title) private var badgeIconSize: CGFloat = 44

    @State private var showBadge = false
    @State private var showText = false
    @State private var showButton = false
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 0.3

    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 20) {
                // Badge icon with animation
                ZStack {
                    // Glow
                    Circle()
                        .fill(color.opacity(0.3))
                        .frame(width: 120, height: 120)
                        .blur(radius: 20)
                        .scaleEffect(showBadge ? 1.2 : 0.5)

                    // Badge background
                    Circle()
                        .fill(AppGradients.celebration)
                        .frame(width: 100, height: 100)
                        .shadow(color: color.opacity(0.5), radius: 10)

                    // Icon
                    Image(systemName: icon)
                        .font(.system(size: badgeIconSize))
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(rotation))
                }
                .scaleEffect(scale)
                .opacity(showBadge ? 1 : 0)

                // Text content
                VStack(spacing: 8) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .opacity(showText ? 1 : 0)
                .offset(y: showText ? 0 : 20)

                // Dismiss button
                Button {
                    dismiss()
                } label: {
                    Text("Awesome!")
                        .fontWeight(.semibold)
                        .frame(width: 150)
                        .padding()
                        .background(color)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .opacity(showButton ? 1 : 0)
                .scaleEffect(showButton ? 1 : 0.8)
            }
            .padding(40)
        }
        .onAppear {
            // Badge entrance
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                showBadge = true
                scale = 1
            }

            // Rotation flourish
            withAnimation(.spring(response: 0.8, dampingFraction: 0.5).delay(0.2)) {
                rotation = 360
            }

            // Text entrance
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4)) {
                showText = true
            }

            // Button entrance
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.6)) {
                showButton = true
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeIn(duration: 0.2)) {
            showBadge = false
            showText = false
            showButton = false
        }
        Task {
            try? await Task.sleep(for: .milliseconds(200))
            onDismiss()
        }
    }
}

// MARK: - Streak Celebration

/// Animated celebration for logging streaks
struct StreakCelebrationView: View {
    let streakCount: Int
    let onDismiss: () -> Void

    /// Flame glow effect size scales with Dynamic Type
    @ScaledMetric(relativeTo: .largeTitle) private var flameGlowSize: CGFloat = 80
    /// Main flame icon size scales with Dynamic Type
    @ScaledMetric(relativeTo: .largeTitle) private var flameIconSize: CGFloat = 70
    /// Streak number font size scales with Dynamic Type
    @ScaledMetric(relativeTo: .largeTitle) private var streakNumberSize: CGFloat = 60

    @State private var showFlame = false
    @State private var showNumber = false
    @State private var showText = false
    @State private var flameScale: CGFloat = 0.5
    @State private var numberValue: Double = 0

    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 16) {
                // Flame icon
                ZStack {
                    // Glow effect
                    Image(systemName: "flame.fill")
                        .font(.system(size: flameGlowSize))
                        .foregroundStyle(AppColors.warning.opacity(0.5))
                        .blur(radius: 20)
                        .scaleEffect(showFlame ? 1.3 : 0.5)

                    // Main flame
                    Image(systemName: "flame.fill")
                        .font(.system(size: flameIconSize))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.red, .orange, .yellow],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .scaleEffect(flameScale)
                }
                .opacity(showFlame ? 1 : 0)

                // Streak number
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(Int(numberValue), format: .number)
                        .font(.system(size: streakNumberSize, weight: .bold, design: .rounded))
                        .contentTransition(.numericText(value: numberValue))

                    Text("days")
                        .font(.title2)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.white)
                .opacity(showNumber ? 1 : 0)

                // Message
                Text(streakMessage)
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.9))
                    .opacity(showText ? 1 : 0)

                // Dismiss button
                Button {
                    dismiss()
                } label: {
                    Text("Keep it up!")
                        .fontWeight(.semibold)
                        .frame(width: 150)
                        .padding()
                        .background(.white)
                        .foregroundStyle(AppColors.warning)
                        .clipShape(Capsule())
                }
                .opacity(showText ? 1 : 0)
                .padding(.top, 8)
            }
            .padding(40)
        }
        .onAppear {
            // Flame entrance
            withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                showFlame = true
                flameScale = 1
            }

            // Pulse flame
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true).delay(0.5)) {
                flameScale = 1.1
            }

            // Number count up
            withAnimation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.3)) {
                showNumber = true
                numberValue = Double(streakCount)
            }

            // Text entrance
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.6)) {
                showText = true
            }
        }
    }

    private var streakMessage: String {
        switch streakCount {
        case 1...6:
            return "Great start! Keep going!"
        case 7:
            return "One week strong! 🎉"
        case 8...13:
            return "You're on fire!"
        case 14:
            return "Two weeks! Incredible!"
        case 15...29:
            return "Unstoppable!"
        case 30:
            return "One month! Amazing! 🏆"
        case 31...59:
            return "You're a legend!"
        case 60...89:
            return "Two months! Unbelievable!"
        case 90...:
            return "Three months+! You're inspiring!"
        default:
            return "Keep going!"
        }
    }

    private func dismiss() {
        withAnimation(.easeIn(duration: 0.2)) {
            showFlame = false
            showNumber = false
            showText = false
        }
        Task {
            try? await Task.sleep(for: .milliseconds(200))
            onDismiss()
        }
    }
}

// MARK: - Bounce Animation Modifier

struct BounceModifier: ViewModifier {
    @State private var bouncing = false
    let delay: Double
    let amount: CGFloat

    func body(content: Content) -> some View {
        content
            .offset(y: bouncing ? -amount : 0)
            .onAppear {
                withAnimation(
                    .spring(response: 0.3, dampingFraction: 0.3)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    bouncing = true
                }
            }
    }
}

// MARK: - Pop Animation Modifier

struct PopModifier: ViewModifier {
    @Binding var isActive: Bool
    let scale: CGFloat

    func body(content: Content) -> some View {
        content
            .scaleEffect(isActive ? scale : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isActive)
    }
}

// MARK: - View Extensions

extension View {
    /// Adds a bouncing animation
    func bounce(delay: Double = 0, amount: CGFloat = 5) -> some View {
        modifier(BounceModifier(delay: delay, amount: amount))
    }

    /// Adds a pop scale effect
    func pop(isActive: Binding<Bool>, scale: CGFloat = 1.2) -> some View {
        modifier(PopModifier(isActive: isActive, scale: scale))
    }

    /// Entrance animation with scale and opacity
    func entranceAnimation(delay: Double = 0) -> some View {
        modifier(EntranceModifier(delay: delay))
    }
}

struct EntranceModifier: ViewModifier {
    let delay: Double
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.8)
            .offset(y: isVisible ? 0 : 20)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay)) {
                    isVisible = true
                }
            }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Animated Number") {
    AnimatedNumber(value: 175.5)
}

#Preview("Badge Unlock") {
    BadgeUnlockView(
        icon: "star.fill",
        title: "First Milestone!",
        subtitle: "You reached your first weight goal",
        color: AppColors.accent
    ) { }
}

#Preview("Streak Celebration - 7 days") {
    StreakCelebrationView(streakCount: 7) { }
}

#Preview("Streak Celebration - 30 days") {
    StreakCelebrationView(streakCount: 30) { }
}
#endif
