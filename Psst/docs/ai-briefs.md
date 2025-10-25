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

**Blocks:** PR #007 (Auto Client Profiles), PR #012 (User Preferences), PR #013 (YOLO Mode)

---

### PR #009: Trainer-Client Relationship System & Contact Management

**Brief:** Implement explicit trainer-client relationship model replacing the current "everyone can access everyone" architecture with trainer-controlled access. Create Firestore collections `/contacts/{trainerId}/clients` for active clients and `/contacts/{trainerId}/prospects` for lightweight prospect tracking. Update Firebase security rules so clients can only initiate chats with trainers who explicitly added them as clients. Build "Add Client" UI in trainer app with name + email input that creates client relationship and sends invitation. Implement group chat access rule: when trainer creates group chat with multiple clients, those clients unlock ability to message each other 1-on-1 (peer discovery through shared groups). Support prospect workflow: trainers can add prospects with name only (no email), system generates placeholder `prospect-[name]@psst.app`, prospects appear only in calendar/contacts (not chat list), trainers can upgrade prospects to full clients by adding email and sending invite. Create ContactsView showing two sections: "My Clients" (active relationships) and "Prospects" (pending/lightweight). Include client management actions: view client details, archive client (removes access), resend invitation. Update UserService and ChatService to respect relationship constraints. This foundational access control system enables trainers to manage their business roster and ensures clients only see relevant conversations.

**User Capability:** Trainers can add/manage their client roster and prospects, controlling who can message them and creating secure client relationships

**Dependencies:** PR #006.5 (User Roles - need to distinguish trainers from clients)

**Complexity:** Complex (affects security rules, chat permissions, data model)

**Phase:** 0 (Prerequisite)

**Blocks:** PR #010 (Calendar - needs client/prospect lists for event scheduling)

---

#### Implementation Sub-Tasks (User Stories)

**Story 1: Contact Data Model & Firestore Schema**
- Create `/contacts/{trainerId}/clients/{clientId}` collection with fields: `clientId`, `displayName`, `email`, `phone`, `addedAt`, `status` (active/invited/archived), `invitationSentAt`, `tags` (array for grouping)
- Create `/contacts/{trainerId}/prospects/{prospectId}` collection with fields: `prospectId`, `displayName`, `placeholderEmail`, `notes`, `addedAt`, `convertedToClientId` (null or clientId if upgraded)
- Add `trainerId` reference to User model for clients to track their trainer
- Add index on `trainerId` for efficient client lookups
- Store relationship metadata: `relationshipStartedAt`, `lastContactedAt`

**Story 2: Firebase Security Rules - Access Control**
- Update Firestore security rules: clients can only read/write chats where `trainerId` matches their assigned trainer in `/contacts` collection
- Rule: `allow read, write: if request.auth.uid in resource.data.participants && exists(/databases/$(database)/documents/contacts/$(trainerId)/clients/$(request.auth.uid))`
- Trainers can read/write all chats with their clients
- Group chat rule: clients in same group can message each other if they share a group with their mutual trainer
- Validate relationship exists before allowing chat creation

**Story 3: Add Client UI (Trainer)**
- Create "Add Client" button in ContactsView with bottomSheet form
- Form fields: Display Name (required), Email (required), Phone (optional), Tags (optional)
- Validate email format and check if user already exists in `/users` collection
- If email exists → Create relationship in `/contacts/{trainerId}/clients`, send invitation
- If email doesn't exist → Create invitation record, send email invite to join Psst
- Success message: "✅ Added [Name] as client. Invitation sent!"
- Error handling: duplicate client, invalid email, network failure

**Story 4: Add Prospect UI (Trainer)**
- Add "Add Prospect" option in ContactsView (separate from "Add Client")
- Simplified form: Display Name (required), Notes (optional)
- Generate placeholder email: `prospect-[firstName-lastName]@psst.app`
- Create record in `/contacts/{trainerId}/prospects`
- Prospects tagged with visual indicator: "👤 Prospect" badge
- Empty state: "No prospects yet. Add prospects to track leads before they become clients."

**Story 5: Contacts View UI**
- Create ContactsView.swift with two sections: "My Clients" and "Prospects"
- Client list shows: avatar, display name, last message timestamp, session count badge
- Prospect list shows: name, "Prospect" badge, "Upgrade to Client" button
- Search bar to filter by name
- Pull-to-refresh to sync latest contact data
- Swipe actions: Archive client, Delete prospect, Edit details
- Empty state for new trainers: "Add your first client to get started"

