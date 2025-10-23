//
//  SettingsView.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #4
//  Updated by Caleb (Coder Agent) - PR #17 (Edit Profile integration)
//

import SwiftUI

/// Settings view with logout functionality and profile editing
/// Additional settings features will be implemented in Phase 4
struct SettingsView: View {
    // MARK: - State Management

    /// Authentication view model for logout functionality
    @EnvironmentObject var authViewModel: AuthViewModel

    /// Show error alert
    @State private var showErrorAlert: Bool = false
    
    /// Show notification test view
    @State private var showNotificationTest = false

    // MARK: - Body

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()

                // Feature icon
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 72))
                    .foregroundColor(.gray)

                // Title
                Text("Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                // Logged-in user info
                if let currentUser = authViewModel.currentUser {
                    VStack(spacing: 8) {
                        Text("Logged in as:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(currentUser.email)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .padding(.bottom, 16)
                }

                // Coming soon message
                Text("Coming Soon in Phase 4")
                    .font(.title3)
                    .foregroundColor(.secondary)

                // Description
                Text("This screen will contain app settings and preferences.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()
                
                // Notification Test Button (Debug only)
                #if DEBUG
                Button(action: {
                    showNotificationTest = true
                }) {
                    HStack {
                        Image(systemName: "bell.fill")
                        Text("Test Notifications")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                #endif

                // Logout Button
                Button(action: {
                    Task {
                        await authViewModel.signOut()
                        // Check for error after sign out
                        if authViewModel.errorMessage != nil {
                            showErrorAlert = true
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.right.square.fill")
                        Text("Log Out")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .navigationTitle("Settings")
            .alert("Logout Error", isPresented: $showErrorAlert) {
                Button("OK") {
                    authViewModel.clearError()
                }
            } message: {
                Text(authViewModel.errorMessage ?? "An error occurred while logging out.")
            }
            .sheet(isPresented: $showNotificationTest) {
                NotificationTestView()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environmentObject(AuthViewModel())
}
