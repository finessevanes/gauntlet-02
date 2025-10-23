//
//  ContentView.swift
//  Psst
//
//  Created by Vanessa Mercado on 10/20/25.
//  Updated by Caleb (Coder Agent) - PR #2
//  Root view managing authentication state
//

import SwiftUI

/// Root content view that routes between authentication and main app
/// based on authentication state
struct ContentView: View {
    // MARK: - State Management
    
    @StateObject private var authService = AuthenticationService.shared
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if authService.currentUser != nil {
                // User is authenticated - show main app
                MainAppView()
            } else {
                // User is not authenticated - show login
                LoginView()
            }
        }
        .animation(.easeInOut, value: authService.currentUser)
    }
}

/// Main app view after authentication
/// Shows the conversation list (PR #6)
struct MainAppView: View {
    // Track selected tab for ChatListView
    @State private var selectedTab: Int = 0

    var body: some View {
        // Show ChatListView as main screen after authentication
        ChatListView(selectedTab: $selectedTab)
    }
}

#Preview {
    ContentView()
}