**Story 6: Upgrade Prospect to Client**
- Tap "Upgrade to Client" on prospect → Opens form with pre-filled name
- Add email field (required for upgrade)
- When submitted: creates client relationship, sends invitation, archives prospect record (sets `convertedToClientId`)
- Prospect moves from "Prospects" section to "My Clients" section
- Maintains prospect history in Firestore for tracking lead conversion

**Story 7: Group Chat Peer Discovery**
- When trainer creates group chat with multiple clients (e.g., Sara + Claudia)
- System detects shared group membership in `/chats/{chatId}/participants`
- Update security rules: clients can now initiate 1-on-1 DM with peers from shared groups
- Add "Start Chat" button when viewing peer's profile in group
- Visual indicator in group member list: "You can message Sara directly"

**Story 8: Client Invitation Flow**
- Send email invitation with deep link: `psst://join?trainerId={id}&inviteCode={code}`
- Email template: "[Trainer Name] invited you to join Psst. Download the app and use code: [CODE]"
- Client receives email → Downloads app → Signs up → Enters invite code → Relationship auto-created
- Handle edge cases: expired invites, invalid codes, already-client

**Story 9: Client Management Actions**
- View client details: name, email, phone, tags, added date, session count
- Edit client info (name, tags, notes)
- Archive client: removes access to trainer (doesn't delete messages, just hides)
- Resend invitation (if status = "invited" but not accepted)
- Delete prospect (permanent removal from prospects list)

**Story 10: ContactService.swift - Business Logic**
- `ContactService.swift` with methods:
  - `addClient(name: String, email: String) -> Result<Client, Error>`
  - `addProspect(name: String, notes: String?) -> Result<Prospect, Error>`
  - `upgradeProspectToClient(prospectId: String, email: String) -> Result<Client, Error>`
  - `getClients(trainerId: String) -> [Client]`
  - `getProspects(trainerId: String) -> [Prospect]`
  - `archiveClient(clientId: String)`
  - `searchClients(query: String) -> [Client]`
- Integrate with AuthService for invitation email sending
- Handle Firestore transactions for relationship creation

**Story 11: Update ChatService - Relationship Validation**
- Before creating new chat, validate relationship exists via ContactService
- If client tries to message trainer not in their contacts → Show error: "This trainer hasn't added you yet"
- If trainer tries to message non-client → Auto-prompt "Add [Name] as client first?"
- Cache relationship status locally for offline validation

**Story 12: Migration & Backward Compatibility**
- Migration script for existing users: trainers automatically get all current chat participants added as clients
- Script: Query all chats where `trainerId` is participant → Extract unique `clientIds` → Create relationships in `/contacts`
- Run as Cloud Function on deployment
- Show migration banner in app: "We've updated how client relationships work. Review your client list."

---

#### Technical Architecture

**Firestore Schema:**
```
/contacts/{trainerId}/clients/{clientId}
  - clientId: string (references /users/{clientId})
  - displayName: string
  - email: string
  - phone: string (optional)
  - addedAt: timestamp
  - status: "active" | "invited" | "archived"
  - invitationSentAt: timestamp
  - tags: string[] (e.g., ["weight-loss", "marathon-training"])
  - lastContactedAt: timestamp

/contacts/{trainerId}/prospects/{prospectId}
  - prospectId: string (auto-generated)
  - displayName: string
  - placeholderEmail: string (prospect-name@psst.app)
  - notes: string (optional)
  - addedAt: timestamp
  - convertedToClientId: string (null or clientId after upgrade)
```

**Security Rules Example:**
```javascript
match /chats/{chatId} {
  allow read, write: if request.auth != null && (
    // User is participant in chat
    request.auth.uid in resource.data.participants &&
    // AND user is either trainer OR is client of trainer in this chat
    (resource.data.role == 'trainer' ||
     exists(/databases/$(database)/documents/contacts/$(resource.data.trainerId)/clients/$(request.auth.uid)))
  );
}
```

---

#### Success Criteria

✅ Trainer can add client with email → Client receives invitation
✅ Client who isn't added by trainer cannot message that trainer
✅ Trainer creates group with Sara + Claudia → Sara and Claudia can now DM each other
✅ Trainer can add prospect with name only → Appears in Prospects section
✅ Trainer can upgrade prospect to client → Moves to My Clients section
✅ ContactsView shows two sections: My Clients & Prospects
✅ Firebase security rules enforce relationship constraints
✅ Existing users migrated automatically with all current chat participants as clients
✅ Archive client removes their chat access but preserves message history

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

**Brief:** Enable AI to execute actions instead of just providing information by implementing OpenAI function calling. Define AI tools (functions): `scheduleCall(clientName, dateTime, duration)` to book calendar events in Firestore, `setReminder(clientName, reminderText, dateTime)` to create follow-up reminders, `sendMessage(chatId, messageText)` to send messages on trainer's behalf, and `searchMessages(query, chatId, limit)` to find specific past messages. Implement function execution handlers in Cloud Functions that validate parameters and execute actions safely. Add confirmation UI for actions before execution (except in YOLO mode). Handle function failures gracefully with fallback options. Store function execution history for audit trail in `/aiActions` collection. This transforms the AI from passive assistant to active agent that can take actions to help trainers manage their business.

**User Capability:** AI can execute actions like scheduling calls (Firestore only), setting reminders, and sending messages (with trainer approval)

**Dependencies:** PR #003 (AI Chat Backend)

**Complexity:** Complex

**Phase:** 4

**⚠️ Important:** PR #008 stores calendar events in Firestore only. **PR #010 (Calendar System) is required** to sync these events to trainer's real Google Calendar for the feature to be production-ready and demo-worthy.

---

### PR #011: Voice AI Interface

**Brief:** Add voice interaction to the AI Assistant for hands-free operation while trainers are on the go. Implement voice recording UI with push-to-talk button and audio waveform visualization. Integrate OpenAI Whisper API for speech-to-text transcription of voice messages. Add text-to-speech for AI responses using iOS AVSpeechSynthesizer or OpenAI TTS. Create `VoiceService.swift` to manage audio recording, playback, and permission handling. Implement conversation mode where trainers can have back-and-forth voice discussions with AI. Add visual feedback for voice processing states (listening, transcribing, generating response, speaking). Handle microphone permissions gracefully with clear explanations. Support background audio for voice responses. Include toggle to switch between voice and text modes. This enables trainers to manage their business while walking between sessions or driving.

**User Capability:** Trainers can talk to AI assistant hands-free using voice instead of typing

**Dependencies:** PR #004 (AI Chat UI), PR #003 (AI Chat Backend)

**Complexity:** Medium

**Phase:** 4

---

## Phase 5: Advanced Features

### PR #012: User Preference Storage (Trainer Profile)

**Brief:** Allow trainers to configure their business information and AI behavior so the AI can respond accurately in their voice. Create trainer settings UI for: rates ($150/hour 1-on-1, $50/person group sessions), programs offered (strength training, marathon prep, weight loss), availability (unavailable Sundays, prefers morning calls), communication style (professional/friendly/motivational), auto-response boundaries (what AI can/can't say). Store preferences in Firestore under `trainerProfiles/{userId}` with structured fields for each category. Integrate preferences into AI system prompts so responses include accurate business information. Add preset tone options with examples (Professional: formal language, Friendly: casual emoji use, Motivational: energetic encouragement). Allow per-client tone overrides (corporate client gets professional, casual friend gets friendly). This ensures AI represents the trainer authentically and provides accurate information to leads.

**User Capability:** Trainers can configure their rates, availability, and AI communication style so AI responds in their voice

**Dependencies:** PR #003 (AI Chat Backend)

**Complexity:** Medium

**Phase:** 5

---

### PR #013: YOLO Mode (Automated Responses)

**Brief:** Implement fully automated AI responses that handle common inquiries while trainers sleep or are busy. Add YOLO mode toggle in settings with three options: OFF (AI only suggests, never sends), SCHEDULED (auto-respond during specific hours like 8pm-8am), ALWAYS ON (auto-respond to everything). Create safeguards: only auto-respond to specific question types (rates, availability, program info), require trainer preferences configured before enabling, include disclaimer in auto-responses ("AI assistant for [Trainer Name]"), flag complex questions for manual review. Implement visual indicators showing which messages were AI-sent vs trainer-sent in conversation history. Add "Take Over" button for trainers to disable YOLO mid-conversation. Store all auto-responses for trainer review and feedback. Track conversion metrics (leads qualified, calls booked). This solves the "always on" problem by letting AI handle routine questions 24/7.

**User Capability:** Trainers can enable automated AI responses to handle common questions while they're unavailable

**Dependencies:** PR #012 (User Preferences), PR #008 (Function Calling), PR #003 (AI Chat Backend)

**Complexity:** Complex

**Phase:** 5

---

### PR #014: Multi-Step Agent (Lead Qualification)

**Brief:** Create intelligent multi-turn conversation handling where AI guides prospects through complete qualification flows. Implement state machine for lead qualification workflow: (1) Greet and ask about goals, (2) Discuss fitness background and experience level, (3) Identify any injuries or limitations, (4) Present relevant program and pricing, (5) Book intro call or consultation. Store conversation state in Firestore `leadConversations/{conversationId}` with current step, collected information, and next actions. Enable AI to remember context across multiple messages and continue naturally where it left off. Create "Lead Management" dashboard showing all active leads, their qualification status, and AI conversation summaries. Allow trainers to review AI conversations and take over at any time. Generate lead quality scores based on responses. This transforms the AI into a 24/7 sales assistant that qualifies leads while trainers focus on actual training.

**User Capability:** AI can handle multi-message lead qualification conversations and book intro calls automatically

**Dependencies:** PR #012 (User Preferences), PR #008 (Function Calling), PR #003 (AI Chat Backend with memory)

**Complexity:** Complex

**Phase:** 5

---

### PR #015: AI Tone Customization (Advanced Presets)

**Brief:** Expand AI communication style options with advanced tone presets and detailed customization. Create comprehensive tone system with presets: Professional (formal, no emojis, structured responses), Friendly (casual, warm emojis, conversational), Motivational (energetic, lots of encouragement, exclamation points), Empathetic (understanding, supportive, gentle), Direct (concise, no-nonsense, efficient). Allow global default tone plus per-client overrides stored in client profiles. Implement tone preview system where trainers can see example AI responses in each tone before selecting. Add custom tone creation with sliders for formality, emoji usage, response length, and energy level. Store tone preferences in `trainerProfiles/{userId}/tones` and reference in AI system prompts. Include smart tone suggestions based on client interaction history (client uses emojis → suggest Friendly tone). This ensures every AI interaction feels authentic to the trainer's brand and appropriate for each client relationship.

**User Capability:** Trainers can customize AI communication tone globally and per-client with detailed preset options

**Dependencies:** PR #012 (User Preferences)

**Complexity:** Medium

**Phase:** 5

---

### PR #016: Error Handling & Fallback System

**Brief:** Implement comprehensive error handling across all AI features to ensure graceful degradation when services fail. Create unified error handling system for: API timeouts (OpenAI, Pinecone), rate limit exceeded (429 errors), invalid requests (malformed data), network failures (offline mode), service unavailable (500 errors), and quota exceeded (billing issues). Implement user-friendly error messages: "AI is taking too long. Try again in a moment" (timeout), "Too many requests. Please wait 30 seconds" (rate limit), "I can't do that, but I can help you search conversations instead" (invalid request), "AI unavailable right now. Your message is saved" (service down). Add retry mechanisms with exponential backoff for transient failures. Implement fallback modes where core messaging works even when AI is down. Store failed AI requests for later retry. Include admin dashboard showing AI system health and error rates. Create logging system for debugging AI issues.

**User Capability:** App handles AI failures gracefully with clear error messages and fallback options

**Dependencies:** All AI features (cross-cutting concern)

**Complexity:** Medium

**Phase:** 5

---

### PR #010: Full Calendar System + AI Natural Language Scheduling

**Brief:** Implement comprehensive calendar/appointments system enabling trainers to manage their entire schedule through natural language AI commands and visual calendar UI. Trainers can say "schedule a session with Sam tomorrow at 6pm" and the AI auto-detects event type (Training Session, Call, or Adhoc), validates client/prospect exists, creates event in Firestore, and syncs to Google Calendar. Support three event types with distinct visual treatment: Training Sessions (🏋️ blue - linked to clients), Calls (📞 green - linked to clients/prospects), and Adhoc events (📅 gray - personal appointments like doctor visits or oil changes). Build polished calendar UI with week view timeline, "Today's Schedule" widget on chat list, and dedicated "Cal" tab in bottom navigation. Implement intelligent conflict detection that suggests alternative times when double-booking detected. Handle client/prospect validation: if client doesn't exist when scheduling, AI creates lightweight prospect contact and prompts trainer to upgrade later. Sync all events one-way to Google Calendar (Psst → Google) so trainers see their Psst sessions in their actual calendar app alongside other life appointments. Include manual event creation UI with event type selector, client picker (from contacts PR #009), and standard calendar fields. This transforms Psst into a complete scheduling solution eliminating the need for trainers to juggle multiple calendar apps.

**User Capability:** Trainers can schedule sessions using natural language ("schedule Sam tomorrow at 6pm"), view all appointments in visual calendar UI, and have everything automatically sync to their Google Calendar

**Dependencies:** PR #008 (AI Function Calling - scheduleCall), PR #009 (Contacts - client/prospect lists)

**Complexity:** Complex

**Phase:** 4 (Critical for demo - must have Google Calendar sync visible)

---

#### Implementation Sub-Tasks (User Stories)

**Story 1: Calendar Backend & Firestore Schema**
- Create Firestore `/calendar/{trainerId}/events/{eventId}` collection with fields:
  - `eventId`: string (auto-generated)
  - `trainerId`: string (references /users/{trainerId})
  - `eventType`: "training" | "call" | "adhoc"
  - `title`: string (e.g., "Session with Sam", "Team Call", "Doctor Appointment")
  - `clientId`: string (optional, required for training/call types)
  - `prospectId`: string (optional, if scheduled with prospect)
  - `startTime`: timestamp
  - `endTime`: timestamp
  - `location`: string (optional)
  - `notes`: string (optional)
  - `status`: "scheduled" | "completed" | "cancelled"
  - `googleCalendarEventId`: string (null if not synced)
  - `syncedAt`: timestamp (last sync to Google Calendar)
  - `createdBy`: "ai" | "trainer"
  - `createdAt`: timestamp
- Add Firestore indexes for efficient queries: by trainerId + startTime, by clientId + startTime
- Create CalendarService.swift for CRUD operations on events

**Story 2: AI Natural Language Event Type Detection**
- Enhance `scheduleCall()` function from PR #008 to detect event type from user input:
  - Keywords "session", "training", "workout", "train" → **Training Session**
  - Keywords "call", "phone", "zoom", "meet" → **Call**
  - Keywords "appointment", "doctor", "oil change", "haircut", or anything without client name → **Adhoc**
- Parse natural language date/time: "tomorrow at 6pm", "next Tuesday 3pm", "Monday morning"
- Extract client/prospect name from message and resolve via ContactService
- AI generates appropriate title based on type:
  - Training: "Session with [Client Name]"
  - Call: "Call with [Client Name]"
  - Adhoc: Uses user's original text (e.g., "Doctor appointment")

**Story 3: Client/Prospect Validation & Auto-Creation**
- When AI extracts client name, check if exists in `/contacts/{trainerId}/clients` or `/contacts/{trainerId}/prospects`
- If **client found**: Use `clientId`, create event normally
- If **prospect found**: Use `prospectId`, create event normally
- If **not found**: AI responds: "I don't see [Name] in your contacts. Do you want to add them as a prospect?"
  - User confirms → Create prospect with placeholder email `prospect-[name]@psst.app`
  - Link event to new `prospectId`
  - AI confirms: "✅ Added [Name] as prospect and scheduled [event type] for [time]"
- For adhoc events (no client mentioned): Skip client validation, set `clientId` and `prospectId` to null

**Story 4: Google Calendar Integration (One-Way Sync)**
- Implement OAuth 2.0 flow for Google Calendar API with scope `https://www.googleapis.com/auth/calendar.events`
- Create GoogleCalendarSyncService.swift with methods:
  - `connectGoogleCalendar()` - OAuth flow, store refresh token in Firestore `/users/{userId}/integrations/googleCalendar`
  - `syncEventToGoogle(eventId)` - Create/update event in Google Calendar, store `googleCalendarEventId`
  - `disconnectGoogleCalendar()` - Revoke OAuth token, clear sync data
- When event created/updated in Psst → Immediately sync to Google Calendar (one-way: Psst → Google only)
- Store Google event ID in `googleCalendarEventId` field for tracking
- Handle OAuth token refresh automatically when token expires
- Add "Connect Google Calendar" button in Settings → Calendar

**Story 5: Calendar UI - Week View**
- Create CalendarView.swift with horizontal scrolling week timeline
- Week view shows 7 days (Sun-Sat) with hourly grid (6am-10pm default)
- Each event displays as colored card with:
  - **Training**: 🏋️ Blue card, shows "Session: [Client Name]"
  - **Call**: 📞 Green card, shows "Call: [Client Name]"
  - **Adhoc**: 📅 Gray card, shows custom title (e.g., "Doctor Appointment")
- Tap event → Opens event detail view with edit/delete options
- Show "current time" indicator line moving down the timeline
- Support infinite scroll: swipe left/right to load more weeks
- Empty state: "No events this week. Say: 'Schedule Sam tomorrow at 6pm'"

**Story 6: Today's Schedule Widget (Chat List)**
- Add "Today's Schedule" card at top of ChatListView showing next 3 upcoming events
- Compact view: time, event type icon, title (e.g., "2:00 PM 🏋️ Session: Sam")
- Tap widget → Opens full CalendarView
- Auto-updates as events pass (removes completed events)
- Collapses when no events today
- Shows "No events today" message if calendar empty

**Story 7: Cal Tab (4th Bottom Tab)**
- Add 4th tab to bottom navigation: "Cal" with calendar icon 📅
- Tab opens CalendarView with week timeline
- Badge shows count of today's events (e.g., "Cal (3)")
- Tapping "Cal" while already in CalendarView scrolls to current time

**Story 8: Manual Event Creation UI**
- Add "+" floating action button in CalendarView
- Opens event creation sheet with fields:
  1. **Event Type** (segmented control): Training 🏋️ | Call 📞 | Adhoc 📅
  2. **Client/Prospect** (picker, only if Training or Call selected):
     - Shows list from ContactService: "My Clients" section + "Prospects" section
     - Disabled for Adhoc events
  3. **Title** (text field):
     - Auto-filled for Training/Call: "Session with [Client]" or "Call with [Client]"
     - Manual entry required for Adhoc
  4. **Date** (date picker): Defaults to today
  5. **Start Time** (time picker): Defaults to next hour
  6. **Duration** (picker): 30 min / 1 hr / 1.5 hr / 2 hr (calculates `endTime`)
  7. **Location** (text field, optional)
  8. **Notes** (text area, optional)
- Validation: Training/Call requires client selection, Adhoc requires title
- Success: "✅ Event created and synced to Google Calendar"

**Story 9: Event Type Visual Differentiation**
- Training Sessions: Blue (#007AFF), 🏋️ icon, "Session" prefix
- Calls: Green (#34C759), 📞 icon, "Call" prefix
- Adhoc: Gray (#8E8E93), 📅 icon, custom title
- Calendar legend at top: [🏋️ Training] [📞 Calls] [📅 Other]
- Filter toggle: Show All / Training Only / Calls Only / Adhoc Only

**Story 10: Conflict Detection & Smart Suggestions**
- Before scheduling, query Firestore for existing events at requested time (within 30min window)
- If conflict detected, AI responds: "⚠️ You already have [Event Type] at [Time]. Want me to suggest another time?"
- Smart suggestions algorithm:
  - Find next available 1-hour slot within same day
  - Check trainer's typical working hours (9am-6pm default, configurable in Settings)
  - Suggest 3 alternatives: "How about 7:00 PM, 8:00 PM, or tomorrow at 6:00 PM?"
- Manual creation shows warning banner: "⚠️ Conflicts with [Event]" with force-book option

**Story 11: AI Rescheduling & Cancellation**
- AI handles rescheduling: "move Sam's session to 7pm" or "reschedule tomorrow's 6pm to Thursday"
  - Parse which event (by client name + date)
  - Update `startTime` and `endTime` in Firestore
  - Re-sync to Google Calendar (update existing event)
  - Confirm: "✅ Rescheduled Sam's session to 7:00 PM Thursday"
- AI handles cancellations: "cancel Sam's session tomorrow" or "delete my 6pm appointment"
  - Update `status` to "cancelled" in Firestore
  - Delete from Google Calendar using `googleCalendarEventId`
  - Confirm: "✅ Cancelled session with Sam tomorrow at 6:00 PM"

**Story 12: Event Detail View & Editing**
- Tap any event in calendar → Opens EventDetailView sheet
- Shows: event type icon + color, title, client name (if applicable), date/time, location, notes
- Actions:
  - **Edit**: Opens event editor (same as manual creation UI, pre-filled)
  - **Delete**: Confirmation alert → Deletes from Firestore + Google Calendar
  - **Mark Complete**: Changes status to "completed", grays out in calendar
- Show sync status: "✅ Synced to Google Calendar" or "⏳ Syncing..." or "❌ Sync failed (retry)"

**Story 13: Calendar Settings & Preferences**
- Settings → Calendar section with options:
  - **Google Calendar**: "Connected: [email]" (or "Connect" button)
    - Tap → OAuth flow → Success: "✅ Connected to Google Calendar"
  - **Default Event Duration**: 30 min / 1 hr / 1.5 hr / 2 hr
  - **Working Hours**: Start (default 9:00 AM), End (default 6:00 PM) - used for conflict suggestions
  - **Show Today's Schedule Widget**: Toggle (ON by default)
  - **Calendar Start Day**: Sunday / Monday
- Store preferences in Firestore `trainerProfiles/{userId}/calendarSettings`

**Story 14: Error Handling & Edge Cases**
- **OAuth token expired**: Show re-authentication prompt: "Google Calendar disconnected. Reconnect in Settings."
- **Google Calendar API rate limit**: Queue sync requests, retry after delay, show "⏳ Syncing..." status
- **Network failure during sync**: Store event locally, retry sync when connection restored
- **Invalid time (past date)**: AI responds: "I can't schedule in the past. Did you mean tomorrow?"
- **Ambiguous client name** (multiple Sams): AI asks: "Which Sam? You have 2 clients named Sam: Sam Jones or Sam Smith?"
- **Client not found + trainer declines to add**: "Okay, I won't schedule anything. Let me know when you want to add [Name]."
- **Sync failure**: Show "❌ Failed to sync to Google Calendar" with retry button

**Story 15: Event Completion & History**
- Automatically mark events as "completed" after `endTime` passes (background job)
- Completed events remain visible in calendar (grayed out) for 7 days, then archived
- Add "History" view (optional future enhancement) showing all past events with client session counts

---

#### Technical Architecture

**Firestore Schema:**
```
/calendar/{trainerId}/events/{eventId}
  - eventId: string
  - trainerId: string
  - eventType: "training" | "call" | "adhoc"
  - title: string
  - clientId: string | null
  - prospectId: string | null
  - startTime: timestamp
  - endTime: timestamp
  - location: string
  - notes: string
  - status: "scheduled" | "completed" | "cancelled"
  - googleCalendarEventId: string | null
  - syncedAt: timestamp | null
  - createdBy: "ai" | "trainer"
  - createdAt: timestamp
```

**iOS Services:**
- `CalendarService.swift` - Local event CRUD, Firestore sync, conflict detection
- `GoogleCalendarSyncService.swift` - OAuth flow, Google Calendar API integration
- `CalendarConflictService.swift` - Detect conflicts, suggest alternative times
- `EventTypeDetectionService.swift` - Parse natural language to determine event type

**Cloud Functions:**
- `scheduleEvent(trainerId, eventData)` - Create event, trigger Google sync
- `detectConflicts(trainerId, startTime, duration)` - Check for conflicts, return boolean + conflicting events
- `completeExpiredEvents()` - Scheduled job (runs hourly) to mark past events as completed
- `syncToGoogleCalendar(eventId)` - Create/update/delete event in Google Calendar

**AI Integration:**
- Enhance existing `scheduleCall()` function from PR #008:
  - Add event type detection logic
  - Integrate with ContactService for client/prospect validation
  - Call `CalendarService.createEvent()` instead of direct Firestore write
  - Handle conflict detection responses
- New functions: `rescheduleEvent(eventId, newStartTime)`, `cancelEvent(eventId)`

**Google Calendar API Integration:**
- OAuth 2.0 scopes: `https://www.googleapis.com/auth/calendar.events`
- Endpoints used:
  - `POST /calendars/primary/events` - Create event
  - `PUT /calendars/primary/events/{eventId}` - Update event
  - `DELETE /calendars/primary/events/{eventId}` - Delete event
- Store refresh token securely in Firestore: `/users/{userId}/integrations/googleCalendar/refreshToken`

---

#### Success Criteria

✅ Trainer says "schedule a session with Sam tomorrow at 6pm" → Training event created with blue 🏋️ styling
✅ Trainer says "I have a doctor appointment at 2pm" → Adhoc event created with gray 📅 styling
✅ Trainer says "schedule a call with John" (John doesn't exist) → AI prompts to add John as prospect
✅ Event created in Psst → Appears in Google Calendar within 5 seconds
✅ CalendarView shows week timeline with color-coded events (Blue/Green/Gray)
✅ "Today's Schedule" widget shows next 3 events on chat list
✅ "Cal" tab in bottom navigation opens full calendar
✅ Manual event creation supports all 3 event types with client picker
✅ Conflict detection works: AI warns when double-booking and suggests alternatives
✅ Rescheduling works: "move Sam to 7pm" updates event in Psst + Google Calendar
✅ Cancellation works: "cancel Sam's session" deletes from Psst + Google Calendar
✅ Event filters work: Show Training Only / Calls Only / All
✅ OAuth flow handles token refresh without user intervention
✅ Error messages are user-friendly for all failure scenarios

---

## 📊 Summary

### Project Progress
- **Phase 0 (Prerequisites):** 0/2 Complete (0%) - PR #006.5 (User Roles), PR #009 (Contacts)
- **Phase 1 (Foundation):** 0/2 Complete (0%)
- **Phase 2 (Basic AI Chat):** 0/2 Complete (0%)
- **Phase 3 (RAG + Context):** 0/3 Complete (0%)
- **Phase 4 (Actions + Voice):** 0/3 Complete (0%) - Includes PR #010 (Calendar), PR #011 (Voice)
- **Phase 5 (Advanced):** 0/5 Complete (0%) - PR #012-#016
- **Infrastructure:** 0/1 Complete (0%) - PR #017 (Fastlane)

### Overall Status
- **Total PRs:** 17 (includes infrastructure)
- **Completed:** 0 (0%)
- **In Progress:** 1 (PR #008)
- **Pending:** 16 (94%)

### Next Steps
**Recommended Build Order:**
1. `/pam 006.5` - User Roles & Required Name (prerequisite for many features)
2. `/pam 009` - Trainer-Client Relationship System (prerequisite for calendar)
3. `/pam 010` - Full Calendar System + AI Scheduling (critical for demo)
4. Then Phase 1 parallel development:
   - `/pam 1` - AI Backend Infrastructure
   - `/pam 2` - iOS AI Scaffolding

Phase 0 PRs should be built first to establish foundational access control and user model.

---

## Feature-to-Requirement Mapping

| AI Requirement | PRs That Implement It |
|----------------|----------------------|
| **RAG Pipeline** | PR #5 (Semantic Search), PR #7 (Client Profiles) |
| **User Preferences** | PR #12 (Trainer Profile), PR #13 (YOLO Mode), PR #15 (Tone) |
| **Function Calling** | PR #8 (Tool Integration), PR #13 (YOLO), PR #14 (Multi-Step) |
| **Memory/State** | PR #3 (Chat Backend), PR #7 (Profiles), PR #14 (Multi-Step) |
| **Error Handling** | PR #16 (Fallback System) + All features |

---

## Assignment Demo Coverage

**Demo 1 (Marcus - Lead Qualification):**
- Uses PR #006.5 (User Roles - distinguish trainers from clients)
- Uses PR #009 (Contacts - client/prospect management)
- Uses PR #12 (User Preferences)
- Uses PR #8 (Function Calling - scheduleCall)
- **Uses PR #10 (Full Calendar System + Google Calendar sync)** ⭐ Critical for demo
- Uses PR #14 (Multi-Step Agent)
- Uses PR #13 (YOLO Mode)

**Demo 2 (Alex - Context Recall):**
- Uses PR #006.5 (User Roles - trainer context)
- Uses PR #009 (Contacts - client relationships)
- Uses PR #5 (RAG Pipeline)
- Uses PR #7 (Client Profiles)
- Uses PR #6 (Contextual Actions)
- Uses PR #3 (AI Chat Backend)

**Note:** PR #009 (Contacts) is a prerequisite for PR #010 (Calendar) since scheduling requires client/prospect selection. PR #010 is critical for Demo 1 to show AI-scheduled sessions appearing in trainer's real Google Calendar app. Without this, events only exist in Firestore which isn't visible to users in their daily workflow.

---

Each PR is designed to deliver a complete, testable AI capability that builds incrementally toward the full AI assistant vision described in AI-PRODUCT-VISION.md.

---

## Infrastructure & DevOps

### PR #017: Fastlane Deployment Setup

**Brief:** Implement automated iOS deployment pipeline using Fastlane with App Store Connect API authentication for streamlined TestFlight and App Store releases. Install Fastlane CLI and configure project-specific Fastfile with lanes for beta deployment (TestFlight), production release (App Store), and certificate management. Set up App Store Connect API key authentication (JSON key file) to avoid manual 2FA prompts during CI/CD. Create Fastlane lanes: `beta` (build → sign → upload to TestFlight), `release` (build → sign → upload to App Store), `screenshots` (generate App Store screenshots), and `test` (run XCTest suite). Configure Match for code signing certificate management across team members and CI servers. Store API keys securely using environment variables or .env files (git-ignored). Document authentication setup, lane usage, and troubleshooting in README. This replaces manual Xcode Archive → Upload workflow with single-command deployments.

**User Capability:** Developers can deploy iOS app to TestFlight and App Store with a single command using automated certificate management

**Dependencies:** None (infrastructure improvement)

**Complexity:** Medium

**Phase:** Infrastructure

**Technical Notes:**
- Use App Store Connect API (not Apple ID login) to avoid 2FA friction
- Configure Match for team-wide code signing automation
- Store API key JSON file outside of git (use .gitignore)
- Set up lanes: `fastlane beta`, `fastlane release`, `fastlane test`
- Compatible with GitHub Actions, CircleCI, or local dev machines
- Requires Apple Developer Program membership

