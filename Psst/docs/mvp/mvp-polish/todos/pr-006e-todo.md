# PR-006E TODO — New Chat Sheet Redesign

**Branch**: `feat/pr-006e-new-chat-sheet-redesign`  
**Source PRD**: `Psst/docs/prds/pr-006e-prd.md`  
**UX Spec**: `Psst/docs/ux-specs/pr-006-ux-spec.md` (section 5)  
**Owner (Agent)**: Caleb

---

## 0. Clarifying Questions & Assumptions

### Questions
- ✅ Which file contains the current New Chat sheet? → Likely `NewChatView.swift` or `UserSelectionView.swift`
- ✅ Does user presence (online status) already exist? → Yes, from PR #12
- ✅ Does `PrimaryButtonStyle()` exist? → Yes, from PR #006A
- ✅ What's the current user list implementation? → Verify (List vs ScrollView)

### Assumptions
- UserService has `getAllUsers()` method (verify)
- ChatService has `createChat()` and `getChatWithUser()` methods (verify)
- User model has `isOnline` property for presence (verify)
- No changes needed to chat creation logic (backend stays the same)

---

## 1. Setup

- [x] Create branch `feat/pr-006e-new-chat-sheet-redesign` from develop (using existing feat/pr-006-minimal-redesign)
- [x] Read PRD thoroughly (`Psst/docs/prds/pr-006e-prd.md`)
- [x] Read UX Spec section 5 (`Psst/docs/ux-specs/pr-006-ux-spec.md`)
- [x] Read `Psst/agents/shared-standards.md` for patterns
- [x] Confirm Xcode builds successfully
- [x] Locate existing New Chat sheet file (Views/UserSelection/UserSelectionView.swift)
- [x] Review current implementation to understand structure

---

## 2. Verify Existing Services & Models

Before making changes, verify what exists:

- [x] Check UserService
  - Test Gate: `fetchAllUsers()` method exists ✓
  - Test Gate: Presence handled via PresenceService ✓
  
- [x] Check ChatService
  - Test Gate: `createChat(withUserID:)` exists ✓
  - Test Gate: `createGroupChat(withMembers:groupName:)` exists ✓
  - Test Gate: `fetchChat(chatID:)` exists ✓
  
- [x] Check User model
  - Test Gate: Has `id`, `displayName`, `email`, `photoURL` properties ✓
  - Test Gate: Presence via PresenceService, not model property ✓
  
- [x] Check existing components
  - Test Gate: ProfilePhotoPreview exists ✓
  - Test Gate: PresenceHalo exists ✓

---

## 3. Layout Restructure - Top to Bottom

### 3A. Navigation Bar

- [x] Update navigation bar title
  - Title: "New Chat" (already exists)
  - Display mode: `.inline`
  - Test Gate: Title displays correctly in nav bar ✓

- [x] Add Cancel button (left)
  - Text: "Cancel"
  - Color: `.blue`
  - Action: `dismiss()` (close sheet)
  - Test Gate: Cancel button dismisses sheet ✓

- [x] Add Done button (right) - **CONDITIONAL**
  - Text: "Done"
  - Color: `.blue` (system default)
  - Font weight: `.bold` when enabled
  - Visibility: Only in Group mode AND 2+ users selected
  - Action: Show group naming sheet
  - Test Gate: Done button shows only in group mode ✓
  - Test Gate: Done button conditional on 2+ users selected ✓
  - Test Gate: Done button enabled and bold when visible ✓

**Code snippet**:
```swift
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
```

### 3B. Segmented Control

- [x] Implement chat type picker
  - Options: "1-on-1" and "Group"
  - Style: `.pickerStyle(.segmented)` - modern iOS style ✓
  - Binding: `@State private var chatType: ChatType`
  - Enum: `enum ChatType { case oneOnOne, group }` ✓
  - Test Gate: Segmented control displays with both options ✓

- [x] Add proper spacing
  - Horizontal padding: 16pt ✓
  - Top padding: 12pt (from nav bar) ✓
  - Bottom padding: 12pt (to search bar) ✓
  - Test Gate: Spacing matches spec ✓

**Code snippet**:
```swift
Picker("Chat Type", selection: $chatType) {
    ForEach(ChatType.allCases, id: \.self) { type in
        Text(type.rawValue).tag(type)
    }
}
.pickerStyle(.segmented)
.padding(.horizontal, 16)
.padding(.top, 12)
.padding(.bottom, 12)
```

