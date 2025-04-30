//
//  ToastView.swift
//  W8Trackr
//
//  Created by Will Saults on 4/30/25.
//

import SwiftUI

struct ToastView: View {
    let message: String
    let systemImage: String
    
    var body: some View {
        Label {
            Text(message)
        } icon: {
            Image(systemName: systemImage)
                .foregroundColor(.blue)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 2)
    }
}

struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String
    let systemImage: String
    
    var yOffset: CGFloat {
        isPresented ? 0 : -100
    }
    
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            
            ToastView(message: message, systemImage: systemImage)
                .padding(.top)
                .opacity(isPresented ? 1 : 0)
                .offset(y: yOffset)
                .animation(.easeInOut(duration: 0.3), value: isPresented)
        }
        .onChange(of: isPresented) { _, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
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
        modifier(ToastModifier(isPresented: isPresented, message: message, systemImage: systemImage))
    }
}
