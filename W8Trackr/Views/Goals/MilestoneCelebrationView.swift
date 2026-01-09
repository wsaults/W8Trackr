//
//  MilestoneCelebrationView.swift
//  W8Trackr
//
//  Created by Claude on 1/8/26.
//

import SwiftUI

struct MilestoneCelebrationView: View {
    let milestoneWeight: Double
    let unit: WeightUnit
    let onDismiss: () -> Void

    @State private var showContent = false
    @State private var showConfetti = false
    @ScaledMetric(relativeTo: .largeTitle) private var trophySize: CGFloat = 60

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            // Confetti layer
            if showConfetti {
                MilestoneConfettiView()
                    .ignoresSafeArea()
            }

            // Celebration card
            VStack(spacing: 20) {
                // Trophy icon with animation
                Image(systemName: "trophy.fill")
                    .font(.system(size: trophySize))
                    .foregroundStyle(.yellow)
                    .scaleEffect(showContent ? 1.0 : 0.5)
                    .opacity(showContent ? 1.0 : 0)

                VStack(spacing: 8) {
                    Text("Milestone Reached!")
                        .font(.title)
                        .fontWeight(.bold)

                    HStack(spacing: 4) {
                        Text(milestoneWeight, format: .number.precision(.fractionLength(0)))
                            .font(.largeTitle)
                            .fontWeight(.heavy)
                        Text(unit.rawValue)
                            .font(.title2)
                    }
                    .foregroundStyle(.blue)

                    Text("Keep up the great work!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .opacity(showContent ? 1.0 : 0)
                .offset(y: showContent ? 0 : 20)

                Button {
                    dismiss()
                } label: {
                    Text("Continue")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                }
                .opacity(showContent ? 1.0 : 0)
                .padding(.top, 8)
            }
            .padding(24)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 20)
            .padding(40)
            .scaleEffect(showContent ? 1.0 : 0.8)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showContent = true
            }
            withAnimation(.easeOut(duration: 0.3).delay(0.2)) {
                showConfetti = true
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeIn(duration: 0.2)) {
            showContent = false
            showConfetti = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
}

// MARK: - Confetti Animation

struct MilestoneConfettiView: View {
    let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink]
    let particleCount = 50

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<particleCount, id: \.self) { index in
                    MilestoneConfettiParticle(
                        color: colors[index % colors.count],
                        size: CGFloat.random(in: 8...14),
                        startX: CGFloat.random(in: 0...geometry.size.width),
                        delay: Double.random(in: 0...0.5)
                    )
                }
            }
        }
    }
}

struct MilestoneConfettiParticle: View {
    let color: Color
    let size: CGFloat
    let startX: CGFloat
    let delay: Double

    @State private var offsetY: CGFloat = -50
    @State private var opacity: Double = 1
    @State private var rotation: Double = 0
    @State private var offsetX: CGFloat = 0

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: size, height: size * 0.6)
            .rotationEffect(.degrees(rotation))
            .offset(x: startX + offsetX, y: offsetY)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: 2.5).delay(delay)) {
                    offsetY = UIScreen.main.bounds.height + 50
                    rotation = Double.random(in: 360...720)
                    offsetX = CGFloat.random(in: -100...100)
                }
                withAnimation(.easeIn(duration: 1.5).delay(delay + 1.0)) {
                    opacity = 0
                }
            }
    }
}

// MARK: - History View

struct MilestoneHistoryView: View {
    let milestones: [CompletedMilestone]
    let unit: WeightUnit

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Milestones Achieved")
                .font(.headline)
                .padding(.horizontal)

            if milestones.isEmpty {
                Text("No milestones completed yet. Keep going!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else {
                ForEach(milestones.sorted { $0.achievedDate > $1.achievedDate }, id: \.achievedDate) { milestone in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Text(milestone.targetWeight(in: unit), format: .number.precision(.fractionLength(0)))
                                    .fontWeight(.semibold)
                                Text(unit.rawValue)
                            }
                            Text(milestone.achievedDate, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.vertical)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

#Preview("Celebration") {
    MilestoneCelebrationView(milestoneWeight: 175, unit: .lb) { }
}

#Preview("History") {
    MilestoneHistoryView(
        milestones: [
            CompletedMilestone(targetWeight: 195, unit: .lb, achievedDate: Date().addingTimeInterval(-86400 * 30), startWeight: 200),
            CompletedMilestone(targetWeight: 190, unit: .lb, achievedDate: Date().addingTimeInterval(-86400 * 20), startWeight: 200),
            CompletedMilestone(targetWeight: 185, unit: .lb, achievedDate: Date().addingTimeInterval(-86400 * 10), startWeight: 200)
        ],
        unit: .lb
    )
}
