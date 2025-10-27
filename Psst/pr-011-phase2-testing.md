# PR-011 Phase 2: Testing Checklist

**Phase:** Text-to-Speech (TTS)
**Date:** October 26, 2025
**Status:** Ready for Testing
**Prerequisites:** Phase 1 (Core Recording & Transcription) must be complete

---

## ✅ Pre-Test Setup

- [x] **Phase 1 complete** - Recording and transcription working correctly
- [x] **Build succeeds** - No compilation errors
- [x] **AI Assistant functional** - Can send messages and receive AI responses
- [x] **Speaker available** - Device volume turned up to hear TTS
- [ ] **VoiceSettings model exists** - Check `voiceResponseEnabled` property

---

## 🎯 Core Functionality Tests

### Test 1: TTS Auto-Play on AI Response (First Time)

**Steps:**
1. Fresh app install OR clear app data
2. Open AI Assistant
3. Send a text message: "Hello, how are you?"
4. Wait for AI response

**Expected:**
- [ ] AI responds with text (existing functionality works)
- [ ] TTS **automatically begins speaking** within 500ms
- [ ] Audio plays clearly through speaker
- [ ] Text is spoken at normal pace
- [ ] Full message is spoken (not cut off)

**Console Logs Expected:**
```
✅ [ViewModel] AI response received: "Hello! I'm doing well..."
🔊 [ViewModel] Starting TTS for response...
🔊 [VoiceService] speak() called with text length: XX chars
🔊 [VoiceService] Configuring AVSpeechUtterance...
✅ [VoiceService] AVSpeechSynthesizer started speaking
```

**Pass Criteria:** TTS plays automatically, audio is clear and complete

---

### Test 2: Speaker Icon Appears on AI Messages

**Steps:**
1. After Test 1, observe the AI message bubble
2. Look for speaker icon (🔊 or speaker symbol)

**Expected:**
- [ ] Speaker icon visible on **AI message bubble**
- [ ] Icon appears in **top-right or right side** of message
- [ ] Icon is **tappable** (shows touch feedback)
- [ ] **User messages do NOT have speaker icon** (only AI)

**Pass Criteria:** Speaker icon visible only on AI messages, positioned correctly

---

### Test 3: Replay TTS by Tapping Speaker Icon

**Steps:**
1. Wait for TTS from Test 1 to finish completely
2. Tap the **speaker icon** on the AI message
3. Observe behavior

**Expected:**
- [ ] TTS **replays** the message from the beginning
- [ ] Audio plays clearly
- [ ] Full message is spoken again
- [ ] Can tap speaker icon **multiple times** to replay

**Console Logs Expected:**
```
🔊 [ViewModel] Replaying TTS for message: "Hello! I'm doing well..."
🔊 [VoiceService] speak() called with text length: XX chars
✅ [VoiceService] AVSpeechSynthesizer started speaking
```

**Pass Criteria:** Tapping speaker icon replays TTS, can replay multiple times

---

### Test 4: Stop TTS Mid-Playback

**Steps:**
1. Send a longer message to AI: "Tell me a detailed explanation of how protein synthesis works."
2. Wait for AI response (should be long)
3. TTS begins speaking
4. **Tap speaker icon again** while TTS is still speaking

**Expected:**
- [ ] TTS **stops immediately** mid-sentence
- [ ] Audio playback halts
- [ ] Speaker icon remains visible (can tap to replay)
- [ ] No audio glitches or crashes

**Console Logs Expected:**
```
⏹️ [VoiceService] stopSpeaking() called
✅ [VoiceService] AVSpeechSynthesizer stopped
```

**Pass Criteria:** TTS stops cleanly when speaker icon tapped during playback

---

### Test 5: Multiple AI Messages in Sequence

**Steps:**
1. Send message: "Hi"
2. Wait for AI response + TTS
3. Immediately send: "What's the weather?"
4. Wait for second AI response + TTS
5. Send third message: "Thanks"
6. Wait for third response + TTS

**Expected:**
- [ ] Each AI response **auto-plays TTS** in sequence
- [ ] Previous TTS **stops** when new response arrives
- [ ] No overlapping audio (only one TTS at a time)
- [ ] Speaker icons appear on all AI messages

**Console Logs Expected:**
```
🔊 [ViewModel] Starting TTS for response 1...
✅ [VoiceService] Speaking...
⏹️ [VoiceService] Stopping previous TTS (new response arrived)
🔊 [ViewModel] Starting TTS for response 2...
```

