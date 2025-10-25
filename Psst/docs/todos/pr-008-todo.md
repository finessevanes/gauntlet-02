# PR-008 TODO — AI Function Calling (Tool Integration)

**Branch**: `feat/pr-008-ai-function-calling`
**Source PRD**: `Psst/docs/prds/pr-008-prd.md`
**Owner (Agent)**: Caleb

---

## 0. Clarifying Questions & Assumptions

**Questions:**
- ✅ All questions resolved in PRD review

**Assumptions:**
- PR #003 (AI Chat Backend) is completed and `chatWithAI` Cloud Function exists
- OpenAI API key and Pinecone API key configured in Firebase Functions config
- AI SDK by Vercel (`ai` package) already installed in functions/package.json
- Swift models for AI (AIMessage, AIConversation) exist from PR #002

---

## 1. Setup

- [ ] Create branch `feat/pr-008-ai-function-calling` from develop
  - **Test Gate:** Branch created, currently on correct branch

- [ ] Read PRD thoroughly (`Psst/docs/prds/pr-008-prd.md`)
  - **Test Gate:** Understand all 4 functions, data models, acceptance gates

- [ ] Read `Psst/agents/shared-standards.md` for patterns
  - **Test Gate:** Understand TypeScript requirements, MVVM patterns, testing approach

- [ ] Verify Cloud Functions environment works
  - **Test Gate:** `cd Psst/functions && npm install && npm run build` succeeds

- [ ] Verify iOS build works
  - **Test Gate:** Open Xcode, build succeeds without errors

---

## 2. Backend: OpenAI Function Definitions

### 2.1 Create Function Schema File

- [ ] Create `functions/schemas/aiFunctionSchemas.ts`
  - **Test Gate:** File created with proper TypeScript structure

- [ ] Define `scheduleCall` function schema
  - **Test Gate:** Schema includes name, description, parameters (clientName, dateTime, duration)

- [ ] Define `setReminder` function schema
  - **Test Gate:** Schema includes name, description, parameters (clientName, reminderText, dateTime)

- [ ] Define `sendMessage` function schema
  - **Test Gate:** Schema includes name, description, parameters (chatId, messageText)

- [ ] Define `searchMessages` function schema
  - **Test Gate:** Schema includes name, description, parameters (query, chatId, limit)

- [ ] Export `AIFunctionSchemas` array with all 4 functions
  - **Test Gate:** TypeScript compiles without errors

---

## 3. Backend: Function Execution Handlers

### 3.1 Create Execution Service

- [ ] Create `functions/services/functionExecutionService.ts`
  - **Test Gate:** File created with TypeScript structure

- [ ] Add imports for Firestore, validation utilities
  - **Test Gate:** No TypeScript errors

### 3.2 Implement scheduleCall Handler

- [ ] Create `executeScheduleCall(trainerId, clientName, dateTime, duration)` function
  - **Test Gate:** Function signature with proper TypeScript types

- [ ] Validate `dateTime` is in the future
  - **Test Gate:** Returns error if past date provided

- [ ] Find `clientId` from `clientName` in trainer's contacts
  - **Test Gate:** Query `/users` collection for displayName match

- [ ] Create calendar event in `/calendar/{eventId}`
  - **Test Gate:** Firestore write with all required fields (trainerId, clientId, clientName, title, dateTime, duration, createdBy: "ai", createdAt, status: "scheduled")

- [ ] Return success result with `eventId`
  - **Test Gate:** Returns `{ success: true, eventId: "...", message: "Call scheduled" }`

- [ ] Handle errors (invalid client, Firestore failure)
  - **Test Gate:** Returns `{ success: false, error: "..." }` for failures

### 3.3 Implement setReminder Handler

- [ ] Create `executeSetReminder(trainerId, clientName, reminderText, dateTime)` function
  - **Test Gate:** Function signature with proper TypeScript types

- [ ] Validate `dateTime` is valid future date
  - **Test Gate:** Returns error if invalid date

- [ ] Find `clientId` if `clientName` provided (optional parameter)
  - **Test Gate:** Query `/users` if clientName exists, otherwise null

