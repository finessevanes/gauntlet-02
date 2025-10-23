# PR-006A TODO — Authentication Redesign - Clean iOS Patterns

**Branch**: `feat/pr-006a-authentication-redesign`  
**Source PRD**: `Psst/docs/prds/pr-006a-prd.md`  
**Owner (Agent)**: Caleb

---

## 0. Clarifying Questions & Assumptions

- **Questions**: None - this is a clear UI-only redesign
- **Assumptions (confirm in PR if needed)**:
  - All existing authentication functionality remains unchanged (email signin, Google signin, signup, password reset)
  - ButtonStyles created here will be reused in PR #006B and #006C for consistency
  - This establishes the design system foundation (colors, typography, spacing) for the entire app
  - No Firebase auth configuration changes needed

---

## 1. Setup

- [ ] Create branch `feat/pr-006a-authentication-redesign` from develop
- [ ] Read PRD thoroughly (`Psst/docs/prds/pr-006a-prd.md`)
- [ ] Read `Psst/agents/shared-standards.md` for patterns
- [ ] Read UX spec (`Psst/docs/ux-specs/pr-006-ux-spec.md` sections 1-2)
- [ ] Confirm environment and test runner work

---

## 2. Service Layer

No new service methods needed. This is a UI-only change that uses existing authentication services.

- [ ] Verify existing AuthenticationService methods work correctly
  - Test Gate: Email signin, Google signin, signup, password reset all function unchanged
- [ ] Confirm no changes needed to existing service contracts
  - Test Gate: All existing auth functionality continues to work identically

---

## 3. Data Model & Rules

No changes to existing Firebase auth configuration. This is a UI-only change.

- [ ] Confirm existing Firebase Authentication setup is sufficient
  - Test Gate: No Firebase auth configuration changes needed
- [ ] Verify Firebase security rules unchanged
  - Test Gate: Existing auth permissions work correctly
- [ ] Confirm AuthViewModel needs only minor UI state additions (if any)
  - Test Gate: Existing state management works with new UI

---

## 4. UI Components

Create/modify SwiftUI views per PRD Section 10.

### Create ButtonStyles.swift (New File)

- [x] Create `Utilities/ButtonStyles.swift`
  - Test Gate: File created in correct location
- [x] Implement `PrimaryButtonStyle` (blue, `.borderedProminent`)
  - Test Gate: Style matches iOS blue button with prominent appearance
- [x] Implement `SecondaryButtonStyle` (gray, `.bordered`)
  - Test Gate: Style matches iOS gray button with bordered appearance
- [x] Implement `DestructiveButtonStyle` (red, for logout)
  - Test Gate: Style matches iOS red destructive button
- [x] Add SwiftUI Preview with all 3 button styles
  - Test Gate: Preview renders all 3 button styles correctly
- [x] Test Dark Mode compatibility
  - Test Gate: All button styles adapt to Dark Mode automatically

### Modify LoginView.swift

- [x] Remove gradient background
  - Replace with `.background(Color(.systemBackground))`
  - Test Gate: Background is white (light mode) / black (dark mode)
- [x] Remove card container and shadow decorations
  - Test Gate: No card, no shadows, clean flat design
- [x] Simplify icon presentation
  - Use monochrome icon or simple "Psst" text (40pt)
  - Remove colored circles
  - Test Gate: Icon is simple and monochrome
- [x] Update heading typography
  - "Welcome Back" → `.font(.largeTitle)` + `.fontWeight(.bold)`
  - "Sign in to continue" → `.font(.subheadline)` + `.foregroundColor(.secondary)`
  - Test Gate: Typography uses iOS system text styles
- [x] Apply `PrimaryButtonStyle` to "Continue with Email" button
  - Test Gate: Button is blue with prominent style
- [x] Apply `SecondaryButtonStyle` to "Continue with Google" button
  - Test Gate: Button is gray with bordered style
- [x] Update spacing
  - Horizontal padding: 24pt
  - Vertical spacing between elements: 16pt
  - Test Gate: Spacing follows 8/16/24pt grid
- [x] Keep "Sign up" link with blue color
  - Test Gate: Link uses `.foregroundColor(.blue)`
- [x] Test SwiftUI Preview
  - Test Gate: Preview renders clean design, zero console errors
- [x] Test Dark Mode
  - Test Gate: All elements adapt correctly to Dark Mode

### Modify SignUpView.swift

- [x] Remove gradient background
  - Replace with `.background(Color(.systemBackground))`
  - Test Gate: Background is white (light mode) / black (dark mode)
