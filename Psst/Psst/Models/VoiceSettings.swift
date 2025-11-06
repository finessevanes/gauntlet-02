//
//  VoiceSettings.swift
//  Psst
//
//  Created by Caleb (AI Agent) on 10/26/25.
//  PR #011 - Phase 2: Text-to-Speech
//

import Foundation

/// User preferences for voice features (recording, TTS)
struct VoiceSettings: Codable {
    var voiceResponseEnabled: Bool
    var autoSendAfterTranscription: Bool
    var autoSpeakConfirmations: Bool // PR #018: Auto-speak action confirmations
    var ttsVoice: TTSVoice
    var ttsRate: Float // Speech rate: 0.0 (slowest) to 1.0 (fastest)
    var ttsPitch: Float // Pitch: 0.5 (low) to 2.0 (high)
    var ttsVolume: Float // Volume: 0.0 (silent) to 1.0 (max)
    var transcriptionLanguage: String

    /// Available TTS voices
    enum TTSVoice: String, Codable {
        case samantha = "com.apple.ttsbundle.Samantha-compact"
        case alex = "com.apple.ttsbundle.Alex-compact"
        case fred = "com.apple.ttsbundle.Fred-compact"
        case karen = "com.apple.voice.compact.en-AU.Karen"
        case daniel = "com.apple.voice.compact.en-GB.Daniel"

        var displayName: String {
            switch self {
            case .samantha: return "Samantha (US Female)"
            case .alex: return "Alex (US Male)"
            case .fred: return "Fred (US Male)"
            case .karen: return "Karen (AU Female)"
            case .daniel: return "Daniel (UK Male)"
            }
        }
    }

    /// Default settings
    static var `default`: VoiceSettings {
        return VoiceSettings(
            voiceResponseEnabled: true,
            autoSendAfterTranscription: true, // PR #018: Default to true for voice-first workflow
            autoSpeakConfirmations: true, // PR #018: Auto-speak action confirmations
            ttsVoice: .samantha,
            ttsRate: 0.5, // Normal speed
            ttsPitch: 1.0, // Normal pitch
            ttsVolume: 1.0, // Max volume
            transcriptionLanguage: "en-US"
        )
    }

    /// UserDefaults key
    private static let userDefaultsKey = "voiceSettings"

    /// Load settings from UserDefaults
    static func load() -> VoiceSettings {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let settings = try? JSONDecoder().decode(VoiceSettings.self, from: data) else {
            return .default
        }
        return settings
    }

    /// Save settings to UserDefaults
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
        }
    }
}
