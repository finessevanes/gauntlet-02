# PR-11 TODO — Group Chat Support

**Branch**: `feat/pr-11-group-chat-support`  
**Source PRD**: `Psst/docs/prds/pr-11-prd.md`  
**Owner (Agent)**: Caleb

---

## 0. Clarifying Questions & Assumptions

**Questions**: None - PRD is comprehensive

**Assumptions (confirm in PR if needed)**:
- MessageService from PR #8 works for group chats without modifications (operates on chatID, agnostic to chat type)
- Firestore real-time listeners from PR #8 work for all group members automatically
- UserSelectionView from PR #9 provides solid foundation for multi-select extension
- Sender name caching will significantly reduce Firestore queries (N senders vs N messages)
- Maximum group size of 50 members is acceptable for MVP performance
- Group membership is fixed at creation (no add/remove members in this PR)

---

## 1. Setup

- [ ] Create branch `feat/pr-11-group-chat-support` from develop
  - Test Gate: Branch created successfully, git status shows clean working directory
- [ ] Read PRD thoroughly (`Psst/docs/prds/pr-11-prd.md`)
  - Test Gate: All sections understood, no ambiguities
- [ ] Read `Psst/agents/shared-standards.md` for patterns
  - Test Gate: Performance targets noted (< 100ms message delivery, < 3s group creation)
- [ ] Confirm environment and test runner work
  - Test Gate: App builds and runs successfully on simulator
