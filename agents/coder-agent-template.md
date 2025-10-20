# Building Agent (Coder) — Instructions Template

**Role:** Implementation agent that builds features from PRD and TODO list

---

## 🎯 ASSIGNMENT

**PR Number:** `#___` ← **FILL THIS IN**

**PR Name:** `___________` ← Will be found in pr-briefs.md

**Branch Name:** `feat/pr-___-{feature-name}` ← Create this branch

---

**Input Documents:**
- PRD document (`psst/docs/prds/pr-{number}-prd.md`) - READ this
- TODO list (`psst/docs/todos/pr-{number}-todo.md`) - READ this
- PR brief (`psst/docs/pr-briefs.md`) - READ for context
- Architecture doc (`psst/docs/architecture.md`) - READ for codebase structure

**Documents you will CREATE:**
- Feature code (SwiftUI views, services, models, etc.)
- Test files:
  - Unit tests: `PsstTests/{Feature}Tests.swift`
  - UI tests: `PsstUITests/{Feature}UITests.swift`
  - Service tests: `PsstTests/Services/{ServiceName}Tests.swift` (if applicable)

---

## Workflow Steps

### Step 1: Setup
```
FIRST: Create a new branch FROM develop
- Base branch: develop
- Branch name: feat/pr-{number}-{feature-name}
- Example: feat/pr-1-pencil-tool

Commands:
git checkout develop
git pull origin develop
git checkout -b feat/pr-1-pencil-tool
```

### Step 2: Read PRD and TODO

**IMPORTANT:** PRD and TODO have already been created. Your job is to implement them.

**Read these documents thoroughly:**
1. **PRD** (`psst/docs/prds/pr-{number}-prd.md`)
   - Understand all requirements
   - Note acceptance gates
   - Review data model and service contracts
   - Check UI components to modify
   
2. **TODO** (`psst/docs/todos/pr-{number}-todo.md`)
   - This is your step-by-step guide
   - Follow tasks in order
   - Check off each task as you complete it
   
3. **Architecture doc** (`psst/docs/architecture.md`)
   - Understand codebase structure
   - Follow existing patterns

**Key questions to verify:**
- Do I understand the end-to-end user outcome?
- Do I know which files to modify/create?
- Are the acceptance gates clear?
- Do I understand the dependencies?

**If anything is unclear in the PRD/TODO, ask for clarification before proceeding.**

### Step 3: Implementation

**Follow the TODO list exactly:**
- Complete tasks in order (top to bottom)
- Check off each task as you complete it
- If blocked, document the blocker in TODO
- Keep PRD open as reference for requirements

**Code quality requirements:**
- Follow existing Swift code patterns
- Use proper Swift types (avoid `Any` types)
- Include comments for complex logic
- Use meaningful variable names
- Keep functions small and focused
- Follow SwiftUI best practices

**Real-time messaging requirements:**
- Messages sync across devices in <100ms
- Offline messages queue and send on reconnect
- Optimistic UI updates for sent messages
- Handle concurrent messaging gracefully

**Performance requirements:**
- Smooth 60fps scrolling with 100+ messages
- App load time < 2-3 seconds
- Message send/receive latency < 100ms
- No UI blocking on main thread


### Step 4: Write Tests

**Create test files following the template at `agents/test-template.md`**

**You must create these test files:**

1. **Unit tests** (mandatory for all features):
   - Path: `PsstTests/{Feature}Tests.swift`
   - Tests: Service method behavior, validation, Firebase operations
   - Example: `PsstTests/MessageServiceTests.swift`

2. **UI tests** (mandatory for user-facing features):
   - Path: `PsstUITests/{Feature}UITests.swift`
   - Tests: User interactions, navigation, state changes
   - Example: `PsstUITests/ChatViewUITests.swift`

3. **Service tests** (if you created/modified service methods):
   - Path: `PsstTests/Services/{ServiceName}Tests.swift`
   - Tests: Firebase interactions, async operations, error handling
   - Example: `PsstTests/Services/MessageServiceTests.swift`

**For every feature, write these 2 types of tests:**

#### A. Unit Test (XCTest - Is the logic correct?)
```swift
// Example: Does message sending work correctly?
func testSendMessage() async throws {
    // Given
    let service = MessageService()
    let testMessage = "Hello World"
    
    // When
    let messageID = try await service.sendMessage(chatID: "test", text: testMessage)
    
    // Then
    XCTAssertNotNil(messageID)
    // Verify message saved to Firebase
    // Verify message has correct properties
}
```

#### B. UI Test (XCUITest - Does it work for users?)
```swift
// Example: Can user send a message?
func testUserCanSendMessage() throws {
    let app = XCUIApplication()
    app.launch()
    
    // Tap message input
    let messageInput = app.textFields["messageInput"]
    messageInput.tap()
    messageInput.typeText("Hello World")
    
    // Tap send button
    app.buttons["sendButton"].tap()
    
    // Assert message appears
    XCTAssertTrue(app.staticTexts["Hello World"].exists)
}
```

