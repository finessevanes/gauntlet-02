# PR-12 TODO — Online/Offline Presence System

**Branch**: `feat/pr-12-online-offline-presence-system`  
**Source PRD**: `Psst/docs/prds/pr-12-prd.md`  
**Owner (Agent)**: Caleb

---

## 0. Clarifying Questions & Assumptions

- Questions: None - PRD is comprehensive
- Assumptions (confirm in PR if needed):
  - Presence data is minimal (won't impact bandwidth or costs)
  - < 1000 concurrent users for MVP (Firebase free tier sufficient)
  - Firebase Realtime Database free tier supports presence needs
  - Binary online/offline sufficient (no custom statuses needed)
  - 3-second latency target is achievable with Firebase Realtime Database

---

## 1. Setup

- [x] Create branch `feat/pr-12-online-offline-presence-system` from develop
- [x] Read PRD thoroughly (`Psst/docs/prds/pr-12-prd.md`)
- [x] Read `Psst/agents/shared-standards.md` for patterns
- [ ] Verify Firebase Realtime Database is configured in Firebase Console
- [x] Confirm Firebase Authentication is working (from PR #2)
- [x] Verify existing PRs 1-8 are merged to develop

---

## 2. Data Model

Create UserPresence Swift model.

- [ ] Create `Psst/Psst/Models/UserPresence.swift`
  - Test Gate: File created in correct location

- [ ] Define UserPresence struct
  ```swift
  struct UserPresence: Identifiable, Codable {
      let id: String          // userID
      var isOnline: Bool      // derived from status
      var lastChanged: Date   // timestamp
  }
  ```
  - Test Gate: Struct compiles without errors

- [ ] Add initializer
  ```swift
  init(id: String, isOnline: Bool, lastChanged: Date = Date()) {
      self.id = id
      self.isOnline = isOnline
      self.lastChanged = lastChanged
  }
  ```
  - Test Gate: Can create sample UserPresence instance

- [ ] Test model with sample data
  - Test Gate: UserPresence model encodes/decodes correctly

---

## 3. Service Layer - PresenceService

Implement Firebase Realtime Database presence tracking.

### 3.1: Create PresenceService File

- [ ] Create `Psst/Psst/Services/PresenceService.swift`
  - Test Gate: File created in Services folder

- [ ] Add imports
  ```swift
  import Foundation
  import FirebaseDatabase
  import Combine
  ```
  - Test Gate: Imports resolve without errors

- [ ] Define PresenceService class structure
  ```swift
  class PresenceService: ObservableObject {
      private let database = Database.database().reference()
      private var presenceRefs: [String: DatabaseReference] = [:]
  }
  ```
  - Test Gate: Class compiles, properties defined

### 3.2: Implement setOnlineStatus()

- [ ] Add setOnlineStatus method signature
  ```swift
  func setOnlineStatus(userID: String, isOnline: Bool) async throws
  ```
  - Test Gate: Method signature compiles

- [ ] Implement presence data write
  - Step 1: Create presenceRef to `/presence/{userID}`
  - Step 2: Create presenceData dictionary with "status" and "lastChanged"
  - Step 3: Use `ServerValue.timestamp()` for lastChanged
  - Step 4: Call `setValue(presenceData)` with async/await
  - Test Gate: Method compiles without errors

- [ ] Configure onDisconnect() hook when going online
  - Step 1: Check if `isOnline == true`
  - Step 2: Create offlineData dictionary with "status": "offline"
  - Step 3: Call `presenceRef.onDisconnectSetValue(offlineData)`
  - Test Gate: onDisconnect hook configured

- [ ] Add error handling
  - Wrap in do-catch for Firebase errors
  - Log errors with print statements
  - Rethrow errors for caller to handle
  - Test Gate: Errors logged clearly

- [ ] Test setOnlineStatus manually
  - Test Gate: Call with valid userID succeeds
  - Test Gate: Firebase Console shows `/presence/{userID}` data

### 3.3: Implement observePresence()

- [ ] Add observePresence method signature
  ```swift
  func observePresence(userID: String, completion: @escaping (Bool) -> Void) -> DatabaseReference
  ```
  - Test Gate: Method signature compiles

- [ ] Implement Firebase listener attachment
  - Step 1: Create presenceRef to `/presence/{userID}`
  - Step 2: Attach `.observe(.value)` listener
  - Step 3: Parse snapshot.value as [String: Any]
  - Step 4: Extract "status" field
  - Step 5: Call completion(status == "online")
  - Test Gate: Listener attaches without errors

- [ ] Handle missing or invalid data
  - Default to offline (false) if data missing
  - Default to offline if status field not found
  - Log warnings for debugging
  - Test Gate: Invalid data handled gracefully

- [ ] Store reference for cleanup
  - Add to `presenceRefs[userID]` dictionary
  - Return DatabaseReference for caller
  - Test Gate: Reference stored correctly

- [ ] Test observePresence manually
  - Test Gate: Listener fires immediately with current status
  - Test Gate: Listener fires when status changes in Firebase Console

### 3.4: Implement stopObserving()

- [ ] Add stopObserving method signature
  ```swift
  func stopObserving(userID: String)
  ```
  - Test Gate: Method signature compiles

- [ ] Implement listener removal
  - Step 1: Check if presenceRefs[userID] exists
  - Step 2: Call `ref.removeAllObservers()`
  - Step 3: Remove from presenceRefs dictionary
  - Test Gate: Listener removed without errors

- [ ] Test stopObserving manually
  - Test Gate: After calling, listener no longer fires
  - Test Gate: presenceRefs dictionary cleaned up

### 3.5: Implement stopAllObservers()

- [ ] Add stopAllObservers method signature
  ```swift
  func stopAllObservers()
  ```
  - Test Gate: Method signature compiles

- [ ] Implement cleanup logic
  - Step 1: Iterate through presenceRefs dictionary
  - Step 2: Call removeAllObservers() on each reference
  - Step 3: Clear presenceRefs dictionary
  - Test Gate: All listeners removed

- [ ] Test stopAllObservers manually
  - Test Gate: All active listeners stopped
  - Test Gate: presenceRefs is empty after call

### 3.6: Add Error Handling and Logging

- [ ] Add error logging throughout PresenceService
  - Log when setOnlineStatus fails
  - Log when observePresence encounters bad data
  - Use descriptive print statements with "PresenceService:" prefix
  - Test Gate: Errors logged clearly in console

- [ ] Test error scenarios
  - Test Gate: Network error doesn't crash app
  - Test Gate: Invalid userID handled gracefully
  - Test Gate: Offline mode uses cached data

---

## 4. UI Components

Create reusable presence indicator and integrate into existing views.

### 4.1: Create PresenceIndicator Component

- [ ] Create `Psst/Psst/Views/Components/` folder if it doesn't exist
  - Test Gate: Folder exists

- [ ] Create `Psst/Psst/Views/Components/PresenceIndicator.swift`
  - Test Gate: File created

- [ ] Implement PresenceIndicator view
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
  - Test Gate: View compiles without errors

- [ ] Add SwiftUI preview
  - Test Gate: Preview renders green circle for online
  - Test Gate: Preview renders gray circle for offline

- [ ] Test animation
  - Test Gate: Status change animates smoothly (0.3s fade)

### 4.2: Modify ChatRowView for Presence

- [ ] Open `Psst/Psst/Views/ChatList/ChatRowView.swift`
  - Test Gate: File exists from PR #6

- [ ] Add PresenceService to ChatRowView
  ```swift
  @EnvironmentObject private var presenceService: PresenceService
  ```
  - Test Gate: Property compiles

- [ ] Add state variable for presence
  ```swift
  @State private var isContactOnline: Bool = false
  ```
  - Test Gate: State variable defined

- [ ] Extract contact userID from chat
  - Get chat.members array
  - Filter out current user's ID
  - Get first remaining userID (the contact)
  - Test Gate: Contact ID extracted correctly

- [ ] Add .onAppear to attach listener
  ```swift
  .onAppear {
      let contactID = // ... extract from chat.members
      _ = presenceService.observePresence(userID: contactID) { isOnline in
          DispatchQueue.main.async {
              self.isContactOnline = isOnline
          }
      }
  }
  ```
  - Test Gate: Listener attaches when row appears

- [ ] Add .onDisappear to detach listener
  ```swift
  .onDisappear {
      let contactID = // ... same extraction
      presenceService.stopObserving(userID: contactID)
  }
  ```
  - Test Gate: Listener detaches when row disappears

- [ ] Add PresenceIndicator to UI
  - Place next to contact name or avatar
  - Use HStack with spacing
  - Test Gate: Presence dot appears in row

- [ ] Handle group chats
  - For group chats, show aggregate or first member's presence
  - Test Gate: Group chats display presence appropriately

- [ ] Test ChatRowView changes
  - Test Gate: Presence dot renders correctly
  - Test Gate: Green dot for online contacts
  - Test Gate: Gray dot for offline contacts
  - Test Gate: Updates in real-time without refresh

### 4.3: Modify ChatView for Presence

- [ ] Open `Psst/Psst/Views/ChatList/ChatView.swift`
  - Test Gate: File exists from PR #7

- [ ] Add PresenceService to ChatView
  ```swift
  @EnvironmentObject private var presenceService: PresenceService
  ```
  - Test Gate: Property compiles

- [ ] Add state variable for presence
  ```swift
  @State private var isContactOnline: Bool = false
  ```
  - Test Gate: State variable defined

- [ ] Extract contact userID from chat
  - Similar logic to ChatRowView
  - Filter chat.members for other user's ID
  - Test Gate: Contact ID extracted

- [ ] Add .onAppear to attach listener
  ```swift
  .onAppear {
      let contactID = // ... extract from chat.members
      _ = presenceService.observePresence(userID: contactID) { isOnline in
          DispatchQueue.main.async {
              self.isContactOnline = isOnline
          }
      }
  }
  ```
  - Test Gate: Listener attaches when chat opens

- [ ] Add .onDisappear to detach listener
  ```swift
  .onDisappear {
      let contactID = // ... same extraction
      presenceService.stopObserving(userID: contactID)
  }
  ```
  - Test Gate: Listener detaches when chat closes

- [ ] Add PresenceIndicator to chat header
  - Place next to contact name in header
  - Use HStack with PresenceIndicator component
  - Test Gate: Presence dot appears in header

- [ ] Test ChatView changes
  - Test Gate: Presence dot renders in header
  - Test Gate: Updates in real-time while chat is open
  - Test Gate: No memory leaks after opening/closing multiple chats

---

## 5. App Lifecycle Integration

Integrate presence with app lifecycle and authentication.

### 5.1: Enable Firebase Realtime Database in PsstApp

- [ ] Open `Psst/Psst/PsstApp.swift`
  - Test Gate: File exists

- [ ] Add Firebase Realtime Database import
  ```swift
  import FirebaseDatabase
  ```
  - Test Gate: Import resolves

- [ ] Enable offline persistence in init
  ```swift
  init() {
      FirebaseApp.configure()
      Database.database().isPersistenceEnabled = true
  }
  ```
  - Test Gate: Persistence enabled, no compilation errors

### 5.2: Add PresenceService to App Environment

- [ ] Create PresenceService StateObject in PsstApp
  ```swift
  @StateObject private var presenceService = PresenceService()
  ```
  - Test Gate: StateObject created

- [ ] Add PresenceService to ContentView environment
  ```swift
  ContentView()
      .environmentObject(authService)
      .environmentObject(presenceService)
  ```
  - Test Gate: PresenceService available throughout app

### 5.3: Implement scenePhase Monitoring

- [ ] Add scenePhase environment variable
  ```swift
  @Environment(\.scenePhase) private var scenePhase
  ```
  - Test Gate: Environment variable defined

- [ ] Add onChange modifier to WindowGroup
  ```swift
  .onChange(of: scenePhase) { newPhase in
      handleScenePhaseChange(newPhase)
  }
  ```
  - Test Gate: Modifier compiles

- [ ] Implement handleScenePhaseChange method
  ```swift
  private func handleScenePhaseChange(_ phase: ScenePhase) {
      guard let userID = authService.currentUser?.uid else { return }
      
      switch phase {
      case .active:
          Task {
              try? await presenceService.setOnlineStatus(userID: userID, isOnline: true)
          }
      case .background, .inactive:
          Task {
              try? await presenceService.setOnlineStatus(userID: userID, isOnline: false)
          }
      @unknown default:
          break
      }
  }
  ```
  - Test Gate: Method compiles and runs

- [ ] Test scenePhase integration
  - Test Gate: App goes to background → status becomes "offline"
  - Test Gate: App returns to foreground → status becomes "online"
  - Test Gate: Status changes within 3 seconds

### 5.4: Integrate with AuthenticationService

- [ ] Open `Psst/Psst/Services/AuthenticationService.swift`
  - Test Gate: File exists from PR #2

- [ ] Add reference to PresenceService (or use notification pattern)
  - Option 1: Inject PresenceService dependency
  - Option 2: Post notification that PsstApp observes
  - Choose Option 2 for cleaner separation
  - Test Gate: Approach decided

- [ ] In PsstApp, observe authentication state changes
  - Add .onChange(of: authService.currentUser)
  - When user logs in: Call presenceService.setOnlineStatus(userID, true)
  - When user logs out: Call presenceService.setOnlineStatus(userID, false)
  - Test Gate: Presence updates on login/logout

- [ ] Add cleanup on logout
  - Call presenceService.stopAllObservers() on logout
  - Test Gate: All listeners cleaned up after logout

- [ ] Test authentication integration
  - Test Gate: Login → status becomes "online" within 3 seconds
  - Test Gate: Logout → status becomes "offline" within 3 seconds
  - Test Gate: No dangling listeners after logout

---

## 6. Firebase Configuration

Deploy Firebase Realtime Database security rules.

- [ ] Create Firebase Realtime Database security rules
  ```json
  {
    "rules": {
      "presence": {
        "$uid": {
          ".read": true,
          ".write": "$uid === auth.uid"
        }
      }
    }
  }
  ```
  - Test Gate: Rules defined

- [ ] Deploy rules to Firebase Console
  - Navigate to Firebase Console → Realtime Database → Rules
  - Paste rules JSON
  - Publish rules
  - Test Gate: Rules deployed successfully

- [ ] Test security rules
  - Test Gate: User can write their own presence (/presence/{their_uid})
  - Test Gate: User CANNOT write another user's presence (/presence/{other_uid})
  - Test Gate: User can read any user's presence

- [ ] Verify rules in Firebase Console
  - Test Gate: Rules visible in Firebase Console
  - Test Gate: Last modified timestamp updated

---

## 7. Manual Testing Validation

**Current**: Manual testing validation (see `Psst/agents/shared-standards.md`)

### Configuration Testing

- [ ] **Firebase Realtime Database connection established**
  - Test Gate: Firebase Console shows active connection from app
  - Test Gate: No connection errors in Xcode console

- [ ] **Security rules deployed correctly**
  - Test Gate: Rules JSON visible in Firebase Console
  - Test Gate: Write permissions enforced (test with invalid UID)

- [ ] **Offline persistence enabled**
  - Test Gate: `Database.database().isPersistenceEnabled = true` in code
  - Test Gate: Cached presence data available offline

- [ ] **PresenceService initializes without errors**
  - Test Gate: App launches successfully with PresenceService
  - Test Gate: No initialization errors in console

### Happy Path Testing

- [ ] **User opens app → Status changes to "online"**
  - Test Gate: Open app on Device 1
  - Test Gate: Firebase Console shows `/presence/{userID}/status = "online"` within 3 seconds
  - Test Gate: Device 2 sees green dot appear within 3 seconds

- [ ] **User goes to background → Status changes to "offline"**
  - Test Gate: Press home button or switch apps
  - Test Gate: Firebase Console shows status = "offline" within 3 seconds
  - Test Gate: Device 2 sees gray dot within 3 seconds

- [ ] **User returns to foreground → Status changes to "online"**
  - Test Gate: Reopen app from background
  - Test Gate: Firebase Console shows status = "online" within 3 seconds
  - Test Gate: Device 2 sees green dot reappear within 3 seconds

- [ ] **Presence indicator displays in Conversation List**
  - Test Gate: Open Conversation List screen
  - Test Gate: Green dots show for online contacts
  - Test Gate: Gray dots show for offline contacts
  - Test Gate: Visual verification with 10+ chats in list

- [ ] **Presence indicator displays in Chat View header**
  - Test Gate: Open 1-on-1 chat
  - Test Gate: Green/gray dot appears next to contact name in header
  - Test Gate: Dot updates in real-time while chat is open

### Edge Cases Testing

- [ ] **App crashes (force quit) → Status automatically goes offline**
  - Test Gate: Force quit app on Device 1 (swipe up, kill)
  - Test Gate: Device 2 sees status change to offline within 3 seconds
  - Test Gate: Firebase Console shows status = "offline"
  - Test Gate: Firebase `onDisconnect()` hook triggered successfully

- [ ] **Network disconnects (airplane mode) → Status goes offline**
  - Test Gate: Enable airplane mode on Device 1
  - Test Gate: Device 2 sees offline status within 3 seconds
  - Test Gate: Disable airplane mode → Status returns to online within 5 seconds

- [ ] **User logs out → Status changes to offline**
  - Test Gate: Tap logout button
  - Test Gate: Firebase Console shows status = "offline"
  - Test Gate: `stopAllObservers()` called (verify no listeners remain)

- [ ] **Invalid user ID → Graceful failure**
  - Test Gate: Call observePresence() with non-existent userID
  - Test Gate: Returns offline (false), doesn't crash
  - Test Gate: Error logged for debugging

- [ ] **App restarts offline → Last known status displayed**
  - Test Gate: Enable airplane mode
  - Test Gate: Restart app
  - Test Gate: Presence indicators show last cached values
  - Test Gate: No crashes or error messages

### Multi-Device Testing

**Setup:** 2+ devices logged in as different users

- [ ] **User A goes online → User B sees green dot within 3 seconds**
  - Test Gate: Open app on Device A (User A)
  - Test Gate: Green dot appears on Device B (User B's conversation list) within 3 seconds

- [ ] **User A goes offline → User B sees gray dot within 3 seconds**
  - Test Gate: Background app on Device A (User A)
  - Test Gate: Gray dot appears on Device B within 3 seconds

- [ ] **Real-time updates in Conversation List**
  - Test Gate: User B is viewing conversation list
  - Test Gate: User A changes status (online/offline)
  - Test Gate: Presence updates on Device B without manual refresh

- [ ] **Real-time updates in Chat View**
  - Test Gate: User B is chatting with User A (chat is open)
  - Test Gate: User A backgrounds app
  - Test Gate: Gray dot appears in chat header on Device B within 3 seconds

### Offline Behavior Testing

- [ ] **App starts offline → Displays last known presence**
  - Test Gate: Enable airplane mode
  - Test Gate: Launch app
  - Test Gate: Presence indicators show cached values (gray dots expected)
  - Test Gate: No crashes, no error messages

- [ ] **Go offline mid-session → No crashes**
  - Test Gate: Open app, view conversation list
  - Test Gate: Enable airplane mode
  - Test Gate: App continues functioning normally
  - Test Gate: Presence stops updating but doesn't cause errors

- [ ] **Reconnect → Presence syncs automatically**
  - Test Gate: Disable airplane mode
  - Test Gate: Presence data refreshes within 5 seconds
  - Test Gate: All presence indicators update to current status
  - Test Gate: No manual refresh required

### Performance Testing

Reference targets from `Psst/agents/shared-standards.md`:

- [ ] **App load time < 2-3 seconds**
  - Test Gate: Cold start app (fully closed)
  - Test Gate: Measure time to interactive UI
  - Test Gate: Presence initialization doesn't delay launch
  - Test Gate: Time is < 3 seconds

- [ ] **Smooth 60fps scrolling with presence indicators**
  - Test Gate: Conversation List with 100+ chats (use mock data if needed)
  - Test Gate: Scroll rapidly up and down
  - Test Gate: No jank or frame drops
  - Test Gate: Use Instruments to verify 60fps maintained

- [ ] **Presence updates don't block main thread**
  - Test Gate: Enable Main Thread Checker in Xcode
  - Test Gate: Change presence status (background/foreground app)
  - Test Gate: No Main Thread Checker violations
  - Test Gate: UI remains responsive during updates

### Memory & Lifecycle Testing

- [ ] **No memory leaks from presence listeners**
  - Test Gate: Open Xcode Memory Debugger
  - Test Gate: Open and close 10+ chats
  - Test Gate: Memory usage remains stable (no continuous growth)
  - Test Gate: Use Instruments Leaks tool to verify no leaks

- [ ] **Listeners properly cleaned up on view disappear**
  - Test Gate: Set breakpoint in stopObserving()
  - Test Gate: Navigate away from chat or conversation list
  - Test Gate: Breakpoint hits, listener removed
  - Test Gate: presenceRefs dictionary cleaned up

- [ ] **Listeners cleaned up on logout**
  - Test Gate: Login, attach several presence listeners
  - Test Gate: Logout
  - Test Gate: Verify stopAllObservers() called
  - Test Gate: presenceRefs is empty
  - Test Gate: No dangling Firebase references

---

## 8. Acceptance Gates

Check every gate from PRD Section 12:

- [ ] **All Configuration Testing gates pass** (4 gates)
- [ ] **All Happy Path Testing gates pass** (5 test scenarios)
- [ ] **All Edge Cases Testing gates pass** (5 test scenarios)
- [ ] **All Multi-Device Testing gates pass** (4 test scenarios)
- [ ] **All Offline Behavior Testing gates pass** (3 test scenarios)
- [ ] **All Performance Testing gates pass** (3 test scenarios)
- [ ] **All Memory & Lifecycle Testing gates pass** (3 test scenarios)

**Total Gates:** 27 test scenarios across 7 categories

---

## 9. Documentation & PR

- [ ] Add inline code comments to PresenceService
  - Document each method's purpose
  - Explain onDisconnect() hook setup
  - Note thread safety considerations
  - Test Gate: All public methods have documentation comments

- [ ] Add code comments to UI integration
  - Explain presence listener lifecycle
  - Note main thread dispatch for UI updates
  - Test Gate: Complex logic commented

- [ ] Update README if needed
  - Add Firebase Realtime Database to setup instructions
  - Note offline persistence configuration
  - Test Gate: README accurate and up-to-date

- [ ] Create PR description using template
  ```markdown
  # PR #12: Online/Offline Presence System
  
  ## Summary
  Implements online/offline presence tracking using Firebase Realtime Database with automatic status updates and visual indicators throughout the app.
  
  ## Changes
  - Created PresenceService for Firebase Realtime Database integration
  - Implemented automatic presence updates via app lifecycle monitoring
  - Added PresenceIndicator component (green/gray dot)
  - Integrated presence into Conversation List and Chat View
  - Configured Firebase security rules for presence data
  
  ## Testing
  - [x] Configuration testing (Firebase connection, rules, persistence)
  - [x] Happy path testing (online/offline transitions)
  - [x] Edge cases testing (force quit, airplane mode, logout)
  - [x] Multi-device testing (2+ devices, real-time sync)
  - [x] Performance testing (app load, scrolling, main thread)
  
  ## Related
  - PRD: `Psst/docs/prds/pr-12-prd.md`
  - TODO: `Psst/docs/todos/pr-12-todo.md`
  - Blocks: PR #13 (Typing Indicators)
  ```
  - Test Gate: PR description complete

- [ ] Verify with user before creating PR
  - Show summary of changes
  - Confirm all acceptance gates passed
  - Get explicit approval to create PR
  - Test Gate: User approval received

- [ ] Open PR to develop branch
  - Branch: `feat/pr-12-online-offline-presence-system`
  - Target: `develop`
  - Link PRD and TODO in description
  - Test Gate: PR created successfully

---

## Copyable Checklist (for PR description)

```markdown
- [ ] Branch created from develop
- [ ] All TODO tasks completed
- [ ] PresenceService implemented with proper error handling
- [ ] UserPresence model created
- [ ] PresenceIndicator SwiftUI component created
- [ ] ChatRowView displays presence in conversation list
- [ ] ChatView displays presence in chat header
- [ ] PsstApp.swift lifecycle monitoring implemented
- [ ] Firebase Realtime Database security rules deployed
- [ ] Real-time sync verified across 2+ devices (<3 second latency)
- [ ] onDisconnect() hook tested (force quit, airplane mode)
- [ ] Multi-device sync verified (<3 seconds)
- [ ] Offline behavior tested (cached data displayed)
- [ ] Performance targets met (app load <3s, 60fps scrolling)
- [ ] No memory leaks (verified with Instruments)
- [ ] All acceptance gates pass (27 test scenarios)
- [ ] Code follows Psst/agents/shared-standards.md patterns
- [ ] Main Thread Checker: No violations
- [ ] No console warnings or errors
- [ ] Documentation updated (inline comments, README)
```

---

## Notes

- Break tasks into <30 min chunks
- Complete tasks sequentially (data model → service → UI → integration)
- Check off after completion
- Document blockers immediately
- Reference `Psst/agents/shared-standards.md` for common patterns
- **Critical:** Test multi-device sync early and often (core feature)
- **Critical:** Verify onDisconnect() hook works (handles crashes)
- **Critical:** Check for memory leaks (listeners must be detached)
- Use Firebase Console to verify presence data structure during development
- Test with physical devices when possible (simulators may not fully test lifecycle)

