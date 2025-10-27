//
//  VoiceServiceError.swift
//  Psst
//
//  Created by Caleb (AI Agent) on 10/26/25.
//

import Foundation

/// Errors that can occur during voice recording, transcription, and TTS operations
enum VoiceServiceError: Error, LocalizedError {
    case microphonePermissionDenied
    case recordingFailed(String)
    case recordingTooShort(TimeInterval)
    case transcriptionFailed(String)
    case ttsNotAvailable
    case audioSessionFailed(String)

    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return "Microphone permission denied. Please enable it in Settings."
        case .recordingFailed(let reason):
            return "Recording failed: \(reason)"
        case .recordingTooShort(let duration):
            return "Recording too short. Please speak for at least 1 second."
        case .transcriptionFailed(let reason):
            return "Couldn't transcribe audio. \(reason)"
        case .ttsNotAvailable:
            return "Text-to-speech unavailable on this device"
        case .audioSessionFailed(let reason):
            return "Audio setup failed: \(reason)"
        }
    }
}
