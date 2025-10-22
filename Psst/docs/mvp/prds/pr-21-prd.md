# PRD: Message Status and Timestamp UI Polish

**Feature**: message-status-and-timestamp-ui-polish

**Version**: 1.0

**Status**: Ready for Development

**Agent**: Caleb

**Target Release**: Phase 4

**Links**: [PR Brief], [TODO], [Designs], [Tracking Issue]

---

## 1. Summary

Fix two critical UI inconsistencies in the chat interface to match iOS Messages behavior: limit "Delivered" status to only the latest message and implement swipe-to-reveal timestamps functionality. This creates a cleaner, more professional chat experience that follows iOS design patterns.

---

## 2. Problem & Goals

- **User Problem**: Current chat interface shows "Delivered" status under every message (visual clutter) and lacks timestamp visibility, making it difficult to see when messages were sent. Additionally, there's a device-specific issue where "Delivered" text is not visible on real devices in dark mode compared to simulator.

- **Why Now**: These UI inconsistencies create a poor user experience that doesn't match iOS Messages behavior and professional messaging standards.

- **Goals** (ordered, measurable):
  - [ ] G1 — "Delivered" status only appears on the latest message (not every message)
  - [ ] G2 — Users can swipe messages to reveal timestamps (left for own messages, right for others)
  - [ ] G3 — Fix "Delivered" text visibility issue on real devices in dark mode

---

## 3. Non-Goals / Out of Scope

