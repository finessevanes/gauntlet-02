//
//  ChatService.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #6
//  Service layer for chat-related Firestore operations
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - Errors

/// Errors that can occur during chat operations
enum ChatError: LocalizedError {
    case notAuthenticated
    case cannotChatWithSelf
    case invalidUserID
    case invalidGroupName
    case insufficientMembers
    case relationshipNotFound  // NEW: PR #009
    case firestoreError(Error)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User must be logged in to create chats"
        case .cannotChatWithSelf:
            return "Cannot create a chat with yourself"
        case .invalidUserID:
            return "Invalid user ID provided"
        case .invalidGroupName:
            return "Group name must be 1-50 characters"
        case .insufficientMembers:
            return "Groups require at least 3 members"
        case .relationshipNotFound:
            return "This trainer hasn't added you as a client yet"
        case .firestoreError(let error):
            return "Firestore error: \(error.localizedDescription)"
        }
    }
}

/// Service managing chat operations with Firestore
/// Handles real-time chat listing and user data fetching
class ChatService {
    // MARK: - Properties

    private let db = Firestore.firestore()
    private let contactService = ContactService.shared  // PR #009
    private let userService = UserService.shared  // PR #009
    
    // MARK: - Public Methods
    
    /// Observe all chats for a specific user with real-time updates
    /// Returns a listener that must be removed when view disappears to prevent memory leaks
    /// - Parameters:
    ///   - userID: The user ID to fetch chats for
    ///   - completion: Closure called with updated chat array whenever changes occur
    /// - Returns: ListenerRegistration to remove listener later
    func observeUserChats(userID: String, completion: @escaping ([Chat]) -> Void) -> ListenerRegistration {
        // Query chats where user is a member, sorted by most recent first
        return db.collection("chats")
            .whereField("members", arrayContains: userID)
            .order(by: "lastMessageTimestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                // Handle errors gracefully
                if let error = error {
                    print("❌ Error observing chats: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                // Parse documents into Chat objects
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                
                // Decode each document to Chat model
                let chats = documents.compactMap { document -> Chat? in
                    do {
                        return try document.data(as: Chat.self)
                    } catch {
                        print("⚠️ Error decoding chat \(document.documentID): \(error.localizedDescription)")
                        return nil
                    }
                }
                
                // Call completion with sorted chats
                completion(chats)
            }
    }
    
    /// Fetch a user's display name from Firestore
    /// Returns "Unknown User" if user document not found
    /// - Parameter userID: The user ID to fetch name for
    /// - Returns: User's display name or fallback
    /// - Throws: Firestore errors (except document not found, which returns fallback)
    func fetchUserName(userID: String) async throws -> String {
        do {
            let document = try await db.collection("users").document(userID).getDocument()
            
            // Check if document exists
            guard document.exists else {
                print("⚠️ User document not found for ID: \(userID)")
                return "Unknown User"
            }
            
            // Try to decode as User model
            if let user = try? document.data(as: User.self) {
                return user.displayName
            }
            
            // Fallback: try to get displayName directly from data
            if let displayName = document.data()?["displayName"] as? String {
                return displayName
            }
            
            return "Unknown User"
        } catch {
            print("❌ Error fetching user name for \(userID): \(error.localizedDescription)")
            return "Unknown User"
        }
    }
    
    /// Fetch a chat by ID
    /// - Parameter chatID: The chat document ID
    /// - Returns: Chat object
    /// - Throws: Firestore errors or decoding errors
    func fetchChat(chatID: String) async throws -> Chat {
        let document = try await db.collection("chats").document(chatID).getDocument()
        
        guard document.exists else {
            throw NSError(domain: "ChatService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Chat not found"])
        }
        
        return try document.data(as: Chat.self)
    }
    
    // MARK: - Create Chat
    
    /// Creates a new 1-on-1 chat or returns existing chat if one already exists
    /// Performs duplicate check before creating to prevent multiple chats with same user
    /// - Parameter targetUserID: The ID of the user to create a chat with
    /// - Returns: The ID of the created or existing chat
    /// - Throws: ChatError if validation fails or Firestore operations fail
    func createChat(withUserID targetUserID: String) async throws -> String {
        // Validate current user is authenticated
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            print("❌ Cannot create chat: user not authenticated")
            throw ChatError.notAuthenticated
        }

        // Validate target user is not self
        guard targetUserID != currentUserID else {
            print("❌ Cannot create chat: target user is self")
            throw ChatError.cannotChatWithSelf
        }

        // Validate target user ID is not empty
        guard !targetUserID.isEmpty else {
            print("❌ Cannot create chat: target user ID is empty")
            throw ChatError.invalidUserID
        }

        // PR #009: Relationship validation (feature flag controlled)
        if FeatureFlags.enableRelationshipValidation {
            do {
                // Get both users to determine roles
                let currentUser = try await userService.getUser(id: currentUserID)
                let targetUser = try await userService.getUser(id: targetUserID)

                // Determine trainer/client based on roles
                if currentUser.role == .trainer && targetUser.role == .client {
                    // Validate trainer → client relationship
                    let hasRelationship = try await contactService.validateRelationship(
                        trainerId: currentUserID,
                        clientId: targetUserID
                    )
                    if !hasRelationship {
                        print("❌ Relationship not found: trainer=\(currentUserID) client=\(targetUserID)")
                        throw ChatError.relationshipNotFound
                    }
                    print("✅ Validated trainer→client relationship")
                } else if currentUser.role == .client && targetUser.role == .trainer {
                    // Validate client → trainer relationship (reversed)
                    let hasRelationship = try await contactService.validateRelationship(
                        trainerId: targetUserID,
                        clientId: currentUserID
                    )
                    if !hasRelationship {
                        print("❌ Relationship not found: trainer=\(targetUserID) client=\(currentUserID)")
                        throw ChatError.relationshipNotFound
                    }
                    print("✅ Validated client→trainer relationship")
                }
                // Both trainers or both clients: no validation needed (business decision)
            } catch let error as ChatError {
                // Re-throw ChatError as-is
                throw error
            } catch {
                // Log other errors but don't block chat creation (graceful degradation)
                print("⚠️ Relationship validation failed, allowing chat: \(error.localizedDescription)")
            }
        }

        // Step 1: Check for existing chat with this user
        print("🔍 Checking for existing chat with user: \(targetUserID)")
        do {
            let snapshot = try await db.collection("chats")
                .whereField("members", arrayContains: currentUserID)
                .getDocuments()
            
            // Filter for existing 1-on-1 chat with target user
            for document in snapshot.documents {
                let data = document.data()
                if let members = data["members"] as? [String],
                   members.count == 2,
                   members.contains(targetUserID),
                   let isGroupChat = data["isGroupChat"] as? Bool,
                   !isGroupChat {
                    // Validate the chat can be decoded properly
                    do {
                        let _ = try document.data(as: Chat.self)
                        // Existing valid chat found - return its ID
                        print("✅ Found existing chat: \(document.documentID)")
                        return document.documentID
                    } catch {
                        // Chat exists but is malformed - skip it and allow new chat creation
                        print("⚠️ Found chat \(document.documentID) but it's malformed, skipping: \(error.localizedDescription)")
                        continue
                    }
                }
            }
            
            // Step 2: No existing chat found - create new one
            let newChatID = UUID().uuidString
            print("➕ Creating new chat with ID: \(newChatID)")
            
            let newChat: [String: Any] = [
                "id": newChatID,
                "members": [currentUserID, targetUserID],
                "lastMessage": "",
                "lastMessageTimestamp": FieldValue.serverTimestamp(),
                "isGroupChat": false,
                "createdAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp()
            ]
            
            try await db.collection("chats").document(newChatID).setData(newChat)
            print("✅ Created new chat: \(newChatID)")
            
            return newChatID
        } catch {
            print("❌ Error creating chat: \(error.localizedDescription)")
            throw ChatError.firestoreError(error)
        }
    }
    
