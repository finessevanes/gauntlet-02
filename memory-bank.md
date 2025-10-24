# Memory Bank

I am an expert software engineer with memory that resets between sessions. This Memory Bank is my single source of truth. I MUST read this file at the start of EVERY task - this is not optional.

---

## 1. Project Brief

**Project:** Psst - Personal Trainer Messaging App with AI  
**Type:** Native iOS Chat Application (SwiftUI + Firebase)  
**Current Phase:** MVP Complete ✅ | Next: AI Features (Phase 1-5)

### Core Foundation (MVP Complete ✅)
1. ✅ One-on-one chat functionality
2. ✅ Real-time message delivery (2+ users)
3. ✅ Message persistence (survives app restarts)
4. ✅ Optimistic UI updates
5. ✅ Online/offline status indicators
6. ✅ Message timestamps
7. ✅ User authentication (email/password + Google Sign-In)
8. ✅ Group chat functionality (3+ users)
9. ✅ Message read receipts
10. ✅ Push notifications

### AI Features (Next Build - Phase 1-5)
1. AI Chat Assistant (semantic search over conversations)
2. YOLO Mode (auto-responses in trainer's voice)
3. Proactive Assistant (client retention, follow-ups)
4. Function Calling (schedule, remind, send messages)
5. Voice Interface (speech-to-text, voice commands)
6. Contextual AI Actions (summarize, surface context, set reminders)

---

## 2. Product Context

### Why This Exists
**For personal trainers** managing 15-30+ clients across messaging platforms. Solves **3 core problems**:

1. **Information Overload** - Can't remember every client's history, injuries, goals
2. **No Boundaries** - Always "on", repetitive questions, can't scale
3. **Client Retention** - Clients go quiet, trainers forget to follow up, 30-50% churn

### How AI Solves These Problems

**AI as "Second Brain":**
- RAG Pipeline: Semantic search ("What did John say about his knee?")
- Memory/State: Tracks client contexts, engagement patterns
- User Preferences: Learns trainer's voice, rates, style
- Function Calling: AI can actually send messages, book calls, set reminders
- Error Handling: Graceful failures, always functional

**Key Personas:**
- **Marcus** (Remote Worker Trainer) - Needs boundaries, struggles with retention
- **Alex** (Adaptive Trainer) - Info overload, too many clients to track mentally

### Rubric Alignment
**Chosen Persona:** Content Creator/Influencer  
**Required AI Features:**
1. Auto-categorization (sort by topic)
2. Response drafting (YOLO mode)
3. FAQ auto-responder (lead qualification)
4. Sentiment analysis (churn prediction)
5. Collaboration scoring (engagement tracking)

**Target Score:** 90+ / 100

---

## 3. Agent System

### The Team

**Brenda (Brief Creator)**
- Creates PR briefs from feature requirements or documents
- Assigns PR numbers, defines scope
- Command: `/brenda [feature-name-or-document-paths]`

**Pam (Planning Agent)**
- Creates PRDs and TODOs from briefs
- Supports greenfield + brownfield modes
- Command: `/pam pr-N [brownfield] [yolo]`

**Arnold (The Architect)**
- Documents existing codebase for brownfield work
- Identifies integration points
- Command: `/arnold [document]`

**Claudia (UX Expert)**
- Creates UI/UX specs, wireframes
- Designs user flows and interactions
- Command: `/claudia pr-N`

**Quinn (Test Architect & Risk Analyst)**
- Assesses risks, costs, and integration complexity
- Identifies new tools and learning curves
- Command: `/quinn pr-N`

**Caleb (Coder Agent)**
- Implements features from PRDs/TODOs
- Checks off tasks, creates tests
- Command: `/caleb pr-N`

### Workflows

**Greenfield (New Features):**
```
Brenda → Pam → Claudia (optional) → Caleb
```

**Brownfield (Enhancements to Existing Code):**
```
Arnold → Brenda → Pam (brownfield mode) → Caleb
```

---

## 4. Active Context

### Current Work Focus
**Phase:** Post-MVP / Pre-AI Development  
**Status:** Documentation refactored, ready to build AI features

### Recent Major Changes
- ✅ AI-PRODUCT-VISION.md finalized (3 problems, 2 personas, no translation)
- ✅ Testing strategy refactored (user-centric: happy path, edge cases, error handling)
- ✅ Added Arnold agent for brownfield documentation
- ✅ Added brownfield mode to Pam
- ✅ Removed translation features (not needed for rubric)
- ✅ Created ai-tone-presets.md reference

### Next Steps
1. **Run Arnold** to document existing Psst iOS codebase
2. **Create AI PR briefs** with Brenda
3. **Start Phase 1:** Pinecone setup + iOS AI scaffolding (parallel build)
4. **Build in 5 phases:** Foundation → Basic Chat → RAG → Advanced → Polish

### Active Decisions

**AI Feature Scope:**
- ✅ Focus on 3 universal trainer problems (not 4)
- ✅ Remove translation (niche problem, not needed for 90+ score)
- ✅ Align with Content Creator/Influencer rubric persona

**Testing Approach:**
- ✅ User-centric manual validation (not automated yet)
- ✅ 3 scenarios per PR: Happy path, 1-2 edge cases, error handling
- ✅ Multi-device testing optional (only for real-time features)
- ✅ Automated testing deferred to Phase 6+

**Build Strategy:**
- ✅ Parallel build with 2 agents (40% faster)
- ✅ Agent 1: Backend (functions/, Pinecone)
- ✅ Agent 2: Frontend (Psst/Psst/, iOS)

---

## 5. System Patterns

### Architecture Overview
**Pattern:** MVVM (Model-View-ViewModel) with SwiftUI  
**Backend:** Firebase (Auth, Firestore, Realtime DB, FCM, Functions)  
**AI Backend:** Firebase Cloud Functions + OpenAI GPT-4 + Pinecone (vector search)

### Tech Stack

**iOS App:**
- SwiftUI (iOS 16+)
- Swift 5.9+
- Firebase iOS SDK
- Async/await concurrency

**AI Backend:**
- Firebase Cloud Functions (TypeScript/Node.js)
- AI SDK by Vercel (agent framework)
- OpenAI GPT-4 (AI model)
- Pinecone (vector search)

**Data Storage:**
- Firestore: Chats, messages, users
- Pinecone: Message embeddings (vector search)
- Firebase Realtime DB: Presence only

### Critical Patterns

**Existing (MVP):**
- Optimistic UI: Local updates before server confirm
- Offline-first: Firestore persistence enabled
- Real-time listeners: Firestore snapshots
- Server timestamps: `FieldValue.serverTimestamp()`

**New (AI Features):**
- RAG Pipeline: Vector search with embeddings
- Function Calling: AI triggers actions (schedule, send, remind)
- Multi-turn conversations: State management in Firestore
- Error handling: Graceful fallbacks at every layer

---

## 6. Documentation Structure

### Core Documents (Read These)

**Product & Planning:**
- `Psst/docs/AI-PRODUCT-VISION.md` - What/Why (3 problems, 2 personas) **[REQUIRED]**
- `Psst/docs/AI-BUILD-PLAN.md` - 5-phase implementation plan **[REQUIRED]**

**Technical Architecture:**
- `Psst/docs/architecture.md` - System architecture (Arnold creates/updates) **[REQUIRED]**

**Standards & Templates:**
- `Psst/agents/shared-standards.md` - Code quality, testing standards
- `Psst/agents/prd-template.md` - PRD format
- `Psst/agents/todo-template.md` - TODO format

**Reference Materials:**
- `Psst/docs/reference/AI-ASSIGNMENT-SPEC.md` - Assignment requirements
- `Psst/docs/reference/ai-tone-presets.md` - AI tone examples
- `Psst/docs/testing-strategy.md` - Testing approach

### Agent Instructions
- `Psst/agents/arnold-agent.md` - Architect
- `Psst/agents/pam-agent.md` - Planning
- `Psst/agents/caleb-agent.md` - Coding
- `Psst/agents/creative-claudia-agent.md` - UX Design

### File Organization
```
Psst/docs/
├── pr-briefs.md           ← All PR descriptions
├── prds/pr-{N}-prd.md     ← Individual PRDs
├── todos/pr-{N}-todo.md   ← Individual TODOs
└── ux-specs/pr-{N}-ux-spec.md ← UI/UX specs
```

---

## 7. Key Reminders

### Testing Standards (Updated!)
**Philosophy:** User-centric manual validation

**Every PR tests 3 scenarios:**
1. **Happy Path** - Main user flow works end-to-end
2. **Edge Cases** - 1-2 non-standard inputs handled gracefully
3. **Error Handling** - Offline/timeout/invalid input show clear messages

**Not:** Complex multi-device, automated unit tests (Phase 6+)

### Brownfield Best Practices
When enhancing existing code:
1. Run `/arnold document` first
2. Use `/pam pr-N brownfield` for planning
3. Pam reads architecture.md before writing PRD
4. PRD includes "Affected Existing Code" section
5. Caleb respects existing patterns (MVVM, service layer)
6. Include regression testing requirements

### Git Strategy
- **Base branch:** `develop` (never `main`)
- **Branch naming:** `feat/pr-{number}-{feature-name}`
- **PR target:** Always `develop`

### Performance Targets (From shared-standards.md)
- App load: < 2-3 seconds
- Message delivery: < 100ms
- Scrolling: 60fps with 100+ messages
- Tap feedback: < 50ms

---

## 8. Current Status

### What's Complete ✅
**MVP (14/14 PRs):**
- User authentication (email + Google Sign-In)
- One-on-one messaging
- Group chat (3+ users)
- Real-time sync across devices
- Offline persistence
- Read receipts
- Typing indicators
- Push notifications
- Presence system
- Profile management
- Message queuing

### What's Next 🚀
**AI Features (Phase 1-5):**

**Phase 1:** Foundation
- Pinecone vector database setup
- iOS AI scaffolding
- Parallel build (2 agents)

**Phase 2:** Basic AI Chat
- AI Assistant chat screen
- chatWithAI Cloud Function
- Simple Q&A

**Phase 3:** RAG + UI
- Vector search implementation
- Semantic query handling
- Contextual AI menu (long-press)

**Phase 4:** Advanced Features
- Function calling (schedule, send, remind)
- Voice interface

**Phase 5:** Polish
- User preferences (AI tone customization)
- Advanced agents (YOLO mode)
- Final integration

### Known Context
- MVP is complete and functional
- AI features are greenfield (new code) + brownfield (enhance existing)
- Documentation refactored for clarity
- Ready to start building AI features

---

## 9. Important Commands

### Quick Start AI Development
```bash
/arnold document                        # Document existing codebase
/brenda AI-PRODUCT-VISION.md AI-BUILD-PLAN.md  # Create all AI feature briefs
/pam pr-010a                            # Backend PRD
/pam pr-010b                            # Frontend PRD
/caleb pr-010a                          # Agent 1 builds backend
/caleb pr-010b                          # Agent 2 builds frontend
```

### Standard Workflow
```bash
/brenda [feature-or-docs]               # Create brief(s)
/pam pr-N [brownfield] [yolo]           # Create PRD + TODO
/claudia pr-N                           # Optional: UX specs
/caleb pr-N                             # Implement feature
```

---

## 10. Tech Decisions Summary

| Decision | Rationale | Status |
|----------|-----------|--------|
| SwiftUI + Firebase | Fast development, real-time built-in | ✅ Working |
| MVVM architecture | Clean separation, testable | ✅ Working |
| Firestore + Realtime DB hybrid | Best of both for messaging + presence | ✅ Working |
| AI SDK by Vercel | Simpler than LangChain, great for Cloud Functions | 📋 Planned |
| OpenAI GPT-4 | Best function calling for agent tasks | 📋 Planned |
| Pinecone | Purpose-built vector database, simple API, free tier | 📋 Planned |
| User-centric testing | Speed over automation (for now) | ✅ Adopted |
| 3-scenario testing | Happy path + edge cases + error handling | ✅ Adopted |

---

## Success Criteria

### MVP (Completed) ✅
All 10 core requirements met - messaging app fully functional

### AI Features (Next)
**Assignment Rubric Requirements:**
- RAG Pipeline ✅ Planned (Phase 3)
- User Preferences ✅ Planned (Phase 5)
- Function Calling ✅ Planned (Phase 4)
- Memory/State Management ✅ Planned (Phase 2-5)
- Error Handling ✅ Planned (All phases)

**Target:** 90+ / 100 score on MessageAI rubric

---

**Last Updated:** October 23, 2025  
**Next Milestone:** Phase 1 - AI Backend Infrastructure + iOS Scaffolding
