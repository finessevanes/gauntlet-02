//
//  ProfileService.swift
//  Psst
//
//  Created by Caleb (Coder Agent) on 10/24/25.
//  PR #007: Contextual Intelligence (Auto Client Profiles)
//  Service layer for client profile Firestore operations
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Service managing client profile operations with Firestore
/// Handles CRUD operations and real-time profile updates
class ProfileService {
    // MARK: - Properties

    private let db = Firestore.firestore()
    private static let COLLECTION_NAME = "clientProfiles"

    // MARK: - Public Methods

    /// Fetches client profile for a given client ID
    /// - Parameter clientId: User ID of the client
    /// - Returns: ClientProfile or nil if not found
    /// - Throws: ProfileError if fetch fails
    func fetchClientProfile(clientId: String) async throws -> ClientProfile? {
        try requireAuth()

        do {
            let document = try await db.collection(Self.COLLECTION_NAME).document(clientId).getDocument()

            // Return nil if profile doesn't exist yet
            guard document.exists, let data = document.data() else {
                return nil
            }

            // Parse Firestore data to ClientProfile
            return try ClientProfile.fromFirestore(id: document.documentID, data: data)
        } catch let error as ProfileError {
            throw error
        } catch {
            throw ProfileError.networkError
        }
    }

    /// Updates a specific profile item (manual edit)
    /// - Parameters:
    ///   - clientId: User ID of the client
    ///   - itemId: ID of the profile item to update
    ///   - newText: Updated text content
    /// - Returns: Updated ProfileItem
    /// - Throws: ProfileError if update fails
    func updateProfileItem(
        clientId: String,
        itemId: String,
        newText: String
    ) async throws -> ProfileItem {
        try requireAuth()

        // Fetch current profile
        guard var profile = try await fetchClientProfile(clientId: clientId) else {
            throw ProfileError.notFound
        }

        // Find the item using helper
        guard let (category, index) = findItem(in: profile, itemId: itemId) else {
            throw ProfileError.notFound
        }

        // Get current item
        var items = profile.items(for: category)
        let item = items[index]

        // Create updated item with manual edit flag
        let updatedItem = ProfileItem(
            id: item.id,
            text: newText,
            category: item.category,
            timestamp: item.timestamp,
            sourceMessageId: item.sourceMessageId,
            sourceChatId: item.sourceChatId,
            confidenceScore: item.confidenceScore,
            isManuallyEdited: true,
            editedAt: Date(),
            createdBy: item.createdBy
        )

        // Update profile
        items[index] = updatedItem
        profile.setItems(items, for: category)

        // Save to Firestore
        try await saveProfile(profile, clientId: clientId)

        return updatedItem
    }

    /// Deletes a profile item
    /// - Parameters:
    ///   - clientId: User ID of the client
    ///   - itemId: ID of the profile item to delete
    /// - Throws: ProfileError if deletion fails
    func deleteProfileItem(clientId: String, itemId: String) async throws {
        try requireAuth()

        // Fetch current profile
        guard var profile = try await fetchClientProfile(clientId: clientId) else {
            throw ProfileError.notFound
        }

        // Find the item using helper
        guard let (category, index) = findItem(in: profile, itemId: itemId) else {
            throw ProfileError.notFound
        }

        // Remove item from profile
        var items = profile.items(for: category)
        items.remove(at: index)
        profile.setItems(items, for: category)

        // Save to Firestore
        try await saveProfile(profile, clientId: clientId)
    }

    /// Adds a manual profile entry
    /// - Parameters:
    ///   - clientId: User ID of the client
    ///   - category: Profile category (injuries, goals, etc.)
    ///   - text: Profile item text
    /// - Returns: Created ProfileItem
    /// - Throws: ProfileError if creation fails
    func addManualProfileItem(
        clientId: String,
        category: ProfileCategory,
        text: String,
        sourceChatId: String = "manual_entry"
    ) async throws -> ProfileItem {
        // Verify authentication
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw ProfileError.notAuthenticated
        }

        // Fetch or create profile
        var profile = try await fetchClientProfile(clientId: clientId)