    // MARK: - Unread Message Count
    
    /// Get the count of unread messages for the current user in a specific chat
    /// Queries the messages subcollection where currentUserID is NOT in the readBy array
    /// Used for unread message indicators in ChatRowView
    /// - Parameters:
    ///   - chatID: The chat ID to query
    ///   - currentUserID: The current user's ID
    /// - Returns: Number of unread messages (0 if all read or chat empty)
    /// - Throws: Firestore errors, ChatError for invalid parameters
    func getUnreadMessageCount(chatID: String, currentUserID: String) async throws -> Int {
        // Validate parameters
        guard !chatID.isEmpty else {
            print("❌ Cannot get unread count: chatID is empty")
            throw ChatError.invalidUserID
        }
        
        guard !currentUserID.isEmpty else {
            print("❌ Cannot get unread count: currentUserID is empty")
            throw ChatError.invalidUserID
        }
        
        do {
            // Query messages where currentUserID is NOT in readBy array
            // Firestore doesn't have a native "arrayDoesNotContain" query
            // So we need to fetch all messages and filter client-side
            // For better performance, we limit to recent messages (last 100)
            let snapshot = try await db.collection("chats")
                .document(chatID)
                .collection("messages")
                .order(by: "timestamp", descending: true)
                .limit(to: 100)
                .getDocuments()
            
            // Filter messages where currentUserID is NOT in readBy
            let unreadMessages = snapshot.documents.filter { document in
                // Get readBy array, default to empty if missing
                let readBy = document.data()["readBy"] as? [String] ?? []
                
                // Get senderID to skip own messages
                let senderID = document.data()["senderID"] as? String ?? ""
                
                // Skip own messages (you can't have "unread" messages you sent yourself)
                if senderID == currentUserID {
                    return false
                }
                
                // Message is unread if currentUserID is NOT in readBy array
                return !readBy.contains(currentUserID)
            }
            
            let count = unreadMessages.count
            return count
            
        } catch {
            print("❌ Error fetching unread message count for chat \(chatID): \(error.localizedDescription)")
            // Return 0 instead of throwing to prevent UI errors
            // The indicator will just show no unread messages
            return 0
        }
    }
    