- [ ] Create reminder in `/reminders/{reminderId}`
  - **Test Gate:** Firestore write with all required fields (trainerId, clientId, clientName, reminderText, dueDate, createdBy: "ai", createdAt, completed: false)

- [ ] Return success result with `reminderId`
  - **Test Gate:** Returns `{ success: true, reminderId: "...", message: "Reminder set" }`

- [ ] Handle errors
  - **Test Gate:** Returns `{ success: false, error: "..." }` for failures

### 3.4 Implement sendMessage Handler

- [ ] Create `executeSendMessage(trainerId, chatId, messageText)` function
  - **Test Gate:** Function signature with proper TypeScript types

- [ ] Verify trainer is a member of the specified chat
  - **Test Gate:** Query `/chats/{chatId}` and check `members` array includes trainerId

- [ ] Return error if unauthorized
  - **Test Gate:** Returns `{ success: false, error: "You don't have access to this chat" }` if not member

- [ ] Write message to `/chats/{chatId}/messages/{messageId}`
  - **Test Gate:** Firestore write with text, senderID (trainerId), timestamp, readBy: [trainerId]

- [ ] Update chat's `lastMessage` and `lastMessageTimestamp`
  - **Test Gate:** `/chats/{chatId}` updated

- [ ] Return success result with `messageId`
  - **Test Gate:** Returns `{ success: true, messageId: "...", message: "Message sent" }`

- [ ] Handle errors
  - **Test Gate:** Returns `{ success: false, error: "..." }` for failures

### 3.5 Implement searchMessages Handler

- [ ] Create `executeSearchMessages(trainerId, query, chatId, limit)` function
  - **Test Gate:** Function signature with proper TypeScript types

- [ ] Generate embedding for query using OpenAI
  - **Test Gate:** Call OpenAI embeddings API, get 1536-dim vector

- [ ] Query Pinecone with embedding and trainerId filter
  - **Test Gate:** Pinecone query with metadata filter: `{ trainerId: "..." }`

- [ ] Optionally filter by `chatId` if provided
  - **Test Gate:** Add `firestoreChatId` to metadata filter if chatId exists

- [ ] Limit results to specified limit (default 10)
  - **Test Gate:** Pinecone topK parameter set correctly

- [ ] Format results into message array
  - **Test Gate:** Returns structured array of messages with text, sender, timestamp

- [ ] Return success result with messages
  - **Test Gate:** Returns `{ success: true, messages: [...] }`

- [ ] Handle errors (OpenAI failure, Pinecone failure)
  - **Test Gate:** Returns `{ success: false, error: "..." }` for failures

---

## 4. Backend: Enhance chatWithAI Function

### 4.1 Add Function Calling to AI SDK

- [ ] Open `functions/functions/chatWithAI.ts`
  - **Test Gate:** File exists from PR #003

- [ ] Import `AIFunctionSchemas` from schemas file
  - **Test Gate:** No TypeScript errors

- [ ] Add `tools` parameter to AI SDK call
  - **Test Gate:** AI SDK configured with tools: AIFunctionSchemas

- [ ] Implement function execution callback
  - **Test Gate:** When AI calls function, execute corresponding handler (scheduleCall → executeScheduleCall)

- [ ] Pass function results back to AI for response generation
  - **Test Gate:** AI receives function result and generates natural language response

- [ ] Handle function execution errors
  - **Test Gate:** AI receives error message and informs user gracefully

- [ ] Test with manual Cloud Function call
  - **Test Gate:** Deploy function, call with "Schedule call with Mike tomorrow at 2pm", verify function called

---

## 5. Backend: Audit Logging

### 5.1 Create Audit Log Service

- [ ] Create `functions/services/auditLogService.ts`
  - **Test Gate:** File created with TypeScript structure

- [ ] Implement `logFunctionCall(trainerId, functionName, parameters, status, result)` function
  - **Test Gate:** Function signature with proper types

