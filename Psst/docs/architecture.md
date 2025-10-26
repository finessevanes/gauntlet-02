# Psst Architecture Documentation

**Last Updated:** October 26, 2025 (Comprehensive Update)
**Version:** Post-MVP + AI Features Active + Google Calendar Sync + PR #011 Planned (PRs #006.5-010C Complete)
**Documented by:** Arnold (The Architect)

> **📌 Quick Links:**
> - **Concise Version (350 lines):** `architecture-concise.md` ← Use this for agent context!
> - **PR #009 Brownfield:** `brownfield-analysis-pr-009.md`
> - **Full Backup (1,381 lines):** `architecture-full-backup.md`

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Current iOS App Architecture](#current-ios-app-architecture)
3. [Firebase Backend](#firebase-backend)
4. [AI System Integration Plan](#ai-system-integration-plan)
5. [Data Flow Diagrams](#data-flow-diagrams)
6. [Technical Stack](#technical-stack)
7. [Integration Strategy](#integration-strategy)
8. [Key Design Patterns](#key-design-patterns)

---

## System Overview

Psst is a personal trainer messaging app built with SwiftUI and Firebase with **AI-powered assistant capabilities**. The app currently supports:

### Core Messaging Features
- Real-time messaging (1-on-1 and group chats)
- User presence tracking (online/offline status)
- Read receipts and typing indicators
- Image sharing with automatic compression
- Offline message queuing
- Push notifications

### AI Features (ACTIVE - PRs #006-008)
- **AI Chat Assistant** - Trainers can ask AI questions and get intelligent responses
- **Semantic Search (RAG)** - AI searches message history using vector embeddings via Pinecone
- **AI Function Calling** - AI can schedule calls, send messages, set reminders
- **Contextual AI Actions** - Long-press messages for AI summaries, context surfacing, reminders
- **Auto Client Profiles** - AI automatically extracts profile data from conversations (injuries, goals, preferences)

### Access Control (PR #009)
- **Trainer-Client Relationships** - Explicit relationship model with trainer-controlled access
- **Contact Management** - Trainers manage client roster and prospects
- **Group Peer Discovery** - Clients in shared groups can message each other

### Calendar Integration (PR #010C)
- **Google Calendar OAuth** - Secure OAuth 2.0 flow for calendar access
- **One-Way Sync** - Psst events automatically sync to Google Calendar
- **Event Types** - Training sessions, calls, and adhoc appointments
- **Smart Scheduling** - AI-powered natural language event creation

### User Roles (PR #006.5)
- **Role-Based System** - Users are either trainers or clients
- **Required Display Name** - All users must provide name during signup

---

## Current iOS App Architecture

### Project Structure

```
Psst/
├── PsstApp.swift                      # App entry point, Firebase initialization
├── ContentView.swift                  # Root content wrapper
├── Models/                            # 27 Swift model files
│   ├── Core Models/
│   │   ├── User.swift                 # User data model (Firebase Auth integration)
│   │   ├── Chat.swift                 # Chat/conversation model (1-on-1 and groups)
│   │   ├── Message.swift              # Message model with media support
│   │   ├── QueuedMessage.swift        # Offline message queue model
│   │   ├── UserPresence.swift         # Real-time presence tracking
│   │   ├── GroupPresence.swift        # Group presence aggregation
│   │   ├── TypingStatus.swift         # Typing indicator model
│   │   └── ReadReceiptDetail.swift    # Read receipt details for UI
│   │
│   ├── AI Models (PRs #006-008)/
│   │   ├── AIMessage.swift            # AI conversation message model
│   │   ├── AIConversation.swift       # AI chat session model
│   │   ├── AIResponse.swift           # AI function call responses
│   │   ├── AIContextAction.swift      # Contextual AI action types
│   │   ├── AIContextResult.swift      # Results from contextual actions
│   │   ├── AISelectionRequest.swift   # User selection prompts
│   │   ├── FunctionCall.swift         # AI function call data
│   │   ├── Reminder.swift             # AI-created reminders
│   │   ├── ReminderSuggestion.swift   # AI reminder suggestions
│   │   └── RelatedMessage.swift       # Semantically related messages
│   │
│   ├── Profile Models (PR #007)/
│   │   ├── ClientProfile.swift        # Auto-extracted client data
│   │   ├── ProfileItem.swift          # Individual profile fields
│   │   ├── ProfileCategory.swift      # Profile categorization
│   │   └── ProfileItemSource.swift    # Track extraction source
│   │
│   ├── Contact Models (PR #009)/
│   │   ├── Client.swift               # Client contact model
│   │   ├── Prospect.swift             # Prospect contact model
│   │   └── Contact.swift              # Contact protocol
│   │
│   └── Calendar Models (PR #010A-C)/
│       ├── CalendarEvent.swift        # Training/Call/Adhoc events with Google sync
│       └── SchedulingResult.swift     # Scheduling conflict resolution
│
├── Views/                             # ~83 Swift view files
│   ├── Authentication/
│   │   ├── LoginView.swift            # Email/password login
│   │   ├── SignUpView.swift           # User registration with role selection
│   │   ├── EmailSignInView.swift      # Email signin flow
│   │   └── ForgotPasswordView.swift   # Password reset
│   │
│   ├── ChatList/
│   │   ├── ChatListView.swift         # Main conversation list
│   │   ├── ChatRowView.swift          # Individual chat preview with unread count
│   │   ├── ChatView.swift             # Conversation screen
│   │   ├── MessageRow.swift           # Message bubble (text + image)
│   │   ├── MessageInputView.swift     # Text input + image picker
│   │   └── GroupMemberStatusView.swift # Group member presence
│   │
│   ├── AI/ (PRs #006-008)             # ~15 AI-related view files
│   │   ├── AIAssistantView.swift      # Dedicated AI chat interface
│   │   ├── AIMessageRow.swift         # AI response bubble styling
│   │   ├── ContextualAIMenu.swift     # Long-press menu on messages
│   │   ├── AILoadingIndicator.swift   # "AI is thinking..." indicator
│   │   ├── AISummaryView.swift        # AI-generated summaries
│   │   ├── AIRelatedMessagesView.swift # Show related context
│   │   ├── AIReminderSheet.swift      # AI-suggested reminders
│   │   ├── AISelectionCard.swift      # User selection prompts
│   │   ├── ActionConfirmationCard.swift # Confirm AI actions
│   │   ├── ActionResultViews.swift    # Display AI action results
│   │   ├── ClientProfileDetailView.swift # Auto-extracted profile display
│   │   ├── ClientProfileBannerView.swift # Profile summary banner
│   │   ├── FloatingAIButton.swift     # Quick AI assistant access
│   │   ├── EventConfirmationCard.swift # Confirm calendar events
│   │   ├── ConflictWarningCard.swift  # Scheduling conflict warnings
│   │   └── AddProspectPromptCard.swift # Add prospects from AI
│   │
│   ├── Calendar/ (PR #010A-C)         # ~10 calendar view files
│   │   ├── CalendarView.swift         # Main calendar interface
│   │   ├── WeekTimelineView.swift     # Week view with timeline
│   │   ├── TodaysScheduleWidget.swift # Today's schedule summary
│   │   ├── EventCardView.swift        # Event display card
│   │   ├── EventDetailView.swift      # Event details modal
│   │   ├── EventCreationSheet.swift   # Create new events
│   │   ├── EventEditSheet.swift       # Edit existing events
│   │   ├── ClientPickerView.swift     # Select client for event
│   │   ├── CurrentTimeIndicatorView.swift # Live time indicator
│   │   └── CalendarEmptyStateView.swift # Empty calendar state
│   │
│   ├── Contacts/ (PR #009)            # Contact management views
│   │   ├── ContactsView.swift         # Clients + prospects list
│   │   ├── AddClientView.swift        # Add new client form
│   │   └── ContactDetailView.swift    # Contact details
│   │
│   ├── Components/                    # ~30 reusable components
│   │   ├── ProfilePhotoPicker.swift   # Profile photo upload
│   │   ├── ImageMessageView.swift     # Image message display
│   │   ├── MessageStatusIndicator.swift # Message status
│   │   ├── TypingIndicatorView.swift  # Typing animation
│   │   ├── PresenceIndicator.swift    # Online status badge
│   │   ├── ReadReceiptDetailView.swift # Read receipt modal
│   │   ├── NetworkStatusBanner.swift  # Offline warning
│   │   └── [23 other reusable components]
│   │
│   ├── UserSelection/
│   │   ├── UserSelectionView.swift    # Select users for chat
│   │   ├── UserRow.swift              # User list row
│   │   └── GroupNamingView.swift      # Group chat naming
│   │
│   ├── Profile/
│   │   ├── ProfileView.swift          # User profile display
│   │   └── EditProfileView.swift      # Edit profile (name, photo)
│   │
│   ├── Settings/
│   │   ├── SettingsView.swift         # App settings + Google Calendar
│   │   ├── NotificationsSettingsView.swift
│   │   ├── AboutView.swift
│   │   └── HelpSupportView.swift
│   │
│   ├── ConversationList/              # Alternative chat list view
│   │   └── ConversationListView.swift
│   │
│   ├── RootView.swift                 # Auth state routing
│   ├── MainTabView.swift              # Tab navigation (Chats, Calendar, Profile, Settings)
│   └── LoadingScreenView.swift        # App loading state
│
├── ViewModels/                        # 11 Swift ViewModel files
│   ├── Core ViewModels/
│   │   ├── AuthViewModel.swift        # Authentication state management
│   │   ├── ChatListViewModel.swift    # Chat list data + real-time updates
│   │   ├── ChatInteractionViewModel.swift # Message sending + real-time updates
│   │   ├── MessageManagementViewModel.swift # Message read receipts + status
│   │   ├── PresenceTrackingViewModel.swift # User presence updates
│   │   └── ReadReceiptDetailViewModel.swift # Read receipt details modal
│   │
│   ├── AI ViewModels (PRs #006-008)/
│   │   ├── AIAssistantViewModel.swift # AI chat state management (PR #006)
│   │   ├── ContextualAIViewModel.swift # Contextual AI actions (PR #008)
│   │   └── ClientProfileViewModel.swift # Auto profile management (PR #007)
│   │
│   └── Feature ViewModels (PRs #009-010)/
│       ├── ContactViewModel.swift     # Contact management (PR #009)
│       └── CalendarViewModel.swift    # Calendar events and scheduling (PR #010A)
│
├── Services/                          # 18 Swift service files
│   ├── Core Services/
│   │   ├── FirebaseService.swift      # Firebase SDK initialization
│   │   ├── AuthenticationService.swift # User login/signup/logout
│   │   ├── UserService.swift          # User profile CRUD
│   │   ├── ChatService.swift          # Chat CRUD + user name fetching
│   │   ├── MessageService.swift       # Message send/receive + read receipts
│   │   ├── PresenceService.swift      # Realtime DB presence tracking
│   │   ├── TypingIndicatorService.swift # Typing status updates
│   │   ├── MessageQueue.swift         # Offline message queue
│   │   ├── NetworkMonitor.swift       # Network connectivity monitor
│   │   ├── NotificationService.swift  # Push notification handling
│   │   ├── ImageUploadService.swift   # Image compression + Storage upload
│   │   └── ImageCacheService.swift    # Image download + cache
│   │
│   ├── AI Services (PRs #006-008)/
│   │   ├── AIService.swift            # AI Cloud Function calls
│   │   ├── ProfileService.swift       # Client profile CRUD (PR #007)
│   │   └── ContactService.swift       # Trainer-client relationships (PR #009)
│   │
│   └── Calendar Services (PR #010A-C)/
│       ├── CalendarService.swift      # Calendar CRUD and event management
│       ├── CalendarConflictService.swift # Scheduling conflict detection
│       └── GoogleCalendarSyncService.swift # OAuth + Google Calendar API
│
└── Utilities/                         # ~10 utility files
    ├── Logger.swift                    # Logging utility
    ├── ColorScheme.swift               # App color palette
    ├── Typography.swift                # Text styles
    ├── ButtonStyles.swift              # Reusable button styles
    ├── Date+Extensions.swift           # Date formatting helpers
    ├── DeepLinkHandler.swift           # Deep link navigation
    ├── ProfilePhotoError.swift         # Error types for profile photos
    ├── PresenceObserverModifier.swift  # SwiftUI modifier for presence
    ├── FeatureFlags.swift              # Feature toggle system
    └── Config.example.swift            # Configuration template
```

---

## Firebase Backend

### Firestore Collections

```
/users/{userID}
  - uid: String
  - email: String
  - displayName: String
  - photoURL: String? (Cloud Storage URL)
  - createdAt: Timestamp
  - updatedAt: Timestamp
  - fcmToken: String? (for push notifications)

/chats/{chatID}
  - id: String
  - members: [String] (array of user IDs)
  - lastMessage: String
  - lastMessageTimestamp: Timestamp
  - isGroupChat: Boolean
  - groupName: String? (for groups only)
  - createdAt: Timestamp
  - updatedAt: Timestamp

/chats/{chatID}/messages/{messageID}
  - id: String
  - text: String
  - senderID: String
  - timestamp: Timestamp
  - readBy: [String] (array of user IDs who read this message)
  
  # Image message fields (PR #009)
  - mediaType: String? ("image")
  - mediaURL: String? (Cloud Storage download URL)
  - mediaThumbnailURL: String? (thumbnail URL)
  - mediaSize: Int? (bytes)
  - mediaDimensions: Map? ({width: Int, height: Int})

/presence/{userID}
  - online: Boolean
  - lastSeen: Timestamp

/typing/{chatID}/{userID}
  - isTyping: Boolean
  - timestamp: Timestamp
```

### Firebase Realtime Database

Used for real-time presence tracking (faster than Firestore for high-frequency updates):

```
/presence/{userID}
  - online: Boolean
  - lastSeen: Timestamp (server timestamp)
```

### Cloud Storage

```
/users/{userID}/profile.jpg             # Profile photos
/chats/{chatID}/{messageID}/image.jpg   # Full-size images
/chats/{chatID}/{messageID}/thumb.jpg   # Thumbnails (200x200)
```

### Cloud Functions (TypeScript)

**Active Functions (9 deployed + 2 migration scripts):**
```
functions/src/                      # 26 TypeScript files total
├── index.ts                        # Main exports file (all function exports)
│
├── Cloud Functions (9 active)/
│   ├── onMessageCreate.ts          # Push notification triggers (PR #004)
│   ├── generateEmbedding.ts        # Auto-embed messages to Pinecone (PR #006)
│   ├── chatWithAI.ts               # AI assistant endpoint (PR #006-007)
│   ├── semanticSearch.ts           # RAG semantic search (PR #006)
│   ├── executeFunctionCall.ts      # AI function calling (PR #008)
│   ├── extractProfileInfoOnMessage.ts # Auto client profile extraction (PR #007)
│   └── onCalendarEventCreate.ts    # Google Calendar sync trigger (PR #010C)
│
├── migrations/                     # Migration scripts (PR #009)
│   ├── migrateExistingChats.ts     # Backfill trainer-client relationships
│   └── fixProspectChats.ts         # Fix prospect chat permissions
│
├── services/                       # 9 backend service files
│   ├── openaiService.ts            # OpenAI API (GPT-4 + embeddings)
│   ├── pineconeService.ts          # Pinecone vector DB client
│   ├── vectorSearchService.ts      # Semantic search queries
│   ├── aiChatService.ts            # AI conversation orchestration
│   ├── profileExtractionService.ts # Extract structured profile data
│   ├── functionExecutionService.ts # Execute AI function calls
│   ├── conversationService.ts      # Conversation history management
│   ├── auditLogService.ts          # AI action audit logging
│   └── googleCalendarService.ts    # Google Calendar API (PR #010C)
│
├── schemas/
│   └── aiFunctionSchemas.ts        # AI function call type definitions
│
├── types/
│   ├── aiConversation.ts           # AI conversation types
│   └── rag.ts                      # RAG pipeline types
│
├── config/
│   ├── ai.config.ts                # AI configuration constants
│   └── secrets.ts                  # Secret management helpers
│
├── utils/
│   └── retryHelper.ts              # Retry logic for API calls
│
└── @types/
    └── pinecone.d.ts               # Pinecone TypeScript definitions
```

**Dependencies:**
- `@pinecone-database/pinecone` v6.1.2 - Vector database for semantic search
- `openai` v6.6.0 - OpenAI GPT-4 and embeddings API
- `firebase-admin` v12.0.0 - Firestore, Auth, Storage access
- `firebase-functions` v5.1.0 - Cloud Functions runtime
- `googleapis` v164.1.0 - Google Calendar API integration (PR #010C)
- `luxon` v3.7.2 - Date/time manipulation (PR #010C)

---

## AI System Architecture (ACTIVE)

### Current AI Implementation Status

**Completed PRs:**
- ✅ PR #006: AI Infrastructure, Embeddings, Basic Chat (Pinecone + OpenAI)
- ✅ PR #007: Auto Client Profiles (AI extracts profile data from chats)
- ✅ PR #008: AI Function Calling (schedule calls, send messages, set reminders)
- ✅ PR #009: Trainer-Client Relationships (access control + contact management)
- ✅ PR #010C: Google Calendar Integration (OAuth + one-way sync to Google Calendar)

**Next Planned:**
- 🔜 PR #010 (Full): Calendar UI (Week view, Today's Schedule widget, Cal tab)
- 🔜 PR #011: Enhanced UI/UX for AI Features
- 🔜 PR #012: User Preferences & Personalization
- 🔜 PR #013: YOLO Mode (aggressive AI automation)

### Architecture Overview

```
┌────────────────────────────────────────────────────────────┐
│                iOS SwiftUI App (Frontend)                   │
│  - AIAssistantView (new chat screen)                        │
│  - Contextual AI buttons (summarize, surface context, etc.) │
│  - Display AI responses in chat bubbles                     │
└──────────────────────┬─────────────────────────────────────┘
                       │ Firebase Callable Function
                       ▼
┌────────────────────────────────────────────────────────────┐
│          Firebase Cloud Functions (AI Backend)              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  AI SDK by Vercel (Agent Framework)                  │  │
│  │  - Manages conversation flow                         │  │
│  │  - Handles function calling/tool use                 │  │
│  │  - Manages memory/state between messages             │  │
│  └────────────────────┬─────────────────────────────────┘  │
│                       │ API Call                            │
│                       ▼                                     │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         OpenAI GPT-4 (AI Model)                      │  │
│  │  - Generates responses                               │  │
│  │  - Understands semantic queries                      │  │
│  └────────────────────┬─────────────────────────────────┘  │
│                       │ Needs context                       │
│                       ▼                                     │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Pinecone Vector Database                           │  │
│  │  - Stores message embeddings (vectors)               │  │
│  │  - Semantic search via vector similarity             │  │
│  │  - Purpose-built for vector operations               │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
│  Also accesses:                                             │
│  - Firestore (chat history, user preferences)              │
│  - Realtime DB (presence)                                  │
│  - Cloud Storage (if voice messages)                       │
└─────────────────────────────────────────────────────────────┘
```

### AI Components (BUILT)

#### iOS App Additions

**Views (11 files):**
- ✅ `AIAssistantView.swift` - Dedicated AI chat interface (PR #006)
- ✅ `AIMessageRow.swift` - AI response bubble with distinct styling (PR #006)
- ✅ `ContextualAIMenu.swift` - Long-press menu on messages (PR #008)
- ✅ `AILoadingIndicator.swift` - Animated "AI is thinking..." indicator (PR #006)
- ✅ `AISummaryView.swift` - Display AI-generated summaries (PR #008)
- ✅ `AIRelatedMessagesView.swift` - Show related context messages (PR #008)
- ✅ `AIReminderSheet.swift` - Create AI-suggested reminders (PR #008)
- ✅ `AISelectionCard.swift` - User selection prompts for AI (PR #008)
- ✅ `ActionConfirmationCard.swift` - Confirm AI actions (PR #008)
- ✅ `ActionResultViews.swift` - Display AI action results (PR #008)
- ✅ `ClientProfileDetailView.swift` - Display auto-extracted profile (PR #007)
- ✅ `ClientProfileBannerView.swift` - Profile summary banner (PR #007)
- ✅ `FloatingAIButton.swift` - Quick access to AI assistant (PR #006)

**ViewModels (4 files):**
- ✅ `AIAssistantViewModel.swift` - Manages AI chat state (PR #006)
- ✅ `ContextualAIViewModel.swift` - Handles contextual AI actions (PR #008)
- ✅ `ClientProfileViewModel.swift` - Auto profile management (PR #007)

**Services (3 files):**
- ✅ `AIService.swift` - Calls Cloud Functions for AI operations (PR #006)
- ✅ `ProfileService.swift` - Client profile CRUD operations (PR #007)
- ✅ `ContactService.swift` - Trainer-client relationship management (PR #009)

**Models (16 files):**
- ✅ `AIMessage.swift` - AI conversation message model (PR #006)
- ✅ `AIConversation.swift` - AI chat session model (PR #006)
- ✅ `AIResponse.swift` - AI function call responses (PR #008)
- ✅ `AIContextAction.swift` - Contextual AI action types (PR #008)
- ✅ `AIContextResult.swift` - Results from contextual actions (PR #008)
- ✅ `AISelectionRequest.swift` - User selection prompts (PR #008)
- ✅ `FunctionCall.swift` - AI function call data (PR #008)
- ✅ `CalendarEvent.swift` - AI-scheduled events (PR #008)
- ✅ `Reminder.swift` - AI-created reminders (PR #008)
- ✅ `ReminderSuggestion.swift` - AI reminder suggestions (PR #008)
- ✅ `RelatedMessage.swift` - Semantically related messages (PR #008)
- ✅ `ClientProfile.swift` - Auto-extracted client data (PR #007)
- ✅ `ProfileItem.swift` - Individual profile fields (PR #007)
- ✅ `ProfileCategory.swift` - Profile categorization (PR #007)
- ✅ `ProfileItemSource.swift` - Track extraction source (PR #007)
- ✅ `Client.swift` - Client contact model (PR #009)
- ✅ `Prospect.swift` - Prospect contact model (PR #009)
- ✅ `Contact.swift` - Contact protocol (PR #009)

#### Cloud Functions Structure

```
functions/
├── index.ts                        # Exports all functions
├── services/
│   ├── embeddingService.ts         # OpenAI embeddings + Pinecone storage
│   ├── aiService.ts                # AI SDK integration
│   └── vectorSearchService.ts      # Semantic search queries
├── functions/
│   ├── chatWithAI.ts               # Main AI chat endpoint
│   ├── embedMessage.ts             # Firestore trigger for new messages
│   └── backfillEmbeddings.ts       # One-time migration script
└── package.json                    # Dependencies: @pinecone-database/pinecone, ai, @ai-sdk/openai
```

#### Pinecone Index Configuration

**Index Name:** `chat-messages`
**Dimensions:** 1536 (OpenAI text-embedding-3-small)
**Metric:** Cosine similarity
**Cloud:** AWS (free tier)

**Vector Metadata Structure:**
```typescript
{
  id: messageId,  // Firestore message ID
  values: [0.123, -0.456, ...],  // 1536-dim embedding vector
  metadata: {
    firestoreMessageId: "msg_abc123",
    firestoreChatId: "chat_xyz789",
    trainerId: "user_123",
    senderId: "user_456",
    senderName: "John Doe",
    text: "My knee hurts",
    timestamp: 1729789200000,  // Unix timestamp in ms
    isGroupChat: false
  }
}
```

**Key Benefits over SQL approach:**
- No schema migrations needed
- Managed scaling and performance
- Built-in metadata filtering
- Simple API (upsert, query, delete)
- Free tier: 100k vectors (plenty for school project)

---

## Data Flow Diagrams

### Current Message Flow (Existing)

```
User types message in ChatView
         ↓
ChatInteractionViewModel.sendMessage()
         ↓
MessageService.sendMessage(chatID, text)
         ↓
Creates optimistic Message with .sending status
         ↓
Returns to ViewModel immediately (optimistic UI)
         ↓
ChatView displays message instantly
         ↓ (parallel background process)
Writes to Firestore: /chats/{chatID}/messages/{messageID}
         ↓
Firestore snapshot listener triggers
         ↓
ChatInteractionViewModel receives updated message
         ↓
UI updates message status to .delivered
```

### AI Assistant Flow (ACTIVE - PR #006-008)

```
User asks AI: "Find clients with injuries"
         ↓
AIAssistantViewModel.sendMessage(query)
         ↓
AIService.chatWithAI(query)
         ↓
Calls Firebase Cloud Function: chatWithAI(query)
         ↓
Cloud Function (chatWithAI.ts):
  1. Load conversation history from Firestore
  2. Generate embedding for query (openaiService.ts)
  3. Search Pinecone for similar messages (vectorSearchService.ts)
  4. Load trainer preferences from Firestore
  5. Call GPT-4 with context using OpenAI SDK
  6. If GPT-4 calls function → executeFunctionCall.ts
  7. Save conversation to Firestore /ai_conversations
         ↓
Returns AI response to iOS app
         ↓
AIAssistantViewModel updates state
         ↓
AIAssistantView displays response with function call results
```

### Auto-Embedding Flow (ACTIVE - PR #006)

```
User sends message: "My knee hurts"
         ↓
Message written to Firestore (existing flow)
         ↓
Firestore trigger fires: generateEmbedding (onDocumentCreated)
         ↓
Cloud Function: generateEmbedding.ts
         ↓
1. Call openaiService.generateEmbedding(text)
2. OpenAI returns 1536-dimensional vector
3. Store in Pinecone with metadata:
   - id: messageId
   - values: [embedding vector]
   - metadata: {
       firestoreMessageId, firestoreChatId,
       trainerId, senderId, senderName,
       text, timestamp, isGroupChat
     }
4. Log success or retry on failure
         ↓
Message now searchable by semantic meaning via RAG
```

### Auto Profile Extraction Flow (ACTIVE - PR #007)

```
User sends message: "My knee has been hurting since last week"
         ↓
Message written to Firestore
         ↓
Firestore trigger fires: extractProfileInfoOnMessage
         ↓
Cloud Function: extractProfileInfoOnMessage.ts
         ↓
1. Identify if chat is between trainer and client (check roles)
2. Call profileExtractionService.extractProfileInfo()
3. Use GPT-4 to extract structured data:
   - Injuries: "knee pain since last week"
   - Goals: (if mentioned)
   - Preferences: (if mentioned)
4. Write to /clientProfiles/{clientId} in Firestore
5. Merge with existing profile data
         ↓
Trainer sees updated client profile in real-time
```

### AI Function Calling Flow (ACTIVE - PR #008)

```
User asks AI: "Schedule a call with Sara tomorrow at 3pm"
         ↓
AIAssistantViewModel → AIService.chatWithAI()
         ↓
Cloud Function: chatWithAI.ts
         ↓
1. GPT-4 detects function call intent
2. Returns function call: scheduleCall(clientName, date, time)
3. iOS shows confirmation: AISelectionCard
4. User confirms action
         ↓
AIService.executeFunctionCall(functionData)
         ↓
Cloud Function: executeFunctionCall.ts
         ↓
1. Validate function parameters
2. Execute function (functionExecutionService.ts):
   - scheduleCall → write to /calendar/{eventId}
   - sendMessage → write to /chats/{chatId}/messages
   - setReminder → write to /reminders/{reminderId}
3. Log to /aiActions for audit trail (auditLogService.ts)
         ↓
Return success + created resource ID
         ↓
iOS displays ActionResultViews with confirmation
```

---

## Technical Stack

### Current Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Frontend** | SwiftUI | iOS UI framework |
| **Language** | Swift 5.0+ | iOS development |
| **Backend** | Firebase | Authentication, database, storage, functions |
| **Database** | Firestore | Primary data storage (chat, messages, users) |
| **Real-time** | Realtime Database | Presence tracking |
| **Storage** | Cloud Storage | Profile photos, image messages |
| **Auth** | Firebase Auth | Email/password authentication |
| **Notifications** | Firebase Cloud Messaging | Push notifications |
| **Architecture** | MVVM | Views → ViewModels → Services |
| **Async** | Swift async/await | Modern Swift concurrency |
| **Networking** | URLSession | HTTP requests |

### AI Stack (ACTIVE)

| Layer | Technology | Version | Purpose | Implementation Status |
|-------|-----------|---------|---------|----------------------|
| **AI Model** | OpenAI GPT-4 | gpt-4 | Text generation, reasoning, function calling | ✅ Active (PR #006-008) |
| **Embeddings** | OpenAI text-embedding-3-small | - | Convert text to 1536-dim vectors | ✅ Active (PR #006) |
| **Vector DB** | Pinecone | v6.1.2 | Semantic search, RAG context | ✅ Active (PR #006) |
| **Backend Runtime** | Node.js 18 | 18.x | Cloud Functions execution | ✅ Active |
| **TypeScript** | TypeScript | v5.9.3 | Type-safe backend code | ✅ Active |
| **OpenAI SDK** | openai | v6.6.0 | API client for GPT-4 & embeddings | ✅ Active |
| **Pinecone SDK** | @pinecone-database/pinecone | v6.1.2 | Vector DB client | ✅ Active |

**Cost Notes:**
- OpenAI GPT-4: ~$0.03/1K tokens (input) + $0.06/1K tokens (output)
- OpenAI Embeddings: ~$0.02/1M tokens
- Pinecone: Free tier (100K vectors, plenty for school project)
- Firebase Functions: Pay-as-you-go (generous free tier)

---

## Implementation Status

### Completed Phases (PRs #006-009)

#### ✅ PR #006.5: User Roles & Required Name (DONE)
**Status:** Merged to develop
**Deliverable:** Role-based system with trainer/client distinction
- Added `UserRole` enum to User model
- Updated SignUpView with role selection
- Required displayName during signup
- Updated Firestore security rules for role validation
- Role is immutable after creation

#### ✅ PR #006: AI Infrastructure + Basic Chat + RAG (DONE)
**Status:** Merged to develop
**Deliverable:** Full AI assistant with semantic search
- Created Pinecone index with 1536 dimensions
- Implemented `generateEmbedding.ts` Cloud Function
- Auto-embed all new messages via Firestore trigger
- Built `AIService.swift`, `AIAssistantViewModel`, `AIAssistantView`
- Implemented `chatWithAI.ts` with RAG pipeline
- Vector search integrated (semantic queries work)
- AI conversations saved to Firestore

**Key Files:**
- Backend: `generateEmbedding.ts`, `chatWithAI.ts`, `semanticSearch.ts`
- Services: `openaiService.ts`, `pineconeService.ts`, `vectorSearchService.ts`
- iOS: `AIService.swift`, `AIAssistantView.swift`, `AIAssistantViewModel.swift`

#### ✅ PR #007: Auto Client Profiles (DONE)
**Status:** Merged to develop
**Deliverable:** AI automatically builds client profiles from conversations
- Implemented `extractProfileInfoOnMessage.ts` Cloud Function
- Firestore trigger extracts structured data from messages
- Created `ProfileService.swift` for CRUD operations
- Built `ClientProfileDetailView` and `ClientProfileBannerView`
- Profiles categorized: Injuries, Goals, Preferences, Notes
- Tracks extraction source (messageId, timestamp)

**Key Files:**
- Backend: `extractProfileInfoOnMessage.ts`, `profileExtractionService.ts`
- iOS: `ProfileService.swift`, `ClientProfileViewModel.swift`
- Models: `ClientProfile.swift`, `ProfileItem.swift`, `ProfileCategory.swift`

#### ✅ PR #008: AI Function Calling (DONE)
**Status:** Merged to develop
**Deliverable:** AI can perform actions (schedule calls, send messages, set reminders)
- Implemented `executeFunctionCall.ts` Cloud Function
- GPT-4 function calling integrated in `chatWithAI.ts`
- Three functions: `scheduleCall`, `sendMessage`, `setReminder`
- Built confirmation UI: `AISelectionCard`, `ActionConfirmationCard`
- Audit logging to `/aiActions` collection
- Contextual AI menu (long-press messages)

**Key Files:**
- Backend: `executeFunctionCall.ts`, `functionExecutionService.ts`, `auditLogService.ts`
- iOS: `ContextualAIViewModel.swift`, `ContextualAIMenu.swift`
- Models: `CalendarEvent.swift`, `Reminder.swift`, `FunctionCall.swift`

#### ✅ PR #009: Trainer-Client Relationships (DONE)
**Status:** Merged to develop
**Deliverable:** Explicit access control with contact management
- Created `/contacts/{trainerId}/clients` and `/prospects` collections
- Implemented `ContactService.swift` for relationship management
- Built ContactsView with client/prospect sections
- Updated security rules for relationship-based access
- Migration scripts for existing chats
- Group peer discovery (clients in shared groups can DM)

**Key Files:**
- Backend: `migrateExistingChats.ts`, `fixProspectChats.ts`
- iOS: `ContactService.swift`, `ContactsView.swift`, `AddClientView.swift`
- Models: `Client.swift`, `Prospect.swift`, `Contact.swift`

---

### Next Planned PRs

#### 🔜 PR #010: Calendar & Scheduling System
**Status:** Not started
**Goal:** Visual calendar for trainers to manage client sessions
- Calendar view with month/week/day modes
- Integration with AI-scheduled events from PR #008
- Manual event creation and editing
- Client session tracking

#### 🔜 PR #011: Voice AI Interface
**Status:** PRD and TODO created, ready for development
**Goal:** Enable hands-free voice conversations with AI assistant
- Voice input via OpenAI Whisper (speech-to-text)
- Voice output via iOS text-to-speech
- Conversation mode for back-and-forth voice exchanges
- Maintain full feature parity with text chat (RAG, function calling)
- Target: <5s response time for voice interactions

#### 🔜 PR #012: User Preferences & Personalization
**Status:** Not started
**Goal:** Let trainers customize AI behavior
- AI tone/personality presets
- Response length preferences
- Feature toggles (auto-profiles, proactive suggestions)
- Privacy settings

#### 🔜 PR #013: YOLO Mode (Aggressive Automation)
**Status:** Not started
**Goal:** AI autonomously performs actions with minimal confirmation
- Auto-schedule calls when clients mention availability
- Auto-send follow-up messages
- Auto-create reminders from conversations
- Requires explicit opt-in due to autonomy level

---

## Key Design Patterns

### Current Patterns

**MVVM:**
- Views: SwiftUI (display only)
- ViewModels: `@Published` properties, business logic
- Services: Firebase operations

**Service Layer:**
- `AuthenticationService`, `ChatService`, `MessageService`, `PresenceService`, `UserService`
- New: `AIService` (calls Cloud Functions)

**Optimistic UI:**
- Messages show instantly with `.sending` status
- Firestore listener updates to `.delivered`

**Offline-First:**
- `MessageQueue` for offline messages
- Auto-send when reconnected

**Real-time:**
- Firestore snapshot listeners for live updates

---

## Concurrency

**Swift async/await** used throughout:
- Main thread: UI updates
- Background: Firestore, image processing, network
- `Task` + `MainActor.run` for thread-safe updates

---

## Security

**Current:**
- Firebase Security Rules (Firestore, Storage, Realtime DB)
- All operations require authentication
- Client-side validation

**AI (Planned):**
- Cloud Function auth tokens
- Rate limiting for OpenAI API
- User isolation (trainers only see their data)
- Cost monitoring

---

## Performance

**Current:**
- Image compression (max 2MB, 1920x1080)
- Thumbnail generation (200x200)
- Image caching via URLCache
- Query pagination (last 100 messages)
- Optimistic UI

**AI (Planned):**
- Embedding caching for frequent queries
- Batch embedding processing
- Similarity threshold 0.7+ for relevance

---

## Error Handling

**Current:**
- `MessageError` enum (notAuthenticated, offline, etc.)
- Toast notifications, retry buttons
- Status indicators (.sending, .failed)

**AI (Planned):**
- `AIError` enum (rateLimitExceeded, openAIError, etc.)
- Fallback to "AI unavailable" message
- Manual alternatives when AI fails

---

## Testing

**Current Coverage (~17% of services):**

Unit Tests (2/12 services):
- ✅ `AuthenticationServiceTests` (10 tests) - login, signup, error handling
- ✅ `UserServiceTests` (18 tests) - CRUD, validation, caching

UI Tests:
- ✅ `AuthenticationUITests` (17 tests) - login, signup, forgot password flows

Manual:
- Real device, Simulator

**Missing (to be implemented):**
- `ChatServiceTests`, `MessageServiceTests`, `PresenceServiceTests`
- `TypingIndicatorServiceTests`, `ImageUploadServiceTests`, `MessageQueueTests`
- `NetworkMonitorTests`, `NotificationServiceTests`, `ImageCacheServiceTests`
- UI tests for chat, profile, settings screens

**AI Unit Tests (Planned):**
- `EmbeddingServiceTests` - OpenAI embedding generation
- `VectorSearchServiceTests` - Pinecone query logic
- `AIServiceTests` - Cloud Function calls, error handling

---

## Deployment

**iOS:** Xcode → Archive → TestFlight → App Store

**Firebase:**
```bash
firebase deploy --only firestore:rules,storage:rules
```

**AI (Planned):**
```bash
cd Psst/functions
npm install
firebase deploy --only functions

# Environment variables
firebase functions:config:set openai.key="sk-..."
firebase functions:config:set pinecone.apikey="..."
firebase functions:config:set pinecone.environment="..."
firebase functions:config:set pinecone.index="chat-messages"
```

---

## Brownfield Integration Notes

> **Note:** Detailed brownfield analysis has been moved to separate documents for better context management:
> - **PR #009 Analysis:** `brownfield-analysis-pr-009.md` (comprehensive migration strategy)
> - **Concise Architecture:** `architecture-concise.md` (streamlined reference, 350 lines)

### PR #006.5: User Roles (Implemented)

**Status:** ✅ Complete - Merged to develop

**Key Changes:**
- Added `UserRole` enum to `User.swift`: `.trainer` | `.client`
- Updated `SignUpView.swift` with role selection screen
- Made `displayName` required during signup (no skipping)
- Updated Firestore security rules to validate role field
- Role is immutable after account creation

**Files Modified:**
- `Models/User.swift` - Added role field
- `Views/Authentication/SignUpView.swift` - Role selection UI
- `Services/AuthenticationService.swift` - Updated signUp signature
- `Services/UserService.swift` - Updated createUser signature
- `firestore.rules` - Role validation rules

**Migration:** Existing users default to `.trainer` role for backward compatibility

**For full implementation details:** See `prds/pr-6.5-prd.md`

---

### PR #009: Trainer-Client Relationships (Implemented)

**Status:** ✅ Complete - Merged to develop

**Key Changes:**
- Created `/contacts/{trainerId}/clients` and `/prospects` collections
- Implemented `ContactService.swift` for relationship management
- Built `ContactsView.swift` with add client/prospect UI
- Updated security rules for relationship-based chat access
- Migration scripts: `migrateExistingChats.ts`, `fixProspectChats.ts`
- Group peer discovery (clients in shared groups can DM)

**Files Created:**
- `ContactService.swift`, `ContactsView.swift`, `AddClientView.swift`
- `Client.swift`, `Prospect.swift`, `Contact.swift`
- `migrations/migrateExistingChats.ts`, `migrations/fixProspectChats.ts`

**Files Modified:**
- `ChatService.swift` - Relationship validation in createChat()
- `UserService.swift` - Added getUserByEmail() method
- `firestore.rules` - Security rules for /contacts collections

**For full brownfield analysis:** See `brownfield-analysis-pr-009.md`

---

### PR #010C: Google Calendar Integration (Implemented)

**Status:** ✅ Complete - Merged to develop (Oct 26, 2025)

**Key Changes:**
- Implemented OAuth 2.0 flow for Google Calendar API access
- One-way sync: Psst calendar events → Google Calendar
- Automatic sync via Firestore trigger `onCalendarEventCreate`
- Token management with automatic refresh handling
- Settings UI for connecting/disconnecting Google Calendar account
- Support for calendar event types: Training, Call, Adhoc

**Files Created:**
- `GoogleCalendarSyncService.swift` - OAuth flow, token management, API calls
- `onCalendarEventCreate.ts` - Firestore trigger for auto-sync
- `googleCalendarService.ts` - Backend Google Calendar API integration
- `SecretsManager.swift` - Secure credential storage
- Calendar views: Multiple calendar UI components in Views/Calendar/

**Files Modified:**
- `CalendarService.swift` - Added Google Calendar sync integration
- `CalendarEvent.swift` - Added `googleCalendarEventId`, `syncedAt` fields
- `SettingsView.swift` - Added Google Calendar connection UI
- `functions/package.json` - Added `googleapis` v164.1.0, `luxon` v3.7.2
- `Info.plist` - Configured OAuth callback URL scheme

**Data Model Updates:**
```swift
/calendar/{trainerId}/events/{eventId}
  - googleCalendarEventId: String? (null if not synced)
  - syncedAt: Timestamp? (last successful sync)

/users/{userId}/integrations/googleCalendar
  - refreshToken: String (encrypted)
  - connectedAt: Timestamp
  - email: String (connected Google account)
```

**Key Features:**
- ✅ OAuth 2.0 secure authentication flow
- ✅ Automatic token refresh when expired
- ✅ Event creation, update, and deletion sync
- ✅ Visual sync status indicators in UI
- ✅ Error handling for API failures
- ✅ Settings toggle to disconnect calendar

**Note:** PR #010C implements backend sync and basic calendar views. Full calendar UI polish (week view refinements, Today's Schedule widget, Cal tab) will be completed in PR #010 (Full).

---
## Summary: Current System Capabilities

### For Trainers
**Messaging:**
- Real-time 1-on-1 and group chats with clients
- Image sharing with automatic compression
- Read receipts and typing indicators
- Offline message queuing

**AI Assistant:**
- Ask AI questions about clients and conversations
- Semantic search across all message history (RAG)
- AI automatically builds client profiles from chats
- AI can schedule calls, send messages, set reminders
- Long-press messages for AI summaries and context
- All AI actions logged for audit trail

**Contact Management:**
- Add clients via email (sends invitation)
- Track prospects (lightweight leads without full accounts)
- Upgrade prospects to clients
- Group peer discovery (clients in shared groups can DM)
- Relationship-based access control

**Calendar & Scheduling:**
- Google Calendar integration with OAuth 2.0
- One-way sync: Psst events → Google Calendar
- AI-powered natural language scheduling
- Event types: Training sessions, calls, adhoc appointments
- Automatic sync with visual status indicators

### For Clients
- Message their assigned trainer(s)
- Join group chats created by trainers
- Message other clients in shared groups
- View their own AI-built profile
- Standard messaging features (images, read receipts, etc.)

### Technology Highlights
**Frontend:**
- **152 Swift files** across Models (27), Services (18), ViewModels (11), Views (~83), Utilities (~10)
- SwiftUI + Combine for reactive UI
- MVVM architecture pattern with service layer
- Thread-safe async/await concurrency
- Google Calendar OAuth 2.0 integration
- AI-powered features across ~15 dedicated AI views

**Backend:**
- **26 TypeScript files**: 9 Cloud Functions + 9 services + 8 support files
- Node.js 18 runtime
- OpenAI GPT-4 for AI reasoning and function calling
- Pinecone vector database for semantic search (100K vectors free tier)
- Firebase Firestore, Realtime DB, Cloud Storage
- Google Calendar API (OAuth 2.0 + one-way sync)
- Comprehensive security rules with role-based access

**AI Integration:**
- Auto-embedding pipeline (all messages → Pinecone)
- RAG context retrieval for relevant conversation history
- Function calling for autonomous actions (scheduleCall, sendMessage, setReminder)
- Auto profile extraction from natural conversations
- Audit logging for all AI operations
- Contextual AI actions (long-press messages for summaries, related context)

---

## For New Developers: Where to Start

### Understand the Core
1. **Read this document** - You're doing it! ✅
2. **Review `Psst/agents/shared-standards.md`** - Coding standards and patterns
3. **Check `Psst/docs/ai-briefs.md`** - High-level feature descriptions

### Explore the Codebase
**iOS App Entry Points:**
- `Psst/Psst/PsstApp.swift` - App initialization
- `Psst/Psst/Views/RootView.swift` - Auth routing
- `Psst/Psst/Views/MainTabView.swift` - Main navigation

**Key Services:**
- `AuthenticationService.swift` - User auth and session management
- `ChatService.swift` - Chat CRUD operations
- `MessageService.swift` - Message sending and real-time updates
- `AIService.swift` - AI assistant integration
- `ContactService.swift` - Trainer-client relationships

**Cloud Functions:**
- `functions/src/index.ts` - Function exports
- `functions/src/chatWithAI.ts` - Main AI endpoint
- `functions/src/generateEmbedding.ts` - Auto-embedding trigger

### Common Tasks
**Add a new feature:**
1. Create PR brief in `ai-briefs.md` (or use `/brenda`)
2. Use `/pam` to generate PRD and TODO
3. Use `/caleb` to implement following the TODO
4. Test manually (see `testing-strategy.md`)
5. Create PR to `develop` branch

**Fix a bug:**
1. Identify affected service/view
2. Check service tests for existing coverage
3. Add test case for bug reproduction
4. Fix bug, verify test passes
5. Manual testing on simulator
6. Create PR with "fix:" prefix

**Update AI behavior:**
1. Modify Cloud Function in `functions/src/`
2. Update TypeScript types if needed
3. Test in Firebase emulator: `npm run serve`
4. Deploy: `npm run deploy`
5. Test in iOS app with real Firebase

---

**Document Owner:** Finesse Vanes (Arnold - The Architect)
**Last Updated:** October 26, 2025
**Status:** ✅ Complete brownfield analysis for AI-enhanced messaging app

**Arnold says:** "I'll be back... when you need more documentation. Come with me if you want to build."

---

**Recent Changes (Oct 26, 2025 - Comprehensive Update):**
- ✅ Fully documented PR #010C (Google Calendar Integration with OAuth 2.0)
- ✅ Added PR #011 (Voice AI Interface) to planned PRs with PRD/TODO status
- ✅ Updated project structure with accurate file counts:
  - iOS: 152 Swift files (27 Models, 18 Services, 11 ViewModels, ~83 Views, ~10 Utilities)
  - Backend: 26 TypeScript files (9 functions, 9 services, 8 support files)
- ✅ Expanded Views section to show AI (~15 files), Calendar (~10 files), Contacts folders
- ✅ Added detailed breakdown of AI Models, Contact Models, Calendar Models
- ✅ Updated Services with AI Services and Calendar Services sections
- ✅ Added ViewModels breakdown (Core, AI, Feature ViewModels)
- ✅ Updated Cloud Functions structure with all 26 TypeScript files categorized
- ✅ Updated system capabilities to reflect Google Calendar sync
- ✅ Added technology highlights with precise file counts and architecture details
