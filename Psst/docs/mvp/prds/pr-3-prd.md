# PRD: User Profile Model and Firestore Integration

**Feature**: user-profile-model-and-firestore

**Version**: 1.0

**Status**: Ready for Development

**Agent**: Pam

**Target Release**: Phase 1 - Foundation

**Links**: [PR Brief](../pr-briefs.md#pr-3-user-profile-model-and-firestore) | [TODO](../todos/pr-3-todo.md)

---

## 1. Summary

Extend the User model to persist in Firestore's `users` collection and implement UserService to handle CRUD operations for user profiles. This establishes the user data layer that chat features, contacts, and presence will depend on.

---

## 2. Problem & Goals

**Problem**: After authentication (PR #2), users exist only in Firebase Auth. We need persistent profiles in Firestore so other users can discover profiles, display names in chats, and update display names/photos.

**Why now**: This is a Phase 1 foundation PR. PR #5 (chat models), PR #6 (conversation list), and PR #12 (start new chat) all require fetching user profile data from Firestore.

**Goals** (ordered, measurable):
  - [ ] G1 — `users` collection in Firestore with schema: uid, email, displayName, photoURL, createdAt, updatedAt
  - [ ] G2 — UserService implements CRUD operations with < 300ms latency
  - [ ] G3 — User documents auto-created on signup within 300ms
  - [ ] G4 — Profile data fetchable by ID in < 200ms with offline cache support

---

## 3. Non-Goals / Out of Scope

- [ ] Not implementing profile editing UI (PR #21)
- [ ] Not implementing photo upload to Firebase Storage (PR #21)
- [ ] Not implementing contact list or search UI (PR #12, PR #22)
- [ ] Not implementing user presence/online status (PR #15 uses Realtime Database)
- [ ] Not implementing blocking, privacy settings, email verification (future)

---

## 4. Success Metrics

Reference `Psst/agents/shared-standards.md` for metric templates:

**User-visible**:
- Profile data loads in < 500ms
- Profile updates sync across devices in < 100ms

**System**:
- User document creation: < 300ms after signup
- Fetch user by ID: < 200ms (network), < 50ms (cache)
- App load time: < 2-3 seconds (includes user data fetch)

**Quality**:
- 0 blocking bugs, all gates pass, crash-free >99%
- Zero data inconsistencies between Auth UID and Firestore document ID

---

## 5. Users & Stories

- As a **new user**, I want my profile auto-created in Firestore when I sign up so that other users can find me
- As a **user**, I want my profile updates to sync instantly across all my devices
- As a **developer**, I want a clean UserService API to fetch user data for chat features
- As a **chat participant**, I want to see accurate profile info for other users

---

## 6. Experience Specification (UX)

**Entry points and flows**:
- **Automatic**: User signs up → AuthenticationService creates account → UserService creates Firestore document
- **Developer API**: Call `UserService.shared.getUser(id:)` to fetch profiles
- **Developer API**: Call `UserService.shared.updateUser(id:data:)` to update profiles

**Visual behavior**:
- No direct UI in this PR (service layer only)
- Future UIs will display user data fetched from this service

**Loading/disabled/error states**:
- Service throws typed errors: `userNotFound`, `createFailed`, `validationFailed`
- Offline: Cached data returned instantly, writes queued

**Performance**:
- Create < 300ms, Fetch < 200ms, Update < 300ms
- All operations async, no UI blocking

---

## 7. Functional Requirements (Must/Should)

**MUST**:
- MUST extend User model with Codable support and Firestore field mapping
- MUST create `users` collection in Firestore
- MUST implement UserService with methods:
  - `createUser(id:email:displayName:photoURL:)` — Create user document
  - `getUser(id:)` — Fetch user by ID with cache support
  - `updateUser(id:data:)` — Update profile fields
  - `observeUser(id:completion:)` — Real-time listener
  - `getUsers(ids:)` — Batch fetch (optional but recommended)
- MUST auto-create user document on signup via AuthenticationService
- MUST validate data: non-empty ID, valid email, displayName 1-50 chars
- MUST use server timestamps for createdAt/updatedAt

**SHOULD**:
- SHOULD cache fetched users in memory
- SHOULD include comprehensive error logging

**Acceptance gates**:
- [Gate] User signs up → Document created at `users/{uid}` in < 300ms
- [Gate] `getUser(id:)` returns User in < 200ms or throws `userNotFound`
- [Gate] Network unavailable → Cached data returned from Firestore offline persistence
- [Gate] `updateUser()` → Changes sync across devices in < 100ms
- [Gate] Invalid data → Throws `validationFailed`, no partial writes

---

## 8. Data Model

### Firestore Schema

**Collection**: `users`
**Document ID**: `{uid}` (matches Firebase Auth UID)

**Fields**:
```swift
{
  uid: String,              // Matches Firebase Auth UID
  email: String,            // User's email
  displayName: String,      // Display name (default: email prefix)
  photoURL: String?,        // Profile photo URL (optional)
  createdAt: Timestamp,     // FieldValue.serverTimestamp()
  updatedAt: Timestamp      // FieldValue.serverTimestamp()
}
```

### Swift Model (extend existing Models/User.swift)

```swift
struct User: Identifiable, Codable, Equatable {
    let id: String
    let email: String
    var displayName: String
    var photoURL: String?
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id = "uid"
        case email, displayName, photoURL, createdAt, updatedAt
    }

    func toDictionary() -> [String: Any] {
        return [
            "uid": id,
            "email": email,
            "displayName": displayName,
            "photoURL": photoURL as Any,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": FieldValue.serverTimestamp()
        ]
    }
}
```

### Validation Rules

- **uid**: Non-empty, matches Firebase Auth UID
- **email**: Valid email format (enforced by Auth)
- **displayName**: 1-50 characters
- **photoURL**: Optional, valid URL format
- **createdAt/updatedAt**: Auto-set server timestamps

### Firestore Security Rules

```javascript
match /users/{userId} {
  allow read: if request.auth != null;
  allow create, update: if request.auth != null && request.auth.uid == userId;
  allow delete: if false;
}
```

---

## 9. API / Service Contracts

```swift
class UserService {
    static let shared = UserService()

    func createUser(id: String, email: String, displayName: String, photoURL: String? = nil) async throws -> User
    func getUser(id: String) async throws -> User
    func getUsers(ids: [String]) async throws -> [User]
    func updateUser(id: String, data: [String: Any]) async throws
    func observeUser(id: String, completion: @escaping (Result<User, Error>) -> Void) -> ListenerRegistration
    func clearCache()
}

enum UserServiceError: Error, LocalizedError {
    case invalidUserID, invalidEmail, userNotFound
    case createFailed(Error), updateFailed(Error), fetchFailed(Error)
    case validationFailed(String)
}
```

**Pre/post-conditions**:
- Pre: Firebase and Firestore initialized (PR #1)
- Post: User data persisted in `users/{uid}`, cached in memory

**Error handling**:
- All methods use `async throws`
- Errors logged with context, thrown to caller
- No partial writes on validation failures

---

## 10. UI Components to Create/Modify

**Files to Create**:
- `Services/UserService.swift` — Firestore CRUD for user profiles

**Files to Modify**:
- `Models/User.swift` — Extend with Codable, toDictionary()
- `Services/AuthenticationService.swift` — Call UserService.createUser() on signup

**No SwiftUI views in this PR**.

---

## 11. Integration Points

- **Firebase Authentication**: Use Auth UID as Firestore document ID
- **Firestore Database**: `users` collection with real-time listeners
- **State management**: UserService provides data; ViewModels will observe in future PRs

**Integration Flow**:
1. User signs up → AuthenticationService creates Auth account
2. AuthenticationService calls UserService.createUser() → Firestore document created
3. Future features call UserService.getUser(id:) to fetch profiles

---

## 12. Test Plan & Acceptance Gates

Reference testing standards from `Psst/agents/shared-standards.md`.

**Testing Framework**: Swift Testing for service tests (`@Test("Display Name")` with `#expect`)

### Happy Path
- [ ] Create user with valid data
  - [ ] Gate: Returns User object, document exists at `users/{uid}` in < 300ms
- [ ] Fetch existing user by ID
  - [ ] Gate: Returns User in < 200ms (network), < 50ms (cache hit)
- [ ] Update user profile
  - [ ] Gate: Changes persist, updatedAt refreshed
- [ ] Observe user changes
  - [ ] Gate: Listener fires on updates within 100ms
- [ ] Batch fetch multiple users
  - [ ] Gate: Returns array of Users, handles invalid IDs gracefully

### Edge Cases
- [ ] Fetch non-existent user
  - [ ] Gate: Throws `UserServiceError.userNotFound`
- [ ] Create user with empty ID/email/displayName
  - [ ] Gate: Throws `invalidUserID`, `invalidEmail`, or `validationFailed`
- [ ] Create user with displayName > 50 chars
  - [ ] Gate: Throws `validationFailed`
- [ ] Update user with invalid data
  - [ ] Gate: Throws validation error, no partial writes

### Offline Behavior
- [ ] Fetch user while offline (cached)
  - [ ] Gate: Returns cached data in < 50ms
- [ ] Update user while offline
  - [ ] Gate: Write queued, syncs on reconnect

### Performance (see shared-standards.md)
- [ ] User creation < 300ms
- [ ] Fetch by ID < 200ms (network), < 50ms (cache)
- [ ] Update < 300ms

### Security Rules
- [ ] Authenticated user can read any user document
- [ ] User can create/update only their own document
- [ ] Unauthenticated access denied

---

## 13. Definition of Done

See standards in `Psst/agents/shared-standards.md`:
- [ ] User model extended with Firestore support
- [ ] UserService implemented with all CRUD methods
- [ ] Service tests created (Swift Testing: `@Test("Display Name")`, `#expect`)
- [ ] Integration with AuthenticationService (create user on signup)
- [ ] Firestore security rules deployed
- [ ] All acceptance gates pass
- [ ] No console warnings
- [ ] Code follows shared standards
- [ ] PR merged to `develop` branch

**Note**: Full integration tests deferred to Phase 4 (PR #25). See `/Psst/docs/backlog.md`.

---

## 14. Risks & Mitigations

- **Risk**: Auth succeeds but Firestore creation fails → **Mitigation**: Retry logic, prominent error logging
- **Risk**: Stale cache data → **Mitigation**: Invalidate cache on updates, use `observeUser()` for real-time UIs
- **Risk**: Security rules too permissive → **Mitigation**: Conservative rules, test with emulator
- **Risk**: Performance degradation with large user base → **Mitigation**: Memory cache, batch operations, pagination in future

---

## 15. Rollout & Telemetry

**Feature flag**: N/A (core infrastructure)

**Metrics**:
- Firestore Console: Monitor `users` collection read/write counts
- User creation success rate (Auth signups vs Firestore documents)
- Cache hit rate, fetch latency

**Manual validation**:
1. Sign up new user → Verify document in Firestore Console at `users/{uid}`
2. Update profile → Verify changes in Firestore
3. Restart app offline → Verify cached data loads

---

## 16. Open Questions

- **Q1**: Hard delete users from Firestore? → Defer to future
- **Q2**: Unique display names? → No, allow duplicates (identified by UID)
- **Q3**: Additional profile fields (bio, phone)? → Start minimal, extend in PR #21
- **Q4**: Cache TTL? → Indefinite cache, invalidate on updates

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future:
- [ ] Profile photo upload to Storage (PR #21)
- [ ] Profile editing UI (PR #21)
- [ ] User search functionality (PR #22)
- [ ] Blocking/privacy controls (future)
- [ ] Email verification (future)
- [ ] Account deletion (future)

**Deferred Testing** (tracked in `/Psst/docs/backlog.md`):
- [ ] Full integration tests (Auth → Firestore flow, race conditions)
- [ ] Multi-device sync with 3+ devices
- [ ] Comprehensive security rules testing

---

## Preflight Questionnaire

1. **Smallest end-to-end outcome?** User signs up → Profile created in Firestore → Other features can fetch user data
2. **Primary user?** Developers (service layer consumers)
3. **Must-have vs nice-to-have?** Must: create/fetch/update user, schema. Nice: cache, batch fetch, listeners
4. **Real-time requirements?** Profile updates sync in < 100ms via Firestore listeners
5. **Performance constraints?** Create < 300ms, Fetch < 200ms, Update < 300ms
6. **Error cases?** User not found, invalid data, network errors, permission denied
7. **Data model changes?** Extend User model with Codable; create `users` collection
8. **Service APIs?** createUser, getUser, getUsers, updateUser, observeUser
9. **UI entry points?** None (service layer only)
10. **Security?** Any authenticated user reads; users only write their own document
11. **Dependencies?** PR #1 (Firebase), PR #2 (Auth)
12. **Rollout?** Direct rollout, verify via Firestore Console
13. **Out of scope?** Profile UI, photo uploads, search, blocking, verification

---

## Authoring Notes

- ✅ Service layer only — no UI components
- ✅ Extend existing User model (don't create from scratch)
- ✅ Integration with AuthenticationService is critical (call createUser on signup)
- ✅ Use Swift Testing framework (`@Test("Display Name")` with `#expect`)
- ✅ Test offline scenarios thoroughly
- ✅ Deploy and test Firestore security rules
- ✅ All acceptance gates are measurable with specific latency targets
