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
    case firestoreError(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User must be logged in to create chats"
        case .cannotChatWithSelf:
            return "Cannot create a chat with yourself"
        case .invalidUserID:
            return "Invalid user ID provided"
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
}

