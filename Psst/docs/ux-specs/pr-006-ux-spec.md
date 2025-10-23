# UX Specification: Complete App Design System & UI Overhaul

**PR #006** | **Created by:** Claudia (UX Expert) | **Date:** October 23, 2025

---

## 🎯 Design Goal

Create a **unified, clean design system** for a messaging app with Signal vibes. Currently, the app has inconsistent design - elaborate gradients on auth screens, basic placeholders in settings, and standard iOS patterns elsewhere. This PR redesigns ALL screens to work cohesively together.

**App Vibe:** Simple, clean messaging app like Signal - no-nonsense. Design must be clean, trustworthy, and work well for both 1-on-1 and group conversations.

**Scope:** All major screens - Auth (3), Conversations tab, Profile tab, Settings tab, Navigation

**Important:** This is a **pure UI/UX redesign** - NO new features, just polishing and reorganizing what already exists!

---

## 🎨 Unified Design System

### Design Principles

1. **Simple & Clean** - Signal-like aesthetic, no clutter
2. **Consistency Everywhere** - Same visual language across all screens
3. **iOS Native** - Leverage familiar, battle-tested patterns
4. **Privacy First** - Trustworthy, secure feel (like Signal)
5. **Scalable** - Works for 1-on-1 and group conversations

### Color Palette

