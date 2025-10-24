# PR-006 TODO — Contextual AI Actions (Long-Press Menu)

**Branch**: `feat/pr-6-contextual-ai-actions`  
**Source PRD**: `Psst/docs/prds/pr-006-prd.md`  
**Owner (Agent)**: Caleb

---

## 0. Clarifying Questions & Assumptions

### Questions
- **Q1**: Where should reminders be stored? (UserDefaults, Firestore, or iOS Reminders app?)
- **Q2**: Should we show "Mock AI" label during development?
- **Q3**: Should related messages be tappable to scroll to original message?

### Assumptions (confirm in PR if needed)
- **A1**: Use Firestore `/users/{userID}/reminders` collection for cross-device sync
- **A2**: Add "Mock" badge in AI results during development, remove before production
- **A3**: Related messages are display-only in v1, tappable in v2
- **A4**: PR #005 (RAG Pipeline) is in progress - use mocks initially, integrate real backend later
- **A5**: Long-press duration is 0.5 seconds (iOS standard)
- **A6**: All AI actions work offline with cached data where possible

---

## 1. Setup

- [ ] Create branch `feat/pr-6-contextual-ai-actions` from develop
  - Test Gate: Branch exists, based on latest develop
- [ ] Read PRD thoroughly (`Psst/docs/prds/pr-006-prd.md`)
  - Test Gate: Understand all 3 actions, mock strategy, integration plan
- [ ] Read `Psst/agents/shared-standards.md` for patterns
  - Test Gate: Know performance targets, code quality standards
- [ ] Confirm environment and test runner work
  - Test Gate: Xcode builds, simulator runs, no errors
- [ ] Review existing `AIService.swift` from PR #004
  - Test Gate: Understand current AI service structure

---

## 2. Data Models

Create new models in `Psst/Psst/Models/` directory.

### Task 2.1: Create AIContextAction Enum
- [x] Create `Models/AIContextAction.swift`
  - Test Gate: Enum with 3 cases (summarize, surfaceContext, setReminder)
  - Test Gate: Each case has icon (SF Symbol name) and description
  - Test Gate: Conforms to `String`, `CaseIterable`, `Identifiable`

**Implementation guidance** (from PRD Section 8):
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
        case .summarize: return "Get a concise summary of this conversation"
        case .surfaceContext: return "Find related past conversations"
        case .setReminder: return "Create a follow-up reminder from this message"
        }
    }
}
```

---

### Task 2.2: Create AIContextResult Model
- [x] Create `Models/AIContextResult.swift`
  - Test Gate: Struct with id, action, sourceMessageID, result, timestamp, isLoading, error
  - Test Gate: Conforms to `Identifiable`, `Codable`
  - Test Gate: `AIResultContent` enum handles all 3 result types

**Implementation guidance**:
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
```

---

### Task 2.3: Create RelatedMessage Model
- [x] Create `Models/RelatedMessage.swift`
  - Test Gate: Struct with id, messageID, text, senderName, timestamp, relevanceScore
  - Test Gate: Conforms to `Identifiable`, `Codable`
  - Test Gate: relevanceScore is Double (0.0 - 1.0)

**Implementation guidance**:
```swift
struct RelatedMessage: Identifiable, Codable {
    let id: String
    let messageID: String
    let text: String
    let senderName: String
    let timestamp: Date
    let relevanceScore: Double // 0.0 - 1.0
}
```

---

### Task 2.4: Create ReminderSuggestion Model
- [x] Create `Models/ReminderSuggestion.swift`
  - Test Gate: Struct with text, suggestedDate, extractedInfo
  - Test Gate: Conforms to `Codable`
  - Test Gate: extractedInfo is [String: String] dictionary

**Implementation guidance**:
```swift
struct ReminderSuggestion: Codable {
    let text: String
    let suggestedDate: Date
    let extractedInfo: [String: String]
}
```

---