**Note:** Visual appearance testing (colors, spacing, fonts) will be verified manually by the user after implementation.

### Step 5: Multi-Device Testing (Automated)

**Write automated tests that simulate multiple devices (included in unit tests):**

```swift
// This is part of your unit test file
func testMessageSyncAcrossDevices() async throws {
    // Simulate 2 devices with Firebase
    let device1Service = MessageService()
    let device2Service = MessageService()
    
    // Device 1 sends message
    let messageID = try await device1Service.sendMessage(
        chatID: "test-chat",
        text: "Hello from device 1"
    )
    
    // Wait briefly for Firebase sync
    try await Task.sleep(nanoseconds: 100_000_000) // 100ms
    
    // Assert: Device 2 receives the message
    let messages = try await device2Service.fetchMessages(chatID: "test-chat")
    XCTAssertTrue(messages.contains { $0.id == messageID })
}
```

**This tests real-time sync programmatically, no manual device testing needed at this stage.**

**Note:** Manual multi-device testing will be done by USER during PR review.

### Step 6: Verify Acceptance Gates

**Check every gate from PRD Section 12:**
- [ ] All "Happy Path" gates pass
- [ ] All "Edge Case" gates pass
- [ ] All "Multi-User" gates pass
- [ ] All "Performance" gates pass

**If any gate fails:**
1. Document the failure in TODO
2. Fix the issue
3. Re-run tests
4. Don't proceed until all gates pass

### Step 7: Verify With User (Before PR)

**BEFORE creating the PR, verify with the user:**

1. **Build and run the application:**
   ```bash
   # Open in Xcode or build from command line
   xcodebuild -scheme Psst -destination 'platform=iOS Simulator,name=iPhone 15' build
   ```

2. **Test the feature end-to-end:**
   - Does it work as described in the PRD?
   - Are there any bugs or unexpected behaviors?
   - Does it feel smooth and responsive?

3. **Confirm with user:**
   ```
   "Feature is complete. All tests pass. All acceptance gates pass. 
   No bugs found in my testing. Ready to create PR?"
   ```

4. **Wait for user approval** before proceeding to create the PR

**If user finds issues:**
- Document them in TODO
- Fix the issues
- Re-run tests
- Verify again with user

### Step 8: Create Pull Request & Handoff

**IMPORTANT: PR must target `develop` branch, NOT `main`**

After creating the PR, the agent's work is complete. The following will be done by the user:

**Manual verification needed (USER does this):**

**PR title format:**
```
PR #{number}: {Feature Name}
Example: PR #1: Message Send Feature
```

**Base branch:** `develop`  
**Compare branch:** `feat/pr-{number}-{feature-name}`

**PR description must include:**

```markdown
## Summary
One sentence: what does this PR do?

## What Changed
- List all modified files
- List all new files created
- Note any breaking changes

## Testing
- [ ] Unit tests (XCTest) created and passing
- [ ] UI tests (XCUITest) created and passing (if UI changes)
- [ ] Service tests created and passing (if service methods added)
- [ ] Multi-device testing complete
- [ ] All acceptance gates pass
- [ ] Visual verification (USER will do this manually)
- [ ] Performance feel test (USER will do this manually)

## Checklist
- [ ] All TODO items completed
- [ ] Code follows existing Swift/SwiftUI patterns
- [ ] Proper Swift types used (no `Any`)
- [ ] Comments added for complex logic
- [ ] No console warnings

## Notes
Any gotchas, trade-offs, or future improvements to mention
```

---

## Testing Checklist (Run Before PR)

### Functional Tests
- [ ] Feature works as described in PRD
- [ ] All user interactions respond correctly
- [ ] Error states handled gracefully
- [ ] Loading states shown appropriately

### Performance Tests
- [ ] Smooth 60fps scrolling with 100+ messages
- [ ] App load time < 2-3 seconds
- [ ] Message delivery < 100ms
- [ ] No lag or stuttering
- [ ] No console warnings/errors

### Real-Time Messaging Tests
- [ ] Messages sync across devices <100ms
- [ ] Concurrent messages don't conflict
- [ ] Works with 3+ simultaneous devices
- [ ] Offline queue works correctly
- [ ] Reconnection handled gracefully

### Device Tests
- [ ] iPhone (various sizes: SE, 14, 15 Pro Max)
- [ ] iOS Simulator testing complete
- [ ] Physical device testing (USER will do)

### Edge Cases
- [ ] Empty chat view
- [ ] Chat with 100+ messages
- [ ] Offline mode (messages queue)
- [ ] Small screen (iPhone SE)
- [ ] Large screen (iPad/iPhone Pro Max)

---

## Common Issues & Solutions

### Issue: "My changes don't sync to Firebase"
**Solution:** Make sure you're calling the service method, not just updating local state
```swift
// ❌ Wrong - only updates local state
messages.append(newMessage)

// ✅ Correct - saves to Firebase AND updates local state
Task {
    try await messageService.sendMessage(chatID: chatID, text: text)
}
```

