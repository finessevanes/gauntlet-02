# AI Build Plan: Parallel Strategy (ACTIVE)

**Decision:** Parallel Build with 2 agents  
**Date:** October 23, 2025  
**Last Updated:** October 24, 2025  
**Status:** Phase 3 Complete ✅ | Phase 4 In Progress (PR #008 Complete ✅)

---

## Progress Overview

| Phase | PRs | Status | Progress |
|-------|-----|---------|----------|
| **Phase 1: Foundation** | PR #001, #002 | ✅ Complete | 2/2 (100%) |
| **Phase 2: Basic AI Chat** | PR #003, #004 | ✅ Complete | 2/2 (100%) |
| **Phase 3: RAG + Contextual** | PR #005, #006, #007 | ✅ Complete | 3/3 (100%) |
| **Phase 4: Actions + Calendar + Voice** | PR #008, #009, #010, #011 | ⏳ In Progress | 1/4 (25%) |
| **Phase 5: Advanced** | PR #012, #013, #014, #015, #016 | ⏳ Pending | 0/5 (0%) |

**Overall Progress:** 8/16 PRs Complete (50%)

**Next Steps:** Continue Phase 4 - Priority: PR #009 (Contacts) → PR #010 (Calendar) ⭐ Critical for Demo
**Status:** PR #008 Complete ✅ | Phase 4 In Progress

---

## Phase 1: Foundation (PR #001 & #002)

### PR #001: AI Backend Infrastructure ✅ COMPLETE
```bash
# COMPLETED: October 24, 2025
# Branch: feat/pr-1-ai-backend-infrastructure
# PR: [Ready for review]
```

**Deliverables:** ✅ ALL COMPLETE
- ✅ Pinecone index setup (coachai, 1536 dims, cosine, serverless)
- ✅ Embedding generation service (OpenAI text-embedding-3-small)
- ✅ Cloud Function: `generateEmbedding` (Firestore trigger)
- ✅ Environment variables: `OPENAI_API_KEY`, `PINECONE_API_KEY`, `PINECONE_ENVIRONMENT`
- ✅ TypeScript migration for all Cloud Functions
- ✅ Retry logic with exponential backoff
- ✅ Error handling for API timeouts and rate limits

**Testing:** ✅ VERIFIED
- ✅ Happy path: Message sent → Embedding generated → Stored in Pinecone
- ✅ Edge case: Empty messages skipped gracefully
- ✅ Error: API failures retry with backoff
- ✅ Integration: Confirmed working in production (message ID: 94EB4823...)

---

### PR #002: iOS AI Scaffolding ✅ COMPLETE
```bash
# Completed: October 23, 2025
# Branch: feat/pr-002-ios-ai-scaffolding
```

**Deliverables:** ✅ ALL COMPLETE
- ✅ `AIService.swift` (handles Cloud Function calls with mock responses)
- ✅ `AIMessage.swift`, `AIConversation.swift`, `AIResponse.swift` models
- ✅ `AIAssistantView.swift` full chat interface (not just skeleton!)
- ✅ `AIAssistantViewModel.swift` for state management
- ✅ `AIMessageRow.swift`, `AILoadingIndicator.swift` UI components
- ✅ `MockAIData.swift` for development and testing
- ✅ SwiftUI previews functional
- ✅ Enter to send, auto-scroll, error handling

**Testing:** ✅ PASSED
- ✅ Happy path (send/receive messages, mock AI responses)
- ✅ Edge cases (empty message, long text, emojis)
- ✅ Error handling (auth check, validation)
- ✅ Performance (view load < 100ms, smooth scrolling)

**Status:** Merged to `feat/pr-002-ios-ai-scaffolding` - Ready for backend integration

---

**Phase 1 Sync Point:** 
- ✅ Both PRs can run in parallel (no dependencies)
- ✅ Both complete and merged to `develop`
- ✅ Integration tested and working

---

## Phase 2: Basic AI Chat (PR #003 & #004)

**Status:** Both Complete ✅

### PR #003: AI Chat Backend ✅ COMPLETE
```bash
# COMPLETED: October 24, 2025
# Branch: feat/pr-003-ai-chat-backend
```

**Deliverables:** ✅ ALL COMPLETE
- ✅ Cloud Function: `chatWithAI(userId, message, conversationId)`
- ✅ OpenAI ChatGPT integration
- ✅ Basic conversation history storage in Firestore
- ✅ Response streaming support

**Testing:** ✅ PASSED
- ✅ Happy path (AI responds) + Edge case (long message) + Error (OpenAI timeout)

---

### PR #004: AI Chat UI ✅ COMPLETE
```bash
# COMPLETED: October 24, 2025
# Branch: feat/pr-004-ai-chat-ui
# PR: [Ready for review]
```

**Deliverables:** ✅ ALL COMPLETE
- ✅ Enhanced `AIService.swift` with Cloud Function integration (ready for PR-003)
- ✅ Updated `AIAssistantViewModel.swift` with retry/error handling
- ✅ Enhanced `AIAssistantView.swift` with production-ready error alerts
- ✅ New `FloatingAIButton.swift` component with pulse animation
- ✅ Integrated AI Assistant into ChatListView navigation
- ✅ Message validation (empty check, 2000 char limit)
- ✅ Comprehensive error handling (offline, timeout, auth, server)
- ✅ Loading states ("AI is thinking..." indicator)
- ✅ Empty states (welcome message, example prompts)

**Testing:** ✅ PASSED
- ✅ Happy path (tap button → open chat → send message → receive mock response)
- ✅ Edge cases (empty messages prevented, long messages handled, rapid sends)
- ✅ Error handling (retry functionality, clear error messages)
- ✅ Regression (all existing features still work)
- ✅ Performance (view load <200ms, smooth scrolling)

**Backend Integration:**
- ⚠️ Currently using MOCK responses (intelligent contextual mocks)
- ✅ Code structured to easily switch to real Cloud Functions
- ✅ Feature flag `useRealBackend = false` (flip to `true` when PR-003 deploys)
- ✅ Clear instructions in AIService.swift header for enabling backend

**Status:** Merged to `feat/pr-004-ai-chat-ui` - Ready for backend integration when PR #003 completes

---

**Phase 2 Sync Point:** 
- ✅ PR #003 deployment → Flip feature flag → **First working AI chat!** 🎉
- ✅ Both PRs complete and merged to `develop`
- ✅ Integration tested and working

---

## Phase 3: RAG + Contextual Intelligence (PR #005, #006, #007)

**Status:** ✅ Complete (3/3 Complete) | **Dependencies:** Phase 1 & 2 Complete ✅

### PR #005: RAG Pipeline (Semantic Search) ✅ COMPLETE
```bash
# COMPLETED: October 25, 2025
# Branch: feat/pr-005-rag-pipeline
# Dependencies: PR #001, #003
```

**Brief:** Implement Retrieval Augmented Generation (RAG) to enable AI to search past conversations and provide context-aware answers.

**Deliverables:**
- Vector similarity search in Pinecone
- Message embedding indexing pipeline
- Cloud Function: `semanticSearch(query, userId, limit)`
- RAG integration into `chatWithAI`
- Relevance scoring for search results
- Error handling for Pinecone timeouts

**Testing:** 
- Happy path: Semantic search finds relevant messages
- Edge case: No results found, empty history
- Error: Pinecone timeout, API failures

**User Capability:** AI can search past conversations and answer questions about client history

---

### PR #006: Contextual AI Actions (Long-Press Menu) ✅ COMPLETE
```bash
# COMPLETED: October 25, 2025
# Branch: feat/pr-006-contextual-ai-actions
# Dependencies: PR #004, #005
```

**Brief:** Add contextual AI actions directly in conversations via long-press gestures on messages.

**Deliverables:**
- Long-press menu with three actions: Summarize, Set Reminder, Surface Context
- Contextual menu UI with icons and haptic feedback
- Inline AI results display
- Loading states and error handling
- Animations for menu and results

**Testing:**
- Happy path: Long-press shows menu, actions work
- Edge case: Spam long-press, rapid interactions
- Error: AI unavailable, timeout

**User Capability:** Trainers can long-press any message to get AI summaries, set reminders, or view related past conversations

---

### PR #007: Contextual Intelligence (Auto Client Profiles) ✅ COMPLETE
```bash
# COMPLETED: October 24, 2025
# Branch: feat/pr-007-contextual-intelligence
# PR: [Ready for review]
```

**Brief:** Automatically build rich client profiles from conversations without manual data entry.

**Deliverables:** ✅ ALL COMPLETE
- ✅ Background processing to extract client information (injuries, goals, equipment, preferences, travel, stress)
- ✅ Firestore storage: `clientProfiles/{clientId}`
- ✅ UI to view auto-generated profiles with categories (banner + detail modal)
- ✅ Manual edit/correction capabilities
- ✅ Profile information surfaced in conversations (trainer-only visibility)
- ✅ Cloud Function: `extractProfileInfoOnMessage` (Firestore onCreate trigger)
- ✅ OpenAI GPT-4o-mini integration for AI extraction with JSON structured output
- ✅ Role-based extraction (only CLIENT messages trigger extraction)
- ✅ Role-based UI visibility (only TRAINERS see client profiles)
- ✅ Duplicate detection with text similarity matching
- ✅ Confidence scoring (high/medium/low badges)
- ✅ Newest-first sorting for all profile items
- ✅ Refactored code (DRY principles, helper methods, ForEach loops)
- ✅ Firestore security rules for clientProfiles collection

**Testing:** ✅ VERIFIED
- ✅ Happy path: Client sends message → AI extracts info → Profile updated → Trainer sees it
- ✅ Edge case: Trainer messages do NOT trigger extraction
- ✅ Edge case: Client cannot see profile UI (trainer-only)
- ✅ Edge case: Duplicate items update timestamp instead of creating duplicates
- ✅ Edge case: Items sorted newest-first across all categories
- ✅ Error: Extraction failures don't break message send (graceful degradation)
- ✅ Integration: Merged PR #6.5 role field for role-based logic
- ✅ Code quality: Refactored for DRY principles (ProfileService helpers, ForEach in detail view)

**User Capability:** AI automatically remembers and organizes client details from conversations (trainer-only feature)

---

**Phase 3 Sync Point:** ✅ ALL COMPLETE → RAG fully functional with contextual UI
- ✅ PR #005 (RAG Pipeline)
- ✅ PR #006 (Contextual Actions)
- ✅ PR #007 (Auto Client Profiles)
- ✅ Integration tested and working
- ✅ Ready to begin Phase 4

---

## Phase 4: Actions + Voice + Calendar (PR #008, #009, #010, #011)

**Status:** ⏳ In Progress (1/4 Complete) | **Dependencies:** Phase 3 Complete ✅

### PR #008: AI Function Calling (Tool Integration) ✅ COMPLETE
```bash
# COMPLETED: October 25, 2025
# Branch: feat/pr-008-function-calling
# Dependencies: PR #003
```

**Brief:** Enable AI to execute actions instead of just providing information.

**Deliverables:**
- OpenAI function calling setup
- Tools: `scheduleCall()`, `setReminder()`, `sendMessage()`, `searchMessages()`
- Function execution handlers in Cloud Functions
- Confirmation UI (except YOLO mode)
- Function execution history/audit trail

**Testing:**
- Happy path: AI calls function, action executes
- Edge case: Invalid params, permission denied
- Error: Function execution fails

**User Capability:** AI can execute actions like scheduling calls (Firestore only), setting reminders, sending messages (with approval)

**⚠️ Important:** PR #008 stores calendar events in Firestore only. **PR #010 (Calendar System) is required** to sync these events to trainer's real Google Calendar.

---

### PR #009: Trainer-Client Relationship System & Contact Management ✅ COMPLETE
```bash
# Status: ⏳ PENDING
# Branch: feat/pr-009-contacts
# Dependencies: PR #006.5 (User Roles)
```

**Brief:** Implement explicit trainer-client relationship model replacing "everyone can access everyone" architecture.

**Deliverables:**
- Firestore collections: `/contacts/{trainerId}/clients` and `/contacts/{trainerId}/prospects`
- Firebase security rules for relationship-based access control
- "Add Client" and "Add Prospect" UI in trainer app
- Group chat peer discovery (clients can message each other if in same group)
- Prospect workflow with placeholder emails (`prospect-[name]@psst.app`)
- ContactsView with "My Clients" and "Prospects" sections
- Upgrade prospect to client functionality
- Client invitation flow with deep links
- Migration script for existing users

**Testing:**
- Happy path: Trainer adds client → Client receives invitation
- Edge case: Client tries to message trainer who hasn't added them (blocked)
- Error: Invitation failures, network issues

**User Capability:** Trainers can add/manage their client roster and prospects, controlling who can message them

**Blocks:** PR #010 (Calendar needs client/prospect lists)

---

### PR #010: Full Calendar System + AI Natural Language Scheduling
```bash
# Status: ⏳ PENDING
# Branch: feat/pr-010-calendar
# Dependencies: PR #008 (Function Calling), PR #009 (Contacts)
```

**Brief:** Implement comprehensive calendar/appointments system with natural language AI scheduling and Google Calendar sync.

**Deliverables:**
- Firestore `/calendar/{trainerId}/events` collection
- Three event types: Training (🏋️ blue), Calls (📞 green), Adhoc (📅 gray)
- AI natural language parsing ("schedule Sam tomorrow at 6pm")
- Event type detection from keywords
- Client/prospect validation with auto-creation
- Google Calendar OAuth 2.0 integration (one-way sync: Psst → Google)
- CalendarView with week timeline
- "Today's Schedule" widget on chat list
- "Cal" tab in bottom navigation
- Manual event creation UI with event type selector and client picker
- Conflict detection with smart time suggestions
- AI rescheduling and cancellation support
- Calendar settings and preferences

**Testing:**
- Happy path: "schedule session with Sam at 6pm" → Event created + synced to Google Calendar
- Edge case: Conflict detection suggests alternatives
- Error: OAuth token refresh, sync failures

**User Capability:** Trainers can schedule sessions using natural language, view appointments in visual calendar, and have everything automatically sync to Google Calendar

**⭐ Critical for Demo 1** (Marcus - Lead Qualification)

---

### PR #011: Voice AI Interface
```bash
# Status: ⏳ PENDING
# Branch: feat/pr-011-voice-ai
# Dependencies: PR #004, #003
```

**Brief:** Add voice interaction to the AI Assistant for hands-free operation.

**Deliverables:**
- Voice recording UI with push-to-talk and waveform
- OpenAI Whisper API for speech-to-text
- Text-to-speech (AVSpeechSynthesizer or OpenAI TTS)
- `VoiceService.swift` for audio management
- Conversation mode for back-and-forth voice
- Microphone permission handling
- Background audio support
- Voice/text mode toggle

**Testing:**
- Happy path: Record → transcribe → AI responds → speaks
- Edge case: Long recording, background interruption
- Error: Mic permission denied, transcription failure

**User Capability:** Trainers can talk to AI assistant hands-free using voice

---

**Phase 4 Sync Point:** All actions, calendar, and voice features complete → AI becomes interactive scheduling agent

---

## Phase 5: Advanced Features (PR #012, #013, #014, #015, #016)

**Status:** ⏳ Pending | **Dependencies:** Phase 4 Complete

### PR #012: User Preference Storage (Trainer Profile)
```bash
# Status: ⏳ PENDING
# Branch: feat/pr-012-trainer-preferences
# Dependencies: PR #003
```

**Brief:** Allow trainers to configure their business information and AI behavior.

**Deliverables:**
- Trainer settings UI (rates, programs, availability, style)
- Firestore storage: `trainerProfiles/{userId}`
- Integration into AI system prompts
- Preset tone options (Professional, Friendly, Motivational)
- Per-client tone overrides

**Testing:**
- Happy path: Preferences saved, AI uses them
- Edge case: Incomplete preferences
- Error: Save failures

**User Capability:** Trainers configure rates, availability, and AI communication style

---

### PR #013: YOLO Mode (Automated Responses)
```bash
# Status: ⏳ PENDING
# Branch: feat/pr-013-yolo-mode
# Dependencies: PR #012, #008, #003
```

**Brief:** Implement fully automated AI responses for common inquiries.

**Deliverables:**
- YOLO mode toggle (OFF, SCHEDULED, ALWAYS ON)
- Safeguards (question types, preferences required, disclaimers)
- Visual indicators for AI-sent messages
- "Take Over" functionality
- Response review and feedback
- Conversion metrics tracking

**Testing:**
- Happy path: Auto-response sent during configured hours
- Edge case: Complex question flagged for manual review
- Error: YOLO disabled if preferences incomplete

**User Capability:** Automated AI responses handle common questions 24/7

---

### PR #014: Multi-Step Agent (Lead Qualification)
```bash
# Status: ⏳ PENDING
# Branch: feat/pr-014-multi-step-agent
# Dependencies: PR #012, #008, #003
```

**Brief:** Create intelligent multi-turn conversation handling for lead qualification.

**Deliverables:**
- State machine for lead qualification workflow (5 steps)
- Firestore: `leadConversations/{conversationId}`
- Context retention across messages
- "Lead Management" dashboard
- Trainer takeover capability
- Lead quality scoring

**Testing:**
- Happy path: Full qualification flow completes
- Edge case: User abandons mid-flow, resumes later
- Error: State corruption recovery

**User Capability:** AI handles multi-message lead qualification and books intro calls

---

### PR #015: AI Tone Customization (Advanced Presets)
```bash
# Status: ⏳ PENDING
# Branch: feat/pr-015-tone-customization
# Dependencies: PR #012
```

**Brief:** Expand AI communication style options with advanced tone presets.

**Deliverables:**
- Comprehensive tone presets (Professional, Friendly, Motivational, Empathetic, Direct)
- Global default + per-client overrides
- Tone preview system with examples
- Custom tone creation (sliders for formality, emoji, length, energy)
- Firestore: `trainerProfiles/{userId}/tones`
- Smart tone suggestions based on client history

**Testing:**
- Happy path: Tone selected, AI responds in that style
- Edge case: Custom tone with extreme settings
- Error: Invalid tone configuration

**User Capability:** Customize AI communication tone globally and per-client

---

### PR #016: Error Handling & Fallback System
```bash
# Status: ⏳ PENDING
# Branch: feat/pr-016-error-handling
# Dependencies: All AI features (cross-cutting)
```

**Brief:** Implement comprehensive error handling across all AI features.

**Deliverables:**
- Unified error handling (timeouts, rate limits, network, service down, quota)
- User-friendly error messages
- Retry mechanisms with exponential backoff
- Fallback modes (messaging works even if AI down)
- Failed request storage for retry
- Admin dashboard for AI system health
- Logging system for debugging

**Testing:**
- Happy path: Transient error retries successfully
- Edge case: Multiple simultaneous failures
- Error: All AI services down, app still functional

**User Capability:** App handles AI failures gracefully with clear error messages

---

**Phase 5 Sync Point:** All advanced features complete → **Full AI Assistant Ready** 🎉

**Final Sync:** Merge to `develop` → QA → Production Deploy 🚀

---

## File Ownership (Avoid Conflicts)

| Agent | Owns | Never Touch |
|-------|------|-------------|
| **Agent 1** | `functions/`, Pinecone config, backend docs | `Psst/Psst/` (iOS code) |
| **Agent 2** | `Psst/Psst/` (iOS app), UI/UX docs | `functions/` (Cloud Functions) |

---

## Quick Start Commands

### Phase 1 (Foundation) - ✅ COMPLETE
```bash
# Already complete - for reference only
/pam 1          # PR #001: AI Backend Infrastructure
/pam 2          # PR #002: iOS AI Scaffolding
/caleb 1        # Implement backend
/caleb 2        # Implement iOS
```

### Phase 2 (Basic AI Chat) - ✅ COMPLETE
```bash
# Already complete - for reference only
/pam 3          # PR #003: AI Chat Backend
/pam 4          # PR #004: AI Chat UI
/caleb 3        # Implement backend
/caleb 4        # Implement iOS
```

### Phase 3 (RAG + Contextual) - ⏳ NEXT UP
```bash
# Ready to start
/pam 5          # PR #005: RAG Pipeline (Semantic Search)
/pam 6          # PR #006: Contextual AI Actions
/pam 7          # PR #007: Auto Client Profiles

/caleb 5        # Implement RAG backend
/caleb 6        # Implement long-press UI
/caleb 7        # Implement profile extraction
```

### Phase 4 (Actions + Calendar + Voice) - ⏳ WAITING
```bash
/pam 8          # PR #008: Function Calling
/pam 9          # PR #009: Contacts System
/pam 10         # PR #010: Calendar + AI Scheduling
/pam 11         # PR #011: Voice AI

/caleb 8        # Implement function calling
/caleb 9        # Implement contacts & relationships
/caleb 10       # Implement calendar system ⭐ Critical for demo
/caleb 11       # Implement voice interface
```

### Phase 5 (Advanced) - ⏳ WAITING
```bash
/pam 12         # PR #012: User Preferences
/pam 13         # PR #013: YOLO Mode
/pam 14         # PR #014: Multi-Step Agent
/pam 15         # PR #015: Tone Customization
/pam 16         # PR #016: Error Handling

/caleb 12       # Implement trainer profiles
/caleb 13       # Implement auto-responses
/caleb 14       # Implement lead qualification
/caleb 15       # Implement tone system
/caleb 16       # Implement error handling
```

---

## Complete PR Roadmap

| PR # | Feature | Phase | Dependencies | Status |
|------|---------|-------|--------------|--------|
| #001 | AI Backend Infrastructure | 1 | None | ✅ Complete |
| #002 | iOS AI Scaffolding | 1 | None | ✅ Complete |
| #003 | AI Chat Backend | 2 | #001 | ✅ Complete |
| #004 | AI Chat UI | 2 | #002, #003 | ✅ Complete |
| #005 | RAG Pipeline | 3 | #001, #003 | ✅ Complete |
| #006 | Contextual AI Actions | 3 | #004, #005 | ✅ Complete |
| #007 | Auto Client Profiles | 3 | #005 | ✅ Complete |
| #008 | Function Calling | 4 | #003 | ✅ Complete |
| #009 | Contacts System | 4 | #006.5 (Roles) | ⏳ Pending |
| #010 | Calendar + AI Scheduling | 4 | #008, #009 | ⏳ Pending ⭐ Demo |
| #011 | Voice AI Interface | 4 | #003, #004 | ⏳ Pending |
| #012 | User Preferences | 5 | #003 | ⏳ Pending |
| #013 | YOLO Mode | 5 | #003, #008, #012 | ⏳ Pending |
| #014 | Multi-Step Agent | 5 | #003, #008, #012 | ⏳ Pending |
| #015 | Tone Customization | 5 | #012 | ⏳ Pending |
| #016 | Error Handling | 5 | All features | ⏳ Pending |

---

## Dependency Graph

```
Phase 1 (Foundation):
  PR #001 (Backend) ─────┐
                         ├──> PR #003 (Chat Backend) ──┐
  PR #002 (iOS) ─────────┤                             │
                         └──> PR #004 (Chat UI) ───────┤
                                                        │
Phase 3 (RAG):                                         │
  PR #005 (RAG) <──────────────────────────────────────┤
      │                                                 │
      ├──> PR #006 (Contextual Actions) <──────────────┘
      │
      └──> PR #007 (Client Profiles) ──┐
                                        │
Phase 4 (Actions):                     │
  PR #008 (Functions) <─────────────────┼──────────────┐
      │                                 │              │
      └──> PR #009 (Proactive) <────────┘              │
                                                        │
  PR #010 (Voice) <───────────────────────────────────┘
                                                        │
Phase 5 (Advanced):                                    │
  PR #011 (Preferences) <──────────────────────────────┤
      │                                                 │
      ├──> PR #012 (YOLO) <─────────────────────────────┤
      │                                                 │
      ├──> PR #013 (Multi-Step) <───────────────────────┤
      │                                                 │
      └──> PR #014 (Tone) <─────────────────────────────┤
                                                        │
  PR #015 (Error Handling) <──────────────────────────┘
```

---

## Feature-to-Requirement Mapping

| AI Requirement | Implementing PRs | Status |
|----------------|------------------|--------|
| **RAG Pipeline** | #005, #007 | ✅ 2/2 Complete |
| **User Preferences** | #012, #013, #015 | ⏳ Pending |
| **Function Calling** | #008, #013, #014 | ✅ 1/3 Complete (#008) |
| **Memory/State** | #003, #007, #014 | ✅ 2/3 Complete (#003, #007) |
| **Error Handling** | #016 + All features | Ongoing |

---

## Demo Coverage (Assignment Requirements)

**Demo 1 (Marcus - Lead Qualification):**
- Requires: PR #006.5 (Roles), #009 (Contacts), #012 (Preferences), #008 (Functions), **#010 (Calendar)** ⭐, #014 (Multi-Step), #013 (YOLO)
- Phase: 4-5
- Status: ⏳ Phase 4-5 pending
- **Critical:** PR #010 (Calendar) required to show AI-scheduled sessions in real Google Calendar

**Demo 2 (Alex - Context Recall):**
- Requires: PR #006.5 (Roles), #009 (Contacts), #005 (RAG), #007 (Profiles), #006 (Contextual), #003 (Chat)
- Phase: 3-4
- Status: ⏳ Phase 3 complete! (4/6 complete: #003, #005, #006, #007 ✅ | #006.5, #009 pending)

---

**Reference Docs:**
- Product vision: `AI-PRODUCT-VISION.md`
- Architecture: `architecture.md`
- Testing strategy: `testing-strategy.md`
- All PR Briefs: `ai-briefs.md`
