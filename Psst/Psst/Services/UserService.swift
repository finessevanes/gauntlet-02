//
//  UserService.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #3
//  Service layer for user profile CRUD operations with Firestore
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import UIKit

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
    
    // MARK: - Profile Editing Methods (PR #17)
    
    /// Updates user profile information (display name and/or profile photo URL)
    /// - Parameters:
    ///   - uid: User's unique identifier
    ///   - displayName: New display name (optional, validates 2-50 characters)
    ///   - profilePhotoURL: New profile photo URL from Firebase Storage (optional)
    /// - Throws: UserServiceError if validation fails or update fails
    func updateUserProfile(uid: String, displayName: String?, profilePhotoURL: String?) async throws {
        let start = Date()
        
        // Validate uid
        guard !uid.isEmpty else {
            throw UserServiceError.invalidUserID
        }
        
        // Validate displayName if provided
        if let displayName = displayName {
            guard displayName.count >= 2 && displayName.count <= 50 else {
                throw UserServiceError.validationFailed("Display name must be 2-50 characters")
            }
        }
        
        // Build update data dictionary
        var updateData: [String: Any] = [:]
        
        if let displayName = displayName {
            updateData["displayName"] = displayName
        }
        
        if let profilePhotoURL = profilePhotoURL {
            updateData["photoURL"] = profilePhotoURL
        }
        
        // Add server timestamp for updatedAt
        updateData["updatedAt"] = FieldValue.serverTimestamp()
        
        // Ensure we have at least one field to update
        guard updateData.count > 1 else { // >1 because updatedAt is always included
            print("[UserService] ⚠️ No fields to update for user \(uid)")
            return
        }
        
        // Update in Firestore
        do {
            try await db.collection(usersCollection).document(uid).updateData(updateData)
            
            // Log performance
            let duration = Date().timeIntervalSince(start) * 1000
            print("[UserService] Updated profile for user \(uid) in \(Int(duration))ms")
            
            // Invalidate cache
            userCache.removeValue(forKey: uid)
            
        } catch {
            print("[UserService] ❌ Failed to update profile for user \(uid): \(error.localizedDescription)")
            throw UserServiceError.updateFailed(error)
        }
    }
    
    /// Uploads a profile photo to Firebase Storage with compression
    /// - Parameters:
    ///   - uid: User's unique identifier
    ///   - imageData: Image data to upload (will be compressed if >1MB)
    /// - Returns: Download URL string for the uploaded photo
    /// - Throws: ProfilePhotoError with specific error details
    func uploadProfilePhoto(uid: String, imageData: Data) async throws -> String {
        let start = Date()
        
        // Validate uid
        guard !uid.isEmpty else {
            throw UserServiceError.invalidUserID
        }
        
        // Check network connectivity first
        guard await checkNetworkConnectivity() else {
            print("[UserService] ❌ Upload blocked: No network connection")
            throw ProfilePhotoError.networkUnavailable
        }
        
        print("[UserService] Starting profile photo upload for user \(uid), original size: \(imageData.count) bytes")
        
        // Convert to UIImage first
        guard let image = UIImage(data: imageData) else {
            print("[UserService] ❌ Invalid image data")
            throw ProfilePhotoError.invalidImageData
        }
        
        // Attempt compression FIRST (this handles large images)
        let compressedData: Data
        do {
            compressedData = try await compressImage(image, maxSizeKB: 1000)
            print("[UserService] ✅ Compression complete: \(compressedData.count) bytes")
        } catch {
            print("[UserService] ❌ Compression failed: \(error.localizedDescription)")
            throw error
        }
        
        // NOW validate the COMPRESSED data
        do {
            try validateImageData(compressedData)
        } catch {
            print("[UserService] ❌ Compressed image still too large: \(error.localizedDescription)")
            throw error
        }
        
        // Upload to Firebase Storage
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let filePath = "profile_photos/\(uid)/profile.jpg"
        let fileRef = storageRef.child(filePath)
        
        // Set metadata
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        do {
            // Upload the image
            print("[UserService] Uploading to path: \(filePath)")
            print("[UserService] Upload size: \(compressedData.count) bytes")
            
            let uploadMetadata = try await fileRef.putData(compressedData, metadata: metadata)
            
            print("[UserService] ✅ Upload completed successfully")
            print("[UserService] Upload metadata: \(uploadMetadata)")
            
            // Get download URL after successful upload with retry logic
            // Firebase Storage sometimes has a brief propagation delay
            print("[UserService] Fetching download URL...")
            let downloadURL = try await fetchDownloadURLWithRetry(fileRef: fileRef, maxAttempts: 5)
            
            // Log performance
            let duration = Date().timeIntervalSince(start) * 1000
            print("[UserService] ✅ Uploaded profile photo for user \(uid) in \(Int(duration))ms")
            print("[UserService] Download URL: \(downloadURL.absoluteString)")
            
            // Invalidate cache for this user so new photo will be fetched
            await ImageCacheService.shared.invalidateProfilePhotoCache(userID: uid)
            
            return downloadURL.absoluteString
            
        } catch let error as NSError {
            print("[UserService] ❌ Failed to upload profile photo for user \(uid)")
            print("[UserService] Error domain: \(error.domain)")
            print("[UserService] Error code: \(error.code)")
            print("[UserService] Error description: \(error.localizedDescription)")
            print("[UserService] Error details: \(error)")
            print("[UserService] User info: \(error.userInfo)")
            
            // Check for specific Firebase Storage errors
            if error.domain == "FIRStorageErrorDomain" {
                print("[UserService] Firebase Storage Error Code: \(error.code)")
                
                // Error code -13021 is permission denied
                if error.code == -13021 {
                    throw ProfilePhotoError.permissionDenied
                }
            }
            
            throw ProfilePhotoError.uploadFailed(reason: error.localizedDescription)
        }
    }
    
    /// Validates image data format and size
    /// - Parameter data: Image data to validate
    /// - Throws: ProfilePhotoError if validation fails
    func validateImageData(_ data: Data) throws {
        // Check if data is empty
        guard !data.isEmpty else {
            throw ProfilePhotoError.invalidImageData
        }
        
        // Validate maximum size (5MB)
        let maxSizeBytes = 5 * 1024 * 1024 // 5MB
        if data.count > maxSizeBytes {
            let sizeInMB = Double(data.count) / (1024.0 * 1024.0)
            let maxSizeInMB = Double(maxSizeBytes) / (1024.0 * 1024.0)
            throw ProfilePhotoError.imageTooLarge(sizeInMB: sizeInMB, maxSizeInMB: maxSizeInMB)
        }
        
        // Validate image format by checking magic bytes
        let pngHeader: [UInt8] = [0x89, 0x50, 0x4E, 0x47]
        let jpegHeader: [UInt8] = [0xFF, 0xD8, 0xFF]
        
        let headerBytes = [UInt8](data.prefix(4))
        
        let isPNG = headerBytes.prefix(4).elementsEqual(pngHeader)
        let isJPEG = headerBytes.prefix(3).elementsEqual(jpegHeader)
        
        // Also check if UIImage can decode it (covers HEIC and other formats)
        let canDecode = UIImage(data: data) != nil
        
        guard isPNG || isJPEG || canDecode else {
            // Try to determine format from data
            let format = String(data: data.prefix(10), encoding: .utf8) ?? "unknown"
            throw ProfilePhotoError.invalidFormat(format: format)
        }
        
        print("[UserService] ✅ Image validation passed (\(data.count) bytes)")
    }
    
    /// Compresses an image to target size with quality fallback
    /// - Parameters:
    ///   - image: UIImage to compress
    ///   - maxSizeKB: Maximum size in kilobytes (default: 500KB)
    /// - Returns: Compressed image data
    /// - Throws: ProfilePhotoError.compressionFailed if compression fails
    func compressImage(_ image: UIImage, maxSizeKB: Int = 500) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            // Run compression on background thread to avoid blocking UI
            DispatchQueue.global(qos: .userInitiated).async {
                let maxSizeBytes = maxSizeKB * 1024
                var compressionQuality: CGFloat = 0.8
                var compressedData: Data?
                
                print("[UserService] Starting compression (target: \(maxSizeKB)KB)...")
                
                // Try to compress with decreasing quality until size is acceptable
                var attempts = 0
                let maxAttempts = 10
                
                while compressionQuality >= 0.3 && attempts < maxAttempts {
                    attempts += 1
                    
                    guard let data = image.jpegData(compressionQuality: compressionQuality) else {
                        print("[UserService] ❌ Failed to create JPEG data at quality \(compressionQuality)")
                        compressionQuality -= 0.1
                        continue
                    }
                    
                    print("[UserService] Attempt \(attempts): \(data.count) bytes at quality \(String(format: "%.1f", compressionQuality))")
                    
                    if data.count <= maxSizeBytes {
                        compressedData = data
                        print("[UserService] ✅ Compression successful: \(data.count) bytes")
                        break
                    }
                    
                    compressionQuality -= 0.1
                }
                
                // If still too large, use the last compressed version
                if compressedData == nil {
                    compressedData = image.jpegData(compressionQuality: 0.3)
                    print("[UserService] ⚠️ Using minimum compression quality")
                }
                
                guard let finalData = compressedData else {
                    continuation.resume(throwing: ProfilePhotoError.compressionFailed)
                    return
                }
                
                continuation.resume(returning: finalData)
            }
        }
    }
    
    /// Checks if device has network connectivity
    /// - Returns: True if connected, false if offline
    func checkNetworkConnectivity() async -> Bool {
        return NetworkMonitor.shared.isConnected
    }
    
    /// Loads profile photo with cache-first strategy
    /// - Parameter userID: User's unique identifier
    /// - Returns: UIImage from cache or network
    /// - Throws: ProfilePhotoError if load fails
    func loadProfilePhoto(userID: String) async throws -> UIImage {
        // Check cache first
        if let cachedImage = await ImageCacheService.shared.getCachedProfilePhoto(userID: userID) {
            print("[UserService] Loaded profile photo from cache for user \(userID)")
            
            // Background refresh: fetch latest photo from Firestore in background
            Task {
                await refreshProfilePhotoInBackground(userID: userID)
            }
            
            return cachedImage
        }
        
        // Cache miss - fetch from network
        print("[UserService] Cache miss, fetching from network for user \(userID)")
        
        // Get user to get photo URL
        let user = try await getUser(id: userID)
        
        guard let photoURLString = user.photoURL,
              let photoURL = URL(string: photoURLString) else {
            throw ProfilePhotoError.uploadFailed(reason: "No profile photo URL")
        }
        
        // Download image
        let (data, _) = try await URLSession.shared.data(from: photoURL)
        
        guard let image = UIImage(data: data) else {
            throw ProfilePhotoError.invalidImageData
        }
        
        // Cache the downloaded image
        await ImageCacheService.shared.cacheProfilePhoto(image, userID: userID)
        
        print("[UserService] ✅ Downloaded and cached profile photo for user \(userID)")
        
        return image
    }
    
    /// Refreshes profile photo in background without blocking UI
    /// - Parameter userID: User's unique identifier
    private func refreshProfilePhotoInBackground(userID: String) async {
        do {
            // Get latest user data
            let user = try await getUser(id: userID)
            
            guard let photoURLString = user.photoURL,
                  let photoURL = URL(string: photoURLString) else {
                return
            }
            
            // Download latest image
            let (data, _) = try await URLSession.shared.data(from: photoURL)
            
            guard let image = UIImage(data: data) else {
                return
            }
            
            // Update cache with latest image
            await ImageCacheService.shared.cacheProfilePhoto(image, userID: userID)
            
            print("[UserService] ✅ Background refresh complete for user \(userID)")
            
        } catch {
            print("[UserService] ⚠️ Background refresh failed for user \(userID): \(error.localizedDescription)")
        }
    }
    
    /// Gets the current authenticated user's profile
    /// - Returns: Current User object
    /// - Throws: UserServiceError.userNotFound if not authenticated
    func getCurrentUserProfile() async throws -> User {
        guard let currentUser = Auth.auth().currentUser else {
            throw UserServiceError.userNotFound
        }
        
        return try await getUser(id: currentUser.uid)
    }
    
    // MARK: - Private Helper Methods
    
    /// Fetches download URL with retry logic to handle Firebase Storage propagation delays
    /// - Parameters:
    ///   - fileRef: Storage reference to the uploaded file
    ///   - maxAttempts: Maximum number of retry attempts (default: 5)
    /// - Returns: Download URL
    /// - Throws: Storage error if all retries fail
    private func fetchDownloadURLWithRetry(fileRef: StorageReference, maxAttempts: Int = 5) async throws -> URL {
        var attempt = 0
        var lastError: Error?
        
        while attempt < maxAttempts {
            attempt += 1
            
            do {
                let url = try await fileRef.downloadURL()
                if attempt > 1 {
                    print("[UserService] ✅ Download URL fetched on attempt \(attempt)")
                }
                return url
            } catch let error as NSError {
                lastError = error
                
                // Only retry on 404 errors (object not found due to propagation delay)
                if error.domain == "FIRStorageErrorDomain" && error.code == -13010 {
                    if attempt < maxAttempts {
                        let delay = Double(attempt) * 0.5 // Exponential backoff: 0.5s, 1s, 1.5s, 2s
                        print("[UserService] ⚠️ Download URL not ready (attempt \(attempt)/\(maxAttempts)), retrying in \(delay)s...")
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    }
                } else {
                    // Non-404 error, don't retry
                    throw error
                }
            }
        }
        
        // All retries failed
        print("[UserService] ❌ Failed to fetch download URL after \(maxAttempts) attempts")
        throw lastError ?? ProfilePhotoError.uploadFailed(reason: "Could not fetch download URL")
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
