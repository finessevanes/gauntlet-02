# PR-006B TODO — Main App UI Polish - Conversations & Profile

**Branch**: `feat/pr-006b-main-app-ui-polish`  
**Source PRD**: `Psst/docs/prds/pr-006b-prd.md`  
**Owner (Agent)**: Caleb

---

## 0. Clarifying Questions & Assumptions

- **Questions**: None - this is a clear UI polish update
- **Assumptions (confirm in PR if needed)**:
  - All existing features work unchanged (online status, unread badges, sender names, typing indicators)
  - Uses design system from PR #006A (ButtonStyles, colors, typography, spacing grid)
  - FAB replaces nav bar "+" button functionality (opens same UserSelectionView)
  - PR #006A is merged before starting this PR (depends on ButtonStyles and design system)

---

## 1. Setup

  - Test Gate: ButtonStyles.swift exists and is accessible
- [ ] Read PRD thoroughly (`Psst/docs/prds/pr-006b-prd.md`)
- [ ] Read `Psst/agents/shared-standards.md` for patterns
- [ ] Read UX spec (`Psst/docs/ux-specs/pr-006-ux-spec.md` sections 2-3)
- [ ] Confirm environment and test runner work

---

## 2. Service Layer

No new service methods needed. This is a UI-only polish that uses existing services.

- [ ] Verify existing ChatService methods work correctly
  - Test Gate: Chat list loading, real-time updates work unchanged
- [ ] Verify existing UserService methods work correctly
  - Test Gate: User data fetching works unchanged
- [ ] Verify existing PresenceService methods work correctly
  - Test Gate: Online status indicators work unchanged
- [ ] Confirm no changes needed to existing service contracts
  - Test Gate: All existing functionality continues to work identically

---

## 3. Data Model & Rules

No changes to existing data models. This is a UI-only change.

- [ ] Confirm existing Chat model is sufficient
  - Test Gate: No data model changes needed
- [ ] Confirm existing User model is sufficient
  - Test Gate: No data model changes needed
- [ ] Confirm existing Message model is sufficient
  - Test Gate: No data model changes needed
- [ ] Verify Firebase security rules unchanged
  - Test Gate: Existing permissions work correctly

---

## 4. UI Components

Create/modify SwiftUI views per PRD Section 10.

### Create FloatingActionButton.swift (New File)

- [ ] Create `Views/Components/FloatingActionButton.swift`
  - Test Gate: File created in correct location
- [ ] Implement FAB component structure
  - 56pt diameter circle
  - Blue background (Color.blue)
  - White plus icon (SF Symbol "plus", 24pt, semibold)
  - Tap action closure parameter
  - Test Gate: Basic structure implemented
- [ ] Add shadow for elevation effect
  - Shadow: color .black.opacity(0.2), radius 8, x: 0, y: 4
  - Test Gate: FAB appears to float above content
- [ ] Add tap animation (scale effect)
  - Scale to 0.95x when pressed for feedback
  - Test Gate: FAB responds visually to taps
- [ ] Add SwiftUI Preview
  - Test Gate: Preview renders FAB with shadow correctly
- [ ] Test Dark Mode compatibility
  - Test Gate: FAB adapts to Dark Mode (blue remains visible)

### Modify ChatListView.swift

- [ ] Remove "+" button from nav bar toolbar
  - Find and remove toolbar button
  - Test Gate: No "+" button visible in nav bar
- [ ] Add user avatar to nav bar (leading position)
  - Use UserAvatarView at 32pt size
  - Position in .toolbar, .navigationBarLeading
  - Test Gate: 32pt user avatar visible on left side of nav bar
- [ ] Wire nav bar avatar tap to navigate to Profile tab
  - Wrap avatar in Button or use .onTapGesture
  - Switch to Profile tab (tab index change)
  - Test Gate: Tapping nav avatar switches to Profile tab
- [ ] Add FAB to view using overlay or ZStack
  - Position at .bottomTrailing
  - 16pt padding from bottom and right edges
  - Test Gate: FAB appears in bottom-right corner
