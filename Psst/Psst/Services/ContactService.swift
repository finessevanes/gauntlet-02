//
//  ContactService.swift
//  Psst
//
//  Created for PR #009: Trainer-Client Relationship System
//  Service layer for managing trainer-client relationships and prospects
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Service for managing trainer-client relationships and prospects
/// Handles CRUD operations for contacts collection
class ContactService {

    // MARK: - Singleton

    static let shared = ContactService()

    // MARK: - Properties

    private let db = Firestore.firestore()
    private let contactsCollection = "contacts"
    private let userService = UserService.shared

    /// Private initializer to enforce singleton pattern
    private init() {}

    // MARK: - Public Methods - Clients

    /// Add an existing user as a client by email lookup
    /// - Parameter email: Client's email address (must exist in /users)
    /// - Returns: Client document with auto-populated display name
    /// - Throws: ContactError (invalidEmail, userNotFound, alreadyExists, networkError)
    func addClient(email: String) async throws -> Client {
        // Get current trainer ID
        guard let trainerId = Auth.auth().currentUser?.uid else {
            throw ContactError.unauthorized
        }

        // Validate email format
        guard email.contains("@") else {
            throw ContactError.invalidEmail
        }

        Log.i("ContactService", "Adding client with email: \(email)")

        let start = Date()
        let sw = Stopwatch()

        do {
            // Step 1: Ensure parent document exists
            try await ensureContactsDocumentExists(trainerId: trainerId)

            // Step 2: Lookup user by email
            let user = try await userService.getUserByEmail(email)

            Log.i("ContactService", "Found user: \(user.displayName) (id: \(user.id))")

            // Step 3: Check if client already exists
            let clientRef = db.collection(contactsCollection)
                .document(trainerId)
                .collection("clients")
                .document(user.id)

            let existingDoc = try await clientRef.getDocument()

            if existingDoc.exists {
                Log.w("ContactService", "Client already exists: \(user.id)")
                throw ContactError.alreadyExists
            }

            // Step 4: Create Client object with auto-populated displayName
            let client = Client(
                id: user.id,
                displayName: user.displayName,
                email: email,
                addedAt: Date(),
                lastContactedAt: nil
            )

            // Step 5: Write to Firestore
            try await clientRef.setData(client.toDictionary())

            // Log performance
            let duration = Date().timeIntervalSince(start) * 1000
            Log.i("ContactService", "Added client \(client.displayName) in \(Int(duration))ms (\(sw.ms)ms)")

            return client

        } catch let error as ContactError {
            throw error
        } catch let error as UserServiceError {
            // Convert UserService errors to ContactError
            if case .userNotFound = error {
                throw ContactError.userNotFound
            } else if case .invalidEmail = error {
                throw ContactError.invalidEmail
            } else {
                throw ContactError.networkError
            }
        } catch {
            Log.e("ContactService", "Failed to add client: \(error.localizedDescription)")
            throw ContactError.networkError
        }
    }

    /// Get all clients for the current trainer
    /// - Returns: Array of Client documents (empty array if no clients exist)
    func getClients() async throws -> [Client] {
        guard let trainerId = Auth.auth().currentUser?.uid else {
            throw ContactError.unauthorized
        }

        let start = Date()
        let sw = Stopwatch()

        do {
            let snapshot = try await db.collection(contactsCollection)
                .document(trainerId)
                .collection("clients")
                .order(by: "addedAt", descending: true)
                .getDocuments()

            let clients = try snapshot.documents.map { document -> Client in
                return try document.data(as: Client.self)
            }

            let duration = Date().timeIntervalSince(start) * 1000
            Log.i("ContactService", "Fetched \(clients.count) clients in \(Int(duration))ms (\(sw.ms)ms)")

            return clients

        } catch {
            // Check if error is due to missing parent document (first time user)
            let errorDescription = error.localizedDescription
            if errorDescription.contains("Missing or insufficient permissions") ||
               errorDescription.contains("PERMISSION_DENIED") {
                // First time user - no contacts document exists yet
                // This is expected, return empty array
                Log.i("ContactService", "No contacts document exists yet (first time user). Returning empty array.")
                return []
            }

            // Other errors should be logged and thrown
            Log.e("ContactService", "Failed to fetch clients: \(errorDescription)")
            throw ContactError.networkError
        }
    }

