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

/// Placeholder for main app view after authentication
/// Will be replaced in future PRs with actual app content
struct MainAppView: View {
    @StateObject private var authService = AuthenticationService.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72))
                    .foregroundColor(.green)
                
                Text("Successfully Authenticated!")
                    .font(.title)
                    .fontWeight(.bold)
                
                if let user = authService.currentUser {
                    VStack(alignment: .leading, spacing: 8) {
                        if let email = user.email {
                            Text("Email: \(email)")
                                .font(.subheadline)
                        }
                        
                        if let displayName = user.displayName {
                            Text("Name: \(displayName)")
                                .font(.subheadline)
                        }
                        
                        Text("User ID: \(user.id)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                Text("Main app screens will be implemented in future PRs")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, 20)
                
                // Sign Out Button
                Button(action: {
                    Task {
                        try? await authService.signOut()
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.right.square.fill")
                        Text("Sign Out")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
            }
            .padding()
            .navigationTitle("Psst")
        }
    }
}

#Preview {
    ContentView()
}
