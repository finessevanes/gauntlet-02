//
//  VoiceRecording.swift
//  Psst
//
//  Created by Caleb (AI Agent) on 10/26/25.
//

import Foundation

/// Represents a voice recording with its metadata and transcription status
struct VoiceRecording: Identifiable, Codable {
    let id: String
    let audioURL: URL
    let duration: TimeInterval
    let timestamp: Date
    var transcription: String?
    var status: RecordingStatus

    enum RecordingStatus: String, Codable {
        case recording
        case transcribing
        case transcribed
        case failed
    }

    init(id: String = UUID().uuidString,
         audioURL: URL,
         duration: TimeInterval,
         timestamp: Date = Date(),
         transcription: String? = nil,
         status: RecordingStatus = .recording) {
        self.id = id
        self.audioURL = audioURL
        self.duration = duration
        self.timestamp = timestamp
        self.transcription = transcription
        self.status = status
    }
}
