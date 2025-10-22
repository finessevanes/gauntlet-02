//
//  ForgotPasswordView.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #20
//  Redesigned password reset screen with gradient background
//

import SwiftUI

/// Redesigned forgot password view with clean, modern interface
/// Features gradient background and consistent styling
struct ForgotPasswordView: View {
    // MARK: - State Management
    
    @StateObject private var viewModel = AuthViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var email: String = ""
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                // Gradient Background
                GradientBackground.primary()
                
                VStack(spacing: 32) {
                    // Header Section
                    VStack(spacing: 16) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.white)
                        
                        Text("Reset Password")
                            .font(PsstTypography.largeTitle)
                            .foregroundColor(.white)
                        
                        Text("Enter your email address and we'll send you a link to reset your password.")
                            .font(PsstTypography.body)
                            .foregroundColor(Color.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 60)
                    .padding(.bottom, 20)
                    
                    // Email Form
                    VStack(spacing: 20) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(PsstTypography.headline)
                                .foregroundColor(.white)
                            
                            TextField("Enter your email", text: $email)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                                .disabled(viewModel.isLoading)
                                .accessibilityIdentifier("forgotPasswordEmailField")
                        }
                        
                        // Send Reset Link Button
                        AuthenticationButton.primary(
                            title: "Send Reset Link",
                            isLoading: viewModel.isLoading
                        ) {
                            Task {
                                await viewModel.resetPassword(email: email)
                            }
                        }
                        .disabled(email.isEmpty)
                    }
                    .padding(.horizontal, 24)
                    
                    // Back to Login Link
                    Button("Back to Sign In") {
                        dismiss()
                    }
                    .font(PsstTypography.caption)
                    .foregroundColor(.white)
                    .disabled(viewModel.isLoading)
                    .padding(.top, 8)
                    .accessibilityIdentifier("Back to Sign In")
                    
                    Spacer()
                }
                
                // Error Alert
                if let errorMessage = viewModel.errorMessage {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(errorMessage)
                                .font(.footnote)
                        }
                        .padding()
                        .background(PsstColors.error.opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding()
                        .onTapGesture {
                            viewModel.clearError()
                        }
                    }
                    .transition(.move(edge: .bottom))
                    .animation(.spring(), value: viewModel.errorMessage)
                }
                
                // Success Alert
                if let successMessage = viewModel.successMessage {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text(successMessage)
                                .font(.footnote)
                        }
                        .padding()
                        .background(PsstColors.success.opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding()
                        .onTapGesture {
                            viewModel.clearSuccess()
                        }
                    }
                    .transition(.move(edge: .bottom))
                    .animation(.spring(), value: viewModel.successMessage)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                    .disabled(viewModel.isLoading)
                    .accessibilityIdentifier("closeButton")
                }
            }
        }
    }
}

// MARK: - Preview

struct ForgotPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ForgotPasswordView()
    }
}

