# PRD: Optimistic UI and Offline Persistence

**Feature**: Optimistic UI and Offline Persistence

**Version**: 1.0

**Status**: Ready for Development

**Agent**: Pam

**Target Release**: Phase 2 - 1-on-1 Chat

**Links**: [PR Brief #10](../pr-briefs.md#pr-10-optimistic-ui-and-offline-persistence), [TODO](../todos/pr-10-todo.md), [Architecture](../architecture.md), [PR #8 PRD](./pr-8-prd.md)

---

## 1. Summary

Implement optimistic UI pattern for instant message feedback and enable full offline support through Firestore persistence, message queueing, and network state monitoring. Users will see messages appear immediately with "sending" status, be able to view previously loaded content offline, and have messages automatically sync when reconnected.

---

## 2. Problem & Goals

**Problem**: Currently, messages don't appear in the UI until Firestore confirms the write, creating perceived latency and poor user experience. Additionally, users can't access their message history when offline, and there's no indication of network state or failed sends.

**Why now**: With real-time messaging working (PR #8), we need to enhance the user experience to feel instant and reliable. This is critical for user satisfaction and competitive parity with modern messaging apps. Users expect immediate feedback and offline functionality as standard features.

**Goals**:
  - [ ] G1 — Messages appear in UI instantly when sent (before Firestore confirms) with "sending" indicator
  - [ ] G2 — Enable Firestore offline persistence so users can view previously loaded messages without internet
  - [ ] G3 — Messages sent while offline queue locally and automatically sync when connection restored
  - [ ] G4 — Display network state indicators (online/offline mode) so users understand connectivity status
  - [ ] G5 — Handle network transitions gracefully with proper error states and retry logic

---

## 3. Non-Goals / Out of Scope

- [ ] Advanced retry logic with exponential backoff (basic automatic retry only)
- [ ] Conflict resolution for concurrent edits (messages are append-only in this PR)
- [ ] Message editing or deletion while offline (future)
- [ ] Offline profile picture uploads (future)
- [ ] Custom offline storage beyond Firestore cache (using Firestore's built-in persistence)
- [ ] Offline indicators for other users (PR #12 handles presence)
- [ ] Push notifications while offline (handled by FCM automatically)
- [ ] Automated unit/UI tests (deferred to backlog per testing-strategy.md)
- [ ] Manual sync controls (sync happens automatically)
- [ ] Storage quota management for offline cache (using Firestore defaults)

---

## 4. Success Metrics

Reference `Psst/agents/shared-standards.md` for metric templates:

**User-visible**:
- **Perceived send latency**: 0ms (message appears instantly in UI)
- **Offline message delivery**: 100% of queued messages send on reconnect
- **Flow completion**: User can read all previously loaded messages offline
- **Network state awareness**: User sees clear online/offline indicator

**System** (see shared-standards.md):
- **Optimistic UI update**: < 10ms from send button tap to UI update
- **Firestore persistence enabled**: isPersistenceEnabled = true
- **Offline cache size**: Stores minimum 100+ messages per chat
- **Sync on reconnect**: < 2 seconds to flush queue after connection restored
- **No UI blocking**: All operations remain async

**Quality**:
- 0 blocking bugs during manual testing
- All acceptance gates pass
- Crash-free rate >99%
- No data loss during offline/online transitions
- No duplicate messages from queue

---

## 5. Users & Stories

- As a **user**, I want to **see my message appear immediately after tapping send** so that **the app feels responsive and instant**.

- As a **user with poor network**, I want to **continue using the app and see my old messages** so that **I'm not blocked by connectivity issues**.

- As a **user composing offline**, I want to **send messages that queue and deliver automatically when I reconnect** so that **I don't have to remember to resend or worry about message loss**.

- As a **user**, I want to **see if I'm online or offline** so that **I know whether my messages are sending in real-time or queued**.

- As a **user**, I want to **see the status of my sent messages (sending/delivered/failed)** so that **I have confidence my messages are being delivered**.

- As a **developer**, I want **Firestore to handle offline caching automatically** so that **I don't have to build custom storage logic**.

---

## 6. Experience Specification (UX)

**Entry Points**:
- User opens ChatView → Sees previously loaded messages even offline
- User sends message → Message appears instantly with "sending" indicator
- Network disconnects → User sees offline indicator in navigation bar
- Network reconnects → Queued messages sync automatically, indicator updates

**Visual Behavior**:

**Optimistic UI Flow**:
1. User types message and taps send
2. Message immediately appears in message list with gray "Sending..." text
3. Message animates into position smoothly
4. After Firestore confirms (~50-100ms), "Sending..." changes to timestamp
5. If send fails, message shows red "Failed - Tap to retry" indicator

**Offline Mode Flow**:
1. User's network disconnects (airplane mode, no WiFi, etc.)
2. Small banner appears below navigation bar: "Offline - Messages will send when reconnected"
3. Message list shows all previously loaded messages from cache
4. User can still scroll, read, and compose messages
5. Sent messages show **yellow "Queued - Will send when online" badge**
6. User can tap queued message to see options: "Cancel" or "Info" (explains auto-retry)
7. When network reconnects, banner shows "Reconnecting..." then disappears
8. Queued messages automatically sync with gray "Sending..." then timestamp

**Loading/Error States**:
- **Loading**: Initial app load shows skeleton screen while cache loads
- **Sending (Online)**: Gray "Sending..." text below message
- **Queued (Offline)**: Yellow badge with "Queued - Will send when online" - tappable for options
- **Error - Send Failed Online**: Red "Failed - Tap to retry" with red icon
- **Error - Offline Mode**: Banner shows "Offline - Messages will send when reconnected"
- **Success - Message Sent**: Timestamp appears, indicator removed
- **Success - Reconnected**: Green "Connected" banner appears briefly then fades

**Performance Targets** (see shared-standards.md):
- Optimistic UI update: < 10ms (instant perceived feedback)
- Offline cache load: < 500ms for 100+ messages
- Queue processing on reconnect: < 2 seconds for 10 queued messages
- No UI thread blocking during sync

---

## 7. Functional Requirements (Must/Should)

**MUST - Optimistic UI**:

- MUST implement MessageSendStatus enum
  - [Gate] Enum values: sending, delivered, failed
  - [Gate] Message model extended to include sendStatus field
  - [Gate] UI displays appropriate indicator for each status

- MUST add message to UI immediately on send
  - [Gate] User taps send → Message appears in UI within 10ms
  - [Gate] Message displays with gray "Sending..." indicator (if online)
  - [Gate] Message displays with yellow "Queued" badge (if offline)
  - [Gate] Message positioned at bottom of message list
  - [Gate] Scroll animates to new message

- MUST update message status after Firestore confirmation
  - [Gate] Firestore write succeeds → Status changes to delivered
  - [Gate] Timestamp replaces "Sending..." text
  - [Gate] Transition animates smoothly (fade)
  - [Gate] ID remains consistent (no duplicate messages)

- MUST handle send failures gracefully
  - [Gate] Network error → Status changes to failed
  - [Gate] Message shows "Failed - Tap to retry" with red icon
  - [Gate] User can tap message to retry
  - [Gate] Successful retry updates to delivered
  - [Gate] Failed messages persist in UI until retry succeeds

**MUST - Offline Persistence**:

- MUST enable Firestore offline persistence
  - [Gate] FirebaseService initializes with isPersistenceEnabled = true
  - [Gate] Setting applied before any Firestore queries
  - [Gate] No errors in console about persistence configuration

- MUST load cached messages offline
  - [Gate] User opens app offline → Previously loaded messages display
  - [Gate] Messages load from cache within 500ms
  - [Gate] No network required to view cached conversations
  - [Gate] Empty chats (never loaded) show empty state, not error

- MUST cache messages automatically
  - [Gate] Messages loaded online automatically cached for offline access
  - [Gate] Cache persists across app restarts
  - [Gate] Minimum 100+ messages cached per chat
  - [Gate] Firestore manages cache eviction automatically

**MUST - Message Queueing**:

- MUST queue messages sent while offline
  - [Gate] User sends message offline → Message shows yellow "Queued" badge
  - [Gate] Message appears in UI immediately with queue indicator
  - [Gate] Queued message tappable to show options (Cancel, Info)
  - [Gate] Queue persisted locally (survives app restart)
  - [Gate] Queue order preserved (FIFO)

- MUST auto-sync queued messages on reconnect
  - [Gate] Network reconnects → Queue processes automatically
  - [Gate] All queued messages send within 2 seconds
  - [Gate] Messages transition from "Queued" → "Sending" → "Delivered"
  - [Gate] Failed queue items show error, allow retry
  - [Gate] No duplicate messages (deduplication by message ID)

**MUST - Network State Monitoring**:

- MUST detect network state changes
  - [Gate] Network reachability monitored using NWPathMonitor
  - [Gate] Online/offline state tracked in real-time
  - [Gate] State changes trigger UI updates
  - [Gate] Works for WiFi, cellular, airplane mode

- MUST display network state indicator
  - [Gate] Offline: Banner shows "Offline - Messages will send when reconnected"
  - [Gate] Reconnecting: Banner shows "Reconnecting..." 
  - [Gate] Online: Green "Connected" banner shows briefly then fades
  - [Gate] Banner appears below navigation bar, doesn't cover content
  - [Gate] Banner animates smoothly (slide down/up)

**SHOULD**:

- SHOULD implement user actions for queued messages
  - [Gate] User taps queued message → Sheet shows options
  - [Gate] "Cancel" option removes message from queue
  - [Gate] "Info" option explains: "This message will send automatically when you're back online"
  - [Gate] Canceled messages removed from UI and queue

- SHOULD implement exponential backoff for retries
  - [Gate] First retry: immediate
  - [Gate] Second retry: 1 second delay
  - [Gate] Third retry: 3 seconds delay
  - [Gate] Max 3 retry attempts, then mark failed

- SHOULD provide queue status information
  - [Gate] Show count of queued messages in offline banner
  - [Gate] Example: "Offline - 3 messages queued"

- SHOULD handle edge cases gracefully
  - [Gate] App killed while queue pending → Queue restores on relaunch
  - [Gate] Network flickers (on/off/on rapidly) → Queue only processes once
  - [Gate] Large queue (50+ messages) → Process in batches without blocking UI

**Acceptance Gates Summary**:
- [Gate] User sends message online → Appears instantly with "Sending...", updates to timestamp in <100ms
- [Gate] User sends message offline → Appears instantly with "Queued", syncs on reconnect
- [Gate] User goes offline → All previously loaded messages viewable from cache
- [Gate] User goes offline and back online → Banner shows state changes, queued messages sync automatically
- [Gate] Message send fails → Shows "Failed - Tap to retry", user can retry
- [Gate] App restarts offline → Cached messages load, queued messages restore
- [Gate] No duplicate messages from queue processing

---

## 8. Data Model

### Message Model Extension

**Update Message.swift** to include optimistic UI status:

```swift
/// Message model representing individual messages within a chat
struct Message: Identifiable, Codable, Equatable {
    /// Existing fields
    let id: String
    let text: String
    let senderID: String
    let timestamp: Date
    var readBy: [String]
    
    /// NEW: Send status for optimistic UI
    /// Not persisted to Firestore - client-side only
    var sendStatus: MessageSendStatus?
    
    // CodingKeys to exclude sendStatus from Firestore serialization
    enum CodingKeys: String, CodingKey {
        case id, text, senderID, timestamp, readBy
    }
    
    /// Initialize with optional send status
    init(id: String, text: String, senderID: String,
         timestamp: Date = Date(), readBy: [String] = [],
         sendStatus: MessageSendStatus? = nil) {
        self.id = id
        self.text = text
        self.senderID = senderID
        self.timestamp = timestamp
        self.readBy = readBy
        self.sendStatus = sendStatus
    }
}

/// Message send status for optimistic UI
enum MessageSendStatus: String, Codable {
    case sending    // Message being sent to Firestore
    case queued     // Message queued for offline sync
    case delivered  // Message confirmed by Firestore
    case failed     // Message send failed
}
```

### Firestore Configuration

**FirebaseService.swift** must enable persistence:

```swift
class FirebaseService {
    static func configure() {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Enable Firestore offline persistence
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        Firestore.firestore().settings = settings
    }
}
```

### Message Queue Model

**New: MessageQueue.swift** for offline queue management:

```swift
/// Persistent queue for messages sent while offline
struct QueuedMessage: Identifiable, Codable {
    let id: String           // Same as Message.id
    let chatID: String       // Chat to send to
    let text: String         // Message text
    let timestamp: Date      // When queued
    var retryCount: Int      // Number of retry attempts
    
    /// Convert to Message for UI display
    func toMessage(senderID: String) -> Message {
        Message(
            id: id,
            text: text,
            senderID: senderID,
            timestamp: timestamp,
            sendStatus: .queued
        )
    }
}
```

**Queue Storage**:
- Stored in UserDefaults as JSON array
- Key: "com.psst.messageQueue"
- Persists across app restarts
- Cleared after successful send

### Validation Rules

**No changes to Firestore validation** - sendStatus is client-side only and not persisted to Firestore.

---

## 9. API / Service Contracts

### MessageService.swift Updates

**Update sendMessage() for optimistic UI**:

```swift
/// Sends a message with optimistic UI support
/// - Parameters:
///   - chatID: The ID of the chat to send message to
///   - text: The message text (will be trimmed)
///   - optimisticCompletion: Called immediately with optimistic message (before Firestore)
/// - Returns: The ID of the created message
/// - Throws: MessageError if validation fails or Firestore write fails
func sendMessage(
    chatID: String, 
    text: String,
    optimisticCompletion: ((Message) -> Void)? = nil
) async throws -> String {
    // Validate inputs
    let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
    try validateMessageText(trimmedText)
    let senderID = try getCurrentUserID()
    let messageID = UUID().uuidString
    
    // Create optimistic message
    let optimisticMessage = Message(
        id: messageID,
        text: trimmedText,
        senderID: senderID,
        timestamp: Date(),
        readBy: [],
        sendStatus: .sending
    )
    
    // Call optimistic completion immediately (before Firestore)
    optimisticCompletion?(optimisticMessage)
    
    // Check network state
    if !NetworkMonitor.shared.isConnected {
        // Queue message for offline sync
        try MessageQueue.shared.enqueue(
            QueuedMessage(
                id: messageID,
                chatID: chatID,
                text: trimmedText,
                timestamp: Date(),
                retryCount: 0
            )
        )
        throw MessageError.offline
    }
    
    // Send to Firestore (existing logic)
    do {
        let messageRef = db
            .collection("chats")
            .document(chatID)
            .collection("messages")
            .document(messageID)
        
        try await messageRef.setData(optimisticMessage.toDictionary())
        try await updateChatLastMessage(chatID: chatID, text: trimmedText)
        
        return messageID
    } catch {
        throw MessageError.firestoreError(error)
    }
}
```

### New: NetworkMonitor.swift

**Network reachability monitoring service**:

```swift
import Network
import Combine

/// Monitors network connectivity state
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    @Published var isConnected: Bool = true
    @Published var connectionType: NWInterface.InterfaceType?
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    private init() {
        startMonitoring()
    }
    
    /// Start monitoring network state
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = path.availableInterfaces.first?.type
            }
        }
        monitor.start(queue: queue)
    }
    
    /// Stop monitoring
    func stopMonitoring() {
        monitor.cancel()
    }
}
```

### New: MessageQueue.swift

**Offline message queue manager**:

```swift
import Foundation

/// Manages queue of messages sent while offline
class MessageQueue {
    static let shared = MessageQueue()
    
    private let queueKey = "com.psst.messageQueue"
    private let messageService = MessageService()
    
    private init() {}
    
    /// Add message to queue
    func enqueue(_ message: QueuedMessage) throws {
        var queue = getQueue()
        queue.append(message)
        saveQueue(queue)
    }
    
    /// Remove message from queue
    func dequeue(id: String) {
        var queue = getQueue()
        queue.removeAll { $0.id == id }
        saveQueue(queue)
    }
    
    /// Get all queued messages for a chat
    func getQueuedMessages(for chatID: String) -> [QueuedMessage] {
        return getQueue().filter { $0.chatID == chatID }
    }
    
    /// Process entire queue (send all queued messages)
    func processQueue() async {
        let queue = getQueue()
        
        for queuedMessage in queue {
            do {
                // Attempt to send
                _ = try await messageService.sendMessage(
                    chatID: queuedMessage.chatID,
                    text: queuedMessage.text
                )
                
                // Success - remove from queue
                dequeue(id: queuedMessage.id)
            } catch {
                print("Failed to send queued message \(queuedMessage.id): \(error)")
                
                // Update retry count
                var updated = queuedMessage
                updated.retryCount += 1
                
                if updated.retryCount >= 3 {
                    // Max retries - mark as failed
                    dequeue(id: queuedMessage.id)
                    print("Message \(queuedMessage.id) failed after 3 retries")
                } else {
                    // Update retry count
                    var queue = getQueue()
                    if let index = queue.firstIndex(where: { $0.id == queuedMessage.id }) {
                        queue[index] = updated
                        saveQueue(queue)
                    }
                }
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func getQueue() -> [QueuedMessage] {
        guard let data = UserDefaults.standard.data(forKey: queueKey),
              let queue = try? JSONDecoder().decode([QueuedMessage].self, from: data) else {
            return []
        }
        return queue
    }
    
    private func saveQueue(_ queue: [QueuedMessage]) {
        if let data = try? JSONEncoder().encode(queue) {
            UserDefaults.standard.set(data, forKey: queueKey)
        }
    }
}
```

### MessageError Updates

**Add offline error case**:

```swift
enum MessageError: LocalizedError {
    case notAuthenticated
    case emptyText
    case textTooLong
    case invalidChatID
    case offline           // NEW: Message queued for offline send
    case firestoreError(Error)
    
    var errorDescription: String? {
        switch self {
        case .offline:
            return "Message queued - will send when online"
        // ... existing cases
        }
    }
}
```

---

## 10. UI Components to Create/Modify

**Create**:
- `Services/NetworkMonitor.swift` — Network reachability monitoring (NEW)
- `Services/MessageQueue.swift` — Offline message queue management (NEW)
- `Views/Components/NetworkStatusBanner.swift` — Online/offline indicator banner (NEW)
- `Views/Components/MessageStatusIndicator.swift` — Sending/delivered/failed status view (NEW)

**Modify**:
- `Models/Message.swift` — Add sendStatus field and MessageSendStatus enum
- `Services/FirebaseService.swift` — Enable Firestore offline persistence
- `Services/MessageService.swift` — Add optimistic UI support and offline queueing
- `Views/ChatList/ChatView.swift` — Integrate optimistic UI, network monitoring, and queue processing
- `Views/ChatList/MessageRow.swift` — Display message status indicators
- `App/PsstApp.swift` — Initialize network monitoring on app launch

**No changes to**:
- `Models/Chat.swift` — No changes needed
- `Views/ChatList/MessageInputView.swift` — No changes needed (ChatView handles send logic)

---

## 11. Integration Points

**Firebase Services**:
- **Firestore Offline Persistence**: Enable isPersistenceEnabled = true
- **Firestore Cache**: Automatically caches queries for offline access
- **Firestore Snapshot Listeners**: Work seamlessly offline with cached data
- **FieldValue.serverTimestamp()**: Continue using for accurate timestamps

**iOS Frameworks**:
- **Network.framework**: NWPathMonitor for network reachability
- **UserDefaults**: Persist message queue across app restarts
- **Combine**: NetworkMonitor publishes state changes via @Published

**SwiftUI Integration**:
- **@ObservedObject**: ChatView observes NetworkMonitor for state changes
- **@State**: Track optimistic messages separately from Firestore messages
- **Animation**: Smooth transitions for status changes and banner

**Architecture Pattern** (per architecture.md):
- NetworkMonitor: Singleton service, observable
- MessageQueue: Singleton service, persists to UserDefaults
- ChatView: Observes NetworkMonitor, manages optimistic message list
- MessageService: Handles send logic, queue management, Firestore writes

**Thread Safety**:
- NetworkMonitor uses DispatchQueue.main.async for property updates
- MessageQueue operates on main thread (UserDefaults)
- Firestore operations remain async on background threads

---

## 12. Manual Validation Plan

**Current**: Manual testing validation (see `Psst/agents/shared-standards.md`)

### Testing Setup

**Devices Needed**:
- Device A: Primary testing device (iPhone or Simulator)
- Device B: Secondary device for multi-device sync verification
- Network control: Airplane mode, WiFi toggle, or network conditioner

**Test Users**:
- **vanes**: `OUv2v5intnP7kHXv7rh550GQn6o1`
- **jameson**: `wOh11I865XTWQVTmd1RfWsB9sBD3`

**Test Chat**:
- Use existing test chat from PR #8: `test_chat_vanes_jameson`

### Configuration Testing

- [ ] Firebase Firestore persistence enabled (isPersistenceEnabled = true)
- [ ] No console errors about persistence configuration
- [ ] NetworkMonitor initializes on app launch
- [ ] MessageQueue initializes successfully
- [ ] All new Swift files compile without errors

### Happy Path Testing - Optimistic UI

- [ ] **Device A (Online)**: User sends message
- [ ] Gate: Message appears in UI within 10ms with "Sending..." indicator
- [ ] Gate: After ~100ms, "Sending..." changes to timestamp
- [ ] Gate: Message visible to user immediately (no wait)
- [ ] **Device B**: Message appears within 100ms with timestamp (no "Sending..." visible)
- [ ] Gate: Both devices show same message with same ID (no duplicate)

### Happy Path Testing - Offline Persistence

- [ ] **Device A (Online)**: User opens chat, loads 10+ messages
- [ ] **Device A**: Enable airplane mode (go offline)
- [ ] Gate: Offline banner appears: "Offline - Messages will send when reconnected"
- [ ] Gate: All 10+ messages still visible in UI (loaded from cache)
- [ ] Gate: User can scroll, read messages normally
- [ ] Gate: No errors in console about network failure
- [ ] **Device A**: Close app (terminate)
- [ ] **Device A**: Reopen app (still offline)
- [ ] Gate: Messages still load from cache within 500ms
- [ ] Gate: Offline banner displays

### Happy Path Testing - Message Queueing

- [ ] **Device A (Offline)**: User types message and taps send
- [ ] Gate: Message appears in UI immediately with "Queued" status
- [ ] Gate: Banner updates: "Offline - 1 message queued"
- [ ] **Device A (Offline)**: User sends 2 more messages
- [ ] Gate: All 3 messages show "Queued" status
- [ ] Gate: Banner shows: "Offline - 3 messages queued"
- [ ] **Device A**: Disable airplane mode (reconnect)
- [ ] Gate: Banner changes to "Reconnecting..."
- [ ] Gate: Within 2 seconds, all 3 messages transition "Queued" → "Sending" → timestamp
- [ ] Gate: Banner shows "Connected" briefly then disappears
- [ ] **Device B**: All 3 messages appear in correct order with timestamps
- [ ] Gate: No duplicate messages on either device

### Edge Cases Testing

- [ ] **Empty cache**: User opens chat that was never loaded
- [ ] Gate: Empty state shows (not error), offline banner displays
- [ ] Gate: No crashes or console errors
- [ ] **App kill with queue**: User queues 2 messages offline, force quit app
- [ ] Gate: Reopen app → Queue restores, messages show "Queued"
- [ ] Gate: Reconnect → Messages send automatically
- [ ] **Send failure**: Simulate Firestore error (disconnect after reconnect, before send completes)
- [ ] Gate: Message shows "Failed - Tap to retry" with red icon
- [ ] Gate: User taps message to retry
- [ ] Gate: Message re-sends successfully
- [ ] **Rapid network changes**: Toggle airplane mode on/off/on/off rapidly
- [ ] Gate: App doesn't crash
- [ ] Gate: Queue processes correctly after settling online
- [ ] Gate: No duplicate messages
- [ ] **Large queue**: Queue 20 messages offline
- [ ] Gate: All send on reconnect within 5 seconds
- [ ] Gate: UI remains responsive during sync
- [ ] Gate: Order preserved

### Multi-Device Testing

- [ ] **Device A**: Send message with optimistic UI (online)
- [ ] **Device B**: Verify message appears within 100ms
- [ ] Gate: Device B never sees "Sending..." status (only A sees it)
- [ ] **Device A**: Go offline, send message (queued)
- [ ] **Device B**: Sees no new message (expected)
- [ ] **Device A**: Reconnect, message syncs
- [ ] **Device B**: Message appears within 2 seconds
- [ ] Gate: Correct chronological order on both devices

### Performance Testing (see shared-standards.md)

- [ ] **Optimistic UI speed**: Measure time from send button tap to UI update
- [ ] Gate: < 10ms (essentially instant)
- [ ] **Cache load speed**: Close and reopen app offline
- [ ] Gate: Messages appear within 500ms
- [ ] **Queue processing**: Queue 10 messages, reconnect, measure sync time
- [ ] Gate: All 10 messages sent within 2 seconds
- [ ] **UI responsiveness**: Send message while scrolling rapidly
- [ ] Gate: No lag, stuttering, or UI freezing

### Visual State Verification

- [ ] Optimistic message shows gray "Sending..." text
- [ ] Queued message shows yellow "Queued - Will send when online" badge
- [ ] Queued message is tappable (tap shows action sheet)
- [ ] Action sheet shows "Cancel" and "Info" options
- [ ] Delivered message shows timestamp, no indicator
- [ ] Failed message shows red "Failed - Tap to retry" text with icon
- [ ] Offline banner displays below navigation bar
- [ ] Online banner shows green "Connected" briefly then fades
- [ ] Banner doesn't cover chat content
- [ ] Smooth animations for all state transitions
- [ ] Color coding clear: Gray (sending) → Yellow (queued) → Timestamp (delivered) → Red (failed)
- [ ] No console warnings or errors

---

## 13. Definition of Done

See standards in `Psst/agents/shared-standards.md`:

- [ ] Message model extended with sendStatus field
- [ ] MessageSendStatus enum implemented (sending, queued, delivered, failed)
- [ ] NetworkMonitor service implemented with NWPathMonitor
- [ ] MessageQueue service implemented with UserDefaults persistence
- [ ] NetworkStatusBanner component created and integrated
- [ ] MessageStatusIndicator component created and integrated
- [ ] FirebaseService enables Firestore offline persistence
- [ ] MessageService updated with optimistic completion callback
- [ ] MessageService checks network state and queues offline messages
- [ ] ChatView implements optimistic UI pattern (immediate message display)
- [ ] ChatView observes NetworkMonitor and displays status banner
- [ ] ChatView processes message queue on reconnect
- [ ] MessageRow displays status indicators based on sendStatus
- [ ] Failed messages support tap-to-retry
- [ ] All acceptance gates pass
- [ ] Manual testing completed (configuration, user flows, multi-device, offline, performance)
- [ ] No console warnings or errors
- [ ] Code follows `Psst/agents/shared-standards.md` patterns
- [ ] No data loss during offline/online transitions
- [ ] No duplicate messages from queue
- [ ] PR created targeting develop branch

---

## 14. Risks & Mitigations

**Risk: Optimistic message shows but actual send fails silently**
- **Mitigation**: Track message IDs and update status after Firestore confirmation. Show failed state with retry option.

**Risk: Queue grows unbounded if user sends many messages offline**
- **Mitigation**: For MVP, acceptable (user unlikely to send 100+ messages offline). Future: Add queue size limit and warning.

**Risk: Duplicate messages if queue processes multiple times**
- **Mitigation**: Use consistent message IDs. Firestore setData() with same ID overwrites (idempotent). Check queue before processing.

**Risk: Cache takes too much storage space**
- **Mitigation**: Use Firestore's default cache management (LRU eviction). For MVP, no custom management needed.

**Risk: Network state detection lags (false positives/negatives)**
- **Mitigation**: NWPathMonitor is reliable on iOS. Test with actual devices in various network conditions. Add 100ms debounce if flicker issues occur.

**Risk: Queue fails to restore after app restart**
- **Mitigation**: Use UserDefaults for persistence (reliable, synchronous). Test app kill scenarios thoroughly.

**Risk: Offline persistence conflicts with Firestore rules**
- **Mitigation**: Offline persistence uses cached data from previous authenticated sessions. Security rules still enforced on server write. No client-side bypass possible.

**Risk: User confusion about message states**
- **Mitigation**: Use clear, consistent visual indicators. "Sending...", "Queued", timestamp, "Failed - Tap to retry". User testing to validate clarity.

**Risk: Poor performance with large message queues**
- **Mitigation**: Process queue asynchronously. Use batch writes if >10 messages. Monitor performance, add pagination to queue if needed.

---

## 15. Rollout & Telemetry

**Feature Flag**: No

**Metrics (Manual Observation)**:
- Count optimistic UI → delivered transitions during testing
- Measure time from send tap to UI update (should be <10ms)
- Count queued messages that successfully sync on reconnect
- Verify 0% message loss during offline/online cycles
- Check cache load times when offline
- Monitor console for errors during network transitions

**Manual Validation Steps**:
1. Send message online, verify instant UI update
2. Go offline, verify cached messages still visible
3. Send message offline, verify queue
4. Reconnect, verify automatic sync
5. Force fail send, verify retry works
6. Kill app with queue, verify restore
7. Test on 2+ devices for sync verification

**Logging Strategy**:
```swift
// Add debug logs for monitoring
print("⚡️ Optimistic message added: \(messageID)")
print("✅ Message confirmed delivered: \(messageID)")
print("📥 Message queued for offline send: \(messageID)")
print("🌐 Network state changed: \(isConnected ? "Online" : "Offline")")
print("📤 Processing message queue: \(queueCount) messages")
print("❌ Message send failed: \(messageID) - \(error)")
print("🔄 Retrying message: \(messageID) (attempt \(retryCount))")
```

---

## 16. Open Questions

**Q1**: Should optimistic messages be distinguishable from delivered messages visually?
- **Answer**: Yes, show subtle "Sending..." text below message. Remove after delivery. Users expect visual confirmation.

**Q2**: What happens if app is offline for days and queue has 100+ messages?
- **Answer**: For MVP, process all on reconnect. May take 10-20 seconds. User sees progress. Future: Add chunked processing with progress indicator.

**Q3**: Should we show timestamp or "Sending..." for optimistic messages?
- **Answer**: Show "Sending..." until Firestore confirms, then show timestamp. Timestamp accuracy requires server confirmation.

**Q4**: How do we handle timezone differences with optimistic timestamps?
- **Answer**: Display local time for optimistic message. After server confirms, update to server timestamp. Slight shift is acceptable.

**Q5**: Should failed messages be deletable?
- **Answer**: For MVP, no. User can only retry or ignore. Message deletion is out of scope (future feature).

**Q6**: What if Firestore persistence isn't supported on device?
- **Answer**: Extremely rare (requires iOS 10+). If persistence fails, log error and continue without offline support. Don't block app.

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future PRs:

- [ ] Advanced retry logic with exponential backoff (basic 3-try retry only)
- [ ] Conflict resolution for concurrent edits (messages are append-only)
- [ ] Message editing/deletion while offline (future)
- [ ] Offline profile picture uploads (future)
- [ ] Custom offline storage beyond Firestore cache (using defaults)
- [ ] Push notifications while offline (FCM handles automatically)
- [ ] Manual sync controls (automatic sync only)
- [ ] Storage quota management for cache (Firestore defaults)
- [ ] Queue size limits and warnings (unlimited for MVP)
- [ ] Chunked queue processing with progress (process all at once for MVP)
- [ ] Message deletion from queue (retry or ignore only)
- [ ] Automated unit tests for offline scenarios (deferred to backlog)
- [ ] Network conditioner integration for testing (manual airplane mode)
- [ ] Analytics tracking for offline usage patterns (future)

---

## 18. Preflight Questionnaire

1. **Smallest end-to-end user outcome for this PR?**
   - User sends message and sees it appear instantly in UI before Firestore confirms, creating perception of zero latency.

2. **Primary user and critical action?**
   - Primary user: Any authenticated user in a chat
   - Critical action: Send message with instant feedback, use app offline, have messages auto-sync on reconnect

3. **Must-have vs nice-to-have?**
   - Must-have: Optimistic UI, offline cache, message queue, network state indicator
   - Nice-to-have: Advanced retry logic, queue limits, manual sync (deferred)

4. **Real-time requirements?** (see shared-standards.md)
   - Optimistic UI update: < 10ms (instant)
   - Firestore confirmation: < 100ms (existing from PR #8)
   - Queue processing on reconnect: < 2 seconds for 10 messages
   - Cache load: < 500ms for 100+ messages

5. **Performance constraints?** (see shared-standards.md)
   - No UI blocking during queue processing
   - Smooth 60fps animations for status transitions
   - Background thread for network monitoring
   - Main thread for UI updates only

6. **Error/edge cases to handle?**
   - Send failure online (show retry)
   - App killed with queue pending (restore on launch)
   - Network flicker (debounce, avoid duplicate processing)
   - Large queue (process asynchronously)
   - Cache empty offline (show empty state)
   - Duplicate IDs (idempotent writes)

7. **Data model changes?**
   - Add sendStatus field to Message model (client-side only, not persisted to Firestore)
   - Add MessageSendStatus enum
   - Add QueuedMessage model for queue persistence

8. **Service APIs required?**
   - `sendMessage(chatID:text:optimisticCompletion:) async throws -> String`
   - `NetworkMonitor.shared.isConnected: Bool`
   - `MessageQueue.shared.enqueue()`, `processQueue()`

9. **UI entry points and states?**
   - Entry: ChatView observes NetworkMonitor
   - States: Online, Offline, Reconnecting
   - Message states: Sending, Queued, Delivered, Failed
   - Banner: Offline banner, reconnecting banner, connected banner

10. **Security/permissions implications?**
    - Firestore security rules still enforced (cached data already passed rules)
    - Queue stored locally (device access only via UserDefaults)
    - No security changes needed

11. **Dependencies or blocking integrations?**
    - Depends on: PR #8 (MessageService, real-time sync)
    - Blocks: None (enhances existing functionality)

12. **Rollout strategy and metrics?**
    - Manual testing with airplane mode
    - Measure optimistic UI latency with timer logs
    - Verify queue sync on reconnect
    - Test cache load times offline

13. **What is explicitly out of scope?**
    - Advanced retry logic, conflict resolution, message editing offline, custom storage, manual sync controls, queue limits, automated tests, analytics

---

## Authoring Notes

- This PR significantly enhances user experience by removing perceived latency
- Optimistic UI is client-side only - message IDs ensure consistency with Firestore
- Firestore offline persistence is built-in and robust - leverage it fully
- Network monitoring using iOS Network.framework is reliable
- UserDefaults sufficient for queue persistence (simple, reliable, performant)
- Keep UI responsive during queue processing (async operations)
- Test thoroughly with airplane mode and network conditioner
- Follow shared-standards.md for threading and performance patterns
- This PR makes the app feel fast and reliable even with poor connectivity

