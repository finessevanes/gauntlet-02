//
//  ColorScheme.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #20
//  Minimal green light color palette for clean, modern authentication
//

import SwiftUI

/// Minimal green light color scheme for Psst authentication screens
/// Clean, modern aesthetic with soft green tones and excellent contrast
struct PsstColors {
    
    // MARK: - Primary Green Palette
    
    /// Main brand green - fresh and modern
    static let primaryGreen = Color(red: 0.2, green: 0.7, blue: 0.4)
    
    /// Light green for backgrounds and accents
    static let lightGreen = Color(red: 0.9, green: 0.98, blue: 0.92)
    
    /// Soft green for subtle elements
    static let softGreen = Color(red: 0.6, green: 0.9, blue: 0.7)
    
    /// Dark green for text and emphasis
    static let darkGreen = Color(red: 0.1, green: 0.5, blue: 0.3)
    
    // MARK: - Background Gradients
    
    /// Main background gradient - subtle green to white
    static let primaryGradient = LinearGradient(
        colors: [
            Color.white,
            Color(red: 0.95, green: 0.98, blue: 0.96)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Button gradient - vibrant green
    static let buttonGradient = LinearGradient(
        colors: [
            primaryGreen,
            Color(red: 0.15, green: 0.6, blue: 0.35)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    /// Subtle card background
    static let cardBackground = Color.white
    
    // MARK: - Text Colors
    
    /// Primary text - dark green for excellent readability
    static let primaryText = darkGreen
    
    /// Secondary text - muted green
    static let secondaryText = Color(red: 0.4, green: 0.6, blue: 0.5)
    
    /// White text for buttons
    static let whiteText = Color.white
    
    /// Muted text for subtle elements
    static let mutedText = Color(red: 0.6, green: 0.6, blue: 0.6)
    
    // MARK: - Interactive Elements
    
    /// Button background for primary actions
    static let primaryButton = primaryGreen
    
    /// Secondary button background
    static let secondaryButton = Color(red: 0.95, green: 0.95, blue: 0.95)
    
    /// Border color for inputs and cards
    static let borderColor = Color(red: 0.9, green: 0.9, blue: 0.9)
    
    /// Focus border color
    static let focusBorder = primaryGreen
    
    // MARK: - Status Colors
    
    /// Success color
    static let success = Color(red: 0.2, green: 0.7, blue: 0.4)
    
    /// Error color - soft red
    static let error = Color(red: 0.9, green: 0.3, blue: 0.3)
    
    /// Warning color - soft orange
    static let warning = Color(red: 0.9, green: 0.6, blue: 0.2)
    
    // MARK: - Shadows and Effects
    
    /// Subtle shadow color
    static let shadowColor = Color.black.opacity(0.05)
    
    /// Card shadow
    static let cardShadow = Color.black.opacity(0.08)
}

// MARK: - Gradient Extensions

extension LinearGradient {
    /// Creates a subtle animated gradient for backgrounds
    static func animatedGradient(colors: [Color]) -> LinearGradient {
        LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
