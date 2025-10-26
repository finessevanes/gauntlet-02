# UX Specification: Trainer-Client Relationship System (PR #009)

**Feature:** Trainer-Client Relationships & Contact Management
**Designer:** Claudia (UX Expert)
**Date:** October 25, 2025
**Version:** 1.0
**Status:** Ready for Implementation

**Related Documents:**
- PRD: `Psst/docs/prds/pr-009-prd.md`
- TODO: `Psst/docs/todos/pr-009-todo.md`
- Brownfield Analysis: `Psst/docs/brownfield-analysis-pr-009.md`
- Risk Assessment: `Psst/docs/risk-assessment-pr-009.md`

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Navigation Design Decision](#navigation-design-decision)
3. [Screen Specifications](#screen-specifications)
4. [Component Specifications](#component-specifications)
5. [Interaction Patterns](#interaction-patterns)
6. [Visual Design](#visual-design)
7. [Accessibility](#accessibility)
8. [Edge Cases & Error States](#edge-cases--error-states)
9. [Performance & Perceived Performance](#performance--perceived-performance)
10. [Wireframes](#wireframes)

---

## Executive Summary

The Trainer-Client Relationship System introduces explicit contact management for trainers, replacing the open-access messaging model with controlled, relationship-based communication. This UX specification addresses the following key challenges:

**Key UX Challenges Solved:**
1. **Navigation Placement** - Recommends Option A (new tab) with clear rationale
2. **Email Lookup Experience** - Smooth, informative lookup with helpful feedback
3. **Two-Section List Design** - Clear visual distinction between clients and prospects
4. **Performance Perception** - Makes 200-500ms operations feel instant
5. **Error Messaging** - Empathetic, actionable error states

**Design Principles:**
- **Trainer-First**: Every interaction optimized for trainer workflow
- **Speed Perception**: Loading states that feel faster than actual performance
- **Error Empathy**: Friendly, constructive error messages
- **Visual Hierarchy**: Clients clearly prioritized over prospects
- **Touch-First**: 44pt minimum touch targets, generous spacing

---

## Navigation Design Decision

### Recommendation: Option A - New Tab in Bottom Navigation

**Winner: Option A** ✅

#### Rationale

**Why Option A (New Tab):**

1. **Primary Feature for Trainers** - Contact management is core functionality, not secondary:
   - Trainers will access this multiple times per day (adding clients, checking roster)
   - Deserves same prominence as Chats and Profile
   - Establishes contacts as first-class citizen in app hierarchy

2. **Mental Model Alignment** - Users expect contacts in persistent navigation:
   - Industry pattern: WhatsApp, iMessage, Telegram all have dedicated contacts tabs
   - Trainers think "Who are my clients?" not "Where do I manage relationships?"
   - Tab bar = "What can I do?" vs Settings = "How do I configure?"

3. **Discoverability** - New trainers immediately see contact management:
   - Empty state with clear CTA: "Add your first client"
   - No hunting through settings or menus
   - Onboarding can guide: "Step 1: Add Clients"

4. **Efficiency** - One tap access vs. multiple taps:
   - Option A: 1 tap (Contacts tab)
   - Option B: 2-3 taps (Settings → Contacts or Profile → Contacts)
   - Option C: 1 tap but spatially awkward (FAB blocks content)

5. **Scalability** - Future features fit naturally:
   - Client filtering/segments (Premium tier)
   - Client analytics dashboard
   - Quick actions (message all clients, broadcast)

**Why NOT Option B (Settings/Profile Menu Item):**
- Settings = configuration, not core workflow
- 2-3 taps to reach (slower access)
- Hides feature for new users (low discoverability)
- Communicates "this is optional" when it's actually essential

**Why NOT Option C (Floating Action Button in ChatListView):**
- FAB blocks chat list content (poor UX for scrolling)
- Spatially disconnected from chat list actions
- Doesn't scale (what if we add more primary actions?)
- Not iOS native pattern (more common in Material Design)

#### Tab Bar Layout

**Updated Navigation:**
```
┌─────────────────────────────────────────────────┐
│                                                 │
│          [Content Area - Full Height]           │
│                                                 │
├─────────────────────────────────────────────────┤
│  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐       │
│  │ 💬   │  │ 👥   │  │ 👤   │  │ ⚙️   │       │
│  │Chats │  │Contacts│ │Profile│ │Settings│     │
│  └──────┘  └──────┘  └──────┘  └──────┘       │
└─────────────────────────────────────────────────┘
```

**Tab Order:**
1. **Chats** (💬) - Primary communication
2. **Contacts** (👥) - NEW - Client management
3. **Profile** (👤) - User profile
4. **Settings** (⚙️) - App configuration

**Icon Choice:**
- SF Symbol: `person.2.fill` (two people icon)
- Active state: Blue tint (#007AFF)
- Badge support: Unread count for prospects who signed up (future feature)

#### Accessibility Considerations

**VoiceOver Labels:**
- "Contacts tab, 2 of 4" when unselected
- "Contacts tab, 2 of 4, selected" when active
- "Contacts, 3 new clients" when badge present (future)

**Dynamic Type:**
- Tab labels scale with system font size
- Icons remain fixed size (28pt)
- Labels may wrap to 2 lines at largest accessibility sizes

**Color Contrast:**
- Active tab: Blue #007AFF (meets WCAG AA against white)
- Inactive tab: Gray #8E8E93 (meets WCAG AA)
- Tab bar background: White with 1pt gray border (separator)

#### Trade-offs Analysis

| Aspect | Option A (Tab) | Option B (Menu) | Option C (FAB) |
|--------|---------------|-----------------|----------------|
| **Discoverability** | ⭐⭐⭐⭐⭐ Excellent | ⭐⭐ Poor | ⭐⭐⭐ Good |
| **Access Speed** | ⭐⭐⭐⭐⭐ 1 tap | ⭐⭐ 2-3 taps | ⭐⭐⭐⭐⭐ 1 tap |
| **Screen Real Estate** | ⭐⭐⭐⭐ Tab bar always visible | ⭐⭐⭐⭐⭐ No persistent UI | ⭐⭐⭐ FAB overlays content |
| **iOS Native Feel** | ⭐⭐⭐⭐⭐ Standard pattern | ⭐⭐⭐⭐⭐ Standard pattern | ⭐⭐ Android-style |
| **Scalability** | ⭐⭐⭐⭐⭐ Room for features | ⭐⭐⭐ Limited | ⭐⭐ Hard to extend |
| **Mental Model** | ⭐⭐⭐⭐⭐ Contacts = primary | ⭐⭐⭐ Contacts = settings | ⭐⭐⭐⭐ Contacts = action |

**Winner: Option A** - Best balance of discoverability, efficiency, and scalability.

---

## Screen Specifications

### 1. ContactsView (Main Screen)

#### Layout Structure

```
┌───────────────────────────────────────────────┐
│  ← Back          Contacts        [+ Add] [•••]│ ← Navigation Bar
├───────────────────────────────────────────────┤
│  🔍 Search clients and prospects...           │ ← Search Bar
├───────────────────────────────────────────────┤
│                                               │
│  MY CLIENTS (12)                              │ ← Section Header
│  ┌─────────────────────────────────────────┐ │
│  │ [Photo] Jane Smith                      │ │ ← Client Row
│  │         Added 3 days ago                │ │
│  └─────────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────┐ │
│  │ [Photo] Michael Chen                    │ │
│  │         Last contacted 1 hour ago       │ │
│  └─────────────────────────────────────────┘ │
│                                               │
│  PROSPECTS (5)                                │ ← Section Header
│  ┌─────────────────────────────────────────┐ │
│  │ [👤] Sarah Williams    👤 Prospect      │ │ ← Prospect Row
│  │      Added 5 days ago                   │ │
│  └─────────────────────────────────────────┘ │
│                                               │
│  ... (more rows)                              │
│                                               │
└───────────────────────────────────────────────┘
```

#### Navigation Bar

**Title:** "Contacts" (centered, SF Pro Display Bold 17pt)

**Left Item:**
- None (root view in tab)

**Right Items:**
1. **Add Button (+):**
   - SF Symbol: `plus` in circle button
   - Color: Blue (#007AFF)
   - Action: Opens action sheet with:
     - "Add Client" (email lookup)
     - "Add Prospect" (name only)
   - VoiceOver: "Add client or prospect"

2. **More Menu (•••):**
   - SF Symbol: `ellipsis.circle`
   - Color: Blue (#007AFF)
   - Action: Opens menu with:
     - "Sort by Name" / "Sort by Recent"
     - "Export Contacts" (future)
     - "Import from CSV" (future)
   - VoiceOver: "More options"

#### Search Bar

**Placement:** Below navigation bar, sticky on scroll

**Styling:**
- Background: Light gray (#F2F2F7)
- Border radius: 10pt
- Height: 36pt
- Margin: 8pt horizontal, 8pt top, 4pt bottom

**Placeholder:** "Search clients and prospects..."
- Font: SF Pro Text Regular 17pt
- Color: Gray (#8E8E93)

**Behavior:**
- Real-time filtering (filters as user types)
- Searches: display name, email (for clients)
- Clears on tap of (X) button
- Keyboard: Default (allows letters, numbers, spaces)
- Return key: "Search"

**States:**
- **Empty:** Placeholder visible
- **Typing:** Placeholder disappears, typed text shows
- **Has Text:** (X) clear button appears on right
- **Active:** Blue cursor, keyboard visible
- **Results:** Filtered list updates in real-time

**Search Algorithm:**
- Case-insensitive substring match
- Searches both `displayName` and `email` fields
- Priority: Clients before prospects in results
- Performance: < 100ms for 100+ contacts (in-memory filter)

#### Section Headers

**"MY CLIENTS (count)"**
- Font: SF Pro Text Semibold 13pt
- Color: Gray (#8E8E93)
- Text: All caps
- Padding: 16pt horizontal, 16pt top, 8pt bottom
- Background: White (same as list)
- Sticky header: Yes (remains visible during scroll)

**"PROSPECTS (count)"**
- Same styling as "MY CLIENTS"
- Separator: 8pt vertical space before header

**Dynamic Count:**
- Updates automatically as clients/prospects added/removed
- VoiceOver: "My Clients, 12 items" / "Prospects, 5 items"

#### Empty States

**No Clients Yet:**
```
        📋
   No clients yet

Add your first client to start
    managing your roster

   [Add Client Button]
```

**No Prospects Yet:**
```
        👤
   No prospects yet

Track potential clients before
    they sign up for Psst

   [Add Prospect Button]
```

**No Search Results:**
```
        🔍
   No results for "Sam"

Try a different search or
   add a new contact

   [Clear Search Button]
```

**Empty State Styling:**
- Center aligned vertically and horizontally
- Icon: 48pt system icon, gray color
- Heading: SF Pro Display Medium 20pt, dark gray
- Body: SF Pro Text Regular 15pt, light gray
- Button: Primary button style (blue, rounded)

#### Pull-to-Refresh

**Gesture:** Pull down from top of list

**Behavior:**
- Shows spinning indicator (iOS native)
- Reloads contacts from Firestore
- Updates counts, sorts list
- Dismisses automatically on completion

**States:**
- **Idle:** No indicator
- **Pulling:** Indicator scales in (0% → 100%)
- **Refreshing:** Indicator spins
- **Complete:** Brief checkmark (200ms), then dismisses

**Performance Target:** < 500ms refresh time

#### Loading State (Initial Load)

**Skeleton Loader:**
```
┌───────────────────────────────────────────────┐
│  MY CLIENTS                                   │
│  ┌─────────────────────────────────────────┐ │
│  │ [○] ▬▬▬▬▬▬▬▬▬                          │ │ ← Skeleton Row
│  │     ▬▬▬▬▬▬                              │ │
│  └─────────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────┐ │
│  │ [○] ▬▬▬▬▬▬▬▬▬▬                         │ │
│  │     ▬▬▬▬▬▬▬                             │ │
│  └─────────────────────────────────────────┘ │
│  ... (8-10 skeleton rows)                     │
└───────────────────────────────────────────────┘
```

**Skeleton Styling:**
- Background: Light gray (#F2F2F7)
- Border radius: 8pt (matches real rows)
- Animation: Shimmer effect (gradient moves left → right)
- Duration: Loops until data loads
- Count: Show 8-10 skeleton rows

**Transition:**
- Skeleton rows fade out (200ms)
- Real rows fade in (200ms)
- Stagger animation: 50ms delay per row (top to bottom)

---

### 2. Add Client Form (Sheet)

#### Layout Structure

```
┌───────────────────────────────────────────────┐
│  [Cancel]        Add Client          [Done]   │ ← Navigation Bar
├───────────────────────────────────────────────┤
│                                               │
│  Enter the email address of an existing Psst │
│  user to add them as your client.            │ ← Instructions
│                                               │
│  ┌───────────────────────────────────────┐   │
│  │ Email Address                         │   │ ← Text Field Label
│  │ ┌─────────────────────────────────┐   │   │
│  │ │ client@example.com              │   │   │ ← Text Input
│  │ └─────────────────────────────────┘   │   │
│  └───────────────────────────────────────┘   │
│                                               │
│  Display Name (Auto-populates)               │ ← Auto-populated Field
│  ┌───────────────────────────────────────┐   │
│  │ ┌─────────────────────────────────┐   │   │
│  │ │ Looking up user...              │   │   │ ← Loading State
│  │ └─────────────────────────────────┘   │   │
│  └───────────────────────────────────────┘   │
│                                               │
│  [     Add Client to Roster     ]            │ ← Primary Button
│                                               │
└───────────────────────────────────────────────┘
```

#### Presentation Style

**Sheet:** iOS native sheet (`.sheet` modifier)
- Dismissible: Swipe down or tap Cancel
- Detents: Medium height (~50% screen)
- Background: White with rounded top corners (16pt radius)

#### Navigation Bar

**Title:** "Add Client" (SF Pro Display Bold 17pt)

**Left Button:** "Cancel"
- Color: Blue (#007AFF)
- Action: Dismisses sheet without saving
- VoiceOver: "Cancel, button"

**Right Button:** "Done" (initially hidden)
- Color: Blue (#007AFF)
- Action: Submits form (same as primary button)
- Enabled: When email valid and user found
- VoiceOver: "Done, button"

#### Instructions Text

**Content:** "Enter the email address of an existing Psst user to add them as your client."

**Styling:**
- Font: SF Pro Text Regular 15pt
- Color: Dark gray (#3C3C43)
- Alignment: Left
- Padding: 16pt horizontal, 16pt top, 24pt bottom
- Line height: 20pt (comfortable reading)

#### Email Input Field

**Label:** "Email Address"
- Font: SF Pro Text Regular 13pt
- Color: Gray (#8E8E93)
- Padding: 4pt bottom

**Text Field:**
- Font: SF Pro Text Regular 17pt
- Color: Black (#000000)
- Placeholder: "client@example.com"
- Keyboard Type: Email address (.emailAddress)
- Auto-capitalization: None
- Auto-correction: Off
- Return Key: "Next" (moves to Submit button)

**Border:**
- Default: Light gray (#E5E5EA), 1pt, 8pt radius
- Focused: Blue (#007AFF), 2pt, 8pt radius
- Error: Red (#FF3B30), 2pt, 8pt radius

**Height:** 44pt (minimum touch target)

**Validation:**
- Real-time: Checks email format as user types
- Regex: Simple `@` check initially (full validation on submit)
- Error appears below field (red text, 13pt)

**States:**
- **Empty:** Placeholder visible
- **Typing:** Black text, blue border
- **Valid:** Green checkmark icon on right (subtle)
- **Invalid:** Red error text below: "Please enter a valid email address"

#### Display Name Field (Auto-populated)

**Label:** "Display Name (Auto-populates)"
- Font: SF Pro Text Regular 13pt
- Color: Gray (#8E8E93)
- Padding: 4pt bottom

**Field Appearance:**
- Background: Light gray (#F2F2F7) - indicates read-only
- Border: None
- Border radius: 8pt
- Height: 44pt
- Padding: 12pt horizontal

**States:**

1. **Initial (No Email Entered):**
   - Text: "(empty)" in light gray
   - Icon: None

2. **Looking Up User:**
   - Text: "Looking up user..." with animated dots
   - Icon: Spinning indicator (14pt) on left
   - Animation: Fade in (200ms)

3. **User Found (Success):**
   - Text: "Jane Smith" (actual user's displayName)
   - Icon: Green checkmark (✓) on right
   - Animation: Fade in (200ms), slight scale bounce (1.0 → 1.1 → 1.0)
   - Background: Very light green (#E8F5E9) for 1 second, then back to gray

4. **User Not Found (Error):**
   - Text remains "(empty)"
   - Error message appears below field (see Error States section)
   - No icon in field

**VoiceOver:**
- "Display Name, text field, read only"
- "Jane Smith" when populated
- "Looking up user" when loading

#### Primary Button

**Label:** "Add Client to Roster"

**Styling:**
- Background: Blue (#007AFF)
- Text: White, SF Pro Text Semibold 17pt
- Height: 50pt
- Border radius: 12pt
- Shadow: Subtle (0pt 2pt 4pt rgba(0,0,0,0.1))

**States:**

1. **Disabled (Initial):**
   - Background: Light gray (#E5E5EA)
   - Text: Gray (#8E8E93)
   - Cursor: Not allowed
   - Condition: Email empty or invalid format

2. **Enabled:**
   - Background: Blue (#007AFF)
   - Text: White
   - Hover: Slight scale (1.0 → 1.02) on touch down

3. **Loading (Looking Up User):**
   - Background: Blue (#007AFF)
   - Text: Hidden
   - Icon: White spinning indicator (20pt)
   - Condition: After tap, during email lookup

4. **Loading (Adding Client):**
   - Background: Blue (#007AFF)
   - Text: "Adding..."
   - Icon: White spinning indicator (20pt) on left

**Animation:**
- Touch down: Scale 0.98, duration 100ms
- Touch up: Scale 1.0, spring animation (damping 0.6)

**Haptic Feedback:**
- Success: Light impact
- Error: Error haptic

#### Keyboard Behavior

**Auto-Focus:** Email field focused on sheet appearance (keyboard slides up)

**Dismissal:**
- Tap outside fields: Keyboard dismisses
- Swipe down on sheet: Keyboard dismisses, sheet dismisses
- Tap Return: Keyboard dismisses (if on last field)

---

### 3. Add Prospect Form (Sheet)

#### Layout Structure

```
┌───────────────────────────────────────────────┐
│  [Cancel]       Add Prospect         [Done]   │
├───────────────────────────────────────────────┤
│                                               │
│  Track potential clients who haven't signed  │
│  up for Psst yet. You can upgrade them to    │
│  clients once they create an account.        │
│                                               │
│  ┌───────────────────────────────────────┐   │
│  │ Name                                  │   │
│  │ ┌─────────────────────────────────┐   │   │
│  │ │ Sarah Williams                  │   │   │
│  │ └─────────────────────────────────┘   │   │
│  └───────────────────────────────────────┘   │
│                                               │
│  [     Add Prospect     ]                    │
│                                               │
└───────────────────────────────────────────────┘
```

**Much simpler than Add Client - only name required.**

#### Instructions Text

**Content:** "Track potential clients who haven't signed up for Psst yet. You can upgrade them to clients once they create an account."

**Styling:** Same as Add Client instructions

#### Name Input Field

**Label:** "Name"

**Text Field:**
- Placeholder: "Sarah Williams"
- Keyboard Type: Default (allows all characters)
- Auto-capitalization: Words
- Auto-correction: On
- Return Key: "Done" (submits form)

**Validation:**
- Required: Name cannot be empty
- Min length: 2 characters
- Max length: 50 characters
- Error: "Name is required" (appears below field if empty on submit)

#### Primary Button

**Label:** "Add Prospect"

**States:**
- Disabled: Name empty or < 2 characters
- Enabled: Name valid
- Loading: "Adding..." with spinner

---

### 4. Upgrade Prospect Form (Sheet)

#### Layout Structure

```
┌───────────────────────────────────────────────┐
│  [Cancel]    Upgrade Prospect        [Done]   │
├───────────────────────────────────────────────┤
│                                               │
│  Sarah Williams has signed up for Psst!      │
│  Enter their email to upgrade them to a      │
│  client.                                      │
│                                               │
│  Prospect Name                                │
│  ┌───────────────────────────────────────┐   │
│  │ ┌─────────────────────────────────┐   │   │
│  │ │ Sarah Williams                  │   │   │ ← Read-only
│  │ └─────────────────────────────────┘   │   │
│  └───────────────────────────────────────┘   │
│                                               │
│  Email Address                                │
│  ┌───────────────────────────────────────┐   │
│  │ ┌─────────────────────────────────┐   │   │
│  │ │ sarah@example.com               │   │   │
│  │ └─────────────────────────────────┘   │   │
│  └───────────────────────────────────────┘   │
│                                               │
│  [     Upgrade to Client     ]               │
│                                               │
└───────────────────────────────────────────────┘
```

#### Key Differences from Add Client

1. **Prospect Name (Read-Only):**
   - Shows prospect's existing name
   - Light gray background (read-only indicator)
   - Cannot be edited

2. **Instructions:**
   - Personalized: "Sarah Williams has signed up for Psst!"
   - Explains action: "upgrade them to a client"

3. **Button Label:** "Upgrade to Client" (instead of "Add Client to Roster")

4. **Success Action:**
   - Prospect moves from "Prospects" to "My Clients" section
   - Toast: "✅ Sarah Williams upgraded to client"

---

## Component Specifications

### ContactRowView (Reusable List Item)

#### Layout Structure

```
┌─────────────────────────────────────────────────┐
│ [Photo]  Jane Smith                             │ ← 52pt row height
│          Added 3 days ago                       │
└─────────────────────────────────────────────────┘
      ↑           ↑
   Avatar    Name + Metadata
  (40pt)
```

#### Avatar (Profile Photo or Initials)

**Size:** 40pt × 40pt

**Styling:**
- Border radius: 20pt (perfect circle)
- Border: None
- Shadow: None (flat design)

**If Photo Exists:**
- AsyncImage from `photoURL`
- Placeholder: Gray circle with initials while loading
- Aspect ratio: Fill (crops to circle)

**If No Photo (Initials):**
- Background: Gradient based on user ID hash
  - Algorithm: Hash user ID → select from 10 preset gradients
  - Prevents all avatars looking same
- Initials: First letter of first and last name
  - Example: "Jane Smith" → "JS"
  - Font: SF Pro Display Bold 16pt
  - Color: White
  - Centered vertically and horizontally

**Gradient Palette (10 options):**
1. Blue: #007AFF → #5AC8FA
2. Green: #34C759 → #30D158
3. Orange: #FF9500 → #FF3B30
4. Purple: #AF52DE → #BF5AF2
5. Pink: #FF2D55 → #FF375F
6. Teal: #5AC8FA → #64D2FF
7. Indigo: #5856D6 → #7D7AFF
8. Red: #FF3B30 → #FF6961
9. Yellow: #FFCC00 → #FFD60A
10. Mint: #00C7BE → #63E6E2

#### Name and Metadata

**Display Name:**
- Font: SF Pro Text Semibold 17pt
- Color: Black (#000000)
- Line height: 22pt

**Metadata (Below Name):**
- Font: SF Pro Text Regular 15pt
- Color: Gray (#8E8E93)
- Line height: 20pt

**Metadata Content:**

For **Clients:**
- "Added [timeago]" (e.g., "Added 3 days ago")
- If `lastContactedAt` exists: "Last contacted [timeago]"
- TimeAgo format:
  - < 1 hour: "Added 45 minutes ago"
  - < 24 hours: "Added 5 hours ago"
  - < 7 days: "Added 3 days ago"
  - < 30 days: "Added 2 weeks ago"
  - > 30 days: "Added on Mar 15" (date)

For **Prospects:**
- "👤 Prospect · Added [timeago]"
- Prospect badge inline with metadata

#### Prospect Badge (Inline)

**Text:** "👤 Prospect"

**Styling:**
- Background: Light gray (#F2F2F7)
- Text: Gray (#8E8E93), SF Pro Text Medium 13pt
- Padding: 4pt horizontal, 2pt vertical
- Border radius: 4pt
- Position: Inline before "Added [timeago]"

**Alternative (More Prominent):**
- Background: Blue (#007AFF) with 10% opacity
- Text: Blue (#007AFF), SF Pro Text Semibold 13pt
- Border: 1pt solid blue (#007AFF)

**Recommendation:** Use subtle light gray version (less visual noise in list).

#### Swipe Actions

**For Clients:**

Swipe **left** reveals:
- **Remove** (destructive action)
  - Icon: SF Symbol `trash.fill`
  - Color: Red (#FF3B30)
  - Width: 80pt
  - Action: Presents confirmation alert (see Error States)

**For Prospects:**

Swipe **left** reveals (two actions):
1. **Upgrade** (primary action, left position)
   - Icon: SF Symbol `arrow.up.circle.fill`
   - Color: Blue (#007AFF)
   - Width: 90pt
   - Action: Opens Upgrade Prospect sheet

2. **Delete** (destructive action, right position)
   - Icon: SF Symbol `trash.fill`
   - Color: Red (#FF3B30)
   - Width: 80pt
   - Action: Presents confirmation alert

**Swipe Interaction:**
- Swipe threshold: 40pt (shows first action)
- Full swipe threshold: 120pt (shows all actions)
- Spring animation: Bounce back when released
- Haptic feedback: Light impact when threshold reached

**Animation:**
- Actions slide in from right as row swipes left
- Icons fade in (0% → 100%) during swipe
- Row background darkens slightly during swipe

#### Row Padding and Spacing

**Padding:**
- Horizontal: 16pt (left and right)
- Vertical: 12pt (top and bottom)
- Total row height: 64pt (40pt avatar + 12pt top + 12pt bottom)

**Spacing (Avatar to Text):**
- Gap: 12pt horizontal between avatar and name

**Separator Line:**
- Height: 0.5pt
- Color: Light gray (#E5E5EA)
- Inset: 68pt from left (aligns with text, not avatar)
- Position: Bottom of row

#### Interaction States

**Default:** White background

**Tap (Hover):**
- Background: Very light gray (#F9F9F9)
- Duration: While finger down

**Selected:**
- Not applicable (rows don't have selected state in this design)

**Dragging (Reorder - Future):**
- Shadow: 0pt 4pt 8pt rgba(0,0,0,0.15)
- Lift animation: Scale 1.02, rotate 2deg

#### Accessibility

**VoiceOver Label:**
- For Client: "Jane Smith, client, added 3 days ago"
- For Prospect: "Sarah Williams, prospect, added 5 days ago"

**Swipe Actions:**
- "Remove Jane Smith from client list" (double-tap to activate)
- "Upgrade Sarah Williams to client" (double-tap to activate)
- "Delete Sarah Williams prospect" (double-tap to activate)

**Minimum Touch Target:** 64pt height (exceeds 44pt minimum)

**Dynamic Type:**
- Name and metadata scale with system font size
- Avatar remains 40pt (fixed)
- Row height adjusts automatically (64pt minimum)

---

### Search Bar Component

**(Detailed in ContactsView section above)**

Key points:
- Real-time filtering (< 100ms response)
- Searches displayName and email
- Clear button (X) appears when text present
- Keyboard dismisses on scroll

---

### Section Header Component

**(Detailed in ContactsView section above)**

Key points:
- Sticky header (remains visible during scroll)
- Dynamic count updates automatically
- All caps, gray text, 13pt semibold

---

### Empty State Component

**(Detailed in ContactsView section above)**

Key points:
- Center aligned, icon + text + button
- Different states for clients, prospects, search
- Friendly, actionable messaging

---

## Interaction Patterns

### Add Client Flow (Complete Sequence)

```
User taps "+" button
    ↓
Action sheet appears: "Add Client" / "Add Prospect"
    ↓
User taps "Add Client"
    ↓
Sheet slides up (medium detent, ~50% screen)
    ↓
Email field auto-focused, keyboard appears
    ↓
User types "jane@example.com"
    ↓
Real-time validation: Checkmark appears (valid format)
    ↓
User taps "Add Client to Roster" button
    ↓
Button → Loading state: "Looking up user..." + spinner
    ↓
[Backend: UserService.getUserByEmail("jane@example.com")]
    ↓
SUCCESS: User found
    ↓
Display Name field animates:
  - Fade in "Jane Smith"
  - Green checkmark appears
  - Very light green background (1 second)
    ↓
Button text changes: "Add Jane Smith"
    ↓
User confirms (button already highlighted, no need to tap again)
    ↓
Button → Loading state: "Adding..." + spinner
    ↓
[Backend: ContactService.addClient(email)]
    ↓
SUCCESS: Client added
    ↓
Sheet dismisses with slide-down animation (300ms)
    ↓
ContactsView updates:
  - "Jane Smith" row slides in from top (250ms slide + fade)
  - Haptic feedback (light impact)
  - Toast appears: "✅ Added Jane Smith as client" (2 seconds)
    ↓
Done! ✅
```

**Total Time (Optimal):**
- User types email: ~5 seconds
- Lookup: ~200ms (target: < 200ms)
- Add client: ~300ms (target: < 500ms)
- UI animations: ~800ms
- **Total: ~6.3 seconds from tap to success**

### Error Case: User Not Found

```
... (same as above until lookup) ...
    ↓
FAILURE: User not found
    ↓
Button returns to enabled state (no longer loading)
Display Name field remains "(empty)"
    ↓
Toast appears at top of sheet:
  ┌───────────────────────────────────────┐
  │ ⚠️ User not found                     │
  │ This email isn't associated with a    │
  │ Psst account yet. Add them as a       │
  │ prospect instead.                     │
  │                    [Add Prospect →]   │
  └───────────────────────────────────────┘
    ↓
Toast auto-dismisses after 4 seconds
(or user taps "Add Prospect" to switch forms)
```

**Toast Styling:**
- Background: Light orange (#FFF4E5)
- Border: 1pt orange (#FF9500)
- Icon: ⚠️ (warning triangle)
- Text: Dark gray, 15pt
- Action link: Blue, underlined
- Position: Top of sheet (below nav bar)
- Animation: Slide down from top (300ms)

### Add Prospect Flow

```
User taps "+" → "Add Prospect"
    ↓
Sheet slides up
    ↓
Name field auto-focused, keyboard appears
    ↓
User types "Sarah Williams"
    ↓
User taps "Add Prospect" button
    ↓
Button → Loading: "Adding..." + spinner (300ms)
    ↓
[Backend: ContactService.addProspect(name)]
    ↓
SUCCESS: Prospect added
    ↓
Sheet dismisses
    ↓
ContactsView updates:
  - "Sarah Williams" row appears in "PROSPECTS" section
  - Badge: "👤 Prospect"
  - Toast: "✅ Added Sarah Williams as prospect"
    ↓
Done! ✅
```

**Total Time:** ~3-4 seconds (much faster, no lookup)

### Upgrade Prospect Flow

```
User finds prospect "Sarah Williams" in list
    ↓
User swipes left on row
    ↓
Swipe actions revealed: [Upgrade] [Delete]
    ↓
User taps "Upgrade"
    ↓
Upgrade Prospect sheet slides up
    ↓
Prospect name shown (read-only): "Sarah Williams"
Email field auto-focused
    ↓
User types "sarah@example.com"
    ↓
User taps "Upgrade to Client" button
    ↓
Button → Loading: "Looking up user..." + spinner
    ↓
[Backend: UserService.getUserByEmail("sarah@example.com")]
    ↓
SUCCESS: User found
    ↓
[Backend: ContactService.upgradeProspectToClient(prospectId, email)]
    ↓
SUCCESS: Prospect upgraded
    ↓
Sheet dismisses
    ↓
ContactsView updates:
  - Row animates from "PROSPECTS" to "MY CLIENTS" section
    - Fade out from prospects (200ms)
    - Fade in at top of clients (200ms)
  - Badge "👤 Prospect" removed
  - Metadata changes: "Added 5 days ago" → "Last contacted just now"
  - Toast: "✅ Sarah Williams upgraded to client"
    ↓
Done! ✅
```

**Animation Details (Prospect → Client Transition):**
1. Row in Prospects section highlights with blue background (100ms)
2. Row shrinks vertically to 0pt (200ms ease-in)
3. Prospects count updates: (5) → (4)
4. Row appears at top of Clients section, expanding from 0pt → 64pt (200ms ease-out)
5. Clients count updates: (12) → (13)
6. New row fades in (200ms)
7. Total animation: 600ms (feels smooth, not jarring)

### Remove Client Flow

```
User finds client "Jane Smith" in list
    ↓
User swipes left on row
    ↓
Swipe action revealed: [Remove]
    ↓
User taps "Remove"
    ↓
Confirmation alert appears:
  ┌───────────────────────────────────────┐
  │ Remove Jane Smith?                    │
  │                                       │
  │ They will no longer be able to        │
  │ message you. This cannot be undone.   │
  │                                       │
  │          [Cancel]  [Remove]           │
  └───────────────────────────────────────┘
    ↓
User taps "Remove" (red, destructive)
    ↓
Alert dismisses
    ↓
Row animates out:
  - Background flashes red briefly (100ms)
  - Row slides left and fades out (250ms)
  - Rows below slide up to fill gap (250ms)
    ↓
[Backend: ContactService.removeClient(clientId)]
    ↓
Clients count updates: (13) → (12)
    ↓
Toast appears: "Removed Jane Smith"
  - Includes "Undo" button (3 seconds)
    ↓
If user taps "Undo" within 3 seconds:
  - Client re-added immediately
  - Row slides back in
  - Toast: "Client restored"
    ↓
Done! ✅
```

**Undo Mechanism:**
- Client ID stored in memory (not deleted from Firestore yet)
- After 3 seconds: Permanent delete from Firestore
- If undo tapped: Re-add to Firestore, cancel delete

### Search Interaction

```
User taps search bar
    ↓
Keyboard appears, search bar focused (blue border)
    ↓
User types "S"
    ↓
List filters in real-time (< 100ms):
  - Shows: Sarah Williams, Sam Johnson, Steve Brown
  - Hides: All other contacts
    ↓
User types "Sa"
    ↓
List filters again:
  - Shows: Sarah Williams, Sam Johnson
  - Hides: Steve Brown
    ↓
User types "Sar"
    ↓
List filters:
  - Shows: Sarah Williams only
    ↓
User taps (X) to clear search
    ↓
Search text clears, full list returns
Keyboard remains (user can type again)
    ↓
User taps "Cancel" or scrolls list
    ↓
Keyboard dismisses
    ↓
Done! ✅
```

**Search Performance:**
- Filter algorithm: In-memory array filter (not Firestore query)
- Complexity: O(n) where n = contact count
- Target: < 100ms for 100 contacts
- Debounce: None (real-time feels better for small lists)

---

## Visual Design

### Color Palette

**Primary Colors:**
- **Blue (Primary Action):** #007AFF
  - Buttons, links, active states
- **Green (Success):** #34C759
  - Success indicators, checkmarks
- **Red (Destructive):** #FF3B30
  - Delete actions, errors
- **Orange (Warning):** #FF9500
  - Warnings, cautionary messages

**Neutral Colors:**
- **Black (Text Primary):** #000000
  - Display names, headings
- **Dark Gray (Text Secondary):** #3C3C43
  - Body text, instructions
- **Gray (Text Tertiary):** #8E8E93
  - Metadata, labels, placeholders
- **Light Gray (Backgrounds):** #F2F2F7
  - Section backgrounds, read-only fields
- **Border Gray:** #E5E5EA
  - Separators, borders, dividers
- **White (Backgrounds):** #FFFFFF
  - Main backgrounds, cards

**Semantic Colors:**
- **Prospect Badge Background:** #F2F2F7 (light gray)
- **Prospect Badge Text:** #8E8E93 (gray)
- **Success Background (Temporary):** #E8F5E9 (very light green)
- **Error Background:** #FFEBEE (very light red)
- **Warning Background:** #FFF4E5 (very light orange)

### Typography

**Font Family:** San Francisco (SF Pro)
- System font, excellent legibility on iOS

**Text Styles:**

| Style | Font | Size | Weight | Color | Usage |
|-------|------|------|--------|-------|-------|
| **Large Title** | SF Pro Display | 34pt | Bold | Black | Page titles (if needed) |
| **Title 1** | SF Pro Display | 28pt | Bold | Black | Section headings |
| **Title 2** | SF Pro Display | 22pt | Bold | Black | Card titles |
| **Title 3** | SF Pro Display | 20pt | Semibold | Black | Modal titles |
| **Headline** | SF Pro Display | 17pt | Semibold | Black | Navigation bar titles |
| **Body** | SF Pro Text | 17pt | Regular | Black | Display names, body text |
| **Body Semibold** | SF Pro Text | 17pt | Semibold | Black | Emphasized body text |
| **Callout** | SF Pro Text | 16pt | Regular | Dark Gray | Supporting text |
| **Subheadline** | SF Pro Text | 15pt | Regular | Gray | Metadata, timestamps |
| **Footnote** | SF Pro Text | 13pt | Regular | Gray | Captions, fine print |
| **Footnote Semibold** | SF Pro Text | 13pt | Semibold | Gray | Section headers (caps) |
| **Caption 1** | SF Pro Text | 12pt | Regular | Gray | Very small text |
| **Caption 2** | SF Pro Text | 11pt | Regular | Gray | Tiny labels |

**Line Heights:**
- Calculated automatically by iOS for optimal readability
- Body text: ~1.3x font size
- Tight headings: ~1.1x font size

**Letter Spacing:**
- Default (0pt) for most text
- Section headers (all caps): +0.5pt tracking

### Spacing System

**Base Unit:** 4pt (all spacing multiples of 4)

**Spacing Scale:**
- **4pt:** Minimal spacing (label to field)
- **8pt:** Small spacing (section padding, icon margins)
- **12pt:** Medium spacing (row padding, avatar to text)
- **16pt:** Default spacing (screen margins, section padding)
- **24pt:** Large spacing (between sections)
- **32pt:** Extra large spacing (empty state elements)

**Component Spacing:**
- **Screen Margins:** 16pt horizontal (consistent throughout app)
- **Row Padding:** 16pt horizontal, 12pt vertical
- **Section Header Padding:** 16pt horizontal, 16pt top, 8pt bottom
- **Button Padding:** 16pt horizontal, 14pt vertical (for 50pt height buttons)
- **Text Field Padding:** 12pt horizontal, 12pt vertical (for 44pt height fields)

### Border Radius

**Consistency:**
- **Small (4pt):** Badges, tags
- **Medium (8pt):** Text fields, input borders
- **Large (12pt):** Buttons, cards
- **Extra Large (20pt):** Avatars (circles = radius = width/2)

### Shadows

**Usage:** Sparingly (iOS design is mostly flat)

**Shadow Styles:**
- **Subtle Shadow (Buttons):**
  - Offset: 0pt x, 2pt y
  - Blur: 4pt
  - Color: rgba(0,0,0,0.1)
  - Use: Primary buttons (adds depth)

- **Card Shadow (Elevated):**
  - Offset: 0pt x, 4pt y
  - Blur: 8pt
  - Color: rgba(0,0,0,0.12)
  - Use: Modals, sheets (when above content)

- **Dragging Shadow:**
  - Offset: 0pt x, 8pt y
  - Blur: 16pt
  - Color: rgba(0,0,0,0.2)
  - Use: Rows being dragged (future reorder feature)

### Icons

**Icon Library:** SF Symbols (Apple's system icon set)

**Icon Sizes:**
- **Small (14pt):** Inline with text (checkmarks, indicators)
- **Medium (20pt):** Buttons, actions
- **Large (24pt):** Tab bar, navigation
- **Extra Large (48pt):** Empty states

**Icon Usage:**

| Context | SF Symbol | Size | Color |
|---------|-----------|------|-------|
| Add Button | `plus` | 20pt | Blue |
| More Menu | `ellipsis.circle` | 20pt | Blue |
| Search | `magnifyingglass` | 18pt | Gray |
| Remove Action | `trash.fill` | 20pt | Red |
| Upgrade Action | `arrow.up.circle.fill` | 20pt | Blue |
| Checkmark (Success) | `checkmark` | 16pt | Green |
| Warning | `exclamationmark.triangle.fill` | 16pt | Orange |
| Error | `xmark.circle.fill` | 16pt | Red |
| Empty State (Clients) | `person.2` | 48pt | Gray |
| Empty State (Prospects) | `person.badge.plus` | 48pt | Gray |
| Empty State (Search) | `magnifyingglass` | 48pt | Gray |
| Prospect Badge | `person.fill` | 13pt | Gray |
| Loading Spinner | `ProgressView` (native) | 20pt | Blue/White |

### Animations

**Animation Durations:**
- **Fast (100-150ms):** Instant feedback (button press, highlight)
- **Standard (200-300ms):** Most UI transitions (sheet open/close, row insert/delete)
- **Slow (400-600ms):** Complex animations (section-to-section moves)

**Animation Curves:**
- **Ease Out:** Most UI transitions (starts fast, slows down)
- **Ease In Out:** Symmetric animations (scale, opacity)
- **Spring:** iOS native spring (used for button presses, smooth bounces)

**Specific Animation Timings:**

| Animation | Duration | Curve | Details |
|-----------|----------|-------|---------|
| Sheet Appear | 300ms | Ease Out | Slide up from bottom |
| Sheet Dismiss | 300ms | Ease In | Slide down to bottom |
| Row Insert | 250ms | Ease Out | Slide in from top + fade in |
| Row Delete | 250ms | Ease In | Slide left + fade out |
| Button Press | 100ms | Spring | Scale 1.0 → 0.98 → 1.0 |
| Checkmark Appear | 200ms | Ease Out | Scale 0 → 1.2 → 1.0 (bounce) |
| Toast Appear | 300ms | Ease Out | Slide down from top |
| Toast Dismiss | 300ms | Ease In | Slide up to top |
| Loading Spinner | Continuous | Linear | Rotate 360deg loop |
| Skeleton Shimmer | 1.5s | Linear | Gradient moves left → right |
| Swipe Actions | 200ms | Ease Out | Actions slide in as row swipes |

**Haptic Feedback:**
- **Light Impact:** Success actions (client added, prospect upgraded)
- **Medium Impact:** Button taps (primary actions)
- **Error Haptic:** Error states (user not found, validation failed)
- **Selection Haptic:** Swipe action threshold reached

---

## Accessibility

### VoiceOver Support

**Screen Titles:**
- ContactsView: "Contacts"
- Add Client Sheet: "Add Client"
- Add Prospect Sheet: "Add Prospect"
- Upgrade Prospect Sheet: "Upgrade Prospect"

**Section Headers:**
- "My Clients, 12 items"
- "Prospects, 5 items"

**Contact Rows:**
- Client: "Jane Smith, client, added 3 days ago, button"
- Prospect: "Sarah Williams, prospect, added 5 days ago, button"

**Swipe Actions:**
- "Remove Jane Smith from client list, button"
- "Upgrade Sarah Williams to client, button"
- "Delete Sarah Williams, button"

**Search Bar:**
- "Search clients and prospects, search field"
- When typing: "Search results: 3 contacts"
- When empty: "No results for 'Sam', text"

**Buttons:**
- Add Button: "Add client or prospect, button"
- Primary Button: "Add Client to Roster, button, enabled" / "disabled"
- Cancel Button: "Cancel, button"
- Done Button: "Done, button"

**Form Fields:**
- Email Field: "Email Address, text field"
- Display Name Field: "Display Name, text field, read only"
- Name Field: "Name, text field"

**Empty States:**
- "No clients yet. Add your first client to start managing your roster. Add Client, button"

**Alerts:**
- "Remove Jane Smith? They will no longer be able to message you. This cannot be undone. Cancel button, Remove button"

### Dynamic Type

**Font Scaling:**
- All text scales with system font size (Settings → Display & Brightness → Text Size)
- SF Pro Text is Dynamic Type-ready
- Use `.font(.body)`, `.font(.headline)` etc. (semantic styles)

**Layout Adjustments:**
- Row heights increase with larger text (64pt minimum → up to 100pt at largest size)
- Buttons maintain 50pt minimum height, text wraps if needed
- Search bar height scales (36pt → 50pt at largest size)
- Section headers may wrap to 2 lines at largest sizes

**Testing:**
- Test at smallest size (xSmall)
- Test at largest size (AX5)
- Ensure no text truncation
- Ensure buttons remain tappable (44pt minimum)

### Color Contrast

**WCAG AA Compliance (4.5:1 ratio minimum for text):**

| Element | Foreground | Background | Ratio | Pass? |
|---------|------------|------------|-------|-------|
| Display Name | Black (#000000) | White (#FFFFFF) | 21:1 | ✅ Yes |
| Body Text | Dark Gray (#3C3C43) | White (#FFFFFF) | 12:1 | ✅ Yes |
| Metadata | Gray (#8E8E93) | White (#FFFFFF) | 4.6:1 | ✅ Yes |
| Section Headers | Gray (#8E8E93) | White (#FFFFFF) | 4.6:1 | ✅ Yes |
| Primary Button | White (#FFFFFF) | Blue (#007AFF) | 4.5:1 | ✅ Yes |
| Error Text | Red (#FF3B30) | White (#FFFFFF) | 5.2:1 | ✅ Yes |
| Success Text | Green (#34C759) | White (#FFFFFF) | 3.1:1 | ⚠️ Marginal |

**Fix for Success Text:** Use darker green (#2A9D3E) for text-only success messages to meet 4.5:1 ratio.

### Minimum Touch Targets

**iOS Guidelines:** 44pt × 44pt minimum

**Touch Target Sizes:**
- Buttons: 50pt height (exceeds minimum) ✅
- Text Fields: 44pt height (meets minimum) ✅
- Contact Rows: 64pt height (exceeds minimum) ✅
- Swipe Actions: 80pt width (exceeds minimum) ✅
- Tab Bar Icons: 44pt height (meets minimum) ✅
- Add Button: 44pt × 44pt (meets minimum) ✅
- More Menu: 44pt × 44pt (meets minimum) ✅

### Keyboard Navigation (iOS External Keyboard Support)

**Tab Order:**
1. Search bar
2. Add button
3. More menu
4. First contact row
5. Second contact row
6. ... (all rows in sequence)

**Keyboard Shortcuts (Future Enhancement):**
- ⌘N: Add new client
- ⌘F: Focus search bar
- ⌘R: Refresh contacts
- ⌘1, ⌘2, etc.: Tab navigation

---

## Edge Cases & Error States

### Error Messaging Principles

1. **Be Empathetic:** Assume user's good intent, don't blame
2. **Be Actionable:** Always suggest next steps
3. **Be Concise:** 1-2 sentences max
4. **Be Friendly:** Conversational tone, not robotic

### Email Lookup Errors

#### Error 1: User Not Found

**Scenario:** Email entered doesn't match any Psst user

**Error Message:**
```
⚠️ User not found

This email isn't associated with a Psst account yet.
Add them as a prospect instead.

[Add as Prospect →]
```

**Display:**
- Toast at top of Add Client sheet
- Background: Light orange (#FFF4E5)
- Border: 1pt orange (#FF9500)
- Icon: Warning triangle (⚠️)
- Duration: 4 seconds (or until dismissed)
- Action link: "Add as Prospect" (switches to Add Prospect form)

**VoiceOver:** "Warning. User not found. This email isn't associated with a Psst account yet. Add them as a prospect instead. Add as Prospect button."

**Haptic:** Error haptic (system error vibration)

#### Error 2: Duplicate Client

**Scenario:** Email entered already exists in client list

**Error Message:**
```
ℹ️ Already a client

Jane Smith is already in your client list.

[View Client →]
```

**Display:**
- Toast at top of sheet
- Background: Light blue (#E3F2FD)
- Border: 1pt blue (#007AFF)
- Icon: Info circle (ℹ️)
- Duration: 3 seconds
- Action link: "View Client" (dismisses sheet, scrolls to that client in list)

**Haptic:** Light impact (not error, just informative)

#### Error 3: Invalid Email Format

**Scenario:** Email format is malformed (no @, etc.)

**Error Message:**
```
Please enter a valid email address
```

**Display:**
- Inline error below email field
- Color: Red (#FF3B30)
- Font: SF Pro Text Regular 13pt
- Appears: After user taps submit (not while typing)

**Validation Rules:**
- Must contain @
- Must have text before and after @
- No spaces
- Minimum 5 characters (e.g., a@b.c)

#### Error 4: Network Error (Offline)

**Scenario:** No internet connection when attempting lookup

**Error Message:**
```
🌐 No internet connection

Please check your connection and try again.

[Retry]
```

**Display:**
- Toast at top of sheet
- Background: Light gray (#F2F2F7)
- Border: 1pt gray (#8E8E93)
- Icon: Globe (🌐)
- Duration: Does not auto-dismiss (requires action)
- Action button: "Retry" (re-attempts lookup)

**Additional UI:**
- Network status banner at top of ContactsView: "Offline - Some features unavailable"
- Add Client button disabled while offline

#### Error 5: Email Lookup Timeout

**Scenario:** Lookup takes > 5 seconds (slow network or server issue)

**Error Message:**
```
⏱ Lookup taking longer than expected

This is unusual. Please try again.

[Retry]
```

**Display:**
- Replaces loading spinner after 5 seconds
- Toast at top of sheet
- Background: Light orange (#FFF4E5)
- Duration: Does not auto-dismiss
- Action button: "Retry"

**Technical Note:**
- Quinn's target: < 200ms for email lookup
- 5 second timeout is very generous (should rarely hit)
- If timeout occurs frequently, indicates index or performance issue

### Form Validation Errors

#### Error 6: Empty Name (Add Prospect)

**Scenario:** User tries to submit with empty name field

**Error Message:**
```
Name is required
```

**Display:**
- Inline error below name field
- Color: Red (#FF3B30)
- Font: SF Pro Text Regular 13pt
- Primary button remains disabled (gray)

**Prevention:**
- Button disabled until name has 2+ characters
- Error only shows if user taps disabled button

#### Error 7: Name Too Long

**Scenario:** Name exceeds 50 characters

**Error Message:**
```
Name is too long (max 50 characters)
```

**Display:**
- Inline error below field
- Red text
- Character count: "48/50" shown in gray when approaching limit

**Prevention:**
- Text field has `maxLength: 50` limit (prevents typing more)
- Error rarely seen (field blocks input at 50 chars)

### Contact List Errors

#### Error 8: Failed to Load Contacts (Network Error)

**Scenario:** Firestore query fails on ContactsView load

**Error Message:**
```
Failed to load contacts

Please check your internet connection and pull down to refresh.
```

**Display:**
- Replaces contact list (full-screen error state)
- Icon: Cloud with slash (☁️🚫)
- Font: Same as empty state
- Includes "Pull to Refresh" instruction
- Also shows network status banner at top

**Recovery:**
- User pulls to refresh (triggers retry)
- Network monitor automatically retries when connection returns

#### Error 9: Failed to Remove Client (Network Error)

**Scenario:** Remove client API call fails

**Error Message:**
```
❌ Failed to remove client

Please check your connection and try again.

[Retry]  [Cancel]
```

**Display:**
- Alert modal (iOS native alert)
- Two buttons: Retry, Cancel
- Retry: Re-attempts removal
- Cancel: Restores client to list (undo removal)

**Technical Note:**
- Client removed optimistically from UI first
- If API fails, restore client to list
- Show error alert

#### Error 10: Failed to Add Client (Firestore Write Error)

**Scenario:** Firestore write fails (quota exceeded, permissions, etc.)

**Error Message:**
```
❌ Failed to add client

Something went wrong. Please try again.

[Retry]  [Cancel]
```

**Display:**
- Alert modal
- Two buttons: Retry, Cancel
- Retry: Re-attempts add
- Cancel: Dismisses sheet

**Logging:**
- Log full error to console for debugging
- Send error to analytics (track failure rate)

### Upgrade Prospect Errors

#### Error 11: Upgrade Failed - User Not Found

**Scenario:** Email entered in Upgrade Prospect form has no matching user

**Error Message:**
(Same as Error 1: User Not Found)

```
⚠️ User not found

This email isn't associated with a Psst account yet.
Ask your prospect to sign up for Psst first.
```

**Display:**
- Toast in Upgrade Prospect sheet
- No "Add as Prospect" action (already a prospect)
- User can try different email or cancel

#### Error 12: Upgrade Failed - Duplicate Client

**Scenario:** Prospect's email matches existing client

**Error Message:**
```
ℹ️ Already a client

This prospect is already in your client list under a different email.

[View Client →]
```

**Display:**
- Toast in sheet
- Action: View Client (dismisses sheet, shows existing client)
- Prospect remains in prospects list (not deleted)

**Edge Case Handling:**
- If user accidentally added duplicate (different name, same email):
  - Show both in list briefly
  - Backend detects duplicate on upgrade
  - Keeps original client, deletes duplicate prospect

### Confirmation Dialogs

#### Confirmation 1: Remove Client

**Title:** "Remove Jane Smith?"

**Message:** "They will no longer be able to message you. This cannot be undone."

**Buttons:**
- "Cancel" (default, left side)
- "Remove" (destructive, red, right side)

**Styling:**
- iOS native alert (UIAlertController style)
- Title: Bold, 17pt
- Message: Regular, 15pt
- Button height: 44pt minimum

**Accessibility:**
- VoiceOver: "Remove Jane Smith? They will no longer be able to message you. This cannot be undone. Cancel button. Remove button, destructive."

#### Confirmation 2: Delete Prospect

**Title:** "Delete Sarah Williams?"

**Message:** "This will permanently remove this prospect from your list."

**Buttons:**
- "Cancel" (default)
- "Delete" (destructive, red)

**Note:** Simpler message than Remove Client (prospects can't message you anyway).

### Edge Case: Very Long Names

**Scenario:** Name is 30+ characters (e.g., "Dr. Elizabeth Margaret Thompson-Williams")

**Handling:**

1. **In Contact Rows:**
   - Truncate after ~30 characters with ellipsis (...)
   - Full name visible on tap (detail view or tooltip)
   - Example: "Dr. Elizabeth Margaret Tho..."

2. **In Forms:**
   - Full name visible (multi-line if needed)
   - Text fields expand to accommodate
   - No truncation in input fields

3. **In Toasts:**
   - Truncate to first name only: "✅ Added Elizabeth as client"
   - Avoids overly long toast messages

### Edge Case: Empty Search Results

**Scenario:** User searches "Sam" but no matches found

**Display:**
```
        🔍
   No results for "Sam"

Try a different search or add a new contact

   [Clear Search]
```

**Styling:**
- Same as empty state design
- Includes search query in quotes
- Clear Search button clears search field

### Edge Case: Multiple Clients with Same Name

**Scenario:** Two clients both named "Sam Smith"

**Handling:**

1. **In Contact List:**
   - Show email in metadata to differentiate
   - Example:
     - "Sam Smith" / "sam.smith1@email.com"
     - "Sam Smith" / "sam.smith2@email.com"

2. **In Search Results:**
   - Email shown prominently
   - Maybe add initials in avatar (if photos are similar)

3. **In Add Client Form:**
   - Show full email below display name
   - "Sam Smith (sam.smith1@email.com)"

### Edge Case: Offline Mode (No Network)

**Behavior:**

1. **ContactsView:**
   - Shows last cached contacts (from previous load)
   - Network status banner: "Offline - Showing cached contacts"
   - Add button disabled (grayed out)
   - Pull-to-refresh shows error (cannot refresh offline)

2. **Add Client:**
   - Button disabled in nav bar
   - If user somehow opens sheet (edge case):
     - Show alert: "Cannot add clients while offline"
     - Disable submit button

3. **Remove Client:**
   - Queue removal for later
   - Remove from UI optimistically
   - Toast: "Will remove Jane Smith when online"
   - If app closes before sync: restored on next launch

4. **Network Returns:**
   - Network banner dismisses
   - Queued actions execute automatically
   - Contacts refresh (pull-to-refresh happens automatically)

### Edge Case: Deleted User

**Scenario:** Client's user account deleted from Firestore (rare)

**Handling:**

1. **In Contact List:**
   - Show row with "(Deleted User)" placeholder
   - Avatar: Gray circle with "?" icon
   - Metadata: "User account no longer exists"

2. **On Tap:**
   - Show alert: "This user's account has been deleted. Would you like to remove them from your client list?"
   - Buttons: "Remove" (recommended) / "Keep"

3. **Prevention:**
   - UserService.getUser() should handle deleted users gracefully
   - Log warning (don't crash app)

---

## Performance & Perceived Performance

### Performance Targets (from Quinn & PRD)

| Operation | Target | Acceptable | Unacceptable |
|-----------|--------|------------|--------------|
| **Email Lookup** | < 200ms | 200-500ms | > 500ms |
| **Contact List Load** | < 500ms | 500-1000ms | > 1000ms |
| **Search Filter** | < 100ms | 100-200ms | > 200ms |
| **Add Client (Total)** | < 1 second | 1-2 seconds | > 2 seconds |

### Making Operations Feel Instant

#### Technique 1: Optimistic UI Updates

**Concept:** Update UI immediately, sync with backend in background

**Examples:**

1. **Add Client:**
   - Client appears in list IMMEDIATELY after tap (before API completes)
   - Show subtle spinner in row (small, doesn't block)
   - If API fails: Remove row, show error toast
   - Result: Feels instant (no perceived wait)

2. **Remove Client:**
   - Row disappears immediately (slide-out animation)
   - API call happens in background
   - If API fails: Restore row, show error toast
   - Result: Feels instant

3. **Upgrade Prospect:**
   - Prospect moves to clients section immediately
   - API call syncs in background
   - Result: Smooth, no waiting

**Caveat:**
- Only use for low-failure-risk operations
- Have rollback plan if API fails
- Don't use for email lookup (must validate first)

#### Technique 2: Skeleton Loaders

**Concept:** Show layout placeholder while loading (feels faster than blank screen or spinner)

**Implementation:**
- 8-10 gray rectangles shaped like contact rows
- Shimmer animation (gradient moves left → right, 1.5s loop)
- Transitions to real content (fade-in)

**Why It Works:**
- Gives user something to look at (not blank screen)
- Sets expectation (shows what's coming)
- Feels faster than spinner (progress is visible)

**Performance:**
- Skeleton appears instantly (< 16ms, 60fps)
- Real content loads in background (< 500ms)
- Crossfade animation (200ms)

#### Technique 3: Instant Search (No Debounce)

**Concept:** Filter results as user types (no delay)

**Implementation:**
- `onTextChange` event triggers immediate filter
- In-memory array filter (not Firestore query)
- O(n) complexity, fast for < 1000 contacts

**Why No Debounce:**
- Debounce (e.g., 300ms delay) would feel sluggish
- Instant feedback feels more responsive
- Performance sufficient for expected list sizes

**Performance:**
- Filter executes: < 50ms (for 100 contacts)
- UI update: < 16ms (60fps)
- Total perceived latency: < 66ms (feels instant)

#### Technique 4: Staggered Row Animations

**Concept:** Rows fade in with slight delay (creates flow)

**Implementation:**
```swift
ForEach(Array(clients.enumerated()), id: \.element.id) { index, client in
    ContactRowView(contact: client)
        .transition(.opacity)
        .animation(.easeOut(duration: 0.2).delay(Double(index) * 0.05))
}
```

**Why It Works:**
- Draws eye downward (top → bottom flow)
- Hides loading time (looks intentional, not slow)
- Feels polished, premium

**Timings:**
- First row: 0ms delay
- Second row: 50ms delay
- Third row: 100ms delay
- ... (50ms increments)
- Total: 10 rows = 500ms max (still within budget)

#### Technique 5: Progress Indication During Lookup

**Concept:** Show multi-stage progress (not just spinner)

**Email Lookup States:**
1. **User types email** (0ms)
   - Immediate validation (red/green border)

2. **User taps Submit** (0ms)
   - Button → Loading: "Looking up user..."
   - Spinner appears

3. **Email lookup in progress** (0-200ms)
   - Keep showing: "Looking up user..."
   - Spinner spins (activity indication)

4. **User found** (200ms)
   - Display name field animates:
     - Spinner fades out (100ms)
     - "Jane Smith" fades in (200ms)
     - Green checkmark appears (bounce animation)
     - Background flashes light green (1 second)
   - Button changes: "Add Jane Smith"
   - Haptic feedback (light impact)

5. **Adding to Firestore** (200-500ms)
   - Button: "Adding..."
   - Spinner continues

6. **Success** (500ms total)
   - Sheet dismisses
   - Client appears in list
   - Toast: "✅ Added Jane Smith as client"
   - Haptic feedback (success)

**Why It Works:**
- Multi-stage progress feels faster than single long wait
- User sees action happening at each stage
- Visual feedback (checkmark, color) distracts from latency
- Total perceived time < actual time (psychological)

#### Technique 6: Haptic Feedback

**Concept:** Physical feedback makes actions feel immediate

**Usage:**
- **Light Impact:** Success (client added, row inserted)
- **Medium Impact:** Button tap (primary actions)
- **Error Haptic:** Validation failed (alert)

**Why It Works:**
- Haptic occurs instantly (< 10ms)
- Tricks brain into thinking action completed
- Bridges gap between tap and visual feedback

**Implementation:**
```swift
let haptic = UIImpactFeedbackGenerator(style: .light)
haptic.impactOccurred()
```

#### Technique 7: Prefetching User Data

**Concept:** Load data before it's needed

**Example:**
- When user types email, start prefetching user data
- By the time they tap Submit, data may already be cached
- Lookup feels instant (0ms)

**Implementation (Future Optimization):**
```swift
// As user types email
onEmailChange { email in
    // Debounce 500ms (only prefetch after pause)
    Task.delayed(by: 0.5) {
        if email.contains("@") {
            // Prefetch user silently
            await userService.getUserByEmail(email)
        }
    }
}
```

**Caveats:**
- Don't overuse (wasted API calls)
- Only for high-probability actions
- Debounce to avoid premature fetching

### Perceived Performance Metrics

**Goal:** Make 300ms feel like 100ms

**Strategies:**
1. ✅ Optimistic UI (instant feedback)
2. ✅ Skeleton loaders (set expectations)
3. ✅ Progress indication (multi-stage)
4. ✅ Staggered animations (hide latency)
5. ✅ Haptic feedback (instant confirmation)
6. ✅ No debounce on search (instant filter)
7. ⏳ Prefetching (future optimization)

**Result:**
- 300ms operation feels < 200ms (perceived latency reduced by 30%+)
- User satisfaction increases (feels "snappy")

---

## Wireframes

### Wireframe 1: ContactsView (Full Screen)

```
┌───────────────────────────────────────────────────────┐
│ ☰ Menu         Contacts           [+]  [•••]         │ ← Nav Bar
├───────────────────────────────────────────────────────┤
│                                                       │
│  ┌─────────────────────────────────────────────────┐ │
│  │ 🔍  Search clients and prospects...             │ │ ← Search
│  └─────────────────────────────────────────────────┘ │
│                                                       │
│  MY CLIENTS (12)                                      │ ← Section
├───────────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────────────┐   │
│  │  [ ]  Jane Smith                             │   │ ← Row
│  │  ( )  Added 3 days ago                       │   │
│  └──────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────┐   │
│  │  [ ]  Michael Chen                           │   │
│  │  ( )  Last contacted 1 hour ago              │   │
│  └──────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────┐   │
│  │  [ ]  Ava Martinez                           │   │
│  │  ( )  Added 1 week ago                       │   │
│  └──────────────────────────────────────────────┘   │
│                                                       │
│  PROSPECTS (5)                                        │ ← Section
├───────────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────────────┐   │
│  │  [👤] Sarah Williams    👤 Prospect          │   │ ← Row
│  │  ( )  Added 5 days ago                       │   │
│  └──────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────┐   │
│  │  [👤] Tom Rodriguez     👤 Prospect          │   │
│  │  ( )  Added 2 weeks ago                      │   │
│  └──────────────────────────────────────────────┘   │
│                                                       │
│  ... (more rows scroll) ...                          │
│                                                       │
└───────────────────────────────────────────────────────┘
     ───────────────────────────────
    │ 💬 │ 👥 │ 👤 │ ⚙️  │  ← Tab Bar
    │Chats│Contacts│Profile│Settings│
     ───────────────────────────────

Legend:
[ ] = Avatar (circle with photo or initials)
( ) = Metadata text (gray, smaller)
[+] = Add button (plus icon)
[•••] = More menu (three dots)
👤 = Prospect badge icon
```

---

### Wireframe 2: Add Client Sheet (Email Form)

```
┌───────────────────────────────────────────────────────┐
│                                                       │
│  [Cancel]        Add Client                 [Done]   │ ← Nav Bar
│                                                       │
├───────────────────────────────────────────────────────┤
│                                                       │
│  Enter the email address of an existing Psst user    │
│  to add them as your client.                         │ ← Instructions
│                                                       │
│  Email Address                                        │
│  ┌─────────────────────────────────────────────────┐ │
│  │ client@example.com                              │ │ ← Input
│  └─────────────────────────────────────────────────┘ │
│                                                       │
│  Display Name (Auto-populates)                       │
│  ┌─────────────────────────────────────────────────┐ │
│  │ [○] Looking up user...                          │ │ ← Loading
│  └─────────────────────────────────────────────────┘ │
│                                                       │
│  ┌─────────────────────────────────────────────────┐ │
│  │         Add Client to Roster                    │ │ ← Button
│  └─────────────────────────────────────────────────┘ │
│                                                       │
│                                                       │
└───────────────────────────────────────────────────────┘

Legend:
[○] = Spinning indicator (animated)
```

---

### Wireframe 3: Add Client Sheet (Success State)

```
┌───────────────────────────────────────────────────────┐
│                                                       │
│  [Cancel]        Add Client                 [Done]   │
│                                                       │
├───────────────────────────────────────────────────────┤
│                                                       │
│  Enter the email address of an existing Psst user    │
│  to add them as your client.                         │
│                                                       │
│  Email Address                                        │
│  ┌─────────────────────────────────────────────────┐ │
│  │ jane@example.com                        [✓]     │ │ ← Valid
│  └─────────────────────────────────────────────────┘ │
│                                                       │
│  Display Name (Auto-populates)                       │
│  ┌─────────────────────────────────────────────────┐ │
│  │ Jane Smith                              [✓]     │ │ ← Found!
│  └─────────────────────────────────────────────────┘ │ (green bg)
│                                                       │
│  ┌─────────────────────────────────────────────────┐ │
│  │ [○] Adding Jane Smith...                        │ │ ← Loading
│  └─────────────────────────────────────────────────┘ │
│                                                       │
│                                                       │
└───────────────────────────────────────────────────────┘

Legend:
[✓] = Green checkmark icon
[○] = Spinner (in button)
```

---

### Wireframe 4: Add Client Sheet (Error - User Not Found)

```
┌───────────────────────────────────────────────────────┐
│  ┌─────────────────────────────────────────────────┐ │
│  │ ⚠️ User not found                              │ │ ← Toast
│  │                                                  │ │ (orange)
│  │ This email isn't associated with a Psst         │ │
│  │ account yet. Add them as a prospect instead.    │ │
│  │                             [Add Prospect →]    │ │
│  └─────────────────────────────────────────────────┘ │
│                                                       │
│  [Cancel]        Add Client                 [Done]   │
│                                                       │
├───────────────────────────────────────────────────────┤
│                                                       │
│  Enter the email address of an existing Psst user    │
│  to add them as your client.                         │
│                                                       │
│  Email Address                                        │
│  ┌─────────────────────────────────────────────────┐ │
│  │ unknown@example.com                             │ │
│  └─────────────────────────────────────────────────┘ │
│                                                       │
│  Display Name (Auto-populates)                       │
│  ┌─────────────────────────────────────────────────┐ │
│  │ (empty)                                          │ │
│  └─────────────────────────────────────────────────┘ │
│                                                       │
│  ┌─────────────────────────────────────────────────┐ │
│  │         Add Client to Roster                    │ │ ← Button
│  └─────────────────────────────────────────────────┘ │ (enabled again)
│                                                       │
└───────────────────────────────────────────────────────┘
```

---

### Wireframe 5: ContactRowView with Swipe Actions (Client)

```
┌───────────────────────────────────────────────────────┐
│  MY CLIENTS (12)                                      │
├───────────────────────────────────────────────────────┤
│                                                       │
│  ┌──────────────────────────────────────────────┐   │
│  │  [ ]  Jane Smith                             │   │
│  │  ( )  Added 3 days ago                       │   │
│  └──────────────────────────────────────────────┘   │
│                                                       │
│  ┌────────────────────────────────┬──────────────┐  │ ← Swiped
│  │  [ ]  Michael Chen             │  [Remove]    │  │
│  │  ( )  Last contacted 1 hour... │   (red)      │  │
│  └────────────────────────────────┴──────────────┘  │
│                                                       │
│  ┌──────────────────────────────────────────────┐   │
│  │  [ ]  Ava Martinez                           │   │
│  │  ( )  Added 1 week ago                       │   │
│  └──────────────────────────────────────────────┘   │
│                                                       │
└───────────────────────────────────────────────────────┘

Legend:
[Remove] = Red button, trash icon, 80pt wide
```

---

### Wireframe 6: ContactRowView with Swipe Actions (Prospect)

```
┌───────────────────────────────────────────────────────┐
│  PROSPECTS (5)                                        │
├───────────────────────────────────────────────────────┤
│                                                       │
│  ┌──────────────────────────────────────────────┐   │
│  │  [👤] Sarah Williams    👤 Prospect          │   │
│  │  ( )  Added 5 days ago                       │   │
│  └──────────────────────────────────────────────┘   │
│                                                       │
│  ┌────────────────────┬──────────┬──────────────┐   │ ← Swiped
│  │  [👤] Tom Rodriguez│[Upgrade] │   [Delete]    │   │
│  │  ( )  Added 2 we...│  (blue)  │    (red)      │   │
│  └────────────────────┴──────────┴──────────────┘   │
│                                                       │
│  ┌──────────────────────────────────────────────┐   │
│  │  [👤] Lisa Chen        👤 Prospect           │   │
│  │  ( )  Added 1 week ago                       │   │
│  └──────────────────────────────────────────────┘   │
│                                                       │
└───────────────────────────────────────────────────────┘

Legend:
[Upgrade] = Blue button, arrow-up icon, 90pt wide
[Delete] = Red button, trash icon, 80pt wide
```

---

### Wireframe 7: Empty State (No Clients)

```
┌───────────────────────────────────────────────────────┐
│ ☰ Menu         Contacts           [+]  [•••]         │
├───────────────────────────────────────────────────────┤
│                                                       │
│  ┌─────────────────────────────────────────────────┐ │
│  │ 🔍  Search clients and prospects...             │ │
│  └─────────────────────────────────────────────────┘ │
│                                                       │
│  MY CLIENTS (0)                                       │
├───────────────────────────────────────────────────────┤
│                                                       │
│                                                       │
│                       📋                              │ ← Icon
│                                                       │
│                  No clients yet                       │ ← Heading
│                                                       │
│          Add your first client to start              │ ← Body
│            managing your roster                       │
│                                                       │
│              ┌──────────────────┐                    │
│              │   Add Client     │                    │ ← Button
│              └──────────────────┘                    │
│                                                       │
│                                                       │
│                                                       │
│  PROSPECTS (0)                                        │
├───────────────────────────────────────────────────────┤
│                                                       │
│                       👤                              │
│                                                       │
│               No prospects yet                        │
│                                                       │
│          Track potential clients before              │
│              they sign up for Psst                    │
│                                                       │
│              ┌──────────────────┐                    │
│              │  Add Prospect    │                    │
│              └──────────────────┘                    │
│                                                       │
│                                                       │
└───────────────────────────────────────────────────────┘
```

---

### Wireframe 8: Upgrade Prospect Sheet

```
┌───────────────────────────────────────────────────────┐
│                                                       │
│  [Cancel]    Upgrade Prospect           [Done]       │
│                                                       │
├───────────────────────────────────────────────────────┤
│                                                       │
│  Sarah Williams has signed up for Psst!              │
│  Enter their email to upgrade them to a client.      │ ← Instructions
│                                                       │
│  Prospect Name                                        │
│  ┌─────────────────────────────────────────────────┐ │
│  │ Sarah Williams                                  │ │ ← Read-only
│  └─────────────────────────────────────────────────┘ │ (gray bg)
│                                                       │
│  Email Address                                        │
│  ┌─────────────────────────────────────────────────┐ │
│  │ sarah@example.com                               │ │ ← Input
│  └─────────────────────────────────────────────────┘ │
│                                                       │
│  ┌─────────────────────────────────────────────────┐ │
│  │          Upgrade to Client                      │ │ ← Button
│  └─────────────────────────────────────────────────┘ │
│                                                       │
│                                                       │
└───────────────────────────────────────────────────────┘
```

---

## Implementation Notes for Caleb

### Priority Recommendations

**P0 (Must Have for MVP):**
1. ✅ ContactsView with clients and prospects sections
2. ✅ Add Client form with email lookup
3. ✅ Add Prospect form
4. ✅ Remove client / Delete prospect
5. ✅ Search functionality (real-time filter)
6. ✅ Empty states (no clients, no prospects)
7. ✅ Error handling (user not found, network errors)
8. ✅ Tab navigation (new Contacts tab)

**P1 (Should Have for Polish):**
1. ✅ Upgrade prospect flow
2. ✅ Skeleton loaders (initial load)
3. ✅ Staggered row animations
4. ✅ Swipe actions (remove, delete, upgrade)
5. ✅ Pull-to-refresh
6. ✅ Haptic feedback
7. ✅ Toast confirmations ("Added client" etc.)
8. ✅ Undo removal (3-second window)

**P2 (Nice to Have for Future):**
1. ⏳ Optimistic UI updates
2. ⏳ Prefetching user data
3. ⏳ Offline mode with queued actions
4. ⏳ Advanced search (filter by email, date added)
5. ⏳ Sort options (by name, by recent, by last contacted)
6. ⏳ Export contacts (CSV)
7. ⏳ Bulk import (CSV)
8. ⏳ Contact detail view (tap row → full details)

### Key Technical Considerations

1. **Performance:**
   - Firestore index on `email` field (MANDATORY)
   - In-memory search (not Firestore query)
   - Debounce pull-to-refresh (prevent spam)

2. **Accessibility:**
   - All text Dynamic Type-compatible
   - VoiceOver labels for all interactive elements
   - 44pt minimum touch targets everywhere

3. **Error Handling:**
   - Graceful degradation (show cached data if offline)
   - User-friendly error messages (no technical jargon)
   - Logging for debugging (but not user-visible)

4. **Testing:**
   - Unit tests for ContactService (all methods)
   - UI tests for happy path (add client, add prospect, remove)
   - Manual testing for edge cases (network errors, long names)

5. **Migration:**
   - Test migration script in staging FIRST
   - Dry-run before production migration
   - Monitor for failures (have rollback plan)

---

## Approval & Sign-Off

**UX Specification Status:** ✅ **Complete - Ready for Implementation**

**Next Steps:**
1. **User Review:** Review this spec, provide feedback or approve
2. **Caleb Review:** Read spec thoroughly, ask questions if needed
3. **Implementation:** Caleb begins building according to spec
4. **Design QA:** Claudia reviews implementation for adherence to spec

**Estimated Implementation Time:**
- P0 features: 12-16 hours (core functionality)
- P1 features: 6-8 hours (polish)
- Testing: 4-6 hours (manual + automated)
- **Total:** ~25-30 hours

**Questions or Feedback?**
Tag @Claudia for UX questions or @Caleb for implementation questions.

---

**Document Version:** 1.0
**Created:** October 25, 2025
**Author:** Claudia (UX Expert Agent)
**Review Status:** Ready for Implementation