- [ ] Write to `/aiActions/{actionId}` collection
  - **Test Gate:** Firestore write with trainerId, functionName, parameters (Map), status, result, createdAt, executedAt

- [ ] Return actionId
  - **Test Gate:** Returns document ID for reference

### 5.2 Integrate Audit Logging

- [ ] Add audit log call to each function execution handler
  - **Test Gate:** Before execution: log with status "pending"

- [ ] Update audit log after execution
  - **Test Gate:** After execution: update with status "executed" or "failed", add result and executedAt

- [ ] Test audit logging
  - **Test Gate:** Execute function, verify `/aiActions/{actionId}` document created with correct data

---

## 6. Firestore: Data Model & Security Rules

### 6.1 Create Firestore Collections (Manual)

- [ ] Create `/calendar` collection in Firebase Console
  - **Test Gate:** Collection exists, can manually write test document

- [ ] Create `/reminders` collection in Firebase Console
  - **Test Gate:** Collection exists, can manually write test document

- [ ] Create `/aiActions` collection in Firebase Console
  - **Test Gate:** Collection exists, can manually write test document

### 6.2 Update Firestore Security Rules

- [ ] Open `firestore.rules` file
  - **Test Gate:** File exists in project root

- [ ] Add rules for `/calendar/{eventId}`
  - **Test Gate:** Allow read/write if request.auth.uid == resource.data.trainerId

- [ ] Add rules for `/reminders/{reminderId}`
  - **Test Gate:** Allow read/write if request.auth.uid == resource.data.trainerId

- [ ] Add rules for `/aiActions/{actionId}`
  - **Test Gate:** Allow read if request.auth.uid == resource.data.trainerId, allow write from Cloud Functions only

- [ ] Deploy security rules
  - **Test Gate:** `firebase deploy --only firestore:rules` succeeds

- [ ] Test rules with unauthenticated request
  - **Test Gate:** Unauthenticated read/write denied

---

## 7. iOS: Data Models

### 7.1 Create Calendar Event Model

- [ ] Create `Models/CalendarEvent.swift`
  - **Test Gate:** File created in Xcode project

- [ ] Define `CalendarEvent` struct conforming to `Codable`, `Identifiable`
  - **Test Gate:** Properties: id, trainerId, clientId, clientName, title, dateTime (Date), duration (Int), createdBy, createdAt, status

- [ ] Add Firebase Timestamp conversion helpers
  - **Test Gate:** Codable encoding/decoding works with Firestore Timestamp

### 7.2 Create Reminder Model

- [ ] Create `Models/Reminder.swift`
  - **Test Gate:** File created in Xcode project

- [ ] Define `Reminder` struct conforming to `Codable`, `Identifiable`
  - **Test Gate:** Properties: id, trainerId, clientId, clientName, reminderText, dueDate (Date), createdBy, createdAt, completed (Bool), completedAt

- [ ] Add Firebase Timestamp conversion helpers
  - **Test Gate:** Codable encoding/decoding works

### 7.3 Create Function Call Models

- [ ] Create `Models/FunctionCall.swift`
  - **Test Gate:** File created

- [ ] Define `PendingAction` struct
  - **Test Gate:** Properties: id (UUID), functionName, parameters ([String: Any]), displayText, timestamp

- [ ] Define `FunctionExecutionResult` struct
  - **Test Gate:** Properties: success (Bool), actionId (String?), result (String?), data ([String: Any]?)

- [ ] Add helper methods for display formatting
  - **Test Gate:** `displayText` property generates human-readable description ("Schedule call with Mike Johnson on Jan 15 at 2:00 PM")

---

## 8. iOS: AIService Enhancement

### 8.1 Add Function Execution Methods

- [ ] Open `Services/AIService.swift`
  - **Test Gate:** File exists from PR #002

- [ ] Add `executeFunctionCall(functionName:parameters:requireConfirmation:)` method
  - **Test Gate:** Method signature: `func executeFunctionCall(functionName: String, parameters: [String: Any], requireConfirmation: Bool = true) async throws -> FunctionExecutionResult`

