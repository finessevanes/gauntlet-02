# PR-10 TODO — Optimistic UI and Offline Persistence

**Branch**: `feat/pr-10-optimistic-ui-offline`  
**Source PRD**: `Psst/docs/prds/pr-10-prd.md`  
**Owner (Agent)**: Caleb

---

## 0. Clarifying Questions & Assumptions

- **Questions**: None - PRD is comprehensive
- **Assumptions**:
  - Firestore offline persistence works reliably on all iOS versions (iOS 13+)
  - UserDefaults sufficient for queue storage (small data, < 1MB expected)
  - NWPathMonitor provides accurate network state detection
  - Users understand color coding: Gray (sending) → Yellow (queued) → Timestamp (delivered) → Red (failed)

---

## 1. Setup

- [x] Create branch `feat/pr-10-optimistic-ui-offline` from develop
  - Test Gate: Branch created, checkout successful
- [x] Read PRD thoroughly (`Psst/docs/prds/pr-10-prd.md`)
  - Test Gate: Understand all requirements, acceptance gates clear
- [x] Read `Psst/agents/shared-standards.md` for threading and performance patterns
  - Test Gate: Threading rules clear (background for heavy work, main for UI)
- [x] Review existing MessageService from PR #8
  - Test Gate: Understand current send/observe implementation
- [x] Confirm Xcode project builds and runs
  - Test Gate: No existing errors, app launches successfully ✅ BUILD SUCCEEDED

---

## 2. Data Models

### 2.1 Extend Message Model

- [x] Open `Models/Message.swift`
  - Test Gate: File opens, current structure clear ✅
- [x] Add `MessageSendStatus` enum above Message struct
  - Test Gate: Enum has cases: `.sending`, `.queued`, `.delivered`, `.failed` ✅
- [x] Add `var sendStatus: MessageSendStatus?` field to Message struct
  - Test Gate: Optional property added, defaults to nil ✅
- [x] Add `sendStatus` to custom init method
  - Test Gate: Init parameter added with default `nil` ✅
- [x] Update `CodingKeys` enum to exclude `sendStatus` from Firestore serialization
  - Test Gate: `sendStatus` not in CodingKeys (client-side only) ✅
- [x] Add helper method `isDelivered() -> Bool`
  - Test Gate: Returns `true` if sendStatus is `.delivered` or `nil` ✅
- [x] Build project
  - Test Gate: No compiler errors from Message model changes ✅

### 2.2 Create QueuedMessage Model

- [x] Create new file `Models/QueuedMessage.swift`
  - Test Gate: File created in Models folder ✅
- [x] Define `QueuedMessage` struct conforming to `Identifiable`, `Codable`, `Equatable`
  - Test Gate: Struct compiles with required conformances ✅
- [x] Add properties: `id: String`, `chatID: String`, `text: String`, `timestamp: Date`, `retryCount: Int`
  - Test Gate: All properties defined with correct types ✅
- [x] Add `toMessage(senderID:)` method that converts to Message with `.queued` status
  - Test Gate: Method returns Message with correct fields and `.queued` status ✅
- [x] Build project
  - Test Gate: QueuedMessage model compiles successfully ✅

---

## 3. Service Layer - Network Monitoring

### 3.1 Create NetworkMonitor Service

- [x] Create new file `Services/NetworkMonitor.swift`
  - Test Gate: File created in Services folder
- [ ] Import `Network` and `Combine` frameworks
  - Test Gate: Imports resolve (no errors)
- [ ] Define `NetworkMonitor` class inheriting from `ObservableObject`
  - Test Gate: Class definition compiles
- [ ] Add `static let shared = NetworkMonitor()` singleton
  - Test Gate: Singleton property added
- [ ] Add `@Published var isConnected: Bool = true` property
  - Test Gate: Published property for SwiftUI observation
- [ ] Add `@Published var connectionType: NWInterface.InterfaceType?` property
  - Test Gate: Published property for connection type tracking
- [ ] Add `private let monitor = NWPathMonitor()` property
  - Test Gate: NWPathMonitor instance created
- [ ] Add `private let queue = DispatchQueue(label: "NetworkMonitor")` property
  - Test Gate: Background queue for network monitoring