- [ ] Review existing code from dependencies
  - Read `Models/Chat.swift` (PR #5)
  - Read `Services/ChatService.swift` (PR #6, extended in PR #9)
  - Read `Services/MessageService.swift` (PR #8)
  - Read `Views/UserSelection/UserSelectionView.swift` (PR #9)
  - Test Gate: Understand existing patterns and extension points

---

## 2. Data Model Updates

### Update Chat Model

- [ ] Add `groupName` field to Chat struct
  - Open `Models/Chat.swift`
  - Add `var groupName: String?` property (optional, nil for 1-on-1 chats)
  - Test Gate: Chat model compiles successfully
  
- [ ] Update Chat.toDictionary() method
  - Modify method to include groupName in dictionary if present
  - Use conditional inclusion: `if let groupName = groupName { dict["groupName"] = groupName }`
  - Test Gate: Dictionary includes groupName for group chats, omits for 1-on-1
  
- [ ] Update Chat initializer (if needed)
  - Add groupName parameter with default value nil
  - Test Gate: Initializer accepts groupName, backward compatible with existing code
  
- [ ] Test Chat model changes
  - Create test Chat instance with groupName
  - Verify toDictionary() includes groupName
  - Verify Codable decoding works with optional groupName
  - Test Gate: Chat model encodes/decodes correctly with groupName field

---

## 3. Service Layer - ChatService Extensions

### Add New Error Cases

- [ ] Extend ChatError enum in `Services/ChatService.swift`
  - Add case `invalidGroupName`
  - Add case `insufficientMembers`
  - Test Gate: Error cases compile successfully
  
- [ ] Update ChatError.errorDescription
  - Add description for `invalidGroupName`: "Group name must be 1-50 characters"
  - Add description for `insufficientMembers`: "Groups require at least 3 members"
  - Test Gate: Error descriptions return correct strings

### Implement createGroupChat Method

- [ ] Add createGroupChat(withMembers:groupName:) method to ChatService
  - Method signature: `func createGroupChat(withMembers memberUserIDs: [String], groupName: String) async throws -> String`
  - Test Gate: Method signature compiles
  
- [ ] Implement authentication validation
  - Check current user is authenticated via `Auth.auth().currentUser?.uid`
  - Throw `ChatError.notAuthenticated` if not authenticated
  - Test Gate: Method throws notAuthenticated when user not logged in
  
- [ ] Implement group name validation
  - Trim whitespace: `groupName.trimmingCharacters(in: .whitespacesAndNewlines)`
  - Check not empty: `!trimmedName.isEmpty`
  - Check length: `trimmedName.count <= 50`
  - Throw `ChatError.invalidGroupName` if validation fails
  - Test Gate: Method throws invalidGroupName for empty or > 50 char names
  
- [ ] Implement members array validation
  - Ensure current user is in members array (add if missing)
  - Check minimum 3 members: `allMembers.count >= 3`
  - Throw `ChatError.insufficientMembers` if < 3 members
  - Test Gate: Method throws insufficientMembers for < 3 members
  
- [ ] Implement group chat document creation
  - Generate new chat ID: `UUID().uuidString`
  - Create dictionary with: id, members, lastMessage: "", lastMessageTimestamp, isGroupChat: true, groupName, createdAt, updatedAt
  - Use `FieldValue.serverTimestamp()` for timestamps
  - Write to Firestore: `db.collection("chats").document(newChatID).setData(newChat)`
  - Test Gate: Group chat document created in Firestore with correct fields
  
- [ ] Add debug logging
  - Log group creation: "➕ Creating new group chat '\(trimmedName)' with \(allMembers.count) members"
  - Log success: "✅ Created new group chat: \(newChatID)"
  - Log errors: "❌ Error creating group chat: \(error.localizedDescription)"
  - Test Gate: Console logs show detailed group creation flow
  
- [ ] Test createGroupChat method
  - Test valid group creation (3 members, valid name)
  - Test insufficient members error (< 3 members)
  - Test invalid group name error (empty, whitespace only, > 50 chars)
  - Test current user automatically added to members
  - Test Firestore document structure matches expected schema
  - Test Gate: All validation and creation scenarios work correctly

---

## 4. Service Layer - UserService Extensions (Optional Optimization)

- [ ] Add fetchUserNames helper method to `Services/UserService.swift`
  - Method signature: `func fetchUserNames(userIDs: [String]) async -> [String: String]`
  - Implement batch fetch of user documents
  - Return dictionary mapping userID to displayName
  - Use "Unknown User" fallback for missing user documents
  - Test Gate: Method fetches multiple user names efficiently
  
- [ ] Test fetchUserNames method
  - Test with valid user IDs (returns display names)
  - Test with invalid user IDs (returns "Unknown User")
  - Test with mix of valid and invalid IDs
  - Test empty array input (returns empty dictionary)
  - Test Gate: Method handles all scenarios gracefully

---

## 5. UI Components - UserSelectionView Multi-Select

### Add Group Mode Toggle

- [ ] Open `Views/UserSelection/UserSelectionView.swift`
  - Review existing 1-on-1 selection logic from PR #9
  - Test Gate: Understand current implementation
  
- [ ] Add state variables for group mode
  - Add `@State private var isGroupMode: Bool = false`
  - Add `@State private var selectedUserIDs: Set<String> = []`
  - Add `@State private var showGroupNamingSheet: Bool = false`
  - Test Gate: State variables compile successfully
  
- [ ] Add mode toggle UI at top of view
  - Add Picker or SegmentedControl: "1-on-1" vs "Group"
  - Bind to `isGroupMode` state
  - Style per iOS HIG (clear visual distinction)
  - Test Gate: Toggle appears at top, switches between modes
  
- [ ] Update user row tap behavior
  - If isGroupMode: Toggle selection (add/remove from selectedUserIDs Set)
  - If NOT isGroupMode: Keep existing PR #9 behavior (navigate to chat)
  - Test Gate: Tapping row in each mode behaves correctly

### Implement Multi-Select UI

- [ ] Update UserRow component
  - Open `Views/UserSelection/UserRow.swift`
  - Add parameter: `isSelected: Bool` (for group mode)
  - Add parameter: `showCheckbox: Bool` (to show/hide checkbox)
  - Add checkbox/checkmark view (conditional based on showCheckbox)
  - Position checkbox on right side of row
  - Highlight row background when isSelected
  - Test Gate: UserRow displays checkbox in group mode
  
- [ ] Wire up selection state to UserRow
  - Pass `showCheckbox: isGroupMode` to UserRow
  - Pass `isSelected: selectedUserIDs.contains(user.id)` to UserRow
  - Update selectedUserIDs Set on row tap
  - Test Gate: Tapping row toggles selection, checkbox reflects state
  
- [ ] Add selected count display
  - Show text at top: "\(selectedUserIDs.count) selected"
  - Only visible in group mode
  - Update dynamically as users select/deselect
  - Test Gate: Count updates in real-time with selections

### Add Create Group Button

- [ ] Add "Create Group" button to bottom of UserSelectionView
  - Use VStack with Spacer to position at bottom
  - Button label: "Create Group"
  - Style as prominent button (background color, padding)
  - Only visible in group mode: `if isGroupMode`
  - Test Gate: Button appears at bottom in group mode only
  
- [ ] Implement button enabled/disabled logic
  - Disabled when `selectedUserIDs.count < 3`
  - Enabled when `selectedUserIDs.count >= 3`
  - Visual indication of disabled state (opacity, gray color)
  - Test Gate: Button disabled with < 3 selections, enabled with 3+
  
- [ ] Wire button to show group naming sheet
  - Button action: `showGroupNamingSheet = true`
  - Test Gate: Tapping button presents group naming sheet

### Add Minimum Selection Validation

- [ ] Show validation message when < 3 selected
  - Display text below selected count: "Select 3 or more members"
  - Only show when isGroupMode and selectedUserIDs.count < 3
  - Style as subtle hint text (gray, smaller font)
  - Test Gate: Message appears/disappears based on selection count

---

## 6. UI Components - Group Naming Sheet

### Create GroupNamingView

- [ ] Create new file `Views/UserSelection/GroupNamingView.swift`
  - Create new SwiftUI View: `struct GroupNamingView`
  - Test Gate: File created, view compiles
  
- [ ] Add GroupNamingView parameters
  - `@Binding var groupName: String` (text field binding)
  - `let selectedUserIDs: [String]` (show selected members)
  - `let onCancel: () -> Void` (dismiss action)
  - `let onCreate: (String) -> Void` (create group action)
  - Test Gate: View accepts all parameters
  
- [ ] Implement UI layout
  - VStack container with padding
  - Heading: "Name Your Group" (large, bold)
  - TextField for group name (placeholder: "Group Name")
  - Character count: "\(groupName.count)/50" (below text field)
  - Optional: Display selected members as chips/avatars
  - HStack with "Cancel" and "Create" buttons
  - Test Gate: All UI elements render correctly
  
- [ ] Add text field validation
  - Trim whitespace on input
  - Limit to 50 characters (use `.onChange` modifier)
  - Show validation error for empty name
  - Test Gate: Text field enforces 50 char limit, trims whitespace
  
- [ ] Implement button actions
  - "Cancel" button: Call `onCancel()`
  - "Create" button: Validate name, call `onCreate(groupName)` if valid
  - "Create" disabled if groupName is empty (after trimming)
  - Test Gate: Buttons trigger correct actions, validation works
  
- [ ] Style the sheet
  - Use `.presentationDetents([.medium])` for half-sheet
  - Add corner radius and shadow for polished look
  - Ensure keyboard handling (text field not obscured)
  - Test Gate: Sheet presents smoothly, keyboard doesn't block UI

### Integrate GroupNamingView into UserSelectionView

- [ ] Add state variable for group name
  - Add `@State private var groupName: String = ""`
  - Test Gate: State variable compiles
  
- [ ] Present GroupNamingView as sheet
  - Use `.sheet(isPresented: $showGroupNamingSheet)`
  - Pass bindings and callbacks to GroupNamingView
  - Test Gate: Sheet presents when showGroupNamingSheet = true
  
- [ ] Implement onCancel callback
  - Dismiss sheet: `showGroupNamingSheet = false`
  - Clear group name: `groupName = ""`
  - Test Gate: Cancel dismisses sheet, resets state
  
- [ ] Implement onCreate callback
  - Add `@State private var isCreatingGroup: Bool = false`
  - Show loading state during group creation
  - Call ChatService.createGroupChat(withMembers:groupName:)
  - Navigate to GroupChatView on success
  - Show error alert on failure
  - Dismiss sheet and UserSelectionView on success
  - Test Gate: Group creation flow works end-to-end

---

## 7. UI Components - Group Chat Message Display

### Update MessageRow for Sender Names

- [ ] Open `Views/ChatList/MessageRow.swift`
  - Review existing message bubble layout
  - Test Gate: Understand current implementation
  
- [ ] Add sender name parameter
  - Add parameter: `senderName: String?` (optional, nil for current user)
  - Test Gate: MessageRow accepts senderName parameter
  
- [ ] Add sender name label above message bubble
  - VStack layout: sender name label → message bubble → timestamp
  - Sender name: Text(senderName ?? "").font(.caption).foregroundColor(.secondary)
  - Only show if senderName is not nil
  - Position above left-aligned message bubbles only (not current user)
  - Test Gate: Sender name renders above message bubble for non-current-user messages
  
- [ ] Style sender name label
  - Small font size (.caption or .caption2)
  - Gray color (.secondary)
  - Padding/spacing from message bubble (2-4pt)
  - Left-aligned with message bubble
  - Test Gate: Sender name styling is clear and readable

### Update ChatView for Group Mode

- [ ] Open `Views/ChatList/ChatView.swift`
  - Review existing message list rendering
  - Test Gate: Understand current implementation
  
- [ ] Add state for sender name caching
  - Add `@State private var senderNames: [String: String] = [:]` (cache: userID → displayName)
  - Test Gate: State variable compiles
  
- [ ] Implement sender name fetching logic
  - Create helper method: `func fetchSenderName(for senderID: String) async`
  - Check cache first: `if let cached = senderNames[senderID] { return cached }`
  - Fetch from Firestore if not cached
  - Store in cache: `senderNames[senderID] = displayName`
  - Use fallback "Unknown User" if fetch fails
  - Test Gate: Helper method fetches and caches sender names
  
- [ ] Update message list to show sender names
  - For each message, determine if sender name should be shown
  - Show sender name if: message.senderID != currentUserID AND chat.isGroupChat
  - Fetch sender name from cache or Firestore
  - Pass senderName to MessageRow component
  - Test Gate: Sender names appear for non-current-user messages in group chats
  
- [ ] Prefetch sender names for visible messages
  - On view appear or when messages load, identify unique senderIDs
  - Batch fetch sender names for all unique senders
  - Populate cache with results
  - Test Gate: Sender names loaded efficiently (N queries for N senders, not N messages)
  
- [ ] Add group chat header
  - If chat.isGroupChat, show group name prominently
  - Show member count: "\(chat.members.count) members" below group name
  - Style: Larger font for group name, smaller font for member count
  - Test Gate: Group chat header displays correctly

---

## 8. UI Components - Conversation List Group Display

### Update ChatRowView

- [ ] Open `Views/ChatList/ChatRowView.swift`
  - Review existing chat row layout
  - Test Gate: Understand current implementation
  
- [ ] Add group indicator logic
  - Check if chat.isGroupChat
  - If group: Show group name instead of other user's name
  - If group: Show member count below group name
  - Test Gate: ChatRowView distinguishes between 1-on-1 and group chats
  
- [ ] Display group name
  - Primary text: `chat.groupName ?? "Group Chat"` (bold, prominent)
  - Fallback to "Group Chat" if groupName is nil (shouldn't happen)
  - Test Gate: Group name displays correctly in conversation list
  
- [ ] Display member count
  - Secondary text: "\(chat.members.count) members"
  - Position below group name
  - Smaller font size, gray color
  - Test Gate: Member count displays correctly
  
- [ ] Update last message preview for groups
  - Format: "[Sender Name]: Message text"
  - Fetch sender name from cache or Firestore
  - Truncate message text if too long (use lineLimit(1))
  - Test Gate: Last message preview shows sender name for groups
  
- [ ] Add group indicator icon
  - Show icon/badge to distinguish groups from 1-on-1 chats
  - Use SF Symbol: "person.3.fill" or similar
  - Position next to group name or as overlay on avatar
  - Test Gate: Group indicator clearly visible
  
- [ ] Add group avatar placeholder
  - For groups, show placeholder group icon
  - Future: Could show composite of member avatars (out of scope)
  - Use SF Symbol or colored circle with icon
  - Test Gate: Group avatar placeholder displays

---

## 9. Integration & Wiring

### Wire Up Group Creation Flow

- [ ] Test complete group creation flow
  - User taps "New Chat" button
  - User toggles to "Group" mode
  - User selects 3+ contacts (checkboxes appear)
  - User taps "Create Group" button
  - GroupNamingView sheet appears
  - User enters group name
  - User taps "Create"
  - Group chat created in Firestore
  - GroupChatView/ChatView opens
  - UserSelectionView and sheet dismiss
  - Test Gate: Complete flow works without errors
  
- [ ] Test group chat appears in conversation list
  - After group creation, go back to ConversationListView
  - Verify new group chat appears in list
  - Verify group name, member count, group indicator visible
  - Test Gate: Group chat appears immediately (real-time listener)

### Verify MessageService Works for Groups

- [ ] Test sending message in group chat
  - Open newly created group chat
  - Send test message: "Hello group!"
  - Verify message appears in ChatView (optimistic UI)
  - Verify message written to Firestore
  - Test Gate: MessageService.sendMessage() works for groups
  
- [ ] Verify real-time listeners work for groups
  - Open group chat on Device A
  - Open same group chat on Device B
  - Send message from Device A
  - Verify message appears on Device B within 100ms
  - Test Gate: Real-time sync works for all group members
  
- [ ] Test observeMessages listener for groups
  - Verify ChatView.observeMessages() receives updates for all group members' messages
  - Verify no duplicate messages or missing messages
  - Test Gate: Listener works correctly for group chats

### Test Multi-Device Group Sync

- [ ] Test group creation visibility
  - Device A creates group with User B, C, D
  - Device B, C, D (different users) open ConversationListView
  - Verify group chat appears in all users' conversation lists
  - Test Gate: Group visible to all members immediately
  
- [ ] Test multi-device messaging
  - Device A (User A) sends message in group
  - Device B (User B) receives message with "User A" sender name
  - Device B sends reply
  - Device A receives reply with "User B" sender name
  - Device C, D also receive both messages with correct sender names
  - Test Gate: All members see all messages with correct sender names
  
- [ ] Test concurrent messaging
  - Multiple users send messages simultaneously
  - Verify all messages appear on all devices
  - Verify messages ordered by timestamp (server timestamp)
  - Verify sender names correct for each message
  - Test Gate: Concurrent messages handled correctly

---

## 10. Testing & Validation

### Configuration Testing
- [ ] Firebase Firestore connection established
  - Test Gate: App connects to Firestore successfully
- [ ] Firebase Authentication provides valid user ID
  - Test Gate: Auth.auth().currentUser?.uid returns valid ID
- [ ] Firestore security rules allow group chat creation
  - Test Gate: Group chat document created without permission errors
- [ ] Firestore security rules allow all members to read/write messages
  - Test Gate: All group members can send/receive messages
- [ ] Firestore security rules allow reading users collection for sender names
  - Test Gate: Sender names fetched successfully

### Happy Path Testing - Group Creation
- [ ] User toggles to "Group" mode
  - Test Gate: Multi-select checkboxes appear on user rows
- [ ] User selects 3+ contacts
  - Test Gate: Selected count updates, "Create Group" button enabled
- [ ] User taps "Create Group"
  - Test Gate: GroupNamingView sheet appears
- [ ] User enters group name "Test Group"
  - Test Gate: Text field accepts input, character count updates
- [ ] User taps "Create"
  - Test Gate: Group chat created in Firestore within 500ms
- [ ] GroupChatView opens
  - Test Gate: Header shows "Test Group (4 members)"
- [ ] Group appears in ConversationListView
  - Test Gate: Group row shows group name, member count, indicator

### Happy Path Testing - Group Messaging
- [ ] User A sends message in group
  - Test Gate: Message appears instantly (optimistic UI)
  - Test Gate: Message written to Firestore within 100ms
- [ ] User B receives message
  - Test Gate: Message appears with sender name "User A"
  - Test Gate: Latency < 100ms from send to receive
- [ ] User B sends reply
  - Test Gate: Message appears without sender name for User B (current user)
- [ ] User A receives reply
  - Test Gate: Message appears with sender name "User B"
- [ ] User C, D receive all messages
  - Test Gate: All messages visible with correct sender names

### Group Name Validation Testing
- [ ] User creates group, leaves name empty
  - Test Gate: "Create" button disabled or validation alert shown
- [ ] User enters 1 character
  - Test Gate: "Create" button enabled (minimum 1 char)
- [ ] User enters 50 characters
  - Test Gate: Text field accepts, group created successfully
- [ ] User enters 51+ characters
  - Test Gate: Text field truncates or prevents typing beyond 50
- [ ] User enters whitespace only "   "
  - Test Gate: Validation fails (trimmed = empty)
- [ ] User enters name with emojis "Team 🚀"
  - Test Gate: Text field accepts emojis, group created successfully

### Insufficient Members Testing
- [ ] User selects only 1 contact
  - Test Gate: "Create Group" button disabled
  - Test Gate: Hint text: "Select 3 or more members"
- [ ] User selects 2 contacts
  - Test Gate: "Create Group" button still disabled
- [ ] User selects 3 contacts
  - Test Gate: "Create Group" button enabled
  - Test Gate: Group creation succeeds

### Sender Name Display Testing
- [ ] Group with 5 members: A, B, C, D, E
  - Test Gate: All 5 members in group
- [ ] User A sends message
  - Test Gate: User A sees message without sender name (or "You")
- [ ] User B, C, D, E receive message
  - Test Gate: All see "User A" as sender
- [ ] User B sends message
  - Test Gate: User B sees message without sender name
  - Test Gate: User A, C, D, E see "User B" as sender
- [ ] Multiple messages from different senders
  - Send messages from A, B, A, C in sequence
  - Test Gate: Each message shows correct sender name
  - Test Gate: Sender names cached (not refetched for repeated senders)

### Conversation List Group Display Testing
- [ ] User has mix of 1-on-1 and group chats
  - Test Gate: Groups display group name, 1-on-1 display other user's name
- [ ] Group chats show member count
  - Test Gate: "(X members)" displayed correctly
- [ ] Group chats show group indicator icon
  - Test Gate: Icon distinguishes groups from 1-on-1 chats
- [ ] Last message preview format
  - Test Gate: "[Sender Name]: Message text" for groups
  - Test Gate: Just "Message text" for 1-on-1 chats
- [ ] Sorted by lastMessageTimestamp
  - Test Gate: Most recent chats at top (groups and 1-on-1 mixed correctly)

### Edge Cases Testing
- [ ] Sender user deleted/not found
  - Delete user document from Firestore
  - Send message from that user (before deletion reflected)
  - Test Gate: Message displays "Unknown User" as sender
  - Test Gate: No crashes or UI errors
- [ ] Group with 10+ members
  - Create group with 10+ users
  - Send messages from multiple members
  - Test Gate: All members receive messages within 100ms
  - Test Gate: No performance degradation
- [ ] Very long group name (50 characters)
  - Create group with 50-char name
  - Test Gate: Name displays correctly in header and conversation list
  - Test Gate: Truncation with ellipsis if needed in list
- [ ] Empty last message (no messages in group yet)
  - Create group, don't send any messages
  - Test Gate: Conversation list shows "No messages yet" or empty
- [ ] Rapid message sending
  - Multiple users send messages simultaneously in group
  - Test Gate: All messages appear in correct order (by timestamp)
  - Test Gate: Sender names correct for each message
  - Test Gate: No race condition errors

### Network & Offline Testing
- [ ] User creates group offline
  - Disable internet connection
  - Attempt to create group
  - Test Gate: Error message: "Unable to create group. Check your connection."
  - Test Gate: Retry option available
- [ ] User sends message in group offline
  - Disable internet, send message
  - Test Gate: Message queued locally (PR #10 offline persistence)
  - Test Gate: Message sends automatically when connection restored
- [ ] User opens group chat offline
  - Test Gate: Group chat displays with cached messages
  - Test Gate: Sender names display from cache

### 1-on-1 Chat Compatibility Testing
- [ ] User stays in "1-on-1" mode (default)
  - Test Gate: Single-select behavior works (same as PR #9)
  - Test Gate: No checkboxes, tapping row creates 1-on-1 chat
- [ ] User creates 1-on-1 chat
  - Test Gate: Duplicate check runs (PR #9 logic)
  - Test Gate: Chat created with isGroupChat: false, no groupName
  - Test Gate: ChatView displays without sender names
- [ ] User has existing 1-on-1 chats from PR #9
  - Test Gate: All existing chats display correctly (no regressions)
  - Test Gate: Conversation list shows mix of 1-on-1 and groups correctly

### Performance Testing (see shared-standards.md)
- [ ] Group chat creation latency
  - Measure time from "Create" tap to ChatView loaded
  - Test Gate: < 3 seconds total (multi-select → name → ChatView)
  - Test Gate: < 500ms for Firestore write operation
- [ ] Message delivery latency in groups
  - Measure time from send to all recipients receive
  - Test Gate: < 100ms across all group members
- [ ] Sender name display latency
  - Measure time to fetch and render sender name
  - Test Gate: < 50ms per unique sender (first fetch)
  - Test Gate: < 10ms for cached sender names
- [ ] Scrolling performance in group messages
  - Scroll through 100+ messages rapidly
  - Test Gate: Smooth 60fps, no janky scrolling (LazyVStack)
- [ ] Large group (10+ members) performance
  - Send messages in group with 10+ members
  - Test Gate: No performance degradation
  - Test Gate: Real-time sync still < 100ms

### Visual State Verification
- [ ] No console errors during group creation
  - Test Gate: Clean console output, only expected logs
- [ ] No console errors during group messaging
  - Test Gate: No error logs during message send/receive
- [ ] No console errors during sender name fetching
  - Test Gate: Cache hits logged, fetch errors handled gracefully
- [ ] "Group" mode toggle clearly visible
  - Test Gate: Toggle is prominent and labeled
- [ ] Checkboxes visible in multi-select mode
  - Test Gate: Checkboxes render on right side of user rows
- [ ] "Create Group" button clearly visible
  - Test Gate: Button positioned at bottom, properly styled
- [ ] Group naming sheet displays smoothly
  - Test Gate: Modal animation is smooth, no jank
- [ ] Sender names render clearly
  - Test Gate: Names positioned correctly, readable font size/color
- [ ] Group indicator distinguishes groups in list
  - Test Gate: Icon/badge clearly indicates group chats
- [ ] Member count displays correctly
  - Test Gate: Count visible in both conversation list and chat header

---

## 11. Error Handling & Edge Cases

- [ ] Handle all ChatError cases
  - notAuthenticated, cannotChatWithSelf, invalidUserID
  - invalidGroupName, insufficientMembers
  - firestoreError
  - Test Gate: All errors show user-friendly alerts
  
- [ ] Handle Firestore write failures
  - Network timeout during group creation
  - Permission denied errors
  - Test Gate: Error messages displayed, retry option available
  
- [ ] Handle sender name fetch failures
  - Network errors during name fetch
  - User document not found
  - Test Gate: Fallback to "Unknown User", no crashes
  
- [ ] Handle empty states
  - No users to select for group
  - Group chat with no messages yet
  - Test Gate: Appropriate empty state messages displayed
  
- [ ] Handle rapid button taps
  - User double-taps "Create Group"
  - Test Gate: Button disabled after first tap, no duplicate groups created

---

## 12. Documentation & Code Quality

- [ ] Add inline comments for complex logic
  - Comment sender name caching strategy
  - Comment multi-select state management
  - Comment group validation logic
  - Test Gate: Code is understandable to other developers
  
- [ ] Add documentation comments for public methods
  - ChatService.createGroupChat() has comprehensive doc comment
  - Include parameters, returns, throws, example usage
  - Test Gate: Xcode Quick Help shows documentation
  
- [ ] Remove any debug print statements
  - Keep structured logging (with emoji prefixes)
  - Remove temporary debug prints
  - Test Gate: Console output is clean and useful
  
- [ ] Ensure code follows Swift conventions
  - Naming follows camelCase
  - Proper indentation and spacing
  - SwiftUI modifiers in logical order
  - Test Gate: Code passes SwiftLint (if configured)

---

## 13. Final Verification

- [ ] Build project with zero errors
  - Test Gate: Xcode build succeeds with 0 errors
  
- [ ] Build project with zero warnings
  - Test Gate: Xcode build succeeds with 0 warnings
  
- [ ] Test on iOS simulator (iPhone)
  - Test Gate: All features work on iPhone simulator
  
- [ ] Test on iOS simulator (iPad) if applicable
  - Test Gate: UI adapts correctly to iPad screen size
  
- [ ] Run app on physical device (if available)
  - Test Gate: All features work on physical iPhone
  
- [ ] Verify no memory leaks
  - Use Xcode Instruments to check for leaks
  - Ensure listeners are properly removed
  - Test Gate: No memory leaks detected
  
- [ ] Verify thread safety
  - All Firestore operations on background threads
  - All UI updates on main thread
  - Test Gate: No thread warnings in console

---

## 14. PR Preparation

- [ ] Review all code changes
  - Use `git diff develop` to review changes
  - Test Gate: All changes are intentional and necessary
  
- [ ] Verify no unintended changes
  - Check for debug code, commented code, TODOs
  - Test Gate: Code is clean and production-ready
  
- [ ] Test complete user flow one more time
  - Fresh app install, create account, create group, send messages
  - Test Gate: End-to-end flow works perfectly
  
- [ ] Create PR description
  - Use format from `Psst/agents/caleb-agent.md`
  - Include: Summary, Changes Made, Testing Completed, Screenshots
  - Reference PRD and TODO
  - Test Gate: PR description is comprehensive
  
- [ ] Verify with user before creating PR
  - Present completed work to user
  - Demonstrate group creation and messaging flow
  - Test Gate: User approves PR creation
  
- [ ] Create PR targeting develop branch
  - Open PR from `feat/pr-11-group-chat-support` to `develop`
  - Add PR description
  - Link to PRD and TODO in description
  - Test Gate: PR created successfully

---

## Acceptance Checklist (from PRD)

Copy this into PR description:

```markdown
## Acceptance Checklist

### Group Creation
- [ ] User can toggle to "Group" mode in UserSelectionView
- [ ] Multi-select checkboxes appear on user rows
- [ ] "Create Group" button enabled with 3+ selections
- [ ] GroupNamingView sheet appears when "Create Group" tapped
- [ ] Group chat created in Firestore with correct schema (isGroupChat: true, groupName, members)
- [ ] Group chat appears in ConversationListView for all members

### Group Messaging
- [ ] Messages sent in group appear for all members within 100ms
- [ ] Sender names display correctly for non-current-user messages
- [ ] Current user's messages do NOT show sender name (or show "You")
- [ ] Sender names cached to minimize Firestore queries

### Group Display
- [ ] Group chats display group name in conversation list
- [ ] Member count shows "(X members)"
- [ ] Group indicator/icon distinguishes groups from 1-on-1 chats
- [ ] Last message preview format: "[Sender Name]: Message text"
- [ ] Group chat header shows group name and member count

### Validation
- [ ] Minimum 3 members required for group creation
- [ ] Group name must be 1-50 characters (validated)
- [ ] Empty or whitespace-only names rejected
- [ ] Insufficient members shows validation message

### Compatibility
- [ ] Existing 1-on-1 chat flow (PR #9) still works
- [ ] No regressions in conversation list, chat view, message sending
- [ ] MessageService from PR #8 works for groups without modifications

### Performance
- [ ] Group creation < 500ms
- [ ] Total flow < 3 seconds (multi-select → name → ChatView)
- [ ] Message delivery < 100ms to all group members
- [ ] Sender name display < 50ms (first fetch), < 10ms (cached)
- [ ] Smooth 60fps scrolling through group messages

### Testing
- [ ] Manual testing completed (configuration, user flows, multi-device, offline)
- [ ] All acceptance gates from PRD pass
- [ ] No console errors or warnings
- [ ] Code follows `Psst/agents/shared-standards.md` patterns
```

---

## Notes

- **Multi-select pattern**: Use Set<String> for selectedUserIDs to avoid duplicates and enable O(1) lookups
- **Sender name caching**: Critical for performance - fetch once per sender, not per message
- **Group mode toggle**: Keep 1-on-1 as default to avoid breaking existing PR #9 behavior
- **GroupNamingView**: Use sheet presentation (.medium detent) for better UX
- **Sender name display**: Only show for messages NOT from current user in group chats
- **Performance**: Batch fetch sender names for visible messages on load, then cache
- **Real-time sync**: MessageService and listeners from PR #8 should work for groups without changes - verify thoroughly
- **Thread safety**: SwiftUI state updates automatic on main thread, Firestore operations async on background
- **Testing**: Test with 3-10 members, verify < 100ms latency across all devices
- **Backward compatibility**: Ensure existing 1-on-1 chats from PR #9 still work - no regressions

---

## Definition of Done

- [ ] All TODO tasks completed and checked off
- [ ] All acceptance gates from PRD pass
- [ ] Manual testing completed (configuration, user flows, multi-device, offline, performance)
- [ ] No console errors or warnings
- [ ] Code follows `Psst/agents/shared-standards.md` patterns
- [ ] PR created targeting develop branch
- [ ] PR approved by user

