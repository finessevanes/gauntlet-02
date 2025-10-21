//
//  AuthenticationService.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #2
//  Handles all authentication operations using Firebase Auth
//

import Foundation
import FirebaseAuth
import GoogleSignIn

/// Error types for authentication operations
enum AuthenticationError: LocalizedError {
    case invalidEmail
    case weakPassword
    case userNotFound
    case wrongPassword
    case emailAlreadyInUse
    case networkError
    case googleSignInFailed
    case googleSignInCancelled
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address."
        case .weakPassword:
            return "Password must be at least 6 characters long."
        case .userNotFound:
            return "No account found with this email. Please sign up."
        case .wrongPassword:
            return "Incorrect password. Please try again."
        case .emailAlreadyInUse:
            return "An account with this email already exists."
        case .networkError:
            return "Network error. Please check your connection and try again."
        case .googleSignInFailed:
            return "Google Sign-In failed. Please try again."
        case .googleSignInCancelled:
            return "Google Sign-In was cancelled."
        case .unknownError(let message):
            return "An error occurred: \(message)"
        }
    }
}

/// Service handling all authentication operations
/// Singleton pattern for app-wide auth state management
class AuthenticationService: ObservableObject {
    /// Shared instance for app-wide access
    static let shared = AuthenticationService()
    
    /// Current authenticated user
    @Published var currentUser: User?
    
    /// Authentication state listener handle
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    /// Private initializer to enforce singleton pattern
    private init() {
        // Observe auth state changes and update currentUser
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            if let firebaseUser = firebaseUser {
                self?.currentUser = User(from: firebaseUser)
            } else {
                self?.currentUser = nil
            }
        }
    }
    
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    // MARK: - Email/Password Authentication
    
    /// Sign up a new user with email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password (min 6 characters)
    /// - Returns: Newly created User object
    /// - Throws: AuthenticationError if signup fails
    func signUp(email: String, password: String) async throws -> User {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            return User(from: result.user)
        } catch let error as NSError {
            throw mapFirebaseError(error)
        }
    }
    
    /// Sign in an existing user with email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    /// - Returns: Authenticated User object
    /// - Throws: AuthenticationError if signin fails
    func signIn(email: String, password: String) async throws -> User {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            return User(from: result.user)
        } catch let error as NSError {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Google Sign-In Authentication
    
    /// Sign up a new user with Google authentication
    /// - Returns: Newly created User object
    /// - Throws: AuthenticationError if Google sign-up fails
    func signUpWithGoogle() async throws -> User {
        // Google Sign-In uses the same flow for both sign-up and sign-in
        // Firebase Auth automatically creates account if it doesn't exist
        return try await signInWithGoogle()
    }
    
    /// Sign in an existing user with Google authentication
    /// - Returns: Authenticated User object
    /// - Throws: AuthenticationError if Google sign-in fails
    func signInWithGoogle() async throws -> User {
        // Get the presenting view controller on the main thread
        let viewController = await MainActor.run {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first?.rootViewController else {
                return nil as UIViewController?
            }
            return rootViewController
        }
        
        guard let viewController = viewController else {
            throw AuthenticationError.googleSignInFailed
        }
        
        // Get Firebase client ID from GoogleService-Info.plist
        guard let clientID = Auth.auth().app?.options.clientID else {
            throw AuthenticationError.googleSignInFailed
        }
        
        // Configure Google Sign-In
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        // Perform Google Sign-In (must be on main thread)
        return try await performGoogleSignIn(with: viewController)
    }
    
    /// Perform the actual Google Sign-In and Firebase authentication
    /// Must be called from main thread
    @MainActor
    private func performGoogleSignIn(with viewController: UIViewController) async throws -> User {
        do {
            // Start Google Sign-In flow (this presents UI)
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)
            
            guard let idToken = result.user.idToken?.tokenString else {
                throw AuthenticationError.googleSignInFailed
            }
            
            let accessToken = result.user.accessToken.tokenString
            
            // Create Firebase credential from Google tokens
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: accessToken
            )
            
            // Sign in to Firebase with Google credential
            let authResult = try await Auth.auth().signIn(with: credential)
            return User(from: authResult.user)
            
        } catch let error as NSError {
            // Handle Google Sign-In cancellation
            if error.domain == "com.google.GIDSignIn" && error.code == -5 {
                throw AuthenticationError.googleSignInCancelled
            }
            throw AuthenticationError.googleSignInFailed
        }
    }
    
    // MARK: - Sign Out
    
    /// Sign out the current user
    /// - Throws: AuthenticationError if signout fails
    func signOut() async throws {
        do {
            try Auth.auth().signOut()
            // Also sign out from Google if signed in with Google
            GIDSignIn.sharedInstance.signOut()
        } catch let error as NSError {
            throw AuthenticationError.unknownError(error.localizedDescription)
        }
    }
    
    // MARK: - Password Reset
    
    /// Send password reset email to user
    /// - Parameter email: User's email address
    /// - Throws: AuthenticationError if reset email fails
    func resetPassword(email: String) async throws {
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch let error as NSError {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - User State
    
    /// Get the currently authenticated user
    /// - Returns: Current User object, or nil if not authenticated
    func getCurrentUser() -> User? {
        guard let firebaseUser = Auth.auth().currentUser else {
            return nil
        }
        return User(from: firebaseUser)
    }
    
    /// Observe authentication state changes
    /// - Parameter completion: Callback fired when auth state changes
    /// - Returns: Listener handle (not used in SwiftUI, but kept for API contract)
    func observeAuthState(completion: @escaping (User?) -> Void) -> NSObjectProtocol {
        return Auth.auth().addStateDidChangeListener { _, firebaseUser in
            if let firebaseUser = firebaseUser {
                completion(User(from: firebaseUser))
            } else {
                completion(nil)
            }
        }
    }
    
    // MARK: - Error Mapping
    
    /// Map Firebase Auth errors to user-friendly AuthenticationError
    /// - Parameter error: Firebase NSError
    /// - Returns: Mapped AuthenticationError
    private func mapFirebaseError(_ error: NSError) -> AuthenticationError {
        guard let errorCode = AuthErrorCode(_bridgedNSError: error) else {
            return .unknownError(error.localizedDescription)
        }
        
        switch errorCode.code {
        case .invalidEmail:
            return .invalidEmail
        case .weakPassword:
            return .weakPassword
        case .userNotFound:
            return .userNotFound
        case .wrongPassword:
            return .wrongPassword
        case .emailAlreadyInUse:
            return .emailAlreadyInUse
        case .networkError:
            return .networkError
        default:
            return .unknownError(error.localizedDescription)
        }
    }
}

