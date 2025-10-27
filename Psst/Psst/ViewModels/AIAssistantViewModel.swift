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
import Combine

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

    // MARK: - Voice State (PR #011)

    @Published var isRecording: Bool = false
    @Published var isTranscribing: Bool = false
    @Published var voiceError: String? = nil
    @Published var currentlySpeakingMessageId: String? = nil // Phase 2: Track which message is playing

    // MARK: - Dependencies

    private let aiService: AIService
    private let calendarService: CalendarService
    private let contactService: ContactService
    private let voiceService: VoiceService = VoiceService()

    // Track backend conversation ID (nil until first message is sent)
    private var backendConversationId: String?

    // Combine cancellables for subscriptions
    private var cancellables = Set<AnyCancellable>()
    
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

        // Subscribe to voice service speaking state (Phase 2)
        voiceService.$isSpeaking
            .sink { [weak self] isSpeaking in
                if !isSpeaking {
                    // TTS finished - clear currently speaking message
                    self?.currentlySpeakingMessageId = nil
                }
            }
            .store(in: &cancellables)
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

                // Speak AI response if TTS is enabled (Phase 2)
                let settings = VoiceSettings.load()
                if settings.voiceResponseEnabled {
                    currentlySpeakingMessageId = aiMessage.id
                    voiceService.speak(text: response.text, voice: settings.ttsVoice)
                }

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
        // Check if this function needs parameter validation (has clientName but no specific ID)
        let needsValidation = shouldValidateParameters(functionName: name, parameters: parameters)

        if needsValidation {
            validateAndResolveParameters(functionName: name, parameters: parameters)
        } else {
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
        isExecutingAction = true

        Task {
            do {
                // Send parameters with timezone info - backend will handle conversion
                var parametersWithTimezone = parameters

                // Add user's timezone to the request
                let timezone = TimeZone.current.identifier
                parametersWithTimezone["timezone"] = timezone

                let result = try await aiService.executeFunctionCall(
                    functionName: functionName,
                    parameters: parametersWithTimezone,
                    conversationId: backendConversationId
                )

                isExecutingAction = false

                // Check if selection is required
                if checkForSelectionRequest(result) {
                    // Selection card will be shown by checkForSelectionRequest
                    return
                }

                // Check if conflict detected
                if checkForConflictDetected(result, originalParameters: parametersWithTimezone) {
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
        let action = PendingAction(
            functionName: functionName,
            parameters: parameters,
            timestamp: Date()
        )

        // Set pending action - this will trigger the confirmation UI
        pendingAction = action
    }

    /// Confirm and execute the pending action
    func confirmAction() {
        guard let action = pendingAction else {
            return
        }

        // Set executing state
        isExecutingAction = true
        errorMessage = nil
        lastActionResult = nil

        // Execute function
        Task {
            do {
                // Send parameters with timezone info - backend will handle conversion
                var parametersWithTimezone = action.parameters

                // Add user's timezone to the request
                let timezone = TimeZone.current.identifier
                parametersWithTimezone["timezone"] = timezone

                let result = try await aiService.executeFunctionCall(
                    functionName: action.functionName,
                    parameters: parametersWithTimezone,
                    conversationId: backendConversationId
                )

                // Update state on main thread
                isExecutingAction = false

                // Check if this is a selection request
                if checkForSelectionRequest(result) {
                    pendingAction = nil
                    return
                }

                // Check if this is a conflict detection
                if checkForConflictDetected(result, originalParameters: parametersWithTimezone) {
                    pendingAction = nil
                    return
                }

                lastActionResult = result
                pendingAction = nil

                // Auto-dismiss success and error messages after 5 seconds
                Task {
                    try? await Task.sleep(nanoseconds: 5_000_000_000)
                    if lastActionResult?.actionId == result.actionId {
                        lastActionResult = nil
                    }
                }

            } catch {
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
        guard let selection = pendingSelection else {
            return
        }

        guard let context = selection.context else {
            return
        }

        // Merge selection into original parameters
        var updatedParameters = context.originalParameters.mapValues { $0.value }

        switch selection.selectionType {
        case .contact:
            // For scheduleCall and setReminder, add userId
            if context.originalFunction == "scheduleCall" || context.originalFunction == "setReminder" {
                if let userId = option.metadata?["userId"]?.value as? String {
                    updatedParameters["clientId"] = userId
                }
            }

            // For sendMessage, add chatId
            if context.originalFunction == "sendMessage" {
                if let chatId = option.metadata?["chatId"]?.value as? String {
                    updatedParameters["chatId"] = chatId
                }
            }

            // Update clientName to exact selected name
            updatedParameters["clientName"] = option.title

        case .time:
            updatedParameters["dateTime"] = option.id

        case .action:
            // Re-route to different function
            break

        case .parameter, .generic:
            // Generic parameter update
            break
        }

        // Clear selection state
        pendingSelection = nil

        // Now show confirmation card with resolved parameters
        showConfirmation(functionName: context.originalFunction, parameters: updatedParameters)
    }

    /// Cancel the pending selection
    func cancelSelection() {
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

        // Parse selection request
        if let selectionRequest = AISelectionRequest.fromResponse(data) {
            pendingSelection = selectionRequest
            return true
        }

        return false
    }

    /// Check if error response contains a conflict detection
    /// - Parameters:
    ///   - result: Function execution result
    ///   - originalParameters: Original scheduling parameters
    /// - Returns: True if conflict was detected and handled
    private func checkForConflictDetected(_ result: FunctionExecutionResult, originalParameters: [String: Any]) -> Bool {
        // Check if error is CONFLICT_DETECTED
        guard !result.success,
              result.result == "CONFLICT_DETECTED",
              let data = result.data else {
            return false
        }

        // Parse conflict data
        guard let conflictingEventData = data["conflictingEvent"] as? [String: Any] else {
            return false
        }

        guard let suggestionsData = data["suggestions"] as? [String] else {
            return false
        }

        guard let originalRequest = data["originalRequest"] as? [String: Any] else {
            return false
        }

        // Parse conflicting event
        guard let eventId = conflictingEventData["id"] as? String,
              let eventTitle = conflictingEventData["title"] as? String,
              let startTimeString = conflictingEventData["startTime"] as? String,
              let endTimeString = conflictingEventData["endTime"] as? String else {
            return false
        }

        // Parse dates
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let startTime = isoFormatter.date(from: startTimeString),
              let endTime = isoFormatter.date(from: endTimeString) else {
            return false
        }

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
        let suggestedTimes = suggestionsData.compactMap { isoFormatter.date(from: $0) }
        guard suggestedTimes.count == suggestionsData.count else {
            return false
        }

        // Extract original request details
        guard let clientName = originalRequest["clientName"] as? String,
              let duration = originalRequest["duration"] as? Int,
              let eventTypeString = originalRequest["eventType"] as? String else {
            return false
        }

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

        // Set pending conflict resolution
        pendingConflictResolution = conflictResolution
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

    // MARK: - Voice Methods (PR #011 Phase 1)

    /// Toggle voice recording on/off
    func toggleVoiceRecording() {
        print("🔘 [ViewModel] Toggle voice recording (current state: isRecording=\(isRecording))")

        if isRecording {
            stopVoiceRecording()
        } else {
            startVoiceRecording()
        }
    }

    /// Start voice recording
    private func startVoiceRecording() {
        print("▶️ [ViewModel] Starting voice recording...")

        voiceError = nil

        Task {
            do {
                print("🔐 [ViewModel] Requesting microphone permission...")
                let hasPermission = await voiceService.requestMicrophonePermission()

                guard hasPermission else {
                    print("❌ [ViewModel] Microphone permission denied")
                    voiceError = "Microphone permission denied. Please enable it in Settings."
                    return
                }

                print("✅ [ViewModel] Microphone permission granted")

                _ = try await voiceService.startRecording()
                isRecording = true
                print("✅ [ViewModel] Recording started successfully")

            } catch {
                print("❌ [ViewModel] Failed to start recording: \(error.localizedDescription)")
                isRecording = false

                if let voiceError = error as? VoiceServiceError {
                    self.voiceError = voiceError.errorDescription
                } else {
                    self.voiceError = "Failed to start recording: \(error.localizedDescription)"
                }
            }
        }
    }

    /// Stop voice recording and transcribe
    private func stopVoiceRecording() {
        print("⏹️ [ViewModel] Stopping voice recording...")

        isRecording = false
        isTranscribing = true
        voiceError = nil

        Task {
            do {
                // Stop recording and get audio file URL
                let audioURL = try await voiceService.stopRecording()

                print("📝 [ViewModel] Transcribing audio...")

                // Transcribe the audio
                let transcription = try await voiceService.transcribe(audioURL: audioURL)

                isTranscribing = false

                print("✅ [ViewModel] Transcription received: \"\(transcription)\"")

                // Populate the input field with transcribed text
                currentInput = transcription

                print("✅ [ViewModel] Input field updated with transcription")

            } catch {
                print("❌ [ViewModel] Voice service error: \(error.localizedDescription)")
                isTranscribing = false

                if let voiceError = error as? VoiceServiceError {
                    self.voiceError = voiceError.errorDescription
                } else {
                    self.voiceError = "Voice operation failed: \(error.localizedDescription)"
                }
            }
        }
    }

    /// Cancel voice recording
    func cancelVoiceRecording() {
        print("🚫 [ViewModel] Cancelling voice recording...")
        voiceService.cancelRecording()
        isRecording = false
        isTranscribing = false
        voiceError = nil
    }

    /// Clear voice error
    func clearVoiceError() {
        voiceError = nil
    }

    // MARK: - Text-to-Speech Methods (PR #011 Phase 2)

    /// Toggle speaking for a specific message (play/stop)
    /// - Parameters:
    ///   - messageId: The message ID
    ///   - messageText: The message text to speak
    func toggleSpeakMessage(messageId: String, messageText: String) {
        // If this message is currently playing, stop it
        if currentlySpeakingMessageId == messageId && voiceService.isSpeaking {
            print("⏹️ [ViewModel] Stopping TTS for message: \(messageId)")
            voiceService.stopSpeaking()
            currentlySpeakingMessageId = nil
        } else {
            // Otherwise, play this message
            print("🔊 [ViewModel] Speaking message: \"\(messageText.prefix(50))...\"")
            currentlySpeakingMessageId = messageId
            let settings = VoiceSettings.load()
            voiceService.speak(text: messageText, voice: settings.ttsVoice)
        }
    }

    /// Stop current TTS playback
    func stopSpeaking() {
        print("⏹️ [ViewModel] Stopping TTS")
        voiceService.stopSpeaking()
        currentlySpeakingMessageId = nil
    }

    /// Check if TTS is currently playing
    var isSpeaking: Bool {
        return voiceService.isSpeaking
    }

    /// Check if a specific message is currently playing
    func isMessageSpeaking(_ messageId: String) -> Bool {
        return currentlySpeakingMessageId == messageId && voiceService.isSpeaking
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
