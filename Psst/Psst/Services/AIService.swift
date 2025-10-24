//
//  AIService.swift
//  Psst
//
//  Created by AI Assistant on PR #002
//  iOS AI Infrastructure Foundation
//

import Foundation
import FirebaseAuth
import FirebaseFunctions

/// Handles communication with AI backend (Cloud Functions)
class AIService: ObservableObject {
    private let functions = Functions.functions()
    
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
    
    /// TEST METHOD: Calls real production chatWithAI function
    /// - Parameter message: User's message
    /// - Returns: Real AIResponse from backend
    func testRealChatWithAI(message: String) async throws -> AIResponse {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw AIError.notAuthenticated
        }
        
        let data: [String: Any] = [
            "userId": userId,
            "message": message
        ]
        
        let result = try await functions.httpsCallable("chatWithAI").call(data)
        
        guard let responseData = result.data as? [String: Any],
              let success = responseData["success"] as? Bool,
              success,
              let responseText = responseData["response"] as? String,
              let conversationId = responseData["conversationId"] as? String else {
            throw AIError.invalidResponse
        }
        
        let tokensUsed = responseData["tokensUsed"] as? Int ?? 0
        
        print("✅ AI Response received:")
        print("   Response: \(responseText)")
        print("   Conversation ID: \(conversationId)")
        print("   Tokens Used: \(tokensUsed)")
        
        return AIResponse(
            messageId: UUID().uuidString,
            text: responseText,
            timestamp: Date(),
            metadata: AIResponse.AIResponseMetadata(
                modelUsed: "gpt-4",
                tokensUsed: tokensUsed,
                responseTime: 0.0
            )
        )
    }
    
    /// Loads mock AI response for development (temporary)
    /// - Parameter message: User's message
    /// - Returns: Mock AIResponse
    func getMockResponse(for message: String) async -> AIResponse {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Use centralized mock response logic
        let responseText = MockAIData.mockResponse(for: message)
        
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

