# PRD: Voice AI Interface

**Feature**: Voice AI Interface

**Version**: 1.0

**Status**: Ready for Development

**Agent**: Caleb

**Target Release**: Phase 4

**Links**: [PR Brief: ai-briefs.md#PR-011], [TODO: pr-011-todo.md]

---

## 1. Summary

Enable trainers to interact with their AI Assistant using voice instead of typing, allowing hands-free operation while walking between sessions, driving, or when typing is inconvenient. The AI will transcribe speech to text, generate responses, and optionally speak them back using text-to-speech.

---

## 2. Problem & Goals

**Problem:** Trainers are often on the go (walking between sessions, driving to clients, at the gym) and can't easily type to interact with their AI Assistant. This limits AI adoption to desk-based scenarios.

**Why Now:** With AI Chat (PR #006) and RAG (PR #006) complete, trainers have a powerful "second brain" but need hands-free access to unlock its full potential.

**Goals:**
- [ ] G1 — Enable 100% of AI Assistant features via voice (ask questions, search history, execute actions)
- [ ] G2 — Provide near-instant transcription (<2s from end of speech to text display)
- [ ] G3 — Deliver natural-sounding AI voice responses using TTS

---

## 3. Non-Goals / Out of Scope

- [ ] Voice messages in regular chats (recording voice memos to send directly to clients - not AI-related, future feature)
- [ ] Voice cloning or custom trainer voices (Phase 5 enhancement)
- [ ] Offline voice transcription (requires cloud API for now)
- [ ] Wake word detection ("Hey Psst" - future enhancement)
- [ ] Continuous conversation mode with interruptions (V2 feature)

> **✅ IN SCOPE:** Voice input TO the AI Assistant (which can then use all AI tools: sendMessage, scheduleCall, setReminder, searchMessages)
>
> **❌ OUT OF SCOPE:** Recording voice memos to send directly in regular chats (like WhatsApp voice messages) - this is a separate messaging feature unrelated to AI

---

## 4. Success Metrics

**User-visible:**
- Time to complete voice query (speak → response): < 5s total
- Voice mode activation: 1 tap (microphone button)
- Successful transcription rate: >95% accuracy (dependent on OpenAI Whisper quality)

**System:**
- Speech-to-text latency: < 2s after recording stops
- Text-to-speech start: < 500ms after AI response received
- Audio recording quality: 16kHz+ sample rate, AAC format

**Quality:**
- 0 blocking bugs in microphone permissions flow
- Clean error messages for "microphone denied" scenarios
- Crash-free rate >99% during voice operations

---

## 5. Users & Stories

- As a trainer walking between sessions, I want to ask "What did Sarah say about her diet?" using voice so I can review client context hands-free.
- As a trainer driving to a client, I want to ask "Schedule a call with John tomorrow at 6pm" so I can manage my calendar without typing.
- As a trainer in a loud gym, I want the AI to show transcribed text on screen so I can verify what it heard before processing.
- As a trainer wearing AirPods, I want AI responses spoken aloud so I can multitask while getting answers.

---

## 6. Experience Specification (UX)

### Entry Points
- AI Assistant chat screen (AIAssistantView): Microphone button in bottom toolbar (next to text input)
- Default mode: Text input visible + mic button available
- Tap mic → Switches to voice mode

### Voice Recording Flow
1. User taps microphone button
2. Permission check:
   - If denied: Alert with "Open Settings" button
   - If allowed: Recording starts immediately
3. Visual feedback during recording:
   - Pulsing mic icon (red)
   - Waveform visualization showing audio levels
   - Timer showing recording duration (max 60s)
4. User taps mic again to stop recording (or release if push-to-talk)
5. Loading state: "Transcribing..." with spinner
6. Transcribed text appears in message input field
7. User reviews text and taps "Send" (or auto-send if configured)

### Voice Response Flow
1. AI generates text response (existing flow from PR #006)
2. If "Voice Response" toggle enabled:
   - Text-to-speech begins automatically
   - Speaker icon appears next to AI message
   - User can tap speaker icon to replay
3. User can interrupt TTS playback by speaking again or tapping mic

### Visual States
- **Idle:** Microphone icon (gray) in toolbar
- **Recording:** Pulsing red mic icon + waveform animation
- **Transcribing:** Mic disabled + "Transcribing..." spinner
- **Playing TTS:** Speaker icon (blue) + sound waves animation
- **Error:** Mic icon with red X + error banner

### Settings
- Voice Response toggle: ON (default) / OFF
- Transcription Language: English (default), Spanish, French (future)
- Auto-send after transcription: ON / OFF (default)

### Performance Targets
- Microphone activation: < 50ms response time (instant feedback)
- Speech-to-text latency: < 2s after recording stops
- Text-to-speech start: < 500ms after AI response received
- Audio playback: Smooth, no stuttering or buffering

---

## 7. Functional Requirements (Must/Should)

### Recording Requirements
- MUST: Request microphone permission on first use with clear explanation
- MUST: Handle permission denied gracefully (show alert with Settings link)
- MUST: Capture audio in AAC format at 16kHz+ sample rate
- MUST: Limit recording duration to 60 seconds (show warning at 50s)
- MUST: Show real-time waveform during recording for visual feedback
- MUST: Allow user to cancel recording (X button appears during recording)
- SHOULD: Support background audio (continue recording if user switches apps)

**Acceptance Gates:**
- [Gate] User taps mic → Recording starts within 100ms
- [Gate] User speaks for 10s → Waveform animates in real-time
- [Gate] User taps mic again → Recording stops, transcription begins
- [Gate] Permission denied → Shows "Microphone access required" alert with Settings button

### Transcription Requirements
- MUST: Send audio to OpenAI Whisper API for transcription
- MUST: Display transcribed text in message input field for review
- MUST: Allow user to edit transcribed text before sending
- MUST: Handle transcription errors (empty result, API timeout) with retry option
- SHOULD: Auto-capitalize first letter and add punctuation

**Acceptance Gates:**
- [Gate] 5-second audio clip → Transcribed text appears within 2s
- [Gate] Unclear audio → Shows partial transcription + "Try again?" button
- [Gate] API timeout → Shows "Transcription failed. Retry?" message
- [Gate] User edits transcription → Edited text sent to AI, not original

### Text-to-Speech Requirements
- MUST: Use iOS native AVSpeechSynthesizer for TTS (or OpenAI TTS API as upgrade)
- MUST: Allow user to toggle TTS on/off in settings
- MUST: Provide playback controls (pause, replay, stop)
- MUST: Handle background audio properly (pause music, resume after TTS)
- SHOULD: Support multiple voices (male/female, different accents)

**Acceptance Gates:**
- [Gate] AI responds → TTS begins within 500ms (if toggle enabled)
- [Gate] User taps speaker icon on past message → TTS plays that message
- [Gate] User switches away from app → TTS pauses, resumes when app reopens
- [Gate] User disables TTS in settings → AI responses silent (text only)

### Voice Service Requirements
- MUST: Create VoiceService.swift for audio recording, transcription, TTS
- MUST: Integrate with OpenAI Whisper API for speech-to-text
- MUST: Handle audio session configuration (recording, playback modes)
- MUST: Manage audio permissions and provide clear error messages
- SHOULD: Cache TTS audio for replay without re-generating

**Acceptance Gates:**
- [Gate] VoiceService.startRecording() → Captures audio to file
- [Gate] VoiceService.transcribe(audioURL) → Returns transcribed text or error
- [Gate] VoiceService.speak(text) → Plays TTS audio using AVSpeechSynthesizer
- [Gate] Recording fails → Returns .microphonePermissionDenied error with recovery action

---

## 8. Data Model

### Swift Models

```swift
// VoiceRecording.swift
struct VoiceRecording: Identifiable, Codable {
    let id: String
    let audioURL: URL           // Local file URL
    let duration: TimeInterval  // Recording length in seconds
    let timestamp: Date
    var transcription: String?  // nil until transcribed
    var status: RecordingStatus

    enum RecordingStatus: String, Codable {
        case recording
        case transcribing
        case transcribed
        case failed
    }
}

// VoiceSettings.swift
struct VoiceSettings: Codable {
    var voiceResponseEnabled: Bool = true
    var autoSendAfterTranscription: Bool = false
    var ttsVoice: TTSVoice = .samantha  // iOS voice identifier
    var transcriptionLanguage: String = "en-US"

    enum TTSVoice: String, Codable {
        case samantha = "com.apple.ttsbundle.Samantha-compact"
        case alex = "com.apple.ttsbundle.Alex-compact"
        case fred = "com.apple.ttsbundle.Fred-compact"
    }
}

// VoiceServiceError.swift
enum VoiceServiceError: Error, LocalizedError {
    case microphonePermissionDenied
    case recordingFailed(String)
    case transcriptionFailed(String)
    case ttsNotAvailable
    case audioSessionFailed(String)

    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return "Microphone access required. Enable in Settings > Psst > Microphone"
        case .recordingFailed(let reason):
            return "Recording failed: \(reason)"
        case .transcriptionFailed(let reason):
            return "Couldn't transcribe audio. \(reason). Try again?"
        case .ttsNotAvailable:
            return "Text-to-speech unavailable on this device"
        case .audioSessionFailed(let reason):
            return "Audio setup failed: \(reason)"
        }
    }
}
```

### Firestore Schema Changes
**No Firestore changes required** - Voice is a client-side feature. Transcriptions are sent to AI Chat backend as regular text messages using existing `/ai_conversations` schema.

### UserDefaults Storage
```swift
// Store voice settings locally
UserDefaults.standard
  - "voiceSettings" → Encoded VoiceSettings JSON
```

---

## 9. API / Service Contracts

### VoiceService.swift

```swift
class VoiceService: ObservableObject {
    @Published var isRecording = false
    @Published var currentRecording: VoiceRecording?
    @Published var audioLevel: Float = 0.0  // For waveform

    private let audioRecorder: AVAudioRecorder?
    private let audioPlayer: AVAudioPlayer?
    private let speechSynthesizer: AVSpeechSynthesizer

    // MARK: - Recording

    /// Request microphone permission
    func requestMicrophonePermission() async -> Bool

    /// Start audio recording
    func startRecording() throws -> VoiceRecording

    /// Stop audio recording and return file URL
    func stopRecording() async throws -> URL

    /// Cancel current recording and delete file
    func cancelRecording()

    /// Get current audio level (0.0 to 1.0) for waveform visualization
    func getAudioLevel() -> Float

    // MARK: - Transcription

    /// Transcribe audio file using OpenAI Whisper API
    func transcribe(audioURL: URL, language: String) async throws -> String

    // MARK: - Text-to-Speech

    /// Speak text using AVSpeechSynthesizer
    func speak(text: String, voice: VoiceSettings.TTSVoice)

    /// Stop current TTS playback
    func stopSpeaking()

    /// Check if TTS is currently playing
    var isSpeaking: Bool { get }

    // MARK: - Settings

    /// Load voice settings from UserDefaults
    func loadSettings() -> VoiceSettings

    /// Save voice settings to UserDefaults
    func saveSettings(_ settings: VoiceSettings)
}
```

### OpenAI Whisper API Integration

**Endpoint:** `POST https://api.openai.com/v1/audio/transcriptions`

**Request:**
```
Headers:
  Authorization: Bearer {OPENAI_API_KEY}
  Content-Type: multipart/form-data

Body:
  file: {audio.m4a}  // AAC audio file
  model: "whisper-1"
  language: "en"  // Optional, auto-detect if omitted
  response_format: "json"  // or "verbose_json" for timestamps
```

**Response:**
```json
{
  "text": "What did Sarah say about her diet?"
}
```

**Error Handling:**
- 400: Invalid audio format → "Audio format not supported"
- 401: Invalid API key → "Authentication failed"
- 413: File too large (>25MB) → "Recording too long. Max 60 seconds"
- 429: Rate limit exceeded → "Too many requests. Try again in a moment"
- 500: Server error → "Transcription service unavailable. Retry?"

---

## 10. UI Components to Create/Modify

### New Components
- `Views/AI/VoiceRecordingView.swift` — Voice recording UI with waveform and controls
- `Components/WaveformView.swift` — Real-time audio waveform visualization
- `Components/VoiceButton.swift` — Microphone button with recording states
- `Views/Settings/VoiceSettingsView.swift` — Voice preferences configuration

### Modified Components
- `Views/AI/AIAssistantView.swift` — Add voice button to toolbar, integrate voice recording
- `ViewModels/AIAssistantViewModel.swift` — Add voice state management
- `Services/AIService.swift` — Potentially add OpenAI TTS support (future upgrade)

### New Services
- `Services/VoiceService.swift` — Core voice recording, transcription, TTS logic
- `Services/AudioSessionService.swift` — AVAudioSession configuration and management

---

## 11. Integration Points

### iOS Frameworks
- **AVFoundation:** AVAudioRecorder, AVAudioPlayer, AVAudioSession
- **Speech:** AVSpeechSynthesizer, AVSpeechUtterance, AVSpeechSynthesisVoice
- **SwiftUI:** @Published properties for reactive UI updates
- **Combine:** Audio level monitoring via Timer.publish

### External APIs
- **OpenAI Whisper API:** Speech-to-text transcription
- **OpenAI TTS API (Future):** High-quality text-to-speech (upgrade from AVSpeechSynthesizer)

### Existing Services
- **AIService.swift:** Voice transcriptions sent as text to existing `chatWithAI()` flow
- **AI Conversations:** Voice interactions stored in `/ai_conversations` as text messages

### Permissions
- **Microphone:** NSMicrophoneUsageDescription in Info.plist
- **Speech Recognition (Future):** NSSpeechRecognitionUsageDescription if using iOS Speech framework

---

## 12. Testing Plan & Acceptance Gates

### Happy Path
- [ ] User opens AI Assistant → Taps microphone button → Speaks "What did Sarah say about her diet?" → Stops recording
- [ ] **Gate:** Audio transcribes to text within 2 seconds
- [ ] User taps "Send" → AI responds with text → TTS speaks response aloud (if enabled)
- [ ] **Gate:** TTS begins within 500ms of AI response
- [ ] **Pass Criteria:** End-to-end voice query completed in <5s, clear audio playback

**Example Flow:**
1. Open AIAssistantView
2. Tap microphone button (grants permission if first use)
3. Speak: "Schedule a call with John tomorrow at 6pm"
4. Tap mic to stop
5. Transcription appears: "Schedule a call with John tomorrow at 6pm"
6. Review and tap Send
7. AI responds: "I've scheduled a call with John for tomorrow at 6:00 PM"
8. TTS speaks the response aloud
9. User hears confirmation through speaker/headphones

---

### Edge Cases

- [ ] **Edge Case 1: Background noise / unclear audio**
  - **Test:** Record in noisy environment (gym background noise)
  - **Expected:** Partial transcription appears + "Audio unclear. Try again?" button
  - **Pass:** Handles gracefully, allows retry, no crash

- [ ] **Edge Case 2: Very short recording (< 1 second)**
  - **Test:** Tap mic → Immediately stop recording
  - **Expected:** Shows "Recording too short. Please try again"
  - **Pass:** No API call made, clear feedback, retry available

- [ ] **Edge Case 3: Maximum recording length (60 seconds)**
  - **Test:** Hold mic button for 60+ seconds
  - **Expected:** Auto-stops at 60s, shows "Maximum length reached", proceeds to transcription
  - **Pass:** Doesn't crash, transcribes 60s audio successfully

- [ ] **Edge Case 4: User switches away during recording**
  - **Test:** Start recording → Switch to Messages app → Return to Psst
  - **Expected:** Recording continues in background (if supported) or pauses gracefully
  - **Pass:** No data loss, recording completes or provides clear "Recording paused" message

---

### Error Handling

- [ ] **Microphone Permission Denied**
  - **Test:** User denies microphone permission on first request
  - **Expected:** Alert appears: "Microphone access required. Enable in Settings > Psst > Microphone" with "Open Settings" button
  - **Pass:** Clear message, actionable button, doesn't crash

- [ ] **Offline Mode (No Internet)**
  - **Test:** Enable airplane mode → Attempt voice recording → Stop recording
  - **Expected:** Recording completes locally → "No internet connection. Transcription pending..." → Queues for retry when online
  - **Pass:** Recording saved, clear offline indicator, auto-retries when online

- [ ] **OpenAI Whisper API Timeout**
  - **Test:** Simulate slow network → Record audio → API timeout during transcription
  - **Expected:** "Transcription taking longer than expected. Retry?" with retry button
  - **Pass:** Timeout handled gracefully, retry option provided

- [ ] **TTS Voice Not Available**
  - **Test:** Select TTS voice that's not downloaded on device
  - **Expected:** Falls back to default iOS voice or shows "Downloading voice..." progress
  - **Pass:** TTS still works with fallback, no silence or crash

- [ ] **Audio Session Conflict (Music Playing)**
  - **Test:** Play Spotify → Open Psst → Start voice recording
  - **Expected:** Spotify pauses → Recording begins → After TTS playback, Spotify resumes (or doesn't, depending on audio session config)
  - **Pass:** Clear audio session handling, no audio glitches

---

### Performance Check

- [ ] Speech-to-text latency measured (target: <2s after recording stops)
- [ ] TTS start latency measured (target: <500ms after AI response)
- [ ] Recording feels instant (tap mic → red animation within 50ms)
- [ ] Waveform animation smooth (no stuttering during recording)

**If performance issues:**
- [ ] Optimize audio level sampling (reduce frequency if needed)
- [ ] Pre-load TTS synthesizer to reduce first-playback delay
- [ ] Compress audio before sending to Whisper API

---

### Optional: Multi-Device Testing

**Not applicable** - Voice is a client-side feature, no cross-device sync required.

---

## 13. Definition of Done

- [ ] VoiceService.swift implemented with recording, transcription, TTS methods
- [ ] VoiceRecordingView.swift with waveform visualization and recording controls
- [ ] VoiceButton component integrated into AIAssistantView toolbar
- [ ] Microphone permission flow with clear error messages
- [ ] OpenAI Whisper API integration with error handling
- [ ] AVSpeechSynthesizer TTS implementation with playback controls
- [ ] VoiceSettingsView for user preferences (toggle TTS, select voice)
- [ ] All acceptance gates pass (recording, transcription, TTS, permissions)
- [ ] Manual testing completed (happy path, edge cases, error handling)
- [ ] No console errors during voice operations
- [ ] Documentation updated (inline comments, README if needed)

---

## 14. Risks & Mitigations

**Risk:** OpenAI Whisper API costs add up with heavy usage (transcriptions not free)
- **Mitigation:** Monitor usage via Cloud Function logging, set budget alerts, consider caching transcriptions for replay

**Risk:** Microphone permission denied by users, blocking voice feature entirely
- **Mitigation:** Clear permission request explanation ("Voice lets you talk to AI hands-free"), Settings shortcut in error message, fallback to text input always available

**Risk:** TTS quality with AVSpeechSynthesizer sounds robotic compared to OpenAI TTS
- **Mitigation:** Start with AVSpeechSynthesizer (free, fast), plan upgrade to OpenAI TTS API in Phase 5 for premium users

**Risk:** Audio session conflicts with other apps (Spotify, Apple Music)
- **Mitigation:** Use AVAudioSession.Category.playAndRecord with .duckOthers option to lower other audio during recording/TTS

**Risk:** Background recording drains battery
- **Mitigation:** Limit recording to 60 seconds max, disable background recording if battery impact is high

**Risk:** Poor transcription accuracy in noisy environments (gym background noise)
- **Mitigation:** Show transcribed text before sending so user can edit, provide "Try again" button, consider noise cancellation in future

---

## 15. Rollout & Telemetry

### Feature Flag
- No feature flag required - Voice is additive (doesn't break existing text input)
- Users can opt-out by not using microphone button

### Metrics to Track
- **Usage:** % of AI queries via voice vs text
- **Transcription success rate:** % of recordings successfully transcribed
- **TTS usage:** % of users with TTS enabled
- **Permission denial rate:** % of users who deny microphone permission
- **Error rate:** Whisper API failures, audio recording failures
- **Latency:** Average transcription time, TTS start time

### Manual Validation Steps
1. Record 5-second audio clip → Verify transcription accuracy
2. Send voice query → Verify AI response + TTS playback
3. Test in noisy environment → Verify partial transcription handling
4. Deny microphone permission → Verify clear error message + Settings link
5. Toggle TTS on/off in settings → Verify audio playback behavior

---

## 16. Open Questions

- **Q1:** Should we use OpenAI TTS API or AVSpeechSynthesizer for V1?
  - **Decision:** Start with AVSpeechSynthesizer (free, fast, no API dependency). Upgrade to OpenAI TTS in Phase 5 if needed.

- **Q2:** Should recording be push-to-talk (hold button) or tap-to-start/tap-to-stop?
  - **Decision:** Tap-to-start/tap-to-stop (simpler UX, easier to record longer queries). Push-to-talk can be added as option later.

- **Q3:** Should we support wake word detection ("Hey Psst")?
  - **Decision:** Out of scope for V1. Requires background listening, privacy concerns, battery impact. Future Phase 5 enhancement.

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future:
- [ ] Wake word detection ("Hey Psst" to activate)
- [ ] Continuous conversation mode (interrupt AI mid-response)
- [ ] Voice message sending in regular chats (non-AI conversations)
- [ ] Voice cloning to match trainer's actual voice
- [ ] Offline transcription using iOS Speech framework
- [ ] Voice command shortcuts ("Remind me to...", "Find clients with...")
- [ ] Multi-language transcription (Spanish, French beyond English)
- [ ] Noise cancellation and audio enhancement

---

## Preflight Questionnaire

1. **Smallest end-to-end user outcome for this PR?**
   - Trainer speaks to AI Assistant → Gets spoken response back (hands-free interaction)

2. **Primary user and critical action?**
   - Trainers (Marcus, Alex) → Tap mic, speak query, receive AI response via audio

3. **Must-have vs nice-to-have?**
   - Must: Recording, Whisper transcription, text input pre-fill, TTS toggle
   - Nice: Waveform animation, multiple TTS voices, auto-send, background recording

4. **Real-time requirements?**
   - Not applicable (no cross-device sync)

5. **Performance constraints?**
   - Transcription latency: < 2s (Whisper API dependent)
   - TTS start: < 500ms (iOS AVSpeechSynthesizer)
   - Recording start: < 50ms (instant feedback critical)

6. **Error/edge cases to handle?**
   - Microphone permission denied, offline mode, API timeout, unclear audio, audio session conflicts, TTS voice unavailable

7. **Data model changes?**
   - Client-side only (VoiceRecording, VoiceSettings models in Swift)
   - No Firestore schema changes (transcriptions sent as text to existing AI chat)

8. **Service APIs required?**
   - VoiceService.swift (recording, transcription, TTS)
   - OpenAI Whisper API integration (speech-to-text)
   - AVSpeechSynthesizer (text-to-speech)

9. **UI entry points and states?**
   - Entry: Microphone button in AIAssistantView toolbar
   - States: Idle, Recording, Transcribing, Playing TTS, Error

10. **Security/permissions implications?**
    - Microphone permission required (NSMicrophoneUsageDescription in Info.plist)
    - Audio recordings stored locally, sent to OpenAI Whisper API (privacy consideration)

11. **Dependencies or blocking integrations?**
    - Depends on PR #006 (AI Chat UI) - already complete
    - OpenAI Whisper API access (existing OpenAI account from PR #001)

12. **Rollout strategy and metrics?**
    - Soft launch: Available to all users immediately (additive feature)
    - Metrics: Voice usage %, transcription success rate, TTS toggle rate

13. **What is explicitly out of scope?**
    - Wake word detection, voice cloning, offline transcription, continuous conversation mode, voice messages in regular chats

---

## Authoring Notes

- Voice feature is additive to existing AI Chat (PR #006) - doesn't modify existing text-based flow
- Focus on microphone permissions UX - many users hesitant to grant permission
- Whisper API costs money - log usage for budget tracking
- AVSpeechSynthesizer is "good enough" for V1, can upgrade to OpenAI TTS later
- Waveform visualization is nice-to-have but important for user confidence during recording
- Always show transcribed text before sending - allows error correction
- Test thoroughly in real-world conditions (gym noise, AirPods, driving scenarios)

