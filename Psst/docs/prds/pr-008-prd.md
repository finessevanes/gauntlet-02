# PRD: AI Function Calling (Tool Integration)

**Feature**: AI Function Calling

**Version**: 1.0

**Status**: Draft

**Agent**: Pam → Caleb

**Target Release**: Phase 4

**Links**: [PR Brief](../ai-briefs.md#pr-008-ai-function-calling-tool-integration), [TODO](../todos/pr-008-todo.md)

---

## 1. Summary

Enable the AI assistant to execute actions on behalf of trainers instead of just providing information. The AI can schedule calendar events, create follow-up reminders, send messages to clients, and search specific past conversations using OpenAI function calling. All actions require trainer confirmation before execution (except in YOLO mode).

---

## 2. Problem & Goals

### Problem
Currently, the AI assistant is read-only—it answers questions but can't take actions. Trainers must manually perform follow-up tasks like scheduling calls, setting reminders, or sending check-in messages after getting information from the AI. This creates friction and reduces the AI's value as a true "assistant."

### Why Now?
This is Phase 4 of the AI feature rollout. We've established RAG capabilities (PR #005) and contextual intelligence (PR #007), so the AI understands client context. Now we need to close the loop by enabling it to act on that understanding.

### Goals (ordered, measurable):
- [x] G1 — AI can execute 4 core actions: schedule calls, set reminders, send messages, search conversations
- [x] G2 — 100% of AI-initiated actions show confirmation UI before execution (safety)
- [x] G3 — Function execution success rate >95% (proper validation and error handling)

---

## 3. Non-Goals / Out of Scope

To avoid scope creep, we are intentionally excluding:

- [ ] Not implementing YOLO mode auto-execution (handled in PR #012)
- [ ] Not implementing voice interface (handled in PR #010)
- [ ] Not implementing proactive suggestions (handled in PR #009)
- [ ] Not implementing complex multi-step agent workflows (handled in PR #013)
- [ ] Not creating UI for calendar/reminders management (just create data, no views)
- [ ] Not implementing payment processing or financial actions
- [ ] Not implementing data deletion or destructive actions

---

## 4. Success Metrics

Reference `Psst/agents/shared-standards.md` for metric templates:

### User-visible Metrics:
- Time to complete "schedule a call" task: <10 seconds (AI chat → confirm → done)
- Number of taps to execute action: 2 (AI suggests → tap confirm)
- Task completion rate: >90% (actions complete successfully after confirmation)

### System Metrics:
- Function call latency: <2 seconds (AI decides → presents confirmation)
- OpenAI API response time: <3 seconds (including function calling round-trip)
- Action execution time: <1 second (write to Firestore)

### Quality Metrics:
- 0 blocking bugs preventing function execution
- All acceptance gates pass
- Crash-free rate >99%
- Invalid function calls: <1% (proper parameter validation)

---

## 5. Users & Stories

### Primary User: Alex (Personal Trainer)
- As Alex, I want to ask AI "Schedule a call with Mike for tomorrow at 2pm" and have it create the calendar event, so I don't have to open my calendar app manually.
- As Alex, I want to tell AI "Remind me to follow up with Sarah about her diet in 3 days" and have it create a reminder, so I never forget important follow-ups.
- As Alex, I want to say "Send John a check-in message asking about his knee" and review the draft before sending, so the AI helps me stay engaged without sounding robotic.
- As Alex, I want to ask "Find all messages where Mike mentioned his shoulder" and get specific results, so I can reference exact conversations.

### Secondary User: System Admin (Future)
- As a system admin, I want to see audit logs of all AI actions, so I can monitor usage and debug issues.

---

## 6. Experience Specification (UX)

### Entry Points
1. **AI Assistant Chat**: User types natural language request ("Schedule a call with Mike tomorrow at 2pm")
2. **Voice (Future - PR #010)**: User speaks request to AI

### Visual Behavior

#### Confirmation Flow (Default Mode)
1. User sends function-invoking message to AI
2. AI shows loading indicator ("Thinking...")
3. AI displays confirmation card:
   ```
   ┌─────────────────────────────────┐
   │ 🤖 I'd like to:                │
   │                                 │
   │ Schedule Call                   │
   │ Client: Mike Johnson            │
   │ Date: Tomorrow at 2:00 PM       │
   │ Duration: 30 minutes            │
   │                                 │
   │  [Confirm]  [Cancel]  [Edit]    │
   └─────────────────────────────────┘
   ```
4. User taps "Confirm" → Action executes → Success message shows
5. User taps "Cancel" → AI acknowledges ("Okay, I won't schedule that")
6. User taps "Edit" → Inline text input appears to modify parameters

#### Direct Execution Flow (YOLO Mode - PR #012)
1. User sends request → AI executes immediately → Shows "✓ Done" message
2. No confirmation step (configured in settings)

#### Error Handling
- Missing parameters: AI asks clarifying question ("What time should I schedule the call?")
- Invalid parameters: AI shows error ("Mike doesn't exist in your contacts")
- Execution failure: AI shows retry button with error ("Couldn't save. Try again?")

### States
- **Idle**: Normal chat interface
- **Processing**: AI analyzing request, shows typing indicator
- **Awaiting Confirmation**: Card displayed with action details
- **Executing**: Loading spinner on confirmation card
- **Success**: Green checkmark + success message
- **Failed**: Red X + error message + retry option
- **Cancelled**: Gray message acknowledging cancellation

### Performance Targets
Reference `Psst/agents/shared-standards.md`:
- AI response time: <3 seconds (including function call round-trip)
- Action execution: <1 second (Firestore write)
- UI feedback: Immediate (<50ms tap response)
- No blocking: All operations async, main thread free

---

## 7. Functional Requirements (Must/Should)

### MUST Requirements

**Function Definitions:**
- MUST: Define 4 functions in OpenAI function calling schema:
  1. `scheduleCall(clientName, dateTime, duration)` - Create calendar event
  2. `setReminder(clientName, reminderText, dateTime)` - Create follow-up reminder
  3. `sendMessage(chatId, messageText)` - Send message on trainer's behalf
  4. `searchMessages(query, chatId, limit)` - Find specific past messages

**Validation:**
- MUST: Validate all function parameters before execution
- MUST: Check user authentication before any action
- MUST: Verify clientName exists in trainer's contacts before scheduling/messaging
- MUST: Validate dateTime is in the future (not past)
- MUST: Limit chatId access to trainer's own chats only (security)

**Confirmation UI:**
- MUST: Show confirmation card for all actions before execution (default mode)
- MUST: Display all action parameters clearly in confirmation card
- MUST: Provide "Confirm", "Cancel", and "Edit" buttons
- MUST: Show success/failure feedback after execution

**Error Handling:**
- MUST: Handle missing required parameters gracefully (ask AI to clarify)
- MUST: Handle invalid parameters with clear error messages
- MUST: Handle Firestore write failures with retry option
- MUST: Log all function calls and results for debugging

**Audit Trail:**
- MUST: Store function execution history in Firestore `/aiActions/{actionId}`
- MUST: Include timestamp, trainerId, functionName, parameters, result, status

### SHOULD Requirements

**Smart Parsing:**
- SHOULD: Handle natural language date/time ("tomorrow at 2pm" → DateTime object)
- SHOULD: Infer duration if not specified (default 30 min for calls)
- SHOULD: Suggest client names if spelling is close but not exact match

**User Experience:**
- SHOULD: Show recent actions in AI chat history (grouped by type)
- SHOULD: Allow undo within 30 seconds of action execution
- SHOULD: Animate confirmation card appearance with smooth transition

### Acceptance Gates

#### Function Calling
- [Gate] AI receives "Schedule call with Mike tomorrow at 2pm" → Calls `scheduleCall()` function with correct parameters
- [Gate] AI receives "Remind me about Sarah's diet in 3 days" → Calls `setReminder()` function with dateTime = now + 3 days
- [Gate] All 4 functions callable by GPT-4 via OpenAI function calling API

#### Validation
- [Gate] Invalid clientName → AI shows "I couldn't find Mike in your contacts"
- [Gate] Past dateTime → AI shows "That time has passed. When should I schedule it?"
- [Gate] Unauthorized chatId → Function returns error, no data written

#### Confirmation Flow
- [Gate] Function call → Confirmation card appears in <2 seconds
- [Gate] User taps "Confirm" → Action executes → Success message appears within 1 second
- [Gate] User taps "Cancel" → No action taken, AI acknowledges cancellation
- [Gate] User taps "Edit" → Inline editor appears, allows parameter modification

#### Execution
- [Gate] Confirmed action → Data written to Firestore → Success status returned
- [Gate] Firestore write fails → Error message shows with retry button
- [Gate] Retry successful → Success message replaces error

#### Audit
- [Gate] Every function call → Entry created in `/aiActions/{actionId}` with all details
- [Gate] Audit log includes: timestamp, trainerId, functionName, parameters, status (pending/success/failed)

---

## 8. Data Model

### New Firestore Collections

#### Calendar Events
```swift
/calendar/{eventId}
  - id: String (auto-generated)
  - trainerId: String (owner)
  - clientId: String (user ID)
  - clientName: String (display name)
  - title: String (e.g., "Call with Mike Johnson")
  - dateTime: Timestamp (scheduled time)
  - duration: Int (minutes, default 30)
  - createdBy: String ("ai" or "user")
  - createdAt: Timestamp
  - status: String ("scheduled", "completed", "cancelled")
```

#### Reminders
```swift
/reminders/{reminderId}
  - id: String (auto-generated)
  - trainerId: String (owner)
  - clientId: String? (optional, may be general reminder)
  - clientName: String? (optional)
  - reminderText: String (e.g., "Follow up about diet")
  - dueDate: Timestamp (when to remind)
  - createdBy: String ("ai" or "user")
  - createdAt: Timestamp
  - completed: Boolean (default false)
  - completedAt: Timestamp? (when marked done)
```

#### AI Action Audit Log
```swift
/aiActions/{actionId}
  - id: String (auto-generated)
  - trainerId: String (owner)
  - functionName: String ("scheduleCall", "setReminder", "sendMessage", "searchMessages")
  - parameters: Map (JSON of function parameters)
  - status: String ("pending", "confirmed", "executed", "failed", "cancelled")
  - result: String? (success message or error)
  - createdAt: Timestamp
  - executedAt: Timestamp? (when action completed)
  - conversationId: String? (AI conversation context)
```

### Validation Rules

**Calendar Events:**
- `trainerId` required and must match authenticated user
- `dateTime` must be in the future
- `duration` must be 5-480 minutes (5 min to 8 hours)

**Reminders:**
- `trainerId` required and must match authenticated user
- `dueDate` must be in the future or within 7 days past (grace period)
- `reminderText` max 500 characters

**AI Actions:**
- `trainerId` required and must match authenticated user
- `functionName` must be one of 4 valid functions
- `status` transitions: pending → confirmed → executed OR pending → cancelled

### Indexing/Queries

**Firestore Indexes:**
```
Collection: calendar
  - trainerId (ASC), dateTime (ASC) - for "upcoming events" query

Collection: reminders
  - trainerId (ASC), completed (ASC), dueDate (ASC) - for "active reminders" query

Collection: aiActions
  - trainerId (ASC), createdAt (DESC) - for audit log history
```

---

## 9. API / Service Contracts

### Cloud Function: chatWithAI (Enhanced)

**Existing Signature:**
```typescript
chatWithAI(userId: string, message: string, conversationId?: string): Promise<AIResponse>
```

**Enhancement: Add Function Calling Support**

**New Function Definitions (OpenAI Format):**
```typescript
const functions = [
  {
    name: 'scheduleCall',
    description: 'Schedule a call with a client',
    parameters: {
      type: 'object',
      properties: {
        clientName: { type: 'string', description: 'Client full name' },
        dateTime: { type: 'string', description: 'ISO 8601 datetime string' },
        duration: { type: 'number', description: 'Call duration in minutes (default 30)' }
      },
      required: ['clientName', 'dateTime']
    }
  },
  {
    name: 'setReminder',
    description: 'Create a follow-up reminder',
    parameters: {
      type: 'object',
      properties: {
        clientName: { type: 'string', description: 'Client full name (optional)' },
        reminderText: { type: 'string', description: 'What to remind about' },
        dateTime: { type: 'string', description: 'ISO 8601 datetime when to remind' }
      },
      required: ['reminderText', 'dateTime']
    }
  },
  {
    name: 'sendMessage',
    description: 'Send a message to a client',
    parameters: {
      type: 'object',
      properties: {
        chatId: { type: 'string', description: 'Firestore chat ID' },
        messageText: { type: 'string', description: 'Message content to send' }
      },
      required: ['chatId', 'messageText']
    }
  },
  {
    name: 'searchMessages',
    description: 'Search past messages for specific content',
    parameters: {
      type: 'object',
      properties: {
        query: { type: 'string', description: 'Search query' },
        chatId: { type: 'string', description: 'Limit to specific chat (optional)' },
        limit: { type: 'number', description: 'Max results (default 10)' }
      },
      required: ['query']
    }
  }
];
```

**Function Execution Handlers:**
```typescript
// Backend Cloud Functions implementation
async function executeScheduleCall(
  trainerId: string,
  clientName: string,
  dateTime: string,
  duration: number = 30
): Promise<{ success: boolean; eventId?: string; error?: string }> {
  // 1. Validate dateTime is in future
  // 2. Find clientId from clientName in trainer's contacts
  // 3. Write to /calendar/{eventId}
  // 4. Return success/error
}

async function executeSetReminder(
  trainerId: string,
  clientName: string | null,
  reminderText: string,
  dateTime: string
): Promise<{ success: boolean; reminderId?: string; error?: string }> {
  // 1. Validate dateTime
  // 2. Find clientId if clientName provided
  // 3. Write to /reminders/{reminderId}
  // 4. Return success/error
}

async function executeSendMessage(
  trainerId: string,
  chatId: string,
  messageText: string
): Promise<{ success: boolean; messageId?: string; error?: string }> {
  // 1. Verify trainer is member of chat
  // 2. Write to /chats/{chatId}/messages/{messageId}
  // 3. Return success/error
}

async function executeSearchMessages(
  trainerId: string,
  query: string,
  chatId: string | null,
  limit: number = 10
): Promise<{ success: boolean; messages?: Message[]; error?: string }> {
  // 1. Generate embedding for query (OpenAI)
  // 2. Search Pinecone with trainerId filter
  // 3. Optionally filter by chatId
  // 4. Return top N results
}
```

### iOS Service: AIService.swift (Enhanced)

**New Method:**
```swift
func executeFunctionCall(
    functionName: String,
    parameters: [String: Any],
    requireConfirmation: Bool = true
) async throws -> FunctionExecutionResult

struct FunctionExecutionResult {
    let success: Bool
    let actionId: String?
    let result: String? // Success message or error
    let data: [String: Any]? // Optional structured data
}
```

### iOS ViewModel: AIAssistantViewModel (Enhanced)

**New Properties:**
```swift
@Published var pendingAction: PendingAction? = nil
@Published var isExecutingAction: Bool = false

struct PendingAction: Identifiable {
    let id = UUID()
    let functionName: String
    let parameters: [String: Any]
    let displayText: String // Human-readable description
    let timestamp: Date
}
```

**New Methods:**
```swift
func handleFunctionCall(functionName: String, parameters: [String: Any])
func confirmAction()
func cancelAction()
func editAction(newParameters: [String: Any])
```

---

## 10. UI Components to Create/Modify

### New Components

- `ActionConfirmationCard.swift` — Card displaying function details with confirm/cancel/edit buttons
- `ActionSuccessView.swift` — Success message with checkmark animation
- `ActionErrorView.swift` — Error message with retry button
- `ActionHistoryRow.swift` — List item showing past AI action in chat history

### Modified Components

- `AIAssistantView.swift` — Add ActionConfirmationCard overlay when pendingAction exists
- `AIAssistantViewModel.swift` — Add function calling state management
- `AIService.swift` — Add function execution methods

### New Models

- `FunctionCall.swift` — Represents a pending or executed function call
- `FunctionParameter.swift` — Typed parameter for function calls
- `ActionHistory.swift` — Past AI actions for display

---

## 11. Integration Points

### Backend Integration
- **OpenAI API**: Function calling feature (GPT-4 with tools)
- **Pinecone**: Semantic search for `searchMessages` function
- **Firestore**: Write calendar events, reminders, messages, audit logs
- **Firebase Authentication**: Validate trainerId for all operations

### iOS Integration
- **AIService**: Call Cloud Function with function execution request
- **MessageService**: Integration for `sendMessage` function (reuse existing method)
- **AuthViewModel**: Get current user ID for authorization
- **State Management**: SwiftUI @Published properties for reactive UI updates

---

## 12. Testing Plan & Acceptance Gates

**Define these 3 scenarios BEFORE implementation.** Use specific, testable criteria.

**See `Psst/docs/testing-strategy.md` for examples and detailed guidance.**

---

### Happy Path

**Scenario: Schedule a call via AI**
1. User opens AI Assistant
2. User types: "Schedule a call with Mike Johnson tomorrow at 2pm"
3. AI displays confirmation card with parsed details
4. User taps "Confirm"
5. Success message appears: "✓ Call scheduled for tomorrow at 2:00 PM"
6. Calendar event created in Firestore

**Pass Criteria:**
- [ ] AI correctly parses natural language into function parameters
- [ ] Confirmation card appears within 2 seconds
- [ ] Tapping "Confirm" executes action within 1 second
- [ ] Success message displays with green checkmark
- [ ] Firestore `/calendar/{eventId}` document exists with correct data
- [ ] No console errors

**Gate:** End-to-end flow completes in <5 seconds with successful Firestore write

---

### Edge Cases

#### Edge Case 1: Missing Required Parameter
**Test:**
1. User types: "Schedule a call with Mike" (missing dateTime)
2. AI should ask clarifying question

**Expected:**
- AI responds: "When would you like to schedule the call with Mike?"
- No confirmation card shown yet
- User can reply with time to complete action

**Pass:** AI handles missing parameter gracefully, no crash, clear follow-up

---

#### Edge Case 2: Invalid Client Name
**Test:**
1. User types: "Schedule call with XYZ NonExistent Person tomorrow at 2pm"
2. AI should validate client exists

**Expected:**
- Confirmation card shows error: "I couldn't find 'XYZ NonExistent Person' in your contacts"
- Cancel button returns to normal chat
- No Firestore write attempted

**Pass:** Invalid input caught before execution, clear error message shown

---

#### Edge Case 3: Edit Action Parameters
**Test:**
1. AI shows confirmation card for "Call with Mike tomorrow at 2pm, 30 min"
2. User taps "Edit"
3. User changes time to "3pm" and duration to "60 minutes"
4. User taps "Confirm"

**Expected:**
- Edit UI allows parameter modification
- Updated parameters reflected in confirmation card
- Firestore write uses edited values, not original

**Pass:** Editing works smoothly, final action uses edited parameters

---

### Error Handling

#### Offline Mode
**Test:**
1. Enable airplane mode
2. User confirms AI action (schedule call)

**Expected:**
- Immediate message: "No internet connection. Action will complete when online"
- Action queued locally (or clear message that it can't be done offline)
- When online: Action executes automatically OR user is prompted to retry

**Pass:** Clear offline handling, no silent failures

---

#### Firestore Write Failure
**Test:**
1. Simulate Firestore permission denied or network timeout
2. User confirms AI action

**Expected:**
- Error message: "Couldn't complete action. Try again?"
- Retry button shown
- Tapping retry attempts function execution again

**Pass:** Failure handled gracefully, retry option provided, no crash

---

#### Invalid DateTime (Past Date)
**Test:**
1. User types: "Schedule call with Mike yesterday at 2pm"
2. AI should validate dateTime is in future

**Expected:**
- AI responds: "That time has already passed. When should I schedule the call?"
- No confirmation card for invalid time
- User can provide future time to proceed

**Pass:** Past dates rejected before confirmation, clear feedback

---

#### Unauthorized Chat Access
**Test:**
1. User (via direct API call or hack) tries to send message to chatId they're not a member of
2. Backend validation should reject

**Expected:**
- Function returns error: "You don't have access to this chat"
- No message written to Firestore
- Error logged in audit trail

**Pass:** Security validation prevents unauthorized actions

---

### Performance Check

**Function Call Latency:**
- [ ] AI function call decision: <2 seconds (OpenAI API round-trip)
- [ ] Confirmation card render: <200ms
- [ ] Action execution (Firestore write): <1 second
- [ ] Total time (message → success): <5 seconds

**UI Responsiveness:**
- [ ] Tap "Confirm" → immediate loading state (<50ms)
- [ ] Tap "Cancel" → immediate dismissal (<50ms)
- [ ] No UI blocking during function execution

---

## 13. Definition of Done

Reference standards in `Psst/agents/shared-standards.md`:

- [ ] All 4 functions defined in OpenAI function calling schema
- [ ] Cloud Function handlers implemented with validation and error handling
- [ ] Firestore collections created: `/calendar`, `/reminders`, `/aiActions`
- [ ] Firebase security rules updated for new collections
- [ ] ActionConfirmationCard component built with confirm/cancel/edit
- [ ] AIAssistantViewModel enhanced with function calling state
- [ ] AIService.swift methods for function execution
- [ ] Success and error feedback UI implemented
- [ ] All acceptance gates pass (happy path, edge cases, errors)
- [ ] Manual testing completed:
  - [ ] Schedule call (past, future, invalid client)
  - [ ] Set reminder (valid, invalid date)
  - [ ] Send message (authorized, unauthorized chat)
  - [ ] Search messages (with/without chatId filter)
- [ ] Offline behavior tested (graceful degradation)
- [ ] Performance targets met (<5 sec end-to-end)
- [ ] Audit logs verified in Firestore `/aiActions`
- [ ] No console errors or warnings
- [ ] Documentation updated (inline comments for complex logic)

---

## 14. Risks & Mitigations

### Risk 1: OpenAI Function Calling Reliability
**Risk:** GPT-4 may hallucinate function parameters or call wrong function
**Impact:** Actions execute with incorrect data (wrong time, wrong client)
**Mitigation:**
- Always show confirmation card before execution
- Validate all parameters in Cloud Function (double-check)
- Log all function calls for debugging
- Add "Undo" feature within 30 seconds

### Risk 2: Natural Language Date Parsing
**Risk:** "Tomorrow at 2pm" may be ambiguous (timezone, DST)
**Impact:** Calendar events scheduled at wrong time
**Mitigation:**
- Use trainer's device timezone from iOS app
- Show parsed dateTime in confirmation card for user verification
- Allow editing before confirmation

### Risk 3: Firestore Write Failures
**Risk:** Network issues or permission errors prevent action execution
**Impact:** User thinks action completed, but nothing saved
**Mitigation:**
- Show clear error messages with retry button
- Don't show success message until Firestore write confirmed
- Store pending actions locally for retry on reconnect

### Risk 4: Unauthorized Data Access
**Risk:** Malicious user tries to send messages to chats they don't own
**Impact:** Privacy violation, spam
**Mitigation:**
- Validate trainerId matches authenticated user in Cloud Functions
- Verify trainer is member of chat before sending message
- Firebase security rules enforce ownership
- All attempts logged in audit trail

### Risk 5: Cost Overrun (OpenAI API Calls)
**Risk:** Function calling requires multiple API round-trips
**Impact:** Higher OpenAI usage costs
**Mitigation:**
- Cache frequent function definitions
- Batch function calls where possible
- Monitor usage via OpenAI dashboard
- Set rate limits per user (e.g., 100 actions/day)

---

## 15. Rollout & Telemetry

### Feature Flag
- **Yes** - `ai_function_calling_enabled` flag in Firestore `/config`
- Default: `false` (disabled for initial rollout)
- Can enable per-user for beta testing

### Metrics to Track
- **Usage:**
  - Function calls per user per day
  - Most popular function (scheduleCall vs setReminder vs sendMessage vs searchMessages)
  - Confirmation vs cancellation rate

- **Errors:**
  - Function call failures (Firestore write errors)
  - Parameter validation errors
  - OpenAI API timeouts

- **Latency:**
  - Time from message → confirmation card display
  - Time from confirm → success message
  - OpenAI function calling round-trip time

### Manual Validation Steps
1. Send test message requesting each of 4 functions
2. Verify confirmation cards show correct parsed parameters
3. Confirm actions → verify Firestore documents created
4. Cancel actions → verify no Firestore writes
5. Edit parameters → verify updated values used
6. Test invalid inputs (past dates, non-existent clients)
7. Test offline behavior
8. Review audit logs in `/aiActions` collection

---

## 16. Open Questions

- **Q1:** Should we limit the number of AI actions per day to prevent abuse?
  **Decision Needed:** Yes/No, and if yes, what limit? (Suggestion: 100 actions/day per trainer)

- **Q2:** Should "Send Message" require preview of message text before sending?
  **Decision Needed:** Always preview, or trust AI in YOLO mode? (Suggestion: Always preview for now)

- **Q3:** Should we support recurring events (e.g., "Schedule weekly call with Mike")?
  **Decision Needed:** Out of scope for PR-008, defer to future enhancement?

- **Q4:** What happens if calendar event conflicts with existing event?
  **Decision Needed:** Warn user, or allow double-booking? (Suggestion: Allow for now, warn in future)

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future PRs:

- [ ] **YOLO Mode Auto-Execution** - Handled in PR #012
- [ ] **Voice Interface** - Handled in PR #010
- [ ] **Proactive Suggestions** - Handled in PR #009 (AI suggests actions without being asked)
- [ ] **Multi-Step Agent Workflows** - Handled in PR #013 (lead qualification flow)
- [ ] **Calendar/Reminder Management UI** - Full CRUD views for calendar and reminders
- [ ] **Recurring Events** - "Schedule weekly call with Mike every Monday"
- [ ] **Conflict Detection** - Warn when scheduling overlaps with existing event
- [ ] **Undo Feature** - Reverse action within 30 seconds
- [ ] **Batch Actions** - "Schedule calls with all clients who haven't checked in this week"
- [ ] **Advanced Permissions** - Different action limits for free vs paid trainers

---

## Preflight Questionnaire

1. **Smallest end-to-end user outcome for this PR?**
   Trainer asks AI "Schedule call with Mike tomorrow at 2pm" → AI shows confirmation → Trainer taps confirm → Calendar event created

2. **Primary user and critical action?**
   Alex (trainer) - Execute AI-suggested actions (schedule, remind, send, search)

3. **Must-have vs nice-to-have?**
   Must: 4 functions, confirmation UI, Firestore writes, validation
   Nice: Edit feature, undo, conflict detection

4. **Real-time requirements?**
   No real-time sync needed. Actions write to Firestore, standard latency (<1s) acceptable.

5. **Performance constraints?**
   - Function call decision: <2 seconds (OpenAI API)
   - Action execution: <1 second (Firestore write)
   - Total flow: <5 seconds (message → success)

6. **Error/edge cases to handle?**
   - Missing parameters (AI asks clarifying question)
   - Invalid client name (error before confirmation)
   - Past dateTime (validation error)
   - Offline mode (queue or clear error message)
   - Firestore write failure (retry option)
   - Unauthorized chat access (backend validation)

7. **Data model changes?**
   New collections: `/calendar`, `/reminders`, `/aiActions`

8. **Service APIs required?**
   - Cloud Function: Enhanced `chatWithAI` with function calling
   - 4 execution handlers: scheduleCall, setReminder, sendMessage, searchMessages
   - iOS: AIService.executeFunctionCall()

9. **UI entry points and states?**
   Entry: AI Assistant chat
   States: Idle → Processing → Awaiting Confirmation → Executing → Success/Failed

10. **Security/permissions implications?**
    - Validate trainerId matches authenticated user
    - Verify trainer is chat member before sending message
    - Firebase security rules for new collections
    - Audit log all function calls

11. **Dependencies or blocking integrations?**
    - Requires PR #003 (AI Chat Backend) completed
    - Optional but enhanced by PR #005 (RAG for searchMessages function)

12. **Rollout strategy and metrics?**
    - Feature flag: `ai_function_calling_enabled`
    - Track: function usage, errors, latency, confirmation rate
    - Manual validation: Test all 4 functions + edge cases

13. **What is explicitly out of scope?**
    - YOLO mode (PR #012), Voice (PR #010), Proactive (PR #009), Multi-step agents (PR #013)
    - Calendar/Reminder management UI (just create data, no views)
    - Undo, recurring events, conflict detection, batch actions

---

## Authoring Notes

- **Write Test Plan before coding** - Section 12 defines acceptance gates
- **Favor vertical slice** - All 4 functions work end-to-end, but no advanced features yet
- **Keep service layer deterministic** - Cloud Functions validate and return success/error
- **SwiftUI views are thin wrappers** - Logic in ViewModel, UI displays state
- **Test offline/online thoroughly** - Graceful degradation when network fails
- **Reference `Psst/agents/shared-standards.md` throughout** - TypeScript-only backend, MVVM patterns, async/await

---

**Dependencies:**
- PR #003: AI Chat Backend (required)
- PR #005: RAG Pipeline (enhances `searchMessages` function)

**Enables:**
- PR #009: Proactive Assistant (uses function calling for suggestions)
- PR #012: YOLO Mode (auto-execute functions without confirmation)
- PR #013: Multi-Step Agent (function calling for lead qualification flow)
