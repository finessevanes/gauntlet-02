# Memory Bank

I am Alex, an expert software engineer with a unique characteristic: my memory resets completely between sessions. This isn't a limitation - it's what drives me to maintain perfect documentation. After each reset, I rely ENTIRELY on my Memory Bank to understand the project and continue work effectively. I MUST read ALL memory bank files at the start of EVERY task - this is not optional.

---

## 1. Brief

**Project:** Simplified MessageAI  
**Tagline:** Building Cross-Platform Messaging Apps  
**Type:** Native iOS Chat Application

### Core Requirements (10 Must-Haves)
1. One-on-one chat functionality
2. Real-time message delivery (2+ users)
3. Message persistence (survives app restarts)
4. Optimistic UI updates
5. Online/offline status indicators
6. Message timestamps
7. User authentication (accounts/profiles)
8. Basic group chat functionality (3+ users)
9. Message read receipts
10. Push notifications (foreground)

### Project Goals
- Build a simple, reliable, native iOS messaging app
- Focus on seamless user experience
- Provide robust offline capabilities
- Support both 1-on-1 and group conversations
- Enable real-time synchronization

---

## 2. Product Context

### Why This Exists
To create a native iOS chat application that prioritizes simplicity, reliability, and seamless user experience over feature bloat. The focus is on doing core messaging features exceptionally well.

### Problems It Solves
- **Real-time Communication:** Users need instant message delivery with low latency
- **Offline Reliability:** Users must access messages and queue sends without connectivity
- **Status Awareness:** Users need to know if contacts are online/offline
- **Message Confirmation:** Users need read receipts to know messages were seen
- **Group Coordination:** Users need to communicate in groups of 3+ people

### How It Works

**User Journey:**
1. **Onboarding:** Download app → Sign up (email/password or social auth) → Log in
2. **Home:** View conversation list with recent messages, timestamps, and user status
3. **Initiate Chat:** Start new 1-on-1 or group chat by selecting from contacts
4. **Conversation:** 
   - Send/receive messages with instant UI updates
   - See real-time message arrivals
   - View timestamps on all messages
   - See read receipts on sent messages
5. **Offline/Background:**
   - Receive push notifications when app is closed
   - Read persisted messages while offline
   - Queue messages to send when reconnected

### User Experience Goals
- **Instant Feedback:** Optimistic UI shows messages immediately
- **Always Available:** Offline persistence keeps conversations accessible
- **Status Transparency:** Clear online/offline indicators
- **Message Confidence:** Read receipts confirm message delivery
- **Modern Design:** Beautiful, intuitive SwiftUI interface

---

## 3. Active Context

### Current Work Focus
**Phase:** Project Initialization  
**Status:** Setting up Memory Bank and project structure

### Recent Changes
- Created PRD with full technical specifications
- Defined database schema (Firestore NoSQL)
- Established 4-phase implementation plan
- Completed Memory Bank structure

### Next Steps
1. **Setup Firebase project**
   - Configure Firebase Authentication
   - Set up Firestore database
   - Configure Firebase Cloud Messaging
   - Enable Firestore offline persistence

2. **Initialize iOS Project**
   - Create SwiftUI project in Xcode
   - Add Firebase SDK dependencies
   - Set up basic navigation structure
   - Configure project settings

3. **Phase 1: Core Foundation**
   - Implement user authentication (sign up, log in, log out)
   - Build basic SwiftUI app structure
   - Create users collection and profile model
   - Set up navigation framework

### Active Decisions
- **SwiftUI over UIKit:** Chosen for faster development, native data binding, and cross-platform future
- **Firebase as BaaS:** Chosen to bundle Auth, Firestore, Realtime DB (for presence), and FCM in one platform
- **NoSQL Schema:** Using Firestore's document-subcollection pattern for chats and messages

### Important Patterns
- **Optimistic UI Pattern:** Add message to local state immediately, then sync with server
- **Offline-First:** All data cached locally via Firestore persistence
- **Real-time Listeners:** Use Firestore snapshot listeners for live updates
- **Server Timestamps:** Always use `FieldValue.serverTimestamp()` for accurate time across devices

---

## 4. System Patterns

