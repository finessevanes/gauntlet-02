# PR-011 Phase 3: Testing Checklist

**Phase:** UI Polish & Settings
**Date:** October 26, 2025
**Status:** Ready for Testing
**Prerequisites:** Phase 1 (Core Recording & Transcription) + Phase 2 (Text-to-Speech) must be complete

---

## ✅ Pre-Test Setup

- [ ] **Phase 1 complete** - Recording and transcription working correctly
- [ ] **Phase 2 complete** - TTS auto-play and manual replay working
- [ ] **Build succeeds** - No compilation errors
- [ ] **All Phase 2 tests passed** - Voice recording and TTS fully functional
- [ ] **Waveform visualization exists** - WaveformView.swift implemented
- [ ] **Voice settings screen exists** - VoiceSettingsView.swift implemented

---

## 🎯 Core Functionality Tests

### Test 1: Waveform Visualization During Recording

**Steps:**
1. Open AI Assistant
2. Tap microphone button to start recording
3. Speak at normal volume: "What did Sarah say about her workout?"
4. Observe waveform animation
5. Stop recording

**Expected:**
- [ ] Waveform **appears** when recording starts
- [ ] Waveform **animates** in real-time as you speak
- [ ] Waveform bars **pulse** with voice amplitude (louder = taller bars)
- [ ] Waveform **smooth** (60fps, no stuttering)
- [ ] Waveform stops animating when recording ends
- [ ] Silence shows **flat/minimal waveform**
- [ ] Speaking shows **active waveform bars**

**Console Logs Expected:**
```
🎤 [VoiceService] Recording started
📊 [WaveformView] Audio level: 0.45
📊 [WaveformView] Audio level: 0.78
📊 [WaveformView] Audio level: 0.32
✅ [VoiceService] Recording stopped
```

**Pass Criteria:** Waveform visualization is smooth, responsive, and accurately reflects voice volume

---

### Test 2: Recording Timer Accuracy

**Steps:**
1. Open AI Assistant
2. Tap microphone button
3. Speak for exactly 10 seconds (use stopwatch)
4. Observe timer display
5. Stop recording

**Expected:**
- [ ] Timer starts at **0:00** when recording begins
- [ ] Timer counts up **every second** (0:01, 0:02, 0:03...)
- [ ] Timer displays format: **"M:SS"** (e.g., 0:10, 1:23)
- [ ] Timer is **accurate** (matches actual elapsed time ±0.5s)
- [ ] Timer visible throughout recording
- [ ] Timer resets to 0:00 on next recording

**Console Logs Expected:**
```
⏱️ [VoiceRecordingView] Timer started
⏱️ [VoiceRecordingView] Timer: 0:01
⏱️ [VoiceRecordingView] Timer: 0:10
✅ [VoiceRecordingView] Recording stopped at 0:10
```

**Pass Criteria:** Timer counts accurately, displays correct format, resets properly

---

### Test 3: 60-Second Auto-Stop

**Steps:**
1. Open AI Assistant
2. Tap microphone button
3. Speak continuously or play music to keep recording active
4. Wait until timer reaches **0:50** (50 seconds)
5. Continue until **1:00** (60 seconds)

**Expected:**
- [ ] Timer displays **0:50** warning state (yellow/orange color)
- [ ] Warning message appears: **"10 seconds remaining"** or similar
- [ ] At **1:00**, recording **auto-stops** immediately
- [ ] Message appears: **"Maximum recording length reached"** or similar
- [ ] Transcription begins automatically (no manual stop needed)
- [ ] Audio file is **60 seconds long** (not longer)

**Console Logs Expected:**
```
⏱️ [VoiceRecordingView] Timer: 0:50
⚠️ [VoiceRecordingView] Warning: 10 seconds remaining
⏱️ [VoiceRecordingView] Timer: 1:00
⏹️ [VoiceService] Auto-stop at 60 seconds
✅ [VoiceService] Recording stopped, duration: 60.0s
🔄 [ViewModel] Starting transcription...
```