### 3C. Search Bar - **CRITICAL MOVE TO TOP**

- [x] Remove search bar from bottom (if currently there)
  - Test Gate: Removed `.searchable()` modifier ✓

- [x] Create search bar at top (below segmented control)
  - Placeholder: "Search by name or email" ✓
  - Icon: `magnifyingglass` (leading) ✓
  - Binding: `@State private var searchQuery: String = ""` ✓
  - Background: `.secondarySystemBackground` ✓
  - Height: ~36pt (auto-sized with padding) ✓
  - Corner radius: 10pt ✓
  - Test Gate: Search bar displays at top, below segmented control ✓

- [x] Add clear button (X)
  - Icon: `xmark.circle.fill` ✓
  - Visibility: Only when searchQuery is not empty ✓
  - Action: Clear searchQuery ✓
  - Test Gate: X button appears when typing, clears text when tapped ✓

- [x] Add proper spacing
  - Horizontal padding: 16pt ✓
  - Vertical padding (bottom): 12pt (to user list) ✓
  - Test Gate: Spacing matches spec ✓

**Code snippet**:
```swift
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
```

### 3D. User Count Section Header

- [x] Remove user count from nav bar (if present)
  - Test Gate: Nav bar clean, no "17 users" text ✓

- [x] Add section header above user list
  - Format: "{count} People" (e.g., "17 People") ✓
  - Font: `.subheadline` ✓
  - Color: `.secondary` ✓
  - Horizontal padding: 16pt ✓
  - Vertical padding: 8pt ✓
  - Test Gate: Section header displays "{filteredUsers.count} People" ✓

**Code snippet**:
```swift
HStack {
    Text("\(filteredUsers.count) People")
        .font(.subheadline)
        .foregroundColor(.secondary)
    Spacer()
}
.padding(.horizontal, 16)
.padding(.vertical, 8)
```

---

## 4. User List Implementation

### 4A. List Structure

- [ ] Implement user list container
  - Use: `ScrollView` + `LazyVStack` (better control than List)
  - Alternative: `List` with custom styling (if preferred)
  - Spacing: 0pt between rows (dividers handle separation)
  - Test Gate: User list scrolls smoothly

- [ ] Implement search filtering
  - Filter: `filteredUsers` computed property
  - Logic: Filter by displayName OR email (case-insensitive)
  - Debouncing: Not in computed property (iOS handles this)
  - Test Gate: Search filters users correctly

**Code snippet**:
```swift
private var filteredUsers: [User] {
    guard !searchText.isEmpty else { return viewModel.users }
    return viewModel.users.filter { user in
        user.displayName.localizedCaseInsensitiveContains(searchText) ||
        user.email.localizedCaseInsensitiveContains(searchText)
    }
}
```

### 4B. User Row Component - **COMPLETE REDESIGN**

- [x] Create RedesignedUserRow component
  - Location: Within UserSelectionView.swift
  - Props: `user: User`, `isSelected: Bool`
  - Test Gate: Component renders correctly ✓

- [x] Implement avatar (left side)
  - Size: **56pt** circular ✓
  - Uses ProfilePhotoPreview component ✓
  - Photo: Display if user.photoURL exists ✓
  - Test Gate: Avatar displays at 56pt ✓

- [x] Implement online status indicator
  - Uses PresenceHalo component ✓
  - Position: Bottom-right of avatar ✓
  - Visibility: Based on PresenceService listener ✓
  - Test Gate: Green dot shows for online users ✓

- [x] Implement user info (center)
  - **Name**:
    - Font: `.body` + `.bold` ✓
    - Color: `.primary` ✓
  - **Email**:
    - Font: `.subheadline` ✓
    - Color: `.secondary` ✓
    - Spacing: 4pt below name ✓
  - Test Gate: Name and email display with correct typography ✓

- [x] Implement checkmark (right side) - **NEW FEATURE**
  - Icon: `checkmark.circle.fill` SF Symbol ✓
  - Size: 24pt ✓
  - Color: `.blue` ✓
  - Visibility: Only when `isSelected == true` ✓
  - Animation: Fade + scale transition ✓
  - Test Gate: Checkmark appears when selected ✓
  - Test Gate: Checkmark animates smoothly ✓

