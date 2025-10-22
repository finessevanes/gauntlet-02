//
//  RootView.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #4
//  Root navigation controller for the app
//  Manages conditional navigation based on authentication state
//

import SwiftUI

/// Root view that manages app-level navigation
/// Shows authentication screens when logged out, main app when logged in
struct RootView: View {
    // MARK: - State Management

    /// Authentication view model - observes auth state changes
    @StateObject private var authViewModel = AuthViewModel()
    
    /// Notification service - injected from parent (PsstApp)
    @EnvironmentObject var notificationService: NotificationService
    
    /// Track if permission has been requested to avoid duplicate prompts
    @AppStorage("hasRequestedNotificationPermission") private var hasRequestedPermission = false

    // MARK: - Computed Properties

    /// Check if user is authenticated based on currentUser
    private var isAuthenticated: Bool {
        authViewModel.currentUser != nil
    }

    // MARK: - Body

    var body: some View {
        Group {
            if isAuthenticated {
                // User is authenticated - show main app with tabs
                MainTabView()
                    .environmentObject(authViewModel)
            } else {
                // User is not authenticated - show login flow
                LoginView()
                    .environmentObject(authViewModel)
            }
        }
        .animation(.easeInOut, value: isAuthenticated)
        .onChange(of: isAuthenticated) { oldValue, newValue in
            // Request notification permission after successful authentication
            if newValue && !hasRequestedPermission {
                Task {
                    do {
                        let granted = try await notificationService.requestPermission()
                        hasRequestedPermission = true
                        print("[RootView] Notification permission: \(granted ? "granted" : "denied")")
                    } catch {
                        print("[RootView] Error requesting permission: \(error.localizedDescription)")
                        hasRequestedPermission = true // Don't ask again even if error
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    RootView()
}
