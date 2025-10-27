# PR-011 Phased Implementation Plan

**Feature:** Voice AI Interface
**Strategy:** Build in 3 testable phases with micro-tests after each phase

---

## Phase 1: Core Recording & Transcription ⚡ START HERE

**Goal:** Get voice-to-text working end-to-end

**What We're Building:**
- VoiceService with recording + Whisper API transcription
- Microphone permission handling
- Basic voice button in AI Assistant
- Transcribed text populates message input

**Files to Create:**
- `Models/VoiceRecording.swift`
- `Models/VoiceServiceError.swift`
- `Services/VoiceService.swift` (recording + transcription only)
- `Components/VoiceButton.swift` (basic states)
- Modify: `Views/AI/AIAssistantView.swift`
- Modify: `ViewModels/AIAssistantViewModel.swift`
- Add: `NSMicrophoneUsageDescription` to Info.plist

**Success Criteria (Micro-Test):**
```
✅ User opens AI Assistant
✅ Taps microphone button
✅ Permission granted (first time)
✅ Recording starts (visual feedback)
✅ User speaks: "What did Sarah say about her diet?"
✅ Taps mic again to stop
✅ Transcription appears in text input within 2 seconds
✅ User can edit transcription
✅ Taps Send → AI responds (existing flow)
```

**Testing Checklist:**
- [ ] Microphone permission flow works
- [ ] Recording captures audio
- [ ] Whisper API transcribes correctly
- [ ] Transcription appears in message input
- [ ] Can edit and send transcribed text
- [ ] Error handling: permission denied
- [ ] Error handling: transcription fails

**Estimated Time:** 2-3 hours
**User Test After:** User tests voice recording → transcription → send

---

## Phase 2: Text-to-Speech 🔊

**Goal:** AI responds with spoken audio

**What We're Building:**
- AVSpeechSynthesizer integration
- TTS auto-plays after AI responds
- Speaker icon on AI messages for replay
- Stop/pause controls

**Files to Modify:**
- `Services/VoiceService.swift` (add TTS methods)
- `Models/VoiceSettings.swift` (add voiceResponseEnabled toggle)
- `ViewModels/AIAssistantViewModel.swift` (add TTS trigger)
- `Views/AI/AIAssistantView.swift` (add speaker icons)

**Success Criteria (Micro-Test):**
```
✅ User sends voice query (from Phase 1)
✅ AI responds with text (existing)
✅ TTS begins speaking within 500ms
✅ Audio plays clearly through speaker/headphones
✅ User can tap speaker icon to replay
✅ User can stop TTS mid-playback
```

**Testing Checklist:**
- [ ] TTS plays AI responses automatically
- [ ] Voice sounds natural (AVSpeechSynthesizer)
- [ ] Speaker icon appears on AI messages
- [ ] Tap speaker → replays message
- [ ] Can stop playback mid-sentence
- [ ] Works with AirPods/headphones

**Estimated Time:** 1-2 hours
**User Test After:** User tests voice query → AI responds → hears TTS

---

## Phase 3: UI Polish & Settings 🎨

**Goal:** Professional UX with visual feedback and customization

**What We're Building:**
- Waveform visualization during recording
- Recording timer (shows duration, auto-stop at 60s)
- VoiceSettingsView (toggle TTS, select voice, auto-send)
- Full VoiceRecordingView sheet (polished UI)
- Loading states and error messages

**Files to Create:**
- `Components/WaveformView.swift`
- `Views/AI/VoiceRecordingView.swift`
- `Views/Settings/VoiceSettingsView.swift`
- `Services/AudioSessionService.swift`

**Files to Modify:**
- `Services/VoiceService.swift` (add getAudioLevel for waveform)
- `Views/Settings/SettingsView.swift` (link to voice settings)

**Success Criteria (Micro-Test):**
```
✅ Waveform animates during recording
✅ Timer shows recording duration
✅ Auto-stops at 60 seconds
✅ Settings: Toggle TTS on/off works
✅ Settings: Select different TTS voice works
✅ Loading states show during transcription
✅ Error messages clear and actionable
```

**Testing Checklist:**
- [ ] Waveform visualization smooth (60fps)
- [ ] Timer counts correctly
- [ ] 60-second auto-stop works
- [ ] Voice settings persist
- [ ] Loading spinners appear appropriately
- [ ] Error messages user-friendly

**Estimated Time:** 2-3 hours
**User Test After:** Full feature demo with polished UX

---

## Overall Success: All 3 Phases Complete

**Final End-to-End Test:**
1. Open AI Assistant
2. Tap mic → Speak query → See waveform
3. Stop recording → Transcription appears
4. Edit if needed → Send
5. AI responds → TTS speaks response
6. Open settings → Toggle TTS → Verify changes

**PR Ready When:**
- [ ] All 3 phases tested individually
- [ ] Final end-to-end test passes
- [ ] No console errors
- [ ] Performance targets met (2s transcription, 500ms TTS)
- [ ] User approves feature

---

## Current Status

**Phase 1:** 🔴 Not Started
**Phase 2:** ⚪ Blocked (needs Phase 1)
**Phase 3:** ⚪ Blocked (needs Phase 2)

**Next Action:** Create branch → Start Phase 1 implementation
