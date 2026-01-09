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
    var isError: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Label {
                Text(message)
            } icon: {
                Image(systemName: systemImage)
                    .foregroundColor(isError ? .red : .blue)
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
        .background {
            if isError {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.red.opacity(0.1))
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.ultraThinMaterial)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
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
    var duration: TimeInterval = 5
    var isError: Bool = false

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
                onAction: onAction,
                isError: isError
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

    func errorToast(isPresented: Binding<Bool>, message: String) -> some View {
        modifier(ToastModifier(isPresented: isPresented, message: message, systemImage: "exclamationmark.triangle.fill", isError: true))
    }
}
