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
    
    /// Presence service - injected from parent (PsstApp)
    @EnvironmentObject var presenceService: PresenceService
    
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
                    .id(authViewModel.currentUser?.id) // Force fresh view on each login
                    .environmentObject(authViewModel)
            } else {
                // User is not authenticated - show login flow
                LoginView()
                    .environmentObject(authViewModel)
            }
        }
        .animation(.easeInOut, value: isAuthenticated)
        .onAppear {
            // Inject presence service into auth view model for logout handling
            authViewModel.setPresenceService(presenceService)
        }
        .onChange(of: isAuthenticated) { oldValue, newValue in
            // Request notification permission after successful authentication
            if newValue && !hasRequestedPermission {
                Task {
                    do {
                        let granted = try await notificationService.requestPermission()
                        hasRequestedPermission = true
                        print("[RootView] Notification permission: \(granted ? "granted" : "denied")")
                        
                        // If permission granted, the FCM token will be refreshed automatically
                        // when the APNs token is received in AppDelegate
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
