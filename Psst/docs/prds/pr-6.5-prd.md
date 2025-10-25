# PRD: User Roles & Required Name

**Feature**: User role distinction (trainer vs client) and required displayName

**Version**: 1.0

**Status**: Ready for Development

**Agent**: Pam → Caleb

**Target Release**: Phase 0 (Prerequisite for AI features)

**Links**: [PR Brief in ai-briefs.md](../ai-briefs.md), [TODO](../todos/pr-6.5-todo.md), [Architecture](../architecture.md#brownfield-analysis-user-roles--required-name-pr-0065)

---

## 1. Summary

Add user role (trainer vs client) distinction to the User model and enforce required displayName during signup to enable role-based AI features. This foundation allows future features to differentiate between trainers building client profiles and clients receiving training.

---

## 2. Problem & Goals

**Problem:**
- Current system has no way to distinguish trainers from clients
- PR #007 (Auto Client Profiles) needs to know which user is the trainer to create profiles correctly
- displayName is optional during signup, leading to auto-generated names that aren't meaningful
- Future AI features require role context (trainers get assistant tools, clients get different features)

**Why now:**
- Prerequisite for PR #007 (Auto Client Profiles) which is blocked without role distinction
- Foundation for all AI features in Phases 1-5
- Better to add early before user base grows (easier migration)

**Goals (ordered, measurable):**
- [x] G1 — Every new user has an explicit role (trainer or client) stored in Firestore
- [x] G2 — Every new user provides a meaningful displayName (no more auto-generated names)
- [x] G3 — Existing authentication flow updated without breaking current features
- [x] G4 — Role field accessible throughout app for future feature logic

---

## 3. Non-Goals / Out of Scope

To avoid scope creep, we are NOT doing:

- [ ] Not implementing role-based permissions yet (wait for specific features that need it)
- [ ] Not allowing users to change roles after signup (roles are permanent)
- [ ] Not adding role-specific features yet (just the foundation)
- [ ] Not creating separate apps for trainers/clients (single app, different experiences)
- [ ] Not implementing role badges in UI (optional enhancement for future PR)
- [ ] Not migrating existing users (will default to trainer role)

---

## 4. Success Metrics

**User-visible:**
- New signup flow takes < 30 seconds (role selection adds ~5 seconds)
- 100% of new users have explicit role assigned
- 0 users with auto-generated displayNames (all must provide real names)

**System:**
- All existing features work unchanged (no regressions)
- Role field present in 100% of new user documents
- Firestore security rules enforce valid role values

**Quality:**
- 0 blocking bugs in signup flow
- All acceptance gates pass
- Crash-free rate >99%

---

## 5. Users & Stories

**As a new trainer**, I want to select "I'm a Trainer" during signup so that future AI features work correctly for my business needs.

**As a new client**, I want to select "I'm a Client" during signup so that I get the appropriate client experience.

**As a trainer using PR #007**, I want the system to know I'm a trainer so it can automatically build profiles for my clients (not the other way around).

**As a developer building AI features**, I want reliable role data so I can implement trainer-specific vs client-specific logic confidently.

---

## 5b. Affected Existing Code

This is a **brownfield PR** that modifies existing authentication code. Here are the files that will be **MODIFIED** (not created):

### Models:
- **`Models/User.swift`** - Add `role` field, update Codable conformance, add UserRole enum
  - Current: 7 fields (id, email, displayName, photoURL, createdAt, updatedAt, fcmToken)
  - After: 8 fields (adds role: UserRole)
  - Change: Add enum `UserRole { trainer, client }`, update init/CodingKeys

### Services:
- **`Services/AuthenticationService.swift`** - Update `signUp()` method signature
  - Current: `signUp(email:password:displayName:) async throws -> User`
  - After: `signUp(email:password:displayName:role:) async throws -> User`
  - Change: Add role parameter, make displayName required (remove optional/fallback)

- **`Services/UserService.swift`** - Update `createUser()` method signature
  - Current: `createUser(id:email:displayName:photoURL:) async throws -> User`
  - After: `createUser(id:email:displayName:role:photoURL:) async throws -> User`
  - Change: Add role parameter, include in Firestore document creation

### Views:
- **`Views/Authentication/SignUpView.swift`** - Add role selection, enforce required name
  - Current: Optional displayName field with fallback to email prefix
  - After: Required displayName field + role selection screen
  - Change: Add role selection UI, update validation logic, add new state variables

### ViewModels:
- **`ViewModels/AuthViewModel.swift`** - Update signUp call
  - Current: Calls `authService.signUp(email: ..., password: ..., displayName: ...)`
  - After: Calls `authService.signUp(email: ..., password: ..., displayName: ..., role: ...)`
  - Change: Pass selected role from view to service

### Backend:
- **`firestore.rules`** - Add role validation rules
  - Current: Allows any fields during user creation
  - After: Validates role field is 'trainer' or 'client'
  - Change: Add role field validation in create/update rules

---

## 6. Experience Specification (UX)

### Entry Points & Flows

**New User Signup:**
1. User taps "Sign Up" from LoginView
2. **NEW:** Role selection screen appears first
   - Title: "I am a..."
   - Two large buttons:
     - "Personal Trainer" (icon: dumbbell or person)
     - "Client" (icon: person or heart)
   - Subtitle: "This helps us personalize your experience"
3. User selects role → navigates to signup form
4. Signup form (MODIFIED):
   - displayName field now **required** (no skip button)
   - Email field
   - Password field
   - Confirm Password field
   - Sign Up button (disabled until all fields valid)
5. Submit → Account created → Navigate to main app

**Visual Behavior:**
- Role selection buttons: Large tap targets (80% screen width), clear icons
- displayName field: Shows error state if left empty on submit attempt
- All existing animations/transitions preserved

**Loading/Error States:**
- Loading: Spinner on "Sign Up" button during account creation
- Error: Alert for invalid role, empty name, existing email, weak password
- Empty state: displayName field shows red border if empty after submit attempt

**Performance:**
- Role selection: Instant response (<50ms)
- Form validation: Real-time as user types
- Account creation: < 2 seconds (existing Firebase performance)

---

## 7. Functional Requirements (Must/Should)

### MUST Requirements:

**R1: Role Selection**
- MUST present role selection before or during signup
- MUST store role in Firestore `/users/{uid}` document
- MUST validate role is either "trainer" or "client"
- [Gate] When user selects role → SignUpView receives selected role and enables form

**R2: Required Display Name**
- MUST require displayName field during signup (no empty submission)
- MUST validate displayName is not empty string or whitespace only
- MUST remove auto-generation fallback from AuthenticationService
- [Gate] When user submits empty name → Shows validation error "Display name is required"

**R3: Data Persistence**
- MUST save role to Firestore user document
- MUST include role in User model throughout app
- MUST maintain role immutability (no changes after creation)
- [Gate] When user creates account → Firestore document includes role field with correct value

**R4: Backward Compatibility**
- MUST not break existing users without role field
- MUST default existing users to "trainer" role when loaded
- MUST preserve all existing auth functionality
- [Gate] When existing user logs in → App loads successfully without crashes

### SHOULD Requirements:

**R5: Firestore Security Rules**
- SHOULD validate role field in security rules
- SHOULD prevent role changes after account creation
- SHOULD enforce role values are only "trainer" or "client"

**R6: User Experience**
- SHOULD show clear role descriptions during selection
- SHOULD make displayName field prominent and obvious
- SHOULD validate displayName in real-time (not just on submit)

---

## 8. Data Model

### User Model (Modified)

**File:** `Psst/Psst/Models/User.swift`

```swift
// NEW: User role enum
enum UserRole: String, Codable {
    case trainer = "trainer"
    case client = "client"
}

// MODIFIED: User struct
struct User: Identifiable, Codable {
    let id: String              // Firebase Auth UID
    let email: String           // User email
    var displayName: String     // NOW REQUIRED (was optional)
    var role: UserRole          // NEW FIELD
    var photoURL: String?       // Profile photo
    let createdAt: Date        // Account creation
    var updatedAt: Date        // Last update
    var fcmToken: String?      // Push notifications

    // NEW: CodingKeys update
    enum CodingKeys: String, CodingKey {
        case id, email, displayName, role, photoURL, createdAt, updatedAt, fcmToken
    }

    // MODIFIED: Add default role for backward compatibility
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        displayName = try container.decode(String.self, forKey: .displayName)

        // NEW: Default to trainer for existing users without role
        role = try container.decodeIfPresent(UserRole.self, forKey: .role) ?? .trainer

        photoURL = try container.decodeIfPresent(String.self, forKey: .photoURL)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        fcmToken = try container.decodeIfPresent(String.self, forKey: .fcmToken)
    }

    // MODIFIED: Include role in dictionary
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "email": email,
            "displayName": displayName,
            "role": role.rawValue,  // NEW
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]
        if let photoURL = photoURL {
            dict["photoURL"] = photoURL
        }
        if let fcmToken = fcmToken {
            dict["fcmToken"] = fcmToken
        }
        return dict
    }
}
```

### Firestore Schema Update

**Collection:** `/users/{uid}`

**New Field:**
```json
{
  "id": "user_123",
  "email": "trainer@example.com",
  "displayName": "John Trainer",
  "role": "trainer",           // NEW: "trainer" | "client"
  "photoURL": "https://...",
  "createdAt": "2025-10-24T12:00:00Z",
  "updatedAt": "2025-10-24T12:00:00Z",
  "fcmToken": "fcm_token_here"
}
```

**Validation Rules:**
- `role` field MUST be present for new users
- `role` value MUST be "trainer" or "client"
- `role` field MUST NOT change after creation
- `displayName` MUST NOT be empty string

---

## 9. API / Service Contracts

### AuthenticationService (Modified)

**File:** `Psst/Psst/Services/AuthenticationService.swift`

```swift
// BEFORE:
func signUp(email: String, password: String, displayName: String? = nil) async throws -> User {
    // Auto-generates displayName from email if nil
}

// AFTER:
func signUp(email: String, password: String, displayName: String, role: UserRole) async throws -> User {
    // displayName is required, no fallback
    // role is required

    // Pre-conditions:
    // - email is valid format
    // - password is 6+ characters
    // - displayName is not empty/whitespace
    // - role is .trainer or .client

    // Post-conditions:
    // - Firebase Auth user created
    // - Firestore user document created with role
    // - Returns User object with role

    // Error cases:
    // - emailAlreadyInUse
    // - weakPassword
    // - invalidEmail
    // - emptyDisplayName (NEW)
    // - invalidRole (NEW)
}
```

### UserService (Modified)

**File:** `Psst/Psst/Services/UserService.swift`

```swift
// BEFORE:
func createUser(id: String, email: String, displayName: String, photoURL: String?) async throws -> User

// AFTER:
func createUser(id: String, email: String, displayName: String, role: UserRole, photoURL: String?) async throws -> User {
    // Pre-conditions:
    // - id is valid Firebase Auth UID
    // - email is valid
    // - displayName is not empty
    // - role is .trainer or .client

    // Post-conditions:
    // - Firestore document created at /users/{id}
    // - Document includes role field
    // - Returns User object

    // Error cases:
    // - firestoreError (network, permissions)
    // - documentAlreadyExists
}
```

---

## 10. UI Components to Create/Modify

### Modified Components:

1. **`Views/Authentication/SignUpView.swift`** — Add role selection UI, enforce required displayName
   - Add `@State private var selectedRole: UserRole?`
   - Add role selection screen (two buttons)
   - Update `isFormValid` to check displayName not empty
   - Remove "skip" logic for displayName
   - Pass role to AuthViewModel

2. **`ViewModels/AuthViewModel.swift`** — Update signUp method call
   - Add role parameter to `signUp(email:password:displayName:role:)`
   - Pass role from view to service

3. **`Models/User.swift`** — Add UserRole enum, add role field, update Codable
   - Create `UserRole` enum
   - Add `role: UserRole` property
   - Update CodingKeys
   - Add backward compatibility fallback
   - Update `toDictionary()`

4. **`Services/AuthenticationService.swift`** — Update signUp signature, remove fallback
   - Make displayName required (remove optional)
   - Add role parameter
   - Remove auto-generation logic
   - Add validation for empty displayName

5. **`Services/UserService.swift`** — Update createUser signature
   - Add role parameter
   - Include role in Firestore document

### Optional Enhancements (Future PRs):

- **`Views/Profile/ProfileView.swift`** — Display role badge (optional)
- **`Views/ChatList/ChatView.swift`** — Show user role in header (optional)

---

## 11. Integration Points

**Firebase Authentication:**
- Existing: Email/password signup flow
- No changes to Firebase Auth itself (role stored in Firestore, not Auth)

**Firestore:**
- Modified: `/users/{uid}` document schema (add role field)
- New field: `role: "trainer" | "client"`

**State Management:**
- SignUpView: New `@State var selectedRole: UserRole?`
- AuthViewModel: Passes role through to services

**Security:**
- `firestore.rules`: Add validation for role field

---

## 12. Testing Plan & Acceptance Gates

**See `Psst/docs/testing-strategy.md` for examples and detailed guidance.**

---

### Happy Path

**Test:** New user signs up with role and displayName

**Steps:**
1. Open app → Tap "Sign Up"
2. See role selection screen
3. Tap "Personal Trainer" button
4. Fill out signup form:
   - displayName: "John Trainer"
   - email: "john@example.com"
   - password: "password123"
   - confirmPassword: "password123"
5. Tap "Sign Up"
6. Account created → Navigate to ChatListView

**Gates:**
- [x] Role selection screen appears before signup form
- [x] Selected role is visible/confirmed in UI
- [x] Signup form submits successfully with all fields
- [x] User document in Firestore includes `role: "trainer"`
- [x] User is logged in and sees main app

**Pass Criteria:** Flow completes without errors, Firestore document contains correct role, user lands on ChatListView

---

### Edge Cases

**Edge Case 1: Empty displayName**

**Test:** User tries to submit signup form without providing a name

**Steps:**
1. Complete role selection
2. Fill email and password
3. Leave displayName field empty
4. Tap "Sign Up"

**Expected:**
- displayName field shows red border or error message
- Form does not submit
- Error text: "Display name is required"

**Pass:** Form validation prevents submission, clear error shown, no crash

---

**Edge Case 2: No role selected**

**Test:** User skips role selection (if possible)

**Steps:**
1. Open signup flow
2. Try to skip role selection screen
3. Attempt to submit form

**Expected:**
- Cannot proceed without selecting role
- Role selection screen blocks progress
- OR: Form shows error "Please select your role"

**Pass:** Cannot create account without role, clear feedback provided

---

**Edge Case 3: Existing user without role logs in**

**Test:** Backward compatibility for users created before this PR

**Steps:**
1. Use existing Firebase Auth account (no role in Firestore)
2. Log in
3. Navigate to ChatListView

**Expected:**
- App loads successfully
- User model defaults role to `.trainer`
- No crashes or errors

**Pass:** Existing users can still log in, app defaults role to trainer

---

### Error Handling

**Offline Mode:**

**Test:** Enable airplane mode → attempt signup

**Expected:**
- "No internet connection" message
- Signup does not proceed
- Clear retry option when back online

**Pass:** Clear error message, no partial account creation, retry works

---

**Invalid Input:**

**Test:** Submit malformed data
- displayName: "   " (only whitespace)
- email: "notanemail"
- password: "123" (too short)

**Expected:**
- Validation errors shown inline for each field
- displayName: "Display name cannot be empty"
- email: "Invalid email format"
- password: "Password must be at least 6 characters"

**Pass:** All validation errors caught, user can correct and retry

---

**Firebase Error:**

**Test:** Email already exists in Firebase Auth

**Steps:**
1. Attempt signup with existing email

**Expected:**
- Alert: "This email is already in use"
- User can go back and try different email

**Pass:** Error handled gracefully, no crash

---

### Regression Testing

Since this is a **brownfield PR**, we must verify existing features still work:

**Existing Feature Tests:**
- [x] Email/password login still works (no changes to login flow)
- [x] User profile loading works for existing users
- [x] Chat functionality unchanged
- [x] Presence tracking still works
- [x] Message sending/receiving unchanged
- [x] Profile photo upload still works

**Pass Criteria:** All existing features work as before, no regressions

---

### Multi-Device Testing

**Not required** for this PR (authentication only, no real-time sync involved)

---

### Performance Check

**Subjective checks:**
- [x] Role selection feels instant (<50ms tap response)
- [x] Signup form validation responsive
- [x] Account creation < 3 seconds (same as before)

**Pass Criteria:** No noticeable performance degradation

---

## 13. Definition of Done

Checklist for completion:

- [x] UserRole enum created
- [x] User model updated with role field
- [x] User model Codable conformance updated
- [x] User.toDictionary() includes role
- [x] AuthenticationService.signUp() signature updated (add role, require displayName)
- [x] UserService.createUser() signature updated (add role)
- [x] SignUpView includes role selection UI
- [x] SignUpView enforces required displayName
- [x] AuthViewModel passes role to service
- [x] Firestore security rules updated to validate role
- [x] Backward compatibility: existing users default to trainer
- [x] All acceptance gates pass (happy path, edge cases, errors)
- [x] Manual testing completed on simulator
- [x] No console errors during signup flow
- [x] Regression testing: existing features work unchanged
- [x] Code follows `Psst/agents/shared-standards.md` patterns

---

## 14. Risks & Mitigations

**Risk 1: Breaking existing users**
- **Severity:** High
- **Impact:** Existing users cannot log in
- **Mitigation:** Add default role fallback in User model decoder (default to `.trainer`)
- **Mitigation:** Test with existing Firebase Auth accounts before deployment

**Risk 2: Forgetting to pass role in new code**
- **Severity:** Medium
- **Impact:** Compilation errors in new features using User model
- **Mitigation:** Update all signup flows in one PR
- **Mitigation:** Compiler will catch missing role parameter (required parameter)

**Risk 3: Role validation inconsistency**
- **Severity:** Low
- **Impact:** Invalid roles stored in database
- **Mitigation:** Firestore security rules enforce valid role values
- **Mitigation:** Swift enum restricts possible values

**Risk 4: User confusion during role selection**
- **Severity:** Low
- **Impact:** Users select wrong role, see incorrect features later
- **Mitigation:** Clear descriptions on role selection buttons
- **Mitigation:** Make roles immutable (cannot change after creation)

**Risk 5: PR #007 still broken**
- **Severity:** Medium
- **Impact:** Auto Client Profiles feature doesn't work as expected
- **Mitigation:** Verify PR #007 logic uses role field correctly
- **Mitigation:** Add integration test for trainer-client chat

---

## 15. Rollout & Telemetry

**Feature Flag:** No (core authentication change, cannot be toggled)

**Deployment Strategy:**
1. Deploy Firestore security rules first (add role validation)
2. Deploy iOS app with role selection
3. Monitor signup success rate for 24 hours
4. If issues: revert and investigate

**Metrics to Track:**
- Signup success rate (should stay ~same as before)
- Signup duration (may increase by ~5 seconds for role selection)
- Role distribution (what % select trainer vs client)
- Error rate during signup
- Existing user login success rate (backward compatibility check)

**Manual Validation:**
- Create 5 new accounts (mix of trainer/client)
- Verify all Firestore documents include role field
- Check security rules block invalid role values
- Test existing account login

---

## 16. Open Questions

**Q1:** Should we allow users to change roles after signup?
- **Answer:** No (out of scope). Roles are immutable to prevent confusion and data integrity issues.

**Q2:** Should we show role badges in the UI now?
- **Answer:** No (out of scope). This PR is foundation only. UI enhancements in future PR.

**Q3:** What if someone creates a trainer account but is actually a client?
- **Answer:** Support issue. For MVP, no role change feature. Future: Add support ticket system.

**Q4:** Should we migrate existing users to have roles?
- **Answer:** Not required. Default to `.trainer` for existing users. Manual migration script optional.

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future PRs:

- [ ] Role badges in ProfileView (visual indicator)
- [ ] Role display in chat headers
- [ ] Role change feature (support ticket required)
- [ ] Role-based filtering in user list
- [ ] Analytics dashboard for role distribution
- [ ] Bulk migration tool for existing users

---

## Preflight Questionnaire

1. **Smallest end-to-end user outcome for this PR?**
   - New users select role during signup and provide required displayName → Account created with role stored in Firestore

2. **Primary user and critical action?**
   - New users (both trainers and clients) → Select role and complete signup

3. **Must-have vs nice-to-have?**
   - Must: Role selection, required displayName, Firestore storage, backward compatibility
   - Nice: Role badges in UI, role change feature (deferred)

4. **Real-time requirements?**
   - None (authentication only)

5. **Performance constraints?**
   - Signup flow < 30 seconds total (adds ~5 seconds for role selection)

6. **Error/edge cases to handle?**
   - Empty displayName, no role selected, existing users without role, invalid role values

7. **Data model changes?**
   - Add `role: UserRole` field to User model
   - Update Firestore `/users/{uid}` schema

8. **Service APIs required?**
   - Modify AuthenticationService.signUp()
   - Modify UserService.createUser()

9. **UI entry points and states?**
   - Entry: SignUpView
   - States: Role selection, form input, loading, error, success

10. **Security/permissions implications?**
    - Add Firestore security rules to validate role field

11. **Dependencies or blocking integrations?**
    - None (this PR unblocks PR #007)

12. **Rollout strategy and metrics?**
    - Deploy rules first, then app
    - Monitor signup success rate

13. **What is explicitly out of scope?**
    - Role-based permissions/features, role changes, UI badges, migrations

---

## Authoring Notes

- **Brownfield PR:** This modifies core authentication code
- **Breaking Change:** AuthenticationService.signUp() signature changes (requires update in all calling code)
- **Backward Compatibility:** Critical to test existing users can still log in
- **Foundation for Future:** This PR enables all of Phase 1-5 AI features
- **Test offline/online:** Signup must handle network errors gracefully
- **Reference:** `Psst/agents/shared-standards.md` for code quality standards