    /// Remove a client (deletes relationship, client loses chat access)
    /// - Parameter clientId: Client's user ID
    /// - Throws: ContactError (clientNotFound, networkError)
    func removeClient(clientId: String) async throws {
        guard let trainerId = Auth.auth().currentUser?.uid else {
            throw ContactError.unauthorized
        }

        Log.i("ContactService", "Removing client: \(clientId)")

        let start = Date()
        let sw = Stopwatch()

        do {
            let clientRef = db.collection(contactsCollection)
                .document(trainerId)
                .collection("clients")
                .document(clientId)

            // Check if client exists
            let existingDoc = try await clientRef.getDocument()

            guard existingDoc.exists else {
                throw ContactError.clientNotFound
            }

            // Delete client document
            try await clientRef.delete()

            let duration = Date().timeIntervalSince(start) * 1000
            Log.i("ContactService", "Removed client \(clientId) in \(Int(duration))ms (\(sw.ms)ms)")

        } catch let error as ContactError {
            throw error
        } catch {
            Log.e("ContactService", "Failed to remove client: \(error.localizedDescription)")
            throw ContactError.networkError
        }
    }

    // MARK: - Public Methods - Prospects

    /// Add a prospect by name only (for leads without accounts)
    /// - Parameter name: Prospect's display name
    /// - Returns: Prospect document with generated placeholder email
    /// - Throws: ContactError (invalidName, networkError)
    func addProspect(name: String) async throws -> Prospect {
        guard let trainerId = Auth.auth().currentUser?.uid else {
            throw ContactError.unauthorized
        }

        // Validate name
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ContactError.invalidName
        }

        Log.i("ContactService", "Adding prospect: \(name)")

        let start = Date()
        let sw = Stopwatch()