    // MARK: - Create Group Chat
    
    /// Creates a new group chat with 3+ members and a custom name
    /// - Parameters:
    ///   - memberUserIDs: Array of user IDs to include in the group (must be 3+)
    ///   - groupName: Name for the group chat (1-50 characters)
    /// - Returns: The ID of the created group chat
    /// - Throws: ChatError if validation fails or Firestore operations fail
    func createGroupChat(withMembers memberUserIDs: [String], groupName: String) async throws -> String {
        // Validate current user is authenticated
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            print("❌ Cannot create group chat: user not authenticated")
            throw ChatError.notAuthenticated
        }
        
        // Validate group name
        let trimmedName = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, trimmedName.count <= 50 else {
            print("❌ Cannot create group chat: invalid group name")
            throw ChatError.invalidGroupName
        }
        
        // Ensure current user is in members array
        var allMembers = memberUserIDs
        if !allMembers.contains(currentUserID) {
            allMembers.append(currentUserID)
        }
        
        // Validate minimum 3 total members (current user + 2 others)
        guard allMembers.count >= 3 else {
            print("❌ Cannot create group chat: need at least 3 total members (you + 2 others), got \(allMembers.count)")
            throw ChatError.insufficientMembers
        }
        
        // Check for duplicate group (same name case-insensitive + same members)
        print("🔍 Checking for duplicate group with name '\(trimmedName)' and \(allMembers.count) members")
        do {
            let snapshot = try await db.collection("chats")
                .whereField("members", arrayContains: currentUserID)
                .whereField("isGroupChat", isEqualTo: true)
                .getDocuments()
            
            let sortedMembers = allMembers.sorted()
            
            for document in snapshot.documents {
                let data = document.data()
                
                // Check if group name matches (case-insensitive) and members match
                if let existingGroupName = data["groupName"] as? String,
                   existingGroupName.lowercased() == trimmedName.lowercased(),
                   let existingMembers = data["members"] as? [String] {
                    
                    let sortedExistingMembers = existingMembers.sorted()
                    
                    // If same members and same name (case-insensitive), it's a duplicate
                    if sortedMembers == sortedExistingMembers {
                        print("✅ Found existing group '\(existingGroupName)' with matching members: \(document.documentID)")
                        return document.documentID
                    }
                }
            }
        } catch {
            print("⚠️ Error checking for duplicate groups: \(error.localizedDescription)")
            // Continue with creation if check fails
        }
        
        // Create new group chat
        let newChatID = UUID().uuidString
        print("➕ Creating new group chat '\(trimmedName)' with \(allMembers.count) members")
        
        let newChat: [String: Any] = [
            "id": newChatID,
            "members": allMembers,
            "lastMessage": "",
            "lastMessageTimestamp": FieldValue.serverTimestamp(),
            "isGroupChat": true,
            "groupName": trimmedName,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        do {
            try await db.collection("chats").document(newChatID).setData(newChat)
            print("✅ Created new group chat: \(newChatID)")
            return newChatID
        } catch {
            print("❌ Error creating group chat: \(error.localizedDescription)")
            throw ChatError.firestoreError(error)
        }
    }
}

