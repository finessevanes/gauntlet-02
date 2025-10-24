# PRD: App Launch Loading Screen & Skeleton

**Feature**: app-launch-loading-screen-and-skeleton

**Version**: 1.0

**Status**: Ready for Development

**Agent**: Caleb

**Target Release**: Phase 1 (MVP Polish)

**Links**: [PR Brief], [TODO], [Designs], [Tracking Issue]

---

## 1. Summary

Replace the jarring login screen flash with a smooth loading screen and skeleton UI that appears immediately on app launch while Firebase Authentication checks user status in the background, creating a professional, seamless user experience that matches modern app standards.

---

## 2. Problem & Goals

- **User Problem**: Users who were previously logged in see the login screen for a second before being redirected to the main app, creating a jarring and unprofessional user experience
- **Why Now**: This is a critical UX issue that affects every app launch and makes the app feel unpolished compared to modern messaging apps
- **Goals (ordered, measurable)**:
  - [ ] G1 — Eliminate login screen flash for authenticated users (0ms visible time)
  - [ ] G2 — Provide immediate visual feedback on app launch (<100ms loading screen appearance)
  - [ ] G3 — Smooth transition to main app without visual glitches

---

## 3. Non-Goals / Out of Scope

- [ ] Not implementing custom splash screen animations (keep simple and fast)
- [ ] Not adding app version checking or update prompts during loading
- [ ] Not implementing progressive loading of app features (skeleton UI only)

---

## 4. Success Metrics

Reference `Psst/agents/shared-standards.md` for metric templates:
- **User-visible**: Loading screen appears in <100ms, smooth transition to main app
- **System**: App load time < 2-3 seconds (cold start to interactive UI), no UI blocking on main thread
- **Quality**: 0 blocking bugs, all gates pass, crash-free >99%

---

## 5. Users & Stories

- As a returning user, I want to see a loading screen immediately when I open the app so that I don't see the jarring login screen flash
- As a new user, I want to see a professional loading experience so that the app feels polished and modern
- As a user on slow networks, I want to see skeleton UI that matches the main app layout so that I understand what's loading

---

## 6. Experience Specification (UX)

- **Entry points and flows**: App launch → Loading screen → Authentication check → Smooth transition to main app or login screen
- **Visual behavior**: 
  - Loading screen with app branding and skeleton UI components
  - Skeleton components that match main app layout (conversation list, navigation)
  - Smooth fade transition to main app
- **Loading/disabled/error states**: 
  - Loading: Skeleton UI with subtle animations
  - Error: Graceful fallback to login screen if auth fails
- **Performance**: See targets in `Psst/agents/shared-standards.md`

---

## 7. Functional Requirements (Must/Should)

- MUST: Loading screen appears immediately on app launch (<100ms)
- MUST: Firebase Authentication check happens in background without blocking UI
- MUST: Smooth transition to main app without showing login screen for authenticated users
- MUST: Skeleton UI components match main app layout structure
- SHOULD: Subtle loading animations for better perceived performance

Acceptance gates per requirement:
- [Gate] When user opens app → Loading screen appears in <100ms
- [Gate] When authenticated user opens app → No login screen flash, direct transition to main app
- [Gate] When unauthenticated user opens app → Smooth transition to login screen
- [Gate] When network is slow → Skeleton UI shows appropriate loading states

---

## 8. Data Model

No new Firestore collections or data model changes required. This feature only affects the app launch flow and UI presentation.

- **Validation rules**: No changes to Firebase security rules
- **Indexing/queries**: No new Firestore queries required

---

## 9. API / Service Contracts

No new service methods required. This feature modifies the existing authentication flow:

```swift
// Existing authentication service usage
func checkAuthenticationStatus() async -> Bool
func signInAnonymously() async throws
func signOut() async throws
```

- **Pre/post-conditions**: Authentication check runs in background during loading screen
- **Error handling strategy**: Graceful fallback to login screen if auth fails
- **Parameters and types**: No new parameters required
- **Return values**: No new return values required

---

## 10. UI Components to Create/Modify

- `Views/LoadingScreenView.swift` — Main loading screen with app branding and skeleton UI
- `Components/SkeletonConversationRow.swift` — Skeleton version of conversation list row
- `Components/SkeletonNavigationBar.swift` — Skeleton version of navigation bar
- `Views/RootView.swift` — Modified to show loading screen before auth check
- `PsstApp.swift` — Modified to handle loading screen presentation

