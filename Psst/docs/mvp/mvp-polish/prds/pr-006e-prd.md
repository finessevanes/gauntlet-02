# PRD: New Chat Sheet Redesign

**Feature**: New Chat Sheet UI/UX Overhaul

**Version**: 1.0

**Status**: Ready for Development

**Agent**: Pam (Planning Agent)

**Target Release**: Phase 1 - MVP Polish

**Links**: 
- PR Brief: `Psst/docs/pr-briefs.md` (PR #006E)
- TODO: `Psst/docs/todos/pr-006e-todo.md`
- UX Spec: `Psst/docs/ux-specs/pr-006-ux-spec.md` (section 5)
- Dependencies: PR #006A (design system), PR #006B (main app polish)

---

## 1. Summary

Complete redesign of the New Chat sheet to improve usability and visual polish: move search to top (currently at bottom), modernize segmented control, add selection checkmarks with Done button for groups, implement auto-navigation for 1-on-1 chats, enhance user rows with better spacing and animations, and create a cohesive experience following iOS design patterns.

---

## 2. Problem & Goals

**Problem**: 
The current New Chat sheet has several UX issues: (1) Search bar is at the bottom which is counterintuitive - users expect search at the top; (2) Segmented control uses dated iOS 6 rounded style; (3) No visual feedback when selecting users - unclear what's selected; (4) Same flow for 1-on-1 and group chats is inefficient - 1-on-1 requires unnecessary taps; (5) User rows lack polish with small avatars and inconsistent spacing; (6) No tap animations or visual feedback; (7) "17 users" counter in nav bar is distracting.

**Why Now**: 
This is the fifth and final piece of the app-wide design system overhaul (PR #006A → #006B → #006C → #006D → #006E). The New Chat sheet is a critical user flow - it's how users start conversations. After polishing auth, main app, settings, and profile, the New Chat sheet is the last major interface that needs modernization. It's highly visible and used frequently.

**Goals** (ordered, measurable):
- [ ] **G1** — Move search bar to top (below segmented control) for better discoverability
- [ ] **G2** — Modernize segmented control to current iOS style (not iOS 6 rounded)
- [ ] **G3** — Add visual selection feedback (blue checkmarks) for clear user selection state
- [ ] **G4** — Implement smart behavior: 1-on-1 auto-navigates, groups require Done button
- [ ] **G5** — Enhance user rows with larger avatars (56pt), better spacing, tap animations
- [ ] **G6** — Maintain all existing New Chat functionality with zero regressions

---

## 3. Non-Goals / Out of Scope

To keep this PR focused on UI/UX redesign:

- [ ] **Not changing** user fetching logic or Firebase queries (keep existing)
- [ ] **Not adding** user search functionality beyond existing (alphabetical sort, basic filter)
- [ ] **Not implementing** group chat creation logic changes (use existing)
- [ ] **Not adding** user blocking, favorites, or categories
- [ ] **Not implementing** recent contacts or suggested users
- [ ] **Not adding** QR code scanning or deep linking
- [ ] **Not changing** chat creation backend logic

---

## 4. Success Metrics

**User-visible**:
- New Chat sheet feels modern and intuitive
- Search is discoverable and easy to use
- Clear visual feedback for user selection
- Faster 1-on-1 chat creation (one less tap)
- Smooth, delightful animations

**System** (see `Psst/agents/shared-standards.md`):
- Sheet presents in <50ms
- Search filtering <100ms (debounced 300ms)
- User row tap feedback <16ms (60fps)
- Chat creation <200ms
- Smooth 60fps scrolling (100+ users)

**Quality**:
- 0 regressions in chat creation
- All acceptance gates pass
- Clean UI on all device sizes
- Dark Mode support (automatic)
- No console errors

---

## 5. Users & Stories

**Primary Users**: All app users creating new chats (1-on-1 or group)

**User Stories**:

1. **As a user**, I want to search for contacts quickly so that I can find people to message without scrolling.

2. **As a user**, I want to see which users I've selected so that I know who will be in the group before creating it.

3. **As a user**, I want to start a 1-on-1 chat with one tap so that I can message someone quickly without extra steps.

4. **As a user**, I want to create group chats with clear visual feedback so that I can easily add multiple people.

5. **As a user**, I want smooth, polished animations so that the experience feels professional and modern.

---

## 6. Experience Specification (UX)

### Entry Points

**Conversations Tab**:
- FAB (Floating Action Button) in bottom-right → Presents New Chat sheet
- (or) Nav bar button → Presents New Chat sheet

### Visual Behavior

**New Chat Sheet - Before (Current)**:
```
┌─────────────────────────┐
│ Cancel   New Chat  17 users │ ← "17 users" distracting
│                         │
│  [1-on-1]  [Group]      │ ← Old style segmented
│                         │
│ Alice Johnson           │ ← No selection feedback
│ alice@example.com       │
│                         │
│ Bob Smith               │
│ bob@example.com         │
│                         │
│ ...                     │
│                         │
│ 🔍 Search...            │ ← Search at bottom (bad)
└─────────────────────────┘
```

**New Chat Sheet - After (Redesigned)**:
```
┌─────────────────────────┐
│ Cancel   New Chat   Done │ ← Done button (group mode)
│                         │
│  [1-on-1]  [Group]      │ ← Modern segmented
│                         │
│ 🔍 Search by name...    │ ← Search at top
│                         │
│ 17 People               │ ← Section header
│                         │
│ [Photo●] Alice J     ✓  │ ← 56pt avatar, checkmark
│ alice@example.com       │
│                         │
│ [Photo] Bob Smith       │ ← Larger, better spacing
│ bob@example.com         │
│                         │
│ ...                     │
└─────────────────────────┘
```

### Detailed Component Specs

**1. Modal Presentation**:
- Style: `.sheet` (not full screen)
- Detents: `.large` (full height)
- Swipe-to-dismiss: Enabled
- Corner radius: 16pt (iOS standard)
- Background: `.systemBackground`

**2. Navigation Bar**:
- **Title**: "New Chat" (`.headline` + `.bold`)
- **Left Button**: "Cancel" (blue)
  - Action: Dismiss sheet
  - Always visible
- **Right Button**: "Done" (blue, bold when enabled)
  - Visibility: Only in **Group mode** AND 2+ users selected
  - Action: Create group chat with selected users
  - States:
    - Hidden: 1-on-1 mode
    - Disabled (gray): Group mode, <2 users selected
    - Enabled (blue, bold): Group mode, 2+ users selected
- **Background**: `.systemBackground`
- **Separator**: 0.5pt, `.separator`

**3. User Count Indicator**:
- Remove from nav bar ("17 users")
- Add as section header above user list
- Format: "{count} People" (e.g., "17 People")
- Style: `.subheadline` + `.secondary`
- Padding: 16pt horizontal, 8pt vertical

**4. Segmented Control (1-on-1 / Group)**:
- Style: **Modern iOS** (NOT old rounded style)
- Implementation: `Picker` with `.pickerStyle(.segmented)`
- Options: "1-on-1" and "Group"
- Full width with 16pt horizontal padding
- 12pt padding from nav bar
- 12pt padding to search bar
- Selected: `.blue` accent
- Unselected: `.secondarySystemBackground`
- Height: 32pt (iOS standard)

**5. Search Bar**:
- **Position**: Top (below segmented control) - **CRITICAL CHANGE**
- **Placeholder**: "Search by name or email"
- **Icon**: Magnifying glass (leading)
- **Style**: Use `.searchable()` modifier or custom TextField
- **Background**: `.secondarySystemBackground`
- **Height**: 36pt
- **Corner radius**: 10pt
- **Padding**: 16pt horizontal, 12pt vertical (from segmented control)
- **Behavior**:
  - Debounced filtering: 300ms delay
  - Case-insensitive search
  - Searches both name and email
  - Clear button on right when text entered
  - Keyboard: Default (text)
  - Return key: "Search"

**6. User List**:
- **Implementation**: `ScrollView` + `LazyVStack` (better control than List)
  - Alternative: `List` with custom row styling
- **Background**: `.systemBackground`
- **Spacing**: 0pt between rows (dividers handle separation)
- **Top padding**: 8pt from search bar (or section header)
- **Performance**: Lazy loading for 100+ users

**7. User Row (Completely Redesigned)**:

**Row Layout**:
```
┌─────────────────────────────┐
│ [Avatar●] Name          [✓] │ ← 56pt avatar, checkmark
│           email             │ ← Email below name
└─────────────────────────────┘
```

**Row Components**:

- **Avatar** (Left):
  - Size: **56pt** circular (up from ~48pt)
  - Online status: 12pt green dot (bottom-right of avatar) if online
  - If no photo: User initials on `.systemGray5` background
  - Spacing: 16pt from leading edge

- **User Info** (Center):
  - **Name**: 
    - Font: `.body` + `.bold`
    - Color: `.label`
  - **Email**:
    - Font: `.subheadline`
    - Color: `.secondary`
    - Position: 4pt below name
  - **Spacing**: 16pt from avatar (leading)

- **Checkmark** (Right):
  - **NEW ADDITION** - critical for selection feedback
  - Style: Blue filled circle (24pt) with white checkmark
  - Icon: `checkmark.circle.fill` SF Symbol
  - Color: `.blue`
  - Position: 16pt from trailing edge
  - Visibility: Only when user is selected
  - Animation: Fade in/out (0.2s ease)
  
- **Row Dimensions**:
  - Height: **72pt** minimum (allows 56pt avatar + padding)
  - Padding: 16pt horizontal, 12pt vertical
  - Tap area: **Full row** (not just avatar)
  
- **Row Styling**:
  - Background: `.systemBackground`
  - Background (tapped): `.systemGray6` (subtle highlight)
  - Divider: 0.5pt, `.separator`
  - Divider padding: 72pt leading (after avatar + spacing)

**8. Selection Behavior**:

**1-on-1 Mode** (Single Selection):
- Tap user row → Blue checkmark appears briefly (100ms)
- Auto-navigate to chat immediately (no Done button needed)
- Dismiss New Chat sheet automatically
- Create or navigate to existing 1-on-1 chat
- **Result**: Faster chat creation (one less tap)

**Group Mode** (Multi-Selection):
- Tap user row → Toggle checkmark (on/off)
- Checkmark animates in/out (fade 0.2s)
- Multiple users can be selected
- Done button enabled when 2+ users selected
- Tap Done → Create group chat with selected users
- Minimum 2 users required (Done disabled otherwise)
- **Result**: Clear visual feedback, intentional group creation

**9. Animations & Feedback**:

- **Row Tap**:
  - Scale to 0.98 with spring animation (0.1s)
  - Background flash to `.systemGray6` (0.05s)
  - Haptic feedback (light impact)
  
- **Checkmark Appearance**:
  - Fade in/out: 0.2s ease
  - Scale from 0.8 to 1.0 when appearing
  
- **Search Filtering**:
  - Debounced: 300ms delay
  - Smooth fade transition for filtered results
  
- **Sheet Presentation/Dismissal**:
  - Standard iOS sheet animation (slide up/down)
  - 0.3s ease curve

**10. States**:

**Empty State** (No Users):
- Center icon: `person.3` SF Symbol (96pt, gray)
- Text: "No users available"
- Style: `.title3` + `.secondary`
- Position: Centered vertically

**Search Results Empty**:
- Center icon: `magnifyingglass` SF Symbol (96pt, gray)
- Text: "No results for '{search term}'"
- Style: `.title3` + `.secondary`
- Position: Centered in list area

**Loading State**:
- Skeleton loading rows (3-5 placeholders)
- Shimmer effect on avatar and text areas
- Gray rectangles for text
- Circular placeholder for avatar

**Error State**:
- Center icon: `exclamationmark.triangle` SF Symbol (96pt, red)
- Text: "Unable to load users"
- Button: "Try Again" (blue)
- Action: Retry user fetch

### Performance Targets

See `Psst/agents/shared-standards.md` for general targets. Specific to this feature:

- **Sheet presentation**: <50ms
- **Search filtering**: <100ms after 300ms debounce
- **Row tap feedback**: <16ms (60fps)
- **Chat creation**: <200ms (Firebase write)
- **Smooth scrolling**: 60fps for 100+ users (use LazyVStack)
- **Checkmark animation**: Smooth 60fps fade/scale

---

## 7. Functional Requirements (Must/Should)

### Must-Have Requirements

**R1**: Search bar MUST be positioned at top (below segmented control, above user list)
- **Acceptance Gate**: Search bar appears at top, immediately below segmented control

**R2**: Segmented control MUST use modern iOS style (not old rounded)
- **Acceptance Gate**: Segmented control matches iOS 16+ style with `.pickerStyle(.segmented)`

**R3**: User rows MUST display selection checkmarks when selected
- **Acceptance Gate**: Blue filled circle with white checkmark appears on right when user selected

**R4**: 1-on-1 mode MUST auto-navigate to chat (no Done button)
- **Acceptance Gate**: Tap user in 1-on-1 mode → Immediately opens/creates chat, dismisses sheet

**R5**: Group mode MUST show Done button, enabled when 2+ users selected
- **Acceptance Gate**: Done button visible in group mode, disabled for 0-1 users, enabled for 2+ users

**R6**: User rows MUST have 56pt avatars with better spacing
- **Acceptance Gate**: Avatars render at 56pt, rows have 72pt minimum height, 16pt padding

**R7**: Row tap MUST provide visual feedback (scale animation, background flash)
- **Acceptance Gate**: Tap row → Scales to 0.98 with spring, background flashes `.systemGray6`

**R8**: Search MUST be debounced at 300ms for performance
- **Acceptance Gate**: Search waits 300ms after last keystroke before filtering

**R9**: User count MUST appear as section header (not in nav bar)
- **Acceptance Gate**: "{count} People" shows as section header above list, nav bar clean

**R10**: All existing chat creation functionality MUST work identically
- **Acceptance Gate**: 1-on-1 and group chat creation work as before, 0 regressions

### Should-Have Requirements

**R11**: Checkmark animation SHOULD be smooth (fade + scale)
- **Acceptance Gate**: Checkmark fades in/out smoothly, scales from 0.8 to 1.0

**R12**: Empty and loading states SHOULD be implemented
- **Acceptance Gate**: Empty state shows icon + text, loading shows skeleton rows

**R13**: Haptic feedback SHOULD accompany row tap
- **Acceptance Gate**: Light haptic feedback on row tap (iOS standard)

**R14**: Search SHOULD filter both name and email
- **Acceptance Gate**: Search query matches against both user.displayName and user.email

---

## 8. Data Model

**No data model changes required.** Uses existing user data.

**Existing Models Used**:
```swift
// From existing User model (no changes)
struct User {
    var id: String
    var email: String
    var displayName: String
    var photoURL: String?
    var isOnline: Bool // For online status indicator
}
```

**New Local State** (View-level only):
```swift
// In NewChatView or similar
@State private var selectedUsers: Set<String> = [] // User IDs
@State private var searchText: String = ""
@State private var chatType: ChatType = .oneOnOne // .oneOnOne or .group

enum ChatType {
    case oneOnOne
    case group
}
```

---

## 9. API / Service Contracts

**No new service methods required.** Uses existing services.

**Existing Services Used**:

```swift
// From UserService (no changes)
func getAllUsers() async throws -> [User]
func getUserPresence(userID: String) async throws -> Bool

// From ChatService (no changes)
func createChat(participantIDs: [String], isGroup: Bool) async throws -> String
func getChatWithUser(userID: String) async throws -> Chat?
```

**New Helper Methods** (View/ViewModel level):

```swift
// In NewChatViewModel or View
func filterUsers(searchText: String) -> [User] {
    guard !searchText.isEmpty else { return allUsers }
    return allUsers.filter { user in
        user.displayName.localizedCaseInsensitiveContains(searchText) ||
        user.email.localizedCaseInsensitiveContains(searchText)
    }
}

func handleUserSelection(user: User, chatType: ChatType) {
    if chatType == .oneOnOne {
        // Auto-navigate to chat
        createOrNavigateToChat(with: user)
    } else {
        // Toggle selection
        toggleUserSelection(user)
    }
}

func toggleUserSelection(_ user: User) {
    if selectedUsers.contains(user.id) {
        selectedUsers.remove(user.id)
    } else {
        selectedUsers.insert(user.id)
    }
}
```

---

## 10. UI Components to Create/Modify

### Files to Modify

**New Chat Sheet** (1 main file):
- `Views/UserSelection/NewChatView.swift` or similar — Complete UI overhaul

**Potential Component Files**:
- `Components/UserRow.swift` — May need to create reusable user row component
- `Components/SearchBar.swift` — If using custom search (optional, can use `.searchable()`)

**Total**: 1 modified, 0-2 new components (optional)

### Implementation Breakdown

**NewChatView.swift Redesign**:

```swift
import SwiftUI

struct NewChatView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = NewChatViewModel()
    
    @State private var chatType: ChatType = .oneOnOne
    @State private var searchText: String = ""
    @State private var selectedUsers: Set<String> = []
    
    enum ChatType: String, CaseIterable {
        case oneOnOne = "1-on-1"
        case group = "Group"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented Control
                Picker("Chat Type", selection: $chatType) {
                    ForEach(ChatType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 12)
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search by name or email", text: $searchText)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                
                // User List
                if viewModel.isLoading {
                    loadingView
                } else if filteredUsers.isEmpty {
                    emptyStateView
                } else {
                    userListView
                }
            }
            .navigationTitle("New Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                if chatType == .group && selectedUsers.count >= 2 {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            createGroupChat()
                        }
                        .fontWeight(.bold)
                    }
                }
            }
        }
        .task {
            await viewModel.loadUsers()
        }
    }
    
    // Filtered users based on search
    private var filteredUsers: [User] {
        guard !searchText.isEmpty else { return viewModel.users }
        return viewModel.users.filter { user in
            user.displayName.localizedCaseInsensitiveContains(searchText) ||
            user.email.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // User List View
    private var userListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Section header
                HStack {
                    Text("\(filteredUsers.count) People")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
                // User rows
                ForEach(filteredUsers) { user in
                    UserRowView(
                        user: user,
                        isSelected: selectedUsers.contains(user.id)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        handleUserTap(user)
                    }
                    
                    if user.id != filteredUsers.last?.id {
                        Divider()
                            .padding(.leading, 72)
                    }
                }
            }
        }
    }
    
    // Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ForEach(0..<5, id: \.self) { _ in
                HStack(spacing: 16) {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 56, height: 56)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .frame(height: 16)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray6))
                            .frame(height: 12)
                            .frame(maxWidth: 200)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.top, 16)
    }
    
    // Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: searchText.isEmpty ? "person.3" : "magnifyingglass")
                .font(.system(size: 96))
                .foregroundColor(.gray)
            
            Text(searchText.isEmpty ? "No users available" : "No results for '\(searchText)'")
                .font(.title3)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // Handle User Tap
    private func handleUserTap(_ user: User) {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        if chatType == .oneOnOne {
            // Auto-navigate to chat
            Task {
                await createOrNavigateToChat(with: user)
            }
        } else {
            // Toggle selection
            withAnimation(.easeInOut(duration: 0.2)) {
                if selectedUsers.contains(user.id) {
                    selectedUsers.remove(user.id)
                } else {
                    selectedUsers.insert(user.id)
                }
            }
        }
    }
    
    // Create or navigate to 1-on-1 chat
    private func createOrNavigateToChat(with user: User) async {
        // Implementation: Check if chat exists, create if not, navigate
        dismiss()
    }
    
    // Create group chat
    private func createGroupChat() {
        Task {
            // Implementation: Create group with selectedUsers
            dismiss()
        }
    }
}

// User Row Component
struct UserRowView: View {
    let user: User
    let isSelected: Bool
    
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Text(String(user.displayName.prefix(1)))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
                
                // Online status
                if user.isOnline {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color(.systemBackground), lineWidth: 2)
                        )
                }
            }
            
            // User Info
            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayName)
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundColor(.label)
                
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Checkmark
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(isPressed ? Color(.systemGray6) : Color(.systemBackground))
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}
```

---

## 11. Integration Points

### Existing Integrations (No Changes)
- **Firebase Firestore**: User data fetching (existing)
- **Firebase Realtime Database**: Presence/online status (existing)
- **UserService**: getAllUsers(), getUserPresence() (existing)
- **ChatService**: createChat(), getChatWithUser() (existing)
- **State management**: SwiftUI @State, @StateObject

### Design Consistency
- Uses design system from PR #006A/B:
  - Color: `.blue` accent (checkmarks, buttons), system colors
  - Typography: iOS text styles (`.body`, `.headline`, `.subheadline`)
  - Spacing: 8pt/12pt/16pt grid
  - Animations: Spring (0.3s, dampingFraction 0.7), ease (0.2s)
  - Search bar: 36pt height, 10pt radius (standard)

---

## 12. Testing Plan & Acceptance Gates

### Configuration Testing
- [ ] Firebase Firestore connected (user fetch works)
- [ ] Firebase Realtime Database connected (presence works)
- [ ] UserService can fetch all users
- [ ] ChatService can create chats

### Visual Testing
- [ ] Search bar at top (below segmented control)
- [ ] Segmented control uses modern iOS style
- [ ] User rows have 56pt avatars
- [ ] Row height is 72pt minimum
- [ ] Checkmarks appear when users selected (blue circle)
- [ ] Done button shows in group mode only
- [ ] User count shows as section header ("{count} People")
- [ ] Spacing matches spec (16pt padding, 12pt vertical)
- [ ] Dark Mode: All colors adapt correctly

### Happy Path Testing - 1-on-1 Mode
- [ ] Gate: Tap segmented control → Switch to "1-on-1"
- [ ] Gate: Tap user row → Checkmark shows briefly (100ms)
- [ ] Gate: Auto-navigate to chat immediately
- [ ] Gate: Sheet dismisses automatically
- [ ] Gate: Chat created/opened in <200ms
- [ ] Gate: Done button NOT visible

### Happy Path Testing - Group Mode
- [ ] Gate: Tap segmented control → Switch to "Group"
- [ ] Gate: Tap user row → Checkmark appears (animated)
- [ ] Gate: Tap selected row again → Checkmark disappears
- [ ] Gate: Select 2+ users → Done button enabled (blue, bold)
- [ ] Gate: Tap Done → Group chat created
- [ ] Gate: Sheet dismisses after group created
- [ ] Gate: Group chat appears in conversation list

### Search Testing
- [ ] Gate: Type in search bar → Results filter in <100ms after 300ms debounce
- [ ] Gate: Search matches display name (case-insensitive)
- [ ] Gate: Search matches email (case-insensitive)
- [ ] Gate: Clear search (X button) → All users show again
- [ ] Gate: No results → Empty state shows
- [ ] Gate: Search with special characters doesn't crash

### Animation Testing
- [ ] Gate: Row tap → Scale to 0.98 with spring animation
- [ ] Gate: Row tap → Background flashes to `.systemGray6`
- [ ] Gate: Checkmark → Fades in smoothly (0.2s)
- [ ] Gate: Checkmark → Scales from 0.8 to 1.0
- [ ] Gate: Sheet presentation → Smooth slide up
- [ ] Gate: Sheet dismissal → Smooth slide down

### Edge Cases Testing
- [ ] No users in database → Empty state shows
- [ ] Search with no results → "No results for '...'" shows
- [ ] User fetch fails → Error state shows with retry button
- [ ] Very long user name → Text doesn't overflow
- [ ] Very long email → Text truncates properly
- [ ] 100+ users → Lazy loading, smooth scroll (60fps)
- [ ] Select user then switch to 1-on-1 mode → Selection clears
- [ ] Offline mode → Shows cached users or error

### Multi-Device Testing
- [ ] iPhone SE → Search bar visible, rows tappable
- [ ] iPhone 15 → Layout perfect
- [ ] iPhone 15 Pro Max → Layout adapts well
- [ ] Landscape → Layout works (scrollable)
- [ ] Dark Mode → All colors correct

### Performance Testing
- [ ] Sheet presents in <50ms
- [ ] Search filtering <100ms (after 300ms debounce)
- [ ] Row tap feedback <16ms (60fps)
- [ ] Chat creation <200ms
- [ ] Smooth 60fps scrolling with 100+ users
- [ ] No memory leaks

### Regression Testing
- [ ] 1-on-1 chat creation works (existing functionality)
- [ ] Group chat creation works (existing functionality)
- [ ] User presence indicators work
- [ ] Chat navigation works
- [ ] Sheet dismiss works

---

## 13. Definition of Done

- [ ] NewChatView redesigned with all UI changes
- [ ] Search bar at top (below segmented control)
- [ ] Modern segmented control implemented
- [ ] User rows: 56pt avatars, 72pt height, proper spacing
- [ ] Selection checkmarks (blue circle) implemented
- [ ] 1-on-1 mode: Auto-navigation implemented
- [ ] Group mode: Done button with 2+ user validation
- [ ] Row tap animations (scale, background flash)
- [ ] Search debouncing (300ms)
- [ ] User count as section header
- [ ] Empty and loading states implemented
- [ ] Dark Mode supported
- [ ] All acceptance gates pass
- [ ] Manual testing completed
- [ ] Performance targets met
- [ ] 0 regressions in chat creation
- [ ] Code review completed
- [ ] Design reviewed and approved

---

## 14. Risks & Mitigations

**Risk**: Search debouncing causes perceived lag
- **Mitigation**: 300ms is industry standard; show search bar feedback (loading indicator if needed)

**Risk**: 1-on-1 auto-navigation feels too fast/unexpected
- **Mitigation**: Brief checkmark (100ms) provides visual feedback before navigation

**Risk**: Large user lists (1000+) cause performance issues
- **Mitigation**: Use LazyVStack for lazy loading; test with 100+ users; pagination if needed (future)

**Risk**: Checkmark animation not smooth on older devices
- **Mitigation**: Use simple fade (0.2s), avoid complex animations; test on iPhone SE

**Risk**: Done button state confusing for users
- **Mitigation**: Clear disabled/enabled states (gray vs blue); only show in group mode

**Risk**: Search bar at top pushes content down too much
- **Mitigation**: Compact design (36pt height); use LazyVStack for virtualized scrolling

---

## 15. Rollout & Telemetry

**Feature Flag**: No

**Rollout Strategy**: 
- Deploy as part of PR #006E
- Final piece of design system overhaul (006A → 006B → 006C → 006D → 006E)
- No gradual rollout needed

**Manual Validation**:
- Test both 1-on-1 and group chat creation
- Test search extensively
- Verify animations on physical device
- Test Dark Mode
- Screenshot before/after

**Success Indicators**:
- 0 New Chat-related bug reports
- Chat creation works seamlessly
- Users find search easily (top position)
- Improved UX for 1-on-1 chats (faster)
- Professional, modern feel

---

## 16. Open Questions

**Q1**: Should we add haptic feedback on checkmark toggle?
- **Answer**: Yes, light impact on selection/deselection

**Q2**: Should we limit group size (max participants)?
- **Answer**: Not in this PR (UI only); can add validation in future

**Q3**: Should search support advanced filters (online only, etc.)?
- **Answer**: No, keep simple for MVP; defer to Phase 2

**Q4**: Should we show user count in nav bar when searching?
- **Answer**: No, section header handles this; keep nav bar clean

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future phases:

**Phase 2 - Enhanced Search**:
- [ ] Search filters (online only, recent contacts)
- [ ] Search history/suggestions
- [ ] Fuzzy search (typo tolerance)
- [ ] Alphabetical section headers (A, B, C...)

**Phase 2 - User Organization**:
- [ ] Favorites/pinned users at top
- [ ] Recent contacts section
- [ ] Contact categories (work, friends, family)
- [ ] User blocking/hiding

**Phase 2 - Group Creation**:
- [ ] Group name input during creation
- [ ] Group photo selection
- [ ] Group chat limits (max participants)
- [ ] Group templates

**Phase 2 - Advanced Features**:
- [ ] QR code scanning to add users
- [ ] Deep links (psst://user/...)
- [ ] Contact sync (phone contacts)
- [ ] Invite non-users (SMS/email)

---

## Preflight Questionnaire

1. **Smallest end-to-end user outcome for this PR?**
   - User opens New Chat sheet, finds contact easily (search at top), taps to create chat

2. **Primary user and critical action?**
   - All users creating new chats (1-on-1 or group)

3. **Must-have vs nice-to-have?**
   - Must: Search at top, modern segmented, checkmarks, 1-on-1 auto-nav, Done button
   - Nice: Animations, haptics, skeleton loading, empty states

4. **Real-time requirements?**
   - User presence indicators (online status) - existing

5. **Performance constraints?**
   - Sheet <50ms, search <100ms (debounced 300ms), scroll 60fps

6. **Error/edge cases to handle?**
   - No users, search no results, fetch failure, long text, 100+ users

7. **Data model changes?**
   - None (uses existing User model, local state for selection)

8. **Service APIs required?**
   - None (uses existing UserService, ChatService)

9. **UI entry points and states?**
   - Entry: FAB or nav button in Conversations tab
   - States: Default, loading, empty, search results, error

10. **Security/permissions implications?**
    - None (uses existing Firebase auth and user fetch)

11. **Dependencies or blocking integrations?**
    - Depends on: PR #006A (design system), PR #006B (main app)
    - Blocks: None (final PR in #006 series)

12. **Rollout strategy and metrics?**
    - Deploy directly, completes PR #006 overhaul
    - Success: Modern New Chat UI, 0 regressions, faster 1-on-1 creation

13. **What is explicitly out of scope?**
    - Advanced search filters, contact sync, group naming, QR codes, user categories

---

**End of PRD**

