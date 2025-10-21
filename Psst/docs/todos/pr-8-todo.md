# PR-8 TODO — Real-Time Messaging Service

**Branch**: `feat/pr-8-real-time-messaging-service`  
**Source PRD**: `Psst/docs/prds/pr-8-prd.md`  
**Owner (Agent)**: Caleb (Coder Agent)

---

## 0. Clarifying Questions & Assumptions

**Questions:**
- None outstanding — PRD is complete with all service specifications

**Assumptions (confirm during implementation):**
- Firebase SDK and Firestore already configured from PR #1
- Chat and Message models already implemented in PR #5
- ChatView UI already built in PR #7
- Testing via manual Firestore Console setup (automated tests deferred to backlog per PRD Section 17)
- Test users already exist in Firebase Auth:
  - **vanes**: `OUv2v5intnP7kHXv7rh550GQn6o1`
  - **jameson**: `wOh11I865XTWQVTmd1RfWsB9sBD3`
- Temporary test button will be added for testing, then removed before PR merge

---

## 1. Setup

- [ ] Create branch `feat/pr-8-real-time-messaging-service` from develop
  - Test Gate: Branch created and checked out successfully

- [ ] Read PRD thoroughly (`Psst/docs/prds/pr-8-prd.md`)
  - Test Gate: Understand all service requirements, acceptance gates, and performance targets

- [ ] Read `Psst/agents/shared-standards.md` for patterns
  - Test Gate: Understand async/await patterns, error handling, and performance requirements

- [ ] Verify Firebase Firestore is configured and accessible
  - Test Gate: Can import `FirebaseFirestore` and access `Firestore.firestore()`

- [ ] Verify Firebase Authentication is working
  - Test Gate: Can access `Auth.auth().currentUser`

- [ ] Review Message and Chat models from PR #5
  - Test Gate: Understand model structure, toDictionary() methods, and Codable implementation

- [ ] Review ChatView implementation from PR #7
  - Test Gate: Understand current UI structure, state management, and navigation

- [ ] Confirm app builds successfully
  - Test Gate: Existing code compiles without errors

---

## 2. Firebase Configuration

### 2.1 Configure Firestore Security Rules

- [ ] Open Firebase Console → Firestore Database → Rules
  - Test Gate: Security Rules editor accessible

- [ ] Add security rules from PRD Section 11
  - Copy rules for authenticated access
  - Copy rules for chat member validation
  - Copy rules for message sender validation
  - Test Gate: Rules published successfully without syntax errors

- [ ] Test rules with Firestore Rules Playground (optional)
  - Test read access for chat member
  - Test write access with correct senderID
  - Test Gate: Rules behave as expected

**Security Rules to Add:**
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

---

## 3. Testing Preparation

### 3.1 Create Test Chat in Firestore Console

- [ ] Open Firebase Console → Firestore Database
  - Test Gate: Firestore console accessible

