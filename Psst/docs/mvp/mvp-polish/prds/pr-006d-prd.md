# PRD: Profile Tab Enhancements

**Feature**: Profile Tab UI Polish

**Version**: 1.0

**Status**: Ready for Development

**Agent**: Pam (Planning Agent)

**Target Release**: Phase 1 - MVP Polish

**Links**: 
- PR Brief: `Psst/docs/pr-briefs.md` (PR #006D)
- TODO: `Psst/docs/todos/pr-006d-todo.md`
- UX Spec: `Psst/docs/ux-specs/pr-006-ux-spec.md` (section 3)
- Dependencies: PR #17 (profile editing - completed), PR #006A (design system foundation)

---

## 1. Summary

Polish the Profile tab with enhanced visual design following the established design system: larger profile photo (140pt), improved typography hierarchy, full-width blue Edit Profile button with icon, better spacing in the Account Information section, and consistent use of the 8pt/16pt/24pt/32pt grid system.

---

## 2. Problem & Goals

**Problem**: 
The current Profile tab works functionally but lacks visual polish compared to the rest of the app after PR #006A/B/C. The profile photo is smaller than ideal (120pt), the Edit Profile button doesn't match the design system, spacing is inconsistent, and the overall visual hierarchy could be improved. Users should feel proud of their profile screen - it's a representation of their identity in the app.

**Why Now**: 
This is the fourth piece of the app-wide design system overhaul (PR #006A → #006B → #006C → #006D). The Profile tab is highly visible and users interact with it frequently when managing their account. After enhancing auth screens, main app, and settings, the Profile tab is one of the last major screens that needs visual polish.

**Goals** (ordered, measurable):
- [ ] **G1** — Increase profile photo size from 120pt to 140pt for better visual presence
- [ ] **G2** — Update Edit Profile button to match design system (blue, full-width, with pencil icon)
- [ ] **G3** — Improve typography hierarchy with proper font styles and spacing
- [ ] **G4** — Apply consistent spacing throughout using the 8pt/16pt/24pt/32pt grid
- [ ] **G5** — Maintain all existing profile functionality with zero regressions

---

## 3. Non-Goals / Out of Scope

To keep this PR focused on visual polish:

- [ ] **Not changing** profile editing functionality (EditProfileView stays the same)
- [ ] **Not adding** new profile fields or data (use existing User model)
- [ ] **Not implementing** profile photo upload improvements (defer to PR #001)
- [ ] **Not adding** profile customization features (themes, status messages)
- [ ] **Not changing** navigation or tab bar structure
- [ ] **Not implementing** profile sharing or QR codes

---

## 4. Success Metrics

**User-visible**:
- Profile screen looks polished and professional
- Clear visual hierarchy (photo → name → email → button → details)
- Consistent with design system from PR #006A/B/C
- Photo appears prominent and centered

**System** (see `Psst/agents/shared-standards.md`):
- Profile screen renders in <100ms
- Photo loads smoothly (existing caching)
- Smooth 60fps scrolling
- No UI blocking

**Quality**:
- 0 visual regressions
- Edit Profile functionality works identically
- All acceptance gates pass
- Clean UI on all device sizes (SE to Pro Max)
- Dark Mode support (automatic with system colors)

---

## 5. Users & Stories

**Primary Users**: All app users viewing/managing their profile

**User Stories**:

1. **As a user**, I want my profile photo to be large and prominent so that I feel my identity is well-represented in the app.

2. **As a user**, I want the Edit Profile button to be easy to find and tap so that I can quickly update my information.

3. **As a user**, I want a clean, organized profile screen so that I can easily see my account information at a glance.

4. **As a user**, I want the Profile tab to match the quality of the rest of the app so that the experience feels cohesive and professional.

---

## 6. Experience Specification (UX)

### Entry Points

**Profile Tab**:
- Accessed via tab bar (2nd or 3rd tab, "Profile" icon)
- Main view: Profile screen with photo, name, email, button, info cards
- Navigation to EditProfileView via Edit Profile button

### Visual Behavior

**Profile Screen Layout**:

**Before (Current)**:
```
┌─────────────────────────┐
│      Profile            │
│                         │
│   [Photo 120pt]         │ ← Smaller
│      Sarah M            │
│  sarah@email.com        │
│                         │
│ [Edit Profile]          │ ← Basic button
│                         │
│ Account Information     │
│ ┌─────────────────────┐ │
│ │ 👤 User ID          │ │
│ │ 📅 Member Since     │ │
│ └─────────────────────┘ │
└─────────────────────────┘
```

**After (Enhanced)**:
```
┌─────────────────────────┐
│      Profile            │
│                         │
│   [Photo 140pt]         │ ← Larger, with border
│      Sarah Mitchell     │ ← .title + .bold
│  sarah@email.com        │ ← .subheadline + .secondary
│                         │
│ [✏️  Edit Profile]      │ ← Blue, full-width, icon
│                         │
│ Account Information     │ ← .headline
│ ┌─────────────────────┐ │
│ │ 👤 User ID          │ │ ← Better spacing
│ │ abc123...           │ │
│ │                     │ │
│ │ 📅 Member Since     │ │
│ │ Jan 15, 2025        │ │
│ └─────────────────────┘ │
│                         │
└─────────────────────────┘
```

**Design Details**:

**1. Profile Photo**:
- Size: **140pt** (up from 120pt)
- Circular with subtle border: 1pt, `.quaternaryLabel` color
- Top padding: 32pt from navigation bar
- If no photo: User initials on `.systemGray5` background
- Center aligned
- Use existing `ProfilePhotoPreview` component (update size prop)

**2. Name & Email**:
- **Name**: 
  - Font: `.title` + `.bold`
  - Color: `.label`
  - Center aligned
  - 16pt below profile photo
- **Email**:
  - Font: `.subheadline`
  - Color: `.secondary`
  - Center aligned
  - 4pt below name
  - 8pt spacing below email before button

**3. Edit Profile Button**:
- Style: `PrimaryButtonStyle()` (established in PR #006A)
- Background: `.blue` (iOS system blue)
- Text: "Edit Profile" in `.headline` + `.bold`
- Icon: `pencil` SF Symbol (leading, 16pt)
- Full width with 24pt horizontal padding
- Height: 44pt minimum (iOS touch target standard)
- Corner radius: 12pt (matches design system)
- 16pt padding from email above
- Center aligned
- Tap feedback: Scale to 0.98 with spring animation

**4. Account Information Section**:
- **Section Header**:
  - Text: "Account Information"
  - Font: `.headline`
  - Color: `.label`
  - 24pt horizontal padding
  - 32pt top padding from button (visual separation)
  
- **Info Card**:
  - Background: `.systemBackground` (white in light mode)
  - Corner radius: 12pt
  - 16pt top padding from header
  - 24pt horizontal padding
  - Shadow: None (flat design, matches system)

- **Info Rows** (use existing `ProfileInfoRow` component):
  - Icon: 20pt SF Symbol, `.blue` color
  - Label: `.caption` + `.secondary` (e.g., "User ID")
  - Value: `.body` + `.label` (e.g., "abc123...")
  - Row height: 44pt minimum
  - 16pt horizontal padding inside card
  - 12pt vertical padding per row
  - Divider between rows: 0.5pt, `.separator`, leading padding 56pt (after icon)

**5. Spacing Grid**:
- Top spacer: 20pt
- Photo to Name: 16pt
- Name to Email: 4pt
- Email to Button: 8pt
- Button top/bottom padding: 12pt (internal)
- Button to Section Header: 32pt
- Section Header to Card: 16pt
- Bottom spacing: Natural scroll (ScrollView)

**Visual States**:

**Loading State**:
- Skeleton loading for photo (gray circle with shimmer)
- Placeholder text for name/email
- Button disabled, grayed out

**Error State**:
- If user fetch fails: Show "Unable to load profile" message
- Retry button
- Keep basic structure visible

**No Photo State**:
- Circle with user initials (first letter of display name)
- Background: `.systemGray5`
- Text: `.title` + `.bold` + white color
- Same 140pt size with border

### Performance Targets

See `Psst/agents/shared-standards.md` for general targets. Specific to this feature:

- **Screen render**: <100ms to display Profile screen
- **Photo load**: <200ms (existing caching from UserService)
- **Edit Profile navigation**: <50ms
- **Smooth scrolling**: 60fps for all scroll interactions

---

## 7. Functional Requirements (Must/Should)

### Must-Have Requirements

**R1**: Profile photo MUST be 140pt with 1pt border
- **Acceptance Gate**: Photo renders at 140pt, circular, with subtle border visible

**R2**: Name MUST use `.title` + `.bold`, email MUST use `.subheadline` + `.secondary`
- **Acceptance Gate**: Typography matches spec, proper color contrast in Light/Dark Mode

**R3**: Edit Profile button MUST match design system (blue, full-width, pencil icon)
- **Acceptance Gate**: Button uses `PrimaryButtonStyle()`, has pencil icon, full width with 24pt padding

**R4**: Spacing MUST follow 8pt/16pt/24pt/32pt grid consistently
- **Acceptance Gate**: All spacing measurements match spec exactly

**R5**: Account Information section MUST use updated layout with proper card styling
- **Acceptance Gate**: Card has 12pt radius, proper padding, rows use existing `ProfileInfoRow` component

**R6**: Edit Profile button MUST navigate to existing EditProfileView
- **Acceptance Gate**: Tap button → Sheet presents EditProfileView successfully

**R7**: All existing profile functionality MUST work identically (0 regressions)
- **Acceptance Gate**: User data loads, Edit Profile works, profile updates reflect correctly

### Should-Have Requirements

**R8**: Profile photo border SHOULD be subtle (1pt, quaternaryLabel)
- **Acceptance Gate**: Border visible but not distracting in both Light/Dark Mode

**R9**: Button tap SHOULD have subtle animation (scale 0.98)
- **Acceptance Gate**: Tap shows spring animation feedback

**R10**: Loading state SHOULD show skeleton UI
- **Acceptance Gate**: While loading, skeleton visible for photo/name/email

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
    var createdAt: Date
}
```

---

## 9. API / Service Contracts

**No new service methods required.** Uses existing services.

**Existing Services Used**:

```swift
// From UserService (no changes)
func getCurrentUser() async throws -> User
func updateProfile(displayName: String?, photoURL: String?) async throws

// From AuthViewModel (no changes)
@Published var currentUser: User?
```

---

## 10. UI Components to Create/Modify

### Files to Modify

**Profile Tab** (1 file to modify):
- `Views/Profile/ProfileView.swift` — Update photo size, typography, button style, spacing

**Components** (potentially update):
- `Components/ProfilePhotoPreview.swift` — Verify border styling works with larger size
- `Utilities/ButtonStyles.swift` — Ensure `PrimaryButtonStyle()` exists (from PR #006A)

**Total**: 1 modified, 0 new = 1 file (minimal changes)

### Implementation Breakdown

**ProfileView.swift Updates**:

```swift
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showEditProfile = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Top spacing
                    Spacer()
                        .frame(height: 20)
                    
                    // Profile Photo (UPDATED: 140pt with border)
                    if let user = authViewModel.currentUser {
                        ProfilePhotoPreview(
                            imageURL: user.photoURL,
                            selectedImage: nil,
                            isLoading: false,
                            size: 140
                        )
                        .overlay(
                            Circle()
                                .stroke(Color(.quaternaryLabel), lineWidth: 1)
                        )
                        .padding(.top, 32)
                        
                        // Display Name (UPDATED: .title + .bold)
                        Text(user.displayName)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.label)
                            .padding(.top, 16)
                        
                        // Email (UPDATED: .subheadline + .secondary)
                        Text(user.email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                        
                        // Edit Profile Button (UPDATED: Full width, blue, icon)
                        Button(action: {
                            showEditProfile = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 16))
                                Text("Edit Profile")
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        
                        // Account Info Section (UPDATED: Better spacing)
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Account Information")
                                .font(.headline)
                                .foregroundColor(.label)
                                .padding(.horizontal, 24)
                            
                            VStack(spacing: 0) {
                                ProfileInfoRow(
                                    icon: "person.fill",
                                    label: "User ID",
                                    value: String(user.id.prefix(8)) + "..."
                                )
                                
                                Divider()
                                    .padding(.leading, 56)
                                
                                ProfileInfoRow(
                                    icon: "calendar",
                                    label: "Member Since",
                                    value: user.createdAt.formatted(date: .abbreviated, time: .omitted)
                                )
                            }
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .padding(.horizontal, 24)
                        }
                        .padding(.top, 32)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showEditProfile) {
                if let user = authViewModel.currentUser {
                    EditProfileView(user: user)
                }
            }
        }
    }
}
```

**Changes Summary**:
- Photo: 120pt → 140pt, add border overlay
- Name: Add `.title` + `.bold` + `.foregroundColor(.label)`
- Email: Update spacing (4pt from name)
- Button: Add pencil icon, use `PrimaryButtonStyle()`, full width
- Section header: Add `.foregroundColor(.label)`
- Spacing: Update all padding values to match 8pt grid

---

## 11. Integration Points

### Existing Integrations (No Changes)
- **Firebase Authentication**: User authentication (existing)
- **UserService**: Current user data fetching (existing)
- **AuthViewModel**: State management (existing)
- **EditProfileView**: Existing profile editing screen (navigation only)
- **ProfilePhotoPreview**: Existing photo display component (update size prop)

### Design Consistency
- Uses design system from PR #006A:
  - Color: `.blue` accent (button), system colors
  - Typography: iOS text styles (`.title`, `.headline`, `.subheadline`)
  - Spacing: 8pt/16pt/24pt/32pt grid
  - Button style: `PrimaryButtonStyle()` (established in #006A)
  - Corner radius: 12pt (standard)

---

## 12. Testing Plan & Acceptance Gates

### Configuration Testing
- [ ] Firebase Authentication connected (user loads)
- [ ] UserService can fetch current user
- [ ] AuthViewModel provides current user data

### Visual Testing
- [ ] Profile photo renders at 140pt (not 120pt)
- [ ] Photo has 1pt border (`.quaternaryLabel`)
- [ ] Name uses `.title` + `.bold`
- [ ] Email uses `.subheadline` + `.secondary`
- [ ] Edit Profile button has pencil icon
- [ ] Edit Profile button is full width (24pt horizontal padding)
- [ ] Edit Profile button uses `PrimaryButtonStyle()` (blue)
- [ ] Account Information header uses `.headline`
- [ ] Info card has 12pt corner radius
- [ ] All spacing matches spec (16pt, 24pt, 32pt grid)
- [ ] Dark Mode: All colors adapt correctly

### Happy Path Testing
- [ ] Gate: Profile screen loads in <100ms
- [ ] Gate: Profile photo displays correctly (140pt, bordered)
- [ ] Gate: User name and email display correctly
- [ ] Gate: Tap "Edit Profile" → Navigates to EditProfileView
- [ ] Gate: Edit Profile sheet presents smoothly
- [ ] Gate: Back navigation works from EditProfileView

### Edge Cases Testing
- [ ] No profile photo → Shows initials in circle (140pt)
- [ ] Very long display name → Text doesn't overflow, wraps properly
- [ ] Very long email → Text truncates with ellipsis
- [ ] User fetch fails → Show error, retry button
- [ ] Edit Profile while offline → Shows appropriate error

### Multi-Device Testing
- [ ] iPhone SE → Profile looks good, button tappable
- [ ] iPhone 15 → Profile looks perfect
- [ ] iPhone 15 Pro Max → Profile looks perfect, no awkward spacing
- [ ] Landscape → Profile adapts (scrollable if needed)
- [ ] Dark Mode → All colors and contrasts correct

### Performance Testing
- [ ] Profile screen renders in <100ms
- [ ] Photo loads in <200ms (existing caching)
- [ ] Edit Profile navigation <50ms
- [ ] Smooth 60fps scrolling
- [ ] No memory leaks

### Regression Testing
- [ ] EditProfileView still works (existing functionality)
- [ ] Profile updates reflect correctly (name/photo changes)
- [ ] Tab navigation works
- [ ] User data still loads correctly

---

## 13. Definition of Done

- [ ] ProfileView updated with 140pt photo size
- [ ] Photo border added (1pt, quaternaryLabel)
- [ ] Name typography updated (.title + .bold)
- [ ] Email typography updated (.subheadline + .secondary)
- [ ] Edit Profile button redesigned (blue, full-width, icon)
- [ ] Account Information section spacing updated
- [ ] All spacing follows 8pt/16pt/24pt/32pt grid
- [ ] Edit Profile navigation works (0 regressions)
- [ ] Dark Mode supported
- [ ] Manual testing completed (all gates pass)
- [ ] Code review completed
- [ ] Design reviewed and approved (matches UX spec)

---

## 14. Risks & Mitigations

**Risk**: Larger photo size affects loading performance
- **Mitigation**: Use existing caching; 140pt still small enough for fast loading

**Risk**: Border looks too harsh or invisible
- **Mitigation**: Use `.quaternaryLabel` (subtle in Light/Dark Mode); test extensively

**Risk**: Full-width button looks awkward on large screens
- **Mitigation**: 24pt horizontal padding creates breathing room; standard iOS pattern

**Risk**: Spacing changes break layout on small devices
- **Mitigation**: Test on iPhone SE; ScrollView handles overflow gracefully

**Risk**: Existing ProfilePhotoPreview component doesn't support border
- **Mitigation**: Add border as overlay (no component changes needed)

---

## 15. Rollout & Telemetry

**Feature Flag**: No

**Rollout Strategy**: 
- Deploy as part of PR #006D
- Continues design system overhaul (006A → 006B → 006C → 006D)
- No gradual rollout needed

**Manual Validation**:
- Test all device sizes
- Verify Dark Mode
- Test Edit Profile navigation
- Screenshot before/after for documentation

**Success Indicators**:
- 0 Profile-related bug reports
- Edit Profile works without issues
- Improved visual consistency across app
- Professional appearance matches iOS standards

---

## 16. Open Questions

**Q1**: Should the profile photo have a tap action (view full-size)?
- **Answer**: Not for this PR; focus on visual polish only; can add in future PR

**Q2**: Should we show user status/bio in this view?
- **Answer**: No, keep minimal (name, email, account info only); defer to Phase 2

**Q3**: Should the border be thicker or have a custom color?
- **Answer**: 1pt `.quaternaryLabel` is subtle and adapts to Dark Mode; test and iterate if needed

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future phases:

**Phase 2 - Profile Enhancements**:
- [ ] Profile photo tap to view full-size
- [ ] User status/bio field
- [ ] Profile customization (themes, colors)
- [ ] Profile sharing (QR code, link)
- [ ] Profile badges or verification

**Phase 2 - Profile Analytics**:
- [ ] Profile view tracking
- [ ] Last updated timestamp
- [ ] Activity stats (messages sent, etc.)

---

## Preflight Questionnaire

1. **Smallest end-to-end user outcome for this PR?**
   - User sees polished Profile screen with larger photo and better design

2. **Primary user and critical action?**
   - All users viewing their profile, tapping Edit Profile button

3. **Must-have vs nice-to-have?**
   - Must: Photo size, typography, button redesign, spacing
   - Nice: Button animation, subtle border styling

4. **Real-time requirements?**
   - None (Profile is mostly static UI)

5. **Performance constraints?**
   - Screen render <100ms, photo load <200ms

6. **Error/edge cases to handle?**
   - No photo (initials), long text, user fetch failure

7. **Data model changes?**
   - None (uses existing User model)

8. **Service APIs required?**
   - None (uses existing UserService, AuthViewModel)

9. **UI entry points and states?**
   - Entry: Profile tab from tab bar
   - States: Default, loading, error, no photo

10. **Security/permissions implications?**
    - None (uses existing Firebase auth)

11. **Dependencies or blocking integrations?**
    - Depends on: PR #006A (button styles), PR #17 (EditProfileView)
    - Blocks: None

12. **Rollout strategy and metrics?**
    - Deploy directly, part of PR #006 series
    - Success: Professional Profile UI, 0 regressions

13. **What is explicitly out of scope?**
    - Profile editing logic, new fields, photo upload improvements, profile sharing

---

**End of PRD**

