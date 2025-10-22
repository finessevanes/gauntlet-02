# PRD: Typing Indicators

**Feature**: Typing Indicators ("is typing...")

**Version**: 1.0

**Status**: Ready for Development

**Agent**: Pam

**Target Release**: Phase 3

**Links**: [PR Brief: PR #13](../pr-briefs.md), [TODO](../todos/pr-13-todo.md), [Architecture](../architecture.md), [PR #12 PRD](./pr-12-prd.md)

---

## 1. Summary

Users need visual feedback when others are actively composing messages in a conversation. This PR implements real-time typing indicators that display "is typing..." notifications in chat views, using Firebase Realtime Database with automatic 3-second timeouts to show when contacts are actively typing and handle inactivity gracefully.

---

## 2. Problem & Goals

**Problem:** Users currently cannot tell when someone is actively composing a response in a conversation. This leads to:
- Uncertainty about whether to wait for a reply or move on to another conversation
- Awkward conversation timing where users send simultaneous messages
- Missing the real-time, immediate feeling that makes messaging apps engaging
- Reduced perceived responsiveness even when contacts are actively responding
- Poor user experience compared to modern messaging apps (WhatsApp, iMessage, Telegram)

**Why now?**
- Core messaging functionality (PRs 1-8) is complete
- Presence system (PR #12) is implemented and provides the Firebase Realtime Database infrastructure
- Users already see online/offline status, typing indicators are the natural next step
- This enhances the real-time feel before moving to read receipts (PR #14) and notifications (PRs 15-16)
- Required for Phase 3 completion before moving to Phase 4 polish

**Goals (ordered, measurable):**
- [x] G1 — Implement real-time typing status that broadcasts when users start/stop typing with <100ms latency
- [x] G2 — Display "is typing..." indicator in chat view when one or more users are actively composing messages
- [x] G3 — Automatically clear typing status after 3 seconds of inactivity to prevent stale indicators

---

## 3. Non-Goals / Out of Scope

Call out what's intentionally excluded to avoid scope creep.

- [ ] Not implementing typing indicators in the Conversation List — Only showing in active chat views to reduce noise
- [ ] Not showing what the user is typing (preview text) — Privacy concern, just showing that they're typing
- [ ] Not showing typing indicators for users who are offline — They can't be typing if they're offline
- [ ] Not implementing "seen by" or read receipts — This is separate PR #14
- [ ] Not showing typing indicators for group chat members in the conversation list — Too complex for MVP
- [ ] Not persisting typing state across app restarts — Ephemeral state by design

---

## 4. Success Metrics

Reference `Psst/agents/shared-standards.md` for metric templates:

**User-visible:**
- Time to see typing indicator: < 100ms from keypress to display on other devices
- Typing indicator accuracy: >95% correct state (typing when actually typing, cleared when stopped)
- User taps to see typing: 0 (always visible, no interaction needed)
- False positive rate: <5% (indicator cleared within 3 seconds of inactivity)

**System (from shared-standards.md):**
- Typing status update latency: < 100ms (keypress → Firebase → other devices)
- Firebase Realtime Database connection: maintains persistent connection established in PR #12
- App load time: < 2-3 seconds (no degradation from typing feature)
- UI performance: smooth 60fps with typing updates (no jank)
- Message delivery latency: < 100ms (unchanged from PR #8)

**Quality:**
- 0 blocking bugs in typing detection or display
- All acceptance gates pass (see Section 12)
- Crash-free rate >99% (typing service doesn't cause crashes)
- Typing indicator doesn't interfere with message sending
- No memory leaks from typing listeners

---

## 5. Users & Stories

**Primary User:** Any user engaged in an active conversation who wants to know if the other person is composing a response.

**User Stories:**

1. **As a user**, I want to see "is typing..." when my contact is composing a message so that I know they're actively responding and I should wait for their reply.

2. **As a user**, I want the typing indicator to appear immediately when someone starts typing so that I get real-time feedback about conversation activity.

3. **As a user**, I want the typing indicator to disappear automatically after a few seconds if the person stops typing so that I don't see stale status.

4. **As a user**, I want the typing indicator to disappear when a message is sent so that the UI feels responsive and accurate.

5. **As a group chat participant**, I want to see who is typing in group conversations (e.g., "Alice is typing..." or "Alice and 2 others are typing...") so that I know multiple people are composing responses.

6. **As a user**, I want my typing indicator to be sent to others automatically as I type so that they know I'm actively engaged without manual effort.

---

## 6. Experience Specification (UX)

### Entry Points and Flows

**Entry Point: Chat View (Primary)**
- User opens a 1-on-1 or group chat conversation
- Below the message list, there's a small typing indicator area
- **Default state:** Hidden (no indicator shown)
- **Typing state:** Shows "Alice is typing..." with animated dots (...)
- **Group typing state:** Shows "Alice and Bob are typing..." or "Alice and 2 others are typing..."

### Visual Behavior

**Typing Indicator Appearance:**
- **Location:** Below the message list, above the message input bar (sticky at bottom)
- **1-on-1 chat format:** "[Name] is typing..." with animated dots
- **Group chat (1 person):** "[Name] is typing..."
- **Group chat (2 people):** "[Name1] and [Name2] are typing..."
- **Group chat (3+ people):** "[Name1] and [N] others are typing..."
- **Styling:** 
  - Gray text color (`Color.secondary`)
  - Small font (`.caption` or `.footnote`)
  - Animated dots: `...` with fade-in/out animation (0.6s loop)
  - Left-aligned
  - Subtle appearance/disappearance animation (fade in 0.2s, fade out 0.2s)

**Animation Details:**
- **Dots animation:** Three dots that fade in and out sequentially (... → .. → . → ...)
- **Appearance:** Fade in from opacity 0 to 1 over 0.2 seconds
- **Disappearance:** Fade out from opacity 1 to 0 over 0.2 seconds

**Behavior Triggers:**

**Typing indicator appears when:**
1. User starts typing in the text field (after first character entered)
2. Firebase broadcasts typing status to other participants
3. Other users see indicator appear within 100ms

**Typing indicator disappears when:**
1. User sends a message (immediately)
2. User deletes all text in input field (back to empty)
3. User stops typing for 3 seconds (automatic timeout)
4. User navigates away from chat view
5. User goes offline (presence changes to offline)

### Empty States

**No typing activity:**
- Typing indicator area is hidden/collapsed (takes up no space)
- No placeholder or empty view shown

### Loading States

**Not applicable** — Typing status is ephemeral, no loading state needed

### Error States

**Firebase connection lost:**
- Continue showing last known typing status for up to 3 seconds
- If connection remains lost beyond 3 seconds, clear typing indicator
- No error message shown (typing is a "nice-to-have" feature, silent failure is acceptable)

**User goes offline:**
- Typing status automatically cleared by Firebase Realtime Database (similar to presence onDisconnect)
- Other users stop seeing typing indicator immediately

### Success States

**Typing indicator updates smoothly:**
- Indicator appears within 100ms of typing
- Indicator clears within 3 seconds of inactivity
- No toast/alert needed (silent feature)
- Smooth animations enhance perceived responsiveness

### Performance Targets (from shared-standards.md)

- **App load time**: < 2-3 seconds (typing indicators don't delay app launch)
- **Typing update latency**: < 100ms (keypress → Firebase → other devices)
- **Message delivery latency**: < 100ms (unchanged from PR #8)
- **Scrolling**: Smooth 60fps in chat view with typing indicators (no jank)
- **Tap feedback**: < 50ms response time (typing doesn't affect input responsiveness)
- **No UI blocking**: Typing status updates run on background thread
- **Smooth animations**: Typing indicator uses SwiftUI animation modifiers

---

## 7. Functional Requirements (Must/Should)

### MUST Requirements

**MUST-1: TypingIndicatorService Implementation**
- Create `Services/TypingIndicatorService.swift` with deterministic methods for typing management
- Service methods:
  - `startTyping(chatID: String, userID: String) async throws` — Broadcast typing status
  - `stopTyping(chatID: String, userID: String) async throws` — Clear typing status
  - `observeTypingUsers(chatID: String, completion: @escaping ([String]) -> Void) -> DatabaseReference` — Real-time listener for typing users
  - `stopObserving(chatID: String)` — Cleanup listener
- Use Firebase Realtime Database (same as PR #12 presence system)
- [Gate] TypingIndicatorService unit tests pass for valid/invalid inputs

**MUST-2: Typing Status Broadcast on Keypress**
- When user types in message input field (TextField), broadcast typing status
- Trigger on `.onChange(of: inputText)` when text is non-empty
- Write to Firebase path: `/typing/{chatID}/{userID} = { status: "typing", timestamp: ServerValue.timestamp() }`
- Debounce writes to Firebase (max 1 write per 500ms to avoid spam)
- [Gate] User types → Firebase shows typing status within 100ms
- [Gate] Typing broadcasts are throttled (verified in Firebase console)

**MUST-3: Automatic Typing Timeout (3 seconds)**
- Use Firebase Realtime Database `onDisconnect()` and TTL mechanism to auto-clear typing status
- When writing typing status, set expiration: `{ status: "typing", timestamp: ServerValue.timestamp(), expiresAt: ServerValue.timestamp() + 3000 }`
- Client-side: Implement timer that clears status after 3 seconds of no keypress
- Server-side: Firebase expires old typing data (via scheduled cleanup or TTL)
- [Gate] User types, then stops → Typing status cleared within 3 seconds on all devices

**MUST-4: Clear Typing Status on Message Send**
- When user sends a message, immediately clear typing status
- Call `stopTyping()` in message send flow (before Firestore write)
- [Gate] User types, sends message → Typing indicator disappears immediately on all devices

**MUST-5: Clear Typing Status on Empty Input**
- When user deletes all text (input field becomes empty), clear typing status
- Trigger on `.onChange(of: inputText)` when `inputText.isEmpty`
- [Gate] User types, then deletes all text → Typing indicator cleared within 100ms

**MUST-6: Real-Time Typing Listeners**
- Implement Firebase Realtime Database listeners for active chat
- Chat view observes typing users for current chat: `/typing/{chatID}`
- Listener returns array of user IDs currently typing
- Fetch user display names for UI rendering
- [Gate] User A types on Device 1 → User B sees "Alice is typing..." on Device 2 within 100ms

**MUST-7: Typing Indicator Display in Chat View**
- Display typing indicator below message list, above input bar
- For 1-on-1 chats: "[Name] is typing..." with animated dots
- For group chats (1 person): "[Name] is typing..."
- For group chats (2 people): "[Name1] and [Name2] are typing..."
- For group chats (3+ people): "[Name1] and [N] others are typing..."
- Animated dots (three dots fading in/out sequentially)
- [Gate] Visual verification: Typing indicator renders correctly in 1-on-1 and group chats

**MUST-8: Exclude Current User from Typing Display**
- Typing indicator only shows other users' typing status
- Never show "You are typing..." for the current user
- Filter current user ID from typing users array before rendering
- [Gate] User types in chat → Does not see their own typing indicator

**MUST-9: Listener Lifecycle Management**
- Attach typing listener when chat view appears (`.onAppear`)
- Detach typing listener when chat view disappears (`.onDisappear`)
- Prevent memory leaks from dangling Firebase listeners
- Clear own typing status when leaving chat
- [Gate] Memory profiling: No listener leaks after opening/closing 10+ chats

**MUST-10: Integration with Presence System**
- Only show typing indicators for users who are currently online
- If user goes offline, automatically clear their typing status
- Use existing PresenceService from PR #12 to check online status
- [Gate] User A types, then goes offline → User B sees typing indicator disappear within 3 seconds

**MUST-11: Performance Requirements**
- Typing feature doesn't degrade message send latency (< 100ms maintained)
- Typing updates don't block main thread
- Scrolling remains smooth 60fps with typing indicators
- Typing broadcasts throttled to prevent Firebase quota exhaustion
- [Gate] Instruments profiling: 60fps maintained, main thread not blocked

### SHOULD Requirements

**SHOULD-1: Debounced Typing Broadcasts**
- Throttle typing status writes to Firebase (1 write per 500ms)
- Prevents excessive Firebase writes on rapid typing
- [Gate] User types rapidly → Firebase receives max 2 writes per second

**SHOULD-2: Typing Indicator Animation**
- Animated dots (... → .. → . → ...) with 0.6s loop
- Smooth fade-in/fade-out transitions (0.2s)
- Enhances perceived real-time feel
- [Gate] Visual verification: Animation is smooth and not distracting

**SHOULD-3: Smart Display for Multiple Typers**
- Show up to 2 user names explicitly ("Alice and Bob are typing...")
- For 3+ typers: Show first name + count ("Alice and 2 others are typing...")
- Prioritize showing names of users with most recent typing activity
- [Gate] Group chat with 4 typers: Indicator shows "[Name] and 3 others are typing..."

**SHOULD-4: Typing Indicator Position**
- Sticky at bottom of chat view (above input bar)
- Doesn't push up message list (overlay/absolute positioning)
- Doesn't interfere with scrolling or message input
- [Gate] Visual verification: Typing indicator doesn't cause layout jumps

---

## 8. Data Model

### Firebase Realtime Database Schema

**Why Realtime Database?**
- Already established in PR #12 for presence system
- Lower latency for frequent small updates (typing events)
- Automatic expiration with `onDisconnect()` hooks
- Consistent with presence infrastructure

**Typing Schema:**

```swift
// Firebase Realtime Database path:
/typing
  /{chatID}
    /{userID}
      /status: "typing"
      /timestamp: <ServerValue.timestamp()>
      /expiresAt: <ServerValue.timestamp() + 3000>  // 3 seconds from now
```

**Example:**
```json
{
  "typing": {
    "chat123": {
      "user456": {
        "status": "typing",
        "timestamp": 1698345600000,
        "expiresAt": 1698345603000
      },
      "user789": {
        "status": "typing",
        "timestamp": 1698345601500,
        "expiresAt": 1698345604500
      }
    }
  }
}
```

### Swift Models

```swift
// Models/TypingStatus.swift
struct TypingStatus: Identifiable, Codable {
    let id: String          // userID
    var isTyping: Bool      // derived from status
    var timestamp: Date     // when they started typing
    var expiresAt: Date     // when status should expire
    
    init(id: String, isTyping: Bool, timestamp: Date = Date(), expiresAt: Date = Date().addingTimeInterval(3)) {
        self.id = id
        self.isTyping = isTyping
        self.timestamp = timestamp
        self.expiresAt = expiresAt
    }
}
```

### Validation Rules

**Firebase Realtime Database Security Rules:**

```json
{
  "rules": {
    "typing": {
      "$chatID": {
        "$uid": {
          ".read": "auth != null && root.child('chats').child($chatID).child('members').val().contains(auth.uid)",
          ".write": "$uid === auth.uid"
        }
      }
    }
  }
}
```

**Field Constraints:**
- `status`: Must be "typing" (simplified - presence is removed by deletion)
- `timestamp`: Must be Firebase ServerValue.timestamp()
- `expiresAt`: Must be timestamp + 3000ms (3 seconds)
- `userID`: Must match authenticated user's UID (enforced by security rules)
- `chatID`: Must be a valid chat that the user is a member of

**Indexing/Queries:**
- No indexes needed (simple key lookups by chatID)
- Listeners are attached per chat: `/typing/{chatID}`
- Returns all userIDs currently typing in that chat

---

## 9. API / Service Contracts

### TypingIndicatorService.swift

```swift
// Services/TypingIndicatorService.swift

import Foundation
import FirebaseDatabase

class TypingIndicatorService: ObservableObject {
    private let database = Database.database().reference()
    private var typingRefs: [String: DatabaseReference] = [:]  // Track active listeners
    private var typingTimers: [String: Timer] = [:]  // Track timeout timers
    private var lastBroadcastTime: [String: Date] = [:]  // Track last broadcast per chat (for debouncing)
    
    private let typingTimeout: TimeInterval = 3.0  // 3 seconds
    private let broadcastThrottle: TimeInterval = 0.5  // 500ms
    
    // MARK: - Public Methods
    
    /// Broadcast typing status for the current user in a chat
    /// Automatically sets expiration for 3 seconds
    /// Throttled to max 1 broadcast per 500ms per chat
    /// - Parameters:
    ///   - chatID: The chat ID where user is typing
    ///   - userID: The user's Firebase UID
    /// - Throws: Firebase database errors
    func startTyping(chatID: String, userID: String) async throws {
        // Debounce: Check if we recently broadcasted
        let key = "\(chatID)_\(userID)"
        if let lastBroadcast = lastBroadcastTime[key],
           Date().timeIntervalSince(lastBroadcast) < broadcastThrottle {
            // Skip this broadcast (too soon after last one)
            return
        }
        
        let typingRef = database.child("typing").child(chatID).child(userID)
        
        let typingData: [String: Any] = [
            "status": "typing",
            "timestamp": ServerValue.timestamp(),
            "expiresAt": ServerValue.timestamp()  // Will be calculated as now + 3000ms client-side
        ]
        
        try await typingRef.setValue(typingData)
        lastBroadcastTime[key] = Date()
        
        // Set up auto-clear after 3 seconds (client-side timeout)
        setupTypingTimeout(chatID: chatID, userID: userID)
    }
    
    /// Clear typing status for the current user
    /// - Parameters:
    ///   - chatID: The chat ID
    ///   - userID: The user's Firebase UID
    /// - Throws: Firebase database errors
    func stopTyping(chatID: String, userID: String) async throws {
        let typingRef = database.child("typing").child(chatID).child(userID)
        
        // Remove typing data from Firebase
        try await typingRef.removeValue()
        
        // Cancel timer
        let key = "\(chatID)_\(userID)"
        typingTimers[key]?.invalidate()
        typingTimers.removeValue(forKey: key)
    }
    
    /// Observe typing users in a specific chat
    /// - Parameters:
    ///   - chatID: The chat ID to observe
    ///   - completion: Callback with array of user IDs currently typing
    /// - Returns: DatabaseReference for listener cleanup
    func observeTypingUsers(chatID: String, completion: @escaping ([String]) -> Void) -> DatabaseReference {
        let typingRef = database.child("typing").child(chatID)
        
        typingRef.observe(.value) { snapshot in
            guard let typingData = snapshot.value as? [String: Any] else {
                completion([])
                return
            }
            
            // Extract user IDs currently typing
            let typingUserIDs = typingData.keys.filter { userID in
                // Check if not expired
                if let userData = typingData[userID] as? [String: Any],
                   let expiresAt = userData["expiresAt"] as? Double {
                    let expirationDate = Date(timeIntervalSince1970: expiresAt / 1000)
                    return expirationDate > Date()
                }
                return true  // Include if no expiration data
            }
            
            completion(Array(typingUserIDs))
        }
        
        // Store reference for cleanup
        typingRefs[chatID] = typingRef
        return typingRef
    }
    
    /// Stop observing typing users for a chat
    /// - Parameter chatID: The chat ID to stop observing
    func stopObserving(chatID: String) {
        if let ref = typingRefs[chatID] {
            ref.removeAllObservers()
            typingRefs.removeValue(forKey: chatID)
        }
    }
    
    /// Stop all active typing listeners (call on logout)
    func stopAllObservers() {
        typingRefs.forEach { _, ref in
            ref.removeAllObservers()
        }
        typingRefs.removeAll()
        
        // Cancel all timers
        typingTimers.forEach { _, timer in
            timer.invalidate()
        }
        typingTimers.removeAll()
    }
    
    // MARK: - Private Methods
    
    /// Set up automatic timeout to clear typing status after 3 seconds
    private func setupTypingTimeout(chatID: String, userID: String) {
        let key = "\(chatID)_\(userID)"
        
        // Cancel existing timer for this chat/user
        typingTimers[key]?.invalidate()
        
        // Create new timer
        let timer = Timer.scheduledTimer(withTimeInterval: typingTimeout, repeats: false) { [weak self] _ in
            Task {
                try? await self?.stopTyping(chatID: chatID, userID: userID)
            }
        }
        
        typingTimers[key] = timer
    }
}
```

### Pre/Post-Conditions

**startTyping()**
- **Pre-conditions:**
  - User must be authenticated (userID is valid Firebase UID)
  - User must be a member of the chat (enforced by security rules)
  - Firebase Realtime Database connection available
- **Post-conditions:**
  - Typing data written to `/typing/{chatID}/{userID}`
  - Timeout timer started (3 seconds)
  - Broadcast throttled (max 1 per 500ms)
  - Completion within 100ms under normal network conditions

**stopTyping()**
- **Pre-conditions:**
  - User previously called startTyping for this chat
  - Firebase connection available
- **Post-conditions:**
  - Typing data removed from Firebase
  - Timer cancelled
  - Completion within 100ms

**observeTypingUsers()**
- **Pre-conditions:**
  - chatID must be valid
  - User must be a member of the chat (for security rules)
  - Firebase connection available
- **Post-conditions:**
  - Listener attached to `/typing/{chatID}`
  - Completion callback fires immediately with current typing users
  - Subsequent typing changes trigger callback in real-time
  - Expired typing statuses filtered out

**stopObserving()**
- **Pre-conditions:**
  - Listener was previously attached for the given chatID
- **Post-conditions:**
  - Listener detached from Firebase
  - No more callbacks for that chatID
  - Memory released

### Error Handling Strategy

**Network Errors:**
- If Firebase connection fails: Silently fail (typing is a "nice-to-have")
- No error message shown to user
- Automatically retry when connection restored

**Permission Errors:**
- If security rules deny write: Log error, fail silently
- If security rules deny read: Return empty array (no one typing)

**Invalid Data:**
- If typing snapshot has unexpected format: Return empty array
- Log warning for debugging but don't crash

**Timer Issues:**
- If timer fails to fire: Typing status will be cleaned up by next typing event or view disappear

---

## 10. UI Components to Create/Modify

### New Files to Create

- `Services/TypingIndicatorService.swift` — Firebase Realtime Database typing management (all methods from Section 9)
- `Models/TypingStatus.swift` — Swift model for typing data
- `Views/Components/TypingIndicatorView.swift` — Reusable SwiftUI view for typing indicator with animated dots

### Existing Files to Modify

- `Views/ChatList/ChatView.swift` — Add typing indicator display and listener management
- `Views/ChatList/MessageInputView.swift` — Add typing broadcast on text change

### Component Details

**TypingIndicatorView.swift:**
```swift
struct TypingIndicatorView: View {
    let typingUserNames: [String]  // Names of users currently typing
    @State private var animationPhase: Int = 0
    
    var body: some View {
        if !typingUserNames.isEmpty {
            HStack(spacing: 4) {
                Text(displayText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Animated dots
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(Color.secondary)
                            .frame(width: 3, height: 3)
                            .opacity(animationPhase == index ? 0.3 : 1.0)
                    }
                }
                .onAppear {
                    startAnimation()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.2), value: typingUserNames.count)
        }
    }
    
    private var displayText: String {
        switch typingUserNames.count {
        case 0:
            return ""
        case 1:
            return "\(typingUserNames[0]) is typing"
        case 2:
            return "\(typingUserNames[0]) and \(typingUserNames[1]) are typing"
        default:
            let others = typingUserNames.count - 1
            return "\(typingUserNames[0]) and \(others) others are typing"
        }
    }
    
    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { _ in
            withAnimation {
                animationPhase = (animationPhase + 1) % 3
            }
        }
    }
}
```

**ChatView.swift modifications:**
- Add `@StateObject private var typingIndicatorService = TypingIndicatorService()`
- Add `@State private var typingUserIDs: [String] = []`
- Add `@State private var typingUserNames: [String] = []`
- In `.onAppear`: Attach typing listener for chat
- In `.onDisappear`: Detach typing listener and clear own typing status
- Add TypingIndicatorView between message list and input bar
- When typing users change: Fetch user display names and update typingUserNames
- Filter out current user from typing display

**MessageInputView.swift modifications:**
- Accept TypingIndicatorService as parameter
- Add `.onChange(of: text)` modifier
- When text becomes non-empty: Call `typingIndicatorService.startTyping()`
- When text becomes empty: Call `typingIndicatorService.stopTyping()`
- When send button tapped: Call `typingIndicatorService.stopTyping()` before sending message

---

## 11. Integration Points

### Firebase Services

**Firebase Realtime Database:**
- Used for typing status (same as presence system in PR #12)
- Uses existing persistent connection from PR #12
- Security rules restrict writes to authenticated users (own typing status only)
- Reads restricted to chat members only

**Firebase Authentication (existing from PR #2):**
- Typing requires authenticated userID
- Security rules enforce user is a member of the chat

**Firebase Firestore (existing):**
- Fetch user display names for typing indicator text
- Use UserService from PR #3 to get display names

### App Components

**ChatView.swift:**
- Attach/detach typing listeners based on view lifecycle
- Display TypingIndicatorView when typingUserNames array is non-empty
- Clear own typing status when leaving chat (`.onDisappear`)

**MessageInputView.swift:**
- Broadcast typing status when user types
- Clear typing status when input becomes empty or message sent

**UserService.swift (existing from PR #3):**
- Fetch user display names for typing user IDs
- Cache display names to minimize Firestore reads

### State Management

**SwiftUI Patterns:**
- TypingIndicatorService as `@StateObject` in ChatView
- Pass service to MessageInputView via parameter
- Individual views use `@State` for typing users array
- Real-time updates from Firebase trigger `@State` changes → UI rerenders

---

## 12. Testing Plan & Acceptance Gates

Define BEFORE implementation. Use checkboxes.

**Current**: Manual testing validation (see `Psst/agents/shared-standards.md`)  
**Future**: Automated testing recommendations in `Psst/docs/testing-strategy.md`

### Configuration Testing

- [ ] **Firebase Realtime Database typing path accessible**
  - [Gate] Firebase console shows `/typing/{chatID}/{userID}` structure
  
- [ ] **Firebase Realtime Database security rules deployed**
  - [Gate] Test write with valid chat member succeeds, write from non-member fails
  
- [ ] **TypingIndicatorService properly initialized**
  - [Gate] Service can be created without errors

### Happy Path Testing

- [ ] **User types → Typing indicator appears on other devices**
  - [Gate] User A types in chat → User B sees "Alice is typing..." within 100ms
  - [Gate] Firebase console shows typing status
  
- [ ] **User stops typing → Typing indicator disappears after 3 seconds**
  - [Gate] User A types, then stops → User B sees indicator disappear within 3 seconds
  - [Gate] Firebase typing status cleared
  
- [ ] **User sends message → Typing indicator disappears immediately**
  - [Gate] User A types, sends message → User B sees indicator disappear immediately (not after 3 seconds)
  
- [ ] **User deletes all text → Typing indicator disappears**
  - [Gate] User A types, deletes all text → User B sees indicator disappear within 100ms
  
- [ ] **Typing indicator displays in Chat View**
  - [Gate] Visual verification: "[Name] is typing..." renders below message list
  - [Gate] Animated dots loop smoothly

### Edge Cases Testing

- [ ] **Empty input → No typing status broadcasted**
  - [Gate] Input field is empty → No typing data in Firebase
  
- [ ] **User leaves chat while typing → Typing status cleared**
  - [Gate] User A types, backs out of chat → User B sees indicator disappear within 1 second
  
- [ ] **App backgrounded while typing → Typing status cleared**
  - [Gate] User A types, backgrounds app → User B sees indicator disappear within 3 seconds
  
- [ ] **User goes offline while typing → Typing status cleared**
  - [Gate] User A types, goes offline → User B sees indicator disappear immediately
  
- [ ] **Current user is excluded from typing display**
  - [Gate] User types in chat → Does not see their own typing indicator
  
- [ ] **Invalid chat ID → Graceful failure**
  - [Gate] observeTypingUsers() with non-existent chatID returns empty array (doesn't crash)

### Multi-User Testing (1-on-1 Chat)

**Setup:** 2 devices logged in as different users

- [ ] **User A types → User B sees typing indicator**
  - [Gate] Device A (User A) types → Device B (User B) sees "Alice is typing..." within 100ms
  
- [ ] **User A stops → Typing indicator clears after 3 seconds**
  - [Gate] User A stops typing → Device B sees indicator disappear within 3 seconds
  
- [ ] **User A sends message → Typing indicator clears immediately**
  - [Gate] User A sends → Device B sees indicator disappear before message appears
  
- [ ] **Both users type simultaneously → Each sees the other's indicator**
  - [Gate] Both type at same time → User A sees "Bob is typing...", User B sees "Alice is typing..."

### Multi-User Testing (Group Chat)

**Setup:** 3+ devices logged in as different users in same group chat

- [ ] **One person typing → Shows "[Name] is typing..."**
  - [Gate] User A types → Others see "Alice is typing..."
  
- [ ] **Two people typing → Shows "[Name1] and [Name2] are typing..."**
  - [Gate] User A and User B both type → User C sees "Alice and Bob are typing..."
  
- [ ] **Three+ people typing → Shows "[Name] and [N] others are typing..."**
  - [Gate] Users A, B, C all type → User D sees "Alice and 2 others are typing..."
  
- [ ] **Users stop typing at different times → Indicator updates correctly**
  - [Gate] 3 users typing → 1 stops → Others see "Alice and Bob are typing..."
  - [Gate] 2 more users stop → Last user sees indicator disappear

### Performance Testing (see shared-standards.md)

- [ ] **Typing update latency < 100ms**
  - [Gate] Measure time from keypress to indicator display on other device
  
- [ ] **Message send latency unchanged (< 100ms)**
  - [Gate] Sending messages still meets PR #8 latency targets
  
- [ ] **Smooth 60fps scrolling with typing indicators**
  - [Gate] Chat view with 100+ messages scrolls smoothly with typing indicator visible
  - [Gate] Instruments profiling shows 60fps maintained
  
- [ ] **Typing updates don't block main thread**
  - [Gate] Main Thread Checker: No violations
  - [Gate] UI remains responsive during typing broadcasts
  
- [ ] **Firebase writes throttled**
  - [Gate] Rapid typing → Firebase receives max 2 writes per second (500ms throttle)

### Memory & Lifecycle Testing

- [ ] **No memory leaks from typing listeners**
  - [Gate] Open/close 10+ chats → Memory usage stable (Instruments profiling)
  - [Gate] All listeners detached in `.onDisappear`
  
- [ ] **Timers properly cleaned up**
  - [Gate] Typing timers cancelled when leaving chat
  - [Gate] No zombie timers after multiple chat opens/closes
  
- [ ] **Listeners properly cleaned up on logout**
  - [Gate] Login → Type in chats → Logout → Verify all listeners removed
  - [Gate] No dangling Firebase references

### Animation & UI Testing

- [ ] **Typing indicator animates smoothly**
  - [Gate] Visual verification: Dots animate in sequence (... → .. → . → ...)
  - [Gate] Animation loops continuously while typing status active
  
- [ ] **Typing indicator appears/disappears smoothly**
  - [Gate] Fade-in transition (0.2s) when indicator appears
  - [Gate] Fade-out transition (0.2s) when indicator disappears
  
- [ ] **Typing indicator doesn't cause layout shifts**
  - [Gate] Messages don't jump when typing indicator appears
  - [Gate] Input bar stays in same position

---

## 13. Definition of Done

See standards in `Psst/agents/shared-standards.md`:

- [ ] **TypingIndicatorService implemented** with all methods from Section 9
- [ ] **Service methods include proper error handling** (network errors, invalid data, permissions)
- [ ] **TypingIndicatorView SwiftUI component created** (reusable with animated dots)
- [ ] **ChatView modified** to display typing indicator and manage listeners
- [ ] **MessageInputView modified** to broadcast typing status on text change
- [ ] **Firebase Realtime Database security rules deployed** for /typing path
- [ ] **Real-time sync verified across 2+ devices** (<100ms latency)
- [ ] **Automatic timeout tested** (3-second clearance after inactivity)
- [ ] **All acceptance gates pass** (Configuration, Happy Path, Edge Cases, Multi-User, Group Chat, Performance, Memory, Animation)
- [ ] **Manual testing completed** for all test scenarios in Section 12
- [ ] **No console errors or warnings** during typing operations
- [ ] **Documentation updated** (inline code comments, README if needed)

---

## 14. Risks & Mitigations

**Risk: Typing broadcasts could spam Firebase and exhaust quota**
- **Mitigation:** Implement 500ms throttle (max 2 writes/second). Firebase free tier supports 100k simultaneous connections and 10GB/month data transfer (more than sufficient). Monitor usage in Firebase console.

**Risk: Stale typing indicators if timeout doesn't work**
- **Mitigation:** Implement both client-side timer (3s) AND server-side expiration check. Multiple layers ensure typing status always clears eventually.

**Risk: Typing indicator could interfere with message input UI**
- **Mitigation:** Use absolute/overlay positioning for typing indicator. Doesn't push up message list or input bar. Test with various screen sizes.

**Risk: Multiple users typing in large group chats could be noisy**
- **Mitigation:** Simplify display: Show first name + count for 3+ typers. Don't show all individual names. Example: "Alice and 4 others are typing..." instead of listing all 5 names.

**Risk: Typing status could survive user going offline**
- **Mitigation:** Integrate with PresenceService from PR #12. Filter out typing users who are offline. Use Firebase `onDisconnect()` similar to presence.

**Risk: Race condition between typing and message send**
- **Mitigation:** Clear typing status BEFORE writing message to Firestore. Ensures typing indicator disappears before message appears.

**Risk: Battery drain from constant typing broadcasts**
- **Mitigation:** Throttle broadcasts (500ms). Use Firebase's persistent connection (no new connections per broadcast). Monitor battery usage during testing. If issues arise, increase throttle to 1 second.

---

## 15. Rollout & Telemetry

**Feature Flag:** No feature flag needed. Typing indicators are a standard messaging feature that should be always-on once deployed.

**Metrics to Track:**
- **Usage:** % of messages sent with typing indicator shown beforehand (measures feature adoption)
- **Errors:** Number of Firebase Realtime Database connection errors for typing path
- **Latency:** Average time for typing indicator to appear on other devices (target: <100ms)
- **Accuracy:** % of time typing indicator matches actual user state (target: >95%)
- **Stale indicators:** Number of typing indicators that remain visible >5 seconds (should be 0%)

**Manual Validation Steps (before merging PR):**
1. Test on 2+ physical devices (not just simulators) with different Apple IDs
2. Verify typing indicators during: typing, stopping, sending, deleting text, leaving chat
3. Measure latency: Start typing on Device A → Start timer → Stop when Device B shows indicator
4. Confirm 3-second timeout: Type, stop, measure time until indicator clears
5. Test group chat with 3+ users typing simultaneously
6. Verify Firebase Realtime Database console shows expected data structure
7. Check Firebase usage metrics: typing path reads/writes, data transfer
8. Confirm no memory leaks: Use Xcode Instruments, Memory Debugger
9. Verify animations are smooth and not distracting

---

## 16. Open Questions

**Q1: Should we show typing indicators in the Conversation List preview?**
- **Decision:** No (see Non-Goals). Too noisy and distracting. Only show in active chat view.

**Q2: Should we allow users to disable typing indicators (privacy setting)?**
- **Decision:** Out of scope for MVP. Standard messaging apps (WhatsApp, iMessage) don't offer this option. Can revisit if user feedback requests it.

**Q3: What happens to typing status for deleted users?**
- **Dependency:** User deletion flow is not yet defined. For now, if a user is deleted, their typing status will naturally expire after 3 seconds. Add cleanup logic in future user deletion PR.

**Q4: Should we show typing indicators for users who are offline?**
- **Decision:** No. Filter typing users by online status from PresenceService (PR #12). Offline users cannot be typing.

**Q5: How to handle very long user names in typing indicator?**
- **Decision:** Truncate display names to 15 characters with "..." if needed. Example: "VeryLongName123... is typing"

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future iterations:

- [ ] **Typing indicators in Conversation List** — Show preview in chat row (too noisy for MVP)
- [ ] **"Recording audio" indicator** — For voice messages (voice not in MVP)
- [ ] **"Sharing location" indicator** — For location sharing (not in MVP)
- [ ] **Typing preview text** — Show what user is typing (privacy concern)
- [ ] **Disable typing indicators setting** — Privacy option (no user request yet)
- [ ] **Smart typing timeout** — Adjust timeout based on typing speed (over-optimization)
- [ ] **Typing indicator sound** — Audio feedback when someone starts typing (could be annoying)

---

## Preflight Questionnaire

Answer these to drive vertical slice and acceptance gates:

1. **Smallest end-to-end user outcome for this PR?**
   - User is in a chat → Can see "is typing..." when contact starts composing a message → Indicator disappears when contact stops or sends message.

2. **Primary user and critical action?**
   - **User:** Anyone engaged in active conversation. **Action:** See typing indicator to know contact is composing a response.

3. **Must-have vs nice-to-have?**
   - **Must-have:** Real-time typing broadcasts, typing indicator display, 3-second timeout, clear on message send
   - **Nice-to-have:** Animated dots, group chat display names, throttled broadcasts

4. **Real-time requirements? (see shared-standards.md)**
   - **Sync speed:** Typing status must sync across devices in < 100ms
   - **Offline behavior:** No typing status shown for offline users
   - **Concurrent updates:** Handle multiple users typing simultaneously

5. **Performance constraints? (see shared-standards.md)**
   - App load < 2-3 seconds (typing doesn't delay launch)
   - Message send latency < 100ms (unchanged from PR #8)
   - Scrolling 60fps with typing indicators
   - Typing updates don't block main thread

6. **Error/edge cases to handle?**
   - Empty input → No typing broadcast
   - User leaves chat → Clear typing status
   - User goes offline → Clear typing status
   - App crash → Timeout clears stale status
   - Firebase connection failure → Silent failure (typing is nice-to-have)

7. **Data model changes?**
   - New Firebase Realtime Database schema: `/typing/{chatID}/{userID}`
   - New Swift model: `TypingStatus.swift`

8. **Service APIs required?**
   - `TypingIndicatorService.startTyping()` — Broadcast typing status
   - `TypingIndicatorService.stopTyping()` — Clear typing status
   - `TypingIndicatorService.observeTypingUsers()` — Listen to typing users
   - `TypingIndicatorService.stopObserving()` — Cleanup listeners

9. **UI entry points and states?**
   - **Entry points:** Chat View (1-on-1 and group chats)
   - **States:** No one typing (hidden), 1 person typing, 2+ people typing

10. **Security/permissions implications?**
    - Users can only write their own typing status (enforced by Firebase rules)
    - Users can only read typing status for chats they're members of

11. **Dependencies or blocking integrations?**
    - **Depends on:** PR #12 (Presence system — provides Firebase Realtime Database infrastructure)
    - **Blocks:** None (typing indicators are independent feature)

12. **Rollout strategy and metrics?**
    - No feature flag (always-on)
    - Track: typing latency, accuracy, stale indicators, Firebase usage
    - Manual validation on 2+ devices before merging

13. **What is explicitly out of scope?**
    - Typing indicators in conversation list, typing preview text, disable setting, audio indicator, typing in list preview

---

## Authoring Notes

- **Write Test Plan before coding** — Section 12 defines all acceptance gates. Use these as implementation checklist.
- **Favor vertical slice that ships standalone** — This PR delivers complete typing indicator system (broadcast + display) independently.
- **Keep service layer deterministic** — TypingIndicatorService methods have clear inputs/outputs/errors.
- **SwiftUI views are thin wrappers** — UI components just display typing state from service.
- **Test multi-user scenarios thoroughly** — Typing indicators are most valuable in active conversations with 2+ participants.
- **Leverage existing infrastructure** — Use Firebase Realtime Database connection from PR #12. Don't reinvent presence patterns.
- **Reference `Psst/agents/shared-standards.md` throughout** — Performance targets, testing strategy, code quality standards.

