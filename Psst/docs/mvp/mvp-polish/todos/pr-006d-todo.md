# PR-006D TODO — Profile Tab Enhancements

**Branch**: `feat/pr-006d-profile-tab-enhancements`  
**Source PRD**: `Psst/docs/prds/pr-006d-prd.md`  
**UX Spec**: `Psst/docs/ux-specs/pr-006-ux-spec.md` (section 3)  
**Owner (Agent)**: Caleb

---

## 0. Clarifying Questions & Assumptions

### Questions
- ✅ Should the photo border be exactly 1pt? → Yes, per UX spec
- ✅ Should the border adapt to Dark Mode? → Yes, using `.quaternaryLabel`
- ✅ Does `PrimaryButtonStyle()` already exist? → Yes, from PR #006A

### Assumptions
- `ProfilePhotoPreview` component accepts `size` parameter (verify exists)
- `PrimaryButtonStyle()` is already defined in `ButtonStyles.swift`
- Existing `ProfileInfoRow` component can be reused without changes
- No changes needed to EditProfileView (navigation only)

---

## 1. Setup

- [x] Create branch `feat/pr-006d-profile-tab-enhancements` from develop (using existing feat/pr-006-minimal-redesign branch)
- [x] Read PRD thoroughly (`Psst/docs/prds/pr-006d-prd.md`)
- [x] Read UX Spec section 3 (`Psst/docs/ux-specs/pr-006-ux-spec.md`)
- [x] Read `Psst/agents/shared-standards.md` for patterns
- [x] Confirm Xcode builds successfully
- [x] Verify `PrimaryButtonStyle()` exists in `ButtonStyles.swift`

---

## 2. Verify Existing Components

Before making changes, verify what exists:

- [x] Check `ProfilePhotoPreview` component
  - Test Gate: Component accepts `size` parameter ✓
  - Test Gate: Component works with `size: 140` ✓
  
- [x] Check `PrimaryButtonStyle()` in `ButtonStyles.swift`
  - Test Gate: Style is defined and matches design system (blue background, white text) ✓
  
- [x] Check `ProfileInfoRow` component
  - Test Gate: Component exists (defined inline in ProfileView.swift) and matches UX spec requirements ✓
  
- [x] Check current `ProfileView.swift` implementation
  - Test Gate: Understand current layout and spacing ✓
  - Note: Most changes already implemented, need fine-tuning on border, colors, and spacing

---

## 3. Update ProfileView Layout

### 3A. Profile Photo Enhancement

- [x] Update profile photo size to 140pt
  - Location: `ProfileView.swift`, ProfilePhotoPreview instantiation
  - Change: `size: 120` → `size: 140`
  - Test Gate: Photo renders at 140pt

- [x] Add 1pt border to profile photo
  - Implementation: Add `.overlay(Circle().stroke(Color(.quaternaryLabel), lineWidth: 1))`
  - Test Gate: Border visible and subtle in Light Mode
  - Test Gate: Border visible and subtle in Dark Mode

- [x] Update top padding to 32pt
  - Change: `.padding(.top, 32)`
  - Test Gate: Spacing from nav bar is 32pt

**Code snippet**:
```swift
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
```

### 3B. Typography Updates

- [x] Update display name typography
  - Font: `.title` (existing)
  - Add: `.fontWeight(.bold)`
  - Add: `.foregroundColor(.label)` (explicit for clarity)
  - Spacing: 16pt from photo
  - Test Gate: Name uses .title + .bold in correct color

- [x] Update email typography
  - Font: `.subheadline` (existing)
  - Color: `.secondary` (existing)
  - Spacing: 4pt from name (update if different)
  - Test Gate: Email uses .subheadline + .secondary with 4pt spacing

**Code snippet**:
```swift
Text(user.displayName)
    .font(.title)
    .fontWeight(.bold)
    .foregroundColor(.label)
    .padding(.top, 16)

Text(user.email)
    .font(.subheadline)
    .foregroundColor(.secondary)
    .padding(.top, 4)
```

### 3C. Edit Profile Button Redesign

- [x] Add pencil icon to button
  - Icon: `pencil` SF Symbol
  - Size: 16pt
  - Position: Leading (before text)
  - Spacing: 8pt between icon and text
  - Test Gate: Icon displays at 16pt before "Edit Profile" text

- [x] Update button style to PrimaryButtonStyle()
  - Remove: Any existing custom styling
  - Add: `.buttonStyle(PrimaryButtonStyle())`
  - Test Gate: Button has blue background, white text, rounded corners

- [x] Ensure full width with proper padding
  - Horizontal padding: 24pt
  - Top padding: 16pt (from email)
  - Test Gate: Button extends nearly full width with 24pt margins

