//
//  AuthViewModel.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #2
//  ViewModel for authentication state management
//

import Foundation
import SwiftUI
import Combine
import FirebaseDatabase

// MARK: - Notification Names

extension Notification.Name {
    /// Posted before user logout to allow cleanup of Firestore listeners
    static let userWillLogout = Notification.Name("userWillLogout")
}

/// ViewModel managing authentication UI state and operations
/// Thin wrapper around AuthenticationService following MVVM pattern
@MainActor
class AuthViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Current authenticated user
    @Published var currentUser: User?
    
    /// Loading state for async operations
    @Published var isLoading: Bool = false
    
    /// Error message to display to user
    @Published var errorMessage: String?
    
    /// Success message for password reset
    @Published var successMessage: String?
    
    // MARK: - Dependencies
    
    /// Authentication service instance
    private let authService: AuthenticationService
    
    /// Presence service for setting online/offline status
    private var presenceService: PresenceService?
    
    /// Cancellable for auth state subscription
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Initialize with authentication service
    /// - Parameter authService: AuthenticationService instance (defaults to shared)
    init(authService: AuthenticationService = .shared) {
        self.authService = authService
        
        // Subscribe to auth service's currentUser changes
        authService.$currentUser
            .assign(to: &$currentUser)
    }
    
    /// Set presence service for logout handling
    /// Must be called after initialization to avoid dependency injection issues
    /// - Parameter service: PresenceService instance
    func setPresenceService(_ service: PresenceService) {
        self.presenceService = service
    }
    
    // MARK: - Email/Password Authentication
    
    /// Sign up a new user with email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    ///   - displayName: Optional display name (defaults to email prefix if not provided)
    func signUp(email: String, password: String, displayName: String? = nil) async {
        clearMessages()
        isLoading = true
        
        do {
            _ = try await authService.signUp(email: email, password: password, displayName: displayName)
            // Success - currentUser will be updated automatically via ObservableObject
        } catch let error as AuthenticationError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "An unexpected error occurred. Please try again."
        }
        
        isLoading = false
    }
    
    /// Sign in an existing user with email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    func signIn(email: String, password: String) async {
        clearMessages()
        isLoading = true
        
        do {
            _ = try await authService.signIn(email: email, password: password)
            // Success - currentUser will be updated automatically via ObservableObject
        } catch let error as AuthenticationError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "An unexpected error occurred. Please try again."
        }
        
        isLoading = false
    }
    
    // MARK: - Google Sign-In Authentication
    
    /// Sign up a new user with Google authentication
    func signUpWithGoogle() async {
        clearMessages()
        isLoading = true
        
        do {
            _ = try await authService.signUpWithGoogle()
            // Success - currentUser will be updated automatically via ObservableObject
        } catch let error as AuthenticationError {
            // Don't show error for user cancellation
            if case .googleSignInCancelled = error {
                // User cancelled, no error message needed
            } else {
                errorMessage = error.errorDescription
            }
        } catch {
            errorMessage = "An unexpected error occurred. Please try again."
        }
        
        isLoading = false
    }
    
    /// Sign in an existing user with Google authentication
    func signInWithGoogle() async {
        clearMessages()
        isLoading = true
        
        do {
            _ = try await authService.signInWithGoogle()
            // Success - currentUser will be updated automatically via ObservableObject
        } catch let error as AuthenticationError {
            // Don't show error for user cancellation
            if case .googleSignInCancelled = error {
                // User cancelled, no error message needed
            } else {
                errorMessage = error.errorDescription
            }
        } catch {
            errorMessage = "An unexpected error occurred. Please try again."
        }
        
        isLoading = false
    }
    
    // MARK: - Sign Out
    
    /// Sign out the current user
    func signOut() async {
        clearMessages()
        isLoading = true
        
        do {
            // CRITICAL: Disconnect from Firebase Realtime Database BEFORE signing out
            // This triggers the onDisconnect() hook which sets status to offline
            // We can't manually set offline because auth token gets invalidated
            print("[AuthViewModel] Disconnecting from Firebase Database to trigger offline status...")
            
            // Force disconnect which triggers onDisconnect() hook
            Database.database().goOffline()
            
            // Wait a moment for the disconnect to process
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Post notification to cleanup all Firestore listeners BEFORE auth invalidation
            print("[AuthViewModel] Posting logout notification to cleanup Firestore listeners...")
            await MainActor.run {
                NotificationCenter.default.post(name: .userWillLogout, object: nil)
            }
            
            // Small delay to let listeners cleanup
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            // Reset tab selection to Conversations for next login
            UserDefaults.standard.set(0, forKey: "selectedTab")
            
            // Now sign out (this invalidates auth token)
            try await authService.signOut()
            // Success - currentUser will be cleared automatically via ObservableObject
            
            print("[AuthViewModel] User signed out successfully")
        } catch let error as AuthenticationError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "An unexpected error occurred. Please try again."
        }
        
        isLoading = false
    }
    
    // MARK: - Password Reset
    
    /// Send password reset email to user
    /// - Parameter email: User's email address
    func resetPassword(email: String) async {
        clearMessages()
        isLoading = true
        
        do {
            try await authService.resetPassword(email: email)
            successMessage = "Password reset email sent. Please check your inbox."
        } catch let error as AuthenticationError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "An unexpected error occurred. Please try again."
        }
        
        isLoading = false
    }
    
    // MARK: - Helpers
    
    /// Clear all messages
    private func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
    
    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
    
    /// Clear success message
    func clearSuccess() {
        successMessage = nil
    }
}

