//
//  SettingsView.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #4
//  Updated by Caleb (Coder Agent) - PR #17 (Edit Profile integration)
//  Redesigned by Caleb (Coder Agent) - PR #006C (iOS grouped list)
//

import SwiftUI

/// Settings view with iOS-native grouped list design
/// Includes user info, account settings, support options, and logout
struct SettingsView: View {
    // MARK: - Environment
    
    /// Authentication view model for logout functionality
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // MARK: - State
    
    /// Logout loading state
    @State private var isLoggingOut = false
    
    /// Show logout error alert
    @State private var showLogoutError = false
    
    /// Error message for logout failures
    @State private var errorMessage = ""
    
    /// Show notification test view
    @State private var showNotificationTest = false
    
    /// AI backend test state
    @State private var testingAI = false
    @State private var aiTestResult = ""
    @State private var showAITestResult = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            List {
                // User Info Section (custom header, not in Section)
                userInfoSection
                
                // Account Section
                Section(header: Text("ACCOUNT")) {
                    NavigationLink(destination: NotificationsSettingsView()) {
                        Label("Notifications", systemImage: "bell.circle")
                    }
                }
                
                // Support Section
                Section(header: Text("SUPPORT")) {
                    NavigationLink(destination: HelpSupportView()) {
                        Label("Help & Support", systemImage: "questionmark.circle")
                    }
                    
                    NavigationLink(destination: AboutView()) {
                        Label("About", systemImage: "info.circle")
                    }
                }
                
                // Notification Test Button (Debug only)
                #if DEBUG
                Section(header: Text("DEBUG")) {
                    Button(action: {
                        showNotificationTest = true
                    }) {
                        HStack {
                            Image(systemName: "bell.fill")
                            Text("Test Notifications")
                                .fontWeight(.semibold)
                        }
                    }
                    
                    Button(action: testAIBackend) {
                        HStack {
                            if testingAI {
                                ProgressView()
                                    .padding(.trailing, 8)
                            } else {
                                Image(systemName: "brain")
                            }
                            Text(testingAI ? "Testing AI..." : "Test AI Backend")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(testingAI)
                }
                #endif
                
                // Logout Button Section
                Section {
                    logoutButton
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Logout Error", isPresented: $showLogoutError) {
                Button("OK", role: .cancel) {
                    showLogoutError = false
                }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showNotificationTest) {
                NotificationTestView()
            }
            .alert("AI Backend Test Result", isPresented: $showAITestResult) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(aiTestResult)
            }
        }
    }
    
    // MARK: - User Info Section
    
    /// User info header with profile photo, name, and email
    private var userInfoSection: some View {
        HStack(spacing: 16) {
            // Profile Photo (60pt circular)
            ProfilePhotoPreview(
                imageURL: authViewModel.currentUser?.photoURL,
                userID: authViewModel.currentUser?.id,
                selectedImage: nil,
                isLoading: false,
                size: 60
            )
            
            // User Info (name and email)
            VStack(alignment: .leading, spacing: 4) {
                Text(authViewModel.currentUser?.displayName ?? "User")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text(authViewModel.currentUser?.email ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .listRowBackground(Color(.secondarySystemBackground))
    }
    
    // MARK: - Logout Button
    
    /// Logout button with destructive styling and loading state
    private var logoutButton: some View {
        Button(action: handleLogout) {
            if isLoggingOut {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(.white)
                    Text("Logging out...")
                        .foregroundColor(.white)
                        .padding(.leading, 8)
                    Spacer()
                }
            } else {
                HStack {
                    Spacer()
                    Text("Log Out")
                        .foregroundColor(.white)
                    Spacer()
                }
            }
        }
        .buttonStyle(.borderedProminent)
        .tint(.red)
        .disabled(isLoggingOut)
        .listRowBackground(Color.clear)
    }
    
    // MARK: - Methods
    
    /// Handles logout button tap
    /// Shows loading state, signs out user, and handles errors
    private func handleLogout() {
        isLoggingOut = true
        
        Task {
            // Call AuthViewModel's signOut method (async)
            await authViewModel.signOut()
            
            // Check for errors after signout
            if let error = authViewModel.errorMessage {
                errorMessage = error
                showLogoutError = true
                isLoggingOut = false
            }
            // Navigation handled by AuthViewModel (returns to LoginView)
        }
    }
    
    /// Tests the AI backend (PR #003)
    /// Calls the production chatWithAI Cloud Function
    private func testAIBackend() {
        testingAI = true
        
        Task {
            do {
                let aiService = AIService()
                let response = try await aiService.testRealChatWithAI(
                    message: "Hhey, what did jameson say last?"
                )
                
                await MainActor.run {
                    aiTestResult = """
                    ✅ SUCCESS!
                    
                    AI Response:
                    \(response.text)
                    
                    Tokens Used: \(response.metadata?.tokensUsed ?? 0)
                    Model: \(response.metadata?.modelUsed ?? "unknown")
                    """
                    showAITestResult = true
                    testingAI = false
                }
                
                print("✅ AI Backend Test Successful!")
                print("Response: \(response.text)")
                
            } catch {
                await MainActor.run {
                    aiTestResult = """
                    ❌ ERROR
                    
                    \(error.localizedDescription)
                    """
                    showAITestResult = true
                    testingAI = false
                }
                
                print("❌ AI Backend Test Failed: \(error)")
            }
        }
    }
    
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environmentObject(AuthViewModel())
}
