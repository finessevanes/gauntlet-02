# PR-6.5 TODO — User Roles & Required Name

**Branch**: `feat/pr-6.5-user-roles-required-name`
**Source PRD**: `Psst/docs/prds/pr-6.5-prd.md`
**Owner (Agent)**: Caleb

---

## 0. Clarifying Questions & Assumptions

**Questions:**
- None currently - PRD is comprehensive

**Assumptions:**
- Existing users will default to `.trainer` role (confirmed in PRD Section 14)
- Roles are immutable after creation (confirmed in PRD Section 3)
- No UI badges/indicators for roles in this PR (deferred to future PR)
- Role selection happens BEFORE signup form (confirmed in PRD Section 6)

---

## 1. Setup

- [ ] Create branch `feat/pr-6.5-user-roles-required-name` from develop
  - Test Gate: `git branch --show-current` returns correct branch name
- [ ] Read PRD thoroughly at `Psst/docs/prds/pr-6.5-prd.md`
  - Test Gate: Understand all 5 affected files and brownfield changes
- [ ] Read `Psst/agents/shared-standards.md` for Swift patterns
  - Test Gate: Review MVVM, Codable, and error handling standards
- [ ] Confirm Xcode builds successfully on develop branch
  - Test Gate: ⌘+B builds without errors

---

## 2. Data Model Changes

### Task 2.1: Create UserRole Enum
- [ ] Create `UserRole` enum in `Psst/Psst/Models/User.swift`
  - Add enum before User struct definition:
    ```swift
    enum UserRole: String, Codable {
        case trainer = "trainer"
        case client = "client"
    }
    ```
  - Test Gate: Enum compiles, Codable conformance works

### Task 2.2: Add Role Field to User Model
- [ ] Add `var role: UserRole` property to User struct
  - Place after `displayName` field for logical grouping
  - Test Gate: Compiler shows errors in other files (expected breaking change)

### Task 2.3: Update User CodingKeys
- [ ] Add `role` to CodingKeys enum in User struct
  - Add: `case role`
  - Test Gate: CodingKeys includes all 8 fields (id, email, displayName, role, photoURL, createdAt, updatedAt, fcmToken)

### Task 2.4: Add Backward Compatibility to User Decoder
- [ ] Modify `init(from decoder:)` to default role to `.trainer` for existing users
  - Add after displayName decoding:
    ```swift
    role = try container.decodeIfPresent(UserRole.self, forKey: .role) ?? .trainer
    ```
  - Test Gate: Decoder handles missing role field gracefully

### Task 2.5: Update User.toDictionary()
- [ ] Add role to dictionary conversion in `toDictionary()` method
  - Add: `"role": role.rawValue` to dict
  - Test Gate: Dictionary includes role as string value

### Task 2.6: Update User Initializers
- [ ] Find all User initializers and add role parameter
  - Update any custom inits (check for test mocks)
  - Test Gate: All initializers compile successfully

---

## 3. Service Layer Changes

### Task 3.1: Update AuthenticationService.signUp() Signature
- [ ] Modify `signUp()` method in `Psst/Psst/Services/AuthenticationService.swift`
  - BEFORE: `func signUp(email: String, password: String, displayName: String? = nil) async throws -> User`
  - AFTER: `func signUp(email: String, password: String, displayName: String, role: UserRole) async throws -> User`
  - Remove displayName optional default
  - Add role parameter
  - Test Gate: Method signature updated correctly

### Task 3.2: Remove DisplayName Auto-Generation Logic
- [ ] Find and remove displayName fallback code in `signUp()`
  - Remove lines like: `let finalDisplayName = displayName ?? email.components(separatedBy: "@").first ?? "User"`
  - Test Gate: No auto-generation logic remains

### Task 3.3: Add DisplayName Validation
- [ ] Add validation for empty displayName in `signUp()`
  - Add check:
    ```swift
    guard !displayName.trimmingCharacters(in: .whitespaces).isEmpty else {
        throw AuthError.emptyDisplayName
    }
    ```
  - Test Gate: Empty displayName throws error

### Task 3.4: Pass Role to UserService
- [ ] Update `UserService.createUser()` call in `signUp()`
  - Add role parameter to createUser call
  - Test Gate: Compiler error resolved after updating createUser signature

### Task 3.5: Add AuthError Case (if needed)
- [ ] Add `.emptyDisplayName` case to AuthError enum (if not already present)
  - Test Gate: Error case exists and is throwable

