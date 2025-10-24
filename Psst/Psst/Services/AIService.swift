//
//  AIService.swift
//  Psst
//
//  Created by AI Assistant on PR #002
//  Enhanced in PR #003 - AI Chat Backend (real Cloud Function)
//  Enhanced in PR #004 - AI Chat UI
//

import Foundation
import FirebaseAuth
import FirebaseFunctions

/// Handles communication with AI backend (Cloud Functions)
class AIService: ObservableObject {
    private let functions = Functions.functions()
    private let timeout: TimeInterval = 30.0 // 30 second timeout for AI responses
    
    // Feature flag: Set to true when backend is ready (PR #003 deployed)
    private let useRealBackend = true // ✅ Backend deployed and tested!
    
    // Store conversation ID from backend (accessible to ViewModel)
    private(set) var conversationIdFromBackend: String?
    
    // MARK: - Public Methods
    
    /// Sends a message to the AI assistant via Cloud Function and returns the response
    /// - Parameters:
    ///   - message: The user's message text
    ///   - conversationId: Optional conversation ID for context tracking (nil for new conversations)
    /// - Returns: AIResponse with AI's reply
    /// - Throws: AIError if request fails
    func chatWithAI(message: String, conversationId: String?) async throws -> AIResponse {
        // Validate authentication
        guard Auth.auth().currentUser != nil else {
            throw AIError.notAuthenticated
        }
        
        // Validate message
        guard validateMessage(message) else {
            throw AIError.invalidMessage
        }
        
        // Use mock backend until useRealBackend flag is enabled
        if !useRealBackend {
            return await getMockResponse(for: message)
        }
        
        // Get current user ID
        guard let userId = Auth.auth().currentUser?.uid else {
            throw AIError.notAuthenticated
        }
        
        // Call Cloud Function
        let chatFunction = functions.httpsCallable("chatWithAI")
        
        // Build parameters (only include conversationId if it exists)
        var parameters: [String: Any] = [
            "userId": userId,
            "message": message
        ]
        
        if let conversationId = conversationId, !conversationId.isEmpty {
            parameters["conversationId"] = conversationId
        }
        
        do {
            let result = try await chatFunction.call(parameters)
            
            // Parse response
            guard let data = result.data as? [String: Any],
                  let success = data["success"] as? Bool,
                  success,
                  let responseMessage = data["response"] as? String,
                  let returnedConversationId = data["conversationId"] as? String else {
                throw AIError.invalidResponse
            }
            
            // Store the conversation ID for future use (temporary solution)
            // TODO: Return conversationId properly
            conversationIdFromBackend = returnedConversationId
            
            // Handle timestamp from backend (if provided, otherwise use Date())
            let timestamp: Date
            if let timestampValue = data["timestamp"] as? Double {
                timestamp = Date(timeIntervalSince1970: timestampValue / 1000) // Convert from milliseconds
            } else {
                timestamp = Date()
            }
            
            return AIResponse(
                messageId: UUID().uuidString,
                text: responseMessage,
                timestamp: timestamp,
                metadata: AIResponse.AIResponseMetadata(
                    modelUsed: "gpt-4",
                    tokensUsed: data["tokensUsed"] as? Int,
                    responseTime: nil
                )
            )
            
        } catch let error as NSError {
            // Map Firebase errors to AIError
            if error.domain == "com.firebase.functions" {
                switch error.code {
                case FunctionsErrorCode.unauthenticated.rawValue:
                    throw AIError.notAuthenticated
                case FunctionsErrorCode.resourceExhausted.rawValue:
                    throw AIError.rateLimitExceeded
                case FunctionsErrorCode.unavailable.rawValue:
                    throw AIError.serviceUnavailable
                case FunctionsErrorCode.deadlineExceeded.rawValue:
                    throw AIError.timeout
                default:
                    let errorMessage = error.localizedDescription
                    throw AIError.serverError(errorMessage)
                }
            }
            
            // Network connectivity errors
            if (error.domain == NSURLErrorDomain) {
                throw AIError.networkError
            }
            
            throw AIError.unknownError
        }
    }
    
    /// Validates user message before sending
    /// - Parameter message: User input text
    /// - Returns: true if valid, false if empty or too long
    func validateMessage(_ message: String) -> Bool {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= 2000
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
    
    /// Loads mock AI response for development (fallback when backend is disabled)
    /// - Parameter message: User's message
    /// - Returns: Mock AIResponse
    func getMockResponse(for message: String) async -> AIResponse {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        let responseText = "⚠️ AI Backend is currently disabled. Enable real backend to chat with AI."
        
        return AIResponse(
            messageId: UUID().uuidString,
            text: responseText,
            timestamp: Date(),
            metadata: AIResponse.AIResponseMetadata(
                modelUsed: "mock-fallback",
                tokensUsed: 0,
                responseTime: 1.5
            )
        )
    }
}

// MARK: - Error Handling

/// Errors that can occur when using AI services
enum AIError: LocalizedError {
    case notAuthenticated
    case invalidMessage
    case networkError
    case timeout
    case serverError(String)
    case unknownError
    case rateLimitExceeded
    case serviceUnavailable
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please log in to use AI assistant"
        case .invalidMessage:
            return "Message cannot be empty or longer than 2000 characters"
        case .networkError:
            return "No internet connection. Check your network and try again."
        case .timeout:
            return "Request took too long. Try asking in a different way."
        case .serverError(let message):
            return "AI Error: \(message)"
        case .unknownError:
            return "Something went wrong. Please try again."
        case .rateLimitExceeded:
            return "Too many requests. Please wait a moment."
        case .serviceUnavailable:
            return "AI assistant is temporarily unavailable. Try again in a moment."
        case .invalidResponse:
            return "Received invalid response from AI service"
        }
    }
}
