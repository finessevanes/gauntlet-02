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
        }
    }
    
    // MARK: - User Info Section
    
    /// User info header with profile photo, name, and email
    private var userInfoSection: some View {
        HStack(spacing: 16) {
            // Profile Photo (60pt circular)
            ProfilePhotoPreview(
                imageURL: authViewModel.currentUser?.photoURL,
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
    
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environmentObject(AuthViewModel())
}
