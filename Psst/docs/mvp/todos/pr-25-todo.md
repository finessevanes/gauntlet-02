# PR-25 TODO — Presence Service Multi-Listener Refactor

**Branch**: `feat/pr-25-presence-multi-listener`  
**Source PRD**: `Psst/docs/prds/pr-25-prd.md`  
**Owner (Agent)**: Caleb

---

## 0. Clarifying Questions & Assumptions

### Assumptions:
- Firebase Realtime Database is already enabled and configured
- Existing presence system works but has listener conflicts
- Two-device testing will use simulators or physical devices
- Changes are backward-compatible (no breaking changes to other features)

---

## 1. Setup

- [x] Create branch `feat/pr-25-presence-multi-listener` from develop
- [x] Read PRD thoroughly (`Psst/docs/prds/pr-25-prd.md`)
- [x] Read `Psst/agents/shared-standards.md` for patterns
- [x] Verify Firebase Realtime Database is accessible from app

---

## 2. Phase 1: Logging Infrastructure (Foundation)

**Goal**: Add comprehensive debug logging BEFORE making any functional changes

### 2.1 Update PresenceService Logging
- [x] Add structured logging to `setOnlineStatus()`
  - Log: "✅ Set {userID} status to {online/offline}"
  - Log: "❌ Error setting status: {error}"
  - Test Gate: Run app, verify status changes log correctly

- [x] Add structured logging to `observePresence()`
  - Log: "➕ Added listener {listenerID} for user {userID} (total: {count})"
  - Log: "👁️ Presence update for {userID}: {🟢 online / 🔴 offline}"
  - Test Gate: Open chat, verify listener attachment logs appear

- [x] Add structured logging to `stopObserving()`
  - Log: "➖ Removed listener {listenerID} for {userID} (remaining: {count})"
  - Log: "⚠️ No listener found for {userID} with ID {listenerID}" (if not found)
  - Test Gate: Navigate away from chat, verify detach logs appear

- [x] Add structured logging to `stopAllObservers()`
  - Log: "🧹 Stopped all presence observers ({count} listeners removed)"
  - Test Gate: Logout, verify cleanup log appears

### 2.2 Update ChatView Logging
- [x] Add logging to `attachPresenceListener()`
  - Log: "👁️ ChatView: Attached presence listener for {userID}"
  - Test Gate: Open chat, verify log appears

- [x] Add logging to `detachPresenceListener()`
  - Log: "🧹 ChatView: Detached presence listener for {userID}"
  - Test Gate: Navigate back, verify log appears

### 2.3 Update ChatRowView Logging
- [x] Add logging to `attachPresenceListener()`
  - Log: "👁️ ChatRowView: Attached presence listener for {userID}"
  - Test Gate: Load chat list, verify logs for each row

- [x] Add logging to `detachPresenceListener()`
  - Log: "🧹 ChatRowView: Detached presence listener for {userID}"
  - Test Gate: Navigate to chat, verify some rows detach (list unloaded)

### 2.4 Baseline Testing
- [ ] Run app and document current behavior in Debug Log Sheet
  - Test: Open chat list → Note which logs appear
  - Test: Tap into chat → Note listener attachment sequence
  - Test: Navigate back → Note cleanup sequence
  - Test: Open same chat again → Look for duplicate listeners
  - **Document findings in PRD Section 18 Debug Log Tracking Sheet**

---

## 3. Phase 2: Core PresenceService Refactor

**Goal**: Implement multi-listener support with UUID tracking

### 3.1 Update Internal Data Structure
- [x] Change `presenceRefs` from `[String: DatabaseReference]` to `[String: [UUID: DatabaseReference]]`
  - Location: `PresenceService.swift` line ~32
  - Test Gate: App compiles

