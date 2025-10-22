//
//  EmailSignInView.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #20
//  Email/password sign-in modal with new design system
//

import SwiftUI

/// Email/password sign-in modal
/// Clean form with gradient background and modern styling
struct EmailSignInView: View {
    // MARK: - State Management
    
    @StateObject private var viewModel = AuthViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showingForgotPassword: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                // Gradient Background
                GradientBackground.primary()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header Section
                        VStack(spacing: 16) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.white)
                            
                            Text("Sign in with Email")
                                .font(PsstTypography.largeTitle)
                                .foregroundColor(.white)
                            
                            Text("Enter your credentials to continue")
                                .font(PsstTypography.body)
                                .foregroundColor(Color.white.opacity(0.8))
                        }
                        .padding(.top, 40)
                        .padding(.bottom, 20)
                        
                        // Email/Password Form
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
                                    .accessibilityIdentifier("emailSignInField")
                            }
                            
                            // Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(PsstTypography.headline)
                                    .foregroundColor(.white)
                                
                                SecureField("Enter your password", text: $password)
                                    .textFieldStyle(.roundedBorder)
                                    .textContentType(.password)
                                    .disabled(viewModel.isLoading)
                                    .accessibilityIdentifier("passwordSignInField")
                            }
                            
                            // Forgot Password Link
                            HStack {
                                Spacer()
                                Button("Forgot Password?") {
                                    showingForgotPassword = true
                                }
                                .font(PsstTypography.caption)
                                .foregroundColor(.white)
                                .disabled(viewModel.isLoading)
                                .accessibilityIdentifier("forgotPasswordLink")
                            }
                            
                            // Sign In Button
                            AuthenticationButton.primary(
                                title: "Sign In",
                                isLoading: viewModel.isLoading
                            ) {
                                Task {
                                    await viewModel.signIn(email: email, password: password)
                                }
                            }
                            .disabled(email.isEmpty || password.isEmpty)
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer()
                    }
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
            .sheet(isPresented: $showingForgotPassword) {
                ForgotPasswordView()
            }
            .onChange(of: viewModel.currentUser) { oldValue, newValue in
                // Automatically dismiss when authentication succeeds
                if newValue != nil {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Preview

struct EmailSignInView_Previews: PreviewProvider {
    static var previews: some View {
        EmailSignInView()
    }
}

