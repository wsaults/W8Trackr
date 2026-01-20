//
//  EmptyStateView.swift
//  W8Trackr
//
//  Created by W8Trackr Team on 1/8/26.
//

import SwiftUI

/// Reusable empty state component with custom illustrations and encouraging copy
struct EmptyStateView: View {
    let illustration: EmptyStateIllustration
    let title: String
    let description: String
    var actionTitle: String?
    var action: (() -> Void)?
    @ScaledMetric(relativeTo: .title) private var mainIconSize: CGFloat = 48
    @ScaledMetric(relativeTo: .body) private var accentIconSize: CGFloat = 24

    var body: some View {
        VStack(spacing: 24) {
            illustrationView

            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 32)

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(AppColors.primary)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .accessibilityHint("Tap to get started")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    @ViewBuilder
    private var illustrationView: some View {
        switch illustration {
        case .startTracking:
            startTrackingIllustration
        case .emptyLogbook:
            emptyLogbookIllustration
        case .noChartData:
            noChartDataIllustration
        }
    }

    private var startTrackingIllustration: some View {
        ZStack {
            Circle()
                .fill(AppColors.primary.opacity(0.1))
                .frame(width: 120, height: 120)

            Image(systemName: "figure.walk")
                .font(.system(size: mainIconSize))
                .foregroundStyle(AppColors.primary.gradient)

            Image(systemName: "plus.circle.fill")
                .font(.system(size: accentIconSize))
                .foregroundStyle(AppColors.success)
                .offset(x: 30, y: -30)
        }
    }

    private var emptyLogbookIllustration: some View {
        ZStack {
            Circle()
                .fill(AppColors.warning.opacity(0.1))
                .frame(width: 120, height: 120)

            Image(systemName: "book.pages")
                .font(.system(size: mainIconSize))
                .foregroundStyle(AppColors.warning.gradient)

            Image(systemName: "pencil.circle.fill")
                .font(.system(size: accentIconSize))
                .foregroundStyle(AppColors.primary)
                .offset(x: 30, y: 30)
        }
    }

    private var noChartDataIllustration: some View {
        ZStack {
            Circle()
                .fill(AppColors.accent.opacity(0.1))
                .frame(width: 120, height: 120)

            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: mainIconSize))
                .foregroundStyle(AppColors.accent.gradient)

            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: accentIconSize))
                .foregroundStyle(.secondary)
                .offset(x: 30, y: -30)
        }
    }
}

enum EmptyStateIllustration {
    case startTracking
    case emptyLogbook
    case noChartData
}

#Preview("Start Tracking") {
    EmptyStateView(
        illustration: .startTracking,
        title: "Begin Your Journey",
        description: "Track your weight to see trends and progress toward your goals.",
        actionTitle: "Log Your First Weight",
        action: { }
    )
}

#Preview("Empty Logbook") {
    EmptyStateView(
        illustration: .emptyLogbook,
        title: "Your Logbook Awaits",
        description: "Every journey starts with a single step. Add your first entry to begin tracking.",
        actionTitle: "Add Entry",
        action: { }
    )
}

#Preview("No Chart Data") {
    EmptyStateView(
        illustration: .noChartData,
        title: "Not Enough Data",
        description: "Add a few more entries to see your weight trend chart come to life."
    )
}
