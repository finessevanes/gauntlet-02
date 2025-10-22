# PR-9 TODO — Chat Creation and Contact Selection

**Branch**: `feat/pr-9-chat-creation-and-contact-selection`  
**Source PRD**: `Psst/docs/prds/pr-9-prd.md`  
**Owner (Agent)**: Caleb

---

## 0. Clarifying Questions & Assumptions

- Questions: None - PRD is comprehensive
- Assumptions (confirm in PR if needed):
  - User list will be < 500 users for MVP (client-side search acceptable)
  - Alphabetical sorting by display name is sufficient
  - Sheet presentation preferred over navigation push for UserSelectionView
  - No profile pictures needed for MVP (placeholder initials acceptable)

---

## 1. Setup

- [x] Create branch `feat/pr-9-chat-creation-and-contact-selection` from develop
- [x] Read PRD thoroughly (`Psst/docs/prds/pr-9-prd.md`)
- [x] Read `Psst/agents/shared-standards.md` for patterns
- [x] Confirm Firebase Firestore and Auth are working
- [x] Verify existing PRs 1-8 are merged to develop

---

## 2. Service Layer - ChatService Extension

Implement chat creation with duplicate prevention in existing ChatService.

- [x] Open `Services/ChatService.swift`
  - Test Gate: File exists from PR #6

- [x] Add ChatError enum before ChatService class
  ```swift
  enum ChatError: LocalizedError {
      case notAuthenticated
      case cannotChatWithSelf
      case invalidUserID
      case firestoreError(Error)
  }
  ```
  - Test Gate: Enum compiles, cases accessible

- [x] Implement `createChat(withUserID:)` method in ChatService
  - Step 1: Get current user ID from Firebase Auth
  - Step 2: Validate targetUserID != currentUserID
  - Step 3: Validate targetUserID is not empty
  - Test Gate: Validation logic prevents self-chat and empty IDs

- [x] Implement duplicate chat detection query
  - Step 1: Query chats where current user is member (arrayContains)
  - Step 2: Filter results client-side for targetUserID in members
  - Step 3: Check members.count == 2 and !isGroupChat
  - Test Gate: Query finds existing 1-on-1 chats correctly

- [x] Implement new chat creation logic
  - Step 1: Generate new chatID with UUID().uuidString
  - Step 2: Create chat dictionary with proper schema (members, timestamps, isGroupChat: false)
  - Step 3: Write to Firestore using setData
  - Test Gate: New chat document appears in Firestore Console

- [x] Add error handling and logging
  - Catch authentication errors
  - Catch Firestore errors
  - Add debug print statements for tracking
  - Test Gate: Errors logged clearly, no crashes

- [x] Test createChat method manually
  - Test Gate: Method compiles without errors
  - Test Gate: Returns chatID string on success

---

## 3. Service Layer - UserService Verification

Verify or add fetchAllUsers method.

- [x] Open `Services/UserService.swift`
  - Test Gate: File exists from PR #3

- [x] Check if `fetchAllUsers()` method exists
  - Search for "fetchAllUsers" in file
  - Test Gate: Method exists or needs to be added

- [x] If method doesn't exist, implement it
  - Query all documents from "users" collection
  - Decode each document as User model
  - Return array of User objects
  - Handle decoding errors with compactMap
  - Test Gate: Method returns all users from Firestore

- [x] If method exists, verify it matches requirements
  - Returns `async throws -> [User]`
  - Fetches from "users" collection
  - Handles decoding errors gracefully
  - Test Gate: Method works correctly with test users

---

## 4. UI Components - Directory Setup

Create UserSelection directory structure.

- [x] Create new directory `Psst/Psst/Views/UserSelection/`
  - Test Gate: Directory exists in project navigator

---

## 5. UI Components - UserRow

Create reusable user row component.

- [x] Create file `Views/UserSelection/UserRow.swift`
  - Test Gate: File created in correct directory

- [x] Implement UserRow view
  - Accept User model as parameter
  - HStack with display name (primary) and email (secondary)
  - Use VStack for stacked text layout
  - Add placeholder circle avatar (initials from displayName)
  - Test Gate: SwiftUI preview renders correctly

- [x] Style UserRow
  - Display name: .headline font
  - Email: .subheadline font, secondary color
  - Avatar: Circle with initials, blue background
  - Padding and spacing for iOS HIG compliance
  - Test Gate: Visual appearance matches iOS standards

---

## 6. UI Components - UserSelectionView

