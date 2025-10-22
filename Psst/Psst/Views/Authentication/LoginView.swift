//
//  LoginView.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #20
//  Minimal green light login screen with clean, modern design
//

import SwiftUI

/// Minimal login view with clean green light aesthetic
/// Features simple layout with excellent UX and modern typography
struct LoginView: View {
    // MARK: - State Management
    
    @StateObject private var viewModel = AuthViewModel()
    
    @State private var showingSignUp: Bool = false
    @State private var showingEmailSignIn: Bool = false
    @State private var showingForgotPassword: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                // Clean background
                PsstColors.primaryGradient
                    .ignoresSafeArea()
                
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
                                
                                Image(systemName: "message.fill")
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(spacing: 8) {
                                Text("Welcome to Psst")
                                    .font(PsstTypography.display)
                                    .foregroundColor(PsstColors.primaryText)
                                
                                Text("Secure messaging made simple")
                                    .font(PsstTypography.body)
                                    .foregroundColor(PsstColors.secondaryText)
                            }
                        }
                        
                        // Sign in options
                        VStack(spacing: 16) {
                            // Email sign in button
                            Button(action: {
                                showingEmailSignIn = true
                            }) {
                                HStack {
                                    Image(systemName: "envelope.fill")
                                        .font(.system(size: 16, weight: .medium))
                                    
                                    Text("Continue with Email")
                                        .font(PsstTypography.button)
                                    
                                    Spacer()
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 16)
                                .background(PsstColors.primaryButton)
                                .cornerRadius(12)
                            }
                            .disabled(viewModel.isLoading)
                            
                            // Google sign in button
                            Button(action: {
                                Task {
                                    await viewModel.signInWithGoogle()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "globe")
                                        .font(.system(size: 16, weight: .medium))
                                    
                                    Text("Continue with Google")
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
                        }
                        
                        // Sign up link
                        HStack(spacing: 4) {
                            Text("Don't have an account?")
                                .font(PsstTypography.caption)
                                .foregroundColor(PsstColors.mutedText)
                            
                            Button("Sign up") {
                                showingSignUp = true
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
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSignUp) {
                SignUpView()
            }
            .sheet(isPresented: $showingEmailSignIn) {
                EmailSignInView()
            }
            .sheet(isPresented: $showingForgotPassword) {
                ForgotPasswordView()
            }
        }
    }
}

// MARK: - Preview

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}