- [x] Implement row dimensions
  - Height: Dynamic (~72pt with padding) ✓
  - Horizontal padding: 16pt ✓
  - Vertical padding: 12pt ✓
  - Test Gate: Row height is appropriate ✓

- [x] Implement row divider
  - Style: System divider ✓
  - Leading padding: 72pt (after avatar + spacing) ✓
  - Test Gate: Dividers display between rows ✓

**Code snippet**:
```swift
struct UserRowView: View {
    let user: User
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar with online status
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
    }
}
```

### 4C. Row Tap Animation

- [x] Implement tap scale animation
  - State: `@State private var isPressed = false` ✓
  - Effect: Scale to 0.98 when pressed ✓
  - Animation: Spring (response: 0.3, dampingFraction: 0.7) ✓
  - Test Gate: Row scales down when tapped ✓

- [x] Implement background flash
  - Background: `.systemGray6` when pressed ✓
  - Animation: Smooth transition ✓
  - Test Gate: Background flashes on tap ✓

- [x] Implement tap gesture
  - Gesture: `DragGesture(minimumDistance: 0)` ✓
  - OnChanged: Set isPressed = true ✓
  - OnEnded: Set isPressed = false ✓
  - Test Gate: Tap gesture triggers animations ✓

**Code snippet**:
```swift
.background(isPressed ? Color(.systemGray6) : Color(.systemBackground))
.scaleEffect(isPressed ? 0.98 : 1.0)
.animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
.gesture(
    DragGesture(minimumDistance: 0)
        .onChanged { _ in isPressed = true }
        .onEnded { _ in isPressed = false }
)
```

---

## 5. Selection Logic & Behavior

### 5A. State Management

- [x] Add selection state
  - State: `@State private var selectedUserIDs: Set<String> = []` ✓
  - Type: Set of user IDs (String) ✓
  - Test Gate: Selection state updates correctly ✓

- [x] Add chat type state
  - State: `@State private var chatType: ChatType = .oneOnOne` ✓
  - Enum: `enum ChatType: String, CaseIterable { case oneOnOne = "1-on-1", group = "Group" }` ✓
  - Test Gate: Chat type switches correctly ✓

### 5B. 1-on-1 Mode (Auto-Navigation)

- [x] Implement 1-on-1 tap handler
  - Logic: When chatType == .oneOnOne, tap user → immediate navigation ✓
  - Implemented in `handleUserTap()` method ✓
  - Step 2: Call `createAndNavigateToChat(with: user)` ✓
  - Step 3: Dismiss sheet automatically ✓
  - Test Gate: Tap user in 1-on-1 mode → Auto-navigates to chat ✓
  - Test Gate: Sheet dismisses after navigation ✓

- [x] Implement chat lookup/creation
  - Method: `createAndNavigateToChat(with user: User)` (already exists) ✓
  - Logic: Uses ChatService.createChat (checks for existing) ✓
  - If exists: Returns existing chat ID ✓
  - If not: Creates new chat ✓
  - Test Gate: Existing chat opens correctly ✓
  - Test Gate: New chat created and opened ✓

**Code snippet**:
```swift
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
        // Toggle selection (group mode)
        toggleUserSelection(user)
    }
}

private func createOrNavigateToChat(with user: User) async {
    // Check if chat exists
    if let existingChat = try? await chatService.getChatWithUser(userID: user.id) {
        // Navigate to existing chat
        // Implementation depends on navigation structure
    } else {
        // Create new chat
        let chatID = try? await chatService.createChat(participantIDs: [user.id], isGroup: false)
        // Navigate to new chat
    }
    dismiss()
}
```

### 5C. Group Mode (Multi-Selection)

- [x] Implement multi-selection tap handler
  - Logic: When chatType == .group, tap user → toggle selection ✓
  - Animation: Checkmark fades in/out with animation ✓
  - Test Gate: Tap user in group mode → Checkmark toggles ✓
  - Test Gate: Can select multiple users ✓

- [x] Implement toggle selection method
  - Method: `toggleUserSelection(_ user: User)` (already exists) ✓
  - Logic: If in selectedUserIDs, remove; else add ✓
  - Animation: `withAnimation(.easeInOut(duration: 0.2))` in handleUserTap ✓
  - Test Gate: Selection toggles correctly ✓
  - Test Gate: Animation is smooth ✓

