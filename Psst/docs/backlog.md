# Technical Backlog

This document tracks deferred items and "we'll get back to this" tasks that are intentionally postponed to maintain development velocity.

**Last Updated**: October 21, 2025

---

## 🧪 Deferred Testing

### Integration Testing (End-to-End)
**Deferred from**: PR #3  
**Priority**: High  
**Target**: Phase 4 (PR #25 - Testing & QA)

**Description:**
Full integration tests that span multiple services and Firebase integrations. These are critical for production readiness but deferred during feature development to maintain velocity.

**Specific Items:**
- [ ] **Auth + Firestore Integration** (PR #3)
  - Test signup flow creates both Firebase Auth account AND Firestore user document
  - Verify Auth UID matches Firestore document ID
  - Verify email from Auth matches Firestore email field
  - Test race conditions (what if Firestore write fails but Auth succeeds?)

- [ ] **End-to-End Multi-Device Sync** (PR #3)
  - Device A updates profile → Device B sees update in < 100ms
  - Test with 3+ simultaneous devices
  - Verify offline queueing and sync on reconnect

- [ ] **Security Rules Comprehensive Testing** (PR #3)
  - Test all Firestore security rules with different user contexts
  - Verify unauthorized users cannot access restricted data
  - Test edge cases (deleted users, malformed data, etc.)

- [ ] **UserService Integration Tests with Firebase Emulator** (PR #3)
  - Current tests only validate error types, model encoding, and input validation
  - Need real Firestore integration tests with emulator:
    - createUser() actually writes to Firestore and returns correct data
    - getUser() fetches from Firestore and caches correctly
    - updateUser() persists changes and invalidates cache
    - observeUser() real-time listener receives updates
    - getUsers() batch fetch handles partial failures
    - Offline persistence returns cached data
    - Performance metrics (< 300ms create, < 200ms fetch, < 50ms cache hit)
  - Setup: Configure Firebase emulator suite
  - Use Swift Testing framework with emulator connection

**Notes:**
- These tests require Firebase emulator setup or dedicated test Firebase project
- Should use XCTest for UI-driven integration tests
- Consider using Firebase Test Lab for multi-device testing
- Document test data setup and teardown procedures

---

## 🎯 How to Use This Backlog

### Adding Items
When deferring work during a PR:
1. Add item to appropriate section with clear description
2. Reference source PR (e.g., "Deferred from PR #3")
3. Assign priority (High/Medium/Low)
4. Add to relevant PRD's "Out-of-Scope" section

### Completing Items
- Move completed items to "Done" section below
- Archive items if no longer relevant

---

## ✅ Done (Completed Backlog Items)

*(Items will move here when completed)*