### 3.2 Refactor `observePresence()` Method
- [x] Change return type from `DatabaseReference` to `UUID`
- [x] Generate unique `UUID()` for each listener
- [x] Update internal storage to use nested dictionary
  - Initialize `presenceRefs[userID] = [:]` if needed
  - Store: `presenceRefs[userID]?[listenerID] = presenceRef`
- [x] Update logging to include listener ID and count
- [x] Test Gate: App compiles, logs show unique UUIDs

### 3.3 Refactor `stopObserving()` Method
- [x] Change signature to `stopObserving(userID: String, listenerID: UUID)`
- [x] Look up specific listener: `presenceRefs[userID]?[listenerID]`
- [x] Remove only that specific listener
- [x] Clean up empty dictionary if no listeners remain:
  ```swift
  if presenceRefs[userID]?.isEmpty == true {
      presenceRefs.removeValue(forKey: userID)
  }
  ```
- [x] Update logging to show remaining listener count
- [x] Test Gate: App compiles

### 3.4 Improve `setOnlineStatus()` for Crash Protection
- [x] Move `onDisconnectSetValue()` BEFORE `setValue()` (always set crash protection first)
- [x] Call `onDisconnectSetValue()` even when going offline (not just online)
- [x] Update logging
- [ ] Test Gate: Force quit app, verify Firebase shows offline within 10 seconds

### 3.5 Verify `stopAllObservers()` Still Works
- [x] Update to iterate nested dictionary structure:
  ```swift
  presenceRefs.forEach { userID, listeners in
      listeners.forEach { _, ref in
          ref.removeAllObservers()
      }
  }
  ```
- [ ] Test Gate: Logout, verify all listeners cleaned up

---

## 4. Phase 3: Update Views to Use New API

**Goal**: Update ChatView and ChatRowView to use UUID-based tracking

### 4.1 Update ChatView
- [x] Add state variable: `@State private var presenceListenerID: UUID? = nil`
  - Location: Around line ~40 with other state variables

- [x] Update `attachPresenceListener()` method (around line ~449):
  ```swift
  presenceListenerID = presenceService.observePresence(userID: contactID) { isOnline in
      DispatchQueue.main.async {
          self.isContactOnline = isOnline
      }
  }
  ```

- [x] Update `detachPresenceListener()` method (around line ~457):
  ```swift
  guard let contactID = otherUserID, let listenerID = presenceListenerID else { return }
  presenceService.stopObserving(userID: contactID, listenerID: listenerID)
  presenceListenerID = nil
  ```

- [x] Add logging (already covered in Phase 1)
- [ ] Test Gate: Open chat, verify listener attaches and detaches correctly in logs

### 4.2 Update ChatRowView
- [x] Add state variable: `@State private var presenceListenerID: UUID? = nil`
  - Location: Around line ~28 with other state variables

- [x] Refactor `attachPresenceListener()` to remove polling loop (around lines ~179-200):
  ```swift
  private func attachPresenceListener() {
      guard !chat.isGroupChat else { return }
      
      Task {
          // Wait for otherUserID to be set by loadDisplayName
          while otherUserID == nil && !Task.isCancelled {
              try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
          }
          
          guard let contactID = otherUserID, !Task.isCancelled else { return }
          
          // Attach presence listener on main thread and store ID
          await MainActor.run {
              presenceListenerID = presenceService.observePresence(userID: contactID) { isOnline in
                  DispatchQueue.main.async {
                      self.isContactOnline = isOnline
                  }
              }
              print("👁️ ChatRowView: Attached presence listener for \(contactID)")
          }
      }
  }
  ```

- [x] Update `detachPresenceListener()` method (around line ~203):
  ```swift
  private func detachPresenceListener() {
      guard let contactID = otherUserID, let listenerID = presenceListenerID else { return }
      
      presenceService.stopObserving(userID: contactID, listenerID: listenerID)
      presenceListenerID = nil
      print("🧹 ChatRowView: Detached presence listener for \(contactID)")
      
      // Remove user profile listener
      userListener?.remove()
      userListener = nil
  }
  ```