**Pass Criteria:** Auto-stop works at exactly 60s, warning shown at 50s, transcription proceeds normally

---

### Test 4: Waveform Visualization with Different Audio Levels

**Test 4a: Whisper (Very Quiet)**
**Steps:**
1. Start recording
2. Whisper very quietly: "Testing whisper mode"
3. Observe waveform

**Expected:**
- [ ] Waveform shows **minimal bars** (low amplitude)
- [ ] Bars still animate (not frozen)
- [ ] Audio still captures (transcription works)

**Test 4b: Normal Speaking**
**Steps:**
1. Start recording
2. Speak at normal conversational volume
3. Observe waveform

**Expected:**
- [ ] Waveform shows **medium bars** (moderate amplitude)
- [ ] Bars pulse naturally with speech rhythm

**Test 4c: Loud Shouting**
**Steps:**
1. Start recording
2. Speak loudly or near-shout
3. Observe waveform

**Expected:**
- [ ] Waveform shows **tall bars** (high amplitude)
- [ ] Bars don't clip or overflow UI bounds
- [ ] Waveform still smooth (no glitches)

**Test 4d: Silence**
**Steps:**
1. Start recording
2. Stay completely silent for 5 seconds
3. Observe waveform

**Expected:**
- [ ] Waveform shows **flat line** or minimal noise floor
- [ ] Timer continues counting
- [ ] Recording still active (doesn't auto-cancel)

**Pass Criteria:** Waveform accurately reflects all audio levels without UI glitches

---

## 🎨 UI/UX Tests

### Test 5: VoiceRecordingView Full-Screen UI

**Steps:**
1. Tap microphone button in AI Assistant
2. Observe the VoiceRecordingView that appears

**Expected:**
- [ ] View appears as **full-screen sheet** (or large modal)
- [ ] **Waveform visualization** prominently displayed (center or top)
- [ ] **Timer** clearly visible (e.g., top-right)
- [ ] **Microphone icon** visible (indicating recording state)
- [ ] **Cancel button** (X) visible (e.g., top-left)
- [ ] **Stop button** visible (e.g., bottom center, large)
- [ ] Background color: **Dark or themed** (not jarring white)
- [ ] All elements properly sized for iPhone (not cut off)

**Pass Criteria:** VoiceRecordingView is polished, professional, all controls accessible

---

### Test 6: Cancel Recording Flow

**Steps:**
1. Start recording
2. Speak for 3 seconds
3. Tap **Cancel button (X)**
4. Observe behavior

**Expected:**
- [ ] Recording **stops immediately**
- [ ] VoiceRecordingView **dismisses** (sheet closes)
- [ ] **No transcription occurs** (no API call)
- [ ] Message input **remains empty** (not populated)
- [ ] Temporary audio file **deleted** (no storage waste)
- [ ] Can start new recording immediately

**Console Logs Expected:**
```
❌ [ViewModel] User cancelled recording
🗑️ [VoiceService] Deleting temporary audio file
✅ [VoiceService] Recording cancelled, cleanup complete
```

**Pass Criteria:** Cancel works cleanly, no transcription, storage cleaned up

---

### Test 7: Stop Recording Button Functionality

**Steps:**
1. Start recording
2. Speak: "What is the best protein source?"
3. Tap **Stop button** (not Cancel)
4. Observe behavior

**Expected:**
- [ ] Recording **stops** when button tapped
- [ ] VoiceRecordingView shows **loading state** ("Transcribing...")
- [ ] Loading spinner appears
- [ ] Waveform **freezes** or **hides**
- [ ] Timer **stops counting**
- [ ] After 1-2 seconds, transcription completes
- [ ] VoiceRecordingView **dismisses**
- [ ] Transcription **appears in message input**

**Console Logs Expected:**
```
⏹️ [ViewModel] Stop button tapped
✅ [VoiceService] Recording stopped, duration: 4.2s
🔄 [ViewModel] Starting transcription...
📝 [ViewModel] Transcription received: "What is the best protein source?"
✅ [ViewModel] Populating message input
```

**Pass Criteria:** Stop button works, loading state clear, transcription populates input

---

### Test 8: Loading State During Transcription

**Steps:**
1. Start recording
2. Speak for 5-10 seconds (longer message)
3. Tap Stop button
4. Observe UI during transcription

**Expected:**
- [ ] **"Transcribing..."** text appears
- [ ] Loading spinner/activity indicator visible
- [ ] Timer display **grayed out** or hidden
- [ ] Waveform **hidden** or frozen
- [ ] Stop button **disabled** (can't tap again)
- [ ] Cancel button **disabled** (can't cancel during transcription)
- [ ] Loading state lasts 1-3 seconds
- [ ] After transcription: View dismisses, text appears

**Pass Criteria:** Loading state is clear, user knows transcription is happening

---

### Test 9: Error Message Display (Visual Feedback)

**Steps:**
1. Enable airplane mode (simulate offline)
2. Start recording
3. Speak for 3 seconds
4. Tap Stop button
5. Observe error handling

**Expected:**
- [ ] Loading state appears ("Transcribing...")
- [ ] After timeout, **error message** appears
- [ ] Error text: **"No internet connection. Transcription failed."** (or similar)
- [ ] **Retry button** visible
- [ ] Error message **clear and actionable**
- [ ] VoiceRecordingView **doesn't dismiss** (stays open for retry)

**Console Logs Expected:**
```
❌ [VoiceService] Transcription failed: Network error
⚠️ [ViewModel] Showing error: No internet connection
```

**Pass Criteria:** Error messages clear, actionable, UI doesn't crash

---

## ⚙️ Settings Tests

### Test 10: VoiceSettingsView Navigation

**Steps:**
1. Open main **Settings** screen
2. Look for "Voice" or "Voice Settings" option
3. Tap to navigate to VoiceSettingsView

**Expected:**
- [ ] "Voice Settings" navigation link exists in main Settings
- [ ] Icon visible (e.g., 🎤 microphone icon)
- [ ] Tap navigates to **VoiceSettingsView**
- [ ] VoiceSettingsView has navigation bar with "Voice" title
- [ ] Back button returns to main Settings

**Pass Criteria:** Voice settings accessible from main Settings screen

---

### Test 11: Toggle - Enable Voice Responses (TTS)

**Steps:**
1. Open Settings → Voice Settings
2. Find "Enable Voice Responses" toggle
3. Current state: **ON** (default)
4. Toggle to **OFF**
5. Return to AI Assistant
6. Send message and observe TTS behavior
7. Return to Settings
8. Toggle back to **ON**
9. Send another message

**Expected:**
- [ ] Toggle exists and is clearly labeled
- [ ] Default state is **ON**
- [ ] When **OFF**: TTS does not auto-play (Phase 2 behavior: manual only)
- [ ] When **ON**: TTS auto-plays (existing Phase 2 behavior)
- [ ] Toggle state **persists** across app restarts
- [ ] Toggle change takes effect immediately

**Console Logs Expected:**
```
⚙️ [VoiceService] Voice responses disabled
✅ [VoiceService] Settings saved: voiceResponseEnabled = false
⚙️ [VoiceService] Voice responses enabled
✅ [VoiceService] Settings saved: voiceResponseEnabled = true
```

**Pass Criteria:** Toggle controls TTS auto-play, settings persist

---

### Test 12: Picker - Select TTS Voice

**Steps:**
1. Open Settings → Voice Settings
2. Find "TTS Voice" picker
3. Current selection: (Default, e.g., "Samantha")
4. Tap picker to open voice options
5. Select different voice: **"Alex"**
6. Return to AI Assistant
7. Send message and listen to TTS

**Expected:**
- [ ] Picker shows available TTS voices (e.g., Samantha, Alex, Fred, Victoria)
- [ ] Tap picker → Voice list appears (modal or sheet)
- [ ] Select voice → Picker updates to show "Alex"
- [ ] Return to AI Assistant
- [ ] TTS plays with **new voice** (sounds different)
- [ ] Voice selection **persists** across app restarts

**Console Logs Expected:**
```
⚙️ [VoiceService] TTS voice changed to: Alex
✅ [VoiceService] Settings saved: ttsVoice = Alex
🔊 [VoiceService] Speaking with voice: Alex
```

**Pass Criteria:** Voice selection works, voices sound distinct, settings persist

---

### Test 13: Toggle - Auto-Send After Transcription

**Steps:**
1. Open Settings → Voice Settings
2. Find "Auto-Send After Transcription" toggle
3. Toggle to **ON**
4. Return to AI Assistant
5. Start voice recording
6. Speak: "What's the weather?"
7. Stop recording
8. Observe behavior

**Expected:**
- [ ] Toggle exists and is clearly labeled
- [ ] Default state is **OFF** (user reviews transcription first)
- [ ] When **ON**: After transcription appears, message **auto-sends immediately**
- [ ] When **OFF**: Transcription populates input, **user taps Send manually**
- [ ] Toggle state **persists** across app restarts

**Console Logs Expected:**
```
⚙️ [VoiceService] Auto-send enabled
✅ [ViewModel] Transcription complete, auto-sending...
📤 [ViewModel] Message sent automatically
```

**Pass Criteria:** Auto-send toggle works, settings persist, behavior matches expectation

---

### Test 14: Picker - Transcription Language

**Steps:**
1. Open Settings → Voice Settings
2. Find "Transcription Language" picker
3. Current selection: **"English"** (default)
4. Tap picker to open language options
5. Select different language: **"Spanish"** (if available)
6. Return to AI Assistant
7. Start recording
8. Speak in Spanish: "Hola, cómo estás?"
9. Stop recording
10. Observe transcription

**Expected:**
- [ ] Picker shows available languages (e.g., English, Spanish, French, etc.)
- [ ] Tap picker → Language list appears
- [ ] Select language → Picker updates to show "Spanish"
- [ ] Whisper API uses selected language
- [ ] Transcription appears in **Spanish** (if spoken in Spanish)
- [ ] Language selection **persists** across app restarts

**Alternative Test (if only English supported):**
- [ ] Picker shows "English" only
- [ ] Tap picker → Shows message "More languages coming soon"
- [ ] (Document planned feature)

**Console Logs Expected:**
```
⚙️ [VoiceService] Transcription language changed to: es
✅ [VoiceService] Settings saved: transcriptionLanguage = es
📝 [VoiceService] Transcribing with language: es
```

**Pass Criteria:** Language picker works, Whisper API respects language setting

---

### Test 15: Settings Persistence Across App Restarts

**Steps:**
1. Open Settings → Voice Settings
2. Change ALL settings:
   - Enable Voice Responses: **OFF**
   - TTS Voice: **"Alex"**
   - Auto-Send: **ON**
   - Transcription Language: **"Spanish"** (if available)
3. Close app completely (swipe up in app switcher)
4. Reopen app
5. Navigate to Settings → Voice Settings
6. Verify all settings

**Expected:**
- [ ] Enable Voice Responses: Still **OFF**
- [ ] TTS Voice: Still **"Alex"**
- [ ] Auto-Send: Still **ON**
- [ ] Transcription Language: Still **"Spanish"**
- [ ] All settings loaded correctly from UserDefaults

**Console Logs Expected:**
```
✅ [VoiceService] loadSettings() - voiceResponseEnabled: false, ttsVoice: Alex, autoSend: true, language: es
```

**Pass Criteria:** All settings persist correctly across app restarts

---

### Test 16: Reset to Default Settings (If Implemented)

**Steps:**
1. Change all voice settings from defaults
2. Open Settings → Voice Settings
3. Look for "Reset to Defaults" button (if exists)
4. Tap "Reset to Defaults"
5. Observe changes

**Expected:**
- [ ] Button exists and is clearly labeled
- [ ] Confirmation alert appears: "Reset all voice settings to defaults?"
- [ ] Tap "Reset" → All settings return to defaults:
  - Enable Voice Responses: **ON**
  - TTS Voice: **"Samantha"** (or default)
  - Auto-Send: **OFF**
  - Transcription Language: **"English"**
- [ ] Settings screen updates immediately

**Alternative (if not implemented):**
- [ ] No reset button exists (document as future enhancement)

**Pass Criteria:** Reset button works (if implemented), or feature documented for future

---

## 🔄 Integration Tests (Phase 1 + Phase 2 + Phase 3)

### Test 17: Full Voice Conversation with Polished UI

**Steps:**
1. Open AI Assistant
2. Tap microphone button
3. VoiceRecordingView appears with waveform and timer
4. Speak for 5 seconds: "What did Sarah say about her nutrition plan?"
5. Watch waveform animate and timer count
6. Tap Stop button
7. See "Transcribing..." loading state
8. Transcription appears in message input
9. Edit transcription if needed (add punctuation)
10. Tap Send
11. AI responds with text
12. TTS plays response aloud (if enabled)
13. Tap speaker icon to replay

**Expected:**
- [ ] Full flow works end-to-end
- [ ] Waveform visualization smooth throughout
- [ ] Timer accurate
- [ ] Loading states clear
- [ ] Transcription accurate
- [ ] TTS plays (if enabled in settings)
- [ ] No errors or crashes
- [ ] Flow feels polished and professional

**Pass Criteria:** Complete voice conversation works with polished UI

---

### Test 18: Auto-Send Flow (Settings ON)

**Steps:**
1. Open Settings → Voice Settings
2. Enable "Auto-Send After Transcription"
3. Return to AI Assistant
4. Start recording
5. Speak: "Tell me about protein synthesis"
6. Stop recording
7. Observe behavior

**Expected:**
- [ ] Transcription appears in message input
- [ ] Message **auto-sends immediately** (no manual Send tap)
- [ ] AI responds
- [ ] TTS plays response (if TTS enabled)
- [ ] No opportunity to edit transcription (trade-off of auto-send)

**Pass Criteria:** Auto-send works seamlessly, saves time for hands-free use

---

### Test 19: Cancel During Waveform Visualization

**Steps:**
1. Start recording
2. Speak for 3 seconds (waveform animating)
3. Tap **Cancel button (X)** mid-recording
4. Observe cleanup

**Expected:**
- [ ] Recording stops immediately
- [ ] Waveform animation stops
- [ ] Timer stops
- [ ] VoiceRecordingView dismisses
- [ ] No transcription occurs
- [ ] Temp audio file deleted
- [ ] No memory leaks

**Console Logs Expected:**
```
❌ [ViewModel] User cancelled during recording
⏹️ [VoiceService] Stopping recording...
🗑️ [VoiceService] Deleting temporary file
✅ [VoiceService] Cleanup complete
```

**Pass Criteria:** Cancel works cleanly even during active recording

---

## 📱 Device/OS Tests

### Test 20: Waveform Performance on Different Devices

**Test 20a: iPhone (Standard Performance)**
**Steps:**
1. Test waveform on iPhone 12 or newer
2. Start recording and observe animation

**Expected:**
- [ ] Waveform smooth (60fps)
- [ ] No stuttering or lag
- [ ] Timer updates every second

**Test 20b: Older iPhone (Lower Performance)**
**Steps:**
1. Test on iPhone 8 or older (if available)
2. Start recording and observe animation

**Expected:**
- [ ] Waveform may be slightly less smooth (acceptable 30fps)
- [ ] Timer still accurate
- [ ] No crashes

**Test 20c: iPad (Larger Screen)**
**Steps:**
1. Test on iPad
2. Start recording

**Expected:**
- [ ] VoiceRecordingView scales properly to larger screen
- [ ] Waveform appropriately sized (not tiny)
- [ ] Timer visible and readable
- [ ] All buttons accessible

**Pass Criteria:** Waveform works on at least 2 different devices, scales properly

---

### Test 21: Background Audio During Recording

**Steps:**
1. Open Apple Music or Spotify
2. Play music at medium volume
3. Return to Psst
4. Start voice recording
5. Observe audio session behavior

**Expected:**
- [ ] Background music **pauses** or **ducks** (volume lowers) when recording starts
- [ ] Recording captures voice clearly
- [ ] Waveform shows voice amplitude (not music)
- [ ] After recording stops, music **resumes** or volume returns
- [ ] No audio session conflicts

**Console Logs Expected:**
```
🔊 [AudioSessionService] Setting audio session to .record
✅ [AudioSessionService] Background audio paused
⏹️ [VoiceService] Recording stopped
🔊 [AudioSessionService] Restoring audio session
```

**Pass Criteria:** Audio session handled gracefully, no conflicts with background audio

---

### Test 22: Portrait vs Landscape Orientation

**Steps:**
1. Start recording in **portrait** mode
2. Observe VoiceRecordingView layout
3. Rotate device to **landscape** mode
4. Observe layout changes
5. Continue recording
6. Stop recording

**Expected:**
- [ ] VoiceRecordingView adapts to **portrait** layout
- [ ] Rotating to **landscape** doesn't crash
- [ ] Layout adjusts appropriately (waveform, timer, buttons still visible)
- [ ] Recording continues without interruption
- [ ] Timer keeps counting accurately

**Alternative Expected (if landscape not supported):**
- [ ] VoiceRecordingView locks to **portrait only**
- [ ] Rotation doesn't crash app

**Pass Criteria:** Orientation changes handled gracefully or locked to portrait

---

## ❌ Error Handling Tests

### Test 23: Very Short Recording (Edge Case)

**Steps:**
1. Tap microphone button
2. Immediately tap Stop button (<0.5 seconds elapsed)
3. Observe behavior

**Expected:**
- [ ] Alert appears: **"Recording too short. Please try again."** (or similar)
- [ ] **No transcription API call** (saves cost)
- [ ] VoiceRecordingView dismisses or resets
- [ ] Can start new recording

**Console Logs Expected:**
```
⚠️ [ViewModel] Recording too short (0.3s), minimum is 1s
❌ [ViewModel] Not sending to Whisper API
```

**Pass Criteria:** Short recordings rejected gracefully, clear feedback

---

### Test 24: Transcription Timeout

**Steps:**
1. Enable Network Link Conditioner (100% loss or very slow network)
2. Start recording
3. Speak for 5 seconds
4. Stop recording
5. Wait for timeout

**Expected:**
- [ ] Loading state appears ("Transcribing...")
- [ ] After 10-15 seconds, timeout occurs
- [ ] Error message: **"Transcription taking too long. Retry?"**
- [ ] **Retry button** appears
- [ ] Tap Retry → Re-attempts transcription
- [ ] VoiceRecordingView doesn't dismiss until success or cancel

**Console Logs Expected:**
```
⏳ [VoiceService] Transcription timeout after 15s
❌ [ViewModel] Showing error: Request timeout
🔄 [ViewModel] User tapped Retry
```

**Pass Criteria:** Timeout handled gracefully, retry option available

---

### Test 25: Waveform with No Audio Input

**Steps:**
1. Start recording
2. Stay completely silent for 10 seconds
3. Observe waveform
4. Stop recording

**Expected:**
- [ ] Waveform shows **minimal bars** (flat or near-flat)
- [ ] Waveform doesn't freeze (still animating slightly with noise floor)
- [ ] Timer continues counting
- [ ] Recording still works (doesn't auto-cancel)
- [ ] Transcription occurs (may return empty or "[silence]")

**Pass Criteria:** Waveform handles silence gracefully, doesn't crash

---

## 🔍 Console Log Validation

### Test 26: Clean Console Logs During Full Flow

**Steps:**
1. Start recording → Speak → Stop → Transcription appears
2. Review console output

**Expected:**
- [ ] No **red errors** (except intentional error tests)
- [ ] No **yellow warnings**
- [ ] Logs use proper emoji prefixes (🎤, 📊, ⏱️, ✅, ❌)
- [ ] Log flow is logical and sequential
- [ ] Timing logs show performance (e.g., "Transcription completed in 1.8s")

**Example Clean Log Flow:**
```
🎤 [ViewModel] Microphone tapped, starting recording
✅ [VoiceService] Recording started
📊 [WaveformView] Audio level: 0.65
⏱️ [VoiceRecordingView] Timer: 0:05
⏹️ [ViewModel] Stop button tapped
✅ [VoiceService] Recording stopped, duration: 5.2s
🔄 [ViewModel] Starting transcription...
📝 [VoiceService] Transcription completed in 1.8s
✅ [ViewModel] Transcription: "What is the best protein source?"
```

**Pass Criteria:** Console logs clean, informative, properly formatted

---

## ✅ Final Acceptance Tests

### Test 27: End-to-End Polished Voice Flow

**Complete this scenario successfully:**

1. Open AI Assistant
2. Tap microphone button
3. VoiceRecordingView appears with animated waveform
4. Speak for 7 seconds: "Explain the benefits of HIIT training for fat loss"
5. Watch timer count: 0:01, 0:02, ... 0:07
6. Waveform animates smoothly with voice
7. Tap Stop button
8. "Transcribing..." loading state appears
9. Transcription appears in message input within 2 seconds
10. Transcription is accurate
11. Tap Send
12. AI responds with detailed answer
13. TTS auto-plays response (if enabled)
14. Full flow completes in <10 seconds total

**Expected:**
- [ ] All steps complete without errors
- [ ] Waveform visualization smooth and responsive
- [ ] Timer accurate
- [ ] Loading states clear
- [ ] Transcription accurate
- [ ] TTS works (if enabled)
- [ ] Flow feels polished and professional

**Pass Criteria:** Complete polished voice flow works end-to-end

---

### Test 28: Settings Workflow End-to-End

**Complete this scenario successfully:**

1. Open Settings
2. Navigate to Voice Settings
3. Change TTS voice to "Alex"
4. Enable "Auto-Send After Transcription"
5. Disable "Enable Voice Responses" (TTS)
6. Return to AI Assistant
7. Start voice recording
8. Speak: "What's the best recovery method after workouts?"
9. Stop recording
10. Transcription auto-sends (auto-send enabled)
11. AI responds
12. TTS does NOT play (disabled in settings)
13. Verify speaker icon still appears for manual replay

**Expected:**
- [ ] All settings changes take effect immediately
- [ ] Auto-send works
- [ ] TTS disabled (no auto-play)
- [ ] Manual TTS replay still available (speaker icon)
- [ ] Settings persist after app restart

**Pass Criteria:** All settings work correctly and affect voice behavior as expected

---

### Test 29: Stress Test - Multiple Recordings in Sequence

**Steps:**
1. Record 5 voice messages in quick succession (no pauses):
   - Recording 1: "Message one" → Stop → Send
   - Recording 2: "Message two" → Stop → Send
   - Recording 3: "Message three" → Stop → Send
   - Recording 4: "Message four" → Stop → Send
   - Recording 5: "Message five" → Stop → Send
2. Observe performance throughout

**Expected:**
- [ ] Each recording works correctly
- [ ] Waveform animates smoothly for all 5 recordings
- [ ] Timers reset properly between recordings
- [ ] Transcriptions accurate for all 5
- [ ] No memory leaks or performance degradation
- [ ] App remains responsive
- [ ] No temp file accumulation (cleanup works)

**Console Logs Expected:**
```
✅ [VoiceService] Recording 1 complete, cleanup done
✅ [VoiceService] Recording 2 complete, cleanup done
✅ [VoiceService] Recording 3 complete, cleanup done
✅ [VoiceService] Recording 4 complete, cleanup done
✅ [VoiceService] Recording 5 complete, cleanup done
```

**Pass Criteria:** Multiple recordings work without degradation or errors

---

## 📋 Phase 3 Completion Criteria

**Phase 3 is COMPLETE when:**

- [ ] **Waveform Tests Pass:** Tests 1, 4 all pass (100%)
- [ ] **Timer Tests Pass:** Tests 2, 3 pass (100%)
- [ ] **UI Tests Pass:** Tests 5-9 all pass (100%)
- [ ] **Settings Tests Pass:** Tests 10-16 pass (at least 90%)
- [ ] **Integration Tests Pass:** Tests 17-19 pass (100%)
- [ ] **Device Tests Pass:** Tests 20-22 pass (no critical failures)
- [ ] **Error Tests Pass:** Tests 23-25 pass (graceful error handling)
- [ ] **Console Logs Clean:** Test 26 passes
- [ ] **Final Acceptance:** Tests 27-29 pass end-to-end
- [ ] **Performance Acceptable:** Waveform smooth (60fps), timer accurate, no lag

**Critical Blockers (Must Fix Before PR):**
- Any crash or freeze
- Waveform doesn't animate
- Timer inaccurate or doesn't count
- Settings don't persist
- Auto-stop at 60s doesn't work
- VoiceRecordingView UI broken

**Minor Issues (Can Polish in Follow-Up):**
- Waveform animation slightly choppy on older devices (acceptable 30fps)
- Timer ±0.5s accuracy (acceptable)
- Settings UI polish (colors, spacing)
- Additional language support (can add later)

---

## 🎯 Next Steps After Phase 3

**After Phase 3 passes all tests:**

**Ready for Pull Request:**
- All 3 phases complete (Phase 1: Recording/Transcription, Phase 2: TTS, Phase 3: UI Polish)
- Full end-to-end voice conversation works
- Settings functional and persistent
- Performance targets met
- Error handling comprehensive
- UI polished and professional

**PR Creation Checklist:**
- [ ] All Phase 1, 2, 3 tests passed
- [ ] Demo video recorded (show full voice flow)
- [ ] Code documented with comments
- [ ] README updated (if needed)
- [ ] User approval obtained
- [ ] PR created targeting `develop` branch

**Estimated Time for Phase 3:** 2-3 hours
**Total PR-011 Time (All Phases):** 5-8 hours

---

**Testing Started:** ___________
**Testing Completed:** ___________
**Tests Passed:** ____ / 29
**Phase 3 Status:** ⚪ Not Started | 🟡 In Progress | 🟢 Complete

---

**Tester Notes:**
```
[Add any issues, observations, or feedback here]




```

---

## 📝 Key Differences from Phase 2

**Phase 2 (Text-to-Speech):**
- Focus: AI text response → AVSpeechSynthesizer → Audio output
- Primary tests: TTS auto-play, speaker icon replay, stop/pause

**Phase 3 (UI Polish & Settings):**
- Focus: Visual feedback (waveform, timer) + User customization (settings)
- Primary tests: Waveform animation, timer accuracy, auto-stop, settings persistence
- New UI: VoiceRecordingView full-screen sheet, VoiceSettingsView
- New features: Waveform visualization, recording timer, auto-send toggle

**Combined (Phase 1 + 2 + 3):**
- Full polished voice experience: Visual feedback during recording → Transcription → AI response → TTS playback
- Complete settings control: TTS voice, auto-send, language, enable/disable
- Professional UI: Waveform, timer, loading states, error messages
- Production-ready: All edge cases handled, settings persist, performance optimized

---

## 🎬 Demo Script for User Approval

**After all tests pass, demonstrate to user:**

1. **Show Settings:**
   - "Here are all the voice settings you can customize"
   - Toggle TTS on/off, select voice, enable auto-send

2. **Show Recording UI:**
   - "When you tap the mic, you see this polished recording view"
   - Point out waveform, timer, cancel/stop buttons

3. **Demonstrate Full Flow:**
   - Record voice message with visible waveform and timer
   - Stop recording → Show transcription loading
   - Transcription appears → Send
   - AI responds → TTS plays (or doesn't, based on settings)

4. **Show Edge Cases:**
   - Cancel mid-recording (cleanup)
   - Auto-stop at 60s (if time allows)
   - Settings persist across app restart

5. **Get Approval:**
   - "Does this meet your expectations for Phase 3?"
   - "Any changes before we create the PR?"

---

**Ready to test Phase 3!** 🎨✨