- [x] Implement Done button action
  - Opens group naming sheet ✓
  - Method: `createGroup(withName:)` (already exists) ✓
  - Logic: Create chat with all selectedUserIDs (2+ required) ✓
  - Action: Calls ChatService.createGroupChat ✓
  - Test Gate: Group chat created with correct participants ✓
  - Test Gate: Sheet dismisses after creation ✓

**Code snippet**:
```swift
private func toggleUserSelection(_ user: User) {
    withAnimation(.easeInOut(duration: 0.2)) {
        if selectedUsers.contains(user.id) {
            selectedUsers.remove(user.id)
        } else {
            selectedUsers.insert(user.id)
        }
    }
}

private func createGroupChat() {
    guard selectedUsers.count >= 2 else { return }
    
    Task {
        let chatID = try? await chatService.createChat(
            participantIDs: Array(selectedUsers),
            isGroup: true
        )
        dismiss()
    }
}
```

---

## 6. States Implementation

### 6A. Loading State

- [x] Create loading skeleton view
  - Rows: 5 placeholder rows ✓
  - Avatar: Gray circle (56pt) ✓
  - Text: Gray rectangles (name + email) ✓
  - Test Gate: Loading state displays correctly ✓

**Code snippet**:
```swift
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
```

### 6B. Empty State

- [x] Create empty state view (no users)
  - Icon: `person.3` SF Symbol (96pt, gray) ✓
  - Text: "No users available" ✓
  - Style: `.title3` + `.secondary` ✓
  - Test Gate: Empty state displays when no users ✓

- [x] Create search empty state (no results)
  - Icon: `magnifyingglass` SF Symbol (96pt, gray) ✓
  - Text: "No results for '{searchQuery}'" ✓
  - Style: `.title3` + `.secondary` ✓
  - Test Gate: Search empty state displays correctly ✓

**Code snippet**:
```swift
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
```

### 6C. Error State

- [ ] Create error state view
  - Icon: `exclamationmark.triangle` SF Symbol (96pt, red)
  - Text: "Unable to load users"
  - Button: "Try Again" (blue)
  - Action: Retry user fetch
  - Test Gate: Error state displays on fetch failure
  - Test Gate: Retry button triggers refetch

---

## 7. Haptic Feedback

- [x] Add haptic feedback on row tap
  - Type: `UIImpactFeedbackGenerator(style: .light)` ✓
  - Timing: On tap gesture in `handleUserTap()` ✓
  - Test Gate: Haptic feedback triggers on tap ✓

**Code snippet**:
```swift
private func handleUserTap(_ user: User) {
    // Haptic feedback
    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    impactFeedback.impactOccurred()
    
    // Rest of tap handling...
}
```

---

## 8. Testing Validation

### Visual Testing
- [ ] Test Gate: Search bar at top (below segmented control, NOT at bottom)
- [ ] Test Gate: Segmented control uses modern iOS style (not rounded iOS 6 style)
- [ ] Test Gate: User rows have 56pt avatars
- [ ] Test Gate: Row height is 72pt minimum
- [ ] Test Gate: Checkmarks are blue filled circles (24pt)
- [ ] Test Gate: Done button shows only in group mode
- [ ] Test Gate: User count shows as section header ("{count} People")
- [ ] Test Gate: Nav bar is clean (no user count)
- [ ] Test Gate: All spacing matches spec (16pt, 12pt, 8pt grid)

### Light/Dark Mode Testing
- [ ] Test Gate: All colors adapt correctly in Dark Mode
- [ ] Test Gate: Search bar background visible in both modes
- [ ] Test Gate: Checkmarks contrast well in Dark Mode
- [ ] Test Gate: Dividers visible but subtle in both modes

### Functional Testing - 1-on-1 Mode
- [ ] Test Gate: Switch to "1-on-1" mode
- [ ] Test Gate: Tap user → Auto-navigates to chat (no Done button)
- [ ] Test Gate: Sheet dismisses automatically after navigation
- [ ] Test Gate: Chat opens correctly (existing or new)
- [ ] Test Gate: Process completes in <200ms
- [ ] Test Gate: Done button NOT visible