Create main user selection screen.

- [x] Create file `Views/UserSelection/UserSelectionView.swift`
  - Test Gate: File created in correct directory

- [x] Add state properties
  - @State private var users: [User] = []
  - @State private var searchQuery: String = ""
  - @State private var isLoading: Bool = true
  - @State private var errorMessage: String?
  - @State private var isCreatingChat: Bool = false
  - Test Gate: Properties compile without errors

- [x] Add service instances
  - private let userService = UserService()
  - private let chatService = ChatService()
  - Test Gate: Services instantiate correctly

- [x] Implement computed property for filtered users
  - Filter by searchQuery (display name OR email)
  - Case-insensitive search
  - Exclude current user from results
  - Alphabetical sorting by display name
  - Test Gate: Filtering works in preview

- [x] Implement body with NavigationView/NavigationStack
  - VStack container
  - Search bar at top (.searchable modifier)
  - Scrollable user list in middle
  - Test Gate: Basic layout renders in preview

- [x] Implement user list with LazyVStack
  - ScrollView wrapper
  - LazyVStack for performance
  - ForEach over filteredUsers
  - Each row: Button with UserRow component
  - Test Gate: Scrolling smooth with 50+ test users

- [x] Implement loading state
  - Show ProgressView with "Loading users..." text
  - Display while isLoading == true
  - Test Gate: Loading spinner appears correctly

- [x] Implement empty states
  - "No users found" when users array is empty
  - "No results for '\(searchQuery)'" when filtered results empty
  - Styled with secondary text color
  - Test Gate: Empty states display correctly

- [x] Implement error state
  - Show error message with retry button
  - Appears when errorMessage != nil
  - Test Gate: Error UI displays correctly

- [x] Add navigation title and toolbar
  - Title: "New Chat"
  - Show user count: "X users" or "X results"
  - Test Gate: Navigation bar looks correct

---

## 7. Integration - Fetch Users

Wire up user fetching on view appear.

- [x] Add .onAppear modifier to UserSelectionView
  - Test Gate: Modifier attached to view

- [x] Implement fetchUsers() async function
  - Set isLoading = true at start
  - Call userService.fetchAllUsers()
  - Update users array on success
  - Set errorMessage on failure
  - Set isLoading = false at end
  - Run on background thread (Task)
  - Test Gate: Users load from Firestore on view appear

- [x] Add error handling with retry
  - Catch Firestore errors
  - Set errorMessage with user-friendly text
  - Provide retry button that calls fetchUsers() again
  - Test Gate: Network errors handled gracefully

---

## 8. Integration - Chat Creation

Wire up chat creation when user taps row.

- [x] Implement createAndNavigateToChat(with user:) function
  - Accept User parameter
  - Set isCreatingChat = true
  - Call chatService.createChat(withUserID: user.id)
  - Get chatID from result
  - Navigate to ChatView with Chat object
  - Set isCreatingChat = false
  - Test Gate: Function compiles without errors

- [x] Add navigation logic
  - Use NavigationLink or programmatic navigation
  - Create Chat object from chatID and members
  - Pass to ChatView
  - Dismiss UserSelectionView (if sheet)
  - Test Gate: Navigation works smoothly

- [x] Add loading indicator during creation
  - Show small spinner or disable button when isCreatingChat == true
  - Prevent double-taps on user rows
  - Test Gate: Button disabled during creation

- [x] Add error handling for chat creation
  - Catch ChatError cases
  - Show alert with error message
  - Allow user to retry
  - Test Gate: Chat creation errors display alerts

- [x] Wire up button action in UserRow
  - Button wraps UserRow component
  - onTap calls createAndNavigateToChat
  - Disabled when isCreatingChat
  - Test Gate: Tap triggers chat creation

---

## 9. Integration - ConversationListView Button

Add "New Chat" button to existing ConversationListView.

- [x] Open `Views/ConversationList/ConversationListView.swift`
  - Test Gate: File exists from PR #6

- [x] Add state for showing UserSelectionView
  - @State private var showingNewChatView = false
  - Test Gate: State property added

- [x] Add toolbar button
  - Use .toolbar modifier
  - ToolbarItem with placement: .navigationBarTrailing
  - Button with "+" or "compose" icon
  - onTap sets showingNewChatView = true
  - Test Gate: Button appears in navigation bar

- [x] Add sheet presentation
  - .sheet(isPresented: $showingNewChatView)
  - Present UserSelectionView
  - Test Gate: Sheet presents when button tapped

