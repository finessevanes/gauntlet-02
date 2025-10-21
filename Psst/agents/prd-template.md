# PRD: [Feature Name]

**Feature**: [short name]

**Version**: 1.0

**Status**: Draft | Ready for Development | In Progress | Shipped

**Agent**: [Phillip/Caleb]

**Target Release**: [date or sprint]

**Links**: [PR Brief], [TODO], [Designs], [Tracking Issue]

---

## 1. Summary

One or two sentences: problem and outcome. Focus on minimum vertical slice that delivers user value independently.

---

## 2. Problem & Goals

- What user problem are we solving?
- Why now?
- Goals (ordered, measurable):
  - [ ] G1 — [clear goal]
  - [ ] G2 — [clear goal]

---

## 3. Non-Goals / Out of Scope

Call out what's intentionally excluded to avoid scope creep.

- [ ] Not doing X (why)
- [ ] Not doing Y (why)

---

## 4. Success Metrics

Reference `Psst/agents/shared-standards.md` for metric templates:
- User-visible: [time to complete, taps, flow completion]
- System: [See performance requirements in shared-standards.md]
- Quality: [0 blocking bugs, all gates pass, crash-free >99%]

---

## 5. Users & Stories

- As a [role], I want [action] so that [outcome].
- As a [collaborator], I want [real-time effect] so that [coordination].

---

## 6. Experience Specification (UX)

- Entry points and flows: [where in app, how triggered]
- Visual behavior: [buttons, gestures, empty states, animations]
- Loading/disabled/error states: [what user sees]
- Performance: See targets in `Psst/agents/shared-standards.md`

---

## 7. Functional Requirements (Must/Should)

- MUST: [deterministic service-layer method for each action]
- MUST: [real-time delivery per shared-standards.md]
- MUST: [offline persistence and queue]
- SHOULD: [optimistic UI]

Acceptance gates per requirement:
- [Gate] When User A sends message → User B sees in <100ms
- [Gate] Offline: messages queue and deliver on reconnect
- [Gate] Error case: invalid input shows alert; no partial writes

---

## 8. Data Model

Describe new/changed Firestore collections, schemas, invariants.

Reference examples in `Psst/agents/shared-standards.md` for common patterns.

```swift
// Define your specific data model here
```

- Validation rules: [Firebase security rules, field constraints]
- Indexing/queries: [Firestore listeners, composite indexes]

---

## 9. API / Service Contracts

Specify concrete service layer methods. Reference examples in `Psst/agents/shared-standards.md`.

```swift
// Example:
func sendMessage(chatID: String, text: String) async throws -> String
```

- Pre/post-conditions for each method
- Error handling strategy
- Parameters and types
- Return values

---

## 10. UI Components to Create/Modify

List SwiftUI views/files with one-line purpose each.

- `Views/[Name].swift` — [purpose]
- `Components/[Name].swift` — [purpose]
- `Services/[Name].swift` — [purpose]

---

## 11. Integration Points

- Firebase Authentication
- Firestore
- Firebase Realtime Database (presence)
- FCM (push notifications)
- State management (SwiftUI patterns)

---

## 12. Test Plan & Acceptance Gates

Define BEFORE implementation. Use checkboxes.

Reference testing standards from `Psst/agents/shared-standards.md`.

- Happy Path
  - [ ] User action succeeds
  - [ ] Gate: [specific measurable outcome]
  
- Edge Cases
  - [ ] Empty/invalid input handled
  - [ ] Offline behavior correct
  
- Multi-User
  - [ ] Real-time sync <100ms
  - [ ] Concurrent actions handled
  
- Performance (see shared-standards.md)
  - [ ] App load < 2-3s
  - [ ] Smooth 60fps scrolling
  - [ ] Message latency < 100ms

---

## 13. Definition of Done

See standards in `Psst/agents/shared-standards.md`:
- [ ] Service methods implemented + unit tests (XCTest)
- [ ] SwiftUI views with all states
- [ ] Real-time sync verified across 2+ devices
- [ ] Offline persistence tested
- [ ] All acceptance gates pass
- [ ] Docs updated

---

## 14. Risks & Mitigations

- Risk: [area] → Mitigation: [approach]
- Risk: [performance/consistency] → Mitigation: [throttle, batch]

---

## 15. Rollout & Telemetry

- Feature flag? [yes/no]
- Metrics: [usage, errors, latency]
- Manual validation steps

---

## 16. Open Questions

- Q1: [decision needed]
- Q2: [dependency/owner]

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future:
- [ ] Future X
- [ ] Future Y

---

## Preflight Questionnaire

Answer these to drive vertical slice and acceptance gates:

1. Smallest end-to-end user outcome for this PR?
2. Primary user and critical action?
3. Must-have vs nice-to-have?
4. Real-time requirements? (see shared-standards.md)
5. Performance constraints? (see shared-standards.md)
6. Error/edge cases to handle?
7. Data model changes?
8. Service APIs required?
9. UI entry points and states?
10. Security/permissions implications?
11. Dependencies or blocking integrations?
12. Rollout strategy and metrics?
13. What is explicitly out of scope?

---

## Authoring Notes

- Write Test Plan before coding
- Favor vertical slice that ships standalone
- Keep service layer deterministic
- SwiftUI views are thin wrappers
- Test offline/online thoroughly
- Reference `Psst/agents/shared-standards.md` throughout
