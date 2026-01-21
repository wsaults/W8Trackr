//
//  CompletionStepView.swift
//  W8Trackr
//
//  Completion screen for onboarding flow
//

import SwiftUI

struct CompletionStepView: View {
    var onFinish: () -> Void

    @State private var showContent = false
    @State private var showCheckmark = false
    @ScaledMetric(relativeTo: .largeTitle) private var checkmarkSize: CGFloat = 50

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Success checkmark
            ZStack {
                Circle()
                    .fill(AppColors.success.opacity(0.15))
                    .frame(width: 140, height: 140)

                Circle()
                    .fill(AppColors.success)
                    .frame(width: 100, height: 100)

                Image(systemName: "checkmark")
                    .font(.system(size: checkmarkSize, weight: .bold))
                    .foregroundStyle(.white)
                    .scaleEffect(showCheckmark ? 1.0 : 0)
            }
            .scaleEffect(showContent ? 1.0 : 0.5)
            .opacity(showContent ? 1.0 : 0.0)

            VStack(spacing: 16) {
                Text("You're All Set!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("Your journey to a healthier you starts now. Log your weight daily for the best insights.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            .offset(y: showContent ? 0 : 20)
            .opacity(showContent ? 1.0 : 0.0)

            Spacer()

            Button(action: onFinish) {
                Text("Start Tracking")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.primary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 20)
            .scaleEffect(showContent ? 1.0 : 0.95)
            .opacity(showContent ? 1.0 : 0.0)
        }
        .onAppear {
            animateEntrance()
        }
    }

    private func animateEntrance() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
            showContent = true
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.4)) {
            showCheckmark = true
        }
    }
}

#Preview {
    CompletionStepView(onFinish: {})
}
