# AI Feature PR Briefs

This document contains high-level briefs for all AI-related Pull Requests in the Psst messaging app. Each PR represents a logical, vertical slice of functionality focused on AI capabilities for personal trainers.

**Status:** 🚀 Ready to Start | 0 Completed

---

## Phase 0: Prerequisites

### PR #006.5: User Roles & Required Name

**Brief:** Implement user role distinction (trainer vs client) and require displayName during signup to enable role-based AI features. Add `role` field to User model with values "trainer" or "client". Update SignupView and EmailSignInView to include role selection screen ("Are you a trainer or client?") before account creation. Make displayName field required (no skipping) during signup flow. Update Firestore User schema to include role field. Modify Firestore security rules to support role-based access controls for future features. Display user role badges in profile views and chat headers. Store role in UserDefaults for quick access. This foundational feature is required for PR #007 (Auto Client Profiles) where trainers build profiles for their clients, and other AI features that need to distinguish between trainer and client contexts.

**User Capability:** Users select their role (trainer or client) during signup and provide required display name

**Dependencies:** None (prerequisite for AI features)

**Complexity:** Simple

**Phase:** 0 (Prerequisite)

**Blocks:** PR #007 (Auto Client Profiles), PR #011 (User Preferences), PR #012 (YOLO Mode)

---

## Phase 1: Foundation

### PR #001: AI Backend Infrastructure

**Brief:** Establish the foundational AI infrastructure including Pinecone vector database setup, OpenAI API integration, and Cloud Functions for embedding generation. Create Pinecone index for chat messages with 1536 dimensions and cosine similarity metric. Implement embedding generation service using OpenAI's text-embedding-3-small model. Set up Cloud Function `generateEmbedding(messageId)` that automatically creates vector embeddings for messages. Configure environment variables for `OPENAI_API_KEY`, `PINECONE_API_KEY`, and `PINECONE_ENV`. This foundational infrastructure enables semantic search and RAG capabilities in later phases while remaining invisible to users at this stage.

**User Capability:** Backend systems can generate and store vector embeddings for messages (foundation for future semantic search)

**Dependencies:** None

**Complexity:** Complex

**Phase:** 1

---

### PR #002: iOS AI Scaffolding

**Brief:** Create the iOS-side AI infrastructure including AIService, data models, and UI skeleton for AI features. Implement `AIService.swift` to handle Cloud Function calls and AI interactions. Create Swift models for `AIMessage.swift`, `AIConversation.swift`, and `AIResponse.swift` with proper Codable conformance. Build basic `AIAssistantView.swift` skeleton with placeholder UI components. Set up mock data for AI development and testing without requiring backend connectivity. Establish patterns for async AI operations using Swift's async/await. This scaffolding provides the foundation for all iOS-side AI features while maintaining clean separation of concerns.

**User Capability:** iOS app has AI service layer and models ready for AI feature integration