- [ ] Implement Cloud Function call to execute function
  - **Test Gate:** Calls Firebase callable function with functionName and parameters

- [ ] Parse response into `FunctionExecutionResult`
  - **Test Gate:** Returns success/failure with result message

- [ ] Handle errors (network, auth, execution failure)
  - **Test Gate:** Throws descriptive errors for different failure cases

- [ ] Add unit test for `executeFunctionCall`
  - **Test Gate:** Mock Cloud Function response, verify parsing works

---

## 9. iOS: AIAssistantViewModel Enhancement

### 9.1 Add Function Calling State

- [ ] Open `ViewModels/AIAssistantViewModel.swift`
  - **Test Gate:** File exists from PR #004

- [ ] Add `@Published var pendingAction: PendingAction? = nil`
  - **Test Gate:** Property added with proper SwiftUI Published wrapper

- [ ] Add `@Published var isExecutingAction: Bool = false`
  - **Test Gate:** Property added

- [ ] Add `@Published var lastActionResult: FunctionExecutionResult? = nil`
  - **Test Gate:** Property added

### 9.2 Implement Function Call Handling

- [ ] Create `handleFunctionCall(functionName:parameters:)` method
  - **Test Gate:** Method signature: `func handleFunctionCall(functionName: String, parameters: [String: Any])`

- [ ] Generate display text from parameters
  - **Test Gate:** Calls helper to create human-readable description

- [ ] Set `pendingAction` with function details
  - **Test Gate:** UI reacts to show confirmation card

- [ ] Create `confirmAction()` method
  - **Test Gate:** Calls `AIService.executeFunctionCall()`, sets `isExecutingAction = true`

- [ ] Handle execution result
  - **Test Gate:** On success: show success message, clear pendingAction; On failure: show error message

- [ ] Create `cancelAction()` method
  - **Test Gate:** Clears `pendingAction`, sends cancellation message to AI

- [ ] Create `editAction(newParameters:)` method
  - **Test Gate:** Updates `pendingAction` parameters, allows re-confirmation

### 9.3 Integrate with AI Response Parsing

- [ ] Update `sendMessage()` method to detect function calls in AI response
  - **Test Gate:** When AI response includes function_call, extract functionName and parameters

- [ ] Call `handleFunctionCall()` when function detected
  - **Test Gate:** `pendingAction` set, confirmation UI appears

- [ ] Handle AI text responses normally (no function)
  - **Test Gate:** Regular chat messages work as before

---

## 10. iOS: UI Components

### 10.1 Create ActionConfirmationCard

- [ ] Create `Views/Components/ActionConfirmationCard.swift`
  - **Test Gate:** File created in Xcode

- [ ] Design card layout with action details
  - **Test Gate:** VStack with function icon, title, parameter details

- [ ] Add "Confirm" button
  - **Test Gate:** Green button, calls `confirmAction()` on tap

- [ ] Add "Cancel" button
  - **Test Gate:** Gray button, calls `cancelAction()` on tap

- [ ] Add "Edit" button
  - **Test Gate:** Blue button, shows inline editor

- [ ] Add parameter display section
  - **Test Gate:** Shows formatted parameters (Client: Mike, Time: 2:00 PM, Duration: 30 min)

- [ ] Add loading state overlay when executing
  - **Test Gate:** Shows spinner when `isExecutingAction == true`

- [ ] Test in Xcode Preview with mock data
  - **Test Gate:** Preview renders correctly with sample PendingAction

### 10.2 Create ActionSuccessView

- [ ] Create `Views/Components/ActionSuccessView.swift`
  - **Test Gate:** File created

- [ ] Design success message with checkmark animation
  - **Test Gate:** Green checkmark icon with scale animation

- [ ] Display success message text
  - **Test Gate:** Text from `FunctionExecutionResult.result`

- [ ] Auto-dismiss after 3 seconds
  - **Test Gate:** Uses `DispatchQueue.main.asyncAfter` to clear

- [ ] Test in Preview
  - **Test Gate:** Animation plays smoothly

### 10.3 Create ActionErrorView

