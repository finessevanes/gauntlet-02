//
//  Typography.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #20
//  Clean, minimal typography system for modern authentication
//

import SwiftUI

/// Clean typography system for Psst authentication screens
/// Minimal, readable fonts with excellent hierarchy
struct PsstTypography {
    
    // MARK: - Display Styles
    
    /// Large display text for main headings
    static let display = Font.system(size: 32, weight: .bold, design: .rounded)
    
    /// Main title for screens
    static let title = Font.system(size: 28, weight: .semibold, design: .rounded)
    
    /// Section headings
    static let heading = Font.system(size: 20, weight: .semibold, design: .default)
    
    // MARK: - Body Text Styles
    
    /// Primary body text - clean and readable
    static let body = Font.system(size: 16, weight: .regular, design: .default)
    
    /// Secondary body text for descriptions
    static let bodySecondary = Font.system(size: 16, weight: .regular, design: .default)
    
    /// Large body text for emphasis
    static let bodyLarge = Font.system(size: 18, weight: .medium, design: .default)
    
    // MARK: - Interactive Text Styles
    
    /// Button text - clean and bold
    static let button = Font.system(size: 16, weight: .semibold, design: .default)
    
    /// Link text for navigation
    static let link = Font.system(size: 16, weight: .medium, design: .default)
    
    // MARK: - Small Text Styles
    
    /// Caption for hints and footnotes
    static let caption = Font.system(size: 14, weight: .regular, design: .default)
    
    /// Small caption for very small text
    static let captionSmall = Font.system(size: 12, weight: .regular, design: .default)
    
    // MARK: - Form Text Styles
    
    /// Label text for form fields
    static let label = Font.system(size: 14, weight: .medium, design: .default)
    
    /// Input text for form fields
    static let input = Font.system(size: 16, weight: .regular, design: .default)
    
    /// Helper text for form validation
    static let helper = Font.system(size: 12, weight: .regular, design: .default)
    
    // MARK: - Aliases for compatibility
    /// Alias for large title style (maps to display)
    static let largeTitle = PsstTypography.display
    /// Alias for headline style (maps to heading)
    static let headline = PsstTypography.heading
    /// Alias for primary button text (maps to button)
    static let buttonPrimary = PsstTypography.button
}

// MARK: - Font Extensions

extension Font {
    /// Creates a font with custom weight
    /// - Parameter weight: The font weight
    /// - Returns: A font with the specified weight
    func weight(_ weight: Font.Weight) -> Font {
        return Font.system(size: 17, weight: weight)
    }
    
    /// Creates a font with custom size
    /// - Parameter size: The font size
    /// - Returns: A font with the specified size
    func size(_ size: CGFloat) -> Font {
        return Font.system(size: size, weight: .regular)
    }
}

// MARK: - Text Style Modifiers

extension Text {
    /// Applies the large title style
    func largeTitleStyle() -> some View {
        self.font(PsstTypography.largeTitle)
    }
    
    /// Applies the title style
    func titleStyle() -> some View {
        self.font(PsstTypography.title)
    }
    
    /// Applies the headline style
    func headlineStyle() -> some View {
        self.font(PsstTypography.headline)
    }
    
    /// Applies the body style
    func bodyStyle() -> some View {
        self.font(PsstTypography.body)
    }
    
    /// Applies the caption style
    func captionStyle() -> some View {
        self.font(PsstTypography.caption)
    }
    
    /// Applies the button style
    func buttonStyle() -> some View {
        self.font(PsstTypography.button)
    }
    
    /// Applies the primary button style
    func primaryButtonStyle() -> some View {
        self.font(PsstTypography.buttonPrimary)
    }
}
