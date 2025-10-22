# PRD: Online/Offline Presence System

**Feature**: Online/Offline Presence Indicators

**Version**: 1.0

**Status**: Ready for Development

**Agent**: Pam

**Target Release**: Phase 3

**Links**: [PR Brief: PR #12](../pr-briefs.md), [TODO](../todos/pr-12-todo.md), [Architecture](../architecture.md)

---

## 1. Summary

Users need to know when their contacts are available to chat in real-time. This PR implements an online/offline presence system using Firebase Realtime Database that automatically tracks and displays user availability status (online/offline) with visual indicators throughout the app, with automatic status updates even when the app crashes or loses connection.

---

## 2. Problem & Goals

**Problem:** Users currently have no visibility into whether their contacts are online and available to chat. This leads to:
- Uncertainty about message response times
- Sending messages to users who might not see them for hours
- Reduced engagement because users don't know when it's a good time to initiate conversations
- Poor user experience compared to modern messaging apps

**Why now?** 
- Core messaging functionality (PRs 1-8) is complete
- Chat creation (PR #9) is in progress
- Users need presence information before group chat features (PR #11) to understand group member availability
- Presence is foundational for typing indicators (PR #13 dependency)

**Goals (ordered, measurable):**
- [x] G1 — Implement reliable presence tracking that automatically updates within 3 seconds when users go online/offline
- [x] G2 — Display visual presence indicators (green dot = online, gray dot = offline) in Conversation List and Chat View
- [x] G3 — Ensure presence status updates automatically even when app crashes or network disconnects abruptly

---

## 3. Non-Goals / Out of Scope

Call out what's intentionally excluded to avoid scope creep.

- [ ] Not implementing "Last Seen" timestamps (e.g., "Last seen 2 hours ago") — Too complex for MVP, can be added in Phase 4
- [ ] Not implementing custom statuses (e.g., "Away", "Busy", "Do Not Disturb") — Simple online/offline is sufficient for MVP
- [ ] Not implementing presence history or analytics — No user need identified yet
- [ ] Not implementing "typing..." indicators — This is a separate PR #13 that builds on presence infrastructure
- [ ] Not optimizing for battery life — Will address in later optimization phase if metrics show impact

---

## 4. Success Metrics

Reference `Psst/agents/shared-standards.md` for metric templates:

**User-visible:**
- Time to see presence change: < 3 seconds from state change to UI update
- User taps to see presence: 0 (always visible, no interaction needed)
- Presence accuracy: >95% correct status (verified via multi-device testing)

**System (from shared-standards.md):**
- Presence update latency: < 3 seconds (online → offline, offline → online)
- Firebase Realtime Database connection: maintains persistent connection with automatic reconnection
- App load time: < 2-3 seconds (no degradation from presence feature)
- UI performance: smooth 60fps with presence updates (no jank)

**Quality:**
- 0 blocking bugs in presence detection or display
- All acceptance gates pass (see Section 12)
- Crash-free rate >99% (presence service doesn't cause crashes)
- Presence survives: app crashes, network loss, force quit

---

## 5. Users & Stories

**Primary User:** Any user who wants to see if their contacts are currently online and available to chat.

**User Stories:**

1. **As a user**, I want to see which of my contacts are currently online so that I know who is available to chat right now.

2. **As a user**, I want to see my online/offline status automatically update when I open or close the app so that my contacts know my availability without manual effort.

3. **As a user**, I want to see presence indicators in the conversation list so that I can quickly scan which conversations are with online users before opening a chat.

4. **As a user**, I want to see presence status in the chat view header so that I know if the person I'm chatting with is currently online and likely to respond quickly.

5. **As a developer/collaborator**, I want presence status to automatically go offline when the app crashes or loses connection so that users always see accurate availability information.

---

## 6. Experience Specification (UX)

### Entry Points and Flows

**Entry Point 1: Conversation List**
- User opens the app and lands on Conversation List screen
- Each chat row displays a presence indicator next to the contact's name/avatar
- Online users show a solid green circle (●)
- Offline users show a gray circle (●) 
- Presence updates in real-time without requiring pull-to-refresh

**Entry Point 2: Chat View**
- User taps into a 1-on-1 conversation
- Chat header displays the contact's name with presence indicator
- Green circle = online, Gray circle = offline
- Presence updates in real-time while viewing chat

**Entry Point 3: New Chat Creation (PR #9 integration)**
- User taps "New Chat" and sees list of all users
- Each user in the selection list shows presence indicator
- Helps users decide who to message based on availability

### Visual Behavior

**Presence Indicators:**
- **Online**: Solid green circle (●) using `Color.green`, 8pt diameter
- **Offline**: Solid gray circle (●) using `Color.gray`, 8pt diameter
- Position: To the left of user's name or overlaid on avatar (bottom-right corner)
- Animation: Gentle fade transition (0.3s) when status changes

**Empty States:**
- If user has no contacts yet: No presence indicators shown (expected behavior)
- If presence data hasn't loaded: Show gray circle as default until status confirmed

**Loading States:**
- On app launch: Show gray circles for all users
- Presence updates stream in within 3 seconds
- No explicit loading spinner (presence is background feature)

**Error States:**
- If Firebase Realtime Database connection fails: Continue showing last known status
- Display a subtle banner: "Connection lost. Presence status may be outdated."
- Auto-dismiss banner when connection restored

**Success States:**
- Presence indicators update smoothly in real-time
- No toast/alert needed for successful presence updates (silent feature)

### Performance Targets (from shared-standards.md)

- **App load time**: < 2-3 seconds (presence initialization doesn't delay app launch)
- **Presence update latency**: < 3 seconds (user goes online → all contacts see green dot)
- **Scrolling**: Smooth 60fps in Conversation List even with 100+ chats with presence indicators
- **Tap feedback**: < 50ms response time (presence doesn't affect navigation)
- **No UI blocking**: Presence listeners run on background thread
- **Smooth animations**: Presence status changes use SwiftUI animation modifiers

---

## 7. Functional Requirements (Must/Should)

### MUST Requirements

**MUST-1: PresenceService Implementation**
- Create `Services/PresenceService.swift` with deterministic methods for presence management
- Service methods:
  - `startMonitoring(userID: String)` — Begin tracking presence for a user
  - `stopMonitoring(userID: String)` — Stop tracking (cleanup)
  - `setOnlineStatus(userID: String, isOnline: Bool) async throws` — Update presence in Firebase
  - `observePresence(userID: String, completion: @escaping (Bool) -> Void) -> DatabaseReference?` — Real-time listener
- Use Firebase Realtime Database (not Firestore) for superior `onDisconnect()` support
- [Gate] PresenceService unit tests pass for valid/invalid user IDs

**MUST-2: Automatic Online Status on App Launch**
- When user authenticates and app loads, automatically set presence to "online"
- Write to Firebase Realtime Database path: `/presence/{userID}/status = "online"`
- Include `lastChanged` timestamp using `ServerValue.timestamp()`
- [Gate] User opens app → Firebase shows status = "online" within 3 seconds

**MUST-3: Automatic Offline Status with onDisconnect()**
- Configure Firebase's `onDisconnect()` hook when setting online status
- If connection drops (crash, network loss, force quit), Firebase automatically writes status = "offline"
- [Gate] Simulate app crash → Other users see status change to "offline" within 3 seconds
- [Gate] Airplane mode enabled → Status changes to "offline" within 3 seconds

**MUST-4: App Lifecycle Presence Updates**
- Monitor app lifecycle events: foreground, background, terminate
- **Foreground**: Set status = "online"
- **Background**: Set status = "offline" (user is not actively using app)
- **Terminate**: Firebase `onDisconnect()` handles automatically
- [Gate] User switches to another app → Status changes to "offline" within 3 seconds
- [Gate] User returns to app → Status changes to "online" within 3 seconds

**MUST-5: Real-Time Presence Listeners**
- Implement Firebase Realtime Database listeners for observed users
- Conversation List observes presence for all visible chat participants
- Chat View observes presence for the specific contact(s)
- Listeners automatically receive updates when presence changes
- [Gate] User A goes online on Device 1 → User B sees green dot on Device 2 within 3 seconds

**MUST-6: Presence Display in Conversation List**
- Each `ChatRowView` displays presence indicator next to contact name/avatar
- Green dot (●) for online, Gray dot (●) for offline
- For group chats: Show first online member's status or aggregate indicator
- [Gate] Visual verification: Presence dots render correctly for 10+ chats in list

**MUST-7: Presence Display in Chat View Header**
- Chat header shows presence indicator next to contact name
- Updates in real-time while chat is open
- For group chats (PR #11 dependency): Show multiple presence indicators for all members
- [Gate] Visual verification: Presence dot renders in chat header and updates smoothly

**MUST-8: Listener Lifecycle Management**
- Attach listeners when view appears (`.onAppear`)
- Detach listeners when view disappears (`.onDisappear`)
- Prevent memory leaks from dangling Firebase listeners
- [Gate] Memory profiling: No listener leaks after opening/closing 10+ chats

**MUST-9: Offline Behavior**
- App works offline per shared-standards.md requirements
- If offline: Show last known presence status from cache
- When reconnection occurs: Refresh all presence data automatically
- [Gate] Start app offline → Last known presence displayed, no crashes

**MUST-10: Performance Requirements**
- Presence feature doesn't degrade app load time (< 2-3 seconds still maintained)
- Scrolling remains smooth 60fps with presence indicators
- Presence updates don't block main thread
- [Gate] Instruments profiling: 60fps maintained with 100+ chats

### SHOULD Requirements

**SHOULD-1: Visual Feedback for Status Changes**
- When presence changes (online ↔ offline), use subtle fade animation (0.3s)
- Helps users notice status changes without being disruptive
- [Gate] User testing: Status changes feel smooth and natural

**SHOULD-2: Connection Status Indicator**
- If app loses Firebase Realtime Database connection, show subtle banner
- "Connection lost. Presence status may be outdated."
- Auto-dismiss when reconnected
- [Gate] Visual verification: Banner appears/disappears correctly

**SHOULD-3: Presence for Multiple Users in Group Chats**
- For group chats, aggregate presence (e.g., "3 online" or show up to 3 dots)
- Helps users understand group availability at a glance
- [Gate] Group chat with 5 members: Presence displays correctly

---

## 8. Data Model

### Firebase Realtime Database Schema

**Why Realtime Database and not Firestore?**
- Realtime Database has superior `onDisconnect()` hook for presence
- Lower latency for frequent small updates (presence changes)
- Firestore is still used for chats and messages
- This is a complementary use of Firebase Realtime Database

**Presence Schema:**

```swift
// Firebase Realtime Database path:
/presence
  /{userID}
    /status: "online" | "offline"
    /lastChanged: <ServerValue.timestamp()>
```

**Example:**
```json
{
  "presence": {
    "user123": {
      "status": "online",
      "lastChanged": 1698345600000
    },
    "user456": {
      "status": "offline",
      "lastChanged": 1698345550000
    }
  }
}
```

### Swift Models

```swift
// Models/UserPresence.swift
struct UserPresence: Identifiable, Codable {
    let id: String          // userID
    var isOnline: Bool      // derived from status
    var lastChanged: Date   // timestamp
    
    init(id: String, isOnline: Bool, lastChanged: Date = Date()) {
        self.id = id
        self.isOnline = isOnline
        self.lastChanged = lastChanged
    }
}
```

### Validation Rules

**Firebase Realtime Database Security Rules:**

```json
{
  "rules": {
    "presence": {
      "$uid": {
        ".read": true,  // Anyone can read presence status
        ".write": "$uid === auth.uid"  // Users can only write their own status
      }
    }
  }
}
```

**Field Constraints:**
- `status`: Must be either "online" or "offline" (validated on write)
- `lastChanged`: Must be Firebase ServerValue.timestamp() (prevents clock skew)
- `userID`: Must match authenticated user's UID (enforced by security rules)

**Indexing/Queries:**
- No indexes needed (simple key-value lookups by userID)
- Listeners are attached per user: `/presence/{userID}`
- No complex queries required

---

## 9. API / Service Contracts

### PresenceService.swift

```swift
// Services/PresenceService.swift

import Foundation
import FirebaseDatabase

class PresenceService: ObservableObject {
    private let database = Database.database().reference()
    private var presenceRefs: [String: DatabaseReference] = [:]  // Track active listeners
    
    // MARK: - Public Methods
    
    /// Set the current user's online status
    /// - Parameters:
    ///   - userID: The user's Firebase UID
    ///   - isOnline: True for online, false for offline
    /// - Throws: Firebase database errors
    func setOnlineStatus(userID: String, isOnline: Bool) async throws {
        let presenceRef = database.child("presence").child(userID)
        
        let presenceData: [String: Any] = [
            "status": isOnline ? "online" : "offline",
            "lastChanged": ServerValue.timestamp()
        ]
        
        try await presenceRef.setValue(presenceData)
        
        // Set up onDisconnect hook when going online
        if isOnline {
            let offlineData: [String: Any] = [
                "status": "offline",
                "lastChanged": ServerValue.timestamp()
            ]
            try await presenceRef.onDisconnectSetValue(offlineData)
        }
    }
    
    /// Observe presence status for a specific user
    /// - Parameters:
    ///   - userID: The user ID to observe
    ///   - completion: Callback with Bool (true = online, false = offline)
    /// - Returns: DatabaseReference for listener cleanup
    func observePresence(userID: String, completion: @escaping (Bool) -> Void) -> DatabaseReference {
        let presenceRef = database.child("presence").child(userID)
        
        presenceRef.observe(.value) { snapshot in
            guard let data = snapshot.value as? [String: Any],
                  let status = data["status"] as? String else {
                completion(false)  // Default to offline if data missing
                return
            }
            completion(status == "online")
        }
        
        // Store reference for cleanup
        presenceRefs[userID] = presenceRef
        return presenceRef
    }
    
    /// Stop observing presence for a user
    /// - Parameter userID: The user ID to stop observing
    func stopObserving(userID: String) {
        if let ref = presenceRefs[userID] {
            ref.removeAllObservers()
            presenceRefs.removeValue(forKey: userID)
        }
    }
    
    /// Stop all active presence listeners (call on logout or app termination)
    func stopAllObservers() {
        presenceRefs.forEach { _, ref in
            ref.removeAllObservers()
        }
        presenceRefs.removeAll()
    }
}
```

### Integration with App Lifecycle

```swift
// PsstApp.swift modifications

import SwiftUI
import FirebaseCore

@main
struct PsstApp: App {
    @StateObject private var authService = AuthenticationService.shared
    @StateObject private var presenceService = PresenceService()
    
    init() {
        FirebaseApp.configure()
        
        // Enable Realtime Database offline persistence
        Database.database().isPersistenceEnabled = true
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .environmentObject(presenceService)
                .onChange(of: scenePhase) { newPhase in
                    handleScenePhaseChange(newPhase)
                }
        }
    }
    
    @Environment(\.scenePhase) private var scenePhase
    
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        guard let userID = authService.currentUser?.uid else { return }
        
        switch phase {
        case .active:
            // User brought app to foreground
            Task {
                try? await presenceService.setOnlineStatus(userID: userID, isOnline: true)
            }
        case .background, .inactive:
            // User sent app to background or it became inactive
            Task {
                try? await presenceService.setOnlineStatus(userID: userID, isOnline: false)
            }
        @unknown default:
            break
        }
    }
}
```

### Pre/Post-Conditions

**setOnlineStatus()**
- **Pre-conditions:** 
  - User must be authenticated (userID is valid Firebase UID)
  - Firebase Realtime Database connection must be available
- **Post-conditions:**
  - Presence data written to `/presence/{userID}`
  - If going online: `onDisconnect()` hook configured
  - Completion within 1 second under normal network conditions

**observePresence()**
- **Pre-conditions:**
  - userID must be valid (exists in system)
  - Firebase Realtime Database connection available (or uses cached data)
- **Post-conditions:**
  - Listener attached to `/presence/{userID}`
  - Completion callback fires immediately with current status
  - Subsequent status changes trigger callback in real-time

**stopObserving()**
- **Pre-conditions:**
  - Listener was previously attached for the given userID
- **Post-conditions:**
  - Listener detached from Firebase
  - No more callbacks for that userID
  - Memory released

### Error Handling Strategy

**Network Errors:**
- If Firebase connection fails: Use last known cached status
- Display connection lost banner (see UX section)
- Automatically retry when connection restored

**Permission Errors:**
- If security rules deny write (wrong UID): Log error, fail silently, show generic error to user
- If read denied: Default to offline status

**Invalid Data:**
- If presence snapshot has unexpected format: Default to offline status
- Log warning for debugging but don't crash

---

## 10. UI Components to Create/Modify

### New Files to Create

- `Services/PresenceService.swift` — Firebase Realtime Database presence management (all methods from Section 9)
- `Models/UserPresence.swift` — Swift model for presence data
- `Views/Components/PresenceIndicator.swift` — Reusable SwiftUI view for presence dot (green/gray circle)

### Existing Files to Modify

- `Views/ChatList/ChatRowView.swift` — Add PresenceIndicator next to contact name/avatar
- `Views/ChatList/ChatView.swift` — Add PresenceIndicator in chat header
- `PsstApp.swift` — Integrate app lifecycle monitoring for presence updates
- `Services/AuthenticationService.swift` — Call PresenceService.setOnlineStatus() after successful login

### Component Details

**PresenceIndicator.swift:**
```swift
struct PresenceIndicator: View {
    let isOnline: Bool
    
    var body: some View {
        Circle()
            .fill(isOnline ? Color.green : Color.gray)
            .frame(width: 8, height: 8)
            .animation(.easeInOut(duration: 0.3), value: isOnline)
    }
}
```

**ChatRowView.swift modifications:**
- Add `@StateObject private var presenceService = PresenceService()`
- Add `@State private var isContactOnline: Bool = false`
- In `.onAppear`: Attach presence listener for contact
- In `.onDisappear`: Detach presence listener
- Display `PresenceIndicator(isOnline: isContactOnline)` next to contact name

**ChatView.swift modifications:**
- Similar pattern: Add presence listener for chat contact(s)
- Display PresenceIndicator in header next to contact name
- Cleanup listener on `.onDisappear`

---

## 11. Integration Points

### Firebase Services

**Firebase Realtime Database:**
- Used exclusively for presence tracking (not for messages/chats)
- Enable offline persistence: `Database.database().isPersistenceEnabled = true`
- Security rules restrict writes to authenticated users (own status only)
- Reads are public (any authenticated user can see presence)

**Firebase Authentication (existing from PR #2):**
- Presence requires authenticated userID
- On login: Set status = "online"
- On logout: Set status = "offline" and detach all listeners

### App Components

**PsstApp.swift:**
- Monitor `scenePhase` changes (active, background, inactive)
- Call `presenceService.setOnlineStatus()` based on phase

**AuthenticationService.swift:**
- After successful login: Call `presenceService.setOnlineStatus(userID, true)`
- On logout: Call `presenceService.setOnlineStatus(userID, false)` and `stopAllObservers()`

**ChatRowView.swift / ChatView.swift:**
- Attach/detach presence listeners based on view lifecycle
- Update UI when presence changes via SwiftUI state binding

### State Management

**SwiftUI Patterns:**
- PresenceService as `@EnvironmentObject` (available globally)
- Individual views use `@State` for per-user presence status
- Real-time updates from Firebase trigger `@State` changes → UI rerenders

---

## 12. Testing Plan & Acceptance Gates

Define BEFORE implementation. Use checkboxes.

**Current**: Manual testing validation (see `Psst/agents/shared-standards.md`)  
**Future**: Automated testing recommendations in `Psst/docs/testing-strategy.md`

### Configuration Testing

- [ ] **Firebase Realtime Database connection established**
  - [Gate] Firebase console shows active connection from app
  
- [ ] **Firebase Realtime Database security rules deployed**
  - [Gate] Test write with valid UID succeeds, write with wrong UID fails
  
- [ ] **Offline persistence enabled**
  - [Gate] `Database.database().isPersistenceEnabled = true` confirmed in code

- [ ] **PresenceService properly initialized**
  - [Gate] Service can be created without errors

### Happy Path Testing

- [ ] **User opens app → Status changes to "online"**
  - [Gate] Firebase console shows `/presence/{userID}/status = "online"` within 3 seconds
  - [Gate] Other devices see green dot appear within 3 seconds
  
- [ ] **User goes to background → Status changes to "offline"**
  - [Gate] Firebase shows status = "offline" within 3 seconds
  - [Gate] Other devices see gray dot within 3 seconds
  
- [ ] **User returns to foreground → Status changes to "online"**
  - [Gate] Firebase shows status = "online" within 3 seconds
  - [Gate] Green dot reappears on other devices within 3 seconds
  
- [ ] **Presence indicator displays in Conversation List**
  - [Gate] Green dots show for online contacts, gray for offline
  - [Gate] Visual verification with 10+ chats in list
  
- [ ] **Presence indicator displays in Chat View header**
  - [Gate] Green/gray dot appears next to contact name
  - [Gate] Updates in real-time while chat is open

### Edge Cases Testing

- [ ] **App crashes (force quit) → Status automatically goes offline**
  - [Gate] Force quit app on Device 1 → Device 2 sees status change to offline within 3 seconds
  - [Gate] Firebase `onDisconnect()` hook triggers successfully
  
- [ ] **Network disconnects (airplane mode) → Status goes offline**
  - [Gate] Enable airplane mode → Other users see offline status within 3 seconds
  - [Gate] Disable airplane mode → Status returns to online within 5 seconds
  
- [ ] **User logs out → Status changes to offline**
  - [Gate] Logout triggers `setOnlineStatus(userID, false)`
  - [Gate] All presence listeners detached (no memory leaks)
  
- [ ] **Invalid user ID → Graceful failure**
  - [Gate] observePresence() with non-existent userID returns offline (doesn't crash)
  - [Gate] Error logged for debugging
  
- [ ] **App restarts offline → Last known status displayed**
  - [Gate] Start app with no internet → Presence indicators show last cached values
  - [Gate] No crashes or loading spinners

### Multi-Device Testing

**Setup:** 2+ devices logged in as different users

- [ ] **User A goes online → User B sees green dot within 3 seconds**
  - [Gate] Open app on Device A (User A) → Green dot appears on Device B (User B's view)
  
- [ ] **User A goes offline → User B sees gray dot within 3 seconds**
  - [Gate] Background app on Device A → Gray dot appears on Device B
  
- [ ] **Real-time updates in Conversation List**
  - [Gate] User B is viewing conversation list when User A changes status → Presence updates without refresh
  
- [ ] **Real-time updates in Chat View**
  - [Gate] User B is chatting with User A when User A backgrounds app → Gray dot appears in chat header within 3 seconds

### Offline Behavior Testing

- [ ] **App starts offline → Displays last known presence**
  - [Gate] Start app with airplane mode enabled → Presence indicators show cached values
  - [Gate] No crashes, no error messages
  
- [ ] **Go offline mid-session → No crashes**
  - [Gate] Enable airplane mode while app is open → App continues functioning
  - [Gate] Presence stops updating but doesn't cause errors
  
- [ ] **Reconnect → Presence syncs automatically**
  - [Gate] Disable airplane mode → Presence data refreshes within 5 seconds
  - [Gate] All presence indicators update to current status

### Performance Testing (see shared-standards.md)

- [ ] **App load time < 2-3 seconds**
  - [Gate] Cold start to interactive UI measured (presence doesn't delay launch)
  
- [ ] **Smooth 60fps scrolling with presence indicators**
  - [Gate] Conversation List with 100+ chats scrolls smoothly
  - [Gate] Instruments profiling shows 60fps maintained
  
- [ ] **Presence updates don't block main thread**
  - [Gate] Main Thread Checker: No violations
  - [Gate] UI remains responsive during presence updates

### Memory & Lifecycle Testing

- [ ] **No memory leaks from presence listeners**
  - [Gate] Open/close 10+ chats → Memory usage stable (Instruments profiling)
  - [Gate] All listeners detached in `.onDisappear`
  
- [ ] **Listeners properly cleaned up on logout**
  - [Gate] Login → Attach listeners → Logout → Verify all listeners removed
  - [Gate] No dangling Firebase references

---

## 13. Definition of Done

See standards in `Psst/agents/shared-standards.md`:

- [ ] **PresenceService implemented** with all methods from Section 9
- [ ] **Service methods include proper error handling** (network errors, invalid data, permissions)
- [ ] **PresenceIndicator SwiftUI component created** (reusable green/gray dot)
- [ ] **ChatRowView modified** to display presence in conversation list
- [ ] **ChatView modified** to display presence in chat header
- [ ] **PsstApp.swift lifecycle monitoring** implemented (foreground/background presence updates)
- [ ] **Firebase Realtime Database security rules deployed**
- [ ] **Real-time sync verified across 2+ devices** (<3 second latency)
- [ ] **onDisconnect() hook tested** (force quit, airplane mode)
- [ ] **All acceptance gates pass** (Configuration, Happy Path, Edge Cases, Multi-Device, Offline, Performance, Memory)
- [ ] **Manual testing completed** for all test scenarios in Section 12
- [ ] **No console errors or warnings** during presence operations
- [ ] **Documentation updated** (inline code comments, README if needed)

---

## 14. Risks & Mitigations

**Risk: Firebase Realtime Database has separate billing from Firestore**
- **Mitigation:** Presence data is extremely small (just status + timestamp per user). Monitor usage in Firebase console. Free tier supports 100k simultaneous connections (more than sufficient for MVP).

**Risk: Presence updates could drain battery if not optimized**
- **Mitigation:** Firebase Realtime Database maintains a single persistent connection (not polling). Use Firebase's built-in connection management. Monitor battery usage during testing. If issues arise, implement throttling in Phase 4.

**Risk: Users going offline during chat could confuse message delivery expectations**
- **Mitigation:** This PR only implements presence indicators. Message delivery status (read receipts) is handled separately in PR #14. Presence shows *availability*, not *message delivery*.

**Risk: Race condition between authentication and presence service initialization**
- **Mitigation:** Presence is set only after authentication completes. Use proper async/await patterns. Test with slow network conditions.

**Risk: Stale presence data if Firebase connection silently fails**
- **Mitigation:** Display connection status banner when Firebase reports disconnect. Show last known status with visual indicator (e.g., gray dot with opacity change). Auto-refresh on reconnection.

**Risk: Group chat presence (PR #11) might be complex with many members**
- **Mitigation:** For MVP, show simple aggregate (e.g., "3 online" or first 3 online members). Defer advanced group presence UI to Phase 4 if needed.

---

## 15. Rollout & Telemetry

**Feature Flag:** No feature flag needed. Presence is a core feature that should be always-on once deployed.

**Metrics to Track:**
- **Usage:** % of users with presence status = "online" at peak hours (measures adoption)
- **Errors:** Number of Firebase Realtime Database connection errors per user session
- **Latency:** Average time for presence change to propagate across devices (target: <3 seconds)
- **Accuracy:** % of time presence status matches actual user state (target: >95%)

**Manual Validation Steps (before merging PR):**
1. Test on 2+ physical devices (not just simulators) with different Apple IDs
2. Verify presence updates during: app open, app background, force quit, airplane mode
3. Measure latency: Start timer when User A backgrounds app → Stop when User B sees gray dot
4. Confirm no memory leaks: Use Xcode Instruments, Memory Debugger
5. Verify Firebase Realtime Database console shows expected data structure
6. Check Firebase usage metrics: Realtime Database connections, data transfer

---

## 16. Open Questions

**Q1: Should we show "Last Seen" timestamps (e.g., "Last seen 2 hours ago") for offline users?**
- **Decision:** No (see Non-Goals). Adds complexity (timezone handling, privacy concerns). Can revisit in Phase 4 if user feedback requests it.

**Q2: Should we differentiate between "Away" and "Offline"?**
- **Decision:** No (see Non-Goals). Binary online/offline is sufficient for MVP. Custom statuses can be added later.

**Q3: What happens to presence for deleted users?**
- **Dependency:** User deletion flow is not yet defined. For now, if a user is deleted from `users` collection but presence data exists, default to showing offline status. Add cleanup logic in future user deletion PR.

**Q4: Should presence work for anonymous users (if anonymous auth is supported)?**
- **Decision:** Out of scope. Current design assumes email/password authentication (PR #2). Anonymous auth is not part of MVP.

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future iterations:

- [ ] **Last Seen Timestamps** — "Last seen 2 hours ago" (privacy, timezone complexity)
- [ ] **Custom Status Messages** — "Busy", "In a meeting", "Do Not Disturb" (requires additional UI)
- [ ] **Presence History/Analytics** — Track when users are typically online (no user need identified)
- [ ] **Battery Optimization** — Throttle presence updates on low battery (optimize only if metrics show issue)
- [ ] **Presence for Group Chats (advanced)** — Show all members' presence in group header (deferred to PR #11 or later)
- [ ] **Invisible Mode** — Let users appear offline while actually online (privacy feature, not MVP)

---

## Preflight Questionnaire

Answer these to drive vertical slice and acceptance gates:

1. **Smallest end-to-end user outcome for this PR?**
   - User opens app → Can see which contacts are online (green dot) vs offline (gray dot) in conversation list and chat view.

2. **Primary user and critical action?**
   - **User:** Anyone using the app to chat. **Action:** Glance at presence indicator to decide who to message.

3. **Must-have vs nice-to-have?**
   - **Must-have:** Online/offline detection, automatic status updates, visual indicators in UI, onDisconnect() hook.
   - **Nice-to-have:** Last seen timestamps, custom statuses, connection status banner.

4. **Real-time requirements? (see shared-standards.md)**
   - **Sync speed:** Presence updates must sync across devices in < 3 seconds.
   - **Offline behavior:** Show last known cached presence when offline.
   - **Concurrent updates:** Handle multiple users changing status simultaneously (Firebase handles this).

5. **Performance constraints? (see shared-standards.md)**
   - App load < 2-3 seconds (presence doesn't delay launch).
   - Scrolling 60fps with presence indicators.
   - Presence updates don't block main thread.

6. **Error/edge cases to handle?**
   - App crash (force quit) → onDisconnect() sets offline.
   - Network loss (airplane mode) → onDisconnect() sets offline.
   - Invalid user ID → Default to offline, don't crash.
   - Firebase connection failure → Show last known status + banner.

7. **Data model changes?**
   - New Firebase Realtime Database schema: `/presence/{userID}/status` and `lastChanged`.
   - New Swift model: `UserPresence.swift`.

8. **Service APIs required?**
   - `PresenceService.setOnlineStatus()` — Update own status.
   - `PresenceService.observePresence()` — Listen to another user's status.
   - `PresenceService.stopObserving()` — Cleanup listeners.

9. **UI entry points and states?**
   - **Entry points:** Conversation List, Chat View, New Chat Creation.
   - **States:** Online (green dot), Offline (gray dot), Loading (gray dot default), Error (show banner).

10. **Security/permissions implications?**
    - Users can only write their own presence status (enforced by Firebase rules).
    - Users can read any other user's presence (public within authenticated users).

11. **Dependencies or blocking integrations?**
    - **Depends on:** PR #1 (Firebase setup), PR #2 (Authentication), PR #6 (Conversation List UI).
    - **Blocks:** PR #13 (Typing Indicators — uses same Realtime Database infrastructure).

12. **Rollout strategy and metrics?**
    - No feature flag (always-on).
    - Track: presence accuracy, latency, Firebase connection errors.
    - Manual validation on 2+ devices before merging.

13. **What is explicitly out of scope?**
    - Last seen timestamps, custom statuses, presence history, battery optimization, invisible mode.

---

## Authoring Notes

- **Write Test Plan before coding** — Section 12 defines all acceptance gates. Use these as implementation checklist.
- **Favor vertical slice that ships standalone** — This PR delivers complete presence system (detection + display) independently.
- **Keep service layer deterministic** — PresenceService methods have clear inputs/outputs/errors.
- **SwiftUI views are thin wrappers** — UI components just display presence state from service.
- **Test offline/online thoroughly** — Presence is critical for user trust. Must be accurate >95% of the time.
- **Reference `Psst/agents/shared-standards.md` throughout** — Performance targets, testing strategy, code quality standards.

