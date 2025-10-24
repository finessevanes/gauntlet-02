//
//  AIAssistantViewModel.swift
//  Psst
//
//  Created by AI Assistant on PR #002
//  iOS AI Infrastructure Foundation
//

import Foundation
import SwiftUI

/// Manages state and logic for AI Assistant chat interface
@MainActor
class AIAssistantViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var conversation: AIConversation
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var currentInput: String = ""
    
    // MARK: - Dependencies
    
    private let aiService: AIService
    
    // MARK: - Initialization
    
    /// Initialize AIAssistantViewModel
    /// - Parameter aiService: AI service instance (defaults to new instance)
    init(aiService: AIService = AIService()) {
        self.aiService = aiService
        self.conversation = aiService.createConversation()
    }
    
    // MARK: - Private Methods
    
    /// Updates the status of a message in the conversation
    /// - Parameters:
    ///   - messageId: ID of the message to update
    ///   - status: New status to set
    private func updateMessageStatus(_ messageId: String, to status: AIMessage.AIMessageStatus) {
        guard let index = conversation.messages.firstIndex(where: { $0.id == messageId }) else {
            return
        }
        
        let currentMessage = conversation.messages[index]
        conversation.messages[index] = AIMessage(
            id: currentMessage.id,
            text: currentMessage.text,
            isFromUser: currentMessage.isFromUser,
            timestamp: currentMessage.timestamp,
            status: status
        )
    }
    
    // MARK: - Public Methods
    
    /// Send user message and get AI response
    func sendMessage() {
        // Validate input
        let trimmedInput = currentInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else {
            errorMessage = "Message cannot be empty"
            return
        }
        
        // Validate message length
        guard aiService.validateMessage(trimmedInput) else {
            errorMessage = "Message is too long. Please keep it under 2000 characters."
            return
        }
        
        // Create and append user message
        let userMessage = AIMessage(
            text: trimmedInput,
            isFromUser: true,
            timestamp: Date(),
            status: .sending
        )
        
        conversation.messages.append(userMessage)
        
        // Clear input immediately for better UX
        let messageToSend = trimmedInput
        currentInput = ""
        
        // Set loading state
        isLoading = true
        errorMessage = nil
        
        // Send message asynchronously
        Task {
            do {
                // Update user message status to delivered
                updateMessageStatus(userMessage.id, to: .delivered)
                
                // Get AI response from Cloud Function
                let response = try await aiService.chatWithAI(
                    message: messageToSend,
                    conversationId: conversation.id
                )
                
                // Create AI message from response
                let aiMessage = AIMessage(
                    id: response.messageId,
                    text: response.text,
                    isFromUser: false,
                    timestamp: response.timestamp,
                    status: .delivered
                )
                
                // Append AI response
                conversation.messages.append(aiMessage)
                
                // Update conversation timestamp
                conversation.updatedAt = Date()
                
                // Clear loading state
                isLoading = false
                
            } catch {
                // Handle error
                isLoading = false
                
                // Update user message status to failed
                updateMessageStatus(userMessage.id, to: .failed)
                
                // Set error message
                if let aiError = error as? AIError {
                    errorMessage = aiError.errorDescription
                } else {
                    errorMessage = "Failed to get AI response: \(error.localizedDescription)"
                }
            }
        }
    }
    
    /// Retry last failed message
    func retry() {
        // Find the last user message that failed
        guard let failedMessage = conversation.messages.last(where: { $0.isFromUser && $0.status == .failed }) else {
            return
        }
        
        // Resend the message
        currentInput = failedMessage.text
        sendMessage()
    }
    
    /// Clear current error message
    func clearError() {
        errorMessage = nil
    }
    
    /// Load mock conversation for testing and development
    func loadMockConversation() {
        conversation = MockAIData.sampleConversation
    }
    
    /// Clear current conversation and start fresh
    func clearConversation() {
        conversation = aiService.createConversation()
        errorMessage = nil
        currentInput = ""
    }
}

