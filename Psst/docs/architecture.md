# Psst Architecture Documentation

**Last Updated:** October 23, 2025  
**Version:** Post-MVP + AI Features Integration Plan

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

Psst is a personal trainer messaging app built with SwiftUI and Firebase. The app currently supports:
- Real-time messaging (1-on-1 and group chats)
- User presence tracking (online/offline status)
- Read receipts and typing indicators
- Image sharing with automatic compression
- Offline message queuing
- Push notifications

**Upcoming Enhancement:** AI-powered assistant features to help trainers manage clients, conversations, and scheduling.

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

### Cloud Functions

**Current:** None deployed yet

**Planned (AI Features):**
- `chatWithAI` - AI assistant endpoint
- `embedMessage` - Auto-embed new messages to Pinecone
- `backfillEmbeddings` - One-time script to embed existing messages
- `processImageMessage` - Server-side image processing (future)
- `sendPushNotification` - Push notification triggers (future)

---

## AI System Integration Plan

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

### New Components for AI

#### iOS App Additions

**New Views:**
- `AIAssistantView.swift` - Dedicated AI chat interface
- `AIMessageRow.swift` - AI response bubble (distinct styling)
- `ContextualAIMenu.swift` - Long-press menu on messages (summarize, surface context, set reminder)
- `AILoadingIndicator.swift` - Animated "AI is thinking..." indicator

**New ViewModels:**
- `AIAssistantViewModel.swift` - Manages AI chat state
- `AIContextViewModel.swift` - Handles contextual AI actions

**New Services:**
- `AIService.swift` - Calls Firebase Cloud Functions for AI operations

**New Models:**
- `AIMessage.swift` - AI conversation message model
- `AIConversation.swift` - AI chat session model

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

### AI Assistant Flow (Planned)

```
User asks AI: "Find clients with injuries"
         ↓
AIAssistantViewModel.sendMessage(query)
         ↓
AIService.chatWithAI(query)
         ↓
Calls Firebase Cloud Function: chatWithAI(query)
         ↓
Cloud Function:
  1. Generate embedding for query (OpenAI)
  2. Search Pinecone for similar messages (vector search)
  3. Load trainer preferences from Firestore
  4. Send context + query to GPT-4 via AI SDK
  5. GPT-4 generates response
         ↓
Returns AI response to iOS app
         ↓
AIAssistantViewModel updates state
         ↓
AIAssistantView displays response
```

### Auto-Embedding Flow (Planned)

```
User sends message: "My knee hurts"
         ↓
Message written to Firestore (existing flow)
         ↓
Firestore trigger fires: onMessageCreate
         ↓
Cloud Function: embedMessage(messageData)
         ↓
1. Generate embedding vector (OpenAI API)
2. Store in Pinecone with metadata:
   - firestore_message_id
   - firestore_chat_id
   - trainer_id
   - text
   - timestamp
         ↓
Message now searchable by semantic meaning
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

### New Stack for AI Features

| Layer | Technology | Purpose | Why Chosen |
|-------|-----------|---------|------------|
| **AI Model** | OpenAI GPT-4 | Text generation, reasoning | Best function calling, reliable agents |
| **Agent Framework** | AI SDK by Vercel | Orchestrates AI behavior | Simpler than LangChain, great for Cloud Functions |
| **Vector DB** | Pinecone | Semantic search | Purpose-built, managed, 100k free tier |
| **Embeddings** | OpenAI text-embedding-3-small | Convert text to vectors | Cost-effective ($0.02/1M tokens), 1536 dimensions |
| **Backend Runtime** | Node.js (Cloud Functions) | Run AI logic | Already using Firebase, easy integration |

---

## Integration Strategy

### Two Development Approaches

You have **2 agents available** (can work in parallel). We've outlined two strategies:

**Option A: Sequential Build**
- One agent works on AI features linearly (PR-010 → PR-011 → PR-012 → ... → PR-016)
- Lower risk, thorough testing between phases
- Best for: Learning new tech, stability

**Option B: Parallel Build (~40% faster)**
- Agent 1: Backend track (Pinecone, Cloud Functions, embeddings)
- Agent 2: Frontend track (iOS UI, ViewModels, Services)
- Requires coordination, regular sync points
- Best for: Speed, experienced teams

**Recommended:** Start parallel (Phases 1-2), pivot to sequential if coordination becomes difficult.

---

### Phase 1: AI Infrastructure Setup (PR-010)

**Goal:** Set up foundation for AI features

**Tasks:**
1. Create Pinecone account and index (free tier)
2. Configure index: 1536 dimensions, cosine similarity
3. Set up Cloud Functions project dependencies
4. Implement `embeddingService.ts` with OpenAI API + Pinecone SDK
5. Create Firestore trigger: `embedMessage` (auto-embed new messages)
6. Create backfill script for existing messages
7. Set up environment variables (OpenAI key, Pinecone API key)

**Firestore Changes:** None (read-only)

**iOS Changes:** None yet

**Deliverable:** Backend infrastructure ready for AI queries

---

### Phase 2: Basic AI Chat Interface (PR-011)

**Goal:** Dedicated "AI Assistant" chat screen

**Tasks:**
1. Implement `chatWithAI` Cloud Function (basic Q&A, no tools yet)
2. Create `AIService.swift` in iOS app
3. Create `AIAssistantViewModel.swift`
4. Create `AIAssistantView.swift` (chat UI)
5. Add "AI Assistant" button in ChatListView
6. Display AI responses with distinct styling

**Integration Points:**
- AIService calls Cloud Function
- No Firestore changes (AI conversations in-memory for now)

**Deliverable:** Users can ask AI general questions

---

### Phase 3: RAG Pipeline (Semantic Search) (PR-012)

**Goal:** AI can search chat history semantically

**Tasks:**
1. Integrate vector search into `chatWithAI` function
2. Load relevant messages before GPT-4 call
3. Format context for AI prompt
4. Handle semantic queries ("find injuries" → "hurt", "pain", "strain")

**Integration Points:**
- Cloud Function queries Pinecone
- Returns results to GPT-4 as context

**Deliverable:** AI answers questions about past conversations

---

### Phase 4: AI Function Calling (PR-013)

**Goal:** AI can perform actions (schedule, remind, send message)

**Tasks:**
1. Define tools in AI SDK (scheduleCall, sendMessage, setReminder)
2. Implement execute functions for each tool
3. Write to Firestore from Cloud Functions
4. Return action confirmation to user

**Integration Points:**
- Cloud Functions write to Firestore `/calendar`, `/reminders` collections

**Deliverable:** AI can perform tasks, not just answer questions

---

### Phase 5: Contextual AI Features (PR-014)

**Goal:** AI buttons inside regular chats

**Tasks:**
1. Add long-press menu to MessageRow
2. Create separate Cloud Functions for quick actions (summarize, surface context)
3. Display results inline or in modal
4. Cache frequent AI responses

**iOS Changes:**
- MessageRow gets long-press gesture
- ContextualAIMenu component
- Quick action handlers

**Deliverable:** AI features accessible without leaving chat

---

### Phase 6: Advanced AI Agents (PR-015)

**Goal:** Proactive assistant, multi-step conversations

**Tasks:**
1. Implement state management for multi-turn conversations
2. Add proactive triggers (calendar conflicts, inactive clients)
3. Store user preferences in Firestore
4. Personalize AI voice/style

**Integration Points:**
- Firestore `/users/{userID}/preferences`
- Firestore `/users/{userID}/ai_conversations`

**Deliverable:** AI acts proactively, maintains conversation context

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

**Document Owner:** Finesse Vanes  
**Last Updated:** October 24, 2025
