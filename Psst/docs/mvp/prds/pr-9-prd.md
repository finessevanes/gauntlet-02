# PRD: Chat Creation and Contact Selection

**Feature**: Chat Creation and Contact Selection

**Version**: 1.0

**Status**: Ready for Development

**Agent**: Pam

**Target Release**: Phase 2 - 1-on-1 Chat

**Links**: [PR Brief #9](../pr-briefs.md#pr-9-chat-creation-and-contact-selection), [TODO](../todos/pr-9-todo.md), [Architecture](../architecture.md)

---

## 1. Summary

Build the complete "Start New Chat" flow enabling users to search and select contacts from the users collection, create 1-on-1 conversations with duplicate chat prevention, and remove the DEBUG-only MockDataService now that users can create real chats through the UI.

---

## 2. Problem & Goals

**Problem**: Users currently cannot create new chats through the UI. PRs 6-8 built screens to display and message in chats, but users must either manually create chat documents in Firestore Console or use MockDataService (DEBUG-only fake data). This prevents real-world testing and makes the app unusable for actual communication.

**Why now**: This is a critical dependency issue discovered after PR #8. Without chat creation, users cannot organically start conversations, making all previous chat/messaging work untestable in a real scenario. This PR unblocks the natural user flow: sign up → find contacts → start chatting.

**Goals**:
  - [ ] G1 — Users can tap "New Chat" button and see a list of all available users
  - [ ] G2 — Users can search/filter users by display name or email in real-time
  - [ ] G3 — Users can select a contact to create a 1-on-1 chat and navigate directly to ChatView
  - [ ] G4 — ChatService.createChat() prevents duplicate chats for same user pair
  - [ ] G5 — Remove MockDataService since users can now create real chats

---

## 3. Non-Goals / Out of Scope

- [ ] Group chat creation with multi-select (PR #11 - will enable 3+ user selection)
- [ ] User profile pictures in contact list (basic implementation only, polish in PR #17)
- [ ] "Recently chatted" or "favorites" sections (future)
- [ ] Contact import from phone/iCloud (future)
- [ ] Blocking/reporting users (future)
- [ ] Custom chat names for 1-on-1 chats (future)
- [ ] Showing "last seen" or online status in contact list (PR #12 - presence system)
- [ ] Pagination for large user lists (future - 100+ users)
- [ ] Automated unit/UI tests (deferred to backlog per testing-strategy.md)

---

## 4. Success Metrics

Reference `Psst/agents/shared-standards.md` for metric templates:

**User-visible**:
- Time to create chat: User taps "New Chat" → selects contact → ChatView loads < 2 seconds
- Flow completion: 100% of contact selections result in successful chat creation
- Search performance: Real-time filtering responds within 50ms of keystroke
- Zero duplicate chats created during testing session

**System** (see shared-standards.md):
- **Firestore query latency**: < 500ms to fetch all users from `users` collection
- **Duplicate check**: < 200ms to query existing chats before creating new one
- **Chat creation**: < 300ms to write new chat document to Firestore
- **Navigation**: < 100ms to transition from user selection to ChatView
- **No UI blocking**: All Firebase operations run on background threads

**Quality**:
- 0 blocking bugs during manual testing
- All acceptance gates pass
- Crash-free rate >99%
- No console errors during chat creation flow
- Search handles edge cases (empty results, special characters)

---

## 5. Users & Stories

- As a **new user**, I want to **see a list of all available users** so that **I can find someone to chat with**.

- As a **user**, I want to **search for users by name or email** so that **I can quickly find the person I'm looking for without scrolling**.

- As a **user**, I want to **tap a contact to start a 1-on-1 conversation** so that **I can immediately begin messaging them**.

- As a **user**, I want to **avoid creating duplicate chats** so that **I don't have multiple conversations with the same person**.

- As a **developer**, I want **MockDataService removed** so that **testing reflects real user data and the codebase is cleaner**.

---

## 6. Experience Specification (UX)

**Entry Points**:
- User taps "New Chat" button in ConversationListView → Navigates to UserSelectionView
- Future: Long-press on conversation (deferred to PR #11 for group creation)

**Visual Behavior**:

1. **User taps "New Chat" button**
   - UserSelectionView sheet/navigation presented
   - Loading state shows while fetching users from Firestore
   - Search bar appears at top of screen

2. **User list loads**
   - All users from `users` collection displayed in scrollable list
   - Each row shows: display name, email (subtitle)
   - Current user excluded from list
   - Empty state: "No users found" if database empty
   - Alphabetical sorting by display name

3. **User searches for contact**
   - Types in search bar
   - List filters in real-time (< 50ms response)
   - Search matches display name OR email (case-insensitive)
   - Shows "No results for '[query]'" if no matches

4. **User selects contact**
   - Taps contact row
   - Brief loading indicator (< 1 second)
   - Duplicate check runs in background
   - If chat exists: Navigate to existing ChatView
   - If new: Create chat → Navigate to ChatView
   - UserSelectionView dismisses

**Loading/Error States**:
- **Loading - Initial**: "Loading users..." with spinner while fetching from Firestore
- **Loading - Creating Chat**: Brief spinner/disabled state during chat creation (< 1 second)
- **Empty State - No Users**: "No users found. Invite friends to join Psst!"
- **Empty State - No Search Results**: "No results for '[search query]'"
- **Error - Network Failure**: "Unable to load users. Check your connection." with retry button
- **Error - Chat Creation Failed**: "Failed to create chat. Please try again." (alert)
- **Error - Not Authenticated**: Automatically handled by auth guard (shouldn't reach this screen)

**Performance Targets** (see shared-standards.md):
- User list fetch: < 500ms from Firestore
- Search filtering: < 50ms per keystroke
- Duplicate chat check: < 200ms
- Chat creation: < 300ms
- Total flow: < 2 seconds (tap "New Chat" → ChatView loads)
- Smooth 60fps scrolling through user list

---

## 7. Functional Requirements (Must/Should)

**MUST**:

- MUST implement `createChat(withUserID:)` in ChatService
  - [Gate] Method accepts target user ID as parameter
  - [Gate] Checks for existing chat with those 2 members before creating
  - [Gate] Query: `chats` collection where `members` array contains both current user and target user
  - [Gate] If existing chat found → Returns existing chatID without creating duplicate
  - [Gate] If no chat found → Creates new chat document with proper schema
  - [Gate] New chat includes: auto-generated ID, members array [currentUserID, targetUserID], isGroupChat: false, empty lastMessage, server timestamps
  - [Gate] Returns chatID (new or existing)
  - [Gate] Handles async errors (network, Firestore, authentication)

- MUST implement UserSelectionView SwiftUI screen
  - [Gate] Screen displays all users from `users` collection except current user
  - [Gate] Users fetched from Firestore on view appear
  - [Gate] Each row shows display name (primary) and email (secondary)
  - [Gate] Scrollable list with LazyVStack for performance
  - [Gate] Tapping row triggers chat creation and navigation
  - [Gate] Navigation/sheet presentation from ConversationListView

- MUST implement real-time search functionality
  - [Gate] Search bar at top of UserSelectionView
  - [Gate] Filters users by display name OR email (case-insensitive)
  - [Gate] Updates UI in real-time as user types (< 50ms per keystroke)
  - [Gate] Search happens client-side (filter local array, not new Firestore query)
  - [Gate] Shows count: "X users" or "X results"

- MUST prevent duplicate chat creation
  - [Gate] Before creating chat, query existing chats where both users are members
  - [Gate] Query: `.whereField("members", arrayContains: currentUserID)` then filter locally for targetUserID
  - [Gate] If existing chat found → Navigate to that chat without creating new document
  - [Gate] If no existing chat → Create new chat document
  - [Gate] Edge case: Concurrent creation by both users simultaneously handled gracefully (first write wins, second navigates to first's chat)

- MUST add "New Chat" button to ConversationListView
  - [Gate] Button visible in navigation toolbar or floating action button
  - [Gate] Tapping button presents UserSelectionView
  - [Gate] Uses sheet or navigation push (iOS HIG compliant)

- MUST remove MockDataService file
  - [Gate] Delete `Services/MockDataService.swift` file completely
  - [Gate] Remove any references to MockDataService from other files
  - [Gate] Remove any DEBUG-only UI buttons that called MockDataService
  - [Gate] Verify app builds without MockDataService

**SHOULD**:

- SHOULD show user count in UserSelectionView
  - [Gate] Header displays "X users" dynamically

- SHOULD optimize Firestore query with proper indexing
  - [Gate] Ensure `members` array field is indexed in Firestore

- SHOULD handle edge cases gracefully
  - [Gate] Empty user list shows helpful message
  - [Gate] No search results shows "No results for '[query]'"
  - [Gate] Network errors show retry option

- SHOULD provide visual feedback during operations
  - [Gate] Loading spinner while fetching users
  - [Gate] Brief indicator during chat creation (< 1 second)
  - [Gate] Immediate navigation to ChatView (no lingering on UserSelectionView)

**Acceptance Gates Summary**:
- [Gate] User taps "New Chat" → UserSelectionView appears within 100ms
- [Gate] User list loads from Firestore within 500ms
- [Gate] User types in search → Results filter within 50ms
- [Gate] User selects contact → Duplicate check + creation + navigation completes within 2 seconds
- [Gate] Selecting same contact twice → Navigates to same existing chat (no duplicate)
- [Gate] Chat created appears immediately in ConversationListView (via existing listener from PR #6)
- [Gate] MockDataService completely removed, app builds successfully

---

## 8. Data Model

Reference models from PR #5. This PR extends ChatService to create Chat documents.

### Firestore Collections

**Collection**: `users`

**Query**: Fetch all users for contact selection
```swift
db.collection("users").getDocuments()
```

**Filter**: Exclude current user client-side (not in Firestore query)
```swift
let filteredUsers = users.filter { $0.id != currentUserID }
```

**Collection**: `chats`

**New Chat Document** (created by this PR):
```swift
{
  id: String,                    // Auto-generated UUID
  members: [String],             // [currentUserID, targetUserID] (exactly 2)
  lastMessage: String,           // "" (empty initially)
  lastMessageTimestamp: Timestamp, // FieldValue.serverTimestamp()
  isGroupChat: Bool,             // false (always for this PR)
  createdAt: Timestamp,          // FieldValue.serverTimestamp()
  updatedAt: Timestamp           // FieldValue.serverTimestamp()
}
```

### Duplicate Chat Detection Query

**Query existing chats for two users**:
```swift
// Step 1: Query chats where current user is a member
db.collection("chats")
  .whereField("members", arrayContains: currentUserID)
  .getDocuments()

// Step 2: Filter results client-side to find chat with target user
let existingChat = chats.first { chat in
    chat.members.contains(targetUserID) && chat.members.count == 2 && !chat.isGroupChat
}
```

**Why not pure Firestore query?**
- Firestore doesn't support `arrayContainsAll` with dynamic arrays
- `arrayContains` only checks one value
- Client-side filtering is fast (< 50ms for typical user's 10-50 chats)
- Alternative: Use compound query with custom index (more complex, not worth it for MVP)

### Validation Rules

**Target User ID**:
- Must be non-empty string
- Must not equal current user ID
- Must reference existing user document in `users` collection (optional validation)

**Members Array**:
- Must contain exactly 2 user IDs for this PR
- Must include current authenticated user's ID
- Must include target user's ID
- No duplicates allowed

**Chat ID**:
- Auto-generated UUID using `UUID().uuidString`
- Used as Firestore document ID

### Indexing/Queries

**Firestore Indexes Required**:
1. **Composite index**: `chats` collection
   - `members` (array-contains) + `lastMessageTimestamp` (descending)
   - Auto-created by Firestore when first queried (PR #6 already created this)

**No new indexes needed for this PR** (members array already indexed from PR #6)

---

## 9. API / Service Contracts

Reference examples in `Psst/agents/shared-standards.md`.

### ChatService.swift (Extend Existing File)

**File Location**: `Services/ChatService.swift` (already exists from PR #6)

**New Method to Add**:

```swift
// MARK: - Create Chat

/// Creates a new 1-on-1 chat or returns existing chat if one already exists
/// Performs duplicate check before creating to prevent multiple chats with same user
/// - Parameter targetUserID: The ID of the user to create a chat with
/// - Returns: The ID of the created or existing chat
/// - Throws: ChatError if validation fails or Firestore operations fail
func createChat(withUserID targetUserID: String) async throws -> String {
    // Pre-conditions:
    // - User must be authenticated
    // - targetUserID must not be empty
    // - targetUserID must not equal current user ID
    
    // Steps:
    // 1. Get current user ID from Firebase Auth
    // 2. Validate targetUserID != currentUserID
    // 3. Query existing chats where current user is a member
    // 4. Filter results for chat that includes target user (members.count == 2, not group chat)
    // 5. If existing chat found → return existing chatID
    // 6. If no existing chat → create new chat document
    // 7. Return new chatID
    
    // Post-conditions:
    // - Returns chatID (existing or newly created)
    // - New chat document written to Firestore (if no duplicate found)
    // - Chat appears in ConversationListView (via existing listener from PR #6)
}
```

**Implementation Details**:

```swift
import Foundation
import FirebaseFirestore
import FirebaseAuth

// Add to existing ChatService class:

/// Creates a new 1-on-1 chat or returns existing chat
func createChat(withUserID targetUserID: String) async throws -> String {
    // Validate current user is authenticated
    guard let currentUserID = Auth.auth().currentUser?.uid else {
        throw ChatError.notAuthenticated
    }
    
    // Validate target user is not self
    guard targetUserID != currentUserID else {
        throw ChatError.cannotChatWithSelf
    }
    
    // Validate target user ID is not empty
    guard !targetUserID.isEmpty else {
        throw ChatError.invalidUserID
    }
    
    // Step 1: Check for existing chat with this user
    let snapshot = try await db.collection("chats")
        .whereField("members", arrayContains: currentUserID)
        .getDocuments()
    
    // Filter for existing 1-on-1 chat with target user
    for document in snapshot.documents {
        let data = document.data()
        if let members = data["members"] as? [String],
           members.count == 2,
           members.contains(targetUserID),
           let isGroupChat = data["isGroupChat"] as? Bool,
           !isGroupChat {
            // Existing chat found - return its ID
            print("✅ Found existing chat: \(document.documentID)")
            return document.documentID
        }
    }
    
    // Step 2: No existing chat found - create new one
    let newChatID = UUID().uuidString
    let newChat: [String: Any] = [
        "id": newChatID,
        "members": [currentUserID, targetUserID],
        "lastMessage": "",
        "lastMessageTimestamp": FieldValue.serverTimestamp(),
        "isGroupChat": false,
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp()
    ]
    
    try await db.collection("chats").document(newChatID).setData(newChat)
    print("✅ Created new chat: \(newChatID)")
    
    return newChatID
}

// MARK: - Errors

enum ChatError: LocalizedError {
    case notAuthenticated
    case cannotChatWithSelf
    case invalidUserID
    case firestoreError(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User must be logged in to create chats"
        case .cannotChatWithSelf:
            return "Cannot create a chat with yourself"
        case .invalidUserID:
            return "Invalid user ID provided"
        case .firestoreError(let error):
            return "Firestore error: \(error.localizedDescription)"
        }
    }
}
```

### UserService.swift (Extend Existing File or Use in UserSelectionView)

**File Location**: `Services/UserService.swift` (already exists from PR #3)

**Verify Existing Method**:
```swift
/// Fetch all users from Firestore
func fetchAllUsers() async throws -> [User]
```

**If method doesn't exist, add it**:
```swift
/// Fetches all users from Firestore users collection
/// - Returns: Array of User objects
/// - Throws: Firestore errors if query fails
func fetchAllUsers() async throws -> [User] {
    let snapshot = try await db.collection("users").getDocuments()
    
    let users = snapshot.documents.compactMap { document -> User? in
        do {
            return try document.data(as: User.self)
        } catch {
            print("⚠️ Error decoding user \(document.documentID): \(error)")
            return nil
        }
    }
    
    return users
}
```

---

## 10. UI Components to Create/Modify

**Create**:
- `Views/UserSelection/UserSelectionView.swift` — Main contact selection screen (NEW)
- `Views/UserSelection/UserRow.swift` — Individual user row component (NEW)

**Modify**:
- `Services/ChatService.swift` — Add createChat(withUserID:) method
- `Services/UserService.swift` — Verify/add fetchAllUsers() method
- `Views/ConversationList/ConversationListView.swift` — Add "New Chat" button in navigation toolbar

**Delete**:
- `Services/MockDataService.swift` — Remove entire file (DEBUG-only mock data)

**No changes to**:
- `Models/User.swift` (already defined in PR #3)
- `Models/Chat.swift` (already defined in PR #5)
- `Views/ChatList/ChatView.swift` (no changes needed)

---

## 11. Integration Points

**Firebase Services**:
- **Firestore Database**: Query `users` collection, query/write `chats` collection
- **Firebase Auth**: Get current user ID for chat membership validation
- **FieldValue.serverTimestamp()**: Synchronized timestamps for chat creation

**SwiftUI Integration**:
- **UserSelectionView**: Sheet or navigation push from ConversationListView
- **@State users array**: Fetched from UserService, filtered by search query
- **Task/async-await**: For async Firestore operations
- **NavigationLink/programmatic navigation**: Navigate to ChatView after chat creation
- **Search functionality**: SwiftUI `.searchable()` modifier or custom search bar

**Architecture Pattern** (per architecture.md):
- Service layer handles all Firebase logic
- Views remain thin wrappers
- State management via SwiftUI @State
- MVVM pattern: UserSelectionView → ChatService/UserService → Firestore

**Thread Safety** (see Swift Development Rules in .cursorrules):
- All Firestore operations run on background threads automatically
- UI updates wrapped in `DispatchQueue.main.async` or via `@MainActor`
- SwiftUI updates automatically on main thread when @State changes

**Existing Listener Integration**:
- ConversationListView already has ChatService.observeUserChats() listener (PR #6)
- When new chat created → Listener automatically fires → New chat appears in list
- No additional code needed in ConversationListView beyond "New Chat" button

---

## 12. Manual Validation Plan

**Current**: Manual testing validation (see `Psst/agents/shared-standards.md`)

### Configuration Testing
- [ ] Firebase Firestore connection established
- [ ] Firebase Authentication provides valid user ID
- [ ] Firestore security rules allow read access to `users` collection
- [ ] Firestore security rules allow read/write access to `chats` collection
- [ ] All necessary Firebase imports working

### Happy Path Testing
- [ ] **User A logs in**: Opens ConversationListView
- [ ] Gate: "New Chat" button visible in navigation toolbar
- [ ] **User A taps "New Chat"**: UserSelectionView appears
- [ ] Gate: View presents within 100ms (sheet or navigation push)
- [ ] **User list loads**: All users except User A displayed
- [ ] Gate: Users fetch from Firestore within 500ms
- [ ] Gate: Display names and emails visible in each row
- [ ] Gate: User A's account NOT in list (filtered out)
- [ ] **User A selects User B**: Taps row
- [ ] Gate: Brief loading indicator (< 1 second)
- [ ] Gate: New chat created in Firestore
- [ ] Gate: ChatView opens with empty message list
- [ ] Gate: UserSelectionView dismisses automatically
- [ ] **User A goes back**: Returns to ConversationListView
- [ ] Gate: New chat with User B appears in conversation list
- [ ] **User A sends message**: Types "Hello" and sends
- [ ] Gate: Message appears in ChatView (validates PR #8 integration)
- [ ] **User B logs in**: Opens ConversationListView
- [ ] Gate: Chat with User A appears in User B's list (real-time listener)

### Duplicate Prevention Testing
- [ ] **User A**: Already has existing chat with User B (from Happy Path test)
- [ ] **User A taps "New Chat"**: UserSelectionView appears
- [ ] **User A selects User B again**: Taps User B's row
- [ ] Gate: Duplicate check runs (< 200ms)
- [ ] Gate: Existing chat found (no new chat created in Firestore)
- [ ] Gate: Navigates to existing ChatView (shows previous "Hello" message)
- [ ] Gate: No duplicate chat documents in Firestore Console
- [ ] **Concurrent creation test**:
  - [ ] User A and User B both tap "New Chat" at same time
  - [ ] User A selects User B, User B selects User A (within 1 second of each other)
  - [ ] Gate: Only one chat document created (first write wins)
  - [ ] Gate: Both users navigate to same chat
  - [ ] Gate: No duplicate chats in Firestore Console

### Search Functionality Testing
- [ ] **User list loaded**: 5+ users in database for meaningful test
- [ ] **User types in search bar**: "Ali"
- [ ] Gate: Results filter in real-time (< 50ms)
- [ ] Gate: Only users with "Ali" in display name OR email show
- [ ] Gate: Search is case-insensitive ("ali" matches "Alice")
- [ ] **User clears search**: Deletes text
- [ ] Gate: Full user list restored
- [ ] **User types non-matching query**: "XYZ123"
- [ ] Gate: "No results for 'XYZ123'" message appears
- [ ] Gate: No users displayed (empty list)
- [ ] **User types partial email**: "@example"
- [ ] Gate: All users with "@example" in email displayed
- [ ] **Special characters test**: Types "O'Brien"
- [ ] Gate: Search handles apostrophes correctly

### Edge Cases Testing
- [ ] **Empty database**: Delete all users except current user
- [ ] Gate: UserSelectionView shows "No users found" message
- [ ] Gate: Search bar disabled or shows helpful text
- [ ] **Network offline**: Disable internet connection
- [ ] Gate: Firestore query fails gracefully
- [ ] Gate: Error message: "Unable to load users. Check your connection."
- [ ] Gate: Retry button available
- [ ] **Very long display name**: User with 50+ character name
- [ ] Gate: UI handles long names without truncation issues (ellipsis)
- [ ] **Large user list**: 100+ users in database
- [ ] Gate: Smooth 60fps scrolling with LazyVStack
- [ ] Gate: Search still responds within 50ms
- [ ] **Rapid selection**: User double-taps contact row
- [ ] Gate: Only one chat creation attempt (button disabled after first tap)
- [ ] Gate: No race condition errors

### MockDataService Removal Testing
- [ ] **Code search**: Search entire project for "MockDataService"
- [ ] Gate: No references found in any Swift files
- [ ] Gate: File `Services/MockDataService.swift` deleted
- [ ] **Build verification**: Build project in Xcode
- [ ] Gate: Build succeeds with 0 errors
- [ ] Gate: No compiler warnings about missing MockDataService
- [ ] **DEBUG build test**: Run app in DEBUG mode
- [ ] Gate: No references to mock data buttons in UI
- [ ] Gate: All features work with real Firestore data

### Performance Testing (see shared-standards.md)
- [ ] **User list fetch**: Measure time to load users on UserSelectionView appear
- [ ] Gate: < 500ms from Firestore query to UI display
- [ ] **Search responsiveness**: Type quickly in search bar (10 keystrokes in 2 seconds)
- [ ] Gate: No lag, results filter within 50ms per keystroke
- [ ] **Duplicate check latency**: Measure time from row tap to navigation
- [ ] Gate: < 2 seconds total (includes duplicate check + optional creation + navigation)
- [ ] **Chat creation**: Measure time to write new chat document
- [ ] Gate: < 300ms for Firestore write operation
- [ ] **Scrolling performance**: Scroll through 50+ user list rapidly
- [ ] Gate: Smooth 60fps, no janky scrolling (LazyVStack)

### Visual State Verification
- [ ] No console errors during user list fetch
- [ ] No console errors during search filtering
- [ ] No console errors during chat creation
- [ ] "New Chat" button clearly visible in ConversationListView
- [ ] UserSelectionView presents smoothly (sheet animation or navigation push)
- [ ] Loading spinner appears while fetching users
- [ ] Search bar clearly visible at top of UserSelectionView
- [ ] User count displayed: "X users" or "X results"
- [ ] Empty states render correctly with helpful messages
- [ ] ChatView loads immediately after selection (no blank screen delay)

---

## 13. Definition of Done

See standards in `Psst/agents/shared-standards.md`:

- [ ] ChatService.createChat(withUserID:) implemented with duplicate prevention
- [ ] UserService.fetchAllUsers() implemented (or verified existing)
- [ ] UserSelectionView.swift created with user list display
- [ ] UserRow.swift created for consistent user display
- [ ] Search functionality implemented (real-time filtering by name/email)
- [ ] "New Chat" button added to ConversationListView navigation toolbar
- [ ] Navigation from UserSelectionView to ChatView working
- [ ] Duplicate chat prevention verified (no duplicate documents created)
- [ ] MockDataService.swift file completely removed from project
- [ ] All references to MockDataService removed from codebase
- [ ] Error handling for all failure cases (auth, network, validation)
- [ ] Empty states implemented (no users, no search results)
- [ ] Loading states implemented (fetching users, creating chat)
- [ ] All acceptance gates pass
- [ ] Manual testing completed (configuration, user flows, search, duplicate prevention, performance)
- [ ] Performance targets met (< 2 second total flow)
- [ ] No console warnings or errors
- [ ] Code follows `Psst/agents/shared-standards.md` patterns
- [ ] Project builds successfully after MockDataService removal
- [ ] PR created targeting develop branch

---

## 14. Risks & Mitigations

**Risk: Duplicate chats created if two users select each other simultaneously**
- **Mitigation**: Firestore query + filter approach handles this. First write wins, second write's duplicate check finds the first's chat. Both users end up in same chat.
- **Alternative mitigation**: Use deterministic chat ID (sorted userID concatenation) but this is more complex and unnecessary.

**Risk: Search performance degrades with large user lists (1000+ users)**
- **Mitigation**: For MVP, client-side filtering is acceptable (< 50ms for 100-500 users). Future optimization: Algolia or Firestore full-text search index.
- **Current scope**: Assume < 500 users for MVP (typical small community app).

**Risk: User list fetch is slow (> 500ms) with many users**
- **Mitigation**: Fetch happens once on UserSelectionView appear. Use loading spinner. Future: Pagination with limit(50) and "load more" button.
- **Testing**: Verify with 100+ test users to confirm acceptable performance.

**Risk: Removing MockDataService breaks existing tests or workflows**
- **Mitigation**: Search entire codebase for "MockDataService" references before removal. Update any DEBUG-only UI that depended on it. Since this PR enables real chat creation, mock data no longer needed.

**Risk: Search doesn't handle special characters (accents, emojis) correctly**
- **Mitigation**: Swift String filtering handles Unicode correctly by default. Test with names like "José", "François", "李明" to verify.

**Risk: User selects deleted/invalid user from list**
- **Mitigation**: For MVP, assume users in `users` collection are valid. Future: Add validation in createChat() to check if target user document exists.

**Risk: Navigation doesn't work correctly (sheet vs push vs modal)**
- **Mitigation**: Follow iOS HIG. Use NavigationLink or sheet presentation. Test on actual device to ensure smooth animations.

**Risk: Chat created but doesn't appear in ConversationListView immediately**
- **Mitigation**: Existing listener from PR #6 uses snapshot listeners, so new chats appear automatically. Verify listener is attached before creating chat.

---

## 15. Rollout & Telemetry

**Feature Flag**: No

**Metrics (Manual Observation)**:
- Count successful chat creations vs failures during testing
- Measure time from "New Chat" tap to ChatView loaded
- Measure search filtering latency (keystroke to UI update)
- Verify zero duplicate chats created in Firestore Console
- Confirm MockDataService removal doesn't break build

**Manual Validation Steps**:
1. Log in as User A
2. Tap "New Chat" button
3. Select User B from list
4. Verify ChatView loads with empty messages
5. Go back, tap "New Chat" again
6. Select User B again (duplicate test)
7. Verify navigates to existing chat (no duplicate)
8. Search for user by name
9. Verify results filter correctly
10. Log in as User B on different device
11. Verify chat with User A appears in list

**Logging Strategy**:
```swift
// Add debug logs for monitoring
print("🔍 Fetching all users from Firestore")
print("✅ Loaded \(users.count) users")
print("🔎 Searching for: '\(searchQuery)'")
print("📊 \(filteredUsers.count) results")
print("➕ Creating chat with user: \(targetUserID)")
print("✅ Found existing chat: \(chatID)")
print("✅ Created new chat: \(chatID)")
print("❌ Chat creation failed: \(error.localizedDescription)")
```

---

## 16. Open Questions

**Q1**: Should we show user profile pictures in the contact list?
- **Answer**: Yes, show placeholder or actual photoURL from User model, but low priority. Basic implementation (circle avatar) is fine for MVP. Polish in PR #17.

**Q2**: Should we sort users alphabetically or by some other criteria?
- **Answer**: Alphabetically by display name. Future: Sort by "recently chatted" or "favorites" (deferred).

**Q3**: What happens if a user's account is deleted between loading list and creating chat?
- **Answer**: Out of scope for this PR. Deferred to future error handling improvements. createChat() will succeed but chat will have invalid member.

**Q4**: Should we paginate the user list for large databases?
- **Answer**: No pagination for MVP. Assume < 500 users. LazyVStack handles this efficiently. Future: Add limit(50) and "Load more" if needed.

**Q5**: Should users be able to create chats with themselves (for notes)?
- **Answer**: No. Validation prevents currentUserID == targetUserID. Future feature if requested.

**Q6**: What if Firestore security rules block user list fetch?
- **Answer**: Ensure rules allow authenticated users to read `users` collection. Verify in manual testing. Error message guides user to check connection.

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future PRs:

- [ ] Group chat creation (3+ user selection) (PR #11)
- [ ] User profile picture upload (PR #17)
- [ ] Custom chat names/icons for groups (PR #14)
- [ ] "Recently chatted" or "favorites" sections (future)
- [ ] Contact import from phone/iCloud (future)
- [ ] Blocking/reporting users (future)
- [ ] User presence indicators in contact list (PR #12)
- [ ] Pagination for user list (future - if > 500 users)
- [ ] Full-text search with Algolia (future)
- [ ] "Invite friends" functionality (future)
- [ ] User verification/badges (future)
- [ ] Automated unit tests (deferred to backlog)
- [ ] Integration tests (deferred to backlog)

---

## Preflight Questionnaire

1. **Smallest end-to-end user outcome for this PR?**
   - User can tap "New Chat", select a contact, and immediately start messaging them in a new or existing chat.

2. **Primary user and critical action?**
   - Primary user: Any authenticated user wanting to start a conversation
   - Critical action: Select contact → Create/navigate to chat

3. **Must-have vs nice-to-have?**
   - Must-have: User selection, search, createChat(), duplicate prevention, MockDataService removal
   - Nice-to-have: Profile pictures, sorting options, pagination (deferred)

4. **Real-time requirements?** (see shared-standards.md)
   - Chat creation: < 300ms
   - New chat appears in ConversationListView automatically (via existing PR #6 listener)
   - Search filtering: < 50ms per keystroke
   - Total flow: < 2 seconds (tap to ChatView loaded)

5. **Performance constraints?** (see shared-standards.md)
   - User list fetch: < 500ms
   - Search responsiveness: < 50ms per keystroke
   - Duplicate check: < 200ms
   - Smooth 60fps scrolling through user list
   - No UI blocking (async operations)

6. **Error/edge cases to handle?**
   - Empty user list (no users in database)
   - No search results (query doesn't match any users)
   - Network failure during user fetch or chat creation
   - User not authenticated (shouldn't reach this screen)
   - Cannot chat with self (validation error)
   - Duplicate chat creation attempts (prevented by query)
   - Rapid/double taps on user row (button debouncing)

7. **Data model changes?**
   - No changes to User or Chat models (defined in PR #3 and PR #5)
   - Uses existing Firestore schema
   - New chat documents created with proper structure

8. **Service APIs required?**
   - `ChatService.createChat(withUserID:) async throws -> String`
   - `UserService.fetchAllUsers() async throws -> [User]` (verify or add)

9. **UI entry points and states?**
   - Entry: "New Chat" button in ConversationListView navigation toolbar
   - States: Loading users, Search, Selecting user, Creating chat, Error
   - Exit: Navigate to ChatView, dismiss UserSelectionView

10. **Security/permissions implications?**
    - Firestore security rules must allow authenticated users to read `users` collection
    - Firestore security rules must allow authenticated users to create `chats` documents where they are a member
    - Rules validation deferred to PR #9 completion

11. **Dependencies or blocking integrations?**
    - Depends on: PR #1 (Firebase setup), PR #2 (Auth), PR #3 (User model), PR #4 (Navigation), PR #5 (Chat model), PR #6 (ConversationListView with listener), PR #7 (ChatView UI), PR #8 (MessageService)
    - Blocks: PR #11 (Group chat - extends this functionality)

12. **Rollout strategy and metrics?**
    - Manual testing with 2+ users creating chats
    - Verify duplicate prevention with Firestore Console
    - Measure latency with timer logs
    - Confirm MockDataService removal doesn't break build

13. **What is explicitly out of scope?**
    - Group chat creation, profile picture upload, custom chat names, contact import, blocking, presence indicators in list, pagination, full-text search, automated tests

---

## Authoring Notes

- This PR is the MISSING LINK that enables real-world testing of PRs 6-8
- createChat() duplicate prevention is critical - test thoroughly with concurrent attempts
- Search must be performant - client-side filtering is acceptable for MVP (< 500 users)
- MockDataService removal is a cleanup task - verify all references removed before PR
- Follow architecture.md: Services handle Firebase logic, Views stay thin
- Use async/await for clean async code
- LazyVStack for user list to maintain 60fps with many users
- Per Swift threading rules: Firebase callbacks already on main thread
- Reference shared-standards.md for performance targets throughout
- Navigation should feel instant (< 100ms from tap to view transition)
- Empty states and loading states are important for good UX
- Test duplicate prevention with BOTH users creating chat simultaneously

