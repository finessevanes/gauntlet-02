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

    // MARK: - Voice State (PR #011)

    @Published var isRecording: Bool = false
    @Published var isTranscribing: Bool = false
    @Published var voiceError: String? = nil
    @Published var currentlySpeakingMessageId: String? = nil // Phase 2: Track which message is playing

    // MARK: - Dependencies

    private let aiService: AIService
    let voiceService: VoiceService = VoiceService() // Made internal for VoiceRecordingView access (Phase 3)
    let actionCoordinator: AIActionCoordinator // Shared coordinator for function calling and scheduling

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
        self.conversation = aiService.createConversation()
        self.actionCoordinator = AIActionCoordinator(
            aiService: aiService,
            calendarService: calendarService,
            contactService: contactService
        )

        // Set self as delegate after initialization
        self.actionCoordinator.delegate = self

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
                    // Update coordinator with conversation ID
                    actionCoordinator.setConversationId(backendConversationId)
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

                // PR #018: Auto-speak confirmations if enabled, otherwise respect voiceResponseEnabled setting
                let settings = VoiceSettings.load()
                let shouldAutoSpeak: Bool

                if settings.autoSpeakConfirmations && isConfirmationMessage(response.text) {
                    // Auto-speak confirmations regardless of voiceResponseEnabled
                    shouldAutoSpeak = true
                } else if settings.voiceResponseEnabled {
                    // Speak all responses if voiceResponseEnabled is true
                    shouldAutoSpeak = true
                } else {
                    shouldAutoSpeak = false
                }

                if shouldAutoSpeak {
                    currentlySpeakingMessageId = aiMessage.id
                    voiceService.speak(text: response.text, voice: settings.ttsVoice)
                }

                // Check if AI wants to call a function
                if let functionCall = response.functionCall {
                    actionCoordinator.handleFunctionCall(name: functionCall.name, parameters: functionCall.parameters)
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
        actionCoordinator.setConversationId(nil) // Reset coordinator conversation ID
        errorMessage = nil
        currentInput = ""
    }

    // MARK: - Delegated Methods (using ActionCoordinator)

    /// Confirm and execute the pending action (delegated to coordinator)
    func confirmAction() {
        actionCoordinator.confirmAction()
    }

    /// Cancel the pending action (delegated to coordinator)
    func cancelAction() {
        actionCoordinator.cancelAction()
    }

    /// Edit action parameters
    /// - Parameter newParameters: Updated parameters
    func editAction(newParameters: [String: Any]) {
        guard let action = actionCoordinator.pendingAction else { return }

        // Update pending action with new parameters
        actionCoordinator.pendingAction = PendingAction(
            functionName: action.functionName,
            parameters: newParameters,
            timestamp: Date()
        )
    }

    /// Dismiss the last action result (delegated to coordinator)
    func dismissActionResult() {
        actionCoordinator.dismissActionResult()
    }

    /// Handle user selection from multiple options (delegated to coordinator)
    func handleSelection(_ option: AISelectionRequest.SelectionOption) {
        actionCoordinator.handleSelection(option)
    }

    /// Cancel the pending selection (delegated to coordinator)
    func cancelSelection() {
        actionCoordinator.cancelSelection()
    }

    /// Confirm and create the pending event (delegated to coordinator)
    func confirmEventCreation() {
        actionCoordinator.confirmEventCreation()
    }

    /// Cancel the pending event confirmation (delegated to coordinator)
    func cancelEventCreation() {
        actionCoordinator.cancelEventCreation()
    }

    /// Select an alternative time for the conflicted event (delegated to coordinator)
    func selectAlternativeTime(_ date: Date) {
        actionCoordinator.selectAlternativeTime(date)
    }

    /// Cancel conflict resolution (delegated to coordinator)
    func cancelConflictResolution() {
        actionCoordinator.cancelConflictResolution()
    }

    /// Confirm and create prospect, then create event (delegated to coordinator)
    func confirmProspectCreation() {
        actionCoordinator.confirmProspectCreation()
    }

    /// Cancel prospect creation (delegated to coordinator)
    func cancelProspectCreation() {
        actionCoordinator.cancelProspectCreation()
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

    // MARK: - Helper Methods (PR #018)

    /// Check if AI response is an action confirmation
    /// - Parameter text: The message text to check
    /// - Returns: True if message contains confirmation keywords
    private func isConfirmationMessage(_ text: String) -> Bool {
        let confirmationKeywords = ["scheduled", "created", "removed", "updated", "confirmed", "added", "completed", "sent", "cancelled"]
        let lowercasedText = text.lowercased()
        return confirmationKeywords.contains { lowercasedText.contains($0) }
    }
}

// MARK: - AIActionCoordinatorDelegate Implementation

extension AIAssistantViewModel: AIActionCoordinatorDelegate {

    /// Handle message from coordinator
    func coordinator(_ coordinator: AIActionCoordinator, didReceiveMessage text: String) {
        let aiMessage = AIMessage(
            text: text,
            isFromUser: false,
            timestamp: Date(),
            status: .delivered
        )
        conversation.messages.append(aiMessage)

        // Auto-speak if voice response is enabled
        let settings = VoiceSettings.load()
        if settings.voiceResponseEnabled || (settings.autoSpeakConfirmations && isConfirmationMessage(text)) {
            currentlySpeakingMessageId = aiMessage.id
            voiceService.speak(text: text, voice: settings.ttsVoice)
        }
    }

    /// Handle error from coordinator
    func coordinator(_ coordinator: AIActionCoordinator, didEncounterError message: String) {
        errorMessage = message
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
