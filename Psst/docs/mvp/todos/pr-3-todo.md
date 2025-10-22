# PR-3 TODO — User Profile Model and Firestore Integration

**Branch**: `feat/pr-3-user-profile-model-and-firestore`
**Source PRD**: `Psst/docs/prds/pr-3-prd.md`
**Owner (Agent)**: Caleb (Building Agent)

---

## 0. Clarifying Questions & Assumptions

**Questions**: None outstanding (PRD approved)

**Assumptions (confirm in PR if needed)**:
  - Firebase SDK and Firestore initialized in PR #1
  - AuthenticationService exists and has signup flow from PR #2
  - User model exists at `Models/User.swift` (created in PR #2)
  - Firestore offline persistence enabled in Firebase configuration

---

## 1. Setup

- [ ] Create branch `feat/pr-3-user-profile-model-and-firestore` from develop
  - Acceptance: Branch created, no merge conflicts with develop

- [ ] Read PRD thoroughly (`Psst/docs/prds/pr-3-prd.md`)
  - Acceptance: Understand all requirements, acceptance gates, data model

- [ ] Read `Psst/agents/shared-standards.md` for patterns
  - Acceptance: Familiar with testing strategy (Swift Testing for services), performance targets, code quality standards

- [ ] Confirm environment and test runner work
  - Acceptance: Xcode opens project, builds successfully, existing tests run

---

## 2. Data Model & Rules

- [ ] Extend User model in `Models/User.swift` with Firestore support
  - Add `Codable` conformance
  - Add `CodingKeys` enum mapping `id` to `"uid"`
  - Add `toDictionary()` method for Firestore writes with server timestamps
  - Add initializer from Firebase Auth User
  - Test Gate: Model compiles, no warnings

- [ ] Define Firestore security rules for `users` collection
  - Create/update Firebase security rules file (or document for manual deployment)
  - Rules: Any authenticated user can read; users can only create/update their own document; no deletes
  - Test Gate: Rules documented and ready for deployment

- [ ] Deploy Firestore security rules (if using emulator or dev Firebase project)
  - Test Gate: Rules active in Firebase Console, test reads/writes manually

---

## 3. Service Layer

Implement deterministic service contracts from PRD Section 9.

- [ ] Create `Services/UserService.swift` file
  - Create class with singleton pattern (`static let shared`)
  - Add private properties: `db`, `usersCollection`, `userCache` dictionary
  - Test Gate: File compiles, no errors

- [ ] Implement `UserServiceError` enum
  - Add cases: invalidUserID, invalidEmail, userNotFound, createFailed, updateFailed, fetchFailed, validationFailed
  - Conform to `Error` and `LocalizedError`
  - Add `errorDescription` computed property
  - Test Gate: Enum compiles, error messages descriptive

- [ ] Implement `createUser(id:email:displayName:photoURL:)` method
  - Validate inputs: non-empty ID, email contains "@", displayName 1-50 chars
  - Create User object with current Date for createdAt/updatedAt
  - Call `db.collection(usersCollection).document(id).setData(user.toDictionary())`
  - Cache user in memory
  - Log success/failure
  - Test Gate: Method compiles, handles async throws

- [ ] Implement `getUser(id:)` method
  - Check cache first, return if found
  - Fetch from Firestore: `db.collection(usersCollection).document(id).getDocument()`
  - Throw `userNotFound` if document doesn't exist
  - Decode document using `document.data(as: User.self)`
  - Cache fetched user
  - Test Gate: Method compiles, handles async throws, cache logic correct

- [ ] Implement `getUsers(ids:)` batch fetch method
  - Loop through IDs, call `getUser(id:)` for each
  - Catch errors, log warnings, continue (don't fail entire batch)
  - Return array of successfully fetched users
  - Test Gate: Method compiles, handles partial failures gracefully

- [ ] Implement `observeUser(id:completion:)` real-time listener
  - Return `db.collection(usersCollection).document(id).addSnapshotListener { snapshot, error in ... }`
  - Handle errors via completion(.failure)
  - Decode snapshot, cache user, call completion(.success)
  - Test Gate: Returns ListenerRegistration, compiles correctly

- [ ] Implement `updateUser(id:data:)` method
  - Validate ID non-empty
  - Validate displayName if in data (1-50 chars)
  - Add `updatedAt: FieldValue.serverTimestamp()` to update data
  - Call `db.collection(usersCollection).document(id).updateData(updateData)`
  - Invalidate cache for this user ID
  - Log success/failure
  - Test Gate: Method compiles, validation works, cache invalidated

- [ ] Implement `clearCache()` helper method
  - Clear `userCache` dictionary
  - Test Gate: One-line method, compiles

---

## 4. Integration with AuthenticationService

- [ ] Modify `Services/AuthenticationService.swift` signup flow
  - After successful `Auth.auth().createUser()`, get the Firebase User object
  - Call `try await UserService.shared.createUser(id: user.uid, email: user.email ?? "", displayName: ...)`
  - Handle errors (log prominently, consider rethrowing or showing alert)
  - Test Gate: Signup flow calls UserService, compiles without errors

- [ ] Test integration manually (optional, before unit tests)
  - Run app, sign up new user
  - Check Firestore Console for new document in `users` collection
  - Test Gate: Document created with correct UID, fields populated

---

## 5. Tests (Swift Testing Framework)

Follow patterns from `Psst/agents/shared-standards.md` (Swift Testing for services).

- [ ] Create `PsstTests/Services/UserServiceTests.swift` file
  - Import Testing framework: `import Testing`
  - Import app module: `@testable import Psst`
  - Test Gate: File created, compiles

### Happy Path Tests

- [ ] Write test: Create user with valid data
  - Use `@Test("Create User With Valid Data Succeeds")` syntax
  - Call `UserService.shared.createUser(id: "test123", email: "alice@test.com", displayName: "Alice")`
  - Use `#expect(user.id == "test123")` for assertions
  - Verify Firestore document created (or mock Firestore for unit test)
  - Test Gate: Test passes, user object returned correctly

- [ ] Write test: Fetch existing user by ID
  - `@Test("Fetch Existing User By ID Returns User Object")`
  - Create user first, then fetch with `getUser(id:)`
  - `#expect(fetchedUser.email == "alice@test.com")`
  - Test Gate: Test passes, data correct

- [ ] Write test: Cache hit on second fetch
  - `@Test("Second Fetch Uses Cache And Returns Quickly")`
  - Fetch user once, measure time for second fetch
  - `#expect` cache hit (fast return)
  - Test Gate: Test passes, cache working

- [ ] Write test: Update user profile
  - `@Test("Update User Profile Persists Changes")`
  - Create user, update displayName, fetch again
  - `#expect(updatedUser.displayName == "Alice Smith")`
  - Test Gate: Test passes, update persisted

- [ ] Write test: Observe user changes (real-time listener)
  - `@Test("Observe User Fires On Document Changes")`
  - Set up listener, verify callback fires on create/update
  - Test Gate: Test passes, listener receives updates

- [ ] Write test: Batch fetch multiple users
  - `@Test("Batch Fetch Returns Array Of Users")`
  - Create 3 users, fetch with `getUsers(ids:)`
  - `#expect(users.count == 3)`
  - Test Gate: Test passes, all users returned

### Edge Case Tests

- [ ] Write test: Fetch non-existent user throws error
  - `@Test("Fetch Non-Existent User Throws UserNotFound")`
  - Use `#expect(throws: UserServiceError.userNotFound) { try await getUser(id: "fake") }`
  - Test Gate: Test passes, correct error thrown

- [ ] Write test: Create user with empty ID throws error
  - `@Test("Create User With Empty ID Throws InvalidUserID")`
  - `#expect(throws: UserServiceError.invalidUserID) { ... }`
  - Test Gate: Test passes

- [ ] Write test: Create user with invalid email throws error
  - `@Test("Create User With Invalid Email Throws InvalidEmail")`
  - Try email without "@"
  - Test Gate: Test passes, validation works

- [ ] Write test: Create user with empty displayName throws error
  - `@Test("Create User With Empty DisplayName Throws ValidationFailed")`
  - Test Gate: Test passes

- [ ] Write test: Create user with displayName > 50 chars throws error
  - `@Test("Create User With Long DisplayName Throws ValidationFailed")`
  - Try 51-character string
  - Test Gate: Test passes

- [ ] Write test: Update user with invalid data throws error
  - `@Test("Update User With Invalid Data Throws ValidationFailed")`
  - Try empty displayName in update
  - Test Gate: Test passes, no partial writes

### Offline Behavior Tests (if using Firebase emulator)

- [ ] Write test: Fetch user while offline returns cached data
  - `@Test("Fetch User Offline Returns Cached Data")`
  - Fetch user online, disconnect, fetch again
  - `#expect` cached data returned
  - Test Gate: Test passes (or skip if emulator not set up)

- [ ] Write test: Update user while offline queues write
  - `@Test("Update User Offline Queues Write")`
  - Update while offline, reconnect, verify sync
  - Test Gate: Test passes (or skip if emulator not set up)

### Cleanup

- [ ] Add test cleanup/teardown if needed
  - Delete test users from Firestore after tests
  - Clear UserService cache between tests
  - Test Gate: Tests don't pollute database, run independently

---

## 6. Performance Verification

Verify targets from `Psst/agents/shared-standards.md`.

- [ ] Measure user document creation time
  - Add timing logs: `let start = Date(); ... ; print("Created in \(Date().timeIntervalSince(start))s")`
  - Run multiple creates, verify < 300ms average
  - Test Gate: Latency meets target (log evidence in PR)

- [ ] Measure fetch user by ID time (network)
  - Time `getUser()` call with empty cache
  - Test Gate: < 200ms average

- [ ] Measure fetch user by ID time (cache hit)
  - Time second `getUser()` call
  - Test Gate: < 50ms

- [ ] Measure update user time
  - Time `updateUser()` call
  - Test Gate: < 300ms average

---

## 7. Acceptance Gates Verification

Check every gate from PRD Section 12:

- [ ] Gate: User signs up → Firestore document created at `users/{uid}` within 300ms
  - Test: Sign up new user, check Firestore Console

- [ ] Gate: `getUser(id:)` with valid ID → Returns User in < 200ms
  - Test: Call method, measure time

- [ ] Gate: `getUser(id:)` with non-existent ID → Throws `userNotFound`
  - Test: Unit test covers this

- [ ] Gate: Network unavailable → Cached data returned in < 50ms
  - Test: Offline test or manual verification

- [ ] Gate: `updateUser()` → Changes sync across devices in < 100ms
  - Test: Manual multi-device test or deferred to Phase 4

- [ ] Gate: Invalid data → Throws `validationFailed`, no partial writes
  - Test: Unit tests cover validation

- [ ] Gate: Firestore error → Logged with context, descriptive error thrown
  - Test: Check logs during error scenarios

---

## 8. Documentation & Code Quality

- [ ] Add inline code comments for complex logic
  - Document `toDictionary()` method (server timestamp usage)
  - Document `observeUser()` listener lifecycle
  - Document validation rules at top of UserService
  - Test Gate: Code readable, comments explain "why" not "what"

- [ ] Verify code follows `Psst/agents/shared-standards.md`
  - Proper Swift types (no `Any` except in toDictionary for nil handling)
  - Function parameters explicitly typed
  - Meaningful variable names
  - Test Gate: Code review passes

- [ ] Run Xcode linter / fix warnings
  - Test Gate: Zero warnings in modified files

- [ ] Test all acceptance gates from PRD Section 13 (Definition of Done)
  - Test Gate: All checkboxes can be marked complete

---

## 9. Manual Testing & Validation

- [ ] Test signup creates Firestore document
  - Sign up new user in app
  - Open Firebase Console → Firestore → `users` collection
  - Verify document exists with correct UID, email, displayName
  - Test Gate: Document created successfully

- [ ] Test fetch user by ID
  - Call `UserService.shared.getUser(id: "known-id")` from test code
  - Verify correct User object returned
  - Test Gate: Fetch works

- [ ] Test update user profile
  - Call `updateUser(id: "test-id", data: ["displayName": "New Name"])`
  - Refresh Firestore Console, verify update
  - Test Gate: Update persisted

- [ ] Test offline persistence
  - Fetch user while online
  - Disable network (Airplane mode)
  - Restart app, fetch same user
  - Test Gate: Cached data loads instantly

- [ ] Test security rules
  - Attempt to update another user's document (should fail)
  - Verify authenticated user can read any user document
  - Test Gate: Security rules enforced correctly

---

## 10. PR Preparation

- [ ] Run all tests (unit tests must pass)
  - `Cmd+U` in Xcode or `xcodebuild test`
  - Test Gate: All tests green, zero failures

- [ ] Verify no console warnings during normal operations
  - Run app, sign up, fetch users
  - Check Xcode console for warnings
  - Test Gate: Clean console output

- [ ] Create PR description using format from `Psst/agents/caleb-agent.md`
  - Include PRD link, TODO link
  - List changes: files created/modified
  - Testing evidence: test pass screenshots, Firestore Console screenshots
  - Acceptance gates checklist
  - Test Gate: PR description complete and detailed

- [ ] Verify with user before creating PR
  - Confirm all work complete, gates pass
  - Test Gate: User approval to proceed

- [ ] Open PR targeting `develop` branch (NOT `main`)
  - Title: `feat: User Profile Model and Firestore Integration (PR #3)`
  - Link PRD and TODO in description
  - Test Gate: PR created, CI passes (if configured)

---

## Copyable Checklist (for PR description)

```markdown
## PR #3: User Profile Model and Firestore Integration

**PRD**: [Psst/docs/prds/pr-3-prd.md](../prds/pr-3-prd.md)
**TODO**: [Psst/docs/todos/pr-3-todo.md](../todos/pr-3-todo.md)

### Changes
- [x] Extended `Models/User.swift` with Firestore support (Codable, CodingKeys, toDictionary)
- [x] Created `Services/UserService.swift` with CRUD operations
- [x] Integrated with `AuthenticationService.swift` signup flow
- [x] Deployed Firestore security rules for `users` collection
- [x] Created unit tests using Swift Testing framework (`PsstTests/Services/UserServiceTests.swift`)

### Testing
- [x] Service tests pass (Swift Testing: `@Test("Display Name")` syntax)
  - Happy path: create, read, update, observe, batch fetch
  - Edge cases: validation errors, not found, invalid inputs
  - Offline behavior: cache hit, offline writes
- [x] Manual testing: signup creates Firestore document
- [x] Performance verified: Create < 300ms, Fetch < 200ms, Update < 300ms
- [x] Security rules tested: users can read all, write only own

### Acceptance Gates
- [x] User signup → Firestore document created at `users/{uid}` in < 300ms
- [x] `getUser(id:)` → Returns User in < 200ms (network) / < 50ms (cache)
- [x] `getUser(id:)` with invalid ID → Throws `userNotFound`
- [x] `updateUser()` → Changes persist, sync across devices
- [x] Invalid data → Throws `validationFailed`, no partial writes
- [x] Firestore errors → Logged with context, descriptive error thrown

### Code Quality
- [x] Follows `Psst/agents/shared-standards.md` patterns
- [x] Zero console warnings
- [x] Inline comments for complex logic
- [x] All function parameters explicitly typed
- [x] Tests use Swift Testing framework with readable display names

### Screenshots
- [ ] Xcode test results (all tests passing)
- [ ] Firestore Console showing `users` collection with test documents
- [ ] Performance logs showing latency measurements
```

---

## Notes

- Break tasks into < 30 min chunks (if task too large, split it)
- Complete tasks sequentially (check off after completion)
- Document blockers immediately in PR or TODO
- Reference `Psst/agents/shared-standards.md` for common patterns
- **Deferred to Phase 4 (PR #25)**: Full integration tests (Auth + Firestore flow), multi-device sync with 3+ devices, comprehensive security rule tests
