//
//  AIAssistantView.swift
//  Psst
//
//  Created by AI Assistant on PR #002
//  iOS AI Infrastructure Foundation
//

import SwiftUI

/// Main AI Assistant chat interface
struct AIAssistantView: View {
    @StateObject private var viewModel = AIAssistantViewModel()
    @FocusState private var isInputFocused: Bool
    @State private var showVoiceRecording = false // PR #011 Phase 3

    var body: some View {
        NavigationView {
            ZStack {
                mainContentView
                overlaysView
            }
        }
        .sheet(isPresented: $showVoiceRecording) {
            VoiceRecordingView(
                voiceService: viewModel.voiceService,
                isPresented: $showVoiceRecording,
                onTranscriptionComplete: { transcribedText in
                    viewModel.currentInput = transcribedText

                    // Auto-send if enabled in settings
                    if VoiceSettings.load().autoSendAfterTranscription {
                        viewModel.sendMessage()
                    }
                }
            )
        }
    }

    // MARK: - Main Content

    private var mainContentView: some View {
        mainContent
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(role: .destructive) {
                        viewModel.clearConversation()
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("Retry") {
                    viewModel.retry()
                }
                Button("Cancel", role: .cancel) {
                    viewModel.clearError()
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .alert("Voice Error", isPresented: .constant(viewModel.voiceError != nil)) {
                Button("OK") {
                    viewModel.clearVoiceError()
                }
            } message: {
                if let voiceError = viewModel.voiceError {
                    Text(voiceError)
                }
            }
            .modifier(StateChangeLogger(viewModel: viewModel))
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            messagesScrollView
            Divider()
            inputView
        }
    }

    private var messagesScrollView: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                if viewModel.conversation.messages.isEmpty {
                    emptyStateView
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.conversation.messages) { message in
                            AIMessageRow(
                                message: message,
                                onSpeakerTap: { messageId, messageText in
                                    // Phase 2: TTS toggle play/stop
                                    viewModel.toggleSpeakMessage(messageId: messageId, messageText: messageText)
                                },
                                isCurrentlyPlaying: viewModel.isMessageSpeaking(message.id)
                            )
                            .id(message.id)
                        }

                        if viewModel.isLoading {
                            AILoadingIndicator()
                                .id("loading")
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .onChange(of: viewModel.conversation.messages.count) { _ in
                if let lastMessage = viewModel.conversation.messages.last {
                    withAnimation {
                        scrollProxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: viewModel.isLoading) { isLoading in
                if isLoading {
                    withAnimation {
                        scrollProxy.scrollTo("loading", anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Overlays

    @ViewBuilder
    private var overlaysView: some View {
        selectionOverlay
        confirmationOverlay
        resultOverlay
        schedulingOverlays
    }

    @ViewBuilder
    private var selectionOverlay: some View {
        if let selection = viewModel.pendingSelection {
            VStack {
                Spacer()

                AISelectionCard(
                    request: selection,
                    onSelect: { option in
                        withAnimation {
                            viewModel.handleSelection(option)
                        }
                    },
                    onCancel: {
                        withAnimation {
                            viewModel.cancelSelection()
                        }
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.3))
            .edgesIgnoringSafeArea(.all)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.pendingSelection != nil)
        }
    }

    @ViewBuilder
    private var confirmationOverlay: some View {
        if let action = viewModel.pendingAction {
            VStack {
                Spacer()

                ActionConfirmationCard(
                    action: action,
                    isExecuting: viewModel.isExecutingAction,
                    onConfirm: {
                        viewModel.confirmAction()
                    },
                    onCancel: {
                        viewModel.cancelAction()
                    },
                    onEdit: {
                        // Edit functionality
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.3))
            .edgesIgnoringSafeArea(.all)
        }
    }

    @ViewBuilder
    private var resultOverlay: some View {
        VStack {
            if let result = viewModel.lastActionResult {
                if result.success {
                    ActionSuccessView(
                        result: result,
                        onDismiss: {
                            withAnimation {
                                viewModel.dismissActionResult()
                            }
                        }
                    )
                } else {
                    ActionErrorView(
                        result: result,
                        onDismiss: {
                            withAnimation {
                                viewModel.dismissActionResult()
                            }
                        },
                        onRetry: {
                            // Retry not implemented yet
                        }
                    )
                }
            }

            Spacer()
        }
        .padding(.top, 20)
        .animation(.spring(), value: viewModel.lastActionResult != nil)
    }

    // MARK: - Scheduling Overlays (PR #010B)

    @ViewBuilder
    private var schedulingOverlays: some View {
        eventConfirmationOverlay
        conflictWarningOverlay
        prospectPromptOverlay
    }

    @ViewBuilder
    private var eventConfirmationOverlay: some View {
        if let pending = viewModel.pendingEventConfirmation {
            VStack {
                Spacer()

                EventConfirmationCard(
                    eventType: pending.eventType,
                    clientName: pending.clientName,
                    startTime: pending.startTime,
                    duration: pending.duration,
                    location: pending.location,
                    notes: pending.notes,
                    onConfirm: {
                        withAnimation {
                            viewModel.confirmEventCreation()
                        }
                    },
                    onCancel: {
                        withAnimation {
                            viewModel.cancelEventCreation()
                        }
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.3))
            .edgesIgnoringSafeArea(.all)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.pendingEventConfirmation != nil)
        }
    }

    @ViewBuilder
    private var conflictWarningOverlay: some View {
        if let pending = viewModel.pendingConflictResolution {
            VStack {
                Spacer()

                ConflictWarningCard(
                    conflictingEvent: pending.conflictingEvent,
                    suggestedTimes: pending.suggestedTimes,
                    requestedDuration: pending.duration,
                    onSelectTime: { selectedDate in
                        withAnimation {
                            viewModel.selectAlternativeTime(selectedDate)
                        }
                    },
                    onCancel: {
                        withAnimation {
                            viewModel.cancelConflictResolution()
                        }
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.3))
            .edgesIgnoringSafeArea(.all)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.pendingConflictResolution != nil)
        }
    }

    @ViewBuilder
    private var prospectPromptOverlay: some View {
        if let pending = viewModel.pendingProspectCreation {
            VStack {
                Spacer()

                AddProspectPromptCard(
                    clientName: pending.clientName,
                    onAddProspect: {
                        withAnimation {
                            viewModel.confirmProspectCreation()
                        }
                    },
                    onCancel: {
                        withAnimation {
                            viewModel.cancelProspectCreation()
                        }
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.3))
            .edgesIgnoringSafeArea(.all)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.pendingProspectCreation != nil)
        }
    }

    // MARK: - Subviews

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("AI Assistant")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Ask me anything about your clients and conversations. I can help you search, summarize, and find information quickly.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            VStack(alignment: .leading, spacing: 8) {
                Text("Try asking:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)

                ForEach(["Show me recent messages from John", "Summarize my conversation with Sarah", "Find messages about the project"], id: \.self) { suggestion in
                    Button {
                        viewModel.currentInput = suggestion
                        viewModel.sendMessage()
                    } label: {
                        HStack {
                            Text(suggestion)
                                .font(.callout)
                            Spacer()
                            Image(systemName: "arrow.right.circle")
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                }
            }
        }
    }

    private var inputView: some View {
        HStack(spacing: 12) {
            // Voice Button (PR #011 Phase 3)
            VoiceButton(
                state: viewModel.isRecording ? VoiceButton.ButtonState.recording :
                       viewModel.isTranscribing ? VoiceButton.ButtonState.transcribing :
                       viewModel.voiceError != nil ? VoiceButton.ButtonState.error : VoiceButton.ButtonState.idle,
                action: {
                    showVoiceRecording = true
                }
            )

            TextField("Ask me anything...", text: $viewModel.currentInput)
                .textFieldStyle(.roundedBorder)
                .focused($isInputFocused)
                .disabled(viewModel.isLoading || viewModel.isRecording || viewModel.isTranscribing)
                .onSubmit {
                    viewModel.sendMessage()
                }

            Button {
                viewModel.sendMessage()
            } label: {
                Image(systemName: viewModel.isLoading ? "stop.circle.fill" : "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(viewModel.currentInput.isEmpty && !viewModel.isLoading ? .gray : .blue)
            }
            .disabled(viewModel.currentInput.isEmpty && !viewModel.isLoading)
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

// MARK: - View Modifiers

/// ViewModifier to log state changes for debugging
struct StateChangeLogger: ViewModifier {
    @ObservedObject var viewModel: AIAssistantViewModel

    func body(content: Content) -> some View {
        content
    }
}

// MARK: - Preview

struct AIAssistantView_Previews: PreviewProvider {
    static var previews: some View {
        AIAssistantView()
    }
}
