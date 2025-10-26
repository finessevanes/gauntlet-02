# PR-011 TODO — Voice AI Interface

**Branch**: `feat/pr-011-voice-ai-interface`
**Source PRD**: `Psst/docs/prds/pr-011-prd.md`
**Owner (Agent)**: Caleb

---

## 0. Clarifying Questions & Assumptions

**Assumptions (confirm in PR if needed):**
- OpenAI Whisper API key already configured in Cloud Functions environment (from PR #001)
- Testing on physical iPhone required (simulator doesn't support microphone well)
- English-only transcription for MVP (Whisper supports 99 languages but we'll start with English)
- Auto-delete audio recordings after 30 days to manage storage costs
- TTS uses iOS system voices (no custom voice training)

**Questions:**
- None at this time (PRD is comprehensive)

---

## 1. Setup

- [ ] Create branch `feat/pr-011-voice-ai-interface` from develop
- [ ] Read PRD thoroughly (`Psst/docs/prds/pr-011-prd.md`)
- [ ] Read `Psst/agents/shared-standards.md` for Swift/iOS patterns
- [ ] Verify physical iPhone available for testing (microphone access)
- [ ] Check OpenAI Whisper API key exists in Cloud Functions config
  - Test Gate: `firebase functions:config:get openai.api_key` returns key

---

## 2. Backend: Cloud Function for Whisper Transcription

**File:** `functions/src/services/whisperService.ts` (new)

- [ ] Install OpenAI SDK in Cloud Functions: `npm install openai@latest`
  - Test Gate: `package.json` shows openai dependency
- [ ] Create `whisperService.ts` with `transcribeAudio(audioURL: string)` method
  - Downloads audio from Cloud Storage
  - Calls OpenAI Whisper API (`/v1/audio/transcriptions`)
  - Returns transcribed text + confidence score
  - Test Gate: Unit test with sample M4A file returns text
- [ ] Add error handling for Whisper API failures
  - Timeout after 10s
  - Handle 429 rate limit errors
  - Handle unsupported audio format errors
  - Test Gate: Error cases throw proper TypeScript errors

**File:** `functions/src/index.ts` (modify)

- [ ] Export new Cloud Function `transcribeAudio(userId, audioURL)`
  - Validates user is authenticated
  - Calls `whisperService.transcribeAudio()`
  - Saves transcription to `/ai_conversations/{conversationId}/messages`
  - Returns `{ text: string, confidence?: number, duration: number }`
  - Test Gate: Function callable from iOS via Firebase SDK

**Manual Test:**
- [ ] Deploy function: `firebase deploy --only functions:transcribeAudio`
- [ ] Test with cURL or Postman using sample audio URL
  - Test Gate: Returns JSON with transcribed text

---

## 3. iOS: VoiceService (Audio Recording & Playback)

**File:** `Psst/Psst/Services/VoiceService.swift` (new)

### 3.1: Audio Recording Setup

- [ ] Import AVFoundation framework
- [ ] Create `VoiceService` class conforming to `ObservableObject`
- [ ] Add `AVAudioRecorder` property for recording
- [ ] Implement `requestMicrophonePermission() async -> Bool`
  - Uses `AVAudioSession.requestRecordPermission()`
  - Returns true if granted, false if denied
  - Test Gate: First call shows iOS permission alert, subsequent calls return cached result
- [ ] Implement `startRecording() throws`
  - Sets up audio session: `AVAudioSession.sharedInstance().setCategory(.playAndRecord)`
  - Creates temp file URL: `FileManager.default.temporaryDirectory.appendingPathComponent("voice-\(UUID()).m4a")`
  - Configures recorder: 16kHz sample rate, mono channel, AAC codec
  - Starts recording: `recorder.record()`
  - Test Gate: Calling method starts recording, waveform levels available
- [ ] Implement `stopRecording() async throws -> URL`
  - Stops recorder: `recorder.stop()`
  - Returns local file URL of M4A audio
  - Test Gate: File exists at returned URL, playable in QuickTime
- [ ] Add `getAudioLevels() -> Float` for waveform visualization
  - Uses `recorder.updateMeters()` and `recorder.averagePower(forChannel: 0)`
  - Returns normalized 0.0-1.0 value
  - Test Gate: While recording, returns changing values based on mic input

### 3.2: Text-to-Speech Playback

- [ ] Add `AVSpeechSynthesizer` property for TTS
- [ ] Implement `speak(text: String, rate: Float) async throws`
  - Creates `AVSpeechUtterance` with text
  - Sets voice: `AVSpeechSynthesisVoice(language: "en-US")`
  - Sets rate: `utterance.rate = rate` (0.5-2.0 range)
  - Speaks: `synthesizer.speak(utterance)`
  - Test Gate: Text plays through device speakers
- [ ] Implement `pauseSpeech()`, `resumeSpeech()`, `stopSpeech()`
  - Uses synthesizer methods: `pauseSpeaking()`, `continueSpeaking()`, `stopSpeaking()`
  - Test Gate: Pause/resume work mid-sentence without glitches
- [ ] Add background audio mode support
  - Configure audio session: `AVAudioSession.sharedInstance().setCategory(.playback)`
  - Test Gate: TTS continues playing when app is backgrounded

### 3.3: State Management

- [ ] Add `@Published var isRecording: Bool = false`
- [ ] Add `@Published var isSpeaking: Bool = false`
- [ ] Add `@Published var audioLevels: Float = 0.0` (updated 30x/sec)
- [ ] Implement error enum `VoiceServiceError`
  - Cases: `microphonePermissionDenied`, `recordingFailed(String)`, `audioSessionError(String)`, `playbackFailed(String)`
  - Test Gate: Errors thrown with descriptive messages

**Manual Test:**
- [ ] Test recording on physical iPhone: Tap record → speak → stop → file exists
  - Test Gate: M4A file playable, contains spoken audio
- [ ] Test TTS: Call `speak("Hello world")` → hears voice output
  - Test Gate: Audio plays clearly, no distortion
- [ ] Test audio levels: Record while speaking → `audioLevels` updates
  - Test Gate: Values range 0.0-1.0, responsive to volume

---

## 4. iOS: AIService Extensions (Whisper Integration)

**File:** `Psst/Psst/Services/AIService.swift` (modify)

- [ ] Add `transcribeAudio(audioURL: URL) async throws -> String` method
  - Uploads M4A file to Cloud Storage at `/users/{userId}/voice_recordings/{UUID}.m4a`
  - Calls Cloud Function `transcribeAudio(userId: currentUser.uid, audioURL: storageURL)`
  - Returns transcribed text string
  - Test Gate: Sample audio file returns expected text
- [ ] Add error handling for transcription failures
  - Catch Firebase errors (storage upload fails)
  - Catch Cloud Function errors (Whisper API timeout)
  - Throw `AIServiceError.transcriptionFailed(String)` with details
  - Test Gate: Network failure shows "No internet" error
- [ ] Add `processVoiceMessage(audioURL: URL) async throws -> (response: String, conversationId: String)` helper
  - Calls `transcribeAudio()` to get text
  - Calls existing `chatWithAI(message: text)` to get AI response
  - Returns both response text and conversation ID
  - Test Gate: End-to-end voice → AI response works

**Manual Test:**
- [ ] Record sample audio, upload to Cloud Storage manually
- [ ] Call `transcribeAudio(audioURL)` from iOS
  - Test Gate: Returns accurate transcription of spoken words
- [ ] Test full flow: `processVoiceMessage()` with question audio
  - Test Gate: Returns contextual AI response (RAG works)

---

## 5. iOS: Data Models

**File:** `Psst/Psst/Models/VoicePreferences.swift` (new)

- [ ] Create `VoicePreferences` struct
  - Properties: `ttsEnabled: Bool`, `ttsRate: Float`, `autoConversationMode: Bool`, `backgroundAudioEnabled: Bool`
  - Defaults: `ttsEnabled = true, ttsRate = 1.0, autoConversationMode = false, backgroundAudioEnabled = true`
  - Codable conformance for UserDefaults storage
  - Test Gate: Can encode/decode to JSON

**File:** `Psst/Psst/Models/AIMessage.swift` (modify)

- [ ] Add optional `inputMethod: String?` property ("text" or "voice")
- [ ] Add optional `audioURL: String?` property (Cloud Storage path)
- [ ] Update `Codable` conformance with CodingKeys
  - Test Gate: Existing messages still decode (backward compatible)

---

## 6. iOS: ViewModels

**File:** `Psst/Psst/ViewModels/VoiceInputViewModel.swift` (new)

### 6.1: Recording State Management

- [ ] Create `VoiceInputViewModel: ObservableObject`
- [ ] Inject dependencies: `VoiceService`, `AIService`
- [ ] Add `@Published var recordingState: RecordingState` enum
  - Cases: `idle`, `recording`, `transcribing`, `error(String)`
- [ ] Add `@Published var audioLevels: Float = 0.0`
- [ ] Implement `startRecording() async`
  - Checks microphone permission first
  - Calls `voiceService.startRecording()`
  - Sets state to `.recording`
  - Starts timer to poll `audioLevels` 30x/sec
  - Test Gate: State transitions: idle → recording
- [ ] Implement `stopRecording() async`
  - Calls `voiceService.stopRecording()` → gets audio URL
  - Sets state to `.transcribing`
  - Calls `aiService.transcribeAudio(audioURL)`
  - Returns transcribed text
  - Test Gate: State transitions: recording → transcribing → idle
- [ ] Add error handling
  - Catches `VoiceServiceError.microphonePermissionDenied` → sets state to `.error("Microphone permission required")`
  - Catches transcription failures → sets state to `.error("Transcription failed")`
  - Test Gate: Permission denial shows error state

**File:** `Psst/Psst/ViewModels/VoicePlaybackViewModel.swift` (new)

### 6.2: TTS Playback State Management

- [ ] Create `VoicePlaybackViewModel: ObservableObject`
- [ ] Inject `VoiceService` dependency
- [ ] Add `@Published var playbackState: PlaybackState` enum
  - Cases: `idle`, `playing`, `paused`, `stopped`
- [ ] Add `@Published var playbackRate: Float = 1.0` (0.5-2.0)
- [ ] Implement `speak(text: String) async`
  - Calls `voiceService.speak(text, rate: playbackRate)`
  - Sets state to `.playing`
  - Test Gate: Audio plays, state updates
- [ ] Implement `pause()`, `resume()`, `stop()`
  - Calls corresponding VoiceService methods
  - Updates `playbackState`
  - Test Gate: Pause/resume works mid-sentence
- [ ] Add `adjustSpeed(rate: Float)`
  - Validates range 0.5-2.0
  - Saves to `VoicePreferences` in UserDefaults
  - Test Gate: Speed change persists across app restarts

**File:** `Psst/Psst/ViewModels/AIAssistantViewModel.swift` (modify)

- [ ] Add `@Published var isVoiceMode: Bool = false`
- [ ] Add `VoiceInputViewModel` as child ViewModel
- [ ] Implement `processVoiceInput(audioURL: URL) async`
  - Calls `aiService.processVoiceMessage(audioURL)`
  - Adds transcribed text as user message to conversation
  - Adds AI response to conversation
  - If TTS enabled: Calls `VoicePlaybackViewModel.speak(response)`
  - Test Gate: Voice input flows through existing AI pipeline
- [ ] Add toggle method `toggleVoiceMode()`
  - Switches `isVoiceMode` between true/false
  - Test Gate: UI updates when toggled

---

## 7. iOS: UI Components

**File:** `Psst/Psst/Views/AI/Components/AudioWaveformView.swift` (new)

- [ ] Create `AudioWaveformView` SwiftUI component
- [ ] Accept `audioLevels: Float` binding (0.0-1.0)
- [ ] Render 50 vertical bars in HStack
  - Each bar height scales with `audioLevels` (randomized slightly for visual effect)
  - Bars colored green when active, gray when idle
  - Smooth animation using `.animation(.easeInOut(duration: 0.1))`
  - Test Gate: Waveform animates smoothly as audio levels change
- [ ] Add pulse animation when recording
  - Scale effect: `scaleEffect(isRecording ? 1.1 : 1.0)`
  - Test Gate: Visual feedback matches recording state

**File:** `Psst/Psst/Views/AI/VoiceInputView.swift` (new)

### 7.1: Push-to-Talk Interface

- [ ] Create `VoiceInputView` with `@ObservedObject voiceInputVM: VoiceInputViewModel`
- [ ] Design microphone button (large circular button)
  - Idle: Gray circle with mic icon 🎤
  - Recording: Red pulsing circle with waveform
  - Transcribing: Spinner with "Transcribing..." text
  - Error: Red circle with shake animation + error message
- [ ] Implement push-to-talk gesture
  - `onLongPressGesture(minimumDuration: 0.0)` for tap-and-hold
  - `perform: { voiceInputVM.startRecording() }`
  - `onPressingChanged: { pressing in if !pressing { voiceInputVM.stopRecording() } }`
  - Test Gate: Hold to record, release to stop
- [ ] Integrate `AudioWaveformView` below button
  - Binds to `voiceInputVM.audioLevels`
  - Visible only when recording
  - Test Gate: Waveform appears during recording, hides when idle
- [ ] Add transcription display
  - Show transcribed text in chat bubble after processing
  - Test Gate: Text appears after recording stops

**File:** `Psst/Psst/Views/AI/VoicePlaybackView.swift` (new)

### 7.2: TTS Playback Controls

- [ ] Create `VoicePlaybackView` with `@ObservedObject playbackVM: VoicePlaybackViewModel`
- [ ] Display currently speaking text in highlighted bubble
  - Gray background, speaker icon 🔊
  - Text shown in full (no truncation)
- [ ] Add playback controls (HStack of buttons)
  - Pause button (⏸️): Calls `playbackVM.pause()`
  - Resume button (▶️): Calls `playbackVM.resume()`
  - Stop button (⏹️): Calls `playbackVM.stop()`
  - Speed button: Shows current rate (e.g., "1.0x"), taps open speed picker
  - Test Gate: All buttons work, state updates correctly
- [ ] Add speed adjustment picker
  - Slider or segmented control: 0.5x, 1.0x, 1.5x, 2.0x
  - Updates `playbackVM.playbackRate`
  - Test Gate: Speed change takes effect immediately on next speak() call
- [ ] Show playback progress (optional enhancement)
  - Text highlights word-by-word as spoken (uses AVSpeechSynthesizer delegate)
  - Test Gate: Highlighting syncs with audio

**File:** `Psst/Psst/Views/AI/AIAssistantView.swift` (modify)

### 7.3: Integrate Voice UI into AI Assistant

- [ ] Add voice/text mode toggle in top bar
  - Icon button: 🎤 (voice mode) or ⌨️ (text mode)
  - Tapping toggles `aiAssistantVM.isVoiceMode`
  - Test Gate: Toggling switches input UI
- [ ] Replace text input field with VoiceInputView when `isVoiceMode == true`
  - Use `if-else` conditional view
  - Test Gate: View switches smoothly, no layout jank
- [ ] Add VoicePlaybackView above message list
  - Visible when `playbackVM.playbackState == .playing || .paused`
  - Overlays at bottom of screen (above input area)
  - Test Gate: Appears during TTS, dismisses when stopped
- [ ] Show "Speaking..." indicator in AI message bubble during TTS
  - Add `isSpeaking: Bool` flag to AI message UI
  - Test Gate: Indicator visible while TTS active

**File:** `Psst/Psst/Views/Settings/SettingsView.swift` (modify)

### 7.4: Voice Settings UI

- [ ] Add "Voice Settings" section
  - Toggle: "Enable Voice Responses" → `voicePreferences.ttsEnabled`
  - Slider: "Speech Speed" → `voicePreferences.ttsRate` (0.5x-2.0x)
  - Toggle: "Auto Conversation Mode" → `voicePreferences.autoConversationMode`
  - Toggle: "Background Audio" → `voicePreferences.backgroundAudioEnabled`
  - Test Gate: All settings save to UserDefaults, persist across restarts
- [ ] Add "Test Voice" button
  - Taps button → Speaks sample text: "Hi, I'm your AI assistant. How can I help you today?"
  - Test Gate: TTS plays with current settings
- [ ] Add explanatory text for each setting
  - "Auto Conversation Mode: Mic auto-activates after AI responds"
  - Test Gate: Text visible, clear descriptions

---

## 8. Permissions & Info.plist

**File:** `Psst/Psst/Info.plist` (modify)

- [ ] Add microphone usage description
  - Key: `NSMicrophoneUsageDescription`
  - Value: "Psst needs microphone access so you can ask your AI assistant questions using your voice."
  - Test Gate: Permission alert shows this text on first mic access
- [ ] Add background audio capability (if using background playback)
  - Key: `UIBackgroundModes`
  - Value: `audio` (array)
  - Test Gate: TTS continues playing when app backgrounded

---

## 9. Firebase Cloud Storage Setup

**File:** `storage.rules` (modify, if exists)

- [ ] Add rule for voice recordings folder
  ```
  match /users/{userId}/voice_recordings/{fileName} {
    allow write: if request.auth.uid == userId;
    allow read: if request.auth.uid == userId;
  }
  ```
  - Test Gate: Users can only access their own recordings
- [ ] Configure auto-delete lifecycle (Firebase Console)
  - Navigate to Cloud Storage → Lifecycle
  - Add rule: Delete files in `/users/*/voice_recordings/*` older than 30 days
  - Test Gate: Old files auto-deleted (verify in Firebase Console after 30 days)

---

## 10. Integration Testing

### 10.1: End-to-End Voice Flow

- [ ] Test full flow: Tap mic → speak "What did Sarah say about her knee?" → release → hear response
  - Test Gate: Transcription appears correctly
  - Test Gate: AI response includes RAG context (mentions Sarah's past messages)
  - Test Gate: TTS plays response clearly
  - Test Gate: Total time <5 seconds

### 10.2: Continuous Conversation Mode

- [ ] Enable auto conversation mode in settings
- [ ] Ask voice question → AI responds → mic auto-activates
- [ ] Ask follow-up question without tapping mic button
  - Test Gate: Conversation flows naturally, mic activates after TTS completes
  - Test Gate: Conversation history preserved across multiple exchanges

### 10.3: Voice + Text Mixing

- [ ] Start with voice question
- [ ] AI responds with TTS
- [ ] Switch to text input (toggle mode)
- [ ] Type follow-up question
- [ ] Switch back to voice for third question
  - Test Gate: Conversation history shows mixed voice/text messages
  - Test Gate: AI maintains context across input methods

---

## 11. User-Centric Testing (3 Scenarios)

### Happy Path: Basic Voice Question

- [ ] **Flow:** Trainer opens AI Assistant → taps microphone → speaks "What exercises did Marcus request?" → releases button → sees transcription → hears AI response listing Marcus's exercise requests
- [ ] **Test Gate:**
  - Transcription accuracy >90% (manual review)
  - AI response includes RAG context from past conversations
  - TTS voice clear and understandable
  - Total time <5 seconds from button release to audio start
- [ ] **Pass:** Flow completes without errors, user gets actionable answer

### Edge Cases

**Edge Case 1: Very Short Audio (<1 second)**
- [ ] **Test:** Tap mic, say "Hi", release immediately
- [ ] **Expected:** Transcription shows "Hi", AI responds "Hello! How can I help you today?"
- [ ] **Pass:** No crash, minimum audio handled gracefully

**Edge Case 2: Background Noise (Gym Environment)**
- [ ] **Test:** Record audio with loud music playing in background
- [ ] **Expected:** Transcription may include noise words, but main question still understandable
- [ ] **Pass:** System doesn't crash, user can retry or switch to text

**Edge Case 3: Rapid Follow-Up Questions**
- [ ] **Test:** Ask question, get response, immediately interrupt TTS to ask follow-up
- [ ] **Expected:** TTS stops mid-sentence, mic activates for new recording
- [ ] **Pass:** No audio overlap, smooth transition, history preserved

**Edge Case 4: Switch Voice/Text Mid-Conversation**
- [ ] **Test:** Voice question → text question → voice question
- [ ] **Expected:** All inputs saved to same conversation, AI maintains context
- [ ] **Pass:** No conversation reset, seamless switching

### Error Handling

**Offline Mode:**
- [ ] **Test:** Enable airplane mode → tap mic → record → release button
- [ ] **Expected:** Shows "No internet connection. Voice requires internet for transcription."
- [ ] **Pass:** Error message clear, audio saved locally (can retry later)

**Microphone Permission Denied:**
- [ ] **Test:** First launch, deny mic permission → tap voice button
- [ ] **Expected:** Alert: "Psst needs microphone access for voice chat. Open Settings?"
- [ ] **Pass:** Tapping Settings opens iOS Settings → Psst → Microphone toggle

**Whisper API Timeout:**
- [ ] **Test:** Simulate slow network (Network Link Conditioner: 3G)
- [ ] **Expected:** Spinner shows for ~10s, then "Transcription taking too long. Try again?"
- [ ] **Pass:** Timeout handled gracefully, retry button works

**TTS Unavailable:**
- [ ] **Test:** Force-stop AVSpeechSynthesizer (simulate iOS bug)
- [ ] **Expected:** AI response appears as text with notice: "Audio playback unavailable. Showing text instead."
- [ ] **Pass:** User can still read response, no crash

**Audio Session Interrupted (Phone Call):**
- [ ] **Test:** Start recording → receive phone call → answer → hang up
- [ ] **Expected:** Recording auto-stops, shows "Recording interrupted by phone call"
- [ ] **Pass:** No crash, can restart recording after call

### Final Checks

- [ ] No console errors during all test scenarios
- [ ] Feature feels responsive (no noticeable lag)
- [ ] Waveform animations smooth (60fps)
- [ ] TTS voice sounds natural (not robotic)

---

## 12. Performance Verification

**Measured Targets (from shared-standards.md):**

- [ ] **Microphone activation:** <50ms from tap to waveform visible
  - Test: Tap mic button, measure time to waveform start using Instruments
  - Gate: <50ms tap response
- [ ] **Transcription time:** <3s for 30-second audio clip
  - Test: Record 30s audio, measure time from `stopRecording()` to transcription returned
  - Gate: <3 seconds
- [ ] **TTS playback latency:** <500ms from response received to audio starts
  - Test: Measure time from `aiService.chatWithAI()` completion to `speak()` audio start
  - Gate: <500ms
- [ ] **Total round-trip:** <5s from "release button" to "hear first word of response"
  - Test: End-to-end flow with typical question ("What did Sarah say?")
  - Gate: <5 seconds total

**Instruments Profiling:**
- [ ] Check memory usage during 10-minute voice conversation
  - Test Gate: No memory leaks (Instruments Leaks shows 0 leaks)
- [ ] Check CPU usage during recording and TTS
  - Test Gate: <20% CPU usage on average

---

## 13. Acceptance Gates (All from PRD)

### Voice Recording Gates
- [x] Tap microphone → Recording starts within 50ms with waveform visible
- [x] Audio captured at 16kHz mono with AAC compression
- [x] Recording stops on button release → Audio file uploaded to Cloud Function

### Speech-to-Text Gates
- [x] 30-second audio → Transcribed by Whisper API in <3s
- [x] Transcription accuracy >90% for clear English speech (manual test with 10 samples)
- [x] Transcription appears as user message in chat history

### Text-to-Speech Gates
- [x] AI response received → TTS playback starts within 500ms
- [x] Pause/resume controls work without audio glitches
- [x] Playback continues in background when app minimized (iOS background audio mode)

### Conversation Flow Gates
- [x] Voice question → AI voice response → Mic auto-activates for follow-up question
- [x] Switch from voice to text input mid-conversation → Conversation history preserved
- [x] Incoming phone call → Voice pauses, resumes after call ends

### Error Handling Gates
- [x] Microphone permission denied → Shows settings link + explanation
- [x] Network offline during transcription → Shows "No internet" + saves audio for retry
- [x] Whisper API timeout → Shows retry button + option to type instead
- [x] TTS unavailable → Falls back to text-only display with notice

---

## 14. Documentation & PR

- [ ] Add inline comments for AVAudioRecorder setup (complex audio session config)
- [ ] Add inline comments for Whisper API integration (request format, error codes)
- [ ] Document known limitations in code comments:
  - Requires internet (no offline transcription)
  - English-only transcription for MVP
  - Max 2-minute recording duration
  - Audio files auto-deleted after 30 days
- [ ] Update README with voice feature section (if applicable)
- [ ] Create PR description with format:
  ```markdown
  ## PR #011: Voice AI Interface

  **Feature:** Enables trainers to interact with AI Assistant using voice

  **Changes:**
  - Added VoiceService for audio recording and TTS playback
  - Integrated OpenAI Whisper API for speech-to-text
  - Created VoiceInputView with push-to-talk and waveform visualization
  - Added VoicePlaybackView with speed controls
  - Extended AIService with transcribeAudio() method
  - Added Cloud Function: transcribeAudio
  - Voice settings UI in Settings page

  **Testing:**
  - ✅ All acceptance gates pass (recording, transcription, TTS, errors)
  - ✅ Tested on physical iPhone (mic + speaker + AirPods)
  - ✅ Performance targets met (<5s round-trip)
  - ✅ Background audio mode verified

  **Links:**
  - PRD: Psst/docs/prds/pr-011-prd.md
  - TODO: Psst/docs/todos/pr-011-todo.md
  ```
- [ ] Verify with user before creating PR
- [ ] Open PR targeting `develop` branch
- [ ] Link PRD and TODO in PR description

---

## Copyable Checklist (for PR description)

```markdown
- [ ] Branch created from develop
- [ ] All TODO tasks completed
- [ ] VoiceService implemented (recording, playback, permissions)
- [ ] AIService.transcribeAudio() integrated with Whisper API
- [ ] Cloud Function `transcribeAudio` deployed and tested
- [ ] VoiceInputView with push-to-talk and waveform
- [ ] VoicePlaybackView with TTS controls
- [ ] AIAssistantView modified with voice mode toggle
- [ ] Settings page with voice preferences
- [ ] Info.plist updated with microphone permission description
- [ ] Cloud Storage rules for voice recordings
- [ ] Manual testing completed on physical iPhone
- [ ] Tested with AirPods, Bluetooth car, device speaker
- [ ] Background audio mode verified
- [ ] All acceptance gates pass (PRD Section 12)
- [ ] Performance targets met (<5s round-trip, <3s transcription)
- [ ] No memory leaks (Instruments verified)
- [ ] Code follows Psst/agents/shared-standards.md patterns
- [ ] No console warnings
- [ ] Documentation updated (inline comments, known limitations)
```

---

## Notes

**Development Tips:**
- Test on physical iPhone (simulator doesn't support microphone well)
- Use AirPods for testing to avoid speaker feedback during TTS playback
- Enable "Network Link Conditioner" in iOS Settings → Developer to simulate slow network
- Use Instruments → Leaks to check for AVAudioRecorder memory leaks
- Reference Apple's AVFoundation docs for audio session interruption handling

**Common Issues:**
- Audio session conflicts: Ensure proper category setting (`.playAndRecord` for recording, `.playback` for TTS)
- Microphone feedback loop: Use headphones during testing if speaker + mic are active simultaneously
- Background audio not working: Check `UIBackgroundModes` in Info.plist includes `audio`

**Tasks are broken into <30 min chunks for Caleb to complete sequentially.**
**Check off each task immediately after completion.**

---

**Document Status:** ✅ Ready for Caleb to implement
**Next Steps:** `/caleb 011` to begin implementation