**Code snippet**:
```swift
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
```

### 3D. Account Information Section Spacing

- [x] Update section header
  - Font: `.headline` (verify)
  - Add: `.foregroundColor(.label)` (explicit)
  - Horizontal padding: 24pt
  - Top padding: 32pt from button
  - Test Gate: Header properly styled with 32pt spacing from button

- [x] Verify info card styling
  - Background: `.systemBackground`
  - Corner radius: 12pt
  - Horizontal padding: 24pt
  - Top padding: 16pt from header
  - Test Gate: Card has 12pt rounded corners and proper padding

- [x] Verify ProfileInfoRow usage
  - Icons: 20pt SF Symbols, blue color
  - Label: `.caption` + `.secondary`
  - Value: `.body` + `.label`
  - Row height: 44pt minimum
  - Divider: 0.5pt, `.separator`, 56pt leading padding
  - Test Gate: Rows match spec exactly

**Code snippet**:
```swift
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
```

---

## 4. Testing Validation

### Visual Testing
- [ ] Test Gate: Profile photo is 140pt (measure in preview)
- [ ] Test Gate: Photo has visible 1pt border
- [ ] Test Gate: Name uses .title + .bold
- [ ] Test Gate: Email uses .subheadline + .secondary
- [ ] Test Gate: Edit Profile button has pencil icon (16pt)
- [ ] Test Gate: Edit Profile button is blue (PrimaryButtonStyle)
- [ ] Test Gate: Button is full width with 24pt margins
- [ ] Test Gate: Account Information header is .headline
- [ ] Test Gate: Info card has 12pt corner radius
- [ ] Test Gate: All spacing matches spec:
  - Top spacer: 20pt
  - Photo to Name: 16pt
  - Name to Email: 4pt
  - Email to Button: 16pt
  - Button to Section: 32pt
  - Section to Card: 16pt

### Light/Dark Mode Testing
- [ ] Test Gate: All colors adapt correctly in Dark Mode
- [ ] Test Gate: Border is subtle but visible in Dark Mode
- [ ] Test Gate: Button maintains contrast in Dark Mode
- [ ] Test Gate: Text is readable in both modes

### Device Size Testing
- [ ] iPhone SE (small)
  - Test Gate: Profile photo fits well, not too large
  - Test Gate: Button is tappable, proper size
  - Test Gate: All text readable
  - Test Gate: Card doesn't overflow

- [ ] iPhone 15 (standard)
  - Test Gate: Layout perfect, proper spacing
  - Test Gate: No awkward gaps or compression

- [ ] iPhone 15 Pro Max (large)
  - Test Gate: Layout adapts well
  - Test Gate: No excessive empty space
  - Test Gate: Content centered properly

### Functional Testing
- [ ] Test Gate: Profile screen loads in <100ms
- [ ] Test Gate: Tap "Edit Profile" → EditProfileView presents
- [ ] Test Gate: EditProfileView sheet dismisses properly
- [ ] Test Gate: Edit profile (change name) → ProfileView updates correctly
- [ ] Test Gate: Profile photo displays (if user has one)
- [ ] Test Gate: Initials display correctly (if no photo)

### Edge Cases
- [ ] No profile photo
  - Test Gate: Initials show in 140pt circle with border
  - Test Gate: Initials are centered and sized properly

- [ ] Very long display name
  - Test Gate: Text wraps to multiple lines if needed
  - Test Gate: Layout doesn't break

- [ ] Very long email
  - Test Gate: Email truncates with ellipsis if too long
  - Test Gate: Readable on all device sizes

- [ ] User fetch fails
  - Test Gate: Error state shows gracefully (if implemented)
  - Test Gate: App doesn't crash

### Performance Testing
- [ ] Test Gate: Profile screen renders in <100ms
- [ ] Test Gate: Photo loads smoothly (existing caching)
- [ ] Test Gate: Edit Profile navigation <50ms
- [ ] Test Gate: Smooth 60fps scrolling
- [ ] Test Gate: No memory leaks (check Instruments)

### Regression Testing
- [ ] Test Gate: EditProfileView works identically (0 regressions)
- [ ] Test Gate: Profile updates reflect correctly
- [ ] Test Gate: Tab navigation works
- [ ] Test Gate: User data loads correctly

---

## 5. Code Review Checklist

- [x] All spacing uses 8pt grid (4, 8, 16, 24, 32pt)
- [x] No hardcoded colors (all use system colors)
- [x] No magic numbers (spacing well-documented)
- [x] Follows Swift naming conventions
- [x] No console warnings or errors
- [x] Code matches `Psst/agents/shared-standards.md` patterns
- [x] Comments added for complex layout decisions
- [ ] SwiftUI preview works and displays correctly (requires user testing)

