//
//  Message.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #5
//  Message data model matching Firestore schema for individual messages
//

import Foundation
import FirebaseFirestore

/// Message model representing individual messages within a chat
/// Supports read receipts and sender identification
struct Message: Identifiable, Codable, Equatable {
    /// Unique message identifier
    let id: String
    
    /// Text content of the message (1-10,000 characters)
    let text: String
    
    /// User ID of the message sender
    let senderID: String
    
    /// Timestamp when the message was sent
    let timestamp: Date
    
    /// Array of user IDs who have read this message
    var readBy: [String]
    
    /// Initialize Message with default values
    /// - Parameters:
    ///   - id: Unique message identifier
    ///   - text: Message text content
    ///   - senderID: User ID of the sender
    ///   - timestamp: Message timestamp (default: now)
    ///   - readBy: Array of user IDs who read the message (default: empty)
    init(id: String, text: String, senderID: String,
         timestamp: Date = Date(), readBy: [String] = []) {
        self.id = id
        self.text = text
        self.senderID = senderID
        self.timestamp = timestamp
        self.readBy = readBy
    }
    
    /// Convert Message model to dictionary for Firestore writes
    /// Uses server timestamps for consistency across devices
    /// - Returns: Dictionary representation suitable for Firestore setData/updateData
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "text": text,
            "senderID": senderID,
            "timestamp": FieldValue.serverTimestamp(),
            "readBy": readBy
        ]
    }
    
    /// Check if a specific user has read this message
    /// - Parameter userID: The user ID to check
    /// - Returns: True if the user has read this message, false otherwise
    func isReadBy(userID: String) -> Bool {
        return readBy.contains(userID)
    }
    
    /// Check if this message was sent by the current user
    /// - Parameter currentUserID: The current user's ID
    /// - Returns: True if the current user sent this message, false otherwise
    func isFromCurrentUser(currentUserID: String) -> Bool {
        return senderID == currentUserID
    }
}
