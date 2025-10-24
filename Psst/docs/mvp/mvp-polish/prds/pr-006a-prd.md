# PRD: Authentication Redesign - Clean iOS Patterns

**Feature**: Authentication UI Redesign

**Version**: 1.0

**Status**: Ready for Development

**Agent**: Pam (Planning Agent)

**Target Release**: Phase 1 - MVP Polish

**Links**: 
- PR Brief: `Psst/docs/pr-briefs.md` (PR #006A)
- TODO: `Psst/docs/todos/pr-006a-todo.md` (to be created)
- UX Spec: `Psst/docs/ux-specs/pr-006-ux-spec.md` (sections 1-2)
- Dependencies: PR #2 (authentication flow - completed)

---

## 1. Summary

Redesign all authentication screens (LoginView, SignUpView, EmailSignInView) to use clean, native iOS patterns instead of elaborate gradient backgrounds and weather-app styling. This creates a unified, trustworthy authentication experience that establishes the design system foundation for the entire app.

---

## 2. Problem & Goals

**Problem**: 
The current authentication screens use elaborate gradient backgrounds, decorative card containers with shadows, and colored icon circles that feel more like a weather app than a secure messaging app. This inconsistent styling creates a disconnect between the auth experience and the clean, simple main app interface. Users need to trust the app with their credentials, but the current "flashy" design undermines that trust.

**Why Now**: 
This is the foundation for a complete app-wide design system overhaul. Authentication is the first impression users get, and it needs to communicate simplicity, security, and trustworthiness (Signal vibes). All other design updates (PR #006B and #006C) will build on the patterns established here.

**Goals** (ordered, measurable):
- [ ] **G1** — Remove all gradient backgrounds and decorative styling from auth screens
- [ ] **G2** — Implement consistent iOS system colors and typography across all 3 auth screens
- [ ] **G3** — Create reusable button styles that will be used app-wide
- [ ] **G4** — Maintain all existing authentication functionality with zero regressions

---

## 3. Non-Goals / Out of Scope

To keep this PR focused on UI redesign only:

- [ ] **Not changing** authentication logic or Firebase integration (keep existing)
- [ ] **Not adding** new auth methods (OAuth, phone auth, biometrics)
- [ ] **Not implementing** password strength indicators or validation changes
- [ ] **Not adding** forgot password functionality improvements (use existing)
- [ ] **Not changing** navigation flow between auth screens
- [ ] **Not adding** animations beyond standard iOS transitions

---

## 4. Success Metrics

**User-visible**:
- Auth screens feel clean, simple, and trustworthy
- Visual consistency across all 3 auth screens (LoginView, SignUpView, EmailSignInView)
- Button tap feedback <50ms (iOS standard)

**System** (see `Psst/agents/shared-standards.md`):
- No performance degradation (screens load as fast or faster than before)
- Smooth 60fps animations for transitions
- No UI blocking during auth operations
- Dark Mode support (automatic with system colors)

**Quality**:
- 0 visual regressions in auth flow
- All existing auth functionality works identically
- All acceptance gates pass
- Clean UI on all device sizes (SE to Pro Max)

---

## 5. Users & Stories

**Primary Users**: New users signing up and existing users logging in

**User Stories**:

1. **As a new user**, I want the signup screen to feel clean and trustworthy so that I feel confident providing my email and password.

2. **As a returning user**, I want the login screen to be simple and familiar (standard iOS patterns) so that I can quickly access my account without distraction.

3. **As a privacy-conscious user**, I want the app to communicate security through clean, professional design (Signal aesthetic) so that I trust it with my messages.

4. **As an iOS user**, I want the auth screens to use familiar iOS patterns and Dark Mode support so that the experience feels native and comfortable.

---

## 6. Experience Specification (UX)

### Entry Points

**LoginView** (App Launch):
- First screen users see when not authenticated
- Entry to SignUpView via "Sign up" link
- Entry to EmailSignInView via "Continue with Email" button

**SignUpView**:
- Accessed from LoginView via "Sign up" link
- Entry to EmailSignInView for email/password signup

**EmailSignInView**:
- Modal sheet from LoginView or SignUpView
- Can be signin (login) or signup mode

### Visual Behavior

**LoginView - Simplified**:

**Before (Current)**:
- Gradient background (purple/pink/orange)
- Card container with shadow
- Colored icon circles
- Custom button styling

**After (New)**:
```
┌─────────────────────────┐
│                         │
│    [Simple Icon]        │  ← Logo/icon (40pt, monochrome)
│   Welcome Back          │  ← .largeTitle + .bold
│  Sign in to continue    │  ← .subheadline + .secondary
│                         │
│  [Continue with Email]  │  ← Blue button (.fill style)
│  [Continue with Google] │  ← Gray button (.bordered style)
│                         │
│   Don't have account?   │  ← .subheadline
│      Sign up            │  ← Blue link
└─────────────────────────┘
```

**Design Changes**:
- Background: Gradient → `.systemBackground` (white/dark)
- Remove: Card container, shadows, decorative elements
- Icon: Colored circle → Simple monochrome icon (40pt)
- Typography: `.largeTitle` for heading, `.subheadline` for subtitle
- Buttons: Custom styling → iOS `.buttonStyle` (`.bordered` and `.borderedProminent`)
- Spacing: Standard 8pt/16pt/24pt grid
- Padding: 24pt horizontal padding

**SignUpView - Standard Form**:

**Before (Current)**:
- Gradient background
- Card layout with decorative elements
- Custom text fields
- Mixed styling

**After (New)**:
```
┌─────────────────────────┐
│  ← Back    Sign Up      │  ← Standard nav bar
│                         │
│    Create Account       │  ← .title2 + .semibold
│                         │
│  Full Name              │  ← .caption (label)
│  [             ]        │  ← Standard TextField
│                         │
│  Email                  │
│  [             ]        │
│                         │
│  Password               │
│  [             ]        │
│                         │
│  [   Sign Up   ]        │  ← Blue button (.fill)
│                         │
│  Already have account?  │
│      Log in             │  ← Blue link
└─────────────────────────┘
```

**Design Changes**:
- Background: Gradient → `.systemBackground`
- Navigation: Standard iOS nav bar (large title off)
- Text Fields: Standard iOS `TextField` with `.textFieldStyle(.roundedBorder)`
- Form layout: Use `Form` or `VStack` with proper spacing
- Button: Matches LoginView button style
- Remove all decorative elements

**EmailSignInView - Minimal Modal**:

**Before (Current)**:
- Gradient background
- Card layout
- Decorative elements
- Custom styling

**After (New)**:
```
┌─────────────────────────┐
│  Email Sign In      [X] │  ← Sheet header
│                         │
│  Email                  │
│  [             ]        │
│                         │
│  Password               │
│  [             ]        │
│                         │
│  Forgot password?       │  ← Link (right-aligned)
│                         │
│  [   Continue   ]       │  ← Blue button
└─────────────────────────┘
```

**Design Changes**:
- Background: Gradient → `.systemBackground`
- Presentation: Keep `.sheet` modal style
- Layout: Minimal, focused form
- Text Fields: Standard iOS TextField
- Button: Consistent blue button style
- Remove all decorative elements

### Loading/Disabled/Error States

**Loading State**:
- Button shows `ProgressView()` inside
- Button disabled with reduced opacity
- Text changes to "Signing in..." or "Creating account..."

**Disabled State**:
- Empty fields → button disabled (gray, reduced opacity)
- Invalid email format → button disabled

**Error State**:
- Red error message below form (not alert)
- `.foregroundColor(.red)` + `.caption` font
- Form remains accessible for correction
- Error clears when user edits field

### Performance Targets

See `Psst/agents/shared-standards.md` for general targets. Specific to this feature:

- **Screen render**: <100ms to display auth screens
- **Tap feedback**: <50ms button press animation
- **Dark Mode**: Automatic support via system colors
- **Smooth transitions**: 60fps between auth screens

---

## 7. Functional Requirements (Must/Should)

### Must-Have Requirements

**R1**: LoginView MUST use `.systemBackground` instead of gradient
- **Acceptance Gate**: LoginView background is white (light mode) / black (dark mode) with no gradient

**R2**: All auth screens MUST use iOS system colors for text and buttons
- **Acceptance Gate**: Text uses `.label`, `.secondaryLabel`; buttons use `.blue` for primary actions

**R3**: Button styles MUST be consistent across all 3 auth screens
- **Acceptance Gate**: Primary buttons use blue `.borderedProminent`, secondary use `.bordered`

**R4**: All auth screens MUST use standard iOS typography hierarchy
- **Acceptance Gate**: Headings use `.largeTitle` or `.title2`, body uses `.body`, captions use `.caption`

**R5**: Text fields MUST use standard iOS TextField styling
- **Acceptance Gate**: TextFields use `.textFieldStyle(.roundedBorder)` or Form-based styling

**R6**: All existing authentication functionality MUST continue to work
- **Acceptance Gate**: Email signin, Google signin, signup, forgot password all function identically to current

**R7**: Dark Mode MUST be supported automatically
- **Acceptance Gate**: All auth screens adapt to dark mode via system colors without custom code

**R8**: All auth screens MUST use standard 8pt/16pt/24pt spacing grid
- **Acceptance Gate**: Spacing between elements follows consistent grid

### Should-Have Requirements

**R9**: Buttons SHOULD provide immediate visual feedback on tap
- **Acceptance Gate**: Button scale animation or opacity change <50ms on tap

**R10**: Error messages SHOULD be inline (not alerts) for better UX
- **Acceptance Gate**: Invalid credentials show error text below form, not in alert dialog

**R11**: Loading states SHOULD be clear and non-blocking
- **Acceptance Gate**: Signing in shows progress indicator inside button, button disabled but visible

---

## 8. Data Model

**No data model changes required.** This is a pure UI redesign using existing authentication services.

**Existing Services Used**:
- `AuthenticationService` - handles Firebase auth (no changes)
- `AuthViewModel` - manages auth state (may need minor UI state additions)

---

## 9. API / Service Contracts

**No new service methods required.** This PR only changes the UI layer.

**Existing Methods Used**:

```swift
// From AuthenticationService (no changes)
func signIn(email: String, password: String) async throws
func signUp(email: String, password: String, displayName: String) async throws
func signInWithGoogle() async throws
func sendPasswordReset(email: String) async throws
func signOut() throws
```

**ViewModel Updates** (minor):

```swift
// AuthViewModel - may add for inline error handling
@Published var errorMessage: String? = nil  // For inline errors instead of alerts
@Published var isLoading: Bool = false      // For button loading state
```

---

## 10. UI Components to Create/Modify

### Files to Modify

**Authentication Views** (3 files):
- `Views/Authentication/LoginView.swift` — Remove gradient, implement clean iOS design
- `Views/Authentication/SignUpView.swift` — Remove gradient, standard form layout
- `Views/Authentication/EmailSignInView.swift` — Remove gradient, minimal modal style

**Utilities** (1 file - create new):
- `Utilities/ButtonStyles.swift` — Create reusable button styles for entire app

### Components Breakdown

**LoginView.swift**:
- Remove gradient background → `.systemBackground`
- Remove card container and shadows
- Simplify icon presentation (monochrome, 40pt)
- Update typography (`.largeTitle`, `.subheadline`)
- Apply new button styles (`.borderedProminent` for primary)
- Update spacing to 24pt padding, 16pt between elements

**SignUpView.swift**:
- Remove gradient background → `.systemBackground`
- Add standard navigation bar
- Convert to Form or VStack with standard TextFields
- Apply new button styles
- Update typography
- Improve spacing and layout

**EmailSignInView.swift**:
- Remove gradient background → `.systemBackground`
- Simplify modal layout (minimal)
- Standard TextFields
- Apply button styles
- Keep sheet presentation

**ButtonStyles.swift** (new file):
```swift
// Reusable button styles for app-wide consistency
struct PrimaryButtonStyle: ButtonStyle { ... }  // Blue, prominent
struct SecondaryButtonStyle: ButtonStyle { ... } // Gray, bordered
struct DestructiveButtonStyle: ButtonStyle { ... } // Red (for logout, etc.)
```

---

## 11. Integration Points

### Existing Integrations (No Changes)
- **Firebase Authentication**: Keep existing email/Google signin
- **AuthViewModel**: Existing state management (minor UI state additions only)
- **Navigation**: Existing NavigationStack/sheet presentations

### Design System Foundation
This PR establishes:
- **Color system**: iOS system colors (`.blue`, `.label`, `.systemBackground`)
- **Typography system**: iOS text styles (`.largeTitle`, `.body`, `.caption`)
- **Button styles**: Reusable `ButtonStyle` components
- **Spacing grid**: 8pt/16pt/24pt system

These will be used in PR #006B and #006C for consistency.

---

## 12. Testing Plan & Acceptance Gates

### Configuration Testing
- [ ] Firebase Authentication still works after UI changes
- [ ] Google Sign-In configured and functional
- [ ] Email sign-in and signup flows work
- [ ] Password reset flow works

### Visual Testing
- [ ] LoginView renders with clean design (no gradient)
- [ ] SignUpView renders with standard form layout
- [ ] EmailSignInView renders as minimal modal
- [ ] All text uses iOS system fonts
- [ ] All buttons use consistent styles
- [ ] Spacing follows 8/16/24pt grid
- [ ] Dark Mode renders correctly on all 3 screens

### Happy Path Testing
- [ ] Gate: User can tap "Continue with Email" → EmailSignInView opens as sheet
- [ ] Gate: User can enter email/password → Sign in successful → Navigate to main app
- [ ] Gate: User can tap "Sign up" → SignUpView opens
- [ ] Gate: User can complete signup form → Account created → Navigate to main app
- [ ] Gate: User can tap "Forgot password?" → Password reset email sent

### Edge Cases Testing
- [ ] Empty email/password → Button disabled
- [ ] Invalid email format → Show inline error
- [ ] Wrong credentials → Show inline error (not alert)
- [ ] Network error → Show clear error message
- [ ] Multiple rapid taps on button → Prevent duplicate requests

### Multi-Device Testing
- [ ] iPhone SE (small screen) → Layout works
- [ ] iPhone 15 Pro Max (large screen) → Layout works
- [ ] iPad (if supported) → Layout works
- [ ] Landscape orientation → Layout adapts

### Performance Testing
- [ ] LoginView loads in <100ms
- [ ] Button tap feedback <50ms
- [ ] Smooth 60fps transitions between auth screens
- [ ] Dark Mode toggles instantly

### Regression Testing
- [ ] All existing auth flows work identically (no broken functionality)
- [ ] Email signin success → Navigates to main app
- [ ] Google signin success → Navigates to main app
- [ ] Signup success → Creates account and navigates
- [ ] Logout → Returns to LoginView

---

## 13. Definition of Done

- [ ] All 3 auth screens redesigned (LoginView, SignUpView, EmailSignInView)
- [ ] Gradients removed, system backgrounds used
- [ ] Consistent button styles created and applied
- [ ] Typography follows iOS system text styles
- [ ] Spacing follows 8/16/24pt grid
- [ ] Dark Mode supported automatically
- [ ] All existing auth functionality works (0 regressions)
- [ ] Manual testing completed (all gates pass)
- [ ] Code review completed
- [ ] Design reviewed and approved (matches UX spec)

---

## 14. Risks & Mitigations

**Risk**: Button style changes break existing functionality
- **Mitigation**: Test all auth flows thoroughly; button styles are visual only, don't change logic

**Risk**: Text field styling changes affect input behavior
- **Mitigation**: Use standard iOS TextField with minimal customization; test all input cases

**Risk**: Dark Mode reveals hardcoded colors causing contrast issues
- **Mitigation**: Use system colors exclusively (`.label`, `.systemBackground`, etc.)

**Risk**: Layout breaks on small devices (iPhone SE)
- **Mitigation**: Test on SE simulator; use ScrollView for long forms; ensure 24pt padding

**Risk**: Users dislike new design (too plain)
- **Mitigation**: This is intentional (Signal aesthetic); cleaner = more trustworthy for messaging

---

## 15. Rollout & Telemetry

**Feature Flag**: No

**Rollout Strategy**: 
- This is a visual redesign with no functionality changes
- Deploy as part of PR #006A
- No gradual rollout needed

**Manual Validation**:
- Test all auth flows on physical device
- Verify Dark Mode on device
- Screenshot before/after for documentation

**Success Indicators**:
- 0 auth-related bug reports after deployment
- Clean, consistent visual experience
- Foundation set for PR #006B and #006C

---

## 16. Open Questions

**Q1**: Should we keep the Google Sign-In button or remove it (not implemented yet)?
- **Answer**: Keep the button in UI for future implementation, but it can remain non-functional for now

**Q2**: Should error messages be inline or alerts?
- **Answer**: Inline (better UX, matches modern patterns)

**Q3**: What icon/logo to use on LoginView?
- **Answer**: Simple "Psst" text or SF Symbol (message bubble), monochrome

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future:
- [ ] Password strength indicator (Phase 2)
- [ ] Biometric authentication (Face ID/Touch ID) (Phase 2)
- [ ] Phone number authentication (Phase 3)
- [ ] Remember me / auto-fill support (Phase 2)
- [ ] Loading skeleton UI (defer to PR #007)
- [ ] Onboarding flow after signup (Phase 2)

---

## Preflight Questionnaire

1. **Smallest end-to-end user outcome for this PR?**
   - User sees clean, trustworthy auth screens using iOS native patterns

2. **Primary user and critical action?**
   - New/returning users signing in or creating account

3. **Must-have vs nice-to-have?**
   - Must: Remove gradients, use system colors, consistent buttons
   - Nice: Inline errors, sophisticated loading states

4. **Real-time requirements?**
   - None (auth is request/response, not real-time)

5. **Performance constraints?**
   - Screen render <100ms, button feedback <50ms (standard iOS)

6. **Error/edge cases to handle?**
   - Empty fields, invalid email, wrong credentials, network errors

7. **Data model changes?**
   - None (UI only)

8. **Service APIs required?**
   - None (uses existing AuthenticationService)

9. **UI entry points and states?**
   - Entry: App launch (LoginView) → SignUpView → EmailSignInView
   - States: Default, loading, error

10. **Security/permissions implications?**
    - None (using existing Firebase auth)

11. **Dependencies or blocking integrations?**
    - Depends on: PR #2 (auth flow - completed)
    - Blocks: PR #006B (needs design system established)

12. **Rollout strategy and metrics?**
    - Deploy directly, no gradual rollout
    - Success: 0 auth regressions, visual consistency achieved

13. **What is explicitly out of scope?**
    - New auth methods, validation changes, animations, functionality changes

---

**End of PRD**

