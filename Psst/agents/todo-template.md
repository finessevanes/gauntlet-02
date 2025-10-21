# PR-{N} TODO — [Feature Name]

**Branch**: `feat/pr-{n}-{feature-slug}`  
**Source PRD**: `Psst/docs/prds/pr-{n}-prd.md`  
**Owner (Agent)**: [name]

---

## 0. Clarifying Questions & Assumptions

- Questions: [unanswered items from PRD]
- Assumptions (confirm in PR if needed):
  - [assumption 1]
  - [assumption 2]

---

## 1. Setup

- [ ] Create branch `feat/pr-{n}-{feature-slug}` from develop
- [ ] Read PRD thoroughly
- [ ] Read `Psst/agents/shared-standards.md` for patterns
- [ ] Confirm environment and test runner work

---

## 2. Service Layer

Implement deterministic service contracts from PRD.

- [ ] Implement [service method name]
  - Test Gate: Unit test passes for valid/invalid cases
- [ ] Implement [service method name]
  - Test Gate: Unit test passes
- [ ] Add validation logic
  - Test Gate: Edge cases handled correctly

---

## 3. Data Model & Rules

- [ ] Define new types/structs in Swift
- [ ] Update Firestore schema (if needed)
- [ ] Add Firebase security rules
  - Test Gate: Reads/writes succeed with rules applied

---

## 4. UI Components

Create/modify SwiftUI views per PRD Section 10.

- [ ] Create/modify [View name]
  - Test Gate: SwiftUI Preview renders; zero console errors
- [ ] Wire up state management (@State, @StateObject, etc.)
  - Test Gate: Interaction updates state correctly
- [ ] Add loading/error/empty states
  - Test Gate: All states render correctly

---

## 5. Integration & Real-Time

Reference requirements from `Psst/agents/shared-standards.md`.

- [ ] Firebase service integration
  - Test Gate: Auth/Firestore/FCM configured
- [ ] Real-time listeners working
  - Test Gate: Data syncs across devices <100ms
- [ ] Offline persistence
  - Test Gate: App restarts work offline with cached data
- [ ] Presence/status indicators (if applicable)
  - Test Gate: Online/offline states reflect correctly

---

## 6. Tests

Follow patterns from `Psst/agents/shared-standards.md` and `Psst/agents/test-template.md`.

- [ ] Unit Tests (XCTest)
  - Path: `PsstTests/{Feature}Tests.swift`
  - Test Gate: Service logic validated, edge cases covered
  
- [ ] UI Tests (XCUITest)
  - Path: `PsstUITests/{Feature}UITests.swift`
  - Test Gate: User flows succeed, navigation works
  
- [ ] Service Tests (if applicable)
  - Path: `PsstTests/Services/{ServiceName}Tests.swift`
  - Test Gate: Firebase operations tested
  
- [ ] Multi-device sync test
  - Test Gate: Use pattern from Psst/agents/shared-standards.md
  
- [ ] Visual states verification
  - Test Gate: Empty, loading, error, success render correctly

---

## 7. Performance

Verify targets from `Psst/agents/shared-standards.md`.

- [ ] App load time < 2-3 seconds
  - Test Gate: Cold start to interactive measured
- [ ] Message latency < 100ms
  - Test Gate: Firebase calls measured
- [ ] Smooth 60fps scrolling (100+ items)
  - Test Gate: Use LazyVStack, verify with instruments

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
- [ ] Services implemented + unit tests (XCTest)
- [ ] SwiftUI views implemented with state management
- [ ] Firebase integration tested (real-time sync, offline)
- [ ] UI tests pass (XCUITest)
- [ ] Multi-device sync verified (<100ms)
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
