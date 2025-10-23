# PRD: Main App UI Polish - Conversations & Profile

**Feature**: Main App Visual Enhancement

**Version**: 1.0

**Status**: Ready for Development

**Agent**: Pam (Planning Agent)

**Target Release**: Phase 1 - MVP Polish

**Links**: 
- PR Brief: `Psst/docs/pr-briefs.md` (PR #006B)
- TODO: `Psst/docs/todos/pr-006b-todo.md` (to be created)
- UX Spec: `Psst/docs/ux-specs/pr-006-ux-spec.md` (sections 2-3)
- Dependencies: PR #006A (authentication redesign - establishes design system)

---

## 1. Summary

Polish the main app experience by enhancing the Conversations tab (ChatListView) and Profile tab with improved visual hierarchy, better UX patterns, and consistent styling. This includes moving the "new message" button to a Floating Action Button (FAB), increasing avatar sizes, improving spacing, and creating a more polished, professional main app experience.

---

## 2. Problem & Goals

**Problem**: 
The Conversations tab and Profile tab feel basic and lack visual polish. The "new message" button is hidden in the nav bar (low discoverability), avatars are too small (50pt), spacing is inconsistent, and the overall visual hierarchy doesn't guide users effectively. While all the features work (online status, unread badges, sender names), they're not presented in the most intuitive, modern way.

**Why Now**: 
This builds on the design system established in PR #006A. The main app screens (Conversations and Profile) are where users spend 95% of their time - these need to feel polished and professional. The Floating Action Button pattern is standard in modern messaging apps (WhatsApp, Telegram) and dramatically improves new message discoverability.

**Goals** (ordered, measurable):
- [ ] **G1** — Move "new message" button from nav bar to Floating Action Button (FAB) for better discoverability
- [ ] **G2** — Increase avatar sizes from 50pt to 56pt for better visual presence
- [ ] **G3** — Add user avatar to nav bar for quick profile access
- [ ] **G4** — Improve spacing and layout consistency across Conversations and Profile tabs
- [ ] **G5** — Apply consistent blue accent color to tab bar and interactive elements

---

## 3. Non-Goals / Out of Scope

To keep this PR focused on visual polish only:

- [ ] **Not adding** new features (all existing features stay as-is)
- [ ] **Not changing** how online status works (just making it look better)
- [ ] **Not changing** how unread badges work (just making them look better)
- [ ] **Not changing** how sender names work (just making them look better)
- [ ] **Not implementing** new navigation patterns (keep existing NavigationStack)
- [ ] **Not redesigning** ChatView (message bubbles) - only the list
- [ ] **Not adding** new Profile features (only visual improvements)
- [ ] **Not changing** tab structure (keep existing tabs)

---

## 4. Success Metrics

**User-visible**:
- "New message" FAB is immediately visible and discoverable
- Chat rows feel more spacious and easier to read
- Profile screen feels more polished and professional
- Consistent visual language across main app

**System** (see `Psst/agents/shared-standards.md`):
- Smooth 60fps scrolling in chat list (maintain existing performance)
- Button tap feedback <50ms
- No performance degradation from larger avatars
- Tab switching remains instant (<50ms)

**Quality**:
- 0 visual regressions
- All existing features work identically
- All acceptance gates pass
- Clean UI on all device sizes

---

## 5. Users & Stories

**Primary Users**: Active messaging app users browsing conversations and managing profile

**User Stories**:

1. **As a user**, I want the "new message" button to be obvious and thumb-friendly so that I can quickly start conversations without searching the nav bar.

2. **As a user browsing conversations**, I want larger profile photos and better spacing so that I can quickly scan my chat list and find the conversation I need.

3. **As a user**, I want to access my profile quickly from the conversations screen so that I don't have to switch tabs to see my own info.

4. **As a user viewing my profile**, I want a larger profile photo and better layout so that the screen feels polished and professional.

5. **As a user**, I want the app to feel cohesive with consistent colors and styling so that it feels like a professional product.

---

## 6. Experience Specification (UX)

### Entry Points

**Conversations Tab** (ChatListView):
- Default tab when app opens
- Main view: List of conversations
- New feature: FAB for new message
- New feature: User avatar in nav bar

**Profile Tab**:
- Accessed via tab bar (2nd tab)
- Main view: User profile info
- Enhanced layout with larger photo

### Visual Behavior

**Conversations Tab (ChatListView) - Enhanced Layout**:

**Before (Current)**:
```
┌─────────────────────────┐
│ Messages         [+]    │  ← Nav bar with button
│                         │
│ [50pt●] Sarah M         │  ← Small avatars
│ "Great!" 2m          ●  │
│                         │
│ [50pt] Team 2024        │
│ Mark: "Let's…" 1h    3  │
└─────────────────────────┘
```

**After (New)**:
```
┌─────────────────────────┐
│ [Nav●] Messages      •  │  ← User avatar left, unread badge right
│                         │
│ [56pt●] Sarah M         │  ← Larger avatars (50→56pt)
│ "Great session!" 2m  ●  │  ← Better spacing
│                         │
│ [56pt] Team 2024        │  ← Polish existing features
│ Mark: "Let's…" 1h    3  │  ← (online status, badges, etc.)
│                         │
│              [+]        │  ← FAB bottom-right
└─────────────────────────┘
```

**Key Changes**:

1. **Floating Action Button (FAB)**:
   - Position: Bottom-right corner, 16pt from edges
   - Size: 56pt diameter circle
   - Color: `.blue` (iOS accent)
   - Icon: SF Symbol `plus` (white, 24pt)
   - Shadow: Subtle elevation shadow for depth
   - Tap → Opens UserSelectionView (existing functionality)

2. **Navigation Bar Updates**:
   - Remove "+" button from nav bar (moved to FAB)
   - Add user avatar on left (32pt circle)
   - Tap avatar → Navigate to Profile tab
   - Keep "Messages" title
   - Add unread badge to avatar if there are unread messages

3. **Chat Row Enhancements**:
   - Avatar size: 50pt → 56pt (6pt larger)
   - Horizontal padding: Increase to 16pt (was tight)
   - Vertical padding: 12pt between rows (was 8pt)
   - All existing features remain: online status dots, unread badges, sender names, timestamps

4. **Empty State**:
   - When no conversations exist
   - Show centered message: "No conversations yet"
   - Show hint: "Tap + to start messaging"
   - Icon above text (SF Symbol `message`)

**Profile Tab - Enhanced Layout**:

**Before (Current)**:
```
┌─────────────────────────┐
│      Profile            │
│   [120pt Photo]         │  ← Medium photo
│      Sarah M            │
│  sarah@email.com        │
│                         │
│ [Edit Profile]          │
└─────────────────────────┘
```

**After (New)**:
```
┌─────────────────────────┐
│      Profile            │
│                         │
│   [140pt Photo]         │  ← Larger photo (120→140pt)
│      Sarah M            │  ← .title + .bold
│  sarah@email.com        │  ← .subheadline + .secondary
│                         │
│ [Edit Profile]          │  ← Blue button (matches style)
│                         │
│ Profile Details         │  ← .headline
│ ┌─────────────────────┐ │
│ │ 👤 User ID          │ │  ← Info cards
│ │ 📅 Member Since     │ │
│ └─────────────────────┘ │
└─────────────────────────┘
```

**Key Changes**:

1. **Profile Photo**:
   - Size: 120pt → 140pt (20pt larger)
   - Position: Top center with more breathing room
   - Padding: 32pt top padding (was 24pt)

2. **Typography Updates**:
   - Name: `.title` + `.bold` (was `.title2`)
   - Email: `.subheadline` + `.secondary` (consistent)
   - Section headers: `.headline`

3. **Button Styling**:
   - Use same blue button style from auth (PR #006A)
   - `.borderedProminent` style

4. **Layout Spacing**:
   - Increase spacing between elements (16pt → 24pt)
   - Better visual hierarchy
   - Cleaner, more spacious feel

**Tab Bar - Consistency Update**:

**Changes**:
- Accent color: `.blue` (iOS system blue)
- Selected tab: Blue indicator
- Unselected tab: `.secondary` gray
- Badge: Red badge on Conversations tab (if unread messages)

### Loading/Disabled/Error States

**Conversations Tab**:
- **Loading**: Skeleton rows while loading conversations
- **Empty**: "No conversations yet" message with FAB visible
- **Error**: "Unable to load conversations" with retry

**Profile Tab**:
- **Loading**: Skeleton UI while loading user data
- **Error**: "Unable to load profile" with retry button

**FAB**:
- **Disabled**: Not applicable (always active)
- **Pressed**: Scale animation (0.95x) for feedback

### Performance Targets

See `Psst/agents/shared-standards.md` for general targets. Specific to this feature:

- **Chat list scrolling**: Smooth 60fps with 100+ conversations
- **FAB tap feedback**: <50ms animation response
- **Avatar loading**: Cached, instant display
- **Tab switching**: <50ms transition

---

## 7. Functional Requirements (Must/Should)

### Must-Have Requirements

**R1**: "New message" button MUST move from nav bar to Floating Action Button (FAB)
- **Acceptance Gate**: FAB visible in bottom-right corner, tapping opens UserSelectionView

**R2**: FAB MUST be positioned properly on all device sizes
- **Acceptance Gate**: FAB 16pt from bottom and right edges on iPhone SE through Pro Max

**R3**: Avatar size MUST increase from 50pt to 56pt in chat list
- **Acceptance Gate**: Chat row avatars measure 56pt in all conversation rows

**R4**: User avatar MUST appear in Conversations nav bar
- **Acceptance Gate**: 32pt user avatar visible in nav bar, tapping navigates to Profile tab

**R5**: All existing features MUST continue working (online status, unread badges, sender names)
- **Acceptance Gate**: Online dots, unread badges, sender names display correctly after UI changes

**R6**: Profile photo MUST increase from 120pt to 140pt
- **Acceptance Gate**: Profile photo measures 140pt on Profile tab

**R7**: Tab bar MUST use consistent `.blue` accent color
- **Acceptance Gate**: Selected tab shows blue indicator, matches iOS standard

**R8**: Spacing MUST follow 8pt/16pt/24pt grid consistently
- **Acceptance Gate**: All padding and spacing uses multiples of 8pt

### Should-Have Requirements

**R9**: FAB SHOULD have subtle shadow for elevation effect
- **Acceptance Gate**: FAB appears to "float" above content with subtle shadow

**R10**: Chat row spacing SHOULD improve readability
- **Acceptance Gate**: Rows feel more spacious, easier to scan visually

**R11**: Empty state SHOULD guide users to FAB
- **Acceptance Gate**: Empty state message mentions "Tap + to start messaging"

**R12**: Transitions SHOULD be smooth (60fps)
- **Acceptance Gate**: No dropped frames during scrolling or tab switching

---

## 8. Data Model

**No data model changes required.** This is a pure UI polish update using existing data.

**Existing Models Used**:
- `Chat` - conversation data (no changes)
- `User` - user profile data (no changes)
- `Message` - for read/unread status (no changes)

---

## 9. API / Service Contracts

**No new service methods required.** This PR only changes the UI layer.

**Existing Services Used**:

```swift
// From ChatService (no changes)
func observeChats(for userID: String, completion: @escaping ([Chat]) -> Void) -> ListenerRegistration

// From UserService (no changes)
func getUser(userID: String) async throws -> User
func getCurrentUser() async throws -> User

// From PresenceService (no changes)
func observePresence(for userID: String, completion: @escaping (UserPresence?) -> Void) -> ListenerRegistration
```

---

## 10. UI Components to Create/Modify

### Files to Modify

**Conversations Tab** (3 files):
- `Views/ChatList/ChatListView.swift` — Add FAB, update nav bar with user avatar, improve layout
- `Views/ChatList/ChatRowView.swift` — Increase avatar size to 56pt, improve spacing
- `Views/Components/FloatingActionButton.swift` — Create new FAB component (new file)

**Profile Tab** (1 file):
- `Views/Profile/ProfileView.swift` — Larger photo (140pt), update layout/spacing, apply button styles

**Navigation** (1 file):
- `Views/MainTabView.swift` — Update tab bar accent color to `.blue`

**Shared Components** (1 file):
- `Views/Components/UserAvatarView.swift` — Ensure it supports variable sizes (32pt, 56pt, 140pt)

### Components Breakdown

**FloatingActionButton.swift** (new file):
```swift
// Reusable FAB component
struct FloatingActionButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color.blue)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
    }
}
```

**ChatListView.swift**:
- Remove `+` button from `.toolbar`
- Add user avatar to nav bar (left side)
- Add FAB using `.overlay` or `ZStack`
- Position FAB: `.bottomTrailing` with 16pt padding
- Improve empty state UI

**ChatRowView.swift**:
- Increase avatar size: 50pt → 56pt
- Increase horizontal padding: 12pt → 16pt
- Increase vertical padding: 8pt → 12pt
- Keep all existing logic (online status, unread badges, sender names)

**ProfileView.swift**:
- Increase photo size: 120pt → 140pt
- Update typography (`.title` for name)
- Apply button style from PR #006A
- Increase spacing (16pt → 24pt between elements)
- Better visual hierarchy

**MainTabView.swift**:
- Set `.tint(.blue)` for tab bar accent color

---

## 11. Integration Points

### Existing Integrations (No Changes)
- **Firebase Realtime Database**: Presence system (online status)
- **Firestore**: Chat and user data
- **Navigation**: Existing NavigationStack and tab navigation

### Design Consistency
- Uses design system from PR #006A:
  - Color: `.blue` accent
  - Typography: iOS text styles
  - Spacing: 8pt/16pt/24pt grid
  - Button styles: Reuses button styles from auth

---

## 12. Testing Plan & Acceptance Gates

### Configuration Testing
- [ ] Firebase connections work (no regressions)
- [ ] Real-time listeners still active
- [ ] Presence system works after UI changes

### Visual Testing
- [ ] FAB appears in bottom-right corner
- [ ] FAB is 56pt diameter, blue, with shadow
- [ ] Nav bar shows user avatar (32pt) on left
- [ ] Chat rows show 56pt avatars
- [ ] Chat rows have improved spacing (16pt horizontal, 12pt vertical)
- [ ] Profile photo is 140pt
- [ ] Profile layout has 24pt spacing
- [ ] Tab bar uses blue accent color
- [ ] All existing features visible: online status, unread badges, sender names

### Happy Path Testing
- [ ] Gate: Tap FAB → UserSelectionView opens
- [ ] Gate: Tap user avatar in nav bar → Navigate to Profile tab
- [ ] Gate: Scroll chat list → Smooth 60fps with 100+ conversations
- [ ] Gate: Switch between tabs → Instant (<50ms) transition
- [ ] Gate: Tap chat row → Opens ChatView (existing functionality)

### Edge Cases Testing
- [ ] Empty chat list → Shows "No conversations yet" with visible FAB
- [ ] Small device (iPhone SE) → FAB doesn't overlap content
- [ ] Large device (Pro Max) → FAB positioned correctly
- [ ] Landscape mode → FAB visible and accessible
- [ ] Many unread messages → Badge displays correctly on nav avatar

### Multi-Device Testing
- [ ] iPhone SE → Layout works, FAB accessible
- [ ] iPhone 15 → Layout works perfectly
- [ ] iPhone 15 Pro Max → Layout works, no awkward spacing
- [ ] Dark Mode → All colors adapt correctly

### Performance Testing
- [ ] Chat list scrolling: Smooth 60fps with 100+ rows
- [ ] FAB tap feedback: <50ms animation
- [ ] Tab switching: <50ms transition
- [ ] No memory leaks from larger avatars
- [ ] Avatar images cached properly

### Feature Regression Testing
- [ ] Online status dots still show correctly
- [ ] Unread badges still show correct count
- [ ] Sender names still show in group chats
- [ ] Timestamps still display correctly
- [ ] Real-time updates still work (<100ms)
- [ ] Long-press gestures still work (if any)

---

## 13. Definition of Done

- [ ] Floating Action Button (FAB) implemented and positioned correctly
- [ ] "New message" button removed from nav bar
- [ ] User avatar added to nav bar (tappable)
- [ ] Avatar sizes increased (chat: 56pt, profile: 140pt)
- [ ] Spacing improved throughout (follows grid)
- [ ] Profile layout enhanced
- [ ] Tab bar uses blue accent color
- [ ] All existing features work (0 regressions)
- [ ] Manual testing completed (all gates pass)
- [ ] Code review completed
- [ ] Design reviewed and approved (matches UX spec)
- [ ] Performance verified (60fps scrolling, <50ms taps)

---

## 14. Risks & Mitigations

**Risk**: FAB overlaps content in chat list on small devices
- **Mitigation**: Add bottom padding to chat list (.padding(.bottom, 72)) to prevent overlap

**Risk**: Larger avatars (56pt) impact scrolling performance
- **Mitigation**: Already using LazyVStack; test with 100+ conversations; implement image caching

**Risk**: Nav bar becomes too crowded with user avatar
- **Mitigation**: Use 32pt avatar (small), minimal spacing, remove unnecessary nav items

**Risk**: FAB shadow causes rendering performance issues
- **Mitigation**: Use simple shadow (low blur radius), test on device, optimize if needed

**Risk**: Users don't discover FAB (expect nav bar button)
- **Mitigation**: Empty state explicitly mentions "Tap + to start messaging"

**Risk**: Tab bar color change conflicts with other UI
- **Mitigation**: Blue is iOS standard, established in PR #006A, should be consistent

---

## 15. Rollout & Telemetry

**Feature Flag**: No

**Rollout Strategy**: 
- Deploy as part of PR #006B
- Visual improvements with no functionality changes
- No gradual rollout needed

**Manual Validation**:
- Test FAB on all device sizes
- Verify scrolling performance with many conversations
- Test Dark Mode appearance
- Screenshot before/after for documentation

**Success Indicators**:
- 0 UI-related bug reports
- Improved visual consistency
- Maintains <100ms message delivery latency
- Smooth 60fps scrolling

---

## 16. Open Questions

**Q1**: Should FAB have a label (e.g., "New Message") or just the + icon?
- **Answer**: Just icon (cleaner, standard pattern)

**Q2**: Should nav bar avatar show online status dot?
- **Answer**: No (too small, not necessary for own avatar)

**Q3**: Should FAB hide when scrolling down (auto-hide)?
- **Answer**: No (always visible is simpler, more discoverable)

**Q4**: Should empty state show onboarding hints?
- **Answer**: Yes, simple hint: "Tap + to start messaging"

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future:
- [ ] FAB auto-hide on scroll (not needed for MVP)
- [ ] FAB long-press menu (shortcuts to specific actions) (Phase 2)
- [ ] Profile edit inline editing (keep existing EditProfileView) (Phase 2)
- [ ] Customizable tab bar order (Phase 3)
- [ ] Conversation list search/filter (Phase 2)
- [ ] Conversation pinning (Phase 2)

---

## Preflight Questionnaire

1. **Smallest end-to-end user outcome for this PR?**
   - User sees polished main app UI with discoverable FAB and better visual hierarchy

2. **Primary user and critical action?**
   - Active users browsing conversations and starting new chats

3. **Must-have vs nice-to-have?**
   - Must: FAB, larger avatars, nav bar avatar, consistent spacing
   - Nice: Shadows, sophisticated empty states, animations

4. **Real-time requirements?**
   - Maintain existing <100ms message sync (no performance degradation)

5. **Performance constraints?**
   - Smooth 60fps scrolling, <50ms tap feedback

6. **Error/edge cases to handle?**
   - Empty chat list, small devices, landscape, many conversations

7. **Data model changes?**
   - None (UI only)

8. **Service APIs required?**
   - None (uses existing services)

9. **UI entry points and states?**
   - Conversations tab (main view), Profile tab, tab bar
   - States: Default, empty, loading, error

10. **Security/permissions implications?**
    - None

11. **Dependencies or blocking integrations?**
    - Depends on: PR #006A (design system)
    - Blocks: PR #006C (Settings - needs tab bar styling)

12. **Rollout strategy and metrics?**
    - Deploy directly, no gradual rollout
    - Success: 0 regressions, improved discoverability

13. **What is explicitly out of scope?**
    - New features, ChatView changes, search, pinning, auto-hide FAB

---

**End of PRD**

