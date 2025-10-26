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

**Active Functions (9 + 2 migrations):**
1. `onMessageCreate` - Push notifications (PR #004)
2. `generateEmbedding` - Auto-embed to Pinecone (PR #006)
3. `chatWithAI` - AI assistant with RAG (PR #006-007)
4. `semanticSearch` - Semantic search (PR #006)
5. `executeFunctionCall` - AI actions (PR #008)
6. `extractProfileInfoOnMessage` - Auto profiles (PR #007)
7. `onCalendarEventCreate` - Google Calendar sync (PR #010C)
8. `migrateExistingChats` - PR #009 migration
9. `fixProspectChats` - PR #009 prospect fix

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

**Services (18 files):**
- **Core:** AuthenticationService, UserService, ChatService, MessageService, PresenceService, TypingIndicatorService, MessageQueue, NetworkMonitor, NotificationService, ImageUploadService, ImageCacheService, FirebaseService
- **AI (PRs #006-008):** AIService, ProfileService, ContactService
- **Calendar (PR #010A-C):** CalendarService, CalendarConflictService, GoogleCalendarSyncService

**ViewModels (11 files):**
- **Core:** AuthViewModel, ChatListViewModel, ChatInteractionViewModel, MessageManagementViewModel, PresenceTrackingViewModel, ReadReceiptDetailViewModel
- **AI (PRs #006-008):** AIAssistantViewModel, ContextualAIViewModel, ClientProfileViewModel
- **Features (PRs #009-010):** ContactViewModel, CalendarViewModel

**Models (27 files):**
- **Core (8):** User, Chat, Message, QueuedMessage, UserPresence, GroupPresence, TypingStatus, ReadReceiptDetail
- **AI (10):** AIMessage, AIConversation, AIResponse, AIContextAction, AIContextResult, AISelectionRequest, FunctionCall, Reminder, ReminderSuggestion, RelatedMessage
- **Contacts (3):** Client, Prospect, Contact
- **Profiles (4):** ClientProfile, ProfileItem, ProfileCategory, ProfileItemSource
- **Calendar (2):** CalendarEvent, SchedulingResult

**Views (~83 files organized in):**
- Authentication (4), ChatList (6), AI (~15), Calendar (~10), Contacts (3), Components (~30), UserSelection (3), Profile (2), Settings (4), ConversationList (1), Root/Tab/Loading (3)

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

- 🔜 **PR #010 (Full):** Calendar UI polish (Week view refinements, Today's Schedule widget)
- 🔜 **PR #011:** Voice AI Interface (Whisper STT + iOS TTS, hands-free conversations) - **PRD/TODO ready**
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

**Recent Changes (Oct 26, 2025 - Comprehensive Update):**
- ✅ Added PR #010C (Google Calendar Integration) to completed PRs
- ✅ Updated file counts: 152 Swift files (27 Models, 18 Services, 11 ViewModels, ~83 Views), 26 TypeScript files
- ✅ Reorganized Services/ViewModels/Models sections with accurate categorization
- ✅ Added PR #011 (Voice AI) to planned PRs with PRD/TODO ready status
- ✅ Updated Firestore collections with googleCalendarEventId and syncedAt fields
- ✅ Updated Cloud Functions count (9 active functions + 2 migrations)
- ✅ Added External Services section for Google Calendar API integration
