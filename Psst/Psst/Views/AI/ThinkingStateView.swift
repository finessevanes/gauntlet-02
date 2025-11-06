//
//  ThinkingStateView.swift
//  Psst
//
//  Created by Caleb (AI Agent) on PR #018
//  Voice-First AI Coach Workflow
//

import SwiftUI

/// Enhanced thinking indicator with smooth animation
struct ThinkingStateView: View {
    @State private var animationAmount: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 16) {
            // Animated pulsing dots
            HStack(spacing: 12) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 12, height: 12)
                        .scaleEffect(animationAmount)
                        .animation(
                            Animation
                                .easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                            value: animationAmount
                        )
                }
            }

            // "Thinking..." text
            Text("Thinking...")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .onAppear {
            animationAmount = 1.5
        }
    }
}

// MARK: - Preview

struct ThinkingStateView_Previews: PreviewProvider {
    static var previews: some View {
        ThinkingStateView()
            .padding()
            .background(Color(.systemBackground))
    }
}
