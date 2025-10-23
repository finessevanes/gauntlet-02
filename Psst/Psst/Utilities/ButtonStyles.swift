//
//  ButtonStyles.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #006A
//  Reusable iOS-native button styles for app-wide consistency
//

import SwiftUI

// MARK: - Primary Button Style

/// Primary button style using iOS blue with prominent appearance
/// Use for main actions like "Sign In", "Sign Up", "Continue"
struct PrimaryButtonStyle: ButtonStyle {
    var isLoading: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.9)
            }
            configuration.label
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 20)
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(10)
        .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
        .opacity(configuration.isPressed ? 0.9 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Secondary Button Style

/// Secondary button style using gray with bordered appearance
/// Use for optional actions like "Continue with Google", "Skip"
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            .background(Color(.systemGray6))
            .foregroundColor(.primary)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Destructive Button Style

/// Destructive button style using red for destructive actions
/// Use for actions like "Delete", "Logout", "Cancel"
struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Convenience Extensions

extension View {
    /// Applies primary button style (blue, prominent)
    func primaryButtonStyle(isLoading: Bool = false) -> some View {
        self.buttonStyle(PrimaryButtonStyle(isLoading: isLoading))
    }
    
    /// Applies secondary button style (gray, bordered)
    func secondaryButtonStyle() -> some View {
        self.buttonStyle(SecondaryButtonStyle())
    }
    
    /// Applies destructive button style (red)
    func destructiveButtonStyle() -> some View {
        self.buttonStyle(DestructiveButtonStyle())
    }
}

// MARK: - Preview

struct ButtonStyles_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 24) {
            // Primary button
            Button("Sign In") {
                print("Primary button tapped")
            }
            .buttonStyle(PrimaryButtonStyle())
            
            // Primary button loading
            Button("Signing In...") {
                print("Loading button")
            }
            .buttonStyle(PrimaryButtonStyle(isLoading: true))
            .disabled(true)
            
            // Secondary button
            Button("Continue with Google") {
                print("Secondary button tapped")
            }
            .buttonStyle(SecondaryButtonStyle())
            
            // Destructive button
            Button("Delete Account") {
                print("Destructive button tapped")
            }
            .buttonStyle(DestructiveButtonStyle())
        }
        .padding()
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Button Styles")
    }
}

