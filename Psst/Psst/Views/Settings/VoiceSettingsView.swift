//
//  VoiceSettingsView.swift
//  Psst
//
//  Created by Caleb (AI Agent) on 10/26/25.
//  PR #011 - Phase 3: Voice Settings
//

import SwiftUI

/// Settings screen for voice features customization
struct VoiceSettingsView: View {
    @State private var settings = VoiceSettings.load()
    @StateObject private var voiceService = VoiceService()
    @State private var previewingVoice: VoiceSettings.TTSVoice?
    @Environment(\.dismiss) private var dismiss

    // MARK: - Constants

    private let availableVoices: [VoiceSettings.TTSVoice] = [
        .samantha,
        .alex,
        .fred,
        .karen,
        .daniel
    ]

    var body: some View {
        Form {
            textToSpeechSection
            recordingSection
            advancedSection
        }
        .navigationTitle("Voice Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    saveSettings()
                    dismiss()
                }
            }
        }
        .onDisappear {
            voiceService.stopSpeaking()
        }
    }

    // MARK: - Text-to-Speech Section

    private var textToSpeechSection: some View {
        Section {
            Toggle("Enable Voice Responses", isOn: $settings.voiceResponseEnabled)

            // Voice selection with preview button
            HStack {
                Picker("TTS Voice", selection: $settings.ttsVoice) {
                    ForEach(availableVoices, id: \.self) { voice in
                        Text(voice.displayName).tag(voice)
                    }
                }
                .disabled(!settings.voiceResponseEnabled)

                // Preview button
                Button(action: {
                    previewVoice(settings.ttsVoice)
                }) {
                    Image(systemName: previewingVoice == settings.ttsVoice && voiceService.isSpeaking ? "stop.circle.fill" : "play.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .disabled(!settings.voiceResponseEnabled)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Speech Rate")
                    Spacer()
                    Text(String(format: "%.1fx", settings.ttsRate * 2))
                        .foregroundColor(.secondary)
                }
                Slider(value: $settings.ttsRate, in: 0.0...1.0, step: 0.1)
            }
            .disabled(!settings.voiceResponseEnabled)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Pitch")
                    Spacer()
                    Text(String(format: "%.1fx", settings.ttsPitch))
                        .foregroundColor(.secondary)
                }
                Slider(value: $settings.ttsPitch, in: 0.5...2.0, step: 0.1)
            }
            .disabled(!settings.voiceResponseEnabled)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Volume")
                    Spacer()
                    Text("\(Int(settings.ttsVolume * 100))%")
                        .foregroundColor(.secondary)
                }
                Slider(value: $settings.ttsVolume, in: 0.0...1.0, step: 0.1)
            }
            .disabled(!settings.voiceResponseEnabled)

        } header: {
            Text("Text-to-Speech")
        } footer: {
            Text("AI responses will be spoken aloud using the selected voice.")
        }
    }

    // MARK: - Recording Section

    private var recordingSection: some View {
        Section {
            Toggle("Auto-Send After Transcription", isOn: $settings.autoSendAfterTranscription)

            Picker("Transcription Language", selection: $settings.transcriptionLanguage) {
                Text("English (US)").tag("en-US")
                Text("English (UK)").tag("en-GB")
                Text("Spanish").tag("es-ES")
                Text("French").tag("fr-FR")
                Text("German").tag("de-DE")
            }

        } header: {
            Text("Recording")
        } footer: {
            Text("Auto-send will immediately send transcribed text without review.")
        }
    }

    // MARK: - Advanced Section

    private var advancedSection: some View {
        Section {
            Button("Reset to Defaults") {
                settings = .default
                saveSettings()
            }
            .foregroundColor(.red)

        } header: {
            Text("Advanced")
        }
    }

    // MARK: - Helpers

    private func saveSettings() {
        settings.save()
        print("✅ [VoiceSettings] Settings saved")
    }

    private func previewVoice(_ voice: VoiceSettings.TTSVoice) {
        // If currently previewing this voice, stop it
        if previewingVoice == voice && voiceService.isSpeaking {
            voiceService.stopSpeaking()
            previewingVoice = nil
        } else {
            // Preview the voice
            previewingVoice = voice
            let sampleText = "Hello! This is how I sound. I'm \(voice.displayName.split(separator: " ").first ?? "")."
            voiceService.speak(text: sampleText, voice: voice)
        }
    }
}

#Preview {
    VoiceSettingsView()
}
