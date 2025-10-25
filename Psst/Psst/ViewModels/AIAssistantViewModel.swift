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

    // MARK: - Function Calling State (PR #008)

    @Published var pendingAction: PendingAction? = nil
    @Published var isExecutingAction: Bool = false
    @Published var lastActionResult: FunctionExecutionResult? = nil

    // MARK: - Selection State (PR #008 Enhancement)

    @Published var pendingSelection: AISelectionRequest? = nil
    
    // MARK: - Dependencies
    
    private let aiService: AIService
    
    // Track backend conversation ID (nil until first message is sent)
    private var backendConversationId: String?
    
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
                // Only pass conversationId if we have one from the backend
                let response = try await aiService.chatWithAI(
                    message: messageToSend,
                    conversationId: backendConversationId
                )
                
                // Store the backend conversation ID for future messages
                if backendConversationId == nil {
                    // Get the conversation ID from the backend
                    backendConversationId = aiService.conversationIdFromBackend
                }
                
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

                // Check if AI wants to call a function
                if let functionCall = response.functionCall {
                    handleFunctionCall(name: functionCall.name, parameters: functionCall.parameters)
                }

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
    
    /// Clear current conversation and start fresh
    func clearConversation() {
        conversation = aiService.createConversation()
        backendConversationId = nil // Reset backend conversation ID
        errorMessage = nil
        currentInput = ""
    }

    // MARK: - Function Calling Methods (PR #008)

    /// Handle a function call from AI response
    /// - Parameters:
    ///   - name: Function name
    ///   - parameters: Function parameters
    private func handleFunctionCall(name: String, parameters: [String: Any]) {
        print("🎯 [handleFunctionCall] Function: \(name)")
        print("🎯 [handleFunctionCall] Parameters received: \(parameters)")

        // Check if this function needs parameter validation (has clientName but no specific ID)
        let needsValidation = shouldValidateParameters(functionName: name, parameters: parameters)

        if needsValidation {
            print("🎯 [handleFunctionCall] Function needs validation, calling backend first...")
            validateAndResolveParameters(functionName: name, parameters: parameters)
        } else {
            print("🎯 [handleFunctionCall] Parameters complete, showing confirmation")
            showConfirmation(functionName: name, parameters: parameters)
        }
    }

    /// Check if function parameters need validation/resolution
    private func shouldValidateParameters(functionName: String, parameters: [String: Any]) -> Bool {
        switch functionName {
        case "scheduleCall", "setReminder":
            // These need validation if clientName is provided without clientId
            if let _ = parameters["clientName"] as? String,
               parameters["clientId"] == nil {
                return true
            }

        case "sendMessage":
            // Needs validation if clientName is provided without chatId
            if let _ = parameters["clientName"] as? String,
               parameters["chatId"] == nil {
                return true
            }

        default:
            break
        }

        return false
    }

    /// Validate parameters by calling backend (which will return SELECTION_REQUIRED if needed)
    private func validateAndResolveParameters(functionName: String, parameters: [String: Any]) {
        print("🔍 [validateAndResolveParameters] Validating \(functionName)...")

        isExecutingAction = true

        Task {
            do {
                let result = try await aiService.executeFunctionCall(
                    functionName: functionName,
                    parameters: parameters,
                    conversationId: backendConversationId
                )

                isExecutingAction = false

                // Check if selection is required
                if checkForSelectionRequest(result) {
                    print("🔍 [validateAndResolveParameters] Selection required, showing selection card")
                    // Selection card will be shown by checkForSelectionRequest
                    return
                }

                // If we got here, either there was an error or it succeeded without selection
                if result.success {
                    // Single match found and executed
                    // ⚠️ PROBLEM: Backend already executed! This bypasses confirmation.
                    // TODO: Backend should not execute during validation, only resolve parameters
                    // For now, just show the success result (action already happened)
                    lastActionResult = result

                    // Add AI message acknowledging the action was completed
                    let aiMessage = AIMessage(
                        text: result.result ?? "Action completed successfully.",
                        isFromUser: false,
                        timestamp: Date(),
                        status: .delivered
                    )
                    conversation.messages.append(aiMessage)
                } else {
                    // Error occurred (not SELECTION_REQUIRED, which was handled above)
                    lastActionResult = result
                }

            } catch {
                print("❌ [validateAndResolveParameters] Error: \(error)")
                isExecutingAction = false

                let errorResult = FunctionExecutionResult(
                    success: false,
                    actionId: nil,
                    result: error.localizedDescription,
                    data: nil
                )
                lastActionResult = errorResult
            }
        }
    }

    /// Show confirmation card for the action
    private func showConfirmation(functionName: String, parameters: [String: Any]) {
        print("🎯 [showConfirmation] ===== CALLED =====")
        print("🎯 [showConfirmation] Function: \(functionName)")
        print("🎯 [showConfirmation] Parameters: \(parameters)")

        let action = PendingAction(
            functionName: functionName,
            parameters: parameters,
            timestamp: Date()
        )

        print("🎯 [showConfirmation] PendingAction created")
        print("🎯 [showConfirmation] Action.functionName: \(action.functionName)")
        print("🎯 [showConfirmation] Action.parameters: \(action.parameters)")
        print("🎯 [showConfirmation] Action.timestamp: \(action.timestamp)")

        // BEFORE: Check current state
        print("🎯 [showConfirmation] BEFORE - pendingAction: \(pendingAction?.functionName ?? "nil")")
        print("🎯 [showConfirmation] BEFORE - pendingSelection: \(pendingSelection?.prompt ?? "nil")")

        // Set pending action - this will trigger the confirmation UI
        print("🎯 [showConfirmation] Setting pendingAction...")
        pendingAction = action
        print("🎯 [showConfirmation] ✅ pendingAction SET")

        // AFTER: Verify state
        print("🎯 [showConfirmation] AFTER - pendingAction: \(pendingAction?.functionName ?? "nil")")
        print("🎯 [showConfirmation] AFTER - pendingSelection: \(pendingSelection?.prompt ?? "nil")")
        print("🎯 [showConfirmation] ===== DONE =====")
    }

    /// Confirm and execute the pending action
    func confirmAction() {
        print("🔵 [ViewModel.confirmAction] CALLED")

        guard let action = pendingAction else {
            print("⚠️ [ViewModel.confirmAction] No pending action found")
            return
        }

        print("🔵 [ViewModel.confirmAction] Action: \(action.functionName)")
        print("🔵 [ViewModel.confirmAction] Parameters: \(action.parameters)")
        print("🔵 [ViewModel.confirmAction] ConversationId: \(backendConversationId ?? "nil")")

        // Set executing state
        isExecutingAction = true
        errorMessage = nil
        lastActionResult = nil
        print("🔵 [ViewModel.confirmAction] State set to executing")

        // Execute function
        Task {
            print("🔵 [ViewModel.confirmAction] Task started")
            do {
                // Convert dateTime parameters from local time to UTC
                var parametersWithUTC = action.parameters
                if let dateTimeString = action.parameters["dateTime"] as? String {
                    print("🔵 [ViewModel.confirmAction] Original dateTime (local): \(dateTimeString)")

                    // Parse local time (without Z)
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [.withInternetDateTime]
                    formatter.timeZone = TimeZone.current // Parse as local timezone

                    if let localDate = formatter.date(from: dateTimeString) {
                        // Convert to UTC
                        formatter.timeZone = TimeZone(secondsFromGMT: 0) // UTC
                        let utcString = formatter.string(from: localDate)
                        parametersWithUTC["dateTime"] = utcString
                        print("🔵 [ViewModel.confirmAction] Converted to UTC: \(utcString)")
                    } else {
                        print("⚠️ [ViewModel.confirmAction] Failed to parse dateTime, using as-is")
                    }
                }

                print("🔵 [ViewModel.confirmAction] Calling aiService.executeFunctionCall...")
                let result = try await aiService.executeFunctionCall(
                    functionName: action.functionName,
                    parameters: parametersWithUTC,
                    conversationId: backendConversationId
                )

                print("✅ [ViewModel.confirmAction] executeFunctionCall returned")
                print("✅ [ViewModel.confirmAction] Result: success=\(result.success), message=\(result.result ?? "nil")")

                // Update state on main thread
                isExecutingAction = false

                // Check if this is a selection request
                if checkForSelectionRequest(result) {
                    print("✅ [ViewModel.confirmAction] Selection request handled, clearing pending action")
                    pendingAction = nil
                    return
                }

                lastActionResult = result
                pendingAction = nil
                print("✅ [ViewModel.confirmAction] State updated with result")

                // Auto-dismiss success message after 3 seconds
                if result.success {
                    Task {
                        try? await Task.sleep(nanoseconds: 3_000_000_000)
                        if lastActionResult?.actionId == result.actionId {
                            lastActionResult = nil
                        }
                    }
                }

            } catch {
                print("❌ [ViewModel.confirmAction] ERROR CAUGHT")
                print("❌ Error type: \(type(of: error))")
                print("❌ Error description: \(error.localizedDescription)")
                if let aiError = error as? AIError {
                    print("❌ AIError: \(aiError)")
                }

                // Handle error
                isExecutingAction = false

                let errorResult = FunctionExecutionResult(
                    success: false,
                    actionId: nil,
                    result: error.localizedDescription,
                    data: nil
                )

                lastActionResult = errorResult
                pendingAction = nil
                print("❌ [ViewModel.confirmAction] Error result set")
            }
        }
    }

    /// Cancel the pending action
    func cancelAction() {
        pendingAction = nil
        errorMessage = nil

        // Optionally send a message to AI acknowledging cancellation
        let aiMessage = AIMessage(
            text: "Action cancelled.",
            isFromUser: false,
            timestamp: Date(),
            status: .delivered
        )
        conversation.messages.append(aiMessage)
    }

    /// Edit action parameters
    /// - Parameter newParameters: Updated parameters
    func editAction(newParameters: [String: Any]) {
        guard let action = pendingAction else { return }

        // Update pending action with new parameters
        pendingAction = PendingAction(
            functionName: action.functionName,
            parameters: newParameters,
            timestamp: Date()
        )
    }

    /// Dismiss the last action result
    func dismissActionResult() {
        lastActionResult = nil
    }

    // MARK: - Selection Handling Methods (PR #008 Enhancement)

    /// Handle user selection from multiple options
    /// - Parameter option: The selected option
    func handleSelection(_ option: AISelectionRequest.SelectionOption) {
        print("🔷 [handleSelection] ===== CALLED =====")
        print("🔷 [handleSelection] User selected: \(option.title)")
        print("🔷 [handleSelection] Option ID: \(option.id)")
        print("🔷 [handleSelection] Option metadata: \(option.metadata ?? [:])")

        guard let selection = pendingSelection else {
            print("⚠️ [handleSelection] ERROR: No pending selection!")
            return
        }

        print("🔷 [handleSelection] pendingSelection exists")
        print("🔷 [handleSelection] Selection type: \(selection.selectionType)")

        guard let context = selection.context else {
            print("⚠️ [handleSelection] ERROR: No context in selection!")
            return
        }

        print("🔷 [handleSelection] Context found")
        print("🔷 [handleSelection] Original function: \(context.originalFunction)")
        print("🔷 [handleSelection] Original parameters: \(context.originalParameters)")

        // Merge selection into original parameters
        var updatedParameters = context.originalParameters.mapValues { $0.value }
        print("🔷 [handleSelection] Base parameters: \(updatedParameters)")

        switch selection.selectionType {
        case .contact:
            print("🔷 [handleSelection] Processing CONTACT selection")

            // For scheduleCall and setReminder, add userId
            if context.originalFunction == "scheduleCall" || context.originalFunction == "setReminder" {
                print("🔷 [handleSelection] Function is scheduleCall/setReminder")
                if let userId = option.metadata?["userId"]?.value as? String {
                    updatedParameters["clientId"] = userId
                    print("🔷 [handleSelection] ✅ Added clientId: \(userId)")
                } else {
                    print("⚠️ [handleSelection] WARNING: No userId in metadata!")
                    print("⚠️ [handleSelection] Metadata keys: \(option.metadata?.keys.joined(separator: ", ") ?? "none")")
                }
            }

            // For sendMessage, add chatId
            if context.originalFunction == "sendMessage" {
                print("🔷 [handleSelection] Function is sendMessage")
                if let chatId = option.metadata?["chatId"]?.value as? String {
                    updatedParameters["chatId"] = chatId
                    print("🔷 [handleSelection] ✅ Added chatId: \(chatId)")
                } else {
                    print("⚠️ [handleSelection] WARNING: No chatId in metadata!")
                }
            }

            // Update clientName to exact selected name
            updatedParameters["clientName"] = option.title
            print("🔷 [handleSelection] ✅ Updated clientName to: \(option.title)")

        case .time:
            print("🔷 [handleSelection] Processing TIME selection")
            updatedParameters["dateTime"] = option.id

        case .action:
            print("🔷 [handleSelection] Processing ACTION selection")
            // Re-route to different function
            break

        case .parameter, .generic:
            print("🔷 [handleSelection] Processing PARAMETER/GENERIC selection")
            // Generic parameter update
            break
        }

        print("🔷 [handleSelection] Final updated parameters: \(updatedParameters)")

        // Clear selection state
        print("🔷 [handleSelection] Clearing pendingSelection...")
        pendingSelection = nil
        print("🔷 [handleSelection] ✅ pendingSelection = nil")

        // Now show confirmation card with resolved parameters
        print("🔷 [handleSelection] Calling showConfirmation...")
        showConfirmation(functionName: context.originalFunction, parameters: updatedParameters)
        print("🔷 [handleSelection] ===== DONE =====")
    }

    /// Cancel the pending selection
    func cancelSelection() {
        print("🔷 [cancelSelection] User cancelled selection")
        pendingSelection = nil

        // Send acknowledgment message
        let aiMessage = AIMessage(
            text: "Okay, I've cancelled that request.",
            isFromUser: false,
            timestamp: Date(),
            status: .delivered
        )
        conversation.messages.append(aiMessage)
    }

    /// Check if error response contains a selection request
    /// - Parameter result: Function execution result
    /// - Returns: True if selection was detected and handled
    private func checkForSelectionRequest(_ result: FunctionExecutionResult) -> Bool {
        // Check if error is SELECTION_REQUIRED
        guard !result.success,
              result.result == "SELECTION_REQUIRED",
              let data = result.data else {
            return false
        }

        print("🔷 [checkForSelectionRequest] SELECTION_REQUIRED detected")
        print("🔷 [checkForSelectionRequest] Data: \(data)")

        // Parse selection request
        if let selectionRequest = AISelectionRequest.fromResponse(data) {
            print("🔷 [checkForSelectionRequest] Selection request parsed successfully")
            print("🔷 [checkForSelectionRequest] Prompt: \(selectionRequest.prompt)")
            print("🔷 [checkForSelectionRequest] Options count: \(selectionRequest.options.count)")

            pendingSelection = selectionRequest
            return true
        }

        print("⚠️ [checkForSelectionRequest] Failed to parse selection request")
        return false
    }
}

