//
//  ClientProfileViewModel.swift
//  Psst
//
//  Created by Caleb (Coder Agent) on 10/24/25.
//  PR #007: Contextual Intelligence (Auto Client Profiles)
//  ViewModel managing client profile state and operations
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

/// ViewModel managing client profile screen state
/// Follows MVVM pattern: handles business logic and state management
class ClientProfileViewModel: ObservableObject {
    // MARK: - Published Properties

    /// Client profile data
    @Published var profile: ClientProfile?

    /// Loading state for initial fetch
    @Published var isLoading = false

    /// Error message to display to user (if any)
    @Published var errorMessage: String?

    /// Success message for user actions
    @Published var successMessage: String?

    // MARK: - Private Properties

    private let profileService = ProfileService()
    private var listener: ListenerRegistration?
    private var currentClientId: String?

    // MARK: - Public Methods

    /// Load profile for a specific client
    /// - Parameter clientId: User ID of the client
    func loadProfile(clientId: String) {
        Task {
            await MainActor.run {
                isLoading = true
                errorMessage = nil
            }

            do {
                let fetchedProfile = try await profileService.fetchClientProfile(clientId: clientId)

                await MainActor.run {
                    self.profile = fetchedProfile
                    self.isLoading = false

                    if fetchedProfile == nil {
                        print("[ClientProfileViewModel] No profile found for client: \(clientId)")
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    print("❌ [ClientProfileViewModel] Failed to load profile: \(error.localizedDescription)")
                }
            }
        }
    }

    /// Start observing profile for real-time updates
    /// - Parameter clientId: User ID of the client
    func observeProfile(clientId: String) {
        // Store client ID for reference
        currentClientId = clientId

        // Clear error state
        errorMessage = nil

        // Remove existing listener if any
        listener?.remove()

        // Set up new listener
        listener = profileService.observeClientProfile(clientId: clientId) { [weak self] profile in
            DispatchQueue.main.async {
                self?.profile = profile
                self?.isLoading = false
            }
        }
    }

    /// Stop observing profile (cleanup)
    /// Should be called when view disappears to prevent memory leaks
    func stopObserving() {
        listener?.remove()
        listener = nil
    }

    /// Update a profile item with new text
    /// - Parameters:
    ///   - itemId: ID of the item to update
    ///   - newText: New text content
    func updateItem(itemId: String, newText: String) {
        guard let clientId = currentClientId else {
            errorMessage = "No client profile loaded"
            return
        }

        Task {
            do {
                let updatedItem = try await profileService.updateProfileItem(
                    clientId: clientId,
                    itemId: itemId,
                    newText: newText
                )

                await MainActor.run {
                    successMessage = "Profile updated"
                    print("[ClientProfileViewModel] ✅ Item updated: \(updatedItem.text)")

                    // Clear success message after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.successMessage = nil
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    print("❌ [ClientProfileViewModel] Failed to update item: \(error.localizedDescription)")
                }
            }
        }
    }

    /// Delete a profile item
    /// - Parameter itemId: ID of the item to delete
    func deleteItem(itemId: String) {
        guard let clientId = currentClientId else {
            errorMessage = "No client profile loaded"
            return
        }

        Task {
            do {
                try await profileService.deleteProfileItem(clientId: clientId, itemId: itemId)

                await MainActor.run {
                    successMessage = "Item deleted"
                    print("[ClientProfileViewModel] ✅ Item deleted: \(itemId)")

                    // Clear success message after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.successMessage = nil
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    print("❌ [ClientProfileViewModel] Failed to delete item: \(error.localizedDescription)")
                }
            }
        }
    }

    /// Add a manual profile item
    /// - Parameters:
    ///   - category: Profile category
    ///   - text: Item text
    func addManualItem(category: ProfileCategory, text: String) {
        guard let clientId = currentClientId else {
            errorMessage = "No client profile loaded"
            return
        }

        Task {
            do {
                let newItem = try await profileService.addManualProfileItem(
                    clientId: clientId,
                    category: category,
                    text: text
                )

                await MainActor.run {
                    successMessage = "Item added"
                    print("[ClientProfileViewModel] ✅ Manual item added: \(newItem.text)")

                    // Clear success message after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.successMessage = nil
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    print("❌ [ClientProfileViewModel] Failed to add item: \(error.localizedDescription)")
                }
            }
        }
    }

    /// Delete entire profile for a client
    func deleteProfile() {
        guard let clientId = currentClientId else {
            errorMessage = "No client profile loaded"
            return
        }

        Task {
            do {
                try await profileService.deleteClientProfile(clientId: clientId)

                await MainActor.run {
                    profile = nil
                    successMessage = "Profile deleted"
                    print("[ClientProfileViewModel] ✅ Profile deleted for client: \(clientId)")

                    // Clear success message after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.successMessage = nil
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    print("❌ [ClientProfileViewModel] Failed to delete profile: \(error.localizedDescription)")
                }
            }
        }
    }

    /// Mark profile as reviewed
    func markAsReviewed() {
        guard let clientId = currentClientId else { return }

        Task {
            do {
                try await profileService.markProfileAsReviewed(clientId: clientId)
                print("[ClientProfileViewModel] ✅ Profile marked as reviewed")
            } catch {
                print("⚠️ [ClientProfileViewModel] Failed to mark as reviewed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Lifecycle

    deinit {
        stopObserving()
    }
}
