//
//  ConfettiView.swift
//  W8Trackr
//
//  Created by Claude on 1/9/26.
//

import SwiftUI

/// Reusable confetti celebration animation
///
/// Usage:
/// ```swift
/// ZStack {
///     // Your content
///     if showConfetti {
///         ConfettiView()
///     }
/// }
/// ```
struct CelebrationConfettiView: View {
    /// Number of confetti particles
    var particleCount: Int = 60

    /// Colors to use for confetti (defaults to theme celebration colors)
    var colors: [Color] = [
        AppColors.Fallback.primary,
        AppColors.Fallback.secondary,
        AppColors.Fallback.accent,
        AppColors.Fallback.success,
        AppColors.Fallback.warning,
        Color.yellow,
        Color.pink
    ]

    /// Duration of the animation
    var duration: Double = 3.0

    /// Whether to include emoji confetti
    var includeEmoji: Bool = true

    private let emojis = ["🎉", "⭐️", "✨", "🏆", "💪", "🔥"]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Regular confetti particles
                ForEach(0..<particleCount, id: \.self) { index in
                    CelebrationParticle(
                        shape: ConfettiShape.allCases[index % ConfettiShape.allCases.count],
                        color: colors[index % colors.count],
                        size: CGFloat.random(in: 8...16),
                        startX: CGFloat.random(in: 0...geometry.size.width),
                        delay: Double.random(in: 0...0.8),
                        duration: duration
                    )
                }

                // Emoji particles (if enabled)
                if includeEmoji {
                    ForEach(0..<10, id: \.self) { index in
                        EmojiParticle(
                            emoji: emojis[index % emojis.count],
                            startX: CGFloat.random(in: 0...geometry.size.width),
                            delay: Double.random(in: 0...0.5),
                            duration: duration
                        )
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Confetti Shapes

enum ConfettiShape: CaseIterable {
    case rectangle
    case circle
    case triangle
    case star
}

// MARK: - Celebration Particle

struct CelebrationParticle: View {
    let shape: ConfettiShape
    let color: Color
    let size: CGFloat
    let startX: CGFloat
    let delay: Double
    let duration: Double

    @State private var offsetY: CGFloat = -100
    @State private var opacity: Double = 1
    @State private var rotation: Double = 0
    @State private var offsetX: CGFloat = 0
    @State private var scale: CGFloat = 1

    var body: some View {
        confettiShape
            .fill(color)
            .frame(width: size, height: size * (shape == .rectangle ? 0.5 : 1))
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .rotation3DEffect(.degrees(rotation * 0.5), axis: (x: 1, y: 0, z: 0))
            .offset(x: startX + offsetX, y: offsetY)
            .opacity(opacity)
            .onAppear {
                // Falling animation
                withAnimation(.easeIn(duration: duration).delay(delay)) {
                    offsetY = UIScreen.main.bounds.height + 100
                    rotation = Double.random(in: 720...1440)
                    offsetX = CGFloat.random(in: -150...150)
                }

                // Wiggle animation
                withAnimation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true).delay(delay)) {
                    scale = CGFloat.random(in: 0.8...1.2)
                }

                // Fade out
                withAnimation(.easeIn(duration: duration * 0.4).delay(delay + duration * 0.6)) {
                    opacity = 0
                }
            }
    }

    private var confettiShape: AnyShape {
        switch shape {
        case .rectangle:
            AnyShape(Rectangle())
        case .circle:
            AnyShape(Circle())
        case .triangle:
            AnyShape(Triangle())
        case .star:
            AnyShape(Star(corners: 5, smoothness: 0.45))
        }
    }
}

// MARK: - Emoji Particle

struct EmojiParticle: View {
    let emoji: String
    let startX: CGFloat
    let delay: Double
    let duration: Double

    /// Emoji size scales with Dynamic Type
    @ScaledMetric(relativeTo: .body) private var emojiSize: CGFloat = 30

    @State private var offsetY: CGFloat = -50
    @State private var opacity: Double = 1
    @State private var scale: CGFloat = 0.5
    @State private var rotation: Double = 0

    var body: some View {
        Text(emoji)
            .font(.system(size: emojiSize))
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .offset(x: startX, y: offsetY)
            .opacity(opacity)
            .onAppear {
                // Pop in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5).delay(delay)) {
                    scale = 1.2
                }

                // Fall down
                withAnimation(.easeIn(duration: duration * 0.8).delay(delay + 0.3)) {
                    offsetY = UIScreen.main.bounds.height + 50
                    rotation = Double.random(in: -45...45)
                }

                // Fade out
                withAnimation(.easeIn(duration: duration * 0.3).delay(delay + duration * 0.5)) {
                    opacity = 0
                }
            }
    }
}

// MARK: - Custom Shapes

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct Star: Shape {
    let corners: Int
    let smoothness: Double

    func path(in rect: CGRect) -> Path {
        guard corners >= 2 else { return Path() }

        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        var currentAngle = -CGFloat.pi / 2
        let angleAdjustment = .pi * 2 / CGFloat(corners * 2)
        let innerX = center.x * smoothness
        let innerY = center.y * smoothness
        let outerX = center.x
        let outerY = center.y

        var path = Path()

        path.move(to: CGPoint(
            x: center.x + outerX * Darwin.cos(currentAngle),
            y: center.y + outerY * Darwin.sin(currentAngle)
        ))

        var bottom: CGFloat = 0

        for _ in 0..<corners * 2 {
            currentAngle += angleAdjustment

            let point: CGPoint
            if (currentAngle / angleAdjustment).truncatingRemainder(dividingBy: 2) == 1 {
                point = CGPoint(
                    x: center.x + innerX * Darwin.cos(currentAngle),
                    y: center.y + innerY * Darwin.sin(currentAngle)
                )
            } else {
                point = CGPoint(
                    x: center.x + outerX * Darwin.cos(currentAngle),
                    y: center.y + outerY * Darwin.sin(currentAngle)
                )
            }

            path.addLine(to: point)

            if point.y > bottom {
                bottom = point.y
            }
        }

        path.closeSubpath()
        return path
    }
}

// MARK: - Confetti Cannon Modifier

extension View {
    /// Triggers a confetti celebration animation
    func confettiCannon(isActive: Binding<Bool>, particleCount: Int = 60) -> some View {
        ZStack {
            self

            if isActive.wrappedValue {
                CelebrationConfettiView(particleCount: particleCount)
                    .onAppear {
                        // Auto-dismiss after animation completes
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                            isActive.wrappedValue = false
                        }
                    }
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Confetti") {
    ZStack {
        Color.black.opacity(0.3)
            .ignoresSafeArea()

        CelebrationConfettiView()
    }
}

#Preview("Confetti without Emoji") {
    ZStack {
        Color.white
            .ignoresSafeArea()

        CelebrationConfettiView(includeEmoji: false)
    }
}
#endif