- [ ] Implement `private init()` that calls `startMonitoring()`
  - Test Gate: Private initializer prevents external instantiation
- [ ] Implement `startMonitoring()` method
  - Test Gate: Sets up `pathUpdateHandler` on monitor
  - Test Gate: Updates `isConnected` based on `path.status == .satisfied`
  - Test Gate: Updates `connectionType` from `path.availableInterfaces`
  - Test Gate: Uses `DispatchQueue.main.async` for property updates
  - Test Gate: Calls `monitor.start(queue: queue)`
- [ ] Implement `stopMonitoring()` method
  - Test Gate: Calls `monitor.cancel()`
- [ ] Build project
  - Test Gate: NetworkMonitor compiles without errors

### 3.2 Test NetworkMonitor

- [ ] Run app with NetworkMonitor initialized
  - Test Gate: No crashes on app launch
- [ ] Add print statement in `pathUpdateHandler` to log network state
  - Test Gate: Console shows "Network: Connected" or "Network: Disconnected"
- [ ] Toggle airplane mode on device/simulator
  - Test Gate: Console logs state change within 1 second
- [ ] Verify `isConnected` updates correctly
  - Test Gate: Property reflects actual network state

---

## 4. Service Layer - Message Queue

### 4.1 Create MessageQueue Service

- [ ] Create new file `Services/MessageQueue.swift`
  - Test Gate: File created in Services folder
- [ ] Import `Foundation`
  - Test Gate: Import resolves
- [ ] Define `MessageQueue` class
  - Test Gate: Class definition compiles
- [ ] Add `static let shared = MessageQueue()` singleton
  - Test Gate: Singleton property added
- [ ] Add `private let queueKey = "com.psst.messageQueue"` constant
  - Test Gate: UserDefaults key defined
- [ ] Add `private init() {}` private initializer
  - Test Gate: Private init prevents external instantiation
- [ ] Implement `private func getQueue() -> [QueuedMessage]` method
  - Test Gate: Loads array from UserDefaults using `queueKey`
  - Test Gate: Decodes JSON using `JSONDecoder`
  - Test Gate: Returns empty array if no data or decode fails
- [ ] Implement `private func saveQueue(_ queue: [QueuedMessage])` method
  - Test Gate: Encodes array using `JSONEncoder`
  - Test Gate: Saves to UserDefaults with `queueKey`
- [ ] Implement `func enqueue(_ message: QueuedMessage) throws` method
  - Test Gate: Calls `getQueue()` to load current queue
  - Test Gate: Appends new message to queue
  - Test Gate: Calls `saveQueue()` to persist
- [ ] Implement `func dequeue(id: String)` method
  - Test Gate: Loads queue, removes message with matching ID
  - Test Gate: Saves updated queue
- [ ] Implement `func getQueuedMessages(for chatID: String) -> [QueuedMessage]` method
  - Test Gate: Returns filtered queue for specific chat
- [ ] Build project
  - Test Gate: MessageQueue compiles without errors

### 4.2 Implement Queue Processing

- [ ] Add `func processQueue() async` method to MessageQueue
  - Test Gate: Async method definition compiles
- [ ] Get current queue with `let queue = getQueue()`
  - Test Gate: Queue loaded successfully
- [ ] Loop through queue with `for queuedMessage in queue`
  - Test Gate: Loop structure correct
- [ ] Inside loop, attempt to send with `try await MessageService().sendMessage()`
  - Test Gate: Calls MessageService with chatID and text
- [ ] On success, call `dequeue(id: queuedMessage.id)`
  - Test Gate: Message removed from queue after successful send
- [ ] On error, increment `retryCount`
  - Test Gate: Creates updated QueuedMessage with retryCount + 1
- [ ] Check if `retryCount >= 3`
  - Test Gate: After 3 retries, dequeue message (mark as failed)
  - Test Gate: If < 3, update queue with new retry count
- [ ] Add print logs for monitoring
  - Test Gate: Logs success, failures, retry counts
- [ ] Build project
  - Test Gate: processQueue() compiles without errors

---

## 5. Service Layer - Update MessageService

### 5.1 Add MessageError.offline Case