- [x] Style button for iOS HIG compliance
  - Use SF Symbols icon (square.and.pencil or plus)
  - Appropriate size and color
  - Test Gate: Button looks native to iOS

---

## 10. MockDataService Removal

Remove DEBUG-only mock data service.

- [x] Search entire codebase for "MockDataService"
  - Use Xcode Find in Project
  - Check all Swift files
  - Test Gate: List all files referencing MockDataService

- [x] Remove MockDataService references from ConversationListView
  - Check for any DEBUG buttons or test data code
  - Remove mock data seeding code
  - Test Gate: ConversationListView has no MockDataService references

- [x] Remove MockDataService references from any other files
  - Check all results from search
  - Remove imports and usage
  - Test Gate: No files reference MockDataService

- [x] Delete `Services/MockDataService.swift` file
  - Delete file from Xcode project navigator
  - Commit deletion to git
  - Test Gate: File no longer exists in project

- [x] Build project to verify no errors
  - Clean build folder (Cmd+Shift+K)
  - Build project (Cmd+B)
  - Test Gate: Build succeeds with 0 errors
  - Test Gate: No compiler warnings about missing MockDataService

---

## 11. Manual Validation Testing

**Current**: Manual testing validation (see `Psst/agents/shared-standards.md`)

### Configuration Testing

- [ ] Firebase Firestore connection established
  - Test Gate: Can query "users" collection successfully
  
- [ ] Firebase Authentication provides valid user ID
  - Test Gate: Auth.auth().currentUser?.uid returns non-nil
  
- [ ] Firestore security rules allow reading users collection
  - Test Gate: fetchAllUsers() succeeds without permission errors
  
- [ ] Firestore security rules allow creating chats collection
  - Test Gate: createChat() succeeds without permission errors
  
- [ ] All necessary Firebase imports working
  - Test Gate: No import errors in service files

### Happy Path Testing

- [ ] **Device A - User logs in**: Open ConversationListView
  - Test Gate: View loads successfully

- [ ] **Device A - Tap "New Chat"**: Button visible in toolbar
  - Test Gate: Button renders correctly

- [ ] **Device A - UserSelectionView opens**: Sheet/navigation presents
  - Test Gate: View transition within 100ms

- [ ] **Device A - User list loads**: All users displayed except current user
  - Test Gate: Users fetch from Firestore within 500ms
  - Test Gate: Display names and emails visible
  - Test Gate: Current user NOT in list

- [ ] **Device A - Select User B**: Tap User B's row
  - Test Gate: Brief loading indicator (< 1 second)
  - Test Gate: Duplicate check runs in background

- [ ] **Device A - ChatView opens**: New or existing chat loads
  - Test Gate: Navigation completes within 2 seconds total
  - Test Gate: ChatView displays empty message list (new chat)
  - Test Gate: UserSelectionView dismisses

- [ ] **Device A - Go back**: Return to ConversationListView
  - Test Gate: New chat with User B appears in list
  - Test Gate: Chat positioned correctly (by timestamp)

