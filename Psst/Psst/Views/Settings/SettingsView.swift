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
                size: 60,
                displayName: authViewModel.currentUser?.displayName
            )
            
            // User Info (name, email, and role badge)
            VStack(alignment: .leading, spacing: 4) {
                Text(authViewModel.currentUser?.displayName ?? "User")
                    .font(.headline)
                    .fontWeight(.bold)

                Text(authViewModel.currentUser?.email ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                // Role badge (PR #6.5 & PR #007)
                if let role = authViewModel.currentUser?.role {
                    HStack(spacing: 4) {
                        Image(systemName: role == .trainer ? "person.fill.checkmark" : "figure.walk")
                            .font(.caption2)

                        Text(role == .trainer ? "Trainer" : "Client")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(role == .trainer ? Color.blue.opacity(0.15) : Color.green.opacity(0.15))
                    .foregroundColor(role == .trainer ? .blue : .green)
                    .cornerRadius(12)
                }
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
    
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environmentObject(AuthViewModel())
}
