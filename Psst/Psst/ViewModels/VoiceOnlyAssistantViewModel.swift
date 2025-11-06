//
//  VoiceOnlyAssistantViewModel.swift
//  Psst
//
//  Created by Caleb (AI Agent) on PR #018
//  Voice-First AI Coach Workflow
//

import Foundation
import SwiftUI
import FirebaseAuth
import Combine

/// Voice interaction states
enum VoiceAssistantState {
    case idle           // Ready for input
    case recording      // User is speaking
    case processing     // Transcribing + AI thinking
    case speaking       // TTS playing response

    var displayText: String {
        switch self {
        case .idle: return ""
        case .recording: return "Listening..."
        case .processing: return ""  // No text, just animation
        case .speaking: return ""     // No text, just animation
        }
    }
}

/// Manages state and logic for voice-only AI Assistant interface
@MainActor
class VoiceOnlyAssistantViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var state: VoiceAssistantState = .idle
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let aiService: AIService
    let voiceService: VoiceService
    let actionCoordinator: AIActionCoordinator // Shared coordinator for function calling and scheduling

    // Track backend conversation ID (nil until first message is sent)
    private var backendConversationId: String?

    // Combine cancellables for subscriptions
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        aiService: AIService = AIService(),
        calendarService: CalendarService = CalendarService.shared,
        contactService: ContactService = ContactService.shared,
        voiceService: VoiceService? = nil
    ) {
        self.aiService = aiService
        self.voiceService = voiceService ?? VoiceService()
        self.actionCoordinator = AIActionCoordinator(
            aiService: aiService,
            calendarService: calendarService,
            contactService: contactService
        )

        // Set self as delegate after initialization
        self.actionCoordinator.delegate = self

        // Subscribe to voice service speaking state
        self.voiceService.$isSpeaking
            .sink { [weak self] isSpeaking in
                if !isSpeaking && self?.state == .speaking {
                    // TTS finished - return to idle
                    self?.state = .idle
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Voice Interaction Methods

    /// Start voice recording
    func startVoiceRecording() async {
        print("▶️ [VoiceOnlyVM] Starting voice recording...")

        errorMessage = nil

        do {
            print("🔐 [VoiceOnlyVM] Requesting microphone permission...")
            let hasPermission = await voiceService.requestMicrophonePermission()

            guard hasPermission else {
                print("❌ [VoiceOnlyVM] Microphone permission denied")
                errorMessage = "Microphone permission denied. Please enable it in Settings."
                return
            }

            print("✅ [VoiceOnlyVM] Microphone permission granted")

            _ = try await voiceService.startRecording()
            state = .recording
            print("✅ [VoiceOnlyVM] Recording started successfully")

        } catch {
            print("❌ [VoiceOnlyVM] Failed to start recording: \(error.localizedDescription)")
            state = .idle

            if let voiceError = error as? VoiceServiceError {
                errorMessage = voiceError.errorDescription
            } else {
                errorMessage = "Failed to start recording: \(error.localizedDescription)"
            }
        }
    }

    /// Stop voice recording and process
    func stopVoiceRecording() async {
        print("⏹️ [VoiceOnlyVM] Stopping voice recording...")

        state = .processing
        errorMessage = nil

        do {
            // Stop recording and get audio file URL
            let audioURL = try await voiceService.stopRecording()

            print("📝 [VoiceOnlyVM] Transcribing audio...")

            // Transcribe the audio
            let transcription = try await voiceService.transcribe(audioURL: audioURL)

            print("✅ [VoiceOnlyVM] Transcription received: \"\(transcription)\"")

            // Send to AI and get response
            await processUserMessage(transcription)

        } catch {
            print("❌ [VoiceOnlyVM] Voice service error: \(error.localizedDescription)")
            state = .idle

            if let voiceError = error as? VoiceServiceError {
                errorMessage = voiceError.errorDescription
            } else {
                errorMessage = "Voice operation failed: \(error.localizedDescription)"
            }
        }
    }

    /// Cancel voice recording
    func cancelVoiceRecording() {
        print("🚫 [VoiceOnlyVM] Cancelling voice recording...")
        voiceService.cancelRecording()
        state = .idle
        errorMessage = nil
    }

    /// Process user message (transcribed voice)
    private func processUserMessage(_ message: String) async {
        print("🤖 [VoiceOnlyVM] Processing user message: \"\(message)\"")

        // Validate message
        guard !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "No speech detected. Please try again."
            state = .idle
            return
        }

        guard aiService.validateMessage(message) else {
            errorMessage = "Message is too long. Please keep it under 2000 characters."
            state = .idle
            return
        }

        state = .processing

        do {
            // Get AI response from Cloud Function
            let response = try await aiService.chatWithAI(
                message: message,
                conversationId: backendConversationId
            )

            // Store the backend conversation ID for future messages
            if backendConversationId == nil {
                backendConversationId = aiService.conversationIdFromBackend
                actionCoordinator.setConversationId(backendConversationId)
            }

            print("✅ [VoiceOnlyVM] AI response received: \"\(response.text)\"")

            // Check if AI wants to call a function
            if let functionCall = response.functionCall {
                actionCoordinator.handleFunctionCall(name: functionCall.name, parameters: functionCall.parameters)
                // Stay in processing state until function is handled
            } else {
                // No function call - just speak the response
                await speakResponse(response.text)
            }

        } catch {
            print("❌ [VoiceOnlyVM] Failed to get AI response: \(error.localizedDescription)")
            state = .idle

            if let aiError = error as? AIError {
                errorMessage = aiError.errorDescription
            } else {
                errorMessage = "Failed to get AI response: \(error.localizedDescription)"
            }
        }
    }

    /// Speak AI response via TTS
    private func speakResponse(_ text: String) async {
        print("🔊 [VoiceOnlyVM] Speaking response: \"\(text.prefix(50))...\"")

        state = .speaking

        let settings = VoiceSettings.load()
        voiceService.speak(text: text, voice: settings.ttsVoice)

        // State will automatically return to .idle when TTS finishes (via Combine subscription)
    }

    /// Clear error message
    func clearError() {
        errorMessage = nil
    }

    /// Reset conversation and state
    func reset() {
        backendConversationId = nil
        actionCoordinator.setConversationId(nil)
        state = .idle
        errorMessage = nil
        voiceService.stopSpeaking()
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
}

// MARK: - AIActionCoordinatorDelegate Implementation

extension VoiceOnlyAssistantViewModel: AIActionCoordinatorDelegate {

    /// Handle message from coordinator
    func coordinator(_ coordinator: AIActionCoordinator, didReceiveMessage text: String) {
        Task {
            await speakResponse(text)
        }
    }

    /// Handle error from coordinator
    func coordinator(_ coordinator: AIActionCoordinator, didEncounterError message: String) {
        errorMessage = message
        Task {
            await speakResponse(message)
        }
    }
}