- [x] Remove card layout and decorative elements
  - Test Gate: Clean, flat design with no decorations
- [x] Add standard navigation bar
  - Use `NavigationStack` with standard nav bar
  - Title: "Sign Up"
  - Test Gate: Standard iOS nav bar with back button
- [x] Update heading typography
  - "Create Account" → `.font(.title2)` + `.fontWeight(.semibold)`
  - Test Gate: Heading uses iOS system text style
- [x] Convert form to VStack with standard TextFields
  - Full Name field: Standard `TextField` with `.textFieldStyle(.roundedBorder)`
  - Email field: Standard `TextField` with `.textFieldStyle(.roundedBorder)`
  - Password field: Standard `SecureField` with `.textFieldStyle(.roundedBorder)`
  - Test Gate: All text fields use standard iOS styling
- [x] Add field labels
  - Use `.font(.caption)` for labels above each field
  - Test Gate: Labels are clear and use caption font
- [x] Apply `PrimaryButtonStyle` to "Sign Up" button
  - Test Gate: Button is blue with prominent style
- [x] Keep "Log in" link with blue color
  - Test Gate: Link uses `.foregroundColor(.blue)`
- [x] Update spacing to 8/16/24pt grid
  - Horizontal padding: 24pt
  - Vertical spacing: 16pt between fields, 24pt before button
  - Test Gate: Spacing follows consistent grid
- [x] Test SwiftUI Preview
  - Test Gate: Preview renders form layout correctly, zero console errors
- [x] Test Dark Mode
  - Test Gate: Form adapts correctly to Dark Mode

### Modify EmailSignInView.swift

- [x] Remove gradient background
  - Replace with `.background(Color(.systemBackground))`
  - Test Gate: Background is white (light mode) / black (dark mode)
- [x] Remove decorative elements
  - Test Gate: Clean, minimal modal design
- [x] Keep sheet presentation style
  - Test Gate: Opens as `.sheet` modal from LoginView/SignUpView
- [x] Simplify layout to minimal form
  - Email field: Standard `TextField` with `.textFieldStyle(.roundedBorder)`
  - Password field: Standard `SecureField` with `.textFieldStyle(.roundedBorder)`
  - Test Gate: Text fields use standard styling
- [x] Add field labels
  - Use `.font(.caption)` for labels
  - Test Gate: Labels are clear and readable
- [x] Keep "Forgot password?" link (right-aligned)
  - Test Gate: Link is visible and tappable
- [x] Apply `PrimaryButtonStyle` to "Continue" button
  - Test Gate: Button is blue with prominent style
- [x] Update spacing
  - Horizontal padding: 24pt
  - Vertical spacing: 16pt between elements
  - Test Gate: Spacing follows grid
- [x] Test SwiftUI Preview
  - Test Gate: Preview renders as clean modal, zero console errors
- [x] Test Dark Mode
  - Test Gate: Modal adapts correctly to Dark Mode

---

## 5. Integration & Real-Time

Reference requirements from `Psst/agents/shared-standards.md`.

- [ ] Firebase Authentication integration (unchanged)
  - Test Gate: Firebase auth still works after UI changes
- [ ] Email signin flow works
  - Test Gate: User can sign in with email/password successfully
- [ ] Google signin flow works (if implemented)
  - Test Gate: Google signin button works (or remains placeholder)
- [ ] Signup flow works
  - Test Gate: User can create account with email/password successfully
- [ ] Password reset flow works
  - Test Gate: Forgot password sends reset email successfully
- [ ] Navigation between auth screens works
  - Test Gate: LoginView → SignUpView → EmailSignInView transitions work
- [ ] Sheet presentations work
  - Test Gate: EmailSignInView opens/closes as sheet correctly

---

## 6. Testing Validation

**Current**: Manual testing validation (see `Psst/agents/shared-standards.md`)  
**Future**: Automated testing recommendations in `Psst/docs/testing-strategy.md`

### Configuration Testing

- [ ] Firebase Authentication connected and working
  - Test Gate: Firebase auth configured, no connection errors
- [ ] Email signin configured
  - Test Gate: Can sign in with email/password
- [ ] Signup flow configured
  - Test Gate: Can create new account
- [ ] Password reset configured
  - Test Gate: Can request password reset email
  
### Visual Testing

- [ ] LoginView renders with clean design
  - Test Gate: No gradient, uses `.systemBackground`, clean layout
