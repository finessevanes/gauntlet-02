//
//  AIConversation.swift
//  Psst
//
//  Created by AI Assistant on PR #002
//  iOS AI Infrastructure Foundation
//

import Foundation

/// Represents an AI chat session with message history
struct AIConversation: Identifiable, Codable, Equatable {
    let id: String
    var messages: [AIMessage]
    let createdAt: Date
    var updatedAt: Date
    
    /// Returns the last message in the conversation, if any
    var lastMessage: AIMessage? {
        messages.last
    }
    
    /// Initialize AIConversation
    /// - Parameters:
    ///   - id: Unique identifier (defaults to UUID)
    ///   - messages: Array of messages (defaults to empty)
    ///   - createdAt: Creation timestamp (defaults to now)
    ///   - updatedAt: Last update timestamp (defaults to now)
    init(
        id: String = UUID().uuidString,
        messages: [AIMessage] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

