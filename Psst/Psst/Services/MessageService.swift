//
//  MessageService.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #8
//  Real-time messaging service for sending and receiving messages
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Service for handling real-time message sending and receiving
/// Uses Firestore snapshot listeners for sub-100ms message delivery
class MessageService {
    
    // MARK: - Properties
    
    /// Firestore database reference
    private let db = Firestore.firestore()
    
    // MARK: - Send Message
    
    /// Sends a message to a chat
    /// - Parameters:
    ///   - chatID: The ID of the chat to send message to
    ///   - text: The message text (will be trimmed)
    /// - Returns: The ID of the created message
    /// - Throws: MessageError if validation fails or Firestore write fails
    func sendMessage(chatID: String, text: String) async throws -> String {
        // Validate chat ID
        guard !chatID.isEmpty else {
            throw MessageError.invalidChatID
        }
        
        // Trim and validate message text
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        try validateMessageText(trimmedText)
        
        // Get current user ID
        let senderID = try getCurrentUserID()
        
        // Generate unique message ID
        let messageID = UUID().uuidString
        
        // Create message object
        let message = Message(
            id: messageID,
            text: trimmedText,
            senderID: senderID,
            timestamp: Date(),
            readBy: []
        )
        
        // Log message send
        print("📤 Sending message to chat: \(chatID)")
        
        do {
            // Write message to Firestore
            let messageRef = db
                .collection("chats")
                .document(chatID)
                .collection("messages")
                .document(messageID)
            
            try await messageRef.setData(message.toDictionary())
            
            // Update chat document with last message metadata
            try await updateChatLastMessage(chatID: chatID, text: trimmedText)
            
            print("✅ Message sent successfully: \(messageID)")
            
            return messageID
        } catch {
            print("❌ Send failed: \(error.localizedDescription)")
            throw MessageError.firestoreError(error)
        }
    }
    
    // MARK: - Observe Messages
    
    /// Observes messages in a chat with real-time updates
    /// - Parameters:
    ///   - chatID: The ID of the chat to observe
    ///   - completion: Called with array of messages on each update
    /// - Returns: ListenerRegistration to remove listener later
    func observeMessages(chatID: String, completion: @escaping ([Message]) -> Void) -> ListenerRegistration {
        print("👂 Listening for messages in chat: \(chatID)")
        
        // Create Firestore query ordered by timestamp
        let query = db
            .collection("chats")
            .document(chatID)
            .collection("messages")
            .order(by: "timestamp", descending: false)
        
        // Attach snapshot listener
        let listener = query.addSnapshotListener { snapshot, error in
            // Handle errors
            if let error = error {
                print("❌ Listener error: \(error.localizedDescription)")
                completion([])
                return
            }
            
            // Parse snapshot to Message array
            guard let documents = snapshot?.documents else {
                print("📨 Received 0 messages")
                completion([])
                return
            }
            
            // Decode messages from Firestore documents
            let messages = documents.compactMap { document -> Message? in
                do {
                    return try document.data(as: Message.self)
                } catch {
                    print("⚠️ Failed to decode message \(document.documentID): \(error)")
                    return nil
                }
            }
            
            print("📨 Received \(messages.count) messages")
            
            // Call completion handler with messages
            completion(messages)
        }
        
        return listener
    }
    
    // MARK: - Helper Methods
    
    /// Validates message text
    /// - Parameter text: The text to validate (should already be trimmed)
    /// - Throws: MessageError.emptyText or .textTooLong
    private func validateMessageText(_ text: String) throws {
        // Check for empty text
        if text.isEmpty {
            throw MessageError.emptyText
        }
        
        // Check for text length (Firestore best practice: 10,000 character limit)
        if text.count > 10000 {
            throw MessageError.textTooLong
        }
    }
    
    /// Gets current authenticated user ID
    /// - Returns: User ID
    /// - Throws: MessageError.notAuthenticated if no user logged in
    private func getCurrentUserID() throws -> String {
        guard let currentUser = Auth.auth().currentUser else {
            throw MessageError.notAuthenticated
        }
        return currentUser.uid
    }
    
    /// Updates chat document with last message metadata
    /// - Parameters:
    ///   - chatID: The chat to update
    ///   - text: The message text
    private func updateChatLastMessage(chatID: String, text: String) async throws {
        let chatRef = db.collection("chats").document(chatID)
        
        try await chatRef.updateData([
            "lastMessage": text,
            "lastMessageTimestamp": FieldValue.serverTimestamp()
        ])
    }
}

// MARK: - Errors

/// Errors that can occur during message operations
enum MessageError: LocalizedError {
    case notAuthenticated
    case emptyText
    case textTooLong
    case invalidChatID
    case firestoreError(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User must be logged in to send messages"
        case .emptyText:
            return "Message text cannot be empty"
        case .textTooLong:
            return "Message text is too long (max 10,000 characters)"
        case .invalidChatID:
            return "Invalid chat ID"
        case .firestoreError(let error):
            return "Firestore error: \(error.localizedDescription)"
        }
    }
}

