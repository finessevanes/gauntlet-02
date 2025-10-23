//
//  LoginView.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #006A
//  Clean iOS-native login screen with system colors and minimal design
//

import SwiftUI

/// Clean iOS-native login view with minimal design
/// Uses iOS system colors, native typography, and standard patterns
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
                // Clean system background
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Spacer()
                    
                    // Header Section
                    VStack(spacing: 16) {
                        // Simple icon
                        Image(systemName: "message.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        
                        VStack(spacing: 8) {
                            Text("Welcome Back")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("Sign in to continue")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.bottom, 16)
                    
                    // Sign in options
                    VStack(spacing: 16) {
                        // Email sign in button
                        Button(action: {
                            showingEmailSignIn = true
                        }) {
                            Text("Continue with Email")
                                .font(.body)
                                .fontWeight(.semibold)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(viewModel.isLoading)
                        
                        // Google sign in button
                        Button(action: {
                            Task {
                                await viewModel.signInWithGoogle()
                            }
                        }) {
                            Text("Continue with Google")
                                .font(.body)
                                .fontWeight(.semibold)
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .disabled(viewModel.isLoading)
                    }
                    .padding(.horizontal, 24)
                    
                    // Sign up link
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button("Sign up") {
                            showingSignUp = true
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
        Group {
            LoginView()
                .previewDisplayName("Light Mode")
            
            LoginView()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
