# PRD: Presence Indicator Redesign & Unread Badges

**Feature**: presence-indicator-redesign-and-unread-badges

**Version**: 1.0

**Status**: Draft

**Agent**: Pam

**Target Release**: Phase 1 (MVP Polish)

**Links**: 
- PR Brief: `Psst/docs/pr-briefs.md` (PR #003)
- TODO: `Psst/docs/todos/pr-003-todo.md` (pending)
- Dependencies: PR #12 (presence system), PR #14 (read receipts)

---

## 1. Summary

Redesign the presence indicator system from the current circle-based design to a modern halo effect around user profile photos, and add unread message indicators with blue halo/badge styling. This creates a cleaner, more intuitive visual hierarchy that helps users quickly identify who is online and which chats have unread messages.

---

## 2. Problem & Goals

**Problem:** The current presence indicator (small circle) is visually disconnected from the user's profile photo and doesn't stand out enough. Additionally, there's no visual indicator for unread messages, forcing users to manually scan their conversation list to find new activity.

**Why now:** Visual polish is critical for MVP launch. Users expect modern, intuitive indicators that match contemporary messaging apps (WhatsApp, Signal, Telegram).

**Goals:**
- [ ] G1 — Replace circle-based presence indicator with halo effect that integrates visually with profile photos
- [ ] G2 — Implement unread message badges/halos that update in real-time as messages arrive
- [ ] G3 — Maintain < 100ms indicator update latency for both presence and unread status changes

---

## 3. Non-Goals / Out of Scope

- [ ] Unread message count numbers (showing "3" for 3 unread messages) - Phase 2 feature
- [ ] Custom halo colors per user - Using standard online (green) and unread (blue) only
- [ ] Animated halo effects - Static halos only for MVP
- [ ] Group chat member-specific presence indicators - Covered in PR #004
- [ ] Notification badges on app icon - Separate push notification feature

---

## 4. Success Metrics

**User-visible:**
- User can identify online contacts within 1 second of viewing chat list
- User can identify chats with unread messages within 1 second
- Presence status updates visible within 100ms of status change
- Unread indicators clear within 100ms of viewing message

**System:**
- Presence listener latency: < 100ms (Firebase Realtime Database)
- Unread count query latency: < 100ms (Firestore)
- UI render time for indicators: < 16ms (60fps target)
- Memory overhead per indicator: < 50KB

**Quality:**
- 0 blocking bugs in indicator rendering
- All acceptance gates pass
- Crash-free rate >99%
- No visual glitches during halo transitions

---

## 5. Users & Stories

- As a user, I want to see a glowing halo around online contacts' profile photos so that I can quickly identify who's available to chat.
- As a user, I want unread chats to have a blue halo or badge so that I can immediately see which conversations need my attention.
- As a user, I want the indicators to update in real-time so that I always see current status without manual refresh.
- As a user, I want the halo effect to be subtle but noticeable so that it enhances the UI without being distracting.
- As a user, I want unread indicators to disappear automatically when I view a message so that I don't have to manually mark things as read.

---

## 6. Experience Specification (UX)

### Entry Points & Flows
- **Chat List Screen**: All chat rows display presence halos (1-on-1 only) and blue dot indicators (any chat with unread messages)
- **Chat Detail Screen**: Header shows presence halo for 1-on-1 contacts
- **User Selection Screen**: User rows show presence halos during contact selection

### Visual Behavior

**Presence Halo (Online Status):**
- Green circular glow around profile photo border
- 2-3pt radius outside the profile photo circle
- Semi-transparent gradient (60% opacity at edge, fading to 0% outward)
- Only visible for online users (1-on-1 chats only)
- Appears/disappears with smooth 0.2s fade animation

**Unread Indicator (Blue Dot):**
- Small blue circle (8px diameter) next to chat name
- Replaces the old green/gray presence circle indicator
- Solid blue fill (Color.blue)
- Appears on any chat with unread messages
- Clears immediately when user views the chat (opens ChatView)
- Works for both 1-on-1 and group chats

**Visual Separation:**
- Presence halo = around avatar (shows online status for 1-on-1)
- Unread dot = next to name (shows unread messages for all chats)
- Both can appear simultaneously - they serve different purposes

### States
- **Default (offline, no unread)**: Profile photo with no halo, no blue dot
- **Online (read)**: Green presence halo around avatar, no blue dot
- **Offline (unread)**: No halo, blue dot next to name
- **Online (unread)**: Green presence halo around avatar + blue dot next to name
- **Loading**: Show default state until status loads
- **Error**: Fallback to offline state (no halo, no dot)

### Performance
- Halo rendering: < 16ms per indicator (60fps)
- Status update propagation: < 100ms
- Real-time listener setup: < 50ms
- Memory per indicator: < 50KB

---

## 7. Functional Requirements (Must/Should)

**MUST:**
- Presence halo renders around profile photos for online users in ChatRowView (1-on-1 chats only)
- Blue dot indicator renders next to chat name for chats with unread messages
- Indicators update in real-time when presence or read status changes
- Unread count calculated accurately by querying messages where currentUserID is not in readBy array
- Blue dot clears within 100ms when user opens ChatView and messages are marked as read
- Presence halo works correctly in all views: ChatListView, ChatRowView, ChatView header, UserSelectionView
- Blue dot works correctly for both 1-on-1 and group chats
- Offline persistence: Cached unread state loads immediately on app restart
- Both indicators can appear simultaneously (green halo + blue dot)

**SHOULD:**
- Smooth fade animations (0.2s) for halo appearance/disappearance
- Graceful degradation if presence service is unavailable (show offline state)
- Optimize Firestore queries to minimize read operations for unread counts

### Acceptance Gates

**Presence Halo:**
- [Gate] When User A goes online → User B sees green halo around User A's photo within 100ms
- [Gate] When User A goes offline → Green halo disappears from User B's view within 100ms
- [Gate] Presence halo renders correctly in ChatRowView, ChatView header, and UserSelectionView
- [Gate] Multiple presence halos on screen (10+ chats) render smoothly at 60fps

**Unread Dot:**
- [Gate] When User A sends message → User B sees blue dot next to that chat name within 100ms
- [Gate] When User B opens chat → Blue dot clears within 100ms
- [Gate] Blue dot shows for both 1-on-1 and group chats with unread messages
- [Gate] Unread count query completes in < 100ms per chat

**Combined State:**
- [Gate] When chat has unread messages and contact is online → Both green halo (around avatar) and blue dot (next to name) show
- [Gate] When unread messages are cleared → Blue dot disappears, green halo remains (if contact still online)

**Offline:**
- [Gate] Offline: Cached unread state displays correctly without network
- [Gate] Offline: Halos show last known state before disconnect

**Error Cases:**
- [Gate] If presence query fails → Show offline state (no halo), no app crash
- [Gate] If unread query fails → Show no unread indicator, no app crash
- [Gate] Invalid user data → Graceful fallback to default state

---

## 8. Data Model

### Existing Models (No Changes)

**User** (Psst/Psst/Models/User.swift) - No changes needed
**Chat** (Psst/Psst/Models/Chat.swift) - No changes needed
**Message** (Psst/Psst/Models/Message.swift) - No changes needed

### New Computed Properties

Add to `Chat.swift`:
```swift
/// Check if this chat has unread messages for the current user
/// Requires querying messages subcollection
/// - Parameter currentUserID: The current user's ID
/// - Returns: True if there are messages not in readBy array
func hasUnreadMessages(currentUserID: String) async -> Bool {
    // Implementation in ChatService
}
```

### Firebase Realtime Database (Presence)
Already implemented in PR #12 - no changes needed:
```
/presence/{userID}
├── status: "online" | "offline"
└── lastChanged: timestamp
```

### Firestore (Messages)
Already implemented - using existing `readBy` array:
```
/chats/{chatID}/messages/{messageID}
├── text: String
├── senderID: String
├── timestamp: Timestamp
└── readBy: [String]  // Used for unread detection
```

### Validation Rules
- Presence status must be "online" or "offline"
- readBy array must contain valid Firebase user IDs
- Unread query must filter currentUserID correctly

---

## 9. API / Service Contracts

### ChatService (Existing - Add Method)

```swift
/// Get unread message count for a specific chat
/// Queries messages subcollection where currentUserID is NOT in readBy array
/// - Parameters:
///   - chatID: The chat ID to query
///   - currentUserID: The current user's ID
/// - Returns: Number of unread messages
/// - Throws: Firebase errors
func getUnreadMessageCount(chatID: String, currentUserID: String) async throws -> Int
```

**Pre-conditions:**
- chatID must exist in Firestore
- currentUserID must be a valid Firebase UID
- User must be a member of the chat

**Post-conditions:**
- Returns accurate count of messages where currentUserID not in readBy
- Returns 0 if all messages are read or chat is empty
- Throws error if query fails

**Error Handling:**
- Network errors: Return cached count if available, else return 0
- Permission denied: Return 0 and log warning
- Invalid parameters: Throw descriptive error

### PresenceService (Existing - No Changes)

Already implemented in PR #12:
```swift
func observePresence(userID: String, completion: @escaping (Bool) -> Void) -> UUID
func stopObserving(userID: String, listenerID: UUID)
```

---

## 10. UI Components to Create/Modify

### New Components

**`Views/Components/PresenceHalo.swift`** — SwiftUI view that renders green presence halo around profile photos
- Accepts `isOnline: Bool` and `size: CGFloat` parameters
- Renders circular gradient glow effect
- 2-3pt radius outside parent view
- Smooth fade animation (0.2s)
- Only shows when isOnline is true

**`Views/Components/UnreadDotIndicator.swift`** — SwiftUI view that renders blue dot next to chat names
- Accepts `hasUnread: Bool` parameter
- Renders small blue circle (8px diameter)
- Solid Color.blue fill
- Smooth fade animation (0.3s)
- Replaces old PresenceIndicator circle in chat row

### Modified Components

**`Views/ChatList/ChatRowView.swift`** — Update to use new presence halo and unread dot
- Remove old PresenceIndicator circle from name section
- Add PresenceHalo overlay to profile photo for 1-on-1 chats
- Add UnreadDotIndicator next to chat name for any chat with unread messages
- Integrate unread count query
- Both indicators can appear simultaneously

**`Views/ChatList/ChatView.swift`** — Update header to use presence halo for 1-on-1 chats
- Add PresenceHalo overlay to profile photo in header for 1-on-1 chats
- Show green halo when contact is online
- No unread dot in chat view (user is already viewing messages)

**`Views/UserSelection/UserRow.swift`** — Add presence halo to user selection
- Add PresenceHalo overlay to profile photo during contact selection
- Display online status to help users pick active contacts
- No unread dot (not applicable in user selection)

**`Views/Components/PresenceIndicator.swift`** — Deprecate or remove
- Old circle-based indicator no longer needed
- Remove usage from all views

---

## 11. Integration Points

**Firebase Realtime Database (Presence):**
- Existing integration via PresenceService
- Real-time listeners for online/offline status
- No new integration needed

**Firestore (Unread Messages):**
- Query messages subcollection per chat
- Filter: `where("readBy", arrayContains: currentUserID) == false`
- Use Firestore cache for offline support
- Snapshot listeners for real-time unread count updates

**State Management:**
- @State for local unread counts in ChatRowView
- @EnvironmentObject for PresenceService (already exists)
- Real-time listeners update state automatically

**SwiftUI Rendering:**
- ZStack overlay pattern for halos
- Gradient + blur effects for glow appearance
- Conditional rendering based on isOnline/hasUnread states

---

## 12. Testing Plan & Acceptance Gates

**Current**: Manual testing validation (see `Psst/agents/shared-standards.md`)  
**Future**: Automated testing recommendations in `Psst/docs/testing-strategy.md`

### Configuration Testing
- [ ] Firebase Realtime Database connection for presence
- [ ] Firestore connection for unread queries
- [ ] PresenceService properly initialized
- [ ] All environment variables set

### Happy Path Testing

**Presence Halo:**
- [ ] User A logs in → User B sees green halo around User A's photo in ChatRowView within 100ms
- [ ] Gate: Presence halo renders correctly in ChatRowView
- [ ] Gate: Presence halo renders correctly in ChatView header (1-on-1)
- [ ] Gate: Presence halo renders correctly in UserSelectionView
- [ ] User A logs out → Green halo disappears from User B's screen within 100ms
- [ ] Gate: Halo disappears smoothly with fade animation

**Unread Halo:**
- [ ] User A sends message to User B → Blue halo appears on that chat in User B's list within 100ms
- [ ] Gate: Unread halo renders correctly in ChatRowView
- [ ] User B opens chat → Blue halo clears within 100ms
- [ ] Gate: Unread indicator clears immediately on chat view
- [ ] Multiple messages sent → Single blue halo (not multiple)
- [ ] Gate: Unread count accurate for multiple messages

**Combined State:**
- [ ] Online contact sends message → Blue halo shows (not green)
- [ ] Gate: Unread halo takes priority over presence halo
- [ ] Messages marked as read + contact online → Green halo appears
- [ ] Gate: Transition from blue to green halo is smooth

### Edge Cases Testing
- [ ] Offline user with unread messages → Blue halo shows correctly
- [ ] Gate: Offline unread state renders correctly
- [ ] No messages in chat → No halo (default state)
- [ ] Gate: Default state (no halo) renders correctly
- [ ] Presence service unavailable → Graceful fallback to offline state
- [ ] Gate: Error state doesn't crash app
- [ ] Unread query fails → No unread indicator, app continues
- [ ] Gate: Unread query errors handled gracefully
- [ ] Invalid user ID → Default state, no crash
- [ ] Gate: Invalid data handled gracefully

### Multi-Device Testing
- [ ] Device 1: User A goes online → Device 2: User B sees green halo < 100ms
- [ ] Gate: Real-time presence sync works cross-device
- [ ] Device 1: User A sends message → Device 2: User B sees blue halo < 100ms
- [ ] Gate: Real-time unread sync works cross-device
- [ ] Device 1: User B opens chat → Device 2: Blue halo clears < 100ms
- [ ] Gate: Read receipt sync clears unread indicators
- [ ] Test with 3+ devices simultaneously
- [ ] Gate: Multi-device sync maintains consistency

### Offline Behavior Testing
- [ ] Offline: Cached presence state displays (last known status)
- [ ] Gate: Offline presence shows last known state
- [ ] Offline: Cached unread state displays correctly
- [ ] Gate: Offline unread indicators work from cache
- [ ] Reconnect: Halos update to current state within 100ms
- [ ] Gate: Reconnection syncs presence and unread state
- [ ] Messages sent offline → Unread halo appears on reconnect
- [ ] Gate: Offline message queue triggers unread indicators

### Performance Testing
- [ ] Chat list with 50+ chats renders at 60fps
- [ ] Gate: Scrolling smooth with multiple halos
- [ ] 10+ presence halos on screen simultaneously → No frame drops
- [ ] Gate: Multiple indicators don't impact performance
- [ ] Unread count queries for 50+ chats < 5 seconds total
- [ ] Gate: Batch unread queries efficient
- [ ] Memory usage with 100+ chats < 100MB for indicators
- [ ] Gate: Memory overhead acceptable
- [ ] App cold start with halos < 2-3 seconds
- [ ] Gate: Indicators don't slow app launch

### Visual States Verification
- [ ] Presence halo: Green, 2-3pt radius, 60% opacity gradient
- [ ] Gate: Presence halo matches design specs
- [ ] Unread halo: Blue, 3-4pt radius, 70% opacity gradient
- [ ] Gate: Unread halo matches design specs
- [ ] Halos don't overlap or clip profile photos
- [ ] Gate: Visual layout clean and professional
- [ ] Fade animations smooth (0.2s duration)
- [ ] Gate: Animations enhance UX without lag
- [ ] Dark mode: Halos visible and aesthetically pleasing
- [ ] Gate: Dark mode support verified

---

## 13. Definition of Done

See standards in `Psst/agents/shared-standards.md`:
- [ ] New halo components (PresenceHalo, UnreadHalo, ProfilePhotoWithHalo) implemented
- [ ] ChatService.getUnreadMessageCount() method implemented with error handling
- [ ] ChatRowView updated with new halo components
- [ ] ChatView header updated with presence halo
- [ ] UserRow updated with presence halo
- [ ] Old PresenceIndicator component removed/deprecated
- [ ] Real-time listeners for presence and unread status functional
- [ ] Offline persistence verified (cached states display correctly)
- [ ] All acceptance gates pass
- [ ] Manual testing completed (configuration, user flows, multi-device, offline, performance)
- [ ] Visual polish verified (halos match design specs)
- [ ] No console errors or warnings
- [ ] Code follows `Psst/agents/shared-standards.md` patterns
- [ ] Inline comments for complex halo rendering logic
- [ ] Documentation updated

---

## 14. Risks & Mitigations

**Risk: Unread count queries impact performance with many chats**
- Mitigation: Implement batch queries and cache results. Use Firestore snapshots to update only changed chats. Limit initial query to 50 chats, lazy load on scroll.

**Risk: Presence and unread halos both active create visual clutter**
- Mitigation: Priority system (unread > presence). Only show one halo type at a time. Blue for unread, green for presence when no unread.

**Risk: Real-time listeners cause memory leaks with many chats**
- Mitigation: Implement proper listener cleanup in onDisappear. Use UUID-based listener tracking (already implemented in PresenceService). Detach listeners when views scroll off-screen.

**Risk: Halo rendering causes frame drops on older devices**
- Mitigation: Use lightweight SwiftUI gradient effects. Test on iPhone 8/SE. Optimize with LazyVStack for chat list. Profile with Instruments to identify bottlenecks.

**Risk: Offline unread state becomes stale**
- Mitigation: Firestore offline persistence automatically syncs on reconnect. Add refresh mechanism when app returns to foreground. Display last sync timestamp if needed.

---

## 15. Rollout & Telemetry

**Feature Flag:** No - Core UI feature for MVP

**Metrics:**
- Presence halo render time (target: <16ms)
- Unread query latency (target: <100ms)
- Listener setup time (target: <50ms)
- User engagement: Time to open unread chats vs. read chats
- Error rate for presence/unread queries

**Manual Validation Steps:**
1. Open chat list with 10+ chats
2. Verify presence halos show for online contacts
3. Send message from second device
4. Verify unread halo appears within 100ms
5. Open chat with unread messages
6. Verify halo clears immediately
7. Check performance with 50+ chats
8. Test offline behavior (airplane mode)
9. Test multi-device sync (3 devices)
10. Verify visual design matches specs

---

## 16. Open Questions

**Q1: Should unread count be displayed numerically (e.g., "3" badge) or just binary (unread/read)?**
- Answer: Binary for MVP (just blue halo presence). Numeric count is Phase 2 feature.

**Q2: Should group chats show composite presence (X/Y members online) or just unread halo?**
- Answer: Group chat presence is covered in PR #004. This PR focuses on 1-on-1 presence halos and unread indicators for all chat types.

**Q3: What happens if a chat has unread messages but all are from the current user?**
- Answer: No unread halo. Unread query filters out messages where currentUserID is in readBy, which includes sender's own messages (automatically marked as read).

**Q4: Should halos animate on appearance/disappearance?**
- Answer: Yes, use 0.2s fade animation for smooth transitions. No pulsing or complex animations for MVP.

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future phases:
- [ ] Numeric unread count badges (Phase 2)
- [ ] Custom halo colors per user
- [ ] Animated/pulsing halo effects
- [ ] Group chat composite presence indicators (PR #004)
- [ ] Unread message previews
- [ ] Mark as read/unread actions
- [ ] Filter chat list by unread status
- [ ] Push notification badge counts

---

## Preflight Questionnaire

1. **Smallest end-to-end user outcome for this PR?**
   - User can visually identify which contacts are online (green halo) and which chats have unread messages (blue halo) at a glance.

2. **Primary user and critical action?**
   - Primary user: Any app user viewing their chat list
   - Critical action: Glance at chat list → Identify online contacts and unread chats within 1 second

3. **Must-have vs nice-to-have?**
   - Must: Green presence halo, blue unread halo, real-time updates, priority system (unread > presence)
   - Nice: Smooth animations, numeric unread counts (Phase 2)

4. **Real-time requirements?**
   - Presence status updates: < 100ms
   - Unread indicator updates: < 100ms
   - Multi-device sync: < 100ms
   - Offline cache: Last known state displays instantly

5. **Performance constraints?**
   - UI render: < 16ms per halo (60fps)
   - Query latency: < 100ms per unread count
   - Memory: < 50KB per indicator
   - App launch: No impact on < 2-3s target

6. **Error/edge cases to handle?**
   - Presence service unavailable → Default to offline
   - Unread query fails → Hide unread indicator
   - Invalid user data → Default state
   - Offline → Show cached state
   - Rapid status changes → Debounce updates

7. **Data model changes?**
   - No schema changes needed
   - Add helper method to ChatService for unread counts
   - Leverage existing readBy array in Message model

8. **Service APIs required?**
   - New: `ChatService.getUnreadMessageCount(chatID:currentUserID:)`
   - Existing: `PresenceService.observePresence(userID:completion:)` (no changes)

9. **UI entry points and states?**
   - Entry: ChatListView (primary), ChatView header, UserSelectionView
   - States: Online (green halo), Unread (blue halo), Default (no halo), Loading, Error

10. **Security/permissions implications?**
    - Firestore security rules already restrict readBy array to chat members
    - Presence data already protected by Firebase Realtime Database rules
    - No new permission requirements

11. **Dependencies or blocking integrations?**
    - Depends on PR #12 (presence system) - Already completed
    - Depends on PR #14 (read receipts) - Need readBy array implementation
    - If PR #14 incomplete: Stub unread feature for later implementation

12. **Rollout strategy and metrics?**
    - Ship with MVP (no feature flag)
    - Monitor: Render performance, query latency, user engagement with unread chats
    - Manual validation: Multi-device testing, offline behavior, visual design review

13. **What is explicitly out of scope?**
    - Numeric unread counts (Phase 2)
    - Group presence indicators (PR #004)
    - Custom animations beyond simple fade
    - Mark as read/unread manual actions
    - Advanced filtering/sorting by unread status

---

## Authoring Notes

**Vertical Slice:**
This PR delivers a complete visual enhancement to the chat list. Users get immediate value from seeing online status and unread messages at a glance. The feature stands alone and doesn't block other work.

**Service Layer:**
ChatService.getUnreadMessageCount() is deterministic and testable. It queries Firestore with clear parameters and returns a count or throws an error. No side effects.

**SwiftUI Views:**
Halo components are thin wrappers around gradient effects. State management is minimal (Bool flags for isOnline/hasUnread). Views react to state changes via real-time listeners.

**Testing Strategy:**
Manual testing focuses on multi-device sync, performance under load, and offline behavior. Visual validation ensures halos match design specs and animate smoothly.

**Performance Considerations:**
Batch unread queries to minimize Firestore reads. Use LazyVStack in chat list for efficient rendering. Cache presence and unread state to avoid redundant queries. Profile with Instruments to verify 60fps rendering.

**Reference Documents:**
- `Psst/agents/shared-standards.md` for real-time messaging requirements, performance targets, and testing standards
- `Psst/docs/architecture.md` for MVVM patterns and service layer structure
- Existing PresenceService implementation for presence listener patterns
- Existing Message model for readBy array usage

