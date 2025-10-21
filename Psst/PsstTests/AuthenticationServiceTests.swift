//
//  AuthenticationServiceTests.swift
//  PsstTests
//
//  Created by Caleb (Coder Agent) - PR #2
//  Unit tests for AuthenticationService
//

import Testing
@testable import Psst
import FirebaseAuth

/// Unit tests for AuthenticationService
/// Tests authentication operations including sign up, sign in, and sign out
@Suite("Authentication Service Tests")
struct AuthenticationServiceTests {
    
    // MARK: - User State Tests
    
    /// Verifies that getCurrentUser() returns nil when no user is authenticated
    @Test("Get Current User - When Not Authenticated Returns Nil")
    @MainActor func getCurrentUserWhenNotAuthenticatedReturnsNil() {
        // Given: AuthenticationService with no authenticated user
        // Firebase Auth current user is nil by default in tests
        
        // When: Getting current user
        let currentUser = AuthenticationService.shared.getCurrentUser()
        
        // Then: Should return nil
        #expect(currentUser == nil, "Current user should be nil when not authenticated")
    }
    
    // MARK: - Error Mapping Tests
    
    /// Verifies that the invalid email error has a user-friendly description
    @Test("Authentication Error - Invalid Email Has Correct Description")
    @MainActor func authenticationErrorInvalidEmailHasCorrectDescription() {
        // Given: Invalid email error
        let error = AuthenticationError.invalidEmail
        
        // When: Getting error description
        let description = error.errorDescription
        
        // Then: Should have user-friendly message
        #expect(description != nil)
        #expect(description?.contains("valid email") ?? false)
    }
    
    /// Verifies that the weak password error has a user-friendly description
    @Test("Authentication Error - Weak Password Has Correct Description")
    @MainActor func authenticationErrorWeakPasswordHasCorrectDescription() {
        // Given: Weak password error
        let error = AuthenticationError.weakPassword
        
        // When: Getting error description
        let description = error.errorDescription
        
        // Then: Should have user-friendly message
        #expect(description != nil)
        #expect(description?.contains("6 characters") ?? false)
    }
    
    /// Verifies that the user not found error has a user-friendly description
    @Test("Authentication Error - User Not Found Has Correct Description")
    @MainActor func authenticationErrorUserNotFoundHasCorrectDescription() {
        // Given: User not found error
        let error = AuthenticationError.userNotFound
        
        // When: Getting error description
        let description = error.errorDescription
        
        // Then: Should have user-friendly message
        #expect(description != nil)
        #expect(description?.contains("No account") ?? false)
    }
    
    /// Verifies that the wrong password error has a user-friendly description
    @Test("Authentication Error - Wrong Password Has Correct Description")
    @MainActor func authenticationErrorWrongPasswordHasCorrectDescription() {
        // Given: Wrong password error
        let error = AuthenticationError.wrongPassword
        
        // When: Getting error description
        let description = error.errorDescription
        
        // Then: Should have user-friendly message
        #expect(description != nil)
        #expect(description?.contains("Incorrect password") ?? false)
    }
    
    /// Verifies that the email already in use error has a user-friendly description
    @Test("Authentication Error - Email Already In Use Has Correct Description")
    @MainActor func authenticationErrorEmailAlreadyInUseHasCorrectDescription() {
        // Given: Email already in use error
        let error = AuthenticationError.emailAlreadyInUse
        
        // When: Getting error description
        let description = error.errorDescription
        
        // Then: Should have user-friendly message
        #expect(description != nil)
        #expect(description?.contains("already exists") ?? false)
    }
    
    /// Verifies that the Google sign-in failed error has a user-friendly description
    @Test("Authentication Error - Google Sign In Failed Has Correct Description")
    @MainActor func authenticationErrorGoogleSignInFailedHasCorrectDescription() {
        // Given: Google sign-in failed error
        let error = AuthenticationError.googleSignInFailed
        
        // When: Getting error description
        let description = error.errorDescription
        
        // Then: Should have user-friendly message
        #expect(description != nil)
        #expect(description?.contains("Google Sign-In failed") ?? false)
    }
    
    /// Verifies that the Google sign-in cancelled error has a user-friendly description
    @Test("Authentication Error - Google Sign In Cancelled Has Correct Description")
    @MainActor func authenticationErrorGoogleSignInCancelledHasCorrectDescription() {
        // Given: Google sign-in cancelled error
        let error = AuthenticationError.googleSignInCancelled
        
        // When: Getting error description
        let description = error.errorDescription
        
        // Then: Should have user-friendly message
        #expect(description != nil)
        #expect(description?.contains("cancelled") ?? false)
    }
    
    // MARK: - Service Contract Tests
    
    /// Verifies that AuthenticationService maintains a single shared instance
    @Test("Authentication Service Is Singleton")
    @MainActor func authenticationServiceIsSingleton() {
        // Given: Multiple references to AuthenticationService
        let instance1 = AuthenticationService.shared
        let instance2 = AuthenticationService.shared
        
        // Then: Should be same instance
        #expect(instance1 === instance2, "AuthenticationService should be a singleton")
    }
    
    /// Verifies that AuthenticationService exposes a currentUser property
    @Test("Authentication Service Has Current User Property")
    @MainActor func authenticationServiceHasCurrentUserProperty() {
        // Given: AuthenticationService instance
        let service = AuthenticationService.shared
        
        // Then: Should have currentUser property
        // This test verifies the property exists and is accessible
        _ = service.currentUser
    }
    
}

