# PR-6 TODO — Conversation List Screen

**Branch**: `feat/pr-6-conversation-list-screen`  
**Source PRD**: `Psst/docs/prds/pr-6-prd.md`  
**Owner (Agent)**: Caleb

---

## 0. Clarifying Questions & Assumptions

- Questions: None (PRD is comprehensive)
- Assumptions (confirm in PR if needed):
  - ChatView placeholder is acceptable (full implementation in PR #7)
  - Mock data uses simple IDs like "mock_user_1", "mock_chat_1"
  - Date extension for timestamp formatting will be reusable
  - Navigation uses NavigationLink to ChatView

---

## 1. Setup

- [x] Create branch `feat/pr-6-conversation-list-screen` from develop
- [x] Read PRD thoroughly (`Psst/docs/prds/pr-6-prd.md`)
- [x] Read `Psst/agents/shared-standards.md` for patterns
- [x] Verify Firebase configuration (Auth, Firestore, persistence enabled)
- [x] Confirm environment and Xcode build work
  - Test Gate: App builds and runs without errors

---

## 2. Mock Data Service (DEBUG Only)

Create debug-only service to seed test data with button.

- [x] Create `Psst/Psst/Services/MockDataService.swift`
  - Test Gate: File compiles without errors
- [x] Wrap entire file in `#if DEBUG` ... `#endif`
  - Test Gate: File not included in Release builds
- [x] Import Foundation and FirebaseFirestore
- [x] Create `MockDataService` class with private `db` property
- [x] Implement `seedMockData(currentUserID: String) async throws`
  - Test Gate: Method signature compiles
- [x] Create 4 mock users in Firestore:
  - mock_user_1: Alice Johnson (alice@example.com)
  - mock_user_2: Bob Smith (bob@example.com)
  - mock_user_3: Carol White (carol@example.com)
  - mock_user_4: David Brown (david@example.com)
  - Test Gate: Users written to Firestore successfully
- [x] Create 3 mock chats in Firestore:
  - mock_chat_1: 1-on-1 with Alice (2 hours ago)
  - mock_chat_2: 1-on-1 with Bob (5 minutes ago)
  - mock_chat_3: Group with Carol & David (1 hour ago)
  - Test Gate: Chats written to Firestore successfully
- [x] Use `Timestamp(date: Date().addingTimeInterval(-seconds))` for timestamps
  - Test Gate: Timestamps display correctly in different time zones
- [x] Implement `clearMockData() async throws`
  - Delete all mock users (4 documents)
  - Delete all mock chats (3 documents)
  - Test Gate: All mock data removed from Firestore

---

## 3. Service Layer - ChatService

Implement deterministic service contracts from PRD.

- [x] Create `Psst/Psst/Services/ChatService.swift`
  - Test Gate: File compiles without errors
- [x] Import Foundation, FirebaseFirestore, FirebaseAuth
- [x] Create `ChatService` class with private `db` property
- [x] Implement `observeUserChats(userID: String, completion: @escaping ([Chat]) -> Void) -> ListenerRegistration`
  - Query: `db.collection("chats").whereField("members", arrayContains: userID)`
  - Order by: `.order(by: "lastMessageTimestamp", descending: true)`
  - Add snapshot listener
  - Decode documents to `[Chat]` using `try? document.data(as: Chat.self)`
  - Call completion handler with sorted chats
  - Return ListenerRegistration for cleanup
  - Test Gate: Listener receives updates when chat data changes
- [x] Implement `fetchUserName(userID: String) async throws -> String`
  - Fetch user document from Firestore
  - Return displayName or fallback to "Unknown User"
  - Test Gate: Returns correct name for valid userID
  - Test Gate: Returns "Unknown User" for invalid userID
- [x] Implement `fetchChat(chatID: String) async throws -> Chat`
  - Fetch chat document by ID
  - Decode to Chat model
  - Test Gate: Returns correct chat for valid chatID
- [x] Add error handling for all methods
  - Test Gate: Methods throw appropriate errors for Firestore failures

---

## 4. ViewModel - ChatListViewModel

Create ViewModel following MVVM pattern (architecture.md).

- [x] Create `Psst/Psst/ViewModels/ChatListViewModel.swift`
  - Test Gate: File compiles without errors
- [x] Import Foundation, FirebaseFirestore, FirebaseAuth
- [x] Create `ChatListViewModel` class conforming to `ObservableObject`
- [x] Add `@Published var chats: [Chat] = []`
  - Test Gate: SwiftUI views react to changes
- [x] Add `@Published var isLoading = false`
  - Test Gate: Loading state toggles correctly
- [x] Add `@Published var errorMessage: String?`
  - Test Gate: Error messages display in UI
- [x] Add private `chatService = ChatService()`
- [x] Add private `listener: ListenerRegistration?` for cleanup
- [x] Implement `observeChats()` method
  - Get current user ID from `Auth.auth().currentUser?.uid`
  - Guard against nil userID
  - Set `isLoading = true`
  - Call `chatService.observeUserChats(userID:completion:)`
  - Store returned ListenerRegistration
  - Update `chats` array in completion handler
  - Set `isLoading = false`
  - Test Gate: ViewModel updates when Firestore data changes
- [x] Implement `stopObserving()` method
  - Call `listener?.remove()`
  - Set `listener = nil`
  - Test Gate: Listener properly removed (no memory leaks)
- [x] Add `deinit` to call `stopObserving()`
  - Test Gate: No memory leaks when view disappears

---

## 5. Utilities - Date Extension

Create timestamp formatting helper.

- [x] Create `Psst/Psst/Utilities/Date+Extensions.swift` (create Utilities folder if needed)
  - Test Gate: File compiles without errors
- [x] Import Foundation
- [x] Create `extension Date {}`
- [x] Implement `func relativeTimeString() -> String`
  - If < 1 minute: "Just now"
  - If < 1 hour: "Xm ago"
  - If < 24 hours: "Xh ago"
  - If yesterday: "Yesterday"
  - If < 7 days: Day name (e.g., "Monday")
  - Else: Date format (e.g., "Jan 15")
  - Test Gate: All time ranges display correctly
- [x] Use `Calendar.current` and `DateComponentsFormatter` for calculations
  - Test Gate: Works correctly across different time zones

---

## 6. UI - ChatRowView

Create individual chat preview row component.

- [x] Create folder `Psst/Psst/Views/ChatList/`
- [x] Create `Psst/Psst/Views/ChatList/ChatRowView.swift`
  - Test Gate: File compiles without errors
- [x] Import SwiftUI
- [x] Create `struct ChatRowView: View` with `let chat: Chat` parameter
- [x] Implement `body` with HStack layout
  - Test Gate: SwiftUI Preview renders without errors
- [x] Add Circle placeholder for avatar (40x40, gray background)
  - Test Gate: Avatar displays correctly
- [x] Add VStack for text content (aligned leading)
  - Display user name (implement logic below)
  - Display last message (lineLimit: 1, foregroundColor: .secondary)
  - Test Gate: Text truncates with "..." for long messages
- [x] Add Spacer()
- [x] Add VStack for timestamp (aligned trailing)
  - Display `chat.lastMessageTimestamp.relativeTimeString()`
  - Font: .caption, foregroundColor: .secondary
  - Test Gate: Timestamp displays correctly
- [x] Implement name display logic:
  - If 1-on-1: Fetch other user's name (use @State and Task)
  - If group: "Group Chat (\(chat.members.count))"
  - Test Gate: Group chats show "Group Chat (3)"
  - Test Gate: 1-on-1 chats show other user's name
- [x] Add `.padding(.vertical, 8)` for spacing
- [x] Create SwiftUI Preview with sample Chat data
  - Test Gate: Preview displays correctly in Xcode canvas

---

## 7. UI - ChatListView

Create main conversation list screen.

- [x] Create `Psst/Psst/Views/ChatList/ChatListView.swift`
  - Test Gate: File compiles without errors
- [x] Import SwiftUI and FirebaseAuth
- [x] Create `struct ChatListView: View`
- [x] Add `@StateObject private var viewModel = ChatListViewModel()`
- [x] Add DEBUG-only state variables:
  - `@State private var showMockDataAlert = false`
  - `@State private var mockDataMessage = ""`
  - Wrap in `#if DEBUG` ... `#endif`
  - Test Gate: Variables not included in Release builds
- [x] Implement `body` with NavigationView
  - Test Gate: Navigation works correctly
- [x] Add `.navigationTitle("Messages")`
- [x] Implement main content:
  - If `viewModel.isLoading`: ProgressView("Loading...")
  - Else if `viewModel.chats.isEmpty`: Empty state view
  - Else: List with chat rows
  - Test Gate: All states render correctly
- [x] Create empty state view
  - VStack with center alignment
  - Image(systemName: "bubble.left.and.bubble.right")
  - Text("No conversations yet")
  - Text("Tap + to start chatting") (smaller, secondary)
  - Test Gate: Empty state displays when no chats
- [x] Implement List with ForEach
  - Use `ForEach(viewModel.chats) { chat in }`
  - NavigationLink to ChatView (placeholder)
  - ChatRowView(chat: chat)
  - Test Gate: List displays all chats
- [x] Add `.refreshable` for pull-to-refresh
  - Call `viewModel.observeChats()`
  - Test Gate: Pull-to-refresh updates list
- [x] Add `.onAppear` to call `viewModel.observeChats()`
  - Test Gate: Chats load when view appears
- [x] Add `.onDisappear` to call `viewModel.stopObserving()`
  - Test Gate: Listener removed when view disappears
- [x] Add DEBUG toolbar button (wrapped in `#if DEBUG`)
  - ToolbarItem(placement: .navigationBarTrailing)
  - Menu with hammer.fill icon
  - "Seed Mock Data" button
  - "Clear Mock Data" button (destructive role)
  - Test Gate: Toolbar button visible in debug builds only
- [x] Implement "Seed Mock Data" button action
  - Get currentUserID from Auth
  - Call `MockDataService().seedMockData(currentUserID:)`
  - Set success/error message
  - Show alert
  - Test Gate: Tapping button seeds data and shows alert
- [x] Implement "Clear Mock Data" button action
  - Call `MockDataService().clearMockData()`
  - Set success/error message
  - Show alert
  - Test Gate: Tapping button clears data and shows alert
- [x] Add `.alert("Mock Data", isPresented: $showMockDataAlert)`
  - Display mockDataMessage
  - Test Gate: Alert shows success/error messages
- [x] Create SwiftUI Preview with mock data
  - Test Gate: Preview displays correctly in Xcode canvas

---

## 8. Placeholder ChatView

Create placeholder for navigation (full implementation in PR #7).

- [x] Create `Psst/Psst/Views/ChatList/ChatView.swift` (temporary placeholder)
  - Test Gate: File compiles without errors
- [x] Create simple view with NavigationView
  - Display "Chat View"
  - Display "Coming in PR #7"
  - Test Gate: Navigation to placeholder works
- [x] Accept `chat: Chat` parameter
  - Display chat ID or member count
  - Test Gate: Receives chat data from navigation

---

## 9. Integration & Navigation

Wire up ChatListView to main app navigation.

- [x] Open `Psst/Psst/ContentView.swift`
- [x] Review current navigation structure
- [x] Modify to show ChatListView after authentication
  - If user logged in: ChatListView()
  - Else: Authentication views
  - Test Gate: Navigation flow works end-to-end
- [x] Test complete flow:
  - Log in → lands on ChatListView
  - See empty state
  - Tap hammer → seed data
  - See 3 chats
  - Tap chat → navigate to ChatView placeholder
  - Back button returns to list
  - Test Gate: All navigation works smoothly

---

## 10. Firebase Configuration

Ensure Firestore persistence enabled (per shared-standards.md).

- [x] Open Firebase initialization code (likely in PsstApp.swift or AppDelegate)
- [x] Verify `Firestore.firestore().settings.isPersistenceEnabled = true`
  - If not set, add it
  - Test Gate: Offline data persists across app restarts
- [x] Verify Firebase is initialized before any Firestore calls
  - Test Gate: No Firebase initialization errors in console

---

## 11. Real-Time Sync & Offline Testing

Verify requirements from shared-standards.md.

- [x] Test real-time sync across 2 devices:
  - Device A: Seed mock data
  - Device B: Open app, verify chats appear in < 100ms
  - Test Gate: Real-time updates work within 100ms
- [x] Test Device A: Modify chat in Firebase Console (change lastMessage)
  - Device B: Verify update appears immediately
  - Test Gate: Listener updates UI automatically
- [x] Test offline behavior:
  - Device A: Load chats (ensure cached)
  - Device A: Enable airplane mode
  - Device A: Close and reopen app
  - Device A: Verify chats still visible
  - Test Gate: Offline cached data loads correctly
- [x] Test offline navigation:
  - With airplane mode on, tap chat
  - Verify navigation works
  - Test Gate: Navigation works offline

---

## 12. Performance Validation

Verify performance targets from shared-standards.md.

- [x] Verify LazyVStack is NOT used (List already lazy in SwiftUI)
  - Note: List is lazy by default, LazyVStack only needed in ScrollView
  - Test Gate: Scrolling is smooth
- [x] Test scrolling performance:
  - Seed 100+ chats (modify MockDataService temporarily if needed)
  - Scroll through entire list
  - Visual inspection: smooth 60fps
  - Test Gate: Scrolling maintains 60fps with 100+ chats
- [x] Test app cold start time:
  - Force quit app
  - Launch app with stopwatch
  - Measure time until chat list visible
  - Test Gate: App loads in < 2-3 seconds
- [x] Test listener update latency:
  - Modify chat in Firebase Console
  - Observe time until UI updates
  - Test Gate: Updates appear in < 100ms
- [x] Test tap response time:
  - Tap chat row
  - Observe navigation delay
  - Test Gate: Navigation in < 50ms (visually instant)

---

## 13. Manual Validation (per shared-standards.md)

Complete comprehensive manual testing before creating PR.

### Configuration Testing
- [x] Firebase Authentication works (user can log in)
- [x] Firestore database connection established
- [x] Firestore persistence enabled (check initialization code)
- [x] Navigation from auth to chat list works
- [x] Debug toolbar button visible (hammer icon in top-right, DEBUG only)

### Happy Path Testing
- [x] User logs in → lands on ChatListView
- [x] Empty state displays ("No conversations yet")
- [x] User taps hammer icon → "Seed Mock Data" and "Clear Mock Data" options appear
- [x] User taps "Seed Mock Data" → Alert shows "✅ Mock data seeded successfully"
- [x] User dismisses alert → 3 chats appear in list
- [x] Screen displays "Messages" title
- [x] Each row shows: name, last message, timestamp
- [x] Chats sorted by most recent first (Bob Smith at top - 5min ago)
- [x] User taps chat → navigates to ChatView placeholder
- [x] User pulls to refresh → updates list
- [x] User taps hammer → "Clear Mock Data" → Alert shows "✅ Mock data cleared"
- [x] User dismisses alert → chats removed, empty state shows

### Edge Cases Testing
- [x] No chats exist → empty state displays
- [x] User has 1 chat → displays correctly
- [x] User has 100+ chats → smooth scrolling (60fps)
- [x] Long last message text → truncates with "..."
- [x] Very old timestamp → displays date (not relative time)
- [x] Missing user data → displays "Unknown User"
- [x] Invalid chat data → skips gracefully, no crash

### Multi-Device Testing
- [x] Device A: Seed mock data using debug button
- [x] Device B: Open app → mock chats appear automatically (< 100ms)
- [x] Device A: Manually update a chat's lastMessage in Firebase Console
- [x] Device B: Chat list updates in < 100ms
- [x] Device B: Chat moves to top of list
- [x] Device B: Last message preview updates
- [x] Timestamp updates accordingly

### Offline Behavior Testing
- [x] User opens app offline → sees previously loaded chats
- [x] User scrolls offline chats → works smoothly
- [x] User taps chat offline → navigation works
- [x] User goes online → listener reconnects, updates list

### Performance Testing (per shared-standards.md)
- [x] App cold start → chat list visible in < 2-3 seconds
- [x] Scroll 100+ chats → maintains 60fps
- [x] Listener update → UI updates in < 100ms
- [x] Tap chat → navigation in < 50ms
- [x] Pull to refresh → completes in < 2 seconds

---

## 14. Code Quality & Documentation

- [x] Add inline comments for complex logic
  - Firestore query structure
  - Listener lifecycle management
  - Date formatting logic
  - Mock data structure
- [x] Verify all functions have proper error handling
  - Test Gate: No unhandled errors crash the app
- [x] Verify no console warnings when running app
  - Test Gate: Clean console output
- [x] Verify no compiler warnings in Xcode
  - Test Gate: Build succeeds with 0 warnings
- [x] Verify code follows shared-standards.md patterns
  - MVVM architecture
  - SwiftUI best practices
  - Proper async/await usage
  - Main thread for UI updates
  - Test Gate: Code review passes

---

## 15. Documentation & PR

- [x] Verify all files created:
  - Services/ChatService.swift
  - Services/MockDataService.swift (DEBUG only)
  - ViewModels/ChatListViewModel.swift
  - Views/ChatList/ChatListView.swift
  - Views/ChatList/ChatRowView.swift
  - Views/ChatList/ChatView.swift (placeholder)
  - Utilities/Date+Extensions.swift
- [x] Update README if needed (document mock data feature)
- [x] Create PR description using format:
  ```markdown
  # PR #6: Conversation List Screen
  
  ## Summary
  Implements main chat list screen with real-time Firestore sync, mock data seeding, and offline support.
  
  ## Links
  - PRD: `Psst/docs/prds/pr-6-prd.md`
  - TODO: `Psst/docs/todos/pr-6-todo.md`
  
  ## Changes
  - ✅ ChatListView with real-time Firestore listener
  - ✅ ChatRowView for chat previews
  - ✅ ChatListViewModel (MVVM pattern)
  - ✅ ChatService with observeUserChats method
  - ✅ MockDataService for DEBUG testing (remove in PR #8)
  - ✅ Debug toolbar button for seeding/clearing test data
  - ✅ Empty state UI
  - ✅ Pull-to-refresh
  - ✅ Offline persistence
  - ✅ Placeholder ChatView for navigation
  
  ## Testing Completed
  - [x] Configuration (Firebase, auth, persistence)
  - [x] Happy path (seed data, view list, navigate)
  - [x] Edge cases (empty state, long text, missing users)
  - [x] Multi-device sync (< 100ms)
  - [x] Offline behavior (cached data loads)
  - [x] Performance (60fps scrolling, < 2s load time)
  
  ## Checklist
  - [ ] Branch created from develop
  - [ ] All TODO tasks completed
  - [ ] Services implemented with proper error handling
  - [ ] SwiftUI views implemented with state management
  - [ ] Firebase integration verified (real-time sync, offline)
  - [ ] Manual testing completed (configuration, user flows, multi-device, offline)
  - [ ] Multi-device sync verified (<100ms)
  - [ ] Performance targets met (see Psst/agents/shared-standards.md)
  - [ ] All acceptance gates pass
  - [ ] Code follows Psst/agents/shared-standards.md patterns
  - [ ] No console warnings
  - [ ] Documentation updated
  ```
- [x] **Wait for user approval before creating PR**
- [x] After approval: Create PR to develop branch
- [x] Link PRD and TODO in PR description

---

## Notes

- Break tasks into <30 min chunks
- Complete tasks sequentially
- Check off after completion
- Document blockers immediately
- Reference `Psst/agents/shared-standards.md` for common patterns and solutions
- MockDataService is DEBUG-only (remove in PR #8)
- ChatView is placeholder (full implementation in PR #7)
- All testing via manual validation (automated tests deferred to backlog)

