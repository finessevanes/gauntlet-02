//
//  AuthenticationService.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #2
//  Handles all authentication operations using Firebase Auth
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn

/// Error types for authentication operations
enum AuthenticationError: LocalizedError {
    case invalidEmail
    case weakPassword
    case userNotFound
    case wrongPassword
    case emailAlreadyInUse
    case emptyDisplayName
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
        case .emptyDisplayName:
            return "Display name is required."
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
    
    /// Firestore user profile listener
    private var userProfileListener: ListenerRegistration?
    
    /// Private initializer to enforce singleton pattern
    private init() {
        // Observe auth state changes and update currentUser
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            if let firebaseUser = firebaseUser {
                // Initial user from Firebase Auth
                self?.currentUser = User(from: firebaseUser)
                
                // Attach Firestore listener for real-time profile updates
                self?.attachProfileListener(uid: firebaseUser.uid)
            } else {
                self?.currentUser = nil
                // Remove Firestore listener when signed out
                self?.detachProfileListener()
            }
        }
    }
    
    /// Attach real-time listener to user's Firestore profile
    private func attachProfileListener(uid: String) {
        // Remove existing listener if any
        detachProfileListener()
        
        // Listen for real-time updates to the user's profile
        userProfileListener = UserService.shared.observeUser(id: uid) { [weak self] result in
            switch result {
            case .success(let user):
                // Update currentUser with latest profile from Firestore
                DispatchQueue.main.async {
                    self?.currentUser = user
                }
            case .failure(let error):
                print("[AuthenticationService] ❌ Error observing user profile: \(error.localizedDescription)")
            }
        }
    }
    
    /// Remove Firestore profile listener
    private func detachProfileListener() {
        userProfileListener?.remove()
        userProfileListener = nil
    }
    
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
        detachProfileListener()
    }
    
    // MARK: - Email/Password Authentication
    
    /// Sign up a new user with email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password (min 6 characters)
    ///   - displayName: Required display name (no longer optional)
    ///   - role: User's role (trainer or client)
    /// - Returns: Newly created User object
    /// - Throws: AuthenticationError if signup fails
    func signUp(email: String, password: String, displayName: String, role: UserRole) async throws -> User {
        // Validate displayName is not empty or whitespace-only
        guard !displayName.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw AuthenticationError.emptyDisplayName
        }

        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let firebaseUser = result.user

            // Create user profile in Firestore
            do {
                let user = try await UserService.shared.createUser(
                    id: firebaseUser.uid,
                    email: firebaseUser.email ?? email,
                    displayName: displayName,
                    role: role,
                    photoURL: firebaseUser.photoURL?.absoluteString
                )
                print("[AuthenticationService] ✅ User profile created in Firestore for \(firebaseUser.uid) with role: \(role.rawValue)")
                return user
            } catch {
                print("[AuthenticationService] ❌ Failed to create Firestore profile for \(firebaseUser.uid): \(error.localizedDescription)")
                // Return User from Firebase Auth even if Firestore creation fails
                // This prevents user from being locked out if Firestore is temporarily unavailable
                return User(from: firebaseUser, role: role)
            }
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
    /// - Parameter role: User's role (trainer or client)
    /// - Returns: Newly created User object
    /// - Throws: AuthenticationError if Google sign-up fails
    func signUpWithGoogle(role: UserRole) async throws -> User {
        // Google Sign-In uses the same flow for both sign-up and sign-in
        // Firebase Auth automatically creates account if it doesn't exist
        return try await signInWithGoogle(role: role)
    }

    /// Sign in an existing user with Google authentication
    /// - Parameter role: User's role (only used for new users, optional for existing)
    /// - Returns: Authenticated User object
    /// - Throws: AuthenticationError if Google sign-in fails
    func signInWithGoogle(role: UserRole? = nil) async throws -> User {
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
        return try await performGoogleSignIn(with: viewController, role: role)
    }

    /// Perform the actual Google Sign-In and Firebase authentication
    /// Must be called from main thread
    /// - Parameters:
    ///   - viewController: The presenting view controller
    ///   - role: User's role (only used for new users, optional for existing)
    @MainActor
    private func performGoogleSignIn(with viewController: UIViewController, role: UserRole?) async throws -> User {
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
            let firebaseUser = authResult.user

            // Check if this is a new user and create Firestore profile if needed
            if authResult.additionalUserInfo?.isNewUser == true {
                do {
                    let displayName = firebaseUser.displayName ?? firebaseUser.email?.components(separatedBy: "@").first ?? "User"
                    // Use provided role, or default to trainer if not specified (for backward compatibility)
                    let userRole = role ?? .trainer
                    let user = try await UserService.shared.createUser(
                        id: firebaseUser.uid,
                        email: firebaseUser.email ?? "",
                        displayName: displayName,
                        role: userRole,
                        photoURL: firebaseUser.photoURL?.absoluteString
                    )
                    print("[AuthenticationService] ✅ User profile created in Firestore for Google user \(firebaseUser.uid) with role: \(userRole.rawValue)")
                    return user
                } catch {
                    print("[AuthenticationService] ❌ Failed to create Firestore profile for Google user \(firebaseUser.uid): \(error.localizedDescription)")
                    // Return User from Firebase Auth even if Firestore creation fails
                    return User(from: firebaseUser, role: role ?? .trainer)
                }
            } else {
                return User(from: firebaseUser)
            }

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

