//
//  AIResponse.swift
//  Psst
//
//  Created by AI Assistant on PR #002
//  iOS AI Infrastructure Foundation
//

import Foundation

/// Represents a response from the AI backend (future Cloud Function)
struct AIResponse: Codable, Equatable {
    let messageId: String
    let text: String
    let timestamp: Date
    let metadata: AIResponseMetadata?
    
    /// Metadata about the AI response
    struct AIResponseMetadata: Codable, Equatable {
        let modelUsed: String?
        let tokensUsed: Int?
        let responseTime: TimeInterval?
    }
    
    /// Initialize AIResponse
    /// - Parameters:
    ///   - messageId: Unique message identifier
    ///   - text: AI response text
    ///   - timestamp: Response timestamp (defaults to now)
    ///   - metadata: Optional response metadata
    init(
        messageId: String = UUID().uuidString,
        text: String,
        timestamp: Date = Date(),
        metadata: AIResponseMetadata? = nil
    ) {
        self.messageId = messageId
        self.text = text
        self.timestamp = timestamp
        self.metadata = metadata
    }
}