- [ ] Create `Views/Components/ActionErrorView.swift`
  - **Test Gate:** File created

- [ ] Design error message with error icon
  - **Test Gate:** Red X icon

- [ ] Display error message text
  - **Test Gate:** Text from `FunctionExecutionResult.result`

- [ ] Add "Retry" button
  - **Test Gate:** Calls `confirmAction()` again on tap

- [ ] Add "Cancel" button
  - **Test Gate:** Dismisses error, calls `cancelAction()`

- [ ] Test in Preview
  - **Test Gate:** Renders correctly with sample error

### 10.4 Create Parameter Editor (Edit Mode)

- [ ] Create `Views/Components/ActionParameterEditor.swift`
  - **Test Gate:** File created

- [ ] Add text fields for editable parameters
  - **Test Gate:** TextField for each parameter (clientName, dateTime, duration, etc.)

- [ ] Add DatePicker for dateTime parameters
  - **Test Gate:** DatePicker shows, updates parameter on change

- [ ] Add "Save" button
  - **Test Gate:** Calls `editAction(newParameters:)` with updated values

- [ ] Validate inputs before saving
  - **Test Gate:** Shows error if invalid (e.g., empty client name)

- [ ] Test in Preview
  - **Test Gate:** Can edit parameters, save works

---

## 11. iOS: Integrate Confirmation UI

### 11.1 Update AIAssistantView

- [ ] Open `Views/AIAssistantView.swift`
  - **Test Gate:** File exists from PR #004

- [ ] Add overlay for ActionConfirmationCard
  - **Test Gate:** `.overlay { if let action = viewModel.pendingAction { ActionConfirmationCard(...) } }`

- [ ] Pass `pendingAction` to card
  - **Test Gate:** Card displays with correct action details

- [ ] Add overlay for ActionSuccessView
  - **Test Gate:** Shows when `lastActionResult?.success == true`

- [ ] Add overlay for ActionErrorView
  - **Test Gate:** Shows when `lastActionResult?.success == false`

- [ ] Test overlays in Simulator
  - **Test Gate:** Confirmation card appears, confirm works, success/error shows

---

## 12. User-Centric Testing

### 12.1 Happy Path: Schedule Call

- [ ] Open AI Assistant in Simulator
  - **Test Gate:** AI Assistant screen loads

- [ ] Type: "Schedule a call with Mike Johnson tomorrow at 2pm"
  - **Test Gate:** Message sent to AI

- [ ] Verify confirmation card appears
  - **Test Gate:** Card shows "Schedule Call", Client: Mike Johnson, Date: tomorrow 2:00 PM, Duration: 30 min

- [ ] Tap "Confirm"
  - **Test Gate:** Loading spinner appears

- [ ] Verify success message
  - **Test Gate:** Green checkmark + "✓ Call scheduled for [date] at 2:00 PM"

- [ ] Check Firestore in Firebase Console
  - **Test Gate:** `/calendar/{eventId}` document exists with correct data

- [ ] Check audit log
  - **Test Gate:** `/aiActions/{actionId}` document exists with status: "executed"

- [ ] No console errors
  - **Test Gate:** Clean console output

### 12.2 Happy Path: Set Reminder

- [ ] Type: "Remind me to follow up with Sarah about her diet in 3 days"
  - **Test Gate:** Message sent

- [ ] Verify confirmation card
  - **Test Gate:** Card shows "Set Reminder", Client: Sarah, Text: "Follow up about her diet", Due: [3 days from now]

- [ ] Tap "Confirm"
  - **Test Gate:** Executes successfully

- [ ] Verify success message
  - **Test Gate:** "✓ Reminder set for [date]"

- [ ] Check Firestore
  - **Test Gate:** `/reminders/{reminderId}` document exists

### 12.3 Happy Path: Send Message

- [ ] Type: "Send John a message asking how his knee is feeling"
  - **Test Gate:** AI generates message text

- [ ] Verify confirmation card
  - **Test Gate:** Card shows "Send Message", Chat: John, Message: [preview of message text]

