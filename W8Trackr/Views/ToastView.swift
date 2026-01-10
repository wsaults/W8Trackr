//
//  ToastView.swift
//  W8Trackr
//
//  Created by Will Saults on 4/30/25.
//

import SwiftUI
import UIKit

struct ToastView: View {
    let message: String
    let systemImage: String
    var actionLabel: String?
    var onAction: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Label {
                Text(message)
            } icon: {
                Image(systemName: systemImage)
                    .foregroundColor(.blue)
            }

            if let actionLabel, let onAction {
                Button(actionLabel) {
                    onAction()
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.small)
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
    var actionLabel: String?
    var onAction: (() -> Void)?
    var duration: TimeInterval

    var yOffset: CGFloat {
        isPresented ? 0 : -100
    }

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content

            ToastView(
                message: message,
                systemImage: systemImage,
                actionLabel: actionLabel,
                onAction: onAction
            )
            .padding(.top)
            .opacity(isPresented ? 1 : 0)
            .offset(y: yOffset)
            .animation(.easeInOut(duration: 0.3), value: isPresented)
        }
        .onChange(of: isPresented) { _, newValue in
            if newValue {
                // Announce toast message to VoiceOver
                UIAccessibility.post(notification: .announcement, argument: message)

                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPresented = false
                    }
                }
            }
        }
    }
}

extension View {
    func toast(isPresented: Binding<Bool>, message: String, systemImage: String) -> some View {
        modifier(ToastModifier(
            isPresented: isPresented,
            message: message,
            systemImage: systemImage,
            duration: 5
        ))
    }

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
#Preview("Error Toast with Action") {
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
