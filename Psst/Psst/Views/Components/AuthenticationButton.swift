//
//  AuthenticationButton.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #20
//  Minimal button component for clean authentication screens
//

import SwiftUI

/// Minimal button component for authentication screens
/// Clean design with excellent UX and haptic feedback
struct AuthenticationButton: View {
    
    // MARK: - Properties
    
    /// Button title text
    let title: String
    
    /// Optional icon name (SF Symbol)
    let icon: String?
    
    /// Button style variant
    let style: ButtonStyle
    
    /// Button action
    let action: () -> Void
    
    /// Whether the button is disabled
    let isDisabled: Bool
    
    /// Whether the button is loading
    let isLoading: Bool
    
    // MARK: - Button Styles
    
    enum ButtonStyle {
        case primary
        case secondary
        case google
    }
    
    // MARK: - Initializers
    
    /// Creates an authentication button
    /// - Parameters:
    ///   - title: Button title text
    ///   - icon: Optional icon name (SF Symbol)
    ///   - style: Button style variant
    ///   - isDisabled: Whether the button is disabled
    ///   - isLoading: Whether the button is loading
    ///   - action: Button action
    init(
        title: String,
        icon: String? = nil,
        style: ButtonStyle,
        isDisabled: Bool = false,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.isDisabled = isDisabled
        self.isLoading = isLoading
        self.action = action
    }
    
    // MARK: - Body
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            action()
        }) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                        .scaleEffect(0.8)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                }
                
                Text(title)
                    .font(PsstTypography.button)
                
                Spacer()
            }
            .foregroundColor(textColor)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(buttonBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .cornerRadius(12)
        }
        .disabled(isDisabled || isLoading)
        .opacity((isDisabled || isLoading) ? 0.6 : 1.0)
    }
    
    // MARK: - Computed Properties
    
    /// Button background based on style
    private var buttonBackground: some View {
        switch style {
        case .primary:
            return AnyView(PsstColors.primaryButton)
        case .secondary:
            return AnyView(PsstColors.secondaryButton)
        case .google:
            return AnyView(PsstColors.secondaryButton)
        }
    }
    
    /// Text color based on style
    private var textColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return PsstColors.primaryText
        case .google:
            return PsstColors.primaryText
        }
    }
    
    /// Border color based on style
    private var borderColor: Color {
        switch style {
        case .primary:
            return Color.clear
        case .secondary:
            return PsstColors.borderColor
        case .google:
            return PsstColors.borderColor
        }
    }
    
    /// Border width based on style
    private var borderWidth: CGFloat {
        switch style {
        case .primary:
            return 0
        case .secondary:
            return 1
        case .google:
            return 1
        }
    }
}

// MARK: - Convenience Initializers

extension AuthenticationButton {
    /// Creates a primary button
    static func primary(
        title: String,
        icon: String? = nil,
        isDisabled: Bool = false,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) -> AuthenticationButton {
        AuthenticationButton(
            title: title,
            icon: icon,
            style: .primary,
            isDisabled: isDisabled,
            isLoading: isLoading,
            action: action
        )
    }
    
    /// Creates a secondary button
    static func secondary(
        title: String,
        icon: String? = nil,
        isDisabled: Bool = false,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) -> AuthenticationButton {
        AuthenticationButton(
            title: title,
            icon: icon,
            style: .secondary,
            isDisabled: isDisabled,
            isLoading: isLoading,
            action: action
        )
    }
    
    /// Creates a Google button
    static func google(
        title: String,
        isDisabled: Bool = false,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) -> AuthenticationButton {
        AuthenticationButton(
            title: title,
            icon: "g.circle.fill",
            style: .google,
            isDisabled: isDisabled,
            isLoading: isLoading,
            action: action
        )
    }
}

// MARK: - Preview

struct AuthenticationButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            AuthenticationButton.primary(
                title: "Sign in with Email",
                icon: "envelope.fill"
            ) {
                print("Primary button tapped")
            }
            
            AuthenticationButton.google(
                title: "Sign in with Google"
            ) {
                print("Google button tapped")
            }
            
            AuthenticationButton.secondary(
                title: "Cancel",
                icon: "xmark"
            ) {
                print("Secondary button tapped")
            }
        }
        .padding()
    }
}