- [ ] Not implementing read receipts beyond "Delivered" status (already handled in PR #14)
- [ ] Not changing message bubble styling or colors
- [ ] Not implementing message reactions or other interactive features
- [ ] Not modifying the core messaging functionality or Firebase integration

---

## 4. Success Metrics

Reference `Psst/agents/shared-standards.md` for metric templates:
- **User-visible**: Clean message list with status only on latest message, swipe gestures work smoothly
- **System**: Swipe animations maintain 60fps, no performance degradation
- **Quality**: 0 blocking bugs, all gates pass, crash-free >99%

---

## 5. Users & Stories

- As a **messaging user**, I want to see "Delivered" status only on my latest message so that the chat interface is clean and uncluttered.
- As a **messaging user**, I want to swipe messages to see timestamps so that I can check when messages were sent without cluttering the interface.
- As a **user on a real device**, I want to see "Delivered" text clearly in dark mode so that I can confirm message delivery status.

---

## 6. Experience Specification (UX)

- **Entry points and flows**: 
  - Status visibility: Automatic based on message position (latest only)
  - Timestamp reveal: Swipe gesture on any message bubble
- **Visual behavior**: 
  - "Delivered" text appears only under the most recent sent message
  - Swipe left on own messages reveals timestamp on the right
  - Swipe right on other users' messages reveals timestamp on the left
  - Smooth slide animations (iOS Messages style)
- **Loading/disabled/error states**: 
  - No loading states needed (immediate visual feedback)
  - Graceful handling if swipe gesture conflicts with scroll
- **Performance**: See targets in `Psst/agents/shared-standards.md`

---

## 7. Functional Requirements (Must/Should)

- **MUST**: "Delivered" status only shows on the latest sent message
- **MUST**: Swipe gestures work on all message bubbles (own and others)
- **MUST**: Timestamps slide into view with smooth animation
- **MUST**: Fix "Delivered" text visibility on real devices in dark mode
- **SHOULD**: Swipe gesture doesn't interfere with message list scrolling
- **SHOULD**: Timestamp format matches iOS Messages (e.g., "2:30 PM", "Yesterday")

**Acceptance gates per requirement:**
- [Gate] When user sends multiple messages → only latest shows "Delivered"
- [Gate] When user swipes left on own message → timestamp slides in from right
- [Gate] When user swipes right on other's message → timestamp slides in from left
- [Gate] When user tests on real device in dark mode → "Delivered" text is clearly visible

---

## 8. Data Model

No changes to Firestore schema required. This is purely a UI enhancement.

**Existing Message model** (from PR #5):
```swift
struct Message {
    let id: String
    let text: String
    let senderID: String
    let timestamp: Timestamp
    let readBy: [String]
}
```

- **Validation rules**: No new validation needed
- **Indexing/queries**: No new queries needed

---

## 9. API / Service Contracts

No new service methods required. This enhancement uses existing message data.

**Existing service methods** (from PR #8):
```swift
// No new service methods needed
// Uses existing MessageService.observeMessages() and MessageService.sendMessage()
```

- **Pre/post-conditions**: No changes to existing service contracts
- **Error handling strategy**: No new error handling needed
- **Parameters and types**: No new parameters
- **Return values**: No new return values

---

## 10. UI Components to Create/Modify

- `Views/ChatList/MessageRow.swift` — Add swipe gesture handling and timestamp reveal
- `Views/ChatList/ChatView.swift` — Update message status display logic (latest only)
- `Components/MessageStatusIndicator.swift` — Modify to show status only on latest message
- `Utilities/Date+Extensions.swift` — Add timestamp formatting for display

---

## 11. Integration Points

- **SwiftUI state management**: Update message display logic
- **Gesture handling**: Implement swipe gestures on message bubbles
- **Animation system**: SwiftUI animations for timestamp reveal
- **Dark mode support**: Ensure "Delivered" text visibility in dark mode

---

## 12. Testing Plan & Acceptance Gates

Define BEFORE implementation. Use checkboxes.

**Current**: Manual testing validation (see `Psst/agents/shared-standards.md`)  
**Future**: Automated testing recommendations in `Psst/docs/testing-strategy.md`

- **Configuration Testing**
  - [ ] Firebase Authentication setup works
  - [ ] Firestore database connection established
  - [ ] All environment variables and API keys properly set
  
- **Happy Path Testing**
  - [ ] User sends multiple messages → only latest shows "Delivered"
  - [ ] User swipes left on own message → timestamp slides in smoothly
  - [ ] User swipes right on other's message → timestamp slides in smoothly
  - [ ] Gate: All gestures work without interfering with scrolling
  
- **Edge Cases Testing**
  - [ ] Swipe gesture works with single message
  - [ ] Swipe gesture works with many messages (100+)
  - [ ] Swipe gesture doesn't conflict with scroll gestures
  - [ ] "Delivered" text visible in both light and dark mode
  
- **Multi-User Testing**
  - [ ] Real-time sync <100ms across devices
  - [ ] Status updates appear correctly on all devices
  - [ ] Timestamp reveal works on all connected devices
  
- **Performance Testing** (see shared-standards.md)
  - [ ] App load < 2-3s
  - [ ] Smooth 60fps scrolling with swipe animations
  - [ ] No performance degradation with gesture handling

---

## 13. Definition of Done

See standards in `Psst/agents/shared-standards.md`:
- [ ] Message status only shows on latest message
- [ ] Swipe gestures implemented with smooth animations
- [ ] "Delivered" text visible on real devices in dark mode
- [ ] All acceptance gates pass
- [ ] Manual testing completed (configuration, user flows, multi-device, offline)
- [ ] No console errors during testing
- [ ] Documentation updated

---

## 14. Risks & Mitigations

- **Risk**: Swipe gestures conflict with scroll → **Mitigation**: Use proper gesture recognizer priorities and test thoroughly
- **Risk**: Performance impact with many messages → **Mitigation**: Use LazyVStack and optimize gesture handling
- **Risk**: Dark mode visibility issues persist → **Mitigation**: Test on multiple real devices and adjust text color/contrast

---

## 15. Rollout & Telemetry

- **Feature flag?** No (UI enhancement, no feature flag needed)
- **Metrics**: Gesture usage, performance impact
- **Manual validation steps**: Test on real device in dark mode, verify swipe gestures work smoothly

---

## 16. Open Questions

- Q1: Should timestamp format match iOS Messages exactly (e.g., "2:30 PM", "Yesterday")?
- Q2: Should swipe gesture have haptic feedback like iOS Messages?

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future:
- [ ] Message reactions or other interactive features
- [ ] Advanced timestamp formatting options
- [ ] Customizable swipe gesture sensitivity

---

## Preflight Questionnaire

Answer these to drive vertical slice and acceptance gates:

1. **Smallest end-to-end user outcome for this PR?** User sees clean message list with status only on latest message and can swipe to reveal timestamps
2. **Primary user and critical action?** Messaging user viewing and interacting with message timestamps
3. **Must-have vs nice-to-have?** Must-have: status on latest only, swipe timestamps. Nice-to-have: haptic feedback
4. **Real-time requirements?** No new real-time requirements, uses existing message sync
5. **Performance constraints?** Smooth 60fps animations, no scroll interference
6. **Error/edge cases to handle?** Gesture conflicts, dark mode visibility, many messages
7. **Data model changes?** None, purely UI enhancement
8. **Service APIs required?** None, uses existing message data
9. **UI entry points and states?** Message bubbles with swipe gestures, status display logic
10. **Security/permissions implications?** None
11. **Dependencies or blocking integrations?** None
12. **Rollout strategy and metrics?** Direct deployment, monitor gesture usage
13. **What is explicitly out of scope?** Read receipts, message reactions, bubble styling changes

---

## Authoring Notes

- Write Test Plan before coding
- Favor vertical slice that ships standalone
- Keep service layer deterministic
- SwiftUI views are thin wrappers
- Test offline/online thoroughly
- Reference `Psst/agents/shared-standards.md` throughout
- **Critical**: Test "Delivered" text visibility on real devices in dark mode
