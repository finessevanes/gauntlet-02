# PR-002 TODO — iOS AI Scaffolding

**Branch**: `feat/pr-002-ios-ai-scaffolding`  
**Source PRD**: `Psst/docs/prds/pr-002-prd.md`  
**Owner (Agent)**: Caleb

---

## 0. Clarifying Questions & Assumptions

**Questions:** None - this is scaffolding/foundation work

**Assumptions (confirm in PR if needed):**
- AIMessage/AIConversation/AIResponse models will match backend schema from PR #001
- Mock data is sufficient for UI testing and development
- This PR can run in parallel with PR #001 (no backend dependency)
- In-memory conversation storage is acceptable (no Firestore yet)
- AIService follows existing service patterns (AuthenticationService, MessageService)

---

## 1. Setup

- [x] Create branch `feat/pr-002-ios-ai-scaffolding` from develop
- [x] Read PRD thoroughly: `Psst/docs/prds/pr-002-prd.md`
- [x] Read `Psst/agents/shared-standards.md` for patterns
- [x] Read `Psst/docs/architecture.md` for AI integration strategy
- [x] Confirm Xcode build works (⌘B) with 0 errors
- [x] Confirm environment is ready (Firebase configured, project runs)

---

## 2. Data Models

Implement Swift models with Codable conformance.

### AIMessage Model
- [x] Create `Psst/Psst/Models/AIMessage.swift`
- [x] Define struct with: `id`, `text`, `isFromUser`, `timestamp`, `status`
- [x] Add `AIMessageStatus` enum: `.sending`, `.delivered`, `.failed`
- [x] Conform to `Identifiable`, `Codable`, `Equatable`
- [x] Add validation: `text` cannot be empty
  - **Test Gate:** Compile successfully, no warnings ✅

### AIConversation Model
- [x] Create `Psst/Psst/Models/AIConversation.swift`
- [x] Define struct with: `id`, `messages`, `createdAt`, `updatedAt`
- [x] Add computed property: `lastMessage` (returns last message or nil)
- [x] Conform to `Identifiable`, `Codable`, `Equatable`
  - **Test Gate:** Compile successfully, `lastMessage` returns correct value ✅

### AIResponse Model
- [x] Create `Psst/Psst/Models/AIResponse.swift`
- [x] Define struct with: `messageId`, `text`, `timestamp`, `metadata`
- [x] Add nested `AIResponseMetadata` struct: `modelUsed`, `tokensUsed`, `responseTime`
- [x] Conform to `Codable`, `Equatable`
  - **Test Gate:** Compile successfully, metadata is optional ✅

### Test Codable Conformance
- [x] Create simple test to encode AIMessage to JSON
- [x] Decode JSON back to AIMessage
- [x] Verify all fields match (no data loss)
  - **Test Gate:** Encoding/decoding works without errors ✅
  - **Pass:** Fields match exactly after round-trip ✅

---

## 3. Service Layer

Create AIService with async/await patterns.

### Create AIService
- [x] Create `Psst/Psst/Services/AIService.swift`
- [x] Import: `Foundation`, `FirebaseAuth`, `FirebaseFunctions`
- [x] Define class as `@MainActor class AIService: ObservableObject`
- [x] Add private property: `functions = Functions.functions()`
  - **Test Gate:** File compiles, class can be instantiated ✅

### Define AIError Enum
- [x] Add `AIError` enum conforming to `LocalizedError`
- [x] Include cases: `.notAuthenticated`, `.networkError(Error)`, `.invalidResponse`, `.rateLimitExceeded`, `.serviceUnavailable`
- [x] Implement `errorDescription` for each case with user-friendly messages
  - **Test Gate:** Error enum compiles, descriptions are readable ✅

### Implement Mock Response Method
- [x] Add method: `func getMockResponse(for message: String) async -> AIResponse`
- [x] Simulate delay: `try? await Task.sleep(nanoseconds: 1_000_000_000)` (1 second)
- [x] Return mock AIResponse with relevant text based on input
- [x] Handle common queries: "hello", "help", "what can you do"
  - **Test Gate:** Method returns AIResponse after ~1 second delay ✅
  - **Pass:** Mock response text is relevant to input ✅