- [ ] Tap "Confirm"
  - **Test Gate:** Message sent

- [ ] Verify success
  - **Test Gate:** "✓ Message sent to John"

- [ ] Check chat conversation
  - **Test Gate:** Open John's chat, message appears sent by trainer

### 12.4 Happy Path: Search Messages

- [ ] Type: "Find all messages where Mike mentioned his shoulder"
  - **Test Gate:** Message sent

- [ ] Verify AI response (no confirmation needed for search)
  - **Test Gate:** AI shows results: "I found 3 messages: 1) 'My shoulder hurts' on Jan 10, 2) ..."

- [ ] Verify results are relevant
  - **Test Gate:** Results semantically match "shoulder" query

### 12.5 Edge Case: Missing Parameter

- [ ] Type: "Schedule a call with Mike" (no time)
  - **Test Gate:** Message sent

- [ ] Verify AI asks clarifying question
  - **Test Gate:** AI responds: "When would you like to schedule the call with Mike?"

- [ ] Reply with time: "Tomorrow at 3pm"
  - **Test Gate:** Confirmation card now appears with complete parameters

- [ ] Confirm action
  - **Test Gate:** Successfully creates calendar event

### 12.6 Edge Case: Invalid Client Name

- [ ] Type: "Schedule call with XYZ NonExistent Person tomorrow at 2pm"
  - **Test Gate:** Message sent

- [ ] Verify error handling
  - **Test Gate:** AI shows error: "I couldn't find 'XYZ NonExistent Person' in your contacts"

- [ ] Verify no Firestore write
  - **Test Gate:** No new calendar event created

- [ ] Conversation continues normally
  - **Test Gate:** Can send another message

### 12.7 Edge Case: Edit Parameters

- [ ] Type: "Schedule call with Mike tomorrow at 2pm, 30 minutes"
  - **Test Gate:** Confirmation card appears

- [ ] Tap "Edit" button
  - **Test Gate:** Parameter editor appears

- [ ] Change time to "3:00 PM" and duration to "60 minutes"
  - **Test Gate:** Fields update

- [ ] Tap "Save" in editor
  - **Test Gate:** Confirmation card updates with new values

- [ ] Tap "Confirm"
  - **Test Gate:** Calendar event created with edited values (3:00 PM, 60 min)

- [ ] Check Firestore
  - **Test Gate:** Event shows 3:00 PM, not 2:00 PM

### 12.8 Edge Case: Cancel Action

- [ ] Type: "Schedule call with Mike tomorrow at 2pm"
  - **Test Gate:** Confirmation card appears

- [ ] Tap "Cancel"
  - **Test Gate:** Card dismisses

- [ ] Verify AI acknowledges
  - **Test Gate:** AI responds: "Okay, I won't schedule that"

- [ ] Verify no Firestore write
  - **Test Gate:** No calendar event created

### 12.9 Error Handling: Offline Mode

- [ ] Enable airplane mode on device/simulator
  - **Test Gate:** Network disconnected

- [ ] Type: "Schedule call with Mike tomorrow at 2pm"
  - **Test Gate:** Message may queue or show error

- [ ] If confirmation appears, tap "Confirm"
  - **Test Gate:** Shows error: "No internet connection. Try again when online"

- [ ] Disable airplane mode
  - **Test Gate:** Network reconnected

- [ ] Tap "Retry" on error message
  - **Test Gate:** Action executes successfully now

### 12.10 Error Handling: Firestore Write Failure

- [ ] Simulate Firestore failure (temporarily disable internet mid-request or use security rule denial)
  - **Test Gate:** Setup simulated failure

- [ ] Confirm an action
  - **Test Gate:** Execution fails

- [ ] Verify error message
  - **Test Gate:** Shows "Couldn't complete action. Try again?"

- [ ] Tap "Retry"
  - **Test Gate:** Retries execution (succeeds if network restored)

### 12.11 Error Handling: Past DateTime

- [ ] Type: "Schedule call with Mike yesterday at 2pm"
  - **Test Gate:** Message sent

