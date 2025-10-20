# Testing Guidelines

Reference this when creating tests for features. See also `agents/shared-standards.md` for testing standards.

---

## Test Types Overview

### 1. Unit Tests (XCTest)
**Path**: `PsstTests/{Feature}Tests.swift`

**Purpose**: Test service layer logic, validation, Firebase operations

**Pattern**:
```swift
import XCTest
@testable import Psst

class MessageServiceTests: XCTestCase {
    var service: MessageService!
    
    override func setUp() {
        super.setUp()
        service = MessageService()
    }
    
    override func tearDown() {
        service = nil
        super.tearDown()
    }
    
    func testSendMessage() async throws {
        // Given
        let testMessage = "Hello World"
        let testChatID = "test-chat"
        
        // When
        let messageID = try await service.sendMessage(
            chatID: testChatID,
            text: testMessage
        )
        
        // Then
        XCTAssertNotNil(messageID)
        // Verify message saved to Firebase
        let messages = try await service.fetchMessages(chatID: testChatID)
        XCTAssertTrue(messages.contains { $0.id == messageID })
    }
    
    func testSendEmptyMessage() async throws {
        // Empty message should throw error
        do {
            _ = try await service.sendMessage(chatID: "test", text: "")
            XCTFail("Should have thrown error")
        } catch {
            // Expected error
            XCTAssertTrue(true)
        }
    }
}
```

---

### 2. UI Tests (XCUITest)
**Path**: `PsstUITests/{Feature}UITests.swift`

**Purpose**: Test user interactions, navigation, UI state changes

**Pattern**:
```swift
import XCTest

class ChatViewUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    func testUserCanSendMessage() throws {
        // Navigate to chat view
        app.buttons["chatButton"].tap()
        
        // Type message
        let messageInput = app.textFields["messageInput"]
        XCTAssertTrue(messageInput.exists)
        messageInput.tap()
        messageInput.typeText("Hello World")
        
        // Send message
        app.buttons["sendButton"].tap()
        
        // Verify message appears
        let messageText = app.staticTexts["Hello World"]
        XCTAssertTrue(messageText.waitForExistence(timeout: 5))
    }
    
    func testEmptyMessageDisablesSendButton() throws {
        app.buttons["chatButton"].tap()
        
        let sendButton = app.buttons["sendButton"]
        
        // Send button should be disabled when input is empty
        XCTAssertFalse(sendButton.isEnabled)
        
        // Type text
        let messageInput = app.textFields["messageInput"]
        messageInput.tap()
        messageInput.typeText("Hello")
        
        // Now send button should be enabled
        XCTAssertTrue(sendButton.isEnabled)
    }
}
```

---

### 3. Service Tests
**Path**: `PsstTests/Services/{ServiceName}Tests.swift`

**Purpose**: Test Firebase-specific operations, async behavior, error handling

**Pattern**:
```swift
import XCTest
@testable import Psst

class MessageServiceFirebaseTests: XCTestCase {
    var service: MessageService!
    
    override func setUp() {
        super.setUp()
        service = MessageService()
        // Configure Firebase test environment
    }
    
    func testFirestoreWrite() async throws {
        let chatID = "test-chat-\(UUID().uuidString)"
        let text = "Test message"
        
        let messageID = try await service.sendMessage(chatID: chatID, text: text)
        
        // Verify written to Firestore
        // Query Firestore directly to confirm
        XCTAssertNotNil(messageID)
    }
    
    func testOfflineMessageQueue() async throws {
        // Simulate offline mode
        // Send message
        // Verify queued locally
        // Simulate reconnection
        // Verify message sent
    }
}
```

---

## Multi-Device Testing

Use this pattern for testing real-time sync (from `agents/shared-standards.md`):

```swift
func testMessageSyncAcrossDevices() async throws {
    // Simulate 2 devices
    let device1Service = MessageService()
    let device2Service = MessageService()
    
    let chatID = "sync-test-\(UUID().uuidString)"
    
    // Device 1 sends message
    let messageID = try await device1Service.sendMessage(
        chatID: chatID,
        text: "Hello from device 1"
    )
    
    // Wait for Firebase sync (should be <100ms)
    try await Task.sleep(nanoseconds: 100_000_000) // 100ms
    
    // Device 2 fetches messages
    let messages = try await device2Service.fetchMessages(chatID: chatID)
    
    // Assert device 2 received the message
    XCTAssertTrue(messages.contains { $0.id == messageID })
    XCTAssertEqual(messages.first?.text, "Hello from device 1")
}

func testConcurrentMessages() async throws {
    let device1 = MessageService()
    let device2 = MessageService()
    let chatID = "concurrent-test-\(UUID().uuidString)"
    
    // Both devices send simultaneously
    async let msg1 = device1.sendMessage(chatID: chatID, text: "From device 1")
    async let msg2 = device2.sendMessage(chatID: chatID, text: "From device 2")
    
    let (id1, id2) = try await (msg1, msg2)
    
    // Both messages should succeed
    XCTAssertNotNil(id1)
    XCTAssertNotNil(id2)
    
    // Both should be in chat
    let messages = try await device1.fetchMessages(chatID: chatID)
    XCTAssertEqual(messages.count, 2)
}
```

