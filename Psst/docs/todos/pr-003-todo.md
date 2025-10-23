# PR-003 TODO — Presence Indicator Redesign & Unread Badges

**Branch**: `feat/pr-003-presence-indicator-redesign-and-unread-badges`  
**Source PRD**: `Psst/docs/prds/pr-003-prd.md`  
**Owner (Agent)**: Caleb (pending assignment)

---

## 0. Clarifying Questions & Assumptions

**Questions:**
- Is PR #14 (read receipts with readBy array) complete? If not, we can stub the unread count feature for later implementation.

**Assumptions:**
- Presence halo design: Green glow around avatar (2-3pt radius, 60% opacity gradient)
- Unread indicator design: Blue dot next to chat name (8px diameter, solid blue)
- Both indicators can appear simultaneously - they serve different purposes
- Fade animation duration: 0.2s for halo, 0.3s for dot
- PresenceService from PR #12 is fully functional and available
- Message.readBy array is implemented and working (from PR #14)

---

## 1. Setup

- [ ] Create branch `feat/pr-003-presence-indicator-redesign-and-unread-badges` from develop
  - Test Gate: Branch created successfully, git status clean
- [ ] Read PRD thoroughly (`Psst/docs/prds/pr-003-prd.md`)
  - Test Gate: Understand all requirements, acceptance gates, and visual specs
- [ ] Read `Psst/agents/shared-standards.md` for performance and real-time patterns
  - Test Gate: Familiar with <100ms latency requirements and testing standards
- [ ] Review existing PresenceService implementation
  - Test Gate: Understand observePresence() and listener cleanup patterns
- [ ] Confirm Xcode project builds and runs without errors
  - Test Gate: App launches successfully on simulator

---

## 2. Service Layer — Unread Count Query

- [ ] Open `Psst/Psst/Services/ChatService.swift`
  - Test Gate: File opened, existing methods reviewed
- [ ] Implement `getUnreadMessageCount(chatID:currentUserID:)` method
  - Query messages subcollection where currentUserID NOT in readBy array
  - Use Firestore: `whereField("readBy", arrayContains: currentUserID)` negation logic
  - Return Int count of unread messages
  - Test Gate: Method compiles without errors
- [ ] Add error handling for network failures, permission denied, invalid parameters
  - Throw descriptive errors for debugging
  - Test Gate: Error cases handled gracefully
- [ ] Add documentation comments explaining parameters, return values, errors
  - Test Gate: Method fully documented with inline comments
- [ ] Test method manually with Firestore data
  - Create test chat with unread messages
  - Call method and verify correct count returned
  - Test Gate: Unread count accurate for test data

---

## 3. UI Components — New Halo Views

### 3.1 PresenceHalo Component

- [ ] Create `Psst/Psst/Views/Components/PresenceHalo.swift`
  - Test Gate: File created in correct directory
- [ ] Implement PresenceHalo SwiftUI view
  - Accept `isOnline: Bool` and `size: CGFloat` parameters
  - Render green circular gradient (2-3pt radius outside parent)
  - Use linear gradient: green at 60% opacity fading to 0% outward
  - Add conditional visibility: only show when isOnline == true
  - Test Gate: SwiftUI Preview renders correctly
- [ ] Add fade animation (0.2s duration) for appearance/disappearance
  - Use `.animation(.easeInOut(duration: 0.2), value: isOnline)`
  - Test Gate: Animation smooth in Preview
- [ ] Add documentation comments
  - Test Gate: Purpose and parameters documented
- [ ] Test in SwiftUI Preview with both true/false states
  - Test Gate: Halo appears for online, disappears for offline

### 3.2 UnreadDotIndicator Component

- [ ] Create `Psst/Psst/Views/Components/UnreadDotIndicator.swift`
  - Test Gate: File created in correct directory
- [ ] Implement UnreadDotIndicator SwiftUI view
  - Accept `hasUnread: Bool` parameter
  - Render small blue circle (8px diameter)
  - Use solid Color.blue fill
  - Add conditional visibility: only show when hasUnread == true
  - Test Gate: SwiftUI Preview renders correctly
- [ ] Add fade animation (0.3s duration) for appearance/disappearance
  - Use `.animation(.easeInOut(duration: 0.3), value: hasUnread)`
  - Test Gate: Animation smooth in Preview
- [ ] Add documentation comments
  - Test Gate: Purpose and parameters documented
- [ ] Test in SwiftUI Preview with both true/false states
  - Test Gate: Dot appears for unread, disappears for read

### 3.3 Delete Old ProfilePhotoWithHalo and UnreadHalo Files

- [ ] Delete `Psst/Psst/Views/Components/ProfilePhotoWithHalo.swift` (no longer needed)
  - Test Gate: File deleted
- [ ] Delete `Psst/Psst/Views/Components/UnreadHalo.swift` (replaced by UnreadDotIndicator)
  - Test Gate: File deleted

---

## 4. UI Components — Modify Existing Views

### 4.1 Update ChatRowView

- [ ] Open `Psst/Psst/Views/ChatList/ChatRowView.swift`
  - Test Gate: File opened, existing code reviewed
- [ ] Add @State for unread count
  - `@State private var unreadCount: Int = 0`
  - Test Gate: State variable added
- [ ] Add PresenceHalo overlay to profile photo for 1-on-1 chats
  - Wrap ProfilePhotoPreview in ZStack
  - Add PresenceHalo as overlay with isOnline state
  - Test Gate: Code compiles, green halo renders around avatar
- [ ] Add UnreadDotIndicator next to chat name
  - Place before chat name in HStack
  - Show when unreadCount > 0
  - Test Gate: Blue dot appears next to name for unread chats
- [ ] Add method to fetch unread count: `loadUnreadCount()`
  - Call ChatService.getUnreadMessageCount() in background
  - Update unreadCount state on main thread
  - Handle errors gracefully (default to 0 on error)
  - Test Gate: Method implemented with proper error handling
- [ ] Call loadUnreadCount() in `.task` or `.onAppear`
  - Test Gate: Unread count loads when view appears
- [ ] Add real-time listener for unread updates (optional for MVP)
  - Use Firestore snapshot listener on messages subcollection
  - Update unreadCount when new messages arrive
  - Test Gate: Real-time updates work (or stub for Phase 2)
- [ ] Test in app with real Firebase data
  - View chat list with online/offline contacts
  - Verify halos display correctly
  - Test Gate: Halos render on actual device/simulator

### 4.2 Update ChatView Header

- [ ] Open `Psst/Psst/Views/ChatList/ChatView.swift`
  - Test Gate: File opened, header section identified
- [ ] Locate chat header section (typically in navigationBar or custom header)
  - Test Gate: Header code identified
- [ ] Add PresenceHalo overlay to profile photo in header for 1-on-1 chats
  - Wrap ProfilePhotoPreview in ZStack
  - Add PresenceHalo as overlay with isOnline state
  - No unread dot in chat view (user is already viewing messages)
  - Test Gate: Green halo displays in header when contact is online
- [ ] Ensure conditional rendering (only for 1-on-1 chats, not groups)
  - Test Gate: Halo shows for 1-on-1, hidden for groups
- [ ] Test in app
  - Open 1-on-1 chat with online contact
  - Verify green presence halo in header
  - Test Gate: Header halo displays correctly

### 4.3 Update UserRow (User Selection)

- [ ] Open `Psst/Psst/Views/UserSelection/UserRow.swift`
  - Test Gate: File opened, avatar section identified
- [ ] Add @State for user online status
  - `@State private var isUserOnline: Bool = false`
  - Test Gate: State variable added
- [ ] Add PresenceHalo overlay to profile photo
  - Wrap ProfilePhotoPreview in ZStack
  - Add PresenceHalo as overlay with isUserOnline state
  - No unread dot (not applicable in user selection)
  - Test Gate: Code compiles, green halo shows for online users
- [ ] Add presence listener in `.onAppear`
  - Use PresenceService.observePresence() with user.id
  - Update isUserOnline state
  - Store listener UUID for cleanup
  - Test Gate: Listener attached correctly
- [ ] Add listener cleanup in `.onDisappear`
  - Call PresenceService.stopObserving() with stored UUID
  - Test Gate: No memory leaks (verify with Instruments if needed)
- [ ] Test in app
  - Open user selection screen
  - Verify presence halos show for online users
  - Test Gate: User selection halos work correctly

### 4.4 Remove Old PresenceIndicator (Optional Cleanup)

- [ ] Search codebase for PresenceIndicator usage
  - Use grep: `grep -r "PresenceIndicator" Psst/Psst/Views/`
  - Test Gate: All usages identified
- [ ] Verify PresenceIndicator is no longer referenced
  - Test Gate: Only new components used now
- [ ] Delete or deprecate `Psst/Psst/Views/Components/PresenceIndicator.swift` (if exists)
  - Add deprecation comment if keeping for reference
  - Test Gate: Cleanup complete

---

## 5. Integration & Real-Time

- [ ] Verify PresenceService integration
  - Test Gate: Presence listeners work in ChatRowView and UserRow
- [ ] Verify unread count updates in real-time
  - Send message from Device 1 to Device 2
  - Check if blue halo appears on Device 2 within 100ms
  - Test Gate: Real-time unread indicator works
- [ ] Test combined indicators
  - Create scenario: online contact + unread messages
  - Verify both green halo (around avatar) and blue dot (next to name) show
  - Mark messages as read
  - Verify blue dot disappears, green halo remains (if still online)
  - Test Gate: Both indicators work independently and simultaneously
- [ ] Test listener cleanup
  - Scroll chat list up/down rapidly
  - Check for memory leaks using Xcode Memory Graph Debugger
  - Test Gate: No dangling listeners or memory leaks
- [ ] Test offline persistence
  - Enable airplane mode
  - Verify last known presence and unread state displays
  - Disable airplane mode
  - Verify halos update to current state
  - Test Gate: Offline behavior correct

---

## 6. Testing Validation

**Current**: Manual testing validation (see `Psst/agents/shared-standards.md`)

### 6.1 Configuration Testing

- [ ] Firebase Realtime Database connection for presence
  - Test Gate: PresenceService connects successfully
- [ ] Firestore connection for unread queries
  - Test Gate: ChatService queries work without errors
- [ ] PresenceService properly initialized as @EnvironmentObject
  - Test Gate: No runtime errors about missing environment object
- [ ] All environment variables and Firebase config set
  - Test Gate: GoogleService-Info.plist configured

### 6.2 Happy Path Testing

**Presence Halo:**
- [ ] User A logs in → User B sees green halo around User A's photo within 100ms
  - Test Gate: Real-time presence update works
- [ ] Green halo renders correctly in ChatRowView
  - Test Gate: Visual appearance matches design specs
- [ ] Green halo renders correctly in ChatView header (1-on-1)
  - Test Gate: Header halo displays properly
- [ ] Green halo renders correctly in UserSelectionView
  - Test Gate: User selection halos work
- [ ] User A logs out → Green halo disappears within 100ms
  - Test Gate: Offline transition works

**Unread Halo:**
- [ ] User A sends message → User B sees blue halo on that chat within 100ms
  - Test Gate: Real-time unread indicator appears
- [ ] Blue halo renders correctly in ChatRowView
  - Test Gate: Visual appearance matches design specs (3-4pt radius, 70% opacity)
- [ ] User B opens chat → Blue halo clears within 100ms
  - Test Gate: Read status updates clear indicator
- [ ] Multiple messages sent → Single blue halo (not multiple)
  - Test Gate: Indicator shows presence, not count
- [ ] Unread count accurate for multiple messages
  - Test Gate: getUnreadMessageCount() returns correct number

**Combined State:**
- [ ] Online contact sends message → Blue halo shows (not green)
  - Test Gate: Priority system correct (unread > presence)
- [ ] Messages marked as read + contact online → Green halo appears
  - Test Gate: Transition from blue to green smooth

### 6.3 Edge Cases Testing

- [ ] Offline user with unread messages → Blue halo shows correctly
  - Test Gate: Offline unread state renders
- [ ] No messages in chat → No halo (default state)
  - Test Gate: Default state renders correctly
- [ ] Presence service unavailable → Graceful fallback to offline state
  - Test Gate: No crashes on presence errors
- [ ] Unread query fails → No unread indicator, app continues
  - Test Gate: Unread errors handled gracefully
- [ ] Invalid user ID → Default state, no crash
  - Test Gate: Invalid data handled
- [ ] Chat with only current user's messages → No unread halo
  - Test Gate: Own messages don't trigger unread indicator

### 6.4 Multi-Device Testing

- [ ] Device 1: User A goes online → Device 2: User B sees green halo < 100ms
  - Test Gate: Multi-device presence sync works
- [ ] Device 1: User A sends message → Device 2: User B sees blue halo < 100ms
  - Test Gate: Multi-device unread sync works
- [ ] Device 1: User B opens chat → Device 2: Blue halo clears < 100ms
  - Test Gate: Read receipt sync clears indicators
- [ ] Test with 3+ devices simultaneously
  - Test Gate: Multi-device consistency maintained

### 6.5 Offline Behavior Testing

- [ ] Offline: Cached presence state displays (last known status)
  - Test Gate: Offline presence shows cached state
- [ ] Offline: Cached unread state displays correctly
  - Test Gate: Offline unread indicators work from cache
- [ ] Reconnect: Halos update to current state within 100ms
  - Test Gate: Reconnection syncs properly
- [ ] Messages sent offline → Unread halo appears on reconnect
  - Test Gate: Offline queue triggers indicators

### 6.6 Performance Testing

- [ ] Chat list with 50+ chats renders at 60fps
  - Use Xcode Instruments to measure frame rate
  - Test Gate: Smooth scrolling, no frame drops
- [ ] 10+ presence halos on screen simultaneously → No performance issues
  - Test Gate: Multiple indicators don't slow rendering
- [ ] Unread count queries for 50+ chats complete in < 5 seconds total
  - Test Gate: Batch queries efficient
- [ ] Memory usage with 100+ chats < 100MB for indicators
  - Use Xcode Memory Graph Debugger
  - Test Gate: Memory overhead acceptable
- [ ] App cold start with halos < 2-3 seconds
  - Test Gate: Indicators don't slow app launch

---

## 7. Visual Polish

- [x] Verify presence halo design specs
  - Green color: System green or custom (#00FF00 range)
  - Radius: 2-3pt outside profile photo
  - Opacity: 60% at edge, fading to 0%
  - Test Gate: Matches design specifications (implemented in PresenceHalo.swift)
- [ ] Verify unread dot design specs
  - Blue color: System blue (Color.blue)
  - Size: 8px diameter circle
  - Style: Solid fill (no gradient)
  - Test Gate: Matches design specifications (implemented in UnreadDotIndicator.swift)
- [x] Test fade animations
  - Duration: 0.2 seconds
  - Easing: ease-in-out
  - Test Gate: Animations smooth, not jarring (implemented with .animation(.easeInOut(duration: 0.2)))
- [x] Verify halos don't overlap or clip profile photos
  - Test Gate: Layout clean and professional (halos rendered as overlays)
- [ ] Test dark mode appearance
  - Halos visible and aesthetically pleasing in dark mode
  - Test Gate: Dark mode support verified
- [ ] Test on different device sizes (iPhone SE, iPhone 15 Pro Max, iPad)
  - Test Gate: Halos scale correctly on all devices

---

## 8. Acceptance Gates

Check every gate from PRD Section 12:

**Presence Halo Gates:**
- [ ] When User A goes online → User B sees green halo within 100ms
- [ ] When User A goes offline → Green halo disappears within 100ms
- [ ] Presence halo renders correctly in ChatRowView, ChatView header, UserSelectionView
- [ ] Multiple presence halos on screen (10+) render smoothly at 60fps

**Unread Dot Gates:**
- [ ] When User A sends message → User B sees blue dot next to chat name within 100ms
- [ ] When User B opens chat → Blue dot clears within 100ms
- [ ] Blue dot shows for both 1-on-1 and group chats with unread messages
- [ ] Unread count query completes in < 100ms per chat

**Combined State Gates:**
- [ ] When chat has unread + contact online → Both green halo (avatar) and blue dot (name) show
- [ ] When unread cleared → Blue dot disappears, green halo remains (if contact still online)

**Offline Gates:**
- [ ] Offline: Cached unread state displays correctly
- [ ] Offline: Halos show last known state

**Error Gates:**
- [ ] Presence query fails → Show offline state, no crash
- [ ] Unread query fails → No indicator, no crash
- [ ] Invalid user data → Graceful fallback

---

## 9. Documentation & PR

- [ ] Add inline code comments for halo rendering logic
  - Document gradient calculations for PresenceHalo
  - Document indicator positioning for UnreadDotIndicator
  - Test Gate: Complex logic documented
- [ ] Add documentation comments to getUnreadMessageCount() method
  - Test Gate: Service method fully documented
- [ ] Update README if needed (mention new halo system)
  - Test Gate: Documentation updated
- [ ] Create PR description using format from `Psst/agents/caleb-agent.md`
  - Include: Feature summary, technical changes, testing performed, screenshots
  - Test Gate: PR description comprehensive
- [ ] Take screenshots of new indicators
  - Online presence (green halo around avatar)
  - Unread messages (blue dot next to name)
  - Combined state (green halo + blue dot)
  - Test Gate: Visual documentation included
- [ ] Verify with user before creating PR
  - Test Gate: User approval obtained
- [ ] Open PR targeting develop branch
  - Branch: `feat/pr-003-presence-indicator-redesign-and-unread-badges` → `develop`
  - Test Gate: PR created successfully
- [ ] Link PRD and TODO in PR description
  - PRD: `Psst/docs/prds/pr-003-prd.md`
  - TODO: `Psst/docs/todos/pr-003-todo.md`
  - Test Gate: Links included in PR

---

## Copyable Checklist (for PR description)

```markdown
## PR #003: Presence Indicator Redesign & Unread Badges

### Summary
Redesigned presence and unread indicators for better visual clarity. Green halo around profile photos shows online status (1-on-1 chats only). Blue dot next to chat name shows unread messages (all chats). Both indicators can appear simultaneously.

### Technical Changes
- **New Components:**
  - `PresenceHalo.swift` - Green circular glow around avatar for online status
  - `UnreadDotIndicator.swift` - Blue dot next to chat name for unread messages
- **Modified Components:**
  - `ChatRowView.swift` - Added presence halo to avatar + blue dot to name
  - `ChatView.swift` - Added presence halo to header
  - `UserRow.swift` - Added presence halo to user selection
- **Service Layer:**
  - Added `ChatService.getUnreadMessageCount()` method
  - Queries messages where currentUserID NOT in readBy array

### Checklist
- [ ] Branch created from develop
- [ ] All TODO tasks completed
- [ ] Service method implemented with error handling
- [ ] Two new indicator components created (PresenceHalo, UnreadDotIndicator)
- [ ] ChatRowView, ChatView, UserRow updated
- [ ] Real-time sync verified (<100ms latency)
- [ ] Manual testing completed (config, flows, multi-device, offline, performance)
- [ ] Combined indicators tested (green halo + blue dot simultaneously)
- [ ] Performance targets met (60fps with 10+ indicators)
- [ ] Visual specs verified (design matches requirements)
- [ ] Dark mode tested
- [ ] All acceptance gates pass
- [ ] Code follows `Psst/agents/shared-standards.md` patterns
- [ ] No console warnings
- [ ] Documentation updated
- [ ] Screenshots included
```

---

## Notes

- Break tasks into <30 min chunks
- Complete tasks sequentially
- Check off after completion
- Document blockers immediately
- Reference `Psst/agents/shared-standards.md` for common patterns
- Test real-time updates thoroughly (<100ms requirement is critical)
- Verify listener cleanup to prevent memory leaks
- Both indicators can appear simultaneously - test this scenario
- Green halo around avatar, blue dot next to name - different locations
- If PR #14 (read receipts) incomplete, stub unread feature for later implementation