**Use iOS System Colors:**
- Primary accent: `Color.blue` (iOS blue #007AFF)
- Backgrounds: `.systemBackground`, `.secondarySystemBackground`
- Text: `.label`, `.secondaryLabel`, `.tertiaryLabel`
- Buttons: `.blue` (primary), `.systemGray6` (secondary), `.red` (destructive)

**Remove:**
- ❌ Custom green palette
- ❌ Weather app gradients
- ❌ Complex card shadows

### Typography

**Use Standard iOS Fonts:**
- Display: `.largeTitle` + `.bold`
- Headings: `.title2` + `.semibold`
- Body: `.body`
- Secondary: `.subheadline` + `.secondary`
- Captions: `.caption`
- Buttons: `.headline`

### Spacing & Layout

- Standard grid: 8pt, 16pt, 24pt, 32pt
- Horizontal padding: 24pt
- Vertical padding: 16pt
- Corner radius: 8pt (small), 12pt (medium)

---

## 📱 Screen Redesigns

### 1. Authentication Screens

**LoginView - Simplified:**
```
┌─────────────────────────┐
│    [Simple Icon]        │
│   Welcome Back          │
│  Sign in to continue    │
│                         │
│  [Continue with Email]  │ ← Blue button
│  [Continue with Google] │ ← Gray button
│                         │
│   Don't have account?   │
│      Sign up            │ ← Link
└─────────────────────────┘
```

**Changes:**
- Remove gradient background → white
- Remove card container & shadows
- Remove colored icon circles
- Standard iOS spacing
- Match main app aesthetic

**SignUpView - Standard Form:**
- Remove gradient → white background
- Use standard iOS text fields
- Standard navigation bar
- Same button styling as login

**EmailSignInView - Minimal Modal:**
- Remove gradient & decorative elements
- Simple form (email, password, forgot link)
- Standard styling

---

### 2. Conversations Tab (ChatListView) - VISUAL POLISH

**Enhanced Layout:**
```
┌─────────────────────────┐
│ [Avatar] Messages    •  │ ← Nav: Avatar, title
│                         │
│ [Photo●] Sarah M        │ ← Polished rows:
│ "Great session!" 2m  ●  │   - Larger avatars (56pt)
│                         │   - Online status (exists)
│ [Group] Team 2024       │   - Unread badges (exists)
│ Mark: "Let's…" 1h    3  │   - Sender names (exists)
│                         │
│              [+]        │ ← Floating Action Button
└─────────────────────────┘
```

**Visual Changes (NO new features):**
- **Floating Action Button (FAB)** - move existing "new message" button from nav bar
- Larger avatars (50pt → 56pt) - polish existing avatar display
- Better spacing and layout - improve existing chat rows
- User avatar in nav bar - visual addition (tap → profile)
- Improved empty state - better messaging

**Note:** Online status, unread badges, and sender names already exist - just making them look better!

**Why FAB?**
- More discoverable
- Thumb-friendly on large phones
- Common in messaging apps
- Always visible

---

### 3. Profile Tab - Enhanced

**Improved Layout:**
```
┌─────────────────────────┐
│      Profile            │
│                         │
│   [Large Photo 140pt]   │ ← Bigger, centered
│      Sarah Mitchell     │ ← .title + .bold
│  sarah@email.com        │ ← .subheadline + .secondary
│                         │
│   [Edit Profile]        │ ← Blue button (full width)
│                         │
│ Account Information     │ ← Section header
│ ┌─────────────────────┐ │
│ │ 👤 User ID          │ │ ← InfoRow component
│ │ abc123...           │ │
│ │                     │ │
│ │ 📅 Member Since     │ │
│ │ Jan 15, 2025        │ │
│ └─────────────────────┘ │
│                         │
└─────────────────────────┘
```

**Design Details:**

**Profile Photo:**
- Size: 140pt (up from 120pt for better presence)
- Circular with subtle border (1pt, `.quaternaryLabel`)
- Top padding: 32pt from nav bar
- If no photo: Initials on `.systemGray5` background

**Name & Email:**
- Name: `.title` + `.bold` + `.label`
- Email: `.subheadline` + `.secondary`
- Spacing: 4pt between name and email
- Center aligned
- 8pt spacing below email

**Edit Profile Button:**
- Style: `PrimaryButtonStyle()` (blue, rounded)
- Full width with 24pt horizontal padding
- 16pt padding from email above
- Icon: `pencil` SF Symbol (leading)
- Height: 44pt minimum (touch target)

**Account Information Section:**
- Header: `.headline` + `.label`, 24pt horizontal padding
- Card: White background (`.systemBackground`), 12pt corner radius
- Padding: 24pt horizontal, 16pt from header
- Rows: Use existing `ProfileInfoRow` component
  - Icon: 20pt SF Symbol, blue accent
  - Label: `.caption` + `.secondary`
  - Value: `.body` + `.label`
  - Row height: 44pt minimum
  - Divider between rows (leading padding 56pt)

**Spacing:**
- Top: 20pt spacer
- Photo to Name: 16pt
- Button to Section: 32pt
- Section header to card: 16pt

**Changes from Current:**
- ✅ Larger photo (120pt → 140pt)
- ✅ Better vertical spacing
- ✅ Consistent button styling (matches design system)
- ✅ Better visual hierarchy with typography
- ✅ Cleaner info card design

---

### 4. Settings Tab - Complete Redesign

**iOS-Style List:**
```
┌─────────────────────────┐
│      Settings           │
│                         │
│ [Photo] Sarah M         │ ← User info
│ sarah@email.com         │
│                         │
│ Account                 │ ← Grouped sections
│ ► Notifications         │
│                         │
│ Support                 │
│ ► Help & Support        │
│ ► About                 │
│                         │
│ [Log Out]               │ ← Red, destructive
└─────────────────────────┘
```

**Changes:**
- Replace centered placeholder → professional iOS List
- Grouped list style with sections
- User info at top
- `Label` + SF Symbols
- `NavigationLink` for navigation
- Keep logout red

**Note:** Edit Profile is in Profile Tab only (no duplication)

---

### 5. New Chat Sheet - Complete Redesign

**Current Issues:**
- ❌ Segmented control looks dated (iOS 6 style)
- ❌ Inconsistent typography
- ❌ User rows need better spacing
- ❌ Search bar placement unclear
- ❌ No visual feedback on selection

**Redesigned Layout:**
```
┌─────────────────────────┐
│ Cancel   New Chat    ✓  │ ← Nav bar: Cancel (blue), title, Done (blue)
│                         │
│  [1-on-1]  [Group]      │ ← Modern segmented picker
│                         │
│ 🔍 Search by name...    │ ← Search at top
│                         │
│ [Photo●] Sarah M     ✓  │ ← User row (selected)
│ sarah@email.com         │
│                         │
│ [Photo] Bob Smith       │ ← User row (unselected)
│ bob@example.com         │
│                         │
│ [Photo] Carol White     │
│ carol@example.com       │
│                         │
└─────────────────────────┘
```

**Design Details:**

**Modal Presentation:**
- `.sheet` presentation (not full screen)
- Swipe-to-dismiss enabled
- Corner radius: 16pt (iOS standard)

**Navigation Bar:**
- Title: "New Chat" (`.headline` + `.bold`)
- Left: "Cancel" button (blue, dismisses sheet)
- Right: "Done" button (blue, creates chat) - **NEW**
  - Disabled when no users selected
  - Enabled (bold) when users selected
- Background: `.systemBackground`
- Separator: 0.5pt, `.separator`

**User Count Indicator (Top Right):**
- Remove "17 users" from nav bar
- Show in section header instead: "17 People" (`.subheadline` + `.secondary`)

**Segmented Control (1-on-1 / Group):**
- Style: Modern iOS style, not legacy rounded
- Use `Picker` with `.pickerStyle(.segmented)`
- Full width with 16pt horizontal padding
- 12pt padding from nav bar
- Selected: Blue accent
- Unselected: `.secondarySystemBackground`

**Search Bar:**
- **Move to top** (below segmented control, not bottom)
- Placeholder: "Search by name or email"
- Icon: Magnifying glass (leading)
- Style: `.searchable` modifier
- Background: `.secondarySystemBackground`
- Height: 36pt
- Corner radius: 10pt
- 16pt horizontal padding
- 12pt vertical padding from segmented control

**User List:**
- Remove `List`, use `ScrollView` + `LazyVStack` for better control
- Background: `.systemBackground`
- 8pt spacing from search bar

**User Row (Redesigned):**
```
┌─────────────────────────────┐
│ [Avatar] Name           [✓] │
│          email              │
└─────────────────────────────┘
```

**Row Components:**
- Avatar: 56pt circular (left)
  - Online status: 12pt green dot (bottom-right of avatar)
  - If no photo: Initials on `.systemGray5`
- Name: `.body` + `.bold` + `.label`
- Email: `.subheadline` + `.secondary`
  - 4pt below name
- Checkmark: 24pt blue circle with white checkmark (right) - **NEW**
  - Only visible when row selected
  - Animated fade in/out
- Row padding: 16pt horizontal, 12pt vertical
- Row height: 72pt minimum
- Tap area: Full row (not just avatar)
- Divider: 0.5pt, `.separator`, leading padding 72pt (after avatar)

**Selection Behavior:**
- **1-on-1 Mode**: 
  - Single selection only
  - Tap user → auto-navigates to chat (no "Done" button needed)
  - Blue checkmark shows briefly before navigation
- **Group Mode**:
  - Multi-selection enabled
  - Tap to toggle checkmark
  - "Done" button enabled when 2+ users selected
  - Minimum 2 users required for group

**Empty State:**
- No users: Center message "No users available"
- No search results: "No results for 'search term'"
- Icon: `person.3` SF Symbol (96pt, gray)
- Text: `.title3` + `.secondary`

**Loading State:**
- Show skeleton loading rows (3-5 rows)
- Shimmer effect on avatar and text areas

**Visual Feedback:**
- Row tap: Scale to 0.98 with spring animation
- Selection: Checkmark fades in (0.2s ease)
- Search: Debounced (300ms)
- Dismissal: Smooth sheet dismissal animation

**Changes from Current:**
- ✅ Search moved to top (more intuitive)
- ✅ Modern segmented control
- ✅ Better user rows with proper spacing
- ✅ Clear selection feedback (checkmarks)
- ✅ Done button for group creation
- ✅ Auto-navigate for 1-on-1 (no extra tap)
- ✅ Consistent with design system

---

### 6. Navigation & Tab Bar

**Tab Bar:**
- Keep "Conversations" (or "Messages")
- Add unread badge to first tab
- Consistent `.blue` accent color

**Navigation:**
- Large titles on main screens
- Consistent nav bar styling
- Swipe-back gestures everywhere

---

## ✅ Implementation Checklist

### Authentication
- [ ] Remove gradients from all auth screens
- [ ] Use `.systemBackground`
- [ ] Simplify button styling
- [ ] Remove card shadows
- [ ] Standard iOS text fields

### Conversations Tab (Visual Polish Only)
- [ ] Add Floating Action Button (FAB) - move existing button
- [ ] Remove nav bar "new message" button
- [ ] Increase avatar size (50pt → 56pt)
- [ ] Polish existing online status indicators
- [ ] Polish existing unread badges
- [ ] Polish existing sender name display
- [ ] Add user avatar to nav bar (visual only)
- [ ] Improve spacing and layout

### Profile Tab
- [ ] Increase photo size (120pt → 140pt)
- [ ] Add photo border (1pt subtle)
- [ ] Improve name/email typography
- [ ] Update Edit Profile button (blue, full width, with icon)
- [ ] Better Account Information section spacing
- [ ] Consistent spacing throughout (32pt, 24pt, 16pt grid)

### New Chat Sheet
- [ ] Move search to top (below segmented control)
- [ ] Update segmented control to modern iOS style
- [ ] Add "Done" button to nav bar (for group mode)
- [ ] Redesign user rows (56pt avatars, better spacing)
- [ ] Add selection checkmarks (blue circle with ✓)
- [ ] Implement 1-on-1 auto-navigation (no Done button needed)
- [ ] Implement group multi-selection (2+ users)
- [ ] Add row tap animations (scale 0.98)
- [ ] Update empty and loading states
- [ ] Remove "X users" from nav bar, add to section header instead

### Settings Tab
- [ ] Replace placeholder with iOS List
- [ ] Add user info section
- [ ] Create Account & Support sections
- [ ] Use grouped list style
- [ ] Add NavigationLink items

### Overall Consistency
- [ ] Same blue accent everywhere
- [ ] System colors throughout (Dark Mode support)
- [ ] Consistent spacing (8, 16, 24pt grid)
- [ ] Consistent corner radius (8 or 12pt)
- [ ] Same button styles across all screens
- [ ] Same nav bar styling

---

## 📊 Summary

**Screens Updated:** 12 files total
- 3 auth screens (simplify)
- Conversations tab (major enhancements)
- Profile tab (enhanced design)
- New Chat sheet (complete redesign)
- Settings tab (complete redesign)
- Navigation/tab bar (consistency)

**Design System:**
- One accent color (iOS blue)
- System colors everywhere
- Standard iOS fonts
- Consistent spacing/layout

**Impact:**
- ✅ Unified, clean design
- ✅ Native iOS feel
- ✅ Signal-like simplicity and privacy vibe
- ✅ Scales for individual & group conversations
- ✅ Dark Mode support (automatic)

---

**End of UX Specification**

*For detailed implementation, Pam will create comprehensive PRD and TODO.*
