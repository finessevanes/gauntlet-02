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
            
            // Check if response includes a function call
            var functionCall: (name: String, parameters: [String: Any])?
            if let functionCallData = data["functionCall"] as? [String: Any],
               let functionName = functionCallData["name"] as? String,
               let parameters = functionCallData["parameters"] as? [String: Any] {
                functionCall = (functionName, parameters)
            }

            return AIResponse(
                messageId: UUID().uuidString,
                text: responseMessage,
                timestamp: timestamp,
                metadata: AIResponse.AIResponseMetadata(
                    modelUsed: "gpt-4",
                    tokensUsed: data["tokensUsed"] as? Int,
                    responseTime: nil
                ),
                functionCall: functionCall
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

    // MARK: - Function Calling (PR #008)

    /// Executes an AI function call after user confirmation
    /// - Parameters:
    ///   - functionName: Name of the function to execute
    ///   - parameters: Function parameters
    ///   - conversationId: Optional conversation context
    /// - Returns: Function execution result
    /// - Throws: AIError if execution fails
    func executeFunctionCall(
        functionName: String,
        parameters: [String: Any],
        conversationId: String? = nil
    ) async throws -> FunctionExecutionResult {
        print("📞 [AIService.executeFunctionCall] CALLED")
        print("📞 Function: \(functionName)")
        print("📞 Parameters: \(parameters)")
        print("📞 ConversationId: \(conversationId ?? "nil")")

        // Validate authentication
        let currentUser = Auth.auth().currentUser
        print("📞 Current user: \(currentUser?.uid ?? "NONE")")

        guard currentUser != nil else {
            print("❌ [AIService.executeFunctionCall] NOT AUTHENTICATED")
            throw AIError.notAuthenticated
        }

        print("✅ [AIService.executeFunctionCall] User authenticated")

        // Call executeFunctionCall Cloud Function
        let executeFunction = functions.httpsCallable("executeFunctionCall")
        print("📞 Created callable reference for 'executeFunctionCall'")

        var requestParams: [String: Any] = [
            "functionName": functionName,
            "parameters": parameters
        ]

        if let conversationId = conversationId {
            requestParams["conversationId"] = conversationId
        }

        print("📞 Request params: \(requestParams)")

        // Debug: Check parameter types
        if let params = requestParams["parameters"] as? [String: Any] {
            print("📞 Parameters breakdown:")
            for (key, value) in params {
                print("📞   - \(key): \(value) (type: \(type(of: value)))")
            }
        }

        print("📞 Calling Cloud Function...")

        do {
            let result = try await executeFunction.call(requestParams)
            print("✅ [AIService.executeFunctionCall] Cloud Function returned")
            print("📞 Raw result: \(result)")
            print("📞 Result data type: \(type(of: result.data))")

            // Parse response
            guard let data = result.data as? [String: Any] else {
                print("❌ [AIService.executeFunctionCall] Invalid response format")
                print("❌ Result.data: \(result.data)")
                throw AIError.invalidResponse
            }

            print("✅ [AIService.executeFunctionCall] Response parsed successfully")
            print("📞 Response data: \(data)")

            let executionResult = FunctionExecutionResult.fromResponse(data)
            print("✅ [AIService.executeFunctionCall] Execution result: success=\(executionResult.success)")

            return executionResult

        } catch let error as NSError {
            print("❌ [AIService.executeFunctionCall] ERROR CAUGHT")
            print("❌ Error domain: \(error.domain)")
            print("❌ Error code: \(error.code)")
            print("❌ Error description: \(error.localizedDescription)")
            print("❌ Error userInfo: \(error.userInfo)")

            // Map Firebase errors to AIError
            if error.domain == "com.firebase.functions" {
                print("❌ Firebase Functions error detected")
                switch error.code {
                case FunctionsErrorCode.unauthenticated.rawValue:
                    print("❌ Unauthenticated error (code: \(error.code))")
                    throw AIError.notAuthenticated
                case FunctionsErrorCode.permissionDenied.rawValue:
                    print("❌ Permission denied error (code: \(error.code))")
                    throw AIError.invalidRequest
                case FunctionsErrorCode.unavailable.rawValue:
                    print("❌ Service unavailable error (code: \(error.code))")
                    throw AIError.serviceUnavailable
                default:
                    let errorMessage = error.localizedDescription
                    print("❌ Unknown Firebase Functions error: \(errorMessage)")
                    throw AIError.serverError(errorMessage)
                }
            }

            if error.domain == NSURLErrorDomain {
                print("❌ Network error detected")
                throw AIError.networkError
            }

            print("❌ Unknown error type")
            throw AIError.unknownError(error.localizedDescription)
        }
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
        // Validate authentication
        guard Auth.auth().currentUser != nil else {
            throw AIError.notAuthenticated
        }

        // Format messages for summary prompt
        let messageCount = messages.count
        let messageTexts = messages.map { "- \($0.text)" }.joined(separator: "\n")

        // Create summarization prompt
        let prompt = """
        Please provide a concise summary of this conversation with \(messageCount) messages. Format your response as:

        SUMMARY: [One paragraph summary]

        KEY POINTS:
        - [Key point 1]
        - [Key point 2]
        - [Key point 3]

        Conversation messages:
        \(messageTexts)
        """

        // Call chatWithAI to generate summary
        let response = try await chatWithAI(message: prompt, conversationId: nil)

        // Parse response to extract summary and key points
        let responseText = response.text
        let (summary, keyPoints) = parseSummaryResponse(responseText)

        return (summary, keyPoints)
    }

    /// Parses AI response to extract summary and key points
    /// - Parameter response: The AI's formatted response
    /// - Returns: Tuple of (summary, key points array)
    private func parseSummaryResponse(_ response: String) -> (String, [String]) {
        var summary = ""
        var keyPoints: [String] = []

        let lines = response.components(separatedBy: .newlines)
        var inKeyPoints = false

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("SUMMARY:") {
                summary = trimmed.replacingOccurrences(of: "SUMMARY:", with: "").trimmingCharacters(in: .whitespaces)
            } else if !summary.isEmpty && !trimmed.isEmpty && !trimmed.hasPrefix("KEY POINTS:") && !trimmed.hasPrefix("-") {
                // Continue summary if it spans multiple lines
                summary += " " + trimmed
            } else if trimmed.hasPrefix("KEY POINTS:") {
                inKeyPoints = true
            } else if inKeyPoints && trimmed.hasPrefix("-") {
                let point = trimmed.replacingOccurrences(of: "- ", with: "").trimmingCharacters(in: .whitespaces)
                if !point.isEmpty {
                    keyPoints.append(point)
                }
            }
        }

        // Fallback if parsing fails
        if summary.isEmpty {
            summary = response
        }

        if keyPoints.isEmpty {
            keyPoints = ["Summary generated from conversation"]
        }

        return (summary, keyPoints)
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
        // Validate authentication
        guard let userId = Auth.auth().currentUser?.uid else {
            throw AIError.notAuthenticated
        }

        // Call semanticSearch Cloud Function
        let searchFunction = functions.httpsCallable("semanticSearch")

        let parameters: [String: Any] = [
            "query": message.text,
            "userId": userId,
            "limit": limit
        ]

        do {
            let result = try await searchFunction.call(parameters)

            // Parse response
            guard let data = result.data as? [String: Any],
                  let success = data["success"] as? Bool,
                  success,
                  let results = data["results"] as? [[String: Any]] else {
                throw AIError.invalidResponse
            }

            // Convert to RelatedMessage array
            let relatedMessages = results.compactMap { resultDict -> RelatedMessage? in
                guard let messageId = resultDict["messageId"] as? String,
                      let text = resultDict["text"] as? String,
                      let timestampMs = resultDict["timestamp"] as? Double,
                      let score = resultDict["score"] as? Double else {
                    return nil
                }

                let senderName = resultDict["senderName"] as? String ?? "Unknown"
                let timestamp = Date(timeIntervalSince1970: timestampMs / 1000)

                return RelatedMessage(
                    id: UUID().uuidString,
                    messageID: messageId,
                    text: text,
                    senderName: senderName,
                    timestamp: timestamp,
                    relevanceScore: score
                )
            }

            return relatedMessages

        } catch let error as NSError {
            // Map Firebase errors to AIError
            if error.domain == "com.firebase.functions" {
                switch error.code {
                case FunctionsErrorCode.unauthenticated.rawValue:
                    throw AIError.notAuthenticated
                case FunctionsErrorCode.deadlineExceeded.rawValue:
                    throw AIError.serviceTimeout
                case FunctionsErrorCode.unavailable.rawValue:
                    throw AIError.serviceUnavailable
                default:
                    throw AIError.serverError(error.localizedDescription)
                }
            }

            if error.domain == NSURLErrorDomain {
                throw AIError.networkUnavailable
            }

            throw AIError.unknownError(error.localizedDescription)
        }
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
        // Validate authentication
        guard Auth.auth().currentUser != nil else {
            throw AIError.notAuthenticated
        }

        // Create prompt for AI to extract action items
        let prompt = """
        Extract a reminder from this message from \(senderName):

        "\(message.text)"

        Provide your response in this exact format:

        REMINDER TEXT: [Brief reminder text about what to follow up on]
        TOPIC: [Main topic/category - one or two words]
        PRIORITY: [low/medium/high]

        Be concise and actionable.
        """

        // Call chatWithAI to extract reminder info
        let response = try await chatWithAI(message: prompt, conversationId: nil)

        // Parse response
        let (reminderText, extractedInfo) = parseReminderResponse(response.text, senderName: senderName, originalMessage: message.text)

        // Suggest tomorrow at 9 AM
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.day! += 1
        components.hour = 9
        components.minute = 0
        let suggestedDate = Calendar.current.date(from: components) ?? Date().addingTimeInterval(86400)

        return ReminderSuggestion(
            text: reminderText,
            suggestedDate: suggestedDate,
            extractedInfo: extractedInfo
        )
    }

    /// Parses AI response to extract reminder information
    /// - Parameters:
    ///   - response: The AI's formatted response
    ///   - senderName: Name of the message sender
    ///   - originalMessage: The original message text
    /// - Returns: Tuple of (reminder text, extracted info dictionary)
    private func parseReminderResponse(_ response: String, senderName: String, originalMessage: String) -> (String, [String: String]) {
        var reminderText = ""
        var topic = "Message follow-up"
        var priority = "medium"

        let lines = response.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("REMINDER TEXT:") {
                reminderText = trimmed.replacingOccurrences(of: "REMINDER TEXT:", with: "").trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("TOPIC:") {
                topic = trimmed.replacingOccurrences(of: "TOPIC:", with: "").trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("PRIORITY:") {
                priority = trimmed.replacingOccurrences(of: "PRIORITY:", with: "").trimmingCharacters(in: .whitespaces).lowercased()
            }
        }

        // Fallback if parsing fails
        if reminderText.isEmpty {
            let preview = String(originalMessage.prefix(50))
            reminderText = "Follow up with \(senderName) about: \(preview)\(originalMessage.count > 50 ? "..." : "")"
        }

        let extractedInfo: [String: String] = [
            "client": senderName,
            "topic": topic,
            "priority": priority
        ]

        return (reminderText, extractedInfo)
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