- [ ] Verify validation error
  - **Test Gate:** AI responds: "That time has already passed. When should I schedule the call?"

- [ ] Provide future time
  - **Test Gate:** Confirmation card appears with valid time

### 12.12 Error Handling: Unauthorized Chat Access

- [ ] Manually call function with chatId user doesn't own (via API test or modified code)
  - **Test Gate:** Backend receives request with unauthorized chatId

- [ ] Verify security validation
  - **Test Gate:** Cloud Function returns error: "You don't have access to this chat"

- [ ] Verify no message written
  - **Test Gate:** Firestore `/chats/{chatId}/messages` unchanged

- [ ] Verify audit log
  - **Test Gate:** `/aiActions/{actionId}` shows status: "failed", result: error message

---

## 13. Performance Verification

### 13.1 Function Call Latency

- [ ] Measure time from sending message to confirmation card appearing
  - **Test Gate:** Use Xcode Instruments or manual stopwatch, <2 seconds

- [ ] Measure time from tapping "Confirm" to success message
  - **Test Gate:** <1 second for Firestore write

- [ ] Measure total flow time (message → success)
  - **Test Gate:** <5 seconds end-to-end

### 13.2 UI Responsiveness

- [ ] Tap "Confirm" button
  - **Test Gate:** Immediate visual feedback (<50ms), loading spinner appears

- [ ] Tap "Cancel" button
  - **Test Gate:** Immediate dismissal (<50ms)

- [ ] No UI blocking during execution
  - **Test Gate:** Can scroll chat while action executes (async operation)

---

## 14. Acceptance Gates Review

Run through all acceptance gates from PRD Section 12:

### Function Calling Gates
- [ ] AI receives "Schedule call with Mike tomorrow at 2pm" → Calls `scheduleCall()` with correct parameters
- [ ] AI receives "Remind me about Sarah's diet in 3 days" → Calls `setReminder()` with dateTime = now + 3 days
- [ ] All 4 functions callable by GPT-4 via OpenAI function calling API

### Validation Gates
- [ ] Invalid clientName → AI shows "I couldn't find Mike in your contacts"
- [ ] Past dateTime → AI shows "That time has passed. When should I schedule it?"
- [ ] Unauthorized chatId → Function returns error, no data written

### Confirmation Flow Gates
- [ ] Function call → Confirmation card appears in <2 seconds
- [ ] User taps "Confirm" → Action executes → Success message appears within 1 second
- [ ] User taps "Cancel" → No action taken, AI acknowledges cancellation
- [ ] User taps "Edit" → Inline editor appears, allows parameter modification

### Execution Gates
- [ ] Confirmed action → Data written to Firestore → Success status returned
- [ ] Firestore write fails → Error message shows with retry button
- [ ] Retry successful → Success message replaces error

### Audit Gates
- [ ] Every function call → Entry created in `/aiActions/{actionId}` with all details
- [ ] Audit log includes: timestamp, trainerId, functionName, parameters, status (pending/success/failed)

---

## 15. Documentation & PR

### 15.1 Code Documentation

- [ ] Add TSDoc comments to all exported Cloud Functions
  - **Test Gate:** Each function has description, @param, @returns

- [ ] Add Swift documentation comments to public methods
  - **Test Gate:** AIService and ViewModel methods have doc comments

- [ ] No commented-out code in final commit
  - **Test Gate:** Clean code review

- [ ] No hardcoded values (use constants)
  - **Test Gate:** No magic numbers or strings

### 15.2 Testing Documentation

- [ ] Document all manual test results
  - **Test Gate:** Create test log with pass/fail for each scenario

- [ ] Screenshot key UI states (confirmation card, success, error)
  - **Test Gate:** Screenshots saved to `Psst/docs/mocks/pr-008/`

### 15.3 Create PR Description

- [ ] Write PR description using Caleb's format
  - **Test Gate:** Includes: Summary, Changes Made, Testing Completed, Screenshots, Checklist

- [ ] Link PRD and TODO
  - **Test Gate:** Links to `pr-008-prd.md` and `pr-008-todo.md`

