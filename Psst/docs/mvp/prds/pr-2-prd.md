# PRD: User Authentication Flow

**Feature**: user-authentication-flow

**Version**: 1.0

**Status**: Draft

**Agent**: Pam

**Target Release**: Phase 1

**Links**: [PR Brief], [TODO], [Designs], [Tracking Issue]

---

## 1. Summary

Implement complete user authentication flows including sign-up, login, logout, and password reset using Firebase Authentication. Create SwiftUI views for authentication screens with email/password support and build an AuthenticationService to handle all auth operations and state management.

---

## 2. Problem & Goals

- **User Problem**: Users need a secure way to create accounts and access the messaging app
- **Why Now**: Foundation for all user-specific features in the app
- **Goals**:
  - [ ] G1 — Users can create accounts with email/password in <30 seconds
  - [ ] G2 — Users can log in/log out seamlessly with proper state management
  - [ ] G3 — Authentication state persists across app launches
  - [ ] G4 - Google Social

---

## 3. Non-Goals / Out of Scope

- [ ] Apple Sign-In - defer to future PR
- [ ] Two-factor authentication - not needed for MVP
- [ ] Password strength requirements - use Firebase defaults
- [ ] Account deletion flow - defer to future PR

---

## 4. Success Metrics

Reference `Psst/agents/shared-standards.md` for metric templates:
- **User-visible**: Sign-up flow completes in <30 seconds, login in <10 seconds
- **System**: App load time <2-3 seconds, authentication state loads <500ms
- **Quality**: 0 blocking bugs, all gates pass, crash-free >99%

---

## 5. Users & Stories

- As a new user, I want to create an account with email/password so that I can access the messaging app
- As a new user, I want to sign up with Google so that I can quickly create an account
- As a returning user, I want to log in quickly so that I can resume my conversations
- As a user, I want to log out securely so that my account is protected on shared devices
- As a user, I want to reset my password if I forget it so that I can regain access to my account

---

## 6. Experience Specification (UX)

- **Entry points**: App launch (first time), login screen, sign-up screen
- **Visual behavior**: Clean forms with validation feedback, loading states during auth operations
- **Loading/disabled/error states**: Loading spinners, disabled buttons during processing, clear error messages
- **Performance**: See targets in `Psst/agents/shared-standards.md` - auth state loads <500ms

---

## 7. Functional Requirements (Must/Should)

- **MUST**: Sign up with email/password using Firebase Auth
- **MUST**: Sign up with Google using Firebase Auth
- **MUST**: Log in with email/password using Firebase Auth  
- **MUST**: Log in with Google using Firebase Auth
- **MUST**: Log out and clear authentication state
- **MUST**: Password reset via email using Firebase Auth
- **MUST**: Form validation for email format and password requirements
- **MUST**: Authentication state persistence across app launches
- **SHOULD**: Loading states during auth operations
- **SHOULD**: Clear error messages for auth failures

**Acceptance gates per requirement:**
- [Gate] When user enters valid email/password → Account created successfully
- [Gate] When user taps Google sign-up → Google auth flow completes successfully
- [Gate] When user enters valid credentials → Login succeeds in <2 seconds
- [Gate] When user taps Google sign-in → Google auth flow completes successfully
- [Gate] When user logs out → Authentication state cleared, redirected to login
- [Gate] When user requests password reset → Email sent successfully
- [Gate] When app launches → Authentication state restored automatically

---

## 8. Data Model

No new Firestore collections needed - Firebase Auth handles user accounts.

**Firebase Auth User Object:**
```swift
// Firebase Auth provides:
{
  uid: String,           // Unique user identifier
  email: String?,         // User's email address
  displayName: String?,  // User's display name (optional)
  photoURL: String?       // Profile photo URL (optional)
}
```

- **Validation rules**: Firebase Auth handles email/password validation
- **Indexing/queries**: No custom queries needed - Firebase Auth manages user data

---

## 9. API / Service Contracts

Specify concrete service layer methods for authentication operations.

```swift
// AuthenticationService methods:
func signUp(email: String, password: String) async throws -> User
func signUpWithGoogle() async throws -> User
func signIn(email: String, password: String) async throws -> User
func signInWithGoogle() async throws -> User
func signOut() async throws
func resetPassword(email: String) async throws
func getCurrentUser() -> User?
func observeAuthState(completion: @escaping (User?) -> Void) -> ListenerRegistration
```

- **Pre/post-conditions**: All methods validate input, handle Firebase errors
- **Error handling**: Convert Firebase errors to user-friendly messages
- **Parameters and types**: Email/password strings, return User objects
- **Return values**: User object on success, throws on failure

---

## 10. UI Components to Create/Modify

List SwiftUI views/files with one-line purpose each.