- [ ] Wire FAB tap to open UserSelectionView
  - Use existing navigation to UserSelectionView
  - Test Gate: Tapping FAB opens UserSelectionView (same as old button)
- [ ] Add bottom padding to chat list (72pt)
  - Prevents FAB from overlapping last chat row
  - Test Gate: Last chat row visible above FAB
- [ ] Improve empty state UI
  - Show "No conversations yet" message
  - Add "Tap + to start messaging" hint
  - Use centered VStack with SF Symbol "message" icon
  - Test Gate: Empty state looks professional and guides to FAB
- [ ] Test SwiftUI Preview
  - Test Gate: Preview shows FAB, nav avatar, improved layout, zero console errors
- [ ] Test Dark Mode
  - Test Gate: All elements adapt correctly to Dark Mode

### Modify ChatRowView.swift

- [ ] Increase avatar size from 50pt to 56pt
  - Update UserAvatarView size parameter
  - Test Gate: Avatar measures 56pt in chat rows
- [ ] Increase horizontal padding from 12pt to 16pt
  - Update .padding(.horizontal, 16)
  - Test Gate: Rows have more horizontal breathing room
- [ ] Increase vertical padding from 8pt to 12pt
  - Update .padding(.vertical, 12)
  - Test Gate: Rows have more vertical spacing
- [ ] Verify all existing logic remains unchanged
  - Online status dots still show
  - Unread badges still show
  - Sender names still show (group chats)
  - Timestamps still show
  - Test Gate: All existing features display correctly
- [ ] Test SwiftUI Preview
  - Test Gate: Preview shows larger avatars and better spacing, zero console errors
- [ ] Test Dark Mode
  - Test Gate: Chat rows adapt correctly to Dark Mode

### Modify ProfileView.swift

- [ ] Increase profile photo from 120pt to 140pt
  - Update UserAvatarView or profile photo size parameter
  - Test Gate: Profile photo measures 140pt
- [ ] Update name typography
  - Change to .font(.title) + .fontWeight(.bold)
  - Test Gate: Name uses .title font with bold weight
- [ ] Update email typography
  - Change to .font(.subheadline) + .foregroundColor(.secondary)
  - Test Gate: Email uses subheadline font with secondary color
- [ ] Apply PrimaryButtonStyle to "Edit Profile" button
  - Import ButtonStyles from PR #006A if needed
  - Apply .buttonStyle(PrimaryButtonStyle())
  - Test Gate: Button is blue with prominent style (matches auth screens)
- [ ] Increase spacing between elements
  - Change from 16pt to 24pt spacing in VStack
  - Test Gate: Elements have 24pt spacing
- [ ] Increase top padding
  - Change from 24pt to 32pt padding(.top, 32)
  - Test Gate: Profile photo has more top breathing room
- [ ] Test SwiftUI Preview
  - Test Gate: Preview shows larger photo, better spacing, styled button, zero console errors
- [ ] Test Dark Mode
  - Test Gate: Profile view adapts correctly to Dark Mode

### Modify MainTabView.swift

- [ ] Add `.tint(.blue)` to TabView
  - Apply tint modifier to TabView
  - Test Gate: Selected tab shows blue indicator
- [ ] Verify badge support on Conversations tab
  - Ensure .badge() modifier works if present
  - Test Gate: Badge displays on tab icon if there are unread messages
- [ ] Test SwiftUI Preview (if available)
  - Test Gate: Preview shows blue accent on selected tab
- [ ] Test Dark Mode
  - Test Gate: Tab bar adapts correctly to Dark Mode with blue accent

### Update UserAvatarView.swift (If Needed)

- [ ] Check if UserAvatarView supports variable sizes
  - Test with 32pt, 56pt, 140pt sizes
  - Test Gate: Avatar renders correctly at all three sizes
- [ ] If needed, update to support flexible sizing
  - Ensure size parameter is used correctly
  - Test Gate: Avatar scales properly without distortion
- [ ] Test with and without profile photos
  - With photo: displays circular image
  - Without photo: displays initials or placeholder
  - Test Gate: Both cases render correctly at all sizes
