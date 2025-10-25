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
    
    @State private var selectedRole: UserRole? = nil
    @State private var showRoleSelection: Bool = true
    @State private var showAuthMethodSelection: Bool = false
    @State private var selectedAuthMethod: AuthMethod? = nil
    @State private var displayName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""

    enum AuthMethod {
        case email
        case google
    }

    // MARK: - Computed Properties

    private var passwordsMatch: Bool {
        password == confirmPassword && !password.isEmpty
    }

    private var isFormValid: Bool {
        let hasRole = selectedRole != nil
        let hasValidName = !displayName.trimmingCharacters(in: .whitespaces).isEmpty
        let hasValidEmail = !email.isEmpty

        // For Google auth, we don't need password validation
        if selectedAuthMethod == .google {
            return hasRole && hasValidName && hasValidEmail
        }

        // For email auth, we need password validation
        return hasRole && hasValidName && hasValidEmail && !password.isEmpty && passwordsMatch && password.count >= 6
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                // Clean system background
                Color(.systemBackground)
                    .ignoresSafeArea()

                if showRoleSelection {
                    // Role selection screen
                    roleSelectionView
                } else if showAuthMethodSelection {
                    // Auth method selection screen
                    authMethodSelectionView
                } else {
                    // Signup form
                    signupFormView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        if showRoleSelection {
                            dismiss()
                        } else if showAuthMethodSelection {
                            // Go back to role selection
                            withAnimation {
                                showAuthMethodSelection = false
                                showRoleSelection = true
                            }
                        } else {
                            // Go back to auth method selection
                            withAnimation {
                                showAuthMethodSelection = true
                                selectedAuthMethod = nil
                                // Clear form
                                displayName = ""
                                email = ""
                                password = ""
                                confirmPassword = ""
                            }
                        }
                    }) {
                        Image(systemName: showRoleSelection ? "xmark" : "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    .disabled(viewModel.isLoading)
                    .accessibilityIdentifier("backButton")
                }
            }
            .onChange(of: viewModel.currentUser) { oldValue, newValue in
                if newValue != nil {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Role Selection View

    private var roleSelectionView: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 8) {
                    Text("I am a...")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text("This helps us personalize your experience")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 60)

                // Role buttons
                VStack(spacing: 16) {
                    // Personal Trainer button
                    Button(action: {
                        selectedRole = .trainer
                        withAnimation {
                            showRoleSelection = false
                            showAuthMethodSelection = true
                        }
                    }) {
                        HStack(spacing: 16) {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.system(size: 32))
                                .foregroundColor(.blue)
                                .frame(width: 50)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Personal Trainer")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Text("I train clients and manage their progress")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding(20)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    .accessibilityIdentifier("trainerButton")

                    // Client button
                    Button(action: {
                        selectedRole = .client
                        withAnimation {
                            showRoleSelection = false
                            showAuthMethodSelection = true
                        }
                    }) {
                        HStack(spacing: 16) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.green)
                                .frame(width: 50)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Client")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Text("I work with a trainer to achieve my goals")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding(20)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    .accessibilityIdentifier("clientButton")
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
    }

    // MARK: - Auth Method Selection View

    private var authMethodSelectionView: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 8) {
                    Text("Sign Up")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    if let role = selectedRole {
                        Text("As a \(role == .trainer ? "Personal Trainer" : "Client")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 60)

                // Auth method buttons
                VStack(spacing: 16) {
                    // Google Sign-In button
                    Button(action: {
                        Task {
                            await handleGoogleSignUp()
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "g.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.red)

                            Text("Continue with Google")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)

                            Spacer()
                        }
                        .padding(16)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.isLoading)
                    .accessibilityIdentifier("googleSignUpButton")

                    // Email Sign-Up button
                    Button(action: {
                        selectedAuthMethod = .email
                        withAnimation {
                            showAuthMethodSelection = false
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)

                            Text("Continue with Email")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)

                            Spacer()
                        }
                        .padding(16)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.isLoading)
                    .accessibilityIdentifier("emailSignUpButton")
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
    }

    // MARK: - Signup Form View

    private var signupFormView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Section
                VStack(spacing: 8) {
                    Text("Create Account")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    if let role = selectedRole {
                        Text("As a \(role == .trainer ? "Personal Trainer" : "Client")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
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
                                    .disabled(selectedAuthMethod == .google || viewModel.isLoading)
                                    .accessibilityIdentifier("signUpEmailField")
                            }

                            // Password fields (only for email auth)
                            if selectedAuthMethod == .email {
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
                        }
                        .padding(.horizontal, 24)
                        
                // Sign up button
                Button(action: {
                    guard let role = selectedRole else { return }
                    Task {
                        if selectedAuthMethod == .google {
                            // Complete Google signup with edited name
                            await viewModel.signUpWithGoogle(role: role)
                        } else {
                            // Email signup
                            await viewModel.signUp(email: email, password: password, displayName: displayName, role: role)
                        }
                    }
                }) {
                    Text(viewModel.isLoading ? "Creating Account..." : "Create Account")
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

    // MARK: - Helper Methods

    /// Handle Google Sign-In flow: authenticate, get user info, pre-fill form
    private func handleGoogleSignUp() async {
        guard let role = selectedRole else { return }

        // Trigger Google Sign-In (errors handled by viewModel)
        await viewModel.signUpWithGoogle(role: role)

        // If successful, user will be in viewModel.currentUser
        // Pre-fill form with Google data if user was created
        if let user = viewModel.currentUser {
            displayName = user.displayName
            email = user.email

            // Set auth method and navigate to form
            selectedAuthMethod = .google
            withAnimation {
                showAuthMethodSelection = false
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
