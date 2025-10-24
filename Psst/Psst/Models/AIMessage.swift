//
//  AIMessage.swift
//  Psst
//
//  Created by AI Assistant on PR #002
//  iOS AI Infrastructure Foundation
//

import Foundation

/// Represents a single message in an AI conversation (user or AI)
struct AIMessage: Identifiable, Codable, Equatable {
    let id: String
    let text: String
    let isFromUser: Bool
    let timestamp: Date
    let status: AIMessageStatus
    
    /// Status of AI message delivery
    enum AIMessageStatus: String, Codable {
        case sending
        case delivered
        case failed
    }
    
    /// Initialize AIMessage with validation
    /// - Parameters:
    ///   - id: Unique identifier (defaults to UUID)
    ///   - text: Message text content (cannot be empty)
    ///   - isFromUser: Whether message is from user or AI
    ///   - timestamp: Message timestamp (defaults to now)
    ///   - status: Delivery status (defaults to .delivered)
    init(
        id: String = UUID().uuidString,
        text: String,
        isFromUser: Bool,
        timestamp: Date = Date(),
        status: AIMessageStatus = .delivered
    ) {
        self.id = id
        self.text = text
        self.isFromUser = isFromUser
        self.timestamp = timestamp
        self.status = status
    }
}

