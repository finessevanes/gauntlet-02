//
//  AIService.swift
//  Psst
//
//  Created by AI Assistant on PR #002
//  iOS AI Infrastructure Foundation
//

import Foundation
import FirebaseAuth

/// Handles communication with AI backend (Cloud Functions)
class AIService: ObservableObject {
    // TODO: Add FirebaseFunctions import in PR #003 when implementing real Cloud Function calls
    // private let functions = Functions.functions()
    
    // MARK: - Public Methods
    
    /// Sends a message to the AI assistant and returns the response
    /// - Parameters:
    ///   - message: The user's message text
    ///   - conversationId: Optional conversation ID for context
    /// - Returns: AIResponse with AI's reply
    /// - Throws: AIError if request fails
    func sendMessage(message: String, conversationId: String?) async throws -> AIResponse {
        // Validate authentication
        guard Auth.auth().currentUser != nil else {
            throw AIError.notAuthenticated
        }
        
        // Validate message not empty
        guard !message.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw AIError.invalidResponse
        }
        
        // TODO: Implement in PR #003 - AI Chat Backend
        // For now, use mock response
        return await getMockResponse(for: message)
    }
    
    /// Creates a new AI conversation
    /// - Returns: New AIConversation instance with unique ID
    func createConversation() -> AIConversation {
        return AIConversation(
            id: UUID().uuidString,
            messages: [],
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    /// Loads mock AI response for development (temporary)
    /// - Parameter message: User's message
    /// - Returns: Mock AIResponse
    func getMockResponse(for message: String) async -> AIResponse {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        let lowercasedMessage = message.lowercased()
        let responseText: String
        
        // Generate contextual mock responses
        if lowercasedMessage.contains("hello") || lowercasedMessage.contains("hi") {
            responseText = "Hi! I'm your AI assistant. How can I help you today?"
        } else if lowercasedMessage.contains("help") || lowercasedMessage.contains("what can you do") {
            responseText = "I can help you search past conversations, summarize chats, and answer questions about your clients. What would you like to know?"
        } else if lowercasedMessage.contains("client") || lowercasedMessage.contains("message") {
            responseText = "I can help you find messages from specific clients. Try asking 'Show me recent messages from [client name]' or 'Summarize my conversation with [client name]'."
        } else if lowercasedMessage.contains("search") {
            responseText = "I can search through all your conversations. What would you like to search for?"
        } else if lowercasedMessage.contains("summarize") {
            responseText = "I can summarize conversations to help you quickly catch up. Which conversation would you like me to summarize?"
        } else {
            responseText = "I understand you're asking about '\(message)'. Once the AI backend is ready, I'll be able to provide more detailed answers. For now, try asking about searching messages, summarizing conversations, or finding client information."
        }
        
        return AIResponse(
            messageId: UUID().uuidString,
            text: responseText,
            timestamp: Date(),
            metadata: AIResponse.AIResponseMetadata(
                modelUsed: "mock-model",
                tokensUsed: responseText.count,
                responseTime: 1.0
            )
        )
    }
}

// MARK: - Error Handling

/// Errors that can occur when using AI services
enum AIError: LocalizedError {
    case notAuthenticated
    case networkError(Error)
    case invalidResponse
    case rateLimitExceeded
    case serviceUnavailable
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be logged in to use AI features"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Received invalid response from AI service"
        case .rateLimitExceeded:
            return "Too many requests. Please wait a moment."
        case .serviceUnavailable:
            return "AI service is currently unavailable"
        }
    }
}