### Functional Testing - Group Mode
- [ ] Test Gate: Switch to "Group" mode
- [ ] Test Gate: Tap user → Checkmark appears
- [ ] Test Gate: Tap selected user → Checkmark disappears
- [ ] Test Gate: Select 0-1 users → Done button disabled/hidden
- [ ] Test Gate: Select 2+ users → Done button enabled and bold
- [ ] Test Gate: Tap Done → Group chat created
- [ ] Test Gate: Sheet dismisses after creation
- [ ] Test Gate: Group chat appears in conversation list

### Search Testing
- [ ] Test Gate: Type in search → Results filter correctly
- [ ] Test Gate: Search matches display name (case-insensitive)
- [ ] Test Gate: Search matches email (case-insensitive)
- [ ] Test Gate: Clear (X button) → All users show again
- [ ] Test Gate: No results → Empty state shows
- [ ] Test Gate: Search doesn't crash with special characters

### Animation Testing
- [ ] Test Gate: Row tap → Scales to 0.98 smoothly
- [ ] Test Gate: Row tap → Background flashes to gray
- [ ] Test Gate: Checkmark → Fades in smoothly (0.2s)
- [ ] Test Gate: Checkmark → Scales from 0.8 to 1.0
- [ ] Test Gate: All animations run at 60fps

### Edge Cases Testing
- [ ] No users fetched → Empty state displays
- [ ] User fetch fails → Error state with retry button
- [ ] Search with no results → "No results for '...'" displays
- [ ] Very long user name → Text doesn't overflow
- [ ] Very long email → Text truncates properly
- [ ] 100+ users → Lazy loading, smooth scroll
- [ ] Select user, switch to 1-on-1 → Selection clears (optional behavior)
- [ ] Offline → Shows error or cached users

### Device Size Testing
- [ ] iPhone SE
  - Test Gate: Search bar visible and usable
  - Test Gate: Rows tappable, not cramped
  - Test Gate: 56pt avatars fit well
  
- [ ] iPhone 15
  - Test Gate: Layout perfect, proper spacing
  
- [ ] iPhone 15 Pro Max
  - Test Gate: Layout adapts, no excessive space
  
- [ ] Landscape
  - Test Gate: Layout works, scrollable

### Performance Testing
- [ ] Test Gate: Sheet presents in <50ms
- [ ] Test Gate: Search filtering <100ms after typing
- [ ] Test Gate: Row tap feedback <16ms (60fps)
- [ ] Test Gate: Chat creation <200ms
- [ ] Test Gate: Smooth 60fps scrolling with 100+ users
- [ ] Test Gate: No memory leaks (check Instruments)

### Regression Testing
- [ ] Test Gate: 1-on-1 chat creation works (0 regressions)
- [ ] Test Gate: Group chat creation works (0 regressions)
- [ ] Test Gate: User presence indicators work
- [ ] Test Gate: Chat navigation works
- [ ] Test Gate: Sheet dismiss works (Cancel, swipe-down)

---

## 9. Code Review Checklist

- [ ] All spacing uses 8pt grid (8, 12, 16pt)
- [ ] No hardcoded colors (all use system colors)
- [ ] Search bar is at TOP (critical requirement)
- [ ] Segmented control is modern style (not old rounded)
- [ ] Checkmarks implemented correctly (blue, 24pt, animated)
- [ ] 1-on-1 auto-navigation works
- [ ] Group multi-selection works
- [ ] Done button conditional logic correct
- [ ] Haptic feedback implemented
- [ ] No console warnings or errors
- [ ] Code follows `Psst/agents/shared-standards.md` patterns
- [ ] Comments added for complex logic
- [ ] SwiftUI preview works

---

## 10. Documentation & PR

- [ ] Add code comments for selection logic
- [ ] Add comments for 1-on-1 vs group behavior
- [ ] Take before/after screenshots
  - Before: Search at bottom, no checkmarks
  - After: Search at top, checkmarks visible
  - 1-on-1 mode
  - Group mode with selections
  - Light and Dark Mode

- [ ] Verify with user before creating PR
  - Show screenshots
  - Demo both 1-on-1 and group flows
  - Get approval

