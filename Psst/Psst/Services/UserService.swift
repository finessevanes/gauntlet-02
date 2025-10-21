//
//  UserService.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #3
//  Service layer for user profile CRUD operations with Firestore
//

import Foundation
import FirebaseFirestore

/// Service for managing user profile data in Firestore
/// Handles CRUD operations, caching, and real-time listeners for the users collection
///
/// Validation Rules:
/// - uid: Non-empty, matches Firebase Auth UID
/// - email: Valid email format (enforced by Auth)
/// - displayName: 1-50 characters
/// - photoURL: Optional, valid URL format
class UserService {

    // MARK: - Singleton

    static let shared = UserService()

    // MARK: - Properties

    private let db = Firestore.firestore()
    private let usersCollection = "users"

    /// In-memory cache for fetched users to improve performance
    private var userCache: [String: User] = [:]

    /// Private initializer to enforce singleton pattern
    private init() {}

    // MARK: - Public Methods

    /// Creates a new user document in Firestore
    /// - Parameters:
    ///   - id: User's unique identifier (must match Firebase Auth UID)
    ///   - email: User's email address
    ///   - displayName: User's display name (1-50 characters)
    ///   - photoURL: Optional profile photo URL
    /// - Returns: Created User object
    /// - Throws: UserServiceError if validation fails or Firestore operation fails
    func createUser(id: String, email: String, displayName: String, photoURL: String? = nil) async throws -> User {
        // Validate inputs
        guard !id.isEmpty else {
            throw UserServiceError.invalidUserID
        }

        guard email.contains("@") else {
            throw UserServiceError.invalidEmail
        }

        guard !displayName.isEmpty && displayName.count <= 50 else {
            throw UserServiceError.validationFailed("Display name must be 1-50 characters")
        }

        // Create User object
        let now = Date()
        let user = User(
            id: id,
            email: email,
            displayName: displayName,
            photoURL: photoURL,
            createdAt: now,
            updatedAt: now
        )

        // Save to Firestore
        let start = Date()
        do {
            try await db.collection(usersCollection).document(id).setData(user.toDictionary())

            // Log performance
            let duration = Date().timeIntervalSince(start) * 1000
            print("[UserService] Created user \(id) in \(Int(duration))ms")

            // Cache the user
            userCache[id] = user

            return user
        } catch {
            print("[UserService] ❌ Failed to create user \(id): \(error.localizedDescription)")
            throw UserServiceError.createFailed(error)
        }
    }

    /// Fetches a user by ID from Firestore (with caching)
    /// - Parameter id: User's unique identifier
    /// - Returns: User object
    /// - Throws: UserServiceError.userNotFound if user doesn't exist
    func getUser(id: String) async throws -> User {
        // Check cache first
        if let cachedUser = userCache[id] {
            print("[UserService] Cache hit for user \(id)")
            return cachedUser
        }

        // Fetch from Firestore
        let start = Date()
        do {
            let document = try await db.collection(usersCollection).document(id).getDocument()

            guard document.exists else {
                throw UserServiceError.userNotFound
            }

            let user = try document.data(as: User.self)

            // Log performance
            let duration = Date().timeIntervalSince(start) * 1000
            print("[UserService] Fetched user \(id) in \(Int(duration))ms")

            // Cache the user
            userCache[id] = user

            return user
        } catch let error as UserServiceError {
            throw error
        } catch {
            print("[UserService] ❌ Failed to fetch user \(id): \(error.localizedDescription)")
            throw UserServiceError.fetchFailed(error)
        }
    }

    /// Batch fetch multiple users by IDs
    /// - Parameter ids: Array of user IDs to fetch
    /// - Returns: Array of successfully fetched User objects
    /// - Note: Continues on individual fetch failures, logs warnings for invalid IDs
    func getUsers(ids: [String]) async throws -> [User] {
        var users: [User] = []

        for id in ids {
            do {
                let user = try await getUser(id: id)
                users.append(user)
            } catch {
                print("[UserService] ⚠️ Failed to fetch user \(id) in batch: \(error.localizedDescription)")
                // Continue fetching other users
            }
        }

        return users
    }
    
