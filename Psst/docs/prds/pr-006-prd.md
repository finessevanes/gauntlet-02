# PRD: Contextual AI Actions (Long-Press Menu)

**Feature**: Contextual AI Actions

**Version**: 1.0

**Status**: Draft

**Agent**: Pam → Caleb

**Target Release**: Phase 3

**Links**: [PR #006 Brief](../ai-briefs.md#pr-006-contextual-ai-actions-long-press-menu) | [TODO](../todos/pr-006-todo.md) | [Architecture](../architecture.md)

---

## 1. Summary

Enable trainers to access AI intelligence directly within conversations through long-press gestures on messages. Three contextual actions—Summarize Conversation, Set Reminder, and Surface Context—embed AI capabilities into the messaging workflow without requiring context switching to the AI Assistant chat. Initially uses mock RAG responses for parallel development, with seamless backend integration planned when PR #005 completes.

---

## 2. Problem & Goals

### Problem
Trainers like Alex need AI-powered context about their clients but switching to a separate AI Assistant chat disrupts their messaging flow. When a client mentions an injury or goal, trainers want instant access to:
- Conversation summaries to understand key points quickly
- Related past conversations to provide personalized responses
- Quick reminders for follow-up actions

Current solution requires:
1. Leave current chat
2. Open AI Assistant
3. Ask question
4. Return to original chat
5. Manually recall the context

This breaks flow and feels clunky during time-sensitive conversations.

### Why Now?
- PR #004 (AI Chat UI) provides the AI service foundation
- PR #005 (RAG Pipeline) is in parallel development
- Building the UI layer now enables faster integration when backend completes
- Trainers need contextual AI more than dedicated AI chat (better UX)

### Goals
- [ ] **G1 — Zero Context Switching**: Trainers access AI intelligence without leaving conversations
- [ ] **G2 — Instant Feedback**: Actions complete in < 2 seconds (with loading states)
- [ ] **G3 — Parallel Development**: Frontend works with mocks, integrates with real backend when ready

---

## 3. Non-Goals / Out of Scope

To keep this PR focused and shippable:

- [ ] **Not doing** AI-powered message composition (future PR)
- [ ] **Not doing** Multi-message selection for batch operations (v2 feature)
- [ ] **Not doing** Custom AI action creation (use predefined 3 actions only)
- [ ] **Not doing** Voice-based contextual actions (Phase 4)
- [ ] **Not doing** Real RAG backend integration (PR #005 handles that separately)
- [ ] **Not doing** Persistent storage of AI-generated content (in-memory only for now)

---

## 4. Success Metrics

Reference `Psst/agents/shared-standards.md` for metric templates:

### User-Visible
- **Discoverability**: 80%+ of trainers discover long-press menu within first 5 messages
- **Usage**: Average 3+ contextual AI actions per conversation session
- **Time Saved**: 15-30 seconds per action vs. switching to AI Assistant
- **Flow Completion**: 90%+ of initiated actions complete successfully

### System
- **Response Time**: < 2 seconds for mock responses (target for real backend)
- **UI Responsiveness**: Long-press gesture triggers menu in < 50ms
- **Memory**: AI results display without blocking main thread
- **Tap Feedback**: Haptic feedback triggers within 16ms of long-press

### Quality
- **0 blocking bugs** before shipping
- **All acceptance gates pass** (see Section 12)
- **Crash-free rate >99%** for AI actions
- **Smooth animations** for menu appearance/dismissal (60fps)

---

## 5. Users & Stories

### Primary User: Alex - The Adaptive Trainer
**Context**: Manages 20 clients with constantly changing situations (injuries, travel, equipment)

**User Stories**:

1. **As Alex**, I want to **long-press a message about a client's knee pain** so that **I can instantly see past mentions of that injury without searching manually**.

2. **As Alex**, I want to **summarize a long conversation thread** so that **I can quickly understand what was discussed before responding**.

3. **As Alex**, I want to **set a reminder from a message** so that **I don't forget to follow up on important client requests**.

4. **As Alex**, I want to **see related past conversations** so that **I can provide personalized advice based on client history**.

5. **As Alex**, I want **contextual AI actions to feel native to the messaging experience** so that **I stay focused on the conversation without mental context switching**.

### Secondary User: Marcus - The Remote Worker Trainer
**Context**: Manages 30+ clients, always on the go, wants quick actions

**User Stories**:

1. **As Marcus**, I want to **quickly summarize group conversations** so that **I can catch up on what I missed while training other clients**.

2. **As Marcus**, I want to **create reminders without leaving the chat** so that **I can keep my workflow fast and uninterrupted**.

---

## 6. Experience Specification (UX)

### Entry Points and Flows

**Primary Entry Point**: Long-press gesture on any message in ChatView

**User Flow (Happy Path)**:
1. User long-presses a message bubble
2. Haptic feedback triggers immediately
3. Contextual menu appears with 3 options + icons
4. User taps an action
5. Loading indicator appears inline
6. AI result displays in overlay/modal
7. User dismisses result, returns to conversation

### Visual Behavior

**Long-Press Menu**:
- **Trigger**: Long-press (0.5s) on any message bubble
- **Appearance**: Smooth slide-in animation from message (150ms)
- **Styling**: Translucent background blur, rounded corners, subtle shadow
- **Layout**: Vertical stack of 3 buttons with icons:
  - 📊 Summarize Conversation
  - 🔍 Surface Context
  - 🔔 Set Reminder
- **Haptic Feedback**: Medium impact on menu appearance
- **Dismissal**: Tap outside menu, tap action, or swipe down

**Loading States**:
- **Inline Spinner**: Shows below selected message while AI processes
- **Text**: "AI is analyzing..." (1-2s duration with mocks)
- **Animation**: Subtle pulsing, matches app accent color
- **Cancellation**: Optional "Cancel" button for long operations

**Result Display**:
- **Summarize**: Modal with markdown-formatted summary, copy button, dismiss
- **Surface Context**: Inline expansion showing 3-5 related messages with timestamps
- **Set Reminder**: Bottom sheet with pre-filled reminder text, datetime picker, save/cancel

**Error States**:
- **AI Unavailable**: "AI is temporarily unavailable. Try again in a moment."
- **Network Offline**: "No internet connection. AI features require connectivity."
- **Invalid Request**: "Couldn't process this message. Try a different one."

**Empty States**:
- **No Context Found**: "No related conversations found for this message."
- **Too Short to Summarize**: "This conversation is too short to summarize."

### Animations
- **Menu Appear**: Spring animation (mass: 1.0, stiffness: 180, damping: 18)
- **Menu Dismiss**: Fade + scale down (200ms)
- **Result Appear**: Slide up from bottom (300ms ease-out)
- **Loading Pulse**: Opacity 0.3 → 1.0 (1s repeat)

### Performance Targets
See `Psst/agents/shared-standards.md`:
- **Long-press recognition**: < 50ms
- **Menu render**: < 100ms
- **AI response (mock)**: < 2 seconds
- **Smooth animations**: 60fps throughout
- **No UI blocking**: Main thread always responsive

---

## 7. Functional Requirements (Must/Should)

### MUST Requirements

**MUST-1: Long-Press Gesture Recognition**
- Recognize long-press (0.5s hold) on message bubbles
- Trigger haptic feedback on recognition
- Work on both user and sender messages
- Cancel if user drags finger away

**Acceptance Gate**: Long-press any message → Menu appears in < 100ms with haptic feedback

---

**MUST-2: Three Contextual Actions**

**Action 1: Summarize Conversation**
- Displays concise summary of conversation or selected message thread
- Shows key points in bullet format
- Includes participant names and timeframe
- Mock response: "John discussed knee pain (3 days ago), mentioned squats causing issues, prefers low-impact exercises."

**Acceptance Gate**: Tap "Summarize Conversation" → Modal appears with formatted summary in < 2s

---

**Action 2: Surface Context**
- Searches past messages for related topics
- Displays 3-5 most relevant messages with timestamps
- Shows sender names and message previews
- Mock response: Returns 3 pre-defined messages related to the selected message topic

**Acceptance Gate**: Tap "Surface Context" → Inline display shows 3 related messages with "2 weeks ago" timestamps

---

**Action 3: Set Reminder**
- Extracts key information from message
- Pre-fills reminder text
- Shows datetime picker
- Saves reminder to local storage (or Firestore if implemented)
- Mock response: "Reminder: Follow up with John about knee pain. Suggested: Tomorrow 9am"

**Acceptance Gate**: Tap "Set Reminder" → Bottom sheet shows pre-filled reminder text + datetime picker

---

**MUST-3: Mock AI Service Integration**
- Create `MockAIService.swift` with predefined responses
- Simulate network delay (0.5-1.5s random)
- Return contextually appropriate responses based on message content
- Support fallback to generic responses

**Acceptance Gate**: All 3 actions return mock responses that feel realistic and contextually appropriate

---

**MUST-4: Loading States**
- Show inline loading indicator during AI processing
- Display "AI is analyzing..." text
- Prevent duplicate requests while loading
- Timeout after 10s with error message

**Acceptance Gate**: Trigger action → Loading indicator appears → Disappears when result shows

---

**MUST-5: Error Handling**
- Handle network offline gracefully
- Handle AI service failures with retry option
- Show user-friendly error messages
- Log errors for debugging

**Acceptance Gate**: Enable airplane mode → Trigger action → Shows "No internet connection" error

---

**MUST-6: Smooth Animations**
- Menu appearance with spring animation
- Result display with slide-up animation
- Dismissal with fade + scale
- 60fps performance throughout

**Acceptance Gate**: Trigger menu 10 times → No dropped frames, smooth throughout

---

### SHOULD Requirements

**SHOULD-1: Keyboard Dismissal**
- Automatically dismiss keyboard when long-press is recognized
- Prevents keyboard from blocking menu

**SHOULD-2: Accessibility Support**
- VoiceOver labels for all menu actions
- Dynamic Type support for result text
- High contrast mode compatibility

**SHOULD-3: Result Persistence**
- Keep last result visible until dismissed
- Allow re-reading summaries without re-requesting

---

## 8. Data Model

### New Models

#### AIContextAction (Enum)
```swift
enum AIContextAction: String, CaseIterable, Identifiable {
    case summarize = "Summarize Conversation"
    case surfaceContext = "Surface Context"
    case setReminder = "Set Reminder"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .summarize: return "chart.bar.doc.horizontal"
        case .surfaceContext: return "magnifyingglass.circle"
        case .setReminder: return "bell.badge"
        }
    }
    
    var description: String {
        switch self {
        case .summarize: 
            return "Get a concise summary of this conversation"
        case .surfaceContext: 
            return "Find related past conversations"
        case .setReminder: 
            return "Create a follow-up reminder from this message"
        }
    }
}
```

#### AIContextResult
```swift
struct AIContextResult: Identifiable, Codable {
    let id: String
    let action: AIContextAction
    let sourceMessageID: String
    let result: AIResultContent
    let timestamp: Date
    let isLoading: Bool
    let error: String?
}

enum AIResultContent: Codable {
    case summary(text: String, keyPoints: [String])
    case relatedMessages([RelatedMessage])
    case reminder(ReminderSuggestion)
}

struct RelatedMessage: Identifiable, Codable {
    let id: String
    let messageID: String
    let text: String
    let senderName: String
    let timestamp: Date
    let relevanceScore: Double // 0.0 - 1.0
}

struct ReminderSuggestion: Codable {
    let text: String
    let suggestedDate: Date
    let extractedInfo: [String: String] // e.g., ["client": "John", "topic": "knee pain"]
}
```

### Modified Models

No changes to existing `Message.swift` or `Chat.swift` models. Contextual actions read existing data without modification.

---

## 9. API / Service Contracts

### AIService Extensions

```swift
// services/AIService.swift

class AIService: ObservableObject {
    
    // Existing methods from PR #004...
    
    // MARK: - Contextual Actions (PR #006)
    
    /// Generates a conversation summary for the given messages
    /// - Parameters:
    ///   - messages: Array of messages to summarize
    ///   - chatID: The chat ID for context
    /// - Returns: Summary text and key points
    /// - Throws: AIError if service fails
    func summarizeConversation(
        messages: [Message], 
        chatID: String
    ) async throws -> (summary: String, keyPoints: [String]) {
        // Implementation: Calls mock service or real Cloud Function
        // Mock: Returns pre-defined summary based on message count/content
        // Real (future): Calls Firebase Cloud Function with RAG context
    }
    
    /// Surfaces related context for a specific message
    /// - Parameters:
    ///   - message: The message to find context for
    ///   - chatID: The chat ID to search within
    ///   - limit: Maximum number of related messages (default: 5)
    /// - Returns: Array of related messages with relevance scores
    /// - Throws: AIError if service fails
    func surfaceContext(
        for message: Message, 
        chatID: String, 
        limit: Int = 5
    ) async throws -> [RelatedMessage] {
        // Implementation: Calls mock service or real Cloud Function
        // Mock: Returns 3 pre-defined messages with timestamps
        // Real (future): Calls RAG pipeline to find semantically similar messages
    }
    
    /// Creates a reminder suggestion from a message
    /// - Parameters:
    ///   - message: The message to extract reminder from
    ///   - senderName: Name of the message sender
    /// - Returns: Reminder suggestion with pre-filled text and date
    /// - Throws: AIError if service fails
    func createReminderSuggestion(
        from message: Message, 
        senderName: String
    ) async throws -> ReminderSuggestion {
        // Implementation: Calls mock service or real Cloud Function
        // Mock: Extracts keywords and suggests tomorrow 9am
        // Real (future): Uses AI to extract action items and suggest optimal time
    }
}
```

### MockAIService (For Parallel Development)

```swift
// services/MockAIService.swift

class MockAIService {
    
    /// Simulates network delay for realistic UX testing
    private func simulateDelay() async {
        let delay = Double.random(in: 0.5...1.5)
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    }
    
    /// Mock implementation of summarizeConversation
    static func mockSummarize(messages: [Message]) async -> (String, [String]) {
        await simulateDelay()
        
        let messageCount = messages.count
        let summary = "Conversation between you and \(messages.first?.senderID ?? "client") covered \(messageCount) messages over the past 3 days."
        
        let keyPoints = [
            "Discussed knee pain during squats",
            "Mentioned preference for low-impact exercises",
            "Planning to try swimming next week"
        ]
        
        return (summary, keyPoints)
    }
    
    /// Mock implementation of surfaceContext
    static func mockSurfaceContext(for message: Message) async -> [RelatedMessage] {
        await simulateDelay()
        
        // Return 3 contextually similar messages
        return [
            RelatedMessage(
                id: UUID().uuidString,
                messageID: "mock_1",
                text: "My knee has been bothering me after squats",
                senderName: "John Doe",
                timestamp: Date().addingTimeInterval(-14 * 24 * 60 * 60), // 2 weeks ago
                relevanceScore: 0.92
            ),
            RelatedMessage(
                id: UUID().uuidString,
                messageID: "mock_2",
                text: "Should I avoid squats or just modify them?",
                senderName: "John Doe",
                timestamp: Date().addingTimeInterval(-10 * 24 * 60 * 60), // 10 days ago
                relevanceScore: 0.87
            ),
            RelatedMessage(
                id: UUID().uuidString,
                messageID: "mock_3",
                text: "Knee feels better after trying lighter weights",
                senderName: "John Doe",
                timestamp: Date().addingTimeInterval(-5 * 24 * 60 * 60), // 5 days ago
                relevanceScore: 0.81
            )
        ]
    }
    
    /// Mock implementation of createReminderSuggestion
    static func mockReminder(from message: Message, senderName: String) async -> ReminderSuggestion {
        await simulateDelay()
        
        return ReminderSuggestion(
            text: "Follow up with \(senderName) about: \(message.text.prefix(50))...",
            suggestedDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())!,
            extractedInfo: [
                "client": senderName,
                "topic": "Message follow-up",
                "priority": "medium"
            ]
        )
    }
}
```

### Error Types

```swift
enum AIError: LocalizedError {
    case networkUnavailable
    case serviceTimeout
    case invalidRequest
    case rateLimitExceeded
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "No internet connection. AI features require connectivity."
        case .serviceTimeout:
            return "AI is taking too long. Try again in a moment."
        case .invalidRequest:
            return "Couldn't process this message. Try a different one."
        case .rateLimitExceeded:
            return "Too many requests. Please wait 30 seconds."
        case .unknownError(let message):
            return "AI error: \(message)"
        }
    }
}
```

---

## 10. UI Components to Create/Modify

### New Components

**Views/Components/ContextualAIMenu.swift**
- Purpose: Long-press menu with 3 AI action buttons
- Props: `message: Message`, `onActionSelected: (AIContextAction) -> Void`, `onDismiss: () -> Void`
- Layout: Vertical stack, translucent background, icons + text

**Views/Components/AILoadingIndicator.swift**
- Purpose: Inline loading state during AI processing
- Props: `message: String` (default: "AI is analyzing...")
- Animation: Pulsing opacity

**Views/Components/AISummaryView.swift**
- Purpose: Modal display for conversation summaries
- Props: `summary: String`, `keyPoints: [String]`, `onDismiss: () -> Void`
- Features: Markdown formatting, copy button

**Views/Components/AIRelatedMessagesView.swift**
- Purpose: Inline display of related messages
- Props: `relatedMessages: [RelatedMessage]`, `onMessageTap: (String) -> Void`
- Layout: Vertical list with timestamps, sender names

**Views/Components/AIReminderSheet.swift**
- Purpose: Bottom sheet for creating reminders
- Props: `suggestion: ReminderSuggestion`, `onSave: (String, Date) -> Void`, `onCancel: () -> Void`
- Features: Editable text field, datetime picker

### Modified Components

**Views/ChatList/MessageRow.swift**
- Add: Long-press gesture recognizer
- Add: State for showing contextual menu
- Add: Conditional overlay for ContextualAIMenu
- Modify: No changes to existing layout

**Views/ChatList/ChatView.swift**
- Add: State for active AI action results
- Add: Overlay for result displays (summary modal, related messages)
- Modify: No changes to message list layout

### New ViewModels

**ViewModels/ContextualAIViewModel.swift**
- Purpose: Manages contextual AI action state
- Properties:
  - `@Published var activeAction: AIContextAction?`
  - `@Published var isLoading: Bool = false`
  - `@Published var currentResult: AIContextResult?`
  - `@Published var error: AIError?`
- Methods:
  - `func performAction(_ action: AIContextAction, on message: Message, in chatID: String)`
  - `func dismissResult()`
  - `func retryLastAction()`

### New Services

**Services/MockAIService.swift**
- Purpose: Provides mock AI responses for parallel development
- Methods: Static methods matching AIService interface
- Features: Simulated network delay, contextual mock data

---

## 11. Integration Points

### Firebase (Read-Only)
- **Firestore**: Read messages from `/chats/{chatID}/messages` for context
- **Authentication**: Verify user auth before AI operations
- **No writes**: Mock implementation doesn't persist AI results yet

### AIService (From PR #004)
- Extend existing `AIService` class with contextual action methods
- Use mock implementation initially
- Swap to real Cloud Function calls when PR #005 merges

### State Management
- **SwiftUI**: `@State`, `@StateObject`, `@EnvironmentObject` patterns
- **ContextualAIViewModel**: `@StateObject` in ChatView
- **Real-time Updates**: No Firestore listeners needed (one-time actions)

### Navigation
- **No navigation**: Actions happen inline or in modals
- **Dismiss**: Return to conversation after action completes

---

## 12. Testing Plan & Acceptance Gates

**Define these 3 scenarios BEFORE implementation.**

See `Psst/docs/testing-strategy.md` for examples and detailed guidance.

---

### Happy Path

**Scenario**: User long-presses message and successfully gets a conversation summary

**Steps**:
1. Open ChatView with 10+ messages
2. Long-press a message in the middle of conversation
3. Contextual menu appears with 3 options
4. Tap "📊 Summarize Conversation"
5. Loading indicator shows "AI is analyzing..."
6. After 1-2 seconds, modal appears with summary
7. Summary includes key points in bullet format
8. User taps "Dismiss" or outside modal
9. Returns to conversation view

**Pass Criteria**:
- [ ] **Gate 1**: Long-press triggers menu in < 100ms with haptic feedback
- [ ] **Gate 2**: Menu shows 3 actions with icons and labels
- [ ] **Gate 3**: Loading indicator appears immediately on action tap
- [ ] **Gate 4**: Mock summary returns in < 2 seconds
- [ ] **Gate 5**: Summary displays in readable modal with dismiss button
- [ ] **Gate 6**: No console errors throughout flow
- [ ] **Gate 7**: Smooth 60fps animations for menu and modal

---

### Edge Cases

**Edge Case 1: Long-Press on Very Short Conversation**

**Test**: Open chat with only 2 messages → Long-press → Summarize
**Expected**: Shows summary like "Brief conversation between you and John. Discussed workout scheduling." (still provides value even if short)
**Pass**: No crash, appropriate summary shown, no "too short" error

---

**Edge Case 2: Surface Context When No Related Messages Exist**

**Test**: Long-press message → Surface Context → Mock returns empty array
**Expected**: Shows "No related conversations found for this message." with dismiss button
**Pass**: User-friendly empty state, no crash, can dismiss and try again

---

**Edge Case 3: Rapid Long-Press on Multiple Messages**

**Test**: Long-press message 1 → Immediately long-press message 2 before menu appears
**Expected**: First menu cancels, second menu appears for message 2
**Pass**: No menu overlap, no crash, correct message context in menu

---

**Edge Case 4: Dismiss Menu Mid-Action**

**Test**: Long-press → Tap action → Tap outside loading indicator while AI is processing
**Expected**: Action cancels, loading stops, no result shown, can retry
**Pass**: Graceful cancellation, no hanging state

---

### Error Handling

**Offline Mode**

**Test**: Enable airplane mode → Long-press → Tap any action
**Expected**: 
- Loading indicator appears
- After timeout (2s with mock), error shows: "No internet connection. AI features require connectivity."
- Retry button available
**Pass**: Clear error message, no crash, retry option works when back online

---

**Invalid Input (Future Real Backend)**

**Test**: Long-press message with only emoji ("👍") → Summarize
**Expected** (with mocks): Still provides generic summary
**Pass**: No crash, handles gracefully

---

**Service Timeout**

**Test**: Simulate 10+ second delay in mock service
**Expected**: 
- Loading indicator shows for 10s
- Timeout triggers
- Error: "AI is taking too long. Try again in a moment."
- Retry button available
**Pass**: Timeout handled, user can retry

---

### Multi-Device Testing

**Not Required**: Contextual AI actions are local-only (no sync needed). Results don't persist across devices.

---

### Performance Check

**Subjective Tests**:
- [ ] Long-press feels responsive (< 50ms recognition)
- [ ] Menu animations are smooth (60fps, no jank)
- [ ] No UI blocking during AI processing
- [ ] Loading states feel polished, not janky
- [ ] Haptic feedback feels appropriate (not too strong/weak)

**Objective Tests**:
- [ ] Measure long-press recognition time: < 50ms
- [ ] Measure menu render time: < 100ms
- [ ] Measure mock AI response time: < 2 seconds
- [ ] Instruments check: 60fps during all animations

---

### Acceptance Gates Summary

All actions must pass these gates:

**Summarize Conversation**:
- [ ] Returns summary text with 3-5 key points
- [ ] Displays in modal with readable typography
- [ ] Copy button works
- [ ] Dismiss returns to conversation

**Surface Context**:
- [ ] Returns 3-5 related messages with timestamps
- [ ] Shows sender names and message previews
- [ ] Tapping related message scrolls to original (optional v2)
- [ ] Empty state shown if no results

**Set Reminder**:
- [ ] Pre-fills reminder text from message content
- [ ] Shows datetime picker with default tomorrow 9am
- [ ] Save button creates reminder (local storage or Firestore)
- [ ] Cancel dismisses without saving

---

## 13. Definition of Done

See standards in `Psst/agents/shared-standards.md`:

- [ ] All 3 contextual AI actions implemented (Summarize, Surface Context, Set Reminder)
- [ ] Long-press gesture works on all message types (text, image)
- [ ] MockAIService provides realistic responses with simulated delay
- [ ] Loading states show for all actions
- [ ] Error handling covers offline, timeout, invalid input
- [ ] Smooth animations for menu, loading, results (60fps)
- [ ] Haptic feedback on long-press recognition
- [ ] All acceptance gates pass (12 total gates)
- [ ] Manual testing completed (happy path, edge cases, errors)
- [ ] No console errors or warnings
- [ ] Code follows `Psst/agents/shared-standards.md` patterns
- [ ] VoiceOver labels added for accessibility
- [ ] Dynamic Type support verified
- [ ] Documentation comments on public methods
- [ ] PR description includes before/after demo video
- [ ] Ready for real backend integration when PR #005 merges

---

## 14. Risks & Mitigations

### Risk 1: Long-Press Conflicts with iOS System Gestures
**Impact**: Medium  
**Likelihood**: Low  
**Mitigation**: 
- Test on real devices (not just simulator)
- Ensure long-press duration (0.5s) doesn't conflict with text selection
- Add option to disable contextual menu in settings if conflicts arise

---

### Risk 2: Mock Responses Feel Unrealistic
**Impact**: Medium (affects UX testing)  
**Likelihood**: Medium  
**Mitigation**:
- Use contextually appropriate mock data
- Vary responses based on message content (detect keywords)
- Get user feedback on mock quality before building real backend

---

### Risk 3: Backend Integration Requires Significant Refactoring
**Impact**: High  
**Likelihood**: Low  
**Mitigation**:
- Design service interface to match expected Cloud Function API
- Use dependency injection for easy mock → real service swap
- Coordinate with PR #005 agent on API contract early
- Document integration points in this PRD

---

### Risk 4: Performance Degradation with Long Conversations
**Impact**: Medium  
**Likelihood**: Low (mocks are fast)  
**Mitigation**:
- Limit summarization to last 100 messages
- Implement pagination for related messages
- Profile with Instruments for large datasets

---

### Risk 5: User Confusion About AI Capabilities
**Impact**: Medium  
**Likelihood**: Medium  
**Mitigation**:
- Clear action labels ("Summarize Conversation" not just "Summarize")
- Show "Mock AI" label during development
- Include onboarding tooltip on first long-press
- Error messages explain what AI can/cannot do

---

## 15. Rollout & Telemetry

### Feature Flag
**Yes** - Recommended for phased rollout

```swift
struct FeatureFlags {
    static let contextualAIEnabled = true // Toggle in settings or remote config
}
```

### Metrics to Track (Future)
- **Usage**: Number of contextual AI actions per user per day
- **Action Distribution**: Which action is most popular (Summarize vs Context vs Reminder)
- **Errors**: AI error rate by type (network, timeout, invalid)
- **Latency**: Average response time for each action type
- **Completion Rate**: % of started actions that complete successfully

### Manual Validation Steps
Before shipping:
1. ✅ Test on iPhone 13+ (various screen sizes)
2. ✅ Test on iOS 16, 17, 18 (compatibility)
3. ✅ Verify VoiceOver reads action labels correctly
4. ✅ Test in dark mode and light mode
5. ✅ Verify haptic feedback works on real device
6. ✅ Test offline mode thoroughly
7. ✅ Demo to 2-3 beta testers for UX feedback

---

## 16. Open Questions

### Q1: Should Related Messages be Tappable to Scroll to Original?
**Decision Needed**: Yes/No/v2  
**Owner**: UX Designer (Claudia) or User  
**Impact**: Medium (UX polish)  
**Recommendation**: Nice-to-have for v2, keep v1 simple

---

### Q2: Where Should Reminders be Stored?
**Decision Needed**: Local storage (UserDefaults) vs Firestore vs iOS Reminders app  
**Owner**: Product/Architect  
**Impact**: High (affects persistence strategy)  
**Recommendation**: Start with Firestore collection `/users/{userID}/reminders` for cross-device sync

---

### Q3: Should We Show "Mock AI" Label During Development?
**Decision Needed**: Yes/No  
**Owner**: Product  
**Impact**: Low (transparency)  
**Recommendation**: Yes - add small "Mock" badge in results during development, remove when real backend ships

---

### Q4: How to Handle Backend Integration When PR #005 Completes?
**Decision Needed**: Automatic swap vs manual testing phase  
**Owner**: Engineering (Caleb)  
**Impact**: High (deployment strategy)  
**Recommendation**: 
- Feature flag: `useRealAIBackend` (default: false)
- Test real backend thoroughly before flipping flag
- Keep mock service as fallback if backend fails

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future PRs:

- [ ] **Customizable AI Actions**: Let users define their own long-press actions
- [ ] **Multi-Message Selection**: Select multiple messages for batch summarization
- [ ] **Voice-Based Actions**: Trigger contextual AI via voice command
- [ ] **Persistent AI Results**: Save summaries/context to Firestore for later reference
- [ ] **AI Action History**: View past AI actions and results
- [ ] **Smart Suggestions**: AI proactively suggests when to use contextual actions
- [ ] **Group Chat Context**: Surface context across multiple group chats
- [ ] **Client-Specific AI Profiles**: Contextual actions learn from client history
- [ ] **Export AI Results**: Share summaries via email/message
- [ ] **Keyboard Shortcuts**: Mac Catalyst support for keyboard-triggered actions

---

## 18. Backend Integration Plan (When PR #005 Completes)

### Step 1: Verify Cloud Function API Contract
**What to Check**:
- Endpoint exists: `chatWithAI(query, userId, conversationId)`
- RAG search function: `semanticSearch(query, userId, limit)`
- Response format matches `AIContextResult` model

### Step 2: Update AIService
**Changes**:
```swift
// Before (Mock)
func surfaceContext(for message: Message, chatID: String, limit: Int = 5) async throws -> [RelatedMessage] {
    return await MockAIService.mockSurfaceContext(for: message)
}

// After (Real Backend)
func surfaceContext(for message: Message, chatID: String, limit: Int = 5) async throws -> [RelatedMessage] {
    let functions = Functions.functions()
    let data: [String: Any] = [
        "query": message.text,
        "userId": Auth.auth().currentUser?.uid ?? "",
        "chatId": chatID,
        "limit": limit
    ]
    
    let result = try await functions.httpsCallable("semanticSearch").call(data)
    
    // Parse result into [RelatedMessage]
    guard let messages = result.data as? [[String: Any]] else {
        throw AIError.invalidRequest
    }
    
    return messages.compactMap { parseRelatedMessage($0) }
}
```

### Step 3: Add Feature Flag Toggle
```swift
struct FeatureFlags {
    static let useRealAIBackend = false // Flip to true after testing
}

// In AIService
func surfaceContext(...) async throws -> [RelatedMessage] {
    if FeatureFlags.useRealAIBackend {
        return try await realSurfaceContext(...)
    } else {
        return await MockAIService.mockSurfaceContext(...)
    }
}
```

### Step 4: Testing Checklist
- [ ] Test all 3 actions with real backend
- [ ] Verify response times < 5 seconds (real may be slower than mocks)
- [ ] Test error handling with real backend failures
- [ ] Verify semantic search quality (do results make sense?)
- [ ] Compare mock vs real responses for UX differences

### Step 5: Gradual Rollout
- [ ] Ship with `useRealAIBackend = false` (mocks)
- [ ] Flip flag for internal testing
- [ ] Monitor error rates and latency
- [ ] Ship to beta testers
- [ ] Ship to production if all metrics pass

---

## 19. Preflight Questionnaire

**1. Smallest end-to-end user outcome for this PR?**  
Trainer long-presses a message → Gets AI-powered summary/context/reminder → Returns to conversation without leaving the chat screen.

**2. Primary user and critical action?**  
Alex (Adaptive Trainer) long-pressing client message to surface past injury context before responding.

**3. Must-have vs nice-to-have?**  
**Must-have**: 3 actions (Summarize, Context, Reminder), long-press gesture, mock service, loading/error states  
**Nice-to-have**: Tappable related messages, reminder persistence, analytics, VoiceOver (should-have)

**4. Real-time requirements?**  
None. Contextual actions are one-time requests, no sync needed.

**5. Performance constraints?**  
- Long-press recognition < 50ms
- Menu render < 100ms
- Mock AI response < 2 seconds
- 60fps animations throughout

**6. Error/edge cases to handle?**  
- Offline mode (no internet)
- Service timeout (> 10s)
- No related messages found
- Very short conversations
- Rapid long-presses on multiple messages

**7. Data model changes?**  
New models: `AIContextAction`, `AIContextResult`, `RelatedMessage`, `ReminderSuggestion`  
No changes to existing models.

**8. Service APIs required?**  
- `summarizeConversation(messages, chatID) -> (summary, keyPoints)`
- `surfaceContext(message, chatID, limit) -> [RelatedMessage]`
- `createReminderSuggestion(message, senderName) -> ReminderSuggestion`

**9. UI entry points and states?**  
**Entry**: Long-press on message bubble  
**States**: Menu visible, loading, result display (modal/inline), error, dismissed

**10. Security/permissions implications?**  
- Requires Firebase Authentication (existing)
- Read-only access to Firestore messages (existing)
- No new permissions needed
- Future: Rate limiting on Cloud Functions (PR #005 handles)

**11. Dependencies or blocking integrations?**  
- Depends on PR #004 (AI Chat UI) for AIService foundation
- Parallel with PR #005 (RAG Pipeline) - uses mocks initially
- No blocking dependencies for this PR

**12. Rollout strategy and metrics?**  
- Ship with feature flag (default: enabled)
- Monitor usage: actions per user, completion rate, error rate
- Manual validation on 3+ devices before production

**13. What is explicitly out of scope?**  
- Real RAG backend integration (PR #005)
- Persistent AI result storage
- Multi-message selection
- Voice-based actions
- Custom action creation
- Client-side AI features

---

## 20. Authoring Notes

**For Caleb (Coder Agent)**:

### Parallel Development Strategy
- Build this PR while PR #005 is in progress
- Use mocks to simulate backend behavior
- Design service interface to match expected Cloud Function API
- Coordinate with PR #005 agent on API contract

### Mock Quality Matters
- Make mocks feel realistic (vary responses, simulate delay)
- Use contextual keywords to return appropriate mock data
- Test UX thoroughly with mocks before real backend ships

### Service Interface Design
```swift
// Design pattern for easy mock → real swap
protocol AIContextServiceProtocol {
    func summarizeConversation(messages: [Message], chatID: String) async throws -> (String, [String])
    func surfaceContext(for message: Message, chatID: String, limit: Int) async throws -> [RelatedMessage]
    func createReminderSuggestion(from message: Message, senderName: String) async throws -> ReminderSuggestion
}

class MockAIContextService: AIContextServiceProtocol { /* ... */ }
class RealAIContextService: AIContextServiceProtocol { /* ... */ }

// In AIService, use dependency injection
class AIService {
    private let contextService: AIContextServiceProtocol
    
    init(contextService: AIContextServiceProtocol = MockAIContextService()) {
        self.contextService = contextService
    }
}
```

### Testing Priority
1. Happy path with mocks (core UX)
2. Error handling (offline, timeout)
3. Edge cases (short conversation, no results)
4. Performance (animations, responsiveness)
5. Accessibility (VoiceOver, Dynamic Type)

### Reference
- `Psst/agents/shared-standards.md` for code quality, performance, testing standards
- `Psst/docs/architecture.md` for service layer patterns
- `Psst/docs/AI-PRODUCT-VISION.md` for user personas and pain points

---

**Status**: ✅ PRD Complete - Ready for Review  
**Next Step**: User review and approval before creating TODO

