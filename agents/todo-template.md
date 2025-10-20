# PR-N TODO — [Feature Name]

**Branch**: `feature/pr-n-[slug]`  
**Source PRD**: [link to PRD]  
**Owner (Agent)**: [name]

---

## 0. Clarifying Questions & Assumptions

- Questions: [unanswered items from PRD preflight]
- Assumptions (unblock coding now; confirm in PR):
  - [assumption 1]
  - [assumption 2]

---

## 1. Repo Prep

- [ ] Create branch `feature/pr-n-[slug]`
- [ ] Confirm env, emulators, and test runner

---

## 2. Service Layer (deterministic contracts)

- [ ] Implement [service method]
  - Test Gate: unit test passes for valid/invalid cases
- [ ] Implement [service method]
  - Test Gate: unit test passes

---

## 3. Data Model & Rules

- [ ] Update schema/docs
  - Test Gate: reads/writes succeed with rules

---

## 4. UI Components (SwiftUI)

- [ ] Create/modify [View/component]
  - Test Gate: SwiftUI Preview renders; zero console errors
- [ ] Wire up state management (@State, @StateObject, @EnvironmentObject)
  - Test Gate: Interaction updates state correctly

---

## 5. Integration & Realtime

- [ ] Firebase service integration
  - Test Gate: Auth/Firestore/FCM configured and connected
- [ ] Real-time listeners working
  - Test Gate: Data syncs across devices/sessions
- [ ] Offline persistence functioning
  - Test Gate: App restarts work offline with cached data
- [ ] Presence/status indicators updating
  - Test Gate: Online/offline states reflect correctly

---

## 6. Tests

- a) Unit Tests (XCTest)
  - [ ] Service layer logic validated
  - [ ] Edge cases and error handling covered
- b) UI Tests (XCUITest)
  - [ ] User interaction flows succeed
  - [ ] Navigation and gestures work
- c) Visual States
  - [ ] Empty, loading, error, success states render correctly
- d) Real-time & Offline
  - [ ] Messages sync in real-time
  - [ ] Offline mode persists data correctly

---

## 7. Performance

- [ ] App load time: < 2-3 seconds
  - Test Gate: Cold start to interactive UI measured
- [ ] Network latency: < 100ms
  - Test Gate: Firebase calls and message delivery measured

---

## 8. Docs & PR

- [ ] Update `PR-N-todo.md` with gates results
- [ ] Write PR description summary (use this structure):
  - Goal and scope (from PRD)
  - Files changed and rationale
  - Test steps (happy path, edge cases, multi-user, perf)
  - Known limitations and follow-ups
  - Links: PRD, TODO, designs
- [ ] Keep PR description updated after each failed test until all gates pass
- [ ] Open PR with checklist copied here

---

## Copyable Checklist (for PR description)

- [ ] Branch created
- [ ] Services implemented + unit tests (XCTest)
- [ ] SwiftUI views implemented with state management
- [ ] Firebase integration tested (realtime sync, offline persistence)
- [ ] UI tests pass (XCUITest)
- [ ] Performance targets met (load time < 2-3s, latency < 100ms)
- [ ] Docs updated