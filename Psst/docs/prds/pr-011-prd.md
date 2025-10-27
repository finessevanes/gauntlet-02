# PRD: Voice AI Interface

**Feature**: Voice AI Assistant for Hands-Free Operation

**Version**: 1.0

**Status**: Ready for Development

**Agent**: Caleb

**Target Release**: Phase 4

**Links**: [PR Brief](../ai-briefs.md#pr-011-voice-ai-interface), [TODO](../todos/pr-011-todo.md)

---

## 1. Summary

Enable trainers to interact with the AI Assistant using voice instead of typing, allowing hands-free operation while walking between training sessions, driving, or performing other activities. This feature integrates OpenAI Whisper for speech-to-text and iOS text-to-speech for AI responses, creating a seamless voice conversation experience.

---

## 2. Problem & Goals

**Problem:** Personal trainers are often on the move (walking between clients, driving, working out) and can't type lengthy questions to their AI assistant. They need hands-free access to their "second brain" to ask about client histories, schedule appointments, or set reminders while their hands are busy.

**Why now?** The AI Assistant (PR #004) and RAG pipeline (PR #005) are complete, providing intelligent contextual responses. Adding voice input/output removes the last friction point for trainers who are constantly mobile.

**Goals:**
- [ ] G1 — Enable trainers to have voice conversations with AI assistant with <5s response time
- [ ] G2 — Support conversation mode with back-and-forth voice exchanges without touching the phone
- [ ] G3 — Maintain feature parity with text chat (RAG search, function calling, client profiles)

---

## 3. Non-Goals / Out of Scope

Explicitly excluded to maintain focused vertical slice:

- [ ] Not doing: Offline voice transcription (requires internet for OpenAI Whisper)
- [ ] Not doing: Voice customization/accents for TTS (using iOS default voices)
- [ ] Not doing: Voice messages between trainers and clients (this is AI-only)
- [ ] Not doing: Wake word detection ("Hey Psst") - manual activation only
- [ ] Not doing: Real-time streaming transcription (batch processing only)

---

## 4. Success Metrics

**User-visible:**
- Time to get AI response: Speak question → Hear answer in <5s (including transcription, AI processing, and TTS)
- Number of taps to start voice conversation: 1 tap (voice button)
- Voice conversation completion rate: >80% of voice sessions complete without switching to text

**System:**
- Speech-to-text accuracy: >90% for clear audio (measured by manual review)
- Audio recording quality: 16kHz sample rate, mono channel
- TTS playback latency: <500ms from response received to audio starts

**Quality:**
- 0 blocking bugs (crashes, permission failures, audio device conflicts)
- All acceptance gates pass
- Crash-free rate >99% during voice operations

---

## 5. Users & Stories

**As a trainer walking between clients**, I want to ask my AI assistant "What did Sarah say about her knee injury?" using voice so that I can prepare for my next session hands-free.

**As a trainer driving**, I want to tell my AI "Schedule a call with Marcus tomorrow at 3pm" using voice so that I can manage my calendar safely without typing.

**As a trainer mid-workout**, I want to have a back-and-forth voice conversation with my AI to review multiple client details without stopping to type.

**As a trainer with limited vision**, I want to use voice as my primary interaction method with the AI so that I can access all features without reading screens.

**As a trainer in a noisy gym**, I want clear visual feedback when my voice is being processed so that I know the system heard me even if I can't hear the audio response.

---

## 6. Experience Specification (UX)

### Entry Points
1. **AI Assistant View:** Tap microphone button (🎤) in input area to start voice mode
2. **Voice Mode Toggle:** Settings option to make voice the default input method

### Primary Flow
1. User taps microphone button → Button animates to show recording state (pulsing red circle)
2. User speaks question → Live waveform visualization shows audio levels
3. User releases button (push-to-talk) or taps stop → Recording ends
4. System shows "Transcribing..." with spinner → Transcription appears in chat as user message
5. AI processes request → Shows "AI is thinking..." with typing indicator
6. AI response appears as text bubble → Automatically starts speaking (TTS)
7. During TTS playback: Pause/resume controls visible, text highlights as spoken
8. After response completes: Microphone re-activates for continuous conversation mode

### Visual States
- **Idle:** Gray microphone icon in input field
- **Recording:** Pulsing red circle with live waveform animation
- **Transcribing:** Spinner with "Transcribing your message..."
- **AI Processing:** Typing indicator with "AI is thinking..."
- **Speaking:** Speaker icon with animated sound waves, highlighted text
- **Error:** Red microphone with shake animation + error message below

### Loading/Disabled/Error States
- **Loading:** Spinner during transcription (2-3s) and AI processing (1-2s)
- **Disabled:** Microphone grayed out when network offline or permissions denied
- **Permission Denied:** Alert with "Microphone access required. Open Settings?" with direct link
- **Transcription Failed:** "Couldn't understand audio. Try speaking clearer?" with retry button
- **TTS Unavailable:** Falls back to text-only display with notice "Audio unavailable, showing text"

### Performance Targets
- Microphone activation: <50ms tap-to-record response
- Transcription time: <3s for 30-second audio clip
- AI response generation: <2s (same as text chat with RAG)
- TTS playback start: <500ms from response received
- Total round-trip: <5s from "stop recording" to "start speaking response"

---

## 7. Functional Requirements (Must/Should)

**MUST:**
- MUST integrate OpenAI Whisper API for speech-to-text transcription
- MUST use iOS AVSpeechSynthesizer for text-to-speech output
- MUST request microphone permission with clear explanation before first use
- MUST display live audio waveform during recording for visual feedback
- MUST support push-to-talk interaction (hold to record, release to send)
- MUST handle concurrent audio (pause voice if trainer receives phone call)
- MUST fall back to text display if TTS fails or is disabled
- MUST work with existing AI features (RAG search, function calling, client profiles)
- MUST save voice conversations to same `/ai_conversations` collection as text chats
- MUST allow seamless switching between voice and text mid-conversation

**SHOULD:**
- SHOULD support continuous conversation mode (auto-activate mic after AI response)
- SHOULD allow TTS speed adjustment (0.5x, 1x, 1.5x, 2x)
- SHOULD support background audio (voice continues playing when app backgrounded)
- SHOULD cache TTS audio for repeated phrases (e.g., "Let me search for that...")
- SHOULD show transcription confidence score for low-quality audio
- SHOULD support hands-free mode toggle in settings (auto-record when view opens)

### Acceptance Gates

**Voice Recording:**
- [Gate] Tap microphone → Recording starts within 50ms with waveform visible
- [Gate] Audio captured at 16kHz mono with AAC compression
- [Gate] Recording stops on button release → Audio file uploaded to Cloud Function

**Speech-to-Text:**
- [Gate] 30-second audio → Transcribed by Whisper API in <3s
- [Gate] Transcription accuracy >90% for clear English speech (manual test with 10 samples)
- [Gate] Transcription appears as user message in chat history

**Text-to-Speech:**
- [Gate] AI response received → TTS playback starts within 500ms
- [Gate] Text highlights as spoken (word-by-word synchronization)
- [Gate] Pause/resume controls work without audio glitches
- [Gate] Playback continues in background when app minimized (iOS background audio mode)

**Conversation Flow:**
- [Gate] Voice question → AI voice response → Mic auto-activates for follow-up question
- [Gate] Switch from voice to text input mid-conversation → Conversation history preserved
- [Gate] Incoming phone call → Voice pauses, resumes after call ends

**Error Handling:**
- [Gate] Microphone permission denied → Shows settings link + explanation
- [Gate] Network offline during transcription → Shows "No internet" + saves audio for retry
- [Gate] Whisper API timeout → Shows retry button + option to type instead
- [Gate] TTS unavailable → Falls back to text-only display with notice

---

## 8. Data Model

No new Firestore collections required. Voice messages integrate with existing AI chat data model.

### Existing Collection (Reused)
```swift
/ai_conversations/{conversationId}/messages/{messageId}
  - role: "user" | "assistant"
  - content: string (transcribed text or AI response)
  - timestamp: Timestamp
  - inputMethod: "text" | "voice"  // NEW FIELD (optional)
  - audioURL: string?  // NEW FIELD: Cloud Storage path to original audio
```

### Local Storage (UserDefaults)
```swift
// Voice preferences
VoicePreferences {
  ttsEnabled: Bool (default: true)
  ttsRate: Float (0.5-2.0, default: 1.0)
  autoConversationMode: Bool (default: false)
  backgroundAudioEnabled: Bool (default: true)
}
```

### Audio File Storage
```
Firebase Cloud Storage:
/users/{userId}/voice_recordings/{messageId}.m4a
- Audio recordings saved for 30 days (auto-delete policy)
- Used for debugging transcription issues
- Not required for feature operation (optional archive)
```

### Validation Rules
- Audio file size: Max 25MB (enforced client-side before upload)
- Recording duration: Max 2 minutes per voice message
- Supported formats: M4A (AAC), WAV (fallback)
- TTS rate range: 0.5x to 2.0x (AVSpeechUtterance rate limits)

---

## 9. API / Service Contracts

### iOS Services

#### VoiceService.swift
```swift
/// Manages audio recording, playback, and permissions
class VoiceService: ObservableObject {
    // Recording
    func requestMicrophonePermission() async -> Bool
    func startRecording() throws
    func stopRecording() async throws -> URL  // Returns local audio file URL
    func cancelRecording()

    // Playback
    func speak(text: String, rate: Float) async throws
    func pauseSpeech()
    func resumeSpeech()
    func stopSpeech()

    // Utilities
    func getAudioLevels() -> Float  // For waveform visualization
    func isRecording() -> Bool
    func isSpeaking() -> Bool
}

// Errors
enum VoiceServiceError: Error {
    case microphonePermissionDenied
    case recordingFailed(String)
    case audioSessionError(String)
    case playbackFailed(String)
}
```

#### AIService.swift (Extended)
```swift
extension AIService {
    /// Transcribe audio using OpenAI Whisper API
    /// - Parameter audioURL: Local file URL of M4A/WAV audio
    /// - Returns: Transcribed text
    func transcribeAudio(audioURL: URL) async throws -> String

    /// Process voice input end-to-end
    /// - Parameter audioURL: Local audio file
    /// - Returns: AI response text + conversation ID
    func processVoiceMessage(audioURL: URL) async throws -> (response: String, conversationId: String)
}

enum AIServiceError {
    case transcriptionFailed(String)
    case whisperAPITimeout
    case unsupportedAudioFormat
}
```

### Cloud Functions (TypeScript)

#### transcribeAudio (NEW)
```typescript
/**
 * Transcribes audio file using OpenAI Whisper API
 * POST /transcribeAudio
 */
interface TranscribeRequest {
  userId: string;
  audioURL: string;  // Firebase Storage path
}

interface TranscribeResponse {
  text: string;
  confidence?: number;  // Optional confidence score
  duration: number;  // Audio duration in seconds
}

export const transcribeAudio = functions.https.onCall(
  async (data: TranscribeRequest, context): Promise<TranscribeResponse>
);

// Implementation:
// 1. Download audio from Cloud Storage
// 2. Convert to format Whisper accepts (M4A/WAV)
// 3. Call OpenAI Whisper API
// 4. Return transcription text
// 5. Store transcription in /ai_conversations for history
```

#### Existing: chatWithAI
```typescript
// Already supports voice input via transcribed text
// No changes needed - voice transcriptions flow through existing pipeline
```

### Pre/Post-Conditions

**VoiceService.startRecording():**
- **Pre:** Microphone permission granted, no other recording in progress
- **Post:** Audio recording active, audio levels available for waveform
- **Errors:** Throws `microphonePermissionDenied` if permission not granted

**AIService.transcribeAudio():**
- **Pre:** Valid audio file URL (M4A/WAV), file size <25MB, internet connection
- **Post:** Returns transcribed text, saves to conversation history
- **Errors:** Throws `whisperAPITimeout` if >10s, `transcriptionFailed` if Whisper errors

**VoiceService.speak():**
- **Pre:** TTS enabled in settings, valid text string
- **Post:** Audio playing through device speakers/headphones
- **Errors:** Throws `playbackFailed` if AVSpeechSynthesizer unavailable

---

## 10. UI Components to Create/Modify

### New Files

**Views/AI/VoiceInputView.swift**
- Voice recording interface with push-to-talk button
- Live audio waveform visualization (AVAudioRecorder metering)
- Visual states: idle, recording, transcribing, error
- Floating microphone button with animation

**Views/AI/VoicePlaybackView.swift**
- TTS playback controls (pause, resume, stop, speed)
- Text highlighting synchronized with speech
- Progress indicator showing playback position
- Waveform visualization during playback

**Views/AI/AudioWaveformView.swift**
- Reusable waveform visualization component
- Real-time audio level display (0-100 bars)
- Animated bars scaling with volume

**ViewModels/VoiceInputViewModel.swift**
- Manages recording state (idle, recording, transcribing, error)
- Coordinates VoiceService and AIService
- Handles permission requests and error states
- Publishes audio levels for waveform

**ViewModels/VoicePlaybackViewModel.swift**
- Manages TTS playback state (playing, paused, stopped)
- Tracks playback progress for text highlighting
- Handles speed adjustment and background audio

**Services/VoiceService.swift**
- Audio recording using AVAudioRecorder
- TTS playback using AVSpeechSynthesizer
- Microphone permission handling
- Audio session management (handles interruptions)

**Models/VoicePreferences.swift**
- User settings for voice features
- TTS rate, auto-conversation mode, background audio

### Modified Files

**Views/AI/AIAssistantView.swift**
- Add microphone button to input area (replaces keyboard icon when in voice mode)
- Integrate VoiceInputView as bottom sheet
- Add voice/text mode toggle in top bar
- Show "Speaking..." indicator during TTS playback

**ViewModels/AIAssistantViewModel.swift**
- Add `isVoiceMode: Bool` state
- Handle voice input flow (record → transcribe → AI response → TTS)
- Coordinate with VoiceInputViewModel

**Services/AIService.swift**
- Add `transcribeAudio(audioURL:)` method calling Cloud Function
- Add `processVoiceMessage(audioURL:)` combining transcription + chat
- Extend existing `chatWithAI()` to accept `inputMethod` parameter

**Views/Settings/SettingsView.swift**
- Add "Voice Settings" section with:
  - TTS enabled toggle
  - TTS speed slider (0.5x-2.0x)
  - Auto conversation mode toggle
  - Background audio toggle
  - Test voice button (speaks sample text)

---

## 11. Integration Points

**OpenAI Whisper API:**
- Endpoint: `POST https://api.openai.com/v1/audio/transcriptions`
- Authentication: OpenAI API key (server-side only)
- Request: Multipart form-data with audio file (M4A/WAV)
- Response: `{ "text": "transcribed text" }`
- Rate limits: 50 requests/minute (check OpenAI tier)

**iOS AVFoundation (AVAudioRecorder):**
- Audio format: M4A (AAC), 16kHz sample rate, mono channel
- Audio session category: `playAndRecord` (allows simultaneous play/record)
- Audio interruptions: Handle phone calls, alarms, other app audio

**iOS AVFoundation (AVSpeechSynthesizer):**
- Voice: iOS system voice (English US default)
- Rate: Adjustable 0.5x-2.0x via `AVSpeechUtterance.rate`
- Background audio: Enable via `AVAudioSession.setCategory(.playback)`

**Firebase Cloud Storage:**
- Upload audio recordings to `/users/{userId}/voice_recordings/`
- Auto-delete after 30 days via Cloud Storage lifecycle rule
- Download URLs passed to Cloud Function for transcription

**Existing AI Infrastructure:**
- Voice transcriptions feed into existing `chatWithAI()` function
- RAG search works identically for voice vs text input
- Function calling (schedule, remind) triggered same way

**State Management:**
- SwiftUI `@StateObject` for ViewModels
- Combine publishers for real-time audio levels
- `@EnvironmentObject` for shared AIService, VoiceService

---

## 12. Testing Plan & Acceptance Gates

### Happy Path
- [ ] **Flow:** Trainer taps mic → speaks "What did Sarah say about her knee?" → releases button → sees transcription → hears AI response
- [ ] **Gate:** Entire flow completes in <5 seconds from button release to TTS start
- [ ] **Pass:** Transcription accurate (matches spoken words), AI response contextually relevant (RAG search works), TTS plays clearly

### Edge Cases

**Edge Case 1: Very Short Audio (<1 second)**
- **Test:** Tap mic, say "Hi", release immediately
- **Expected:** Transcription still works, shows "Hi" in chat, AI responds normally
- **Pass:** No crashes, minimum audio duration handled (>0.5s), or shows "Audio too short, try again"

**Edge Case 2: Very Long Audio (>2 minutes)**
- **Test:** Record audio for 3+ minutes (long rambling question)
- **Expected:** Recording auto-stops at 2-minute mark, shows "Max recording length reached"
- **Pass:** Audio trimmed to 2 minutes, transcription processes truncated audio, no crash

**Edge Case 3: Background Noise (Gym Environment)**
- **Test:** Record audio with loud background music/talking
- **Expected:** Whisper API transcribes with lower accuracy, possibly includes noise words
- **Pass:** System doesn't crash, shows transcription (even if imperfect), user can retry or switch to text

**Edge Case 4: Rapid Conversation (Multiple Quick Exchanges)**
- **Test:** Ask question, get response, immediately ask follow-up before TTS finishes
- **Expected:** TTS stops mid-sentence, mic activates for new recording
- **Pass:** No audio overlap, smooth transition, conversation history preserved

**Edge Case 5: Switching Between Voice and Text Mid-Conversation**
- **Test:** Start with voice question, then type text response, then back to voice
- **Expected:** Conversation flows naturally, both input methods save to same conversation
- **Pass:** No conversation reset, history shows mixed voice/text messages

### Error Handling

**Offline Mode:**
- **Test:** Enable airplane mode → attempt voice recording → release button
- **Expected:** Shows "No internet connection. Voice requires internet for transcription."
- **Pass:** Audio saved locally, option to retry when online or switch to text input

**Microphone Permission Denied:**
- **Test:** First launch, deny microphone permission → tap voice button
- **Expected:** Alert: "Psst needs microphone access for voice chat. Open Settings?" with [Cancel] [Settings] buttons
- **Pass:** Tapping Settings opens iOS Settings app to Psst permissions, denying shows fallback text input

**Whisper API Timeout:**
- **Test:** Send audio during API outage or slow network (simulate 30s timeout)
- **Expected:** Spinner shows for 10s max, then "Transcription taking too long. Try again?"
- **Pass:** Timeout handled gracefully, retry button works, option to view/edit raw audio

**TTS Unavailable (iOS Bug or Resource Constraint):**
- **Test:** Trigger AVSpeechSynthesizer failure (simulate by force-stopping audio engine)
- **Expected:** AI response appears as text with notice: "Audio playback unavailable. Showing text instead."
- **Pass:** User can still read response, no crash, playback icon hidden

**Audio Session Interrupted (Phone Call):**
- **Test:** Start voice recording → receive phone call → answer call → hang up
- **Expected:** Recording auto-stops when call arrives, shows "Recording interrupted" message
- **Pass:** No crash, user can restart recording after call, audio session properly restored

**Concurrent Audio (Music Playing):**
- **Test:** Play music in Apple Music → open Psst → start voice recording
- **Expected:** Music pauses/ducks, recording captures voice only
- **Pass:** Audio session category `playAndRecord` handles mixing, music resumes after recording

### Multi-Device Testing
**Not applicable** - Voice is local device feature only (no sync required)

### Performance Check

**Subjective:**
- [ ] Voice recording feels instant (<50ms latency from tap to waveform)
- [ ] TTS voice sounds natural (not robotic)
- [ ] Waveform animations smooth (60fps)
- [ ] No audio glitches or crackling during playback

**Measured:**
- [ ] Transcription time for 30s audio: <3 seconds
- [ ] TTS playback start latency: <500ms from response received
- [ ] Total round-trip (speak → hear response): <5 seconds for typical question
- [ ] Audio file upload time: <1 second for 30s M4A file

---

## 13. Definition of Done

**Service Layer:**
- [ ] VoiceService.swift implemented with recording, playback, permissions
- [ ] AIService.transcribeAudio() integrated with Whisper API
- [ ] Cloud Function `transcribeAudio` deployed and tested
- [ ] All service methods have proper error handling (try/catch, async/await)

**UI Components:**
- [ ] VoiceInputView with push-to-talk and waveform visualization
- [ ] VoicePlaybackView with pause/resume/speed controls
- [ ] AudioWaveformView reusable component
- [ ] AIAssistantView modified with voice mode toggle
- [ ] Settings page with voice preferences

**State Management:**
- [ ] VoiceInputViewModel manages recording states
- [ ] VoicePlaybackViewModel manages TTS states
- [ ] All states (idle, recording, transcribing, speaking, error) handled

**Testing:**
- [ ] All acceptance gates pass (happy path, edge cases, errors)
- [ ] Manual testing completed on physical device (simulators don't support mic well)
- [ ] Tested with AirPods, car Bluetooth, and device speaker
- [ ] Background audio mode verified (works when app backgrounded)

**Documentation:**
- [ ] Inline comments for AVAudioRecorder setup
- [ ] Voice settings documented in README
- [ ] Known limitations documented (requires internet, English only)

**Performance:**
- [ ] Transcription <3s for 30s audio verified
- [ ] TTS latency <500ms verified
- [ ] No memory leaks in audio recording (Instruments checked)

---

## 14. Risks & Mitigations

**Risk: Whisper API costs escalate with heavy usage**
- Mitigation: Monitor API usage via OpenAI dashboard, implement client-side caching for repeated questions, set monthly budget alerts

**Risk: Poor transcription accuracy in noisy environments**
- Mitigation: Use Whisper's `large-v3` model for better noise handling, show confidence scores to user, allow manual correction of transcription

**Risk: TTS voice sounds robotic or unnatural**
- Mitigation: Use iOS premium voices if available, allow users to choose voice in settings, provide speed adjustment for clarity

**Risk: Audio session conflicts with other apps (music, podcasts)**
- Mitigation: Properly configure AVAudioSession categories, duck background audio during recording, restore audio after playback

**Risk: Battery drain from continuous audio processing**
- Mitigation: Auto-stop recording after 2 minutes max, disable auto-conversation mode by default, optimize audio encoding (AAC vs WAV)

**Risk: Microphone permission denial blocks entire feature**
- Mitigation: Show clear permission request explanation, provide deep link to Settings, maintain text input as fallback

---

## 15. Rollout & Telemetry

**Feature Flag:** No (always on for users who grant mic permission)

**Metrics to Track:**
- Voice usage rate: % of AI conversations using voice vs text
- Transcription accuracy: Manual review of 100 sample transcriptions
- Error rate: Transcription failures, TTS failures, permission denials
- Average round-trip time: Speak → hear response
- User retention: Do trainers keep using voice after first try?

**Manual Validation Steps:**
1. Test on physical iPhone (not simulator) with microphone
2. Test with different audio sources: AirPods, Bluetooth car, speaker
3. Test in noisy environment (gym simulation)
4. Test background audio mode (lock phone during TTS playback)
5. Verify Whisper API costs align with projections (check OpenAI billing)

---

## 16. Open Questions

**Q1:** Should we support multiple languages or English-only for MVP?
- **Decision needed:** Check Whisper API language support, prioritize based on user base

**Q2:** Should we save audio recordings permanently or auto-delete?
- **Proposal:** Auto-delete after 30 days for storage cost management

**Q3:** Should TTS be interruptible mid-sentence?
- **Proposal:** Yes - allow users to tap mic to interrupt and ask follow-up

**Q4:** Do we need wake word detection ("Hey Psst")?
- **Proposal:** Defer to Phase 5 - manual tap activation is simpler for MVP

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future enhancements:

- [ ] **Wake word detection** - "Hey Psst" hands-free activation
- [ ] **Voice message history playback** - Replay original audio recordings
- [ ] **Multi-language support** - Spanish, French transcription
- [ ] **Custom TTS voices** - Celebrity voices, trainer-recorded samples
- [ ] **Voice notes to clients** - Send voice messages in regular chats
- [ ] **Real-time streaming transcription** - Show words as spoken (WebSocket)
- [ ] **Voice biometrics** - Identify trainer by voice for security
- [ ] **Noise cancellation** - AI-powered background noise filtering

---

## Preflight Questionnaire

1. **Smallest end-to-end user outcome for this PR?**
   - Trainer speaks question → AI answers with voice

2. **Primary user and critical action?**
   - Trainer on-the-go → Tap mic, speak, hear response

3. **Must-have vs nice-to-have?**
   - Must: Recording, transcription, TTS playback
   - Nice: Speed control, auto-conversation mode, background audio

4. **Real-time requirements?**
   - No multi-device sync (local audio only)
   - Target <5s total round-trip time

5. **Performance constraints?**
   - Transcription: <3s for 30s audio
   - TTS latency: <500ms to start playback
   - Recording activation: <50ms tap response

6. **Error/edge cases to handle?**
   - Permission denial, API timeout, offline mode, concurrent audio, interruptions

7. **Data model changes?**
   - Add optional fields to `/ai_conversations/messages`: `inputMethod`, `audioURL`
   - Local VoicePreferences in UserDefaults

8. **Service APIs required?**
   - VoiceService (recording, playback, permissions)
   - AIService.transcribeAudio() (Whisper API)
   - Cloud Function: transcribeAudio

9. **UI entry points and states?**
   - Entry: Microphone button in AIAssistantView
   - States: Idle, recording, transcribing, thinking, speaking, error

10. **Security/permissions implications?**
    - Microphone permission required (iOS Privacy - Microphone Usage Description)
    - Audio files temporarily stored in Cloud Storage (auto-delete 30 days)

11. **Dependencies or blocking integrations?**
    - Depends: PR #004 (AI Chat UI - base interface)
    - Depends: PR #003 (AI Chat Backend - chatWithAI function)
    - New: OpenAI Whisper API integration

12. **Rollout strategy and metrics?**
    - No feature flag (always available if mic permission granted)
    - Track: Voice usage rate, transcription accuracy, error rate, round-trip time

13. **What is explicitly out of scope?**
    - Voice messages to clients (only AI assistant)
    - Wake word detection
    - Multi-language support (English only)
    - Custom voices

---

## Authoring Notes

- Write Test Plan before coding (✅ Completed above)
- Favor vertical slice that ships standalone (✅ Voice input → TTS output is complete flow)
- Keep service layer deterministic (✅ VoiceService has clear inputs/outputs)
- SwiftUI views are thin wrappers (✅ ViewModels handle business logic)
- Test offline/online thoroughly (✅ Covered in error handling tests)
- Reference `Psst/agents/shared-standards.md` throughout (✅ Performance targets aligned)

---

**Document Status:** ✅ Ready for Caleb to implement
**Next Steps:** Create TODO, then `/caleb 011` to begin implementation
