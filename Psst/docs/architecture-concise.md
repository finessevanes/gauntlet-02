# Psst Architecture Documentation (Concise)

**Last Updated:** October 26, 2025
**Version:** AI Features Active + Google Calendar Sync (PRs #006-010C Complete)
**Documented by:** Arnold (The Architect)

> **For detailed brownfield analysis:** See `brownfield-analysis-pr-009.md`
> **For implementation details:** See individual PRDs in `prds/`

---

## Quick System Overview

**Psst** = Personal trainer messaging app with AI-powered assistant

**Stack:** SwiftUI + Firebase + OpenAI GPT-4 + Pinecone vector DB

**Status:**
- ✅ Core messaging (real-time, images, presence, read receipts)
- ✅ AI assistant with RAG semantic search
- ✅ Auto client profile extraction
- ✅ AI function calling (schedule, message, remind)
- ✅ Trainer-client relationship management
- ✅ Google Calendar integration (OAuth + one-way sync)

---

## Architecture at a Glance

```
┌─────────────────────────────────────────────┐
│  iOS App (SwiftUI)                          │
│  • 152 Swift files (MVVM pattern)           │
│  • Services: Auth, Chat, Message, AI,       │
│    Contact, Profile, Presence, Image,       │
│    Calendar, GoogleCalendarSync             │
│  • Real-time Firestore listeners            │
│  • Async/await concurrency                  │
└─────────────────┬───────────────────────────┘
                  │ Firebase SDK + Google Calendar API
                  ▼
┌─────────────────────────────────────────────┐
│  Firebase Backend                            │
│  • Firestore (chats, users, profiles,       │
│    calendar events)                          │
│  • Realtime DB (presence tracking)          │
│  • Cloud Storage (images)                   │
│  • 9 Cloud Functions (TypeScript)           │
└─────────────────┬───────────────────────────┘
                  │ OpenAI API + Pinecone API
                  ▼
┌─────────────────────────────────────────────┐
│  AI Infrastructure                           │
│  • OpenAI GPT-4 (reasoning + function calls) │
│  • text-embedding-3-small (1536-dim vectors)│
│  • Pinecone vector DB (semantic search)     │
└─────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────┐
│  External Services                           │
│  • Google Calendar API (OAuth + event sync) │
│  • One-way sync: Psst → Google Calendar    │
└─────────────────────────────────────────────┘
```

---

## Key Firestore Collections

```
/users/{uid}
  - email, displayName, role (trainer|client), photoURL
  - fcmToken (push notifications)

/chats/{chatId}
  - members: [uid1, uid2, ...], isGroupChat, groupName
  - lastMessage, lastMessageTimestamp

  /chats/{chatId}/messages/{messageId}
    - text, senderID, timestamp, readBy: [uids]
    - mediaType, mediaURL (for images)

/contacts/{trainerId}/clients/{clientId}
  - clientId, displayName, email, status, addedAt

/contacts/{trainerId}/prospects/{prospectId}
  - prospectId, displayName, placeholderEmail, notes

/clientProfiles/{clientId}
  - trainerId, clientId, categories: [items]
  - Auto-extracted by AI from conversations

/ai_conversations/{conversationId}
  - trainerId, createdAt, updatedAt

  /ai_conversations/{conversationId}/messages/{messageId}
    - role (user|assistant), content, timestamp

/calendar/{trainerId}/events/{eventId}
  - trainerId, clientId/prospectId, title, startTime, endTime
  - eventType: "training" | "call" | "adhoc"
  - status: "scheduled" | "completed" | "cancelled"
  - googleCalendarEventId, syncedAt (Google Calendar sync)
  - createdBy: "ai" | "trainer"

/reminders/{reminderId}
  - trainerId, text, dueDate, completed
  - createdBy: "ai" | "user"

/aiActions/{actionId}
  - trainerId, action, parameters, result, timestamp
  - Audit log for all AI operations
```

---

## Cloud Functions (TypeScript)

**Active Functions:**
1. `onMessageCreate` - Send push notifications (PR #004)
2. `generateEmbedding` - Auto-embed messages to Pinecone (PR #006)
3. `chatWithAI` - AI assistant endpoint with RAG (PR #006-007)
4. `semanticSearch` - Semantic search over message history (PR #006)
5. `executeFunctionCall` - Execute AI-requested actions (PR #008)
6. `extractProfileInfoOnMessage` - Auto-build client profiles (PR #007)
7. `onCalendarEventCreate` - Firestore trigger for Google Calendar sync (PR #010C)
8. `migrateExistingChats` - PR #009 migration script
9. `fixProspectChats` - PR #009 prospect fix script

**Key Services (Backend):**
- `openaiService.ts` - OpenAI API integration
- `pineconeService.ts` - Pinecone vector DB operations
- `vectorSearchService.ts` - Semantic search logic
- `aiChatService.ts` - AI conversation management
- `profileExtractionService.ts` - GPT-4 profile extraction
- `functionExecutionService.ts` - AI function execution
- `auditLogService.ts` - AI action logging
- `googleCalendarService.ts` - Google Calendar API integration (PR #010C)

---

## iOS App Structure

**Services (20 files):**
- `AuthenticationService.swift` - User auth, session management
- `UserService.swift` - User CRUD operations
- `ChatService.swift` - Chat creation, user lookup
- `MessageService.swift` - Message send/receive, read receipts
- `PresenceService.swift` - Real-time presence tracking
- `TypingIndicatorService.swift` - Typing status updates
- `ImageUploadService.swift` - Image compression + Storage upload
- `ImageCacheService.swift` - Image download + caching
- `MessageQueue.swift` - Offline message queue
- `NetworkMonitor.swift` - Network connectivity detection
- `NotificationService.swift` - Push notification handling
- `AIService.swift` - AI assistant integration (PR #006)
- `ProfileService.swift` - Client profile management (PR #007)
- `ContactService.swift` - Trainer-client relationships (PR #009)
- `CalendarService.swift` - Event CRUD, conflict detection (PR #010C)
- `GoogleCalendarSyncService.swift` - OAuth + Google Calendar sync (PR #010C)
- `CalendarConflictService.swift` - Smart time suggestions (PR #010C)

**ViewModels (13 files):**
- `AuthViewModel.swift` - Auth state management
- `ChatListViewModel.swift` - Chat list + real-time updates
- `ChatInteractionViewModel.swift` - Message sending + receiving
- `MessageManagementViewModel.swift` - Read receipts + status
- `PresenceTrackingViewModel.swift` - User presence updates
- `ReadReceiptDetailViewModel.swift` - Read receipt details
- `AIAssistantViewModel.swift` - AI chat state (PR #006)
- `ContextualAIViewModel.swift` - Contextual AI actions (PR #008)
- `ClientProfileViewModel.swift` - Auto profile management (PR #007)
- `ContactViewModel.swift` - Contact management (PR #009)
- `CalendarViewModel.swift` - Calendar state, event management (PR #010C)

**Key Models (30+ files):**
- Core: `User.swift`, `Chat.swift`, `Message.swift`, `QueuedMessage.swift`
- AI: `AIMessage.swift`, `AIConversation.swift`, `AIResponse.swift`, `AIContextAction.swift`
- Contacts: `Client.swift`, `Prospect.swift`, `Contact.swift`
- Profiles: `ClientProfile.swift`, `ProfileItem.swift`, `ProfileCategory.swift`
- Calendar: `CalendarEvent.swift`, `SchedulingResult.swift` (PR #010C)
- Actions: `Reminder.swift`, `FunctionCall.swift`, `RelatedMessage.swift`
- Presence: `UserPresence.swift`, `GroupPresence.swift`, `TypingStatus.swift`

---

## Data Flow Examples

### Message Send Flow
```
User types → ChatInteractionViewModel.sendMessage()
→ MessageService.sendMessage() → Optimistic UI (instant display)
→ Firestore write → Snapshot listener → Update to .delivered
→ generateEmbedding trigger → Pinecone storage (for RAG)
```

### AI Assistant Flow
```
User asks "Find clients with injuries"
→ AIService.chatWithAI() → Cloud Function
→ Generate embedding → Pinecone semantic search
→ GPT-4 with context → Response
→ Save to /ai_conversations → Display in iOS
```

### Auto Profile Extraction Flow
```
Client: "My knee hurts"
→ Message saved to Firestore
→ extractProfileInfoOnMessage trigger
→ GPT-4 extracts: injury="knee pain"
→ Write to /clientProfiles/{clientId}
→ Trainer sees updated profile
```

---

## Completed PRs (Production)

**✅ PR #006.5: User Roles** (Merged)
- `UserRole` enum: trainer | client
- Required displayName during signup
- Role-based security rules

**✅ PR #006: AI Infrastructure** (Merged)
- Pinecone vector DB setup
- Auto-embedding pipeline
- AI chat with RAG semantic search
- `AIService.swift`, `AIAssistantView.swift`

**✅ PR #007: Auto Client Profiles** (Merged)
- AI extracts profile data from chats
- `ClientProfile.swift`, `ProfileService.swift`
- Firestore trigger: `extractProfileInfoOnMessage`

**✅ PR #008: AI Function Calling** (Merged)
- GPT-4 function calling integration
- Actions: scheduleCall, sendMessage, setReminder
- Confirmation UI + audit logging

**✅ PR #009: Trainer-Client Relationships** (Merged)
- `/contacts/{trainerId}/clients` collections
- Relationship-based access control
- Contact management UI
- Migration scripts for existing data

**✅ PR #010C: Google Calendar Integration** (Merged)
- OAuth 2.0 flow for Google Calendar API
- One-way sync: Psst events → Google Calendar
- `GoogleCalendarSyncService.swift` with token management
- Calendar event types: Training, Call, Adhoc
- Firestore trigger `onCalendarEventCreate` for auto-sync
- Settings UI for connecting/disconnecting Google Calendar

---

## Next Planned PRs

- 🔜 **PR #010 (Full):** Calendar UI (Week view, Today's Schedule widget, Cal tab)
- 🔜 **PR #011:** Enhanced UI/UX for AI Features
- 🔜 **PR #012:** User Preferences & Personalization
- 🔜 **PR #013:** YOLO Mode (aggressive AI automation)

---

## Integration Points for New Features

**To add AI feature:**
1. Create Cloud Function in `functions/src/`
2. Add iOS service method in `AIService.swift`
3. Create ViewModel for state management
4. Build UI in Views/AI/
5. Test with Firebase emulator

**To modify data model:**
1. Update Swift model in `Models/`
2. Update Firestore schema
3. Update security rules in `firestore.rules`
4. Create migration script if needed

**To add new service:**
1. Create service in `Services/`
2. Inject via `@EnvironmentObject` or direct init
3. Add error handling enum
4. Write unit tests

---

## Critical Files Reference

**Entry Points:**
- `PsstApp.swift` - App initialization
- `RootView.swift` - Auth routing
- `MainTabView.swift` - Main navigation

**Security:**
- `firestore.rules` - Firestore security rules (200 lines)
- Role-based access, relationship validation

**Backend Config:**
- `functions/src/index.ts` - Function exports
- `functions/src/config/ai.config.ts` - AI settings
- `functions/src/config/secrets.ts` - API keys

**Testing:**
- `testing-strategy.md` - Manual testing approach
- Unit tests: `AuthenticationServiceTests`, `UserServiceTests`

---

## Performance Targets

- App load: < 2-3s (cold start)
- Message delivery: < 100ms
- Scrolling: 60fps with 100+ messages
- AI response: < 3s (with RAG)
- Image upload: < 2s (compressed)

---

## Developer Quick Start

**1. Understand the system:**
- Read this doc (you're doing it!)
- Check `shared-standards.md` for code patterns
- Review `ai-briefs.md` for feature context

**2. Run the app:**
```bash
cd Psst
xcodebuild -destination 'platform=iOS Simulator,name=Vanes' build
```

**3. Test Cloud Functions:**
```bash
cd functions
npm install
npm run serve  # Start emulator
```

**4. Common workflows:**
- Add feature: `/brenda` → `/pam` → `/caleb`
- Fix bug: Identify service → Add test → Fix → Manual test → PR
- Update AI: Modify Cloud Function → Test emulator → Deploy

---

**For Detailed Documentation:**
- Full architecture: See original `architecture.md` (1,381 lines)
- PR #009 brownfield: See `brownfield-analysis-pr-009.md`
- Individual PRDs: See `prds/pr-{number}-prd.md`
- Testing strategy: See `testing-strategy.md`

---

**Document Owner:** Arnold (The Architect)
**Last Updated:** October 26, 2025
**Status:** ✅ Concise reference for agent context management

**Arnold says:** "Come with me if you want to build... efficiently."

---

**Recent Changes (Oct 26, 2025):**
- ✅ Added PR #010C (Google Calendar Integration) to completed PRs
- ✅ Updated Swift file count (128 → 152 files)
- ✅ Added Calendar services and ViewModels
- ✅ Updated Firestore collections schema with calendar events
- ✅ Added googleCalendarService.ts to backend services
- ✅ Added External Services section (Google Calendar API)
