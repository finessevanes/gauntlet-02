# PR-018 TODO — Voice-First AI Coach Workflow

**Branch**: `feat/pr-18-voice-first-workflow`
**Source PRD**: `Psst/docs/prds/pr-018-prd.md`
**Owner (Agent)**: Caleb

---

## 0. Clarifying Questions & Assumptions

- Questions: None (PRD is comprehensive)
- Assumptions (confirm in PR if needed):
  - PR #011 (Voice AI Interface) is fully complete and functional
  - Existing VoiceService handles recording, transcription, and TTS
  - Auto-send delay of 1-2 seconds is acceptable for user review
  - Settings toggle for voice-first preference is Phase 5 enhancement (not this PR)

---

## 1. Setup

- [ ] Create branch `feat/pr-18-voice-first-workflow` from develop
- [ ] Read PRD thoroughly at `Psst/docs/prds/pr-018-prd.md`
- [ ] Read `Psst/agents/shared-standards.md` for patterns
- [ ] Confirm environment and test runner work
- [ ] Verify PR #011 (Voice AI Interface) is merged and functional

---

## 2. Service Layer

No new services required - leveraging existing:
- `VoiceService` - Already handles recording, transcription, TTS
- `AIService` - Already handles AI chat

### Updates to Existing Services

- [ ] Update `VoiceSettings.swift` - Set `autoSendAfterTranscription = true` by default
  - Test Gate: New settings load with auto-send enabled
- [ ] Add `autoSpeakConfirmations` property to `VoiceSettings.swift` (default: true)
  - Test Gate: Setting persists across app restarts

---

## 3. Data Model & Rules

