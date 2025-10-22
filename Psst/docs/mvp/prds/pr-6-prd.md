# PRD: Conversation List Screen

**Feature**: conversation-list-screen

**Version**: 1.0

**Status**: Draft

**Agent**: Pam

**Target Release**: Phase 2 - 1-on-1 Chat

**Links**: [PR Brief](../pr-briefs.md#pr-6-conversation-list-screen) | [TODO](../todos/pr-6-todo.md) | [Architecture](../architecture.md)

---

## 1. Summary

Build the main Conversation List screen that displays all user chats in a scrollable list with real-time Firestore listeners. Users see chat previews (other user's name, last message, timestamp) and can tap to open conversations. This is the primary entry point for all messaging interactions.

---

## 2. Problem & Goals

**Problem**: Users need a centralized view to see all their active conversations, monitor incoming messages, and quickly access any chat.

**Why now**: Phase 2 foundation. This is the home screen after authentication and enables PR #7 (chat view), PR #8 (messaging), and PR #12 (start new chat).

**Goals**:
- [ ] G1 — Display all user chats sorted by most recent activity
- [ ] G2 — Real-time sync: new messages appear instantly without refresh
- [ ] G3 — Handle empty state gracefully (no conversations yet)
- [ ] G4 — Fast, smooth scrolling performance (60fps with 100+ chats per shared-standards.md)

---

## 3. Non-Goals / Out of Scope

- [ ] Not implementing chat creation UI (PR #12)
- [ ] Not implementing message sending (PR #8)
- [ ] Not implementing presence indicators (PR #15)
- [ ] Not implementing typing indicators (PR #16)
- [ ] Not implementing search functionality (PR #22)
- [ ] Not implementing swipe actions (delete, archive - future)
- [ ] Not implementing unread badges (future enhancement)
- [ ] Not implementing automated tests (deferred to backlog)

**Note**: Mock data will be created for testing purposes (see Section 12)

---

## 4. Success Metrics

**User-visible**:
- User lands on screen → sees chats in < 1 second
- New message arrives → updates list in < 100ms
- User scrolls 100+ chats → smooth 60fps (per shared-standards.md)
- User taps chat → navigates to conversation in < 50ms

**System**:
- Firestore listener updates < 100ms (per shared-standards.md)
- App cold start to chat list visible < 2-3 seconds (per shared-standards.md)
- Offline: Previously loaded chats visible instantly

**Quality**:
- 0 blocking bugs
- All acceptance gates pass
- Manual testing complete (configuration, user flows, multi-device, offline)
- No console warnings

---

## 5. Users & Stories

- As a **user**, I want to see all my conversations in one place so I can quickly find and open any chat
- As a **user**, I want the most recent chat at the top so I don't miss important messages
- As a **user**, I want to see the last message preview so I know what the conversation is about
- As a **user**, I want real-time updates so I see new messages without manually refreshing
- As a **user**, I want an empty state message when I have no chats so I know the app is working correctly

---

## 6. Experience Specification (UX)

**Entry points**:
- User completes authentication → lands on Conversation List (NavigationView root)
- User finishes chat conversation → returns to Conversation List
- User taps tab bar "Chats" tab → navigates to Conversation List

**Visual behavior**:
- Screen title: "Messages" or "Chats"
- List of chat rows (LazyVStack for performance per shared-standards.md)
- Each row shows:
  - Other user's name (or "Group Chat" + member count)
  - Last message preview text (1 line, truncated)
  - Timestamp (relative: "2m ago", "Yesterday", "Jan 15")
- Empty state: Centered icon + "No conversations yet" + "Tap + to start chatting"
- Pull-to-refresh gesture (triggers manual Firestore refresh)

**Loading states**:
- Initial load: ProgressView spinner in center
- Refreshing: Standard iOS spinner at top
- Error: Alert with retry button

**Performance** (per shared-standards.md):
- Scroll 60fps with 100+ chats (use LazyVStack)
- Real-time updates < 100ms
- Tap response < 50ms
- No main thread blocking

---

## 7. Functional Requirements (Must/Should)

**MUST**:
- MUST fetch all chats where current user is a member
- MUST use Firestore snapshot listener for real-time updates
- MUST sort chats by lastMessageTimestamp descending (newest first)
- MUST display chat preview info: name, last message, timestamp
- MUST handle empty state (no chats)
- MUST implement pull-to-refresh
- MUST use LazyVStack for performance
- MUST navigate to ChatView on tap
- MUST work offline with cached data

**SHOULD**:
- SHOULD show loading spinner on initial load
- SHOULD format timestamps (relative for recent, absolute for old)
- SHOULD truncate long last messages with "..."
- SHOULD handle 1-on-1 vs group chat display logic

**Acceptance gates**:
- [Gate] User opens app → sees chat list in < 1 second
- [Gate] New message sent (Device B) → appears in list on Device A in < 100ms
- [Gate] No chats exist → empty state displays with message and icon
- [Gate] User pulls to refresh → spinner shows, list updates
- [Gate] User taps chat row → navigates to ChatView
- [Gate] Offline: User opens app → sees previously loaded chats
- [Gate] Scroll 100+ chats → maintains 60fps
- [Gate] Chat deleted → immediately removed from list
- [Gate] 1-on-1 chat → displays other user's name
- [Gate] Group chat → displays "Group Chat (3)" or member names

---

## 8. Data Model

**Uses existing models from PR #5**:
- `Chat` model (id, members, lastMessage, lastMessageTimestamp, isGroupChat)
- `User` model (from PR #3 - for fetching display names)

**No new models created in this PR.**

**Firestore queries**:
```swift
// Fetch chats where current user is a member
db.collection("chats")
  .whereField("members", arrayContains: currentUserID)
  .order(by: "lastMessageTimestamp", descending: true)
  .addSnapshotListener { snapshot, error in
    // Real-time updates
  }
```

**Firestore indexes needed** (Firestore automatically creates):
- Collection: `chats`
- Fields: `members` (array), `lastMessageTimestamp` (descending)

---

## 9. API / Service Contracts

**ChatService (to be created in Services/ChatService.swift)**:

```swift
// Observe all chats for current user
func observeUserChats(userID: String, completion: @escaping ([Chat]) -> Void) -> ListenerRegistration

// Fetch user display name (for chat row)
func fetchUserName(userID: String) async throws -> String

// Get chat by ID (for navigation)
func fetchChat(chatID: String) async throws -> Chat
```

**Pre/post-conditions**:
- Pre: User must be authenticated (userID not nil)
- Pre: Firestore connection available (offline cache enabled)
- Post: Returns sorted chats by lastMessageTimestamp
- Post: Listener updates automatically on remote changes

**Error handling**:
- Firebase auth errors → Show alert, logout user
- Network errors → Use cached data, show offline indicator
- Missing user data → Display "Unknown User"
- Empty result → Show empty state UI

---

## 10. UI Components to Create/Modify

**Files to Create**:
- `Views/ChatList/ChatListView.swift` — Main conversation list screen
- `Views/ChatList/ChatRowView.swift` — Individual chat preview row
- `ViewModels/ChatListViewModel.swift` — Manages chat list state and Firestore listener
- `Services/ChatService.swift` — Firestore operations for chats collection
- `Services/MockDataService.swift` — DEBUG-only service to seed test data (remove in PR #8)

**Files to Modify**:
- `ContentView.swift` or navigation root — Set ChatListView as main tab/view after auth

**Component hierarchy**:
```
ChatListView (NavigationView)
├── List or ScrollView + LazyVStack
│   └── ForEach(chats)
│       └── ChatRowView(chat: chat)
│           ├── HStack
│           │   ├── Circle (profile placeholder)
│           │   ├── VStack (name + last message)
│           │   └── VStack (timestamp)
└── Empty state (if chats.isEmpty)
```

---

## 11. Integration Points

- **Firebase Authentication**: Get current user ID
- **Firestore Database**: Query `chats` collection, snapshot listeners
- **Firestore Offline Persistence**: Cached chats available offline
- **SwiftUI Navigation**: NavigationLink to ChatView (PR #7)
- **State Management**: @StateObject ChatListViewModel, @Published chats array
- **Architecture**: MVVM pattern (per architecture.md)

---

## 12. Manual Validation Plan

**Current**: Manual testing validation (see `Psst/agents/shared-standards.md`)  
**Future**: Automated testing recommendations in `Psst/docs/testing-strategy.md`

### Mock Data Setup

**Why**: PR #8 (message sending) and PR #12 (chat creation) don't exist yet, so we need sample data to test the UI.

**Approach**: Debug button in ChatListView that seeds Firestore with sample data.

**Implementation**:

1. Create `Services/MockDataService.swift`:
```swift
#if DEBUG
import Foundation
import FirebaseFirestore

class MockDataService {
    private let db = Firestore.firestore()
    
    func seedMockData(currentUserID: String) async throws {
        // Create mock users
        let mockUsers = [
            ["uid": "mock_user_1", "displayName": "Alice Johnson", "email": "alice@example.com"],
            ["uid": "mock_user_2", "displayName": "Bob Smith", "email": "bob@example.com"],
            ["uid": "mock_user_3", "displayName": "Carol White", "email": "carol@example.com"],
            ["uid": "mock_user_4", "displayName": "David Brown", "email": "david@example.com"]
        ]
        
        for user in mockUsers {
            try await db.collection("users").document(user["uid"] as! String).setData(user)
        }
        
        // Create mock chats
        let chat1 = [
            "id": "mock_chat_1",
            "members": [currentUserID, "mock_user_1"],
            "lastMessage": "Hey, how are you?",
            "lastMessageTimestamp": Timestamp(date: Date().addingTimeInterval(-7200)), // 2 hours ago
            "isGroupChat": false,
            "createdAt": Timestamp(date: Date().addingTimeInterval(-86400)), // 1 day ago
            "updatedAt": Timestamp(date: Date().addingTimeInterval(-7200))
        ] as [String: Any]
        
        let chat2 = [
            "id": "mock_chat_2",
            "members": [currentUserID, "mock_user_2"],
            "lastMessage": "See you tomorrow!",
            "lastMessageTimestamp": Timestamp(date: Date().addingTimeInterval(-300)), // 5 minutes ago
            "isGroupChat": false,
            "createdAt": Timestamp(date: Date().addingTimeInterval(-259200)), // 3 days ago
            "updatedAt": Timestamp(date: Date().addingTimeInterval(-300))
        ] as [String: Any]
        
        let chat3 = [
            "id": "mock_chat_3",
            "members": [currentUserID, "mock_user_3", "mock_user_4"],
            "lastMessage": "Group meeting at 3pm",
            "lastMessageTimestamp": Timestamp(date: Date().addingTimeInterval(-3600)), // 1 hour ago
            "isGroupChat": true,
            "createdAt": Timestamp(date: Date().addingTimeInterval(-604800)), // 1 week ago
            "updatedAt": Timestamp(date: Date().addingTimeInterval(-3600))
        ] as [String: Any]
        
        try await db.collection("chats").document("mock_chat_1").setData(chat1)
        try await db.collection("chats").document("mock_chat_2").setData(chat2)
        try await db.collection("chats").document("mock_chat_3").setData(chat3)
    }
    
    func clearMockData() async throws {
        // Delete mock users
        let mockUserIDs = ["mock_user_1", "mock_user_2", "mock_user_3", "mock_user_4"]
        for userID in mockUserIDs {
            try await db.collection("users").document(userID).delete()
        }
        
        // Delete mock chats
        let mockChatIDs = ["mock_chat_1", "mock_chat_2", "mock_chat_3"]
        for chatID in mockChatIDs {
            try await db.collection("chats").document(chatID).delete()
        }
    }
}
#endif
```

2. Add debug button to ChatListView:
```swift
#if DEBUG
@State private var showMockDataAlert = false
@State private var mockDataMessage = ""

// In toolbar
.toolbar {
    ToolbarItem(placement: .navigationBarTrailing) {
        Menu {
            Button("Seed Mock Data") {
                Task {
                    guard let userID = Auth.auth().currentUser?.uid else { return }
                    do {
                        try await MockDataService().seedMockData(currentUserID: userID)
                        mockDataMessage = "✅ Mock data seeded successfully"
                        showMockDataAlert = true
                    } catch {
                        mockDataMessage = "❌ Error: \(error.localizedDescription)"
                        showMockDataAlert = true
                    }
                }
            }
            Button("Clear Mock Data", role: .destructive) {
                Task {
                    do {
                        try await MockDataService().clearMockData()
                        mockDataMessage = "✅ Mock data cleared"
                        showMockDataAlert = true
                    } catch {
                        mockDataMessage = "❌ Error: \(error.localizedDescription)"
                        showMockDataAlert = true
                    }
                }
            }
        } label: {
            Image(systemName: "hammer.fill")
        }
    }
}
.alert("Mock Data", isPresented: $showMockDataAlert) {
    Button("OK", role: .cancel) { }
} message: {
    Text(mockDataMessage)
}
#endif
```

**Benefits**:
- ✅ One-tap data seeding (no manual Firebase Console work)
- ✅ Consistent test data across team
- ✅ Can reset/clear data easily
- ✅ Only compiles in DEBUG builds (won't ship to production)
- ✅ Success/error feedback via alerts
- ✅ Easy to modify data structure as needed
- ✅ Useful for PR #7 (Chat View) and PR #8 (Messaging) testing

**Cleanup**: Remove `MockDataService.swift` and `#if DEBUG` toolbar code in PR #8 (when real messaging works).

### Configuration Testing
- [ ] Firebase Authentication works (user can log in)
- [ ] Firestore database connection established
- [ ] Firestore persistence enabled (settings.isPersistenceEnabled = true)
- [ ] Navigation from auth to chat list works
- [ ] Debug toolbar button visible (hammer icon in top-right)

### Happy Path Testing
- [ ] User logs in → lands on ChatListView
- [ ] Empty state displays ("No conversations yet")
- [ ] User taps hammer icon → "Seed Mock Data" and "Clear Mock Data" options appear
- [ ] User taps "Seed Mock Data" → Alert shows "✅ Mock data seeded successfully"
- [ ] User dismisses alert → 3 chats appear in list
- [ ] Screen displays "Messages" title
- [ ] Each row shows: name, last message, timestamp
- [ ] Chats sorted by most recent first (Bob Smith at top - 5min ago)
- [ ] User taps chat → navigates to ChatView (placeholder OK for now)
- [ ] User pulls to refresh → updates list
- [ ] User taps hammer → "Clear Mock Data" → Alert shows "✅ Mock data cleared"
- [ ] User dismisses alert → chats removed, empty state shows

### Edge Cases Testing
- [ ] No chats exist → empty state displays
- [ ] User has 1 chat → displays correctly
- [ ] User has 100+ chats → smooth scrolling (60fps)
- [ ] Long last message text → truncates with "..."
- [ ] Very old timestamp → displays date (not relative time)
- [ ] Missing user data → displays "Unknown User"
- [ ] Invalid chat data → skips gracefully, no crash

### Multi-Device Testing
- [ ] Device A: Seed mock data using debug button
- [ ] Device B: Open app → mock chats appear automatically (< 100ms)
- [ ] Device A: Manually update a chat's lastMessage in Firebase Console
- [ ] Device B: Chat list updates in < 100ms
- [ ] Device B: Chat moves to top of list
- [ ] Device B: Last message preview updates
- [ ] Timestamp updates accordingly

### Offline Behavior Testing
- [ ] User opens app offline → sees previously loaded chats
- [ ] User scrolls offline chats → works smoothly
- [ ] User taps chat offline → navigation works
- [ ] User goes online → listener reconnects, updates list

### Performance Testing (per shared-standards.md)
- [ ] App cold start → chat list visible in < 2-3 seconds
- [ ] Scroll 100+ chats → maintains 60fps
- [ ] Listener update → UI updates in < 100ms
- [ ] Tap chat → navigation in < 50ms
- [ ] Pull to refresh → completes in < 2 seconds

---

## 13. Definition of Done

- [ ] ChatListView.swift created with NavigationView structure
- [ ] ChatRowView.swift created with name/message/timestamp
- [ ] ChatListViewModel.swift created with @Published chats array
- [ ] ChatService.swift created with observeUserChats method
- [ ] MockDataService.swift created with seedMockData/clearMockData methods (DEBUG only)
- [ ] Debug toolbar button added to ChatListView (hammer icon menu)
- [ ] Firestore snapshot listener implemented
- [ ] Mock data seeding tested (tap button → 3 chats appear)
- [ ] Mock data clearing tested (tap button → chats removed)
- [ ] Real-time sync verified across 2+ devices (< 100ms) using mock data
- [ ] Empty state implemented and tested
- [ ] Pull-to-refresh implemented
- [ ] Offline persistence tested (cached chats visible)
- [ ] LazyVStack used for performance
- [ ] Navigation to ChatView implemented (even if placeholder)
- [ ] All acceptance gates pass
- [ ] Manual testing completed (configuration, user flows, multi-device, offline)
- [ ] No console warnings
- [ ] Code follows shared-standards.md patterns
- [ ] PR merged to develop

---

## 14. Risks & Mitigations

**Risk**: Listener not updating in real-time → **Mitigation**: Test snapshot listener carefully; verify Firestore rules allow reads

**Risk**: Poor scroll performance with many chats → **Mitigation**: Use LazyVStack (per shared-standards.md); test with 100+ items

**Risk**: Timestamp formatting inconsistent → **Mitigation**: Create Date extension for relative time formatting

**Risk**: Missing user names (user document not found) → **Mitigation**: Handle gracefully with "Unknown User" fallback

**Risk**: Listener memory leak → **Mitigation**: Store ListenerRegistration, call remove() in onDisappear

**Risk**: Race condition (chat updates before user fetch) → **Mitigation**: Use async/await properly; handle nil usernames

---

## 15. Rollout & Telemetry

**Feature Flag**: N/A (core feature)

**Manual Validation Steps**:
1. Log in → Verify chat list appears
2. Send message from another device → Verify real-time update
3. Toggle airplane mode → Verify offline chats load
4. Scroll 50+ chats → Verify smooth performance
5. Pull to refresh → Verify updates
6. Tap chat → Verify navigation

**Metrics** (manual observation):
- App load time (stopwatch)
- Listener update latency (send message, observe delay)
- Scroll fps (visual inspection, Instruments if available)

---

## 16. Open Questions

- **Q1**: Show unread badge? → **Decision**: Defer to future PR (requires read tracking)
- **Q2**: Show typing indicator in list? → **Decision**: No, only in ChatView (PR #16)
- **Q3**: Group chat display format? → **Decision**: "Group Chat (3)" for now; custom names in PR #13
- **Q4**: Profile pictures? → **Decision**: Placeholder circles for now; images in PR #21

---

## 17. Appendix: Out-of-Scope Backlog

**Features Deferred**:
- [ ] Unread message badges (future)
- [ ] Swipe to delete/archive (future)
- [ ] Search chats (PR #22)
- [ ] Pinned chats (future)
- [ ] Chat mute/notification settings (future)
- [ ] Profile pictures (PR #21)
- [ ] Typing indicator in list (future)

**Testing Deferred** (tracked in `/Psst/docs/backlog.md`):
- [ ] All automated tests (unit, integration, UI, performance)
- [ ] Deferred to PR #25 or Phase 4 testing sprint

---

## Preflight Questionnaire

1. **Smallest outcome?** User sees list of chats, taps to open (even if placeholder)
2. **Primary user?** End user accessing their conversations
3. **Must-have?** Display chats, real-time updates, empty state, navigation
4. **Real-time requirements?** Yes - listener updates < 100ms (shared-standards.md)
5. **Performance?** Yes - 60fps scrolling, < 1s load, < 100ms updates (shared-standards.md)
6. **Error cases?** Offline (cached data), missing users (fallback), empty state
7. **Data model changes?** None (uses Chat from PR #5)
8. **Service APIs?** ChatService.observeUserChats(), fetchUserName()
9. **UI entry points?** Post-auth navigation, main app screen
10. **Security?** Firestore rules: users can only read chats they're members of
11. **Dependencies?** PR #3 (User), PR #4 (Navigation), PR #5 (Chat model)
12. **Rollout?** Manual validation across devices
13. **Out of scope?** Search, delete, presence, typing, unread badges, automated tests

---

## Authoring Notes

- Follow architecture.md MVVM pattern
- Follow shared-standards.md for performance (LazyVStack, 60fps)
- Use ChatListViewModel as @StateObject in view
- ViewModel holds @Published chats array, listener
- Service layer (ChatService) handles all Firestore logic
- Keep view thin (no business logic)
- Test multi-device sync carefully (< 100ms requirement)
- Test offline with airplane mode
- Placeholder navigation to ChatView is acceptable (PR #7 implements full chat screen)
- All testing via manual validation (automated tests deferred to backlog)
- **Mock data**: Create `MockDataService.swift` with debug button in toolbar (hammer icon)
- Wrap all mock code in `#if DEBUG` to prevent shipping to production
- Mock data creates 3 chats: 2 one-on-one, 1 group chat with different timestamps
- Leave MockDataService in place for PR #7-#8 testing, remove when real messaging works
- Mock data will be naturally replaced by real chats once PR #8 (messaging) and PR #12 (chat creation) are complete

