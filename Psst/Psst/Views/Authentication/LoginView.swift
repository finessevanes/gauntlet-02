//
//  LoginView.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #2
//  Login screen with email/password and Google Sign-In
//

import SwiftUI

/// Login view for existing users
/// Supports email/password and Google Sign-In authentication
struct LoginView: View {
    // MARK: - State Management
    
    @StateObject private var viewModel = AuthViewModel()
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showingSignUp: Bool = false
    @State private var showingForgotPassword: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Logo/Title Section
                        VStack(spacing: 12) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 72))
                                .foregroundColor(.blue)
                            
                            Text("Welcome Back")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("Sign in to continue")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 60)
                        .padding(.bottom, 20)
                        
                        // Email/Password Form
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
                                    .accessibilityIdentifier("loginEmailField")
                            }
                            
                            // Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                SecureField("Enter your password", text: $password)
                                    .textFieldStyle(.roundedBorder)
                                    .textContentType(.password)
                                    .disabled(viewModel.isLoading)
                                    .accessibilityIdentifier("loginPasswordField")
                            }
                            
                            // Forgot Password Link
                            HStack {
                                Spacer()
                                Button("Forgot Password?") {
                                    showingForgotPassword = true
                                }
                                .font(.footnote)
                                .foregroundColor(.blue)
                                .disabled(viewModel.isLoading)
                                .accessibilityIdentifier("Forgot Password?")
                            }
                            
                            // Sign In Button
                            Button(action: {
                                Task {
                                    await viewModel.signIn(email: email, password: password)
                                }
                            }) {
                                HStack {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Sign In")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(viewModel.isLoading || email.isEmpty || password.isEmpty)
                            .opacity((viewModel.isLoading || email.isEmpty || password.isEmpty) ? 0.6 : 1.0)
                            .accessibilityIdentifier("Sign In")
                        }
                        .padding(.horizontal, 24)
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .fill(Color.secondary.opacity(0.3))
                                .frame(height: 1)
                            
                            Text("OR")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 12)
                            
                            Rectangle()
                                .fill(Color.secondary.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        
                        // Google Sign-In Button
                        Button(action: {
                            Task {
                                await viewModel.signInWithGoogle()
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "g.circle.fill")
                                    .font(.title2)
                                
                                Text("Sign in with Google")
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .disabled(viewModel.isLoading)
                        .opacity(viewModel.isLoading ? 0.6 : 1.0)
                        .padding(.horizontal, 24)
                        .accessibilityIdentifier("Sign in with Google")
                        
                        // Divider
                        HStack {
                            Text("New to Psst?")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 32)
                        
                        // Google Sign-Up Button
                        Button(action: {
                            Task {
                                await viewModel.signUpWithGoogle()
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "g.circle.fill")
                                    .font(.title2)
                                
                                Text("Sign up with Google")
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .disabled(viewModel.isLoading)
                        .opacity(viewModel.isLoading ? 0.6 : 1.0)
                        .padding(.horizontal, 24)
                        .accessibilityIdentifier("Sign up with Google")
                        
                        // Email Sign Up Link
                        HStack {
                            Text("Or create an account with")
                                .foregroundColor(.secondary)
                            
                            Button("Email") {
                                showingSignUp = true
                            }
                            .foregroundColor(.blue)
                            .fontWeight(.semibold)
                            .disabled(viewModel.isLoading)
                            .accessibilityIdentifier("Email")
                        }
                        .font(.footnote)
                        .padding(.top, 16)
                        
                        Spacer()
                    }
                }
                
                // Error/Success Alert
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
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSignUp) {
                SignUpView()
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

