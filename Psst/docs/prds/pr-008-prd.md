# PRD: Message Timestamp Drag Gesture Fix

**Feature**: message-timestamp-drag-gesture-fix

**Version**: 2.0 (Updated after implementation)

**Status**: Implemented

**Agent**: Caleb (Coder Agent)

**Target Release**: Phase 1 (MVP Polish)

**Links**: [PR Brief], [TODO], [UX Spec], [Tracking Issue]

---

## 1. Summary

Implement a drag gesture for viewing message timestamps where the timestamp is only visible while actively dragging. This PR addresses the UX issue by making timestamps accessible on-demand without cluttering the interface. The message bubble springs back when released, and the timestamp automatically disappears.

---

## 2. Problem & Goals

- **User Problem**: Users need to view message timestamps without cluttering the chat interface
- **Why Now**: This is a core UX pattern that makes timestamps accessible on-demand
- **Goals (ordered, measurable)**:
  - [x] G1 — Drag to reveal timestamp (only visible while dragging)
  - [x] G2 — Message bubble bounces back smoothly when released
  - [x] G3 — Works consistently for all message types (text messages implemented, images pending PR #009)

---

## 3. Non-Goals / Out of Scope

- [x] Not implementing auto-hide timers (timestamp only visible while dragging)
- [x] Not implementing tap-to-dismiss (timestamp disappears when drag ends)
- [x] Not changing the timestamp display format or styling (kept existing design)
- [x] Not changing the underlying message data model (no schema changes)

---

## 4. Success Metrics

Reference `Psst/agents/shared-standards.md` for metric templates:
- **User-visible**: Drag gesture auto-returns after 3 seconds, <200ms return animation
- **System**: Drag response <50ms, smooth 60fps animations
- **Quality**: 0 blocking bugs, all gates pass, crash-free >99%

---

## 5. Users & Stories

- As a **messaging user**, I want the drag gesture to auto-return timestamps so that the UI stays clean and uncluttered
- As a **frequent user**, I want timestamps to automatically hide after 3 seconds so that I don't have to manually dismiss them
- As a **group chat participant**, I want consistent drag behavior across all message types so that I can track conversation flow

---

## 6. Experience Specification (UX)

- **Entry points**: Drag left (sent messages) or right (received messages) on message bubble
- **Visual behavior**: 
  - Timestamp fades in as user drags (opacity based on drag distance)
  - Timestamp visible only while actively holding drag
  - Message bubble springs back when user releases
  - Timestamp disappears automatically when drag ends
  - Works for both sent and received messages
- **Loading/disabled/error states**: No loading states needed (instant reveal)
- **Performance**: See targets in `Psst/agents/shared-standards.md`

---

## 7. Functional Requirements (Must/Should)

- **MUST**: Drag gesture reveals timestamp while actively dragging
- **MUST**: Message bubble springs back when user releases drag
- **MUST**: Timestamp disappears automatically when drag ends
- **MUST**: Works for text messages (image messages pending PR #009)
- **MUST**: Maintains existing timestamp styling and positioning
- **SHOULD**: Smooth 60fps animations during drag and spring-back
- **SHOULD**: Timestamp opacity fades in based on drag distance

**Acceptance gates per requirement:**
- [x] [Gate] When user drags message → timestamp appears and follows drag
- [x] [Gate] When user releases → message springs back smoothly
- [x] [Gate] Works for text messages → timestamp reveals during drag
- [ ] [Gate] Works for image messages → pending PR #009
- [x] [Gate] Animation performance → smooth 60fps during transitions

---

## 8. Data Model

No changes to existing data model. Timestamps are already stored in message documents.

```swift
// Existing message model (no changes needed)
struct Message {
    let id: String
    let text: String
    let senderID: String
    let timestamp: Date
    let readBy: [String]
}
```

- **Validation rules**: No new validation needed
- **Indexing/queries**: No new queries needed

---

## 9. API / Service Contracts

No new service methods needed. This is a UI-only enhancement.

```swift
// No new service contracts required
// Existing message display logic enhanced with drag gesture
// Timestamp visibility tied to dragOffset state
```

- **Pre/post-conditions**: N/A (UI-only feature)
- **Error handling strategy**: N/A (no service calls)
- **Parameters and types**: dragOffset: CGFloat (tracks drag distance)
- **Return values**: N/A

---

## 10. UI Components to Create/Modify

- `Views/ChatList/MessageRow.swift` — Modified drag gesture to show timestamp only while dragging
  - Added drag gesture with spring-back animation
  - Timestamp visibility tied to dragOffset (> 20pt for received, < -20pt for sent)
  - Opacity fades in based on drag distance (0-80pt range)
  - No timers, no tap gestures - pure drag interaction

---

## 11. Integration Points

- **SwiftUI State Management**: @State for dragOffset tracking
- **Animation Framework**: SwiftUI spring animations for bounce-back effect
- **Gesture Recognition**: DragGesture() with onChanged and onEnded handlers
- **No Firebase integration needed**: This is UI-only enhancement
- **No timers needed**: Timestamp visibility purely based on drag state

---

## 12. Testing Plan & Acceptance Gates

**Current**: Manual testing validation (see `Psst/agents/shared-standards.md`)  
**Future**: Automated testing recommendations in `Psst/docs/testing-strategy.md`

- **Configuration Testing**
  - [x] App launches and displays messages correctly
  - [x] Existing message functionality still works
  - [x] No new Firebase configuration needed
  
- **Happy Path Testing**
  - [x] User drags text message → timestamp appears while dragging
  - [x] User releases drag → message springs back, timestamp disappears
  - [ ] User drags image message → pending PR #009
  - [x] Gate: Timestamp appears immediately during drag
  - [x] Gate: Message bounces back smoothly on release
  
- **Edge Cases Testing**
  - [x] Very long messages don't overlap timestamp
  - [x] Holding drag keeps timestamp visible
  - [x] Works with different message bubble sizes
  - [x] No "stuck" behavior when holding drag
  
- **Multi-User Testing**
  - [x] Timestamp reveal works for text messages
  - [x] No interference with message sending/receiving
  - [x] Real-time message updates don't affect timestamp display
  
- **Performance Testing (see shared-standards.md)**
  - [x] Drag response immediate (<50ms)
  - [x] Spring animation smooth 60fps
  - [x] No UI blocking during drag interaction

---

## 13. Definition of Done

See standards in `Psst/agents/shared-standards.md`:
- [x] Drag-to-reveal implemented for text messages
- [x] Message spring-back animation working smoothly
- [x] Timestamp only visible while actively dragging
- [x] All acceptance gates pass (text messages)
- [x] Manual testing completed (configuration, user flows, performance)
- [x] No console errors or warnings
- [x] Code follows SwiftUI best practices
- [x] Simplified implementation - no timers, no complex state management

---

## 14. Risks & Mitigations

- **Risk**: Timestamp not visible long enough to read → **Mitigation**: User controls visibility by holding drag, can hold as long as needed
- **Risk**: Animation performance on older devices → **Mitigation**: Using lightweight SwiftUI spring animations, minimal performance impact
- **Risk**: Drag gesture conflicts with other gestures → **Mitigation**: Tested with scroll, tap, and other interactions - no conflicts found

---

## 15. Rollout & Telemetry

- **Feature flag?** No (UI enhancement, low risk)
- **Metrics**: Drag gesture usage, animation performance
- **Manual validation steps**: Test drag gesture on text messages, verify spring-back animation, confirm timestamp disappears on release

---

## 16. Open Questions

- **Q1**: ~~Should the 3-second auto-return timing be configurable?~~ **RESOLVED**: No auto-return timer - timestamp only visible while dragging
- **Q2**: ~~Should auto-return be cancelled if user drags again?~~ **RESOLVED**: Not applicable - no timer needed

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future:
- [ ] Image message timestamp support (pending PR #009)
- [ ] Alternative reveal gestures (tap, long-press)
- [ ] Timestamp editing capabilities
- [ ] Persistent timestamp visibility option

---

## Preflight Questionnaire

Answer these to drive vertical slice and acceptance gates:

1. **Smallest end-to-end user outcome for this PR?** User drags message, sees timestamp while holding, releases and message springs back
2. **Primary user and critical action?** Any user dragging any text message to see timestamp on-demand
3. **Must-have vs nice-to-have?** Must-have: drag reveal, spring-back. Nice-to-have: opacity fade-in
4. **Real-time requirements?** None (UI-only feature)
5. **Performance constraints?** Immediate drag response, 60fps spring animation
6. **Error/edge cases to handle?** Long messages, holding drag, various bubble sizes
7. **Data model changes?** None
8. **Service APIs required?** None
9. **UI entry points and states?** Drag on message bubble, timestamp visible only while dragging
10. **Security/permissions implications?** None
11. **Dependencies or blocking integrations?** None
12. **Rollout strategy and metrics?** Direct deployment, track drag usage
13. **What is explicitly out of scope?** Auto-hide timers, tap gestures, image messages (PR #009), data model changes

---

## Authoring Notes

- Write Test Plan before coding
- Favor vertical slice that ships standalone
- Keep service layer deterministic
- SwiftUI views are thin wrappers
- Test offline/online thoroughly
- Reference `Psst/agents/shared-standards.md` throughout
