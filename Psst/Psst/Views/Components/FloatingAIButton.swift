//
//  FloatingAIButton.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #004
//  AI Chat UI - Floating AI Assistant Button
//

import SwiftUI

/// Floating AI Assistant button for quick access to AI chat
struct FloatingAIButton: View {
    @State private var isPulsing = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Background circle
                Circle()
                    .fill(Color.blue)
                    .frame(width: 60, height: 60)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                
                // AI icon
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(.white)
            }
            .scaleEffect(isPulsing ? 1.1 : 1.0)
            .animation(
                Animation.easeInOut(duration: 1.2)
                    .repeatForever(autoreverses: true),
                value: isPulsing
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("AI Assistant")
        .accessibilityHint("Open AI Assistant chat")
        .onAppear {
            isPulsing = true
        }
    }
}

// MARK: - Previews

#Preview {
    ZStack {
        Color.gray.opacity(0.1)
        VStack {
            Spacer()
            HStack {
                Spacer()
                FloatingAIButton {
                    print("AI button tapped")
                }
                .padding()
            }
        }
    }
    .ignoresSafeArea()
}

