# PRD: Message Read Receipts

**Feature**: Message Read Receipts

**Version**: 1.0

**Status**: Ready for Development

**Agent**: Pam

**Target Release**: Phase 4

**Links**: [PR Brief: PR #14](../pr-briefs.md), [TODO](../todos/pr-14-todo.md), [Architecture](../architecture.md), [PR #8 PRD](./pr-8-prd.md)

---

## 1. Summary

Implement read receipts to show when messages have been seen by recipients. Messages are automatically marked as read when the chat view is opened and messages become visible, updating Firestore's readBy array and displaying "Read", "Delivered", or "Seen" indicators under sent messages with appropriate visual styling for both 1-on-1 and group chats.

---

## 2. Problem & Goals

**Problem:** Users currently cannot tell if their sent messages have been read by recipients. This leads to:
- Uncertainty about whether the recipient saw the message
- Wondering if the recipient is ignoring them or just hasn't opened the chat yet
- Reduced communication clarity and engagement
- Inability to know message acknowledgment status
- Poor user experience compared to modern messaging apps (WhatsApp, iMessage, Signal)

**Why now?**
- Core messaging functionality (PRs 1-8) is complete and stable
- Group chat support (PR #11) is implemented
- Presence system (PR #12) provides online/offline context
- Typing indicators (PR #13) have established real-time status patterns
- This is a critical Phase 4 feature before push notifications (PRs 15-16)
- Message model already includes `readBy` array field (defined in PR #5)
- Users expect read receipts as a standard messaging feature

**Goals (ordered, measurable):**
- [ ] G1 — Automatically mark messages as read when user opens chat and messages become visible on screen
- [ ] G2 — Display clear visual indicators ("Read", "Delivered", "Seen") under sent messages in chat view
- [ ] G3 — Handle read receipts correctly for both 1-on-1 and group chats (showing individual read status per recipient)
- [ ] G4 — Update Firestore message documents with readBy array in real-time with <200ms latency

---

## 3. Non-Goals / Out of Scope

Call out what's intentionally excluded to avoid scope creep.

- [ ] Not implementing "disable read receipts" privacy setting — Always on for MVP
- [ ] Not showing read receipts in conversation list preview — Only in active chat view
- [ ] Not tracking precise read timestamps (when each user read it) — Just boolean "read or not"
- [ ] Not implementing "delivered to device" vs "delivered to server" distinction — Simplified status
- [ ] Not showing per-message read counts in group chats — Just show "Read by 3/5" etc.
- [ ] Not implementing read receipts for media messages — Text messages only for now
- [ ] Not persisting read status locally for offline — Requires Firebase sync
- [ ] Not implementing "read on multiple devices" complex logic — Simplify to user-level read status

---

## 4. Success Metrics

Reference `Psst/agents/shared-standards.md` for metric templates:

**User-visible:**
- Time to mark message as read: < 200ms from viewing message to readBy update in Firestore
- Read indicator accuracy: >99% correct state (shows "Read" only when actually read)
- User sees read status change: Within 200ms of recipient opening chat
- Read indicator clarity: Users understand the difference between "Delivered" and "Read"

**System (from shared-standards.md):**
- Read status update latency: < 200ms (view message → Firestore update → sender sees "Read")
- Message delivery latency: < 100ms (unchanged from PR #8)
- Firestore write operations: Batched marking of multiple messages as read (max 500 per batch)
- App load time: < 2-3 seconds (no degradation from read receipts)
- UI performance: smooth 60fps with read indicators (no jank)

**Quality:**
- 0 blocking bugs in read receipt detection or display
- All acceptance gates pass (see Section 12)
- Crash-free rate >99% (read receipt logic doesn't cause crashes)
- Read receipts don't interfere with message sending
- No duplicate Firestore writes (idempotent read marking)

---

## 5. Users & Stories

**Primary User:** Any user who has sent a message and wants to know if the recipient has seen it.

**User Stories:**

1. **As a user**, I want to see "Read" under my sent message when the recipient has opened the chat so that I know they've seen my message.

2. **As a user**, I want to see "Delivered" under my sent message when it's been successfully sent but not yet read so that I know the message reached the server.

3. **As a user in a group chat**, I want to see how many people have read my message (e.g., "Read by 3/5") so that I know who has seen it.

4. **As a user**, I want my read receipts to update automatically without any action from me so that the experience feels seamless.

5. **As a user**, I want received messages to be automatically marked as read when I open the chat so that senders know I've seen their messages.

6. **As a user**, I want read indicators to appear quickly so that the conversation feels live and responsive.

---

## 6. Experience Specification (UX)

### Entry Points and Flows

**Entry Point 1: Sent Message (Sender's View)**
- User sends a message in ChatView
- Message appears with "Sending..." status briefly
- Status changes to "Delivered" when Firestore confirms write
- Status changes to "Read" when recipient opens chat and views message
- Status updates appear below the message bubble, right-aligned

**Entry Point 2: Received Message (Recipient's View)**
- User opens ChatView containing unread messages
- Messages automatically marked as read when:
  - Chat view appears (`.onAppear`)
  - Messages scroll into view (visible on screen)
- Firestore `readBy` array updated to include recipient's user ID
- Sender sees status change to "Read" within 200ms

### Visual Behavior

**Read Receipt Indicators (Below Sent Messages):**

**1-on-1 Chat Indicators:**
- **"Sending..."** — Message being sent to Firestore (gray, italic)
- **"Delivered"** — Message written to Firestore, not yet read (gray)
- **"Read"** — Recipient opened chat and viewed message (blue accent color)

**Group Chat Indicators:**
- **"Sending..."** — Message being sent to Firestore (gray, italic)
- **"Delivered"** — Message written to Firestore, not yet read by anyone (gray)
- **"Read by 1/5"** — 1 out of 5 recipients have read it (gray)
- **"Read by 3/5"** — 3 out of 5 recipients have read it (gray)
- **"Read by all"** — All recipients have read it (blue accent color)

**Styling:**
- **Location:** Below the message bubble, right-aligned for sent messages
- **Typography:** `.caption` or `.footnote` size
- **Colors:**
  - Gray (`Color.secondary`) for "Delivered" and partial read states
  - Blue (`Color.accentColor`) for fully read states
  - Italic for "Sending..." transient state
- **Animations:** Subtle fade transition (0.2s) when status changes from "Delivered" → "Read"

**Received Messages (No Indicator):**
- Messages received from others do NOT show read indicators
- Only sent messages show status

### Marking Messages as Read

**Automatic Read Marking Logic:**

**Trigger 1: Chat View Opens**
- User navigates to ChatView
- On `.onAppear`, call `markMessagesAsRead()` for all visible messages
- Only marks messages where:
  - `senderID != currentUserID` (not my own messages)
  - `!readBy.contains(currentUserID)` (I haven't read it yet)

**Trigger 2: Messages Scroll Into View**
- As user scrolls through chat history
- Messages become visible on screen
- Mark those messages as read
- (For MVP: mark all on `.onAppear`, skip scroll-based for simplicity)

**Firestore Update:**
- Batch update `readBy` array for unread messages
- `messageRef.updateData(["readBy": FieldValue.arrayUnion([currentUserID])])`
- Idempotent operation (Firebase arrayUnion prevents duplicates)

### Loading States

**Not applicable** — Read receipts update silently in the background

### Empty States

**No messages:**
- No read indicators shown (no messages to read)

### Error States

**Firebase offline:**
- Read marking queued for when connection restored
- UI continues showing last known read status
- No error message shown (silent degradation)

**Permission denied:**
- Log error to console
- Don't crash or show error to user
- Read receipts simply won't update (acceptable graceful failure)

### Success States

**Read receipt updates:**
- Sender sees "Delivered" → "Read" transition smoothly with fade animation
- No toast/alert needed (silent feature)
- Status updates feel immediate (<200ms)

### Performance Targets (from shared-standards.md)

- **App load time**: < 2-3 seconds (read receipts don't delay app launch)
- **Read update latency**: < 200ms (view message → Firestore update → sender sees "Read")
- **Message delivery latency**: < 100ms (unchanged from PR #8)
- **Scrolling**: Smooth 60fps in chat view with read indicators (no jank)
- **Tap feedback**: < 50ms response time (read marking doesn't affect input responsiveness)
- **No UI blocking**: Read marking updates run on background thread (async)
- **Batch writes**: Max 500 messages marked read per batch operation

---

## 7. Functional Requirements (Must/Should)

### MUST Requirements

**MUST-1: Extend MessageService with Read Receipt Methods**
- Add `markMessagesAsRead(chatID: String, messageIDs: [String]) async throws` method
- Add `markChatMessagesAsRead(chatID: String) async throws` method for batch marking all unread
- Methods must:
  - Validate user is authenticated
  - Validate chatID is not empty
  - Validate user is a member of the chat
  - Update Firestore using `FieldValue.arrayUnion([userID])` on `readBy` field
  - Handle errors gracefully (offline, permissions, invalid data)
  - Use batch writes for multiple messages (max 500 per batch)

**Acceptance Gates:**
- [Gate] `markMessagesAsRead()` updates Firestore `readBy` array correctly
- [Gate] `markChatMessagesAsRead()` marks all unread messages in chat within 200ms
- [Gate] Methods are idempotent (calling twice doesn't duplicate user IDs)
- [Gate] Methods handle offline gracefully (queue for sync)
- [Gate] Methods validate user membership before marking

**MUST-2: Automatic Read Marking in ChatView**
- Update `ChatView.swift` to automatically mark messages as read
- Call `markChatMessagesAsRead()` in `.onAppear` lifecycle hook
- Only mark messages where:
  - `message.senderID != currentUserID` (not my own messages)
  - `!message.readBy.contains(currentUserID)` (I haven't read it yet)
- Run on background thread (async) to avoid blocking UI

**Acceptance Gates:**
- [Gate] Opening ChatView marks all unread messages as read within 200ms
- [Gate] Read marking doesn't block UI (runs async)
- [Gate] Read marking only affects other people's messages
- [Gate] Read marking is idempotent (no duplicate writes)

**MUST-3: Display Read Indicators Under Sent Messages**
- Create `MessageReadIndicatorView.swift` SwiftUI component
- Display below message bubble for sent messages only
- Show status based on message state:
  - `sendStatus == .sending` → "Sending..."
  - `readBy.isEmpty` → "Delivered"
  - 1-on-1 chat with recipient in `readBy` → "Read"
  - Group chat with partial reads → "Read by X/Y"
  - Group chat with all reads → "Read by all"
- Apply appropriate styling (color, size, alignment)

**Acceptance Gates:**
- [Gate] Sent messages show read indicator below bubble
- [Gate] Received messages do NOT show read indicator
- [Gate] Indicator updates when `readBy` array changes (via Firestore listener)
- [Gate] Indicator styling matches design spec (caption, gray/blue, right-aligned)
- [Gate] Smooth fade animation when status changes

**MUST-4: 1-on-1 Chat Read Logic**
- For 1-on-1 chats (members.count == 2):
  - "Delivered" when `readBy` is empty
  - "Read" when `readBy` contains the other user's ID
- Simple boolean logic: read or not read

**Acceptance Gates:**
- [Gate] Device A sends message to Device B → shows "Delivered"
- [Gate] Device B opens chat → Device A sees "Read" within 200ms
- [Gate] Indicator color changes from gray → blue on read
- [Gate] Multiple messages all update correctly

**MUST-5: Group Chat Read Logic**
- For group chats (members.count >= 3):
  - "Delivered" when `readBy` is empty
  - "Read by X/Y" when some (but not all) recipients have read
    - X = number of recipients who read (exclude sender)
    - Y = total recipients (exclude sender)
  - "Read by all" when all recipients have read
- Calculate recipients as `members - senderID - currentUserID`

**Acceptance Gates:**
- [Gate] Group message shows "Delivered" initially
- [Gate] First recipient reads → shows "Read by 1/4" (if 5 total members)
- [Gate] All recipients read → shows "Read by all" in blue
- [Gate] Indicator updates in real-time as each user reads

**MUST-6: Real-Time Read Status Updates**
- Leverage existing `observeMessages()` Firestore listener from PR #8
- When message documents update with new `readBy` values:
  - SwiftUI @State messages array updates automatically
  - MessageReadIndicatorView re-renders with new status
  - No additional listeners needed (piggyback on existing)

**Acceptance Gates:**
- [Gate] User A sends message → sees "Delivered"
- [Gate] User B opens chat → User A sees "Read" within 200ms (via existing listener)
- [Gate] No additional Firebase listeners added (reuse observeMessages)
- [Gate] Updates trigger smooth UI re-render (no jank)

**MUST-7: Handle Edge Cases**
- Message sent to user who is offline:
  - Shows "Delivered" until they come online and open chat
- Message sent in group where some users deleted the app:
  - Shows "Read by X/Y" for active users only
- User reads message then deletes account:
  - `readBy` array still contains their ID (acceptable)
- Concurrent reads from multiple users:
  - Firebase `arrayUnion` handles this atomically

**Acceptance Gates:**
- [Gate] Offline user → message stays "Delivered" until they open chat online
- [Gate] Deleted users don't break read count logic
- [Gate] Concurrent reads don't cause race conditions or lost updates
- [Gate] Edge cases logged but don't crash app

### SHOULD Requirements

**SHOULD-1: Batch Read Marking for Performance**
- When marking multiple messages as read, use Firestore batch writes
- Max 500 messages per batch (Firestore limit)
- If >500 unread messages, chunk into multiple batches

**Acceptance Gates:**
- [Gate] Marking 100 messages uses 1 batch write (not 100 individual writes)
- [Gate] Marking 600 messages uses 2 batch writes (500 + 100)
- [Gate] Batch writes complete within 200ms total

**SHOULD-2: Optimize Read Marking to Prevent Redundant Writes**
- Before marking messages as read, filter to only unread messages
- Skip Firestore write if no messages need marking
- Prevents unnecessary Firestore operations

**Acceptance Gates:**
- [Gate] Opening chat with all read messages → no Firestore write
- [Gate] Opening chat with 5 unread messages → only those 5 updated

**SHOULD-3: Add Loading State for Read Indicator (Optional)**
- Show subtle loading spinner during "Sending..." state
- Remove spinner when "Delivered"
- (Optional: may skip for simplicity, just use text)

**Acceptance Gates:**
- [Gate] "Sending..." shows italic gray text
- [Gate] Smooth transition to "Delivered" when confirmed

---

## 8. Data Model

Reference models from PR #5. The `readBy` array is already part of the Message model.

### Existing Message Model (PR #5)

```swift
struct Message: Identifiable, Codable {
    let id: String                    // UUID
    let text: String                  // 1-10,000 chars
    let senderID: String              // User ID who sent message
    let timestamp: Date               // Server timestamp
    var readBy: [String]              // Array of user IDs who have read
    var sendStatus: MessageSendStatus? // Client-side only (sending/delivered/failed)
}
```

### Firestore Message Document

**Collection**: `chats/{chatID}/messages/{messageID}`

```swift
{
  "id": "abc123...",                    // String
  "text": "Hello!",                     // String
  "senderID": "userID_A",               // String
  "timestamp": Timestamp,               // FieldValue.serverTimestamp()
  "readBy": ["userID_B", "userID_C"]    // Array<String> — Updated in this PR
}
```

### Read Receipt Update Operation

**Firestore Update (Single Message):**
```swift
// Mark message as read by current user
messageRef.updateData([
    "readBy": FieldValue.arrayUnion([currentUserID])
])
```

**Firestore Batch Update (Multiple Messages):**
```swift
let batch = db.batch()
for messageID in messageIDs {
    let messageRef = db.collection("chats").document(chatID)
                       .collection("messages").document(messageID)
    batch.updateData(["readBy": FieldValue.arrayUnion([currentUserID])], forDocument: messageRef)
}
try await batch.commit()
```

### Data Invariants

- `readBy` array NEVER contains sender's ID (you can't "read" your own message)
- `readBy` array NEVER contains duplicate user IDs (ensured by `arrayUnion`)
- `readBy` array only grows (never shrinks) — no "unread" operation
- `readBy` array only contains valid user IDs from chat members

---

## 9. API / Service Contracts

Reference examples in `Psst/agents/shared-standards.md`.

### MessageService Extensions

```swift
class MessageService {
    
    // MARK: - Read Receipts
    
    /// Marks specific messages as read by the current user
    /// - Parameters:
    ///   - chatID: The chat containing the messages
    ///   - messageIDs: Array of message IDs to mark as read
    /// - Throws: MessageError if validation fails or Firestore write fails
    func markMessagesAsRead(chatID: String, messageIDs: [String]) async throws
    
    /// Marks all unread messages in a chat as read by the current user
    /// - Parameter chatID: The chat to mark messages in
    /// - Throws: MessageError if validation fails or Firestore write fails
    func markChatMessagesAsRead(chatID: String) async throws
    
    // Existing methods from PR #8 (unchanged)
    func sendMessage(chatID: String, text: String, ...) async throws -> String
    func observeMessages(chatID: String, completion: @escaping ([Message]) -> Void) -> ListenerRegistration
}
```

### Method Specifications

**`markMessagesAsRead(chatID:messageIDs:)`**
- **Pre-conditions:**
  - User authenticated (Auth.auth().currentUser != nil)
  - chatID is not empty
  - messageIDs array is not empty
  - User is a member of the chat
- **Post-conditions:**
  - Each message document's `readBy` array includes current user ID
  - Firestore batch write committed successfully
  - Changes propagate to all listeners within 200ms
- **Error handling:**
  - `.notAuthenticated` if no user logged in
  - `.invalidChatID` if chatID empty
  - `.firestoreError` if write fails
  - `.offline` if no network (queued for later)

**`markChatMessagesAsRead(chatID:)`**
- **Pre-conditions:**
  - User authenticated
  - chatID is not empty
  - User is a member of the chat
- **Post-conditions:**
  - All unread messages (where `!readBy.contains(currentUserID)`) are updated
  - Messages where user is sender are skipped
  - Batch write committed successfully
- **Error handling:**
  - Same as `markMessagesAsRead`

---

## 10. UI Components to Create/Modify

List SwiftUI views/files with one-line purpose each.

### New Files

- `Views/Components/MessageReadIndicatorView.swift` — Displays read receipt status below message bubbles

### Modified Files

- `Services/MessageService.swift` — Add `markMessagesAsRead()` and `markChatMessagesAsRead()` methods
- `Views/ChatView.swift` — Add `.onAppear` logic to mark messages as read automatically
- `Views/Components/MessageRow.swift` — Integrate MessageReadIndicatorView below sent message bubbles
- `Models/Message.swift` — (No changes needed, readBy already exists)

---

## 11. Integration Points

- **Firebase Firestore** — Update `readBy` array using `FieldValue.arrayUnion`
- **Firebase Authentication** — Get current user ID for read marking
- **Existing MessageService** — Extend with read receipt methods
- **Existing observeMessages listener** — Reuse for real-time read status updates
- **State management (SwiftUI)** — @State messages array automatically updates when Firestore changes

---

## 12. Testing Plan & Acceptance Gates

Define BEFORE implementation. Use checkboxes.

**Current**: Manual testing validation (see `Psst/agents/shared-standards.md`)  
**Future**: Automated testing recommendations in `Psst/docs/testing-strategy.md`

### Configuration Testing

- [ ] Firebase Firestore connection established
- [ ] Firebase Authentication works
- [ ] Current user ID retrieved correctly
- [ ] Firestore rules allow `readBy` array updates

### Happy Path Testing

**1-on-1 Chat:**
- [ ] User A sends message to User B → shows "Delivered"
- [ ] User B opens chat → User A sees "Read" within 200ms
- [ ] Read indicator color changes from gray to blue
- [ ] Multiple messages all update correctly

**Group Chat:**
- [ ] User A sends message to group (5 members total)
- [ ] Message shows "Delivered" initially
- [ ] User B opens chat → User A sees "Read by 1/4"
- [ ] User C opens chat → User A sees "Read by 2/4"
- [ ] All 4 recipients read → User A sees "Read by all" in blue

**Gate: 1-on-1 read receipt works end-to-end**
**Gate: Group read receipt shows correct counts**
**Gate: Read status updates in real-time (<200ms)**

### Edge Cases Testing

- [ ] **Offline recipient:** Message stays "Delivered" until recipient comes online and opens chat
  - Gate: Offline user doesn't prevent indicator from working
  
- [ ] **Multiple chats:** Opening Chat A marks Chat A messages as read, doesn't affect Chat B
  - Gate: Read marking is scoped to correct chat
  
- [ ] **Re-opening chat:** Opening chat again doesn't re-mark already read messages
  - Gate: Idempotent behavior (no duplicate Firestore writes)
  
- [ ] **Own messages:** Sent messages never marked as "read by self"
  - Gate: readBy array never contains sender's ID
  
- [ ] **Large chat history:** Chat with 1000+ messages marks all as read without freezing UI
  - Gate: Batch writes handle large message counts efficiently
  
- [ ] **Concurrent reads:** 3 users open group chat simultaneously
  - Gate: All 3 read statuses recorded correctly (no race conditions)

### Multi-Device Testing

- [ ] Device A and Device B logged in as different users
- [ ] Device A sends message
- [ ] Device B opens chat → Device A sees "Read" on same screen within 200ms
- [ ] Real-time sync works across 3+ devices
- [ ] Read status persists across app restarts

**Gate: Real-time read status sync works across 2+ devices**

### Offline Behavior Testing

- [ ] Device B is offline
- [ ] Device A sends message → shows "Delivered"
- [ ] Device B comes online and opens chat
- [ ] Device A sees "Read" within 200ms of Device B coming online
- [ ] Device A goes offline → cannot mark messages as read (queued)

**Gate: Offline scenarios handled gracefully**

### Visual States Verification

- [ ] "Sending..." shown briefly when sending (gray, italic)
- [ ] "Delivered" shown when message written to Firestore (gray)
- [ ] "Read" shown when recipient reads (blue)
- [ ] "Read by X/Y" shown in group chats (gray)
- [ ] "Read by all" shown when all read (blue)
- [ ] Smooth fade animation when status changes
- [ ] Indicator right-aligned below message bubble
- [ ] Received messages do NOT show indicator

**Gate: All visual states render correctly**

### Performance Testing

- [ ] Read marking completes within 200ms (open chat → Firestore updated)
- [ ] Sender sees "Read" within 200ms of recipient opening chat
- [ ] Marking 100 messages as read completes within 200ms
- [ ] No UI jank or freezing when marking messages as read
- [ ] Scrolling remains smooth 60fps with read indicators
- [ ] App load time unchanged (<2-3 seconds)

**Gate: All performance targets met (see shared-standards.md)**

### Error Handling Testing

- [ ] **Network error:** Read marking fails gracefully (silent, no crash)
- [ ] **Permission denied:** Logged to console, no UI error shown
- [ ] **Invalid chatID:** Method throws appropriate error
- [ ] **Not authenticated:** Method throws `.notAuthenticated` error
- [ ] **No console errors:** Clean console output during normal operation

**Gate: All error cases handled gracefully**

---

## 13. Definition of Done

See standards in `Psst/agents/shared-standards.md`:

- [ ] `markMessagesAsRead()` and `markChatMessagesAsRead()` methods implemented in MessageService
- [ ] `MessageReadIndicatorView` component created with proper styling
- [ ] ChatView automatically marks messages as read on `.onAppear`
- [ ] MessageRow displays read indicator below sent message bubbles
- [ ] 1-on-1 chat read logic works correctly (Delivered → Read)
- [ ] Group chat read logic works correctly (Read by X/Y, Read by all)
- [ ] Real-time read status updates verified across 2+ devices (<200ms)
- [ ] Offline persistence tested (read marking queues when offline)
- [ ] All acceptance gates pass (configuration, happy path, edge cases, multi-device, offline, visual, performance, errors)
- [ ] Manual testing completed per shared-standards.md
- [ ] Code follows Swift best practices (typed, documented, no force unwraps)
- [ ] No console errors during testing
- [ ] Performance targets met (read marking <200ms, no UI jank)
- [ ] Batch writes implemented for efficiency (max 500 per batch)

---

## 14. Risks & Mitigations

**Risk: Read marking causes performance issues with large chat histories (1000+ messages)**
- **Mitigation:** Use batch writes (max 500/batch), filter to only unread messages, run async on background thread

**Risk: Race condition if multiple users mark same message as read simultaneously**
- **Mitigation:** Firebase `arrayUnion` is atomic and prevents duplicate IDs automatically

**Risk: Read receipts don't update in real-time, feel laggy**
- **Mitigation:** Reuse existing `observeMessages()` listener, target <200ms latency, test across devices

**Risk: User privacy concerns about read receipts**
- **Mitigation:** Always-on for MVP, document future "disable read receipts" setting in backlog

**Risk: Firestore costs increase due to read marking writes**
- **Mitigation:** Batch writes, skip already-read messages, idempotent operations prevent duplicate writes

**Risk: Offline read marking fails silently**
- **Mitigation:** Log errors, queue for sync when online (handled by Firestore offline persistence)

---

## 15. Rollout & Telemetry

**Feature Flag:** No (always on for MVP)

**Metrics to Monitor:**
- **Usage:**
  - Number of messages marked as read per day
  - Percentage of messages that get read within 1 hour, 1 day, 1 week
  - Average time from message send to read
  
- **Errors:**
  - Firestore write errors for `readBy` updates
  - Authentication errors when marking as read
  - Offline queue failures
  
- **Performance:**
  - Read marking latency (time from chat open to Firestore update)
  - Batch write sizes and frequency
  - Real-time sync latency (send to read status update visible)

**Manual Validation Steps:**
- Test 1-on-1 read receipts across 2 devices
- Test group read receipts across 3+ devices
- Test offline scenarios (mark as read when offline, sync when online)
- Test performance with large chat histories (100+ messages)
- Verify visual styling matches design spec

---

## 16. Open Questions

- **Q1:** Should we show exact read timestamps (e.g., "Read at 3:45 PM") in addition to "Read" indicator?
  - **Decision:** Not for MVP. Simple "Read" indicator is sufficient. Defer timestamps to future enhancement.

- **Q2:** Should we allow users to disable read receipts for privacy?
  - **Decision:** Not for MVP. Always-on simplifies implementation. Add to Phase 5 backlog.

- **Q3:** Should we differentiate between "delivered to device" and "delivered to server"?
  - **Decision:** Not for MVP. Single "Delivered" state simplifies UX. Firestore delivery = "Delivered".

- **Q4:** Should we mark messages as read when they scroll into view, or just when chat opens?
  - **Decision:** Mark all on chat open (`.onAppear`) for MVP simplicity. Defer scroll-based marking to future.

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future:

- [ ] **Privacy setting to disable read receipts** (Phase 5)
- [ ] **Precise read timestamps** ("Read at 3:45 PM") (Phase 5)
- [ ] **Scroll-based read marking** (mark only visible messages) (Phase 5)
- [ ] **"Delivered to device" vs "delivered to server" distinction** (Phase 5)
- [ ] **Per-recipient read timestamps in group chats** (Phase 5)
- [ ] **Read receipts in conversation list preview** (Phase 5)
- [ ] **Read receipts for media messages** (Phase 5)
- [ ] **"Seen by X users" with profile pictures** (Phase 5)

---

## Preflight Questionnaire

Answer these to drive vertical slice and acceptance gates:

1. **Smallest end-to-end user outcome for this PR?**
   - User sends message, recipient opens chat, sender sees "Read" indicator within 200ms

2. **Primary user and critical action?**
   - Sender wants to know if recipient has seen their message; recipient automatically marks messages as read when viewing

3. **Must-have vs nice-to-have?**
   - **Must:** Automatic read marking, visual indicators, 1-on-1 and group chat support, real-time updates
   - **Nice:** Disable read receipts setting, precise timestamps, scroll-based marking

4. **Real-time requirements?** (see shared-standards.md)
   - Read status updates must sync across devices in <200ms
   - Firestore listener automatically propagates `readBy` changes

5. **Performance constraints?** (see shared-standards.md)
   - Read marking: <200ms from chat open to Firestore update
   - Batch writes: max 500 messages per batch
   - No UI blocking: all operations async

6. **Error/edge cases to handle?**
   - Offline read marking (queue for sync)
   - Large chat histories (batch writes)
   - Concurrent reads (atomic arrayUnion)
   - Deleted users (ignore in read count)

7. **Data model changes?**
   - No changes — `readBy` array already exists in Message model (PR #5)
   - Update existing message documents with `FieldValue.arrayUnion`

8. **Service APIs required?**
   - `markMessagesAsRead(chatID:messageIDs:)` — Mark specific messages
   - `markChatMessagesAsRead(chatID:)` — Mark all unread in chat

9. **UI entry points and states?**
   - Entry: ChatView `.onAppear` triggers read marking
   - States: "Sending...", "Delivered", "Read", "Read by X/Y", "Read by all"

10. **Security/permissions implications?**
    - Firestore rules must allow users to update `readBy` array on messages
    - Only chat members can mark messages as read
    - Users cannot mark their own sent messages as read

11. **Dependencies or blocking integrations?**
    - Depends on PR #8 (MessageService and observeMessages listener)
    - Depends on PR #5 (Message model with readBy field)
    - Works with PR #11 (group chat support)

12. **Rollout strategy and metrics?**
    - Always on for MVP, no feature flag
    - Monitor: read marking latency, Firestore write errors, batch sizes
    - Manual testing across 2+ devices for validation

13. **What is explicitly out of scope?**
    - Privacy settings to disable read receipts
    - Precise read timestamps
    - Scroll-based read marking
    - Media message read receipts

---

## Authoring Notes

- Write Test Plan before coding (Section 12 completed)
- Favor vertical slice that ships standalone (read receipts work independently)
- Keep service layer deterministic (`markMessagesAsRead` has clear inputs/outputs)
- SwiftUI views are thin wrappers (MessageReadIndicatorView just displays state)
- Test offline/online thoroughly (queue read marking when offline)
- Reference `Psst/agents/shared-standards.md` throughout (performance, testing, patterns)
- Reuse existing Firestore listener from PR #8 (no new listeners needed)
- Leverage Firebase `arrayUnion` for atomic, idempotent updates

