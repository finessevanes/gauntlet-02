//
//  ContextualAIViewModel.swift
//  Psst
//
//  Created by Caleb (AI Agent) on PR #006
//  Manages state for contextual AI actions (long-press menu)
//

import Foundation
import SwiftUI

/// Manages contextual AI action state and coordinates with AIService
@MainActor
class ContextualAIViewModel: ObservableObject {
    @Published var activeAction: AIContextAction?
    @Published var isLoading: Bool = false
    @Published var currentResult: AIContextResult?
    @Published var error: AIError?
    
    private let aiService: AIService
    private let networkMonitor: NetworkMonitor
    
    // Store last action parameters for retry functionality
    private var lastMessage: Message?
    private var lastChatID: String?
    private var lastMessages: [Message] = []
    private var lastSenderName: String?
    
    init(aiService: AIService = AIService(), networkMonitor: NetworkMonitor = NetworkMonitor.shared) {
        self.aiService = aiService
        self.networkMonitor = networkMonitor
    }
    
    /// Performs a contextual AI action on a message
    /// - Parameters:
    ///   - action: The AI action to perform
    ///   - message: The source message
    ///   - chatID: The chat ID for context
    ///   - messages: All messages in the conversation (for summarize action)
    ///   - senderName: Name of the message sender (for reminder action)
    func performAction(
        _ action: AIContextAction,
        on message: Message,
        in chatID: String,
        messages: [Message] = [],
        senderName: String = ""
    ) async {
        // Store parameters for retry
        lastMessage = message
        lastChatID = chatID
        lastMessages = messages
        lastSenderName = senderName
        lastMessage = message
        
        activeAction = action
        isLoading = true
        error = nil
        
        // Check network connectivity before proceeding
        guard networkMonitor.isConnected else {
            error = .networkUnavailable
            isLoading = false
            return
        }
        
        do {
            let resultContent: AIResultContent
            
            switch action {
            case .summarize:
                let (summary, keyPoints) = try await aiService.summarizeConversation(
                    messages: messages.isEmpty ? [message] : messages,
                    chatID: chatID
                )
                resultContent = .summary(text: summary, keyPoints: keyPoints)
                
            case .surfaceContext:
                let relatedMessages = try await aiService.surfaceContext(
                    for: message,
                    chatID: chatID
                )
                resultContent = .relatedMessages(relatedMessages)
                
            case .setReminder:
                let suggestion = try await aiService.createReminderSuggestion(
                    from: message,
                    senderName: senderName.isEmpty ? "Client" : senderName
                )
                resultContent = .reminder(suggestion)
            }
            
            currentResult = AIContextResult(
                id: UUID().uuidString,
                action: action.rawValue,
                sourceMessageID: message.id,
                result: resultContent,
                timestamp: Date(),
                isLoading: false,
                error: nil
            )
            
            isLoading = false
            
        } catch let aiError as AIError {
            error = aiError
            isLoading = false
        } catch {
            self.error = .unknownError(error.localizedDescription)
            isLoading = false
        }
    }
    
    /// Dismisses the current result and clears state
    func dismissResult() {
        currentResult = nil
        activeAction = nil
        error = nil
    }
    
    /// Retries the last action that was performed
    func retryLastAction() async {
        guard let action = activeAction,
              let message = lastMessage,
              let chatID = lastChatID else {
            return
        }
        
        error = nil
        await performAction(
            action,
            on: message,
            in: chatID,
            messages: lastMessages,
            senderName: lastSenderName ?? ""
        )
    }
}