- [ ] List Firestore changes
  - **Test Gate:** Documents new collections: /calendar, /reminders, /aiActions

- [ ] List new dependencies
  - **Test Gate:** None (AI SDK already installed in PR #003)

### 15.4 Verify with User Before Creating PR

- [ ] Present completed work to user
  - **Test Gate:** User reviews functionality

- [ ] Demo all 4 functions working
  - **Test Gate:** Live demo or screen recording

- [ ] Address any feedback
  - **Test Gate:** Make requested changes

- [ ] Get explicit approval to create PR
  - **Test Gate:** User confirms ready

### 15.5 Create Pull Request

- [ ] Push branch to remote
  - **Test Gate:** `git push -u origin feat/pr-008-ai-function-calling`

- [ ] Open PR targeting `develop` branch (NOT main)
  - **Test Gate:** PR created on GitHub with correct target

- [ ] Add labels: `enhancement`, `ai-feature`, `phase-4`
  - **Test Gate:** Labels applied

- [ ] Link to PR #003 (dependency)
  - **Test Gate:** "Depends on #003" in description

- [ ] Request review
  - **Test Gate:** Reviewer assigned

---

## Copyable Checklist (for PR description)

```markdown
## Checklist

- [ ] Branch created from develop: `feat/pr-008-ai-function-calling`
- [ ] All TODO tasks completed and checked off
- [ ] 4 AI functions implemented: scheduleCall, setReminder, sendMessage, searchMessages
- [ ] Cloud Function handlers with validation and error handling
- [ ] Firestore collections created: /calendar, /reminders, /aiActions
- [ ] Firebase security rules updated and deployed
- [ ] ActionConfirmationCard UI component implemented
- [ ] Success/Error feedback views implemented
- [ ] AIService enhanced with function execution methods
- [ ] AIAssistantViewModel function calling state management
- [ ] Manual testing completed (12 scenarios: happy paths, edge cases, errors)
- [ ] All acceptance gates pass (function calling, validation, confirmation, execution, audit)
- [ ] Performance targets met (<5s end-to-end, <2s confirmation, <1s execution)
- [ ] Audit logging verified in Firestore /aiActions
- [ ] Offline behavior tested (graceful error handling)
- [ ] No console warnings or errors
- [ ] Code follows Psst/agents/shared-standards.md (TypeScript backend, MVVM, async/await)
- [ ] TSDoc/Swift doc comments added
- [ ] No hardcoded values or commented-out code
- [ ] Screenshots captured for key UI states
- [ ] User verified and approved before PR creation
```

---

## Notes

- **Task Size:** Break each task into <30 min chunks. If a task feels too large, split it further.
- **Sequential Completion:** Complete tasks in order. Don't skip ahead.
- **Check Off Immediately:** Mark each checkbox as soon as task is done, don't batch.
- **Document Blockers:** If stuck, document the blocker immediately and ask for help.
- **Reference Standards:** Constantly refer to `Psst/agents/shared-standards.md` for:
  - TypeScript-only backend (NO JavaScript)
  - MVVM patterns
  - Async/await concurrency
  - Testing approach (3 scenarios: happy path, edge cases, error handling)

---

## Dependencies

**Required (Must be completed first):**
- ✅ PR #003: AI Chat Backend (chatWithAI Cloud Function exists)
- ✅ PR #002: iOS AI Scaffolding (AIService, AIMessage models exist)

**Optional (Enhances functionality):**
- PR #005: RAG Pipeline (improves searchMessages semantic search)

**Enables (Blocked until this PR completes):**
- PR #009: Proactive Assistant (uses function calling for suggestions)
- PR #012: YOLO Mode (auto-executes functions without confirmation)
- PR #013: Multi-Step Agent (function calling for lead qualification)

---

**Total Estimated Tasks:** 95+ checkboxes
**Estimated Completion Time:** 10-15 hours (assuming PR #003 is complete)
**Complexity:** Complex (backend + iOS + new data models + extensive testing)

🚀 Ready for Caleb to implement!
