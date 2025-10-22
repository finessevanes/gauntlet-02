//
//  TypingStatus.swift
//  Psst
//
//  Created by Caleb Agent on PR-13
//  Copyright © 2024 Psst. All rights reserved.
//

import Foundation

/// Model representing a user's typing status in a chat
struct TypingStatus: Identifiable, Codable {
    /// The user ID who is typing
    let id: String
    
    /// Whether the user is currently typing
    var isTyping: Bool
    
    /// Timestamp when the user started typing
    var timestamp: Date
    
    /// Timestamp when the typing status should expire (timestamp + 3 seconds)
    var expiresAt: Date
    
    /// Initialize a new typing status
    /// - Parameters:
    ///   - id: The user ID
    ///   - isTyping: Whether the user is typing (default: true)
    ///   - timestamp: When typing started (default: current time)
    ///   - expiresAt: When status expires (default: current time + 3 seconds)
    init(id: String, isTyping: Bool = true, timestamp: Date = Date(), expiresAt: Date = Date().addingTimeInterval(3)) {
        self.id = id
        self.isTyping = isTyping
        self.timestamp = timestamp
        self.expiresAt = expiresAt
    }
}

