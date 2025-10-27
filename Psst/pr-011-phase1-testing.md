# PR-011 Phase 1: Testing Checklist

**Phase:** Core Recording & Transcription
**Date:** October 26, 2025
**Status:** Ready for Testing

---

## ✅ Pre-Test Setup

- [ ] **Build succeeds** - No compilation errors
- [ ] **OpenAI API key configured** - Check `VoiceServiceConfig.swift` has valid key
- [ ] **Microphone permission added** - Verify `Info.plist` has `NSMicrophoneUsageDescription`
- [ ] **AI Assistant accessible** - Can navigate to AI Assistant screen

---

## 🎯 Core Functionality Tests

### Test 1: Microphone Permission Flow (First Time)

**Steps:**
1. Fresh app install OR reset permissions (Settings → Psst → Reset Permissions)
2. Open AI Assistant
3. Tap microphone button (gray mic icon)

**Expected:**
- [ ] iOS permission alert appears
- [ ] Alert shows custom message: "Psst uses your microphone to let you talk to your AI Assistant hands-free..."
- [ ] Two options: "Don't Allow" and "OK"

**Pass Criteria:** Permission alert appears with clear, user-friendly message

---

### Test 2: Permission Granted - Recording Starts

**Steps:**
1. From Test 1, tap "OK" to grant permission
2. Observe UI changes

**Expected:**
- [ ] Mic button turns **RED**
- [ ] Mic icon has **pulsing animation** (red circle expands/contracts)
- [ ] Text input field remains visible but disabled
- [ ] Send button remains visible

**Console Logs Expected:**
```
🔘 [ViewModel] Toggle voice recording (current state: isRecording=false)
▶️ [ViewModel] Starting voice recording...
🔐 [ViewModel] Requesting microphone permission...
✅ [ViewModel] Microphone permission granted
🎤 [VoiceService] Starting recording...
✅ [VoiceService] Microphone permission granted
✅ [VoiceService] Audio session configured
🎙️ [VoiceService] Recording started: true
✅ [ViewModel] Recording started successfully
```

**Pass Criteria:** Red pulsing mic button visible, console shows successful recording start

---

### Test 3: Recording Audio (3-5 seconds)

**Steps:**
1. With recording active (red mic from Test 2)
2. Speak clearly: **"What did Sarah say about her diet?"**
3. Wait 3-5 seconds
4. Observe while speaking

**Expected:**
- [ ] Mic button stays **RED** and **pulsing** while speaking
- [ ] No crashes or freezes
- [ ] Can speak normally

**Pass Criteria:** App remains responsive during recording, mic stays red and pulsing

---

### Test 4: Stop Recording - Transcription Starts

**Steps:**
1. After speaking for 3-5 seconds
2. Tap mic button again to stop

**Expected:**
- [ ] Mic button changes to **BLUE**
- [ ] **Spinner/loading indicator** appears on mic button
- [ ] Text input field shows "Ask me anything..." placeholder (still disabled)

**Console Logs Expected:**
```
⏹️ [VoiceService] Stopping recording...
⏱️ [VoiceService] Calculated duration: 3.XX seconds
✅ [VoiceService] Recording duration valid: X.XXs
📝 [VoiceService] Starting transcription...
✅ [VoiceService] API key present (length: 207 chars)
🌐 [VoiceService] Sending request to Whisper API...
```

**Pass Criteria:** Blue spinner appears, console shows transcription starting

---

### Test 5: Transcription Completes - Text Appears

**Steps:**
1. Wait 1-3 seconds after stopping recording

**Expected:**
- [ ] Mic button returns to **GRAY** (idle state)
- [ ] Transcribed text appears in **text input field**
- [ ] Text is **editable** (can tap and modify)
- [ ] Transcription is **accurate** (matches what you said)

**Console Logs Expected:**
```
📡 [VoiceService] HTTP Status: 200
📝 [VoiceService] Transcription: "What did Sarah say about her diet?"
✅ [ViewModel] Transcription received: "What did Sarah say about her diet?"
✅ [ViewModel] Input field updated with transcription
```

**Pass Criteria:** Transcribed text appears in input field within 2 seconds, text is editable

