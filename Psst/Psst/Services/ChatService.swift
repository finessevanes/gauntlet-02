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
}