        // Create profile if it doesn't exist
        if profile == nil {
            profile = ClientProfile(
                id: clientId,
                clientId: clientId,
                trainerId: currentUserId,
                injuries: [],
                goals: [],
                equipment: [],
                preferences: [],
                travel: [],
                stressFactors: [],
                totalItems: 0
            )
        }

        guard var existingProfile = profile else {
            throw ProfileError.updateFailed("Failed to create profile")
        }

        // Create new manual item
        let newItem = ProfileItem(
            text: text,
            category: category,
            sourceMessageId: "manual_\(UUID().uuidString)",
            sourceChatId: sourceChatId,
            confidenceScore: 1.0,
            createdBy: .manual
        )

        // Add to appropriate category
        var items = existingProfile.items(for: category)
        items.append(newItem)
        existingProfile.setItems(items, for: category)

        // Save to Firestore
        try await saveProfile(existingProfile, clientId: clientId)

        return newItem
    }

    /// Observes real-time updates to client profile
    /// - Parameters:
    ///   - clientId: User ID of the client
    ///   - completion: Callback with updated ClientProfile
    /// - Returns: Firestore listener registration (to cancel later)
    func observeClientProfile(
        clientId: String,
        completion: @escaping (ClientProfile?) -> Void
    ) -> ListenerRegistration {
        return db.collection(Self.COLLECTION_NAME).document(clientId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ Error observing client profile: \(error.localizedDescription)")
                    completion(nil)
                    return
                }

                guard let document = snapshot,
                      document.exists,
                      let data = document.data() else {
                    completion(nil)
                    return
                }

                do {
                    let profile = try ClientProfile.fromFirestore(id: document.documentID, data: data)
                    completion(profile)
                } catch {
                    print("⚠️ Error parsing client profile: \(error.localizedDescription)")
                    completion(nil)
                }
            }
    }

    /// Deletes entire profile for a client (privacy)
    /// - Parameter clientId: User ID of the client
    /// - Throws: ProfileError if deletion fails
    func deleteClientProfile(clientId: String) async throws {
        try requireAuth()

        do {
            try await db.collection(Self.COLLECTION_NAME).document(clientId).delete()
        } catch {
            throw ProfileError.updateFailed(error.localizedDescription)
        }
    }

    /// Marks profile as reviewed by trainer (updates lastReviewedAt)
    /// - Parameter clientId: User ID of the client
    /// - Throws: ProfileError if update fails
    func markProfileAsReviewed(clientId: String) async throws {
        try requireAuth()

        do {
            try await db.collection(Self.COLLECTION_NAME).document(clientId).updateData([
                "lastReviewedAt": Timestamp(date: Date())
            ])
        } catch {
            throw ProfileError.updateFailed(error.localizedDescription)
        }
    }

    // MARK: - Private Helpers

    /// Verify user is authenticated
    /// - Throws: ProfileError.notAuthenticated if not authenticated
    private func requireAuth() throws {
        guard Auth.auth().currentUser != nil else {
            throw ProfileError.notAuthenticated
        }
    }

    /// Find item across all categories in a profile
    /// - Parameters:
    ///   - profile: ClientProfile to search
    ///   - itemId: ID of the item to find
    /// - Returns: Tuple of (category, index) if found, nil otherwise
    private func findItem(in profile: ClientProfile, itemId: String) -> (category: ProfileCategory, index: Int)? {
        for category in ProfileCategory.allCases {
            let items = profile.items(for: category)
            if let index = items.firstIndex(where: { $0.id == itemId }) {
                return (category, index)
            }
        }
        return nil
    }

    /// Save profile to Firestore
    /// - Parameters:
    ///   - profile: ClientProfile to save
    ///   - clientId: Client user ID
    /// - Throws: ProfileError if save fails
    private func saveProfile(_ profile: ClientProfile, clientId: String) async throws {
        do {
            try await db.collection(Self.COLLECTION_NAME).document(clientId).setData(
                profile.toFirestore(),
                merge: true
            )
        } catch {
            throw ProfileError.updateFailed(error.localizedDescription)
        }
    }
}
