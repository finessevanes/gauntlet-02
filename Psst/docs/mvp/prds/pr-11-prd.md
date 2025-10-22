# PRD: Group Chat Support

**Feature**: Group Chat Support

**Version**: 1.0

**Status**: Ready for Development

**Agent**: Pam

**Target Release**: Phase 3 - Group Chats & Presence

**Links**: [PR Brief #11](../pr-briefs.md#pr-11-group-chat-support), [TODO](../todos/pr-11-todo.md), [Architecture](../architecture.md)

---

## 1. Summary

Extend chat functionality to support group conversations with 3+ users by adding multi-select user selection, group chat creation with naming, sender name display in messages, and real-time synchronization for all group participants.

---

## 2. Problem & Goals

**Problem**: Users can currently only create and participate in 1-on-1 conversations. There is no way to start group conversations with 3+ people, which limits collaboration and communication scenarios where multiple users need to coordinate together (e.g., project teams, friend groups, family chats).

**Why now**: Phase 3 focuses on group communication features. With foundation (PR #1-4) and 1-on-1 chat (PR #5-10) complete, the app has proven real-time messaging infrastructure. Adding group chat extends this foundation to enable multi-party conversations, which is a core MVP requirement (PRD item #8) and differentiates the app from basic messaging.

**Goals**:
  - [ ] G1 — Users can select 3+ contacts to create a group chat
  - [ ] G2 — Users can name group chats to identify them easily
  - [ ] G3 — Group chat messages display sender names so participants know who said what
  - [ ] G4 — All group members receive messages in real-time with < 100ms latency
  - [ ] G5 — Group chats appear in conversation list with member avatars/names

---

## 3. Non-Goals / Out of Scope

- [ ] Group chat administration (add/remove members after creation) - Deferred to future
- [ ] Group chat profile pictures/icons - Basic placeholder only, polish later
- [ ] Group chat descriptions or metadata beyond name - Future feature
- [ ] Read receipts showing individual read status per group member - PR #14 handles this
- [ ] Typing indicators for multiple users in groups - PR #13 handles this
- [ ] @ mentions or tagging specific group members - Future feature
- [ ] Group chat settings (mute, leave, delete) - Future feature
- [ ] Maximum group size limits (assume < 50 members for MVP) - Future optimization
- [ ] Group chat permissions/roles (admin, moderator) - Future feature
- [ ] Automated unit/UI tests - Deferred to backlog per testing-strategy.md

---

## 4. Success Metrics

Reference `Psst/agents/shared-standards.md` for metric templates:

**User-visible**:
- Time to create group: User taps "New Chat" → selects 3+ contacts → names group → GroupChatView loads < 3 seconds
- Flow completion: 100% of group creations result in successful group chat creation
- Message delivery: Messages sent to group appear on all members' devices within 100ms
- Sender identification: 100% of group messages show correct sender name
- Zero confusion about who sent which message

**System** (see shared-standards.md):
- **Group chat creation**: < 500ms to write group chat document to Firestore
- **Message sync latency**: < 100ms from sender to all recipients (real-time)
- **Sender name display**: < 50ms to render sender name with each message
- **Conversation list update**: Group chat appears immediately (via existing listener)
- **Multi-member handling**: No performance degradation with 3-10 members
- **No UI blocking**: All operations run asynchronously

**Quality**:
- 0 blocking bugs during manual testing
- All acceptance gates pass
- Crash-free rate >99%
- No console errors during group chat creation/messaging
- Sender names display correctly in all group scenarios (3, 5, 10+ members)

---

## 5. Users & Stories

- As a **user**, I want to **select multiple contacts (3+) from the user selection screen** so that **I can create a group conversation with all of them at once**.

- As a **user**, I want to **name my group chat** so that **I can easily identify it in my conversation list without reading member names**.

- As a **group chat member**, I want to **see who sent each message** so that **I can follow the conversation and know who said what**.

- As a **group chat creator**, I want **all members to receive messages in real-time** so that **everyone stays synchronized and can participate actively**.

- As a **user**, I want to **distinguish group chats from 1-on-1 chats** in my conversation list so that **I can quickly identify multi-party conversations**.

---

## 6. Experience Specification (UX)

**Entry Points**:
- User taps "New Chat" button in ConversationListView → Navigates to UserSelectionView (same as PR #9)
- UserSelectionView now has toggle/mode for "Group Chat" enabling multi-select

**Visual Behavior**:

### Multi-Select User Selection

1. **User taps "New Chat" button**
   - UserSelectionView sheet/navigation presented
   - Toggle at top: "1-on-1" vs "Group" mode (default: "1-on-1")
   - User toggles to "Group" mode

2. **Group mode enabled**
   - Search bar remains at top
   - Each user row now shows selection checkbox or checkmark
   - User can tap multiple contacts (3+ required)
   - Selected count shown: "3 selected", "5 selected", etc.
   - "Create Group" button appears at bottom (disabled until 3+ selected)
   - Minimum 3 users required (validation prevents < 3)

3. **User selects 3+ contacts**
   - Each tap toggles selection (checkmark appears/disappears)
   - Selected contacts highlighted visually
   - "Create Group" button becomes enabled when 3+ selected
   - User can tap "Create Group" button

4. **Group naming sheet**
   - Modal sheet appears: "Name Your Group"
   - Text field: "Group Name" (1-50 characters)
   - Optional: Show selected members as chips/avatars below text field
   - "Cancel" button (dismisses sheet, returns to user selection)
   - "Create" button (creates group chat with provided name)
   - Validation: Group name cannot be empty (minimum 1 character)

5. **Group chat created**
   - Brief loading indicator (< 1 second)
   - Group chat document created in Firestore with members array (current user + selected users)
   - Navigate to GroupChatView (or ChatView with group mode)
   - UserSelectionView and naming sheet dismiss
   - Group chat appears in ConversationListView for all members

### Group Message Display

1. **GroupChatView UI**
   - Chat header shows group name (large text) + member count "(5 members)"
   - Message list displays messages with sender names
   - Each message bubble shows:
     - **Sender name** (small label above/inside bubble) for messages NOT from current user
     - **Message text** (main content)
     - **Timestamp** (below message)
   - Messages from current user: Right-aligned, no sender name (labeled "You" or omitted)
   - Messages from others: Left-aligned, sender name shown prominently

2. **Example message layout (not current user)**:
   ```
   Alice Johnson
   Hey team, what time is the meeting?
   10:42 AM
   ```

3. **Example message layout (current user)**:
   ```
                         It's at 3 PM today!
                                    10:43 AM
   ```

4. **Sender name display logic**:
   - Fetch sender's display name from `users` collection using senderID
   - Cache names locally to avoid repeated Firestore queries
   - If sender not found: Show "Unknown User"

### Conversation List Group Display

1. **Group chat row in ConversationListView**
   - **Group icon/indicator**: Show overlapping circles or "Group" badge
   - **Group name**: Primary text (bold) - "Project Team", "Family Chat", etc.
   - **Last message preview**: "[Sender Name]: Message text" - e.g., "Alice: See you tomorrow!"
   - **Timestamp**: Right side, same as 1-on-1 chats
   - **Member count**: Small text below group name - "(5 members)"
   - **Group avatar**: Placeholder group icon or composite of member avatars (basic implementation)

**Loading/Error States**:
- **Loading - Creating Group**: Spinner with "Creating group..." (< 1 second)
- **Loading - Fetching Sender Names**: Cached locally, fallback to "Unknown User" if fetch fails
- **Error - Insufficient Members**: Alert: "Groups require 3 or more members"
- **Error - Empty Group Name**: Alert: "Please enter a group name" (validation on "Create" button)
- **Error - Network Failure**: "Unable to create group. Check your connection." with retry button
- **Error - Message Send Failed**: "Failed to send message" (same as 1-on-1, handled by PR #8 MessageService)

**Performance Targets** (see shared-standards.md):
- Group chat creation: < 500ms to write to Firestore
- Group message send: < 100ms to all members (real-time sync)
- Sender name display: < 50ms to fetch/cache and render
- Total group creation flow: < 3 seconds (multi-select → name → GroupChatView loads)
- Smooth 60fps scrolling through group messages
- No UI blocking during member name fetches

---

## 7. Functional Requirements (Must/Should)

**MUST**:

- MUST extend `createChat()` in ChatService to support group creation
  - [Gate] Method accepts array of user IDs (3+ members)
  - [Gate] Method accepts optional group name parameter (1-50 characters)
  - [Gate] Validates minimum 3 members (including current user = 4 total, or 3 others + current = 4 total)
  - [Gate] Creates chat document with `isGroupChat: true`
  - [Gate] Creates chat document with `members` array containing all selected user IDs + current user
  - [Gate] Creates chat document with group name field (new field: `groupName: String`)
  - [Gate] Returns chatID of new group
  - [Gate] No duplicate check needed (groups are always new conversations)

- MUST add multi-select mode to UserSelectionView
  - [Gate] Toggle between "1-on-1" and "Group" mode at top of screen
  - [Gate] Group mode shows checkboxes/checkmarks on user rows
  - [Gate] User can tap multiple rows to select 3+ contacts
  - [Gate] Selected count displayed: "X selected"
  - [Gate] "Create Group" button appears at bottom (disabled until 3+ selected)
  - [Gate] Tapping "Create Group" → Group naming sheet appears

- MUST implement group naming UI
  - [Gate] Modal sheet with "Name Your Group" heading
  - [Gate] Text field for group name (1-50 character validation)
  - [Gate] "Cancel" button dismisses sheet
  - [Gate] "Create" button validates name and creates group
  - [Gate] Validation: Empty name shows alert "Please enter a group name"
  - [Gate] Optional: Display selected member names/avatars in sheet

- MUST display sender names in group chat messages
  - [Gate] GroupChatView (or ChatView in group mode) displays sender name above/inside each message bubble
  - [Gate] Messages NOT from current user show sender's display name
  - [Gate] Messages from current user do NOT show sender name (or show "You")
  - [Gate] Sender names fetched from `users` collection via senderID
  - [Gate] Names cached locally to avoid repeated Firestore queries
  - [Gate] Fallback: "Unknown User" if sender not found

- MUST update Chat model to include groupName field
  - [Gate] Add `var groupName: String?` to Chat struct (optional, nil for 1-on-1)
  - [Gate] Include groupName in toDictionary() method
  - [Gate] Decode groupName from Firestore documents

- MUST update MessageService to handle group message sending
  - [Gate] sendMessage() works for both 1-on-1 and group chats (no code changes needed if already chat-agnostic)
  - [Gate] Verify real-time listeners trigger for all group members
  - [Gate] All group members receive messages via existing snapshot listeners from PR #8

- MUST display group chats correctly in ConversationListView
  - [Gate] Group chat rows show group name (not member names)
  - [Gate] Last message preview: "[Sender Name]: Message text"
  - [Gate] Member count displayed: "(X members)"
  - [Gate] Group indicator/icon to distinguish from 1-on-1 chats
  - [Gate] Sorted by lastMessageTimestamp (same as 1-on-1)

**SHOULD**:

- SHOULD cache sender names locally for performance
  - [Gate] Implement in-memory dictionary: `[senderID: displayName]`
  - [Gate] Fetch name once per sender, reuse for all subsequent messages
  - [Gate] Reduces Firestore queries from N messages to N unique senders

- SHOULD show member count in group chat header
  - [Gate] Header displays group name + "(X members)"
  - [Gate] Dynamic count based on members array length

- SHOULD handle sender name fetch errors gracefully
  - [Gate] If Firestore query fails → Use cached name or "Unknown User"
  - [Gate] No UI blocking or crashes from missing names
  - [Gate] Console logs warning for debugging

- SHOULD allow editing group name after creation
  - [Gate] Deferred to future PR (out of scope for this PR)
  - [Gate] For MVP, group name set once during creation

**Acceptance Gates Summary**:
- [Gate] User toggles to "Group" mode → Multi-select checkboxes appear
- [Gate] User selects 3+ contacts → "Create Group" button enabled
- [Gate] User taps "Create Group" → Group naming sheet appears
- [Gate] User enters group name and taps "Create" → Group chat created within 500ms
- [Gate] Group chat appears in ConversationListView with group name and member count
- [Gate] User sends message in group → All members receive within 100ms
- [Gate] Group messages display sender name (not from current user) correctly
- [Gate] Current user's messages do NOT show sender name (or show "You")
- [Gate] Existing 1-on-1 chat creation flow (PR #9) remains unchanged

---

## 8. Data Model

Reference models from PR #5. This PR extends Chat model and ChatService.

### Firestore Collections

**Collection**: `chats`

**Group Chat Document** (created by this PR):
```swift
{
  id: String,                    // Auto-generated UUID
  members: [String],             // [currentUserID, user2ID, user3ID, ...] (3+ members)
  lastMessage: String,           // Text of most recent message
  lastMessageTimestamp: Timestamp, // FieldValue.serverTimestamp()
  isGroupChat: Bool,             // true (always for groups)
  groupName: String?,            // "Project Team", "Family Chat", etc. (NEW FIELD)
  createdAt: Timestamp,          // FieldValue.serverTimestamp()
  updatedAt: Timestamp           // FieldValue.serverTimestamp()
}
```

**New Field**: `groupName` (String, optional)
- Required for group chats, nil for 1-on-1 chats
- 1-50 characters
- User-defined during group creation
- Displayed in conversation list and chat header

**Collection**: `messages` (sub-collection under each chat)

No changes to Message model - already has `senderID` field for identifying sender.

**Message Document** (same as PR #5):
```swift
{
  id: String,
  text: String,
  senderID: String,              // Used to fetch sender name for display
  timestamp: Timestamp,
  readBy: [String]
}
```

### Updated Chat Model (Swift)

**File**: `Models/Chat.swift`

**Add groupName field**:
```swift
struct Chat: Identifiable, Codable, Equatable {
    let id: String
    let members: [String]
    var lastMessage: String
    var lastMessageTimestamp: Date
    var isGroupChat: Bool
    var groupName: String?        // NEW FIELD (optional)
    let createdAt: Date
    var updatedAt: Date
    
    // Update toDictionary() to include groupName
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "members": members,
            "lastMessage": lastMessage,
            "lastMessageTimestamp": FieldValue.serverTimestamp(),
            "isGroupChat": isGroupChat,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        // Include groupName if present
        if let groupName = groupName {
            dict["groupName"] = groupName
        }
        
        return dict
    }
}
```

### Validation Rules

**Group Chat Creation**:
- Members array must contain at least 3 user IDs
- Must include current authenticated user in members array
- All member IDs must be non-empty strings
- Group name must be 1-50 characters (trimmed)
- Group name cannot be only whitespace

**Sender Name Display**:
- Fetch display name from `users` collection using message.senderID
- Cache names locally to avoid repeated queries
- Fallback to "Unknown User" if user document not found

### Indexing/Queries

**Firestore Indexes** (already created in PR #6):
- Composite index: `chats` collection
  - `members` (array-contains) + `lastMessageTimestamp` (descending)
  - Already exists from PR #6, no new index needed

**Firestore Queries**:
- **Fetch group chats**: Same query as 1-on-1 (PR #6) - `.whereField("members", arrayContains: currentUserID)`
- **Fetch sender name**: `db.collection("users").document(senderID).getDocument()`

---

## 9. API / Service Contracts

Reference examples in `Psst/agents/shared-standards.md`.

### ChatService.swift (Extend Existing File)

**File Location**: `Services/ChatService.swift` (already exists from PR #6, extended in PR #9)

**New/Modified Methods**:

#### 1. Create Group Chat (New Method)

```swift
// MARK: - Create Group Chat

/// Creates a new group chat with 3+ members and a custom name
/// - Parameters:
///   - memberUserIDs: Array of user IDs to include in the group (must be 3+)
///   - groupName: Name for the group chat (1-50 characters)
/// - Returns: The ID of the created group chat
/// - Throws: ChatError if validation fails or Firestore operations fail
func createGroupChat(withMembers memberUserIDs: [String], groupName: String) async throws -> String {
    // Pre-conditions:
    // - User must be authenticated
    // - memberUserIDs must contain at least 3 user IDs
    // - groupName must be 1-50 characters (trimmed)
    // - Current user will be added to members automatically
    
    // Steps:
    // 1. Get current user ID from Firebase Auth
    // 2. Validate memberUserIDs.count >= 3
    // 3. Validate groupName is not empty and 1-50 characters
    // 4. Add current user to members array if not already included
    // 5. Create new chat document with isGroupChat: true and groupName
    // 6. Return new chatID
    
    // Post-conditions:
    // - Returns chatID of new group chat
    // - New group chat document written to Firestore
    // - Chat appears in ConversationListView for all members (via existing listener)
}
```

**Implementation Details**:

```swift
/// Creates a new group chat with 3+ members
func createGroupChat(withMembers memberUserIDs: [String], groupName: String) async throws -> String {
    // Validate current user is authenticated
    guard let currentUserID = Auth.auth().currentUser?.uid else {
        print("❌ Cannot create group chat: user not authenticated")
        throw ChatError.notAuthenticated
    }
    
    // Validate group name
    let trimmedName = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedName.isEmpty, trimmedName.count <= 50 else {
        print("❌ Cannot create group chat: invalid group name")
        throw ChatError.invalidGroupName
    }
    
    // Ensure current user is in members array
    var allMembers = memberUserIDs
    if !allMembers.contains(currentUserID) {
        allMembers.append(currentUserID)
    }
    
    // Validate minimum 3 members (including current user)
    guard allMembers.count >= 3 else {
        print("❌ Cannot create group chat: need at least 3 members, got \(allMembers.count)")
        throw ChatError.insufficientMembers
    }
    
    // Create new group chat
    let newChatID = UUID().uuidString
    print("➕ Creating new group chat '\(trimmedName)' with \(allMembers.count) members")
    
    let newChat: [String: Any] = [
        "id": newChatID,
        "members": allMembers,
        "lastMessage": "",
        "lastMessageTimestamp": FieldValue.serverTimestamp(),
        "isGroupChat": true,
        "groupName": trimmedName,
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp()
    ]
    
    try await db.collection("chats").document(newChatID).setData(newChat)
    print("✅ Created new group chat: \(newChatID)")
    
    return newChatID
}
```

#### 2. Update ChatError enum (Add New Cases)

```swift
enum ChatError: LocalizedError {
    case notAuthenticated
    case cannotChatWithSelf
    case invalidUserID
    case invalidGroupName         // NEW
    case insufficientMembers      // NEW
    case firestoreError(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User must be logged in to create chats"
        case .cannotChatWithSelf:
            return "Cannot create a chat with yourself"
        case .invalidUserID:
            return "Invalid user ID provided"
        case .invalidGroupName:
            return "Group name must be 1-50 characters"
        case .insufficientMembers:
            return "Groups require at least 3 members"
        case .firestoreError(let error):
            return "Firestore error: \(error.localizedDescription)"
        }
    }
}
```

### MessageService.swift (Verify Existing Methods)

**File Location**: `Services/MessageService.swift` (already exists from PR #8)

**Verify Existing Method Works for Groups**:

```swift
/// Send a message to a chat (works for both 1-on-1 and group chats)
func sendMessage(chatID: String, text: String) async throws -> String
```

**No changes needed** if the method is already chat-agnostic (operates on any chatID regardless of isGroupChat flag). Verify during implementation that:
- Messages sent to group chats appear for all members
- Real-time listeners (observeMessages) work for all group members
- No group-specific logic needed in MessageService

### UserService.swift (New Helper Method)

**File Location**: `Services/UserService.swift` (already exists from PR #3)

**New Method for Fetching Sender Names**:

```swift
// MARK: - Fetch Multiple User Names

/// Fetches display names for multiple user IDs (for group chat sender display)
/// Returns dictionary mapping userID to displayName
/// - Parameter userIDs: Array of user IDs to fetch names for
/// - Returns: Dictionary [userID: displayName] with "Unknown User" fallback
func fetchUserNames(userIDs: [String]) async -> [String: String] {
    // Implementation: Batch fetch user documents
    // Return dictionary with userID -> displayName mapping
    // Use "Unknown User" for any IDs not found
    // Cache results to avoid repeated queries
}
```

---

## 10. UI Components to Create/Modify

**Modify**:
- `Models/Chat.swift` — Add groupName field (optional String)
- `Services/ChatService.swift` — Add createGroupChat() method, update ChatError enum
- `Services/UserService.swift` — Add fetchUserNames() helper method (optional, for optimization)
- `Views/UserSelection/UserSelectionView.swift` — Add group mode toggle, multi-select checkboxes, "Create Group" button
- `Views/UserSelection/UserRow.swift` — Add checkbox/checkmark for multi-select mode
- `Views/ChatList/ChatView.swift` — Display sender names in group chat mode
- `Views/ChatList/MessageRow.swift` — Show sender name label above/inside message bubble for group messages
- `Views/ChatList/ChatRowView.swift` — Display group name, member count, group indicator icon

**Create**:
- `Views/UserSelection/GroupNamingView.swift` — Modal sheet for naming group chat (NEW)
- `ViewModels/ChatListViewModel.swift` (if needed) — Add group-specific state management (optional)

**No changes to**:
- `Services/MessageService.swift` (should already work for groups, verify only)
- `Services/FirebaseService.swift` (no changes needed)
- `Models/Message.swift` (already has senderID field)
- `Models/User.swift` (no changes needed)

---

## 11. Integration Points

**Firebase Services**:
- **Firestore Database**: Query/write `chats` collection with isGroupChat: true and groupName field
- **Firestore Real-Time Listeners**: Existing snapshot listeners from PR #8 work for groups (no changes)
- **Firebase Auth**: Get current user ID for group membership
- **FieldValue.serverTimestamp()**: Synchronized timestamps for group chat creation

**SwiftUI Integration**:
- **UserSelectionView**: Add mode toggle (1-on-1 vs Group), multi-select checkboxes, "Create Group" button
- **GroupNamingView**: Modal sheet with text field for group name input
- **ChatView/GroupChatView**: Display sender names with messages in group mode
- **MessageRow**: Add sender name label for group messages
- **ChatRowView**: Display group name and member count in conversation list
- **@State**: Manage selected users array, group mode toggle, group name text field
- **Task/async-await**: For async Firestore operations

**Architecture Pattern** (per architecture.md):
- Service layer handles all Firebase logic (ChatService, MessageService)
- Views remain thin wrappers
- State management via SwiftUI @State and @StateObject
- MVVM pattern: Views → Services → Firestore

**Thread Safety** (see Swift Development Rules in .cursorrules):
- All Firestore operations run on background threads automatically
- UI updates wrapped in `DispatchQueue.main.async` or via `@MainActor`
- SwiftUI updates automatically on main thread when @State changes

**Existing Listener Integration**:
- ConversationListView already has ChatService.observeUserChats() listener (PR #6)
- When group chat created → Listener automatically fires → Group appears in list for all members
- MessageService.observeMessages() listener (PR #8) works for groups (all members receive updates)
- No additional listener code needed

**Performance Optimization**:
- Cache sender names locally (in-memory dictionary: [senderID: displayName])
- Fetch sender names once per unique sender, not per message
- Use batch queries for fetching multiple user names (UserService.fetchUserNames())

---

## 12. Manual Validation Plan

**Current**: Manual testing validation (see `Psst/agents/shared-standards.md`)

### Configuration Testing
- [ ] Firebase Firestore connection established
- [ ] Firebase Authentication provides valid user ID
- [ ] Firestore security rules allow read/write access to `chats` collection for group chats
- [ ] Firestore security rules allow read access to `users` collection for fetching sender names
- [ ] All necessary Firebase imports working

### Happy Path Testing - Group Creation
- [ ] **User A logs in**: Opens ConversationListView
- [ ] Gate: "New Chat" button visible in navigation toolbar
- [ ] **User A taps "New Chat"**: UserSelectionView appears
- [ ] Gate: Toggle visible: "1-on-1" vs "Group"
- [ ] **User A toggles to "Group" mode**: Multi-select mode enabled
- [ ] Gate: Checkboxes appear on user rows
- [ ] Gate: "Create Group" button visible at bottom (disabled)
- [ ] **User A selects User B**: Taps row, checkbox appears
- [ ] Gate: Selected count: "1 selected"
- [ ] Gate: "Create Group" button still disabled (need 3+)
- [ ] **User A selects User C and User D**: Taps rows
- [ ] Gate: Selected count: "3 selected"
- [ ] Gate: "Create Group" button enabled
- [ ] **User A taps "Create Group"**: Group naming sheet appears
- [ ] Gate: Modal sheet displays with "Name Your Group" heading
- [ ] Gate: Text field visible for group name input
- [ ] **User A enters group name**: Types "Project Team"
- [ ] Gate: Text field accepts input
- [ ] Gate: Character count validation (1-50 characters)
- [ ] **User A taps "Create"**: Group chat created
- [ ] Gate: Group chat created in Firestore within 500ms
- [ ] Gate: Group chat document includes: members [A, B, C, D], isGroupChat: true, groupName: "Project Team"
- [ ] Gate: GroupChatView opens with empty message list
- [ ] Gate: Header shows "Project Team (4 members)"
- [ ] Gate: UserSelectionView and naming sheet dismiss

### Happy Path Testing - Group Messaging
- [ ] **User A in GroupChatView**: Types "Hello team!" and sends
- [ ] Gate: Message appears instantly in User A's ChatView (optimistic UI)
- [ ] Gate: Message written to Firestore within 100ms
- [ ] **User B, C, D log in**: Open ConversationListView
- [ ] Gate: "Project Team" group appears in all 3 users' conversation lists
- [ ] Gate: Group name displayed correctly
- [ ] Gate: Member count shows "(4 members)"
- [ ] Gate: Last message preview: "User A: Hello team!"
- [ ] **User B opens group chat**: Taps "Project Team" row
- [ ] Gate: GroupChatView opens with message from User A
- [ ] Gate: Message shows sender name: "User A" above/inside bubble
- [ ] Gate: Message text: "Hello team!"
- [ ] Gate: Timestamp displayed
- [ ] **User B sends reply**: Types "Hey User A!" and sends
- [ ] Gate: Message appears instantly in User B's ChatView (optimistic UI)
- [ ] Gate: Message does NOT show sender name for User B (current user)
- [ ] **User A receives User B's message**: Real-time update
- [ ] Gate: Message appears in User A's ChatView within 100ms
- [ ] Gate: Sender name "User B" displayed above message
- [ ] Gate: Message text: "Hey User A!"
- [ ] **User C and D open group**: Both see full conversation
- [ ] Gate: Both messages visible with correct sender names
- [ ] Gate: User A's message shows "User A"
- [ ] Gate: User B's message shows "User B"

### Group Name Validation Testing
- [ ] **User creates group**: Selects 3+ contacts, taps "Create Group"
- [ ] **User leaves group name empty**: Text field blank
- [ ] Gate: "Create" button disabled or shows validation alert
- [ ] Gate: Alert: "Please enter a group name"
- [ ] **User enters 1 character**: Types "A"
- [ ] Gate: "Create" button enabled (minimum 1 character)
- [ ] **User enters 50 characters**: Types max-length name
- [ ] Gate: Text field accepts 50 characters
- [ ] Gate: "Create" button enabled
- [ ] **User enters 51+ characters**: Types beyond limit
- [ ] Gate: Text field truncates to 50 characters OR validation prevents typing
- [ ] **User enters whitespace only**: Types "   "
- [ ] Gate: Validation alert: "Please enter a group name" (trimmed = empty)
- [ ] **User enters name with special characters**: "Team 🚀 Project 2025!"
- [ ] Gate: Text field accepts emojis and special characters
- [ ] Gate: Group created successfully with special characters in name

### Insufficient Members Testing
- [ ] **User toggles to Group mode**: Multi-select enabled
- [ ] **User selects only 1 contact**: Taps 1 user
- [ ] Gate: "Create Group" button disabled
- [ ] Gate: Message: "Select 3 or more members" (or similar)
- [ ] **User selects 2 contacts**: Taps second user
- [ ] Gate: "Create Group" button still disabled
- [ ] Gate: Message: "Select 3 or more members"
- [ ] **User selects 3rd contact**: Taps third user
- [ ] Gate: "Create Group" button enabled
- [ ] Gate: Message updates: "3 selected"

### Sender Name Display Testing
- [ ] **Group chat with 5 members**: User A, B, C, D, E
- [ ] **User A sends message**: "Hello from A"
- [ ] Gate: User A sees message WITHOUT sender name (or "You")
- [ ] **User B receives message**: Opens group chat
- [ ] Gate: Message displays "User A" as sender
- [ ] **User C, D, E receive message**: Open group chat
- [ ] Gate: All see "User A" as sender
- [ ] **User B sends message**: "Reply from B"
- [ ] Gate: User B sees message WITHOUT sender name
- [ ] Gate: User A, C, D, E see "User B" as sender
- [ ] **Multiple messages from different senders**:
  - User A: "Message 1"
  - User B: "Message 2"
  - User A: "Message 3"
  - User C: "Message 4"
- [ ] Gate: Each message shows correct sender name
- [ ] Gate: Sender names cached (not fetched repeatedly for same sender)

### Conversation List Group Display Testing
- [ ] **User has mix of 1-on-1 and group chats**
- [ ] Gate: Group chats display group name (not member names)
- [ ] Gate: Group chats show member count "(X members)"
- [ ] Gate: Group chats show group indicator/icon
- [ ] Gate: Last message preview: "[Sender Name]: Message text"
- [ ] Gate: 1-on-1 chats display other user's name (no group indicator)
- [ ] Gate: Sorted by lastMessageTimestamp (most recent first)
- [ ] **User sends message in group**: Group chat moves to top of list
- [ ] Gate: Real-time update (conversation list reorders)

### Edge Cases Testing
- [ ] **Sender user deleted/not found**: User document missing in Firestore
- [ ] Gate: Message displays "Unknown User" as sender
- [ ] Gate: No crashes or UI errors
- [ ] **Group with 10+ members**: Create large group
- [ ] Gate: All members receive messages within 100ms
- [ ] Gate: No performance degradation
- [ ] Gate: Smooth scrolling through message list
- [ ] **Very long group name**: 50 characters
- [ ] Gate: Group name displays without truncation issues in header
- [ ] Gate: Conversation list handles long name with ellipsis if needed
- [ ] **Empty last message**: Group created but no messages sent yet
- [ ] Gate: Conversation list shows "No messages yet" or similar placeholder
- [ ] **Rapid message sending in group**: Multiple users send simultaneously
- [ ] Gate: All messages appear in correct order (by timestamp)
- [ ] Gate: Sender names display correctly for each message
- [ ] Gate: No race condition errors

### Network & Offline Testing
- [ ] **User creates group offline**: No internet connection
- [ ] Gate: Error message: "Unable to create group. Check your connection."
- [ ] Gate: Retry button available
- [ ] **User sends message in group offline**: No internet
- [ ] Gate: Message queued locally (handled by PR #10 offline persistence)
- [ ] Gate: Message sends automatically when connection restored
- [ ] **User opens group chat offline**: Previously loaded group
- [ ] Gate: Group chat displays with cached messages (Firestore offline cache)
- [ ] Gate: Sender names display from cache

### 1-on-1 Chat Compatibility Testing
- [ ] **User toggles to "1-on-1" mode**: Default mode
- [ ] Gate: Single-select behavior (same as PR #9)
- [ ] Gate: No checkboxes, tapping row creates 1-on-1 chat
- [ ] **User creates 1-on-1 chat**: Selects single contact
- [ ] Gate: Duplicate check runs (PR #9 logic)
- [ ] Gate: Chat created with isGroupChat: false, no groupName
- [ ] Gate: ChatView displays without sender names (same as before)
- [ ] **User has existing 1-on-1 chats**: From PR #9
- [ ] Gate: All existing chats display correctly (no regressions)
- [ ] Gate: Conversation list shows mix of 1-on-1 and group chats

### Performance Testing (see shared-standards.md)
- [ ] **Group chat creation**: Measure time from "Create" tap to ChatView loaded
- [ ] Gate: < 3 seconds total (multi-select → name → ChatView)
- [ ] Gate: < 500ms for Firestore write operation
- [ ] **Message delivery in group**: Measure time from send to all recipients receive
- [ ] Gate: < 100ms latency across all group members
- [ ] **Sender name display**: Measure time to fetch and render sender name
- [ ] Gate: < 50ms per unique sender (first fetch)
- [ ] Gate: < 10ms for cached sender names (subsequent messages)
- [ ] **Scrolling performance**: Scroll through 100+ group messages rapidly
- [ ] Gate: Smooth 60fps, no janky scrolling (LazyVStack)
- [ ] **Large group (10+ members)**: Send messages in group with 10+ members
- [ ] Gate: No performance degradation
- [ ] Gate: Real-time sync still < 100ms

### Visual State Verification
- [ ] No console errors during group creation
- [ ] No console errors during group messaging
- [ ] No console errors during sender name fetching
- [ ] "Group" mode toggle clearly visible and labeled
- [ ] Checkboxes/checkmarks visible in multi-select mode
- [ ] "Create Group" button clearly visible and labeled
- [ ] Group naming sheet displays smoothly (modal animation)
- [ ] Group name text field has clear placeholder text
- [ ] Sender names render clearly above/inside message bubbles
- [ ] Group indicator/icon distinguishes groups from 1-on-1 chats in list
- [ ] Member count displays correctly in conversation list and chat header
- [ ] GroupChatView header shows group name prominently

---

## 13. Definition of Done

See standards in `Psst/agents/shared-standards.md`:

- [ ] Chat model updated with optional groupName field
- [ ] ChatService.createGroupChat() implemented with validation (3+ members, 1-50 char name)
- [ ] ChatError enum updated with new error cases (invalidGroupName, insufficientMembers)
- [ ] UserSelectionView extended with group mode toggle and multi-select
- [ ] UserRow updated with checkbox/checkmark for multi-select mode
- [ ] GroupNamingView created for group name input
- [ ] ChatView/GroupChatView displays sender names in group mode
- [ ] MessageRow shows sender name label for group messages (not current user)
- [ ] ChatRowView displays group name, member count, group indicator
- [ ] UserService.fetchUserNames() helper method implemented (optional, for optimization)
- [ ] Sender name caching implemented to reduce Firestore queries
- [ ] Error handling for all failure cases (auth, network, validation)
- [ ] Loading states implemented (creating group, fetching sender names)
- [ ] Validation implemented (3+ members, 1-50 char name)
- [ ] All acceptance gates pass
- [ ] Manual testing completed (group creation, messaging, sender names, multi-device)
- [ ] Performance targets met (< 3 second group creation, < 100ms message delivery)
- [ ] Existing 1-on-1 chat flow (PR #9) still works (no regressions)
- [ ] No console warnings or errors
- [ ] Code follows `Psst/agents/shared-standards.md` patterns
- [ ] PR created targeting develop branch

---

## 14. Risks & Mitigations

**Risk: Sender name fetching causes UI lag with many unique senders**
- **Mitigation**: Implement in-memory caching ([senderID: displayName] dictionary). Fetch each sender name only once, reuse for all subsequent messages. For 10 unique senders in 100 messages, only 10 Firestore queries vs 100.

**Risk: Group messages appear out of order due to timestamp sync issues**
- **Mitigation**: Already using FieldValue.serverTimestamp() from PR #5. Firestore's server timestamps ensure consistent ordering across all devices. Messages sorted by timestamp.

**Risk: Large groups (20+ members) cause performance issues**
- **Mitigation**: For MVP, assume < 20 members per group. Firestore handles real-time sync efficiently. If performance issues arise, future optimization: pagination, message batching.
- **Testing**: Verify with 10-member group during manual testing.

**Risk: User selects deleted/invalid users for group creation**
- **Mitigation**: For MVP, assume users in `users` collection are valid. Future: Add validation to check all member user documents exist before creating group.

**Risk: Group naming sheet dismissed accidentally (user loses progress)**
- **Mitigation**: "Cancel" button clearly labeled. Future: Add confirmation alert "Discard group creation?" if name partially entered.

**Risk: Sender names don't display if Firestore query fails**
- **Mitigation**: Fallback to "Unknown User" if fetch fails. Cache names to reduce query failures. Log errors to console for debugging.

**Risk: Existing 1-on-1 chat flow (PR #9) breaks with group mode changes**
- **Mitigation**: Keep 1-on-1 and group creation logic separate. Default mode is "1-on-1", group mode is opt-in toggle. Test both flows thoroughly.

**Risk: Message bubbles with sender names become cluttered/hard to read**
- **Mitigation**: Use clear visual hierarchy: sender name (small, gray text above bubble), message text (normal size), timestamp (small, gray text below). Test with multiple senders to ensure readability.

**Risk: Group chat appears multiple times in conversation list (for each member)**
- **Mitigation**: Firestore query `.whereField("members", arrayContains: currentUserID)` returns each chat once per user. No duplication possible (each chat document has unique ID).

---

## 15. Rollout & Telemetry

**Feature Flag**: No

**Metrics (Manual Observation)**:
- Count successful group creations vs failures during testing
- Measure time from "Create" tap to GroupChatView loaded
- Measure message delivery latency (send to all recipients receive)
- Verify sender names display correctly for all group messages
- Confirm no regressions in 1-on-1 chat flow

**Manual Validation Steps**:
1. Log in as User A
2. Tap "New Chat" → Toggle to "Group" mode
3. Select User B, C, D (3 contacts)
4. Tap "Create Group"
5. Enter group name "Test Group"
6. Tap "Create"
7. Verify GroupChatView loads with header "Test Group (4 members)"
8. Send message "Hello everyone!"
9. Log in as User B on different device
10. Verify "Test Group" appears in conversation list
11. Open group chat
12. Verify message from User A appears with sender name "User A"
13. Send reply "Hi from User B"
14. Log in as User C, D on additional devices
15. Verify all users see both messages with correct sender names
16. Verify User A and User B's own messages do NOT show sender names

**Logging Strategy**:
```swift
// Add debug logs for monitoring
print("➕ Creating group chat: '\(groupName)' with \(members.count) members")
print("✅ Group chat created: \(chatID)")
print("🔍 Fetching sender name for: \(senderID)")
print("✅ Cached sender name: \(displayName)")
print("⚠️ Sender name not found for \(senderID), using 'Unknown User'")
print("💬 Group message received from \(senderID): \(messageText)")
print("❌ Group chat creation failed: \(error.localizedDescription)")
```

---

## 16. Open Questions

**Q1**: Should group chats have a maximum member limit?
- **Answer**: For MVP, no enforced limit (assume < 50 members). Future: Add validation for max 50 or 100 members if performance becomes an issue.

**Q2**: Should users be able to add/remove members after group creation?
- **Answer**: Out of scope for this PR. Deferred to future "Group Administration" feature. For MVP, group membership is fixed at creation.

**Q3**: Should group chats have profile pictures/icons?
- **Answer**: Basic placeholder group icon for MVP. Deferred to future PR for custom group icons/photos.

**Q4**: How should sender names be displayed in message bubbles?
- **Answer**: Small label above message bubble (outside bubble) for left-aligned messages (not current user). Current user's messages (right-aligned) omit sender name or show "You".

**Q5**: Should we show read receipts for each group member individually?
- **Answer**: Deferred to PR #14 (read receipts). For this PR, focus on basic group messaging and sender identification.

**Q6**: Should typing indicators work in group chats?
- **Answer**: Deferred to PR #13 (typing indicators). For this PR, focus on message sending/receiving only.

**Q7**: Should users be able to leave a group chat?
- **Answer**: Out of scope for this PR. Deferred to future "Group Administration" feature.

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future PRs:

- [ ] Group administration (add/remove members, leave group, delete group)
- [ ] Custom group profile pictures/icons
- [ ] Group descriptions or metadata beyond name
- [ ] @ mentions or tagging specific group members in messages
- [ ] Group chat settings (mute notifications, rename group)
- [ ] Group permissions/roles (admin, moderator, member)
- [ ] Maximum group size enforcement (if needed)
- [ ] Forwarding messages to groups
- [ ] Pinning group chats to top of conversation list
- [ ] Archiving group chats
- [ ] Search within group messages
- [ ] Export group chat history
- [ ] Group invitations via link
- [ ] Public/private group chat settings
- [ ] Automated unit tests (deferred to backlog)
- [ ] Integration tests (deferred to backlog)

---

## Preflight Questionnaire

1. **Smallest end-to-end user outcome for this PR?**
   - User can select 3+ contacts, name a group, and immediately start messaging all members with sender names clearly displayed.

2. **Primary user and critical action?**
   - Primary user: Any authenticated user wanting to coordinate with 3+ people
   - Critical action: Create group → Send messages → See who said what (sender identification)

3. **Must-have vs nice-to-have?**
   - Must-have: Multi-select, group creation, group naming, sender name display, real-time sync for all members
   - Nice-to-have: Group icons, add/remove members, group settings (deferred to future)

4. **Real-time requirements?** (see shared-standards.md)
   - Group chat creation: < 500ms
   - Message delivery to all group members: < 100ms
   - Sender name display: < 50ms (first fetch), < 10ms (cached)
   - Group appears in conversation list for all members immediately (via existing listener)

5. **Performance constraints?** (see shared-standards.md)
   - Total group creation flow: < 3 seconds (multi-select → name → ChatView)
   - Message latency: < 100ms to all group members
   - Sender name caching to minimize Firestore queries
   - Smooth 60fps scrolling through group messages
   - No UI blocking (async operations)

6. **Error/edge cases to handle?**
   - Insufficient members (< 3 selected)
   - Empty group name
   - Very long group name (> 50 characters)
   - Sender user not found (display "Unknown User")
   - Network failure during group creation
   - Large groups (10+ members) performance
   - Rapid message sending by multiple users
   - Offline message queueing (handled by PR #10)

7. **Data model changes?**
   - Add `groupName` field (optional String) to Chat model
   - Update Chat.toDictionary() to include groupName
   - Update ChatError enum with new cases (invalidGroupName, insufficientMembers)
   - No changes to Message model (already has senderID)

8. **Service APIs required?**
   - `ChatService.createGroupChat(withMembers:groupName:) async throws -> String`
   - `UserService.fetchUserNames(userIDs:) async -> [String: String]` (optional optimization)
   - Verify `MessageService.sendMessage()` works for groups (should already)

9. **UI entry points and states?**
   - Entry: "New Chat" button → UserSelectionView → Toggle to "Group" mode
   - States: Multi-select users, Group naming, Creating group, Messaging in group
   - Exit: Navigate to GroupChatView, dismiss UserSelectionView and naming sheet

10. **Security/permissions implications?**
    - Firestore security rules must allow authenticated users to create group chats
    - Firestore security rules must allow group members to read/write messages
    - Firestore security rules must allow reading `users` collection for sender names
    - Rules validation deferred to PR completion

11. **Dependencies or blocking integrations?**
    - Depends on: PR #9 (UserSelectionView foundation), PR #8 (MessageService real-time), PR #6 (ConversationListView listener), PR #5 (Chat/Message models), PR #3 (User model)
    - Blocks: PR #13 (Typing indicators in groups), PR #14 (Read receipts in groups)

12. **Rollout strategy and metrics?**
    - Manual testing with 3+ users creating and messaging in groups
    - Verify sender names display correctly
    - Measure latency with timer logs
    - Confirm real-time sync across all members

13. **What is explicitly out of scope?**
    - Group administration, custom icons, @ mentions, group settings, permissions, max size enforcement, automated tests

---

## Authoring Notes

- This PR extends PR #9's UserSelectionView to support multi-user selection
- Group chat data model (isGroupChat: true) already exists from PR #5 - just needs groupName field added
- Sender name display is critical for usability - without it, group chats are confusing
- Performance: Cache sender names aggressively to avoid repeated Firestore queries (10 queries for 10 senders, not 100 queries for 100 messages)
- MessageService from PR #8 should work for groups without changes (operates on chatID, agnostic to chat type)
- Follow architecture.md: Services handle Firebase logic, Views stay thin
- Use async/await for clean async code
- Per Swift threading rules: Firestore callbacks already on main thread, SwiftUI updates automatic
- Reference shared-standards.md for performance targets (< 100ms message delivery)
- Test with multiple devices to verify real-time sync for all group members
- Ensure 1-on-1 chat flow (PR #9) still works - no regressions
- Empty states and loading states important for good UX
- Sender name caching pattern: Check cache → Fetch if missing → Store in cache → Display