- `Views/Authentication/LoginView.swift` — Email/password and Google login form
- `Views/Authentication/SignUpView.swift` — Email/password and Google sign-up form  
- `Views/Authentication/ForgotPasswordView.swift` — Password reset form
- `Services/AuthenticationService.swift` — Firebase Auth operations (email + Google)
- `ViewModels/AuthViewModel.swift` — Authentication state management
- `PsstApp.swift` — Root view with auth state routing

---

## 11. Integration Points

- **Firebase Authentication** - Primary auth provider
- **SwiftUI State Management** - @StateObject for auth state
- **App Navigation** - Route between auth and main app screens
- **Error Handling** - User-friendly error messages

---

## 12. Test Plan & Acceptance Gates

Define BEFORE implementation. Use checkboxes.

Reference testing standards from `Psst/agents/shared-standards.md`.

### Testing Framework Strategy

This project uses a **hybrid approach** for testing:

**Unit Tests (Swift Testing Framework)**
- Use `@Test("Display Name")` syntax for readable test names
- Tests appear with custom names in test navigator (e.g., "Sign Up With Valid Credentials Creates User")
- Use `#expect` instead of `XCTAssert`
- Best for service layer, business logic, data models

**UI Tests (XCTest Framework)**
- Use traditional `XCTestCase` with function-based naming
- Required for `XCUIApplication` integration and UI automation
- Use `XCTAssert` for assertions
- Best for user flows, navigation, UI interactions

- **Happy Path**
  - [ ] User can sign up with valid email/password
  - [ ] User can sign up with Google
  - [ ] User can log in with valid credentials
  - [ ] User can log in with Google
  - [ ] User can log out successfully
  - [ ] User can reset password via email
  - [ ] Gate: All auth operations complete in <2 seconds

- **Edge Cases**
  - [ ] Invalid email format shows error
  - [ ] Weak password shows error
  - [ ] Google auth cancelled shows appropriate message
  - [ ] Network error shows retry option
  - [ ] Gate: Error messages are user-friendly

- **Multi-User**
  - [ ] Multiple users can sign up simultaneously
  - [ ] Auth state isolated per user
  - [ ] Gate: No cross-user data leakage

- **Performance** (see shared-standards.md)
  - [ ] App load time <2-3 seconds
  - [ ] Auth state loads <500ms
  - [ ] Smooth transitions between screens

---

## 13. Definition of Done

See standards in `Psst/agents/shared-standards.md`:
- [ ] AuthenticationService implemented + unit tests (Swift Testing)
- [ ] SwiftUI auth views with all states (loading, error, success)
- [ ] Authentication state persistence verified
- [ ] All acceptance gates pass
- [ ] UI tests for auth flows (XCTest/XCUITest)
- [ ] Error handling tested
- [ ] Unit tests use `@Test("Display Name")` for readable test names
- [ ] UI tests use descriptive function names
- [ ] Docs updated

---

## 14. Risks & Mitigations

- **Risk**: Firebase Auth setup complexity → **Mitigation**: Follow Firebase docs, test with emulator
- **Risk**: Google Sign-In configuration complexity → **Mitigation**: Follow Google Sign-In iOS setup guide
- **Risk**: Authentication state not persisting → **Mitigation**: Use Firebase Auth state listeners
- **Risk**: Poor UX during auth → **Mitigation**: Loading states, clear error messages

---

## 15. Rollout & Telemetry

- **Feature flag**: No - core functionality
- **Metrics**: Sign-up completion rate, login success rate, auth errors
- **Manual validation steps**: Test all auth flows on device

---

## 16. Open Questions

- Q1: Should we validate password strength or use Firebase defaults?
- Q2: Do we need email verification before account activation?

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future:
- [ ] Apple Sign-In
- [ ] Two-factor authentication
- [ ] Account deletion
- [ ] Email verification flow

---

## Preflight Questionnaire

Answer these to drive vertical slice and acceptance gates:

1. **Smallest end-to-end user outcome for this PR?** User can create account and log in
2. **Primary user and critical action?** New user creating account, returning user logging in
3. **Must-have vs nice-to-have?** Must-have: sign-up, login, logout. Nice-to-have: password reset
4. **Real-time requirements?** No real-time messaging in this PR
5. **Performance constraints?** Auth state loads <500ms, app launch <2-3s
6. **Error/edge cases to handle?** Invalid credentials, network errors, Firebase errors
7. **Data model changes?** No - using Firebase Auth user object
8. **Service APIs required?** AuthenticationService with 6 methods
9. **UI entry points and states?** Login, sign-up, forgot password screens
10. **Security/permissions implications?** Firebase Auth handles security
11. **Dependencies or blocking integrations?** Depends on PR #1 (Firebase setup)
12. **Rollout strategy and metrics?** Core feature, no feature flag needed
13. **What is explicitly out of scope?** Social login, 2FA, account deletion

---

## Authoring Notes

- Write Test Plan before coding
- Favor vertical slice that ships standalone
- Keep service layer deterministic
- SwiftUI views are thin wrappers
- Test offline/online thoroughly
- Reference `Psst/agents/shared-standards.md` throughout