### Task 3.6: Update UserService.createUser() Signature
- [ ] Modify `createUser()` in `Psst/Psst/Services/UserService.swift`
  - BEFORE: `func createUser(id: String, email: String, displayName: String, photoURL: String?) async throws -> User`
  - AFTER: `func createUser(id: String, email: String, displayName: String, role: UserRole, photoURL: String?) async throws -> User`
  - Add role parameter
  - Test Gate: Method signature updated

### Task 3.7: Include Role in Firestore Document Creation
- [ ] Update Firestore document creation in `createUser()` to include role
  - Add role to document data: `"role": role.rawValue`
  - Test Gate: Firestore write includes role field

---

## 4. UI Components

### Task 4.1: Create Role Selection UI in SignUpView
- [ ] Open `Psst/Psst/Views/Authentication/SignUpView.swift`
  - Add state variable: `@State private var selectedRole: UserRole?`
  - Add state variable: `@State private var showRoleSelection = true`
  - Test Gate: State variables compile

### Task 4.2: Build Role Selection Screen
- [ ] Create role selection view in SignUpView body
  - Add conditional: `if showRoleSelection { ... } else { ... }`
  - Create two large buttons:
    - "Personal Trainer" → sets `selectedRole = .trainer`
    - "Client" → sets `selectedRole = .client`
  - Add title: "I am a..."
  - Add subtitle: "This helps us personalize your experience"
  - Test Gate: UI renders in preview, buttons tap correctly

### Task 4.3: Add Navigation from Role Selection to Form
- [ ] When role selected, set `showRoleSelection = false`
  - Add: `.onTapGesture { selectedRole = .trainer; showRoleSelection = false }`
  - Test Gate: Tapping button shows signup form

### Task 4.4: Update DisplayName Field Validation
- [ ] Make displayName field required (remove skip logic if present)
  - Update field placeholder: "Full Name (Required)"
  - Test Gate: Field shows required state

### Task 4.5: Update isFormValid Computed Property
- [ ] Modify `isFormValid` to check displayName is not empty
  - Add: `!displayName.trimmingCharacters(in: .whitespaces).isEmpty`
  - Add: `selectedRole != nil`
  - Test Gate: Sign Up button disabled until all fields valid

### Task 4.6: Add Error Handling for Empty DisplayName
- [ ] Show error state if user tries to submit with empty name
  - Add visual feedback (red border or text)
  - Test Gate: Error displays correctly

### Task 4.7: Update SignUp Button Action
- [ ] Pass `selectedRole` to AuthViewModel.signUp()
  - Unwrap `selectedRole` safely
  - Test Gate: Selected role passed to ViewModel

---

## 5. ViewModel Changes

### Task 5.1: Update AuthViewModel.signUp() Call
- [ ] Modify `signUp()` method in `Psst/Psst/ViewModels/AuthViewModel.swift`
  - Add `role: UserRole` parameter
  - Update AuthenticationService.signUp() call to include role
  - Test Gate: ViewModel passes role to service correctly

### Task 5.2: Handle Empty DisplayName Error
- [ ] Add error handling for `.emptyDisplayName` case
  - Display user-friendly message: "Display name is required"
  - Test Gate: Error shows in UI when displayName empty

---

## 6. Firestore Security Rules

### Task 6.1: Update /users Security Rules
- [ ] Open `Psst/firestore.rules`
  - Find `/users/{userId}` rule
  - Test Gate: Current rules loaded

### Task 6.2: Add Role Validation on Create
- [ ] Add role field validation in create rule
  - Add check:
    ```javascript
    allow create: if request.auth != null &&
                    request.auth.uid == userId &&
                    request.resource.data.role in ['trainer', 'client'];
    ```
  - Test Gate: Rules validate role is 'trainer' or 'client'

### Task 6.3: Prevent Role Changes on Update
- [ ] Add role immutability check in update rule
  - Add check:
    ```javascript
    allow update: if request.auth != null &&
                    request.auth.uid == userId &&
                    request.resource.data.role == resource.data.role;
    ```
  - Test Gate: Rules prevent role changes after creation

---

## 7. User-Centric Testing

### Happy Path Testing

- [ ] **Test 1: Trainer Signup**
  - Open app → Tap "Sign Up"
  - Select "Personal Trainer"
  - Fill form: displayName="John Trainer", email="john@test.com", password="test123"
  - Tap "Sign Up"
  - **Test Gate:** Account created, navigates to ChatListView
  - **Test Gate:** Check Firestore: `/users/{uid}` has `role: "trainer"`
  - **Pass:** No errors, role stored correctly

- [ ] **Test 2: Client Signup**
  - Repeat above with "Client" selection
  - **Test Gate:** Firestore has `role: "client"`
  - **Pass:** Client account created successfully