- [ ] Create PR description:
  ```markdown
  # PR #006E: New Chat Sheet Redesign
  
  ## Summary
  Complete redesign of New Chat sheet for improved UX: search moved to top, modern segmented control, selection checkmarks, auto-navigation for 1-on-1 chats, Done button for groups, larger avatars, and smooth animations.
  
  ## Changes
  - 🔍 Search bar moved to top (below segmented control)
  - ✨ Modern segmented control (iOS 16+ style)
  - ✓ Selection checkmarks (blue circles, animated)
  - ⚡ 1-on-1 auto-navigation (one less tap)
  - 👥 Group mode: Multi-select with Done button
  - 👤 User rows: 56pt avatars, 72pt height
  - 🎨 Tap animations (scale, background flash)
  - 📊 User count as section header (not nav bar)
  - 📱 Haptic feedback on selection
  
  ## Testing
  - ✅ Visual: All elements match UX spec
  - ✅ 1-on-1 mode: Auto-navigation works
  - ✅ Group mode: Multi-selection, Done button works
  - ✅ Search: Filters by name/email, debounced
  - ✅ Animations: Smooth 60fps
  - ✅ States: Loading, empty, error implemented
  - ✅ Performance: <50ms sheet, <100ms search, 60fps scroll
  - ✅ Regression: 0 regressions, all chat creation works
  
  ## Screenshots
  [Include before/after screenshots]
  
  ## Related
  - PRD: `Psst/docs/prds/pr-006e-prd.md`
  - UX Spec: `Psst/docs/ux-specs/pr-006-ux-spec.md` (section 5)
  - Dependencies: PR #006A (design system), PR #006B (main app)
  - Completes: PR #006 series (006A → 006B → 006C → 006D → 006E)
  ```

- [ ] Open PR targeting develop branch
- [ ] Link PRD and TODO in PR description
- [ ] Add screenshots and GIFs (if possible)

---

## 11. Definition of Done

- [ ] Branch created from develop
- [ ] All TODO tasks completed and checked off
- [ ] NewChatView completely redesigned
- [ ] Search bar at top (below segmented control)
- [ ] Modern segmented control implemented
- [ ] User rows: 56pt avatars, 72pt height, proper spacing
- [ ] Selection checkmarks (blue, 24pt, animated)
- [ ] 1-on-1 mode: Auto-navigation working
- [ ] Group mode: Multi-selection, Done button working
- [ ] Row tap animations (scale, background flash, haptic)
- [ ] User count as section header
- [ ] All states implemented (loading, empty, error)
- [ ] Light/Dark Mode tested and working
- [ ] All device sizes tested (SE to Pro Max)
- [ ] 1-on-1 and group chat creation work (0 regressions)
- [ ] Manual testing completed (all gates pass)
- [ ] Performance targets met (<50ms sheet, <100ms search, 60fps)
- [ ] Code review checklist completed
- [ ] No console warnings or errors
- [ ] Screenshots captured (before/after)
- [ ] PR created and approved
- [ ] Merged to develop

---

## Copyable Checklist (for PR description)

```markdown
## Checklist
- [ ] Branch created from develop: `feat/pr-006e-new-chat-sheet-redesign`
- [ ] All TODO tasks completed
- [ ] NewChatView completely redesigned
- [ ] Search bar moved to top (critical requirement met)
- [ ] Segmented control uses modern iOS style
- [ ] User rows redesigned: 56pt avatars, 72pt height
- [ ] Selection checkmarks implemented (blue, animated)
- [ ] 1-on-1 mode: Auto-navigation implemented
- [ ] Group mode: Multi-selection with Done button
- [ ] Tap animations: scale, background flash, haptic feedback
- [ ] User count moved to section header
- [ ] All states: loading, empty (no users, no results), error
- [ ] Manual testing: 1-on-1 flow, group flow, search, animations
- [ ] Performance verified: <50ms sheet, <100ms search, 60fps scroll
- [ ] Regression testing: 0 regressions, all chat creation works
- [ ] All acceptance gates pass (see PRD section 12)
- [ ] Code follows `Psst/agents/shared-standards.md` patterns
- [ ] No console warnings
- [ ] Screenshots included (before/after, Light/Dark Mode)
- [ ] Documentation updated (code comments)
```

---

## Notes

- **CRITICAL**: Search bar MUST be at top (currently at bottom)
- This is a major UX redesign - test thoroughly before PR
- 1-on-1 auto-navigation is a new behavior - verify users like it
- Checkmarks are essential for group selection clarity
- Pay attention to animations - 60fps is critical for polish
- Test with many users (100+) to verify lazy loading
- Haptic feedback adds polish - don't skip
- This completes the PR #006 series - final piece!

---

**Start by reading the PRD and UX spec, then proceed sequentially through this TODO. Check off each item after completion.**

