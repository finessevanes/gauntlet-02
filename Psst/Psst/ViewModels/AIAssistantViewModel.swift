//
//  AIAssistantViewModel.swift
//  Psst
//
//  Created by AI Assistant on PR #002
//  iOS AI Infrastructure Foundation
//

import Foundation
import SwiftUI
import FirebaseAuth

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

    // MARK: - Scheduling State (PR #010B)

    @Published var pendingEventConfirmation: PendingEventConfirmation? = nil
    @Published var pendingConflictResolution: PendingConflictResolution? = nil
    @Published var pendingProspectCreation: PendingProspectCreation? = nil

    // MARK: - Dependencies

    private let aiService: AIService
    private let calendarService: CalendarService
    private let contactService: ContactService
    
    // Track backend conversation ID (nil until first message is sent)
    private var backendConversationId: String?
    
    // MARK: - Initialization
    
    /// Initialize AIAssistantViewModel
    /// - Parameter aiService: AI service instance (defaults to new instance)
    /// - Parameter calendarService: Calendar service instance (defaults to new instance)
    /// - Parameter contactService: Contact service instance (defaults to new instance)
    init(
        aiService: AIService = AIService(),
        calendarService: CalendarService = CalendarService.shared,
        contactService: ContactService = ContactService.shared
    ) {
        self.aiService = aiService
        self.calendarService = calendarService
        self.contactService = contactService
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
                // Send parameters with timezone info - backend will handle conversion
                var parametersWithTimezone = parameters

                // Add user's timezone to the request
                let timezone = TimeZone.current.identifier
                parametersWithTimezone["timezone"] = timezone
                print("🔍 [validateAndResolveParameters] Adding timezone: \(timezone)")

                if let dateTimeString = parameters["dateTime"] as? String {
                    print("🔍 [validateAndResolveParameters] DateTime (local): \(dateTimeString)")
                } else {
                    print("🔍 [validateAndResolveParameters] DateTime missing in original parameters")
                }
                if let dateTimeString = parametersWithTimezone["dateTime"] as? String {
                    print("🔍 [validateAndResolveParameters] DateTime being sent to backend: \(dateTimeString)")
                }
                if let timezoneString = parametersWithTimezone["timezone"] as? String {
                    print("🔍 [validateAndResolveParameters] Timezone being sent to backend: \(timezoneString)")
                }

                let result = try await aiService.executeFunctionCall(
                    functionName: functionName,
                    parameters: parametersWithTimezone,
                    conversationId: backendConversationId
                )

                isExecutingAction = false

                print("🔍 [validateAndResolveParameters] Result.success: \(result.success)")
                print("🔍 [validateAndResolveParameters] Result.result: \(result.result ?? "nil")")

                // Check if selection is required
                print("🔍 [validateAndResolveParameters] Checking for selection request...")
                if checkForSelectionRequest(result) {
                    print("🔍 [validateAndResolveParameters] Selection required, showing selection card")
                    // Selection card will be shown by checkForSelectionRequest
                    return
                }
                print("🔍 [validateAndResolveParameters] No selection request")

                // Check if conflict detected
                print("🔍 [validateAndResolveParameters] Checking for conflict detection...")
                if checkForConflictDetected(result, originalParameters: parametersWithTimezone) {
                    print("🔍 [validateAndResolveParameters] Conflict detected, showing alternatives")
                    return
                }
                print("🔍 [validateAndResolveParameters] No conflict detected")

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

                    // Auto-dismiss success message after 5 seconds
                    Task {
                        try? await Task.sleep(nanoseconds: 5_000_000_000)
                        if lastActionResult?.actionId == result.actionId {
                            lastActionResult = nil
                        }
                    }
                } else {
                    // Error occurred (not SELECTION_REQUIRED, which was handled above)
                    lastActionResult = result

                    // Auto-dismiss error message after 5 seconds
                    Task {
                        try? await Task.sleep(nanoseconds: 5_000_000_000)
                        if lastActionResult?.success == false {
                            lastActionResult = nil
                        }
                    }
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

                // Auto-dismiss error message after 5 seconds
                Task {
                    try? await Task.sleep(nanoseconds: 5_000_000_000)
                    if lastActionResult?.success == false {
                        lastActionResult = nil
                    }
                }
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
                // Send parameters with timezone info - backend will handle conversion
                var parametersWithTimezone = action.parameters

                // Add user's timezone to the request
                let timezone = TimeZone.current.identifier
                parametersWithTimezone["timezone"] = timezone
                print("🔵 [ViewModel.confirmAction] Adding timezone: \(timezone)")

                if let dateTimeString = action.parameters["dateTime"] as? String {
                    print("🔵 [ViewModel.confirmAction] DateTime (local): \(dateTimeString)")
                } else {
                    print("🔵 [ViewModel.confirmAction] DateTime missing on pending action")
                }
                if let dateTimeString = parametersWithTimezone["dateTime"] as? String {
                    print("🔵 [ViewModel.confirmAction] DateTime being sent to backend: \(dateTimeString)")
                }
                if let timezoneString = parametersWithTimezone["timezone"] as? String {
                    print("🔵 [ViewModel.confirmAction] Timezone being sent to backend: \(timezoneString)")
                }

                print("🔵 [ViewModel.confirmAction] Calling aiService.executeFunctionCall...")
                let result = try await aiService.executeFunctionCall(
                    functionName: action.functionName,
                    parameters: parametersWithTimezone,
                    conversationId: backendConversationId
                )

                print("✅ [ViewModel.confirmAction] executeFunctionCall returned")
                print("✅ [ViewModel.confirmAction] Result.success: \(result.success)")
                print("✅ [ViewModel.confirmAction] Result.result: \(result.result ?? "nil")")
                print("✅ [ViewModel.confirmAction] Result.data: \(result.data ?? [:])")

                // Update state on main thread
                isExecutingAction = false

                // Check if this is a selection request
                print("🔍 [ViewModel.confirmAction] Checking for selection request...")
                if checkForSelectionRequest(result) {
                    print("✅ [ViewModel.confirmAction] Selection request handled, clearing pending action")
                    pendingAction = nil
                    return
                }
                print("🔍 [ViewModel.confirmAction] No selection request detected")

                // Check if this is a conflict detection
                print("🔍 [ViewModel.confirmAction] Checking for conflict detection...")
                if checkForConflictDetected(result, originalParameters: parametersWithTimezone) {
                    print("✅ [ViewModel.confirmAction] Conflict detected, showing alternatives")
                    pendingAction = nil
                    return
                }
                print("🔍 [ViewModel.confirmAction] No conflict detected")

                lastActionResult = result
                pendingAction = nil
                print("✅ [ViewModel.confirmAction] State updated with result")

                // Auto-dismiss success and error messages after 5 seconds
                Task {
                    try? await Task.sleep(nanoseconds: 5_000_000_000)
                    if lastActionResult?.actionId == result.actionId {
                        lastActionResult = nil
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

                // Auto-dismiss error message after 5 seconds
                Task {
                    try? await Task.sleep(nanoseconds: 5_000_000_000)
                    if lastActionResult?.success == false {
                        lastActionResult = nil
                    }
                }
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

    /// Check if error response contains a conflict detection
    /// - Parameters:
    ///   - result: Function execution result
    ///   - originalParameters: Original scheduling parameters
    /// - Returns: True if conflict was detected and handled
    private func checkForConflictDetected(_ result: FunctionExecutionResult, originalParameters: [String: Any]) -> Bool {
        print("🟠 [checkForConflictDetected] ===== CALLED =====")
        print("🟠 [checkForConflictDetected] result.success: \(result.success)")
        print("🟠 [checkForConflictDetected] result.result: \(result.result ?? "nil")")
        print("🟠 [checkForConflictDetected] result.data exists: \(result.data != nil)")

        // Check if error is CONFLICT_DETECTED
        guard !result.success,
              result.result == "CONFLICT_DETECTED",
              let data = result.data else {
            print("🟠 [checkForConflictDetected] Not a conflict (early return)")
            return false
        }

        print("🟠 [checkForConflictDetected] ✅ CONFLICT_DETECTED confirmed!")
        print("🟠 [checkForConflictDetected] Data keys: \(data.keys.joined(separator: ", "))")
        print("🟠 [checkForConflictDetected] Full data: \(data)")

        // Parse conflict data
        print("🟠 [checkForConflictDetected] Parsing conflict data...")
        guard let conflictingEventData = data["conflictingEvent"] as? [String: Any] else {
            print("⚠️ [checkForConflictDetected] Failed to parse conflictingEvent")
            return false
        }
        print("🟠 [checkForConflictDetected] ✅ conflictingEvent parsed")

        guard let suggestionsData = data["suggestions"] as? [String] else {
            print("⚠️ [checkForConflictDetected] Failed to parse suggestions")
            return false
        }
        print("🟠 [checkForConflictDetected] ✅ suggestions parsed: \(suggestionsData.count) alternatives")

        guard let originalRequest = data["originalRequest"] as? [String: Any] else {
            print("⚠️ [checkForConflictDetected] Failed to parse originalRequest")
            return false
        }
        print("🟠 [checkForConflictDetected] ✅ originalRequest parsed")

        // Parse conflicting event
        print("🟠 [checkForConflictDetected] Parsing conflicting event details...")
        guard let eventId = conflictingEventData["id"] as? String,
              let eventTitle = conflictingEventData["title"] as? String,
              let startTimeString = conflictingEventData["startTime"] as? String,
              let endTimeString = conflictingEventData["endTime"] as? String else {
            print("⚠️ [checkForConflictDetected] Failed to parse conflicting event fields")
            print("⚠️ [checkForConflictDetected] id: \(conflictingEventData["id"] != nil)")
            print("⚠️ [checkForConflictDetected] title: \(conflictingEventData["title"] != nil)")
            print("⚠️ [checkForConflictDetected] startTime: \(conflictingEventData["startTime"] != nil)")
            print("⚠️ [checkForConflictDetected] endTime: \(conflictingEventData["endTime"] != nil)")
            return false
        }
        print("🟠 [checkForConflictDetected] ✅ Event details: \(eventTitle) (\(eventId))")

        // Parse dates
        print("🟠 [checkForConflictDetected] Parsing dates...")
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let startTime = isoFormatter.date(from: startTimeString),
              let endTime = isoFormatter.date(from: endTimeString) else {
            print("⚠️ [checkForConflictDetected] Failed to parse event dates")
            print("⚠️ [checkForConflictDetected] startTimeString: \(startTimeString)")
            print("⚠️ [checkForConflictDetected] endTimeString: \(endTimeString)")
            return false
        }
        print("🟠 [checkForConflictDetected] ✅ Dates parsed successfully")
        print("🟠 [checkForConflictDetected] ✅ startTime: \(startTime)")
        print("🟠 [checkForConflictDetected] ✅ endTime: \(endTime)")

        // Create CalendarEvent for the conflicting event
        let trainerId = Auth.auth().currentUser?.uid ?? ""
        let conflictingEvent = CalendarEvent(
            id: eventId,
            trainerId: trainerId,
            eventType: .adhoc, // Default to adhoc since we don't have the type from backend
            title: eventTitle,
            startTime: startTime,
            endTime: endTime
        )

        // Parse suggested times
        print("🟠 [checkForConflictDetected] Parsing suggested times...")
        let suggestedTimes = suggestionsData.compactMap { isoFormatter.date(from: $0) }
        guard suggestedTimes.count == suggestionsData.count else {
            print("⚠️ [checkForConflictDetected] Failed to parse all suggested times")
            print("⚠️ [checkForConflictDetected] Parsed: \(suggestedTimes.count) / \(suggestionsData.count)")
            for (idx, timeString) in suggestionsData.enumerated() {
                let parsed = isoFormatter.date(from: timeString)
                print("⚠️ [checkForConflictDetected]   [\(idx)]: \(timeString) -> \(parsed != nil ? "✅" : "❌")")
            }
            return false
        }
        print("🟠 [checkForConflictDetected] ✅ Parsed \(suggestedTimes.count) suggested times")
        for (idx, time) in suggestedTimes.enumerated() {
            print("🟠 [checkForConflictDetected]   [\(idx)]: \(time)")
        }

        // Extract original request details
        print("🟠 [checkForConflictDetected] Parsing original request details...")
        guard let clientName = originalRequest["clientName"] as? String,
              let duration = originalRequest["duration"] as? Int,
              let eventTypeString = originalRequest["eventType"] as? String else {
            print("⚠️ [checkForConflictDetected] Failed to parse original request")
            print("⚠️ [checkForConflictDetected] clientName: \(originalRequest["clientName"] != nil)")
            print("⚠️ [checkForConflictDetected] duration: \(originalRequest["duration"] != nil)")
            print("⚠️ [checkForConflictDetected] eventType: \(originalRequest["eventType"] != nil)")
            return false
        }
        print("🟠 [checkForConflictDetected] ✅ Original request: \(eventTypeString) with \(clientName) for \(duration)min")

        let eventType = CalendarEvent.EventType(rawValue: eventTypeString) ?? .adhoc
        let clientId = originalRequest["clientId"] as? String
        let prospectId = originalRequest["prospectId"] as? String
        let location = originalRequest["location"] as? String
        let notes = originalRequest["notes"] as? String

        // Construct title
        let title = "\(eventType.rawValue.capitalized) with \(clientName)"

        // Create PendingConflictResolution
        let conflictResolution = PendingConflictResolution(
            conflictingEvent: conflictingEvent,
            suggestedTimes: suggestedTimes,
            eventType: eventType,
            clientName: clientName,
            clientId: clientId,
            prospectId: prospectId,
            title: title,
            duration: duration,
            location: location,
            notes: notes
        )

        print("🟠 [checkForConflictDetected] ===== CREATING CONFLICT RESOLUTION =====")
        print("🟠 [checkForConflictDetected] Conflicting: \(conflictingEvent.title)")
        print("🟠 [checkForConflictDetected] Alternatives: \(suggestedTimes.count)")
        print("🟠 [checkForConflictDetected] Client: \(clientName)")
        print("🟠 [checkForConflictDetected] Event type: \(eventType)")
        print("🟠 [checkForConflictDetected] Duration: \(duration) min")

        // Set pending conflict resolution
        print("🟠 [checkForConflictDetected] Setting pendingConflictResolution...")
        print("🟠 [checkForConflictDetected] BEFORE - pendingConflictResolution is nil: \(pendingConflictResolution == nil)")
        pendingConflictResolution = conflictResolution
        print("🟠 [checkForConflictDetected] AFTER - pendingConflictResolution is nil: \(pendingConflictResolution == nil)")
        print("🟠 [checkForConflictDetected] ✅ SUCCESS - Returning true")
        print("🟠 [checkForConflictDetected] ===== DONE =====")
        return true
    }

    // MARK: - Scheduling Methods (PR #010B)

    /// Confirm and create the pending event
    func confirmEventCreation() {
        guard let pending = pendingEventConfirmation else { return }

        isExecutingAction = true

        Task {
            do {
                let trainerId = Auth.auth().currentUser?.uid ?? ""

                // Create the event
                let event = try await calendarService.createEvent(
                    trainerId: trainerId,
                    eventType: pending.eventType,
                    title: pending.title,
                    clientId: pending.clientId,
                    prospectId: pending.prospectId,
                    startTime: pending.startTime,
                    endTime: pending.endTime,
                    location: pending.location,
                    notes: pending.notes,
                    createdBy: "ai"
                )

                isExecutingAction = false
                pendingEventConfirmation = nil

                // Add success message
                let successMessage = AIMessage(
                    text: "✅ Scheduled \(pending.eventType.rawValue) with \(pending.clientName) for \(formatDateTime(pending.startTime))",
                    isFromUser: false,
                    timestamp: Date(),
                    status: .delivered
                )
                conversation.messages.append(successMessage)

            } catch {
                isExecutingAction = false
                errorMessage = "Failed to create event: \(error.localizedDescription)"
            }
        }
    }

    /// Cancel the pending event confirmation
    func cancelEventCreation() {
        pendingEventConfirmation = nil

        let aiMessage = AIMessage(
            text: "Okay, I've cancelled that event.",
            isFromUser: false,
            timestamp: Date(),
            status: .delivered
        )
        conversation.messages.append(aiMessage)
    }

    /// Select an alternative time for the conflicted event
    func selectAlternativeTime(_ date: Date) {
        guard let pending = pendingConflictResolution else { return }

        isExecutingAction = true

        Task {
            do {
                let trainerId = Auth.auth().currentUser?.uid ?? ""
                let endTime = date.addingTimeInterval(TimeInterval(pending.duration * 60))

                // Create the event at the alternative time
                let event = try await calendarService.createEvent(
                    trainerId: trainerId,
                    eventType: pending.eventType,
                    title: pending.title,
                    clientId: pending.clientId,
                    prospectId: pending.prospectId,
                    startTime: date,
                    endTime: endTime,
                    location: pending.location,
                    notes: pending.notes,
                    createdBy: "ai"
                )

                isExecutingAction = false
                pendingConflictResolution = nil

                // Add success message
                let successMessage = AIMessage(
                    text: "✅ Scheduled \(pending.eventType.rawValue) with \(pending.clientName) for \(formatDateTime(date))",
                    isFromUser: false,
                    timestamp: Date(),
                    status: .delivered
                )
                conversation.messages.append(successMessage)

            } catch {
                isExecutingAction = false
                errorMessage = "Failed to create event: \(error.localizedDescription)"
            }
        }
    }

    /// Cancel conflict resolution
    func cancelConflictResolution() {
        pendingConflictResolution = nil

        let aiMessage = AIMessage(
            text: "Okay, I've cancelled that scheduling request.",
            isFromUser: false,
            timestamp: Date(),
            status: .delivered
        )
        conversation.messages.append(aiMessage)
    }

    /// Confirm and create prospect, then create event
    func confirmProspectCreation() {
        guard let pending = pendingProspectCreation else { return }

        isExecutingAction = true

        Task {
            do {
                let trainerId = Auth.auth().currentUser?.uid ?? ""

                // Create prospect
                let prospect = try await contactService.addProspect(name: pending.clientName)

                // Create event linked to the new prospect
                let event = try await calendarService.createEvent(
                    trainerId: trainerId,
                    eventType: pending.eventType,
                    title: pending.title,
                    prospectId: prospect.id,
                    startTime: pending.startTime,
                    endTime: pending.endTime,
                    location: pending.location,
                    notes: pending.notes,
                    createdBy: "ai"
                )

                isExecutingAction = false
                pendingProspectCreation = nil

                // Add success message
                let successMessage = AIMessage(
                    text: "✅ Added \(pending.clientName) as a prospect and scheduled \(pending.eventType.rawValue) for \(formatDateTime(pending.startTime))",
                    isFromUser: false,
                    timestamp: Date(),
                    status: .delivered
                )
                conversation.messages.append(successMessage)

            } catch {
                isExecutingAction = false
                errorMessage = "Failed to create prospect and event: \(error.localizedDescription)"
            }
        }
    }

    /// Cancel prospect creation
    func cancelProspectCreation() {
        pendingProspectCreation = nil

        let aiMessage = AIMessage(
            text: "Okay, I've cancelled that request.",
            isFromUser: false,
            timestamp: Date(),
            status: .delivered
        )
        conversation.messages.append(aiMessage)
    }

    /// Helper to format date and time
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Pending State Models (PR #010B)

/// Pending event confirmation from AI scheduling
struct PendingEventConfirmation {
    let eventType: CalendarEvent.EventType
    let clientName: String
    let clientId: String?
    let prospectId: String?
    let title: String
    let startTime: Date
    let endTime: Date
    let duration: Int
    let location: String?
    let notes: String?
}

/// Pending conflict resolution with alternative times
struct PendingConflictResolution: Equatable {
    let conflictingEvent: CalendarEvent
    let suggestedTimes: [Date]
    let eventType: CalendarEvent.EventType
    let clientName: String
    let clientId: String?
    let prospectId: String?
    let title: String
    let duration: Int
    let location: String?
    let notes: String?

    static func == (lhs: PendingConflictResolution, rhs: PendingConflictResolution) -> Bool {
        return lhs.conflictingEvent.id == rhs.conflictingEvent.id &&
               lhs.suggestedTimes == rhs.suggestedTimes &&
               lhs.clientName == rhs.clientName &&
               lhs.duration == rhs.duration
    }
}

/// Pending prospect creation before event scheduling
struct PendingProspectCreation {
    let clientName: String
    let eventType: CalendarEvent.EventType
    let title: String
    let startTime: Date
    let endTime: Date
    let duration: Int
    let location: String?
    let notes: String?
}
