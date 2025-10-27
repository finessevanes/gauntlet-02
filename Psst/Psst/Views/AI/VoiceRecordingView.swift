//
//  VoiceRecordingView.swift
//  Psst
//
//  Created by Caleb (AI Agent) on 10/26/25.
//  PR #011 - Phase 3: Polished Recording UI
//

import SwiftUI

/// Full-screen voice recording interface with waveform and timer
struct VoiceRecordingView: View {
    @ObservedObject var voiceService: VoiceService
    @Binding var isPresented: Bool

    var onTranscriptionComplete: ((String) -> Void)?

    @State private var isRecording = false
    @State private var errorMessage: String?

    // MARK: - Constants

    private enum Layout {
        static let iconSize: CGFloat = 80
        static let buttonSize: CGFloat = 80
        static let innerIconSize: CGFloat = 32
        static let shadowRadius: CGFloat = 8
        static let progressScale: CGFloat = 1.5
    }

    private enum RecordingState {
        case idle
        case recording
        case transcribing

        var iconName: String {
            switch self {
            case .idle: return "mic.circle.fill"
            case .recording: return "waveform.circle.fill"
            case .transcribing: return ""
            }
        }

        var iconColor: Color {
            switch self {
            case .idle: return .gray
            case .recording: return .red
            case .transcribing: return .clear
            }
        }

        var statusText: String {
            switch self {
            case .idle: return "Tap to Record"
            case .recording: return "Recording..."
            case .transcribing: return "Transcribing..."
            }
        }
    }

    private var currentState: RecordingState {
        if isRecording {
            return .recording
        } else if voiceService.isRecording {
            return .transcribing
        } else {
            return .idle
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 32) {
                    Spacer()

                    // State indicator
                    stateView

                    // Waveform visualization
                    if isRecording {
                        WaveformView(audioLevel: voiceService.audioLevel)
                            .frame(height: 60)
                            .padding(.horizontal, 40)
                    }

                    // Timer
                    if isRecording {
                        Text(formatDuration(voiceService.recordingDuration))
                            .font(.system(size: 48, weight: .medium, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    // Record button
                    recordButton

                    Spacer()
                }
            }
            .navigationTitle("Voice Recording")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        cancelRecording()
                    }
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }

    // MARK: - Subviews

    private var stateView: some View {
        VStack(spacing: 12) {
            switch currentState {
            case .recording:
                Image(systemName: currentState.iconName)
                    .font(.system(size: Layout.iconSize))
                    .foregroundColor(currentState.iconColor)
                    .symbolEffect(.pulse, options: .repeating)

            case .transcribing:
                ProgressView()
                    .scaleEffect(Layout.progressScale)

            case .idle:
                Image(systemName: currentState.iconName)
                    .font(.system(size: Layout.iconSize))
                    .foregroundColor(currentState.iconColor)
            }

            Text(currentState.statusText)
                .font(.title3)
                .fontWeight(.medium)
                .padding(.top, currentState == .transcribing ? 8 : 0)
        }
    }

    private var recordButton: some View {
        Button(action: toggleRecording) {
            ZStack {
                Circle()
                    .fill(isRecording ? Color.red : Color.blue)
                    .frame(width: Layout.buttonSize, height: Layout.buttonSize)
                    .shadow(radius: Layout.shadowRadius)

                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: Layout.innerIconSize))
                    .foregroundColor(.white)
            }
        }
        .disabled(voiceService.isRecording && !isRecording) // Disable during transcription
    }

    // MARK: - Actions

    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        Task {
            do {
                _ = try await voiceService.startRecording()
                isRecording = true
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func stopRecording() {
        isRecording = false

        Task {
            do {
                let audioURL = try await voiceService.stopRecording()
                let transcription = try await voiceService.transcribe(audioURL: audioURL)

                // Call completion handler
                onTranscriptionComplete?(transcription)

                // Dismiss view
                isPresented = false

            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func cancelRecording() {
        if isRecording {
            voiceService.cancelRecording()
            isRecording = false
        }
        isPresented = false
    }

    // MARK: - Helpers

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    VoiceRecordingView(
        voiceService: VoiceService(),
        isPresented: .constant(true),
        onTranscriptionComplete: { text in
            print("Transcription: \(text)")
        }
    )
}