No new data models required - using existing:
- `VoiceRecording` (from PR #011)
- `VoiceSettings` (modified defaults only)
- `AIMessage` (no changes)
- `AIConversation` (no changes)

---

## 4. UI Components

Create/modify SwiftUI views per PRD Section 10.

### New Components

- [ ] Create `VoiceFirstEmptyStateView.swift`
  - Large recording button (120pt × 120pt minimum)
  - Centered vertically and horizontally
  - Blue color (brand primary) when idle
  - Microphone icon (SF Symbol: `mic.circle.fill`)
  - "Tap to Record" label below button
  - Test Gate: SwiftUI Preview renders; zero console errors

- [ ] Add recording states to `VoiceFirstEmptyStateView.swift`
  - Idle: Blue, microphone icon, "Tap to Record"
  - Recording: Red, waveform icon (`waveform.circle.fill`), "Recording...", timer
  - Transcribing: Spinner, "Transcribing..."
  - Test Gate: All states render correctly in preview

- [ ] Add waveform visualization to `VoiceFirstEmptyStateView.swift`
  - Real-time audio level visualization during recording
  - Below recording button
  - Animated in sync with audio levels
  - Test Gate: Waveform animates when recording

- [ ] Add "or type" toggle link to `VoiceFirstEmptyStateView.swift`
  - Small link at bottom
  - Toggles to text input mode
  - Test Gate: Tap link → Text input appears, recording button moves to toolbar

- [ ] Create `ThinkingStateView.swift`
  - Large animated spinner or pulsing dots
  - "Thinking..." or "Processing your request..." text
  - Smooth, calming animation (not jarring)
  - Replaces recording button area during AI processing
  - Test Gate: SwiftUI Preview renders; smooth animation

### Modified Components

- [ ] Modify `AIAssistantView.swift` - Replace empty state
  - Replace suggestion cards with `VoiceFirstEmptyStateView`
  - Test Gate: Open AI Coach → Large recording button visible, no text input

- [ ] Modify `AIAssistantView.swift` - Hide text input initially
  - Text input field hidden in empty state
  - Show text input after first voice interaction completes
  - Test Gate: Empty state → No text input → Record voice → Text input appears

- [ ] Modify `AIAssistantView.swift` - Integrate ThinkingStateView
  - Show `ThinkingStateView` during AI processing
  - Replace recording button area with thinking indicator
  - Test Gate: Send message → Thinking indicator appears → AI responds → Indicator hides

- [ ] Modify `AIAssistantViewModel.swift` - Auto-send logic
  - When transcription completes, automatically send to AI
  - No manual "Send" button tap required
  - Respect `VoiceSettings.autoSendAfterTranscription` setting
  - Test Gate: Record voice → Stop → Transcription appears → Message sent automatically

- [ ] Modify `AIAssistantViewModel.swift` - Add `isConfirmationMessage()` method
  - Check if AI response contains confirmation keywords
  - Keywords: "scheduled", "created", "removed", "updated", "confirmed"
  - Return true if confirmation, false otherwise
  - Test Gate: Unit test passes for confirmation/non-confirmation messages

- [ ] Modify `AIAssistantViewModel.swift` - Auto-speak confirmations
  - When AI response is a confirmation, automatically speak it
  - Use `VoiceService.speak()` immediately after AI response received
  - Respect `VoiceSettings.autoSpeakConfirmations` setting
  - Test Gate: AI responds with confirmation → TTS begins automatically within 500ms

---

## 5. Integration & Real-Time

Reference requirements from `Psst/agents/shared-standards.md`.

- [ ] Verify VoiceService integration
  - Recording, transcription, TTS working (from PR #011)
  - Test Gate: Record audio → Transcription succeeds → TTS plays

- [ ] Verify AIService integration
  - AI chat responses working
  - Test Gate: Send message → AI responds within expected time

- [ ] Verify auto-send triggers AI processing
  - Transcription → Auto-send → AI response flow
  - Test Gate: Complete voice workflow end-to-end

---

## 6. User-Centric Testing

**Test 3 scenarios before marking complete** (see `Psst/agents/shared-standards.md`):

### Happy Path

- [ ] Voice-first workflow end-to-end
  - **Test Gate:** Open AI Coach → Large recording button visible, no text input
  - **Test Gate:** Tap recording button → Button turns red, waveform appears, "Recording..." shown
  - **Test Gate:** Speak: "Schedule a call with Pam tomorrow at 6am"
  - **Test Gate:** Tap button again → Recording stops, "Transcribing..." shown
  - **Test Gate:** Transcription completes → Transcribed text appears, message sent automatically
  - **Test Gate:** AI processing → "Thinking..." indicator appears prominently
  - **Test Gate:** AI responds → Message appears: "Your call with Pam has been scheduled tomorrow at 6am"
  - **Test Gate:** TTS begins automatically, user hears confirmation
  - **Pass:** End-to-end voice workflow complete in < 8 seconds

### Edge Cases

- [ ] Edge Case 1: User prefers text input
  - **Test Gate:** Open AI Coach → Tap "or type" link
  - **Expected:** Text input appears, recording button moves to toolbar (existing behavior)
  - **Pass:** Text-first option available, no workflow broken

- [ ] Edge Case 2: Very short recording (< 1 second)
  - **Test Gate:** Tap button → Immediately stop
  - **Expected:** "Recording too short. Please try again" message
  - **Pass:** Graceful error, can retry, no crash

- [ ] Edge Case 3: User edits transcription before sending
  - **Test Gate:** Transcription appears → User edits text → Sends
  - **Expected:** Edited text sent to AI, not original transcription
  - **Pass:** Text editing works, auto-send respects manual edits

- [ ] Edge Case 4: AI response is a question (not confirmation)
  - **Test Gate:** Ask "What did Sarah say?" → AI responds with question
  - **Expected:** Text response shown, optional auto-speak (per setting), not forced
  - **Pass:** Only confirmations auto-speak, questions optional

### Error Handling

- [ ] Error 1: Transcription fails
  - **Test Gate:** Record audio → Transcription API fails
  - **Expected:** "Transcription failed. Try again?" with retry button
  - **Pass:** Clear error, retry option, no crash

- [ ] Error 2: Auto-send fails (network error)
  - **Test Gate:** Transcription succeeds → Auto-send fails (no internet)
  - **Expected:** Message queued, retry when online, "Sending..." indicator
  - **Pass:** Graceful offline handling, eventual success

- [ ] Error 3: TTS fails (audio unavailable)
  - **Test Gate:** AI responds with confirmation → TTS fails
  - **Expected:** Text response still shown, no audio, no crash
  - **Pass:** TTS failure doesn't break workflow, text confirmation works

### Final Checks

- [ ] No console errors during all test scenarios
- [ ] Feature feels responsive (subjective - no noticeable lag)
- [ ] Voice-first workflow feels natural and intuitive

---

## 7. Performance

Verify targets from `Psst/agents/shared-standards.md` and PRD Section 4.

- [ ] Empty state → Recording button visible: < 100ms
  - Test Gate: Cold start to button visible measured

- [ ] Tap button → Recording starts: < 50ms
  - Test Gate: Tap to visual feedback measured (button turns red)

- [ ] Stop recording → Transcription begins: < 100ms
  - Test Gate: Stop tap to "Transcribing..." text measured

- [ ] Transcription → Auto-send: < 500ms
  - Test Gate: Transcription complete to message sent measured

- [ ] AI response → Auto-speak: < 500ms
  - Test Gate: AI response received to TTS playback start measured

**If performance issues:**
- [ ] Optimize empty state rendering (lazy load if needed)
- [ ] Pre-load TTS synthesizer to reduce first-playback delay
- [ ] Cache transcription results for retry scenarios

---

## 8. Acceptance Gates

Check every gate from PRD Section 12:

### Happy Path Gates
- [ ] Open AI Coach → Large recording button visible, no text input (REQ-1)
- [ ] Tap recording button → Button turns red, waveform appears, "Recording..." shown
- [ ] Speak request → Audio captured
- [ ] Tap button again → Recording stops, "Transcribing..." shown
- [ ] Transcription completes → Transcribed text appears, message sent automatically (REQ-4)
- [ ] AI processing → "Thinking..." indicator appears prominently (REQ-7)
- [ ] AI responds → Message appears with confirmation text
- [ ] TTS begins automatically within 500ms (REQ-5)
- [ ] End-to-end voice workflow complete in < 8 seconds

### Edge Case Gates
- [ ] Tap "or type" → Text input appears, recording button moves to toolbar (REQ-3)
- [ ] Very short recording → Graceful error, retry option
- [ ] User edits transcription → Edited text sent correctly
- [ ] AI question response → Optional auto-speak (not forced) (REQ-6)

### Error Handling Gates
- [ ] Transcription fails → Clear error, retry option, no crash
- [ ] Auto-send fails → Message queued, retry when online
- [ ] TTS fails → Text response shown, no crash

### Performance Gates
- [ ] Empty state → Button visible < 100ms
- [ ] Tap button → Recording starts < 50ms
- [ ] AI response → Auto-speak < 500ms

### Small Screen Gate
- [ ] iPhone SE → Recording button size adapts, no layout issues

---

## 9. Documentation & PR

- [ ] Add inline code comments for complex logic
  - `isConfirmationMessage()` method
  - Auto-send trigger logic
  - Auto-speak confirmation logic
  - State transitions in VoiceFirstEmptyStateView

- [ ] Update README if needed (voice-first workflow documentation)

- [ ] Create PR description (use format from Psst/agents/caleb-agent.md)
  - Title: "feat(pr-018): Voice-First AI Coach Workflow Redesign"
  - Summary: Voice-first UX enhancement with auto-send and auto-speak
  - Changes: New components, modified views, updated settings
  - Testing: All acceptance gates pass
  - Link to PRD and TODO

- [ ] Verify with user before creating PR

- [ ] Open PR targeting develop branch

- [ ] Link PRD and TODO in PR description

---

## Copyable Checklist (for PR description)

```markdown
## PR-018: Voice-First AI Coach Workflow

### Summary
Redesigned AI Coach to be voice-first by default. Users see a large recording button immediately upon opening, with seamless tap-to-record → speak → auto-send → auto-speak confirmation workflow.

### Changes
- ✅ Created `VoiceFirstEmptyStateView.swift` - Large recording button (120pt, centered)
- ✅ Created `ThinkingStateView.swift` - Enhanced thinking indicator
- ✅ Modified `AIAssistantView.swift` - Voice-first empty state, hidden text input initially
- ✅ Modified `AIAssistantViewModel.swift` - Auto-send, auto-speak confirmations
- ✅ Updated `VoiceSettings.swift` - Default auto-send and auto-speak to true

### Testing Completed
- ✅ All TODO tasks completed
- ✅ Happy path: End-to-end voice workflow (< 8 seconds)
- ✅ Edge cases: Text preference, short recording, transcription editing, question responses
- ✅ Error handling: Transcription failures, network errors, TTS failures
- ✅ Performance gates: < 100ms, < 50ms, < 500ms
- ✅ Small screen (iPhone SE): Button adapts correctly
- ✅ All acceptance gates pass (REQ-1 through REQ-10)
- ✅ Code follows Psst/agents/shared-standards.md patterns
- ✅ No console warnings or errors
- ✅ Documentation updated (inline comments)

### Links
- PRD: `Psst/docs/prds/pr-018-prd.md`
- TODO: `Psst/docs/todos/pr-018-todo.md`
- Dependencies: PR #011 (Voice AI Interface)
```

---

## Notes

- Break tasks into <30 min chunks
- Complete tasks sequentially
- Check off after completion
- Document blockers immediately
- Reference `Psst/agents/shared-standards.md` for common patterns and solutions
- PR #011 (Voice AI Interface) must be fully functional before starting
- Focus on UX smoothness - voice-first should feel natural, not forced
- Test on iPhone SE to ensure button size adapts correctly
- Auto-speak should enhance, not interrupt - only for confirmations initially