- [ ] **Device A - Send message**: Type "Hello" and send
  - Test Gate: Message appears in ChatView (validates PR #8 integration)

- [ ] **Device B - User B logs in**: Open ConversationListView
  - Test Gate: Chat with User A appears in list (real-time listener)

### Duplicate Prevention Testing

- [ ] **Setup**: User A already has chat with User B (from Happy Path)
  - Test Gate: Chat exists in Firestore Console

- [ ] **Device A - Tap "New Chat"**: UserSelectionView appears
  - Test Gate: View opens

- [ ] **Device A - Select User B again**: Tap User B's row
  - Test Gate: Duplicate check runs (< 200ms)
  - Test Gate: Existing chat found (log confirms in console)
  - Test Gate: Navigates to existing ChatView
  - Test Gate: Shows previous "Hello" message
  - Test Gate: No new chat document in Firestore Console

- [ ] **Concurrent creation test**:
  - [ ] Device A and B both tap "New Chat" simultaneously
  - [ ] User A selects User C, User C selects User A (within 1 second)
  - Test Gate: Only one chat document created in Firestore
  - Test Gate: Both users navigate to same chat
  - Test Gate: No duplicate chats in Firestore Console

### Search Functionality Testing

- [ ] **Setup**: Database has 5+ users for meaningful test
  - Test Gate: Multiple users exist in Firestore

- [ ] **User types in search bar**: "Ali"
  - Test Gate: Results filter in real-time (< 50ms)
  - Test Gate: Only users with "Ali" in name OR email show
  - Test Gate: Case-insensitive ("ali" matches "Alice")

- [ ] **User clears search**: Delete all text
  - Test Gate: Full user list restored

- [ ] **User types non-matching query**: "XYZ123"
  - Test Gate: "No results for 'XYZ123'" message appears
  - Test Gate: No users displayed (empty list)

- [ ] **User types partial email**: "@example"
  - Test Gate: All users with "@example" in email displayed

- [ ] **Special characters test**: Types "O'Brien"
  - Test Gate: Search handles apostrophes correctly
  - Test Gate: No crashes or encoding errors

- [ ] **Search performance**: Type rapidly (10 keystrokes in 2 seconds)
  - Test Gate: No lag or dropped keystrokes
  - Test Gate: Results update smoothly

### Edge Cases Testing

- [ ] **Empty database**: Delete all users except current user
  - Test Gate: UserSelectionView shows "No users found" message
  - Test Gate: No crashes or blank screens

- [ ] **Network offline**: Disable internet connection
  - Test Gate: Firestore query fails gracefully
  - Test Gate: Error message: "Unable to load users. Check your connection."
  - Test Gate: Retry button available and works

- [ ] **Very long display name**: User with 50+ character name
  - Test Gate: UI handles long names without truncation issues
  - Test Gate: Text shows ellipsis (...) if needed

- [ ] **Large user list**: 100+ users in database
  - Test Gate: Smooth 60fps scrolling with LazyVStack
  - Test Gate: Search still responds within 50ms
  - Test Gate: No memory issues or crashes

- [ ] **Rapid selection**: User double-taps contact row
  - Test Gate: Only one chat creation attempt
  - Test Gate: Button disabled after first tap
  - Test Gate: No race condition errors

- [ ] **Self-chat attempt**: Try to create chat with own user ID (code test)
  - Test Gate: Validation prevents currentUserID == targetUserID
  - Test Gate: ChatError.cannotChatWithSelf thrown

### MockDataService Removal Testing

- [ ] **Code search**: Search entire project for "MockDataService"
  - Test Gate: No references found in any Swift files

- [ ] **File verification**: Check Services directory
  - Test Gate: MockDataService.swift file deleted

- [ ] **Build verification**: Build project in Xcode
  - Test Gate: Build succeeds with 0 errors
  - Test Gate: No compiler warnings about missing MockDataService

- [ ] **DEBUG build test**: Run app in DEBUG mode
  - Test Gate: No references to mock data buttons in UI
  - Test Gate: All features work with real Firestore data

- [ ] **Clean build**: Clean build folder and rebuild
  - Test Gate: Clean build succeeds
  - Test Gate: No cached references to MockDataService

### Performance Testing (see shared-standards.md)

- [ ] **User list fetch latency**: Measure time to load users on view appear
  - Use print with timestamps or Instruments
  - Test Gate: < 500ms from Firestore query to UI display

- [ ] **Search responsiveness**: Type in search bar
  - Test Gate: Results filter within 50ms per keystroke
  - Test Gate: No lag or dropped keystrokes

- [ ] **Duplicate check latency**: Measure time from row tap to navigation
  - Test Gate: < 2 seconds total (includes duplicate check + optional creation + navigation)

- [ ] **Chat creation time**: Measure Firestore write operation
  - Test Gate: < 300ms for new chat document write

- [ ] **Scrolling performance**: Scroll through 50+ user list rapidly
  - Test Gate: Smooth 60fps, no janky scrolling
  - Test Gate: LazyVStack loads rows efficiently

- [ ] **Navigation transition**: Measure time from tap to ChatView
  - Test Gate: < 100ms for view transition animation

### Visual State Verification

- [ ] No console errors during user list fetch
  - Test Gate: Clean console output

- [ ] No console errors during search filtering
  - Test Gate: No warnings or errors

- [ ] No console errors during chat creation
  - Test Gate: Success messages logged

- [ ] "New Chat" button clearly visible in ConversationListView
  - Test Gate: Button follows iOS HIG (correct icon, size, position)

- [ ] UserSelectionView presents smoothly
  - Test Gate: Sheet animation or navigation push feels native

- [ ] Loading spinner appears while fetching users
  - Test Gate: ProgressView visible with text

- [ ] Search bar clearly visible at top of UserSelectionView
  - Test Gate: Search bar functional and styled correctly

- [ ] User count displayed
  - Test Gate: "X users" or "X results" text visible

- [ ] Empty states render correctly
  - Test Gate: Helpful messages with proper styling

- [ ] ChatView loads immediately after selection
  - Test Gate: No blank screen delay or flash

---

## 12. Acceptance Gates

Check every gate from PRD Section 7:

- [ ] User taps "New Chat" → UserSelectionView appears within 100ms
- [ ] User list loads from Firestore within 500ms
- [ ] Current user excluded from contact list
- [ ] Search filters results within 50ms per keystroke
- [ ] Search matches display name OR email (case-insensitive)
- [ ] User selects contact → duplicate check + creation + navigation < 2 seconds
- [ ] Selecting same contact twice navigates to existing chat (no duplicate)
- [ ] Concurrent creation by both users results in single chat
- [ ] Chat created appears in ConversationListView (via existing listener from PR #6)
- [ ] Empty states display correctly (no users, no search results)
- [ ] Error states handle network failures gracefully
- [ ] MockDataService completely removed from codebase
- [ ] App builds successfully after MockDataService removal
- [ ] Smooth 60fps scrolling through user list (100+ users)

---

## 13. Documentation & PR

- [ ] Add inline code comments for complex logic
  - Duplicate detection algorithm
  - Search filtering logic
  - Navigation flow
  - Test Gate: Comments are clear and helpful

- [ ] Update README if needed
  - Document "New Chat" feature
  - Test Gate: README reflects new functionality (if applicable)

- [ ] Create PR description with following format:
  ```markdown
  # PR #9: Chat Creation and Contact Selection
  
  ## Overview
  Implements complete "Start New Chat" flow with user selection, search, and duplicate prevention. Removes MockDataService since users can now create real chats.
  
  ## Changes
  - Added `ChatService.createChat(withUserID:)` with duplicate prevention
  - Created UserSelectionView with real-time search
  - Added "New Chat" button to ConversationListView
  - Removed MockDataService (DEBUG-only mock data)
  
  ## Testing
  - Manual testing completed across all scenarios
  - Duplicate prevention verified (no duplicate chats created)
  - Search performance verified (< 50ms filtering)
  - Total flow < 2 seconds (tap to ChatView)
  - MockDataService removal verified (build succeeds)
  
  ## Related
  - PRD: Psst/docs/prds/pr-9-prd.md
  - TODO: Psst/docs/todos/pr-9-todo.md
  - Depends on: PRs 1-8
  - Blocks: PR #11 (Group chat creation)
  ```
  - Test Gate: PR description is comprehensive

- [ ] Verify with user before creating PR
  - Test Gate: User approval received

- [ ] Open PR targeting develop branch
  - Base branch: develop
  - Compare branch: feat/pr-9-chat-creation-and-contact-selection
  - Test Gate: PR created successfully

- [ ] Link PRD and TODO in PR description
  - Test Gate: Links work correctly

---

## Copyable Checklist (for PR description)

```markdown
- [ ] Branch created from develop
- [ ] All TODO tasks completed
- [ ] ChatService.createChat(withUserID:) implemented with duplicate prevention
- [ ] UserService.fetchAllUsers() verified/implemented
- [ ] UserSelectionView created with search functionality
- [ ] "New Chat" button added to ConversationListView
- [ ] Navigation from UserSelectionView to ChatView working
- [ ] MockDataService.swift completely removed from project
- [ ] Firebase integration verified (user fetch, chat creation)
- [ ] Manual testing completed (configuration, user flows, duplicate prevention, search, edge cases)
- [ ] Duplicate prevention verified (same user selection, concurrent creation)
- [ ] Search performance verified (< 50ms per keystroke)
- [ ] Performance targets met (< 2 second total flow)
- [ ] All acceptance gates pass
- [ ] Code follows Psst/agents/shared-standards.md patterns
- [ ] No console warnings or errors
- [ ] Project builds successfully after MockDataService removal
- [ ] Documentation updated
```

---

## Notes

- Break tasks into <30 min chunks
- Complete tasks sequentially
- Check off after completion
- Document blockers immediately
- Reference `Psst/agents/shared-standards.md` for common patterns and solutions
- Test duplicate prevention thoroughly with concurrent attempts
- Verify MockDataService removal doesn't break existing functionality
- Search must be performant - use client-side filtering for MVP
- Follow Swift threading rules: UI updates on main thread

