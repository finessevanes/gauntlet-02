# AI Build Plan: Parallel Strategy (ACTIVE)

**Decision:** Parallel Build with 2 agents  
**Date:** October 23, 2025  
**Status:** Ready to start Phase 1

---

## Phase 1: Foundation (PR-010a & PR-010b)

### Agent 1: Backend Infrastructure (PR-010a)
```bash
/brenda ai-backend-infrastructure
# Creates: Pinecone index, embeddings, Cloud Functions foundation
# Branch: feat/pr-010a-backend-infra
```

**Deliverables:**
- Pinecone index setup (chat-messages, 1536 dims, cosine)
- Embedding generation service (OpenAI)
- Cloud Function: `generateEmbedding(messageId)`
- Environment variables: `OPENAI_API_KEY`, `PINECONE_API_KEY`, `PINECONE_ENV`

**Testing:** Happy path (embedding generates) + Edge case (invalid message) + Error (API timeout)

---

### Agent 2: iOS AI Scaffolding (PR-010b)
```bash
/brenda ai-ios-scaffolding
# Creates: AIService, models, UI skeleton
# Branch: feat/pr-010b-ios-scaffolding
```

**Deliverables:**
- `AIService.swift` (handles Cloud Function calls)
- `AIMessage.swift`, `AIConversation.swift` models
- Basic `AIAssistantView.swift` skeleton
- Mock data for UI development

**Testing:** Happy path (view renders) + Edge case (empty state) + Error (service unavailable)

---

**Sync Point:** Both merge to `develop` → Integration test

---

## Phase 2: Basic AI Chat (PR-011a & PR-011b)

### Agent 1: AI Chat Backend (PR-011a)
```bash
/brenda ai-chat-backend
# Creates: chatWithAI Cloud Function, AI SDK integration
# Branch: feat/pr-011a-ai-function
```

**Deliverables:**
- Cloud Function: `chatWithAI(userId, message, conversationId)`
- OpenAI ChatGPT integration
- Basic conversation history storage in Firestore
- Response streaming support

**Testing:** Happy path (AI responds) + Edge case (long message) + Error (OpenAI timeout)

---

### Agent 2: AI Chat UI (PR-011b)
```bash
/brenda ai-chat-frontend
# Creates: AIAssistantView, ViewModel, full UI
# Branch: feat/pr-011b-ai-ui
```

**Deliverables:**
- `AIAssistantViewModel.swift` (calls AIService)
- Complete `AIAssistantView.swift` with chat interface
- Message bubbles, input field, loading states
- Integration with Agent 1's `chatWithAI` endpoint

**Testing:** Happy path (send/receive AI chat) + Edge case (rapid messages) + Error (offline mode)

---

**Sync Point:** Merge both → Full integration test → **First working AI chat!** 🎉

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
