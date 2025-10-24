# PRD: Message Delivery Status Indicator Fix

**Feature**: message-delivery-status-indicator-fix

**Version**: 1.0

**Status**: Ready for Development

**Agent**: Pam

**Target Release**: Phase 1 (MVP Polish)

**Links**: [PR Brief], [TODO], [Designs], [Tracking Issue]

---

## 1. Summary

Fix the "Delivered" status indicator to only show on the latest message instead of appearing under every message bubble, matching iOS Messages behavior and creating a cleaner, more professional chat experience.

---

## 2. Problem & Goals

- **User Problem**: Currently, the delivery status appears under all sent messages which creates visual clutter and doesn't follow standard messaging app patterns
- **Why Now**: This is a critical UX polish issue that affects the professional appearance of the app and user experience
- **Goals (ordered, measurable)**:
  - [ ] G1 — Delivery status indicator only appears on the latest message in each conversation
  - [ ] G2 — Indicator automatically moves to newer messages as they are sent
  - [ ] G3 — Visual design matches iOS Messages behavior and patterns

---

## 3. Non-Goals / Out of Scope

- [ ] Not implementing read receipts (separate feature)
- [ ] Not changing the underlying message delivery logic
- [ ] Not modifying the message bubble design itself
- [ ] Not implementing typing indicators (separate feature)

---

## 4. Success Metrics

Reference `Psst/agents/shared-standards.md` for metric templates:
- **User-visible**: Clean visual hierarchy with status indicator only on latest message
- **System**: Message delivery latency < 100ms (unchanged from existing)
- **Quality**: 0 blocking bugs, all gates pass, crash-free >99%

---

## 5. Users & Stories

- As a **messaging app user**, I want to see delivery status only on my latest message so that the chat interface is clean and uncluttered
- As a **user sending multiple messages**, I want the delivery indicator to automatically move to my newest message so that I can easily track the status of my most recent communication
- As a **user in a conversation**, I want the visual design to match familiar iOS patterns so that the app feels native and professional

---

## 6. Experience Specification (UX)

**Current Issue (Before):**
![Current delivery status clutter - all messages show status](mocks/error-screenshots/pr-002-error-1.png)
*Problem: Delivery status appears under every sent message, creating visual clutter*

![Current delivery status clutter - multiple messages](mocks/error-screenshots/pr-002-error-2.png)
*Problem: Multiple messages all show delivery status, not following iOS Messages pattern*

**Desired Behavior (After):**
- **Entry points and flows**: Status indicator appears automatically on the latest sent message in any conversation
- **Visual behavior**: Small "Delivered" text appears below the latest message bubble only, automatically moves to newer messages when sent
- **Loading/disabled/error states**: Status indicator shows immediately when message is delivered, no loading states needed
- **Performance**: See targets in `Psst/agents/shared-standards.md` - no impact on existing performance

---

## 7. Functional Requirements (Must/Should)

- **MUST**: Track the latest message ID for each conversation
- **MUST**: Only display delivery status on the latest message per conversation
- **MUST**: Automatically move indicator to newer messages when sent
- **MUST**: Maintain existing message delivery logic unchanged
- **SHOULD**: Use consistent styling with existing message UI components

**Acceptance gates per requirement:**
- [Gate] When user sends new message → delivery status moves from old message to new message
- [Gate] When user sends multiple messages → only latest message shows delivery status
- [Gate] When user views conversation → only latest sent message has delivery indicator
- [Gate] Existing message delivery logic continues to work unchanged

---

## 8. Data Model

No changes to existing Firestore schema. This is a UI-only change that uses existing message data.

**Existing Message Document** (unchanged):
```swift
{
  id: String,
  text: String,
  senderID: String,
  timestamp: Timestamp,
  readBy: [String]  // Array of user IDs
}
```

**New UI State Tracking** (local only):
```swift
// Track latest message per conversation for UI display
var latestMessageIDs: [String: String] // [conversationID: messageID]
```

- **Validation rules**: No new Firebase rules needed
- **Indexing/queries**: No new Firestore queries needed

---

## 9. API / Service Contracts

No new service methods needed. This is a UI-only change that uses existing message data and delivery status.

**Existing methods used** (unchanged):
```swift
// Continue using existing message service methods
func observeMessages(chatID: String, completion: @escaping ([Message]) -> Void) -> ListenerRegistration
func sendMessage(chatID: String, text: String) async throws -> String
```

