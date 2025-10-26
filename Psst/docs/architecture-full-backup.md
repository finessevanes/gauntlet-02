# Psst Architecture Documentation

**Last Updated:** October 25, 2025
**Version:** Post-MVP + AI Features Active + Trainer-Client Relationships (PR #009)
**Documented by:** Arnold (The Architect)

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
├── Models/
│   ├── User.swift                     # User data model (Firebase Auth integration)
│   ├── Chat.swift                     # Chat/conversation model (1-on-1 and groups)
│   ├── Message.swift                  # Message model with media support
│   ├── QueuedMessage.swift            # Offline message queue model
│   ├── UserPresence.swift             # Real-time presence tracking
│   ├── GroupPresence.swift            # Group presence aggregation
│   ├── TypingStatus.swift             # Typing indicator model
│   └── ReadReceiptDetail.swift        # Read receipt details for UI
│
├── Views/
│   ├── Authentication/
│   │   ├── LoginView.swift            # Email/password login
│   │   ├── SignUpView.swift           # User registration
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
│   ├── Components/
│   │   ├── ProfilePhotoPicker.swift   # Profile photo upload
│   │   ├── ImageMessageView.swift     # Image message display with tap-to-zoom
│   │   ├── MessageStatusIndicator.swift # Sending/delivered/failed status
│   │   ├── TypingIndicatorView.swift  # Animated "..." typing indicator
│   │   ├── OnlineIndicator.swift      # User online status badge
│   │   ├── UnreadDotIndicator.swift   # Unread message dot
│   │   ├── ReadReceiptDetailView.swift # Read receipt modal
│   │   ├── NetworkStatusBanner.swift   # Offline warning banner
│   │   └── [19 other reusable components]
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
│   │   ├── SettingsView.swift         # App settings
│   │   ├── NotificationsSettingsView.swift
│   │   ├── AboutView.swift
│   │   └── HelpSupportView.swift
│   │
│   ├── RootView.swift                 # Auth state routing (login vs. main app)
│   ├── MainTabView.swift              # Tab navigation (Chats, Profile, Settings)
│   └── LoadingScreenView.swift        # App loading state
│
├── ViewModels/
│   ├── AuthViewModel.swift            # Authentication state management
│   ├── ChatListViewModel.swift        # Chat list data + real-time updates
│   ├── ChatInteractionViewModel.swift # Message sending + real-time message updates
│   ├── MessageManagementViewModel.swift # Message read receipts + status
│   ├── PresenceTrackingViewModel.swift  # User presence updates
│   └── ReadReceiptDetailViewModel.swift # Read receipt details modal
│
├── Services/
│   ├── FirebaseService.swift          # Firebase SDK initialization
│   ├── AuthenticationService.swift    # User login/signup/logout
│   ├── UserService.swift              # User profile CRUD
│   ├── ChatService.swift              # Chat CRUD + user name fetching
│   ├── MessageService.swift           # Message send/receive + read receipts
│   ├── PresenceService.swift          # Realtime DB presence tracking
│   ├── TypingIndicatorService.swift   # Typing status updates
│   ├── MessageQueue.swift             # Offline message queue
│   ├── NetworkMonitor.swift           # Network connectivity monitor
│   ├── NotificationService.swift      # Push notification handling
│   ├── ImageUploadService.swift       # Image compression + Storage upload
│   └── ImageCacheService.swift        # Image download + cache
│
└── Utilities/
    ├── Logger.swift                    # Logging utility
    ├── ColorScheme.swift               # App color palette
    ├── Typography.swift                # Text styles
    ├── ButtonStyles.swift              # Reusable button styles
    ├── Date+Extensions.swift           # Date formatting helpers
    ├── DeepLinkHandler.swift           # Deep link navigation
    ├── ProfilePhotoError.swift         # Error types for profile photos
    └── PresenceObserverModifier.swift  # SwiftUI modifier for presence
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

**Active Functions (8 deployed):**
```
functions/src/
├── index.ts                        # Main exports file
├── onMessageCreate.ts              # Push notification triggers (PR #004)
├── generateEmbedding.ts            # Auto-embed messages to Pinecone (PR #006)
├── chatWithAI.ts                   # AI assistant endpoint (PR #006-007)
├── semanticSearch.ts               # RAG semantic search (PR #006)
├── executeFunctionCall.ts          # AI function calling (PR #008)
├── extractProfileInfoOnMessage.ts  # Auto client profile extraction (PR #007)
├── migrations/
│   ├── migrateExistingChats.ts     # PR #009 migration script
│   └── fixProspectChats.ts         # PR #009 prospect fix script
└── services/
    ├── openaiService.ts            # OpenAI API integration
    ├── pineconeService.ts          # Pinecone vector DB
    ├── vectorSearchService.ts      # Semantic search logic
    ├── aiChatService.ts            # AI conversation management
    ├── profileExtractionService.ts # Profile data extraction
    ├── functionExecutionService.ts # Function call execution
    ├── conversationService.ts      # Conversation history
    └── auditLogService.ts          # AI action audit logs
```

**Dependencies:**
- `@pinecone-database/pinecone` v6.1.2 - Vector database for semantic search
- `openai` v6.6.0 - OpenAI GPT-4 and embeddings API
- `firebase-admin` v12.0.0 - Firestore, Auth, Storage access
- `firebase-functions` v5.1.0 - Cloud Functions runtime

---

## AI System Architecture (ACTIVE)

### Current AI Implementation Status

**Completed PRs:**
- ✅ PR #006: AI Infrastructure, Embeddings, Basic Chat (Pinecone + OpenAI)
- ✅ PR #007: Auto Client Profiles (AI extracts profile data from chats)
- ✅ PR #008: AI Function Calling (schedule calls, send messages, set reminders)
- ✅ PR #009: Trainer-Client Relationships (access control + contact management)

**Next Planned:**
- 🔜 PR #010: Calendar & Scheduling System
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

#### 🔜 PR #011: Enhanced UI/UX for AI Features
**Status:** Not started
**Goal:** Polish AI interactions and improve visual design
- Redesign AI chat interface
- Better loading states and animations
- Improved error handling UX
- AI feature onboarding flow

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

**Add Role Selection:**
- New state: `@State private var selectedRole: UserRole?`
- New UI screen: Role selection (before or after form)
- Options: "I'm a Trainer" / "I'm a Client"
- Visual distinction (icons, descriptions)

**Enforce Required Name:**
- Update `isFormValid` computed property
- Remove fallback logic
- Validate displayName is not empty

**Flow Options:**
- **Option A:** Role selection first → then signup form
- **Option B:** Signup form → then role selection
- **Recommended:** Option A (cleaner UX)

#### 3. **AuthenticationService** (MODIFY)
**File:** `Psst/Psst/Services/AuthenticationService.swift`

**Update signUp method:**
```swift
// Current
func signUp(email: String, password: String, displayName: String? = nil) async throws -> User

// New
func signUp(email: String, password: String, displayName: String, role: UserRole) async throws -> User
```

**Changes:**
- Make displayName required (remove optional, remove fallback)
- Add role parameter
- Pass role to UserService.createUser()

#### 4. **UserService** (MODIFY)
**File:** `Psst/Psst/Services/UserService.swift`

**Update createUser method:**
```swift
// Current
func createUser(id: String, email: String, displayName: String, photoURL: String?) async throws -> User

// New
func createUser(id: String, email: String, displayName: String, role: UserRole, photoURL: String?) async throws -> User
```

**Changes:**
- Add role parameter
- Include role in Firestore document creation

#### 5. **Firestore Schema** (NEW FIELD)
**Collection:** `/users/{uid}`

**Add field:**
```
role: "trainer" | "client"
```

**Migration Strategy:**
- Existing users: Add Cloud Function or manual script to set default role
- New users: Role required at signup

#### 6. **UI Display** (OPTIONAL ENHANCEMENTS)
**Files to potentially update:**
- `ProfileView.swift` - Show role badge
- `ChatListView.swift` / `ChatRowView.swift` - Show user role
- `ChatView.swift` header - Display role in toolbar

---

### Affected Existing Code

#### Files That MUST Be Modified:
1. ✅ **User.swift** - Add role field
2. ✅ **SignUpView.swift** - Add role selection, enforce required name
3. ✅ **AuthenticationService.swift** - Update signUp signature
4. ✅ **UserService.swift** - Update createUser signature

#### Files That MAY Need Updates:
5. ⚠️ **AuthViewModel.swift** - Update signUp call
6. ⚠️ **ProfileView.swift** - Display user role
7. ⚠️ **EditProfileView.swift** - Allow role change? (probably not)
8. ⚠️ **Firestore Security Rules** - Add role-based rules (for future features)

#### Files That Reference User Model:
- Most ViewModels read `currentUser` from AuthenticationService
- No breaking changes as long as role field has default/fallback

---

### Testing Requirements

#### Unit Tests to Create:
- `UserModelTests.swift` - Test role encoding/decoding
- `AuthenticationServiceTests.swift` - Update signup tests with role
- `UserServiceTests.swift` - Update createUser tests with role

#### UI Tests to Create:
- `SignUpUITests.swift` - Test role selection flow
- `SignUpUITests.swift` - Test required displayName validation

#### Manual Testing:
- Create trainer account → verify role in Firestore
- Create client account → verify role in Firestore
- Attempt signup without name → should fail
- Attempt signup without role → should fail

---

### Security Rules Updates

**File:** `Psst/firestore.rules`

**Current `/users` rule:**
```javascript
match /users/{userId} {
  allow read: if request.auth != null;
  allow create: if request.auth != null && request.auth.uid == userId;
  allow update: if request.auth != null && request.auth.uid == userId;
  allow delete: if false;
}
```

**Potential enhancement (for future role-based features):**
```javascript
match /users/{userId} {
  allow read: if request.auth != null;
  allow create: if request.auth != null &&
                  request.auth.uid == userId &&
                  request.resource.data.role in ['trainer', 'client'];
  allow update: if request.auth != null &&
                  request.auth.uid == userId &&
                  // Prevent role changes after creation
                  request.resource.data.role == resource.data.role;
  allow delete: if false;
}
```

---

### Migration Strategy for Existing Users

**Problem:** Existing users in production don't have a role field.

**Options:**

1. **Default to trainer** (safest for MVP):
   - Modify User model to default role to `.trainer` if missing
   - Add migration code in AuthenticationService

2. **Prompt on next login**:
   - Show role selection modal for users without role
   - Update profile once selected

3. **One-time migration script**:
   - Cloud Function to set all existing users to `.trainer`

**Recommended:** Option 1 (default to trainer) for MVP simplicity.

---

### Dependencies for PR #007 (Auto Client Profiles)

**Why PR #007 is blocked:**

Cloud Function `extractProfileInfoOnMessage` needs to:
1. Identify which user is the trainer
2. Identify which user is the client
3. Create profile for client (owned by trainer)

**Current broken logic:**
```typescript
const clientId = otherMemberId;  // Wrong! Both could be trainers
const trainerId = senderId;      // Wrong! Both could be clients
```

**Fixed logic (after PR #006.5):**
```typescript
// Fetch both users from Firestore
const user1 = await getUser(senderId);
const user2 = await getUser(otherMemberId);

// Identify trainer and client
const trainer = user1.role === 'trainer' ? user1 : user2;
const client = user1.role === 'client' ? user1 : user2;

// Only create profile if chat is between trainer and client
if (!trainer || !client) {
  console.log('Skipping: Not a trainer-client conversation');
  return;
}

// Create profile for client
const clientId = client.uid;
const trainerId = trainer.uid;
```

---

### Implementation Checklist

**Phase 1: Models & Services**
- [ ] Create `UserRole` enum
- [ ] Add `role` field to User model
- [ ] Update User codable conformance
- [ ] Update User Firestore dictionary conversion
- [ ] Update AuthenticationService.signUp() signature
- [ ] Update UserService.createUser() signature

**Phase 2: UI Changes**
- [ ] Create role selection UI component
- [ ] Update SignUpView with role selection
- [ ] Enforce required displayName validation
- [ ] Update AuthViewModel to pass role

**Phase 3: Testing**
- [ ] Unit tests for User model with role
- [ ] Unit tests for signup with role
- [ ] UI tests for role selection flow
- [ ] Manual testing on simulator

**Phase 4: Security & Migration**
- [ ] Update Firestore security rules
- [ ] Add migration logic for existing users
- [ ] Deploy security rules

**Phase 5: Optional Enhancements**
- [ ] Display role badge in ProfileView
- [ ] Show role in chat headers
- [ ] Add role filtering (future feature)

---

## Brownfield Analysis: PR #009 - Trainer-Client Relationships

**Status:** Analysis Complete
**Date:** October 25, 2025
**Document:** `Psst/docs/brownfield-analysis-pr-009.md`

### Overview

PR #009 introduces **explicit trainer-client relationships** to replace the current "everyone can message everyone" architecture. This is a **high-risk brownfield change** that modifies critical components.

### Affected Services

**Modified Files:**
- `ChatService.swift` - Add relationship validation to `createChat()` method (Lines 144-214)
- `UserService.swift` - Add `getUserByEmail()` method for email lookup
- `firestore.rules` - Add security rules for new `/contacts` collections

**New Files:**
- `ContactService.swift` - Manage trainer-client relationships
- Models: `Client.swift`, `Prospect.swift`, `Contact.swift` protocol
- Views: `ContactsView.swift`, `AddClientView.swift`, etc.

### Integration Points

```
ContactService (NEW)
    ↓
    ├── UserService.getUserByEmail() (NEW METHOD)
    ├── UserService.getUser() (EXISTING)
    ├── AuthenticationService.currentUser (EXISTING)
    └── Firestore /contacts/{trainerId}/clients (NEW)

ChatService.createChat() (MODIFIED)
    ↓
    ├── ContactService.validateRelationship() (NEW)
    ├── UserService.getUser() (EXISTING - for roles)
    └── Firestore /chats (EXISTING)
```

### Key Risks

1. **Breaking existing chat functionality** (CRITICAL)
   - Mitigation: Feature flag, gradual rollout, comprehensive testing
2. **Migration script failures** (CRITICAL)
   - Mitigation: Dry-run in staging, idempotent script, Firestore backup
3. **Email lookup performance** (MEDIUM)
   - Mitigation: Firestore index on email field, caching, timeouts

### Migration Strategy

**Goal:** Auto-add existing chat participants as clients for all trainers

**Approach:**
1. Identify all trainers (role == "trainer")
2. For each trainer, get all chats where they're a member
3. Extract unique client IDs from chat members
4. Create client relationships in `/contacts/{trainerId}/clients/{clientId}`

**Deployment Phases:**
1. Week 1: Deploy ContactService + security rules (no validation)
2. Week 2: Test migration script in staging
3. Week 3: Run migration in production
4. Week 4: Enable relationship validation (10% → 50% → 100%)

### Required Changes Summary

**ChatService.swift:**
- Add `contactService` dependency
- Add relationship validation in `createChat()` before chat creation
- Fetch user roles to determine trainer/client
- Throw `ChatError.relationshipNotFound` if no relationship exists

**UserService.swift:**
- Add `getUserByEmail(_ email: String) async throws -> User` method
- Query Firestore by email field (requires index)
- Return first match or throw `UserServiceError.userNotFound`

**Security Rules (firestore.rules):**
```javascript
match /contacts/{trainerId}/clients/{clientId} {
  allow read, write: if request.auth != null &&
                        request.auth.uid == trainerId;
}

match /contacts/{trainerId}/prospects/{prospectId} {
  allow read, write: if request.auth != null &&
                        request.auth.uid == trainerId;
}
```

### Performance Targets (from PRD)

- Contact list load: < 500ms
- Email lookup: < 200ms
- Relationship validation: < 100ms
- Search filtering: < 100ms

### Testing Requirements

**Unit Tests:**
- ContactServiceTests (9 test cases)
- ChatServiceTests (6 new test cases for relationship validation)
- UserServiceTests (4 new test cases for email lookup)

**Integration Tests:**
- End-to-end flows: add client → create chat
- Migration script testing in staging
- Group peer discovery scenarios

**Manual Testing:**
- Test with real user accounts
- Verify relationship validation errors are clear
- Test offline scenarios

### Rollback Plan

**If migration fails:**
1. Stop immediately, disable feature flag
2. Delete `/contacts` collection (or mark invalid)
3. Fix migration script, re-run from step 1

**If validation causes issues:**
1. Disable feature flag immediately
2. Investigate failures from logs
3. Re-run migration for affected users
4. Re-enable validation once fixed

**Rollback Time:** < 5 minutes (disable feature flag and re-deploy)

### Success Criteria

✅ All existing chats remain accessible after migration
✅ New relationship validation works without blocking legitimate conversations
✅ Migration completes without data loss
✅ Performance targets met (< 500ms contact list, < 200ms email lookup)
✅ Feature flag enables gradual rollout
✅ Rollback plan tested and documented

### Related Documents

- **PRD:** `Psst/docs/prds/pr-009-prd.md`
- **TODO:** `Psst/docs/todos/pr-009-todo.md`
- **Brownfield Analysis:** `Psst/docs/brownfield-analysis-pr-009.md` ← **Full detailed analysis**

---

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

### For Clients
- Message their assigned trainer(s)
- Join group chats created by trainers
- Message other clients in shared groups
- View their own AI-built profile
- Standard messaging features (images, read receipts, etc.)

### Technology Highlights
**Frontend:**
- 128 Swift files across Models, Views, ViewModels, Services
- SwiftUI + Combine for reactive UI
- MVVM architecture pattern
- Thread-safe async/await concurrency

**Backend:**
- 8 Cloud Functions (TypeScript, Node.js 18)
- OpenAI GPT-4 for AI reasoning and function calling
- Pinecone vector database for semantic search
- Firebase Firestore, Realtime DB, Cloud Storage
- Comprehensive security rules with role-based access

**AI Integration:**
- Auto-embedding pipeline (all messages → Pinecone)
- RAG context retrieval for relevant conversation history
- Function calling for autonomous actions
- Auto profile extraction from natural conversations
- Audit logging for all AI operations

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
**Last Updated:** October 25, 2025
**Status:** ✅ Complete brownfield analysis for AI-enhanced messaging app

**Arnold says:** "I'll be back... when you need more documentation. Come with me if you want to build."