---

## 11. Integration Points

- Firebase Authentication (existing)
- SwiftUI state management (@State, @StateObject)
- App lifecycle management
- No new Firebase services required

---

## 12. Testing Plan & Acceptance Gates

Define BEFORE implementation. Use checkboxes.

**Current**: Manual testing validation (see `Psst/agents/shared-standards.md`)  
**Future**: Automated testing recommendations in `Psst/docs/testing-strategy.md`

- Configuration Testing
  - [ ] Firebase Authentication setup works
  - [ ] App launches without crashes
  - [ ] Loading screen appears immediately
  
- Happy Path Testing
  - [ ] Authenticated user sees loading screen → main app transition
  - [ ] Gate: No login screen flash for authenticated users
  - [ ] Gate: Loading screen appears in <100ms
  
- Edge Cases Testing
  - [ ] Slow network shows skeleton UI appropriately
  - [ ] Authentication failure gracefully shows login screen
  - [ ] App backgrounding/foregrounding works correctly
  
- Multi-User Testing
  - [ ] Loading screen works consistently across different user states
  - [ ] No race conditions between auth check and UI updates
  
- Performance Testing (see shared-standards.md)
  - [ ] App load < 2-3s with loading screen
  - [ ] Smooth 60fps skeleton animations
  - [ ] No UI blocking during auth check

---

## 13. Definition of Done

See standards in `Psst/agents/shared-standards.md`:
- [ ] Loading screen implemented with skeleton UI
- [ ] SwiftUI views with all states (loading, error, success)
- [ ] Authentication flow modified to use loading screen
- [ ] Smooth transitions between loading and main app
- [ ] All acceptance gates pass
- [ ] Manual testing completed (configuration, user flows, performance)
- [ ] No console warnings or errors

---

## 14. Risks & Mitigations

- **Risk**: Loading screen adds perceived delay → **Mitigation**: Keep loading screen minimal, use skeleton UI to show progress
- **Risk**: Authentication check takes too long → **Mitigation**: Set reasonable timeout, show progress indicators
- **Risk**: Skeleton UI doesn't match actual layout → **Mitigation**: Use exact same components with loading state
- **Risk**: Race conditions between auth and UI → **Mitigation**: Proper state management with @StateObject

---

## 15. Rollout & Telemetry

- **Feature flag?** No (core UX improvement)
- **Metrics**: App launch time, loading screen duration, user satisfaction
- **Manual validation steps**: Test with authenticated/unauthenticated users, slow networks

---

## 16. Open Questions

- Q1: Should skeleton UI be interactive or completely static?
- Q2: What should happen if authentication check takes >5 seconds?

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future:
- [ ] Custom splash screen animations
- [ ] Progressive feature loading
- [ ] App update prompts during loading

---

## Preflight Questionnaire

Answer these to drive vertical slice and acceptance gates:

1. **Smallest end-to-end user outcome for this PR?** Smooth app launch without login screen flash
2. **Primary user and critical action?** Returning user opening app, seeing loading screen instead of login flash
3. **Must-have vs nice-to-have?** Must-have: No login screen flash. Nice-to-have: Skeleton UI animations
4. **Real-time requirements?** No real-time messaging requirements for this feature
5. **Performance constraints?** Loading screen must appear <100ms, app load <2-3s total
6. **Error/edge cases to handle?** Slow networks, authentication failures, app backgrounding
7. **Data model changes?** None required
8. **Service APIs required?** No new APIs, modify existing auth flow
9. **UI entry points and states?** App launch → Loading screen → Main app/Login screen
10. **Security/permissions implications?** None
11. **Dependencies or blocking integrations?** Depends on PR #2 (authentication flow), PR #4 (app navigation)
12. **Rollout strategy and metrics?** Immediate rollout, measure launch time and user satisfaction
13. **What is explicitly out of scope?** Custom animations, progressive loading, app updates

---

## Authoring Notes

- Write Test Plan before coding
- Favor vertical slice that ships standalone
- Keep service layer deterministic
- SwiftUI views are thin wrappers
- Test offline/online thoroughly
- Reference `Psst/agents/shared-standards.md` throughout
