//
//  FeatureTourStepView.swift
//  W8Trackr
//
//  Quick feature tour for onboarding
//

import SwiftUI

struct FeatureTourStepView: View {
    var onContinue: () -> Void

    @State private var currentFeature = 0
    @State private var showContent = false
    @ScaledMetric(relativeTo: .title) private var featureIconSize: CGFloat = 40

    private let features: [TourFeature] = [
        TourFeature(
            icon: "chart.line.uptrend.xyaxis",
            title: "Track Your Progress",
            description: "See your weight trend over time with beautiful charts that smooth out daily fluctuations.",
            color: .blue
        ),
        TourFeature(
            icon: "trophy.fill",
            title: "Celebrate Milestones",
            description: "Get rewarded when you hit weight milestones. Every 5 pounds is a victory!",
            color: .yellow
        ),
        TourFeature(
            icon: "bell.badge.fill",
            title: "Stay Consistent",
            description: "Set daily reminders to log your weight and build a healthy habit.",
            color: .orange
        ),
        TourFeature(
            icon: "heart.fill",
            title: "Sync with Health",
            description: "Optionally sync your data with Apple Health for a complete picture.",
            color: .red
        )
    ]

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
                .frame(height: 20)

            Text("Quick Tour")
                .font(.largeTitle)
                .fontWeight(.bold)
                .offset(y: showContent ? 0 : 20)
                .opacity(showContent ? 1.0 : 0.0)

            Spacer()

            // Feature carousel
            TabView(selection: $currentFeature) {
                ForEach(features.indices, id: \.self) { index in
                    FeatureCard(feature: features[index], iconSize: featureIconSize)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 280)
            .scaleEffect(showContent ? 1.0 : 0.95)
            .opacity(showContent ? 1.0 : 0.0)

            // Feature dots
            HStack(spacing: 8) {
                ForEach(features.indices, id: \.self) { index in
                    Circle()
                        .fill(index == currentFeature ? features[index].color : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .scaleEffect(index == currentFeature ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3), value: currentFeature)
                }
            }

            Spacer()

            Button(action: onContinue) {
                Text("Let's Start!")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 30)
            .opacity(showContent ? 1.0 : 0.0)

            Spacer()
                .frame(height: 60)
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

// MARK: - Tour Feature Model

private struct TourFeature {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

// MARK: - Feature Card

private struct FeatureCard: View {
    let feature: TourFeature
    let iconSize: CGFloat

    var body: some View {
        VStack(spacing: 24) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [feature.color, feature.color.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: feature.icon)
                    .font(.system(size: iconSize))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 12) {
                Text(feature.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)

                Text(feature.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 30)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    FeatureTourStepView(onContinue: {})
}