- [ ] SignUpView renders with standard form layout
  - Test Gate: Standard iOS form with proper text fields
- [ ] EmailSignInView renders as minimal modal
  - Test Gate: Clean modal sheet with minimal design
- [ ] All text uses iOS system fonts
  - Test Gate: `.largeTitle`, `.title2`, `.body`, `.subheadline`, `.caption` used correctly
- [ ] All buttons use new ButtonStyles
  - Test Gate: Primary (blue), Secondary (gray), proper styling
- [ ] Spacing follows 8/16/24pt grid
  - Test Gate: All padding and spacing uses multiples of 8pt
- [ ] Dark Mode renders correctly on all 3 screens
  - Test Gate: Toggle Dark Mode, all screens adapt with proper contrast

### Happy Path Testing

- [ ] Gate: User can tap "Continue with Email" → EmailSignInView opens as sheet
- [ ] Gate: User can enter email/password → Sign in successful → Navigate to main app
- [ ] Gate: User can tap "Sign up" link → SignUpView opens
- [ ] Gate: User can complete signup form → Account created → Navigate to main app
- [ ] Gate: User can tap "Forgot password?" → Password reset email sent
- [ ] Gate: User can dismiss EmailSignInView sheet → Returns to LoginView
- [ ] Gate: User can navigate back from SignUpView → Returns to LoginView

### Edge Cases Testing

- [ ] Empty email/password fields → Button disabled or shows validation
  - Test Gate: Cannot submit with empty fields
- [ ] Invalid email format → Show inline error message
  - Test Gate: Error appears below field, not as alert
- [ ] Wrong credentials → Show inline error message (not alert)
  - Test Gate: "Invalid email or password" appears inline
- [ ] Network error → Show clear error message
  - Test Gate: Network errors handled gracefully
- [ ] Multiple rapid taps on button → Prevent duplicate requests
  - Test Gate: Button disables during auth operation
- [ ] Very long email/name → Text truncates or wraps properly
  - Test Gate: UI doesn't break with long text

### Multi-Device Testing

- [ ] iPhone SE (small screen) → Layout works without overflow
  - Test Gate: All content visible and accessible
- [ ] iPhone 15 → Layout works perfectly
  - Test Gate: Optimal layout and spacing
- [ ] iPhone 15 Pro Max (large screen) → Layout works without awkward spacing
  - Test Gate: Content centered, not stretched awkwardly
- [ ] Landscape orientation → Layout adapts
  - Test Gate: All screens work in landscape mode
- [ ] Dark Mode on all devices → Proper contrast and readability
  - Test Gate: Dark Mode looks good on all device sizes

### Performance Testing

- [ ] LoginView loads in < 100ms
  - Test Gate: Screen appears quickly on app launch
- [ ] SignUpView loads in < 100ms
  - Test Gate: Navigation to signup is instant
- [ ] EmailSignInView presents in < 100ms
  - Test Gate: Sheet animation is smooth and fast
- [ ] Button tap feedback < 50ms
  - Test Gate: Immediate visual response on tap
- [ ] Smooth 60fps transitions between auth screens
  - Test Gate: No lag or stuttering during navigation
- [ ] Dark Mode toggles instantly
  - Test Gate: No delay when switching Dark Mode

### Regression Testing

- [ ] All existing auth flows work identically to before
  - Test Gate: Email signin success → Navigates to main app
  - Test Gate: Google signin (if implemented) works unchanged
  - Test Gate: Signup success → Creates account and navigates
  - Test Gate: Password reset → Sends email successfully
  - Test Gate: Logout → Returns to LoginView
- [ ] No console errors or warnings
  - Test Gate: Clean console output during all auth flows

---

## 7. Performance

Verify targets from `Psst/agents/shared-standards.md`.

- [ ] Screen render time < 100ms (no performance degradation)
  - Test Gate: Auth screens load as fast or faster than before
- [ ] Button tap feedback < 50ms
  - Test Gate: Immediate visual response on button press
- [ ] Smooth 60fps animations
  - Test Gate: Navigation transitions at 60fps
- [ ] Dark Mode toggle instant
  - Test Gate: No lag when switching appearance modes
- [ ] No memory leaks from UI changes
  - Test Gate: Monitor memory usage, no unusual growth

---

## 8. Acceptance Gates

Check every gate from PRD Section 12:

### Visual Acceptance Gates

