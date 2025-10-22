# PR-2 TODO — User Authentication Flow

**Branch**: `feat/pr-2-user-authentication-flow`  
**Source PRD**: `Psst/docs/prds/pr-2-prd.md`  
**Owner (Agent)**: Caleb

---

## 0. Clarifying Questions & Assumptions

- Questions: None - PRD is comprehensive
- Assumptions (confirm in PR if needed):
  - Google Sign-In SDK will be added via Swift Package Manager
  - Firebase Auth is already configured (from PR #1)
  - GoogleService-Info.plist is already in place

---

## 1. Setup

- [x] Create branch `feat/pr-2-user-authentication-flow` from develop
- [x] Read PRD thoroughly
- [x] Read `Psst/agents/shared-standards.md` for patterns
- [ ] Confirm environment and test runner work
- [ ] Add Google Sign-In SDK dependency to Xcode project

---

## 2. Service Layer

Implement deterministic service contracts from PRD.

- [x] Create `Services/AuthenticationService.swift`
  - Test Gate: File compiles without errors
- [x] Implement `signUp(email:password:)` method
  - Test Gate: Unit test passes for valid/invalid cases
- [x] Implement `signUpWithGoogle()` method
  - Test Gate: Unit test passes for Google auth flow
- [x] Implement `signIn(email:password:)` method
  - Test Gate: Unit test passes for valid credentials
- [x] Implement `signInWithGoogle()` method
  - Test Gate: Unit test passes for Google auth flow
- [x] Implement `signOut()` method
  - Test Gate: Unit test passes for logout
- [x] Implement `resetPassword(email:)` method
  - Test Gate: Unit test passes for password reset
- [x] Implement `getCurrentUser()` method
  - Test Gate: Unit test passes for current user retrieval
- [x] Implement `observeAuthState(completion:)` method
  - Test Gate: Unit test passes for auth state changes
- [x] Add error handling for Firebase Auth errors
  - Test Gate: Edge cases handled correctly

---

## 3. Data Model & Rules

- [x] Define User model struct in Swift
  - Test Gate: User struct compiles and matches Firebase Auth user
- [ ] Update Firebase Auth configuration for Google Sign-In
  - Test Gate: Google Sign-In enabled in Firebase console
- [ ] Add Firebase security rules for authentication
  - Test Gate: Reads/writes succeed with rules applied

---

## 4. UI Components

Create/modify SwiftUI views per PRD Section 10.

- [x] Create `Views/Authentication/LoginView.swift`
  - Test Gate: SwiftUI Preview renders; zero console errors
- [x] Add email/password input fields to LoginView
  - Test Gate: Text fields accept input correctly
- [x] Add Google Sign-In button to LoginView
  - Test Gate: Button triggers Google auth flow
- [x] Create `Views/Authentication/SignUpView.swift`
  - Test Gate: SwiftUI Preview renders; zero console errors
- [x] Add email/password input fields to SignUpView
  - Test Gate: Text fields accept input correctly
- [x] Add Google Sign-Up button to SignUpView
  - Test Gate: Button triggers Google auth flow
- [x] Create `Views/Authentication/ForgotPasswordView.swift`
  - Test Gate: SwiftUI Preview renders; zero console errors
- [x] Add email input field to ForgotPasswordView
  - Test Gate: Text field accepts input correctly
- [x] Wire up state management (@State, @StateObject, etc.)
  - Test Gate: Interaction updates state correctly
- [x] Add loading/error/empty states to all views
  - Test Gate: All states render correctly

---

## 5. Integration & Real-Time

Reference requirements from `Psst/agents/shared-standards.md`.

- [x] Firebase Authentication integration
  - Test Gate: Auth operations work with Firebase
- [ ] Google Sign-In SDK integration
  - Test Gate: Google auth flow completes successfully (SDK needs to be added)
- [x] Authentication state persistence
  - Test Gate: Auth state persists across app launches
- [x] Real-time auth state listeners
  - Test Gate: Auth state changes trigger UI updates
- [x] Error handling for network/auth failures
  - Test Gate: User-friendly error messages displayed

---

## 6. Tests

Follow patterns from `Psst/agents/shared-standards.md` and `Psst/agents/test-template.md`.

### Testing Framework Strategy

**Unit Tests → Swift Testing Framework**
- Use `@Test("Display Name")` syntax for readable test names
- Use `#expect` for assertions instead of `XCTAssert`
- Tests appear with custom display names in test navigator
- Example: `@Test("Sign Up With Valid Credentials Creates User")`

**UI Tests → XCTest Framework**
- Use traditional `XCTestCase` with `XCUIApplication`
- Use descriptive function names (e.g., `testLoginView_DisplaysCorrectly()`)
- Use `XCTAssert` for assertions
- Required for UI automation and lifecycle management

### Test Checklist

- [x] Unit Tests (Swift Testing)
  - Path: `PsstTests/AuthenticationServiceTests.swift`
  - Test Gate: Service logic validated, edge cases covered
  - Format: Uses `@Test("Display Name")` syntax
  
- [x] UI Tests (XCTest)
  - Path: `PsstUITests/AuthenticationUITests.swift`
  - Test Gate: User flows succeed, navigation works
  - Format: Uses `XCTestCase` with descriptive function names
  
- [x] Service Tests (Swift Testing)
  - Path: `PsstTests/AuthenticationServiceTests.swift`
  - Test Gate: Firebase operations tested
  - Format: Uses `@Test("Display Name")` syntax
  
- [ ] Google Sign-In Tests
  - Test Gate: Google auth flow tested (requires SDK to be added)
  
- [x] Visual states verification
  - Test Gate: Empty, loading, error, success render correctly

---

## 7. Performance

Verify targets from `Psst/agents/shared-standards.md`.

- [ ] App load time < 2-3 seconds
  - Test Gate: Cold start to interactive measured
- [ ] Authentication state loads < 500ms
  - Test Gate: Auth state restoration measured
- [ ] Auth operations complete < 2 seconds
  - Test Gate: Sign-up/login operations timed
- [ ] Smooth transitions between auth screens
  - Test Gate: No frame drops during navigation

---

## 8. Acceptance Gates

Check every gate from PRD Section 12:
- [ ] All happy path gates pass
- [ ] All edge case gates pass
- [ ] All multi-user gates pass
- [ ] All performance gates pass

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
- [ ] AuthenticationService implemented + unit tests (XCTest)
- [ ] SwiftUI auth views implemented with state management
- [ ] Firebase Authentication integration tested
- [ ] Google Sign-In integration tested
- [ ] UI tests pass (XCUITest)
- [ ] Authentication state persistence verified
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
- Google Sign-In setup may require additional configuration in Firebase console
