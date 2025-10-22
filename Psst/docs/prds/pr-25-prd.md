# PRD: Presence Service Refactor - Multi-Listener Fix

**Feature**: presence-service-multi-listener-refactor

**Version**: 1.0

**Status**: Ready for Development

**Agent**: Caleb (Coder Agent)

**Target Release**: Phase 1 Refactor

**Links**: [PR Brief: Psst/docs/pr-briefs.md#PR-25], [TODO: Psst/docs/todos/pr-25-todo.md]

---

## 1. Summary

The current PresenceService has critical bugs causing inconsistent online/offline status updates across ChatListView and ChatView. When multiple views observe the same user's presence, listener conflicts cause status to stop updating. This PRD defines a refactor to support multiple simultaneous listeners per user with proper lifecycle management and comprehensive debug logging.

---

## 2. Problem & Goals

### Current Problems:
1. **Listener Conflicts**: When ChatRowView and ChatView both observe the same user, the second listener overwrites the first in the tracking dictionary, causing the first view to lose updates when the second detaches
2. **Race Conditions**: ChatRowView uses a hacky polling loop (`while otherUserID == nil`) to wait for async user data
3. **Incomplete Crash Protection**: `onDisconnect()` hook only set when going online, not when going offline
4. **Poor Observability**: Insufficient logging makes debugging listener lifecycle issues difficult

### Goals:
- [x] G1 — Support multiple simultaneous presence listeners for the same user without conflicts
- [x] G2 — Eliminate race conditions in listener attachment
- [x] G3 — Ensure crash protection works in all scenarios (login, logout, crash)
- [x] G4 — Add comprehensive debug logging to track listener lifecycle
- [x] G5 — Maintain real-time status updates (<3 second latency) across all views

---

## 3. Non-Goals / Out of Scope

- [ ] Not implementing presence for group chats (intentionally - only 1-on-1 chats show presence)
- [ ] Not adding last seen timestamps (future enhancement)
- [ ] Not optimizing Firebase Realtime Database costs (acceptable for MVP)
- [ ] Not adding presence history/analytics (out of scope)

---

## 4. Success Metrics

### User-Visible:
- Online/offline status updates within 3 seconds across all views
- Status remains consistent when navigating between chat list and individual chats
- Status correctly shows offline when user logs out, app crashes, or goes to background

### System:
- Zero listener conflicts (verified via debug logs)
- Clean listener lifecycle (attach on appear, detach on disappear, no leaks)
- Firebase Realtime Database operations complete in <1 second

### Quality:
- 0 blocking bugs in presence system
- Manual testing passes all acceptance gates
- No memory leaks (verified via Xcode Instruments if needed)

---

## 5. Users & Stories

- As a **chat user**, I want to see accurate online/offline status for my contacts in the chat list, so that I know if they're available
- As a **chat user**, I want to see real-time status updates in the message view, so that I can tell if the other person is actively online
- As a **developer**, I want comprehensive debug logs, so that I can diagnose presence issues quickly
- As a **developer**, I want clean listener management, so that the app doesn't leak memory or have stale listeners

---

## 6. Experience Specification (UX)

### Entry Points:
1. **Chat List (ChatListView → ChatRowView)**: Shows presence indicator next to each 1-on-1 chat contact
2. **Message View (ChatView)**: Shows presence indicator in navigation bar header with contact name

### Visual Behavior:
- 🟢 Green dot = Online (user is actively using the app)
- 🔴 Red dot = Offline (user logged out, closed app, or went to background)
- Presence indicator appears only for 1-on-1 chats (not group chats)
- Status updates animate smoothly (no flickering)

### Loading States:
- Default to offline (red dot) until first presence data arrives
- No loading spinner needed (presence is non-critical)

### Error States:
- If Firebase Realtime Database unavailable, show offline status
- Log errors to console for debugging (don't show user-facing errors)

### Performance:
- Status updates propagate within 3 seconds of change
- No UI blocking during presence operations

---

## 7. Functional Requirements (Must/Should)

### MUST:
- Support multiple simultaneous listeners for the same user without conflicts
- Each listener gets unique UUID identifier for tracking
- Properly detach listeners when views disappear
- Set `onDisconnect()` hook in all scenarios (online, offline, login, logout)
- Update status to offline when user backgrounds app or logs out
- Default to offline status when no data available
- Log all listener lifecycle events (attach, detach, update) for debugging

### SHOULD:
- Clean up empty user dictionaries to prevent memory bloat
- Use structured logging with emojis for easy visual scanning
- Include listener counts in debug logs

### Acceptance Gates:
- **[Gate 1]** ChatRowView shows online status → Navigate to ChatView → Status remains accurate in both views
- **[Gate 2]** User A logs out → User B sees User A go offline within 3 seconds
- **[Gate 3]** App crashes → Firebase automatically sets user offline via `onDisconnect()`
- **[Gate 4]** Open chat list with 5 contacts → Each contact's status loads independently without conflicts
- **[Gate 5]** Navigate between chat list and message view rapidly → No listener leaks or duplicate listeners

---

## 8. Data Model

### Firebase Realtime Database Structure:
```json
{
  "presence": {
    "userID_123": {
      "status": "online",  // or "offline"
      "lastChanged": 1234567890  // Firebase ServerTimestamp
    }
  }
}
```

**No changes to data structure** - Only internal listener management changes.

### Validation Rules:
- Firebase Realtime Database rules already configured
- `status` must be "online" or "offline"
- `lastChanged` is server timestamp

---

## 9. API / Service Contracts

### Updated PresenceService API:

```swift
class PresenceService: ObservableObject {
    
    // CHANGED: Returns UUID instead of DatabaseReference
    func observePresence(
        userID: String, 
        completion: @escaping (Bool) -> Void
    ) -> UUID
    
    // CHANGED: Takes UUID instead of just userID
    func stopObserving(
        userID: String, 
        listenerID: UUID
    )
    
    // UNCHANGED: Already correct
    func setOnlineStatus(
        userID: String, 
        isOnline: Bool
    ) async throws
    
    // UNCHANGED: Already correct
    func stopAllObservers()
}
```

### Internal Data Structure Change:
```swift
// OLD: [userID: reference] - Only one listener per user
private var presenceRefs: [String: DatabaseReference] = [:]

// NEW: [userID: [listenerID: reference]] - Multiple listeners per user
private var presenceRefs: [String: [UUID: DatabaseReference]] = [:]
```

---

## 10. UI Components to Create/Modify

### Services:
- `Services/PresenceService.swift` — **MODIFY**: Support multiple listeners per user with UUID tracking

### Views:
- `Views/ChatList/ChatView.swift` — **MODIFY**: Store and use listener UUID for cleanup
- `Views/ChatList/ChatRowView.swift` — **MODIFY**: Store and use listener UUID for cleanup

### New State Variables:
```swift
// Add to ChatView and ChatRowView
@State private var presenceListenerID: UUID? = nil
```

---

## 11. Integration Points

- **Firebase Realtime Database**: Presence tracking with `.observe(.value)` listeners
- **Firebase Authentication**: User ID for presence keys
- **SwiftUI Lifecycle**: `.onAppear()` and `.onDisappear()` for listener management
- **Environment Objects**: PresenceService injected via `.environmentObject()`

---

## 12. Testing Plan & Acceptance Gates

### Phase 1: Clean Console Logging Setup
- [ ] Add comprehensive logging to PresenceService with emojis (➕ attach, ➖ detach, 👁️ update, 🟢 online, 🔴 offline)
- [ ] Add logging to ChatView presence lifecycle
- [ ] Add logging to ChatRowView presence lifecycle
- [ ] Verify logs are readable and helpful in Xcode console

### Phase 2: Implementation Testing
- [ ] **Config Test**: Firebase Realtime Database connection works
- [ ] **Listener Creation**: `observePresence` returns unique UUID each time
- [ ] **Multiple Listeners**: Can attach 2+ listeners for same user simultaneously
- [ ] **Status Updates**: All listeners receive callbacks when status changes
- [ ] **Cleanup**: `stopObserving` removes only the specified listener, not all

### Phase 3: Integration Testing

#### Single Device Tests:
- [ ] **Happy Path**: Open chat list → All online statuses load correctly
- [ ] **Navigation**: Tap into chat → Status still updates in both chat list and message view
- [ ] **Back Navigation**: Go back to chat list → Both views still show accurate status
- [ ] **Multiple Chats**: Open 3+ different chats in sequence → No listener conflicts

#### Two Device Tests (Use 2 simulators or devices):
- [ ] **Real-time Sync**: Device A user goes online → Device B sees status change within 3 seconds
- [ ] **Logout**: Device A logs out → Device B sees offline within 3 seconds
- [ ] **Background**: Device A backgrounds app → Device B sees offline within 3 seconds
- [ ] **Crash Simulation**: Kill Device A app (force quit) → Device B sees offline within 10 seconds (Firebase timeout)

#### Edge Cases:
- [ ] **No Data**: User never set presence → Shows offline (red dot)
- [ ] **Network Loss**: Disconnect WiFi → Status stops updating (shows last known state)
- [ ] **Network Recovery**: Reconnect WiFi → Status resumes updating

### Phase 4: Performance Testing
- [ ] **Chat List Load**: Open chat list with 10+ contacts → All statuses load within 5 seconds
- [ ] **Rapid Navigation**: Rapidly open/close chats 10 times → No crashes or memory leaks
- [ ] **Memory Test**: Monitor memory in Xcode → No increasing memory usage over time

---

## 13. Definition of Done

- [ ] PresenceService refactored with multi-listener support
- [ ] ChatView updated to use UUID-based listener tracking
- [ ] ChatRowView updated to use UUID-based listener tracking
- [ ] All Phase 1-4 acceptance gates pass
- [ ] Comprehensive debug logging in place
- [ ] Manual two-device testing completed successfully
- [ ] No memory leaks observed
- [ ] Code reviewed and merged to `develop` branch

---

## 14. Risks & Mitigations

### Risk: Breaking existing presence functionality
**Mitigation**: Test thoroughly on single device before two-device testing. Use debug logs to verify correct behavior at each step.

### Risk: Firebase Realtime Database limits
**Mitigation**: Current usage is well within Firebase free tier limits. Monitor connection count in Firebase Console.

### Risk: Race conditions in async listener attachment
**Mitigation**: Use proper async/await patterns and MainActor for UI updates. Remove hacky polling loops.

### Risk: Memory leaks from unremoved listeners
**Mitigation**: Use Xcode Instruments Memory Profiler if leaks suspected. Verify all listeners detach in logs.

---

## 15. Rollout & Telemetry

### Rollout Strategy:
1. Implement changes on feature branch
2. Test manually with single device (Phase 1-3 single device tests)
3. Test with two simulators/devices (Phase 3 two device tests)
4. Merge to `develop` branch after all gates pass
5. Monitor console logs for any issues

### Manual Validation:
- Run app on two devices simultaneously
- Have test accounts chat with each other
- Verify status changes in real-time
- Check console logs for clean listener lifecycle

### Debug Logging Format:
```
[PresenceService] ➕ Added listener abc-123 for user user_456 (total: 2)
[PresenceService] 👁️ Presence update for user_456: 🟢 online
[ChatView] 👁️ ChatView: Attached presence listener for user_456
[ChatRowView] 👁️ ChatRowView: Attached presence listener for user_456
[PresenceService] ➖ Removed listener abc-123 for user_456 (remaining: 1)
```

---

## 16. Open Questions

- ✅ Q1: Should we add presence for group chats?
  - **Answer**: No, only 1-on-1 chats (per requirements)

- ✅ Q2: What's the acceptable latency for status updates?
  - **Answer**: <3 seconds is acceptable (Firebase Realtime Database typical latency)

- ⏳ Q3: Should we implement "last seen" timestamps?
  - **Answer**: Deferred to future enhancement

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future:
- [ ] Last seen timestamps ("Last seen 5 minutes ago")
- [ ] Typing indicators (already exists separately in TypingIndicatorService)
- [ ] Presence history/analytics
- [ ] Presence for group chats
- [ ] Custom status messages ("Busy", "In a meeting", etc.)

---

## 18. Debug Log Tracking Sheet

**Purpose**: Methodical issue tracking during implementation and testing

### Format:
```
[Date/Time] | [Test Scenario] | [Expected] | [Actual] | [Log Output] | [Fix Applied]
```

### Log Entries:

#### 2025-10-22 - Initial Baseline
| Test | Expected | Actual | Logs | Notes |
|------|----------|--------|------|-------|
| Open chat list | All statuses load | ❓ TBD | TBD | Baseline test before refactor |
| Navigate to chat | Status in both views | ❓ TBD | TBD | Looking for conflicts |
| Logout test | Offline within 3s | ❓ TBD | TBD | Check onDisconnect hook |

#### Post-Implementation Testing
| Test | Expected | Actual | Logs | Notes |
|------|----------|--------|------|-------|
| Multiple listeners | 2+ listeners same user | ✅ | TBD | Verify UUID tracking works |
| Listener cleanup | Only target listener removed | ✅ | TBD | Check dict cleanup |
| Status update propagation | All listeners called | ✅ | TBD | Verify no missed updates |

#### Two-Device Testing
| Test | Expected | Actual | Logs | Notes |
|------|----------|--------|------|-------|
| Device A → online | Device B sees green <3s | ✅ | TBD | Real-time sync test |
| Device A → logout | Device B sees red <3s | ✅ | TBD | Disconnect test |
| Device A → crash | Device B sees red <10s | ✅ | TBD | onDisconnect hook test |

#### Known Issues to Track
- [ ] Issue 1: TBD
- [ ] Issue 2: TBD
- [ ] Issue 3: TBD

---

## 19. Implementation Phases

### Phase 1: Logging Infrastructure (30 min)
**Goal**: Add comprehensive logging before making changes

1. Update PresenceService with structured logging
   - Add emojis for visual scanning (➕➖👁️🟢🔴)
   - Log listener counts
   - Log all lifecycle events

2. Update ChatView with logging
   - Log attach/detach events
   - Include user IDs

3. Update ChatRowView with logging
   - Log attach/detach events
   - Include user IDs

4. **Validation**: Run app, verify logs are readable and helpful

### Phase 2: Core Refactor (1 hour)
**Goal**: Implement multi-listener support

1. Update PresenceService internal data structure
2. Change `observePresence` to return UUID
3. Change `stopObserving` to take UUID parameter
4. Update internal tracking logic
5. Add cleanup for empty dictionaries

6. **Validation**: Unit-test-style verification via console logs

### Phase 3: View Updates (30 min)
**Goal**: Update views to use new API

1. Add `@State private var presenceListenerID: UUID?` to ChatView
2. Update attach/detach methods in ChatView
3. Add `@State private var presenceListenerID: UUID?` to ChatRowView  
4. Update attach/detach methods in ChatRowView
5. Remove hacky polling loop from ChatRowView

6. **Validation**: App compiles and runs

### Phase 4: Testing (1-2 hours)
**Goal**: Verify all acceptance gates

1. Single device testing (30 min)
2. Two device testing (30 min)
3. Edge case testing (30 min)
4. Document any issues in Debug Log Tracking Sheet

---

## Preflight Questionnaire

1. **Smallest end-to-end user outcome for this PR?**
   - User sees accurate, consistent online/offline status in chat list and message views

2. **Primary user and critical action?**
   - Chat user viewing presence indicators to know if contacts are available

3. **Must-have vs nice-to-have?**
   - Must: Multi-listener support, crash protection, logging
   - Nice: Performance optimizations, last seen timestamps

4. **Real-time requirements?**
   - Status updates <3 seconds (Firebase Realtime Database standard)

5. **Performance constraints?**
   - No UI blocking, smooth 60fps, <2s initial load

6. **Error/edge cases to handle?**
   - No presence data → offline, Network loss → stale data, Crashes → onDisconnect

7. **Data model changes?**
   - None (only internal service changes)

8. **Service APIs required?**
   - Updated `observePresence()` and `stopObserving()` signatures

9. **UI entry points and states?**
   - Chat list rows, message view header, online/offline states only

10. **Security/permissions implications?**
    - None (using existing Firebase Realtime Database permissions)

11. **Dependencies or blocking integrations?**
    - Firebase Realtime Database must be enabled and configured

12. **Rollout strategy and metrics?**
    - Manual testing on feature branch → merge to develop → monitor logs

13. **What is explicitly out of scope?**
    - Group chat presence, last seen timestamps, custom status messages

---

## Authoring Notes

- **Logging First**: Add comprehensive logs before making changes (critical for debugging)
- **Test Incrementally**: Validate each phase before moving to next
- **Two-Device Testing**: Essential for verifying real-time sync
- **Debug Log Sheet**: Document every issue found during testing
- **Console Hygiene**: Keep logs structured and scannable with emojis
- **Memory Awareness**: Monitor for leaks during rapid navigation testing

