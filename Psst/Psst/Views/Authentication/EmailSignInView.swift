//
//  EmailSignInView.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #006A
//  Clean iOS-native email sign-in modal with minimal design
//

import SwiftUI

/// Clean iOS-native email sign-in modal
/// Minimal design with iOS system colors and native typography
struct EmailSignInView: View {
    // MARK: - State Management
    
    @StateObject private var viewModel = AuthViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showingForgotPassword: Bool = false
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty
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
                            Text("Email Sign In")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                        .padding(.top, 40)
                        
                        // Form fields
                        VStack(spacing: 16) {
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
                                    .accessibilityIdentifier("emailSignInField")
                            }
                            
                            // Password field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                SecureField("Enter your password", text: $password)
                                    .textFieldStyle(.roundedBorder)
                                    .textContentType(.password)
                                    .disabled(viewModel.isLoading)
                                    .accessibilityIdentifier("passwordSignInField")
                            }
                            
                            // Forgot password link
                            HStack {
                                Spacer()
                                Button("Forgot password?") {
                                    showingForgotPassword = true
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                                .disabled(viewModel.isLoading)
                                .accessibilityIdentifier("forgotPasswordLink")
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Sign in button
                        Button(action: {
                            Task {
                                await viewModel.signIn(email: email, password: password)
                            }
                        }) {
                            Text(viewModel.isLoading ? "Signing In..." : "Continue")
                                .font(.body)
                                .fontWeight(.semibold)
                        }
                        .buttonStyle(PrimaryButtonStyle(isLoading: viewModel.isLoading))
                        .disabled(!isFormValid || viewModel.isLoading)
                        .opacity(isFormValid ? 1.0 : 0.6)
                        .padding(.horizontal, 24)
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
        Group {
            EmailSignInView()
                .previewDisplayName("Light Mode")
            
            EmailSignInView()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