---

## Test Coverage Checklist

For every feature, ensure you have tests for:

### Happy Path
- [ ] Primary user action succeeds
- [ ] Data persists correctly
- [ ] UI updates appropriately

### Edge Cases
- [ ] Empty/invalid input
- [ ] Offline behavior
- [ ] Network errors
- [ ] Permission errors
- [ ] Boundary conditions (0 items, 1000+ items)

### Multi-User Scenarios
- [ ] Real-time sync (<100ms)
- [ ] Concurrent operations
- [ ] Conflict resolution

### Performance (see shared-standards.md)
- [ ] Smooth scrolling (60fps)
- [ ] Fast load times (<2-3s)
- [ ] Low latency (<100ms)

### State Management
- [ ] Loading states
- [ ] Error states
- [ ] Empty states
- [ ] Success states

---

## Test Organization

Structure your test files like this:

```swift
// MARK: - Setup/Teardown
override func setUp() { }
override func tearDown() { }

// MARK: - Happy Path Tests
func testFeatureWorksNormally() { }

// MARK: - Edge Case Tests
func testEmptyInput() { }
func testInvalidInput() { }
func testOfflineMode() { }

// MARK: - Multi-User Tests
func testRealTimeSync() { }
func testConcurrentOperations() { }

// MARK: - Performance Tests
func testLoadTime() { }
func testScrollPerformance() { }

// MARK: - Error Handling Tests
func testNetworkError() { }
func testPermissionError() { }
```

---

## Running Tests

### In Xcode
- Run all tests: `Cmd + U`
- Run specific test: Click diamond next to test function
- Run specific test class: Click diamond next to class name

### Command Line
```bash
# Run all tests
xcodebuild test -scheme Psst -destination 'platform=iOS Simulator,name=iPhone 15'

# Run specific test
xcodebuild test -scheme Psst -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:PsstTests/MessageServiceTests/testSendMessage
```

---

## Common Test Patterns

### Testing Async Operations
```swift
func testAsyncOperation() async throws {
    let result = try await service.asyncMethod()
    XCTAssertNotNil(result)
}
```

### Testing Errors
```swift
func testThrowsError() async throws {
    do {
        _ = try await service.failingMethod()
        XCTFail("Should have thrown error")
    } catch {
        // Expected error
        XCTAssertTrue(error is ExpectedErrorType)
    }
}
```

### Testing UI Existence
```swift
func testElementExists() {
    let element = app.buttons["buttonID"]
    XCTAssertTrue(element.exists)
    XCTAssertTrue(element.isHittable)
}
```

### Testing UI State
```swift
func testButtonState() {
    let button = app.buttons["submitButton"]
    XCTAssertFalse(button.isEnabled) // Initially disabled
    
    app.textFields["input"].typeText("text")
    XCTAssertTrue(button.isEnabled) // Now enabled
}
```

---

## Test Data Management

### Use Unique IDs
```swift
let testChatID = "test-\(UUID().uuidString)"
```

### Clean Up After Tests
```swift
override func tearDown() {
    // Delete test data from Firebase
    Task {
        try? await service.deleteTestData()
    }
    super.tearDown()
}
```

---

## Best Practices

- ✅ Tests should be independent (don't rely on order)
- ✅ Clean up test data after each test
- ✅ Use meaningful test names (testUserCanSendMessage)
- ✅ Follow Given-When-Then pattern
- ✅ Test one thing per test function
- ✅ Use XCTAssert for clear failure messages
- ✅ Mock external dependencies when appropriate
- ❌ Don't test implementation details
- ❌ Don't write flaky tests that sometimes fail
- ❌ Don't skip cleanup

---

## Visual Testing Note

**Visual appearance (colors, fonts, spacing, animations) is verified manually by user during PR review.**

Automated tests focus on:
- Functional correctness
- User interaction flows
- Data persistence
- Real-time sync
- Performance targets

See `agents/shared-standards.md` for more patterns and requirements.