---

### Test 6: Edit Transcription and Send

**Steps:**
1. Tap in text input field
2. Edit the transcribed text (e.g., change a word)
3. Tap **Send button** (blue arrow)

**Expected:**
- [ ] Keyboard appears when tapping text field
- [ ] Can edit text normally
- [ ] Tap Send → Message appears in chat
- [ ] AI responds (existing AI flow works)

**Pass Criteria:** Can edit and send transcribed text, AI responds normally

---

## 🔄 Repeat Recording Tests

### Test 7: Second Recording (Permission Already Granted)

**Steps:**
1. After Test 6 completes
2. Tap mic button again
3. Speak: **"Schedule a call with John tomorrow at 6pm"**
4. Stop recording

**Expected:**
- [ ] No permission alert (already granted)
- [ ] Recording starts immediately
- [ ] Red pulsing mic appears
- [ ] Transcription works as before

**Pass Criteria:** Second recording works smoothly without re-prompting for permission

---

### Test 8: Multiple Recordings in Sequence

**Steps:**
1. Record → Transcribe → Clear text
2. Record → Transcribe → Clear text
3. Record → Transcribe → Clear text
4. Repeat 5 times total

**Expected:**
- [ ] Each recording works consistently
- [ ] No memory leaks (app doesn't slow down)
- [ ] No audio session errors
- [ ] Transcriptions remain accurate

**Pass Criteria:** Can record 5 times in a row without issues

---

## ❌ Error Handling Tests

### Test 9: Permission Denied

**Steps:**
1. Reset app permissions (Settings → Psst → Reset)
2. Open AI Assistant
3. Tap mic button
4. Tap **"Don't Allow"** in permission alert

**Expected:**
- [ ] Error alert appears
- [ ] Message: "Microphone permission denied. Please enable it in Settings."
- [ ] Alert has **"OK"** button
- [ ] Mic button stays **GRAY** (idle)

**Console Logs Expected:**
```
❌ [ViewModel] Microphone permission denied
```

**Pass Criteria:** Clear error message shown, app doesn't crash

---

### Test 10: Very Short Recording (< 1 second)

**Steps:**
1. Tap mic button
2. Immediately tap again (< 1 second)

**Expected:**
- [ ] Error alert appears
- [ ] Message: "Recording too short. Please speak for at least 1 second."
- [ ] Alert has **"OK"** button
- [ ] Mic button returns to **GRAY** (idle)

**Console Logs Expected:**
```
❌ [VoiceService] Recording too short: 0.XXs < 1.0s minimum
```

**Pass Criteria:** "Too short" error shown, mic returns to idle state

---

### Test 11: Offline Mode (Airplane Mode)

**Steps:**
1. Enable **Airplane Mode** on device
2. Record audio (3-5 seconds)
3. Stop recording

**Expected:**
- [ ] Recording completes normally
- [ ] Transcription **fails** with error alert
- [ ] Message: "No internet connection" or "Transcription failed"
- [ ] Alert has **"OK"** or **"Retry"** button
- [ ] Mic button returns to **GRAY** (idle)

**Console Logs Expected:**
```
❌ [VoiceService] Transcription failed: ...network...
```

**Pass Criteria:** Graceful offline error, doesn't crash

---

### Test 12: API Error Simulation (Invalid Key)

**Steps:**
1. Open `VoiceServiceConfig.swift`
2. Change API key to `"invalid-key-123"`
3. Build and run
4. Record and stop

**Expected:**
- [ ] Recording completes
- [ ] Transcription fails with error
- [ ] Message: "Couldn't transcribe audio" or "Authentication failed"
- [ ] Mic returns to **GRAY** (idle)

**Console Logs Expected:**
```
📡 [VoiceService] HTTP Status: 401
❌ [ViewModel] Voice service error: ...
```

**Pass Criteria:** API error handled gracefully, clear error message

**⚠️ IMPORTANT:** Restore correct API key after this test!

---

## 🎨 UI/UX Tests

### Test 13: Button States Visual Check

**Steps:**
1. Observe mic button in each state

**Expected States:**
- [ ] **Idle:** Gray mic icon, no animation
- [ ] **Recording:** Red mic icon, pulsing red circle animation
- [ ] **Transcribing:** Blue mic icon, spinning loader
- [ ] **Error:** Red mic with slash icon (or stays gray with error alert)

**Pass Criteria:** Each state has distinct visual appearance

---

### Test 14: Button Disabled During Transcription

**Steps:**
1. Start recording
2. Stop recording (transcription starts)
3. Try to tap mic button while spinner is showing

**Expected:**
- [ ] Mic button is **disabled** (can't tap)
- [ ] No response to taps during transcription
- [ ] Button re-enables when transcription completes

**Pass Criteria:** Can't start new recording while transcribing

---

### Test 15: Text Input Disabled During Recording/Transcribing

**Steps:**
1. Start recording
2. Try to tap text input field
3. Stop recording (transcribing)
4. Try to tap text input field

**Expected:**
- [ ] Text field **disabled** while recording (can't type)
- [ ] Text field **disabled** while transcribing
- [ ] Text field **enabled** after transcription completes

**Pass Criteria:** Can't type while voice operation in progress

---

## 🔊 Audio Quality Tests

### Test 16: Different Speech Patterns

Record and transcribe each of these:

**Test 16a: Normal Speech**
- [ ] Say: "What did Sarah say about her diet?"
- [ ] **Expected:** Accurate transcription

**Test 16b: Fast Speech**
- [ ] Say quickly: "I need to schedule a call with John tomorrow"
- [ ] **Expected:** Mostly accurate (minor errors acceptable)

**Test 16c: Slow Speech**
- [ ] Say slowly: "What... did... Sarah... say..."
- [ ] **Expected:** Accurate transcription

**Test 16d: Proper Nouns**
- [ ] Say: "Schedule a meeting with Marcus and Alex"
- [ ] **Expected:** Names capitalized correctly

**Test 16e: Numbers**
- [ ] Say: "Remind me to call at 6pm tomorrow"
- [ ] **Expected:** "6pm" or "six pm" transcribed

**Pass Criteria:** 4 out of 5 tests transcribe accurately (>80% word accuracy)

---

### Test 17: Background Noise Handling

**Steps:**
1. Play music or turn on TV in background (moderate volume)
2. Record speech with background noise
3. Stop and check transcription

**Expected:**
- [ ] Transcription completes (doesn't error out)
- [ ] Speech is mostly recognizable (may have some errors)
- [ ] If transcription is garbled, error is handled gracefully

**Pass Criteria:** Background noise doesn't crash app, transcription attempts

---

## 📱 Device/OS Tests

### Test 18: Interruption Handling - Phone Call

**Steps:**
1. Start recording
2. Have someone call your phone (or simulate incoming call)

**Expected:**
- [ ] Recording stops gracefully
- [ ] No crash when returning to app
- [ ] Can start new recording after call ends

**Pass Criteria:** Handles phone call interruption without crashing

---

### Test 19: App Backgrounding

**Steps:**
1. Start recording
2. Swipe up to home screen (background app)
3. Wait 2 seconds
4. Return to app

**Expected:**
- [ ] Recording stopped when backgrounded
- [ ] App state recovers when foregrounded
- [ ] No crash
- [ ] Can start new recording

**Pass Criteria:** Handles backgrounding gracefully

---

### Test 20: Different Audio Routes

Test with each audio configuration:

**Test 20a: Built-in Speaker**
- [ ] Record and transcribe
- [ ] **Expected:** Works normally

**Test 20b: AirPods/Bluetooth Headphones**
- [ ] Connect AirPods
- [ ] Record and transcribe
- [ ] **Expected:** Records from AirPods mic, transcribes correctly

**Test 20c: Wired Headphones (if available)**
- [ ] Connect wired headphones with mic
- [ ] Record and transcribe
- [ ] **Expected:** Records from headphone mic

**Pass Criteria:** Works with at least 2 different audio routes

---

## 🔍 Console Log Validation

### Test 21: No Unexpected Errors in Console

**Steps:**
1. Complete one full recording → transcription → send cycle
2. Review entire console output

**Expected:**
- [ ] No red error messages (except expected errors in error tests)
- [ ] No warning messages
- [ ] All log lines use proper emoji prefixes (🎤, ✅, ❌, etc.)
- [ ] Log flow makes logical sense

**Pass Criteria:** Clean console logs with clear flow

---

## 🧹 Cleanup Tests

### Test 22: Temporary Files Cleaned Up

**Steps:**
1. Record 3 different audio clips
2. Let each transcribe successfully
3. Check device storage

**Expected:**
- [ ] Temporary audio files deleted after successful transcription
- [ ] No orphaned .m4a files in /tmp directory

**Console Verification:**
```
✅ [VoiceService] Transcription: "..."
// Audio file should be deleted here
```

**Pass Criteria:** No audio file buildup in temp directory

---

## 📊 Performance Tests

### Test 23: Transcription Latency

**Steps:**
1. Record 3-second audio clip
2. Time from stop button tap to text appearing

**Expected:**
- [ ] Transcription appears in **< 2 seconds** (target)
- [ ] Acceptable if **< 3 seconds**

**Console Timing:**
```
⏹️ [VoiceService] Stopping recording... [Time: 0s]
📝 [VoiceService] Starting transcription... [Time: ~0.1s]
📡 [VoiceService] HTTP Status: 200 [Time: ~1.5s]
✅ [ViewModel] Input field updated [Time: ~2s]
```

**Pass Criteria:** 90% of transcriptions complete in < 3 seconds

---

### Test 24: UI Responsiveness During Operations

**Steps:**
1. Start recording
2. While recording, try to:
   - Scroll message history
   - Tap other UI elements
3. While transcribing, try same actions

**Expected:**
- [ ] UI remains responsive (no freezing)
- [ ] Scrolling smooth
- [ ] Other buttons work (except disabled ones)

**Pass Criteria:** App feels responsive throughout voice operation

---

## ✅ Final Acceptance Test

### Test 25: End-to-End Happy Path

**Complete this scenario successfully:**

1. Open AI Assistant
2. Tap mic button (first time - grant permission)
3. Speak: **"What did Sarah say about her knee injury?"**
4. Stop recording
5. Wait for transcription
6. Verify text appears: "What did Sarah say about her knee injury?"
7. (Optional) Edit text if needed
8. Tap Send
9. Wait for AI response
10. Verify AI responds with relevant information

**Expected:**
- [ ] All steps complete without errors
- [ ] Transcription accurate
- [ ] AI responds appropriately

**Pass Criteria:** Full flow from voice → transcription → AI response works

---

## 📋 Phase 1 Completion Criteria

**Phase 1 is COMPLETE when:**

- [ ] **Core Tests Pass:** Tests 1-8 all pass (100%)
- [ ] **Error Tests Pass:** Tests 9-12 all pass (100%)
- [ ] **UI Tests Pass:** Tests 13-15 all pass (100%)
- [ ] **Audio Tests Pass:** Tests 16-17 pass (80%+ accuracy)
- [ ] **Device Tests Pass:** Tests 18-20 pass (no critical failures)
- [ ] **Performance Acceptable:** Tests 23-24 meet targets
- [ ] **Final Acceptance:** Test 25 passes end-to-end

**Critical Blockers (Must Fix Before Phase 2):**
- Any crash or freeze
- Transcription fails 100% of the time
- Permission flow doesn't work
- API errors not handled

**Minor Issues (Can Fix in Phase 3):**
- UI polish (button sizes, animations)
- Transcription accuracy < 80%
- Latency > 3 seconds

---

## 🎯 Next Phase Preview

**After Phase 1 passes all tests, we move to:**

**Phase 2: Text-to-Speech**
- AI responds with spoken audio
- Speaker icons on AI messages
- Replay controls
- TTS settings

**Estimated Time:** 1-2 hours

---

**Testing Started:** ___________
**Testing Completed:** ___________
**Tests Passed:** ____ / 25
**Phase 1 Status:** ⚪ Not Started | 🟡 In Progress | 🟢 Complete

---

**Tester Notes:**
```
[Add any issues, observations, or feedback here]




```
