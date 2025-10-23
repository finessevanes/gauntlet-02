# PR-007 TODO — App Launch Loading Screen & Skeleton

**Branch**: `feat/pr-007-app-launch-loading-screen-and-skeleton`  
**Source PRD**: `Psst/docs/prds/pr-007-prd.md`  
**Owner (Agent)**: Caleb

---

## 0. Clarifying Questions & Assumptions

- **Questions**: None - PRD is clear on requirements
- **Assumptions (confirm in PR if needed)**:
  - Loading screen should be simple and fast, not complex animations
  - Skeleton UI should match existing conversation list layout
  - Authentication check should happen in background without blocking UI

---

## 1. Setup

- [x] Create branch `feat/pr-007-app-launch-loading-screen-and-skeleton` from develop
- [x] Read PRD thoroughly
- [x] Read `Psst/agents/shared-standards.md` for patterns
- [x] Confirm environment and test runner work
- [x] Review existing authentication flow in `PsstApp.swift` and `RootView.swift`

---

## 2. Service Layer

No new service methods required. This feature modifies existing authentication flow.

- [x] Review existing `AuthenticationService.swift` methods
  - Test Gate: Understand current auth flow and timing
- [x] Identify where to inject loading screen in auth flow
  - Test Gate: Determine optimal timing for loading screen display

---

## 3. Data Model & Rules

No new data model changes required.

- [x] Confirm no Firestore schema changes needed
  - Test Gate: Existing auth flow continues to work
- [x] Verify Firebase security rules remain unchanged
  - Test Gate: Authentication still works with existing rules

---

## 4. UI Components

Create/modify SwiftUI views per PRD Section 10.

- [x] Create `Views/LoadingScreenView.swift`
  - Test Gate: SwiftUI Preview renders; zero console errors
  - Test Gate: Loading screen displays app branding and skeleton UI
- [x] Create `Components/SkeletonConversationRow.swift`
  - Test Gate: Skeleton row matches conversation list layout
  - Test Gate: Subtle loading animation works smoothly
- [x] Create `Components/SkeletonNavigationBar.swift`
  - Test Gate: Skeleton nav bar matches main app navigation
  - Test Gate: Renders without errors
- [x] Modify `Views/RootView.swift` to show loading screen first
  - Test Gate: Loading screen appears before auth check
  - Test Gate: Smooth transition to main app or login screen
- [x] Modify `PsstApp.swift` to handle loading screen presentation
  - Test Gate: App launch flow works correctly
  - Test Gate: No race conditions between loading and auth

---

## 5. Integration & Real-Time

Reference requirements from `Psst/agents/shared-standards.md`.

- [x] Integrate loading screen with existing authentication flow
  - Test Gate: Loading screen appears immediately on app launch
- [x] Ensure authentication check happens in background
  - Test Gate: No UI blocking during auth check
- [x] Implement smooth transitions between states
  - Test Gate: No visual glitches during transitions
- [x] Handle authentication success/failure states
  - Test Gate: Proper fallback to login screen if auth fails

---

## 6. Testing Validation

**Current**: Manual testing validation (see `Psst/agents/shared-standards.md`)  
**Future**: Automated testing recommendations in `Psst/docs/testing-strategy.md`

- [ ] Configuration Testing
  - Test Gate: Firebase Authentication, Firestore, FCM all connected and working
  - Test Gate: App launches without crashes
  - Test Gate: Loading screen appears immediately (<100ms)
  
- [ ] User Flow Testing
  - Test Gate: Authenticated user sees loading screen → main app transition
  - Test Gate: Unauthenticated user sees loading screen → login screen transition
  - Test Gate: No login screen flash for authenticated users
  
- [ ] Multi-Device Testing
  - Test Gate: Loading screen works consistently across different devices
  - Test Gate: No race conditions between auth check and UI updates
  
- [ ] Offline Behavior Testing
  - Test Gate: Loading screen appears even when offline
  - Test Gate: Graceful handling of authentication failures
  
- [ ] Visual States Verification
  - Test Gate: Loading screen renders correctly
  - Test Gate: Skeleton UI matches main app layout
  - Test Gate: Smooth transitions between loading and main app
  - Test Gate: No console errors during testing

---

## 7. Performance

Verify targets from `Psst/agents/shared-standards.md`.

- [ ] Loading screen appears in <100ms
  - Test Gate: Measured timing from app launch to loading screen display
- [ ] App load time < 2-3 seconds total
  - Test Gate: Cold start to interactive UI measured
- [ ] Smooth 60fps skeleton animations
  - Test Gate: Skeleton UI animations run smoothly
- [ ] No UI blocking during authentication
  - Test Gate: Main thread remains responsive during auth check

---

## 8. Acceptance Gates

Check every gate from PRD Section 12:
- [ ] Loading screen appears in <100ms
- [ ] No login screen flash for authenticated users
- [ ] Smooth transition to main app or login screen
- [ ] Skeleton UI shows appropriate loading states
- [ ] Authentication check happens in background
- [ ] No UI blocking during auth check
- [ ] Smooth 60fps skeleton animations
- [ ] App load time < 2-3s with loading screen

---

## 9. Documentation & PR

- [ ] Add inline code comments for complex logic
- [ ] Update README if needed
- [ ] Create PR description (use format from Psst/agents/caleb-agent.md)
- [ ] Verify with user before creating PR
- [ ] Open PR targeting develop branch
- [ ] Link PRD and TODO in PR description

---

## Copyable Checklist (for PR description)

```markdown
- [ ] Branch created from develop
- [ ] All TODO tasks completed
- [ ] Loading screen implemented with skeleton UI
- [ ] Authentication flow modified to use loading screen
- [ ] SwiftUI views implemented with state management
- [ ] Firebase integration verified (auth flow, loading states)
- [ ] Manual testing completed (configuration, user flows, performance)
- [ ] Loading screen appears in <100ms
- [ ] No login screen flash for authenticated users
- [ ] Performance targets met (see Psst/agents/shared-standards.md)
- [ ] All acceptance gates pass
- [ ] Code follows Psst/agents/shared-standards.md patterns
- [ ] No console warnings
- [ ] Documentation updated
```

---

## Notes

- Break tasks into <30 min chunks
- Complete tasks sequentially
- Check off after completion
- Document blockers immediately
- Reference `Psst/agents/shared-standards.md` for common patterns and solutions
- Focus on smooth transitions and eliminating login screen flash
- Skeleton UI should match existing app layout for consistency
