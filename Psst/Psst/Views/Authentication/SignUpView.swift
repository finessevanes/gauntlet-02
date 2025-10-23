//
//  SignUpView.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #006A
//  Clean iOS-native sign up screen with standard form layout
//

import SwiftUI

/// Clean iOS-native sign up view with standard form layout
/// Uses iOS system colors, native typography, and standard patterns
struct SignUpView: View {
    // MARK: - State Management
    
    @StateObject private var viewModel = AuthViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var displayName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    
    // MARK: - Computed Properties
    
    private var passwordsMatch: Bool {
        password == confirmPassword && !password.isEmpty
    }
    
    private var isFormValid: Bool {
        !displayName.isEmpty && !email.isEmpty && !password.isEmpty && passwordsMatch && password.count >= 6
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                // Clean system background
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Section
                        VStack(spacing: 8) {
                            Text("Create Account")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                        .padding(.top, 16)
                        
                        // Form fields
                        VStack(spacing: 16) {
                            // Full Name field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Full Name")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                TextField("Enter your name", text: $displayName)
                                    .textFieldStyle(.roundedBorder)
                                    .textContentType(.name)
                                    .autocapitalization(.words)
                                    .disabled(viewModel.isLoading)
                                    .accessibilityIdentifier("signUpNameField")
                            }
                            
                            // Email field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                TextField("Enter your email", text: $email)
                                    .textFieldStyle(.roundedBorder)
                                    .textContentType(.emailAddress)
                                    .autocapitalization(.none)
                                    .keyboardType(.emailAddress)
                                    .disabled(viewModel.isLoading)
                                    .accessibilityIdentifier("signUpEmailField")
                            }
                            
                            // Password field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                SecureField("Create a password", text: $password)
                                    .textFieldStyle(.roundedBorder)
                                    .textContentType(.newPassword)
                                    .disabled(viewModel.isLoading)
                                    .accessibilityIdentifier("signUpPasswordField")
                                
                                if !password.isEmpty && password.count < 6 {
                                    Text("Password must be at least 6 characters")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                            
                            // Confirm password field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm Password")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                SecureField("Confirm your password", text: $confirmPassword)
                                    .textFieldStyle(.roundedBorder)
                                    .textContentType(.newPassword)
                                    .disabled(viewModel.isLoading)
                                    .accessibilityIdentifier("signUpConfirmPasswordField")
                                
                                if !confirmPassword.isEmpty && !passwordsMatch {
                                    Text("Passwords do not match")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Sign up button
                        Button(action: {
                            Task {
                                await viewModel.signUp(email: email, password: password, displayName: displayName)
                            }
                        }) {
                            Text(viewModel.isLoading ? "Creating Account..." : "Sign Up")
                                .font(.body)
                                .fontWeight(.semibold)
                        }
                        .buttonStyle(PrimaryButtonStyle(isLoading: viewModel.isLoading))
                        .disabled(!isFormValid || viewModel.isLoading)
                        .opacity(isFormValid ? 1.0 : 0.6)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        
                        // Sign in link
                        HStack(spacing: 4) {
                            Text("Already have an account?")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Button("Log in") {
                                dismiss()
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                        }
                        .padding(.top, 8)
                        
                        Spacer()
                        
                        // Error message
                        if let errorMessage = viewModel.errorMessage {
                            VStack(spacing: 8) {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundColor(.red)
                                    
                                    Text(errorMessage)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .multilineTextAlignment(.leading)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                                .padding(.horizontal, 24)
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .animation(.spring(response: 0.3), value: viewModel.errorMessage)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
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
        Group {
            SignUpView()
                .previewDisplayName("Light Mode")
            
            SignUpView()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
