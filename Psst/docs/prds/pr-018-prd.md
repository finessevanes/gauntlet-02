# PRD: Voice-First AI Coach Workflow

**Feature**: Voice-First AI Coach Workflow Redesign

**Version**: 1.0

**Status**: Ready for Development

**Agent**: Auto

**Target Release**: Phase 4 (Enhancement to PR #011)

**Dependencies**:
- PR #011 (Voice AI Interface - REQUIRED - Voice recording, transcription, TTS already implemented)

**Links**: [PR Brief: ai-briefs.md#pr-018](../ai-briefs.md), [TODO](../todos/pr-018-todo.md)

---

## 1. Summary

Redesign the AI Coach interface to be voice-first by default. When users open the AI Assistant, they immediately see a large, prominent recording button instead of text input. The workflow prioritizes voice interaction: tap to record → speak request → tap to stop → thinking state → AI speaks confirmation. This creates a natural, hands-free conversation flow where the AI confirms actions through voice, making the experience feel like talking to a real assistant.

---

## 2. Problem & Goals

**Problem:** 
Currently, the AI Coach uses a text-first interface. Users land on an empty state with suggestion cards, and must tap a small microphone button or type to interact. This creates friction for voice-first use cases (driving, walking between sessions, hands-free operation). The voice feature exists (PR #011) but is secondary—users must discover and activate it.

**Why Now:**
PR #011 (Voice AI Interface) provides the foundation (recording, transcription, TTS), but the UX still prioritizes typing. To unlock true hands-free AI assistance, we need to flip the mental model: voice is the primary interaction, text is secondary.

**Goals:**
- [ ] G1 — Users see a large recording button immediately upon opening AI Coach (no text input visible initially)
- [ ] G2 — Voice workflow is seamless: record → stop → thinking → confirmation (no manual "send" step)
- [ ] G3 — AI automatically speaks confirmations after actions complete (no user tap required)
- [ ] G4 — Text input remains available but hidden until needed (after first voice interaction or user preference)

---

## 3. Non-Goals / Out of Scope

- [ ] **NOT changing** the underlying voice recording/transcription/TTS logic (PR #011 already handles this)
- [ ] **NOT implementing** wake word detection ("Hey Psst") → Future Phase 5 enhancement
- [ ] **NOT removing** text input entirely → Text remains available as fallback/alternative
- [ ] **NOT changing** the AI response logic → Same AI service, just different entry point
- [ ] **NOT implementing** continuous conversation mode → Tap-to-start/tap-to-stop only

---

## 4. Success Metrics

**User-visible:**
- Time to first interaction: < 1 second (tap button → recording starts)
- Voice workflow completion: < 8 seconds (record → transcribe → process → confirm)
- Voice-first adoption: > 70% of AI Coach interactions via voice (within 2 weeks)
- Confirmation clarity: Users hear AI confirmation without reading screen

**System:**
- Auto-send after transcription: 100% (no manual "send" button tap required)
- Auto-speak AI responses: 100% (when action completes)
- Empty state → recording button transition: < 100ms (instant visual feedback)

**Quality:**
- 0 crashes during voice-first workflow
- All acceptance gates pass
- User satisfaction: Voice-first feels natural and intuitive

---

## 5. Users & Stories

**User: Alex (Trainer)**

1. **As a trainer opening AI Coach**, I want to immediately see a large recording button **so that** I know voice is the primary way to interact, not text.

2. **As a trainer walking between sessions**, I want to tap record, speak "Schedule a call with Pam tomorrow at 6am", and tap stop **so that** I can manage my calendar hands-free without typing.

3. **As a trainer after speaking a request**, I want to see the AI "thinking" (processing state) **so that** I know my request is being handled and not lost.

4. **As a trainer after the AI schedules an event**, I want to hear "Your call with Pam has been scheduled tomorrow at 6am" spoken aloud **so that** I get confirmation without looking at the screen.

5. **As a trainer who prefers typing**, I want to access text input after my first voice interaction **so that** I can still use text when needed (voice-first, not voice-only).

---

## 6. Experience Specification (UX)

### Entry Point & Initial State

**When user opens AI Coach (empty conversation):**

1. **Full-screen recording button** (large, prominent, centered)
   - Size: 120pt × 120pt minimum (touch-friendly, impossible to miss)
   - Color: Blue (primary brand color) when idle
   - Icon: Microphone icon (large, SF Symbol: `mic.circle.fill`)
   - Text below: "Tap to Record"
   - No text input field visible
   - No suggestion cards visible

2. **Visual hierarchy:**
   - Recording button: 60% of screen height (centered vertically)
   - "Tap to Record" label: Below button (16pt, secondary color)
   - Optional: Small "or type" link at bottom (toggles to text input)

### Voice Recording Flow

**Step 1: User taps recording button**
- Button turns **red** (recording state)
- Icon changes to `waveform.circle.fill` (animated pulse)
- Waveform visualization appears below button (real-time audio levels)
- Timer appears: "0:00" (counts up)
- "Recording..." text replaces "Tap to Record"
- Button remains tappable (tap again to stop)

**Step 2: User speaks request**
- Example: "Schedule a call with Pam tomorrow at 6am"
- Waveform animates in real-time (visual feedback)
- Timer counts up (max 60 seconds)
- No keyboard visible, no text input

**Step 3: User taps button again (stop recording)**
- Recording stops immediately
- Button shows spinner/loading state
- "Transcribing..." text appears
- Waveform disappears
- Timer freezes

**Step 4: Transcription completes**
- Transcribed text appears in message bubble (user message)
- Text input field appears (for editing if needed)
- Auto-send triggers immediately (if `autoSendAfterTranscription` enabled)
- If manual send required: Send button appears

### Processing State ("Thinking")

**After transcription → Auto-send → AI processing:**

1. **Thinking indicator replaces recording button area**
   - Large animated spinner (or pulsing dots)
   - "Thinking..." text (or "Processing your request...")
   - Visual indicates AI is working (not frozen, not error)

2. **Message bubble appears:**
   - User's transcribed request shown as message
   - AI loading indicator below (existing `AILoadingIndicator` component)

### AI Response & Confirmation

**When AI completes action:**

1. **AI message appears** (text response)
   - Example: "Your call with Pam has been scheduled tomorrow at 6am"
   - Message bubble shows confirmation

2. **Automatic text-to-speech begins**
   - No user tap required
   - AI speaks the confirmation aloud
   - Speaker icon appears next to message (animated sound waves)
   - User hears: "Your call with Pam has been scheduled tomorrow at 6am"

3. **After confirmation:**
   - Text input field remains visible (for follow-up questions)
   - Recording button available (smaller, in input bar)
   - Voice-first workflow complete, ready for next interaction

### Visual States Summary

**Empty State (First Time):**
- Large recording button (120pt, blue, centered)
- "Tap to Record" label
- No text input, no suggestions

**Recording:**
- Button: Red, pulsing, waveform icon
- Waveform visualization (animated)
- Timer counting up
- "Recording..." text

**Transcribing:**
- Button: Spinner/loading state
- "Transcribing..." text
- No waveform

**Thinking/Processing:**
- Large animated indicator (spinner or dots)
- "Thinking..." text
- User message visible
- AI loading indicator

**Confirmation:**
- AI message visible
- TTS playing automatically
- Speaker icon animated
- Text input available for follow-up

---

## 7. Functional Requirements (Must/Should)

### Empty State Redesign

**MUST:**
- **REQ-1**: Replace suggestion cards with large recording button
  - Button size: Minimum 120pt × 120pt (touch-friendly)
  - Centered vertically and horizontally
  - Blue color (brand primary)
  - Microphone icon (SF Symbol: `mic.circle.fill`)
  - [Gate] Open AI Coach → Large recording button visible, no text input

- **REQ-2**: Hide text input initially
  - Text input field hidden in empty state
  - Input field appears after first voice interaction
  - [Gate] Empty state → No text input visible → Record voice → Text input appears

**SHOULD:**
- **REQ-3**: Show "or type" toggle option
  - Small link at bottom: "or type" → Toggles to text input mode
  - Allows users to switch to text-first if preferred
  - [Gate] Tap "or type" → Text input appears, recording button moves to toolbar

### Voice Workflow Automation

**MUST:**
- **REQ-4**: Auto-send after transcription
  - When transcription completes, automatically send to AI
  - No manual "Send" button tap required
  - Ensure `VoiceSettings.load().autoSendAfterTranscription = true` by default
  - [Gate] Record voice → Stop → Transcription appears → Message sent automatically

- **REQ-5**: Auto-speak AI confirmations
  - When AI response contains action confirmation, automatically speak it
  - Use `VoiceService.speak()` immediately after AI response received
  - No user tap on speaker icon required for confirmations
  - [Gate] AI responds with confirmation → TTS begins automatically within 500ms

**SHOULD:**
- **REQ-6**: Smart confirmation detection
  - Detect action confirmations vs. regular questions
  - Only auto-speak for confirmations (e.g., "scheduled", "created", "removed")
  - Regular Q&A responses: Optional auto-speak (user preference)
  - [Gate] Schedule event → Auto-speak confirmation → Ask question → Optional speak (setting)

### Thinking State Indicator

**MUST:**
- **REQ-7**: Show prominent "thinking" state
  - Large animated indicator (spinner or pulsing dots)
  - "Thinking..." or "Processing your request..." text
  - Replaces recording button area during processing
  - [Gate] Send message → Thinking indicator appears → AI responds → Indicator hides

**SHOULD:**
- **REQ-8**: Enhanced thinking animation
  - Smooth, calming animation (not jarring)
  - Optional: Pulsing dots, rotating spinner, or gradient animation
  - [Gate] Thinking state → Animation visible, smooth, non-distracting

### Recording Button Enhancement

**MUST:**
- **REQ-9**: Large, prominent recording button
  - Size: 120pt × 120pt minimum
  - Centered in empty state
  - Clear visual states (idle: blue, recording: red, transcribing: spinner)
  - [Gate] Empty state → Large button visible → Tap → Turns red → Recording starts

**SHOULD:**
- **REQ-10**: Waveform visualization during recording
  - Real-time audio level visualization
  - Below recording button
  - Provides visual feedback that recording is active
  - [Gate] Recording → Waveform animates in sync with audio levels

---

## 8. Data Model

### No New Data Models Required

**Leverages Existing Models (PR #011):**
- `VoiceRecording` - Already exists
- `VoiceSettings` - Already exists (extend to ensure `autoSendAfterTranscription = true` by default)
- `AIMessage` - Already exists (no changes)
- `AIConversation` - Already exists (no changes)

### VoiceSettings Extension (Default Behavior)

```swift
// VoiceSettings.swift (MODIFY DEFAULT)
struct VoiceSettings: Codable {
    var voiceResponseEnabled: Bool = true
    var autoSendAfterTranscription: Bool = true  // CHANGE: Default to true
    var autoSpeakConfirmations: Bool = true      // NEW: Auto-speak action confirmations
    var ttsVoice: TTSVoice = .samantha
    var transcriptionLanguage: String = "en-US"
}
```

---

## 9. API / Service Contracts

### No New Service APIs Required

**Leverages Existing Services:**
- `VoiceService` - Already handles recording, transcription, TTS
- `AIService` - Already handles AI chat
- `AIAssistantViewModel` - Already manages state

### Enhanced AIAssistantViewModel Methods

```swift
// AIAssistantViewModel.swift (MODIFY EXISTING METHODS)

/// Send message and auto-speak confirmations
func sendMessage() {
    // ... existing send logic ...
    
    // NEW: Auto-speak AI response if it contains confirmation
    Task {
        let response = await aiService.chatWithAI(...)
        if isConfirmationMessage(response.text) {
            voiceService.speak(text: response.text)
        }
    }
}

/// Check if message is an action confirmation
private func isConfirmationMessage(_ text: String) -> Bool {
    let confirmationKeywords = ["scheduled", "created", "removed", "updated", "confirmed"]
    return confirmationKeywords.contains { text.localizedCaseInsensitiveContains($0) }
}
```

---

## 10. UI Components to Create/Modify

### New Components (2 files)

1. **`VoiceFirstEmptyStateView.swift`** - Large recording button for empty state
   - Replaces suggestion cards
   - Large button (120pt), centered
   - "Tap to Record" label
   - Optional "or type" toggle

2. **`ThinkingStateView.swift`** - Enhanced thinking indicator
   - Large animated spinner/dots
   - "Thinking..." text
   - Smooth, calming animation

### Modified Components (3 files)

1. **`AIAssistantView.swift`** - Main AI Coach view
   - Replace `emptyStateView` with `VoiceFirstEmptyStateView`
   - Hide text input initially (show after first voice interaction)
   - Integrate auto-send and auto-speak logic

2. **`AIAssistantViewModel.swift`** - ViewModel
   - Add `isConfirmationMessage()` method
   - Auto-speak confirmations after AI response
   - Ensure `autoSendAfterTranscription = true` by default

3. **`VoiceSettings.swift`** - Settings model
   - Default `autoSendAfterTranscription = true`
   - Add `autoSpeakConfirmations` setting

---

## 11. Integration Points

### Existing Services (No Changes)

- **VoiceService** - Recording, transcription, TTS (already implemented)
- **AIService** - AI chat responses (already implemented)
- **AVFoundation** - Audio recording/playback (already integrated)
- **OpenAI Whisper API** - Speech-to-text (already integrated)

### Modified Integration Points

- **AIAssistantView → VoiceFirstEmptyStateView** - Replace empty state
- **AIAssistantViewModel → Auto-send** - Trigger send after transcription
- **AIAssistantViewModel → Auto-speak** - Trigger TTS after confirmation responses

---

## 12. Testing Plan & Acceptance Gates

### Happy Path

**Scenario: Voice-first workflow end-to-end**
- [ ] Open AI Coach → **Gate**: Large recording button visible, no text input
- [ ] Tap recording button → **Gate**: Button turns red, waveform appears, "Recording..." shown
- [ ] Speak: "Schedule a call with Pam tomorrow at 6am"
- [ ] Tap button again → **Gate**: Recording stops, "Transcribing..." shown
- [ ] Transcription completes → **Gate**: Transcribed text appears, message sent automatically
- [ ] AI processing → **Gate**: "Thinking..." indicator appears prominently
- [ ] AI responds → **Gate**: Message appears: "Your call with Pam has been scheduled tomorrow at 6am"
- [ ] **Gate**: TTS begins automatically, user hears confirmation
- [ ] **Pass**: End-to-end voice workflow complete in < 8 seconds

**Example Flow:**
1. Open `AIAssistantView`
2. See large blue recording button (centered, 120pt)
3. Tap button → Turns red, waveform animates
4. Speak: "Schedule a call with Pam tomorrow at 6am"
5. Tap button to stop → "Transcribing..." appears
6. Transcription: "Schedule a call with Pam tomorrow at 6am" appears as message
7. Auto-send triggers → "Thinking..." indicator shows
8. AI responds: "Your call with Pam has been scheduled tomorrow at 6am"
9. TTS speaks confirmation automatically
10. Text input appears for follow-up (if needed)

---

### Edge Cases

**Edge Case 1: User prefers text input**
- [ ] **Test**: Open AI Coach → Tap "or type" link
- [ ] **Expected**: Text input appears, recording button moves to toolbar (existing behavior)
- [ ] **Pass**: Text-first option available, no workflow broken

**Edge Case 2: Very short recording (< 1 second)**
- [ ] **Test**: Tap button → Immediately stop
- [ ] **Expected**: "Recording too short. Please try again" message
- [ ] **Pass**: Graceful error, can retry, no crash

**Edge Case 3: User edits transcription before sending**
- [ ] **Test**: Transcription appears → User edits text → Sends
- [ ] **Expected**: Edited text sent to AI, not original transcription
- [ ] **Pass**: Text editing works, auto-send respects manual edits

**Edge Case 4: AI response is a question (not confirmation)**
- [ ] **Test**: Ask "What did Sarah say?" → AI responds with question
- [ ] **Expected**: Text response shown, optional auto-speak (per setting), not forced
- [ ] **Pass**: Only confirmations auto-speak, questions optional

---

### Error Handling

**Transcription fails**
- [ ] **Test**: Record audio → Transcription API fails
- [ ] **Expected**: "Transcription failed. Try again?" with retry button
- [ ] **Pass**: Clear error, retry option, no crash

**Auto-send fails (network error)**
- [ ] **Test**: Transcription succeeds → Auto-send fails (no internet)
- [ ] **Expected**: Message queued, retry when online, "Sending..." indicator
- [ ] **Pass**: Graceful offline handling, eventual success

**TTS fails (audio unavailable)**
- [ ] **Test**: AI responds with confirmation → TTS fails
- [ ] **Expected**: Text response still shown, no audio, no crash
- [ ] **Pass**: TTS failure doesn't break workflow, text confirmation works

---

### Performance Check

- [ ] Empty state → Recording button visible: < 100ms (instant)
- [ ] Tap button → Recording starts: < 50ms (instant feedback)
- [ ] Stop recording → Transcription begins: < 100ms
- [ ] Transcription → Auto-send: < 500ms
- [ ] AI response → Auto-speak: < 500ms

**If performance issues:**
- [ ] Optimize empty state rendering (lazy load if needed)
- [ ] Pre-load TTS synthesizer to reduce first-playback delay
- [ ] Cache transcription results for retry scenarios

---

## 13. Definition of Done

- [ ] `VoiceFirstEmptyStateView.swift` created (large recording button)
- [ ] `ThinkingStateView.swift` created (enhanced thinking indicator)
- [ ] `AIAssistantView.swift` modified (replace empty state, hide text input initially)
- [ ] `AIAssistantViewModel.swift` enhanced (auto-send, auto-speak confirmations)
- [ ] `VoiceSettings.swift` updated (default `autoSendAfterTranscription = true`)
- [ ] Auto-send after transcription working (100% of voice interactions)
- [ ] Auto-speak confirmations working (AI speaks after actions)
- [ ] Thinking state indicator prominent and clear
- [ ] Text input available after first voice interaction
- [ ] All acceptance gates pass (happy path, edge cases, error handling)
- [ ] Voice-first workflow feels natural and intuitive
- [ ] No crashes during voice-first interactions
- [ ] Documentation updated (inline comments, UX flow notes)

---

## 14. Risks & Mitigations

**Risk 1: Users confused by voice-first (expect text input)**
- **Impact**: Medium (users may not discover text input)
- **Mitigation**: Show "or type" toggle link, text input appears after first voice interaction, Settings option to prefer text-first

**Risk 2: Auto-send sends incorrect transcription**
- **Impact**: High (user says wrong thing, transcription wrong, sent automatically)
- **Mitigation**: Show transcribed text before auto-send with 1-2 second delay, allow editing, Settings toggle to disable auto-send

**Risk 3: Auto-speak interrupts user or other audio**
- **Impact**: Low (TTS plays when user doesn't expect it)
- **Mitigation**: Settings toggle for auto-speak, detect if other audio playing (pause or lower volume), allow user to stop TTS

**Risk 4: Thinking state feels slow or unresponsive**
- **Impact**: Medium (users think app is frozen)
- **Mitigation**: Prominent animated indicator, clear "Thinking..." text, show estimated time if possible

**Risk 5: Large recording button doesn't fit on small screens**
- **Impact**: Low (may need responsive sizing)
- **Mitigation**: Use adaptive sizing (120pt minimum, scales down if needed), test on iPhone SE

---

## 15. Rollout & Telemetry

### Feature Flag
- **No feature flag required** - Voice-first is a UX enhancement, not a breaking change
- Text input remains available, users can toggle preference
- A/B testing optional: Compare voice-first vs. text-first adoption

### Metrics to Track
- **Voice-first adoption**: % of AI Coach sessions that start with voice (vs. text)
- **Auto-send usage**: % of voice transcriptions that auto-send (vs. manual send)
- **Auto-speak usage**: % of AI confirmations that auto-speak (vs. silent)
- **Time to first interaction**: Average time from opening AI Coach to first action
- **Voice workflow completion**: % of voice interactions that complete successfully
- **User preference**: % of users who toggle to text-first after trying voice-first

### Manual Validation Steps
1. Open AI Coach → Verify large recording button visible
2. Record voice request → Verify auto-send works
3. Complete action → Verify auto-speak confirmation
4. Check Settings → Verify auto-send/auto-speak toggles work
5. Test on small screen (iPhone SE) → Verify button size adapts

---

## 16. Open Questions

**Q1: Should text input be completely hidden or just minimized?**
- **Decision**: Completely hidden in empty state, appears after first voice interaction. "or type" toggle available for immediate text access.

**Q2: Should auto-speak apply to all AI responses or only confirmations?**
- **Decision**: Auto-speak confirmations (actions), optional for Q&A responses (user setting). Reduces interruption for information-seeking queries.

**Q3: Should we show transcribed text before auto-sending?**
- **Decision**: Yes, show transcription for 1-2 seconds before auto-send, allow editing. Balances speed with accuracy.

**Q4: What if user wants to disable voice-first default?**
- **Decision**: Settings option: "Default to voice-first" toggle (ON by default). Users can switch to text-first preference.

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future:
- [ ] Wake word detection ("Hey Psst" to activate)
- [ ] Continuous conversation mode (no tap-to-stop)
- [ ] Voice command shortcuts (predefined phrases)
- [ ] Multi-turn voice conversations (follow-up questions via voice)
- [ ] Voice-first onboarding tutorial
- [ ] Customizable recording button size/position

---

## Preflight Questionnaire

1. **Smallest end-to-end user outcome for this PR?**
   - Trainer opens AI Coach → Sees large recording button → Taps → Speaks request → Hears confirmation

2. **Primary user and critical action?**
   - Trainers (Alex, Marcus) → Voice-first interaction with AI Coach → Hands-free action confirmation

3. **Must-have vs nice-to-have?**
   - Must: Large recording button in empty state, auto-send after transcription, auto-speak confirmations, thinking state
   - Nice: Waveform visualization, enhanced thinking animation, "or type" toggle

4. **Real-time requirements?**
   - Not applicable (client-side UX enhancement)

5. **Performance constraints?**
   - Empty state → Button visible: < 100ms (instant)
   - Tap button → Recording starts: < 50ms (instant feedback)
   - AI response → Auto-speak: < 500ms

6. **Error/edge cases to handle?**
   - Transcription fails, auto-send fails, TTS fails, very short recording, user prefers text input, small screen sizes

7. **Data model changes?**
   - No new models, only default setting changes (`autoSendAfterTranscription = true`)

8. **Service APIs required?**
   - No new services, leverages existing VoiceService, AIService

9. **UI entry points and states?**
   - Entry: AI Coach empty state → Large recording button
   - States: Idle, Recording, Transcribing, Thinking, Confirmation (with auto-speak)

10. **Security/permissions implications?**
    - No new permissions (microphone already required from PR #011)

11. **Dependencies or blocking integrations?**
    - Depends on PR #011 (Voice AI Interface) - already complete

12. **Rollout strategy and metrics?**
    - Soft launch: Available to all users immediately (UX enhancement)
    - Metrics: Voice-first adoption %, auto-send/auto-speak usage, time to first interaction

13. **What is explicitly out of scope?**
    - Wake word detection, continuous conversation, voice-first onboarding, custom button sizes

---

## Authoring Notes

- This PR enhances PR #011 (Voice AI Interface) by making voice the primary interaction method
- Focus on reducing friction: large button, auto-send, auto-speak, clear thinking state
- Text input remains available but secondary (voice-first, not voice-only)
- Test thoroughly on small screens (iPhone SE) to ensure button size adapts
- Consider user preferences: some users may prefer text, provide toggle option
- Auto-speak should feel natural, not intrusive - only for confirmations initially

