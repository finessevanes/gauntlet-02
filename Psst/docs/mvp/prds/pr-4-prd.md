# PRD: App Navigation Structure

**Feature**: Core SwiftUI Navigation Framework

**Version**: 1.0

**Status**: Draft

**Agent**: Pam

**Target Release**: Phase 1 - Core Foundation

**Links**: [PR Brief #4](../pr-briefs.md#pr-4-app-navigation-structure) | TODO (pending) | [Architecture](../architecture.md)

---

## 1. Summary

Build the core navigation infrastructure for the Psst messaging app using SwiftUI, enabling seamless transitions between authentication and authenticated states with a tab-based main interface. This establishes the foundational navigation patterns that all future features will build upon.

**Testing Strategy for This PR:**
- **Manual testing only** - This PR will be validated entirely through comprehensive manual testing scenarios
- **No unit/integration tests** - Automated testing is deferred to a future testing-focused PR (see Section 17: Backlog)
- **User-focused validation** - Section 12 provides explicit step-by-step testing instructions to confirm all features work correctly

---

## 2. Problem & Goals

**Problem:** Without a proper navigation structure, users cannot move between screens, and the app cannot distinguish between authenticated and unauthenticated states. The app needs a clear navigation hierarchy that supports both initial authentication flows and the main app experience.

**Why Now:** This is a Phase 1 foundational requirement. All subsequent features (conversation list, chat view, profile management) depend on this navigation structure being in place.

**Goals:**
- [ ] G1 — Create a navigation framework that automatically shows authentication screens when logged out and main app screens when logged in
- [ ] G2 — Implement tab-based navigation for the main app with placeholder screens ready for Phase 2 implementation
- [ ] G3 — Ensure proper SwiftUI view lifecycle management with no memory leaks or navigation stack issues

---

## 3. Non-Goals / Out of Scope

- [ ] Not implementing full functionality in placeholder screens (ConversationList, Profile, Settings) — these will be built in later PRs
- [ ] Not implementing deep linking to specific screens — deferred to Phase 4
- [ ] Not implementing custom tab bar styling or animations — using native SwiftUI TabView
- [ ] Not implementing navigation transitions/animations — using SwiftUI defaults
- [ ] Not implementing settings screen functionality — only the placeholder view

---

## 4. Success Metrics

**User-visible:**
- Screen transitions complete in < 200ms
- Zero navigation bugs (stuck screens, back button issues)
- 100% of users can navigate to all placeholder screens

**System:**
- App load time < 2-3 seconds (per shared-standards.md)
- Navigation state changes reflect immediately (< 50ms)
- Memory usage stable (no leaks from navigation stack)

**Quality:**
- 0 blocking navigation bugs
- All acceptance gates pass
- Crash-free rate >99%

---

## 5. Users & Stories

- As a **new user**, I want to see login/signup screens when I open the app so that I can create an account or log in.
- As an **authenticated user**, I want to see the main app interface (conversation list) immediately after login so that I can start using the app.
- As an **authenticated user**, I want to access different sections via tabs (Conversations, Profile, Settings) so that I can navigate the app efficiently.
- As a **logged-in user**, I want to log out and return to the authentication screen so that I can secure my account.
- As a **developer**, I want clear placeholder screens so that I know where to implement future features.

---

## 6. Experience Specification (UX)

### Entry Points & Flows

**Flow 1: First Launch (Unauthenticated)**
1. App launches → Shows LoginView
2. User can navigate to SignUpView via "Sign Up" button
3. User can navigate to ForgotPasswordView via "Forgot Password?" link
4. After successful authentication → Automatically navigates to MainTabView

**Flow 2: Returning User (Authenticated)**
1. App launches → Shows MainTabView directly
2. User sees 3 tabs: Conversations, Profile, Settings
3. User can tap any tab to navigate
4. User can log out from Settings → Returns to LoginView

### Visual Behavior

**Authentication Screens:**
- LoginView, SignUpView, ForgotPasswordView (already exist from PR #2)
- Navigation between auth screens uses NavigationStack/NavigationLink
- Standard iOS back button behavior

**Main App (MainTabView):**
- TabView with 3 tabs at bottom
- Tab 1: "Conversations" (icon: message bubble) → ConversationListView
- Tab 2: "Profile" (icon: person) → ProfileView
- Tab 3: "Settings" (icon: gear) → SettingsView
- Selected tab highlighted with accent color
- Tab bar always visible (no hiding on scroll)

**Placeholder Screen Layout:**
- Each placeholder shows:
  - Large title with screen name
  - Subtitle: "Coming Soon in Phase 2/3/4"
  - Icon representing the feature
  - Simple centered text layout

### Loading/Error States

- **Loading:** Brief loading indicator during auth state check (< 500ms)
- **Error:** If auth state cannot be determined, default to showing login screen
- **Empty State:** Placeholder screens show "Coming Soon" message

### Performance Targets

- Screen transitions: < 200ms
- Auth state check: < 500ms
- Tab switching: < 50ms (instant)
- Memory usage: Stable (no leaks)

---

## 7. Functional Requirements (Must/Should)

### MUST

- **MUST-1:** Implement RootView that observes authentication state and conditionally displays LoginView or MainTabView
  - [Gate] When user is logged out → LoginView displays
  - [Gate] When user logs in → MainTabView displays automatically
  - [Gate] When user logs out → Returns to LoginView

- **MUST-2:** Create MainTabView with TabView containing 3 tabs
  - [Gate] All 3 tabs render and are tappable
  - [Gate] Tab selection state persists when switching between tabs
  - [Gate] Tab bar icons and labels display correctly

- **MUST-3:** Create ConversationListView placeholder
  - [Gate] View renders with title "Conversations"
  - [Gate] Shows "Coming Soon" placeholder message
  - [Gate] Accessible from first tab

- **MUST-4:** Create ProfileView placeholder
  - [Gate] View renders with title "Profile"
  - [Gate] Shows "Coming Soon" placeholder message
  - [Gate] Accessible from second tab

- **MUST-5:** Create SettingsView placeholder with logout functionality
  - [Gate] View renders with title "Settings"
  - [Gate] Contains logout button
  - [Gate] Tapping logout calls AuthViewModel.logout()
  - [Gate] After logout, returns to LoginView

- **MUST-6:** Proper view lifecycle management
  - [Gate] No memory leaks when navigating between screens
  - [Gate] Views properly deallocate when no longer visible
  - [Gate] Tab state persists across app sessions (optional enhancement)

### SHOULD

- **SHOULD-1:** Add basic tab bar icons using SF Symbols
- **SHOULD-2:** Use SwiftUI's NavigationStack (iOS 16+) or NavigationView for auth flows
- **SHOULD-3:** Add smooth transitions between auth and main app states

---

## 8. Data Model

**No new Firestore collections.** This PR focuses on navigation structure only.

**SwiftUI State Management:**

```swift
// RootView observes AuthViewModel
@StateObject var authViewModel = AuthViewModel()

// AuthViewModel (from PR #2) provides:
var isAuthenticated: Bool  // Computed property or @Published

// MainTabView manages tab selection
@State private var selectedTab: Int = 0
```

**Navigation State:**
- Authentication state drives root-level view (LoginView vs MainTabView)
- Tab selection state managed locally in MainTabView
- No persistent storage needed for tab selection in Phase 1

---

## 9. API / Service Contracts

**No new service methods required.** This PR uses existing AuthViewModel from PR #2.

**Required from PR #2 (AuthViewModel):**

```swift
// Must be implemented in PR #2
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool
    func logout() async throws
}
```

**Usage in Navigation:**

```swift
// In RootView
@StateObject private var authViewModel = AuthViewModel()

var body: some View {
    if authViewModel.isAuthenticated {
        MainTabView()
            .environmentObject(authViewModel)
    } else {
        LoginView()
            .environmentObject(authViewModel)
    }
}
```

---

## 10. UI Components to Create/Modify

### New Files to Create

- `Views/RootView.swift` — Root navigation controller that switches between auth and main app
- `Views/MainTabView.swift` — Tab bar navigation with 3 tabs
- `Views/ConversationList/ConversationListView.swift` — Placeholder for chat list
- `Views/Profile/ProfileView.swift` — Placeholder for user profile
- `Views/Settings/SettingsView.swift` — Settings screen with logout button

### Files to Modify

- `PsstApp.swift` — Update to use RootView as the root view instead of ContentView
- `ContentView.swift` — Can be deleted or repurposed (currently unused boilerplate)

### Folder Structure

```
Psst/Psst/Views/
├── Authentication/          # Already exists from PR #2
│   ├── LoginView.swift
│   ├── SignUpView.swift
│   └── ForgotPasswordView.swift
├── RootView.swift           # NEW: Root navigation
├── MainTabView.swift        # NEW: Tab navigation
├── ConversationList/        # NEW: Folder
│   └── ConversationListView.swift
├── Profile/                 # NEW: Folder
│   └── ProfileView.swift
└── Settings/                # NEW: Folder
    └── SettingsView.swift
```

---

## 11. Integration Points

- **Firebase Authentication:** Uses AuthViewModel from PR #2 to check authentication state
- **SwiftUI State Management:** Uses `@StateObject`, `@EnvironmentObject`, `@Published`
- **Navigation APIs:** SwiftUI NavigationStack (iOS 16+) or NavigationView (iOS 13-15)
- **TabView:** SwiftUI's native TabView component

---

## 12. Test Plan & Acceptance Gates

### Testing Strategy

**This PR uses manual testing only.** Unit and integration tests are intentionally deferred to a future testing-focused PR.

**Why Manual Testing is Sufficient:**
- This PR establishes foundational navigation structure that needs to be experienced by a human to validate user experience
- Navigation flows are visual and interactive, making manual testing more effective than automated tests at this stage
- Automated tests will be added later once the navigation patterns stabilize and more features are built on top of this foundation
- All automated tests are documented in Section 17: Backlog for future implementation

**How to Use This Section:**

The test scenarios below provide **step-by-step instructions** for validating that this PR is complete and working correctly. Treat this as your testing checklist:

1. **Check each checkbox** as you complete each test scenario
2. **Follow the exact steps** described in each test
3. **Verify all expected outcomes** match what you see in the app
4. **Document any failures** immediately if something doesn't work as expected
5. **Do not approve this PR** until all tests pass

---

### Manual Test Scenarios

Complete all scenarios below to confirm the PR is ready for merge:

### Happy Path Testing

- [ ] **HP-1: First Launch (Logged Out State)**
  - **Test:** Delete app or log out, then launch the app
  - **Expected:** LoginView displays immediately with no delay
  - **Confirms:** RootView correctly shows LoginView when unauthenticated

- [ ] **HP-2: Login Flow**
  - **Test:** From LoginView, enter valid credentials and tap "Log In"
  - **Expected:**
    - MainTabView appears smoothly (< 200ms transition)
    - First tab "Conversations" is selected by default
    - ConversationListView displays with "Coming Soon in Phase 2" message
  - **Confirms:** RootView switches to MainTabView on authentication

- [ ] **HP-3: Tab Navigation**
  - **Test:** Tap each tab in order: Profile → Settings → Conversations
  - **Expected:**
    - Profile tab → Shows ProfileView with "Coming Soon in Phase 3"
    - Settings tab → Shows SettingsView with "Coming Soon in Phase 4"
    - Conversations tab → Shows ConversationListView with "Coming Soon in Phase 2"
    - Each transition feels instant (< 50ms)
    - Tab bar highlights the selected tab correctly
  - **Confirms:** All 3 tabs work and placeholder views display correctly

- [ ] **HP-4: Logout Flow**
  - **Test:** Navigate to Settings tab and tap "Log Out" button
  - **Expected:**
    - LoginView appears immediately
    - MainTabView is no longer visible
    - No console errors appear
  - **Confirms:** Logout functionality works and returns to LoginView

### Edge Case Testing

- [ ] **EC-1: Rapid Tab Switching**
  - **Test:** Rapidly tap between tabs 15-20 times in quick succession
  - **Expected:**
    - No crashes occur
    - No UI glitches or blank screens
    - All tabs continue to render correctly
    - Tab selection remains accurate
  - **Confirms:** Tab navigation is robust under stress

- [ ] **EC-2: App Backgrounding & Resume**
  - **Test:**
    1. Select the Settings tab
    2. Press home button to background the app
    3. Wait 5 seconds
    4. Resume the app from app switcher
  - **Expected:**
    - App still shows Settings tab (state preserved)
    - No crashes or navigation resets
  - **Confirms:** Navigation state persists across app lifecycle

- [ ] **EC-3: Multiple Login/Logout Cycles**
  - **Test:** Perform this cycle 3 times in a row:
    - Log in → Navigate to Settings → Log out → Log in again
  - **Expected:**
    - Each cycle works smoothly
    - No memory warnings in console
    - No performance degradation
  - **Confirms:** No memory leaks from repeated navigation

### Performance Verification

- [ ] **PERF-1: App Cold Start Time**
  - **Test:** Force quit app, then launch from home screen
  - **Expected:** From tap to interactive LoginView < 2-3 seconds
  - **Tool:** Manual stopwatch or Xcode Time Profiler
  - **Confirms:** Meets performance standard from shared-standards.md

- [ ] **PERF-2: Tab Switch Responsiveness**
  - **Test:** Tap any tab and observe transition
  - **Expected:** Tab content appears instantly (< 50ms, feels immediate)
  - **Tool:** Visual observation (should feel instant)
  - **Confirms:** Tab navigation is performant

- [ ] **PERF-3: Auth State Transition Speed**
  - **Test:**
    - Measure login → MainTabView appearance
    - Measure logout → LoginView appearance
  - **Expected:** Both transitions < 200ms (smooth, no lag)
  - **Tool:** Visual observation (should feel smooth)
  - **Confirms:** Authentication state changes are responsive

- [ ] **PERF-4: Memory Stability**
  - **Test:**
    - Navigate through all screens 5-10 times
    - Check Xcode Memory Debug Gauge during navigation
    - Optionally run Instruments Leaks tool
  - **Expected:**
    - Memory usage remains stable (no continuous growth)
    - No memory leak warnings
  - **Confirms:** Views properly deallocate when not visible

### Console & Error Verification

- [ ] **No Console Warnings/Errors**
  - **Test:** Perform all happy path tests while monitoring Xcode console
  - **Expected:**
    - No SwiftUI warnings about state management
    - No "broken constraints" warnings
    - No Firebase or authentication errors during navigation
  - **Confirms:** Implementation is clean and follows SwiftUI best practices

---

### Testing Completion Checklist

Before marking this PR as complete, verify **ALL** of the following:

- [ ] All 4 Happy Path tests passed (HP-1, HP-2, HP-3, HP-4)
- [ ] All 3 Edge Case tests passed (EC-1, EC-2, EC-3)
- [ ] All 4 Performance tests passed (PERF-1, PERF-2, PERF-3, PERF-4)
- [ ] Console verification passed (no warnings or errors)
- [ ] All checkboxes above are marked complete
- [ ] Zero crashes occurred during testing
- [ ] Zero UI glitches or bugs observed
- [ ] Navigation feels smooth and responsive

**If any test fails:** Document the issue, fix it, and re-run all tests before proceeding.

**Note:** Unit and integration tests will be implemented in a future PR (see Section 17: Backlog for planned automated tests).

---

## 13. Definition of Done

See standards in `Psst/agents/shared-standards.md`:

- [ ] RootView implemented and set as app root in PsstApp.swift
- [ ] MainTabView implemented with 3 working tabs
- [ ] All 3 placeholder screens created (ConversationList, Profile, Settings)
- [ ] Settings screen has working logout button
- [ ] Navigation flows work: Login → Main App → Logout → Login
- [ ] All manual tests pass (HP-1 through HP-4, EC-1 through EC-3, PERF-1 through PERF-4)
- [ ] All acceptance gates verified through manual testing (see Section 12)
- [ ] No memory leaks (verified with Xcode Memory Debugger or manual observation)
- [ ] Performance targets met: app load < 2-3s, tab switch < 50ms, auth transitions < 200ms
- [ ] Code follows shared-standards.md patterns
- [ ] No console warnings or errors during any test scenario
- [ ] Documentation updated (inline comments for navigation logic)

---

## 14. Risks & Mitigations

**Risk 1: Auth state observation not triggering navigation updates**
- Mitigation: Ensure AuthViewModel properly publishes `isAuthenticated` changes using `@Published`

**Risk 2: Tab state not persisting across app sessions**
- Mitigation: Phase 1 can skip tab state persistence; add in Phase 2 if needed using UserDefaults or AppStorage

**Risk 3: Memory leaks from improper EnvironmentObject usage**
- Mitigation: Test with Instruments Leaks tool; ensure proper lifecycle management

**Risk 4: Navigation stack confusion when switching between auth and main states**
- Mitigation: Use RootView as single source of truth; clear navigation state on logout

---

## 15. Rollout & Telemetry

**Feature Flag:** No

**Metrics to Track:**
- Navigation success rate (login → main app)
- Tab switch frequency
- Logout success rate
- Crash rate related to navigation

**Manual Validation Steps:**
1. Launch app while logged out → Verify LoginView shows
2. Log in → Verify MainTabView shows
3. Switch between all 3 tabs → Verify each placeholder shows
4. Log out → Verify returns to LoginView
5. Repeat 3 times to check for memory leaks

---

## 16. Open Questions

- **Q1:** Should we set minimum iOS version to 16+ to use NavigationStack, or support iOS 13+ with NavigationView?
  - **Decision:** The app min iOS is 16.6

- **Q2:** Should tab selection persist across app sessions?
  - **Decision:** Not required for Phase 1; can add later if user research shows value

- **Q3:** Should we add a splash screen or loading indicator while checking auth state?
  - **Decision:** Only if auth check takes > 500ms; otherwise direct display is fine

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future PRs:

### Functionality Deferred
- [ ] Custom tab bar styling and animations (Phase 4 - UI Polish)
- [ ] Deep linking to specific screens (Phase 4 - Notifications)
- [ ] Navigation history/back stack management (if needed in Phase 2+)
- [ ] Tab state persistence using AppStorage (Phase 2 if needed)
- [ ] Custom navigation transitions (Phase 4 - UI Polish)
- [ ] Accessibility improvements for navigation (Phase 4 - Accessibility PR)

### Testing Deferred

**Unit and Integration Tests** - Intentionally deferred to future testing PR (likely Phase 4 or dedicated testing sprint):

#### Deferred Unit Tests

- [ ] **RootView Auth State Tests**
  - Test RootView displays LoginView when `isAuthenticated = false`
  - Test RootView displays MainTabView when `isAuthenticated = true`
  - Test navigation updates when auth state changes dynamically
  - Mock AuthViewModel to verify conditional rendering logic

- [ ] **MainTabView State Tests**
  - Test tab selection state changes correctly
  - Test all 3 tabs are properly configured
  - Test tab state persistence (if implemented)
  - Verify TabView initialization and lifecycle

- [ ] **Placeholder View Tests**
  - Test each placeholder view renders correctly
  - Verify SF Symbols and text display
  - Test logout button functionality in SettingsView

#### Deferred Integration Tests

- [ ] **End-to-End Navigation Flow Tests**
  - Test complete login → main app → logout → login cycle
  - Test tab navigation with actual FirebaseAuth integration
  - Test navigation state persistence across app lifecycle
  - Test memory management across multiple navigation cycles

- [ ] **UI Tests (SwiftUI Testing)**
  - Automated UI testing of navigation flows
  - Accessibility testing for navigation components
  - Screenshot testing for visual regression

#### When Tests Will Be Added

**Planned Timeline:**
- **Phase 2-3:** Continue with manual testing as features are built
- **Phase 4 or Testing Sprint:** Implement comprehensive automated test suite
- Tests will be added once:
  - Navigation patterns are stable and proven
  - More features are built on top of this foundation
  - Testing infrastructure is established (mocks, fixtures, etc.)

**Rationale for Deferral:**
- **Focus on Feature Delivery:** This PR prioritizes getting working navigation in place
- **Better Test Coverage Later:** Automated tests are more valuable once the full navigation system is in use
- **Manual Testing is Sufficient:** For foundational UI work, human validation ensures good UX
- **Avoid Rework:** Writing tests now might require rework as navigation patterns evolve in Phase 2-3

---

## Preflight Questionnaire

1. **Smallest end-to-end user outcome for this PR?**
   - User can navigate from login screen to main app tabs and back to login via logout.

2. **Primary user and critical action?**
   - All users; critical actions: viewing main app after login, logging out.

3. **Must-have vs nice-to-have?**
   - Must-have: RootView, MainTabView, 3 placeholder screens, logout functionality.
   - Nice-to-have: Tab state persistence, custom tab styling.

4. **Real-time requirements?**
   - Auth state changes must trigger navigation updates immediately (< 50ms).

5. **Performance constraints?**
   - Tab switching < 50ms, screen transitions < 200ms (see shared-standards.md).

6. **Error/edge cases to handle?**
   - Auth state changes while app running, memory leaks, rapid tab switching.

7. **Data model changes?**
   - None. Uses existing AuthViewModel from PR #2.

8. **Service APIs required?**
   - None. Uses existing AuthViewModel.logout() from PR #2.

9. **UI entry points and states?**
   - Entry: App launch → RootView checks auth → Shows LoginView or MainTabView.
   - States: Logged out (LoginView), Logged in (MainTabView with 3 tabs).

10. **Security/permissions implications?**
    - None. Navigation structure doesn't touch sensitive data.

11. **Dependencies or blocking integrations?**
    - Depends on PR #2 (user-authentication-flow) being complete.

12. **Rollout strategy and metrics?**
    - Direct rollout. Track navigation success, logout success, crash rate.

13. **What is explicitly out of scope?**
    - Full functionality in placeholder screens, deep linking, custom tab styling, tab state persistence.

---

## Authoring Notes

- Navigation structure is foundational—keep it simple and robust
- Use SwiftUI's native components (TabView, NavigationStack/NavigationView)
- Ensure AuthViewModel from PR #2 properly publishes auth state changes
- Test memory management with Instruments
- Placeholder screens should be minimal but clearly labeled for future work
- Follow shared-standards.md for SwiftUI state management patterns
