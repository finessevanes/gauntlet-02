//
//  QueuedMessage.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #10
//  Model for messages queued while offline
//

import Foundation

/// Persistent queue model for messages sent while offline
/// Stored in UserDefaults and synced when network reconnects
struct QueuedMessage: Identifiable, Codable, Equatable {
    /// Unique message identifier (same as Message.id for deduplication)
    let id: String
    
    /// ID of the chat this message belongs to
    let chatID: String
    
    /// Text content of the message
    let text: String
    
    /// Timestamp when the message was queued
    let timestamp: Date
    
    /// Number of retry attempts (max 3)
    var retryCount: Int
    
    /// Initialize QueuedMessage
    /// - Parameters:
    ///   - id: Unique message identifier
    ///   - chatID: Chat ID to send message to
    ///   - text: Message text content
    ///   - timestamp: When message was queued (default: now)
    ///   - retryCount: Number of retry attempts (default: 0)
    init(id: String, chatID: String, text: String,
         timestamp: Date = Date(), retryCount: Int = 0) {
        self.id = id
        self.chatID = chatID
        self.text = text
        self.timestamp = timestamp
        self.retryCount = retryCount
    }
    
    /// Convert QueuedMessage to Message for UI display
    /// - Parameter senderID: The ID of the user who sent the message
    /// - Returns: Message with .queued status for display
    func toMessage(senderID: String) -> Message {
        return Message(
            id: id,
            text: text,
            senderID: senderID,
            timestamp: timestamp,
            readBy: [],
            sendStatus: .queued
        )
    }
}

