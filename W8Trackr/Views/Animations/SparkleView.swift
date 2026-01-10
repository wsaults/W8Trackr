//
//  SparkleView.swift
//  W8Trackr
//
//  Created by Claude on 1/9/26.
//

import SwiftUI

/// Subtle sparkle animation for celebrating new lows or achievements
///
/// Usage:
/// ```swift
/// ZStack {
///     Text("New Low!")
///     SparkleView()
/// }
/// ```
struct SparkleView: View {
    /// Number of sparkle particles
    var sparkleCount: Int = 12

    /// Color of the sparkles
    var color: Color = AppColors.Fallback.success

    /// Size range for sparkles
    var sizeRange: ClosedRange<CGFloat> = 4...12

    /// Animation duration
    var duration: Double = 2.0

    /// Whether animation repeats
    var repeating: Bool = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<sparkleCount, id: \.self) { index in
                    SparkleParticle(
                        color: color,
                        size: CGFloat.random(in: sizeRange),
                        position: randomPosition(in: geometry.size, index: index),
                        delay: Double(index) * 0.1,
                        duration: duration,
                        repeating: repeating
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func randomPosition(in size: CGSize, index: Int) -> CGPoint {
        // Distribute sparkles in a circular pattern around center
        let angle = (Double(index) / Double(sparkleCount)) * 2 * .pi
        let radius = min(size.width, size.height) * 0.4
        let centerX = size.width / 2
        let centerY = size.height / 2

        return CGPoint(
            x: centerX + cos(angle) * radius * CGFloat.random(in: 0.5...1.0),
            y: centerY + sin(angle) * radius * CGFloat.random(in: 0.5...1.0)
        )
    }
}

// MARK: - Sparkle Particle

struct SparkleParticle: View {
    let color: Color
    let size: CGFloat
    let position: CGPoint
    let delay: Double
    let duration: Double
    let repeating: Bool

    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.3
    @State private var rotation: Double = 0

    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: size))
            .foregroundStyle(color)
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
            .position(position)
            .onAppear {
                animate()
            }
    }

    private func animate() {
        let animation: Animation = repeating
            ? .easeInOut(duration: duration / 2).repeatForever(autoreverses: true).delay(delay)
            : .easeInOut(duration: duration / 2).delay(delay)

        // Fade in and scale up
        withAnimation(animation) {
            opacity = 1
            scale = 1
            rotation = 45
        }

        if !repeating {
            // Fade out
            withAnimation(.easeIn(duration: duration / 2).delay(delay + duration / 2)) {
                opacity = 0
                scale = 0.5
            }
        }
    }
}

// MARK: - Shimmer Effect

/// A shimmer effect that moves across a view
struct ShimmerView: View {
    var color: Color = .white
    var duration: Double = 1.5
    var angle: Double = 30

    @State private var offset: CGFloat = -1

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let gradient = LinearGradient(
                colors: [
                    color.opacity(0),
                    color.opacity(0.3),
                    color.opacity(0)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )

            Rectangle()
                .fill(gradient)
                .frame(width: width * 0.5)
                .rotationEffect(.degrees(angle))
                .offset(x: offset * width * 1.5)
                .onAppear {
                    withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                        offset = 1
                    }
                }
        }
        .clipped()
        .allowsHitTesting(false)
    }
}

// MARK: - Glow Effect

/// A pulsing glow effect behind a view
struct GlowView: View {
    var color: Color = AppColors.Fallback.success
    var radius: CGFloat = 20
    var intensity: Double = 0.6

    @State private var glowing = false

    var body: some View {
        Circle()
            .fill(color.opacity(glowing ? intensity : intensity * 0.3))
            .blur(radius: radius)
            .scaleEffect(glowing ? 1.2 : 0.8)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    glowing = true
                }
            }
    }
}

// MARK: - New Low Celebration

/// Combined sparkle and glow effect for celebrating a new low weight
struct NewLowCelebration: View {
    var color: Color = AppColors.Fallback.success

    var body: some View {
        ZStack {
            // Background glow
            GlowView(color: color, radius: 30, intensity: 0.4)
                .frame(width: 100, height: 100)

            // Sparkles
            SparkleView(
                sparkleCount: 8,
                color: color,
                sizeRange: 8...16,
                duration: 2.0,
                repeating: false
            )
            .frame(width: 150, height: 150)
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Adds a sparkle effect overlay
    func sparkleEffect(isActive: Bool, color: Color = AppColors.Fallback.success) -> some View {
        ZStack {
            self

            if isActive {
                SparkleView(color: color, repeating: false)
            }
        }
    }

    /// Adds a shimmer effect overlay
    func shimmer(isActive: Bool = true, color: Color = .white, duration: Double = 1.5) -> some View {
        overlay {
            if isActive {
                ShimmerView(color: color, duration: duration)
            }
        }
    }

    /// Adds a glow effect behind the view
    func glowEffect(color: Color = AppColors.Fallback.success, radius: CGFloat = 15) -> some View {
        background {
            GlowView(color: color, radius: radius)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Sparkle") {
    ZStack {
        Color.gray.opacity(0.2)
            .ignoresSafeArea()

        VStack {
            Text("New Low!")
                .font(.title)
                .fontWeight(.bold)
        }

        SparkleView(repeating: true)
            .frame(width: 200, height: 200)
    }
}

#Preview("New Low Celebration") {
    ZStack {
        Color.white
            .ignoresSafeArea()

        NewLowCelebration()
    }
}

#Preview("Shimmer") {
    RoundedRectangle(cornerRadius: 12)
        .fill(AppGradients.primary)
        .frame(width: 200, height: 80)
        .shimmer()
}

#Preview("Glow") {
    Text("🏆")
        .font(.system(size: 60))
        .glowEffect(color: .yellow)
}
#endif