- [ ] Navigate to `chats` collection (create if doesn't exist)
  - Test Gate: Collection visible in console

- [ ] Create new document with ID: `test_chat_vanes_jameson`
  - Test Gate: Document created successfully

- [ ] Add fields to test chat document:
  - `id` (string): `"test_chat_vanes_jameson"`
  - `members` (array): `["OUv2v5intnP7kHXv7rh550GQn6o1", "wOh11I865XTWQVTmd1RfWsB9sBD3"]`
  - `lastMessage` (string): `""`
  - `lastMessageTimestamp` (timestamp): Current timestamp
  - `isGroupChat` (boolean): `false`
  - `createdAt` (timestamp): Current timestamp
  - `updatedAt` (timestamp): Current timestamp
  - Test Gate: All fields added with correct types

- [ ] Verify test chat document structure matches Chat model from PR #5
  - Test Gate: Structure matches exactly

### 3.2 Add Temporary Test Button to ConversationListView

- [ ] Open `Views/ConversationList/ConversationListView.swift`
  - Test Gate: File opens successfully

- [ ] Add temporary test button to navigate to test chat
  - Add Button with label: "🧪 Test Chat (Vanes ↔️ Jameson)"
  - Create Chat object with test_chat_vanes_jameson data
  - Navigate to ChatView with test chat
  - Test Gate: Button renders in ConversationListView

- [ ] Test navigation to ChatView with test chat
  - Tap test button
  - Verify ChatView opens with correct chat
  - Test Gate: Navigation works, ChatView displays

- [ ] Add comment marking this as temporary for testing
  - Comment: `// TEMPORARY: Test button for PR #8 - Remove before merge`
  - Test Gate: Comment added for future removal reminder

---

## 4. Service Layer — MessageService

### 4.1 Create MessageService File

- [ ] Create `Psst/Psst/Services/MessageService.swift`
  - Test Gate: File created in correct location

- [ ] Add file header comments
  - Created by Caleb (Coder Agent) - PR #8
  - Purpose: Real-time messaging service for sending and receiving messages
  - Test Gate: Header comments added

- [ ] Add imports
  - `import Foundation`
  - `import FirebaseFirestore`
  - `import FirebaseAuth`
  - Test Gate: All imports resolve without errors

### 4.2 Implement MessageService Class Structure

- [ ] Define MessageService class
  - `class MessageService`
  - Add property: `private let db = Firestore.firestore()`
  - Test Gate: Class compiles

- [ ] Add MARK comments for organization
  - `// MARK: - Send Message`
  - `// MARK: - Observe Messages`
  - `// MARK: - Helper Methods`
  - Test Gate: Structure organized clearly

### 4.3 Implement MessageError Enum

- [ ] Create MessageError enum conforming to LocalizedError
  - Case: `notAuthenticated`
  - Case: `emptyText`
  - Case: `textTooLong`
  - Case: `invalidChatID`
  - Case: `firestoreError(Error)`
  - Test Gate: Enum compiles

- [ ] Implement errorDescription for each case
  - Provide user-friendly error messages
  - Test Gate: All cases have clear descriptions

### 4.4 Implement Helper Methods

- [ ] Implement `getCurrentUserID() throws -> String`
  - Get current user from `Auth.auth().currentUser`
  - Throw `MessageError.notAuthenticated` if nil
  - Return user UID
  - Test Gate: Method compiles and handles nil case

- [ ] Implement `validateMessageText(_ text: String) throws`
  - Trim whitespace from text
  - Check if empty after trimming → throw `MessageError.emptyText`
  - Check if length > 10,000 → throw `MessageError.textTooLong`
  - Test Gate: Validation logic correct

- [ ] Implement `updateChatLastMessage(chatID: String, text: String) async throws`
  - Reference chat document: `db.collection("chats").document(chatID)`
  - Update fields: `lastMessage` and `lastMessageTimestamp`
  - Use `FieldValue.serverTimestamp()` for timestamp
  - Handle Firestore errors
  - Test Gate: Method compiles and uses correct Firestore API

### 4.5 Implement sendMessage Method

- [ ] Define method signature
  - `func sendMessage(chatID: String, text: String) async throws -> String`
  - Add documentation comments
  - Test Gate: Signature matches PRD Section 9

- [ ] Implement validation logic
  - Trim text
  - Call `validateMessageText(text)`
  - Validate chatID is not empty
  - Test Gate: Validation executes correctly

- [ ] Get current user ID
  - Call `getCurrentUserID()`
  - Store in variable: `let senderID = try getCurrentUserID()`
  - Test Gate: User ID retrieved successfully

- [ ] Create message ID
  - Use `UUID().uuidString`
  - Test Gate: Unique ID generated

- [ ] Create Message object
  - Use Message model from PR #5
  - Set id, text, senderID, timestamp (Date()), readBy ([])
  - Test Gate: Message object created correctly

- [ ] Write message to Firestore
  - Reference: `db.collection("chats").document(chatID).collection("messages").document(messageID)`
  - Call `setData(message.toDictionary())`
  - Use async/await: `try await setData(...)`
  - Wrap Firestore errors in `MessageError.firestoreError`
  - Test Gate: Message written to Firestore successfully

- [ ] Update chat document with lastMessage
  - Call `try await updateChatLastMessage(chatID: chatID, text: text)`
  - Test Gate: Chat document updated

- [ ] Return message ID
  - Test Gate: Method returns correct string

- [ ] Add debug logging
  - Print: "📤 Sending message to chat: \(chatID)"
  - Print: "✅ Message sent successfully: \(messageID)"
  - Test Gate: Logs appear in console during execution

### 4.6 Implement observeMessages Method

- [ ] Define method signature
  - `func observeMessages(chatID: String, completion: @escaping ([Message]) -> Void) -> ListenerRegistration`
  - Add documentation comments
  - Test Gate: Signature matches PRD Section 9

- [ ] Create Firestore query
  - Reference: `db.collection("chats").document(chatID).collection("messages")`
  - Order by: `.order(by: "timestamp", descending: false)`
  - Test Gate: Query constructed correctly

- [ ] Attach snapshot listener
  - Call `.addSnapshotListener { snapshot, error in ... }`
  - Test Gate: Listener API called correctly

- [ ] Handle listener errors
  - Check if error exists
  - Print error: "❌ Listener error: \(error.localizedDescription)"
  - Return early if error
  - Test Gate: Error handling in place

- [ ] Parse snapshot documents to Message array
  - Guard unwrap snapshot documents
  - Use `compactMap` to decode: `snapshot.documents.compactMap { try? $0.data(as: Message.self) }`
  - Test Gate: Messages decoded correctly

- [ ] Call completion handler with messages
  - Ensure on main thread (Firestore already dispatches to main)
  - Call: `completion(messages)`
  - Test Gate: Completion handler called with array

- [ ] Add debug logging
  - Print: "👂 Listening for messages in chat: \(chatID)"
  - Print: "📨 Received \(messages.count) messages"
  - Test Gate: Logs appear in console

- [ ] Return ListenerRegistration
  - Return listener object for lifecycle management
  - Test Gate: ListenerRegistration returned

---

## 5. UI Integration — ChatView

### 5.1 Update ChatView State Management

- [ ] Open `Views/Conversation/ChatView.swift`
  - Test Gate: File opens successfully

- [ ] Add MessageService instance
  - Property: `private let messageService = MessageService()`
  - Test Gate: Property compiles

- [ ] Add listener property for lifecycle management
  - Property: `private var messageListener: ListenerRegistration?`
  - Test Gate: Property compiles

- [ ] Replace placeholder messages with real @State array
  - Change from mock data to: `@State private var messages: [Message] = []`
  - Test Gate: State property updated

### 5.2 Implement Listener Lifecycle Methods

- [ ] Create `startListeningForMessages()` method
  - Private function
  - Call `messageService.observeMessages(chatID: chat.id)`
  - Pass completion handler that updates `self.messages`
  - Store returned listener in `messageListener` property
  - Test Gate: Method compiles and assigns listener

- [ ] Create `stopListeningForMessages()` method
  - Private function
  - Call `messageListener?.remove()`
  - Test Gate: Method compiles

- [ ] Add `.onAppear` modifier to view
  - Call `startListeningForMessages()`
  - Test Gate: Listener starts when view appears

- [ ] Add `.onDisappear` modifier to view
  - Call `stopListeningForMessages()`
  - Test Gate: Listener stops when view disappears

### 5.3 Update Send Message Functionality

- [ ] Locate existing `sendMessage()` function in ChatView
  - Test Gate: Function found

- [ ] Replace placeholder implementation with real MessageService call
  - Wrap in `Task { ... }`
  - Use async/await: `try await messageService.sendMessage(chatID: chat.id, text: inputText)`
  - Clear input field on success: `inputText = ""`
  - Test Gate: Service call implemented

- [ ] Add error handling
  - Wrap in `do-catch` block
  - Catch errors and print: "❌ Error sending message: \(error.localizedDescription)"
  - Keep error logging simple (full error UI in PR #24)
  - Test Gate: Errors caught and logged

- [ ] Verify input field clears after successful send
  - Test Gate: inputText set to empty string after send

---

## 6. UI Integration — MessageInputView (if needed)

- [ ] Open `Views/Conversation/MessageInputView.swift`
  - Test Gate: File opens successfully

- [ ] Verify send button triggers parent's sendMessage callback
  - Check if `onSend` closure is called on button tap
  - Test Gate: Send functionality already wired correctly

- [ ] If modifications needed, update accordingly
  - Test Gate: MessageInputView works with ChatView integration

---

## 7. Manual Testing Validation

### 7.1 Configuration Testing

- [x] Firebase Firestore connection established
  - Launch app, verify no Firebase initialization errors
  - Test Gate: No console errors related to Firestore

- [x] Firebase Authentication provides valid user ID
  - Log in as vanes, check console for UID
  - Test Gate: UID matches: `OUv2v5intnP7kHXv7rh550GQn6o1`

- [x] Firestore security rules allow read/write to messages collection
  - Verify rules published in Firebase Console
  - Test Gate: Rules active and no permission errors

- [x] All necessary Firebase imports working
  - Build project, verify no import errors
  - Test Gate: Project builds successfully

- [x] Test chat document exists in Firestore
  - Check Firebase Console for `test_chat_vanes_jameson`
  - Test Gate: Document present with correct fields

- [x] Test button added to ConversationListView
  - Launch app, see "🧪 Test Chat" button
  - Test Gate: Button visible in conversation list

### 7.2 Happy Path Testing

**Device 1 (Vanes):**
- [x] Log in as vanes
  - Email: vanes account
  - Test Gate: Login successful, Settings shows vanes email

- [x] Navigate to test chat via test button
  - Tap "🧪 Test Chat (Vanes ↔️ Jameson)"
  - Test Gate: ChatView opens with empty message list

- [x] Verify listener attaches
  - Check console for "👂 Listening for messages" log
  - Test Gate: Listener attached, completion handler called with empty array

- [x] Send first message: "Hello from Vanes"
  - Type in input field
  - Tap send button
  - Test Gate: Message appears in ChatView within 100ms

- [x] Verify message in Firestore Console
  - Check `chats/test_chat_vanes_jameson/messages`
  - Test Gate: Message document exists with correct senderID

**Device 2 (Jameson):**
- [x] Log in as jameson
  - Email: jameson account
  - Test Gate: Login successful, Settings shows jameson email

- [x] Navigate to same test chat via test button
  - Tap "🧪 Test Chat (Vanes ↔️ Jameson)"
  - Test Gate: ChatView opens with Vanes' message visible

- [x] Verify message received from Vanes
  - See "Hello from Vanes" message
  - Message aligned left (received message styling)
  - Test Gate: Message appears within 100ms of Device 1 send

- [x] Reply with: "Hi Vanes!"
  - Type in input field
  - Tap send button
  - Test Gate: Message appears in Jameson's ChatView immediately

**Device 1 (Vanes) - Receiving:**
- [x] Verify Jameson's reply appears automatically
  - See "Hi Vanes!" message appear in real-time
  - No manual refresh needed
  - Test Gate: Message appears within 100ms

**Both Devices:**
- [x] Verify messages in chronological order
  - Oldest at top, newest at bottom
  - Test Gate: Order matches send times

- [x] Verify sent vs received styling
  - Vanes' messages right-aligned, blue (on Device 1)
  - Jameson's messages left-aligned, gray (on Device 1)
  - Vice versa on Device 2
  - Test Gate: Styling correct for sender

### 7.3 Edge Cases Testing

- [x] Empty message test
  - Try to send empty message (just spaces)
  - Test Gate: Send fails gracefully, no Firestore write

- [x] Whitespace-only message test
  - Type "   " and tap send
  - Test Gate: Validation catches trimmed empty string

- [ x] Very long message test
  - Type 50-character message (normal length)
  - Test Gate: Sends successfully
  - Type 11,000-character message (if possible)
  - Test Gate: Validation catches text too long error

- [x] Rapid sends test
  - Send 5 messages quickly (1 per second)
  - Test Gate: All messages appear on both devices
  - Test Gate: All messages in correct chronological order

- [x] Navigate away and back
  - Open ChatView, see messages
  - Navigate back to ConversationListView
  - Navigate to ChatView again
  - Test Gate: Listener detached on first exit (check console logs)
  - Test Gate: Listener reattached on second entry
  - Test Gate: Messages still load correctly

### 7.4 Multi-Device Testing (3+ devices if available)

**Setup:**
- [ ] Device 1: Log in as vanes
- [ ] Device 2: Log in as jameson
- [ ] Device 3: Log in as third test user (or reuse one of the above)

**Note:** If only 2 devices available, skip this section or test with 2 devices extensively.

**Testing:**
- [ ] All 3 devices open test chat
  - Test Gate: All see same message history

- [ ] Device 1 sends: "Message 1"
  - Test Gate: Appears on Device 2 within 100ms
  - Test Gate: Appears on Device 3 within 100ms

- [ ] Device 2 sends: "Message 2" immediately
  - Test Gate: Appears on Device 1 within 100ms
  - Test Gate: Appears on Device 3 within 100ms

- [ ] Device 3 sends: "Message 3" immediately
  - Test Gate: Appears on Device 1 within 100ms
  - Test Gate: Appears on Device 2 within 100ms

- [ ] Verify all devices show same order
  - Test Gate: All 3 messages in same chronological order on all devices

### 7.5 Offline Behavior Testing (Basic)

**Note:** Full offline queueing deferred to PR #11. This tests basic error handling.

- [ ] Device 1: Enable Airplane Mode
  - Test Gate: Device offline

- [ ] Device 1: Attempt to send message
  - Type message and tap send
  - Test Gate: Send fails with Firestore network error
  - Test Gate: Error logged to console

- [ ] Verify no partial writes to Firestore
  - Check Firestore Console
  - Test Gate: No incomplete message documents

- [ ] Device 1: Disable Airplane Mode
  - Test Gate: Connection restored

- [ ] Device 2: Send message
  - Test Gate: Device 1 receives message after reconnecting

### 7.6 Performance Testing

**Message Send Latency:**
- [ ] Measure time from sendMessage() call to Firestore write completion
  - Add timestamp logs before and after send
  - Test Gate: < 50ms for send operation (check console timestamps)

**Message Delivery Latency:**
- [ ] Measure time from Device 1 send to Device 2 listener callback
  - Add timestamp to message, compare on receive
  - Test Gate: < 100ms end-to-end delivery

**Listener Registration:**
- [ ] Measure time to attach listener on ChatView .onAppear
  - Add timestamp logs before and after observeMessages call
  - Test Gate: < 50ms to establish listener

**UI Responsiveness:**
- [ ] Send message while scrolling message list
  - Scroll through messages, tap send
  - Test Gate: No UI freezing or lag during send operation
  - Test Gate: Scrolling remains smooth at 60fps

### 7.7 Memory Leak Testing

- [ ] Open Xcode → Product → Profile (Instruments)
  - Select "Leaks" instrument
  - Test Gate: Instruments launches successfully

- [ ] Run app with Leaks instrument
  - Log in as vanes
  - Navigate to test chat
  - Test Gate: ChatView opens

- [ ] Perform navigation cycle 10 times
  - Open ChatView → Go back → Open ChatView → Go back (repeat)
  - Test Gate: Complete 10 cycles

- [ ] Check for memory leaks in Instruments
  - Look for leaked ListenerRegistration objects
  - Look for leaked MessageService instances
  - Test Gate: Zero memory leaks detected

- [ ] Verify listener removed in console logs
  - See "👂 Listening for messages" on appear
  - Verify listener cleanup on disappear
  - Test Gate: Logs confirm proper lifecycle

---

## 8. Acceptance Gates Verification

Reference all gates from PRD Section 12. Check off each:

### Configuration Gates
- [ ] Gate: Firebase Firestore connection established
- [ ] Gate: Firebase Authentication provides valid user ID
- [ ] Gate: Firestore security rules allow read/write
- [ ] Gate: All Firebase imports working
- [ ] Gate: Test chat document created
- [ ] Gate: Test button added for manual testing

### Send Message Gates
- [ ] Gate: sendMessage() accepts chatID and text, returns messageID
- [ ] Gate: Creates message document in correct Firestore path
- [ ] Gate: Uses FieldValue.serverTimestamp() for timestamp
- [ ] Gate: Updates chat's lastMessage and lastMessageTimestamp
- [ ] Gate: Validates text is not empty (trimmed)
- [ ] Gate: Handles async errors (network, Firebase, permissions)

### Observe Messages Gates
- [ ] Gate: Establishes Firestore snapshot listener
- [ ] Gate: Orders messages by timestamp ascending
- [ ] Gate: Calls completion handler with [Message] array
- [ ] Gate: Returns ListenerRegistration for cleanup
- [ ] Gate: Listener triggers immediately with existing messages

### Listener Lifecycle Gates
- [ ] Gate: ChatView calls observeMessages on .onAppear
- [ ] Gate: ChatView stores ListenerRegistration reference
- [ ] Gate: ChatView calls .remove() on .onDisappear
- [ ] Gate: No memory leaks confirmed with Instruments

### Real-Time Delivery Gates
- [ ] Gate: Device A sends message → Device B receives within 100ms
- [ ] Gate: 3+ devices all receive within 100ms (if tested)
- [ ] Gate: Group chats (3+ members) sync within 100ms (basic test)

### Concurrent Messages Gates
- [ ] Gate: Multiple users send simultaneously → all messages appear correctly
- [ ] Gate: No race conditions in message ordering
- [ ] Gate: Server timestamps ensure correct chronological order

### Edge Case Gates
- [ ] Gate: Empty/whitespace-only messages rejected
- [ ] Gate: Messages > 10,000 characters rejected
- [ ] Gate: Rapid sends (10+ messages) handled correctly
- [ ] Gate: Navigate away → listener removed, no leaks

### Performance Gates
- [ ] Gate: Message send < 50ms to Firestore
- [ ] Gate: Message delivery < 100ms end-to-end
- [ ] Gate: Listener registration < 50ms
- [ ] Gate: No UI freezing during send operations

### Visual State Gates
- [ ] Gate: No console errors during message send
- [ ] Gate: No console errors during listener attachment
- [ ] Gate: Messages appear automatically (no manual refresh)
- [ ] Gate: Correct sender styling (sent vs received)
- [ ] Gate: Input field clears after successful send

---

## 9. Code Quality & Standards

- [ ] Follow Swift best practices per `Psst/agents/shared-standards.md`
  - Proper types (no `Any`)
  - Async/await for Firebase operations
  - Proper error handling
  - Test Gate: Code follows standards

- [ ] Add comprehensive inline documentation
  - Document MessageService class and methods
  - Document error enum cases
  - Test Gate: All public APIs documented

- [ ] No console warnings or errors
  - Build project, check for warnings
  - Test Gate: Zero warnings

- [ ] No commented-out code
  - Clean up any debug code
  - Test Gate: No commented code blocks

- [ ] Meaningful variable names
  - Review all variables for clarity
  - Test Gate: Names are descriptive

---

## 10. Documentation & PR Preparation

### 10.1 Code Documentation

- [ ] Add inline comments for complex logic
  - Document Firestore listener setup
  - Document timestamp handling
  - Test Gate: Complex sections explained

- [ ] Verify all methods have documentation comments
  - Check MessageService methods
  - Test Gate: Public APIs fully documented

### 10.2 Remove Temporary Test Code

- [ ] Remove temporary test button from ConversationListView
  - Delete "🧪 Test Chat" button and related code
  - Test Gate: Button removed

- [ ] Remove any debug print statements (keep essential logging)
  - Review for excessive logging
  - Keep: "📤 Sending message", "📨 Received messages"
  - Remove: Temporary debug timestamps
  - Test Gate: Clean logging

- [ ] Remove test chat from Firestore Console (optional)
  - Or document that it's for testing purposes
  - Test Gate: Decision made and executed

### 10.3 Final Testing Pass

- [ ] Full end-to-end test after cleanup
  - Create new chat manually or use existing
  - Test send/receive on 2 devices
  - Test Gate: All functionality still works

- [ ] Build project with zero warnings
  - Clean build folder
  - Build again
  - Test Gate: Builds successfully

### 10.4 Create PR

- [ ] Stage all changes
  - `Services/MessageService.swift` (new)
  - `Views/Conversation/ChatView.swift` (modified)
  - Any other modified files
  - Test Gate: All changes staged

- [ ] Verify with user before creating PR
  - Show summary of changes
  - Confirm all acceptance gates passed
  - Test Gate: User approval received

- [ ] Create PR targeting develop branch
  - Branch: `feat/pr-8-real-time-messaging-service` → `develop`
  - Test Gate: PR created

- [ ] Write PR description

Use this template:

```markdown
# PR #8: Real-Time Messaging Service

## Summary
Implements MessageService with Firestore snapshot listeners for real-time message sending and receiving across devices with sub-100ms latency.

## Changes
- ✅ Created `Services/MessageService.swift`
  - `sendMessage(chatID:text:)` - Send messages with validation
  - `observeMessages(chatID:completion:)` - Real-time message listener
  - MessageError enum for error handling
  - Helper methods for validation and chat updates

- ✅ Updated `Views/Conversation/ChatView.swift`
  - Integrated MessageService for real message operations
  - Implemented listener lifecycle management (.onAppear/.onDisappear)
  - Replaced placeholder messages with real Firestore data

- ✅ Configured Firestore Security Rules for message access control

## Testing Completed
- ✅ Configuration: Firebase, Auth, Security Rules verified
- ✅ Happy Path: 2-device send/receive tested (<100ms)
- ✅ Edge Cases: Empty messages, long messages, rapid sends
- ✅ Multi-Device: Concurrent messaging across devices
- ✅ Performance: Send <50ms, delivery <100ms, 60fps scrolling
- ✅ Memory: No leaks confirmed with Instruments

## Test Users
- vanes: OUv2v5intnP7kHXv7rh550GQn6o1
- jameson: wOh11I865XTWQVTmd1RfWsB9sBD3

## Acceptance Gates
All gates from PRD Section 12 verified ✅

## Performance Targets Met
- Message send latency: <50ms ✅
- Message delivery latency: <100ms ✅
- Listener registration: <50ms ✅
- No UI blocking ✅

## Links
- PRD: `Psst/docs/prds/pr-8-prd.md`
- TODO: `Psst/docs/todos/pr-8-todo.md`

## Next Steps
- PR #9: Optimistic UI updates
- PR #10: Server timestamp display
- PR #11: Offline message queueing
```

- [ ] Link PRD and TODO in PR description
  - Test Gate: Links included

- [ ] Request review (if applicable)
  - Test Gate: PR ready for review

---

## 11. Completion Checklist

Final verification before marking PR complete:

- [ ] All TODO tasks checked off
- [ ] Services implemented with proper error handling
- [ ] SwiftUI views integrated with MessageService
- [ ] Firebase integration verified (real-time sync, security rules)
- [ ] Manual testing completed across all categories
- [ ] Multi-device sync verified (<100ms)
- [ ] Performance targets met (see shared-standards.md)
- [ ] All acceptance gates pass
- [ ] Code follows `Psst/agents/shared-standards.md` patterns
- [ ] No console warnings
- [ ] Memory leaks checked with Instruments (zero leaks)
- [ ] Documentation complete
- [ ] Temporary test code removed
- [ ] User verified before PR creation
- [ ] PR created targeting develop branch

---

## Notes

- Break tasks into <30 min chunks ✅
- Complete tasks sequentially ✅
- Check off after completion ✅
- Document blockers immediately
- Reference PRD sections for clarification
- Reference `Psst/agents/shared-standards.md` for patterns
- This is the CRITICAL PR for real-time messaging functionality
- All future messaging PRs (optimistic UI, offline, read receipts) depend on this
- Message delivery <100ms is a hard requirement — test thoroughly
- Listener lifecycle management prevents memory leaks — verify with Instruments
- Server timestamps prevent timezone issues — use FieldValue.serverTimestamp()
- Test on actual devices for accurate latency measurement (Simulator may be slower)