- [ ] Test Dark Mode
  - Test Gate: Avatar adapts to Dark Mode

---

## 5. Integration & Real-Time

Reference requirements from `Psst/agents/shared-standards.md`.

- [ ] Firebase Realtime Database (presence) integration unchanged
  - Test Gate: Online status indicators work after UI changes
- [ ] Firestore integration unchanged
  - Test Gate: Chat list and user data load correctly
- [ ] Real-time listeners working
  - Test Gate: New messages appear in real-time (<100ms)
  - Test Gate: Online status updates in real-time
- [ ] Navigation works correctly
  - Test Gate: FAB opens UserSelectionView
  - Test Gate: Nav bar avatar navigates to Profile tab
  - Test Gate: Chat row tap opens ChatView
  - Test Gate: Tab bar switches tabs
- [ ] All existing features functional
  - Test Gate: Typing indicators work (if present)
  - Test Gate: Unread badges update correctly
  - Test Gate: Sender names show in group chats

---

## 6. Testing Validation

**Current**: Manual testing validation (see `Psst/agents/shared-standards.md`)  
**Future**: Automated testing recommendations in `Psst/docs/testing-strategy.md`

### Configuration Testing

- [ ] Firebase connections work (no regressions)
  - Test Gate: Firestore connected, no errors
  - Test Gate: Realtime Database connected for presence
- [ ] Real-time listeners active
  - Test Gate: Chat list updates in real-time
  - Test Gate: Presence updates in real-time
- [ ] Presence system works after UI changes
  - Test Gate: Online status dots display correctly
  
### Visual Testing

- [ ] FAB appears in bottom-right corner
  - Test Gate: FAB 16pt from bottom and right edges
- [ ] FAB is 56pt diameter, blue, with shadow
  - Test Gate: FAB matches design spec (blue circle, white plus icon, shadow)
- [ ] Nav bar shows user avatar (32pt) on left
  - Test Gate: User avatar visible in nav bar leading position
- [ ] No "+" button in nav bar toolbar
  - Test Gate: Old button removed, only avatar and title visible
- [ ] Chat rows show 56pt avatars
  - Test Gate: Avatars larger and more prominent
- [ ] Chat rows have improved spacing
  - Test Gate: 16pt horizontal, 12pt vertical padding
- [ ] Profile photo is 140pt
  - Test Gate: Profile photo larger and more prominent
- [ ] Profile spacing is 24pt between elements
  - Test Gate: Profile layout feels more spacious
- [ ] Tab bar uses blue accent color
  - Test Gate: Selected tab shows blue indicator
- [ ] All existing features visible
  - Test Gate: Online status dots, unread badges, sender names, timestamps all display
- [ ] Dark Mode: All elements adapt correctly
  - Test Gate: Toggle Dark Mode, all new UI elements look good

### Happy Path Testing

