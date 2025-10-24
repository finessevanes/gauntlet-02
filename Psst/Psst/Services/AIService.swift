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
            
            throw AIError.unknownError(error.localizedDescription)
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
    
    // MARK: - Contextual Actions (PR #006)
    
    /// Generates a conversation summary for the given messages
    /// - Parameters:
    ///   - messages: Array of messages to summarize
    ///   - chatID: The chat ID for context
    /// - Returns: Summary text and key points
    /// - Throws: AIError if service fails
    func summarizeConversation(
        messages: [Message],
        chatID: String
    ) async throws -> (summary: String, keyPoints: [String]) {
        // For now, use mock service
        // TODO: When PR #005 merges, call real Cloud Function with RAG context
        return await MockAIService.mockSummarize(messages: messages)
    }
    
    /// Surfaces related context for a specific message
    /// - Parameters:
    ///   - message: The message to find context for
    ///   - chatID: The chat ID to search within
    ///   - limit: Maximum number of related messages (default: 5)
    /// - Returns: Array of related messages with relevance scores
    /// - Throws: AIError if service fails
    func surfaceContext(
        for message: Message,
        chatID: String,
        limit: Int = 5
    ) async throws -> [RelatedMessage] {
        // For now, use mock service
        // TODO: When PR #005 merges, call RAG pipeline for semantic similarity search
        return await MockAIService.mockSurfaceContext(for: message)
    }
    
    /// Creates a reminder suggestion from a message
    /// - Parameters:
    ///   - message: The message to extract reminder from
    ///   - senderName: Name of the message sender
    /// - Returns: Reminder suggestion with pre-filled text and date
    /// - Throws: AIError if service fails
    func createReminderSuggestion(
        from message: Message,
        senderName: String
    ) async throws -> ReminderSuggestion {
        // For now, use mock service
        // TODO: When PR #005 merges, use AI to extract action items and suggest optimal time
        return await MockAIService.mockReminder(from: message, senderName: senderName)
    }
}

// MARK: - Error Handling

/// Errors that can occur when using AI services
enum AIError: LocalizedError, Equatable {
    case notAuthenticated
    case invalidMessage
    case networkError
    case networkUnavailable  // PR #006: Contextual AI Actions
    case timeout
    case serviceTimeout      // PR #006: Contextual AI Actions
    case serverError(String)
    case unknownError(String) // PR #006: Updated to include message
    case rateLimitExceeded
    case serviceUnavailable
    case invalidResponse
    case invalidRequest      // PR #006: Contextual AI Actions
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please log in to use AI assistant"
        case .invalidMessage:
            return "Message cannot be empty or longer than 2000 characters"
        case .networkError:
            return "No internet connection. Check your network and try again."
        case .networkUnavailable:
            return "No internet connection. AI features require connectivity."
        case .timeout:
            return "Request took too long. Try asking in a different way."
        case .serviceTimeout:
            return "AI is taking too long. Try again in a moment."
        case .serverError(let message):
            return "AI Error: \(message)"
        case .unknownError(let message):
            return "AI error: \(message)"
        case .rateLimitExceeded:
            return "Too many requests. Please wait 30 seconds."
        case .serviceUnavailable:
            return "AI assistant is temporarily unavailable. Try again in a moment."
        case .invalidResponse:
            return "Received invalid response from AI service"
        case .invalidRequest:
            return "Couldn't process this message. Try a different one."
        }
    }
}