**Pass Criteria:** Multiple TTS playbacks don't overlap, previous stops when new starts

---

## 🔊 Audio Quality Tests

### Test 6: Different TTS Voices

**Steps:**
1. Open Settings → Voice Settings
2. Change TTS voice from default to different option (e.g., "Alex", "Fred", "Samantha")
3. Return to AI Assistant
4. Send message and listen to TTS

**Expected:**
- [ ] Voice settings screen exists and is accessible
- [ ] Can select different voice from picker
- [ ] TTS uses **newly selected voice**
- [ ] Voice change persists across app restarts

**Console Logs Expected:**
```
⚙️ [VoiceService] TTS voice changed to: Alex
✅ [VoiceService] Voice settings saved
```

**Pass Criteria:** Voice selection works, different voices sound distinct

---

### Test 7: TTS with Different Message Lengths

Test TTS with various message lengths:

**Test 7a: Very Short Response**
- [ ] Send: "Yes or no?"
- [ ] AI responds: "Yes." (1 word)
- [ ] **Expected:** TTS speaks clearly, doesn't cut off

**Test 7b: Medium Response**
- [ ] Send: "What is protein?"
- [ ] AI responds: ~2-3 sentences
- [ ] **Expected:** TTS speaks entire response smoothly

**Test 7c: Long Response**
- [ ] Send: "Explain photosynthesis in detail"
- [ ] AI responds: Long paragraph (5+ sentences)
- [ ] **Expected:** TTS speaks full response without errors

**Pass Criteria:** TTS works correctly for all message lengths

---

### Test 8: TTS with Special Characters and Punctuation

**Steps:**
1. Send message that triggers AI response with special formatting:
   - Numbers: "What's 2 + 2?"
   - URLs: "Give me a link to OpenAI"
   - Emojis: (AI includes emoji in response)
   - Punctuation: Questions, exclamations, commas

**Expected:**
- [ ] Numbers spoken correctly ("two plus two equals four")
- [ ] URLs either spoken as letters or skipped gracefully
- [ ] Emojis either skipped or described (e.g., "smiley face")
- [ ] Punctuation creates natural pauses

**Pass Criteria:** TTS handles special characters without crashing or sounding unnatural

---

## 🎨 UI/UX Tests

### Test 9: Speaker Icon States

**Steps:**
1. Send message and observe speaker icon during TTS lifecycle

**Expected States:**
- [ ] **Before TTS starts:** Gray speaker icon (idle)
- [ ] **During TTS playback:** Blue/animated speaker icon (speaking)
- [ ] **After TTS completes:** Gray speaker icon (idle, can replay)
- [ ] **While stopped manually:** Gray speaker icon (idle)

**Pass Criteria:** Speaker icon has distinct visual states for idle/speaking

---

### Test 10: Visual Feedback During TTS Playback

**Steps:**
1. Send message with long AI response
2. Observe UI while TTS is speaking

**Expected:**
- [ ] Speaker icon **animates** (pulsing or waveform) while speaking
- [ ] Message bubble remains visible (not hidden)
- [ ] User can still scroll message history during TTS
- [ ] UI remains responsive (no freezing)

**Pass Criteria:** Clear visual indication that TTS is active, UI stays responsive

---

### Test 11: Toggle TTS On/Off in Settings

**Steps:**
1. Open Settings → Voice Settings
2. Find "Enable Voice Responses" toggle
3. Turn toggle **OFF**
4. Return to AI Assistant
5. Send message and wait for AI response

**Expected:**
- [ ] AI responds with text (normal)
- [ ] TTS **does NOT auto-play**
- [ ] Speaker icon **still appears** on message
- [ ] Tapping speaker icon **manually plays TTS**

**Steps (continued):**
6. Return to Settings → Voice Settings
7. Turn toggle **ON**
8. Send another message

**Expected:**
- [ ] TTS **auto-plays** again
- [ ] Setting persists across app restarts

**Console Logs Expected:**
```
⚙️ [ViewModel] Voice responses disabled - skipping auto-play
🔊 [ViewModel] Manual TTS triggered by speaker icon tap
```

**Pass Criteria:** Toggle controls auto-play, manual replay always available

---

## 🔄 Audio Session & Interruption Tests

### Test 12: TTS with Background Music (Audio Ducking)

