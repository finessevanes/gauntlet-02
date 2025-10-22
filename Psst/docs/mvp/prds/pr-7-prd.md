# PRD: Chat View Screen UI

**Feature**: Chat View Screen with Message List and Input

**Version**: 1.0

**Status**: Ready for Development

**Agent**: Pam

**Target Release**: Phase 2 - 1-on-1 Chat

**Links**: [PR Brief #7](../pr-briefs.md#pr-7-chat-view-screen-ui), [TODO](../todos/pr-7-todo.md)

---

## 1. Summary

Build the Chat View screen UI that allows users to view messages in a conversation and send new messages. This includes a scrollable message list displaying messages in chronological order with visual distinction between sent and received messages, a message input bar with text field and send button, auto-scroll functionality for new messages, and proper keyboard handling to prevent input obstruction.

---

## 2. Problem & Goals

**Problem:** Users need a dedicated screen to view and send messages within a conversation. Without a Chat View screen, users cannot participate in real-time messaging, which is the core functionality of the app.

**Why now:** This PR is a foundational component of Phase 2 (1-on-1 Chat). It builds on the navigation structure (PR #4) and data models (PR #5) to deliver the core messaging UI that will later support real-time functionality (PR #8).

**Goals:**
  - [ ] G1 — Create a fully functional Chat View screen where users can see messages in chronological order
  - [ ] G2 — Implement a message input interface that allows users to compose and send messages
  - [ ] G3 — Ensure smooth scrolling performance with 100+ messages at 60fps

---

## 3. Non-Goals / Out of Scope

Call out what's intentionally excluded to avoid scope creep.

- [ ] Real-time message sending/receiving (handled in PR #8)
- [ ] Typing indicators (handled in PR #16)
- [ ] Read receipts (handled in PR #17)
- [ ] Message timestamps display (handled in PR #10)
- [ ] Offline message queueing (handled in PR #11)
- [ ] Group chat-specific UI features (handled in PR #14)
- [ ] Message editing or deletion
- [ ] Media messages (images, videos)
- [ ] Voice messages
- [ ] Message reactions or emoji support

---

## 4. Success Metrics

Reference `Psst/agents/shared-standards.md` for metric templates:

**User-visible:**
- Users can scroll through 100+ messages smoothly
- Time to compose and tap send: < 3 seconds (fast input)
- Messages display with clear visual distinction (sent vs received)
- Keyboard appears/dismisses without UI glitches

**System:**
- Scrolling performance: 60fps with 100+ messages (see shared-standards.md)
- Keyboard animation: smooth 0.3s transition
- Auto-scroll to bottom: instant (<50ms) when new message appears
- List rendering: LazyVStack for memory efficiency

**Quality:**
- 0 blocking bugs (crashes, UI freezes)
- All acceptance gates pass
- Crash-free rate >99%
- No console warnings or errors

---

## 5. Users & Stories

- As a **user**, I want to **see all messages in a conversation displayed in chronological order** so that **I can follow the conversation flow naturally**.

- As a **user**, I want to **clearly distinguish between messages I sent and messages I received** so that **I know who said what in the conversation**.

- As a **user**, I want to **type a message in an input field and tap send** so that **I can participate in the conversation**.

- As a **user**, I want **the message list to automatically scroll to the newest message** so that **I always see the latest content without manual scrolling**.

- As a **user**, I want **the keyboard to not block the input field when typing** so that **I can always see what I'm writing**.

---

## 6. Experience Specification (UX)

**Entry Points:**
- User taps on a chat row in the Conversation List screen (PR #6)
- User creates a new chat and is navigated to this screen (PR #12)
- Navigation: `NavigationLink` from ConversationListView to ChatView

**Visual Behavior:**
- **Message List:**
  - Messages displayed in chronological order (oldest at top, newest at bottom)
  - Sent messages: aligned right, blue background, white text
  - Received messages: aligned left, gray background, black text
  - Each message shows sender name (for group chats in future PRs)
  - Scrollable with smooth 60fps performance
  - Auto-scrolls to bottom when new messages arrive
  
- **Message Input Bar:**
  - Fixed at bottom of screen
  - Text field with placeholder "Message..."
  - Send button (paper plane icon or text "Send")
  - Send button disabled when text field is empty
  - Send button enabled when text is entered

**States:**
- **Empty State:** "No messages yet. Send a message to start the conversation."
- **Loading State:** Spinner while messages are being fetched (future PR)
- **Active State:** Messages displayed with input bar active
- **Keyboard Visible:** Input bar moves up with keyboard, messages remain visible

**Performance Targets (see shared-standards.md):**
- Scrolling: 60fps with 100+ messages
- Keyboard appearance: smooth 0.3s animation
- Auto-scroll: <50ms response time
- Tap feedback: <50ms response time on send button

---

## 7. Functional Requirements (Must/Should)

**MUST:**
- MUST display messages in a scrollable list in chronological order
  - [Gate] When screen loads → messages appear oldest to newest (top to bottom)
  
- MUST visually distinguish sent vs received messages
  - [Gate] Sent messages appear right-aligned with blue background
  - [Gate] Received messages appear left-aligned with gray background
  
- MUST provide text input field for composing messages
  - [Gate] User can tap input field and type text
  - [Gate] Text appears in field as user types
  
- MUST provide send button that triggers message sending
  - [Gate] Send button disabled when input is empty
  - [Gate] Send button enabled when input has text
  - [Gate] Tapping send button calls message sending function (implemented in PR #8)
  
- MUST auto-scroll to bottom when new messages arrive
  - [Gate] When new message added → scroll position moves to bottom within 50ms
  
- MUST handle keyboard appearance without blocking input
  - [Gate] When keyboard appears → input bar moves up with keyboard
  - [Gate] When keyboard appears → message list adjusts to remain visible
  - [Gate] When keyboard dismisses → UI returns to normal state

**SHOULD:**
- SHOULD use LazyVStack for efficient rendering
  - [Gate] Memory usage stays low (<50MB) with 100+ messages
  
- SHOULD clear input field after sending message
  - [Gate] After send button tapped → input field becomes empty
  
- SHOULD provide smooth animations for keyboard transitions
  - [Gate] Keyboard animations complete in 0.3s without glitches

---

## 8. Data Model

This PR displays data from models defined in PR #5. No new data models are created.

**Used Models:**

```swift
// From PR #5: Message.swift
struct Message: Identifiable, Codable {
    var id: String
    var text: String
    var senderID: String
    var timestamp: Date
    var readBy: [String]
}

// From PR #5: Chat.swift
struct Chat: Identifiable, Codable {
    var id: String
    var members: [String]
    var lastMessage: String
    var lastMessageTimestamp: Date
    var isGroupChat: Bool
}
```

**Data Flow:**
- ChatView receives a `Chat` object (passed via navigation)
- Messages are displayed from a local `@State` array of `Message` objects
- For this PR, messages are mock/placeholder data
- Real-time message fetching will be implemented in PR #8

**Validation Rules:**
- Input text must not be empty to enable send button
- Input text trimmed of whitespace before sending

---

## 9. API / Service Contracts

This PR does NOT implement actual message sending/receiving (that's PR #8). However, it defines the UI contract that PR #8 will fulfill.

**UI → Service Contract (to be implemented in PR #8):**

```swift
// Future MessageService method (PR #8 will implement)
// ChatView will call this when send button is tapped
func sendMessage(chatID: String, text: String) async throws -> String
```

**Pre-conditions for UI:**
- User must be authenticated
- Chat object must have valid chatID
- Input text must not be empty (trimmed)

**Post-conditions after send (for UI):**
- Input field cleared
- Message added to local array (optimistic UI in PR #9)
- Scroll to bottom to show new message

**Error Handling:**
- For this PR, no actual errors occur (placeholder data)
- PR #8 will handle send errors (network, Firebase, etc.)

---

## 10. UI Components to Create/Modify

**Create:**
- `Views/Conversation/ChatView.swift` — Main chat screen with message list and input bar
- `Views/Conversation/MessageRow.swift` — Individual message bubble component
- `Views/Conversation/MessageInputView.swift` — Text input bar with send button

**Modify:**
- `Views/ConversationList/ConversationListView.swift` — Add NavigationLink to ChatView when chat row tapped (if not already done in PR #6)

**File Structure:**
```
Psst/Psst/Views/
├── Conversation/
│   ├── ChatView.swift           # Main screen (NEW)
│   ├── MessageRow.swift         # Message bubble (NEW)
│   └── MessageInputView.swift   # Input bar (NEW)
```

---

## 11. Integration Points

**SwiftUI Components:**
- `NavigationStack` or `NavigationView` for screen navigation
- `ScrollView` with `LazyVStack` for message list
- `TextField` for message input
- `Button` for send action
- `.onAppear` modifier to scroll to bottom on load

**State Management:**
- `@State` for message array (local placeholder data)
- `@State` for input text field value
- `@FocusState` for keyboard handling
- `@EnvironmentObject` for current user (from AuthViewModel)

**Future Integration (PR #8):**
- MessageService for real-time message sending/receiving
- Firestore snapshot listeners for new messages

---

## 12. Testing Plan & Acceptance Gates

Define BEFORE implementation. Use checkboxes.

**Current**: Manual testing validation (see `Psst/agents/shared-standards.md`)

### Configuration Testing
- [ ] ChatView accessible via navigation from ConversationListView
- [ ] SwiftUI Preview renders ChatView without errors
- [ ] All subcomponents (MessageRow, MessageInputView) render correctly

### Happy Path Testing
- [ ] User navigates to ChatView from chat list
- [ ] Messages display in chronological order (oldest top, newest bottom)
- [ ] Gate: Sent messages appear right-aligned with blue background
- [ ] Gate: Received messages appear left-aligned with gray background
- [ ] User taps input field and types message
- [ ] Gate: Text appears in input field as user types
- [ ] Gate: Send button disabled when input empty
- [ ] Gate: Send button enabled when input has text
- [ ] User taps send button
- [ ] Gate: Input field clears after send (for now, just clears input)
- [ ] Gate: Scroll automatically moves to bottom after new message

### Edge Cases Testing
- [ ] Empty state displays when no messages exist
- [ ] Gate: "No messages yet. Send a message to start the conversation."
- [ ] Very long message text wraps correctly within bubble
- [ ] Gate: Message bubble expands to fit text, doesn't overflow
- [ ] Input field handles long text (100+ characters)
- [ ] Gate: TextField scrolls horizontally or wraps text
- [ ] Rapidly typing in input field performs smoothly
- [ ] Gate: No lag or dropped characters

### Multi-User Testing (Future PR #8)
- Not applicable for this PR (UI only, no real-time data)

### Keyboard Testing
- [ ] Tap input field
- [ ] Gate: Keyboard appears with smooth 0.3s animation
- [ ] Gate: Input bar moves up with keyboard
- [ ] Gate: Messages remain visible (not hidden by keyboard)
- [ ] Tap outside input field or send button
- [ ] Gate: Keyboard dismisses smoothly
- [ ] Gate: UI returns to normal state

### Performance Testing (see shared-standards.md)
- [ ] Load ChatView with 100+ placeholder messages
- [ ] Gate: Scrolling remains smooth at 60fps
- [ ] Gate: Memory usage stays low (<50MB)
- [ ] Gate: Initial load renders in <1 second
- [ ] Auto-scroll to bottom
- [ ] Gate: Scroll completes in <50ms

### Visual State Verification
- [ ] Empty state displays correctly
- [ ] Message list displays correctly with messages
- [ ] Sent messages styled correctly (right, blue)
- [ ] Received messages styled correctly (left, gray)
- [ ] Input bar fixed at bottom
- [ ] Send button changes state (disabled/enabled)
- [ ] No console errors or warnings

---

## 13. Definition of Done

See standards in `Psst/agents/shared-standards.md`:

- [ ] ChatView.swift implemented with message list and input bar
- [ ] MessageRow.swift implemented with sent/received styling
- [ ] MessageInputView.swift implemented with text field and send button
- [ ] Navigation from ConversationListView to ChatView working
- [ ] SwiftUI state management (@State, @FocusState) implemented correctly
- [ ] Keyboard handling prevents input obstruction
- [ ] Auto-scroll to bottom when new messages arrive
- [ ] LazyVStack used for efficient scrolling
- [ ] All acceptance gates pass
- [ ] Manual testing completed (UI rendering, keyboard handling, scrolling performance)
- [ ] No console warnings or errors
- [ ] Code follows `Psst/agents/shared-standards.md` patterns
- [ ] SwiftUI previews work for all components
- [ ] PR created targeting develop branch

---

## 14. Risks & Mitigations

**Risk: Keyboard blocking input field**
- **Mitigation:** Use SwiftUI `.ignoresSafeArea(.keyboard)` and `.padding(.bottom, keyboardHeight)` to adjust layout. Test on multiple device sizes (iPhone SE, iPhone 15 Pro Max).

**Risk: Scrolling performance degrades with many messages**
- **Mitigation:** Use `LazyVStack` instead of `VStack` to render only visible messages. Profile with Instruments to ensure 60fps.

**Risk: Auto-scroll not working consistently**
- **Mitigation:** Use `ScrollViewReader` with `.scrollTo()` method triggered by `.onChange` of message array. Add slight delay (0.1s) to ensure layout completion.

**Risk: Send button tap has no feedback**
- **Mitigation:** Add haptic feedback with `UIImpactFeedbackGenerator` on send button tap. Consider visual animation (button scale).

**Risk: Different devices render UI inconsistently**
- **Mitigation:** Test on iOS Simulator with multiple device configurations (SE, 14, 15 Pro). Use SwiftUI's adaptive layouts and avoid hardcoded sizes.

---

## 15. Rollout & Telemetry

**Feature Flag:** No

**Metrics (Manual Observation):**
- UI renders correctly on first load
- Scrolling is smooth during testing
- Keyboard appears/dismisses without issues
- No crashes during 10-minute testing session

**Manual Validation Steps:**
1. Navigate to ChatView from conversation list
2. Verify messages display correctly
3. Type in input field and verify text appears
4. Tap send button and verify input clears
5. Scroll through 100+ messages and verify smoothness
6. Open/close keyboard and verify no UI glitches

---

## 16. Open Questions

**Q1:** Should we add a character limit to message input?
- **Answer:** No character limit for Phase 2. Could be added in Phase 4 if needed.

**Q2:** Should we show timestamps for each message in this PR?
- **Answer:** No, timestamps will be added in PR #10 (server timestamps). For now, focus on core UI structure.

**Q3:** Should we add a "scroll to bottom" button when user scrolls up?
- **Answer:** Not required for MVP. Could be added in Phase 4 polish (PR #23).

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future PRs:

- [ ] Message timestamps (PR #10)
- [ ] Real-time message sync (PR #8)
- [ ] Optimistic UI updates (PR #9)
- [ ] Typing indicators (PR #16)
- [ ] Read receipts (PR #17)
- [ ] Group chat member names (PR #14)
- [ ] Message editing/deletion
- [ ] Media messages (images, videos)
- [ ] Voice messages
- [ ] Message search within conversation
- [ ] Emoji reactions
- [ ] Haptic feedback on send
- [ ] "Scroll to bottom" FAB when scrolled up

---

## Preflight Questionnaire

1. **Smallest end-to-end user outcome for this PR?**
   - User can view a conversation's messages and use the input interface to compose text (actual sending happens in PR #8).

2. **Primary user and critical action?**
   - Primary user: Any authenticated user
   - Critical action: View messages in correct order and type in input field

3. **Must-have vs nice-to-have?**
   - Must-have: Message list display, sent/received styling, input field, send button, auto-scroll, keyboard handling
   - Nice-to-have: Haptic feedback, scroll-to-bottom button, animations

4. **Real-time requirements?** (see shared-standards.md)
   - Not applicable for this PR (UI only). Real-time sync implemented in PR #8.

5. **Performance constraints?** (see shared-standards.md)
   - Scrolling: 60fps with 100+ messages
   - Keyboard: smooth 0.3s animation
   - Auto-scroll: <50ms

6. **Error/edge cases to handle?**
   - Empty message list (empty state)
   - Very long messages (text wrapping)
   - Keyboard blocking input (layout adjustment)
   - No internet connection (not applicable, using placeholder data)

7. **Data model changes?**
   - None. Uses existing Message and Chat models from PR #5.

8. **Service APIs required?**
   - None for this PR. Defines contract for PR #8 (sendMessage).

9. **UI entry points and states?**
   - Entry: Navigation from ConversationListView
   - States: Empty, Loading (future), Active, Keyboard Visible

10. **Security/permissions implications?**
    - None. User must be authenticated to access (handled by navigation structure in PR #4).

11. **Dependencies or blocking integrations?**
    - Depends on: PR #4 (navigation), PR #5 (data models)
    - Blocks: PR #8 (real-time messaging), PR #9 (optimistic UI)

12. **Rollout strategy and metrics?**
    - Manual testing validation. No feature flag.

13. **What is explicitly out of scope?**
    - Real-time message sync, timestamps, read receipts, typing indicators, media messages, message editing.

---

## Authoring Notes

- This PR focuses on UI structure and visual presentation only
- Placeholder/mock data used for testing (no Firebase calls)
- Real-time functionality will be added in PR #8
- Keep components small and reusable (MessageRow, MessageInputView)
- Use LazyVStack for performance with large message lists
- Test keyboard handling on multiple device sizes
- Ensure smooth 60fps scrolling per shared-standards.md

