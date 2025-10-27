# PR-011 TODO — Voice AI Interface

**Branch**: `feat/pr-011-voice-ai-interface`
**Source PRD**: `Psst/docs/prds/pr-011-prd.md`
**Owner (Agent)**: Caleb

---

## 0. Clarifying Questions & Assumptions

**Assumptions:**
- OpenAI Whisper API already accessible (API key from PR #001)
- PR #006 (AI Chat UI) is complete and functional
- AVSpeechSynthesizer (iOS native TTS) is sufficient for V1 (no OpenAI TTS API needed initially)
- Microphone permission flow uses standard iOS permission request
- Recording format: AAC (m4a) at 16kHz sample rate for Whisper API compatibility

**Questions for User (if needed):**
- Should voice recording use push-to-talk (hold button) or tap-to-start/tap-to-stop? → **Decided: Tap-to-start/tap-to-stop**
- Should TTS auto-play by default or require user opt-in? → **Decided: Auto-play with toggle to disable**

---

## 1. Setup

- [ ] Create branch `feat/pr-011-voice-ai-interface` from develop
- [ ] Read PRD thoroughly (`Psst/docs/prds/pr-011-prd.md`)
- [ ] Read `Psst/agents/shared-standards.md` for Swift/SwiftUI patterns
- [ ] Verify OpenAI API key exists in Firebase config (for Whisper API)
- [ ] Test existing AI Assistant chat (PR #006) to understand integration points
- [ ] Confirm Xcode simulator/device has microphone access

---

## 2. Data Models & Types

- [ ] Create `Models/VoiceRecording.swift`
  - Test Gate: Model compiles, Codable conformance works
  - Properties: id, audioURL, duration, timestamp, transcription, status enum

- [ ] Create `Models/VoiceSettings.swift`
  - Test Gate: Encodes/decodes to UserDefaults successfully
  - Properties: voiceResponseEnabled, autoSendAfterTranscription, ttsVoice, transcriptionLanguage

- [ ] Create `Models/VoiceServiceError.swift`
  - Test Gate: Error enum provides localized descriptions
  - Cases: microphonePermissionDenied, recordingFailed, transcriptionFailed, ttsNotAvailable, audioSessionFailed

**Acceptance:** All models compile, conform to Codable, have unit tests for encoding/decoding

---

## 3. VoiceService Implementation

### 3a. Audio Recording

- [ ] Create `Services/VoiceService.swift` with basic structure
  - Test Gate: Service initializes without errors

- [ ] Implement `requestMicrophonePermission() async -> Bool`
  - Test Gate: Returns true if permission granted, false if denied
  - Test Gate: Permission denied shows iOS system alert

- [ ] Implement `startRecording() throws -> VoiceRecording`
  - Configure AVAudioRecorder with AAC format (16kHz)
  - Create temporary file URL for recording
  - Start recording and update `isRecording` published property
  - Test Gate: Audio file created in temp directory
  - Test Gate: isRecording = true when recording active

- [ ] Implement `stopRecording() async throws -> URL`
  - Stop AVAudioRecorder
  - Return file URL of recorded audio
  - Update `isRecording = false`
  - Test Gate: Audio file contains valid audio data

- [ ] Implement `cancelRecording()`
  - Stop recording and delete temporary file
  - Reset recording state
  - Test Gate: Temp file deleted, isRecording = false

- [ ] Implement `getAudioLevel() -> Float`
  - Use AVAudioRecorder.averagePower(forChannel:) for waveform data
  - Test Gate: Returns value between 0.0 and 1.0 during recording

**Acceptance:** Recording works, audio file saved locally, permission flow tested

---

### 3b. Speech-to-Text (Whisper API)

- [ ] Implement `transcribe(audioURL: URL, language: String) async throws -> String`
  - Create multipart/form-data request to OpenAI Whisper API
  - Include audio file as attachment
  - Parse JSON response for transcription text
  - Test Gate: 5-second test audio returns valid transcription
  - Test Gate: Empty audio file throws transcriptionFailed error

- [ ] Add error handling for Whisper API
  - Handle 400 (invalid format), 401 (auth), 413 (file too large), 429 (rate limit), 500 (server error)
  - Map errors to VoiceServiceError cases with user-friendly messages
  - Test Gate: Each error code returns appropriate VoiceServiceError

- [ ] Add retry logic for transient failures (500, timeout)
  - Retry up to 3 times with exponential backoff
  - Test Gate: Transient failure retries, permanent failure throws immediately

**Acceptance:** Whisper API integration works, transcribes real audio, handles errors gracefully

---

### 3c. Text-to-Speech (AVSpeechSynthesizer)

- [ ] Implement `speak(text: String, voice: VoiceSettings.TTSVoice)`
  - Create AVSpeechUtterance with text
  - Configure voice using VoiceSettings.TTSVoice enum
  - Use AVSpeechSynthesizer to speak utterance
  - Test Gate: Text spoken aloud on device/simulator

- [ ] Implement `stopSpeaking()`
  - Stop current AVSpeechSynthesizer playback immediately
  - Test Gate: TTS stops mid-sentence when called

- [ ] Add `isSpeaking: Bool` computed property
  - Return speechSynthesizer.isSpeaking
  - Test Gate: Returns true while speaking, false when idle

**Acceptance:** TTS works with AVSpeechSynthesizer, voice selection works, playback controls function

---

### 3d. Audio Session Management

- [ ] Create `Services/AudioSessionService.swift`
  - Configure AVAudioSession for recording and playback
  - Handle audio interruptions (phone calls, other apps)
  - Test Gate: Audio session switches between record/playback modes without errors

- [ ] Implement recording mode configuration
  - Set category to `.record` or `.playAndRecord`
  - Test Gate: Microphone captures audio correctly

- [ ] Implement playback mode configuration
  - Set category to `.playback` with `.duckOthers` option
  - Test Gate: TTS plays while lowering background music volume

**Acceptance:** Audio session handles recording/playback transitions, doesn't conflict with other audio apps

---

### 3e. Settings Persistence

- [ ] Implement `loadSettings() -> VoiceSettings`
  - Decode VoiceSettings from UserDefaults
  - Return default settings if not found
  - Test Gate: Settings loaded correctly on app launch

- [ ] Implement `saveSettings(_ settings: VoiceSettings)`
  - Encode VoiceSettings to UserDefaults
  - Test Gate: Settings persist across app restarts

**Acceptance:** Voice settings save/load from UserDefaults, defaults applied correctly

---

## 4. UI Components

### 4a. VoiceButton Component

- [ ] Create `Components/VoiceButton.swift`
  - Microphone icon button with state-based styling
  - States: idle (gray), recording (pulsing red), transcribing (disabled + spinner), error (red X)
  - Test Gate: SwiftUI Preview renders all states correctly

- [ ] Add tap gesture handling
  - Tap when idle → Start recording
  - Tap when recording → Stop recording
  - Test Gate: Tap toggles recording state

**Acceptance:** VoiceButton component renders all states, tap gestures work

---

### 4b. Waveform Visualization

- [ ] Create `Components/WaveformView.swift`
  - Real-time waveform using audio level data
  - Animated bars that pulse with audio input
  - Test Gate: SwiftUI Preview shows animated waveform

- [ ] Integrate with VoiceService.getAudioLevel()
  - Poll audio level every 0.1s during recording
  - Update waveform bars with normalized values
  - Test Gate: Waveform animates in real-time during recording

**Acceptance:** Waveform visualization smooth, updates in real-time

---

### 4c. Voice Recording View

- [ ] Create `Views/AI/VoiceRecordingView.swift`
  - Full-screen recording UI with waveform, timer, controls
  - Timer showing recording duration (0:00 format)
  - Cancel button (X) and Stop button (mic icon)
  - Test Gate: SwiftUI Preview renders correctly

- [ ] Add recording duration timer
  - Start at 0:00 when recording begins
  - Update every second
  - Show warning at 50s ("10 seconds remaining")
  - Auto-stop at 60s
  - Test Gate: Timer counts correctly, auto-stop works at 60s

- [ ] Add loading state for transcription
  - "Transcribing..." text + spinner
  - Test Gate: Appears after recording stops, disappears when transcription completes

**Acceptance:** VoiceRecordingView shows all states, timer works, auto-stop at 60s

---

### 4d. Modify AIAssistantView

- [ ] Add VoiceButton to bottom toolbar
  - Position next to text input field
  - Show/hide based on recording state
  - Test Gate: Button appears in AIAssistantView toolbar

- [ ] Integrate voice recording flow
  - Tap mic → Present VoiceRecordingView sheet
  - Recording complete → Dismiss sheet, populate text input with transcription
  - Test Gate: End-to-end voice flow works (speak → transcribe → text appears)

- [ ] Add speaker icon to AI message bubbles
  - Tap speaker → Replay TTS for that message
  - Test Gate: Speaker icon appears on AI messages, tap plays audio

**Acceptance:** Voice button integrated into AI chat, recording flow works end-to-end

---

### 4e. Voice Settings View

- [ ] Create `Views/Settings/VoiceSettingsView.swift`
  - Toggle: Enable Voice Responses (TTS)
  - Picker: TTS Voice (Samantha, Alex, Fred)
  - Toggle: Auto-send after transcription
  - Picker: Transcription Language (English default)
  - Test Gate: SwiftUI Preview renders settings correctly

- [ ] Wire settings to VoiceService
  - Load settings on view appear
  - Save settings when changed
  - Test Gate: Settings changes persist after app restart

- [ ] Add VoiceSettingsView to main Settings screen
  - Add navigation link from SettingsView
  - Test Gate: Navigation to VoiceSettingsView works

**Acceptance:** VoiceSettingsView functional, settings persist, accessible from main Settings

---

## 5. ViewModel Integration

- [ ] Modify `ViewModels/AIAssistantViewModel.swift`
  - Add @Published var isRecording: Bool
  - Add @Published var currentTranscription: String?
  - Add @Published var voiceSettings: VoiceSettings
  - Test Gate: Properties trigger SwiftUI updates

- [ ] Add voice recording methods to ViewModel
  - `startVoiceRecording()` → Call VoiceService.startRecording()
  - `stopVoiceRecording()` → Call VoiceService.stopRecording() → Transcribe
  - `cancelVoiceRecording()` → Call VoiceService.cancelRecording()
  - Test Gate: ViewModel methods call VoiceService correctly

- [ ] Add TTS control methods
  - `speakResponse(_ text: String)` → Call VoiceService.speak()
  - `stopSpeaking()` → Call VoiceService.stopSpeaking()
  - Test Gate: TTS plays AI responses automatically (if enabled)

**Acceptance:** AIAssistantViewModel manages voice state, coordinates with VoiceService

---

## 6. Permissions & Info.plist

- [ ] Add NSMicrophoneUsageDescription to Info.plist
  - Message: "Psst uses your microphone to let you talk to your AI Assistant hands-free. Your voice is transcribed by OpenAI and never stored permanently."
  - Test Gate: Permission alert shows this message on first microphone request

- [ ] Test permission flow
  - First launch → Tap mic → Permission alert appears
  - User grants → Recording starts
  - User denies → Error alert with "Open Settings" button
  - Test Gate: Permission denial shows actionable error message

**Acceptance:** Microphone permission works, clear explanation, Settings shortcut functional

---

## 7. Error Handling

- [ ] Handle microphone permission denied
  - Show alert: "Microphone access required. Enable in Settings > Psst > Microphone"
  - Add "Open Settings" button → Opens iOS Settings app
  - Test Gate: Denial flow works, Settings opens correctly

- [ ] Handle recording failures
  - Catch AVAudioRecorder errors
  - Show user-friendly message: "Recording failed. Please try again."
  - Test Gate: Simulated recording failure shows alert

- [ ] Handle transcription failures (Whisper API)
  - Offline: "No internet connection. Transcription pending..."
  - Timeout: "Transcription taking too long. Retry?"
  - Invalid audio: "Audio unclear. Try again?"
  - Test Gate: Each error type shows appropriate message with retry button

- [ ] Handle TTS failures
  - Voice not available: Fall back to default iOS voice
  - Audio session conflict: Pause recording gracefully
  - Test Gate: TTS failures don't crash app, fallback works

**Acceptance:** All error scenarios handled with clear user messages, retry options provided

---

## 8. OpenAI Whisper API Integration

- [ ] Create Whisper API client in VoiceService
  - Endpoint: `POST https://api.openai.com/v1/audio/transcriptions`
  - Headers: Authorization Bearer token, Content-Type multipart/form-data
  - Body: file (m4a audio), model ("whisper-1"), language ("en")
  - Test Gate: API call returns transcription for test audio file

- [ ] Add multipart/form-data encoding
  - Create boundary-separated multipart body
  - Attach audio file as binary data
  - Test Gate: Whisper API accepts request format

- [ ] Parse Whisper API response
  - Extract "text" field from JSON response
  - Handle verbose_json format if needed (with timestamps)
  - Test Gate: Transcription text extracted correctly

- [ ] Add API key configuration
  - Read OPENAI_API_KEY from Firebase config or environment
  - Test Gate: API key loaded correctly (don't hardcode)

**Acceptance:** Whisper API integration works, transcribes real recordings accurately

---

## 9. User-Centric Testing

### Happy Path
- [ ] Open AI Assistant → Tap microphone button → Permission granted (first time)
- [ ] Speak: "What did Sarah say about her diet?"
- [ ] Tap microphone to stop recording
- [ ] Verify transcription appears in text input within 2 seconds
- [ ] Tap Send → AI responds with text
- [ ] Verify TTS plays response aloud (if enabled in settings)
- [ ] **Test Gate:** End-to-end flow completes in <5 seconds total
- [ ] **Pass:** Voice query → AI response → TTS playback all work smoothly

---

### Edge Cases

- [ ] **Edge Case 1: Background noise / unclear audio**
  - Record in simulated noisy environment (play background music during recording)
  - **Expected:** Whisper API returns partial transcription or empty string
  - **UI:** Shows transcription + "Audio unclear. Try again?" button
  - **Pass:** Handled gracefully, retry button works

- [ ] **Edge Case 2: Very short recording (< 1 second)**
  - Tap mic → Immediately stop (< 1s elapsed)
  - **Expected:** Shows alert "Recording too short. Please try again."
  - **Pass:** No API call made (saves cost), clear feedback

- [ ] **Edge Case 3: Maximum recording length (60 seconds)**
  - Hold recording for 60+ seconds (simulate long query)
  - **Expected:** Auto-stops at 60s, shows "Maximum length reached", transcribes normally
  - **Pass:** Doesn't crash, transcribes 60s audio successfully

- [ ] **Edge Case 4: User switches away during recording**
  - Start recording → Switch to Messages app → Return to Psst
  - **Expected:** Recording pauses or continues (depending on audio session config)
  - **Pass:** No data loss, clear state when returning

---

### Error Handling

- [ ] **Microphone Permission Denied**
  - Fresh app install → Tap mic → Deny permission
  - **Expected:** Alert: "Microphone access required. Enable in Settings > Psst > Microphone" + "Open Settings" button
  - **Pass:** Clear message, Settings shortcut works, app doesn't crash

- [ ] **Offline Mode (No Internet)**
  - Enable airplane mode → Record audio → Stop recording
  - **Expected:** "No internet connection. Transcription pending..." message
  - **Pass:** Recording saved locally, queued for retry when online (or manual retry)

- [ ] **Whisper API Timeout**
  - Simulate slow network (Network Link Conditioner) → Record → API timeout
  - **Expected:** "Transcription taking longer than expected. Retry?" with retry button
  - **Pass:** Timeout handled gracefully, retry works

- [ ] **TTS Voice Not Available**
  - Select TTS voice not downloaded on device (rare edge case)
  - **Expected:** Falls back to default iOS voice or shows "Downloading voice..."
  - **Pass:** TTS still plays with fallback voice

- [ ] **Audio Session Conflict (Music Playing)**
  - Play Spotify → Open Psst → Start recording
  - **Expected:** Spotify pauses (or volume lowers) → Recording begins → After TTS, Spotify resumes
  - **Pass:** No audio glitches, clear audio session handling

---

### Final Checks

- [ ] No console errors during voice operations (recording, transcription, TTS)
- [ ] Voice feature feels responsive (mic tap → recording starts within 50ms)
- [ ] Waveform animation smooth (no stuttering during recording)
- [ ] TTS playback smooth (no buffering, skipping)

---

## 10. Performance Verification

- [ ] Measure speech-to-text latency
  - Record 5-second audio → Stop → Time until transcription appears
  - Target: < 2 seconds
  - Test Gate: 5 test recordings average under 2s transcription time

- [ ] Measure TTS start latency
  - AI responds with text → Time until TTS begins speaking
  - Target: < 500ms
  - Test Gate: TTS starts within 500ms of AI response

- [ ] Measure recording start latency
  - Tap mic button → Time until recording indicator appears
  - Target: < 50ms
  - Test Gate: Feels instant (subjective, no noticeable delay)

- [ ] Test with long recordings (60 seconds)
  - Record 60-second audio → Transcribe
  - Verify: No memory leaks, app remains responsive
  - Test Gate: App doesn't crash or slow down with max-length recording

**Acceptance:** All performance targets met (transcription <2s, TTS <500ms, recording instant)

---

## 11. Documentation & PR

- [ ] Add inline code comments for complex logic
  - VoiceService methods (recording, transcription, TTS)
  - Audio session configuration
  - Whisper API multipart encoding
  - Test Gate: Complex methods have clear documentation comments

- [ ] Update README if needed
  - Add "Voice AI Interface" section to features list
  - Document OpenAI Whisper API requirement
  - Test Gate: README reflects new voice capability

- [ ] Create PR description using format from Caleb agent instructions
  - Title: "feat: Voice AI Interface (PR #011)"
  - Summary: "Adds voice recording, speech-to-text, and text-to-speech to AI Assistant"
  - Testing: List all test scenarios completed
  - Screenshots/video: Record demo of voice interaction
  - Test Gate: PR description comprehensive, includes demo video

- [ ] Verify with user before creating PR
  - Demo voice feature live (recording → transcription → TTS)
  - Get approval for PR creation
  - Test Gate: User approves feature functionality

- [ ] Open PR targeting develop branch
  - Link PRD and TODO in PR description
  - Add labels: "enhancement", "ai-features", "phase-4"
  - Test Gate: PR created successfully

**Acceptance:** PR created with full documentation, demo video, ready for review

---

## Copyable Checklist (for PR description)

```markdown
## PR #011: Voice AI Interface

### Summary
Adds voice interaction to AI Assistant, allowing trainers to speak queries and receive spoken responses hands-free.

### Features
- ✅ Voice recording with visual waveform feedback
- ✅ Speech-to-text using OpenAI Whisper API
- ✅ Text-to-speech using AVSpeechSynthesizer
- ✅ Microphone permission flow with clear error messages
- ✅ Voice settings (enable TTS, select voice, auto-send toggle)
- ✅ Integration with existing AI Chat (PR #006)

### Testing Completed
- [x] Happy path: Record → Transcribe → AI responds → TTS plays
- [x] Edge case: Background noise handling
- [x] Edge case: Very short recording (<1s)
- [x] Edge case: Maximum length recording (60s)
- [x] Error: Microphone permission denied
- [x] Error: Offline mode (transcription pending)
- [x] Error: Whisper API timeout
- [x] Performance: Transcription <2s, TTS start <500ms
- [x] All acceptance gates pass

### Technical Details
- New services: `VoiceService.swift`, `AudioSessionService.swift`
- New components: `VoiceButton.swift`, `WaveformView.swift`, `VoiceRecordingView.swift`
- Modified: `AIAssistantView.swift`, `AIAssistantViewModel.swift`
- API: OpenAI Whisper API (speech-to-text)
- TTS: AVSpeechSynthesizer (iOS native)

### Demo
[Video: voice-ai-demo.mp4]

### Checklist
- [x] Branch created from develop
- [x] All TODO tasks completed
- [x] VoiceService implemented with error handling
- [x] SwiftUI views implemented with state management
- [x] OpenAI Whisper API integration verified
- [x] AVSpeechSynthesizer TTS working
- [x] Microphone permission flow tested
- [x] Manual testing completed (happy path, edge cases, errors)
- [x] Performance targets met (<2s transcription, <500ms TTS)
- [x] All acceptance gates pass
- [x] Code follows `Psst/agents/shared-standards.md` patterns
- [x] No console warnings
- [x] Documentation updated
```

---

## Notes

- **OpenAI Whisper API costs**: Each transcription costs ~$0.006 per minute. Monitor usage via Cloud Function logs.
- **AVSpeechSynthesizer vs OpenAI TTS**: Start with free iOS TTS. Can upgrade to OpenAI TTS API in Phase 5 for better quality.
- **Waveform visualization**: Nice-to-have but important for user confidence that recording is working.
- **Always show transcription before sending**: Allows user to edit if Whisper misheard.
- **Test in real-world conditions**: Gym noise, AirPods, driving (voice-only, no screen interaction).
- **Audio session conflicts**: Use `.duckOthers` to lower background music during TTS without completely stopping it.
- **Recording limit (60s)**: Prevents API abuse and keeps queries focused. Can increase if needed.
- **Offline transcription**: iOS Speech framework could enable offline, but requires additional permissions. Consider for Phase 5.

---

## Reference Files

- PRD: `Psst/docs/prds/pr-011-prd.md`
- Shared Standards: `Psst/agents/shared-standards.md`
- Architecture: `Psst/docs/architecture-concise.md`
- PR Brief: `Psst/docs/ai-briefs.md#PR-011`
- AI Assignment Spec: `Psst/docs/reference/AI-ASSIGNMENT-SPEC.md`

---

**Ready for Caleb to implement!** 🎤