        do {
            // Ensure parent document exists
            try await ensureContactsDocumentExists(trainerId: trainerId)

            // Create Prospect object (placeholder email auto-generated in init)
            let prospect = Prospect(displayName: name, addedAt: Date())

            // Write to Firestore
            let prospectRef = db.collection(contactsCollection)
                .document(trainerId)
                .collection("prospects")
                .document(prospect.id)

            try await prospectRef.setData(prospect.toDictionary())

            let duration = Date().timeIntervalSince(start) * 1000
            Log.i("ContactService", "Added prospect \(prospect.displayName) in \(Int(duration))ms (\(sw.ms)ms)")

            return prospect

        } catch {
            Log.e("ContactService", "Failed to add prospect: \(error.localizedDescription)")
            throw ContactError.networkError
        }
    }

    /// Get all prospects for the current trainer
    /// - Returns: Array of Prospect documents (excludes converted prospects, empty array if no prospects exist)
    func getProspects() async throws -> [Prospect] {
        guard let trainerId = Auth.auth().currentUser?.uid else {
            throw ContactError.unauthorized
        }

        let start = Date()
        let sw = Stopwatch()

        do {
            let snapshot = try await db.collection(contactsCollection)
                .document(trainerId)
                .collection("prospects")
                .order(by: "addedAt", descending: true)
                .getDocuments()

            // Filter out converted prospects (keep for history tracking)
            let prospects = try snapshot.documents.compactMap { document -> Prospect? in
                let prospect = try document.data(as: Prospect.self)
                // Only return prospects that haven't been converted
                return prospect.convertedToClientId == nil ? prospect : nil
            }

            let duration = Date().timeIntervalSince(start) * 1000
            Log.i("ContactService", "Fetched \(prospects.count) prospects in \(Int(duration))ms (\(sw.ms)ms)")

            return prospects

        } catch {
            // Check if error is due to missing parent document (first time user)
            let errorDescription = error.localizedDescription
            if errorDescription.contains("Missing or insufficient permissions") ||
               errorDescription.contains("PERMISSION_DENIED") {
                // First time user - no contacts document exists yet
                // This is expected, return empty array
                Log.i("ContactService", "No contacts document exists yet (first time user). Returning empty array.")
                return []
            }

            // Other errors should be logged and thrown
            Log.e("ContactService", "Failed to fetch prospects: \(errorDescription)")
            throw ContactError.networkError
        }
    }

    /// Upgrade prospect to client by adding email and looking up existing user
    /// - Parameters:
    ///   - prospectId: ID of prospect to upgrade
    ///   - email: Client's email address (must exist in /users)
    /// - Returns: New Client document
    /// - Throws: ContactError (prospectNotFound, invalidEmail, userNotFound, networkError)
    func upgradeProspectToClient(prospectId: String, email: String) async throws -> Client {
        guard let trainerId = Auth.auth().currentUser?.uid else {
            throw ContactError.unauthorized
        }

        // Validate email format
        guard email.contains("@") else {
            throw ContactError.invalidEmail
        }

        Log.i("ContactService", "Upgrading prospect \(prospectId) with email: \(email)")

        let start = Date()
        let sw = Stopwatch()

        do {
            // Step 1: Fetch prospect
            let prospectRef = db.collection(contactsCollection)
                .document(trainerId)
                .collection("prospects")
                .document(prospectId)

            let prospectDoc = try await prospectRef.getDocument()

            guard prospectDoc.exists else {
                throw ContactError.prospectNotFound
            }

            let prospect = try prospectDoc.data(as: Prospect.self)

            // Step 2: Lookup user by email
            let user = try await userService.getUserByEmail(email)

            Log.i("ContactService", "Found user: \(user.displayName) (id: \(user.id))")

            // Step 3: Check if client already exists
            let clientRef = db.collection(contactsCollection)
                .document(trainerId)
                .collection("clients")
                .document(user.id)

            let existingDoc = try await clientRef.getDocument()

            if existingDoc.exists {
                Log.w("ContactService", "Client already exists: \(user.id)")
                throw ContactError.alreadyExists
            }

            // Step 4: Create Client with auto-populated displayName from user
            let client = Client(
                id: user.id,
                displayName: user.displayName,
                email: email,
                addedAt: Date(),
                lastContactedAt: nil
            )

            // Step 5: Write client to Firestore
            try await clientRef.setData(client.toDictionary())

            // Step 6: Update prospect document with convertedToClientId
            try await prospectRef.updateData([
                "convertedToClientId": user.id
            ])

            // Step 7: Update any existing chats to replace prospect ID with real client ID
            await updateChatsForUpgradedProspect(prospectId: prospectId, clientId: user.id)

            let duration = Date().timeIntervalSince(start) * 1000
            Log.i("ContactService", "Upgraded prospect to client \(client.displayName) in \(Int(duration))ms (\(sw.ms)ms)")

            return client

        } catch let error as ContactError {
            throw error
        } catch let error as UserServiceError {
            // Convert UserService errors to ContactError
            if case .userNotFound = error {
                throw ContactError.userNotFound
            } else if case .invalidEmail = error {
                throw ContactError.invalidEmail
            } else {
                throw ContactError.networkError
            }
        } catch {
            Log.e("ContactService", "Failed to upgrade prospect: \(error.localizedDescription)")
            throw ContactError.networkError
        }
    }

    /// Delete a prospect permanently
    /// - Parameter prospectId: Prospect's ID
    /// - Throws: ContactError (prospectNotFound, networkError)
    func deleteProspect(prospectId: String) async throws {
        guard let trainerId = Auth.auth().currentUser?.uid else {
            throw ContactError.unauthorized
        }

        Log.i("ContactService", "Deleting prospect: \(prospectId)")

        let start = Date()
        let sw = Stopwatch()

        do {
            let prospectRef = db.collection(contactsCollection)
                .document(trainerId)
                .collection("prospects")
                .document(prospectId)

            // Check if prospect exists
            let existingDoc = try await prospectRef.getDocument()

            guard existingDoc.exists else {
                throw ContactError.prospectNotFound
            }

            // Delete prospect document
            try await prospectRef.delete()

            let duration = Date().timeIntervalSince(start) * 1000
            Log.i("ContactService", "Deleted prospect \(prospectId) in \(Int(duration))ms (\(sw.ms)ms)")

        } catch let error as ContactError {
            throw error
        } catch {
            Log.e("ContactService", "Failed to delete prospect: \(error.localizedDescription)")
            throw ContactError.networkError
        }
    }

    // MARK: - Public Methods - Reverse Lookup

    /// Get all trainers who have the current user as a client
    /// - Returns: Array of trainer User objects
    /// - Throws: ContactError (unauthorized, networkError)
    func getMyTrainers() async throws -> [User] {
        guard let clientId = Auth.auth().currentUser?.uid else {
            throw ContactError.unauthorized
        }

        Log.i("ContactService", "Finding trainers for client: \(clientId)")

        let start = Date()
        let sw = Stopwatch()

        do {
            // Use collection group query to find all trainers who have this client
            // Query by "clientId" field which exists in all client documents
            let snapshot = try await db.collectionGroup("clients")
                .whereField("clientId", isEqualTo: clientId)
                .getDocuments()

            // Extract trainer IDs from the document paths
            let trainerIds = snapshot.documents.compactMap { doc -> String? in
                // Document path format: contacts/{trainerId}/clients/{clientId}
                let pathComponents = doc.reference.path.components(separatedBy: "/")
                guard pathComponents.count >= 2, pathComponents[0] == "contacts" else {
                    return nil
                }
                return pathComponents[1] // trainerId
            }

            Log.i("ContactService", "Found \(trainerIds.count) trainer(s) for client")

            // Fetch full User objects for each trainer
            var trainers: [User] = []
            for trainerId in trainerIds {
                if let trainer = try? await userService.getUser(id: trainerId) {
                    trainers.append(trainer)
                }
            }

            let duration = Date().timeIntervalSince(start) * 1000
            Log.i("ContactService", "Fetched \(trainers.count) trainer User objects in \(Int(duration))ms (\(sw.ms)ms)")

            return trainers

        } catch {
            Log.e("ContactService", "Failed to fetch trainers: \(error.localizedDescription)")
            throw ContactError.networkError
        }
    }

    /// Get all peer clients (other clients in shared group chats with current client)
    /// This allows clients to see and message other clients they share group chats with
    /// - Returns: Array of peer client User objects
    /// - Throws: ContactError (unauthorized, networkError)
    func getPeerClients() async throws -> [User] {
        guard let currentClientId = Auth.auth().currentUser?.uid else {
            throw ContactError.unauthorized
        }

        Log.i("ContactService", "Finding peer clients for: \(currentClientId)")

        let start = Date()
        let sw = Stopwatch()

        do {
            // Step 1: Find all group chats where current client is a member
            let chatsSnapshot = try await db.collection("chats")
                .whereField("members", arrayContains: currentClientId)
                .whereField("isGroupChat", isEqualTo: true)
                .getDocuments()

            // Step 2: Extract all unique member IDs from those group chats
            var allMemberIds = Set<String>()
            for chatDoc in chatsSnapshot.documents {
                if let members = chatDoc.data()["members"] as? [String] {
                    allMemberIds.formUnion(members)
                }
            }

            // Step 3: Remove current user from the set
            allMemberIds.remove(currentClientId)

            Log.i("ContactService", "Found \(allMemberIds.count) unique peer(s) in \(chatsSnapshot.documents.count) group chat(s)")

            // Step 4: Fetch User objects and filter to only clients (exclude trainers)
            var peerClients: [User] = []
            for memberId in allMemberIds {
                if let user = try? await userService.getUser(id: memberId),
                   user.role == .client {
                    peerClients.append(user)
                }
            }

            let duration = Date().timeIntervalSince(start) * 1000
            Log.i("ContactService", "Fetched \(peerClients.count) peer client User objects in \(Int(duration))ms (\(sw.ms)ms)")

            return peerClients

        } catch {
            Log.e("ContactService", "Failed to fetch peer clients: \(error.localizedDescription)")
            throw ContactError.networkError
        }
    }

    // MARK: - Public Methods - Search & Validation

    /// Search clients and prospects by name
    /// - Parameter query: Search query string
    /// - Returns: Combined array of clients and prospects matching query
    func searchContacts(query: String) async throws -> [Contact] {
        // Get all clients and prospects
        let clients = try await getClients()
        let prospects = try await getProspects()

        let lowercasedQuery = query.lowercased()

        // Filter by displayName
        let filteredClients = clients.filter { client in
            client.displayName.lowercased().contains(lowercasedQuery)
        }

        let filteredProspects = prospects.filter { prospect in
            prospect.displayName.lowercased().contains(lowercasedQuery)
        }

        // Combine into single array (clients first, then prospects)
        var results: [Contact] = filteredClients
        results.append(contentsOf: filteredProspects)

        Log.i("ContactService", "Search '\(query)' returned \(results.count) results")

        return results
    }

    /// Validate if relationship exists between trainer and client
    /// - Parameters:
    ///   - trainerId: Trainer's user ID
    ///   - clientId: Client's user ID
    /// - Returns: True if active relationship exists
    func validateRelationship(trainerId: String, clientId: String) async throws -> Bool {
        let start = Date()
        let sw = Stopwatch()

        do {
            let clientRef = db.collection(contactsCollection)
                .document(trainerId)
                .collection("clients")
                .document(clientId)

            let document = try await clientRef.getDocument()

            let exists = document.exists

            let duration = Date().timeIntervalSince(start) * 1000
            Log.i("ContactService", "Validated relationship trainer=\(trainerId) client=\(clientId) exists=\(exists) in \(Int(duration))ms (\(sw.ms)ms)")

            return exists

        } catch {
            Log.e("ContactService", "Failed to validate relationship: \(error.localizedDescription)")
            throw ContactError.networkError
        }
    }

    // MARK: - Private Helper Methods

    /// Ensures the parent contacts document exists for a trainer
    /// Creates an empty document if it doesn't exist
    /// - Parameter trainerId: The trainer's user ID
    private func ensureContactsDocumentExists(trainerId: String) async throws {
        let contactsRef = db.collection(contactsCollection).document(trainerId)

        do {
            let document = try await contactsRef.getDocument()

            if !document.exists {
                // Create parent document with metadata
                try await contactsRef.setData([
                    "createdAt": FieldValue.serverTimestamp(),
                    "trainerId": trainerId
                ])
                Log.i("ContactService", "Created contacts parent document for trainer: \(trainerId)")
            }
        } catch {
            Log.e("ContactService", "Failed to ensure contacts document exists: \(error.localizedDescription)")
            throw ContactError.networkError
        }
    }

    /// Updates all chats that contain the prospect ID to use the real client ID instead
    /// This ensures presence indicators work correctly after prospect upgrade
    /// - Parameters:
    ///   - prospectId: The prospect ID to replace in chat members
    ///   - clientId: The real client user ID to replace it with
    private func updateChatsForUpgradedProspect(prospectId: String, clientId: String) async {
        let chatsSw = Stopwatch()
        Log.i("ContactService", "Updating chats for upgraded prospect: \(prospectId) -> \(clientId)")

        do {
            // Find all chats where the prospect ID is in the members array
            let chatsSnapshot = try await db.collection("chats")
                .whereField("members", arrayContains: prospectId)
                .getDocuments()

            guard !chatsSnapshot.documents.isEmpty else {
                Log.i("ContactService", "No chats found with prospect ID \(prospectId)")
                return
            }

            Log.i("ContactService", "Found \(chatsSnapshot.documents.count) chat(s) to update")

            // Update each chat to replace prospect ID with client ID
            for document in chatsSnapshot.documents {
                do {
                    // Get current members array
                    guard var members = document.data()["members"] as? [String] else {
                        Log.w("ContactService", "Chat \(document.documentID) has invalid members array")
                        continue
                    }

                    // Replace prospect ID with client ID
                    if let index = members.firstIndex(of: prospectId) {
                        members[index] = clientId

                        // Update the chat document
                        try await document.reference.updateData([
                            "members": members
                        ])

                        Log.i("ContactService", "✅ Updated chat \(document.documentID): replaced \(prospectId) with \(clientId)")
                    }
                } catch {
                    Log.e("ContactService", "Failed to update chat \(document.documentID): \(error.localizedDescription)")
                    // Continue updating other chats even if one fails
                }
            }

            Log.i("ContactService", "Finished updating chats in \(chatsSw.ms)ms")

        } catch {
            Log.e("ContactService", "Failed to query chats for prospect upgrade: \(error.localizedDescription)")
            // Don't throw - this is a best-effort update, main upgrade should succeed
        }
    }
}

// MARK: - Error Types

/// Errors that can occur during ContactService operations
enum ContactError: Error, LocalizedError {
    case invalidEmail
    case invalidName
    case userNotFound
    case alreadyExists
    case clientNotFound
    case prospectNotFound
    case networkError
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address"
        case .invalidName:
            return "Name is required"
        case .userNotFound:
            return "User not found. Client must have a Psst account"
        case .alreadyExists:
            return "This user is already in your client list"
        case .clientNotFound:
            return "Client not found in your contacts"
        case .prospectNotFound:
            return "Prospect not found"
        case .networkError:
            return "Network error. Please try again"
        case .unauthorized:
            return "You don't have permission to perform this action"
        }
    }
}

