# PRD: Real-Time Messaging Service

**Feature**: Real-Time Messaging Service

**Version**: 1.0

**Status**: Ready for Development

**Agent**: Pam

**Target Release**: Phase 2 - 1-on-1 Chat

**Links**: [PR Brief #8](../pr-briefs.md#pr-8-real-time-messaging-service), [TODO](../todos/pr-8-todo.md), [Architecture](../architecture.md)

---

## 1. Summary

Implement MessageService to handle real-time message sending and receiving using Firestore snapshot listeners, enabling instant message delivery across all connected devices with sub-100ms latency, proper listener lifecycle management, and seamless integration with the ChatView UI built in PR #7.

---

## 2. Problem & Goals

**Problem**: Users need to send and receive messages in real-time across multiple devices. Without a robust MessageService with Firestore listeners, messages won't sync automatically, conversations won't feel live, and the core value proposition of instant messaging fails.

**Why now**: This is the critical enabler for Phase 2. PR #7 built the Chat View UI, and PR #5 defined the data models. This PR bridges the gap by connecting the UI to Firebase, enabling actual real-time communication.

**Goals**:
  - [ ] G1 — Messages sent from one device appear on all other devices within 100ms
  - [ ] G2 — MessageService provides deterministic service methods for sending and observing messages
  - [ ] G3 — Firestore snapshot listeners automatically update UI when new messages arrive
  - [ ] G4 — Listener lifecycle properly managed to prevent memory leaks when users navigate away

---

## 3. Non-Goals / Out of Scope

- [ ] Optimistic UI updates (PR #9 - will add immediate visual feedback)
- [ ] Offline message queueing (PR #11 - will handle offline scenarios)
- [ ] Server timestamps display in UI (PR #10 - will show formatted timestamps)
- [ ] Read receipts (PR #17 - will track who read messages)
- [ ] Typing indicators (PR #16 - will show "is typing...")
- [ ] Message editing or deletion (future)
- [ ] Media messages (images, videos) (future)
- [ ] Message reactions (future)
- [ ] Group chat-specific logic beyond basic multi-member support (PR #14)
- [ ] Automated unit/UI tests (deferred to backlog per testing-strategy.md)

---

## 4. Success Metrics

Reference `Psst/agents/shared-standards.md` for metric templates:

**User-visible**:
- Message delivery: User A sends message → User B sees it within 100ms
- Flow completion: 100% of sent messages appear in all devices
- No dropped messages during testing session

**System** (see shared-standards.md):
- **Message delivery latency**: < 100ms (send to receive across devices)
- **Listener registration**: < 50ms to establish Firestore listener
- **No UI blocking**: Message operations run on background threads
- **Memory leak prevention**: Listeners properly detached on view dismissal

**Quality**:
- 0 blocking bugs during manual testing
- All acceptance gates pass
- Crash-free rate >99%
- No console errors during message operations

---

## 5. Users & Stories

- As a **user**, I want to **send a message in a chat** so that **the other person receives it immediately**.

- As a **user**, I want to **see new messages appear automatically** so that **I don't have to refresh or leave the conversation screen**.

- As a **user in a group chat**, I want to **send a message that all group members receive instantly** so that **everyone stays synchronized**.

- As a **developer**, I want **deterministic service methods** so that **I can easily test and reason about message operations**.

- As a **developer**, I want **proper listener cleanup** so that **memory leaks don't occur when users navigate between screens**.

---

## 6. Experience Specification (UX)

**Entry Points**:
- User opens ChatView (PR #7) → MessageService automatically starts listening for new messages
- User types message and taps send → MessageService sends message to Firestore

**Visual Behavior**:
- User taps send button in ChatView
- Message appears in UI (this PR handles actual Firestore write)
- Message syncs to Firestore within 50ms
- All other devices listening to same chat receive update within 100ms
- New message automatically appears in their ChatView UI

**Loading/Error States**:
- **Loading**: N/A for this PR (listener runs in background)
- **Error - Network Failure**: Message send fails (error logged, UI not affected in this PR)
- **Error - Invalid Data**: Validation prevents send (handled by service layer)

**Performance Targets** (see shared-standards.md):
- Message send to Firestore: < 50ms
- Message delivery across devices: < 100ms
- Listener registration: < 50ms
- No UI thread blocking: All Firebase operations async

---

## 7. Functional Requirements (Must/Should)

**MUST**:

- MUST implement `sendMessage(chatID:text:)` service method
  - [Gate] Method accepts chatID and text, returns messageID
  - [Gate] Creates message document in `chats/{chatID}/messages` collection
  - [Gate] Uses FieldValue.serverTimestamp() for accurate timestamps
  - [Gate] Updates chat's lastMessage and lastMessageTimestamp fields
  - [Gate] Validates text is not empty (trimmed)
  - [Gate] Handles async errors (network, Firebase, permissions)

- MUST implement `observeMessages(chatID:completion:)` service method
  - [Gate] Establishes Firestore snapshot listener on `messages` sub-collection
  - [Gate] Orders messages by timestamp ascending (oldest first)
  - [Gate] Calls completion handler with [Message] array on updates
  - [Gate] Returns ListenerRegistration for lifecycle management
  - [Gate] Listener triggers immediately with existing messages on attach

- MUST properly manage listener lifecycle
  - [Gate] ChatView calls observeMessages on .onAppear
  - [Gate] ChatView stores ListenerRegistration reference
  - [Gate] ChatView calls .remove() on .onDisappear
  - [Gate] No memory leaks confirmed with Instruments

- MUST ensure real-time delivery < 100ms
  - [Gate] Device A sends message → Device B receives within 100ms
  - [Gate] 3+ devices all receive within 100ms
  - [Gate] Group chats (3+ members) sync within 100ms

- MUST handle concurrent messages gracefully
  - [Gate] Multiple users send simultaneously → all messages appear correctly
  - [Gate] No race conditions in message ordering
  - [Gate] Server timestamps ensure correct chronological order

**SHOULD**:

- SHOULD validate message text (length, content)
  - [Gate] Empty/whitespace-only messages rejected
  - [Gate] Messages > 10,000 characters rejected (Firestore limit consideration)

- SHOULD update chat document metadata atomically
  - [Gate] lastMessage and lastMessageTimestamp updated in same write

- SHOULD log errors for debugging
  - [Gate] Network errors logged with context
  - [Gate] Validation errors logged with details

**Acceptance Gates Summary**:
- [Gate] User A sends message → appears in their ChatView immediately (via listener)
- [Gate] User B (on different device) sees message within 100ms
- [Gate] User C (3rd device, group chat) sees message within 100ms
- [Gate] Offline case: Send fails gracefully (handled fully in PR #11)
- [Gate] Error case: Invalid text shows no partial writes to Firestore
- [Gate] Memory: Navigate away from ChatView → listener removed, no leaks

---

## 8. Data Model

Reference models from PR #5. This PR implements the service layer to write/read these models.

### Firestore Collections

**Collection**: `chats/{chatID}/messages`

**Message Document** (defined in PR #5):
```swift
{
  id: String,                    // UUID
  text: String,                  // 1-10,000 chars
  senderID: String,              // User ID who sent message
  timestamp: Timestamp,          // FieldValue.serverTimestamp()
  readBy: [String]               // Initially empty, updated in PR #17
}
```

**Chat Document Updates** (lastMessage tracking):
```swift
{
  // Existing fields from PR #5
  lastMessage: String,           // Updated to latest message text
  lastMessageTimestamp: Timestamp // Updated to latest message timestamp
}
```

### Validation Rules

**Message Text**:
- Must not be empty after trimming whitespace
- Maximum length: 10,000 characters (Firestore best practice)
- No special validation (emojis, URLs allowed)

**Chat ID**:
- Must be non-empty string
- Must reference existing chat document

**Sender ID**:
- Must be current authenticated user's UID
- Derived from FirebaseAuth.auth().currentUser?.uid

### Indexing/Queries

**Firestore Query**:
```swift
// Query messages ordered by timestamp
db.collection("chats/\(chatID)/messages")
  .order(by: "timestamp", descending: false)
  .addSnapshotListener { snapshot, error in ... }
```

**Index Required**: Firestore automatically indexes `timestamp` field for ordering.

---

## 9. API / Service Contracts

Reference examples in `Psst/agents/shared-standards.md`.

### MessageService.swift

**File Location**: `Services/MessageService.swift` (per architecture.md)

```swift
import Foundation
import FirebaseFirestore
import FirebaseAuth

class MessageService {
    
    private let db = Firestore.firestore()
    
    // MARK: - Send Message
    
    /// Sends a message to a chat
    /// - Parameters:
    ///   - chatID: The ID of the chat to send message to
    ///   - text: The message text (will be trimmed)
    /// - Returns: The ID of the created message
    /// - Throws: MessageError if validation fails or Firestore write fails
    func sendMessage(chatID: String, text: String) async throws -> String {
        // Pre-conditions:
        // - User must be authenticated
        // - chatID must be non-empty
        // - text must not be empty after trimming
        // - text must be <= 10,000 characters
        
        // Post-conditions:
        // - Message document created in chats/{chatID}/messages
        // - Chat document updated with lastMessage and lastMessageTimestamp
        // - Returns messageID
    }
    
    // MARK: - Observe Messages
    
    /// Observes messages in a chat with real-time updates
    /// - Parameters:
    ///   - chatID: The ID of the chat to observe
    ///   - completion: Called with array of messages on each update
    /// - Returns: ListenerRegistration to remove listener later
    func observeMessages(chatID: String, completion: @escaping ([Message]) -> Void) -> ListenerRegistration {
        // Pre-conditions:
        // - chatID must be non-empty
        
        // Post-conditions:
        // - Snapshot listener attached to messages sub-collection
        // - Completion called immediately with existing messages
        // - Completion called on each new message
        // - Returns ListenerRegistration for cleanup
    }
    
    // MARK: - Helper Methods
    
    /// Validates message text
    /// - Parameter text: The text to validate
    /// - Throws: MessageError.emptyText or .textTooLong
    private func validateMessageText(_ text: String) throws {
        // Validation logic
    }
    
    /// Gets current authenticated user ID
    /// - Returns: User ID
    /// - Throws: MessageError.notAuthenticated if no user logged in
    private func getCurrentUserID() throws -> String {
        // Auth logic
    }
    
    /// Updates chat document with last message metadata
    /// - Parameters:
    ///   - chatID: The chat to update
    ///   - text: The message text
    private func updateChatLastMessage(chatID: String, text: String) async throws {
        // Firestore update logic
    }
}

// MARK: - Errors

enum MessageError: LocalizedError {
    case notAuthenticated
    case emptyText
    case textTooLong
    case invalidChatID
    case firestoreError(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "User must be logged in to send messages"
        case .emptyText: return "Message text cannot be empty"
        case .textTooLong: return "Message text is too long (max 10,000 characters)"
        case .invalidChatID: return "Invalid chat ID"
        case .firestoreError(let error): return "Firestore error: \(error.localizedDescription)"
        }
    }
}
```

### Integration with ChatView

**ChatView.swift Updates**:
```swift
import SwiftUI

struct ChatView: View {
    let chat: Chat
    
    @State private var messages: [Message] = []
    @State private var inputText: String = ""
    
    private let messageService = MessageService()
    private var messageListener: ListenerRegistration?
    
    var body: some View {
        VStack {
            // Message list (from PR #7)
            ScrollView {
                LazyVStack {
                    ForEach(messages) { message in
                        MessageRow(message: message)
                    }
                }
            }
            
            // Input bar (from PR #7)
            MessageInputView(text: $inputText, onSend: sendMessage)
        }
        .onAppear {
            startListeningForMessages()
        }
        .onDisappear {
            stopListeningForMessages()
        }
    }
    
    private func startListeningForMessages() {
        messageListener = messageService.observeMessages(chatID: chat.id) { updatedMessages in
            self.messages = updatedMessages
        }
    }
    
    private func stopListeningForMessages() {
        messageListener?.remove()
    }
    
    private func sendMessage() {
        Task {
            do {
                _ = try await messageService.sendMessage(chatID: chat.id, text: inputText)
                inputText = "" // Clear input on success
            } catch {
                print("Error sending message: \(error.localizedDescription)")
                // TODO: Show error alert in PR #24
            }
        }
    }
}
```

---

## 10. UI Components to Create/Modify

**Create**:
- `Services/MessageService.swift` — Real-time messaging service (NEW)

**Modify**:
- `Views/Conversation/ChatView.swift` — Integrate MessageService, replace placeholder data with real Firestore listeners
- `Views/Conversation/MessageInputView.swift` — Wire send button to MessageService.sendMessage()

**No changes to**:
- `Models/Message.swift` (already defined in PR #5)
- `Models/Chat.swift` (already defined in PR #5)
- `Views/Conversation/MessageRow.swift` (UI component unchanged)

---

## 11. Integration Points

**Firebase Services**:
- **Firestore Database**: Write messages to `chats/{chatID}/messages` collection
- **Firestore Snapshot Listeners**: Real-time updates for new messages
- **Firebase Auth**: Get current user ID for senderID field
- **FieldValue.serverTimestamp()**: Synchronized timestamps across devices

**Firebase Configuration Requirements**:

Before implementing this PR, **Firestore Security Rules** must be configured in Firebase Console.

**Navigate to: Firebase Console → Firestore Database → Rules**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // User must be authenticated for all operations
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
    
    // Messages in chats - users can only read/write if they're members
    match /chats/{chatID}/messages/{messageID} {
      allow read: if request.auth != null && 
                     request.auth.uid in get(/databases/$(database)/documents/chats/$(chatID)).data.members;
      allow create: if request.auth != null && 
                       request.auth.uid in get(/databases/$(database)/documents/chats/$(chatID)).data.members &&
                       request.resource.data.senderID == request.auth.uid;
    }
    
    // Chats - users can read if they're members
    match /chats/{chatID} {
      allow read: if request.auth != null && 
                     request.auth.uid in resource.data.members;
      allow update: if request.auth != null && 
                       request.auth.uid in resource.data.members;
      allow create: if request.auth != null && 
                      request.auth.uid in request.resource.data.members;
    }
    
    // Users collection
    match /users/{userID} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userID;
    }
  }
}
```

**Security Rules Explanation**:
- **Authentication required**: All operations require `request.auth != null`
- **Member-only access**: Users can only read/write messages in chats where they're in the `members` array
- **Sender validation**: Message `senderID` must match authenticated user's UID
- **User privacy**: Users can only write their own user documents

**Firestore Indexes**:
- Single-field index on `timestamp` (created automatically)
- If "index required" error occurs, Firestore Console will provide direct link to create

**SwiftUI Integration**:
- **ChatView**: Creates MessageService instance, manages listener lifecycle
- **@State messages array**: Updated by listener completion handler
- **Task/async-await**: For async message sending operations
- **.onAppear/.onDisappear**: Lifecycle hooks for listener management

**Architecture Pattern** (per architecture.md):
- Service layer handles all Firebase logic
- Views remain thin wrappers
- State management via SwiftUI @State
- MVVM pattern: ChatView → MessageService → Firestore

**Thread Safety**:
- All Firestore operations already run on background threads
- Completion handlers automatically dispatched to main thread
- No manual DispatchQueue calls needed

---

## 12. Manual Validation Plan

**Current**: Manual testing validation (see `Psst/agents/shared-standards.md`)

### Testing Setup (Pre-Implementation)

**Create Test Chat Document in Firestore Console:**

Since PR #12 (Start New Chat Flow) hasn't been built yet, manually create a test chat for multi-device testing.

**Test Users:**
- **vanes**: `OUv2v5intnP7kHXv7rh550GQn6o1`
- **jameson**: `wOh11I865XTWQVTmd1RfWsB9sBD3`

**Firestore Console → chats collection → Add Document:**
```javascript
// Document ID: test_chat_vanes_jameson
{
  id: "test_chat_vanes_jameson",
  members: ["OUv2v5intnP7kHXv7rh550GQn6o1", "wOh11I865XTWQVTmd1RfWsB9sBD3"],
  lastMessage: "",
  lastMessageTimestamp: <current_timestamp>,
  isGroupChat: false,
  createdAt: <current_timestamp>,
  updatedAt: <current_timestamp>
}
```

**Add Temporary Test Navigation:**
In `ConversationListView.swift`, add a test button:
```swift
Button("🧪 Test Chat (Vanes ↔️ Jameson)") {
    let testChat = Chat(
        id: "test_chat_vanes_jameson",
        members: ["OUv2v5intnP7kHXv7rh550GQn6o1", "wOh11I865XTWQVTmd1RfWsB9sBD3"],
        lastMessage: "",
        lastMessageTimestamp: Date(),
        isGroupChat: false
    )
    // Navigate to ChatView(chat: testChat)
}
```

### Configuration Testing
- [ ] Firebase Firestore connection established
- [ ] Firebase Authentication provides valid user ID
- [ ] Firestore security rules allow read/write to messages collection
- [ ] All necessary Firebase imports working
- [ ] Test chat document created in Firestore Console (test_chat_vanes_jameson)
- [ ] Test button added to ConversationListView for manual testing

### Happy Path Testing
- [ ] **Device A**: User logs in, opens ChatView
- [ ] Gate: Messages listener attaches, completion handler called with empty array (new chat)
- [ ] **Device A**: User types "Hello" and taps send
- [ ] Gate: sendMessage() succeeds, returns messageID
- [ ] Gate: Message appears in Device A's UI within 100ms
- [ ] **Device B**: Different user opens same ChatView
- [ ] Gate: Message "Hello" appears in Device B's UI within 100ms
- [ ] **Device B**: User types "Hi there" and taps send
- [ ] Gate: Message appears in Device B's UI immediately
- [ ] Gate: Message appears in Device A's UI within 100ms
- [ ] **Both devices**: Messages displayed in correct chronological order

### Edge Cases Testing
- [ ] **Empty message**: User taps send with empty input
- [ ] Gate: sendMessage() throws MessageError.emptyText
- [ ] Gate: No message written to Firestore
- [ ] **Whitespace-only**: User types "   " and taps send
- [ ] Gate: Text trimmed to empty, sendMessage() throws error
- [ ] **Very long message**: User types 11,000 character message
- [ ] Gate: sendMessage() throws MessageError.textTooLong
- [ ] **Rapid sends**: User taps send 10 times quickly
- [ ] Gate: All 10 messages written successfully
- [ ] Gate: All messages appear in correct order on all devices
- [ ] **Navigate away**: User opens ChatView, then goes back
- [ ] Gate: Listener removed on .onDisappear
- [ ] Gate: Instruments confirms no memory leak

### Multi-User Testing (3+ devices)
- [ ] **Setup**: 3 devices, all logged in as different users, viewing same group chat
- [ ] **Device A**: Sends "Message 1"
- [ ] Gate: Message appears on Device B within 100ms
- [ ] Gate: Message appears on Device C within 100ms
- [ ] **Device B**: Sends "Message 2" immediately
- [ ] Gate: Appears on A and C within 100ms
- [ ] **Device C**: Sends "Message 3" immediately
- [ ] Gate: Appears on A and B within 100ms
- [ ] **All devices**: All messages in same chronological order

### Offline Behavior Testing (Basic)
- [ ] **Device A**: Disable network
- [ ] **Device A**: Attempt to send message
- [ ] Gate: sendMessage() throws Firestore network error
- [ ] Gate: No partial writes to Firestore
- [ ] Note: Full offline queueing deferred to PR #11

### Performance Testing (see shared-standards.md)
- [ ] **Message send latency**: Measure time from sendMessage() call to Firestore write completion
- [ ] Gate: < 50ms for send operation
- [ ] **Message delivery latency**: Measure time from Device A send to Device B listener callback
- [ ] Gate: < 100ms end-to-end delivery
- [ ] **Listener registration**: Measure time to attach listener on ChatView .onAppear
- [ ] Gate: < 50ms to establish listener
- [ ] **UI responsiveness**: Send message while scrolling message list
- [ ] Gate: No UI freezing or lag during send operation

### Visual State Verification
- [ ] No console errors during message send
- [ ] No console errors during listener attachment
- [ ] Messages appear in ChatView UI automatically (no manual refresh)
- [ ] Correct sender styling (sent vs received messages)
- [ ] Input field clears after successful send

---

## 13. Definition of Done

See standards in `Psst/agents/shared-standards.md`:

- [ ] MessageService.swift implemented with sendMessage() and observeMessages()
- [ ] Message validation logic (empty text, text length) implemented
- [ ] Firestore writes use FieldValue.serverTimestamp()
- [ ] Chat document lastMessage fields updated on send
- [ ] Snapshot listener properly orders messages by timestamp
- [ ] ChatView.swift updated to use MessageService instead of placeholder data
- [ ] Listener lifecycle management (.onAppear/.onDisappear) implemented
- [ ] Error handling for all failure cases (auth, network, validation)
- [ ] Real-time sync verified across 2+ devices within 100ms
- [ ] All acceptance gates pass
- [ ] Manual testing completed (configuration, user flows, multi-device, performance)
- [ ] No console warnings or errors
- [ ] Code follows `Psst/agents/shared-standards.md` patterns
- [ ] Memory leaks checked with Instruments
- [ ] PR created targeting develop branch

---

## 14. Risks & Mitigations

**Risk: Firestore listener causes memory leaks**
- **Mitigation**: Store ListenerRegistration reference, call .remove() on .onDisappear. Verify with Instruments Leaks tool.

**Risk: Messages arrive out of order**
- **Mitigation**: Use server timestamps and order by timestamp in Firestore query. Server timestamp ensures consistent ordering across time zones.

**Risk: Network latency exceeds 100ms target**
- **Mitigation**: Use FieldValue.serverTimestamp() (no client delay). Test on actual devices (not just Simulator). Firestore typically < 50ms.

**Risk: Concurrent sends cause race conditions**
- **Mitigation**: Firestore handles concurrent writes atomically. Each message gets unique timestamp. Snapshot listener delivers in correct order.

**Risk: Listener continues firing after user leaves chat**
- **Mitigation**: Use .onDisappear lifecycle hook to detach listener. Store listener reference at view scope, not service scope.

**Risk: Send fails silently (user doesn't know message didn't send)**
- **Mitigation**: For this PR, log errors. PR #9 (Optimistic UI) will add visual feedback. PR #24 will add error alerts.

**Risk: Very large chat history (1000+ messages) slows down listener**
- **Mitigation**: For MVP, acceptable. Future optimization: Paginate with .limit() and load more on scroll.

---

## 15. Rollout & Telemetry

**Feature Flag**: No

**Metrics (Manual Observation)**:
- Count successful sends vs failures during testing
- Measure message latency with timer logs
- Verify no crashes during 30-minute test session
- Check memory usage with Instruments

**Manual Validation Steps**:
1. Open ChatView on Device 1
2. Send message from Device 1
3. Verify message appears on Device 2 within 100ms
4. Send 10 messages rapidly
5. Verify all appear in correct order on both devices
6. Navigate away from ChatView
7. Verify listener removed (check Instruments)

**Logging Strategy**:
```swift
// Add debug logs for monitoring
print("📤 Sending message to chat: \(chatID)")
print("✅ Message sent successfully: \(messageID)")
print("❌ Send failed: \(error.localizedDescription)")
print("👂 Listening for messages in chat: \(chatID)")
print("📨 Received \(messages.count) messages")
```

---

## 16. Open Questions

**Q1**: Should we limit the number of messages loaded initially?
- **Answer**: No limit for MVP. Load all messages. Future optimization (pagination) deferred to backlog.

**Q2**: How do we handle deleted users sending messages?
- **Answer**: Out of scope for this PR. Deferred to PR #24 (error handling).

**Q3**: Should we add retry logic for failed sends?
- **Answer**: No automatic retry in this PR. PR #11 (offline persistence) will handle queuing. PR #24 will add manual retry option.

**Q4**: What happens if listener fails to attach?
- **Answer**: Log error to console. User sees empty state. PR #24 will add error UI.

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future PRs:

- [ ] Optimistic UI updates (PR #9)
- [ ] Offline message queueing (PR #11)
- [ ] Server timestamp formatting in UI (PR #10)
- [ ] Read receipts (PR #17)
- [ ] Typing indicators (PR #16)
- [ ] Message pagination (load more on scroll) (future)
- [ ] Message editing (future)
- [ ] Message deletion (future)
- [ ] Media messages (future)
- [ ] Message search (future)
- [ ] Automated unit tests (deferred to backlog)
- [ ] Integration tests (deferred to backlog)
- [ ] Error alerts in UI (PR #24)
- [ ] Retry mechanism for failed sends (PR #24)

---

## Preflight Questionnaire

1. **Smallest end-to-end user outcome for this PR?**
   - User can send a message and see it appear on another device in real-time (< 100ms).

2. **Primary user and critical action?**
   - Primary user: Any authenticated user in a chat
   - Critical action: Send message and receive real-time updates

3. **Must-have vs nice-to-have?**
   - Must-have: sendMessage(), observeMessages(), listener lifecycle, < 100ms delivery
   - Nice-to-have: Pagination, retry logic, error UI (deferred)

4. **Real-time requirements?** (see shared-standards.md)
   - Message delivery < 100ms across devices
   - Snapshot listener provides real-time updates
   - Works with 3+ devices simultaneously
   - Server timestamps ensure sync

5. **Performance constraints?** (see shared-standards.md)
   - Message send: < 50ms to Firestore
   - Message delivery: < 100ms end-to-end
   - Listener registration: < 50ms
   - No UI blocking (async operations)

6. **Error/edge cases to handle?**
   - Empty message text
   - User not authenticated
   - Network failure (log error, full handling in PR #11)
   - Invalid chat ID
   - Text too long (> 10,000 chars)
   - Concurrent sends (handled by Firestore)

7. **Data model changes?**
   - No changes to Message or Chat models (defined in PR #5)
   - Uses existing Firestore schema

8. **Service APIs required?**
   - `sendMessage(chatID:text:) async throws -> String`
   - `observeMessages(chatID:completion:) -> ListenerRegistration`

9. **UI entry points and states?**
   - Entry: ChatView.onAppear starts listener
   - Exit: ChatView.onDisappear removes listener
   - States: Listening, Sending, Error (logged)

10. **Security/permissions implications?**
    - Firestore security rules must allow authenticated users to read/write messages
    - Users can only send with their own UID as senderID
    - Rules validation deferred to PR #8 completion

11. **Dependencies or blocking integrations?**
    - Depends on: PR #5 (data models), PR #7 (ChatView UI)
    - Blocks: PR #9 (optimistic UI), PR #10 (timestamps), PR #11 (offline)

12. **Rollout strategy and metrics?**
    - Manual testing with 2+ devices
    - Measure latency with timer logs
    - Verify with Firestore Console

13. **What is explicitly out of scope?**
    - Optimistic UI, offline queueing, read receipts, typing indicators, message editing, pagination, automated tests

---

## Authoring Notes

- This PR is CRITICAL for real-time messaging functionality
- Follow architecture.md: Services handle Firebase logic, Views stay thin
- Use async/await for clean async code (no nested callbacks)
- Server timestamps prevent time zone issues
- Proper listener cleanup prevents memory leaks
- Test on actual devices (not just Simulator) for accurate latency measurement
- Per Swift threading rules: Firebase callbacks already on main thread
- Reference shared-standards.md for performance targets throughout