**Steps:**
1. Open Apple Music or Spotify
2. Play music at medium volume
3. Return to Psst AI Assistant
4. Send message and wait for TTS

**Expected:**
- [ ] Music volume **lowers** when TTS starts (audio ducking)
- [ ] TTS plays clearly over lowered music
- [ ] After TTS finishes, music volume **returns to normal**
- [ ] No audio glitches or clipping

**Console Logs Expected:**
```
🔊 [AudioSessionService] Setting audio session to .playback with .duckOthers
✅ [AudioSessionService] Audio session configured for TTS
```

**Pass Criteria:** Background audio ducks during TTS, resumes after

---

### Test 13: Incoming Phone Call During TTS

**Steps:**
1. Send message with long AI response
2. TTS starts speaking
3. Have someone call your phone (or simulate incoming call)

**Expected:**
- [ ] TTS **pauses** when phone rings
- [ ] Phone call alert appears normally
- [ ] After declining/ending call, return to Psst
- [ ] TTS **does not resume** (stays stopped)
- [ ] Can tap speaker icon to replay manually

**Pass Criteria:** Phone call interruption handled gracefully, no crashes

---

### Test 14: TTS with AirPods/Bluetooth Headphones

**Steps:**
1. Connect AirPods or Bluetooth headphones
2. Send message and wait for AI response with TTS

**Expected:**
- [ ] TTS plays through **AirPods/headphones** (not speaker)
- [ ] Audio quality clear
- [ ] Volume controls on AirPods work
- [ ] Disconnect AirPods mid-TTS → Audio switches to phone speaker smoothly

**Pass Criteria:** TTS works with Bluetooth audio devices

---

### Test 15: App Backgrounding During TTS

**Steps:**
1. Send message with long AI response
2. TTS starts speaking
3. Swipe up to home screen (background app)
4. Wait 5 seconds
5. Return to Psst

**Expected:**
- [ ] TTS **stops** when app is backgrounded
- [ ] No crash when returning to app
- [ ] Speaker icon still visible (can replay)
- [ ] App state recovers normally

**Pass Criteria:** Backgrounding stops TTS gracefully, no crashes

---

## ❌ Error Handling Tests

### Test 16: TTS with Empty AI Response (Edge Case)

**Steps:**
1. (Simulate or trigger) AI response with empty text: ""
2. Observe behavior

**Expected:**
- [ ] TTS **does not attempt to play** (no audio)
- [ ] Speaker icon **still appears** (but does nothing when tapped)
- [ ] No crash or console errors

**Console Logs Expected:**
```
⚠️ [VoiceService] speak() called with empty text - skipping
```

**Pass Criteria:** Empty responses handled gracefully, no crashes

---

### Test 17: TTS Voice Not Available (Rare Edge Case)

**Steps:**
1. In Settings, select a TTS voice not downloaded on device
   - (Simulate by selecting uncommon voice like "Xander" or language-specific voice)
2. Send message and wait for TTS

**Expected:**
- [ ] TTS **falls back to default iOS voice**
- [ ] Audio plays (may sound different from selected voice)
- [ ] No error message shown to user
- [ ] Console logs warning

**Console Logs Expected:**
```
⚠️ [VoiceService] Selected voice "Xander" unavailable - using default
✅ [VoiceService] TTS playing with fallback voice
```

**Pass Criteria:** Unavailable voice falls back to default, no user-facing error

---

### Test 18: Rapidly Tapping Speaker Icon

**Steps:**
1. Send message with medium-length AI response
2. Rapidly tap speaker icon 5 times in 1 second

**Expected:**
- [ ] TTS **restarts** on each tap (previous stops, new starts)
- [ ] Final tap results in TTS playing once
- [ ] No audio glitches or overlapping playback
- [ ] No crashes

**Pass Criteria:** Rapid taps handled gracefully, no overlapping audio

---

## 🔍 Integration Tests (Voice + TTS)

### Test 19: Full Voice Conversation Flow

**Steps:**
1. Use voice to ask question (from Phase 1)
2. Speak: "What did Sarah say about her diet?"
3. Wait for transcription → Send
4. AI responds
5. TTS speaks response
6. Use voice again to ask follow-up: "Tell me more"
7. TTS speaks second response

**Expected:**
- [ ] Voice recording → transcription works (Phase 1)
- [ ] AI responds with text
- [ ] TTS speaks both responses
- [ ] Second voice input works while previous TTS is speaking (TTS stops first)
- [ ] Full conversation feels natural