- **Pre/post-conditions**: No changes to existing service contracts
- **Error handling strategy**: No changes to existing error handling
- **Parameters and types**: No changes to existing method signatures
- **Return values**: No changes to existing return values

---

## 10. UI Components to Create/Modify

- `Views/ChatList/MessageRow.swift` — Modify to conditionally show delivery status only on latest message
- `ViewModels/ChatListViewModel.swift` — Add logic to track latest message per conversation
- `Services/MessageService.swift` — No changes needed (UI-only feature)

---

## 11. Integration Points

- **Firebase Authentication**: No changes
- **Firestore**: No changes to existing message queries
- **Firebase Realtime Database**: No changes
- **FCM**: No changes
- **State management**: Add local state tracking for latest message per conversation

---

## 12. Testing Plan & Acceptance Gates

Define BEFORE implementation. Use checkboxes.

**Current**: Manual testing validation (see `Psst/agents/shared-standards.md`)  
**Future**: Automated testing recommendations in `Psst/docs/testing-strategy.md`

- **Configuration Testing**
  - [ ] Firebase Authentication setup works
  - [ ] Firestore database connection established
  - [ ] FCM push notifications configured
  - [ ] All environment variables and API keys properly set
  
- **Happy Path Testing**
  - [ ] User sends message → delivery status appears on that message only
  - [ ] Gate: Only latest message shows delivery status indicator
  
- **Edge Cases Testing**
  - [ ] User sends multiple messages → only latest shows status
  - [ ] User switches between conversations → each shows status on latest only
  - [ ] User receives messages → status indicator behavior unchanged
  
- **Multi-User Testing**
  - [ ] Real-time sync <100ms across devices (unchanged)
  - [ ] Concurrent messages handled correctly (unchanged)
  - [ ] Messages appear on all connected devices (unchanged)
  
- **Performance Testing** (see shared-standards.md)
  - [ ] App load < 2-3s (unchanged)
  - [ ] Smooth 60fps scrolling (unchanged)
  - [ ] Message latency < 100ms (unchanged)

---

## 13. Definition of Done

See standards in `Psst/agents/shared-standards.md`:
- [ ] UI logic implemented to track latest message per conversation
- [ ] SwiftUI views updated to conditionally show delivery status
- [ ] Real-time sync verified across 2+ devices (unchanged behavior)
- [ ] Offline persistence tested manually (unchanged behavior)
- [ ] All acceptance gates pass
- [ ] Manual testing completed (configuration, user flows, multi-device, offline)
- [ ] Docs updated

---

## 14. Risks & Mitigations

- **Risk**: UI state tracking complexity → **Mitigation**: Keep simple local state, no Firebase changes
- **Risk**: Performance impact from UI updates → **Mitigation**: Minimal UI changes, no new Firebase queries
- **Risk**: Breaking existing message delivery → **Mitigation**: No changes to underlying message service logic

---

## 15. Rollout & Telemetry

- **Feature flag?** No - this is a UI polish fix
- **Metrics**: No new metrics needed (UI-only change)
- **Manual validation steps**: Verify delivery status appears only on latest message

---

## 16. Open Questions

- **Q1**: Should we show delivery status immediately or wait for server confirmation? → **A**: Use existing delivery logic
- **Q2**: How should we handle group chats with multiple participants? → **A**: Focus on individual conversations first

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future:
- [ ] Read receipts for group chats
- [ ] Typing indicators
- [ ] Message status for group conversations

---

## Preflight Questionnaire

Answer these to drive vertical slice and acceptance gates:

1. **Smallest end-to-end user outcome for this PR?** User sees delivery status only on latest message
2. **Primary user and critical action?** User sending messages, seeing clean status indicator
3. **Must-have vs nice-to-have?** Must-have: status only on latest message
4. **Real-time requirements?** No changes to existing real-time behavior
5. **Performance constraints?** No impact on existing performance
6. **Error/edge cases to handle?** Multiple messages, conversation switching
7. **Data model changes?** None - UI-only change
8. **Service APIs required?** None - use existing services
9. **UI entry points and states?** Message row component modification
10. **Security/permissions implications?** None
11. **Dependencies or blocking integrations?** None
12. **Rollout strategy and metrics?** Direct deployment, no feature flags
13. **What is explicitly out of scope?** Read receipts, typing indicators, group chat status

---

## Authoring Notes

- Write Test Plan before coding
- Favor vertical slice that ships standalone
- Keep service layer deterministic
- SwiftUI views are thin wrappers
- Test offline/online thoroughly
- Reference `Psst/agents/shared-standards.md` throughout
