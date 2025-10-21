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
    }
}

// MARK: - Preview

#Preview {
    RootView()
}