- [ ] Open `Services/MessageService.swift`
  - Test Gate: File opens, current implementation visible
- [ ] Add `.offline` case to `MessageError` enum
  - Test Gate: Case added after `.invalidChatID`
- [ ] Add error description for `.offline` case
  - Test Gate: Returns "Message queued - will send when online"
- [ ] Build project
  - Test Gate: MessageError enum compiles

### 5.2 Update sendMessage() for Optimistic UI

- [ ] Locate `sendMessage(chatID:text:)` method
  - Test Gate: Method signature found
- [ ] Add new parameter `optimisticCompletion: ((Message) -> Void)? = nil`
  - Test Gate: Optional closure parameter added with default nil
- [ ] After validation, before Firestore write, create optimistic message
  - Test Gate: Message created with `sendStatus: .sending`
- [ ] Call `optimisticCompletion?(optimisticMessage)` immediately
  - Test Gate: Closure called before Firestore write (if provided)
- [ ] Check network state with `if !NetworkMonitor.shared.isConnected`
  - Test Gate: Network check added after optimistic completion
- [ ] If offline, create `QueuedMessage` and enqueue
  - Test Gate: QueuedMessage created with correct fields
  - Test Gate: Calls `MessageQueue.shared.enqueue()`
  - Test Gate: Updates message sendStatus to `.queued` before enqueueing
- [ ] If offline, throw `MessageError.offline`
  - Test Gate: Throws after enqueuing (allows caller to handle)
- [ ] Existing Firestore write remains unchanged (online path)
  - Test Gate: No changes to Firebase logic for online sends
- [ ] Add print logs for optimistic UI and offline queueing
  - Test Gate: Logs "⚡️ Optimistic message added" and "📥 Message queued"
- [ ] Build project
  - Test Gate: Updated sendMessage() compiles successfully

### 5.3 Test MessageService Updates

- [ ] Run app with updated MessageService
  - Test Gate: No crashes on app launch
- [ ] Send message while online
  - Test Gate: optimisticCompletion called immediately
  - Test Gate: Message sends to Firestore successfully
- [ ] Go offline (airplane mode)
  - Test Gate: NetworkMonitor detects offline state
- [ ] Send message while offline
  - Test Gate: optimisticCompletion called immediately
  - Test Gate: Message queued in UserDefaults
  - Test Gate: MessageError.offline thrown
  - Test Gate: No Firestore write attempted
- [ ] Check UserDefaults
  - Test Gate: Queue persisted with correct structure

---

## 6. Service Layer - Enable Firestore Persistence

### 6.1 Update FirebaseService

