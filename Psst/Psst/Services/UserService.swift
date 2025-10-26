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

    /// Concurrent queue for thread-safe cache access
    private let cacheQueue = DispatchQueue(label: "com.psst.userservice.cache", attributes: .concurrent)

    /// In-memory cache for fetched users to improve performance
    private var _userCache: [String: User] = [:]

    /// Private initializer to enforce singleton pattern
    private init() {}

    // MARK: - Cache Access

    /// Synchronously get a cached user if available (does not trigger network fetch)
    /// - Parameter id: User's unique identifier
    /// - Returns: Cached User object if available, nil otherwise
    func getCachedUser(id: String) -> User? {
        return cacheQueue.sync { _userCache[id] }
    }

    /// Thread-safe cache write operation
    /// - Parameters:
    ///   - user: User object to cache
    ///   - id: User's unique identifier
    private func setCachedUser(_ user: User, id: String) {
        cacheQueue.async(flags: .barrier) { self._userCache[id] = user }
    }

    /// Thread-safe cache removal operation
    /// - Parameter id: User's unique identifier
    private func removeCachedUser(id: String) {
        cacheQueue.async(flags: .barrier) { self._userCache.removeValue(forKey: id) }
    }

    /// Thread-safe cache clear operation
    private func clearCacheInternal() {
        cacheQueue.async(flags: .barrier) { self._userCache.removeAll() }
    }

    // MARK: - Public Methods

    /// Creates a new user document in Firestore
    /// - Parameters:
    ///   - id: User's unique identifier (must match Firebase Auth UID)
    ///   - email: User's email address
    ///   - displayName: User's display name (1-50 characters)
    ///   - role: User's role (trainer or client)
    ///   - photoURL: Optional profile photo URL
    /// - Returns: Created User object
    /// - Throws: UserServiceError if validation fails or Firestore operation fails
    func createUser(id: String, email: String, displayName: String, role: UserRole, photoURL: String? = nil) async throws -> User {
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
            role: role,
            photoURL: photoURL,
            createdAt: now,
            updatedAt: now
        )

        // Save to Firestore
        let start = Date()
        let sw = Stopwatch()
        Log.i("UserService", "createUser start id=\(id)")
        do {
            try await db.collection(usersCollection).document(id).setData(user.toDictionary())

            // Log performance
            let duration = Date().timeIntervalSince(start) * 1000
            Log.i("UserService", "Created user id=\(id) in \(Int(duration))ms (\(sw.ms)ms)")

            // Cache the user
            setCachedUser(user, id: id)

            return user
        } catch {
            Log.e("UserService", "Failed to create user id=\(id): \(error.localizedDescription)")
            throw UserServiceError.createFailed(error)
        }
    }

    /// Fetches a user by ID from Firestore (with caching)
    /// - Parameter id: User's unique identifier
    /// - Returns: User object
    /// - Throws: UserServiceError.userNotFound if user doesn't exist
    func getUser(id: String) async throws -> User {
        // Check cache first
        if let cachedUser = getCachedUser(id: id) {
            return cachedUser
        }

        // Fetch from Firestore
        let start = Date()
        let sw = Stopwatch()
        do {
            let document = try await db.collection(usersCollection).document(id).getDocument()

            guard document.exists else {
                throw UserServiceError.userNotFound
            }

            let user = try document.data(as: User.self)

            // Log performance
            let duration = Date().timeIntervalSince(start) * 1000
            Log.i("UserService", "Fetched user id=\(id) in \(Int(duration))ms (\(sw.ms)ms)")

            // Cache the user
            setCachedUser(user, id: id)

            return user
        } catch let error as UserServiceError {
            throw error
        } catch {
            Log.e("UserService", "Failed to fetch user id=\(id): \(error.localizedDescription)")
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
                Log.w("UserService", "Failed to fetch user id=\(id) in batch: \(error.localizedDescription)")
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
        let sw = Stopwatch()
        
        do {
            let snapshot = try await db.collection(usersCollection).getDocuments()
            
            let users = snapshot.documents.compactMap { document -> User? in
                do {
                    return try document.data(as: User.self)
                } catch {
                    Log.w("UserService", "Error decoding user id=\(document.documentID): \(error.localizedDescription)")
                    return nil
                }
            }
            
            // Log performance
            let duration = Date().timeIntervalSince(start) * 1000
            Log.i("UserService", "Fetched users count=\(users.count) in \(Int(duration))ms (\(sw.ms)ms)")
            
            return users
        } catch {
            Log.e("UserService", "Failed to fetch all users: \(error.localizedDescription)")
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
        let sw = Stopwatch()
        do {
            try await db.collection(usersCollection).document(id).updateData(updateData)

            // Log performance
            let duration = Date().timeIntervalSince(start) * 1000
            Log.i("UserService", "Updated user id=\(id) in \(Int(duration))ms (\(sw.ms)ms)")

            // Invalidate cache for this user
            removeCachedUser(id: id)

        } catch {
            Log.e("UserService", "Failed to update user id=\(id): \(error.localizedDescription)")
            throw UserServiceError.updateFailed(error)
        }
    }

    /// Observes real-time changes to a user document
    /// - Parameters:
    ///   - id: User's unique identifier
    ///   - completion: Callback with Result containing User or Error (always called on main thread)
    /// - Returns: ListenerRegistration for removing the listener
    /// - Note: Uses cache-then-network pattern - immediately returns cached data if available, then sets up listener for real-time updates
    func observeUser(id: String, completion: @escaping (Result<User, Error>) -> Void) -> ListenerRegistration {
        // Check if data is already cached
        let cacheHit = getCachedUser(id: id) != nil

        // Cache-then-network pattern
        // If cached data exists, immediately return it on main thread (no async delay)
        if let cachedUser = getCachedUser(id: id) {
            // Call completion on main thread to avoid queuing delay
            if Thread.isMainThread {
                completion(.success(cachedUser))
            } else {
                DispatchQueue.main.async {
                    completion(.success(cachedUser))
                }
            }
        }

        // Set up Firestore listener for real-time updates
        // This will call completion again if data changes on server
        return db.collection(usersCollection).document(id).addSnapshotListener { [weak self] snapshot, error in
            if let error = error {
                Log.e("UserService", "Listener error userID=\(id): \(error.localizedDescription)")
                // Only call completion with error if we didn't already send cached data
                if !cacheHit {
                    DispatchQueue.main.async {
                        completion(.failure(UserServiceError.fetchFailed(error)))
                    }
                }
                return
            }

            guard let snapshot = snapshot, snapshot.exists else {
                if !cacheHit {
                    DispatchQueue.main.async {
                        completion(.failure(UserServiceError.userNotFound))
                    }
                }
                return
            }

            do {
                let user = try snapshot.data(as: User.self)

                // Update cache
                self?.setCachedUser(user, id: id)

                // Call completion with fresh data from server on main thread
                // If cache was hit, this updates the UI with any server changes
                // If cache was missed, this provides the initial data
                DispatchQueue.main.async {
                    completion(.success(user))
                }
            } catch {
                Log.e("UserService", "Failed to decode user id=\(id): \(error.localizedDescription)")
                if !cacheHit {
                    DispatchQueue.main.async {
                        completion(.failure(UserServiceError.fetchFailed(error)))
                    }
                }
            }
        }
    }

    /// Clears the in-memory user cache
    func clearCache() {
        clearCacheInternal()
        Log.i("UserService", "Cache cleared")
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
        let sw = Stopwatch()
        
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
            Log.w("UserService", "No fields to update uid=\(uid)")
            return
        }
        
        // Update in Firestore
        do {
            try await db.collection(usersCollection).document(uid).updateData(updateData)
            
            // Log performance
            let duration = Date().timeIntervalSince(start) * 1000
            Log.i("UserService", "Updated profile for user id=\(uid) in \(Int(duration))ms")

            // Invalidate cache
            removeCachedUser(id: uid)

        } catch {
            Log.e("UserService", "Failed to update profile for user id=\(uid): \(error.localizedDescription)")
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
        let sw = Stopwatch()
        
        // Validate uid
        guard !uid.isEmpty else {
            throw UserServiceError.invalidUserID
        }
        
        // Check network connectivity first
        guard await checkNetworkConnectivity() else {
            Log.e("UserService", "Upload blocked: No network connection")
            throw ProfilePhotoError.networkUnavailable
        }
        
        Log.i("UserService", "Upload start uid=\(uid) origBytes=\(imageData.count)")
        
        // Convert to UIImage first
        guard let image = UIImage(data: imageData) else {
            Log.e("UserService", "Invalid image data")
            throw ProfilePhotoError.invalidImageData
        }
        
        // Attempt compression FIRST (this handles large images)
        // Target: 1500KB (increased from 1000KB for better image quality)
        let compressedData: Data
        let compressSW = Stopwatch()
        do {
            compressedData = try await compressImage(image, maxSizeKB: 1500)
            Log.i("UserService", "Compression complete bytes=\(compressedData.count) took=\(compressSW.ms)ms")
        } catch {
            Log.e("UserService", "Compression failed: \(error.localizedDescription)")
            throw error
        }
        
        // NOW validate the COMPRESSED data
        do {
            try validateImageData(compressedData)
        } catch {
            Log.e("UserService", "Compressed image still too large: \(error.localizedDescription)")
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
            Log.i("UserService", "Uploading path=\(filePath) size=\(compressedData.count)B")
            let uploadSW = Stopwatch()
            
            let uploadMetadata = try await fileRef.putData(compressedData, metadata: metadata)
            
            Log.i("UserService", "Upload completed took=\(uploadSW.ms)ms meta=\(uploadMetadata)")
            
            // Get download URL after successful upload with retry logic
            // Firebase Storage sometimes has a brief propagation delay
            Log.i("UserService", "Fetching download URL...")
            let urlSW = Stopwatch()
            let downloadURL = try await fetchDownloadURLWithRetry(fileRef: fileRef, maxAttempts: 5)
            Log.i("UserService", "Download URL fetched took=\(urlSW.ms)ms")
            
            // Log performance
            let duration = Date().timeIntervalSince(start) * 1000
            Log.i("UserService", "Uploaded profile photo uid=\(uid) total=\(Int(duration))ms (\(sw.ms)ms)")
            Log.i("UserService", "Download URL=\(downloadURL.absoluteString)")
            
            // Invalidate cache for this user so new photo will be fetched
            let invSW = Stopwatch()
            await ImageCacheService.shared.invalidateProfilePhotoCache(userID: uid)
            Log.i("UserService", "Cache invalidated uid=\(uid) took=\(invSW.ms)ms")
            
            return downloadURL.absoluteString
            
        } catch let error as NSError {
            Log.e("UserService", "Failed upload uid=\(uid)")
            Log.e("UserService", "Error domain=\(error.domain) code=\(error.code) desc=\(error.localizedDescription)")
            
            // Check for specific Firebase Storage errors
            if error.domain == "FIRStorageErrorDomain" {
                Log.e("UserService", "Firebase Storage Error Code=\(error.code)")
                
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
        
        Log.i("UserService", "Image validation passed bytes=\(data.count)")
    }
    
    /// Compresses an image to target size with quality fallback
    /// - Parameters:
    ///   - image: UIImage to compress
    ///   - maxSizeKB: Maximum size in kilobytes (default: 1500KB)
    /// - Returns: Compressed image data
    /// - Throws: ProfilePhotoError.compressionFailed if compression fails
    func compressImage(_ image: UIImage, maxSizeKB: Int = 1500) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            // Run compression on background thread to avoid blocking UI
            DispatchQueue.global(qos: .userInitiated).async {
                let maxSizeBytes = maxSizeKB * 1024
                var compressionQuality: CGFloat = 0.8
                var compressedData: Data?
                
                Log.i("UserService", "Compression start target=\(maxSizeKB)KB")
                
                // Try to compress with decreasing quality until size is acceptable
                var attempts = 0
                let maxAttempts = 10
                
                while compressionQuality >= 0.3 && attempts < maxAttempts {
                    attempts += 1
                    
                    guard let data = image.jpegData(compressionQuality: compressionQuality) else {
                    Log.e("UserService", "Failed to create JPEG at quality=\(compressionQuality)")
                        compressionQuality -= 0.1
                        continue
                    }
                    
                    Log.i("UserService", "Compress attempt=\(attempts) size=\(data.count)B quality=\(String(format: "%.1f", compressionQuality))")
                    
                    if data.count <= maxSizeBytes {
                        compressedData = data
                        Log.i("UserService", "Compression successful bytes=\(data.count)")
                        break
                    }
                    
                    compressionQuality -= 0.1
                }
                
                // If still too large, use the last compressed version
                if compressedData == nil {
                    compressedData = image.jpegData(compressionQuality: 0.3)
                    Log.i("UserService", "Using minimum compression quality")
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
            // Background refresh: fetch latest photo from Firestore in background
            Task {
                await refreshProfilePhotoInBackground(userID: userID)
            }
            
            return cachedImage
        }
        
        // Cache miss - fetch from network
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
        
        Log.i("UserService", "Downloaded and cached profile photo userID=\(userID)")
        
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
            
        } catch {
            Log.w("UserService", "Background refresh failed userID=\(userID): \(error.localizedDescription)")
        }
    }
    
    /// Lookup user by email address
    /// Used by ContactService when adding clients by email
    /// - Parameter email: User's email address
    /// - Returns: User object if found
    /// - Throws: UserServiceError.userNotFound if no user with that email exists
    func getUserByEmail(_ email: String) async throws -> User {
        // Validate email format
        guard email.contains("@") else {
            throw UserServiceError.invalidEmail
        }

        Log.i("UserService", "Looking up user by email: \(email)")

        let start = Date()
        let sw = Stopwatch()

        do {
            // Query Firestore (REQUIRES INDEX on email field - see PR #009 Implementation Guide)
            let snapshot = try await db.collection(usersCollection)
                .whereField("email", isEqualTo: email)
                .limit(to: 1)
                .getDocuments()

            guard let document = snapshot.documents.first else {
                Log.w("UserService", "No user found with email: \(email)")
                throw UserServiceError.userNotFound
            }

            let user = try document.data(as: User.self)

            // Log performance (target: < 200ms)
            let duration = Date().timeIntervalSince(start) * 1000
            Log.i("UserService", "Found user by email: \(user.displayName) in \(Int(duration))ms (\(sw.ms)ms)")

            // Cache the user
            setCachedUser(user, id: user.id)

            return user

        } catch let error as UserServiceError {
            throw error
        } catch {
            Log.e("UserService", "Failed to lookup user by email: \(error.localizedDescription)")
            throw UserServiceError.fetchFailed(error)
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
    
    /// Updates user's profile photo with a new image
    /// - Parameters:
    ///   - uid: User's unique identifier
    ///   - imageData: New image data to upload
    /// - Returns: Download URL string for the new uploaded photo
    /// - Throws: ProfilePhotoError with specific error details
    /// - Note: Deletes old photo after new photo upload succeeds (prevents data loss on failure)
    func updateProfilePhoto(uid: String, imageData: Data) async throws -> String {
        let start = Date()
        
        Log.i("UserService", "Starting profile photo update uid=\(uid)")
        
        // Get current user to check for existing photo
        let user = try await getUser(id: uid)
        let oldPhotoURL = user.photoURL
        
        // Upload new photo first (keeps old photo as backup)
        let newPhotoURL = try await uploadProfilePhoto(uid: uid, imageData: imageData)
        
        Log.i("UserService", "New photo uploaded url=\(newPhotoURL)")
        
        // If there was an old photo, delete it from Storage
        if let oldPhotoURL = oldPhotoURL, !oldPhotoURL.isEmpty {
            do {
                // Extract path from old photo URL and delete
                let storage = Storage.storage()
                let storageRef = storage.reference(forURL: oldPhotoURL)
                try await storageRef.delete()
                
                Log.i("UserService", "Deleted old photo from Storage")
            } catch {
                // Log warning but don't fail the update (new photo is already uploaded)
                Log.w("UserService", "Failed to delete old photo: \(error.localizedDescription)")
                Log.w("UserService", "Old photo URL: \(oldPhotoURL)")
            }
        }
        
        // Invalidate cache so new photo will be loaded
        await ImageCacheService.shared.invalidateProfilePhotoCache(userID: uid)
        
        let duration = Date().timeIntervalSince(start) * 1000
        Log.i("UserService", "Updated profile photo uid=\(uid) in \(Int(duration))ms")
        
        return newPhotoURL
    }
    
    /// Deletes user's profile photo from Firebase Storage and Firestore
    /// - Parameter uid: User's unique identifier
    /// - Throws: ProfilePhotoError if deletion fails
    /// - Note: Transactional delete (both Storage and Firestore must succeed)
    func deleteProfilePhoto(uid: String) async throws {
        let start = Date()
        
        Log.i("UserService", "Starting profile photo deletion uid=\(uid)")
        
        // Check network connectivity first
        guard await checkNetworkConnectivity() else {
            Log.e("UserService", "Delete blocked: No network connection")
            throw ProfilePhotoError.networkUnavailable
        }
        
        // Get current user to verify photo exists
        let user = try await getUser(id: uid)
        
        guard let photoURL = user.photoURL, !photoURL.isEmpty else {
            Log.e("UserService", "No profile photo to delete uid=\(uid)")
            throw ProfilePhotoError.noPhotoToDelete
        }
        
        Log.i("UserService", "Deleting photo from Storage url=\(photoURL)")
        
        // Delete from Firebase Storage
        do {
            let storage = Storage.storage()
            let storageRef = storage.reference(forURL: photoURL)
            try await storageRef.delete()
            
            Log.i("UserService", "Deleted photo from Storage")
        } catch let error as NSError {
            Log.e("UserService", "Failed to delete from Storage: \(error.localizedDescription)")
            Log.e("UserService", "Error domain=\(error.domain) code=\(error.code)")
            throw ProfilePhotoError.deleteFailed(reason: error.localizedDescription)
        }
        
        // Clear photoURL from Firestore
        do {
            try await db.collection(usersCollection).document(uid).updateData([
                "photoURL": FieldValue.delete(),
                "updatedAt": FieldValue.serverTimestamp()
            ])
            
            Log.i("UserService", "Cleared photoURL from Firestore")
        } catch let error as NSError {
            Log.e("UserService", "Failed to update Firestore: \(error.localizedDescription)")
            // Photo is already deleted from Storage, but Firestore update failed
            // This leaves a stale URL in Firestore but no actual photo in Storage
            throw ProfilePhotoError.deleteFailed(reason: "Storage deletion succeeded but Firestore update failed: \(error.localizedDescription)")
        }
        
        // Invalidate cache
        await ImageCacheService.shared.invalidateProfilePhotoCache(userID: uid)

        // Invalidate user cache so next fetch gets updated user
        removeCachedUser(id: uid)

        let duration = Date().timeIntervalSince(start) * 1000
        Log.i("UserService", "Deleted profile photo uid=\(uid) in \(Int(duration))ms")
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
            Log.i("UserService", "Download URL fetched on attempt \(attempt)")
                }
                return url
            } catch let error as NSError {
                lastError = error
                
                // Only retry on 404 errors (object not found due to propagation delay)
                if error.domain == "FIRStorageErrorDomain" && error.code == -13010 {
                    if attempt < maxAttempts {
                        let delay = Double(attempt) * 0.5 // Exponential backoff: 0.5s, 1s, 1.5s, 2s
                        Log.w("UserService", "Download URL not ready (attempt \(attempt)/\(maxAttempts)), retrying in \(delay)s…")
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    }
                } else {
                    // Non-404 error, don't retry
                    throw error
                }
            }
        }
        
        // All retries failed
        Log.e("UserService", "Failed to fetch download URL after \(maxAttempts) attempts")
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
