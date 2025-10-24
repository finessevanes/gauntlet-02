//
//  AILoadingIndicator.swift
//  Psst
//
//  Created by Caleb (AI Agent) on PR #006
//  Loading indicator for AI action processing
//

import SwiftUI

/// Displays a pulsing loading indicator while AI processes a request
struct AILoadingIndicator: View {
    var message: String = "AI is analyzing..."
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.8)
                .tint(.accentColor)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(radius: 4)
        .opacity(isAnimating ? 1.0 : 0.3)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    AILoadingIndicator()
}

#Preview("Custom Message") {
    AILoadingIndicator(message: "Searching conversations...")
}