- [ ] **Test 3: Full Signup Flow**
  - Complete signup from role selection to main app
  - **Test Gate:** User sees ChatListView, profile loads
  - **Pass:** End-to-end flow works

### Edge Case Testing

- [ ] **Edge Case 1: Empty displayName**
  - Complete role selection
  - Leave displayName empty
  - Tap "Sign Up"
  - **Test Gate:** Form shows error "Display name is required"
  - **Test Gate:** Form does not submit
  - **Pass:** Validation prevents submission, error shown

- [ ] **Edge Case 2: Whitespace-only displayName**
  - Enter "   " (spaces only) in displayName
  - Tap "Sign Up"
  - **Test Gate:** Validation catches whitespace-only input
  - **Pass:** Error shown, no account created

- [ ] **Edge Case 3: No role selected** (should be impossible with UI flow)
  - If somehow role is nil, verify error handling
  - **Test Gate:** Sign Up button stays disabled
  - **Pass:** Cannot submit without role

- [ ] **Edge Case 4: Existing user without role logs in**
  - Create user in Firestore manually without role field
  - Log in with that account
  - **Test Gate:** App loads successfully, role defaults to `.trainer`
  - **Pass:** No crash, backward compatibility works

### Error Handling Testing

- [ ] **Offline Mode**
  - Enable airplane mode
  - Attempt signup
  - **Test Gate:** Shows "No internet connection" error
  - **Test Gate:** Signup does not proceed
  - **Pass:** Clear error, retry works when online

- [ ] **Invalid Email**
  - Complete role selection
  - Enter email: "notanemail"
  - **Test Gate:** Email validation shows error
  - **Pass:** Cannot proceed with invalid email

- [ ] **Weak Password**
  - Enter password: "123" (too short)
  - **Test Gate:** Password validation shows error "Password must be at least 6 characters"
  - **Pass:** Validation prevents weak password

- [ ] **Email Already Exists**
  - Attempt signup with existing email
  - **Test Gate:** Alert shows "This email is already in use"
  - **Pass:** Clear error message, can try different email

### Regression Testing (Critical for Brownfield)

- [ ] **Existing Feature 1: Login Still Works**
  - Use existing account to log in
  - **Test Gate:** Login flow unchanged, works correctly
  - **Pass:** No regressions in login

- [ ] **Existing Feature 2: User Profile Loading**
  - Log in → Navigate to Profile
  - **Test Gate:** Profile displays correctly
  - **Pass:** User data loads normally

- [ ] **Existing Feature 3: Chat Functionality**
  - Create new message in existing chat
  - **Test Gate:** Messages send/receive normally
  - **Pass:** Messaging unchanged

- [ ] **Existing Feature 4: Presence Tracking**
  - Check online/offline indicators
  - **Test Gate:** Presence still works
  - **Pass:** Real-time presence unchanged

- [ ] **Existing Feature 5: Image Upload**
  - Upload profile photo
  - **Test Gate:** Image upload works
  - **Pass:** Photo upload unchanged

### Final Checks

- [ ] **No Console Errors**
  - Run through all test scenarios
  - **Test Gate:** Console shows no errors or warnings
  - **Pass:** Clean console output

- [ ] **Performance Check**
  - Role selection feels instant (<50ms)
  - Signup form responsive
  - Account creation < 3 seconds
  - **Pass:** No performance degradation

---

## 8. Build & Deploy

### Task 8.1: Build Verification
- [ ] Clean build: ⌘+Shift+K, then ⌘+B
  - Test Gate: No compiler errors or warnings
  - Test Gate: Build succeeds

### Task 8.2: Run on Simulator
- [ ] Test on iOS Simulator (Vanes)
  - Test Gate: App launches successfully
  - Test Gate: Signup flow works end-to-end

### Task 8.3: Deploy Firestore Rules (Before Merging)
- [ ] Deploy updated security rules
  - Run: `firebase deploy --only firestore:rules`
  - Test Gate: Rules deployment succeeds
  - Test Gate: Create test account to verify rules work

---

## 9. Documentation & PR

### Task 9.1: Add Code Comments
- [ ] Add comments to UserRole enum explaining purpose
- [ ] Add comment to role field explaining immutability
- [ ] Add comment to backward compatibility decoder logic
  - Test Gate: Complex logic has clear comments

### Task 9.2: Update Architecture.md (Optional)
- [ ] Mark PR #006.5 brownfield analysis as "Implemented"
  - Test Gate: Architecture doc reflects current state