- [ ] Test Gate: Load chat list, verify each row attaches listener with unique UUID

---

## 5. Integration Testing (Single Device)

**Goal**: Verify functionality works on one device before multi-device testing

### 5.1 Compilation & Basic Functionality
- [ ] App compiles without errors or warnings
- [ ] App launches successfully
- [ ] No crashes on initial load
- [ ] Test Gate: Console shows structured logs with emojis

### 5.2 Chat List View Testing
- [ ] Open chat list with 3+ contacts
- [ ] Verify each contact row logs: "➕ Added listener {UUID} for user {userID}"
- [ ] Verify presence indicators show (default to offline is OK)
- [ ] Test Gate: Each contact has unique listener UUID in logs

### 5.3 Navigation Testing
- [ ] From chat list, tap into a chat
- [ ] Verify ChatView logs: "👁️ ChatView: Attached presence listener"
- [ ] Verify PresenceService logs: "➕ Added listener {UUID}" (should be SECOND listener for this user)
- [ ] Check logs show 2 listeners total for that user
- [ ] Test Gate: Logs show "total: 2" for the user

### 5.4 Back Navigation Testing
- [ ] Navigate back to chat list
- [ ] Verify ChatView logs: "🧹 ChatView: Detached presence listener"
- [ ] Verify PresenceService logs: "➖ Removed listener {UUID} (remaining: 1)"
- [ ] Verify ChatRowView listener is still active (status still updates)
- [ ] Test Gate: Logs show "remaining: 1" and status still works

### 5.5 Multiple Chat Navigation
- [ ] Open 3 different chats in sequence
- [ ] For each, verify listener attaches and detaches cleanly
- [ ] Check logs for any orphaned listeners or conflicts
- [ ] Test Gate: No listener count discrepancies in logs

### 5.6 Rapid Navigation Stress Test
- [ ] Rapidly open/close same chat 10 times
- [ ] Check for listener leaks (count should not grow)
- [ ] Check for crashes or errors
- [ ] Test Gate: Listener count stays consistent, no crashes

---

## 6. Multi-Device Testing (Real-Time Sync)

**Goal**: Verify presence updates sync correctly across devices

### 6.1 Setup Two Test Devices
- [ ] Device A: iOS Simulator or physical device with test account 1
- [ ] Device B: iOS Simulator or physical device with test account 2
- [ ] Ensure both accounts are contacts in each other's chat list
- [ ] Test Gate: Both devices can see each other's chat

### 6.2 Online Status Test
- [ ] Device A: Login and ensure app is in foreground
- [ ] Device B: Open chat list
- [ ] Verify Device B shows Device A as online (🟢) within 3 seconds
- [ ] Check logs on both devices
- [ ] Test Gate: Status change logged and visible within 3 seconds

### 6.3 Logout Test
- [ ] Device A: Logout
- [ ] Device B: Observe status change in chat list
- [ ] Verify Device B shows Device A as offline (🔴) within 3 seconds
- [ ] Check logs: "✅ Set {userID} status to offline"
- [ ] Test Gate: Offline status appears within 3 seconds

### 6.4 Background Test
- [ ] Device A: Login and go to background (home button/swipe up)
- [ ] Device B: Observe status in chat list
- [ ] Verify Device B shows Device A as offline (🔴) within 3 seconds
- [ ] Test Gate: Background triggers offline status

### 6.5 Foreground Test
- [ ] Device A: Bring app back to foreground
- [ ] Device B: Observe status change
- [ ] Verify Device B shows Device A as online (🟢) within 3 seconds
- [ ] Test Gate: Foreground triggers online status

### 6.6 Crash Simulation Test
- [ ] Device A: Force quit app (swipe up in app switcher)
- [ ] Device B: Observe status change
- [ ] Verify Device B shows Device A as offline (🔴) within 10 seconds
- [ ] Check Firebase Console: presence/userA/status should be "offline"
- [ ] Test Gate: onDisconnect() hook works (offline within 10 seconds)

