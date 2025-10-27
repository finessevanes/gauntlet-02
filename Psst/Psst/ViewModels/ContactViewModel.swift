//
//  ContactsViewModel.swift
//  Psst
//
//  Created for PR #009: Trainer-Client Relationship System
//  Manages contact list state and operations
//

import Foundation
import Combine

/// ViewModel for managing contacts (clients and prospects)
@MainActor
class ContactsViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var clients: [Client] = []
    @Published var prospects: [Prospect] = []
    @Published var searchQuery: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var currentUserRole: UserRole = .trainer  // Default to trainer
    @Published var trainers: [User] = []  // For clients to see their trainers
    @Published var peerClients: [User] = []  // For clients to see other clients in group chats

    // MARK: - Dependencies

    private let contactService: ContactService
    private let userService: UserService

    // MARK: - Private Properties

    private var lastLoadTime: Date?
    private let minLoadInterval: TimeInterval = 1.0 // Minimum 1 second between loads
    private var hasLoadedOnce: Bool = false

    // MARK: - Computed Properties

    /// Filtered clients based on search query
    var filteredClients: [Client] {
        guard !searchQuery.isEmpty else {
            return clients
        }

        let lowercasedQuery = searchQuery.lowercased()
        return clients.filter { client in
            client.displayName.lowercased().contains(lowercasedQuery) ||
            client.email.lowercased().contains(lowercasedQuery)
        }
    }

    /// Filtered prospects based on search query
    var filteredProspects: [Prospect] {
        guard !searchQuery.isEmpty else {
            return prospects
        }

        let lowercasedQuery = searchQuery.lowercased()
        return prospects.filter { prospect in
            prospect.displayName.lowercased().contains(lowercasedQuery)
        }
    }

    /// Filtered trainers based on search query (for clients)
    var filteredTrainers: [User] {
        guard !searchQuery.isEmpty else {
            return trainers
        }

        let lowercasedQuery = searchQuery.lowercased()
        return trainers.filter { trainer in
            trainer.displayName.lowercased().contains(lowercasedQuery) ||
            trainer.email.lowercased().contains(lowercasedQuery)
        }
    }

    /// Filtered peer clients based on search query (for clients)
    var filteredPeerClients: [User] {
        guard !searchQuery.isEmpty else {
            return peerClients
        }

        let lowercasedQuery = searchQuery.lowercased()
        return peerClients.filter { peerClient in
            peerClient.displayName.lowercased().contains(lowercasedQuery) ||
            peerClient.email.lowercased().contains(lowercasedQuery)
        }
    }

    // MARK: - Initialization

    init(contactService: ContactService = .shared, userService: UserService = .shared) {
        self.contactService = contactService
        self.userService = userService
    }

    // MARK: - Public Methods - Load

    /// Loads contacts on initial view appear (only runs once)
    func loadContactsOnAppear() async {
        guard !hasLoadedOnce else {
            Log.i("ContactsViewModel", "Skipping initial load - already loaded")
            return
        }
        hasLoadedOnce = true
        await loadContacts()
    }

    /// Loads all contacts based on user role
    /// - Trainers: Load clients and prospects
    /// - Clients: Load trainers and peer clients from group chats
    func loadContacts() async {
        // Prevent rapid successive loads
        let now = Date()
        if let lastLoad = lastLoadTime, now.timeIntervalSince(lastLoad) < minLoadInterval {
            Log.i("ContactsViewModel", "Skipping load - too soon since last load")
            return
        }

        lastLoadTime = now
        isLoading = true
        errorMessage = nil

        do {
            // Get current user's role
            let currentUser = try await userService.getCurrentUserProfile()
            currentUserRole = currentUser.role

            if currentUserRole == .client {
                // CLIENT: Load trainers and peer clients in parallel
                async let trainersResult = contactService.getMyTrainers()
                async let peerClientsResult = contactService.getPeerClients()

                trainers = try await trainersResult
                peerClients = try await peerClientsResult

                Log.i("ContactsViewModel", "Loaded \(trainers.count) trainer(s) and \(peerClients.count) peer client(s)")
            } else {
                // TRAINER: Load clients and prospects in parallel
                async let clientsResult = contactService.getClients()
                async let prospectsResult = contactService.getProspects()

                clients = try await clientsResult
                prospects = try await prospectsResult

                Log.i("ContactsViewModel", "Loaded \(clients.count) clients and \(prospects.count) prospects")
            }

        } catch {
            Log.e("ContactsViewModel", "Failed to load contacts: \(error.localizedDescription)")
            errorMessage = "Failed to load contacts. Please try again."
        }

        isLoading = false
    }

    // MARK: - Public Methods - Clients

    /// Adds a new client by email lookup
    /// - Parameter email: Client's email address (must exist in /users)
    func addClient(email: String) async {
        errorMessage = nil
        successMessage = nil

        do {
            let client = try await contactService.addClient(email: email)

            // Add to local list
            clients.insert(client, at: 0)  // Insert at top (most recent)

            successMessage = "✅ Added \(client.displayName) as client"
            Log.i("ContactsViewModel", "Added client: \(client.displayName)")

        } catch let error as ContactError {
            Log.e("ContactsViewModel", "Failed to add client: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        } catch {
            Log.e("ContactsViewModel", "Unexpected error adding client: \(error.localizedDescription)")
            errorMessage = "Failed to add client. Please try again."
        }
    }

    /// Removes a client
    /// - Parameter clientId: Client's user ID
    func removeClient(clientId: String) async {
        errorMessage = nil
        successMessage = nil

        do {
            try await contactService.removeClient(clientId: clientId)

            // Remove from local list
            clients.removeAll { $0.id == clientId }

            successMessage = "✅ Client removed"
            Log.i("ContactsViewModel", "Removed client: \(clientId)")

        } catch let error as ContactError {
            Log.e("ContactsViewModel", "Failed to remove client: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        } catch {
            Log.e("ContactsViewModel", "Unexpected error removing client: \(error.localizedDescription)")
            errorMessage = "Failed to remove client. Please try again."
        }
    }

    // MARK: - Public Methods - Prospects

    /// Adds a new prospect by name
    /// - Parameter name: Prospect's display name
    func addProspect(name: String) async {
        errorMessage = nil
        successMessage = nil

        do {
            let prospect = try await contactService.addProspect(name: name)

            // Add to local list
            prospects.insert(prospect, at: 0)  // Insert at top (most recent)

            successMessage = "✅ Added \(prospect.displayName) as prospect"
            Log.i("ContactsViewModel", "Added prospect: \(prospect.displayName)")

        } catch let error as ContactError {
            Log.e("ContactsViewModel", "Failed to add prospect: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        } catch {
            Log.e("ContactsViewModel", "Unexpected error adding prospect: \(error.localizedDescription)")
            errorMessage = "Failed to add prospect. Please try again."
        }
    }

    /// Upgrades a prospect to client by adding email
    /// - Parameters:
    ///   - prospectId: ID of prospect to upgrade
    ///   - email: Client's email address (must exist in /users)
    func upgradeProspect(prospectId: String, email: String) async {
        errorMessage = nil
        successMessage = nil

        do {
            let client = try await contactService.upgradeProspectToClient(prospectId: prospectId, email: email)

            // Remove prospect from local list
            prospects.removeAll { $0.id == prospectId }

            // Add client to local list
            clients.insert(client, at: 0)  // Insert at top (most recent)

            successMessage = "✅ Upgraded \(client.displayName) to client"
            Log.i("ContactsViewModel", "Upgraded prospect to client: \(client.displayName)")

        } catch let error as ContactError {
            Log.e("ContactsViewModel", "Failed to upgrade prospect: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        } catch {
            Log.e("ContactsViewModel", "Unexpected error upgrading prospect: \(error.localizedDescription)")
            errorMessage = "Failed to upgrade prospect. Please try again."
        }
    }

    /// Deletes a prospect permanently
    /// - Parameter prospectId: Prospect's ID
    func deleteProspect(prospectId: String) async {
        errorMessage = nil
        successMessage = nil

        do {
            try await contactService.deleteProspect(prospectId: prospectId)

            // Remove from local list
            prospects.removeAll { $0.id == prospectId }

            successMessage = "✅ Prospect deleted"
            Log.i("ContactsViewModel", "Deleted prospect: \(prospectId)")

        } catch let error as ContactError {
            Log.e("ContactsViewModel", "Failed to delete prospect: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        } catch {
            Log.e("ContactsViewModel", "Unexpected error deleting prospect: \(error.localizedDescription)")
            errorMessage = "Failed to delete prospect. Please try again."
        }
    }

    // MARK: - Public Methods - Helpers

    /// Clears success and error messages
    func clearMessages() {
        successMessage = nil
        errorMessage = nil
    }
}