- [ ] LoginView background is `.systemBackground` (no gradient)
- [ ] SignUpView uses standard form layout
- [ ] EmailSignInView is minimal modal
- [ ] All text uses iOS system fonts (`.largeTitle`, `.body`, etc.)
- [ ] All buttons use consistent ButtonStyles
- [ ] Spacing follows 8/16/24pt grid
- [ ] Dark Mode supported on all 3 screens

### Functional Acceptance Gates

- [ ] Tap "Continue with Email" → EmailSignInView opens
- [ ] Enter credentials → Sign in → Navigate to main app
- [ ] Tap "Sign up" → SignUpView opens
- [ ] Complete signup → Account created → Navigate to main app
- [ ] Tap "Forgot password?" → Reset email sent
- [ ] Empty fields → Button disabled
- [ ] Invalid email → Inline error shown
- [ ] Wrong credentials → Inline error shown (not alert)

### Performance Acceptance Gates

- [ ] Screen render < 100ms
- [ ] Button tap feedback < 50ms
- [ ] Smooth 60fps transitions
- [ ] Dark Mode instant

### Multi-Device Acceptance Gates

- [ ] iPhone SE layout works
- [ ] iPhone 15 Pro Max layout works
- [ ] Dark Mode correct on all devices

---

## 9. Documentation & PR

- [ ] Add inline code comments for ButtonStyles implementation
  - Explain PrimaryButtonStyle, SecondaryButtonStyle, DestructiveButtonStyle usage
- [ ] Add comments for any complex layout logic (if needed)
- [ ] No README changes needed (UI-only redesign)
- [ ] Create PR description (use format from Psst/agents/caleb-agent.md)
  - Include before/after screenshots of auth screens
  - Note: This establishes design system for PR #006B and #006C
  - List all visual changes (removed gradients, new buttons, etc.)
- [ ] Verify with user before creating PR
- [ ] Open PR targeting develop branch
- [ ] Link PRD and TODO in PR description

---

## Copyable Checklist (for PR description)

```markdown
## PR #006A: Authentication Redesign - Clean iOS Patterns

### Changes
- ✅ Removed gradient backgrounds from all auth screens
- ✅ Implemented iOS system colors (`.systemBackground`, `.label`, `.blue`)
- ✅ Created reusable ButtonStyles (Primary, Secondary, Destructive)
- ✅ Updated typography to iOS system text styles
- ✅ Standardized spacing to 8/16/24pt grid
- ✅ Added Dark Mode support (automatic via system colors)

### Files Modified
- `Views/Authentication/LoginView.swift` - Clean iOS design
- `Views/Authentication/SignUpView.swift` - Standard form layout
- `Views/Authentication/EmailSignInView.swift` - Minimal modal

### Files Created
- `Utilities/ButtonStyles.swift` - Reusable button styles

### Testing Completed
- [ ] Branch created from develop
- [ ] All TODO tasks completed
- [ ] All 3 auth screens redesigned
- [ ] ButtonStyles implemented and reusable
- [ ] Firebase Authentication verified (all flows work)
- [ ] Manual testing completed (all auth flows, edge cases, multi-device)
- [ ] Dark Mode verified on all screens
- [ ] Performance targets met (< 100ms render, < 50ms tap feedback)
- [ ] All acceptance gates pass (visual, functional, performance)
- [ ] Code follows Psst/agents/shared-standards.md patterns
- [ ] No console warnings or errors
- [ ] Zero regressions (all existing functionality works)

### Design System Foundation
This PR establishes:
- Color system: iOS system colors
- Typography system: iOS text styles
- Button styles: Reusable components
- Spacing grid: 8pt/16pt/24pt

These will be used in PR #006B and #006C for app-wide consistency.

### Links
- PRD: `Psst/docs/prds/pr-006a-prd.md`
- TODO: `Psst/docs/todos/pr-006a-todo.md`
- UX Spec: `Psst/docs/ux-specs/pr-006-ux-spec.md` (sections 1-2)
```

---

## Notes

- Break tasks into < 30 min chunks
- Complete tasks sequentially (Setup → ButtonStyles → LoginView → SignUpView → EmailSignInView → Testing)
- Check off after completion
- Document blockers immediately
- Reference `Psst/agents/shared-standards.md` for common patterns and solutions
- This is a UI-only change - no Firebase auth logic or service layer modifications needed
- Focus on visual consistency and iOS native patterns
- All existing authentication functionality must work identically
- ButtonStyles created here will be reused in PR #006B (Main App) and #006C (Settings)
- Dark Mode support is automatic via system colors - no custom code needed