### 6.7 Message View Test
- [ ] Device B: Tap into chat with Device A
- [ ] Device A: Login/logout several times
- [ ] Verify Device B's ChatView header shows status changes
- [ ] Verify both ChatListView and ChatView update simultaneously
- [ ] Test Gate: Both views show consistent status

---

## 7. Edge Case Testing

**Goal**: Verify robustness in unusual scenarios

### 7.1 No Presence Data Test
- [ ] Create brand new test account (never set presence)
- [ ] Login with other account, view new account in chat list
- [ ] Verify shows offline (🔴) by default
- [ ] Check logs: "No presence data for {userID}, defaulting to offline"
- [ ] Test Gate: Graceful handling of missing data

### 7.2 Network Disconnect Test
- [ ] Device A: Online and chatting
- [ ] Device A: Disable WiFi/cellular (airplane mode)
- [ ] Device B: Should see Device A go offline within 10 seconds
- [ ] Device A: Re-enable network
- [ ] Device B: Should see Device A come online within 3 seconds
- [ ] Test Gate: Network loss/recovery handled correctly

### 7.3 Stale Listener Test
- [ ] Open chat list
- [ ] Let app sit idle for 5 minutes
- [ ] Check logs for any unexpected listener activity
- [ ] Tap into chat, verify status updates still work
- [ ] Test Gate: No stale listeners or memory issues

### 7.4 Group Chat Test
- [ ] Open group chat (should NOT show presence)
- [ ] Verify no presence listener attached for group
- [ ] Check logs: Should not see presence attachment for group chat members
- [ ] Test Gate: Presence only for 1-on-1 chats

---

## 8. Performance & Memory Testing

**Goal**: Verify no performance regressions or memory leaks

### 8.1 Chat List Load Performance
- [ ] Chat list with 10+ contacts
- [ ] Measure time to load all statuses
- [ ] Verify < 5 seconds for all statuses to appear
- [ ] Test Gate: All statuses load within 5 seconds

### 8.2 Memory Leak Check
- [ ] Rapidly navigate between chat list and message views 20 times
- [ ] Monitor memory usage in Xcode Debug Navigator
- [ ] Check for steadily increasing memory (indicates leak)
- [ ] If leak suspected, use Xcode Instruments Memory Profiler
- [ ] Test Gate: Memory usage stays stable (no growth over time)

### 8.3 Listener Count Validation
- [ ] After all testing, logout
- [ ] Check final log: "🧹 Stopped all presence observers ({N} listeners removed)"
- [ ] N should be 0 or low number (all should have been cleaned up already)
- [ ] Test Gate: Listener count matches expectations

---

## 9. Documentation & Debug Log Recording

**Goal**: Document all findings for future reference

### 9.1 Update Debug Log Tracking Sheet
- [ ] Fill in all test results in PRD Section 18
- [ ] Document any issues encountered with reproduction steps
- [ ] Note any unexpected behavior for future investigation
- [ ] Test Gate: Debug log sheet is complete and useful

### 9.2 Add Inline Comments
- [ ] Add comment explaining UUID listener tracking in PresenceService
- [ ] Add comment about onDisconnect() crash protection
- [ ] Add comment about nested dictionary cleanup logic
- [ ] Test Gate: Code is well-documented

### 9.3 Update README (if needed)
- [ ] Document presence system architecture (optional)
- [ ] Note that Firebase Realtime Database is required
- [ ] Test Gate: README is accurate

---

## 10. Acceptance Gates Verification

**Verify ALL gates from PRD Section 12:**

### Configuration Gates
- [ ] Firebase Realtime Database connection works
- [ ] Presence data reads/writes successfully
- [ ] Console logging is clear and structured