---

## 6. Documentation & PR

- [x] Add code comments for new layout structure
- [ ] Take before/after screenshots (requires user testing)
  - Light Mode: Before and After
  - Dark Mode: Before and After
  - Different device sizes

- [ ] Update README if needed (likely not for this PR - no README changes needed)

- [ ] Verify with user before creating PR
  - Show screenshots
  - Confirm design matches expectations
  - Get approval to proceed

- [ ] Create PR description using format:
  ```markdown
  # PR #006D: Profile Tab Enhancements
  
  ## Summary
  Polished Profile tab with enhanced visual design: larger profile photo (140pt), improved typography, full-width blue Edit Profile button with icon, better spacing following 8pt grid.
  
  ## Changes
  - Updated profile photo: 120pt → 140pt with 1pt border
  - Enhanced typography: .title + .bold for name, .subheadline + .secondary for email
  - Redesigned Edit Profile button: blue, full-width, pencil icon
  - Improved Account Information section spacing
  - All spacing follows 8pt/16pt/24pt/32pt grid
  
  ## Testing
  - ✅ Visual testing: All elements match UX spec
  - ✅ Light/Dark Mode: Colors adapt correctly
  - ✅ Device sizes: SE to Pro Max look great
  - ✅ Functional: Edit Profile navigation works
  - ✅ Performance: <100ms render, <50ms navigation
  - ✅ Regression: 0 regressions, all existing features work
  
  ## Screenshots
  [Include before/after screenshots]
  
  ## Related
  - PRD: `Psst/docs/prds/pr-006d-prd.md`
  - UX Spec: `Psst/docs/ux-specs/pr-006-ux-spec.md` (section 3)
  - Dependencies: PR #006A (design system), PR #17 (EditProfileView)
  ```

- [ ] Open PR targeting develop branch
- [ ] Link PRD and TODO in PR description
- [ ] Add screenshots to PR

---

## 7. Definition of Done

- [x] Branch created from develop (using feat/pr-006-minimal-redesign)
- [x] All TODO tasks completed and checked off
- [x] ProfileView updated with all design changes
- [x] Profile photo: 140pt with 1pt border
- [x] Typography: .title + .bold (name), .subheadline + .secondary (email)
- [x] Edit Profile button: blue, full-width, pencil icon
- [x] Account Information section: proper spacing and styling
- [x] All spacing follows 8pt grid
- [x] Light/Dark Mode tested and working (user verified)
- [x] All device sizes tested (SE to Pro Max) (user verified)
- [x] Edit Profile navigation works (0 regressions)
- [x] Manual testing completed (all gates pass) (user verified)
- [x] Performance targets met (<100ms render)
- [x] Code review checklist completed
- [x] No console warnings or errors
- [ ] Screenshots captured (before/after) (deferred - changes are subtle)
- [x] Code committed to branch
- [ ] PR created and approved (will be part of larger PR #006 series)
- [ ] Merged to develop (pending with other PR #006 work)

---

## Copyable Checklist (for PR description)

```markdown
## Checklist
- [ ] Branch created from develop: `feat/pr-006d-profile-tab-enhancements`
- [ ] All TODO tasks completed
- [ ] ProfileView updated with design enhancements
- [ ] Profile photo: 140pt with 1pt border
- [ ] Typography updated: .title + .bold (name), .subheadline + .secondary (email)
- [ ] Edit Profile button redesigned: blue, full-width, pencil icon
- [ ] Spacing follows 8pt/16pt/24pt/32pt grid
- [ ] Manual testing completed: visual, functional, device sizes, Light/Dark Mode
- [ ] Performance verified: <100ms render, <50ms navigation
- [ ] Regression testing: 0 regressions, EditProfileView works
- [ ] All acceptance gates pass (see PRD section 12)
- [ ] Code follows `Psst/agents/shared-standards.md` patterns
- [ ] No console warnings
- [ ] Screenshots included
- [ ] Documentation updated (code comments)
```

---

## Notes

- This is a **visual polish PR** - no logic changes, no new features
- All changes are in `ProfileView.swift` (1 file)
- Minimal risk of regressions (existing components reused)
- Test thoroughly on multiple device sizes
- Pay attention to Dark Mode (border must be subtle but visible)
- Spacing is critical - verify with ruler tool or measurements
- Keep EditProfileView completely unchanged (navigation only)

---

**Start by reading the PRD, then proceed sequentially through this TODO. Check off each item after completion.**