**Pass Criteria:** Voice input and TTS output work seamlessly together

---

### Test 20: Voice Recording While TTS is Playing

**Steps:**
1. Send message with long AI response
2. TTS starts speaking
3. **Tap microphone button** to start voice recording while TTS is still playing

**Expected:**
- [ ] TTS **stops immediately** when recording starts
- [ ] Recording begins normally
- [ ] No audio session conflicts
- [ ] Can complete recording → transcription → send

**Console Logs Expected:**
```
⏹️ [VoiceService] Stopping TTS (recording starting)
🎤 [VoiceService] Starting recording...
✅ [AudioSessionService] Switched audio session to .record
```

**Pass Criteria:** Can start recording during TTS, no conflicts

---

## 📊 Performance Tests

### Test 21: TTS Start Latency

**Steps:**
1. Send message and wait for AI response
2. Time from when AI response appears to when TTS audio begins

**Expected:**
- [ ] TTS starts within **< 500ms** (target)
- [ ] Acceptable if **< 1 second**

**Console Timing:**
```
✅ [ViewModel] AI response received [Time: 0s]
🔊 [VoiceService] speak() called [Time: ~0.05s]
✅ [VoiceService] TTS started [Time: ~0.3s]
```

**Pass Criteria:** 90% of TTS playbacks start in < 500ms

---

### Test 22: TTS Memory Usage (Multiple Responses)

**Steps:**
1. Send 10 messages in a row
2. Let TTS play for each response
3. Monitor app memory usage in Xcode Instruments

**Expected:**
- [ ] Memory usage remains stable (no leaks)
- [ ] Each TTS playback releases memory after finishing
- [ ] No accumulated audio buffers

**Pass Criteria:** No memory leaks, app remains responsive

---

### Test 23: TTS with Very Long Response (Stress Test)

**Steps:**
1. Send: "Write me a 500-word essay on nutrition"
2. AI responds with very long text (5+ paragraphs)
3. TTS begins speaking

**Expected:**
- [ ] TTS speaks **entire response** without cutting off
- [ ] Playback smooth (no stuttering)
- [ ] Can stop TTS at any point
- [ ] No memory or performance issues

**Pass Criteria:** Long responses handled without errors

---

## 📱 Device/OS Tests

### Test 24: Different Device Speakers

Test on multiple devices if available:

**Test 24a: iPhone (Built-in Speaker)**
- [ ] TTS plays clearly through iPhone speaker
- [ ] **Expected:** Good audio quality

**Test 24b: iPad (Stereo Speakers)**
- [ ] TTS plays through iPad speakers
- [ ] **Expected:** Clear audio, uses stereo if available

**Test 24c: Wired Headphones**
- [ ] Connect wired headphones with 3.5mm jack (if available)
- [ ] **Expected:** TTS plays through headphones

**Pass Criteria:** TTS works on at least 2 different devices/audio routes

---

### Test 25: iOS Silent Mode (Mute Switch)

**Steps:**
1. Flip device silent mode switch to ON (mute)
2. Send message and wait for TTS

**Expected:**
- [ ] TTS **still plays** (audio session overrides silent mode)
- [ ] Volume respects device volume slider (not completely silent)

**Alternative Expected (depends on implementation):**
- [ ] TTS respects silent mode and doesn't play (shows visual indicator instead)

**Pass Criteria:** Behavior is consistent and intentional (document choice in notes)

---

## 🧹 Cleanup & Settings Tests

### Test 26: Settings Persistence

**Steps:**
1. Open Settings → Voice Settings
2. Change TTS voice to "Alex"
3. Toggle "Enable Voice Responses" to OFF
4. Close app completely (swipe up in app switcher)
5. Reopen app
6. Check Settings → Voice Settings

**Expected:**
- [ ] TTS voice **still set to "Alex"**
- [ ] "Enable Voice Responses" **still OFF**
- [ ] Settings persist across app restarts

**Console Logs Expected:**
```
✅ [VoiceService] loadSettings() - voiceResponseEnabled: false, ttsVoice: Alex
```

**Pass Criteria:** All voice settings persist correctly

---

### Test 27: Reset to Default Settings

**Steps:**
1. Change all voice settings from defaults
2. (If implemented) Tap "Reset to Defaults" button in Voice Settings
3. Observe changes

**Expected:**
- [ ] TTS voice resets to default (e.g., "Samantha")
- [ ] "Enable Voice Responses" resets to ON
- [ ] All settings return to initial state

