//
//  SignUpView.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #20
//  Minimal green light sign up screen with clean form design
//

import SwiftUI

/// Minimal sign up view with clean green light aesthetic
/// Features simple form layout with excellent UX
struct SignUpView: View {
    // MARK: - State Management
    
    @StateObject private var viewModel = AuthViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    
    // MARK: - Computed Properties
    
    private var passwordsMatch: Bool {
        password == confirmPassword && !password.isEmpty
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && passwordsMatch
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                // Clean background
                PsstColors.primaryGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer()
                        
                        // Main content card
                        VStack(spacing: 32) {
                            // Header
                            VStack(spacing: 16) {
                                // App icon
                                ZStack {
                                    Circle()
                                        .fill(PsstColors.primaryGreen)
                                        .frame(width: 80, height: 80)
                                    
                                    Image(systemName: "person.crop.circle.fill.badge.plus")
                                        .font(.system(size: 32, weight: .medium))
                                        .foregroundColor(.white)
                                }
                                
                                VStack(spacing: 8) {
                                    Text("Create Account")
                                        .font(PsstTypography.display)
                                        .foregroundColor(PsstColors.primaryText)
                                    
                                    Text("Join Psst today")
                                        .font(PsstTypography.body)
                                        .foregroundColor(PsstColors.secondaryText)
                                }
                            }
                            
                            // Form fields
                            VStack(spacing: 20) {
                                // Email field
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Email")
                                        .font(PsstTypography.label)
                                        .foregroundColor(PsstColors.primaryText)
                                    
                                    TextField("Enter your email", text: $email)
                                        .font(PsstTypography.input)
                                        .textContentType(.emailAddress)
                                        .autocapitalization(.none)
                                        .keyboardType(.emailAddress)
                                        .disabled(viewModel.isLoading)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 14)
                                        .background(PsstColors.cardBackground)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(PsstColors.borderColor, lineWidth: 1)
                                        )
                                        .cornerRadius(12)
                                        .accessibilityIdentifier("signUpEmailField")
                                }
                                
                                // Password field
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Password")
                                        .font(PsstTypography.label)
                                        .foregroundColor(PsstColors.primaryText)
                                    
                                    SecureField("Create a password", text: $password)
                                        .font(PsstTypography.input)
                                        .textContentType(.newPassword)
                                        .disabled(viewModel.isLoading)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 14)
                                        .background(PsstColors.cardBackground)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(PsstColors.borderColor, lineWidth: 1)
                                        )
                                        .cornerRadius(12)
                                        .accessibilityIdentifier("signUpPasswordField")
                                    
                                    Text("Must be at least 6 characters")
                                        .font(PsstTypography.helper)
                                        .foregroundColor(PsstColors.mutedText)
                                }
                                
                                // Confirm password field
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Confirm Password")
                                        .font(PsstTypography.label)
                                        .foregroundColor(PsstColors.primaryText)
                                    
                                    SecureField("Confirm your password", text: $confirmPassword)
                                        .font(PsstTypography.input)
                                        .textContentType(.newPassword)
                                        .disabled(viewModel.isLoading)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 14)
                                        .background(PsstColors.cardBackground)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(confirmPassword.isEmpty ? PsstColors.borderColor : 
                                                        passwordsMatch ? PsstColors.primaryGreen : PsstColors.error, 
                                                        lineWidth: 1)
                                        )
                                        .cornerRadius(12)
                                        .accessibilityIdentifier("signUpConfirmPasswordField")
                                    
                                    if !confirmPassword.isEmpty && !passwordsMatch {
                                        Text("Passwords do not match")
                                            .font(PsstTypography.helper)
                                            .foregroundColor(PsstColors.error)
                                    }
                                }
                                
                                // Sign up button
                                Button(action: {
                                    Task {
                                        await viewModel.signUp(email: email, password: password)
                                    }
                                }) {
                                    HStack {
                                        if viewModel.isLoading {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                .scaleEffect(0.8)
                                        } else {
                                            Text("Create Account")
                                                .font(PsstTypography.button)
                                        }
                                        
                                        Spacer()
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 16)
                                    .background(isFormValid ? PsstColors.primaryButton : PsstColors.mutedText)
                                    .cornerRadius(12)
                                }
                                .disabled(!isFormValid || viewModel.isLoading)
                            }
                            
                            // Divider
                            HStack {
                                Rectangle()
                                    .fill(PsstColors.borderColor)
                                    .frame(height: 1)
                                
                                Text("OR")
                                    .font(PsstTypography.caption)
                                    .foregroundColor(PsstColors.mutedText)
                                    .padding(.horizontal, 16)
                                
                                Rectangle()
                                    .fill(PsstColors.borderColor)
                                    .frame(height: 1)
                            }
                            
                            // Google sign up button
                            Button(action: {
                                Task {
                                    await viewModel.signUpWithGoogle()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "globe")
                                        .font(.system(size: 16, weight: .medium))
                                    
                                    Text("Sign up with Google")
                                        .font(PsstTypography.button)
                                    
                                    Spacer()
                                }
                                .foregroundColor(PsstColors.primaryText)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 16)
                                .background(PsstColors.secondaryButton)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(PsstColors.borderColor, lineWidth: 1)
                                )
                                .cornerRadius(12)
                            }
                            .disabled(viewModel.isLoading)
                            
                            // Sign in link
                            HStack(spacing: 4) {
                                Text("Already have an account?")
                                    .font(PsstTypography.caption)
                                    .foregroundColor(PsstColors.mutedText)
                                
                                Button("Sign in") {
                                    dismiss()
                                }
                                .font(PsstTypography.link)
                                .foregroundColor(PsstColors.primaryGreen)
                            }
                            .padding(.top, 8)
                        }
                        .padding(.horizontal, 32)
                        .padding(.vertical, 40)
                        .background(PsstColors.cardBackground)
                        .cornerRadius(24)
                        .shadow(color: PsstColors.cardShadow, radius: 20, x: 0, y: 10)
                        .padding(.horizontal, 24)
                        
                        Spacer()
                    }
                }
                
                // Error toast
                if let errorMessage = viewModel.errorMessage {
                    VStack {
                        Spacer()
                        
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.white)
                            
                            Text(errorMessage)
                                .font(PsstTypography.caption)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button("Dismiss") {
                                viewModel.clearError()
                            }
                            .font(PsstTypography.caption)
                            .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(PsstColors.error)
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: viewModel.errorMessage)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(PsstColors.primaryText)
                    }
                    .disabled(viewModel.isLoading)
                    .accessibilityIdentifier("closeButton")
                }
            }
            .onChange(of: viewModel.currentUser) { oldValue, newValue in
                if newValue != nil {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Preview

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}

