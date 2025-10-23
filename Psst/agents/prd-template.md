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

## 12. Testing Plan & Acceptance Gates

**Define these 3 scenarios BEFORE implementation.** Use specific, testable criteria.

**See `Psst/docs/testing-strategy.md` for examples and detailed guidance.**

---

### Happy Path
- [ ] [Describe main user flow from start to finish]
- [ ] **Gate:** [Specific measurable outcome - e.g., "Message appears in chat within 1 second"]
- [ ] **Pass Criteria:** Flow completes without errors, user sees expected result

**Example (Message Send):**
- User opens chat → types message → taps send → message appears in chat
- Gate: Message persisted to Firestore and appears on sender's screen
- Pass: No errors, message visible with timestamp

---

### Edge Cases (Document 1-2 specific scenarios)

- [ ] **Edge Case 1:** [What happens with non-standard input?]
  - **Test:** [Specific scenario - e.g., "User sends empty message"]
  - **Expected:** [Behavior - e.g., "Shows alert: 'Message cannot be empty'"]
  - **Pass:** Handled gracefully, clear feedback, no crash

- [ ] **Edge Case 2:** [What happens with unusual condition?]
  - **Test:** [Specific scenario - e.g., "User sends 1000-character message"]
  - **Expected:** [Behavior - e.g., "Accepts message or shows character limit"]
  - **Pass:** No crash, appropriate handling

**Common Edge Cases to Consider:**
- Empty input (blank fields, empty messages)
- Long input (character limits, large data)
- Special characters (emojis, Unicode, symbols)
- Rapid actions (spam button, concurrent requests)
- Boundary conditions (max users in group, max message length)

---

### Error Handling

- [ ] **Offline Mode**
  - **Test:** Enable airplane mode → attempt action
  - **Expected:** "No internet connection" message, action queues for retry
  - **Pass:** Clear error message, retry works when online

- [ ] **Invalid Input**
  - **Test:** Submit empty/malformed data (e.g., invalid email format)
  - **Expected:** Validation error shown inline with correction hint
  - **Pass:** User can fix and retry, no crash

- [ ] **Network Timeout** (if applicable for long operations)
  - **Test:** Slow network → action times out
  - **Expected:** Loading state → "Taking longer than expected" → retry button
  - **Pass:** Timeout handled gracefully, retry option provided

- [ ] **Permission Denied** (if applicable)
  - **Test:** User attempts action without proper permissions
  - **Expected:** "You don't have permission" message
  - **Pass:** Clear message, no crash or partial writes

---

### Optional: Multi-Device Testing

**Only for real-time sync features** (messaging, presence, typing indicators):

- [ ] Action on Device 1 syncs to Device 2
- [ ] **Gate:** Sync happens within ~500ms
- [ ] **Pass:** Change visible on all connected devices, no data loss

---

### Performance Check (Subjective)

- [ ] Feature feels responsive (no noticeable lag)
- [ ] Smooth animations (if applicable)
- [ ] No UI blocking during operations

**If performance-critical (lists 50+ items, heavy operations):**
- [ ] Measure specific metric (e.g., scroll performance, load time)
- [ ] Target: [Specific number - e.g., "List loads in < 1 second"]

---

## 13. Definition of Done

See standards in `Psst/agents/shared-standards.md`:
- [ ] Service methods implemented with proper error handling
- [ ] SwiftUI views with all states (empty, loading, error, success)
- [ ] Real-time sync verified across 2+ devices
- [ ] Offline persistence tested manually
- [ ] All acceptance gates pass
- [ ] Manual testing completed (configuration, user flows, multi-device, offline)
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
