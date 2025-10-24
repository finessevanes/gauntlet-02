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
    
    // MARK: - Public Methods
    
    /// Send user message and get AI response
    func sendMessage() {
        // Validate input
        let trimmedInput = currentInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else {
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
                if let index = conversation.messages.firstIndex(where: { $0.id == userMessage.id }) {
                    var updatedMessage = conversation.messages[index]
                    updatedMessage = AIMessage(
                        id: updatedMessage.id,
                        text: updatedMessage.text,
                        isFromUser: updatedMessage.isFromUser,
                        timestamp: updatedMessage.timestamp,
                        status: .delivered
                    )
                    conversation.messages[index] = updatedMessage
                }
                
                // Get AI response
                let response = try await aiService.sendMessage(
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
                if let index = conversation.messages.firstIndex(where: { $0.id == userMessage.id }) {
                    var updatedMessage = conversation.messages[index]
                    updatedMessage = AIMessage(
                        id: updatedMessage.id,
                        text: updatedMessage.text,
                        isFromUser: updatedMessage.isFromUser,
                        timestamp: updatedMessage.timestamp,
                        status: .failed
                    )
                    conversation.messages[index] = updatedMessage
                }
                
                // Set error message
                if let aiError = error as? AIError {
                    errorMessage = aiError.errorDescription
                } else {
                    errorMessage = "Failed to get AI response: \(error.localizedDescription)"
                }
            }
        }
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