### Architecture Overview
**Pattern:** MVVM (Model-View-ViewModel) with SwiftUI  
**Backend:** Firebase Backend-as-a-Service (BaaS)

### System Components

```
┌─────────────────────────────────────────┐
│           SwiftUI Views                 │
│  (ConversationList, ChatView, etc.)     │
└───────────────┬─────────────────────────┘
                │
┌───────────────▼─────────────────────────┐
│        ViewModels (@Observable)         │
│  Handle UI state & business logic       │
└───────────────┬─────────────────────────┘
                │
┌───────────────▼─────────────────────────┐
│          Service Layer                  │
│  - FirebaseService (setup)              │
│  - MessageService (CRUD, listeners)     │
│  - AuthService (sign in/up)             │
│  - PresenceService (online/offline)     │
└───────────────┬─────────────────────────┘
                │
┌───────────────▼─────────────────────────┐
│         Firebase Platform               │
│  - Authentication                       │
│  - Firestore (main DB)                  │
│  - Realtime DB (presence)               │
│  - Cloud Messaging (FCM)                │
│  - Cloud Functions (push triggers)      │
└─────────────────────────────────────────┘
```

### Database Schema (Firestore NoSQL)

**users** (Collection)
```
{userID} (Document)
├── uid: String
├── displayName: String
├── email: String
└── profilePhotoURL: String? (optional)
```

**chats** (Collection)
```
{chatID} (Document)
├── members: [String] (array of userIDs)
├── lastMessage: String
├── lastMessageTimestamp: Timestamp
├── isGroupChat: Boolean
└── messages (Sub-collection)
    └── {messageID} (Document)
        ├── text: String
        ├── senderID: String
        ├── timestamp: Timestamp (server)
        └── readBy: [String] (array of userIDs)
```

### Key Technical Decisions

1. **Real-time Delivery:** Firestore `addSnapshotListener` on messages subcollection
2. **Persistence:** Firestore offline cache with `isPersistenceEnabled = true`
3. **Presence System:** Firebase Realtime Database with `onDisconnect` hook
4. **Timestamps:** `FieldValue.serverTimestamp()` for consistency
5. **Read Receipts:** `readBy` array field updated when user views message
6. **Push Notifications:** Cloud Functions triggered on new message writes

### Critical Implementation Paths

**Sending a Message:**
1. User taps Send
2. Message added to local SwiftUI @State (marked "sending")
3. Async write to Firestore messages subcollection
4. Server confirms write
5. Update local message status to "delivered"
6. Cloud Function triggers push notification to other members

**Receiving a Message:**
1. Firestore snapshot listener detects new document
2. Message pushed to all listening clients
3. SwiftUI View automatically updates via data binding
4. When user views message, update `readBy` array

**Offline Handling:**
1. App loses connectivity
2. Firestore cache serves all previously loaded data
3. User can send messages (queued locally)
4. On reconnection, Firestore syncs queued messages automatically

---

## 5. Tech Context

### Technology Stack

**Frontend:**
- **SwiftUI** (iOS 13+) - Modern declarative UI framework
- **Swift** - Primary programming language
- **Combine** - Reactive programming (if needed)

**Backend-as-a-Service (Firebase):**
- **Firebase Authentication** - User sign up/login/session management
- **Firestore** - Primary NoSQL database (chats, messages)
- **Firebase Realtime Database** - Presence/online status only
- **Firebase Cloud Messaging (FCM)** - Push notifications
- **Cloud Functions** - Serverless triggers for notifications
- **Apple Push Notification service (APNs)** - iOS notification delivery

### Development Setup

**Requirements:**
- macOS (latest)
- Xcode (latest stable)
- iOS Simulator or physical device (iOS 13+)
- Firebase account
- Apple Developer account (for APNs)

**Dependencies (Swift Package Manager):**
- Firebase iOS SDK
  - FirebaseAuth
  - FirebaseFirestore
  - FirebaseDatabase (for presence)
  - FirebaseMessaging

### Technical Constraints

**Platform:**
- iOS 13+ minimum target (for SwiftUI)
- iPhone and iPad support
- Portrait and landscape orientations

