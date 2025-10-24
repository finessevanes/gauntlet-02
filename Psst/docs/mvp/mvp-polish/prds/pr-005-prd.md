# PRD: Group Read Receipts Detailed View

**Feature**: Detailed Group Message Read Receipts

**Version**: 1.0

**Status**: Ready for Development

**Agent**: Pam (Planning Agent)

**Target Release**: Phase 1 - MVP Polish

**Links**: 
- PR Brief: `Psst/docs/pr-briefs.md` (PR #005)
- TODO: `Psst/docs/todos/pr-005-todo.md` (to be created)
- Dependencies: PR #14 (read receipts - completed), PR #11 (group chat support - completed)

---

## 1. Summary

Replace the generic "Read by X/Y" read receipt display in group chats with a detailed, tappable interface that shows exactly which members have read each message by name. This creates a clear, transparent read receipt experience that provides visibility into who has seen messages in group conversations.

---

## 2. Problem & Goals

**Problem**: 
Currently, users in group chats only see a count like "Read by 2/5" under their sent messages. They have no way to know *who specifically* has read their message. This creates uncertainty in group communication and makes it difficult to know if important messages have reached specific team members.

**Why Now**: 
This is a critical MVP polish feature. The basic read receipt system (PR #14) and group chat support (PR #11) are already implemented, but the current implementation feels incomplete. Users expect to see who has read their messages in modern messaging apps (WhatsApp, iMessage, Signal all provide this).

**Goals** (ordered, measurable):
- [ ] **G1** — Users can tap on any read receipt to see who has read the message (by name)
- [ ] **G2** — Detailed view shows member names (not user IDs) for all chat members
- [ ] **G3** — Read receipt detail view loads in <300ms with smooth animations
- [ ] **G4** — System handles large groups (10+ members) efficiently without performance degradation

---

## 3. Non-Goals / Out of Scope

To keep this PR focused and completable within 1-3 days:

- [ ] **Not showing** read timestamps (when each person read the message) - defer to future iteration
- [ ] **Not implementing** read receipts for media messages (only text messages for now)
- [ ] **Not adding** read receipt privacy controls (ability to disable read receipts) - defer to Phase 2
- [ ] **Not adding** sorting/filtering options in the detail view (alphabetical only for now)
- [ ] **Not implementing** notifications when someone reads your message (out of scope)

---

## 4. Success Metrics

**User-visible**:
- Time to view read receipt details: <300ms from tap to modal display
- Number of taps to access detailed view: 1 tap on read receipt indicator
- User can identify who has/hasn't read message within 2 seconds

**System** (see `Psst/agents/shared-standards.md`):
- Read receipt detail view loads in <300ms
- Smooth 60fps animations for modal presentation/dismissal
- No UI blocking during user data fetching
- Batch user fetching completes in <200ms for groups of 10+ members

**Quality**:
- 0 blocking bugs in read receipt detail view
- All acceptance gates pass
- Crash-free rate >99%

---

## 5. Users & Stories

**Primary Users**: Group chat participants who send messages and want to track engagement

**User Stories**:

1. **As a team lead**, I want to see exactly who has read my announcement message so that I can follow up with team members who haven't seen it yet.

2. **As a group chat member**, I want to tap on "Read by 3/8" and see the 3 names who read my message and the 5 who haven't, so that I know if my important message reached the right people.

3. **As a message sender**, I want to quickly distinguish between "read" and "unread" members in the detail view so that I can identify who needs follow-up at a glance.

---

## 6. Experience Specification (UX)

### Entry Points

**From**: `MessageRow` component in `ChatView` (group chats only)

**Trigger**: Tap on `MessageReadIndicatorView` component that shows "Read by X/Y", "Read by all", or "Delivered"

### Visual Behavior

**Tap Interaction**:
- User taps on the read receipt indicator text
- Sheet modal slides up from bottom (iOS native sheet presentation)
- Smooth animation (0.3s spring animation)
- Background dims slightly (standard iOS sheet behavior)

**Detail View Content**:

**Header**:
- Title: "Read By" (bold, 20pt)
- Subtitle: Shows count "4 of 8 members" or "All members"
- Dismiss button (X) in top-right corner

**Two Sections** (if message not fully read):
1. **"Read" Section**:
   - Shows members who have read the message
   - Each row: Profile photo (circular, 40pt) + Name
   - Sorted alphabetically by name
   - Blue checkmark icon next to each name
   
2. **"Not Read Yet" Section**:
   - Shows members who haven't read the message
   - Each row: Profile photo (circular, 40pt) + Name
   - Sorted alphabetically by name
   - Gray color scheme to indicate unread status

**Single Section** (if message fully read):
- Only shows "Read" section with all members
- No "Not Read Yet" section

**States**:
- **Loading**: Skeleton/placeholder rows while fetching user data
- **Empty**: "Delivered" header with all members in "Not Read Yet" section
- **Error**: "Unable to load read receipts" with retry button

**Dismissal**:
- Swipe down on sheet
- Tap X button
- Tap outside sheet (background)

### Performance Targets

See `Psst/agents/shared-standards.md` for general targets. Specific to this feature:

- **Modal presentation**: <50ms from tap to animation start
- **User data fetch**: <200ms to load all member names and photos
- **Full render**: <300ms from tap to fully rendered detail view
- **Smooth animations**: 60fps during sheet presentation/dismissal

---

## 7. Functional Requirements (Must/Should)

### Must-Have Requirements

**R1**: Users MUST be able to tap on read receipt indicators in group chats to open a detailed view
- **Acceptance Gate**: Tap on "Read by 2/5" opens modal within <300ms showing detailed read status

**R2**: Detailed view MUST show member names (not user IDs) for all chat members
- **Acceptance Gate**: Detail view displays "Alice Johnson" and "Bob Smith" instead of user IDs

**R3**: Detailed view MUST distinguish between "Read" and "Not Read Yet" members
- **Acceptance Gate**: Members split into two sections with different colors (blue for read, gray for unread)

**R4**: Detail view MUST handle large groups (10+ members) without performance degradation
- **Acceptance Gate**: Group with 20 members loads detail view in <300ms with smooth scrolling

**R5**: Data fetching MUST happen on background threads to prevent UI blocking
- **Acceptance Gate**: Main thread remains responsive during user data fetch

**R6**: Detail view MUST update in real-time when new members read the message
- **Acceptance Gate**: While detail view is open, User B reads message → User B moves from "Not Read Yet" to "Read" section within <100ms

### Should-Have Requirements

**R7**: Profile photos SHOULD display in detail view for better visual recognition
- **Acceptance Gate**: Members with profile photos show circular avatar, members without show initials

**R8**: Empty states SHOULD provide clear feedback and error recovery
- **Acceptance Gate**: If user data fetch fails, show "Unable to load" with retry button

**R9**: Animations SHOULD follow iOS Human Interface Guidelines for native feel
- **Acceptance Gate**: Sheet presentation uses spring animation matching iOS system sheets

---

## 8. Data Model

### Existing Message Model (No Changes Required)

The existing `readBy` array contains all the data we need. We'll simply fetch user details from the `users` collection to display names instead of IDs.

```swift
// Existing Message model - no changes needed
struct Message {
    let id: String
    let text: String
    let senderID: String
    let timestamp: Date
    var readBy: [String]  // Array of user IDs who have read this message
}
```

### New ViewModel Data Structure

```swift
/// View-ready read receipt data with user information
struct ReadReceiptDetail: Identifiable {
    let id: String  // userID (for Identifiable conformance)
    let userID: String
    let userName: String
    let userPhotoURL: String?
    let hasRead: Bool  // True if in message.readBy array
}
```

### Firestore Schema (No Changes)

Existing schema works as-is. No migration needed.

---

## 9. API / Service Contracts

### New Methods

```swift
/// MessageService.swift - New helper method for read receipt detail view

/// Fetches detailed read receipt information for a message
/// Combines message.readBy array with user data from UserService
/// - Parameters:
///   - message: The message to fetch read receipt details for
///   - chat: The chat containing the message (for member list)
/// - Returns: Array of ReadReceiptDetail with user names and read status
/// - Throws: MessageError if user data fetch fails
func fetchReadReceiptDetails(
    for message: Message, 
    in chat: Chat
) async throws -> [ReadReceiptDetail]
```

### Existing Methods (No Changes)

**MessageService** (from PR #14):
- `markMessagesAsRead()` - already implemented
- `observeMessages()` - already implemented (includes readBy updates)

**UserService**:
- `getUsers(ids:)` - already implemented (batch fetch user data)

### Implementation Logic

The new `fetchReadReceiptDetails` method will:
1. Get all member IDs from `chat.members` (excluding sender)
2. Batch fetch user data using `UserService.getUsers(ids:)`
3. For each member, check if their ID is in `message.readBy`
4. Build `ReadReceiptDetail` objects with userName, photoURL, and hasRead status
5. Sort alphabetically: "Read" section first, then "Not Read Yet" section
6. Return array ready for UI display

---

## 10. UI Components to Create/Modify

### New Components

1. **`Views/Components/ReadReceiptDetailView.swift`**
   - Modal sheet showing detailed read receipt information
   - Two sections: "Read" and "Not Read Yet"
   - Real-time updates via Firestore listener
   - Handles loading, empty, and error states

2. **`Views/Components/ReadReceiptMemberRow.swift`**
   - Individual row for each member in detail view
   - Shows: Profile photo + Name (with checkmark for read members)
   - Reusable component for both sections

3. **`ViewModels/ReadReceiptDetailViewModel.swift`**
   - Manages state for ReadReceiptDetailView
   - Fetches user data and read receipts
   - Handles real-time listener
   - Transforms data to view-ready format

### Modified Components

4. **`Views/Components/MessageReadIndicatorView.swift`**
   - Add tap gesture recognizer (only in group chats)
   - Show visual feedback on tap (slight scale animation)
   - Trigger sheet presentation for ReadReceiptDetailView

5. **`Services/MessageService.swift`**
   - Add `fetchReadReceiptDetails(for:in:)` method
   - Combines message.readBy data with user information

6. **`Models/ReadReceiptDetail.swift`** [NEW FILE]
   - New data model for view-ready read receipt information
   - Contains: userID, userName, photoURL, hasRead

### File Structure

```
Psst/
├── Models/
│   ├── Message.swift [NO CHANGES]
│   └── ReadReceiptDetail.swift [NEW]
├── Services/
│   └── MessageService.swift [MODIFY: add fetchReadReceiptDetails]
├── ViewModels/
│   └── ReadReceiptDetailViewModel.swift [NEW]
└── Views/
    └── Components/
        ├── MessageReadIndicatorView.swift [MODIFY: add tap gesture]
        ├── ReadReceiptDetailView.swift [NEW]
        └── ReadReceiptMemberRow.swift [NEW]
```

---

## 11. Integration Points

### Firebase Firestore
- Read from `chats/{chatID}/messages/{messageID}` collection
- Real-time listeners for read receipt updates
- Use existing `readBy` array (no writes needed for detail view)

### Firebase Authentication
- Get current user ID for filtering members

### UserService
- Batch fetch user data (names, photos) for read receipt display
- Use existing cache for performance
- Handle missing or deleted users gracefully

### State Management (SwiftUI)
- `@State` for modal presentation (isShowingReadReceipts)
- `@StateObject` for ReadReceiptDetailViewModel
- `@Published` properties for real-time updates
- Proper memory management (remove listeners on dismiss)

---

## 12. Testing Plan & Acceptance Gates

**Current**: Manual testing validation (see `Psst/agents/shared-standards.md`)

### Configuration Testing

- [ ] Firebase Auth: User authentication works correctly
- [ ] Firestore: Messages collection accessible with read permissions
- [ ] UserService: Batch user fetching works for 10+ users

### Happy Path Testing

- [ ] **User taps read receipt indicator**: Opens detail modal within <300ms
  - **Gate**: Tap "Read by 2/5" → modal appears smoothly with member list
  
- [ ] **Detail view shows member names**: Displays "Alice Johnson" not "user123"
  - **Gate**: All members show displayName from Firestore users collection
  
- [ ] **Unread members show in separate section**: Clear visual distinction
  - **Gate**: Members who haven't read appear in "Not Read Yet" section with gray styling
  
- [ ] **Dismiss modal works**: Swipe, X button, and background tap all dismiss smoothly
  - **Gate**: All three dismissal methods work with consistent 0.3s animation
  
- [ ] **Real-time updates work**: New reads appear immediately
  - **Gate**: While detail view open, another user reads → moves to "Read" section within <100ms

### Edge Cases Testing

- [ ] **Large groups (10+ members)**: Performance remains smooth
  - **Gate**: Group with 20 members loads detail view in <300ms, scrolls at 60fps
  
- [ ] **No one has read yet**: Shows all members in "Not Read Yet" section
  - **Gate**: Detail view shows "Delivered" state with all members unread
  
- [ ] **All members have read**: Shows single "Read" section, no "Not Read Yet"
  - **Gate**: "Read by all" state shows all members in "Read" section only
  
- [ ] **Missing user data**: Handles deleted or invalid user IDs gracefully
  - **Gate**: If user deleted, shows "Unknown User" with warning in console
  
- [ ] **Network offline**: Shows error state with retry option
  - **Gate**: Offline shows "Unable to load, check connection" message
  
- [ ] **1-on-1 chat**: Read receipt detail view should NOT open (only for groups)
  - **Gate**: Tapping read receipt in 1-on-1 chat does nothing

### Multi-Device Testing

- [ ] **Real-time sync across devices**: Read receipts update <100ms
  - Device 1: User A sends message in group chat
  - Device 2: User B reads message
  - Device 1: User A opens read receipt detail → sees User B in "Read" section within <100ms
  
- [ ] **Modal open during update**: Updates show while detail view visible
  - Device 1: User A opens read receipt detail view, keeps it open
  - Device 2: User B reads the message
  - Device 1: User A sees User B move from "Not Read Yet" to "Read" in real-time

### Performance Testing

- [ ] **Modal presentation**: <50ms from tap to animation start
- [ ] **User data fetch**: <200ms for batch fetching 10+ users
- [ ] **Full render**: <300ms from tap to fully rendered detail view
- [ ] **Smooth animations**: 60fps during sheet presentation/dismissal
- [ ] **No UI blocking**: Main thread remains responsive during data fetch
- [ ] **Listener cleanup**: No memory leaks when dismissing modal

---

## 13. Definition of Done

See standards in `Psst/agents/shared-standards.md`:

- [ ] **Service Layer**: MessageService.fetchReadReceiptDetails() implemented
- [ ] **ViewModel**: ReadReceiptDetailViewModel implemented with real-time listeners
- [ ] **UI Components**: ReadReceiptDetailView and ReadReceiptMemberRow created
- [ ] **Tap Gesture**: MessageReadIndicatorView responds to taps and opens modal (groups only)
- [ ] **Real-time Updates**: Read receipts update in real-time across devices (<100ms)
- [ ] **All Acceptance Gates Pass**: Every gate in Section 12 verified manually
- [ ] **Performance Targets Met**: <300ms load, 60fps animations, no UI blocking
- [ ] **Manual Testing Complete**: Configuration, user flows, multi-device, offline all tested
- [ ] **No Console Errors**: Clean console output during normal usage
- [ ] **Code Quality**: Follows `Psst/agents/shared-standards.md` patterns
- [ ] **SwiftUI Previews**: All new components have working preview code

---

## 14. Risks & Mitigations

### Risk 1: Performance degradation with large groups

**Scenario**: Groups with 50+ members could cause slow loading

**Mitigation**:
- Implement pagination for very large groups (show first 50)
- Use LazyVStack for efficient rendering
- Cache user data aggressively with UserService
- Batch fetch users in chunks of 20

### Risk 2: Real-time listener memory leaks

**Scenario**: Forgetting to remove listeners could cause memory leaks

**Mitigation**:
- Store ListenerRegistration in ViewModel
- Remove listener in `onDisappear` or ViewModel `deinit`
- Use weak self in listener closures
- Test with Xcode Memory Graph Debugger

### Risk 3: User data fetch failures

**Scenario**: If UserService.getUsers() fails, detail view might show blank screen

**Mitigation**:
- Implement comprehensive error handling with try/catch
- Fall back to showing user IDs if names unavailable
- Show error state with retry button instead of crashing
- Cache user data locally to survive temporary network issues

---

## 15. Rollout & Telemetry

### Feature Flag

**Not using feature flags** - This is a core user-facing feature enabled for all users. No gradual rollout needed since it's:
- Non-destructive (doesn't change existing functionality)
- Backward compatible
- Low risk (isolated to read receipt detail view only)

### Metrics to Monitor

**Usage Metrics**:
- Number of read receipt detail views opened per day
- Percentage of users who tap read receipts (engagement rate)

**Performance Metrics**:
- p50, p90, p95 latency for modal presentation
- p50, p90, p95 latency for user data fetching
- Memory usage of real-time listeners

**Error Metrics**:
- User data fetch failure rate
- Firestore read receipt fetch failure rate
- Client-side errors (logged to console)

### Manual Validation Steps

**Before Release**:
1. Test in 1-on-1 chat (feature should not activate)
2. Test in 3-member group (small group)
3. Test in 10-member group (medium group)
4. Test with slow network (throttled to 3G)
5. Test with offline mode (no internet)
6. Test with multiple devices simultaneously
7. Verify no console errors or warnings
8. Confirm all animations are 60fps

---

## 16. Open Questions

**Q1**: Should we limit the number of read receipts displayed to prevent overwhelming UI?
- **Recommendation**: Show all for now, add pagination in Phase 2 if needed
- **Owner**: Caleb (Coder Agent) - decide during implementation based on performance testing

**Q2**: What happens if a user leaves the group after reading a message?
- **Recommendation**: Yes, keep historical read receipts even if member leaves
- **Owner**: Caleb - implement graceful handling for ex-members (show "Former member")

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future phases:

- [ ] **Phase 2**: Read timestamps (when each person read the message)
- [ ] **Phase 2**: Read receipt privacy controls
- [ ] **Phase 2**: Read receipts for media messages
- [ ] **Phase 2**: Sorting/filtering options in detail view
- [ ] **Phase 2**: Bulk actions ("Send reminder to unread members")

---

## Preflight Questionnaire

1. **Smallest end-to-end user outcome?**
   - User taps "Read by 2/5" → sees modal with Alice and Bob in "Read" section, Carol in "Not Read Yet" → understands who has/hasn't read their message

2. **Primary user and critical action?**
   - Group chat message sender who wants to know which members have read their message → taps read receipt indicator

3. **Must-have vs nice-to-have?**
   - **Must**: Tap to open detail, show names, distinguish read/unread, real-time updates
   - **Nice**: Profile photos, smooth animations, error recovery

4. **Real-time requirements?**
   - Read receipts update across devices <100ms
   - Detail view updates in real-time while open

5. **Performance constraints?**
   - Modal presentation <50ms, User data fetch <200ms, Full render <300ms, 60fps animations

6. **Error/edge cases to handle?**
   - User data fetch failures, no one read yet, all read, large groups, offline, missing users

7. **Data model changes?**
   - None - uses existing `readBy` array

8. **Service APIs required?**
   - `fetchReadReceiptDetails(for:in:)` → returns array of ReadReceiptDetail
   - UserService.getUsers(ids:) → batch fetch user data (already exists)

9. **UI entry points and states?**
   - **Entry**: Tap on MessageReadIndicatorView in group chat
   - **States**: Loading, Success, Error, Empty

10. **Security/permissions implications?**
    - Read receipts only visible to chat members (enforce in Firestore rules)

11. **Dependencies?**
    - PR #14 (read receipts) - COMPLETED
    - PR #11 (group chat support) - COMPLETED

12. **What is explicitly out of scope?**
    - Read timestamps, privacy controls, media message read receipts, notifications on read

---

**This PRD is ready for Caleb (Coder Agent) to implement** 🚀
