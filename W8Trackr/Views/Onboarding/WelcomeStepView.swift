//
//  WelcomeStepView.swift
//  W8Trackr
//
//  Welcome screen for onboarding flow
//

import SwiftUI

struct WelcomeStepView: View {
    var onContinue: () -> Void

    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var showIcon = false
    @State private var showButton = false
    @ScaledMetric(relativeTo: .largeTitle) private var iconSize: CGFloat = 50

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // App icon/mascot
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "scalemass.fill")
                    .font(.system(size: iconSize))
                    .foregroundStyle(.white)
            }
            .scaleEffect(showIcon ? 1.0 : 0.5)
            .opacity(showIcon ? 1.0 : 0.0)

            VStack(spacing: 16) {
                Text("Welcome to W8Trackr")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .offset(y: showTitle ? 0 : 20)
                    .opacity(showTitle ? 1.0 : 0.0)

                Text("Let's start your journey to a healthier you!")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .offset(y: showSubtitle ? 0 : 20)
                    .opacity(showSubtitle ? 1.0 : 0.0)
            }
            .padding(.horizontal, 30)

            Spacer()

            Button(action: onContinue) {
                Text("Get Started")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.primary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .accessibilityHint("Begin setting up your weight tracking")
            .padding(.horizontal, 30)
            .padding(.bottom, 20)
            .scaleEffect(showButton ? 1.0 : 0.95)
            .opacity(showButton ? 1.0 : 0.0)
        }
        .onAppear {
            animateEntrance()
        }
    }

    private func animateEntrance() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
            showIcon = true
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3)) {
            showTitle = true
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.5)) {
            showSubtitle = true
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.7)) {
            showButton = true
        }
    }
}

#Preview {
    WelcomeStepView(onContinue: {})
}
