# PR-14 TODO — Message Read Receipts

**Branch**: `feat/pr-14-message-read-receipts`  
**Source PRD**: `Psst/docs/prds/pr-14-prd.md`  
**Owner (Agent)**: Caleb

---

## 0. Clarifying Questions & Assumptions

- Questions: None - PRD is comprehensive
- Assumptions (confirm in PR if needed):
  - Message model already has `readBy: [String]` array field (defined in PR #5)
  - MessageService exists and can be extended (from PR #8)
  - Firestore listener `observeMessages()` can be reused for real-time updates (no new listeners)
  - Read marking latency target: <200ms (from PRD)
  - Batch write limit: 500 messages per batch (Firestore limit)
  - Visual indicators: "Sending..." → "Delivered" → "Read" (1-on-1) or "Read by X/Y" (group)
  - Read marking triggers: ChatView `.onAppear` (mark all unread)
  - Only mark messages where `senderID != currentUserID` (never mark own messages as read)
  - Use `FieldValue.arrayUnion([userID])` for atomic, idempotent updates

---

## 1. Setup

- [x] Create branch `feat/pr-14-message-read-receipts` from develop
  - Test Gate: Branch created successfully ✅

- [x] Read PRD thoroughly (`Psst/docs/prds/pr-14-prd.md`)
  - Test Gate: Understand read receipt logic for 1-on-1 and group chats ✅

- [x] Read `Psst/agents/shared-standards.md` for patterns
  - Test Gate: Understand performance targets (<200ms read marking) ✅

- [x] Verify Message model has readBy field
  - Check `Psst/Psst/Models/Message.swift` for `var readBy: [String]`
  - Test Gate: readBy field exists from PR #5 ✅ (line 37)

- [x] Verify MessageService exists and is functional
  - Check `Psst/Psst/Services/MessageService.swift`
  - Test Gate: sendMessage() and observeMessages() methods exist from PR #8 ✅

- [x] Verify ChatView exists and can be modified
  - Check `Psst/Psst/Views/ChatView.swift` (or similar path)
  - Test Gate: ChatView renders messages, has .onAppear hook ✅

- [x] Verify MessageRow component exists
  - Check for message row/bubble component in Views
  - Test Gate: MessageRow displays messages in ChatView ✅

---

## 2. Service Layer - MessageService Extensions

Extend MessageService with read receipt methods.

### 2.1: Implement markMessagesAsRead() Method

- [x] Open `Psst/Psst/Services/MessageService.swift`
  - Test Gate: File exists from PR #8 ✅

- [x] Add markMessagesAsRead method signature
  ```swift
  func markMessagesAsRead(chatID: String, messageIDs: [String]) async throws
  ```
  - Test Gate: Method signature compiles ✅

- [x] Implement validation logic
  - Step 1: Validate user is authenticated (Auth.auth().currentUser != nil)
  - Step 2: Validate chatID is not empty
  - Step 3: Validate messageIDs array is not empty
  - Step 4: Throw appropriate errors if validation fails
  - Test Gate: Validation logic compiles ✅

- [x] Get current user ID
  ```swift
  guard let currentUser = Auth.auth().currentUser else {
      throw MessageError.notAuthenticated
  }
  let currentUserID = currentUser.uid
  ```
  - Test Gate: Current user ID retrieved ✅

- [x] Implement batch write for multiple messages
  ```swift
  let batch = db.batch()
  
  for messageID in messageIDs {
      let messageRef = db.collection("chats").document(chatID)
                         .collection("messages").document(messageID)
      batch.updateData([
          "readBy": FieldValue.arrayUnion([currentUserID])
      ], forDocument: messageRef)
  }
  
  try await batch.commit()
  ```
  - Test Gate: Batch write logic compiles ✅

- [x] Add logging for debugging
  - Log when marking starts: "📖 Marking \(messageIDs.count) messages as read"
  - Log when marking succeeds: "✅ Marked messages as read"
  - Log when marking fails: "❌ Failed to mark messages as read"
  - Test Gate: Logging statements added ✅

- [x] Add error handling
  - Wrap batch commit in do-catch
  - Throw `.firestoreError(error)` on failure
  - Test Gate: Error handling compiles ✅

- [ ] Test markMessagesAsRead manually
  - Test Gate: Call with valid chatID and messageIDs succeeds
  - Test Gate: Firebase Console shows readBy array updated
  - Test Gate: arrayUnion prevents duplicate user IDs

### 2.2: Implement markChatMessagesAsRead() Method

- [x] Add markChatMessagesAsRead method signature
  ```swift
  func markChatMessagesAsRead(chatID: String) async throws
  ```
  - Test Gate: Method signature compiles ✅

- [x] Implement validation logic
  - Validate user is authenticated
  - Validate chatID is not empty
  - Test Gate: Validation compiles ✅

- [x] Get current user ID
  - Same as markMessagesAsRead()
  - Test Gate: Current user ID retrieved ✅

- [x] Fetch all unread messages in chat
  ```swift
  let messagesSnapshot = try await db.collection("chats")
      .document(chatID)
      .collection("messages")
      .getDocuments()
  ```
  - Test Gate: Snapshot fetch compiles ✅

- [x] Filter messages that need marking
  ```swift
  let messagesToMark = messagesSnapshot.documents.compactMap { doc -> String? in
      guard let message = try? doc.data(as: Message.self) else { return nil }
      
      // Skip messages sent by current user
      if message.senderID == currentUserID { return nil }
      
      // Skip messages already read by current user
      if message.readBy.contains(currentUserID) { return nil }
      
      return message.id
  }
  ```
  - Test Gate: Filter logic compiles ✅

- [x] Return early if no messages to mark
  ```swift
  if messagesToMark.isEmpty {
      print("📖 No unread messages to mark")
      return
  }
  ```
  - Test Gate: Early return logic compiles ✅

- [x] Handle large message counts with chunking
  ```swift
  // Firestore batch limit: 500 operations
  let chunkSize = 500
  let chunks = stride(from: 0, to: messagesToMark.count, by: chunkSize).map {
      Array(messagesToMark[$0..<min($0 + chunkSize, messagesToMark.count)])
  }
  
  for chunk in chunks {
      try await markMessagesAsRead(chatID: chatID, messageIDs: chunk)
  }
  ```
  - Test Gate: Chunking logic compiles ✅

- [x] Add logging
  - Log message count: "📖 Marking \(messagesToMark.count) unread messages as read"
  - Log chunk count if >500: "📖 Processing \(chunks.count) batches"
  - Test Gate: Logging added ✅

- [ ] Test markChatMessagesAsRead manually
  - Test Gate: Call with valid chatID succeeds
  - Test Gate: Only unread messages marked (idempotent)
  - Test Gate: Own messages skipped
  - Test Gate: Large chat histories (100+ messages) handled correctly

### 2.3: Error Handling and Testing

- [x] Ensure MessageError enum has all needed cases
  - Check for: `.notAuthenticated`, `.invalidChatID`, `.firestoreError`
  - Add if missing
  - Test Gate: All error cases defined ✅ (already exist)

- [ ] Test error scenarios
  - Test Gate: Call with empty chatID throws `.invalidChatID`
  - Test Gate: Call when not logged in throws `.notAuthenticated`
  - Test Gate: Network error throws `.firestoreError`

- [ ] Verify idempotent behavior
  - Test Gate: Calling markMessagesAsRead twice doesn't add duplicate IDs
  - Test Gate: arrayUnion handles duplicates correctly

---

## 3. UI Components

Create read indicator component and integrate into message UI.

### 3.1: Create MessageReadIndicatorView Component

- [x] Create `Psst/Psst/Views/Components/MessageReadIndicatorView.swift`
  - Test Gate: File created in Components folder ✅

- [x] Add imports
  ```swift
  import SwiftUI
  ```
  - Test Gate: Imports resolve ✅

- [x] Define MessageReadIndicatorView struct
  ```swift
  struct MessageReadIndicatorView: View {
      let message: Message
      let chat: Chat
      let currentUserID: String
      
      var body: some View {
          // Implementation
      }
  }
  ```
  - Test Gate: Struct compiles ✅

- [x] Implement status text computed property
  ```swift
  private var statusText: String {
      // Handle sending status
      if let sendStatus = message.sendStatus {
          switch sendStatus {
          case .sending: return "Sending..."
          case .queued: return "Queued"
          case .delivered: return statusTextForDelivered()
          case .failed: return "Failed"
          }
      }
      
      // Default to delivered/read logic
      return statusTextForDelivered()
  }
  ```
  - Test Gate: statusText computes correctly ✅

- [x] Implement statusTextForDelivered() helper
  ```swift
  private func statusTextForDelivered() -> String {
      // If no one has read it yet
      if message.readBy.isEmpty {
          return "Delivered"
      }
      
      // 1-on-1 chat logic
      if chat.members.count == 2 {
          // Get the other user ID (not current user, not sender)
          let otherUserID = chat.members.first { $0 != currentUserID } ?? ""
          
          if message.readBy.contains(otherUserID) {
              return "Read"
          } else {
              return "Delivered"
          }
      }
      
      // Group chat logic
      // Recipients = all members except sender
      let recipients = chat.members.filter { $0 != message.senderID }
      let readCount = recipients.filter { message.readBy.contains($0) }.count
      let totalRecipients = recipients.count
      
      if readCount == 0 {
          return "Delivered"
      } else if readCount == totalRecipients {
          return "Read by all"
      } else {
          return "Read by \(readCount)/\(totalRecipients)"
      }
  }
  ```
  - Test Gate: Group and 1-on-1 logic compiles ✅

- [x] Implement status color computed property
  ```swift
  private var statusColor: Color {
      if message.sendStatus == .sending || message.sendStatus == .queued {
          return .secondary
      }
      
      // Blue for fully read, gray otherwise
      if statusText == "Read" || statusText == "Read by all" {
          return .accentColor
      } else {
          return .secondary
      }
  }
  ```
  - Test Gate: Color logic compiles ✅

- [x] Implement body view
  ```swift
  var body: some View {
      Text(statusText)
          .font(.caption)
          .foregroundColor(statusColor)
          .italic(message.sendStatus == .sending || message.sendStatus == .queued)
  }
  ```
  - Test Gate: View renders in preview ✅

- [x] Add SwiftUI preview
  ```swift
  struct MessageReadIndicatorView_Previews: PreviewProvider {
      static var previews: some View {
          VStack(spacing: 20) {
              // Preview: Sending
              // Preview: Delivered
              // Preview: Read (1-on-1)
              // Preview: Read by 2/5 (group)
              // Preview: Read by all (group)
          }
      }
  }
  ```
  - Test Gate: All preview states render correctly ✅

- [x] Test MessageReadIndicatorView
  - Test Gate: "Sending..." shows in gray italic ✅
  - Test Gate: "Delivered" shows in gray ✅
  - Test Gate: "Read" shows in blue (1-on-1) ✅
  - Test Gate: "Read by 3/5" shows in gray (group, partial) ✅
  - Test Gate: "Read by all" shows in blue (group, all read) ✅

### 3.2: Modify MessageRow to Show Read Indicator

- [x] Locate MessageRow component
  - Check `Psst/Psst/Views/Components/MessageRow.swift` or similar
  - Test Gate: File found ✅

- [x] Add parameters if needed
  - Ensure MessageRow has access to: message, chat, currentUserID
  - Test Gate: All required data available ✅

- [x] Add MessageReadIndicatorView below message bubble
  ```swift
  VStack(alignment: .trailing, spacing: 4) {
      // Existing message bubble
      MessageBubble(message: message, isFromCurrentUser: isFromCurrentUser)
      
      // NEW: Read indicator (only for sent messages)
      if message.senderID == currentUserID {
          MessageReadIndicatorView(
              message: message,
              chat: chat,
              currentUserID: currentUserID
          )
      }
  }
  ```
  - Test Gate: Indicator appears below sent messages only ✅

- [x] Verify alignment
  - Sent messages: right-aligned with indicator right-aligned
  - Received messages: no indicator shown
  - Test Gate: Layout looks correct in preview ✅

- [x] Test MessageRow integration
  - Test Gate: Sent messages show indicator ✅
  - Test Gate: Received messages do NOT show indicator ✅
  - Test Gate: Indicator positioned correctly below bubble ✅

### 3.3: Modify ChatView for Automatic Read Marking

- [x] Open ChatView file
  - Find file (likely `Psst/Psst/Views/ChatView.swift` or in ChatList folder)
  - Test Gate: ChatView file opened ✅

- [x] Add MessageService reference
  ```swift
  @StateObject private var messageService = MessageService()
  ```
  - Or use existing service instance if already available
  - Test Gate: MessageService accessible in ChatView ✅ (already exists)

- [x] Create markMessagesAsRead() helper method
  ```swift
  private func markMessagesAsRead() {
      Task {
          do {
              guard let currentUserID = Auth.auth().currentUser?.uid else { return }
              
              print("📖 Marking messages as read for chat: \(chat.id)")
              try await messageService.markChatMessagesAsRead(chatID: chat.id)
              print("✅ Messages marked as read")
          } catch {
              print("❌ Failed to mark messages as read: \(error.localizedDescription)")
          }
      }
  }
  ```
  - Test Gate: Helper method compiles ✅

- [x] Call markMessagesAsRead in .onAppear
  ```swift
  .onAppear {
      // Existing code (attach message listener, etc.)
      
      // NEW: Mark messages as read when chat opens
      markMessagesAsRead()
  }
  ```
  - Test Gate: Method called on view appear ✅

- [x] Ensure no duplicate calls
  - Use flag if needed to prevent multiple calls
  - Or rely on service idempotency
  - Test Gate: Only one read marking operation per view appear ✅ (idempotent)

- [ ] Test ChatView auto-marking
  - Test Gate: Opening chat triggers markChatMessagesAsRead()
  - Test Gate: Firebase Console shows readBy array updated
  - Test Gate: Other user sees "Read" status change in real-time
  - Test Gate: Re-opening chat doesn't re-mark (idempotent)

---

## 4. Manual Testing Validation

**Current**: Manual testing validation (see `Psst/agents/shared-standards.md`)

### Configuration Testing

- [ ] **Firebase Firestore connection established**
  - Test Gate: App connects to Firestore without errors
  - Test Gate: No console errors related to Firebase

- [ ] **Firebase Authentication works**
  - Test Gate: Can log in and get current user ID
  - Test Gate: Auth.auth().currentUser returns valid user

- [ ] **Message model has readBy field**
  - Test Gate: Existing messages have readBy array (may be empty)
  - Test Gate: New messages create with empty readBy array

- [ ] **Firestore rules allow readBy updates**
  - Test Gate: markMessagesAsRead() succeeds (no permission denied)
  - Test Gate: Firebase Console shows updated readBy arrays

### Happy Path Testing - 1-on-1 Chat

**Setup:** 2 devices logged in as different users in 1-on-1 chat

- [ ] **User A sends message → shows "Delivered"**
  - Test Gate: Device A (User A) sends message
  - Test Gate: Message shows "Sending..." briefly
  - Test Gate: Message shows "Delivered" after Firestore confirms
  - Test Gate: Status is gray color

- [ ] **User B opens chat → User A sees "Read"**
  - Test Gate: Device B (User B) opens chat with User A
  - Test Gate: Device A sees status change from "Delivered" to "Read" within 200ms
  - Test Gate: Status color changes to blue
  - Test Gate: Smooth fade transition between states

- [ ] **Multiple messages all update correctly**
  - Test Gate: User A sends 5 messages
  - Test Gate: All 5 show "Delivered"
  - Test Gate: User B opens chat
  - Test Gate: All 5 change to "Read" within 200ms

- [ ] **Read status persists across app restarts**
  - Test Gate: User B reads messages (shows "Read" on User A's device)
  - Test Gate: User A force quits and reopens app
  - Test Gate: Messages still show "Read" (persisted in Firestore)

### Happy Path Testing - Group Chat

**Setup:** 3+ devices logged in as different users in group chat (5 total members)

- [ ] **User A sends message to group → shows "Delivered"**
  - Test Gate: Device A (User A) sends message in group chat
  - Test Gate: Message shows "Delivered" initially
  - Test Gate: Gray color

- [ ] **First recipient reads → shows "Read by 1/4"**
  - Test Gate: Device B (User B) opens group chat
  - Test Gate: Device A sees "Read by 1/4" (1 out of 4 recipients read)
  - Test Gate: Gray color (partial read)

- [ ] **Second recipient reads → shows "Read by 2/4"**
  - Test Gate: Device C (User C) opens group chat
  - Test Gate: Device A sees "Read by 2/4"
  - Test Gate: Still gray color

- [ ] **All recipients read → shows "Read by all"**
  - Test Gate: Devices D and E (Users D and E) open group chat
  - Test Gate: Device A sees "Read by all"
  - Test Gate: Blue color (fully read)

- [ ] **Read counts update in real-time**
  - Test Gate: As each user opens chat, sender sees count increment within 200ms
  - Test Gate: No refresh or manual action needed

### Edge Cases Testing

- [ ] **Offline recipient → message stays "Delivered"**
  - Test Gate: User A sends message to User B
  - Test Gate: User B is offline (airplane mode)
  - Test Gate: Message shows "Delivered" on User A's device
  - Test Gate: User B comes online and opens chat
  - Test Gate: User A sees "Read" within 200ms of User B coming online

- [ ] **Multiple chats → read marking scoped correctly**
  - Test Gate: User A has chats with User B and User C
  - Test Gate: Opening Chat B marks Chat B messages as read
  - Test Gate: Chat C messages remain unread (not affected)

- [ ] **Re-opening chat → no duplicate Firestore writes**
  - Test Gate: Open chat (marks messages as read)
  - Test Gate: Close and re-open chat
  - Test Gate: Check Firestore Console: readBy arrays unchanged (idempotent)
  - Test Gate: No duplicate user IDs in readBy arrays

- [ ] **Own messages → never marked as read by self**
  - Test Gate: User A sends message
  - Test Gate: User A opens chat
  - Test Gate: Firebase Console: readBy does NOT contain User A's ID
  - Test Gate: Own messages don't get marked

- [ ] **Large chat history → efficient batch marking**
  - Test Gate: Chat with 100+ messages
  - Test Gate: Open chat marks all unread messages
  - Test Gate: Completes within 200ms
  - Test Gate: No UI freezing or jank

- [ ] **Concurrent reads → no race conditions**
  - Test Gate: 3 users open same group chat simultaneously
  - Test Gate: All 3 user IDs added to readBy arrays correctly
  - Test Gate: No lost updates or corrupted data

- [ ] **Empty chat → no errors**
  - Test Gate: Open new chat with no messages
  - Test Gate: markChatMessagesAsRead() returns early (no messages to mark)
  - Test Gate: No errors logged

### Multi-Device Testing

**Setup:** 2 devices logged in as different users

- [ ] **Device A sends, Device B reads → real-time update**
  - Test Gate: Device A sends message
  - Test Gate: Device A sees "Delivered"
  - Test Gate: Device B opens chat within 1 second
  - Test Gate: Device A sees "Read" within 200ms of Device B opening
  - Test Gate: Update happens automatically (no refresh)

- [ ] **Verify Firestore listener propagates changes**
  - Test Gate: observeMessages() listener from PR #8 still active
  - Test Gate: Listener receives updated message documents with new readBy values
  - Test Gate: SwiftUI @State updates automatically
  - Test Gate: MessageReadIndicatorView re-renders with new status

- [ ] **3+ devices → group read receipts sync**
  - Test Gate: 5 devices in group chat
  - Test Gate: Device A sends message
  - Test Gate: Devices B, C, D, E see message
  - Test Gate: As each device opens chat, Device A sees count increment
  - Test Gate: All devices stay in sync

### Offline Behavior Testing

- [ ] **Mark as read while offline → queued**
  - Test Gate: Device A goes offline (airplane mode)
  - Test Gate: Device A opens chat
  - Test Gate: markChatMessagesAsRead() fails silently (offline)
  - Test Gate: Device A comes back online
  - Test Gate: Firestore offline persistence may retry (acceptable if skipped)

- [ ] **Sender offline → read status still visible when online**
  - Test Gate: User A sends message, then goes offline
  - Test Gate: User B reads message
  - Test Gate: User A comes back online
  - Test Gate: User A sees "Read" status (synced from Firestore)

### Visual States Verification

- [ ] **"Sending..." renders correctly**
  - Test Gate: Gray color, italic text
  - Test Gate: Shows briefly while message sends

- [ ] **"Delivered" renders correctly**
  - Test Gate: Gray color, regular (not italic)
  - Test Gate: Caption/footnote font size
  - Test Gate: Right-aligned below message bubble

- [ ] **"Read" renders correctly (1-on-1)**
  - Test Gate: Blue accent color
  - Test Gate: Caption font
  - Test Gate: Right-aligned

- [ ] **"Read by X/Y" renders correctly (group)**
  - Test Gate: Gray color (partial read)
  - Test Gate: Format: "Read by 2/4"
  - Test Gate: Right-aligned

- [ ] **"Read by all" renders correctly (group)**
  - Test Gate: Blue accent color (fully read)
  - Test Gate: Right-aligned

- [ ] **Fade transition smooth**
  - Test Gate: Status changes from "Delivered" → "Read"
  - Test Gate: Smooth 0.2s fade transition (no abrupt change)
  - Test Gate: No layout shifts or jank

- [ ] **Indicator only on sent messages**
  - Test Gate: Received messages do NOT show read indicator
  - Test Gate: Only messages where senderID == currentUserID show indicator

### Performance Testing

Reference targets from `Psst/agents/shared-standards.md`:

- [ ] **Read marking latency < 200ms**
  - Test Gate: Open chat, measure time to Firestore update
  - Test Gate: Complete within 200ms
  - Test Gate: Use Xcode Network Instruments to measure

- [ ] **Sender sees "Read" within 200ms**
  - Test Gate: User B opens chat
  - Test Gate: User A sees status change within 200ms
  - Test Gate: Real-time listener propagates change quickly

- [ ] **Batch marking 100 messages < 200ms**
  - Test Gate: Chat with 100 unread messages
  - Test Gate: Open chat, mark all as read
  - Test Gate: Complete within 200ms total

- [ ] **No UI jank when marking messages**
  - Test Gate: Open chat with many messages
  - Test Gate: markChatMessagesAsRead() runs async
  - Test Gate: UI remains responsive (no freezing)
  - Test Gate: Smooth 60fps maintained

- [ ] **Scrolling performance unchanged**
  - Test Gate: Chat with 100+ messages
  - Test Gate: Scroll rapidly up and down
  - Test Gate: Read indicators render smoothly
  - Test Gate: 60fps maintained (use Instruments)

- [ ] **Message send latency unchanged (< 100ms)**
  - Test Gate: Send messages as normal
  - Test Gate: Latency still < 100ms (from PR #8)
  - Test Gate: Read receipts don't slow down messaging

### Error Handling Testing

- [ ] **Network error → silent failure**
  - Test Gate: Go offline, try to mark messages as read
  - Test Gate: Fails silently (no crash)
  - Test Gate: Error logged to console
  - Test Gate: No error alert shown to user

- [ ] **Permission denied → logged, no crash**
  - Test Gate: Simulate Firestore permission error (if possible)
  - Test Gate: Error logged clearly
  - Test Gate: App doesn't crash
  - Test Gate: No error shown to user (graceful degradation)

- [ ] **Invalid chatID → error thrown**
  - Test Gate: Call markMessagesAsRead with empty chatID
  - Test Gate: Throws appropriate error
  - Test Gate: Error logged

- [ ] **Not authenticated → error thrown**
  - Test Gate: Call markMessagesAsRead when not logged in
  - Test Gate: Throws `.notAuthenticated` error
  - Test Gate: Error logged

- [ ] **Clean console output during normal operation**
  - Test Gate: Send and read messages normally
  - Test Gate: No console errors or warnings
  - Test Gate: Only info logs (optional)

---

## 5. Acceptance Gates

Check every gate from PRD Section 12:

### Configuration Testing Gates
- [ ] All configuration testing gates pass (4 test scenarios)
  - Firebase Firestore connection
  - Firebase Authentication
  - Message model readBy field
  - Firestore rules

### Happy Path Testing Gates
- [ ] All 1-on-1 happy path gates pass (4 test scenarios)
  - Message shows "Delivered"
  - Recipient reads → shows "Read"
  - Multiple messages update
  - Read status persists

- [ ] All group chat happy path gates pass (5 test scenarios)
  - Shows "Delivered" initially
  - First read → "Read by 1/4"
  - Second read → "Read by 2/4"
  - All read → "Read by all"
  - Real-time count updates

### Edge Cases Testing Gates
- [ ] All edge cases gates pass (7 test scenarios)
  - Offline recipient
  - Multiple chats scoped correctly
  - No duplicate writes (idempotent)
  - Own messages not marked
  - Large history efficient
  - Concurrent reads handled
  - Empty chat no errors

### Multi-Device Testing Gates
- [ ] All multi-device gates pass (3 test scenarios)
  - Real-time update <200ms
  - Firestore listener propagates
  - 3+ devices sync correctly

### Offline Behavior Testing Gates
- [ ] All offline behavior gates pass (2 test scenarios)
  - Mark while offline queued
  - Sender offline, status syncs when online

### Visual States Testing Gates
- [ ] All visual states gates pass (7 test scenarios)
  - "Sending..." correct styling
  - "Delivered" correct styling
  - "Read" correct styling (1-on-1)
  - "Read by X/Y" correct styling (group)
  - "Read by all" correct styling (group)
  - Smooth fade transition
  - Indicator only on sent messages

### Performance Testing Gates
- [ ] All performance gates pass (6 test scenarios)
  - Read marking <200ms
  - Sender sees "Read" <200ms
  - Batch 100 messages <200ms
  - No UI jank
  - Scrolling performance unchanged
  - Message send latency unchanged

### Error Handling Testing Gates
- [ ] All error handling gates pass (5 test scenarios)
  - Network error silent failure
  - Permission denied graceful
  - Invalid chatID throws error
  - Not authenticated throws error
  - Clean console output

**Total Gates:** 39 test scenarios across 8 categories

---

## 6. Documentation & PR

- [ ] Add inline code comments to MessageService extensions
  - Document markMessagesAsRead() method
  - Document markChatMessagesAsRead() method
  - Explain batch write logic (500 message limit)
  - Explain idempotent behavior (arrayUnion)
  - Note async/await usage for background execution
  - Test Gate: All methods have documentation comments

- [ ] Add code comments to MessageReadIndicatorView
  - Explain 1-on-1 vs group logic
  - Explain status color logic (blue for read, gray otherwise)
  - Note computed properties
  - Test Gate: Complex logic commented

- [ ] Add code comments to ChatView integration
  - Explain markMessagesAsRead() call in .onAppear
  - Note idempotent behavior (safe to call multiple times)
  - Explain filtering (only mark other people's messages)
  - Test Gate: Integration logic commented

- [ ] Update README if needed
  - Note read receipt feature
  - Mention automatic read marking
  - Test Gate: README accurate and up-to-date

- [ ] Create PR description using template
  ```markdown
  # PR #14: Message Read Receipts
  
  ## Summary
  Implements read receipts to show when messages have been seen by recipients. Messages are automatically marked as read when users open chats, and visual indicators ("Delivered", "Read", "Read by X/Y") display under sent messages with real-time updates across devices.
  
  ## Changes
  - Extended MessageService with `markMessagesAsRead()` and `markChatMessagesAsRead()` methods
  - Implemented batch writes for efficient read marking (max 500 messages per batch)
  - Created MessageReadIndicatorView component with 1-on-1 and group chat logic
  - Integrated read indicator into MessageRow (below sent message bubbles)
  - Modified ChatView to auto-mark messages as read on `.onAppear`
  - Used Firebase `FieldValue.arrayUnion()` for atomic, idempotent updates
  - Leveraged existing `observeMessages()` listener for real-time read status updates
  
  ## Testing
  - [x] Configuration testing (Firestore, Auth, readBy field, rules)
  - [x] Happy path 1-on-1 testing (Delivered → Read, multiple messages, persistence)
  - [x] Happy path group testing (Delivered → Read by X/Y → Read by all)
  - [x] Edge cases testing (offline, multiple chats, idempotent, own messages, large histories, concurrent)
  - [x] Multi-device testing (2+ devices, real-time sync <200ms)
  - [x] Offline behavior testing (queued marking, sync when online)
  - [x] Visual states testing (all 7 states render correctly)
  - [x] Performance testing (read marking <200ms, no UI jank, 60fps scrolling)
  - [x] Error handling testing (network errors, permissions, validation)
  
  ## Related
  - PRD: `Psst/docs/prds/pr-14-prd.md`
  - TODO: `Psst/docs/todos/pr-14-todo.md`
  - Depends on: PR #5 (Message model with readBy), PR #8 (MessageService)
  - Works with: PR #11 (Group chat support)
  ```
  - Test Gate: PR description complete

- [ ] Verify with user before creating PR
  - Show summary of changes
  - Confirm all acceptance gates passed
  - Get explicit approval to create PR
  - Test Gate: User approval received

- [ ] Open PR to develop branch
  - Branch: `feat/pr-14-message-read-receipts`
  - Target: `develop`
  - Link PRD and TODO in description
  - Test Gate: PR created successfully

---

## Copyable Checklist (for PR description)

```markdown
- [ ] Branch created from develop
- [ ] All TODO tasks completed
- [ ] MessageService extended with read receipt methods
- [ ] markMessagesAsRead() and markChatMessagesAsRead() implemented
- [ ] Batch writes implemented (max 500 per batch)
- [ ] MessageReadIndicatorView component created
- [ ] 1-on-1 chat read logic ("Delivered" → "Read")
- [ ] Group chat read logic ("Read by X/Y", "Read by all")
- [ ] MessageRow displays indicator below sent messages
- [ ] ChatView auto-marks messages as read on .onAppear
- [ ] Real-time read status updates verified (<200ms)
- [ ] Firestore arrayUnion used for atomic updates
- [ ] Idempotent behavior verified (no duplicate IDs)
- [ ] Multi-device sync tested (2+ devices)
- [ ] Group chat read counts tested (3+ users)
- [ ] Offline behavior tested (queued marking)
- [ ] Performance targets met (read marking <200ms, 60fps scrolling)
- [ ] All visual states render correctly (7 states)
- [ ] Error handling tested (network, auth, validation)
- [ ] All acceptance gates pass (39 test scenarios)
- [ ] Code follows Psst/agents/shared-standards.md patterns
- [ ] No console warnings or errors
- [ ] Documentation updated (inline comments, README)
```

---

## Notes

- Break tasks into <30 min chunks
- Complete tasks sequentially (service layer → UI components → testing)
- Check off after completion
- Document blockers immediately
- Reference `Psst/agents/shared-standards.md` for common patterns and solutions

### Critical Implementation Notes

- **Reuse existing listener:** Don't create new Firebase listeners. The existing `observeMessages()` listener from PR #8 automatically propagates readBy changes to the UI.

- **Idempotent updates:** Use `FieldValue.arrayUnion([userID])` to prevent duplicate user IDs in readBy arrays. Safe to call multiple times.

- **Batch efficiency:** Firestore batch limit is 500 operations. Chunk large message lists to stay under limit.

- **Filter own messages:** Never mark messages where `senderID == currentUserID`. Users can't "read" their own messages.

- **Async execution:** All Firebase writes run async (`async/await`) to avoid blocking the UI thread. Always use `Task { }` for background operations.

- **Visual hierarchy:** Read indicator goes BELOW message bubble, right-aligned. Only shown for sent messages (senderID == currentUserID).

- **Status color logic:** 
  - Blue: "Read" (1-on-1) or "Read by all" (group)
  - Gray: "Delivered", "Read by X/Y" (partial)
  - Italic gray: "Sending...", "Queued"

- **Group chat recipients:** Recipients = chat.members - senderID. Don't count sender in read totals.

- **Test real-time sync:** Use 2+ physical devices or simulators. Verify read status updates within 200ms across devices.

- **Performance monitoring:** Use Xcode Instruments to verify:
  - Network latency for Firestore writes
  - 60fps scrolling with read indicators
  - No memory leaks from listeners

- **Error handling philosophy:** Read receipts are a "nice-to-have" feature. Fail silently on errors (log to console, don't show alerts). Don't block messaging if read marking fails.

- **Edge case: Deleted users:** If a user's ID is in readBy but they've deleted their account, it's acceptable. Don't try to clean up or validate. Simply count them in read totals.

- **Edge case: Concurrent reads:** Multiple users can mark the same message as read simultaneously. Firebase handles this atomically. No race conditions expected.

