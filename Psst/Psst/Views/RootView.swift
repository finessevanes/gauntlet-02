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
/// Shows loading screen during auth check, then authentication screens when logged out, main app when logged in
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
    
    /// Track if initial auth check is complete to show loading screen
    @State private var isInitialAuthCheckComplete = false

    // MARK: - Computed Properties

    /// Check if user is authenticated based on currentUser
    private var isAuthenticated: Bool {
        authViewModel.currentUser != nil
    }
    
    /// Check if we should show loading screen (during initial auth check)
    private var shouldShowLoadingScreen: Bool {
        !isInitialAuthCheckComplete
    }

    // MARK: - Body

    var body: some View {
        Group {
            if shouldShowLoadingScreen {
                // Show loading screen during initial auth check
                LoadingScreenView()
            } else if isAuthenticated {
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
        .animation(.easeInOut, value: shouldShowLoadingScreen)
        .onAppear {
            // Inject presence service into auth view model for logout handling
            authViewModel.setPresenceService(presenceService)
            
            // Start initial auth check with a small delay to ensure loading screen appears
            Task {
                // Small delay to ensure loading screen is visible
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                
                // Mark auth check as complete
                await MainActor.run {
                    isInitialAuthCheckComplete = true
                }
            }
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
