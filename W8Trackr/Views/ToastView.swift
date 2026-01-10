//
//  ToastView.swift
//  W8Trackr
//
//  Created by Will Saults on 4/30/25.
//

import SwiftUI
import UIKit

// MARK: - Toast Type

enum ToastType {
    case success
    case error
    case info

    var iconColor: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        case .info: return .blue
        }
    }

    var defaultIcon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
}

// MARK: - Toast View

struct ToastView: View {
    let message: String
    let systemImage: String
    var type: ToastType = .info
    var actionLabel: String?
    var onAction: (() -> Void)?
    var showDismiss: Bool = false
    var onDismiss: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Label {
                Text(message)
                    .multilineTextAlignment(.leading)
            } icon: {
                Image(systemName: systemImage)
                    .foregroundColor(type.iconColor)
            }

            Spacer(minLength: 0)

            if let actionLabel, let onAction {
                Button(actionLabel) {
                    onAction()
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.small)
                .tint(type == .error ? .red : .blue)
            }

            if showDismiss, let onDismiss {
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss")
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
    }
}

struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String
    let systemImage: String
    var type: ToastType = .info
    var actionLabel: String?
    var onAction: (() -> Void)?
    var duration: TimeInterval
    var persistent: Bool = false

    var yOffset: CGFloat {
        isPresented ? 0 : -100
    }

    private func dismiss() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isPresented = false
        }
    }

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content

            ToastView(
                message: message,
                systemImage: systemImage,
                type: type,
                actionLabel: actionLabel,
                onAction: onAction,
                showDismiss: persistent,
                onDismiss: dismiss
            )
            .padding(.top)
            .padding(.horizontal)
            .opacity(isPresented ? 1 : 0)
            .offset(y: yOffset)
            .animation(.easeInOut(duration: 0.3), value: isPresented)
        }
        .onChange(of: isPresented) { _, newValue in
            if newValue {
                // Announce toast message to VoiceOver
                UIAccessibility.post(notification: .announcement, argument: message)

                // Only auto-dismiss if not persistent
                if !persistent {
                    DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                        dismiss()
                    }
                }
            }
        }
    }
}

extension View {
    /// Basic toast with auto-dismiss
    func toast(isPresented: Binding<Bool>, message: String, systemImage: String) -> some View {
        modifier(ToastModifier(
            isPresented: isPresented,
            message: message,
            systemImage: systemImage,
            duration: 5
        ))
    }

    /// Toast with action button
    func toast(
        isPresented: Binding<Bool>,
        message: String,
        systemImage: String,
        actionLabel: String,
        duration: TimeInterval = 5,
        onAction: @escaping () -> Void
    ) -> some View {
        modifier(ToastModifier(
            isPresented: isPresented,
            message: message,
            systemImage: systemImage,
            actionLabel: actionLabel,
            onAction: onAction,
            duration: duration
        ))
    }

    /// Success toast with green checkmark
    func successToast(isPresented: Binding<Bool>, message: String) -> some View {
        modifier(ToastModifier(
            isPresented: isPresented,
            message: message,
            systemImage: ToastType.success.defaultIcon,
            type: .success,
            duration: 3
        ))
    }

    /// Error toast with retry action (persistent until dismissed)
    func errorToast(
        isPresented: Binding<Bool>,
        message: String,
        retryLabel: String = "Retry",
        onRetry: @escaping () -> Void
    ) -> some View {
        modifier(ToastModifier(
            isPresented: isPresented,
            message: message,
            systemImage: ToastType.error.defaultIcon,
            type: .error,
            actionLabel: retryLabel,
            onAction: onRetry,
            duration: 0,
            persistent: true
        ))
    }

    /// Persistent info toast (requires manual dismiss)
    func persistentToast(
        isPresented: Binding<Bool>,
        message: String,
        systemImage: String
    ) -> some View {
        modifier(ToastModifier(
            isPresented: isPresented,
            message: message,
            systemImage: systemImage,
            type: .info,
            duration: 0,
            persistent: true
        ))
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 18, macOS 15, *)
#Preview("Info Toast") {
    @Previewable @State var isPresented = true

    Color.clear
        .toast(
            isPresented: $isPresented,
            message: "Entry saved successfully",
            systemImage: "checkmark.circle.fill"
        )
}

@available(iOS 18, macOS 15, *)
#Preview("Success Toast") {
    @Previewable @State var isPresented = true

    Color.clear
        .successToast(
            isPresented: $isPresented,
            message: "Weight logged successfully!"
        )
}

@available(iOS 18, macOS 15, *)
#Preview("Error Toast with Retry") {
    @Previewable @State var isPresented = true

    Color.clear
        .errorToast(
            isPresented: $isPresented,
            message: "Failed to sync. Check your connection."
        ) {
            print("Retry tapped")
        }
}

@available(iOS 18, macOS 15, *)
#Preview("Persistent Toast") {
    @Previewable @State var isPresented = true

    Color.clear
        .persistentToast(
            isPresented: $isPresented,
            message: "Syncing in progress...",
            systemImage: "arrow.triangle.2.circlepath"
        )
}

@available(iOS 18, macOS 15, *)
#Preview("Toast with Undo Action") {
    @Previewable @State var isPresented = true

    Color.clear
        .toast(
            isPresented: $isPresented,
            message: "Entry deleted",
            systemImage: "trash",
            actionLabel: "Undo"
        ) {
            print("Undo tapped")
        }
}
#endif
