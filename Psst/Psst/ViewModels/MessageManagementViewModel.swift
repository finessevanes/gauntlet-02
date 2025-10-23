//
//  MessageManagementViewModel.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - Refactored from ChatView
//  Handles message state, sending, receiving, and status tracking
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

/// View model responsible for message management in chat
/// Handles message state, sending, receiving, optimistic UI, and status tracking
@MainActor
class MessageManagementViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// All messages (includes both optimistic and confirmed from Firestore)
    @Published var messages: [Message] = []
    
    /// Latest message IDs for each status type (PR #2 - Timeline View)
    /// Shows status on the latest message of each type for complete status visibility
    @Published var latestReadMessageID: String? = nil
    @Published var latestDeliveredMessageID: String? = nil
    @Published var latestFailedMessageID: String? = nil
    
    /// Count of queued messages for this chat
    @Published var queueCount: Int = 0
    
    /// Cache for sender names (userID -> displayName) for group chats
    @Published var senderNames: [String: String] = [:]
    
    // MARK: - Private Properties
    
    /// The chat being managed
    private let chat: Chat
    
    /// Current user ID from Firebase Auth
    private var currentUserID: String = ""
    
    /// Message service for real-time messaging
    private let messageService = MessageService()
    
    /// Chat service for fetching user names
    private let chatService = ChatService()
    
    /// Firestore listener registration for cleanup
    private var messageListener: ListenerRegistration?
    
    // MARK: - Initialization
    
    init(chat: Chat) {
        self.chat = chat
    }
    
    // MARK: - Public Methods
    
    /// Initialize the view model with current user ID
    func initialize(currentUserID: String) {
        self.currentUserID = currentUserID
        startListeningForMessages()
        updateQueueCount()
        
        // Prefetch sender names for group chats
        if chat.isGroupChat {
            Task {
                await prefetchSenderNames()
            }
        }
        
        // Mark messages as read when chat opens
        markMessagesAsRead()
    }
    
    /// Clean up resources when chat is closed
    func cleanup() {
        stopListeningForMessages()
    }
    
    /// Send a text message with optimistic UI
    func sendMessage(text: String) async {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        do {
            _ = try await messageService.sendMessage(
                chatID: chat.id,
                text: trimmedText,
                optimisticCompletion: { optimisticMessage in
                    // Add message to UI immediately (before Firestore confirms)
                    self.messages.append(optimisticMessage)
                    self.updateLatestMessageIDs()
                }
            )
        } catch MessageError.offline {
            // Message queued for offline send - update status to .queued
            if let index = messages.firstIndex(where: { $0.sendStatus == .sending }) {
                messages[index].sendStatus = .queued
            }
            updateQueueCount()
        } catch {
            // Send failed - update status to .failed
            print("❌ Error sending message: \(error.localizedDescription)")
            if let index = messages.firstIndex(where: { $0.sendStatus == .sending }) {
                messages[index].sendStatus = .failed
            }
        }
    }
    
    /// Send an image message with optimistic UI
    func sendImageMessage(_ image: UIImage) async {
        do {
            _ = try await messageService.sendImageMessage(
                chatID: chat.id,
                image: image,
                optimisticCompletion: { optimisticMessage in
                    self.messages.append(optimisticMessage)
                    self.updateLatestMessageIDs()
                }
            )
        } catch MessageError.offline {
            if let index = messages.firstIndex(where: { $0.sendStatus == .sending }) {
                messages[index].sendStatus = .queued
            }
            updateQueueCount()
        } catch {
            print("❌ Error sending image: \(error.localizedDescription)")
            if let index = messages.firstIndex(where: { $0.sendStatus == .sending }) {
                messages[index].sendStatus = .failed
            }
        }
    }
    
    /// Retry sending a failed message
    func retryMessage(_ message: Message) {
        // Check if this is an image message
        if message.mediaType == "image" {
            // Cannot retry image messages - original image data is lost
            print("⚠️ Cannot retry image message - please delete and resend the image")
            
            // Remove the failed message from the UI
            if let index = messages.firstIndex(where: { $0.id == message.id }) {
                messages.remove(at: index)
            }
            return
        }
        
        // Update failed message to sending status
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
            messages[index].sendStatus = .sending
        }
        
        // Retry send (text messages only)
        Task {
            do {
                _ = try await messageService.sendMessage(
                    chatID: chat.id,
                    text: message.text
                )
            } catch {
                // Failed again - update to failed status
                print("❌ Retry failed: \(error.localizedDescription)")
                if let index = messages.firstIndex(where: { $0.id == message.id }) {
                    messages[index].sendStatus = .failed
                }
            }
        }
    }
    
    /// Get sender name for a message (for group chats only)
    func getSenderName(for message: Message) -> String? {
        // Only show sender names in group chats
        guard chat.isGroupChat else { return nil }
        
        // Don't show sender name for current user's messages
        guard !message.isFromCurrentUser(currentUserID: currentUserID) else { return nil }
        
        // Check cache first
        if let cachedName = senderNames[message.senderID] {
            return cachedName
        }
        
        // If not cached, fetch asynchronously
        Task {
            await fetchSenderName(for: message.senderID)
        }
        
        // Return placeholder while fetching
        return "..."
    }
    
    /// Process queued messages when network reconnects
    func processQueuedMessages() async {
        // Get IDs of queued messages for this chat
        let queuedMessageIDs = MessageQueue.shared.getQueuedMessages(for: chat.id).map { $0.id }
        
        // Update their status from .queued to .sending
        for id in queuedMessageIDs {
            if let index = messages.firstIndex(where: { $0.id == id }) {
                messages[index].sendStatus = .sending
            }
        }
        
        // Process the queue (sends messages to Firestore)
        await MessageQueue.shared.processQueue()
        
        // Update queue count
        updateQueueCount()
    }
    
    // MARK: - Private Methods
    
    /// Start listening for real-time messages
    private func startListeningForMessages() {
        print("👂 [MESSAGE VM] Starting message listener for chat: \(chat.id)")
        
        // Attach Firestore snapshot listener
        messageListener = messageService.observeMessages(chatID: chat.id) { firestoreMessages in
            print("📨 [MESSAGE VM] Received \(firestoreMessages.count) messages from Firestore")
            
            // Log image messages specifically
            let imageMessages = firestoreMessages.filter { $0.mediaType == "image" }
            if !imageMessages.isEmpty {
                print("🖼️ [MESSAGE VM] Found \(imageMessages.count) image messages:")
                for message in imageMessages {
                    print("🖼️ [MESSAGE VM] Image message \(message.id):")
                    print("🔗 [MESSAGE VM]   Media URL: \(message.mediaURL ?? "nil")")
                    print("🔗 [MESSAGE VM]   Thumbnail URL: \(message.mediaThumbnailURL ?? "nil")")
                }
            }
            
            // Merge Firestore messages with optimistic messages
            // Strategy: Update existing messages, add new ones
            var updatedMessages = self.messages
            
            for firestoreMessage in firestoreMessages {
                if let index = updatedMessages.firstIndex(where: { $0.id == firestoreMessage.id }) {
                    // Message exists (was optimistic) - update it and remove status
                    var updated = firestoreMessage
                    updated.sendStatus = nil  // Confirmed, no status indicator needed
                    updatedMessages[index] = updated
                    print("🔄 [MESSAGE VM] Updated existing message: \(firestoreMessage.id)")
                } else {
                    // New message from Firestore - add it
                    updatedMessages.append(firestoreMessage)
                    print("➕ [MESSAGE VM] Added new message: \(firestoreMessage.id)")
                }
            }
            
            // Remove messages that no longer exist in Firestore
            // (Keep optimistic messages with status != nil for retry)
            updatedMessages = updatedMessages.filter { message in
                message.sendStatus != nil || firestoreMessages.contains(where: { $0.id == message.id })
            }
            
            // Sort by timestamp
            updatedMessages.sort { $0.timestamp < $1.timestamp }
            
            print("📨 [MESSAGE VM] Final message count: \(updatedMessages.count)")
            self.messages = updatedMessages
            
            // Update latest message IDs for each status type
            self.updateLatestMessageIDs()
        }
    }
    
    /// Stop listening for messages to prevent memory leaks
    private func stopListeningForMessages() {
        messageListener?.remove()
        messageListener = nil
    }
    
    /// Update queue count for this chat
    private func updateQueueCount() {
        queueCount = MessageQueue.shared.getQueueCount(for: chat.id)
    }
    
    /// Fetch sender name for a specific user ID and cache it
    private func fetchSenderName(for senderID: String) async {
        // Don't fetch if already cached
        guard senderNames[senderID] == nil else { return }
        
        do {
            let name = try await chatService.fetchUserName(userID: senderID)
            senderNames[senderID] = name
        } catch {
            print("⚠️ Failed to fetch sender name for \(senderID): \(error.localizedDescription)")
            senderNames[senderID] = "Unknown User"
        }
    }
    
    /// Prefetch sender names for all unique senders in the chat
    private func prefetchSenderNames() async {
        // Get unique sender IDs from messages
        let uniqueSenderIDs = Set(messages.map { $0.senderID })
        
        // Fetch names for senders not yet cached
        for senderID in uniqueSenderIDs {
            if senderNames[senderID] == nil {
                await fetchSenderName(for: senderID)
            }
        }
    }
    
    /// Updates the latest message IDs for each status type (PR #2 - Timeline View)
    private func updateLatestMessageIDs() {
        // Filter to current user's messages only
        let currentUserMessages = messages.filter { $0.isFromCurrentUser(currentUserID: currentUserID) }
        
        // Find latest READ message (has read receipts from other users)
        latestReadMessageID = currentUserMessages.last { message in
            !message.readBy.isEmpty
        }?.id
        
        // Find latest DELIVERED message (no read receipts yet, successfully delivered)
        latestDeliveredMessageID = currentUserMessages.last { message in
            message.readBy.isEmpty && (message.sendStatus == nil || message.sendStatus == .delivered)
        }?.id
        
        // Find latest FAILED message (send failed, needs retry)
        latestFailedMessageID = currentUserMessages.last { message in
            message.sendStatus == .failed
        }?.id
        
        // Debug logging
        print("📊 [MESSAGE VM Status Timeline]")
        print("   Latest Read: \(latestReadMessageID ?? "none")")
        print("   Latest Delivered: \(latestDeliveredMessageID ?? "none")")
        print("   Latest Failed: \(latestFailedMessageID ?? "none")")
    }
    
    /// Marks all unread messages in this chat as read by the current user
    private func markMessagesAsRead() {
        Task {
            do {
                // Validate current user ID
                guard !currentUserID.isEmpty else {
                    print("⚠️ Cannot mark messages as read: no current user ID")
                    return
                }
                
                try await messageService.markChatMessagesAsRead(chatID: chat.id)
            } catch {
                // Fail silently - read receipts are non-critical
                print("❌ Failed to mark messages as read: \(error.localizedDescription)")
            }
        }
    }
}
