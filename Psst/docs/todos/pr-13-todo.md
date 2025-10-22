# PR-13 TODO — Typing Indicators

**Branch**: `feat/pr-13-typing-indicators`  
**Source PRD**: `Psst/docs/prds/pr-13-prd.md`  
**Owner (Agent)**: Caleb

---

## 0. Clarifying Questions & Assumptions

- Questions: None - PRD is comprehensive
- Assumptions (confirm in PR if needed):
  - Typing timeout: 3 seconds (confirmed in PRD)
  - Broadcast throttle: 500ms max (2 writes per second to prevent Firebase spam)
  - Firebase Realtime Database already configured from PR #12 (presence system)
  - Animated dots pattern: sequential fade (... → .. → . → ...)
  - Typing indicators only shown for online users (integration with PresenceService)
  - Display names fetched from UserService (existing from PR #3)

---

## 1. Setup

- [x] Create branch `feat/pr-13-typing-indicators` from develop
- [x] Read PRD thoroughly (`Psst/docs/prds/pr-13-prd.md`)
- [x] Read `Psst/agents/shared-standards.md` for patterns
- [x] Verify Firebase Realtime Database is configured from PR #12
- [x] Confirm PresenceService is working (from PR #12)
- [x] Verify ChatView exists and is functional (from PRs 7, 10)
- [x] Verify MessageInputView exists (from PR #7)

---

## 2. Data Model

Create TypingStatus Swift model.

- [x] Create `Psst/Psst/Models/TypingStatus.swift`
  - Test Gate: File created in Models folder

- [x] Define TypingStatus struct
  ```swift
  struct TypingStatus: Identifiable, Codable {
      let id: String          // userID
      var isTyping: Bool      // derived from status
      var timestamp: Date     // when they started typing
      var expiresAt: Date     // when status should expire (timestamp + 3s)
  }
  ```
  - Test Gate: Struct compiles without errors

- [x] Add initializer
  ```swift
  init(id: String, isTyping: Bool, timestamp: Date = Date(), expiresAt: Date = Date().addingTimeInterval(3)) {
      self.id = id
      self.isTyping = isTyping
      self.timestamp = timestamp
      self.expiresAt = expiresAt
  }
  ```
  - Test Gate: Can create sample TypingStatus instance

- [x] Test model with sample data
  - Test Gate: TypingStatus model encodes/decodes correctly

---

## 3. Service Layer - TypingIndicatorService

Implement Firebase Realtime Database typing status tracking.

### 3.1: Create TypingIndicatorService File

- [x] Create `Psst/Psst/Services/TypingIndicatorService.swift`
  - Test Gate: File created in Services folder

- [x] Add imports
  ```swift
  import Foundation
  import FirebaseDatabase
  ```
  - Test Gate: Imports resolve without errors

- [x] Define TypingIndicatorService class structure
  ```swift
  class TypingIndicatorService: ObservableObject {
      private let database = Database.database().reference()
      private var typingRefs: [String: DatabaseReference] = [:]
      private var typingTimers: [String: Timer] = [:]
      private var lastBroadcastTime: [String: Date] = [:]
      
      private let typingTimeout: TimeInterval = 3.0  // 3 seconds
      private let broadcastThrottle: TimeInterval = 0.5  // 500ms
  }
  ```
  - Test Gate: Class compiles, all properties defined

### 3.2: Implement startTyping()

- [x] Add startTyping method signature
  ```swift
  func startTyping(chatID: String, userID: String) async throws
  ```
  - Test Gate: Method signature compiles

- [x] Implement debouncing/throttling logic
  - Step 1: Create key "\(chatID)_\(userID)"
  - Step 2: Check lastBroadcastTime dictionary
  - Step 3: If last broadcast < 500ms ago, return early (skip broadcast)
  - Step 4: Update lastBroadcastTime[key] = Date()
  - Test Gate: Throttling logic compiles

- [x] Implement typing data write
  - Step 1: Create typingRef to `/typing/{chatID}/{userID}`
  - Step 2: Create typingData dictionary with "status": "typing", "timestamp", "expiresAt"
  - Step 3: Use `ServerValue.timestamp()` for timestamp
  - Step 4: Call `setValue(typingData)` with async/await
  - Test Gate: Method compiles without errors

- [x] Call setupTypingTimeout() after write
  - Pass chatID and userID to setup 3-second timer
  - Test Gate: Timeout setup called

- [x] Add error handling
  - Wrap in do-catch for Firebase errors
  - Log errors with print statements
  - Rethrow errors for caller to handle
  - Test Gate: Errors logged clearly

- [x] Test startTyping manually
  - Test Gate: Call with valid chatID/userID succeeds
  - Test Gate: Firebase Console shows `/typing/{chatID}/{userID}` data
  - Test Gate: Multiple rapid calls throttled to 2/second

### 3.3: Implement stopTyping()

- [x] Add stopTyping method signature
  ```swift
  func stopTyping(chatID: String, userID: String) async throws
  ```
  - Test Gate: Method signature compiles

- [x] Implement typing data removal
  - Step 1: Create typingRef to `/typing/{chatID}/{userID}`
  - Step 2: Call `removeValue()` with async/await
  - Test Gate: Removal logic compiles

- [x] Cancel associated timer
  - Step 1: Create key "\(chatID)_\(userID)"
  - Step 2: Get timer from typingTimers dictionary
  - Step 3: Call `timer.invalidate()`
  - Step 4: Remove from typingTimers dictionary
  - Test Gate: Timer cleanup compiles

- [x] Add error handling
  - Wrap in do-catch
  - Log errors for debugging
  - Rethrow errors
  - Test Gate: Errors handled

- [x] Test stopTyping manually
  - Test Gate: Typing data removed from Firebase
  - Test Gate: Timer cancelled
  - Test Gate: No more automatic clears

### 3.4: Implement observeTypingUsers()

- [x] Add observeTypingUsers method signature
  ```swift
  func observeTypingUsers(chatID: String, completion: @escaping ([String]) -> Void) -> DatabaseReference
  ```
  - Test Gate: Method signature compiles

- [x] Implement Firebase listener attachment
  - Step 1: Create typingRef to `/typing/{chatID}`
  - Step 2: Attach `.observe(.value)` listener
  - Step 3: Parse snapshot.value as [String: Any]
  - Step 4: Extract all userID keys from dictionary
  - Test Gate: Listener attaches without errors

- [x] Filter expired typing statuses
  - Step 1: For each userID, check if userData has "expiresAt"
  - Step 2: Parse expiresAt as Double (timestamp)
  - Step 3: Convert to Date
  - Step 4: Filter out if expirationDate < Date() (expired)
  - Test Gate: Expiration filter compiles

- [x] Handle missing or invalid data
  - Default to empty array if snapshot.value is nil
  - Default to empty array if parsing fails
  - Log warnings for debugging
  - Test Gate: Invalid data handled gracefully

- [x] Store reference for cleanup
  - Add to `typingRefs[chatID]` dictionary
  - Return DatabaseReference for caller
  - Test Gate: Reference stored correctly

- [x] Test observeTypingUsers manually
  - Test Gate: Listener fires immediately with current typing users
  - Test Gate: Listener fires when typing status changes in Firebase Console
  - Test Gate: Expired users filtered out correctly

### 3.5: Implement stopObserving()

- [x] Add stopObserving method signature
  ```swift
  func stopObserving(chatID: String)
  ```
  - Test Gate: Method signature compiles

- [x] Implement listener removal
  - Step 1: Check if typingRefs[chatID] exists
  - Step 2: Call `ref.removeAllObservers()`
  - Step 3: Remove from typingRefs dictionary
  - Step 4: Add print statement for debugging
  - Test Gate: Listener removed without errors

- [x] Test stopObserving manually
  - Test Gate: After calling, listener no longer fires
  - Test Gate: typingRefs dictionary cleaned up

### 3.6: Implement stopAllObservers()

- [x] Add stopAllObservers method signature
  ```swift
  func stopAllObservers()
  ```
  - Test Gate: Method signature compiles

- [x] Implement cleanup logic
  - Step 1: Iterate through typingRefs dictionary
  - Step 2: Call removeAllObservers() on each reference
  - Step 3: Clear typingRefs dictionary
  - Step 4: Iterate through typingTimers dictionary
  - Step 5: Call invalidate() on each timer
  - Step 6: Clear typingTimers dictionary
  - Test Gate: All listeners and timers cleaned up

- [x] Test stopAllObservers manually
  - Test Gate: All active listeners stopped
  - Test Gate: All timers cancelled
  - Test Gate: Both dictionaries empty after call

### 3.7: Implement setupTypingTimeout() (Private Helper)

- [x] Add setupTypingTimeout private method signature
  ```swift
  private func setupTypingTimeout(chatID: String, userID: String)
  ```
  - Test Gate: Method signature compiles

- [x] Implement timer logic
  - Step 1: Create key "\(chatID)_\(userID)"
  - Step 2: Cancel existing timer for this key if exists
  - Step 3: Create new Timer.scheduledTimer with 3.0 second interval
  - Step 4: In timer callback: Call stopTyping(chatID, userID) in Task
  - Step 5: Store timer in typingTimers[key]
  - Test Gate: Timer creation compiles

- [x] Test timeout manually
  - Test Gate: Timer fires after 3 seconds
  - Test Gate: stopTyping() called automatically
  - Test Gate: Typing status cleared in Firebase

### 3.8: Add Error Handling and Logging

- [x] Add error logging throughout TypingIndicatorService
  - Log when startTyping succeeds/fails
  - Log when stopTyping succeeds/fails
  - Log when observeTypingUsers encounters bad data
  - Use descriptive print statements with "[TypingIndicatorService]" prefix
  - Test Gate: Errors logged clearly in console

- [x] Test error scenarios
  - Test Gate: Network error doesn't crash app
  - Test Gate: Invalid chatID handled gracefully
  - Test Gate: Invalid userID handled gracefully

---

## 4. UI Components

Create typing indicator view and integrate into chat.

### 4.1: Create TypingIndicatorView Component

- [x] Create `Psst/Psst/Views/Components/TypingIndicatorView.swift`
  - Test Gate: File created in Components folder

- [x] Implement basic TypingIndicatorView structure
  ```swift
  struct TypingIndicatorView: View {
      let typingUserNames: [String]
      @State private var animationPhase: Int = 0
      
      var body: some View {
          // Implementation
      }
  }
  ```
  - Test Gate: View compiles

- [x] Implement conditional rendering
  - Show view only if typingUserNames is not empty
  - Use if statement: `if !typingUserNames.isEmpty { ... }`
  - Test Gate: Conditional logic compiles

- [x] Implement display text logic
  ```swift
  private var displayText: String {
      switch typingUserNames.count {
      case 0: return ""
      case 1: return "\(typingUserNames[0]) is typing"
      case 2: return "\(typingUserNames[0]) and \(typingUserNames[1]) are typing"
      default:
          let others = typingUserNames.count - 1
          return "\(typingUserNames[0]) and \(others) others are typing"
      }
  }
  ```
  - Test Gate: Display text computed property compiles

- [x] Implement animated dots
  ```swift
  HStack(spacing: 2) {
      ForEach(0..<3, id: \.self) { index in
          Circle()
              .fill(Color.secondary)
              .frame(width: 3, height: 3)
              .opacity(animationPhase == index ? 0.3 : 1.0)
      }
  }
  ```
  - Test Gate: Animated dots render

- [x] Implement animation timer
  ```swift
  .onAppear {
      Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { _ in
          withAnimation {
              animationPhase = (animationPhase + 1) % 3
          }
      }
  }
  ```
  - Test Gate: Animation loops continuously

- [x] Add styling
  - Font: .caption
  - Color: .secondary
  - Padding: horizontal 16, vertical 8
  - Test Gate: Styling applied correctly

- [x] Add transitions
  - Use `.transition(.opacity)`
  - Use `.animation(.easeInOut(duration: 0.2), value: typingUserNames.count)`
  - Test Gate: Fade-in/fade-out smooth

- [x] Add SwiftUI preview
  - Preview with 1 user typing
  - Preview with 2 users typing
  - Preview with 3+ users typing
  - Test Gate: All previews render correctly

- [x] Test TypingIndicatorView
  - Test Gate: View renders with sample data
  - Test Gate: Animation loops smoothly
  - Test Gate: Display text formats correctly for 1, 2, 3+ users

### 4.2: Modify ChatView for Typing Indicators

- [x] Open `Psst/Psst/Views/ChatList/ChatView.swift`
  - Test Gate: File exists from PR #7, modified in PR #10

- [x] Add TypingIndicatorService to ChatView
  ```swift
  @StateObject private var typingIndicatorService = TypingIndicatorService()
  ```
  - Test Gate: StateObject compiles

- [x] Add state variables for typing
  ```swift
  @State private var typingUserIDs: [String] = []
  @State private var typingUserNames: [String] = []
  ```
  - Test Gate: State variables defined

- [x] Implement attachTypingListener() method
  ```swift
  private func attachTypingListener() {
      _ = typingIndicatorService.observeTypingUsers(chatID: chat.id) { userIDs in
          DispatchQueue.main.async {
              // Filter out current user
              let filteredIDs = userIDs.filter { $0 != self.currentUserID }
              self.typingUserIDs = filteredIDs
              self.fetchDisplayNames(for: filteredIDs)
          }
      }
  }
  ```
  - Test Gate: Method compiles

- [x] Implement detachTypingListener() method
  ```swift
  private func detachTypingListener() {
      typingIndicatorService.stopObserving(chatID: chat.id)
  }
  ```
  - Test Gate: Method compiles

- [x] Implement fetchDisplayNames() method
  ```swift
  private func fetchDisplayNames(for userIDs: [String]) {
      Task {
          var names: [String] = []
          for userID in userIDs {
              if let user = try? await UserService.shared.fetchUser(by: userID) {
                  names.append(user.displayName)
              }
          }
          await MainActor.run {
              self.typingUserNames = names
          }
      }
  }
  ```
  - Test Gate: Method compiles

- [x] Add attachTypingListener to .onAppear
  - Call after existing presence listener attachment
  - Test Gate: Listener attached when view appears

- [x] Add detachTypingListener to .onDisappear
  - Call after existing presence listener detachment
  - Test Gate: Listener detached when view disappears

- [x] Add TypingIndicatorView to UI hierarchy
  - Position between message list (ScrollView) and MessageInputView
  - Inside VStack after NetworkStatusBanner and messageListView
  - Before MessageInputView
  - Test Gate: View positioned correctly

- [x] Pass typingUserNames to TypingIndicatorView
  ```swift
  TypingIndicatorView(typingUserNames: typingUserNames)
  ```
  - Test Gate: Binding works correctly

- [x] Test ChatView integration
  - Test Gate: TypingIndicatorView appears when someone types
  - Test Gate: Current user is filtered out (doesn't see own typing)
  - Test Gate: Display names fetched and shown correctly
  - Test Gate: Listener attaches/detaches without errors

### 4.3: Modify MessageInputView for Typing Broadcasts

- [x] Open `Psst/Psst/Views/ChatList/MessageInputView.swift`
  - Test Gate: File exists from PR #7

- [x] Add parameters to MessageInputView
  ```swift
  struct MessageInputView: View {
      @Binding var text: String
      let onSend: () -> Void
      let chatID: String  // NEW
      let userID: String  // NEW
      let typingIndicatorService: TypingIndicatorService  // NEW
  }
  ```
  - Test Gate: New parameters compile

- [x] Add .onChange modifier for text field
  ```swift
  .onChange(of: text) { oldValue, newValue in
      handleTextChange(newValue)
  }
  ```
  - Test Gate: onChange modifier compiles

- [x] Implement handleTextChange() method
  ```swift
  private func handleTextChange(_ newText: String) {
      let trimmed = newText.trimmingCharacters(in: .whitespacesAndNewlines)
      
      if trimmed.isEmpty {
          // User deleted all text - stop typing
          Task {
              try? await typingIndicatorService.stopTyping(chatID: chatID, userID: userID)
          }
      } else {
          // User is typing - broadcast status
          Task {
              try? await typingIndicatorService.startTyping(chatID: chatID, userID: userID)
          }
      }
  }
  ```
  - Test Gate: Method compiles

- [x] Modify onSend handler to clear typing
  - Before calling the original onSend closure
  - Add: `Task { try? await typingIndicatorService.stopTyping(chatID: chatID, userID: userID) }`
  - Test Gate: Typing cleared on send

- [x] Update ChatView to pass new parameters
  - Pass chat.id for chatID
  - Pass currentUserID for userID
  - Pass typingIndicatorService instance
  - Test Gate: All parameters passed correctly

- [x] Test MessageInputView changes
  - Test Gate: Typing starts when text entered
  - Test Gate: Typing stops when text cleared
  - Test Gate: Typing stops when message sent
  - Test Gate: Firebase receives typing status

---

## 5. Firebase Configuration

Deploy Firebase Realtime Database security rules for typing.

- [x] Create Firebase Realtime Database security rules for typing
  ```json
  {
    "rules": {
      "typing": {
        "$chatID": {
          "$uid": {
            ".read": "auth != null",
            ".write": "$uid === auth.uid"
          }
        }
      }
    }
  }
  ```
  - Test Gate: Rules JSON defined in firebase-realtime-database-rules.json

- [ ] Deploy rules to Firebase Console
  - Navigate to Firebase Console → Realtime Database → Rules
  - Copy contents of firebase-realtime-database-rules.json
  - Paste and publish rules
  - Test Gate: Rules deployed successfully

- [ ] Test security rules
  - Test Gate: Authenticated user can write their own typing status
  - Test Gate: User CANNOT write another user's typing status
  - Test Gate: Authenticated user can read typing status for any chat
  - Test Gate: Unauthenticated user CANNOT read or write typing status

- [ ] Verify rules in Firebase Console
  - Test Gate: Rules visible in Firebase Console
  - Test Gate: Last modified timestamp updated

---

## 6. Manual Testing Validation

**Current**: Manual testing validation (see `Psst/agents/shared-standards.md`)

### Configuration Testing

- [ ] **Firebase Realtime Database typing path accessible**
  - Test Gate: Firebase Console shows `/typing/{chatID}/{userID}` structure
  - Test Gate: No connection errors in Xcode console

- [ ] **Security rules deployed correctly**
  - Test Gate: Rules JSON visible in Firebase Console
  - Test Gate: Write from non-member fails (test in Console)

- [ ] **TypingIndicatorService initializes without errors**
  - Test Gate: App launches with TypingIndicatorService
  - Test Gate: No initialization errors in console

### Happy Path Testing

- [ ] **User types → Typing indicator appears on other devices**
  - Test Gate: User A starts typing in chat
  - Test Gate: User B sees "[Alice] is typing..." within 100ms
  - Test Gate: Firebase Console shows typing status

- [ ] **User stops typing → Typing indicator disappears after 3 seconds**
  - Test Gate: User A types, then stops (don't delete text)
  - Test Gate: User B sees indicator disappear within 3 seconds
  - Test Gate: Firebase typing status cleared

- [ ] **User sends message → Typing indicator disappears immediately**
  - Test Gate: User A types, then sends message
  - Test Gate: User B sees indicator disappear immediately (not 3 seconds later)
  - Test Gate: Indicator disappears before message appears

- [ ] **User deletes all text → Typing indicator disappears**
  - Test Gate: User A types some text
  - Test Gate: User A deletes all text (empty input)
  - Test Gate: User B sees indicator disappear within 100ms

- [ ] **Typing indicator displays in Chat View**
  - Test Gate: Visual verification: "[Name] is typing..." renders below message list
  - Test Gate: Animated dots loop smoothly (... → .. → . → ...)
  - Test Gate: Indicator positioned above input bar, below messages

### Edge Cases Testing

- [ ] **Empty input → No typing status broadcasted**
  - Test Gate: Input field is empty
  - Test Gate: No typing data in Firebase for current user
  - Test Gate: Other users don't see typing indicator

- [ ] **User leaves chat while typing → Typing status cleared**
  - Test Gate: User A is typing in chat
  - Test Gate: User A backs out of chat (navigation back)
  - Test Gate: User B sees indicator disappear within 1 second

- [ ] **App backgrounded while typing → Typing status cleared**
  - Test Gate: User A is typing
  - Test Gate: User A presses home button (backgrounds app)
  - Test Gate: User B sees indicator disappear within 3 seconds

- [ ] **User goes offline while typing → Typing status cleared**
  - Test Gate: User A is typing
  - Test Gate: User A goes offline (airplane mode or force quit)
  - Test Gate: User B sees indicator disappear immediately

- [ ] **Current user is excluded from typing display**
  - Test Gate: User A types in chat
  - Test Gate: User A does NOT see their own typing indicator
  - Test Gate: Only other users' typing shown

- [ ] **Invalid chat ID → Graceful failure**
  - Test Gate: Call observeTypingUsers() with non-existent chatID
  - Test Gate: Returns empty array, doesn't crash
  - Test Gate: Error logged for debugging

### Multi-User Testing (1-on-1 Chat)

**Setup:** 2 devices logged in as different users

- [ ] **User A types → User B sees typing indicator**
  - Test Gate: Device A (User A) starts typing
  - Test Gate: Device B (User B) sees "Alice is typing..." within 100ms

- [ ] **User A stops → Typing indicator clears after 3 seconds**
  - Test Gate: User A stops typing (keeps text)
  - Test Gate: Device B sees indicator disappear within 3 seconds

- [ ] **User A sends message → Typing indicator clears immediately**
  - Test Gate: User A sends message
  - Test Gate: Device B sees indicator disappear before message appears

- [ ] **Both users type simultaneously → Each sees the other's indicator**
  - Test Gate: Both User A and User B type at same time
  - Test Gate: User A sees "Bob is typing..."
  - Test Gate: User B sees "Alice is typing..."

### Multi-User Testing (Group Chat)

**Setup:** 3+ devices logged in as different users in same group chat

- [ ] **One person typing → Shows "[Name] is typing..."**
  - Test Gate: User A types in group chat
  - Test Gate: Users B, C, D all see "Alice is typing..."

- [ ] **Two people typing → Shows "[Name1] and [Name2] are typing..."**
  - Test Gate: User A and User B both type
  - Test Gate: User C sees "Alice and Bob are typing..."

- [ ] **Three+ people typing → Shows "[Name] and [N] others are typing..."**
  - Test Gate: Users A, B, C all type simultaneously
  - Test Gate: User D sees "Alice and 2 others are typing..."

- [ ] **Users stop typing at different times → Indicator updates correctly**
  - Test Gate: 3 users typing (A, B, C)
  - Test Gate: User A stops typing
  - Test Gate: Others see "Bob and Carol are typing..."
  - Test Gate: 2 more users stop
  - Test Gate: Indicator disappears

### Performance Testing

Reference targets from `Psst/agents/shared-standards.md`:

- [ ] **Typing update latency < 100ms**
  - Test Gate: Measure time from keypress to indicator display on other device
  - Test Gate: Latency is consistently < 100ms

- [ ] **Message send latency unchanged (< 100ms)**
  - Test Gate: Send messages as normal
  - Test Gate: Latency still meets PR #8 targets

- [ ] **Smooth 60fps scrolling with typing indicators**
  - Test Gate: Chat view with 100+ messages
  - Test Gate: Typing indicator visible
  - Test Gate: Scroll rapidly up and down
  - Test Gate: No jank or frame drops
  - Test Gate: Use Instruments to verify 60fps maintained

- [ ] **Typing updates don't block main thread**
  - Test Gate: Enable Main Thread Checker in Xcode
  - Test Gate: Type in chat, watch typing indicators
  - Test Gate: No Main Thread Checker violations
  - Test Gate: UI remains responsive

- [ ] **Firebase writes throttled**
  - Test Gate: Type very rapidly (mash keyboard)
  - Test Gate: Firebase Console shows max 2 writes per second
  - Test Gate: Use Firebase usage metrics to verify throttling

### Memory & Lifecycle Testing

- [ ] **No memory leaks from typing listeners**
  - Test Gate: Open Xcode Memory Debugger
  - Test Gate: Open and close 10+ chats (type in each)
  - Test Gate: Memory usage remains stable (no continuous growth)
  - Test Gate: Use Instruments Leaks tool to verify no leaks

- [ ] **Timers properly cleaned up**
  - Test Gate: Type in chat (starts timer)
  - Test Gate: Navigate away from chat
  - Test Gate: Verify timer is cancelled (set breakpoint in stopTyping)
  - Test Gate: No zombie timers running

- [ ] **Listeners properly cleaned up on view disappear**
  - Test Gate: Set breakpoint in stopObserving()
  - Test Gate: Navigate away from chat
  - Test Gate: Breakpoint hits, listener removed
  - Test Gate: typingRefs dictionary cleaned up

- [ ] **Listeners cleaned up on logout**
  - Test Gate: Login, type in several chats (attach listeners)
  - Test Gate: Logout
  - Test Gate: Verify stopAllObservers() called
  - Test Gate: typingRefs and typingTimers dictionaries empty
  - Test Gate: No dangling Firebase references

### Animation & UI Testing

- [ ] **Typing indicator animates smoothly**
  - Test Gate: Visual verification: Dots animate in sequence (... → .. → . → ...)
  - Test Gate: Animation loops continuously while typing status active
  - Test Gate: 0.6 second loop timing feels natural

- [ ] **Typing indicator appears/disappears smoothly**
  - Test Gate: Fade-in transition (0.2s) when indicator appears
  - Test Gate: Fade-out transition (0.2s) when indicator disappears
  - Test Gate: No abrupt appearance/disappearance

- [ ] **Typing indicator doesn't cause layout shifts**
  - Test Gate: Messages don't jump when typing indicator appears
  - Test Gate: Messages don't jump when typing indicator disappears
  - Test Gate: Input bar stays in same position
  - Test Gate: Scroll position preserved

---

## 7. Acceptance Gates

Check every gate from PRD Section 12:

- [ ] **All Configuration Testing gates pass** (3 gates)
- [ ] **All Happy Path Testing gates pass** (4 test scenarios)
- [ ] **All Edge Cases Testing gates pass** (6 test scenarios)
- [ ] **All Multi-User 1-on-1 Testing gates pass** (4 test scenarios)
- [ ] **All Multi-User Group Testing gates pass** (4 test scenarios)
- [ ] **All Performance Testing gates pass** (5 test scenarios)
- [ ] **All Memory & Lifecycle Testing gates pass** (4 test scenarios)
- [ ] **All Animation & UI Testing gates pass** (3 test scenarios)

**Total Gates:** 33 test scenarios across 8 categories

---

## 8. Documentation & PR

- [ ] Add inline code comments to TypingIndicatorService
  - Document each method's purpose
  - Explain throttling mechanism (500ms debounce)
  - Explain timeout mechanism (3-second auto-clear)
  - Note thread safety considerations
  - Test Gate: All public methods have documentation comments

- [ ] Add code comments to UI integration
  - Explain typing listener lifecycle in ChatView
  - Explain typing broadcast logic in MessageInputView
  - Note main thread dispatch for UI updates
  - Test Gate: Complex logic commented

- [ ] Update README if needed
  - Note typing indicator feature
  - Mention Firebase Realtime Database usage (already from PR #12)
  - Test Gate: README accurate and up-to-date

- [ ] Create PR description using template
  ```markdown
  # PR #13: Typing Indicators
  
  ## Summary
  Implements real-time "is typing..." indicators in chat views using Firebase Realtime Database with automatic 3-second timeout and animated dots UI.
  
  ## Changes
  - Created TypingIndicatorService for Firebase Realtime Database typing status
  - Implemented automatic typing timeout (3 seconds) and broadcast throttling (500ms)
  - Created TypingIndicatorView component with animated dots
  - Integrated typing indicators into ChatView (below messages, above input)
  - Modified MessageInputView to broadcast typing on text change
  - Configured Firebase security rules for /typing path
  - Integrated with PresenceService (only show for online users)
  
  ## Testing
  - [x] Configuration testing (Firebase, rules, service initialization)
  - [x] Happy path testing (typing appears/disappears, 3s timeout, immediate clear on send)
  - [x] Edge cases testing (leave chat, offline, empty input, current user excluded)
  - [x] Multi-user 1-on-1 testing (2 devices, simultaneous typing)
  - [x] Multi-user group testing (3+ devices, multiple typers, smart display)
  - [x] Performance testing (latency <100ms, throttling, 60fps)
  - [x] Memory & lifecycle testing (no leaks, timers cleaned, listeners detached)
  - [x] Animation & UI testing (smooth transitions, no layout shifts)
  
  ## Related
  - PRD: `Psst/docs/prds/pr-13-prd.md`
  - TODO: `Psst/docs/todos/pr-13-todo.md`
  - Depends on: PR #12 (Presence System)
  ```
  - Test Gate: PR description complete

- [ ] Verify with user before creating PR
  - Show summary of changes
  - Confirm all acceptance gates passed
  - Get explicit approval to create PR
  - Test Gate: User approval received

- [ ] Open PR to develop branch
  - Branch: `feat/pr-13-typing-indicators`
  - Target: `develop`
  - Link PRD and TODO in description
  - Test Gate: PR created successfully

---

## Copyable Checklist (for PR description)

```markdown
- [ ] Branch created from develop
- [ ] All TODO tasks completed
- [ ] TypingIndicatorService implemented with proper error handling
- [ ] TypingStatus model created
- [ ] TypingIndicatorView SwiftUI component created with animated dots
- [ ] ChatView displays typing indicator and manages listeners
- [ ] MessageInputView broadcasts typing on text change
- [ ] Firebase Realtime Database security rules deployed for /typing path
- [ ] Real-time sync verified across 2+ devices (<100ms latency)
- [ ] Automatic 3-second timeout tested and working
- [ ] Broadcast throttling verified (max 2 writes/second)
- [ ] Multi-user 1-on-1 typing tested (2 devices)
- [ ] Multi-user group typing tested (3+ devices, multiple typers)
- [ ] Performance targets met (latency <100ms, 60fps scrolling)
- [ ] No memory leaks (verified with Instruments)
- [ ] Timers properly cleaned up
- [ ] All acceptance gates pass (33 test scenarios)
- [ ] Code follows Psst/agents/shared-standards.md patterns
- [ ] Main Thread Checker: No violations
- [ ] No console warnings or errors
- [ ] Documentation updated (inline comments, README)
```

---

## Notes

- Break tasks into <30 min chunks
- Complete tasks sequentially (data model → service → UI → testing)
- Check off after completion
- Document blockers immediately
- Reference `Psst/agents/shared-standards.md` for common patterns
- **Critical:** Test throttling early (prevents Firebase quota exhaustion)
- **Critical:** Verify 3-second timeout accuracy (core user expectation)
- **Critical:** Check for memory leaks (timers and listeners must be cleaned up)
- **Critical:** Test multi-device typing scenarios (1-on-1 and group chat)
- **Critical:** Verify animations are smooth and not distracting
- **Critical:** Ensure current user never sees their own typing indicator
- Use Firebase Console to verify typing data structure during development
- Test with physical devices when possible (simulators may not fully test real-time sync)
- Monitor Firebase usage during testing (throttling should keep usage low)
- Integration with PresenceService: Only show typing for online users

