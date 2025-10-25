//
//  AIResponse.swift
//  Psst
//
//  Created by AI Assistant on PR #002
//  iOS AI Infrastructure Foundation
//  Enhanced in PR #008 - AI Function Calling
//

import Foundation

/// Represents a response from the AI backend (future Cloud Function)
struct AIResponse: Equatable {
    let messageId: String
    let text: String
    let timestamp: Date
    let metadata: AIResponseMetadata?
    let functionCall: FunctionCallInfo?

    /// Metadata about the AI response
    struct AIResponseMetadata: Codable, Equatable {
        let modelUsed: String?
        let tokensUsed: Int?
        let responseTime: TimeInterval?
    }

    /// Function call information from AI
    struct FunctionCallInfo: Equatable {
        let name: String
        let parameters: [String: Any]

        static func == (lhs: FunctionCallInfo, rhs: FunctionCallInfo) -> Bool {
            lhs.name == rhs.name
        }
    }

    /// Initialize AIResponse
    /// - Parameters:
    ///   - messageId: Unique message identifier
    ///   - text: AI response text
    ///   - timestamp: Response timestamp (defaults to now)
    ///   - metadata: Optional response metadata
    ///   - functionCall: Optional function call information (name and parameters)
    init(
        messageId: String = UUID().uuidString,
        text: String,
        timestamp: Date = Date(),
        metadata: AIResponseMetadata? = nil,
        functionCall: (name: String, parameters: [String: Any])? = nil
    ) {
        self.messageId = messageId
        self.text = text
        self.timestamp = timestamp
        self.metadata = metadata

        if let functionCall = functionCall {
            self.functionCall = FunctionCallInfo(name: functionCall.name, parameters: functionCall.parameters)
        } else {
            self.functionCall = nil
        }
    }

    // Custom Equatable - ignore functionCall parameters for comparison
    static func == (lhs: AIResponse, rhs: AIResponse) -> Bool {
        lhs.messageId == rhs.messageId &&
        lhs.text == rhs.text &&
        lhs.timestamp == rhs.timestamp &&
        lhs.metadata == rhs.metadata &&
        lhs.functionCall?.name == rhs.functionCall?.name
    }
}