    /// Fetches all users from Firestore users collection
    /// - Returns: Array of User objects
    /// - Throws: Firestore errors if query fails
    func fetchAllUsers() async throws -> [User] {
        let start = Date()
        
        do {
            let snapshot = try await db.collection(usersCollection).getDocuments()
            
            let users = snapshot.documents.compactMap { document -> User? in
                do {
                    return try document.data(as: User.self)
                } catch {
                    print("[UserService] ⚠️ Error decoding user \(document.documentID): \(error.localizedDescription)")
                    return nil
                }
            }
            
            // Log performance
            let duration = Date().timeIntervalSince(start) * 1000
            print("[UserService] Fetched \(users.count) users in \(Int(duration))ms")
            
            return users
        } catch {
            print("[UserService] ❌ Failed to fetch all users: \(error.localizedDescription)")
            throw UserServiceError.fetchFailed(error)
        }
    }

    /// Updates user profile data in Firestore
    /// - Parameters:
    ///   - id: User's unique identifier
    ///   - data: Dictionary of fields to update
    /// - Throws: UserServiceError if validation fails or Firestore operation fails
    func updateUser(id: String, data: [String: Any]) async throws {
        // Validate ID
        guard !id.isEmpty else {
            throw UserServiceError.invalidUserID
        }

        // Validate displayName if present
        if let displayName = data["displayName"] as? String {
            guard !displayName.isEmpty && displayName.count <= 50 else {
                throw UserServiceError.validationFailed("Display name must be 1-50 characters")
            }
        }

        // Add server timestamp for updatedAt
        var updateData = data
        updateData["updatedAt"] = FieldValue.serverTimestamp()

        // Update in Firestore
        let start = Date()
        do {
            try await db.collection(usersCollection).document(id).updateData(updateData)

            // Log performance
            let duration = Date().timeIntervalSince(start) * 1000
            print("[UserService] Updated user \(id) in \(Int(duration))ms")

            // Invalidate cache for this user
            userCache.removeValue(forKey: id)

        } catch {
            print("[UserService] ❌ Failed to update user \(id): \(error.localizedDescription)")
            throw UserServiceError.updateFailed(error)
        }
    }

    /// Observes real-time changes to a user document
    /// - Parameters:
    ///   - id: User's unique identifier
    ///   - completion: Callback with Result containing User or Error
    /// - Returns: ListenerRegistration for removing the listener
    func observeUser(id: String, completion: @escaping (Result<User, Error>) -> Void) -> ListenerRegistration {
        return db.collection(usersCollection).document(id).addSnapshotListener { [weak self] snapshot, error in
            if let error = error {
                print("[UserService] ❌ Listener error for user \(id): \(error.localizedDescription)")
                completion(.failure(UserServiceError.fetchFailed(error)))
                return
            }

            guard let snapshot = snapshot, snapshot.exists else {
                completion(.failure(UserServiceError.userNotFound))
                return
            }

            do {
                let user = try snapshot.data(as: User.self)

                // Cache the user
                self?.userCache[id] = user

                completion(.success(user))
            } catch {
                print("[UserService] ❌ Failed to decode user \(id): \(error.localizedDescription)")
                completion(.failure(UserServiceError.fetchFailed(error)))
            }
        }
    }

    /// Clears the in-memory user cache
    func clearCache() {
        userCache.removeAll()
        print("[UserService] Cache cleared")
    }
}

// MARK: - Error Types

/// Errors that can occur during UserService operations
enum UserServiceError: Error, LocalizedError, Equatable {
    case invalidUserID
    case invalidEmail
    case userNotFound
    case createFailed(Error)
    case updateFailed(Error)
    case fetchFailed(Error)
    case validationFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidUserID:
            return "User ID cannot be empty"
        case .invalidEmail:
            return "Invalid email format"
        case .userNotFound:
            return "User not found"
        case .createFailed(let error):
            return "Failed to create user: \(error.localizedDescription)"
        case .updateFailed(let error):
            return "Failed to update user: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch user: \(error.localizedDescription)"
        case .validationFailed(let message):
            return "Validation failed: \(message)"
        }
    }

    /// Custom Equatable implementation
    /// For cases with Error associated values, we compare by error description
    static func == (lhs: UserServiceError, rhs: UserServiceError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidUserID, .invalidUserID),
             (.invalidEmail, .invalidEmail),
             (.userNotFound, .userNotFound):
            return true
        case (.validationFailed(let lhsMessage), .validationFailed(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.createFailed(let lhsError), .createFailed(let rhsError)),
             (.updateFailed(let lhsError), .updateFailed(let rhsError)),
             (.fetchFailed(let lhsError), .fetchFailed(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}
