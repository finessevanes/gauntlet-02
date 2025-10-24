//
//  AIService.swift
//  Psst
//
//  Created by AI Assistant on PR #002
//  Enhanced in PR #004 - AI Chat UI
//
//  📝 HOW TO ENABLE REAL CLOUD FUNCTIONS (when PR #003 backend is deployed):
//  1. Add FirebaseFunctions package to Xcode project (Package Dependencies)
//  2. Uncomment `import FirebaseFunctions` below
//  3. Uncomment `private let functions = Functions.functions()`
//  4. Set `useRealBackend = true`
//  5. Uncomment the Cloud Function code in chatWithAI() method
//  6. Remove the mock fallback at the bottom of chatWithAI()
//

import Foundation
import FirebaseAuth
// TODO: Uncomment when PR #003 backend is deployed and FirebaseFunctions package is added
// import FirebaseFunctions

/// Handles communication with AI backend (Cloud Functions)
class AIService: ObservableObject {
    // TODO: Uncomment when PR #003 backend is deployed
    // private let functions = Functions.functions()
    private let timeout: TimeInterval = 30.0 // 30 second timeout for AI responses
    
    // Feature flag: Set to true when backend is ready (PR #003 deployed)
    private let useRealBackend = false
    
    // MARK: - Public Methods
    
    /// Sends a message to the AI assistant via Cloud Function and returns the response
    /// - Parameters:
    ///   - message: The user's message text
    ///   - conversationId: Conversation ID for context tracking
    /// - Returns: AIResponse with AI's reply
    /// - Throws: AIError if request fails
    func chatWithAI(message: String, conversationId: String) async throws -> AIResponse {
        // Validate authentication
        guard Auth.auth().currentUser != nil else {
            throw AIError.notAuthenticated
        }
        
        // Validate message
        guard validateMessage(message) else {
            throw AIError.invalidMessage
        }
        
        // Use mock backend until PR #003 is deployed
        if !useRealBackend {
            return await getMockResponse(for: message)
        }
        
        // TODO: Uncomment when PR #003 backend is deployed and FirebaseFunctions package added
        /*
        // Call Cloud Function
        let chatFunction = functions.httpsCallable("chatWithAI")
        
        do {
            let result = try await chatFunction.call([
                "message": message,
                "conversationId": conversationId
            ])
            
            // Parse response
            guard let data = result.data as? [String: Any],
                  let responseMessage = data["message"] as? String,
                  let returnedConversationId = data["conversationId"] as? String else {
                throw AIError.invalidResponse
            }
            
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
                    modelUsed: data["modelUsed"] as? String,
                    tokensUsed: data["tokensUsed"] as? Int,
                    responseTime: data["responseTime"] as? TimeInterval
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
        */
        
        // Fallback to mock (should never reach here when useRealBackend is false)
        return await getMockResponse(for: message)
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
    
    /// Loads mock AI response for development (fallback)
    /// - Parameter message: User's message
    /// - Returns: Mock AIResponse
    func getMockResponse(for message: String) async -> AIResponse {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        // Use centralized mock response logic
        let responseText = MockAIData.mockResponse(for: message)
        
        return AIResponse(
            messageId: UUID().uuidString,
            text: responseText,
            timestamp: Date(),
            metadata: AIResponse.AIResponseMetadata(
                modelUsed: "mock-model",
                tokensUsed: responseText.count,
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