### Issue: "Performance is slow with many messages"
**Solution:** Use LazyVStack and optimize SwiftUI views
```swift
// Use LazyVStack for long lists
ScrollView {
    LazyVStack {
        ForEach(messages) { message in
            MessageRow(message: message)
        }
    }
}
```

### Issue: "Tests are failing"
**Solution:** Check these common problems:
1. Async operations not properly awaited
2. Firebase emulator not running
3. State not updating before assertion
4. Race conditions in concurrent tests

### Issue: "Real-time sync is slow"
**Solution:** 
1. Optimize Firebase queries with indexes
2. Use Firebase batch writes for multiple operations
3. Ensure Firestore persistence is enabled

---

## Code Review Self-Checklist

Before submitting PR, review your own code:

### Architecture
- [ ] Service layer methods are deterministic
- [ ] SwiftUI views are thin wrappers around services
- [ ] State management follows SwiftUI best practices
- [ ] No business logic in UI views

### Code Quality
- [ ] No print statements (use proper logging)
- [ ] No commented-out code
- [ ] No hardcoded values (use constants)
- [ ] No magic numbers
- [ ] No TODO comments without tickets

### Swift/SwiftUI Best Practices
- [ ] No `Any` types (use proper Swift types)
- [ ] All function parameters typed
- [ ] All return types specified
- [ ] Structs/Classes properly defined for models
- [ ] Proper use of `@State`, `@StateObject`, `@ObservedObject`
- [ ] Views are broken into small, reusable components

### Testing
- [ ] Tests are readable and maintainable
- [ ] Tests cover happy path
- [ ] Tests cover edge cases
- [ ] Tests don't depend on each other
- [ ] Tests clean up after themselves

### Documentation
- [ ] Complex logic has comments
- [ ] Public APIs have documentation comments
- [ ] README updated if needed
- [ ] Migration notes added if schema changed

---

## Emergency Procedures

### If you're blocked:
1. Document the blocker in TODO
2. Try a different approach
3. Ask for help (tag senior engineer)
4. Don't merge broken code

### If tests fail in CI:
1. Run tests locally first
2. Check CI logs for specific failure
3. Fix the issue
4. Push fix to same branch
5. Wait for CI to pass before merging

### If performance regresses:
1. Use Xcode Instruments (Time Profiler, Allocations)
2. Identify bottleneck
3. Optimize hot path
4. Re-run performance tests
5. Ensure smooth 60fps maintained

---

## Success Criteria

**PR is ready for USER review when:**
- ✅ All TODO items checked off
- ✅ All automated tests pass (Unit tests, UI tests)
- ✅ All acceptance gates pass
- ✅ Code review self-checklist complete
- ✅ No console warnings
- ✅ Documentation updated
- ✅ PR description complete

**USER will then verify:**
- Visual appearance (colors, spacing, fonts, animations)
- Performance feel (smooth, responsive, 60fps)
- Device compatibility (iPhone, iPad if supported)
- Real multi-device testing (2+ physical devices or simulators)

---

## Example: Complete Workflow

```bash
# 1. Create branch FROM develop
git checkout develop
git pull origin develop
git checkout -b feat/pr-1-message-send

# 2. Read PRD and TODO
# READ:
# - psst/docs/prds/pr-1-prd.md
# - psst/docs/todos/pr-1-todo.md
# - psst/docs/architecture.md

# 3. Implement feature (follow TODO)
# - Add MessageInputView.swift ✓
# - Add send handler to ChatView.swift ✓
# - Add MessageRow rendering ✓
# - Add sendMessage to MessageService.swift ✓
# - Add optimistic UI update ✓
# - etc...

# 4. Build in Xcode
# Open Psst.xcodeproj in Xcode
# Build: Cmd+B

# 5. Write tests
# CREATE:
# - PsstTests/MessageServiceTests.swift (unit tests)
# - PsstUITests/ChatViewUITests.swift (UI tests)
# - PsstTests/Services/MessageServiceTests.swift (if needed)

# 6. Run tests in Xcode
# Test: Cmd+U
# All tests should pass

# 7. Verify gates
# Check PRD Section 12, all gates pass ✓

# 8. IMPORTANT: Verify with user no bugs
# Run the app in simulator/device
# Test the feature end-to-end
# Confirm with user: "Feature is complete, all tests pass, no bugs found. Ready for PR?"
# Wait for user approval before proceeding to next step

# 9. Create PR (targeting develop)
git add .
git commit -m "feat: add message send functionality"
git push origin feat/pr-1-message-send
# Create PR on GitHub:
#   - Base: develop
#   - Compare: feat/pr-1-message-send
#   - Full description with screenshots

# 10. Merge when approved
```

---

**Remember:** Quality over speed. It's better to ship a solid feature late than a buggy feature on time.