- [ ] Gate: Tap FAB → UserSelectionView opens
- [ ] Gate: Select user from UserSelectionView → Creates/opens chat
- [ ] Gate: Tap nav bar avatar → Navigate to Profile tab
- [ ] Gate: Switch back to Conversations tab → Returns to chat list
- [ ] Gate: Scroll chat list → Smooth 60fps with 100+ conversations
- [ ] Gate: Tap chat row → Opens ChatView correctly
- [ ] Gate: Switch between tabs → Instant (<50ms) transition
- [ ] Gate: FAB visible on all screens (doesn't disappear)

### Edge Cases Testing

- [ ] Empty chat list → Shows "No conversations yet" with FAB visible
  - Test Gate: Empty state message mentions "Tap + to start messaging"
- [ ] Small device (iPhone SE) → FAB doesn't overlap content
  - Test Gate: FAB accessible, doesn't cover last chat row
- [ ] Large device (iPhone 15 Pro Max) → FAB positioned correctly
  - Test Gate: FAB in bottom-right, not awkwardly placed
- [ ] Landscape orientation → FAB visible and accessible
  - Test Gate: FAB remains in bottom-right in landscape
- [ ] Many unread messages → Badge displays on nav avatar (if implemented)
  - Test Gate: Badge visible and readable
- [ ] No profile photo → Avatar shows initials or placeholder
  - Test Gate: Nav bar and profile work without photos
- [ ] Very long user name → Text truncates properly
  - Test Gate: UI doesn't break with long names

### Multi-Device Testing

- [ ] iPhone SE (small screen) → Layout works, FAB accessible
  - Test Gate: All content visible and usable
- [ ] iPhone 15 → Layout works perfectly
  - Test Gate: Optimal spacing and proportions
- [ ] iPhone 15 Pro Max (large screen) → Layout works, good spacing
  - Test Gate: No awkward stretching or gaps
- [ ] Landscape on all devices → FAB and layout adapt
  - Test Gate: Landscape mode usable
- [ ] Dark Mode on all devices → Proper contrast and readability
  - Test Gate: Dark Mode looks good on all device sizes

### Performance Testing

- [ ] Chat list scrolling: Smooth 60fps with 100+ conversations
  - Test Gate: No lag or stuttering when scrolling
- [ ] FAB tap feedback: <50ms animation response
  - Test Gate: Immediate visual response on tap
- [ ] Tab switching: <50ms transition
  - Test Gate: Instant tab changes
- [ ] No memory leaks from larger avatars
  - Test Gate: Monitor memory usage, no unusual growth
- [ ] Avatar caching works
  - Test Gate: Avatars load instantly when cached
  - Test Gate: No repeated network requests for same avatar

### Feature Regression Testing

- [ ] All existing chat list features work
  - Test Gate: Real-time updates <100ms
  - Test Gate: Online status dots work
  - Test Gate: Unread badges work
  - Test Gate: Sender names show in group chats
  - Test Gate: Timestamps display correctly
  - Test Gate: Typing indicators work (if present)
- [ ] Profile features work
  - Test Gate: Edit Profile navigation works
  - Test Gate: Profile data loads correctly
  - Test Gate: Logout still works
- [ ] Navigation works
  - Test Gate: All tab switches work
  - Test Gate: All screen transitions work
  - Test Gate: Back navigation works
- [ ] No console errors or warnings
  - Test Gate: Clean console output during all flows

---

## 7. Performance

Verify targets from `Psst/agents/shared-standards.md`.

- [ ] Chat list scrolling smooth 60fps
  - Test Gate: Scroll 100+ conversations with no dropped frames
- [ ] FAB tap feedback < 50ms
  - Test Gate: Immediate scale animation on tap
- [ ] Tab switching < 50ms
  - Test Gate: Instant tab transitions
- [ ] Avatar loading optimized
  - Test Gate: Cached avatars load instantly
  - Test Gate: New avatars load smoothly without blocking UI
- [ ] No performance degradation from UI changes
  - Test Gate: App feels as fast or faster than before
- [ ] No memory leaks
  - Test Gate: Memory usage stable during extended use

---

## 8. Acceptance Gates

Check every gate from PRD Section 12:

### Functional Acceptance Gates

- [ ] R1: FAB visible in bottom-right corner, tapping opens UserSelectionView
- [ ] R2: FAB 16pt from bottom and right edges on all device sizes
- [ ] R3: Chat row avatars measure 56pt
- [ ] R4: 32pt user avatar visible in nav bar, tapping navigates to Profile tab
- [ ] R5: Online dots, unread badges, sender names display correctly
- [ ] R6: Profile photo measures 140pt
- [ ] R7: Selected tab shows blue indicator
- [ ] R8: All padding and spacing uses 8pt/16pt/24pt grid

### Visual Acceptance Gates

- [ ] R9: FAB has subtle shadow for elevation effect
- [ ] R10: Chat rows feel more spacious and easier to scan
- [ ] R11: Empty state mentions "Tap + to start messaging"
- [ ] R12: No dropped frames during scrolling or tab switching

### Performance Acceptance Gates

- [ ] Chat list scrolling: 60fps with 100+ conversations
- [ ] FAB tap: <50ms response
- [ ] Tab switching: <50ms
- [ ] Avatar loading: Cached instantly, new smoothly

### Multi-Device Acceptance Gates

- [ ] iPhone SE: Layout works, FAB accessible
- [ ] iPhone 15 Pro Max: Layout works, good spacing
- [ ] Dark Mode: All elements correct on all devices

---

## 9. Documentation & PR

- [ ] Add inline code comments for FAB implementation
  - Explain FAB positioning and overlay logic
- [ ] Add comments for any complex layout changes (if needed)
- [ ] No README changes needed (UI-only polish)
- [ ] Create PR description (use format from Psst/agents/caleb-agent.md)
  - Include before/after screenshots of chat list and profile
  - Highlight FAB, larger avatars, improved spacing
  - Note: Uses design system from PR #006A
  - List all visual changes
- [ ] Verify with user before creating PR
- [ ] Open PR targeting develop branch
- [ ] Link PRD and TODO in PR description

---

## Copyable Checklist (for PR description)

```markdown
## PR #006B: Main App UI Polish - Conversations & Profile

### Changes
- ✅ Added Floating Action Button (FAB) for new messages
- ✅ Removed "+" button from nav bar (replaced by FAB)
- ✅ Added user avatar to nav bar (32pt, tappable → Profile)
- ✅ Increased chat row avatars (50pt → 56pt)
- ✅ Improved chat row spacing (16pt horizontal, 12pt vertical)
- ✅ Increased profile photo (120pt → 140pt)
- ✅ Enhanced profile layout and spacing (24pt between elements)
- ✅ Applied blue accent to tab bar
- ✅ Improved empty state with helpful hint

### Files Modified
- `Views/ChatList/ChatListView.swift` - FAB, nav avatar, improved layout
- `Views/ChatList/ChatRowView.swift` - Larger avatars, better spacing
- `Views/Profile/ProfileView.swift` - Larger photo, better spacing, styled button
- `Views/MainTabView.swift` - Blue accent color

### Files Created
- `Views/Components/FloatingActionButton.swift` - Reusable FAB component

### Files Updated (if needed)
- `Views/Components/UserAvatarView.swift` - Support for variable sizes (32pt, 56pt, 140pt)

### Testing Completed
- [ ] Branch created from develop (after PR #006A merged)
- [ ] All TODO tasks completed
- [ ] All 4-5 files modified/created
- [ ] FAB implemented and functional
- [ ] Firebase integration verified (real-time sync, presence)
- [ ] Manual testing completed (all flows, edge cases, multi-device)
- [ ] Dark Mode verified on all screens
- [ ] Performance targets met (60fps scrolling, <50ms taps)
- [ ] All acceptance gates pass (functional, visual, performance)
- [ ] Code follows Psst/agents/shared-standards.md patterns
- [ ] No console warnings or errors
- [ ] Zero regressions (all existing features work)

### Design System Consistency
Uses design system from PR #006A:
- Color: `.blue` accent
- Typography: iOS text styles
- Button styles: PrimaryButtonStyle
- Spacing grid: 8pt/16pt/24pt

### User Experience Improvements
- FAB more discoverable than nav bar button
- Larger avatars improve visual hierarchy
- Better spacing improves readability
- Nav bar avatar provides quick Profile access
- Consistent blue accent across app

### Links
- PRD: `Psst/docs/prds/pr-006b-prd.md`
- TODO: `Psst/docs/todos/pr-006b-todo.md`
- UX Spec: `Psst/docs/ux-specs/pr-006-ux-spec.md` (sections 2-3)
- Depends on: PR #006A (design system)
```

---

## Notes

- Break tasks into < 30 min chunks
- Complete tasks sequentially (Setup → FAB → ChatListView → ChatRowView → ProfileView → MainTabView → Testing)
- Check off after completion
- Document blockers immediately
- Reference `Psst/agents/shared-standards.md` for common patterns and solutions
- This is a UI polish update - no new features, just improving existing ones
- Focus on visual hierarchy and discoverability (FAB, larger avatars, better spacing)
- All existing functionality must work identically
- Depends on PR #006A being merged (uses ButtonStyles and design system)
- FAB replaces nav bar button but opens same UserSelectionView
- Keep all existing features functional: online status, unread badges, sender names, typing indicators

