# Testing Guidelines

Reference this when creating tests for features. See also `agents/shared-standards.md` for testing standards.

---

## Testing Framework Strategy

This project uses a **hybrid testing approach**:

### Unit Tests → Swift Testing Framework ⭐ NEW
- **Path**: `PsstTests/{Feature}Tests.swift`
- **Framework**: Swift Testing (modern)
- **Syntax**: `@Test("Display Name")` with `#expect`
- **Benefits**: Readable test names in navigator, modern async/await support
- **Use for**: Service layer, business logic, data models, error handling

### UI Tests → XCTest Framework
- **Path**: `PsstUITests/{Feature}UITests.swift`
- **Framework**: XCTest (traditional)
- **Syntax**: `XCTestCase` with `func test...()`
- **Benefits**: Full `XCUIApplication` support, performance metrics
- **Use for**: User flows, navigation, UI interactions, app lifecycle

---

## Test Types Overview

### 1. Unit Tests (Swift Testing) ⭐ RECOMMENDED

**Path**: `PsstTests/{Feature}Tests.swift`

**Purpose**: Test service layer logic, validation, Firebase operations

**Pattern**:
```swift
import Testing
@testable import Psst

@Suite("Message Service Tests")
struct MessageServiceTests {
    
    /// Verifies that messages are sent successfully to Firebase
    @Test("Send Message With Valid Data Creates Message")
    func sendMessageWithValidDataCreatesMessage() async throws {
        // Given
        let service = MessageService()
        let testMessage = "Hello World"
        let testChatID = "test-chat"
        
        // When
        let messageID = try await service.sendMessage(
            chatID: testChatID,
            text: testMessage
        )
        
        // Then
        #expect(messageID != nil)
        
        // Verify message saved to Firebase
        let messages = try await service.fetchMessages(chatID: testChatID)
        #expect(messages.contains { $0.id == messageID })
    }
    
    /// Verifies that empty messages throw validation error
    @Test("Send Empty Message Throws Validation Error")
    func sendEmptyMessageThrowsValidationError() async throws {
        // Given
        let service = MessageService()
        
        // When/Then
        await #expect(throws: ValidationError.self) {
            try await service.sendMessage(chatID: "test", text: "")
        }
    }
}
```

**Key Points:**
- Use `@Suite("Suite Name")` for test grouping
- Use `@Test("Display Name")` for readable test names in navigator
- Use `#expect` instead of `XCTAssert`
- No `setUp/tearDown` - use instance properties or init if needed
- Tests show as "Send Message With Valid Data Creates Message" in Xcode

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

### 3. Service Tests (Swift Testing)
**Path**: `PsstTests/Services/{ServiceName}Tests.swift`

**Purpose**: Test Firebase-specific operations, async behavior, error handling

**Pattern**:
```swift
import Testing
@testable import Psst

@Suite("Message Service Firebase Tests")
struct MessageServiceFirebaseTests {
    
    /// Verifies that messages are written to Firestore successfully
    @Test("Firestore Write Creates Document")
    func firestoreWriteCreatesDocument() async throws {
        // Given
        let service = MessageService()
        let chatID = "test-chat-\(UUID().uuidString)"
        let text = "Test message"
        
        // When
        let messageID = try await service.sendMessage(chatID: chatID, text: text)
        
        // Then
        #expect(messageID != nil)
        // Query Firestore directly to confirm
    }
    
    /// Verifies that offline messages are queued and sent when online
    @Test("Offline Message Queue Syncs When Online")
    func offlineMessageQueueSyncsWhenOnline() async throws {
        // Given: Offline mode
        // When: Send message
        // Then: Verify queued locally
        // When: Reconnection
        // Then: Verify message sent
    }
}
```

---

## Multi-Device Testing (Swift Testing)

Use this pattern for testing real-time sync (from `agents/shared-standards.md`):

```swift
@Suite("Multi-Device Sync Tests")
struct MultiDeviceSyncTests {
    
    /// Verifies that messages sync across devices within 100ms
    @Test("Message Sync Across Devices Completes Within 100ms")
    func messageSyncAcrossDevicesCompletesWithin100ms() async throws {
        // Given: 2 devices
        let device1Service = MessageService()
        let device2Service = MessageService()
        let chatID = "sync-test-\(UUID().uuidString)"
        
        // When: Device 1 sends message
        let messageID = try await device1Service.sendMessage(
            chatID: chatID,
            text: "Hello from device 1"
        )
        
        // Wait for Firebase sync (should be <100ms)
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Then: Device 2 receives the message
        let messages = try await device2Service.fetchMessages(chatID: chatID)
        
        #expect(messages.contains { $0.id == messageID })
        #expect(messages.first?.text == "Hello from device 1")
    }
    
    /// Verifies that concurrent messages from multiple devices succeed
    @Test("Concurrent Messages From Multiple Devices Succeed")
    func concurrentMessagesFromMultipleDevicesSucceed() async throws {
        // Given: 2 devices
        let device1 = MessageService()
        let device2 = MessageService()
        let chatID = "concurrent-test-\(UUID().uuidString)"
        
        // When: Both devices send simultaneously
        async let msg1 = device1.sendMessage(chatID: chatID, text: "From device 1")
        async let msg2 = device2.sendMessage(chatID: chatID, text: "From device 2")
        
        let (id1, id2) = try await (msg1, msg2)
        
        // Then: Both messages should succeed
        #expect(id1 != nil)
        #expect(id2 != nil)
        
        // And: Both should be in chat
        let messages = try await device1.fetchMessages(chatID: chatID)
        #expect(messages.count == 2)
    }
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

### Swift Testing Patterns

#### Testing Async Operations
```swift
@Test("Async Operation Returns Valid Result")
func asyncOperationReturnsValidResult() async throws {
    let result = try await service.asyncMethod()
    #expect(result != nil)
}
```

#### Testing Errors
```swift
@Test("Failing Method Throws Expected Error")
func failingMethodThrowsExpectedError() async throws {
    await #expect(throws: ExpectedErrorType.self) {
        try await service.failingMethod()
    }
}
```

#### Testing Boolean Conditions
```swift
@Test("User Is Authenticated After Login")
func userIsAuthenticatedAfterLogin() async throws {
    try await service.login(email: "test@example.com", password: "password")
    #expect(service.isAuthenticated == true)
}
```

### XCTest Patterns (for UI Tests)

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

### Framework Selection
- ✅ **Use Swift Testing** for all unit/service tests (readable names, modern syntax)
- ✅ **Use XCTest** for all UI tests (XCUIApplication support)
- ✅ Use `@Test("Display Name")` for unit tests (shows in navigator)
- ✅ Use `#expect` for Swift Testing, `XCTAssert` for XCTest

### General Best Practices
- ✅ Tests should be independent (don't rely on order)
- ✅ Clean up test data after each test
- ✅ Use meaningful test names
- ✅ Follow Given-When-Then pattern
- ✅ Test one thing per test function
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

