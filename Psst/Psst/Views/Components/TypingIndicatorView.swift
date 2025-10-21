//
//  TypingIndicatorView.swift
//  Psst
//
//  Created by Caleb Agent on PR-13
//  Copyright © 2024 Psst. All rights reserved.
//

import SwiftUI

/// A view that displays an animated typing indicator when users are composing messages
struct TypingIndicatorView: View {
    /// Array of display names for users currently typing
    let typingUserNames: [String]
    
    /// Current animation phase (0, 1, or 2) for dot animation
    @State private var animationPhase: Int = 0
    
    /// Timer for controlling dot animation
    @State private var animationTimer: Timer?
    
    var body: some View {
        if !typingUserNames.isEmpty {
            HStack(spacing: 4) {
                Text(displayText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Animated dots (... → .. → . → ...)
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(Color.secondary)
                            .frame(width: 3, height: 3)
                            .opacity(animationPhase == index ? 0.3 : 1.0)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.2), value: typingUserNames.count)
            .onAppear {
                startAnimation()
            }
            .onDisappear {
                stopAnimation()
            }
        }
    }
    
    /// Generate display text based on number of typing users
    private var displayText: String {
        switch typingUserNames.count {
        case 0:
            return ""
        case 1:
            return "\(typingUserNames[0]) is typing"
        case 2:
            return "\(typingUserNames[0]) and \(typingUserNames[1]) are typing"
        default:
            let others = typingUserNames.count - 1
            return "\(typingUserNames[0]) and \(others) others are typing"
        }
    }
    
    /// Start the dot animation loop (0.6 second interval)
    private func startAnimation() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { _ in
            withAnimation {
                animationPhase = (animationPhase + 1) % 3
            }
        }
    }
    
    /// Stop the animation timer
    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
}

// MARK: - Previews

struct TypingIndicatorView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Preview with 1 user typing
            TypingIndicatorView(typingUserNames: ["Alice"])
                .previewDisplayName("1 User Typing")
            
            // Preview with 2 users typing
            TypingIndicatorView(typingUserNames: ["Alice", "Bob"])
                .previewDisplayName("2 Users Typing")
            
            // Preview with 3+ users typing
            TypingIndicatorView(typingUserNames: ["Alice", "Bob", "Carol", "Dave"])
                .previewDisplayName("3+ Users Typing")
            
            // Preview with no users typing (hidden)
            TypingIndicatorView(typingUserNames: [])
                .previewDisplayName("No Users Typing")
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

