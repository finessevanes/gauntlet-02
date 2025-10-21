//
//  Chat.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #5
//  Chat data model matching Firestore schema for conversations
//

import Foundation
import FirebaseFirestore

/// Chat model representing conversations between users
/// Supports both 1-on-1 and group chats with automatic detection
struct Chat: Identifiable, Codable, Equatable {
    /// Unique chat identifier
    let id: String
    
    /// Array of user IDs participating in this chat
    /// 2 members = 1-on-1 chat, 3+ members = group chat
    let members: [String]
    
    /// Text content of the most recent message in this chat
    var lastMessage: String
    
    /// Timestamp of the most recent message
    var lastMessageTimestamp: Date
    
    /// Whether this is a group chat (3+ members) or 1-on-1 chat (2 members)
    var isGroupChat: Bool
    
    /// Timestamp when this chat was created
    let createdAt: Date
    
    /// Timestamp when this chat was last updated
    var updatedAt: Date
    
    /// Initialize Chat with automatic group chat detection
    /// - Parameters:
    ///   - id: Unique chat identifier
    ///   - members: Array of user IDs (minimum 2)
    ///   - lastMessage: Text of most recent message (default: empty)
    ///   - lastMessageTimestamp: Timestamp of most recent message (default: now)
    ///   - isGroupChat: Override auto-detection (default: nil for auto-detection)
    ///   - createdAt: Chat creation timestamp (default: now)
    ///   - updatedAt: Last update timestamp (default: now)
    init(id: String, members: [String], lastMessage: String = "",
         lastMessageTimestamp: Date = Date(), isGroupChat: Bool? = nil,
         createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.members = members
        self.lastMessage = lastMessage
        self.lastMessageTimestamp = lastMessageTimestamp
        self.isGroupChat = isGroupChat ?? (members.count >= 3)
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    /// Convert Chat model to dictionary for Firestore writes
    /// Uses server timestamps for consistency across devices
    /// - Returns: Dictionary representation suitable for Firestore setData/updateData
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "members": members,
            "lastMessage": lastMessage,
            "lastMessageTimestamp": FieldValue.serverTimestamp(),
            "isGroupChat": isGroupChat,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
    }
    
    /// Get the other user's ID in a 1-on-1 chat
    /// - Parameter currentUserID: The current user's ID
    /// - Returns: The other user's ID, or nil if this is a group chat or invalid member count
    func otherUserID(currentUserID: String) -> String? {
        guard !isGroupChat, members.count == 2 else { return nil }
        return members.first { $0 != currentUserID }
    }
}