- [ ] Open `Services/FirebaseService.swift` (or create if doesn't exist)
  - Test Gate: File accessible
- [ ] Locate `configure()` method (or create static method)
  - Test Gate: Method called from PsstApp.swift on launch
- [ ] Add Firestore settings configuration
  - Test Gate: Create `FirestoreSettings()` instance
  - Test Gate: Set `settings.isPersistenceEnabled = true`
  - Test Gate: Set `settings.cacheSizeBytes = FirestoreCacheSizeUnlimited`
  - Test Gate: Apply settings to `Firestore.firestore().settings = settings`
- [ ] Ensure settings applied BEFORE any Firestore queries
  - Test Gate: Configuration happens in app initialization
- [ ] Build project
  - Test Gate: FirebaseService compiles successfully
- [ ] Run app
  - Test Gate: No console errors about persistence configuration
  - Test Gate: Firestore initializes with offline persistence enabled

### 6.2 Test Offline Persistence

- [ ] Run app, open chat, load messages
  - Test Gate: Messages display from Firestore
- [ ] Close app completely (force quit)
  - Test Gate: App terminated
- [ ] Enable airplane mode
  - Test Gate: Device offline
- [ ] Reopen app
  - Test Gate: Previously loaded messages display from cache
  - Test Gate: No network errors in console
  - Test Gate: Messages load within 500ms

---

## 7. UI Components - Network Status Banner

### 7.1 Create NetworkStatusBanner Component

- [ ] Create new file `Views/Components/NetworkStatusBanner.swift`
  - Test Gate: File created in Views/Components folder
- [ ] Import `SwiftUI`
  - Test Gate: Import resolves
- [ ] Define `NetworkStatusBanner` struct conforming to `View`
  - Test Gate: Struct definition compiles
- [ ] Add `@ObservedObject var networkMonitor: NetworkMonitor` property
  - Test Gate: Observes network state changes
- [ ] Add `@Binding var queueCount: Int` property
  - Test Gate: Shows queued message count
- [ ] Add `@State private var showBanner: Bool = false` for animation
  - Test Gate: Controls banner visibility
- [ ] Implement `body` returning banner view
  - Test Gate: Returns VStack with banner content
- [ ] Show banner when offline: `if !networkMonitor.isConnected`
  - Test Gate: Banner visible when offline
- [ ] Display text: "Offline - \(queueCount) message(s) queued"
  - Test Gate: Shows queue count dynamically
- [ ] Style banner with yellow background, padding, rounded corners
  - Test Gate: Background: `.yellow.opacity(0.2)`
  - Test Gate: Text color: `.black`
  - Test Gate: Padding: 12pts vertical, 16pts horizontal
  - Test Gate: Corner radius: 8pts
- [ ] Add slide-down animation with `.transition(.move(edge: .top))`
  - Test Gate: Banner slides in from top
- [ ] Add brief "Connected" banner when reconnecting
  - Test Gate: Shows green banner for 2 seconds on reconnect
  - Test Gate: Auto-dismisses with fade animation
- [ ] Build project
  - Test Gate: NetworkStatusBanner compiles successfully

---

## 8. UI Components - Message Status Indicator

### 8.1 Create MessageStatusIndicator Component

- [ ] Create new file `Views/Components/MessageStatusIndicator.swift`
  - Test Gate: File created in Views/Components folder
- [ ] Import `SwiftUI`
  - Test Gate: Import resolves
- [ ] Define `MessageStatusIndicator` struct conforming to `View`
  - Test Gate: Struct definition compiles
- [ ] Add `let status: MessageSendStatus?` property
  - Test Gate: Receives message send status
- [ ] Add `let onRetry: (() -> Void)?` property for retry action
  - Test Gate: Optional closure for retry button
- [ ] Implement `body` returning appropriate view based on status
  - Test Gate: Switch on `status` cases
- [ ] Case `.sending`: Show gray "Sending..." text
  - Test Gate: Text: "Sending..."
  - Test Gate: Color: `.gray`
  - Test Gate: Font: `.caption`
- [ ] Case `.queued`: Show yellow "Queued - Will send when online" badge
  - Test Gate: Text: "Queued"
  - Test Gate: Background: `.yellow.opacity(0.3)`
  - Test Gate: Padding and corner radius
  - Test Gate: Font: `.caption.bold()`
- [ ] Case `.failed`: Show red "Failed - Tap to retry" with retry action
  - Test Gate: Text: "Failed - Tap to retry"
  - Test Gate: Color: `.red`
  - Test Gate: Tappable with `onTapGesture` calling `onRetry?()`
  - Test Gate: Icon: exclamation mark
- [ ] Case `.delivered` or `nil`: Show nothing (return `EmptyView()`)
  - Test Gate: No indicator for delivered messages
- [ ] Build project
  - Test Gate: MessageStatusIndicator compiles successfully

---

## 9. UI Integration - Update ChatView

### 9.1 Add Network Monitoring to ChatView

- [ ] Open `Views/ChatList/ChatView.swift`
  - Test Gate: File opens, current implementation visible
- [ ] Add `@ObservedObject var networkMonitor = NetworkMonitor.shared` property
  - Test Gate: Property observes network state
- [ ] Add `@State private var queueCount: Int = 0` property
  - Test Gate: Tracks queued messages for this chat
- [ ] Add `@State private var optimisticMessages: [Message] = []` property
  - Test Gate: Stores messages with optimistic status before confirmation
- [ ] Build project
  - Test Gate: New properties compile

### 9.2 Display Network Status Banner

- [ ] Add `NetworkStatusBanner` above message list in VStack
  - Test Gate: Banner positioned below navigation bar
- [ ] Pass `networkMonitor` and `queueCount` bindings
  - Test Gate: Banner receives correct parameters
- [ ] Update `queueCount` in `.onAppear`
  - Test Gate: Load queued messages for this chat
  - Test Gate: Set `queueCount = MessageQueue.shared.getQueuedMessages(for: chat.id).count`
- [ ] Update `queueCount` when queue changes
  - Test Gate: Recalculate after send, after reconnect
- [ ] Build project
  - Test Gate: Banner integrates without errors

### 9.3 Implement Optimistic UI

- [ ] Locate `handleSend()` method in ChatView
  - Test Gate: Method found
- [ ] Update message send to use optimistic completion
  - Test Gate: Add optimistic closure parameter to sendMessage
- [ ] In closure, add message to local state immediately
  - Test Gate: `optimisticMessages.append(optimisticMessage)`
  - Test Gate: Happens before await (instant UI update)
- [ ] Merge `optimisticMessages` with `messages` for display
  - Test Gate: Display `optimisticMessages + messages` in message list
  - Test Gate: Use `.id` to prevent duplicates
- [ ] After successful send, remove from optimistic list
  - Test Gate: Remove message with matching ID from optimisticMessages
  - Test Gate: Firestore listener will add confirmed message to `messages`
- [ ] Handle offline case (MessageError.offline thrown)
  - Test Gate: Update message in optimisticMessages to `.queued` status
  - Test Gate: Increment `queueCount`
  - Test Gate: Don't show error alert (expected behavior)
- [ ] Handle other errors
  - Test Gate: Update message status to `.failed`
  - Test Gate: Keep in optimisticMessages for retry
  - Test Gate: Log error to console
- [ ] Build project
  - Test Gate: Optimistic UI logic compiles

### 9.4 Implement Queue Processing on Reconnect

- [ ] Add `.onChange(of: networkMonitor.isConnected)` modifier to ChatView
  - Test Gate: Modifier observes network state changes
- [ ] Check if reconnected: `if networkMonitor.isConnected`
  - Test Gate: Only processes when going from offline to online
- [ ] Call `Task { await MessageQueue.shared.processQueue() }`
  - Test Gate: Processes queue asynchronously
- [ ] After processing, update `queueCount`
  - Test Gate: Recalculate queued message count
  - Test Gate: Should be 0 if all successful
- [ ] Clear optimistic messages that were queued and now sent
  - Test Gate: Remove messages with `.queued` status from optimisticMessages
  - Test Gate: Confirmed messages appear via Firestore listener
- [ ] Build project
  - Test Gate: Queue processing logic compiles

---

## 10. UI Integration - Update MessageRow

### 10.1 Display Status Indicators in MessageRow

- [ ] Open `Views/ChatList/MessageRow.swift`
  - Test Gate: File opens
- [ ] Add `MessageStatusIndicator` below message text
  - Test Gate: Indicator positioned below message bubble
- [ ] Pass `message.sendStatus` to indicator
  - Test Gate: Status passed correctly
- [ ] Only show indicator for current user's messages
  - Test Gate: Check `message.isFromCurrentUser(currentUserID:)`
- [ ] For failed messages, add retry action
  - Test Gate: Pass `onRetry` closure that calls ChatView's retry method
- [ ] Style appropriately (align with message bubble)
  - Test Gate: Indicator aligned left for sent, right for received
- [ ] Build project
  - Test Gate: MessageRow with indicator compiles

### 10.2 Implement Tap Action for Queued Messages

- [ ] Add `.onTapGesture` to queued messages
  - Test Gate: Only tappable when `status == .queued`
- [ ] Show action sheet on tap
  - Test Gate: Use `.actionSheet()` or `.confirmationDialog()`
- [ ] Add "Cancel" action
  - Test Gate: Removes message from queue
  - Test Gate: Calls `MessageQueue.shared.dequeue(id: message.id)`
  - Test Gate: Removes message from UI
- [ ] Add "Info" action
  - Test Gate: Shows alert: "This message will send automatically when you're back online"
  - Test Gate: Alert has "OK" button to dismiss
- [ ] Add "Dismiss" action
  - Test Gate: Closes action sheet without action
- [ ] Build project
  - Test Gate: Tap actions compile successfully

---

## 11. UI Integration - Update PsstApp

### 11.1 Initialize Services on App Launch

- [ ] Open `PsstApp.swift`
  - Test Gate: File opens
- [ ] In `init()` or app delegate, initialize NetworkMonitor
  - Test Gate: Call `_ = NetworkMonitor.shared` to start monitoring
- [ ] Ensure FirebaseService.configure() enables persistence
  - Test Gate: Firestore settings applied before any queries
- [ ] Build project
  - Test Gate: App initialization compiles

---

## 12. Testing & Validation

### 12.1 Configuration Testing

- [x] Run app and verify Firebase persistence enabled
  - Test Gate: No console errors about persistence
  - Test Gate: Firestore initializes successfully
- [x] Verify NetworkMonitor starts on launch
  - Test Gate: Console logs network state
  - Test Gate: isConnected property accurate
- [x] Verify MessageQueue initializes
  - Test Gate: No errors accessing UserDefaults
  - Test Gate: Empty queue loads successfully
- [x] Build compiles with no warnings or errors
  - Test Gate: Clean build output

### 12.2 Happy Path - Optimistic UI (Online)

- [ ] User sends message while online
  - Test Gate: Message appears in UI within 10ms
  - Test Gate: Shows gray "Sending..." indicator
  - Test Gate: Console logs "⚡️ Optimistic message added"
- [ ] Wait for Firestore confirmation (~100ms)
  - Test Gate: "Sending..." changes to timestamp
  - Test Gate: Indicator disappears
  - Test Gate: Console logs "✅ Message sent successfully"
- [ ] Message appears on second device
  - Test Gate: Syncs within 100ms
  - Test Gate: No "Sending..." visible on second device
  - Test Gate: Only timestamp shown
- [ ] No duplicate messages
  - Test Gate: Both devices show single message with same ID

### 12.3 Happy Path - Offline Persistence

- [ ] Load chat with 10+ messages online
  - Test Gate: Messages display from Firestore
- [ ] Enable airplane mode
  - Test Gate: Yellow offline banner appears
  - Test Gate: Banner text: "Offline - Messages will send when reconnected"
- [ ] All messages still visible
  - Test Gate: Messages load from cache
  - Test Gate: No errors in console
  - Test Gate: Cache loads within 500ms
- [ ] Close app completely
  - Test Gate: Force quit app
- [ ] Reopen app (still offline)
  - Test Gate: Messages load from cache
  - Test Gate: Offline banner displays
  - Test Gate: No network calls attempted

### 12.4 Happy Path - Message Queueing

- [ ] Send message while offline
  - Test Gate: Message appears instantly
  - Test Gate: Shows yellow "Queued" badge
  - Test Gate: Console logs "📥 Message queued"
  - Test Gate: Banner updates: "Offline - 1 message queued"
- [ ] Send 2 more messages offline
  - Test Gate: All 3 show "Queued" status
  - Test Gate: Banner shows: "Offline - 3 messages queued"
- [ ] Tap queued message
  - Test Gate: Action sheet appears
  - Test Gate: Shows "Cancel" and "Info" options
- [ ] Tap "Info"
  - Test Gate: Alert shows explanation about auto-send
  - Test Gate: User can dismiss alert
- [ ] Disable airplane mode (reconnect)
  - Test Gate: Banner changes to "Reconnecting..."
  - Test Gate: Queue processes automatically
  - Test Gate: All 3 messages transition: Queued → Sending → timestamp
  - Test Gate: All send within 2 seconds
  - Test Gate: Banner shows "Connected" briefly then disappears
- [ ] Verify on second device
  - Test Gate: All 3 messages appear in correct order
  - Test Gate: No duplicates

### 12.5 Edge Case - Cancel Queued Message

- [ ] Send message offline (queued)
  - Test Gate: Message shows "Queued" status
- [ ] Tap queued message
  - Test Gate: Action sheet appears
- [ ] Tap "Cancel"
  - Test Gate: Message removed from UI
  - Test Gate: Message removed from queue (check UserDefaults)
  - Test Gate: queueCount decrements
- [ ] Reconnect
  - Test Gate: Canceled message does NOT send
  - Test Gate: Only remaining queued messages send

### 12.6 Edge Case - App Killed with Queue

- [ ] Send 2 messages offline (queued)
  - Test Gate: Both show "Queued" status
- [ ] Force quit app
  - Test Gate: App terminated
- [ ] Reopen app (still offline)
  - Test Gate: Queue restores from UserDefaults
  - Test Gate: Messages show "Queued" status
  - Test Gate: Banner shows: "Offline - 2 messages queued"
- [ ] Reconnect
  - Test Gate: Queue processes automatically
  - Test Gate: Both messages send successfully

### 12.7 Edge Case - Send Failure Online

- [ ] Send message while online
  - Test Gate: Shows "Sending..."
- [ ] Simulate Firestore error (disconnect immediately after send)
  - Test Gate: Send fails
  - Test Gate: Status changes to "Failed - Tap to retry"
  - Test Gate: Message shows in red
- [ ] Tap failed message
  - Test Gate: Retry triggered
  - Test Gate: Message status returns to "Sending..."
- [ ] If retry succeeds
  - Test Gate: Status updates to timestamp
  - Test Gate: Message appears on other devices

### 12.8 Edge Case - Network Flicker

- [ ] Queue 3 messages offline
  - Test Gate: All queued
- [ ] Toggle airplane mode on/off/on/off rapidly
  - Test Gate: App doesn't crash
  - Test Gate: Queue doesn't process multiple times
- [ ] Settle online
  - Test Gate: Queue processes once
  - Test Gate: All messages send successfully
  - Test Gate: No duplicates

### 12.9 Edge Case - Large Queue

- [ ] Send 20 messages offline
  - Test Gate: All queued successfully
  - Test Gate: Banner shows: "Offline - 20 messages queued"
- [ ] Reconnect
  - Test Gate: All 20 messages send
  - Test Gate: Completes within 10 seconds
  - Test Gate: UI remains responsive during sync
  - Test Gate: Order preserved
  - Test Gate: No duplicates

### 12.10 Performance Testing

- [ ] Measure optimistic UI latency
  - Test Gate: Tap send → Message appears < 10ms
  - Test Gate: Use timer logs to verify
- [ ] Measure cache load time offline
  - Test Gate: Open chat offline → Messages appear < 500ms
- [ ] Measure queue processing time
  - Test Gate: Reconnect with 10 queued → All send < 2 seconds
- [ ] Check UI responsiveness
  - Test Gate: Send message while scrolling → No lag
  - Test Gate: Smooth 60fps during queue processing

### 12.11 Visual State Verification

- [ ] Verify color coding
  - Test Gate: Sending = gray text
  - Test Gate: Queued = yellow badge
  - Test Gate: Delivered = timestamp only
  - Test Gate: Failed = red text with icon
- [ ] Verify banner appearance
  - Test Gate: Offline banner = yellow background
  - Test Gate: Connected banner = green background, auto-fades
  - Test Gate: Banner doesn't cover chat content
  - Test Gate: Banner slides down smoothly
- [ ] Verify animations
  - Test Gate: Smooth transitions for status changes
  - Test Gate: Banner fade in/out smooth
  - Test Gate: No jarring jumps or layout shifts
- [ ] No console warnings or errors
  - Test Gate: Clean console during all tests

---

## 13. Performance Validation

- [ ] Verify app load time unchanged
  - Test Gate: Cold start < 2-3 seconds (per shared-standards.md)
- [ ] Verify message delivery latency unchanged
  - Test Gate: Online sends still < 100ms (per shared-standards.md)
- [ ] Verify scrolling performance
  - Test Gate: Smooth 60fps with 100+ messages
- [ ] Verify no memory leaks
  - Test Gate: Use Instruments to check NetworkMonitor
  - Test Gate: Verify listeners properly cleaned up
- [ ] Verify queue storage size reasonable
  - Test Gate: 20 queued messages < 10KB in UserDefaults

---

## 14. Documentation & PR

### 14.1 Code Documentation

- [ ] Add inline comments to complex logic
  - Test Gate: Optimistic UI flow explained
  - Test Gate: Queue processing logic explained
  - Test Gate: Network state transitions explained
- [ ] Add documentation comments to public APIs
  - Test Gate: NetworkMonitor methods documented
  - Test Gate: MessageQueue methods documented
  - Test Gate: MessageService updates documented

### 14.2 Update README (if needed)

- [ ] Document offline capabilities
  - Test Gate: Explain offline persistence to users
  - Test Gate: Explain message queueing behavior
  - Test Gate: Document color coding system

### 14.3 Create PR

- [ ] Verify all TODO items checked off
  - Test Gate: All checkboxes completed
- [ ] Run final build
  - Test Gate: No warnings or errors
- [ ] Test on physical device
  - Test Gate: Real network conditions verified
- [ ] Create PR description using format from caleb-agent.md
  - Test Gate: Links to PRD and TODO included
  - Test Gate: Summary of changes clear
  - Test Gate: Screenshots/GIFs of UI states included
  - Test Gate: Manual testing results documented
- [ ] Verify with user before opening PR
  - Test Gate: User approval received
- [ ] Open PR targeting develop branch
  - Test Gate: PR created successfully
  - Test Gate: Branch: feat/pr-10-optimistic-ui-offline → develop

---

## 15. Acceptance Gates Checklist

Copy this to PR description:

```markdown
## PR #10 Acceptance Gates

### Optimistic UI
- [ ] Message appears in UI < 10ms after send tap (online)
- [ ] Message shows gray "Sending..." indicator
- [ ] After Firestore confirms, indicator changes to timestamp
- [ ] Second device receives message within 100ms
- [ ] No duplicate messages on any device

### Offline Persistence
- [ ] Firestore persistence enabled (no console errors)
- [ ] Messages load from cache when offline < 500ms
- [ ] All previously loaded messages viewable offline
- [ ] Cache persists across app restarts

### Message Queueing
- [ ] Message sent offline shows yellow "Queued" badge instantly
- [ ] Queued message tappable (shows Cancel/Info options)
- [ ] Queue persists across app restarts
- [ ] On reconnect, all queued messages send < 2 seconds
- [ ] Messages transition: Queued → Sending → Delivered
- [ ] No duplicate messages from queue
- [ ] Cancel action removes message from queue and UI

### Network Monitoring
- [ ] Offline banner appears when disconnected
- [ ] Banner shows queue count: "Offline - X messages queued"
- [ ] Connected banner shows briefly on reconnect
- [ ] NetworkMonitor detects state changes < 1 second
- [ ] Banner slides smoothly, doesn't cover content

### Error Handling
- [ ] Online send failure shows red "Failed - Tap to retry"
- [ ] Retry action works correctly
- [ ] Failed messages stay in UI until retry succeeds
- [ ] Max 3 retry attempts for queued messages
- [ ] After 3 retries, message marked as failed

### Performance
- [ ] Optimistic UI update < 10ms
- [ ] Cache load time < 500ms offline
- [ ] Queue processing < 2 seconds for 10 messages
- [ ] No UI blocking during queue sync
- [ ] Smooth 60fps scrolling maintained
- [ ] App load time < 2-3 seconds (unchanged)

### Visual States
- [ ] Color coding clear: Gray (sending) → Yellow (queued) → Timestamp (delivered) → Red (failed)
- [ ] All animations smooth (status transitions, banner)
- [ ] No layout shifts or jarring updates
- [ ] No console warnings or errors

### Multi-Device
- [ ] Optimistic messages sync correctly across devices
- [ ] Queued messages appear on all devices after reconnect
- [ ] Correct chronological order maintained
- [ ] No race conditions or conflicts
```

---

## Notes

- **Optimistic UI is client-side only**: sendStatus field not persisted to Firestore
- **Queue storage**: UserDefaults sufficient for MVP (small data, reliable)
- **Threading**: NetworkMonitor runs on background queue, updates UI on main thread
- **Testing**: Focus on airplane mode testing for offline scenarios
- **Performance**: Keep UI responsive during queue processing (async operations)
- **Reference**: Follow `Psst/agents/shared-standards.md` for threading and performance patterns
- **Priority**: Test edge cases thoroughly (app kill, network flicker, large queue)

