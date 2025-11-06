//
//  VoiceOnlyAssistantView.swift
//  Psst
//
//  Created by Caleb (AI Agent) on PR #018
//  Voice-First AI Coach Workflow
//

import SwiftUI

/// Voice-only AI Assistant interface - NO text, NO chat, ONLY voice
struct VoiceOnlyAssistantView: View {
    @StateObject private var viewModel = VoiceOnlyAssistantViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                mainContentView
                overlaysView
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Main Content

    private var mainContentView: some View {
        VStack(spacing: 0) {
            Spacer()

            // State-based content
            stateContentView

            Spacer()

            // Record button (only show in idle state)
            if viewModel.state == .idle {
                recordButton
                    .padding(.bottom, 60)
            }
        }
        .navigationTitle("AI Assistant")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done") {
                    viewModel.reset()
                    dismiss()
                }
            }
        }
    }

    // MARK: - State Content View

    @ViewBuilder
    private var stateContentView: some View {
        switch viewModel.state {
        case .idle:
            idleStateView

        case .recording:
            recordingStateView

        case .processing:
            processingStateView

        case .speaking:
            speakingStateView
        }
    }

    // MARK: - Idle State

    private var idleStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "mic.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(.blue)

            Text("Tap to speak")
                .font(.title2)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Recording State

    private var recordingStateView: some View {
        VStack(spacing: 32) {
            // Animated pulsing mic icon
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(.red)
                .symbolEffect(.pulse, options: .repeating)

            // Waveform visualization
            WaveformView(audioLevel: viewModel.voiceService.audioLevel)
                .frame(height: 60)
                .padding(.horizontal, 40)

            // Timer
            Text(formatDuration(viewModel.voiceService.recordingDuration))
                .font(.system(size: 48, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundColor(.primary)

            // Stop button
            stopButton
        }
    }

    // MARK: - Processing State

    private var processingStateView: some View {
        VStack(spacing: 32) {
            // Animated thinking dots (NO TEXT)
            HStack(spacing: 12) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 16, height: 16)
                        .scaleEffect(animationAmount(for: index))
                }
            }

            ProgressView()
                .scaleEffect(2.0)
        }
    }

    // MARK: - Speaking State

    private var speakingStateView: some View {
        VStack(spacing: 32) {
            // Animated sound waves
            Image(systemName: "speaker.wave.3.fill")
                .font(.system(size: 100))
                .foregroundColor(.blue)
                .symbolEffect(.pulse, options: .repeating)

            // Visual indicator
            HStack(spacing: 8) {
                ForEach(0..<5) { index in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue)
                        .frame(width: 4, height: animatedBarHeight(for: index))
                        .animation(
                            Animation
                                .easeInOut(duration: 0.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.1),
                            value: viewModel.voiceService.isSpeaking
                        )
                }
            }
            .frame(height: 40)
        }
    }

    // MARK: - Buttons

    private var recordButton: some View {
        Button(action: startRecording) {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 80, height: 80)
                    .shadow(radius: 8)

                Image(systemName: "mic.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
            }
        }
    }

    private var stopButton: some View {
        Button(action: stopRecording) {
            ZStack {
                Circle()
                    .fill(Color.red)
                    .frame(width: 80, height: 80)
                    .shadow(radius: 8)

                Image(systemName: "stop.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
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
        if let selection = viewModel.actionCoordinator.pendingSelection {
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
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.actionCoordinator.pendingSelection != nil)
        }
    }

    @ViewBuilder
    private var confirmationOverlay: some View {
        if let action = viewModel.actionCoordinator.pendingAction {
            VStack {
                Spacer()

                ActionConfirmationCard(
                    action: action,
                    isExecuting: viewModel.actionCoordinator.isExecutingAction,
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
            if let result = viewModel.actionCoordinator.lastActionResult {
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
        .animation(.spring(), value: viewModel.actionCoordinator.lastActionResult != nil)
    }

    // MARK: - Scheduling Overlays

    @ViewBuilder
    private var schedulingOverlays: some View {
        eventConfirmationOverlay
        conflictWarningOverlay
        prospectPromptOverlay
    }

    @ViewBuilder
    private var eventConfirmationOverlay: some View {
        if let pending = viewModel.actionCoordinator.pendingEventConfirmation {
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
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.actionCoordinator.pendingEventConfirmation != nil)
        }
    }

    @ViewBuilder
    private var conflictWarningOverlay: some View {
        if let pending = viewModel.actionCoordinator.pendingConflictResolution {
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
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.actionCoordinator.pendingConflictResolution != nil)
        }
    }

    @ViewBuilder
    private var prospectPromptOverlay: some View {
        if let pending = viewModel.actionCoordinator.pendingProspectCreation {
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
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.actionCoordinator.pendingProspectCreation != nil)
        }
    }

    // MARK: - Actions

    private func startRecording() {
        Task {
            await viewModel.startVoiceRecording()
        }
    }

    private func stopRecording() {
        Task {
            await viewModel.stopVoiceRecording()
        }
    }

    // MARK: - Helpers

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    @State private var animationPhase: CGFloat = 0.0

    private func animationAmount(for index: Int) -> CGFloat {
        return 1.0 + 0.5 * sin(animationPhase + Double(index) * 0.5)
    }

    private func animatedBarHeight(for index: Int) -> CGFloat {
        guard viewModel.voiceService.isSpeaking else { return 4 }
        return 8 + CGFloat.random(in: 0...32)
    }
}

// MARK: - Preview

struct VoiceOnlyAssistantView_Previews: PreviewProvider {
    static var previews: some View {
        VoiceOnlyAssistantView()
    }
}