**Dependencies:** None (can run parallel with PR #001)

**Complexity:** Medium

**Phase:** 1

---

## Phase 2: Basic AI Chat

### PR #003: AI Chat Backend

**Brief:** Implement the core AI chat functionality on the backend including the `chatWithAI` Cloud Function and OpenAI ChatGPT integration. Create Cloud Function that accepts `userId`, `message`, and `conversationId` parameters and returns AI-generated responses. Integrate OpenAI GPT-4 API with proper system prompts for trainer-focused context. Implement conversation history storage in Firestore to maintain context across messages. Add response streaming support for real-time AI reply updates. Include error handling for API timeouts, rate limits, and invalid requests. Store AI conversations separately from regular chats to maintain clear separation. This backend powers the dedicated AI Assistant chat that trainers can use as their "second brain."

**User Capability:** Backend can process AI chat requests and generate contextual responses

**Dependencies:** PR #001 (AI Backend Infrastructure)

**Complexity:** Complex

**Phase:** 2

---

### PR #004: AI Chat UI

**Brief:** Build the complete user-facing AI Assistant chat interface where trainers can ask questions and get instant answers. Implement `AIAssistantViewModel.swift` to manage AI conversation state and coordinate with AIService. Create polished `AIAssistantView.swift` with chat interface including message bubbles (user in blue, AI in gray), text input field, send button, loading states with typing indicators, and error handling UI. Add floating AI button (🤖) accessible from main chat list that opens the AI Assistant. Implement real-time message updates with smooth animations. Handle offline mode gracefully with queued messages. Include empty state for first-time users with example prompts ("What did John say about his knee?"). This is the primary interface trainers use to interact with their AI assistant.

**User Capability:** Trainers can chat with AI assistant to ask questions and get instant answers

**Dependencies:** PR #002 (iOS AI Scaffolding), PR #003 (AI Chat Backend)

**Complexity:** Medium

**Phase:** 2

---

## Phase 3: RAG + Contextual Intelligence

### PR #005: RAG Pipeline (Semantic Search)

**Brief:** Implement Retrieval Augmented Generation (RAG) to enable AI to search past conversations and provide context-aware answers. Build vector similarity search in Pinecone that finds semantically similar messages across all trainer conversations. Create message embedding indexing pipeline that automatically embeds new messages as they're sent. Implement Cloud Function `semanticSearch(query, userId, limit)` that takes natural language queries and returns relevant past messages. Integrate RAG into the existing `chatWithAI` function so AI responses include context from past conversations. Add relevance scoring to surface most useful historical messages. Handle edge cases like no results found, empty message history, and Pinecone timeouts. This transforms the AI from a simple chatbot into a "second brain" that remembers everything clients have said.

**User Capability:** AI can search past conversations and answer questions about client history ("What did Sarah say about her diet?")

**Dependencies:** PR #001 (AI Backend Infrastructure), PR #003 (AI Chat Backend)

**Complexity:** Complex

**Phase:** 3

---

### PR #006: Contextual AI Actions (Long-Press Menu)

**Brief:** Add contextual AI actions directly in conversations via long-press gestures on messages. Implement long-press menu with three AI-powered actions: (1) Summarize Conversation - AI provides concise summary of the conversation or selected message thread, (2) Set Reminder - AI extracts key information and creates reminder for follow-up, (3) Surface Context - AI searches past messages for related topics and displays relevant history. Create smooth contextual menu UI with icons and haptic feedback. Implement inline AI results display that shows summaries or context without leaving the chat view. Add loading states for AI processing and error handling for when AI is unavailable. Include animations for menu appearance and result presentation. This feature embeds AI intelligence directly into the messaging workflow without requiring trainers to switch to the AI Assistant chat.

**User Capability:** Trainers can long-press any message to get AI summaries, set reminders, or view related past conversations

**Dependencies:** PR #004 (AI Chat UI), PR #005 (RAG Pipeline)

**Complexity:** Medium

**Phase:** 3

---

### PR #007: Contextual Intelligence (Auto Client Profiles)

**Brief:** Automatically build rich client profiles from conversations without manual data entry. Implement background processing that extracts and categorizes client information as messages are exchanged: injuries (shoulder pain, knee issues), goals (lose 20 lbs, marathon training), equipment (home gym, dumbbells only), preferences (prefers morning workouts, vegetarian), travel schedules (in Dallas monthly), and stress factors (new job, finals week). Store structured profile data in Firestore under `clientProfiles/{clientId}` with automatic updates when new relevant information appears. Create UI to view auto-generated client profiles with categorized information and timestamps. Allow manual edits and corrections to AI-extracted data. Surface relevant profile information when trainer opens a conversation ("Mike mentioned shoulder pain 2 weeks ago"). This creates a living, breathing knowledge base about each client that grows automatically.

**User Capability:** AI automatically remembers and organizes client details (injuries, goals, equipment, preferences) from conversations

**Dependencies:** PR #005 (RAG Pipeline for extraction)

**Complexity:** Complex

**Phase:** 3

---

## Phase 4: Actions + Voice

### PR #008: AI Function Calling (Tool Integration)

**Brief:** Enable AI to execute actions instead of just providing information by implementing OpenAI function calling. Define AI tools (functions): `scheduleCall(clientName, dateTime, duration)` to book calendar events, `setReminder(clientName, reminderText, dateTime)` to create follow-up reminders, `sendMessage(chatId, messageText)` to send messages on trainer's behalf, and `searchMessages(query, chatId, limit)` to find specific past messages. Implement function execution handlers in Cloud Functions that validate parameters and execute actions safely. Add confirmation UI for actions before execution (except in YOLO mode). Handle function failures gracefully with fallback options. Store function execution history for audit trail. This transforms the AI from passive assistant to active agent that can take actions to help trainers manage their business.

**User Capability:** AI can execute actions like scheduling calls, setting reminders, and sending messages (with trainer approval)

**Dependencies:** PR #003 (AI Chat Backend)

**Complexity:** Complex

**Phase:** 4

---

### PR #009: Proactive Assistant (Churn Prevention)

**Brief:** Implement proactive suggestions where AI identifies patterns and recommends actions without being asked. Create background job that analyzes client engagement patterns daily, identifying clients who haven't messaged in 14+ days (at-risk), clients nearing program milestones (encourage), and clients showing signs of frustration or confusion (support needed). Generate personalized follow-up message suggestions based on conversation history and client profile. Create notification system that alerts trainers to proactive suggestions with push notifications. Implement "Suggestions" tab in AI Assistant showing all pending recommendations with one-tap send. Allow trainers to approve, edit, or dismiss suggestions. Track suggestion acceptance rate to improve recommendations. This prevents client churn by ensuring no one falls through the cracks.

**User Capability:** AI proactively identifies clients who need check-ins and suggests personalized follow-up messages

**Dependencies:** PR #005 (RAG Pipeline), PR #007 (Client Profiles), PR #008 (Function Calling)

**Complexity:** Complex

**Phase:** 4

---

### PR #010: Voice AI Interface

**Brief:** Add voice interaction to the AI Assistant for hands-free operation while trainers are on the go. Implement voice recording UI with push-to-talk button and audio waveform visualization. Integrate OpenAI Whisper API for speech-to-text transcription of voice messages. Add text-to-speech for AI responses using iOS AVSpeechSynthesizer or OpenAI TTS. Create `VoiceService.swift` to manage audio recording, playback, and permission handling. Implement conversation mode where trainers can have back-and-forth voice discussions with AI. Add visual feedback for voice processing states (listening, transcribing, generating response, speaking). Handle microphone permissions gracefully with clear explanations. Support background audio for voice responses. Include toggle to switch between voice and text modes. This enables trainers to manage their business while walking between sessions or driving.

**User Capability:** Trainers can talk to AI assistant hands-free using voice instead of typing

**Dependencies:** PR #004 (AI Chat UI), PR #003 (AI Chat Backend)

**Complexity:** Medium

**Phase:** 4

---

## Phase 5: Advanced Features

### PR #011: User Preference Storage (Trainer Profile)

**Brief:** Allow trainers to configure their business information and AI behavior so the AI can respond accurately in their voice. Create trainer settings UI for: rates ($150/hour 1-on-1, $50/person group sessions), programs offered (strength training, marathon prep, weight loss), availability (unavailable Sundays, prefers morning calls), communication style (professional/friendly/motivational), auto-response boundaries (what AI can/can't say). Store preferences in Firestore under `trainerProfiles/{userId}` with structured fields for each category. Integrate preferences into AI system prompts so responses include accurate business information. Add preset tone options with examples (Professional: formal language, Friendly: casual emoji use, Motivational: energetic encouragement). Allow per-client tone overrides (corporate client gets professional, casual friend gets friendly). This ensures AI represents the trainer authentically and provides accurate information to leads.

**User Capability:** Trainers can configure their rates, availability, and AI communication style so AI responds in their voice

**Dependencies:** PR #003 (AI Chat Backend)

**Complexity:** Medium

**Phase:** 5

---

### PR #012: YOLO Mode (Automated Responses)

**Brief:** Implement fully automated AI responses that handle common inquiries while trainers sleep or are busy. Add YOLO mode toggle in settings with three options: OFF (AI only suggests, never sends), SCHEDULED (auto-respond during specific hours like 8pm-8am), ALWAYS ON (auto-respond to everything). Create safeguards: only auto-respond to specific question types (rates, availability, program info), require trainer preferences configured before enabling, include disclaimer in auto-responses ("AI assistant for [Trainer Name]"), flag complex questions for manual review. Implement visual indicators showing which messages were AI-sent vs trainer-sent in conversation history. Add "Take Over" button for trainers to disable YOLO mid-conversation. Store all auto-responses for trainer review and feedback. Track conversion metrics (leads qualified, calls booked). This solves the "always on" problem by letting AI handle routine questions 24/7.

**User Capability:** Trainers can enable automated AI responses to handle common questions while they're unavailable

**Dependencies:** PR #011 (User Preferences), PR #008 (Function Calling), PR #003 (AI Chat Backend)

**Complexity:** Complex

**Phase:** 5

---

### PR #013: Multi-Step Agent (Lead Qualification)

**Brief:** Create intelligent multi-turn conversation handling where AI guides prospects through complete qualification flows. Implement state machine for lead qualification workflow: (1) Greet and ask about goals, (2) Discuss fitness background and experience level, (3) Identify any injuries or limitations, (4) Present relevant program and pricing, (5) Book intro call or consultation. Store conversation state in Firestore `leadConversations/{conversationId}` with current step, collected information, and next actions. Enable AI to remember context across multiple messages and continue naturally where it left off. Create "Lead Management" dashboard showing all active leads, their qualification status, and AI conversation summaries. Allow trainers to review AI conversations and take over at any time. Generate lead quality scores based on responses. This transforms the AI into a 24/7 sales assistant that qualifies leads while trainers focus on actual training.

**User Capability:** AI can handle multi-message lead qualification conversations and book intro calls automatically

**Dependencies:** PR #011 (User Preferences), PR #008 (Function Calling), PR #003 (AI Chat Backend with memory)

**Complexity:** Complex

**Phase:** 5

---

### PR #014: AI Tone Customization (Advanced Presets)

**Brief:** Expand AI communication style options with advanced tone presets and detailed customization. Create comprehensive tone system with presets: Professional (formal, no emojis, structured responses), Friendly (casual, warm emojis, conversational), Motivational (energetic, lots of encouragement, exclamation points), Empathetic (understanding, supportive, gentle), Direct (concise, no-nonsense, efficient). Allow global default tone plus per-client overrides stored in client profiles. Implement tone preview system where trainers can see example AI responses in each tone before selecting. Add custom tone creation with sliders for formality, emoji usage, response length, and energy level. Store tone preferences in `trainerProfiles/{userId}/tones` and reference in AI system prompts. Include smart tone suggestions based on client interaction history (client uses emojis → suggest Friendly tone). This ensures every AI interaction feels authentic to the trainer's brand and appropriate for each client relationship.

**User Capability:** Trainers can customize AI communication tone globally and per-client with detailed preset options

**Dependencies:** PR #011 (User Preferences)

**Complexity:** Medium

**Phase:** 5

---

### PR #015: Error Handling & Fallback System

**Brief:** Implement comprehensive error handling across all AI features to ensure graceful degradation when services fail. Create unified error handling system for: API timeouts (OpenAI, Pinecone), rate limit exceeded (429 errors), invalid requests (malformed data), network failures (offline mode), service unavailable (500 errors), and quota exceeded (billing issues). Implement user-friendly error messages: "AI is taking too long. Try again in a moment" (timeout), "Too many requests. Please wait 30 seconds" (rate limit), "I can't do that, but I can help you search conversations instead" (invalid request), "AI unavailable right now. Your message is saved" (service down). Add retry mechanisms with exponential backoff for transient failures. Implement fallback modes where core messaging works even when AI is down. Store failed AI requests for later retry. Include admin dashboard showing AI system health and error rates. Create logging system for debugging AI issues.

**User Capability:** App handles AI failures gracefully with clear error messages and fallback options

**Dependencies:** All AI features (cross-cutting concern)

**Complexity:** Medium

**Phase:** 5

---

## 📊 Summary

### Project Progress
- **Phase 1 (Foundation):** 0/2 Complete (0%)
- **Phase 2 (Basic AI Chat):** 0/2 Complete (0%)
- **Phase 3 (RAG + Context):** 0/3 Complete (0%)
- **Phase 4 (Actions + Voice):** 0/3 Complete (0%)
- **Phase 5 (Advanced):** 0/5 Complete (0%)

### Overall Status
- **Total PRs:** 15
- **Completed:** 0 (0%)
- **In Progress:** 0
- **Pending:** 15 (100%)

### Next Steps
Start with Phase 1 parallel development:
1. `/pam 1` - AI Backend Infrastructure
2. `/pam 2` - iOS AI Scaffolding

Both can be developed in parallel by different agents since they have no dependencies on each other.

---

## Feature-to-Requirement Mapping

| AI Requirement | PRs That Implement It |
|----------------|----------------------|
| **RAG Pipeline** | PR #5 (Semantic Search), PR #7 (Client Profiles), PR #9 (Proactive) |
| **User Preferences** | PR #11 (Trainer Profile), PR #12 (YOLO Mode), PR #14 (Tone) |
| **Function Calling** | PR #8 (Tool Integration), PR #9 (Proactive), PR #12 (YOLO), PR #13 (Multi-Step) |
| **Memory/State** | PR #3 (Chat Backend), PR #7 (Profiles), PR #13 (Multi-Step) |
| **Error Handling** | PR #15 (Fallback System) + All features |

---

## Assignment Demo Coverage

**Demo 1 (Marcus - Lead Qualification):**
- Uses PR #11 (User Preferences)
- Uses PR #8 (Function Calling)
- Uses PR #13 (Multi-Step Agent)
- Uses PR #12 (YOLO Mode)

**Demo 2 (Alex - Context Recall):**
- Uses PR #5 (RAG Pipeline)
- Uses PR #7 (Client Profiles)
- Uses PR #6 (Contextual Actions)
- Uses PR #3 (AI Chat Backend)

Both demos will be functional after Phase 5 completion.

---

Each PR is designed to deliver a complete, testable AI capability that builds incrementally toward the full AI assistant vision described in AI-PRODUCT-VISION.md.

