//
//  AILoadingIndicator.swift
//  Psst
//
//  Created by AI Assistant on PR #002
//  iOS AI Infrastructure Foundation
//

import SwiftUI

/// Animated "AI is thinking..." typing indicator
struct AILoadingIndicator: View {
    @State private var animationPhase: Int = 0
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                // "AI is thinking" text
                Text("AI is thinking")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Animated dots
                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.secondary)
                            .frame(width: 6, height: 6)
                            .opacity(animationPhase == index ? 1.0 : 0.3)
                            .animation(
                                Animation.easeInOut(duration: 0.6)
                                    .repeatForever(autoreverses: false)
                                    .delay(Double(index) * 0.2),
                                value: animationPhase
                            )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.systemGray5))
            .cornerRadius(18)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { _ in
            animationPhase = (animationPhase + 1) % 3
        }
    }
}

// MARK: - Previews

#Preview {
    VStack {
        AILoadingIndicator()
        Spacer()
    }
}