**Performance:**
- Real-time message latency: < 3 seconds
- Offline persistence: all previously loaded data
- Optimistic UI: instant local updates

**Security:**
- Firebase Authentication for user identity
- Firestore Security Rules to restrict data access
- HTTPS/SSL for all network traffic

### Tool Usage Patterns

**SwiftUI State Management:**
- `@State` for local view state
- `@Observable` for ViewModels (iOS 17+) or `@ObservableObject` + `@Published` (iOS 13-16)
- `@StateObject` for ViewModel lifecycle management
- `@EnvironmentObject` for app-wide services

**Firestore Patterns:**
- Use `addSnapshotListener` for real-time subscriptions
- Use `getDocument()` for one-time reads
- Use `setData()` for writes
- Use `FieldValue.serverTimestamp()` for timestamps
- Use `FieldValue.arrayUnion()` for readBy updates

---

## 6. Progress

### What Works
✅ Project requirements defined  
✅ PRD completed with full specifications  
✅ Database schema designed  
✅ Implementation plan established  
✅ Memory Bank structure created  

### What's Left to Build

**Phase 1: Core Foundation**
- [ ] Setup Firebase project (Auth, Firestore, FCM)
- [ ] Initialize iOS SwiftUI project in Xcode
- [ ] Add Firebase SDK dependencies
- [ ] Implement User Authentication (Sign up, Log in, Log out)
- [ ] Create basic SwiftUI app structure and navigation
- [ ] Build users collection and basic user profile model

**Phase 2: 1-on-1 Chat**
- [ ] Build Conversation List screen (displays chats)
- [ ] Build Chat View screen (displays messages)
- [ ] Implement real-time message sending/receiving using Firestore listeners
- [ ] Implement Optimistic UI and server timestamps
- [ ] Implement Firestore offline persistence

**Phase 3: Group Chats & Presence**
- [ ] Implement "Create New Chat" flow (selecting 1 or 3+ users)
- [ ] Ensure group chat logic works (sending to N members)
- [ ] Integrate Firebase Realtime Database for online/offline presence indicators

**Phase 4: Polish & Notifications**
- [ ] Implement message read receipts logic (client-side and Firestore updates)
- [ ] Configure APNs and Firebase Cloud Messaging
- [ ] Write and deploy Cloud Function to trigger push notifications
- [ ] Test notifications (foreground, background, terminated)
- [ ] Bug fixing and UI polish

### Current Status
**Stage:** Pre-development / Planning  
**Next Milestone:** Phase 1 - Core Foundation

### Known Issues
None yet - project has not started development.

### Evolution of Project Decisions

**SwiftUI vs UIKit Decision:**
- **Decision:** Use SwiftUI
- **Rationale:** Faster development, native data binding perfect for real-time chat, modern and future-proof, cross-platform potential
- **Trade-off:** iOS 13+ minimum (acceptable - >90% market adoption)

**Firebase vs Custom Backend:**
- **Decision:** Use Firebase BaaS
- **Rationale:** Bundles all needed features (Auth, real-time DB, push, offline sync), faster development, proven scalability
- **Trade-off:** Vendor lock-in (acceptable for MVP)

**Firestore + Realtime DB Hybrid:**
- **Decision:** Use Firestore for main data, Realtime DB only for presence
- **Rationale:** Firestore has better offline support and data modeling, but Realtime DB has superior `onDisconnect` for presence
- **Trade-off:** Slightly more complex but each service used for its strength

---

## Success Criteria Reference

### MVP Must-Haves (P0)
All 10 hard requirements must be met:
- ✅ User authentication working
- ✅ 1-on-1 conversations working
- ✅ Group (3+) conversations working
- ✅ Real-time delivery (< 3 sec latency)
- ✅ Local persistence (viewable offline)
- ✅ Optimistic UI (instant display)
- ✅ Online/offline status indicators
- ✅ Server-synced timestamps
- ✅ Read receipts visible
- ✅ Push notifications working

### Should Have (P1) - Post-MVP
- "Is typing..." indicator
- Edit display name and profile picture
- Search contacts to start chat

### Could Have (P2) - Future
- Image and media message sharing
- Emoji reactions to messages
- Search conversation history
