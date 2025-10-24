# PRD: AI Chat UI

**Feature**: AI Assistant Chat Interface

**Version**: 1.0

**Status**: Draft

**Agent**: Caleb (Coder Agent)

**Target Release**: Phase 2 - Basic AI Chat

**Links**: 
- [PR Brief](../ai-briefs.md#pr-004-ai-chat-ui)
- [TODO](../todos/pr-004-todo.md)
- [Architecture](../architecture.md#ai-system-integration-plan)

---

## 1. Summary

Trainers need a dedicated interface to interact with their AI assistant for instant answers about clients and conversations. This PR builds the complete user-facing AI Assistant chat interface on top of the existing iOS AI scaffolding (PR #002), enabling trainers to ask questions like "What did John say about his knee?" and receive AI-generated responses in a familiar chat experience.

---

## 2. Problem & Goals

**Problem:** Trainers manage 20-30+ clients and lose track of important details (injuries, goals, preferences). They need a "second brain" to instantly recall client information without manually searching through hundreds of messages.

**Why Now:** The iOS AI scaffolding (PR #002) and backend infrastructure (PR #001, PR #003) are complete. This is the first user-facing AI feature that delivers immediate value.

**Goals:**
- [ ] G1 — Trainers can send questions to AI and receive responses within 3 seconds
- [ ] G2 — AI chat interface feels natural and familiar (like messaging another person)
- [ ] G3 — Trainers can access AI assistant from any screen in <2 taps

---

## 3. Non-Goals / Out of Scope

To avoid scope creep, this PR explicitly excludes:

- [ ] Voice input/output (deferred to PR #010)
- [ ] AI function calling (send messages, set reminders) - PR #008
- [ ] Contextual AI actions in regular chats (long-press menu) - PR #006
- [ ] RAG/semantic search - PR #005 (AI will have limited context initially)
- [ ] Conversation history persistence (in-memory only for Phase 2)
- [ ] AI response streaming (initial version shows complete response)

---

## 4. Success Metrics

**User-visible:**
- Time to access AI assistant: < 2 taps from any screen
- AI response time: < 3 seconds for typical queries
- User completes full AI conversation: > 80% (ask follow-up questions)

**System:**
- API latency to Cloud Function: < 1 second
- UI remains responsive during AI processing (no blocking)
- Smooth scrolling with 20+ messages at 60fps

**Quality:**
- 0 blocking bugs in AI chat flow
- Crash-free rate > 99%
- All acceptance gates pass

---

## 5. Users & Stories

**Primary User:** Marcus (Remote Worker Trainer) and Alex (Adaptive Trainer)

**User Stories:**
- As a trainer, I want to ask AI "What did Sarah say about her diet?" so I can give personalized advice without searching manually
- As a trainer, I want to see AI responses in familiar chat bubbles so the interface feels natural
- As a trainer, I want to access the AI assistant quickly so I can get answers while on the go
- As a trainer, I want to see when AI is thinking so I know my request is being processed
- As a trainer, I want clear error messages when AI is unavailable so I know what went wrong

---

## 5b. Affected Existing Code

This PR **enhances** existing iOS AI scaffolding from PR #002. The following files will be **MODIFIED**:

**Services:**
- `Services/AIService.swift` - Replace mock implementation with real Cloud Function calls to `chatWithAI` endpoint

**Views:**
- `Views/AI/AIAssistantView.swift` - Already exists as complete chat interface; will enhance with error handling, empty states, and polish
- `Views/AI/AIMessageRow.swift` - Already exists; minor styling updates for production readiness
- `Views/MainTabView.swift` - Add AI Assistant tab or floating button to navigation

**ViewModels:**
- `ViewModels/AIAssistantViewModel.swift` - Already exists; will enhance with real API integration and error states

**Models:**
- `Models/AIMessage.swift` - Already exists; confirm structure matches backend response
- `Models/AIConversation.swift` - Already exists; may need minor updates
- `Models/AIResponse.swift` - Already exists; validate against Cloud Function response format

**Integration Pattern:**
The existing scaffolding provides a solid foundation. This PR focuses on:
1. Connecting mock UI to real backend (AIService → Cloud Function)
2. Production-ready error handling and edge cases
3. Polished UX (loading states, animations, empty states)
4. Navigation integration (floating AI button or tab)

---

## 6. Experience Specification (UX)

### Entry Points

1. **Primary:** Floating AI button (🤖) in ChatListView (bottom-right corner)
2. **Alternative:** "AI Assistant" tab in MainTabView (if tab design preferred)

### User Flow

```
User opens ChatListView
  ↓
Sees floating 🤖 button (always visible)
  ↓
Taps button → AIAssistantView slides up
  ↓
Sees empty state: "Hi! Ask me anything about your clients or conversations."
  ↓
User types: "What did John say about his knee?"
  ↓
Taps send → Message appears immediately (user bubble, blue)
  ↓
Loading indicator appears: "AI is thinking..." with animated dots
  ↓
AI response arrives (2-3 seconds)
  ↓
AI message appears (gray bubble, left-aligned)
  ↓
User can ask follow-up question or close view
```

### Visual Behavior

**Chat Interface:**
- User messages: Right-aligned, blue bubble (matches regular chat)
- AI messages: Left-aligned, gray bubble with 🤖 icon
- Input field: Bottom of screen with send button
- Scrolling: Auto-scroll to latest message
- Keyboard: Dismisses on scroll or tap outside

**Loading States:**
- Sending: User message shows immediately (optimistic UI)
- AI thinking: Animated ellipsis "..." below last message
- Empty state: "Ask me anything about your clients" with example prompts

**Error States:**
- AI unavailable: "AI assistant is temporarily unavailable. Try again in a moment."
- Network error: "No internet connection. Check your network and try again."
- Timeout: "Request took too long. Try asking in a different way."

**Empty States:**
- First use: Welcome message + 3 example prompts
  - "What did [client] say about [topic]?"
  - "Summarize my conversation with [client]"
  - "Which clients haven't messaged recently?"

**Animations:**
- View transition: Slide up from bottom (0.3s ease-out)
- Message appearance: Fade in + slight scale (0.2s)
- Loading indicator: Pulse animation
- Keyboard: Follows iOS standard behavior

### Performance Targets

Reference `Psst/agents/shared-standards.md`:
- View load time: < 100ms (cold start)
- Message send: Immediate optimistic update
- AI response: Display within 100ms of receiving from backend
- Smooth 60fps scrolling with 20+ messages
- No UI blocking during API calls

---

## 7. Functional Requirements (Must/Should)

### MUST Requirements

**M1: AI Chat Conversation**
- MUST send user messages to `chatWithAI` Cloud Function with userId, message, conversationId
- MUST display AI responses in chat bubbles
- MUST maintain conversation context (conversationId persists during session)
- MUST handle async API calls without blocking UI

[Gate] When user sends message → appears immediately → AI response arrives within 5 seconds → displays in chat

**M2: Service Integration**
- MUST implement `AIService.chatWithAI()` method calling Firebase Cloud Function
- MUST include proper error handling for network failures, timeouts, and API errors
- MUST use async/await pattern for non-blocking operations
- MUST validate user authentication before API calls

[Gate] Offline user attempts AI chat → shows "No internet connection" → does not crash

**M3: State Management**
- MUST use `AIAssistantViewModel` to manage conversation state
- MUST persist conversationId during active session (in-memory for Phase 2)
- MUST update UI reactively using `@Published` properties
- MUST clear conversation when user closes view (no persistence yet)

[Gate] User sends 3 messages → all appear in order → AI responses maintain context

**M4: Loading & Error States**
- MUST show loading indicator while waiting for AI response
- MUST display user-friendly error messages for all failure scenarios
- MUST provide retry option for failed requests
- MUST handle edge cases (empty messages, very long messages, rapid sends)

[Gate] Network timeout occurs → shows "Request took too long" message → retry button appears

**M5: Navigation & Access**
- MUST provide floating AI button in ChatListView for quick access
- MUST animate view transitions smoothly (slide up/down)
- MUST allow dismissal via swipe-down or close button
- MUST maintain navigation state (user can return to chat list)

[Gate] User taps floating 🤖 button → AIAssistantView opens in < 200ms → smooth animation

### SHOULD Requirements

**S1: Empty State Guidance**
- SHOULD show welcome message and example prompts on first use
- SHOULD provide context about AI capabilities

**S2: Message Timestamps**
- SHOULD display timestamps for AI responses (e.g., "Just now", "2m ago")

**S3: Keyboard Management**
- SHOULD dismiss keyboard on scroll (iOS standard behavior)
- SHOULD auto-focus input field when view opens

**S4: Accessibility**
- SHOULD support VoiceOver for AI messages
- SHOULD support Dynamic Type for text scaling

---

## 8. Data Model

### AIMessage (Existing - Confirm Structure)

```swift
// Models/AIMessage.swift
struct AIMessage: Identifiable, Codable {
    let id: String                  // Unique message ID
    let text: String                // Message content
    let sender: MessageSender       // .user or .ai
    let timestamp: Date             // Message timestamp
    
    enum MessageSender: String, Codable {
        case user
        case ai
    }
}
```

### AIConversation (Existing - Confirm Structure)

```swift
// Models/AIConversation.swift
struct AIConversation: Identifiable, Codable {
    let id: String                  // Conversation ID (UUID)
    var messages: [AIMessage]       // Message history
    let createdAt: Date             // Conversation start time
    var updatedAt: Date             // Last message time
}
```

### AIResponse (Existing - Validate Against Backend)

```swift
// Models/AIResponse.swift
struct AIResponse: Codable {
    let message: String             // AI response text
    let conversationId: String      // Session ID
    let timestamp: Date             // Response timestamp
    
    // Optional error field
    let error: String?              // Error message if request failed
}
```

**Validation Rules:**
- User messages: text.count > 0 && text.count < 2000 (reasonable limit)
- AI responses: Must have valid conversationId
- Timestamps: Use Date() for user messages, backend timestamp for AI responses

**Storage:**
- Phase 2: In-memory only (no Firestore persistence)
- Conversation clears when user closes AIAssistantView
- Future (Phase 3+): Persist to Firestore `/users/{userId}/ai_conversations`

---

## 9. API / Service Contracts

### AIService (Modify Existing)

```swift
// Services/AIService.swift

/// Sends a message to the AI assistant and returns the response
/// - Parameters:
///   - message: User's question or prompt
///   - conversationId: Session ID for conversation context
/// - Returns: AI-generated response text
/// - Throws: AIError for network failures, timeouts, or API errors
func chatWithAI(message: String, conversationId: String) async throws -> AIResponse

/// Validates user message before sending
/// - Parameter message: User input text
/// - Returns: true if valid, false if empty or too long
func validateMessage(_ message: String) -> Bool
```

**Error Handling:**

```swift
enum AIError: LocalizedError {
    case notAuthenticated           // User not logged in
    case invalidMessage             // Empty or too long
    case networkError               // No internet connection
    case timeout                    // Request took > 10 seconds
    case serverError(String)        // Backend error with message
    case unknownError               // Unexpected failure
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please log in to use AI assistant"
        case .invalidMessage:
            return "Message cannot be empty"
        case .networkError:
            return "No internet connection. Check your network and try again."
        case .timeout:
            return "Request took too long. Try asking in a different way."
        case .serverError(let message):
            return "AI Error: \(message)"
        case .unknownError:
            return "Something went wrong. Please try again."
        }
    }
}
```

**Cloud Function Integration:**

```swift
// Firebase Callable Function
// Endpoint: chatWithAI
// Input: {
//   message: String,
//   conversationId: String,
//   userId: String (from auth context)
// }
// Output: {
//   message: String,
//   conversationId: String,
//   timestamp: Timestamp
// }

// Example call:
let functions = Functions.functions()
let chatFunction = functions.httpsCallable("chatWithAI")

let result = try await chatFunction.call([
    "message": userMessage,
    "conversationId": conversationId
])
```

**Pre/Post Conditions:**
- Pre: User must be authenticated (AuthenticationService.currentUser != nil)
- Pre: Message must be validated (not empty, < 2000 chars)
- Post: AIResponse contains valid conversationId
- Post: UI updates with response or error message

---

## 10. UI Components to Create/Modify

### Modify Existing Components

**Views/AI/AIAssistantView.swift** (Exists from PR #002)
- Enhance: Connect to real AIService instead of mock data
- Enhance: Add production error handling and retry logic
- Enhance: Polish empty states and welcome message
- Enhance: Smooth animations and keyboard management

**Views/AI/AIMessageRow.swift** (Exists from PR #002)
- Enhance: Final styling polish for user vs AI messages
- Enhance: Add timestamp display
- Enhance: Accessibility labels for VoiceOver

**ViewModels/AIAssistantViewModel.swift** (Exists from PR #002)
- Enhance: Replace mock implementation with real API calls
- Enhance: Error state management
- Enhance: Conversation persistence during session

**Services/AIService.swift** (Exists from PR #002)
- Enhance: Implement real `chatWithAI()` method with Cloud Function calls
- Enhance: Add `validateMessage()` method
- Enhance: Comprehensive error handling

**Models/AIMessage.swift** (Exists from PR #002)
- Verify: Structure matches backend response format
- Minor updates if needed based on Cloud Function response

**Models/AIConversation.swift** (Exists from PR #002)
- Verify: Supports in-memory conversation state
- Minor updates if needed

**Models/AIResponse.swift** (Exists from PR #002)
- Validate: Matches Cloud Function output format
- Add error field if not present

### New Components

**Views/Components/FloatingAIButton.swift** (Create new)
- Floating 🤖 button overlaid on ChatListView
- Bottom-right corner, 60x60pt, rounded circle
- Pulse animation to draw attention (subtle)
- Tap action: Open AIAssistantView as sheet

**Views/Components/AILoadingIndicator.swift** (May exist from PR #002, verify)
- Animated "..." ellipsis below last message
- Pulse animation (fade in/out loop)
- Shows "AI is thinking..." text

**Views/Components/AIEmptyStateView.swift** (Create new)
- Welcome message for first-time users
- 3 example prompts (tappable to auto-fill)
- 🤖 icon + friendly copy

### Integration with MainTabView

**Option A: Floating Button (Recommended)**
```swift
// Views/MainTabView.swift
ChatListView()
    .overlay(alignment: .bottomTrailing) {
        FloatingAIButton()
            .padding()
    }
```

**Option B: Tab Navigation**
```swift
TabView {
    ChatListView()
        .tabItem { Label("Chats", systemImage: "message") }
    
    AIAssistantView()
        .tabItem { Label("AI", systemImage: "brain.head.profile") }
    
    SettingsView()
        .tabItem { Label("Settings", systemImage: "gearshape") }
}
```

---

## 11. Integration Points

**Firebase Authentication:**
- AIService checks `Auth.auth().currentUser` before API calls
- Cloud Function receives userId from auth context

**Firebase Cloud Functions:**
- `chatWithAI` endpoint (PR #003 backend)
- Callable function (not HTTP, uses Firebase SDK)

**State Management:**
- SwiftUI `@StateObject` for AIAssistantViewModel
- `@Published` properties trigger UI updates
- `@State` for local view state (keyboard visible, etc.)

**Navigation:**
- `.sheet()` presentation for AIAssistantView (modal overlay)
- Or `.fullScreenCover()` if full-screen preferred
- Dismiss via swipe-down or close button

**Error Handling:**
- NetworkMonitor.shared for offline detection
- AIError enum for typed error cases
- Toast/alert presentation for user feedback

---

## 12. Testing Plan & Acceptance Gates

**See `Psst/docs/testing-strategy.md` for detailed examples.**

### Happy Path

- [ ] **Flow:** User taps 🤖 button → AIAssistantView opens → types "What did John say about his knee?" → taps send → sees loading indicator → AI response appears within 5 seconds
- [ ] **Gate:** Message sent successfully, AI response displays in gray bubble, conversation continues naturally
- [ ] **Pass Criteria:** No errors, smooth animations, response time < 5 seconds

**Manual Test Steps:**
1. Open ChatListView
2. Tap floating 🤖 button (bottom-right)
3. Verify AIAssistantView slides up smoothly
4. Type message: "Tell me about my recent conversations"
5. Tap send button
6. Verify user message appears immediately (blue bubble, right-aligned)
7. Verify loading indicator appears: "AI is thinking..."
8. Wait for AI response (should arrive within 3-5 seconds)
9. Verify AI message appears (gray bubble, left-aligned, 🤖 icon)
10. Ask follow-up: "What else?"
11. Verify conversation context maintained (AI references previous question)

---

### Edge Cases

- [ ] **Edge Case 1: Empty Message**
  - **Test:** User taps send with empty input field
  - **Expected:** Send button disabled OR shows alert "Message cannot be empty"
  - **Pass:** No API call made, user receives clear feedback, no crash

- [ ] **Edge Case 2: Very Long Message (1000+ characters)**
  - **Test:** User pastes 2000-character message and sends
  - **Expected:** Message accepted (if < 2000) OR shows "Message too long, please shorten" (if > 2000)
  - **Pass:** App handles gracefully, backend accepts or rejects appropriately, no crash

- [ ] **Edge Case 3: Rapid Message Sending (Spam)**
  - **Test:** User taps send button 5 times rapidly
  - **Expected:** Each message queues, loading indicator shows for each, all responses arrive eventually
  - **Pass:** No crash, all messages processed, UI remains responsive

- [ ] **Edge Case 4: Special Characters & Emojis**
  - **Test:** Send message with emojis: "What did 🏋️ John say about 🦵 knee?"
  - **Expected:** Message sent successfully, AI responds appropriately
  - **Pass:** Special characters handled correctly, no encoding errors

---

### Error Handling

- [ ] **Offline Mode**
  - **Test:** Enable airplane mode → tap 🤖 button → try sending message
  - **Expected:** Loading indicator appears → then shows "No internet connection. Check your network and try again."
  - **Pass:** Clear error message, no crash, retry works when reconnected

- [ ] **Invalid Input (Empty Message)**
  - **Test:** Tap send with blank input
  - **Expected:** Send button disabled OR inline error: "Message cannot be empty"
  - **Pass:** Validation prevents empty send, user can type and retry

- [ ] **Network Timeout**
  - **Test:** Send message → simulate slow network (backend delays 15+ seconds)
  - **Expected:** Loading indicator shows → after 10 seconds: "Request took too long. Try again." → Retry button appears
  - **Pass:** Timeout handled gracefully, user can retry, no crash

- [ ] **Backend Error (500)**
  - **Test:** Backend returns server error
  - **Expected:** "AI assistant is temporarily unavailable. Try again in a moment."
  - **Pass:** User-friendly error message, retry option provided, no crash

- [ ] **Authentication Error**
  - **Test:** User logged out (edge case, should not happen in normal flow)
  - **Expected:** "Please log in to use AI assistant" → redirects to login
  - **Pass:** Auth check prevents API call, clear message shown

---

### Regression Testing

These existing features MUST continue working after this PR:

- [ ] **ChatListView Navigation** still works (can open regular chats)
- [ ] **Message Sending** in regular chats unaffected
- [ ] **Profile View** accessible from MainTabView
- [ ] **Settings** accessible and functional
- [ ] **User Authentication** (login/logout) still works
- [ ] **Real-time message sync** in regular chats continues working

---

### Optional: Multi-Device Testing

**Not required for this PR** (AI is user-specific, no cross-device sync needed yet)

---

### Performance Check

- [ ] **AIAssistantView opens quickly** (< 200ms from tap to visible)
- [ ] **Smooth animations** (view transition, message appearance)
- [ ] **No UI blocking** during AI requests (can scroll messages while waiting)
- [ ] **Scrolling performance** with 20+ messages (smooth 60fps)

**If performance issues detected:**
- Measure specific lag (e.g., view load time)
- Optimize: LazyVStack for message list, minimize re-renders
- Target: < 100ms view load, < 50ms message render

---

## 13. Definition of Done

**Service Layer:**
- [ ] `AIService.chatWithAI()` implemented with real Cloud Function calls
- [ ] Error handling for all failure cases (network, timeout, auth, server)
- [ ] Message validation before sending

**ViewModels:**
- [ ] `AIAssistantViewModel` connected to real AIService
- [ ] State management with @Published properties
- [ ] Error state handling and user feedback

**Views:**
- [ ] `AIAssistantView` polished and production-ready
- [ ] `FloatingAIButton` integrated into ChatListView
- [ ] Empty states, loading indicators, error messages implemented
- [ ] All animations smooth and polished

**Testing:**
- [ ] Manual testing completed (happy path, edge cases, error handling)
- [ ] All acceptance gates pass
- [ ] No console errors or warnings
- [ ] Performance targets met (< 5s AI response, smooth 60fps)

**Regression:**
- [ ] All existing features still work (chat list, messaging, profile, settings)
- [ ] No breaking changes to other views

**Documentation:**
- [ ] Inline code comments for complex logic
- [ ] README updated with AI Assistant usage
- [ ] PR description with testing evidence

---

## 14. Risks & Mitigations

**Risk: Backend API not ready**
- **Mitigation:** Continue using mock responses in AIService until PR #003 completes. Easy swap once backend is deployed.

**Risk: AI response time > 5 seconds**
- **Mitigation:** Show loading indicator with "This may take a moment..." after 3 seconds. Implement timeout at 10 seconds.

**Risk: Cloud Function costs exceed budget**
- **Mitigation:** Phase 2 has no RAG (cheaper), limited to simple Q&A. Monitor Firebase usage dashboard. Add rate limiting if needed.

**Risk: Poor error messages confuse users**
- **Mitigation:** User-friendly error strings in `AIError.errorDescription`. Test all error cases manually. Provide actionable retry options.

**Risk: Conversation context lost between messages**
- **Mitigation:** Pass conversationId with each request. Validate backend maintains context. Test multi-message conversations manually.

**Risk: UI feels slow or unresponsive**
- **Mitigation:** Optimistic UI for user messages (appear instantly). Loading indicator for AI responses. async/await prevents blocking.

---

## 15. Rollout & Telemetry

**Feature Flag:** No (AI Assistant available to all users immediately)

**Metrics to Monitor (Manual Validation):**
- AI assistant usage: How many trainers tap 🤖 button daily?
- Message count: Average messages per AI conversation
- Error rate: How often do API calls fail?
- Response time: Average time from send to AI response

**Manual Validation Steps:**
1. Test on real device (iPhone 12+, iOS 16+)
2. Verify on Simulator (various screen sizes)
3. Test with slow network (throttle in Xcode)
4. Test offline mode (airplane mode)
5. Send 10+ messages to verify conversation context

**Rollout Plan:**
- Phase 2 launch: AI Assistant available immediately
- No gradual rollout needed (low-risk UI feature)
- Easy to disable if critical issues found (remove floating button)

---

## 16. Open Questions

- Q1: **Floating button vs. Tab?** → Floating button recommended (less intrusive, accessible from any screen)
- Q2: **Conversation persistence?** → Phase 2: In-memory only. Phase 3+: Persist to Firestore
- Q3: **Response streaming?** → Phase 2: Show complete response at once. Phase 4+: Stream tokens for real-time feel
- Q4: **Rate limiting?** → Monitor costs in Phase 2. Add client-side throttle if needed (e.g., 10 messages/minute)

---

## 17. Appendix: Out-of-Scope Backlog

Features deferred to future phases:

- [ ] **Voice input** (speak to AI instead of typing) - PR #010
- [ ] **AI function calling** (schedule, remind, send messages) - PR #008
- [ ] **Conversation history** (persist to Firestore) - Phase 3+
- [ ] **Response streaming** (show AI typing token-by-token) - Phase 4+
- [ ] **Contextual AI in chats** (long-press menu) - PR #006
- [ ] **RAG/semantic search** (AI knows past conversations) - PR #005
- [ ] **Multi-user AI** (trainers can share AI assistant) - Future
- [ ] **Custom AI tone** (professional/friendly/motivational) - PR #014

---

## Preflight Questionnaire

1. **Smallest end-to-end user outcome?** Trainer asks AI a question and gets a response
2. **Primary user and critical action?** Trainer → Send message to AI
3. **Must-have vs nice-to-have?** Must: Chat UI, API integration, error handling. Nice: Timestamps, example prompts
4. **Real-time requirements?** No real-time sync needed (AI is request/response)
5. **Performance constraints?** UI must remain responsive, no blocking main thread
6. **Error/edge cases?** Offline, timeout, server errors, empty messages, long messages
7. **Data model changes?** Use existing AIMessage, AIConversation, AIResponse models from PR #002
8. **Service APIs required?** AIService.chatWithAI() → Firebase Cloud Function
9. **UI entry points?** Floating 🤖 button in ChatListView
10. **Security/permissions?** User must be authenticated, Cloud Function validates auth token
11. **Dependencies?** PR #002 (iOS scaffolding) complete, PR #003 (backend) needed for real responses
12. **Rollout strategy?** Launch immediately in Phase 2, monitor manually
13. **Out of scope?** Voice, function calling, RAG, conversation persistence

---

## Authoring Notes

- **Vertical Slice:** Complete chat interface from input → API → display response
- **Build on Existing:** PR #002 scaffolding provides foundation, this PR connects to real backend
- **Test First:** Define all 3 test scenarios (happy, edge, error) before coding
- **Service Layer:** Keep business logic in AIService, views are thin wrappers
- **Async/Await:** All API calls must be non-blocking, use Task and MainActor for UI updates
- **User-Friendly Errors:** Every error case has clear message and retry option

