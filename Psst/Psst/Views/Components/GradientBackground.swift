//
//  GradientBackground.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #20
//  Reusable gradient background component for authentication screens
//

import SwiftUI

/// Reusable gradient background component
/// Provides consistent gradient backgrounds across authentication screens
struct GradientBackground: View {
    
    // MARK: - Properties
    
    /// The gradient to display
    let gradient: LinearGradient
    
    /// Whether to enable subtle animation
    let isAnimated: Bool
    
    // MARK: - State
    
    @State private var animationOffset: CGFloat = 0
    
    // MARK: - Initializers
    
    /// Creates a gradient background
    /// - Parameters:
    ///   - gradient: The gradient to display
    ///   - isAnimated: Whether to enable subtle animation (default: true)
    init(gradient: LinearGradient, isAnimated: Bool = true) {
        self.gradient = gradient
        self.isAnimated = isAnimated
    }
    
    // MARK: - Body
    
    var body: some View {
        gradient
            .offset(x: animationOffset)
            .ignoresSafeArea()
            .onAppear {
                if isAnimated {
                    startAnimation()
                }
            }
    }
    
    // MARK: - Private Methods
    
    /// Starts the subtle animation
    private func startAnimation() {
        withAnimation(
            .easeInOut(duration: 2)
            .repeatForever(autoreverses: true)
        ) {
            animationOffset = 10
        }
    }
}

// MARK: - Convenience Initializers

extension GradientBackground {
    /// Creates a primary gradient background
    static func primary() -> GradientBackground {
        GradientBackground(gradient: PsstColors.primaryGradient)
    }
    
    /// Creates an adaptive gradient background
    /// Uses system colors that adapt to light/dark mode to avoid external dependency.
    static func adaptive() -> GradientBackground {
        let start = Color(uiColor: .systemBackground)
        let end = Color(uiColor: .secondarySystemBackground)
        let gradient = LinearGradient(
            colors: [start, end],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        return GradientBackground(gradient: gradient)
    }
    
    /// Creates a static gradient background (no animation)
    static func staticGradient(_ gradient: LinearGradient) -> GradientBackground {
        GradientBackground(gradient: gradient, isAnimated: false)
    }
}

// MARK: - Preview

struct GradientBackground_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            GradientBackground.primary()
            
            VStack {
                Text("Welcome to Psst")
                    .font(PsstTypography.largeTitle)
                    .foregroundColor(.white)
                
                Text("Your secure messaging app")
                    .font(PsstTypography.body)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}
