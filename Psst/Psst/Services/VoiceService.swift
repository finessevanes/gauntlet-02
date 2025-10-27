//
//  VoiceService.swift
//  Psst
//
//  Created by Caleb (AI Agent) on 10/26/25.
//

import Foundation
import AVFoundation
import Combine

/// Service for handling voice recording, transcription, and text-to-speech
@MainActor
class VoiceService: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var currentRecording: VoiceRecording?
    @Published var audioLevel: Float = 0.0
    @Published var isSpeaking = false

    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    private var recordingStartTime: Date?

    // Text-to-Speech (Phase 2)
    private var speechSynthesizer: AVSpeechSynthesizer
    private var currentUtterance: AVSpeechUtterance?

    // OpenAI API configuration
    private let whisperAPIURL = "https://api.openai.com/v1/audio/transcriptions"

    // Minimum recording duration (1 second)
    private let minimumRecordingDuration: TimeInterval = 1.0

    override init() {
        self.speechSynthesizer = AVSpeechSynthesizer()
        super.init()
        self.speechSynthesizer.delegate = self
    }

    /// Get OpenAI API key from Config
    private var openAIAPIKey: String {
        return Config.shared.openAIApiKey
    }

    /// Validate API key is configured
    private func validateAPIKey() throws {
        let key = openAIAPIKey
        guard !key.isEmpty && key != "YOUR_OPENAI_API_KEY_HERE" else {
            throw VoiceServiceError.transcriptionFailed("OpenAI API key not configured. Please set it in Config.swift")
        }
    }

    // MARK: - Microphone Permission

    /// Request microphone permission from the user
    func requestMicrophonePermission() async -> Bool {
        print("🔐 [VoiceService] Requesting microphone permission...")

        let permissionStatus = AVAudioSession.sharedInstance().recordPermission

        switch permissionStatus {
        case .granted:
            print("✅ [VoiceService] Microphone permission granted")
            return true
        case .denied:
            print("❌ [VoiceService] Microphone permission denied")
            return false
        case .undetermined:
            return await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    print(granted ? "✅ [VoiceService] Microphone permission granted" : "❌ [VoiceService] Microphone permission denied")
                    continuation.resume(returning: granted)
                }
            }
        @unknown default:
            return false
        }
    }

    // MARK: - Audio Recording

    /// Start recording audio
    func startRecording() async throws -> VoiceRecording {
        print("🎤 [VoiceService] Starting recording...")

        // Check permission first
        let hasPermission = await requestMicrophonePermission()
        guard hasPermission else {
            throw VoiceServiceError.microphonePermissionDenied
        }

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try audioSession.setActive(true)
            print("✅ [VoiceService] Audio session configured")
        } catch {
            print("❌ [VoiceService] Audio session failed: \(error.localizedDescription)")
            throw VoiceServiceError.audioSessionFailed(error.localizedDescription)
        }

        // Create temporary file for recording
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "voice_recording_\(UUID().uuidString).m4a"
        let fileURL = tempDir.appendingPathComponent(fileName)
        recordingURL = fileURL

        // Configure audio recorder settings (AAC format, 16kHz for Whisper API)
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        // Create and start audio recorder
        do {
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()

            isRecording = true
            recordingStartTime = Date()

            // Create VoiceRecording object
            let recording = VoiceRecording(
                audioURL: fileURL,
                duration: 0,
                status: .recording
            )
            currentRecording = recording

            print("🎙️ [VoiceService] Recording started: \(isRecording)")
            return recording

        } catch {
            print("❌ [VoiceService] Recording failed: \(error.localizedDescription)")
            throw VoiceServiceError.recordingFailed(error.localizedDescription)
        }
    }

    /// Stop recording and return the audio file URL
    func stopRecording() async throws -> URL {
        print("⏹️ [VoiceService] Stopping recording...")

        guard let recorder = audioRecorder, recorder.isRecording else {
            throw VoiceServiceError.recordingFailed("No active recording")
        }

        recorder.stop()
        isRecording = false

        // Calculate duration
        let duration: TimeInterval
        if let startTime = recordingStartTime {
            duration = Date().timeIntervalSince(startTime)
            print("⏱️ [VoiceService] Calculated duration: \(String(format: "%.2f", duration)) seconds")
        } else {
            duration = 0
        }

        // Check minimum duration
        guard duration >= minimumRecordingDuration else {
            print("❌ [VoiceService] Recording too short: \(String(format: "%.2f", duration))s < \(minimumRecordingDuration)s minimum")
            // Clean up the file
            if let url = recordingURL {
                try? FileManager.default.removeItem(at: url)
            }
            throw VoiceServiceError.recordingTooShort(duration)
        }

        print("✅ [VoiceService] Recording duration valid: \(String(format: "%.2f", duration))s")

        guard let url = recordingURL else {
            throw VoiceServiceError.recordingFailed("Recording URL not found")
        }

        // Update current recording
        if var recording = currentRecording {
            recording.status = .transcribing
            currentRecording = recording
        }

        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false)

        return url
    }

    /// Cancel current recording and delete the file
    func cancelRecording() {
        print("🚫 [VoiceService] Cancelling recording...")

        audioRecorder?.stop()
        isRecording = false

        // Delete the temporary file
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }

        recordingURL = nil
        currentRecording = nil
        recordingStartTime = nil

        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false)
    }

    /// Get current audio level for waveform visualization (0.0 to 1.0)
    func getAudioLevel() -> Float {
        guard let recorder = audioRecorder, recorder.isRecording else {
            return 0.0
        }

        recorder.updateMeters()
        let avgPower = recorder.averagePower(forChannel: 0)

        // Convert from dB (-160 to 0) to linear (0 to 1)
        let normalizedLevel = pow(10, avgPower / 20)
        return min(max(normalizedLevel, 0.0), 1.0)
    }

    // MARK: - Speech-to-Text (Whisper API)

    /// Transcribe audio file using OpenAI Whisper API
    func transcribe(audioURL: URL, language: String = "en") async throws -> String {
        print("📝 [VoiceService] Starting transcription...")

        // Validate API key is configured
        try validateAPIKey()

        print("✅ [VoiceService] API key present (length: \(openAIAPIKey.count) chars)")

        // Read audio file data
        let audioData: Data
        do {
            audioData = try Data(contentsOf: audioURL)
        } catch {
            throw VoiceServiceError.transcriptionFailed("Failed to read audio file")
        }

        // Create multipart form data request
        var builder = MultipartFormDataBuilder()
        builder.addDataField(named: "file", data: audioData, mimeType: "audio/m4a", filename: "audio.m4a")
        builder.addTextField(named: "model", value: "whisper-1")
        builder.addTextField(named: "language", value: language)
        builder.addTextField(named: "response_format", value: "json")

        var request = URLRequest(url: URL(string: whisperAPIURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(openAIAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue(builder.contentType, forHTTPHeaderField: "Content-Type")
        request.httpBody = builder.finalize()

        // Send request
        print("🌐 [VoiceService] Sending request to Whisper API...")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw VoiceServiceError.transcriptionFailed("Invalid response")
        }

        print("📡 [VoiceService] HTTP Status: \(httpResponse.statusCode)")

        // Handle different status codes
        switch httpResponse.statusCode {
        case 200:
            // Success - parse JSON response
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let text = json?["text"] as? String else {
                throw VoiceServiceError.transcriptionFailed("No transcription in response")
            }

            print("📝 [VoiceService] Transcription: \"\(text)\"")

            // Update current recording
            if var recording = currentRecording {
                recording.transcription = text
                recording.status = .transcribed
                currentRecording = recording
            }

            // Clean up audio file
            try? FileManager.default.removeItem(at: audioURL)

            return text

        case 400:
            throw VoiceServiceError.transcriptionFailed("Invalid audio format")
        case 401:
            throw VoiceServiceError.transcriptionFailed("Authentication failed - check API key")
        case 413:
            throw VoiceServiceError.transcriptionFailed("File too large (max 25MB)")
        case 429:
            throw VoiceServiceError.transcriptionFailed("Rate limit exceeded - try again in a moment")
        case 500...599:
            throw VoiceServiceError.transcriptionFailed("Server error - try again later")
        default:
            throw VoiceServiceError.transcriptionFailed("Unexpected error (code \(httpResponse.statusCode))")
        }
    }

    // MARK: - Text-to-Speech (Phase 2)

    /// Speak text using AVSpeechSynthesizer
    /// - Parameters:
    ///   - text: Text to speak
    ///   - voice: Optional TTS voice (defaults to user preference)
    func speak(text: String, voice: VoiceSettings.TTSVoice? = nil) {
        print("🔊 [VoiceService] Starting TTS for text: \"\(text.prefix(50))...\"")

        // Stop any current speech
        if speechSynthesizer.isSpeaking {
            stopSpeaking()
        }

        // Create utterance
        let utterance = AVSpeechUtterance(string: text)

        // Load user settings
        let settings = VoiceSettings.load()

        // Configure voice
        let voiceIdentifier = voice?.rawValue ?? settings.ttsVoice.rawValue
        if let selectedVoice = AVSpeechSynthesisVoice(identifier: voiceIdentifier) {
            utterance.voice = selectedVoice
            print("✅ [VoiceService] Using TTS voice: \(voiceIdentifier)")
        } else {
            // Fallback to default English voice
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            print("⚠️ [VoiceService] Voice not found, using default en-US")
        }

        // Configure speech properties from user settings
        utterance.rate = settings.ttsRate
        utterance.pitchMultiplier = settings.ttsPitch
        utterance.volume = settings.ttsVolume

        currentUtterance = utterance
        isSpeaking = true

        // Speak
        speechSynthesizer.speak(utterance)
        print("🎤 [VoiceService] TTS started")
    }

    /// Stop current TTS playback
    func stopSpeaking() {
        guard speechSynthesizer.isSpeaking else { return }

        print("⏹️ [VoiceService] Stopping TTS")
        speechSynthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        currentUtterance = nil
    }

    /// Pause current TTS playback
    func pauseSpeaking() {
        guard speechSynthesizer.isSpeaking else { return }

        print("⏸️ [VoiceService] Pausing TTS")
        speechSynthesizer.pauseSpeaking(at: .word)
    }

    /// Resume paused TTS playback
    func continueSpeaking() {
        guard speechSynthesizer.isPaused else { return }

        print("▶️ [VoiceService] Resuming TTS")
        speechSynthesizer.continueSpeaking()
    }

    // MARK: - Private Helpers

    /// Update TTS state on main actor (helper for delegate callbacks)
    nonisolated private func updateTTSState(isSpeaking: Bool, clearUtterance: Bool = false) {
        Task { @MainActor in
            self.isSpeaking = isSpeaking
            if clearUtterance {
                self.currentUtterance = nil
            }
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate (Phase 2)

extension VoiceService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        print("🔊 [VoiceService] TTS playback started")
        updateTTSState(isSpeaking: true)
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print("✅ [VoiceService] TTS playback finished")
        updateTTSState(isSpeaking: false, clearUtterance: true)
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        print("🚫 [VoiceService] TTS playback cancelled")
        updateTTSState(isSpeaking: false, clearUtterance: true)
    }
}