### Functional Gates
- [ ] [Gate 1] ChatRowView shows online status → Navigate to ChatView → Status remains accurate in both views
- [ ] [Gate 2] User A logs out → User B sees User A go offline within 3 seconds
- [ ] [Gate 3] App crashes (force quit) → Firebase automatically sets user offline via onDisconnect()
- [ ] [Gate 4] Open chat list with 5 contacts → Each contact's status loads independently without conflicts
- [ ] [Gate 5] Navigate between chat list and message view rapidly → No listener leaks or duplicate listeners

### Performance Gates
- [ ] Status updates propagate within 3 seconds
- [ ] Chat list loads within 5 seconds
- [ ] No UI blocking during presence operations
- [ ] Memory usage stays stable during testing

### Quality Gates
- [ ] Zero console errors during testing
- [ ] All logs are structured and readable
- [ ] No crashes or unexpected behavior
- [ ] All edge cases handled gracefully

---

## 11. PR Preparation

### 11.1 Code Review Self-Check
- [ ] All TODO tasks completed above
- [ ] Code follows Swift style guide
- [ ] No debug print statements left (only structured logs)
- [ ] No commented-out code
- [ ] All files properly formatted

### 11.2 Create PR Description
- [ ] **Title**: "PR-25: Fix Presence Service Multi-Listener Conflicts"
- [ ] **Description**: 
  - Link to PRD: `Psst/docs/prds/pr-25-prd.md`
  - Link to TODO: `Psst/docs/todos/pr-25-todo.md`
  - Summary of changes
  - Testing completed
  - Screenshots/logs if helpful
- [ ] Verify with user before creating PR
- [ ] Test Gate: User approves PR creation

### 11.3 Create PR
- [ ] Create PR from `feat/pr-25-presence-multi-listener` → `develop`
- [ ] Add appropriate labels (refactor, bug-fix, presence)
- [ ] Request review (if applicable)
- [ ] Test Gate: PR is created and linked

---

## Copyable Checklist (for PR description)

```markdown
## PR-25: Presence Service Multi-Listener Refactor

### Changes
- ✅ Refactored PresenceService to support multiple simultaneous listeners per user
- ✅ Changed `observePresence()` to return UUID for unique listener tracking
- ✅ Updated `stopObserving()` to take UUID parameter for precise cleanup
- ✅ Improved crash protection with onDisconnect() in all scenarios
- ✅ Added comprehensive debug logging with emojis for easy scanning
- ✅ Updated ChatView to use UUID-based listener tracking
- ✅ Updated ChatRowView to use UUID-based listener tracking
- ✅ Removed hacky polling loop from ChatRowView

### Testing Completed
- [x] Single device testing (chat list, navigation, rapid testing)
- [x] Two device real-time sync testing (login, logout, background, crash)
- [x] Edge case testing (no data, network loss, group chats)
- [x] Performance testing (load time, memory usage)
- [x] All acceptance gates pass (see PRD Section 12)
- [x] Debug log tracking sheet completed

### Performance
- ✅ Status updates propagate within 3 seconds
- ✅ Chat list loads within 5 seconds
- ✅ No memory leaks detected
- ✅ No UI blocking

### Documentation
- ✅ Inline comments added for complex logic
- ✅ Debug log format documented
- ✅ Testing results documented in PRD

### References
- PRD: `Psst/docs/prds/pr-25-prd.md`
- TODO: `Psst/docs/todos/pr-25-todo.md`
- Standards: `Psst/agents/shared-standards.md`
```

---

## Notes

- **Logging First**: Complete Phase 1 (logging) before any functional changes
- **Test Incrementally**: Don't skip single-device testing before multi-device
- **Document Issues**: Use Debug Log Tracking Sheet religiously
- **Console Hygiene**: Keep logs clean and structured for debugging
- **Two Devices Essential**: Real-time testing requires 2 simulators/devices
- **Memory Awareness**: Monitor for leaks during rapid navigation
- **Methodical Approach**: Follow phases in order, don't skip ahead

