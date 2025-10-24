# AI Build Plan: Parallel Strategy (ACTIVE)

**Decision:** Parallel Build with 2 agents  
**Date:** October 23, 2025  
**Status:** Phase 1 - iOS Scaffolding ✅ COMPLETE

---

## Progress Overview

| Phase | Backend (Agent 1) | iOS (Agent 2) | Status |
|-------|------------------|---------------|---------|
| **Phase 1: Foundation** | ✅ PR-001 Complete | ✅ PR-002 Complete | 100% |
| **Phase 2: Basic AI Chat** | ⏳ Waiting (PR-003) | ✅ PR-004 Complete | 50% |
| **Phase 3: RAG + Contextual** | ⏳ Waiting | ⏳ Waiting | 0% |
| **Phase 4: Functions + Voice** | ⏳ Waiting | ⏳ Waiting | 0% |
| **Phase 5: Advanced** | ⏳ Waiting | ⏳ Waiting | 0% |

**Next Steps:** Complete PR-003 (AI Chat Backend) to enable full AI chat functionality
**Status:** Phase 2 iOS Complete ✅ (using mocks) | Waiting for backend

---

## Phase 1: Foundation (PR-010a & PR-010b)

### Agent 1: Backend Infrastructure (PR-010a) ✅ COMPLETE
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

### Agent 2: iOS AI Scaffolding (PR-002) ✅ COMPLETE
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

**Sync Point:** 
- ✅ **Agent 2 Complete:** iOS scaffolding ready for integration
**Progress:** 1/2 complete (50%)  
**Next:** PR-010b (iOS AI Scaffolding) - Ready to start  
**Sync Point:** Both merge to `develop` → Integration test

---

## Phase 2: Basic AI Chat (PR-003 & PR-004)

**Status:** iOS Complete ✅ | Backend Pending

### Agent 1: AI Chat Backend (PR-003)
```bash
# Status: ⏳ PENDING
# Branch: TBD
```

**Deliverables:**
- Cloud Function: `chatWithAI(userId, message, conversationId)`
- OpenAI ChatGPT integration
- Basic conversation history storage in Firestore
- Response streaming support

**Testing:** Happy path (AI responds) + Edge case (long message) + Error (OpenAI timeout)

---

### Agent 2: AI Chat UI (PR-004) ✅ COMPLETE
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

**Status:** Merged to `feat/pr-004-ai-chat-ui` - Ready for backend integration when PR-003 completes

---

**Sync Point:** PR-003 deployment → Flip feature flag → **First working AI chat!** 🎉

---

## Phase 3: RAG + Contextual UI (PR-012a & PR-014)

### Agent 1: RAG Pipeline (PR-012a)
```bash
/brenda rag-backend
# Creates: Vector search, semantic query engine
# Branch: feat/pr-012a-rag-pipeline
```

**Deliverables:**
- Vector similarity search in Pinecone
- Message embedding indexing pipeline
- Cloud Function: `semanticSearch(query, userId, limit)`
- RAG integration into `chatWithAI`

**Testing:** Happy path (semantic search finds relevant messages) + Edge case (no results) + Error (Pinecone timeout)

---

### Agent 2: Contextual AI UI (PR-014)
```bash
/brenda contextual-ai-ui
# Creates: Long-press menu, contextual actions
# Branch: feat/pr-014-contextual-ai
```

**Deliverables:**
- Long-press menu on messages (Summarize, Set Reminder, Surface Context)
- Contextual action handlers in ChatView
- Inline AI results display
- UX polish with animations

**Testing:** Happy path (long-press shows menu, actions work) + Edge case (spam long-press) + Error (AI unavailable)

---

**Sync Point:** Mid-phase check-in, end-of-phase merge

---

## Phase 4: Function Calling + Voice (PR-013 & PR-016)

### Agent 1: Function Calling (PR-013)
```bash
/brenda ai-function-calling
# Creates: AI tools (schedule, remind, send)
# Branch: feat/pr-013-function-calling
```

**Deliverables:**
- OpenAI function calling setup
- Tools: `scheduleCall()`, `setReminder()`, `sendMessage()`
- Function execution handlers in Cloud Functions
- Integration with calendar and notifications

**Testing:** Happy path (AI calls function, action executes) + Edge case (invalid params) + Error (function execution fails)

---

### Agent 2: Voice AI Interface (PR-016)
```bash
/brenda voice-ai-interface
# Creates: Voice recording, transcription, playback
# Branch: feat/pr-016-voice-ai
```

**Deliverables:**
- Voice recording UI component
- OpenAI Whisper integration for transcription
- Text-to-speech for AI responses
- `VoiceService.swift` for audio handling

**Testing:** Happy path (record → transcribe → AI responds) + Edge case (long recording) + Error (mic permission denied)

---

**Sync Point:** End-of-phase merge

---

## Phase 5: Advanced Features (PR-015)

### Agent 1: Advanced Agents (PR-015)
```bash
/brenda advanced-agents-backend
# Creates: Proactive assistant, preferences, state management
# Branch: feat/pr-015-advanced-agents
```

**Deliverables:**
- User preference storage in Firestore
- Conversation state management
- Proactive suggestion triggers
- Multi-step conversation handling

**Testing:** Happy path (preferences save, YOLO mode works) + Edge case (multi-turn conversation) + Error (state corruption recovery)

---

### Agent 2: Integration & Polish
**No new PRs** - Focus on:
- End-to-end testing
- Bug fixes from Agent 1's work
- Performance optimization
- Documentation updates

---

**Final Sync:** Merge to `develop` → QA → Deploy 🚀

---

## File Ownership (Avoid Conflicts)

| Agent | Owns | Never Touch |
|-------|------|-------------|
| **Agent 1** | `functions/`, Pinecone config, backend docs | `Psst/Psst/` (iOS code) |
| **Agent 2** | `Psst/Psst/` (iOS app), UI/UX docs | `functions/` (Cloud Functions) |

---

## Quick Start Commands

```bash
# Phase 1 - Start now
/brenda ai-backend-infrastructure     # Creates PR-010a
/brenda ai-ios-scaffolding            # Creates PR-010b

# Then use Pam + Caleb
/pam pr-010a    # Agent 1
/pam pr-010b    # Agent 2

/caleb pr-010a  # Agent 1 implements
/caleb pr-010b  # Agent 2 implements
```

---

**Reference Docs:**
- Product vision: `AI-PRODUCT-VISION.md`
- Architecture: `architecture.md`
- Testing strategy: `testing-strategy.md`