### Task 2.5: Create AIError Enum
- [x] Add to existing `Models/` or `Utilities/` (if AIError doesn't exist)
  - Test Gate: Enum with 5+ error cases (networkUnavailable, serviceTimeout, invalidRequest, rateLimitExceeded, unknownError)
  - Test Gate: Conforms to `LocalizedError`
  - Test Gate: Each case has user-friendly error description

**Implementation guidance** (from PRD Section 9):
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

## 3. Mock Service Layer

Create mock AI service for parallel development while PR #005 is in progress.

### Task 3.1: Create MockAIService
- [x] Create `Services/MockAIService.swift`
  - Test Gate: Class with 3 static methods (mockSummarize, mockSurfaceContext, mockReminder)
  - Test Gate: Includes private `simulateDelay()` helper (0.5-1.5s random)
  - Test Gate: Returns contextually appropriate mock data

**Implementation guidance** (from PRD Section 9):
```swift
class MockAIService {
    
    /// Simulates network delay for realistic UX testing
    private static func simulateDelay() async {
        let delay = Double.random(in: 0.5...1.5)
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    }
    
    static func mockSummarize(messages: [Message]) async -> (String, [String]) {
        await simulateDelay()
        // Implementation: Return contextual summary based on message count
    }
    
    static func mockSurfaceContext(for message: Message) async -> [RelatedMessage] {
        await simulateDelay()
        // Implementation: Return 3-5 related messages with timestamps
    }
    
    static func mockReminder(from message: Message, senderName: String) async -> ReminderSuggestion {
        await simulateDelay()
        // Implementation: Extract keywords, suggest tomorrow 9am
    }
}
```

---

### Task 3.2: Implement mockSummarize
- [x] Implement `mockSummarize(messages:)` method
  - Test Gate: Returns summary text and 3-5 key points
  - Test Gate: Summary varies based on message count
  - Test Gate: Key points are contextually relevant
  - Test Gate: Simulates 0.5-1.5s delay

**Acceptance**: Call with 10 messages → Returns summary like "Conversation covered 10 messages over 3 days" + key points

---

### Task 3.3: Implement mockSurfaceContext
- [x] Implement `mockSurfaceContext(for:)` method
  - Test Gate: Returns 3-5 RelatedMessage objects
  - Test Gate: Timestamps are realistic (2 weeks ago, 10 days ago, 5 days ago)
  - Test Gate: Relevance scores decrease (0.92, 0.87, 0.81)
  - Test Gate: Messages are contextually similar to input message

**Acceptance**: Call with message about "knee pain" → Returns 3 messages about injuries with timestamps

---

### Task 3.4: Implement mockReminder
- [x] Implement `mockReminder(from:senderName:)` method
  - Test Gate: Pre-fills reminder text from message content
  - Test Gate: Suggests tomorrow 9am as default date
  - Test Gate: Extracts client name, topic, priority in extractedInfo
  - Test Gate: Text truncates long messages to ~50 characters

**Acceptance**: Call with message "Follow up on workout plan" → Returns reminder for tomorrow with extracted info

---

## 4. AIService Extensions

Extend existing `AIService.swift` with contextual action methods.

### Task 4.1: Add summarizeConversation Method
- [x] Add method to `Services/AIService.swift`
  - Test Gate: Method signature matches PRD Section 9
  - Test Gate: Calls MockAIService.mockSummarize initially
  - Test Gate: Returns (summary: String, keyPoints: [String])
  - Test Gate: Throws AIError on failure

**Implementation guidance**:
```swift
func summarizeConversation(
    messages: [Message], 
    chatID: String
) async throws -> (summary: String, keyPoints: [String]) {
    // For now, use mock service
    // TODO: When PR #005 merges, call real Cloud Function
    return await MockAIService.mockSummarize(messages: messages)
}
```

---

### Task 4.2: Add surfaceContext Method
- [x] Add method to `Services/AIService.swift`
  - Test Gate: Method signature matches PRD Section 9
  - Test Gate: Calls MockAIService.mockSurfaceContext initially
  - Test Gate: Returns [RelatedMessage]
  - Test Gate: Limit parameter defaults to 5

**Implementation guidance**:
```swift
func surfaceContext(
    for message: Message, 
    chatID: String, 
    limit: Int = 5
) async throws -> [RelatedMessage] {
    // For now, use mock service
    // TODO: When PR #005 merges, call RAG pipeline
    return await MockAIService.mockSurfaceContext(for: message)
}
```

---

### Task 4.3: Add createReminderSuggestion Method
- [x] Add method to `Services/AIService.swift`
  - Test Gate: Method signature matches PRD Section 9
  - Test Gate: Calls MockAIService.mockReminder initially
  - Test Gate: Returns ReminderSuggestion
  - Test Gate: Includes senderName parameter

**Implementation guidance**:
```swift
func createReminderSuggestion(
    from message: Message, 
    senderName: String
) async throws -> ReminderSuggestion {
    // For now, use mock service
    // TODO: When PR #005 merges, use AI to extract action items
    return await MockAIService.mockReminder(from: message, senderName: senderName)
}
```

---

### Task 4.4: Add Error Handling
- [x] Add network checking before AI calls
  - Test Gate: Throws AIError.networkUnavailable when offline
  - Test Gate: Catches timeout and throws AIError.serviceTimeout
  - Test Gate: All errors have user-friendly messages
  - Note: Error handling implemented in ViewModel (section 5)

**Acceptance**: Enable airplane mode → Call any method → Throws networkUnavailable error

---

## 5. ViewModel

Create ViewModel to manage contextual AI action state.

### Task 5.1: Create ContextualAIViewModel
- [x] Create `ViewModels/ContextualAIViewModel.swift`
  - Test Gate: Class conforms to ObservableObject
  - Test Gate: Has 4 @Published properties (activeAction, isLoading, currentResult, error)
  - Test Gate: Has AIService dependency (injected or initialized)

**Implementation guidance** (from PRD Section 10):
```swift
class ContextualAIViewModel: ObservableObject {
    @Published var activeAction: AIContextAction?
    @Published var isLoading: Bool = false
    @Published var currentResult: AIContextResult?
    @Published var error: AIError?
    
    private let aiService: AIService
    
    init(aiService: AIService = AIService()) {
        self.aiService = aiService
    }
}
```

---

### Task 5.2: Implement performAction Method
- [x] Add `performAction(_:on:in:)` method
  - Test Gate: Sets isLoading = true at start
  - Test Gate: Calls appropriate AIService method based on action type
  - Test Gate: Updates currentResult on success
  - Test Gate: Updates error on failure
  - Test Gate: Sets isLoading = false when complete
  - Test Gate: Uses @MainActor for UI updates

**Implementation guidance**:
```swift
@MainActor
func performAction(
    _ action: AIContextAction, 
    on message: Message, 
    in chatID: String,
    messages: [Message] = [],
    senderName: String = ""
) async {
    activeAction = action
    isLoading = true
    error = nil
    
    do {
        let resultContent: AIResultContent
        
        switch action {
        case .summarize:
            let (summary, keyPoints) = try await aiService.summarizeConversation(messages: messages, chatID: chatID)
            resultContent = .summary(text: summary, keyPoints: keyPoints)
            
        case .surfaceContext:
            let relatedMessages = try await aiService.surfaceContext(for: message, chatID: chatID)
            resultContent = .relatedMessages(relatedMessages)
            
        case .setReminder:
            let suggestion = try await aiService.createReminderSuggestion(from: message, senderName: senderName)
            resultContent = .reminder(suggestion)
        }
        
        currentResult = AIContextResult(
            id: UUID().uuidString,
            action: action,
            sourceMessageID: message.id,
            result: resultContent,
            timestamp: Date(),
            isLoading: false,
            error: nil
        )
        
        isLoading = false
        
    } catch let aiError as AIError {
        error = aiError
        isLoading = false
    } catch {
        self.error = .unknownError(error.localizedDescription)
        isLoading = false
    }
}
```

---

### Task 5.3: Implement dismissResult Method
- [x] Add `dismissResult()` method
  - Test Gate: Clears currentResult, activeAction, error
  - Test Gate: Uses @MainActor for UI updates

**Implementation**:
```swift
@MainActor
func dismissResult() {
    currentResult = nil
    activeAction = nil
    error = nil
}
```

---

### Task 5.4: Implement retryLastAction Method
- [x] Add `retryLastAction()` method
  - Test Gate: Recalls performAction with last parameters
  - Test Gate: Clears previous error before retry
  - Test Gate: Handles case where no previous action exists

**Implementation**:
```swift
@MainActor
func retryLastAction(message: Message, chatID: String, messages: [Message], senderName: String) async {
    guard let action = activeAction else { return }
    error = nil
    await performAction(action, on: message, in: chatID, messages: messages, senderName: senderName)
}
```

---

## 6. UI Components

Create 5 new views and modify 2 existing views.

### Task 6.1: Create ContextualAIMenu Component
- [x] Create `Views/Components/ContextualAIMenu.swift`
  - Test Gate: SwiftUI view with 3 action buttons
  - Test Gate: Each button shows icon + label
  - Test Gate: Translucent background with blur effect
  - Test Gate: Spring animation on appear (mass: 1.0, stiffness: 180, damping: 18)
  - Test Gate: onActionSelected callback triggers on tap
  - Test Gate: onDismiss callback triggers on outside tap

**Implementation guidance** (from PRD Section 6):
```swift
struct ContextualAIMenu: View {
    let message: Message
    let onActionSelected: (AIContextAction) -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(AIContextAction.allCases) { action in
                Button {
                    onActionSelected(action)
                } label: {
                    HStack {
                        Image(systemName: action.icon)
                            .foregroundColor(.accentColor)
                        Text(action.rawValue)
                            .font(.body)
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(radius: 8)
    }
}
```

**Acceptance**: Preview renders with 3 buttons, blur background, rounded corners

---

### Task 6.2: Create AILoadingIndicator Component
- [x] Create `Views/Components/AILoadingIndicator.swift`
  - Test Gate: Shows pulsing progress view
  - Test Gate: Displays "AI is analyzing..." text (customizable)
  - Test Gate: Opacity animation (0.3 → 1.0, 1s repeat)
  - Test Gate: Accent color matches app theme

**Implementation guidance**:
```swift
struct AILoadingIndicator: View {
    var message: String = "AI is analyzing..."
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.8)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .opacity(isAnimating ? 1.0 : 0.3)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}
```

**Acceptance**: Preview shows pulsing indicator with text

---

### Task 6.3: Create AISummaryView Component
- [x] Create `Views/Components/AISummaryView.swift`
  - Test Gate: Modal presentation with summary text and key points
  - Test Gate: Key points displayed as bullet list
  - Test Gate: Copy button copies full summary
  - Test Gate: Dismiss button closes modal
  - Test Gate: Markdown formatting for summary text (if applicable)

**Implementation guidance**:
```swift
struct AISummaryView: View {
    let summary: String
    let keyPoints: [String]
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Summary")
                        .font(.headline)
                    
                    Text(summary)
                        .font(.body)
                    
                    if !keyPoints.isEmpty {
                        Text("Key Points")
                            .font(.headline)
                        
                        ForEach(keyPoints, id: \.self) { point in
                            HStack(alignment: .top) {
                                Text("•")
                                Text(point)
                                Spacer()
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Conversation Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Dismiss") {
                        onDismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        UIPasteboard.general.string = summary
                    } label: {
                        Image(systemName: "doc.on.doc")
                    }
                }
            }
        }
    }
}
```

**Acceptance**: Preview shows summary modal with key points, copy and dismiss buttons work

---

### Task 6.4: Create AIRelatedMessagesView Component
- [x] Create `Views/Components/AIRelatedMessagesView.swift`
  - Test Gate: Displays 3-5 related messages vertically
  - Test Gate: Shows sender name, timestamp, message preview
  - Test Gate: Relevance score shown as visual indicator (optional)
  - Test Gate: Timestamps formatted as relative ("2 weeks ago")
  - Test Gate: onMessageTap callback (for v2 scroll-to-message)

**Implementation guidance**:
```swift
struct AIRelatedMessagesView: View {
    let relatedMessages: [RelatedMessage]
    let onMessageTap: ((String) -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Related Conversations")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(relatedMessages) { message in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(message.senderName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Spacer()
                        Text(message.timestamp, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(message.text)
                        .font(.body)
                        .lineLimit(3)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .onTapGesture {
                    onMessageTap?(message.messageID)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}
```

**Acceptance**: Preview shows list of related messages with names, timestamps, text

---

### Task 6.5: Create AIReminderSheet Component
- [x] Create `Views/Components/AIReminderSheet.swift`
  - Test Gate: Bottom sheet presentation
  - Test Gate: Pre-filled text field (editable)
  - Test Gate: DatePicker for date/time selection
  - Test Gate: Save button calls onSave callback
  - Test Gate: Cancel button calls onCancel callback

**Implementation guidance**:
```swift
struct AIReminderSheet: View {
    let suggestion: ReminderSuggestion
    let onSave: (String, Date) -> Void
    let onCancel: () -> Void
    
    @State private var reminderText: String
    @State private var reminderDate: Date
    
    init(suggestion: ReminderSuggestion, onSave: @escaping (String, Date) -> Void, onCancel: @escaping () -> Void) {
        self.suggestion = suggestion
        self.onSave = onSave
        self.onCancel = onCancel
        _reminderText = State(initialValue: suggestion.text)
        _reminderDate = State(initialValue: suggestion.suggestedDate)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Reminder")) {
                    TextField("What to remember", text: $reminderText)
                }
                
                Section(header: Text("When")) {
                    DatePicker("Date & Time", selection: $reminderDate, displayedComponents: [.date, .hourAndMinute])
                }
            }
            .navigationTitle("Set Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(reminderText, reminderDate)
                    }
                    .disabled(reminderText.isEmpty)
                }
            }
        }
    }
}
```

**Acceptance**: Preview shows form with editable text, date picker, save/cancel buttons

---

### Task 6.6: Modify MessageRow - Add Long-Press Gesture
- [x] Open `Views/ChatList/MessageRow.swift`
  - Test Gate: Add @State for showing menu
  - Test Gate: Add .onLongPressGesture(minimumDuration: 0.5)
  - Test Gate: Trigger haptic feedback on long-press recognition
  - Test Gate: Show ContextualAIMenu overlay when active
  - Test Gate: Pass message to menu for context
  - Note: Implemented in ChatView instead of MessageRow to avoid complexity

**Implementation guidance**:
```swift
// In MessageRow.swift
@State private var showContextMenu = false

var body: some View {
    // Existing message row layout...
    .onLongPressGesture(minimumDuration: 0.5) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        showContextMenu = true
    }
    .overlay {
        if showContextMenu {
            Color.black.opacity(0.3)
                .onTapGesture {
                    showContextMenu = false
                }
            
            ContextualAIMenu(
                message: message,
                onActionSelected: { action in
                    // Handle action selection
                    showContextMenu = false
                },
                onDismiss: {
                    showContextMenu = false
                }
            )
        }
    }
}
```

**Acceptance**: Long-press message → Menu appears with haptic feedback

---

### Task 6.7: Modify ChatView - Add Result Overlays
- [x] Open `Views/ChatList/ChatView.swift`
  - Test Gate: Add @StateObject for ContextualAIViewModel
  - Test Gate: Add overlays for summary modal, related messages, reminder sheet
  - Test Gate: Show appropriate overlay based on activeAction
  - Test Gate: Handle action selection from MessageRow
  - Test Gate: Pass necessary data to ViewModel (messages array, chatID, sender name)

**Implementation guidance**:
```swift
// In ChatView.swift
@StateObject private var contextualAIViewModel = ContextualAIViewModel()

var body: some View {
    // Existing ChatView layout...
    .sheet(item: $contextualAIViewModel.currentResult) { result in
        switch result.result {
        case .summary(let text, let keyPoints):
            AISummaryView(
                summary: text,
                keyPoints: keyPoints,
                onDismiss: { contextualAIViewModel.dismissResult() }
            )
            
        case .reminder(let suggestion):
            AIReminderSheet(
                suggestion: suggestion,
                onSave: { text, date in
                    // Save reminder to Firestore
                    contextualAIViewModel.dismissResult()
                },
                onCancel: { contextualAIViewModel.dismissResult() }
            )
            
        default:
            EmptyView()
        }
    }
    .overlay {
        if let result = contextualAIViewModel.currentResult,
           case .relatedMessages(let messages) = result.result {
            AIRelatedMessagesView(
                relatedMessages: messages,
                onMessageTap: nil // v2 feature
            )
            .background(Color(.systemBackground))
        }
    }
    .overlay {
        if contextualAIViewModel.isLoading {
            AILoadingIndicator()
        }
    }
}
```

**Acceptance**: Trigger action → See loading → See appropriate result display

---

## 7. Integration & Wiring

Wire up the complete flow: gesture → menu → action → result.

### Task 7.1: Connect MessageRow to ChatView
- [x] Pass ViewModel from ChatView to MessageRow
  - Test Gate: MessageRow receives ContextualAIViewModel as parameter
  - Test Gate: Menu action selection triggers ViewModel.performAction
  - Test Gate: All necessary data passed (message, chatID, messages, senderName)

**Implementation**:
```swift
// In ChatView, pass ViewModel to MessageRow
MessageRow(
    message: message,
    contextualAIViewModel: contextualAIViewModel,
    allMessages: messages,
    chatID: chatID,
    senderName: getSenderName(for: message)
)

// In MessageRow, receive and use ViewModel
struct MessageRow: View {
    let message: Message
    let contextualAIViewModel: ContextualAIViewModel
    let allMessages: [Message]
    let chatID: String
    let senderName: String
    
    @State private var showContextMenu = false
    
    // ... in onActionSelected:
    Task {
        await contextualAIViewModel.performAction(
            action,
            on: message,
            in: chatID,
            messages: allMessages,
            senderName: senderName
        )
    }
}
```

**Acceptance**: Long-press → Select action → ViewModel receives call with correct parameters

---

### Task 7.2: Implement Reminder Saving
- [x] Create method to save reminders to Firestore
  - Test Gate: Writes to `/users/{userID}/reminders` collection
  - Test Gate: Includes reminder text, date, createdAt, completed status
  - Test Gate: Handles errors gracefully

**Implementation**:
```swift
// In ChatView or new ReminderService
func saveReminder(text: String, date: Date) async throws {
    guard let userId = Auth.auth().currentUser?.uid else { return }
    
    let reminder: [String: Any] = [
        "text": text,
        "reminderDate": Timestamp(date: date),
        "createdAt": FieldValue.serverTimestamp(),
        "completed": false,
        "sourceMessageID": contextualAIViewModel.currentResult?.sourceMessageID ?? ""
    ]
    
    try await Firestore.firestore()
        .collection("users")
        .document(userId)
        .collection("reminders")
        .addDocument(data: reminder)
}
```

**Acceptance**: Save reminder → Data appears in Firestore console

---

### Task 7.3: Add Error Display
- [x] Show error alerts when ViewModel.error is set
  - Test Gate: Alert shows user-friendly error message
  - Test Gate: Retry button available for retryable errors
  - Test Gate: Alert dismisses when error is cleared

**Implementation**:
```swift
// In ChatView
.alert("AI Error", isPresented: .constant(contextualAIViewModel.error != nil)) {
    Button("Dismiss") {
        contextualAIViewModel.error = nil
    }
    if contextualAIViewModel.error != .invalidRequest {
        Button("Retry") {
            Task {
                // Retry logic
            }
        }
    }
} message: {
    Text(contextualAIViewModel.error?.errorDescription ?? "Unknown error")
}
```

**Acceptance**: Trigger error (airplane mode) → Alert shows with error message

---

### Task 7.4: Add Network Monitoring
- [x] Check network status before AI calls
  - Test Gate: Uses existing NetworkMonitor service
  - Test Gate: Shows immediate error if offline
  - Test Gate: Queues action for retry when online (optional v2)

**Implementation**:
```swift
// In ContextualAIViewModel.performAction
guard NetworkMonitor.shared.isConnected else {
    error = .networkUnavailable
    isLoading = false
    return
}
```

**Acceptance**: Enable airplane mode → Tap action → Immediate error, no loading delay

---

## 8. Testing - Happy Path

**Test the complete user flow end-to-end.**

### Task 8.1: Test Summarize Conversation Flow
- [ ] Open ChatView with 10+ messages
- [ ] Long-press a message in the middle
- [ ] Verify menu appears in < 100ms with haptic feedback
- [ ] Tap "📊 Summarize Conversation"
- [ ] Verify loading indicator appears
- [ ] Wait for mock response (~1 second)
- [ ] Verify summary modal appears with text + key points
- [ ] Tap "Copy" button → Verify summary copied to clipboard
- [ ] Tap "Dismiss" → Verify returns to conversation

**Pass Criteria**:
- [ ] **Gate 1**: Long-press triggers menu < 100ms with haptic
- [ ] **Gate 2**: Menu shows 3 actions with icons
- [ ] **Gate 3**: Loading appears immediately
- [ ] **Gate 4**: Summary returns in < 2 seconds
- [ ] **Gate 5**: Modal displays with readable text
- [ ] **Gate 6**: Copy and dismiss work
- [ ] **Gate 7**: Smooth 60fps animations throughout

---

### Task 8.2: Test Surface Context Flow
- [ ] Long-press message about "knee pain"
- [ ] Tap "🔍 Surface Context"
- [ ] Verify loading indicator
- [ ] Wait for mock response
- [ ] Verify inline display shows 3-5 related messages
- [ ] Verify timestamps formatted as relative ("2 weeks ago")
- [ ] Verify sender names and message previews shown
- [ ] Tap outside to dismiss

**Pass Criteria**:
- [ ] Related messages display inline (not modal)
- [ ] Timestamps are relative and realistic
- [ ] Message previews are readable
- [ ] Dismissal works smoothly

---

### Task 8.3: Test Set Reminder Flow
- [ ] Long-press message "Follow up on workout plan"
- [ ] Tap "🔔 Set Reminder"
- [ ] Verify bottom sheet appears
- [ ] Verify reminder text is pre-filled
- [ ] Verify default date is tomorrow 9am
- [ ] Edit reminder text
- [ ] Change date to custom time
- [ ] Tap "Save"
- [ ] Verify reminder saved to Firestore
- [ ] Verify sheet dismisses

**Pass Criteria**:
- [ ] Pre-filled text matches message content
- [ ] Date picker works correctly
- [ ] Save writes to Firestore `/users/{uid}/reminders`
- [ ] Cancel dismisses without saving

---

## 9. Testing - Edge Cases

### Task 9.1: Test Short Conversation Summarize
- [ ] Open chat with only 2 messages
- [ ] Long-press → Summarize
- [ ] Verify still provides summary (not "too short" error)
- [ ] Verify summary is appropriate for short conversation

**Pass**: No crash, appropriate summary shown

---

### Task 9.2: Test No Related Messages Found
- [ ] Modify mock to return empty array
- [ ] Long-press → Surface Context
- [ ] Verify empty state shows "No related conversations found"
- [ ] Verify dismiss button works

**Pass**: User-friendly empty state, no crash

---

### Task 9.3: Test Rapid Long-Presses
- [ ] Long-press message 1
- [ ] Immediately long-press message 2 before menu appears
- [ ] Verify first menu cancels
- [ ] Verify second menu appears for message 2
- [ ] Verify no menu overlap or crash

**Pass**: No overlap, correct message context

---

### Task 9.4: Test Dismiss Mid-Action
- [ ] Long-press → Tap action
- [ ] Tap outside while loading indicator is showing
- [ ] Verify action cancels
- [ ] Verify loading stops
- [ ] Verify no result shown
- [ ] Verify can retry action

**Pass**: Graceful cancellation, no hanging state

---

## 10. Testing - Error Handling

### Task 10.1: Test Offline Mode
- [ ] Enable airplane mode
- [ ] Long-press → Tap any action
- [ ] Verify error shows: "No internet connection. AI features require connectivity."
- [ ] Verify retry button available
- [ ] Disable airplane mode
- [ ] Tap retry
- [ ] Verify action succeeds

**Pass**: Clear error message, retry works when online

---

### Task 10.2: Test Service Timeout
- [ ] Modify mock to delay 10+ seconds
- [ ] Trigger action
- [ ] Verify timeout triggers after 10s
- [ ] Verify error: "AI is taking too long. Try again in a moment."
- [ ] Verify retry button available

**Pass**: Timeout handled gracefully

---

### Task 10.3: Test Invalid Input (Edge Case)
- [ ] Long-press message with only emoji ("👍")
- [ ] Tap Summarize
- [ ] Verify mock still provides generic summary
- [ ] Verify no crash

**Pass**: Handles gracefully, no crash

---

## 11. Performance Testing

### Task 11.1: Measure Long-Press Recognition
- [ ] Use Instruments or manual timing
- [ ] Measure time from touch to menu appearance
- [ ] Target: < 50ms recognition

**Pass**: Long-press feels responsive, < 50ms

---

### Task 11.2: Measure Menu Render Time
- [ ] Use Instruments
- [ ] Measure menu render time
- [ ] Target: < 100ms

**Pass**: Menu appears instantly, < 100ms

---

### Task 11.3: Measure Animation Performance
- [ ] Record with Instruments
- [ ] Verify 60fps during all animations (menu, modal, loading)
- [ ] Check for dropped frames

**Pass**: Smooth 60fps, no jank

---

### Task 11.4: Test UI Responsiveness During AI Processing
- [ ] Trigger AI action
- [ ] While loading, try scrolling messages
- [ ] Verify UI remains responsive
- [ ] Verify no main thread blocking

**Pass**: Can scroll/interact while AI processing

---

## 12. Accessibility

### Task 12.1: Add VoiceOver Labels
- [ ] Add accessibility labels to all action buttons
- [ ] Add hints for long-press gesture
- [ ] Test with VoiceOver enabled

**Pass**: VoiceOver reads all elements correctly

---

### Task 12.2: Test Dynamic Type
- [ ] Test with largest accessibility text size
- [ ] Verify all text scales properly
- [ ] Verify layouts don't break

**Pass**: Layouts adapt to large text sizes

---

### Task 12.3: Test High Contrast Mode
- [ ] Enable high contrast mode
- [ ] Verify colors have sufficient contrast
- [ ] Verify all UI elements visible

**Pass**: Readable in high contrast mode

---

## 13. Documentation

### Task 13.1: Add Inline Comments
- [ ] Comment complex logic in ContextualAIViewModel
- [ ] Comment mock service algorithms
- [ ] Document gesture handling in MessageRow

**Pass**: Code is self-documenting with helpful comments

---

### Task 13.2: Document Backend Integration Plan
- [ ] Add TODO comments marking mock → real backend swap points
- [ ] Document expected Cloud Function API in comments
- [ ] Create integration checklist in PR description

**Pass**: Clear path for PR #005 integration

---

## 14. PR Preparation

### Task 14.1: Record Demo Video
- [ ] Record screen showing all 3 actions working
- [ ] Show happy path, edge case, error handling
- [ ] Keep video < 2 minutes

**Pass**: Demo video shows feature working end-to-end

---

### Task 14.2: Create PR Description
- [ ] Use format from `Psst/agents/caleb-agent.md`
- [ ] Link PRD and TODO
- [ ] List all files created/modified
- [ ] Include demo video or screenshots
- [ ] Document known issues/future work
- [ ] Add integration plan for PR #005

**Pass**: Comprehensive PR description ready

---

### Task 14.3: Verify with User
- [ ] Present completed feature to user
- [ ] Demo all 3 actions working
- [ ] Show error handling and edge cases
- [ ] Get approval before creating PR

**Pass**: User approves feature for PR

---

### Task 14.4: Create Pull Request
- [ ] Open PR targeting `develop` branch
- [ ] Ensure all CI checks pass (if applicable)
- [ ] Request review
- [ ] Address feedback

**Pass**: PR created and ready for review

---

## 15. Acceptance Gates Summary

From PRD Section 12, verify all gates pass:

**Happy Path (7 gates)**:
- [ ] Gate 1: Long-press triggers menu < 100ms with haptic
- [ ] Gate 2: Menu shows 3 actions with icons and labels
- [ ] Gate 3: Loading indicator appears immediately
- [ ] Gate 4: Mock summary returns < 2 seconds
- [ ] Gate 5: Summary displays in readable modal
- [ ] Gate 6: Dismiss works correctly
- [ ] Gate 7: 60fps animations throughout

**Edge Cases (4 scenarios)**:
- [ ] Short conversation: Provides appropriate summary
- [ ] No context found: Shows empty state
- [ ] Rapid long-presses: No overlap, correct context
- [ ] Dismiss mid-action: Graceful cancellation

**Error Handling (3 scenarios)**:
- [ ] Offline: Shows clear error, retry works
- [ ] Timeout: Handles gracefully after 10s
- [ ] Invalid input: No crash, handles gracefully

**Performance**:
- [ ] Long-press recognition < 50ms
- [ ] Menu render < 100ms
- [ ] Mock response < 2 seconds
- [ ] 60fps animations

---

## Copyable Checklist (for PR description)

```markdown
## PR #006 - Contextual AI Actions (Long-Press Menu)

### Completed Tasks
- [ ] Branch created from develop: `feat/pr-6-contextual-ai-actions`
- [ ] All TODO tasks completed (15 sections, 60+ tasks)
- [ ] 4 new data models created (AIContextAction, AIContextResult, RelatedMessage, ReminderSuggestion)
- [ ] MockAIService implemented with realistic responses
- [ ] AIService extended with 3 contextual action methods
- [ ] ContextualAIViewModel created with state management
- [ ] 5 new UI components created (Menu, Loading, Summary, Context, Reminder)
- [ ] MessageRow modified with long-press gesture
- [ ] ChatView modified with result overlays
- [ ] Reminder saving to Firestore implemented
- [ ] Error handling for offline, timeout, invalid input
- [ ] Manual testing completed (happy path, edge cases, errors)
- [ ] Performance verified (50ms gesture, 100ms menu, 2s response, 60fps)
- [ ] All 12 acceptance gates pass
- [ ] VoiceOver labels added
- [ ] Dynamic Type support verified
- [ ] Code follows Psst/agents/shared-standards.md patterns
- [ ] No console warnings or errors
- [ ] Documentation comments added
- [ ] Backend integration plan documented
- [ ] Demo video recorded

### Files Created
- Models/AIContextAction.swift
- Models/AIContextResult.swift
- Models/RelatedMessage.swift
- Models/ReminderSuggestion.swift
- Services/MockAIService.swift
- ViewModels/ContextualAIViewModel.swift
- Views/Components/ContextualAIMenu.swift
- Views/Components/AILoadingIndicator.swift
- Views/Components/AISummaryView.swift
- Views/Components/AIRelatedMessagesView.swift
- Views/Components/AIReminderSheet.swift

### Files Modified
- Services/AIService.swift (added 3 contextual action methods)
- Views/ChatList/MessageRow.swift (added long-press gesture)
- Views/ChatList/ChatView.swift (added result overlays)

### Integration Notes
- Using MockAIService until PR #005 (RAG Pipeline) completes
- Designed for easy mock → real backend swap via dependency injection
- Feature flag ready: `useRealAIBackend` (default: false)
- See PRD Section 18 for integration checklist

### Testing Results
✅ All 12 acceptance gates pass
✅ Happy path tested (3 actions working)
✅ Edge cases handled (short conversation, no results, rapid taps, mid-dismiss)
✅ Error handling verified (offline, timeout, invalid)
✅ Performance targets met (50ms, 100ms, 2s, 60fps)
✅ Accessibility verified (VoiceOver, Dynamic Type, High Contrast)

### Known Issues / Future Work
- Related messages not tappable (scroll-to-message in v2)
- Reminder notifications not implemented (future PR)
- AI action history not saved (future PR)
- "Mock" badge to be removed when real backend ships

### Demo
[Link to demo video showing all 3 actions]
```

---

## Notes

- **Estimated Time**: 8-12 hours total
- **Break tasks into < 30 min chunks**: Each numbered task should be completable in one sitting
- **Complete tasks sequentially**: Don't skip ahead, check off as you go
- **Document blockers immediately**: If stuck, note it in TODO and ask for help
- **Reference standards**: Use `Psst/agents/shared-standards.md` for patterns
- **Coordinate with PR #005**: Check on backend progress, prepare for integration
- **Test frequently**: Don't wait until end to test, verify each component works

**Priority Order**:
1. Data Models (foundation)
2. Mock Service (enables testing)
3. ViewModel (business logic)
4. Basic UI Components (visible progress)
5. Integration (wire everything up)
6. Testing (verify quality)
7. Polish (accessibility, performance)
8. PR (ship it!)

---

**Status**: ✅ TODO Complete - Ready for Caleb  
**Next Step**: `/caleb 6` to implement this feature