**Pass Criteria:** Reset button works (if implemented), or defaults apply on fresh install

---

## 🔍 Console Log Validation

### Test 28: No Unexpected Errors in Console

**Steps:**
1. Complete one full cycle: Send message → TTS plays → Replay TTS → Stop TTS
2. Review entire console output

**Expected:**
- [ ] No red error messages (except expected errors in error tests)
- [ ] No warning messages
- [ ] All log lines use proper emoji prefixes (🔊, ✅, ❌, etc.)
- [ ] Log flow makes logical sense

**Pass Criteria:** Clean console logs with clear flow

---

## ✅ Final Acceptance Test

### Test 29: End-to-End TTS Happy Path

**Complete this scenario successfully:**

1. Open AI Assistant
2. Send text message: "What is the best way to build muscle?"
3. Wait for AI response
4. Verify TTS **auto-plays** and speaks full response
5. Wait for TTS to finish
6. Tap **speaker icon** on message
7. Verify TTS **replays** from beginning
8. Tap speaker icon again **while TTS is speaking**
9. Verify TTS **stops** immediately
10. Open Settings → Voice Settings
11. Toggle "Enable Voice Responses" to **OFF**
12. Return to AI Assistant
13. Send another message
14. Verify TTS **does not auto-play**
15. Tap speaker icon manually
16. Verify TTS plays when triggered manually

**Expected:**
- [ ] All steps complete without errors
- [ ] TTS auto-play works (when enabled)
- [ ] Manual replay works
- [ ] Stop functionality works
- [ ] Settings toggle controls auto-play behavior

**Pass Criteria:** Full TTS flow works end-to-end

---

## 📋 Phase 2 Completion Criteria

**Phase 2 is COMPLETE when:**

- [ ] **Core TTS Tests Pass:** Tests 1-5 all pass (100%)
- [ ] **Audio Quality Tests Pass:** Tests 6-8 all pass (100%)
- [ ] **UI Tests Pass:** Tests 9-11 all pass (100%)
- [ ] **Audio Session Tests Pass:** Tests 12-15 pass (no critical failures)
- [ ] **Error Tests Pass:** Tests 16-18 pass (graceful error handling)
- [ ] **Integration Tests Pass:** Tests 19-20 pass (Voice + TTS together)
- [ ] **Performance Acceptable:** Tests 21-23 meet targets (< 500ms latency)
- [ ] **Settings Work:** Tests 26-27 pass (persistence)
- [ ] **Final Acceptance:** Test 29 passes end-to-end

**Critical Blockers (Must Fix Before Phase 3):**
- Any crash or freeze
- TTS doesn't play at all
- Audio session conflicts
- Settings don't persist
- Speaker icon doesn't work

**Minor Issues (Can Fix in Phase 3):**
- TTS latency > 1 second (but < 2 seconds)
- Voice quality issues (can switch to OpenAI TTS later)
- UI polish (icon animations, colors)

---

## 🎯 Next Phase Preview

**After Phase 2 passes all tests, we move to:**

**Phase 3: UI Polish & Settings**
- Waveform visualization during recording
- Recording timer with auto-stop at 60s
- Polished VoiceRecordingView sheet
- Full VoiceSettingsView with all options
- Loading states and error messages
- Audio session conflict handling

**Estimated Time:** 2-3 hours

---

**Testing Started:** ___________
**Testing Completed:** ___________
**Tests Passed:** ____ / 29
**Phase 2 Status:** ⚪ Not Started | 🟡 In Progress | 🟢 Complete

---

**Tester Notes:**
```
[Add any issues, observations, or feedback here]




```

---

## 📝 Key Differences from Phase 1

**Phase 1 (Recording & Transcription):**
- Focus: Microphone input → Whisper API → Text output
- Primary interactions: Tap mic, speak, see transcription

**Phase 2 (Text-to-Speech):**
- Focus: AI text response → AVSpeechSynthesizer → Audio output
- Primary interactions: Hear response, tap speaker to replay/stop
- New UI: Speaker icons on messages
- New settings: Toggle TTS, select voice
- Audio session management: Ducking, interruptions, routing

**Combined (Phase 1 + 2):**
- Full voice conversation: Speak → AI responds → Hear response
- Hands-free interaction: Ask question vocally → Get answer vocally
- Must test integration: Recording during TTS, TTS during recording

---

**Ready to test Phase 2!** 🔊