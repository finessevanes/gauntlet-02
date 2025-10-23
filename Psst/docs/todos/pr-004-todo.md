# PR-004 TODO — Group Online Indicators and Member Status

**Branch**: `feat/pr-004-group-online-indicators-and-member-status`  
**Source PRD**: `Psst/docs/prds/pr-004-prd.md`  
**Owner (Agent)**: Caleb (Coder Agent)

---

## 0. Clarifying Questions & Assumptions

**Questions**:
- None - PRD is comprehensive and approved

**Assumptions (confirm in PR if needed)**:
- Existing PresenceService (PR #12) is fully functional and tested
- Group chat functionality (PR #11) is working correctly
- Firebase Realtime Database security rules allow reading all user presence
- Maximum group size for initial release is 50 members
- Online indicator will be 8pt green dot, offline will be 8pt gray dot at 50% opacity

---

## 1. Setup

- [x] Create branch `feat/pr-004-group-online-indicators-and-member-status` from develop
  - Test Gate: Branch created and checked out successfully
  
- [x] Read PRD thoroughly (`Psst/docs/prds/pr-004-prd.md`)
  - Test Gate: Understand all requirements and acceptance gates
  
- [x] Read `Psst/agents/shared-standards.md` for patterns
  - Test Gate: Familiar with performance targets and real-time messaging requirements
  
- [x] Confirm Firebase Realtime Database connection works
  - Test Gate: Can read from `/presence/{userID}` path in Firebase console
  
- [x] Verify existing PresenceService functionality
  - Test Gate: Single-user presence observation works in 1-on-1 chats

---

## 2. Data Model

### Create GroupPresence Model

- [x] Create `Psst/Psst/Models/GroupPresence.swift`
  - Test Gate: File compiles with no errors
  
- [x] Implement GroupPresence struct with properties:
  ```swift
  struct GroupPresence {
      let chatID: String
      var memberPresences: [String: Bool]  // userID -> isOnline
      var listeners: [String: UUID]         // userID -> listenerID
      var onlineCount: Int
      var offlineCount: Int
  }
  ```
  - Test Gate: Struct definition compiles and computed properties work correctly
  
- [x] Add initializer and helper methods
  - Test Gate: Can create GroupPresence instance and access all properties

---

## 3. Service Layer — Extend PresenceService

### Add Group Presence Observation Method

- [x] Open `Psst/Psst/Services/PresenceService.swift`
  - Test Gate: File opens and existing methods are intact
  
- [x] Add `observeGroupPresence()` method:
  ```swift
  func observeGroupPresence(
      userIDs: [String], 
      completion: @escaping (String, Bool) -> Void
  ) -> [String: UUID]
  ```
  - Test Gate: Method signature compiles
  
- [x] Implement loop to observe each user individually
  - Use existing `observePresence()` for each userID
  - Collect listenerIDs in dictionary keyed by userID
  - Test Gate: Can observe 5 users and get callbacks for all
  
- [x] Add validation for empty userIDs array
  - Return empty dictionary if array is empty
  - Test Gate: Edge case handled gracefully
  
- [x] Add logging for group presence observation
  - Log number of users being observed and chatID if available
  - Test Gate: Console shows clear debug output

### Add Group Cleanup Method

- [x] Add `stopObservingGroup()` method:
  ```swift
  func stopObservingGroup(listeners: [String: UUID])
  ```
  - Test Gate: Method signature compiles
  
- [x] Implement cleanup loop
  - For each (userID, listenerID) pair, call existing `stopObserving()`
  - Test Gate: All listeners properly removed
  
- [x] Add logging for cleanup
  - Log number of listeners being cleaned up
  - Test Gate: Console confirms all listeners removed
  
- [x] Add defensive nil checking
  - Silently ignore invalid listenerIDs
  - Test Gate: No crashes with invalid input

### Add Listener Deduplication (Optimization)

- [ ] Add internal tracking for shared listeners
  - Create `private var sharedListeners: [String: [UUID: (Bool) -> Void]]` to track multiple callbacks per user
  - Test Gate: Data structure defined correctly
  
- [ ] Implement `getSharedPresenceListener()` method:
  ```swift
  func getSharedPresenceListener(
      userID: String, 
      completion: @escaping (Bool) -> Void
  ) -> UUID
  ```
  - Test Gate: Method signature compiles
  
- [ ] Check if listener already exists for userID
  - If exists, add completion to subscribers list and return new UUID
  - If not exists, create new listener via `observePresence()`
  - Test Gate: Single Firebase listener handles multiple UI components
  
- [ ] Update `stopObserving()` to handle shared listeners
  - Only remove Firebase listener when last subscriber unsubscribes
  - Test Gate: Listener persists when other subscribers still active

---

## 4. UI Components — Create New Views

### Create OnlineIndicator Component

- [x] Create `Psst/Psst/Views/Components/OnlineIndicator.swift`
  - Test Gate: File created in correct directory
  
- [x] Implement OnlineIndicator view:
  ```swift
  struct OnlineIndicator: View {
      let isOnline: Bool
      let size: CGFloat = 8
      
      var body: some View {
          Circle()
              .fill(isOnline ? Color.green : Color.gray.opacity(0.5))
              .frame(width: size, height: size)
      }
  }
  ```
  - Test Gate: SwiftUI Preview shows green and gray dots correctly
  
- [x] Add fade animation for status changes
  - Use `.animation(.easeInOut(duration: 0.3), value: isOnline)`
  - Test Gate: Preview shows smooth transition when toggling isOnline
  
- [x] Add accessibility label
  - "Online" or "Offline" for VoiceOver
  - Test Gate: Accessibility inspector shows correct labels

### Create ProfilePhotoWithPresence Component

- [x] Create `Psst/Psst/Views/Components/ProfilePhotoWithPresence.swift`
  - Test Gate: File created successfully
  
- [x] Implement ProfilePhotoWithPresence view:
  ```swift
  struct ProfilePhotoWithPresence: View {
      let userID: String
      let photoURL: String?
      let size: CGFloat
      @State private var isOnline: Bool = false
      @State private var listenerID: UUID?
      
      var body: some View {
          ZStack(alignment: .bottomTrailing) {
              // Profile photo
              AsyncImage(url: URL(string: photoURL ?? ""))
                  .frame(width: size, height: size)
                  .clipShape(Circle())
              
              // Online indicator overlay
              OnlineIndicator(isOnline: isOnline)
                  .offset(x: 2, y: 2)
          }
      }
  }
  ```
  - Test Gate: SwiftUI Preview renders profile photo with indicator
  
- [x] Add presence observation in `.onAppear`
  - Call `PresenceService.shared.observePresence()` for userID
  - Update `isOnline` state in completion handler
  - Test Gate: Indicator updates when user status changes
  
- [x] Add cleanup in `.onDisappear`
  - Call `PresenceService.shared.stopObserving()` with listenerID
  - Test Gate: Listener removed when view disappears
  
- [x] Add fallback for missing profile photo
  - Show user initials or placeholder icon
  - Test Gate: Component handles nil photoURL gracefully
  
- [x] Add loading state
  - Default to offline (gray) while loading
  - Test Gate: Initial render shows gray indicator

### Create GroupMemberStatusView

- [x] Create `Psst/Psst/Views/ChatList/GroupMemberStatusView.swift`
  - Test Gate: File created in ChatList directory
  
- [x] Create GroupPresenceTracker ViewModel:
  ```swift
  class GroupPresenceTracker: ObservableObject {
      @Published var memberPresences: [String: Bool] = [:]
      private var listeners: [String: UUID] = [:]
      private let presenceService = PresenceService.shared
      
      func observeMembers(userIDs: [String]) { }
      func cleanup() { }
  }
  ```
  - Test Gate: ViewModel compiles and publishes state changes
  
- [x] Implement observeMembers() in ViewModel
  - Call `presenceService.observeGroupPresence()`
  - Update `memberPresences` dictionary in completion handler
  - Test Gate: Dictionary updates when status changes
  
- [x] Implement cleanup() in ViewModel
  - Call `presenceService.stopObservingGroup()`
  - Clear `memberPresences` and `listeners`
  - Test Gate: All listeners removed
  
- [x] Implement GroupMemberStatusView UI:
  ```swift
  struct GroupMemberStatusView: View {
      let chat: Chat
      @StateObject private var presenceTracker = GroupPresenceTracker()
      @State private var members: [User] = []
      
      var body: some View {
          List {
              ForEach(sortedMembers) { member in
                  HStack {
                      ProfilePhotoWithPresence(
                          userID: member.id,
                          photoURL: member.profilePhotoURL,
                          size: 40
                      )
                      Text(member.displayName)
                      Spacer()
                  }
              }
          }
      }
  }
  ```
  - Test Gate: SwiftUI Preview shows member list
  
- [x] Add member sorting logic
  - Online members first, then offline
  - Alphabetical within each group
  - Test Gate: List sorted correctly
  
- [x] Load member User objects from UserService
  - Fetch user data for each memberID in chat.members
  - Test Gate: All member names and photos display
  
- [x] Add section headers for large groups (>10 members)
  - "Online (X)" and "Offline (Y)" sections
  - Test Gate: Sections appear correctly for large groups
  
- [x] Add .onAppear to start observing
  - Call `presenceTracker.observeMembers(chat.members)`
  - Test Gate: Presence loads when view appears
  
- [x] Add .onDisappear to cleanup
  - Call `presenceTracker.cleanup()`
  - Test Gate: Listeners removed when view disappears
  
- [x] Add loading state while fetching members
  - Show ProgressView until User objects loaded
  - Test Gate: Smooth transition from loading to loaded
  
- [x] Add error handling for failed user fetches
  - Show placeholder if UserService.getUser() fails
  - Test Gate: No crashes with missing user data

---

## 5. Integration — Modify ChatView for Group Presence

### Add Group Header with Member Presence

- [x] Open `Psst/Psst/Views/ChatList/ChatView.swift`
  - Test Gate: File opens and existing code intact
  
- [x] Add state variables for group presence:
  ```swift
  @State private var memberPresences: [String: Bool] = [:]
  @State private var presenceListeners: [String: UUID] = [:]
  @State private var showMemberList: Bool = false
  ```
  - Test Gate: Variables compile without errors
  
- [x] Add computed property for online members:
  ```swift
  var onlineMembers: [String] {
      memberPresences.filter { $0.value }.map { $0.key }
  }
  ```
  - Test Gate: Property correctly filters online users
  
- [x] Create group header view component
  - Show first 3-5 member profile photos in HStack
  - Use ProfilePhotoWithPresence for each
  - Test Gate: Header displays member photos with indicators
  
- [x] Add tap gesture to header
  - Set `showMemberList = true` on tap
  - Test Gate: Tapping header triggers state change
  
- [x] Add sheet presentation for member list
  - `.sheet(isPresented: $showMemberList) { GroupMemberStatusView(chat: chat) }`
  - Test Gate: Sheet appears when header tapped
  
- [x] Conditionally show header only for group chats
  - Check `chat.isGroupChat` before rendering
  - Test Gate: 1-on-1 chats don't show group header
  
- [x] Add .onAppear to start observing group presence
  - Call `PresenceService.shared.observeGroupPresence()` with chat.members
  - Update `memberPresences` in completion
  - Test Gate: Presence loads when chat opens
  
- [x] Add .onDisappear to cleanup listeners
  - Call `PresenceService.shared.stopObservingGroup(presenceListeners)`
  - Clear state variables
  - Test Gate: Listeners removed when leaving chat

### Add Debouncing for Rapid Updates

- [ ] SKIPPED - Not needed for MVP (add debounce timer state)
- [ ] SKIPPED - Not needed for MVP (implement debounced update logic)
- [ ] SKIPPED - Not needed for MVP (add cleanup for timer in .onDisappear)

### User Feedback Adjustments (PR #004)

- [x] Remove "X of Y online" text from ChatView header
  - Visual indicators are sufficient
  - Test Gate: Header shows only member photos and group name
  
- [x] Simplify group presence in ChatRowView (messages list)
  - Keep single group icon avatar
  - Add green PresenceHalo if ANY member (excluding current user) is online
  - Simpler, cleaner approach matching 1-on-1 chat style
  - Test Gate: Group icon shows green halo when at least one other member is online

### Add Lazy Loading for Large Groups (Optional Enhancement)

- [ ] Add state for loaded member count:
  ```swift
  @State private var loadedMemberCount: Int = 10
  ```
  - Test Gate: Variable initialized correctly
  
- [ ] Modify observeGroupPresence call to load first N members
  - `let firstMembers = Array(chat.members.prefix(loadedMemberCount))`
  - Test Gate: Only first 10 members observed initially
  
- [ ] Add "Show More" button in GroupMemberStatusView
  - Button appears if `chat.members.count > loadedMemberCount`
  - Tapping loads next 10 members
  - Test Gate: Progressive loading works for 50+ member groups
  
- [ ] Add loading indicator for additional members
  - Show ProgressView while fetching more
  - Test Gate: Smooth UX when loading more members

---

## 6. Testing Validation

### Configuration Testing

- [ ] Verify Firebase Realtime Database connection
  - Test Gate: Can read `/presence/{userID}` from Firebase console
  
- [ ] Verify security rules allow group presence reads
  - Test Gate: All users can read any presence path
  - Test Gate: Users can only write their own presence path
  
- [ ] Verify PresenceService exists and compiles
  - Test Gate: No compilation errors in PresenceService.swift
  
- [ ] Verify existing presence methods still work
  - Test Gate: 1-on-1 chat presence indicators work unchanged

### Happy Path Testing

- [ ] **Open group chat with 5 members**
  - Test Gate: All 5 member photos appear in header within 100ms
  - Test Gate: Online indicators show correct status (verified in Firebase console)
  
- [ ] **Tap group header to view member list**
  - Test Gate: Sheet opens showing all members
  - Test Gate: Members sorted with online first
  - Test Gate: All presence indicators accurate
  
- [ ] **Member comes online in real-time**
  - Test Gate: Gray dot changes to green within 3 seconds
  - Test Gate: Smooth 0.3s fade animation plays
  - Test Gate: Member moves to "Online" section in list
  
- [ ] **Member goes offline in real-time**
  - Test Gate: Green dot changes to gray within 3 seconds
  - Test Gate: Smooth 0.3s fade animation plays
  - Test Gate: Member moves to "Offline" section in list
  
- [ ] **Leave and return to group chat**
  - Test Gate: Old listeners cleaned up (verified with Firebase console)
  - Test Gate: New listeners attached successfully
  - Test Gate: Presence indicators load correctly on return

### Edge Cases Testing

- [ ] **Group with 1 member (self only)**
  - Test Gate: Own profile photo shows with online indicator
  - Test Gate: No errors or crashes
  - Test Gate: Member list shows just self
  
- [ ] **Group with 50 members**
  - Test Gate: All 50 presence statuses load within 500ms
  - Test Gate: Scrolling member list maintains 60fps
  - Test Gate: Memory usage reasonable (<50MB for presence)
  - Test Gate: No performance degradation
  
- [ ] **Group with 100 members (if lazy loading implemented)**
  - Test Gate: First 10 load in 100ms
  - Test Gate: "Show More" loads next batch smoothly
  - Test Gate: Full list loads in <2 seconds
  
- [ ] **Network disconnection while viewing group**
  - Test Gate: Last known presence statuses remain visible
  - Test Gate: No error UI shown (graceful degradation)
  - Test Gate: Indicators show cached offline state
  
- [ ] **Network reconnection**
  - Test Gate: Presence updates resume within 3 seconds
  - Test Gate: Indicators update to current status
  - Test Gate: No duplicate listeners created
  
- [ ] **Rapid status changes (member toggling online/offline quickly)**
  - Test Gate: UI updates debounced (no excessive renders)
  - Test Gate: Final state always accurate
  - Test Gate: No UI flicker or stuttering
  
- [ ] **Opening multiple group chats simultaneously**
  - Test Gate: Each chat tracks its own member presence
  - Test Gate: Shared listeners prevent duplicate Firebase connections
  - Test Gate: No listener conflicts or mixed state
  
- [ ] **Leaving group chat mid-load**
  - Test Gate: All listeners cleaned up immediately
  - Test Gate: No memory leaks (verified with Instruments)
  - Test Gate: No completion callbacks fire after cleanup

### Multi-Device Testing

- [ ] **Device A and Device B in same 5-person group**
  - Test Gate: Both devices show same presence for all members
  - Test Gate: When Device A user comes online, Device B sees update <3s
  - Test Gate: When Device B user goes offline, Device A sees update <3s
  
- [ ] **3 devices in same group**
  - Test Gate: All devices show consistent presence
  - Test Gate: Status changes propagate to all devices <3s
  - Test Gate: No race conditions or inconsistent state
  
- [ ] **Device A opens group, Device B opens same group 10s later**
  - Test Gate: Device B sees current presence immediately
  - Test Gate: Both devices stay in sync for all updates
  
- [ ] **Background/foreground transitions**
  - Test Gate: App going to background stops presence listeners (optional optimization)
  - Test Gate: App returning to foreground reattaches listeners
  - Test Gate: Presence updates resume correctly

### Performance Testing

- [ ] **App load time regression test**
  - Test Gate: App loads in <2-3 seconds (no regression)
  - Test Gate: Group presence doesn't slow initial app launch
  
- [ ] **Presence load time**
  - Test Gate: 5-member group loads all statuses in <100ms
  - Test Gate: 20-member group loads all statuses in <200ms
  - Test Gate: 50-member group loads all statuses in <500ms
  
- [ ] **Scrolling performance in member list**
  - Test Gate: 60fps scrolling with 10 members
  - Test Gate: 60fps scrolling with 50 members
  - Test Gate: 60fps scrolling with 100 members (if supported)
  
- [ ] **Memory usage**
  - Open Xcode Instruments → Allocations
  - Test Gate: No memory leaks after opening/closing 10 groups
  - Test Gate: Memory usage stable (<50MB for presence tracking)
  - Test Gate: Listeners properly deallocated
  
- [ ] **CPU usage**
  - Open Xcode Instruments → Time Profiler
  - Test Gate: <5% CPU with 20 active groups
  - Test Gate: <10% CPU during rapid status updates
  - Test Gate: Debouncing reduces CPU spikes
  
- [ ] **Firebase Realtime DB usage**
  - Check Firebase console → Usage tab
  - Test Gate: Listener count matches expected (1 per member per open group)
  - Test Gate: No excessive reads or duplicate connections
  - Test Gate: Listeners cleaned up when groups closed

### Visual State Verification

- [ ] **Online state (green dot)**
  - Test Gate: Green color clearly visible (#00FF00 or similar)
  - Test Gate: 8pt diameter size correct
  - Test Gate: Positioned at bottom-right of profile photo
  - Test Gate: 2pt overlap with photo circle
  
- [ ] **Offline state (gray dot)**
  - Test Gate: Gray color at 50% opacity
  - Test Gate: 8pt diameter size correct
  - Test Gate: Same position as online dot
  
- [ ] **Transition animation**
  - Test Gate: 0.3s fade duration (not too fast/slow)
  - Test Gate: EaseInOut timing feels smooth
  - Test Gate: No abrupt color changes
  
- [ ] **Loading state**
  - Test Gate: Shows gray (offline) while loading
  - Test Gate: Updates to correct status within 100ms
  
- [ ] **Error state**
  - Test Gate: Shows gray (offline) on error
  - Test Gate: No error UI or alerts (graceful degradation)
  - Test Gate: Recovers when connection restored
  
- [ ] **Group header layout**
  - Test Gate: First 3-5 members displayed horizontally
  - Test Gate: Photos sized appropriately (30-40pt)
  - Test Gate: Indicators visible on all photos
  - Test Gate: Tap target large enough (44x44pt minimum)
  
- [ ] **Member list layout**
  - Test Gate: Vertical list with clear spacing
  - Test Gate: Section headers visible for large groups
  - Test Gate: Online count accurate in header
  - Test Gate: Scroll indicator appears for >10 members

---

## 7. Performance Optimization

### Listener Efficiency

- [ ] Verify shared listener pattern works
  - Test Gate: Multiple UI components share single Firebase listener per user
  - Test Gate: Listener count in Firebase console matches unique users, not UI instances
  
- [ ] Verify listener cleanup is complete
  - Test Gate: Opening/closing group 10 times doesn't accumulate listeners
  - Test Gate: Instruments shows all listeners deallocated
  
- [ ] Test background/foreground optimization (optional)
  - Pause listeners when app backgrounded
  - Resume listeners when app foregrounded
  - Test Gate: No presence updates wasted in background

### Update Batching

- [ ] Verify debouncing prevents excessive renders
  - Rapid status changes (5 toggles in 1 second)
  - Test Gate: Only 1-2 UI updates instead of 5
  - Test Gate: Final state always accurate
  
- [ ] Test with slow network
  - Throttle network in Settings → Developer
  - Test Gate: Updates batched appropriately
  - Test Gate: No UI stuttering

### Large Group Optimization

- [ ] Test lazy loading (if implemented)
  - Test Gate: Initial 10 members load instantly
  - Test Gate: Additional members load on demand
  - Test Gate: Total time for 100 members <2s
  
- [ ] Test member list pagination
  - Test Gate: Smooth scrolling while loading more
  - Test Gate: No duplicate members in list
  - Test Gate: Presence accurate for all loaded members

---

## 8. Acceptance Gates Checklist

All gates from PRD Section 12 must pass:

### Configuration Gates
- [ ] Firebase Realtime Database connection verified
- [ ] Security rules allow reading all presence, writing only self
- [ ] Multiple listeners don't conflict
- [ ] Listener cleanup verified in Firebase console

### Happy Path Gates
- [ ] All member online indicators display within 100ms
- [ ] Indicators accurately reflect Firebase console status
- [ ] Member comes online → green dot appears <3s with smooth animation
- [ ] Member goes offline → dot fades to gray <3s
- [ ] Tap group header → member list opens with all statuses

### Edge Case Gates
- [ ] 1-member group shows self with no errors
- [ ] 50-member group loads <500ms with 60fps scrolling
- [ ] Network disconnection shows cached status gracefully
- [ ] Network reconnection updates <3s
- [ ] Rapid changes debounced, final state accurate
- [ ] Old listeners cleaned up on leave/rejoin

### Multi-Device Gates
- [ ] Device A online → Device B sees update <3s
- [ ] Device B offline → Device A sees update <3s
- [ ] 3+ devices show consistent status
- [ ] All devices stay in sync

### Performance Gates
- [ ] App load <2-3s (no regression)
- [ ] Presence load <100ms for 5 members, <500ms for 50 members
- [ ] 60fps scrolling with presence indicators
- [ ] No memory leaks (Instruments verification)
- [ ] <5% CPU usage with 20 active groups

### Visual Gates
- [ ] Green dot clearly visible (8pt, bottom-right)
- [ ] Gray dot at 50% opacity (8pt, bottom-right)
- [ ] 0.3s smooth fade transition
- [ ] Loading defaults to gray
- [ ] Error shows gray (no error UI)

---

## 9. Documentation & PR

### Code Documentation

- [x] Add documentation comments to `observeGroupPresence()`
  - Document parameters, return value, pre/post-conditions
  - Test Gate: Quick Help shows clear documentation
  
- [x] Add documentation comments to `stopObservingGroup()`
  - Document cleanup behavior and error handling
  - Test Gate: Quick Help shows clear documentation
  
- [x] Add inline comments for complex listener logic
  - Explain shared listener pattern
  - Explain debouncing mechanism (skipped - not implemented)
  - Test Gate: Code is understandable to future developers
  
- [x] Add documentation to OnlineIndicator component
  - Document props and visual behavior
  - Test Gate: Component usage is clear
  
- [x] Add documentation to ProfilePhotoWithPresence
  - Document props, presence observation, and cleanup
  - Test Gate: Component usage is clear
  
- [x] Add documentation to GroupMemberStatusView
  - Document expected Chat object structure
  - Test Gate: Usage instructions are clear

### Update README

- [x] Add "Group Presence Indicators" section to README
  - Describe feature: "See which group members are online"
  - Explain visual indicators (green/gray dots)
  - Mention performance characteristics
  - Test Gate: README accurately describes feature
  
- [ ] Add screenshots (if applicable) - SKIPPED (will be added after user testing)
  - Group header with presence indicators
  - Member list with online/offline sections
  - Test Gate: Images clearly show feature

### Create PR Description

- [ ] Create comprehensive PR description with:
  - Summary: "Implements group member online indicators"
  - Changes made: List all new files and modified files
  - Testing completed: Link to all acceptance gates
  - Screenshots/videos: Show feature in action
  - Test Gate: PR description is thorough and professional
  
- [ ] Add acceptance gate checklist to PR
  - Copy from Section 8 above
  - Test Gate: All boxes checked before requesting merge
  
- [ ] Link PRD and TODO in PR description
  - Link to `Psst/docs/prds/pr-004-prd.md`
  - Link to `Psst/docs/todos/pr-004-todo.md`
  - Test Gate: Easy reference for reviewers
  
- [ ] Add "Closes #004" or equivalent
  - Test Gate: PR linked to issue/brief

### Final Verification

- [ ] Run full manual testing suite one final time
  - Test Gate: All acceptance gates still pass
  
- [ ] Verify no console errors or warnings
  - Test Gate: Clean console output during all flows
  
- [ ] Verify all TODO checkboxes are checked
  - Test Gate: 100% task completion
  
- [ ] Verify with user before creating PR
  - Present summary of changes
  - Demonstrate feature functionality
  - Test Gate: User approves PR creation
  
- [ ] Create PR targeting develop branch
  - Base: develop
  - Compare: feat/pr-004-group-online-indicators-and-member-status
  - Test Gate: PR created successfully

---

## 10. Copyable Checklist (for PR description)

```markdown
## PR #004: Group Online Indicators and Member Status

### Summary
Implements comprehensive group chat online indicators showing which members are currently online, following WhatsApp/Signal conventions with real-time updates.

### Changes Made
- Extended `PresenceService` with group observation methods
- Created `OnlineIndicator` reusable component (green/gray dot)
- Created `ProfilePhotoWithPresence` component (photo + indicator)
- Created `GroupMemberStatusView` (full member list with sorting)
- Modified `ChatView` to show presence in group header
- Implemented listener deduplication for performance
- Added debouncing for rapid status updates

### Acceptance Gates Passed
- [x] All member indicators display within 100ms
- [x] Status updates propagate <3 seconds across devices
- [x] 60fps scrolling with 50-member groups
- [x] No memory leaks (Instruments verified)
- [x] <5% CPU usage with 20 active groups
- [x] Multi-device sync tested (2+ devices)
- [x] Network disconnection handled gracefully
- [x] Visual design matches iOS patterns

### Testing Completed
- [x] Configuration testing (Firebase Realtime DB connected)
- [x] Happy path testing (open group, view members, see updates)
- [x] Edge case testing (1 member, 50 members, network issues)
- [x] Multi-device testing (real-time sync verified)
- [x] Performance testing (load time, scrolling, memory, CPU)
- [x] Visual state verification (all indicator states correct)

### Performance Metrics
- Presence load time: <100ms (5 members), <500ms (50 members)
- Status update latency: <3 seconds
- Scrolling: 60fps with presence indicators
- Memory: No leaks, <50MB for presence tracking
- CPU: <5% sustained with 20 active groups

### Files Created
- `Psst/Psst/Models/GroupPresence.swift`
- `Psst/Psst/Views/Components/OnlineIndicator.swift`
- `Psst/Psst/Views/Components/ProfilePhotoWithPresence.swift`
- `Psst/Psst/Views/ChatList/GroupMemberStatusView.swift`

### Files Modified
- `Psst/Psst/Services/PresenceService.swift`
- `Psst/Psst/Views/ChatList/ChatView.swift`

### Documentation
- [x] Inline code comments for complex logic
- [x] Service method documentation (Quick Help)
- [x] README updated with feature description

### References
- PRD: `Psst/docs/prds/pr-004-prd.md`
- TODO: `Psst/docs/todos/pr-004-todo.md`
- Standards: `Psst/agents/shared-standards.md`

Closes #004
```

---

## Notes

- **Task Size**: Each task designed to take <30 minutes
- **Sequential Order**: Complete sections 1-9 in order (setup → service → UI → integration → testing → docs)
- **Check Off Tasks**: Mark each checkbox as you complete it
- **Blockers**: Document any blockers immediately in this file
- **Standards Reference**: Consult `Psst/agents/shared-standards.md` for:
  - Performance targets (<100ms load, <3s sync, 60fps)
  - Real-time messaging patterns
  - Testing requirements
  - Common solutions to Firebase issues
- **Testing Strategy**: See `Psst/docs/testing-strategy.md` for comprehensive manual testing approach
- **Memory Leaks**: Use Xcode Instruments → Allocations to verify listener cleanup
- **Firebase Console**: Monitor `/presence/` path to verify listener count and status accuracy