### Task 9.3: Create PR Description
- [ ] Write PR description with format:
  ```markdown
  ## PR #6.5: User Roles & Required Name

  **Type:** Feature (Brownfield - modifies existing authentication)
  **PRD:** docs/prds/pr-6.5-prd.md
  **TODO:** docs/todos/pr-6.5-todo.md

  ### Summary
  Adds user role distinction (trainer vs client) and enforces required displayName during signup. Foundation for PR #007 (Auto Client Profiles) and all AI features.

  ### Changes
  - ✅ Added UserRole enum (trainer, client)
  - ✅ Updated User model with role field
  - ✅ Modified signup flow to include role selection
  - ✅ Enforced required displayName (removed auto-generation)
  - ✅ Updated Firestore security rules
  - ✅ Backward compatibility for existing users (default to trainer)

  ### Testing Completed
  - ✅ Happy path: Trainer and client signup flows
  - ✅ Edge cases: Empty name, whitespace, no role
  - ✅ Error handling: Offline, invalid email, weak password
  - ✅ Regression: Login, profile, chat, presence unchanged
  - ✅ Backward compatibility: Existing users can log in

  ### Screenshots
  [Add screenshots of role selection screen and signup form]

  ### Firestore Security Rules
  Deployed before PR merge: ✅

  ### Breaking Changes
  - AuthenticationService.signUp() signature changed (added role parameter)
  - No impact on production users (new feature in signup flow)

  Generated with [Claude Code](https://claude.com/claude-code)

  Co-Authored-By: Claude <noreply@anthropic.com>
  ```
  - Test Gate: PR description is clear and complete

### Task 9.4: Verify with User Before Creating PR
- [ ] Show user PR is ready
- [ ] Confirm all tests pass
- [ ] Get approval to create PR
  - Test Gate: User approves

### Task 9.5: Create PR
- [ ] Create PR targeting `develop` branch
  - Run: `gh pr create --title "PR #6.5: User Roles & Required Name" --body "$(cat pr-description.md)"`
  - Test Gate: PR created successfully
  - Test Gate: PR targets develop, not main

---

## 10. Acceptance Gates Verification

Check every gate from PRD Section 12:

### Happy Path Gates
- [ ] Role selection screen appears before signup form
- [ ] Selected role is visible/confirmed in UI
- [ ] Signup form submits successfully with all fields
- [ ] User document in Firestore includes `role: "trainer"` or `role: "client"`
- [ ] User is logged in and sees main app

### Edge Case Gates
- [ ] Empty displayName shows validation error
- [ ] Form does not submit without displayName
- [ ] Cannot proceed without selecting role
- [ ] Existing users default to trainer role, no crashes

### Error Handling Gates
- [ ] Offline shows "No internet connection"
- [ ] Invalid email shows validation error
- [ ] Weak password shows error
- [ ] Email already exists shows clear message

### Regression Gates
- [ ] Login flow works unchanged
- [ ] Chat functionality unchanged
- [ ] Presence tracking works
- [ ] Profile loading works

### Performance Gates
- [ ] Role selection < 50ms response
- [ ] Signup form validation responsive
- [ ] Account creation < 3 seconds

---

## Copyable Checklist (for PR description)

```markdown
- [x] Branch created from develop
- [x] All TODO tasks completed
- [x] UserRole enum created
- [x] User model updated with role field
- [x] AuthenticationService.signUp() updated (added role, required displayName)
- [x] UserService.createUser() updated (added role)
- [x] SignUpView includes role selection UI
- [x] displayName field is required
- [x] Firestore security rules updated
- [x] Backward compatibility tested (existing users default to trainer)
- [x] Manual testing completed (happy path, edge cases, errors, regression)
- [x] All acceptance gates pass
- [x] Code follows Psst/agents/shared-standards.md patterns
- [x] No console warnings
- [x] Firestore rules deployed before PR merge
```

---

## Notes

- **CRITICAL:** This is a brownfield PR modifying core authentication code
- **BREAKING CHANGE:** AuthenticationService.signUp() signature changes - update all callers
- **BACKWARD COMPATIBILITY:** Must test existing users can still log in
- **DEPLOYMENT ORDER:** Deploy Firestore rules BEFORE merging PR
- **REGRESSION TESTING:** Verify all existing features work unchanged
- Break tasks into <30 min chunks
- Complete tasks sequentially (models → services → UI → testing)
- Check off after completion
- Document blockers immediately
- Reference `Psst/agents/shared-standards.md` for Swift/Firebase patterns

---

## Dependencies

**This PR unblocks:**
- PR #007 (Auto Client Profiles) - needs role field to identify trainers vs clients
- PR #011 (User Preferences) - needs role for trainer-specific settings
- PR #012 (YOLO Mode) - needs role for trainer-only auto-responses

**This PR depends on:**
- None (foundational change)

---

**Ready for Caleb to implement!** 🚀