### Stub Future Methods
- [x] Add method signature: `func sendMessage(message: String, conversationId: String?) async throws -> AIResponse`
- [x] Add TODO comment: "// TODO: Implement in PR #003 - AI Chat Backend"
- [x] For now, call `getMockResponse()` internally
  - **Test Gate:** Method compiles, can be called from ViewModel ✅

- [x] Add method: `func createConversation() -> AIConversation`
- [x] Generate unique ID: `UUID().uuidString`
- [x] Return new AIConversation with empty messages array
  - **Test Gate:** Method returns valid AIConversation with unique ID ✅

### Add Documentation
- [x] Add doc comments to all public methods (/// format)
- [x] Document parameters, return values, and throws
- [x] Include usage examples in comments
  - **Test Gate:** Xcode Quick Help shows documentation ✅

---

## 4. Mock Data

Create realistic mock AI conversation data.

- [x] Create `Psst/Psst/Utilities/MockAIData.swift`
- [x] Add static property: `sampleConversation: AIConversation`
- [x] Include 5 messages alternating user/AI:
  - User: "Hello AI"
  - AI: "Hi! I'm your AI assistant. How can I help you today?"
  - User: "What can you do?"
  - AI: "I can help you search past conversations, summarize chats, and answer questions about your clients. What would you like to know?"
  - User: "Show me recent messages from John"
  - AI: "Here are John's recent messages: [sample list]. Would you like me to summarize his conversation?"
  - **Test Gate:** Mock conversation compiles and displays properly ✅

- [x] Add static method: `static func mockResponse(for query: String) -> String`
- [x] Return different responses based on common queries
- [x] Include responses for: greetings, help requests, client queries, unknown queries
  - **Test Gate:** Method returns appropriate responses for different inputs ✅

---

## 5. ViewModel

Create AIAssistantViewModel for state management.

- [x] Create `Psst/Psst/ViewModels/AIAssistantViewModel.swift`
- [x] Import: `Foundation`, `SwiftUI`
- [x] Define class: `@MainActor class AIAssistantViewModel: ObservableObject`
  - **Test Gate:** File compiles ✅

### Add Published Properties
- [x] Add `@Published var conversation: AIConversation`
- [x] Add `@Published var isLoading: Bool = false`
- [x] Add `@Published var errorMessage: String?`
- [x] Add `@Published var currentInput: String = ""`
  - **Test Gate:** Properties compile, accessible from views ✅

### Add Dependencies
- [x] Add private property: `private let aiService: AIService`
- [x] Add initializer: `init(aiService: AIService = AIService())`
- [x] Initialize conversation with `aiService.createConversation()`
  - **Test Gate:** ViewModel instantiates without errors ✅

### Implement Send Message
- [x] Add method: `func sendMessage()`
- [x] Validate: Check `currentInput` is not empty
- [x] Create user AIMessage with `.sending` status
- [x] Append to conversation.messages array
- [x] Set `isLoading = true`
- [x] Call `aiService.getMockResponse(for: currentInput)`
- [x] Create AI AIMessage from response
- [x] Append AI message to conversation
- [x] Set `isLoading = false`
- [x] Clear `currentInput`
- [x] Update `conversation.updatedAt` to current time
  - **Test Gate:** Message flow works, user and AI messages appear ✅
  - **Pass:** Loading state toggles correctly, input clears after send ✅

### Error Handling
- [x] Wrap service call in do-catch
- [x] On error, set `errorMessage` with user-friendly text
- [x] Set `isLoading = false` in catch block
  - **Test Gate:** Errors display in UI without crashing ✅

### Load Mock Data Option
- [x] Add method: `func loadMockConversation()`
- [x] Set `conversation = MockAIData.sampleConversation`
- [x] Use for testing/preview purposes
  - **Test Gate:** Mock conversation loads successfully ✅

---

## 6. UI Components

Create SwiftUI views for AI chat interface.

### AIMessageRow Component
- [x] Create `Psst/Psst/Views/AI/AIMessageRow.swift`
- [x] Create `Views/AI/` directory if needed
- [x] Accept parameter: `message: AIMessage`
- [x] Display text in bubble (user = blue/right, AI = gray/left)
- [x] Show timestamp below message
- [x] Use different alignment based on `isFromUser`
  - **Test Gate:** SwiftUI preview shows both user and AI messages correctly ✅

- [x] Add styling: rounded corners, padding, max width
- [x] Match existing message styling from `MessageRow.swift` where appropriate
  - **Test Gate:** Visual appearance matches app design ✅

### AILoadingIndicator Component
- [x] Create `Psst/Psst/Views/Components/AILoadingIndicator.swift`
- [x] Display animated "..." typing indicator
- [x] Use gray color (AI color)
- [x] Add subtle animation (fade in/out or bounce)
- [x] Reuse `TypingIndicatorView` if applicable, or create new
  - **Test Gate:** SwiftUI preview shows animated typing dots ✅
  - **Pass:** Animation is smooth and continuous ✅

### AIAssistantView (Main Interface)
- [x] Create `Psst/Psst/Views/AI/AIAssistantView.swift`
- [x] Add `@StateObject var viewModel: AIAssistantViewModel`
- [x] Create ScrollView with message list
- [x] Use `ForEach(viewModel.conversation.messages)` to display AIMessageRow
- [x] Add `AILoadingIndicator` when `viewModel.isLoading`
  - **Test Gate:** Messages display in scrollable list ✅

- [x] Add text input field at bottom (TextField)
- [x] Bind to `viewModel.currentInput`
- [x] Add send button (disabled when input empty or loading)
- [x] Call `viewModel.sendMessage()` on button tap
  - **Test Gate:** Input field and button work correctly ✅

- [x] Add navigation title: "AI Assistant"
- [x] Add empty state: "Ask me anything about your clients..."
- [x] Show error alert if `viewModel.errorMessage` is set
  - **Test Gate:** Empty state shows when no messages ✅
  - **Pass:** Error alert appears for errors ✅

### Add SwiftUI Previews
- [x] Add preview for `AIMessageRow` (both user and AI message)
- [x] Add preview for `AILoadingIndicator`
- [x] Add preview for `AIAssistantView` with mock data
  - **Test Gate:** All previews render without errors in Xcode ✅
  - **Pass:** Previews show expected UI ✅

---

## 7. Integration & Testing

### Manual Testing

#### Happy Path
- [x] Build project (⌘B) - 0 errors
- [x] Run in Simulator
- [x] Navigate to AIAssistantView (placeholder navigation for now)
- [x] See empty state message
- [x] Type message: "Hello AI"
- [x] Tap send button (or press Enter)
- [x] See user message appear (blue, right-aligned)
- [x] See loading indicator appear
- [x] After 1 second, see AI response (gray, left-aligned)
  - **Test Gate:** Full message flow works end-to-end ✅
  - **Pass:** Messages display correctly, no console errors ✅

#### Edge Cases
- [x] **Edge Case 1: Empty Message**
  - Clear input field
  - Tap send button
  - Verify send button is disabled or shows validation
  - **Pass:** Cannot send empty message ✅

- [x] **Edge Case 2: Long Message (1000+ characters)**
  - Paste 1500 character message
  - Send message
  - Verify message displays fully (scrollable if needed)
  - **Pass:** No crash, message wraps or scrolls correctly ✅

- [x] **Edge Case 3: Special Characters/Emojis**
  - Type: "What's 🔥 about AI? 🤖💬"
  - Send message
  - Verify emojis display correctly in both user and AI messages
  - **Pass:** Emojis render properly ✅

#### Error Handling
- [x] **Codable Test**
  - Encode AIMessage to JSON using JSONEncoder
  - Decode back using JSONDecoder
  - Verify all fields match
  - **Pass:** No data loss, exact match ✅

- [x] **Mock Response Validation**
  - Send various messages
  - Verify mock responses are relevant
  - Check for nil/empty responses
  - **Pass:** All responses valid, non-empty ✅

#### Performance Check
- [x] Measure view load time (should be < 100ms)
- [x] Scroll through 50+ mock messages (create extended mock data)
- [x] Verify smooth scrolling (60fps)
- [x] Check for main thread blocking
  - **Pass:** UI feels responsive, no lag ✅

### SwiftUI Previews Verification
- [x] Open each view file in Xcode
- [x] Enable Canvas (⌥⌘↩)
- [x] Verify preview renders without errors
- [x] Check: AIMessageRow, AILoadingIndicator, AIAssistantView
  - **Test Gate:** All previews render successfully ✅
  - **Pass:** No console errors in preview ✅

### Console Check
- [x] Run app in Simulator
- [x] Navigate through all AI views
- [x] Check Xcode console for errors/warnings
- [x] Verify 0 errors, 0 warnings
  - **Pass:** Clean console output ✅

---

## 8. Acceptance Gates

Verify all gates from PRD Section 12:

- [x] **Gate:** AIService compiles and can be instantiated without errors ✅
- [x] **Gate:** Mock AI conversation displays in AIAssistantView with proper formatting ✅
- [x] **Gate:** SwiftUI preview works for AIAssistantView ✅
- [x] **Gate:** Models encode to JSON and decode back without data loss ✅
- [x] **Gate:** No console warnings when navigating to AI view ✅
- [x] **Gate:** View loads in < 100ms ✅
- [x] **Gate:** No blocking operations on main thread ✅

---

## 9. Documentation & PR

- [ ] Add inline comments to complex logic
- [ ] Ensure all public methods have documentation comments (///)
- [ ] Add file header comments if missing
- [ ] Update README if needed (mention AI features coming soon)
  - **Test Gate:** Xcode Quick Help shows docs for all public APIs

- [ ] Create PR description using format:
```markdown
## PR #002: iOS AI Scaffolding

**PRD:** Psst/docs/prds/pr-002-prd.md
**TODO:** Psst/docs/todos/pr-002-todo.md

### Summary
Created iOS-side AI infrastructure including AIService, data models (AIMessage, AIConversation, AIResponse), and skeleton UI with mock data support.

### What's New
- ✅ AIService.swift - Service layer for AI Cloud Function calls
- ✅ AIMessage, AIConversation, AIResponse models with Codable
- ✅ AIAssistantViewModel - State management for AI chat
- ✅ AIAssistantView - Skeleton AI chat interface
- ✅ Mock data system for development

### Testing Completed
- [x] Manual testing (happy path, edge cases, error handling)
- [x] SwiftUI previews render successfully
- [x] Codable encoding/decoding verified
- [x] Performance check (view load < 100ms)
- [x] Console clean (0 errors, 0 warnings)

### Screenshots
[Add screenshot of AIAssistantView with mock conversation]

### Next Steps
This enables PR #003 (AI Chat Backend) and PR #004 (AI Chat UI) to build on this foundation.
```

- [ ] Verify with user before creating PR
- [ ] Create PR targeting `develop` branch
- [ ] Link PRD and TODO in PR description

---

## Copyable Checklist (for PR description)

```markdown
- [x] Branch created from develop
- [x] All TODO tasks completed
- [x] Data models implemented with Codable conformance
- [x] AIService implemented with async/await patterns
- [x] AIAssistantViewModel manages conversation state
- [x] AIAssistantView displays mock conversations
- [x] SwiftUI previews render successfully
- [x] Mock data provides realistic AI exchanges
- [x] Manual testing completed (navigation, display, edge cases)
- [x] Performance targets met (view load < 100ms)
- [x] All acceptance gates pass
- [x] Code follows MVVM pattern from Psst/agents/shared-standards.md
- [x] No console warnings or errors
- [x] Documentation comments added to public APIs
```

---

## Notes

- This is pure scaffolding - focus on structure over functionality
- Mock data should guide future UI/UX decisions
- Coordinate with PR #001 (backend) on data contracts if needed
- All async operations use Swift async/await (no callbacks)
- Follow existing patterns from `MessageService.swift` and `ChatService.swift`
- Reference `Psst/agents/shared-standards.md` for code quality standards
- Keep tasks small (<30 min each) and check off immediately after completion

