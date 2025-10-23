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
import UIKit

/// Service for handling real-time message sending and receiving
/// Uses Firestore snapshot listeners for sub-100ms message delivery
class MessageService {
    
    // MARK: - Properties
    
    /// Firestore database reference
    private let db = Firestore.firestore()
    
    // MARK: - Send Message
    
    /// Sends a message to a chat with optimistic UI support
    /// - Parameters:
    ///   - chatID: The ID of the chat to send message to
    ///   - text: The message text (will be trimmed)
    ///   - messageID: Optional pre-generated message ID (for queue processing)
    ///   - optimisticCompletion: Optional closure called immediately with optimistic message (before Firestore)
    /// - Returns: The ID of the created message
    /// - Throws: MessageError if validation fails, offline, or Firestore write fails
    func sendMessage(
        chatID: String,
        text: String,
        messageID: String? = nil,
        optimisticCompletion: ((Message) -> Void)? = nil
    ) async throws -> String {
        // Validate chat ID
        guard !chatID.isEmpty else {
            throw MessageError.invalidChatID
        }
        
        // Trim and validate message text
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        try validateMessageText(trimmedText)
        
        // Get current user ID
        let senderID = try getCurrentUserID()
        
        // Use provided message ID or generate new one (for queue processing vs new messages)
        let finalMessageID = messageID ?? UUID().uuidString
        
        // Create optimistic message with .sending status
        let optimisticMessage = Message(
            id: finalMessageID,
            text: trimmedText,
            senderID: senderID,
            timestamp: Date(),
            readBy: [],
            sendStatus: .sending
        )
        
        // Call optimistic completion IMMEDIATELY (before Firestore)
        // This allows UI to show message instantly
        optimisticCompletion?(optimisticMessage)
        print("⚡️ Optimistic message added: \(finalMessageID)")
        
        // Check network state
        if !NetworkMonitor.shared.isConnected {
            // Create queued message
            let queuedMessage = QueuedMessage(
                id: finalMessageID,
                chatID: chatID,
                text: trimmedText,
                timestamp: Date(),
                retryCount: 0
            )
            
            // Enqueue for offline sync
            try MessageQueue.shared.enqueue(queuedMessage)
            print("📥 Message queued for offline send: \(finalMessageID)")
            
            // Throw offline error (allows caller to update UI to "queued" status)
            throw MessageError.offline
        }
        
        // Log message send
        print("📤 Sending message to chat: \(chatID)")
        
        do {
            // Write message to Firestore (online path)
            let messageRef = db
                .collection("chats")
                .document(chatID)
                .collection("messages")
                .document(finalMessageID)
            
            try await messageRef.setData(optimisticMessage.toDictionary())
            
            // Update chat document with last message metadata
            try await updateChatLastMessage(chatID: chatID, text: trimmedText)
            
            print("✅ Message sent successfully: \(finalMessageID)")
            
            return finalMessageID
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

    // MARK: - Send Image Message (PR #009)
    
    /// Sends an image message to a chat. Handles compression, thumbnail generation, and Storage upload before Firestore write.
    /// - Parameters:
    ///   - chatID: Target chat ID
    ///   - image: Original UIImage (will be compressed optimally)
    ///   - messageID: Optional pre-generated message ID (for deterministic paths)
    ///   - optimisticCompletion: Called immediately with an optimistic message (mediaType set to "image") before upload
    /// - Returns: The ID of the created message
    /// - Throws: MessageError or ImageUploadError if validation/upload fails
    func sendImageMessage(
        chatID: String,
        image: UIImage,
        messageID: String? = nil,
        optimisticCompletion: ((Message) -> Void)? = nil
    ) async throws -> String {
        // Validate chat ID
        guard !chatID.isEmpty else {
            throw MessageError.invalidChatID
        }
        
        // Get current user ID
        let senderID = try getCurrentUserID()
        
        // Use provided message ID or generate new one
        let finalMessageID = messageID ?? UUID().uuidString
        
        // Create optimistic placeholder message
        let optimisticMessage = Message(
            id: finalMessageID,
            text: "",
            senderID: senderID,
            timestamp: Date(),
            readBy: [],
            sendStatus: .sending,
            mediaType: "image"
        )
        
        // Return optimistic message immediately
        optimisticCompletion?(optimisticMessage)
        print("⚡️ Optimistic image message added: \(finalMessageID)")
        
        // Check network state (image uploads require network)
        if !NetworkMonitor.shared.isConnected {
            print("📥 Image message queued (offline): \(finalMessageID)")
            throw MessageError.offline
        }
        
        // Compress image (<=2MB, <=1920x1080) - single compression, no double-encoding!
        print("🖼️  Compressing image (single pass, optimal quality)...")
        let uploadService = ImageUploadService.shared
        let compressedData = try await uploadService.compressImage(image)
        print("✅ Compression complete: \(compressedData.count) bytes")
        
        // Generate thumbnail from compressed data
        print("📐 Generating thumbnail for message: \(finalMessageID)")
        let thumbnailData = try await uploadService.generateThumbnail(from: compressedData)
        print("✅ Thumbnail generated: \(thumbnailData.count) bytes")
        
        // Upload image and thumbnail to Storage in parallel (faster than sequential!)
        print("☁️  Uploading image and thumbnail in parallel...")
        async let mediaURLTask = uploadService.uploadImage(imageData: compressedData, chatID: chatID, messageID: finalMessageID)
        async let mediaThumbnailURLTask = uploadService.uploadThumbnail(thumbnailData: thumbnailData, chatID: chatID, messageID: finalMessageID)
        
        let (mediaURL, mediaThumbnailURL) = try await (mediaURLTask, mediaThumbnailURLTask)
        print("✅ Upload complete: image + thumbnail")
        
        // Determine compressed image dimensions
        let compressedImageSize: CGSize = (UIImage(data: compressedData)?.size) ?? image.size
        let width = Int(compressedImageSize.width.rounded())
        let height = Int(compressedImageSize.height.rounded())
        
        // Build final message with media metadata
        let finalMessage = Message(
            id: finalMessageID,
            text: "",
            senderID: senderID,
            timestamp: Date(),
            readBy: [],
            sendStatus: nil,
            mediaType: "image",
            mediaURL: mediaURL,
            mediaThumbnailURL: mediaThumbnailURL,
            mediaSize: compressedData.count,
            mediaDimensions: ["width": width, "height": height]
        )
        
        do {
            // Persist to Firestore
            let messageRef = db
                .collection("chats")
                .document(chatID)
                .collection("messages")
                .document(finalMessageID)
            
            try await messageRef.setData(finalMessage.toDictionary())
            
            // Update chat document last message to a placeholder label
            try await updateChatLastMessage(chatID: chatID, text: "Image")
            
            print("✅ Image message sent successfully: \(finalMessageID)")
            
            return finalMessageID
        } catch {
            print("❌ Image message send failed: \(error.localizedDescription)")
            throw MessageError.firestoreError(error)
        }
    }
    
    // MARK: - Read Receipts (PR #14, PR #5)
    
    /// Fetches detailed read receipt information for a message
    /// Combines message.readBy array with user data from UserService
    /// - Parameters:
    ///   - message: The message to fetch read receipt details for
    ///   - chat: The chat containing the message (for member list)
    /// - Returns: Array of ReadReceiptDetail with user names and read status, sorted alphabetically (read members first, then unread)
    /// - Throws: MessageError if user data fetch fails
    func fetchReadReceiptDetails(for message: Message, in chat: Chat) async throws -> [ReadReceiptDetail] {
        print("📖 Fetching read receipt details for message \(message.id)")
        let start = Date()
        
        // Get recipient member IDs (all members except sender)
        let recipientIDs = chat.members.filter { $0 != message.senderID }
        
        guard !recipientIDs.isEmpty else {
            print("📖 No recipients to fetch")
            return []
        }
        
        print("📖 Fetching details for \(recipientIDs.count) recipients")
        
        // Batch fetch user data using UserService
        let users = try await UserService.shared.getUsers(ids: recipientIDs)
        
        // Build ReadReceiptDetail objects
        var details: [ReadReceiptDetail] = []
        
        for userID in recipientIDs {
            // Find user in fetched users array
            if let user = users.first(where: { $0.id == userID }) {
                let hasRead = message.readBy.contains(userID)
                
                let detail = ReadReceiptDetail(
                    id: userID,
                    userID: userID,
                    userName: user.displayName,
                    userPhotoURL: user.photoURL,
                    hasRead: hasRead
                )
                
                details.append(detail)
            } else {
                // User not found - create fallback entry
                print("⚠️ User \(userID) not found, using fallback")
                
                let hasRead = message.readBy.contains(userID)
                
                let detail = ReadReceiptDetail(
                    id: userID,
                    userID: userID,
                    userName: "Unknown User",
                    userPhotoURL: nil,
                    hasRead: hasRead
                )
                
                details.append(detail)
            }
        }
        
        // Sort alphabetically by userName
        // Read members first, then not read yet members
        let readDetails = details.filter { $0.hasRead }.sorted { $0.userName < $1.userName }
        let unreadDetails = details.filter { !$0.hasRead }.sorted { $0.userName < $1.userName }
        
        let sortedDetails = readDetails + unreadDetails
        
        // Log performance
        let duration = Date().timeIntervalSince(start) * 1000
        print("📖 Fetched \(details.count) read receipt details in \(Int(duration))ms")
        
        return sortedDetails
    }
    
    /// Marks specific messages as read by the current user
    /// Uses atomic arrayUnion for idempotent updates (safe to call multiple times)
    /// - Parameters:
    ///   - chatID: The chat containing the messages
    ///   - messageIDs: Array of message IDs to mark as read
    /// - Throws: MessageError if validation fails or Firestore write fails
    func markMessagesAsRead(chatID: String, messageIDs: [String]) async throws {
        // Validate user is authenticated
        let currentUserID = try getCurrentUserID()
        
        // Validate chatID is not empty
        guard !chatID.isEmpty else {
            throw MessageError.invalidChatID
        }
        
        // Validate messageIDs array is not empty
        guard !messageIDs.isEmpty else {
            print("📖 No messages to mark as read")
            return
        }
        
        print("📖 Marking \(messageIDs.count) messages as read")
        
        do {
            // Create batch write for efficient updates (max 500 operations per batch)
            let batch = db.batch()
            
            for messageID in messageIDs {
                let messageRef = db.collection("chats").document(chatID)
                                   .collection("messages").document(messageID)
                
                // Use arrayUnion for atomic, idempotent update (prevents duplicates)
                batch.updateData([
                    "readBy": FieldValue.arrayUnion([currentUserID])
                ], forDocument: messageRef)
            }
            
            // Commit batch write
            try await batch.commit()
            
            print("✅ Marked \(messageIDs.count) messages as read")
        } catch {
            print("❌ Failed to mark messages as read: \(error.localizedDescription)")
            throw MessageError.firestoreError(error)
        }
    }
    
    /// Marks all unread messages in a chat as read by the current user
    /// Automatically filters to only mark messages from others (not own messages)
    /// - Parameter chatID: The chat to mark messages in
    /// - Throws: MessageError if validation fails or Firestore write fails
    func markChatMessagesAsRead(chatID: String) async throws {
        // Validate user is authenticated
        let currentUserID = try getCurrentUserID()
        
        // Validate chatID is not empty
        guard !chatID.isEmpty else {
            throw MessageError.invalidChatID
        }
        
        print("📖 Fetching unread messages for chat: \(chatID)")
        
        do {
            // Fetch all messages in chat
            let messagesSnapshot = try await db.collection("chats")
                .document(chatID)
                .collection("messages")
                .getDocuments()
            
            // Filter messages that need marking
            let messagesToMark = messagesSnapshot.documents.compactMap { doc -> String? in
                guard let message = try? doc.data(as: Message.self) else { return nil }
                
                // Skip messages sent by current user (can't read own messages)
                if message.senderID == currentUserID { return nil }
                
                // Skip messages already read by current user
                if message.readBy.contains(currentUserID) { return nil }
                
                return message.id
            }
            
            // Return early if no messages to mark
            if messagesToMark.isEmpty {
                print("📖 No unread messages to mark")
                return
            }
            
            print("📖 Marking \(messagesToMark.count) unread messages as read")
            
            // Handle large message counts with chunking (Firestore batch limit: 500 operations)
            let chunkSize = 500
            let chunks = stride(from: 0, to: messagesToMark.count, by: chunkSize).map {
                Array(messagesToMark[$0..<min($0 + chunkSize, messagesToMark.count)])
            }
            
            if chunks.count > 1 {
                print("📖 Processing \(chunks.count) batches")
            }
            
            // Mark messages in chunks
            for chunk in chunks {
                try await markMessagesAsRead(chatID: chatID, messageIDs: chunk)
            }
            
            print("✅ All unread messages marked as read")
        } catch {
            print("❌ Failed to mark chat messages as read: \(error.localizedDescription)")
            throw MessageError.firestoreError(error)
        }
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
    case offline           // Message queued for offline send
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
        case .offline:
            return "Message queued - will send when online"
        case .firestoreError(let error):
            return "Firestore error: \(error.localizedDescription)"
        }
    }
}

