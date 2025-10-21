//
//  ForgotPasswordView.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #2
//  Password reset screen
//

import SwiftUI

/// Forgot password view for password reset
/// Allows users to request a password reset email
struct ForgotPasswordView: View {
    // MARK: - State Management
    
    @StateObject private var viewModel = AuthViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var email: String = ""
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Logo/Title Section
                    VStack(spacing: 12) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 72))
                            .foregroundColor(.blue)
                        
                        Text("Reset Password")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Enter your email address and we'll send you a link to reset your password.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 60)
                    .padding(.bottom, 20)
                    
                    // Email Form
                    VStack(spacing: 16) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            TextField("Enter your email", text: $email)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                                .disabled(viewModel.isLoading)
                                .accessibilityIdentifier("forgotPasswordEmailField")
                        }
                        
                        // Send Reset Link Button
                        Button(action: {
                            Task {
                                await viewModel.resetPassword(email: email)
                            }
                        }) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Send Reset Link")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.isLoading || email.isEmpty)
                        .opacity((viewModel.isLoading || email.isEmpty) ? 0.6 : 1.0)
                        .accessibilityIdentifier("Send Reset Link")
                    }
                    .padding(.horizontal, 24)
                    
                    // Back to Login Link
                    Button("Back to Sign In") {
                        dismiss()
                    }
                    .font(.footnote)
                    .foregroundColor(.blue)
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
                        .background(Color.red.opacity(0.9))
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
                        .background(Color.green.opacity(0.9))
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
                            .foregroundColor(.secondary)
                    }
                    .disabled(viewModel.isLoading)
                    .accessibilityIdentifier("xmark")
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

