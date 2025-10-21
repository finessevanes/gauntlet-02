# Shared Standards & Requirements

This document contains common standards referenced by all agent templates to avoid duplication.

---

## Performance Requirements

All features MUST maintain these targets:

- **App load time**: < 2-3 seconds (cold start to interactive UI)
- **Message delivery latency**: < 100ms (send to receive)
- **Scrolling**: Smooth 60fps with 100+ messages
- **Tap feedback**: < 50ms response time
- **No UI blocking**: Keep main thread responsive
- **Smooth animations**: Use SwiftUI best practices

---

## Real-Time Messaging Requirements

Every feature involving messaging MUST address:

- **Sync speed**: Messages sync across devices in < 100ms
- **Offline behavior**: Messages queue and send on reconnect
- **Optimistic UI**: Immediate visual feedback before server confirmation
- **Concurrent messaging**: Handle multiple simultaneous messages gracefully
- **Works with 3+ devices**: Test multi-device scenarios

---

## Code Quality Standards

### Swift/SwiftUI Best Practices
- ✅ Use proper Swift types (avoid `Any`)
- ✅ All function parameters and return types explicitly typed
- ✅ Structs/Classes properly defined for models
- ✅ Proper use of `@State`, `@StateObject`, `@ObservedObject`, `@EnvironmentObject`
- ✅ Views broken into small, reusable components
- ✅ Keep functions small and focused
- ✅ Meaningful variable names

### Architecture
- ✅ Service layer methods are deterministic
- ✅ SwiftUI views are thin wrappers around services
- ✅ No business logic in UI views
- ✅ State management follows SwiftUI patterns

### Documentation
- ✅ Complex logic has comments
- ✅ Public APIs have documentation comments
- ✅ No commented-out code
- ✅ No hardcoded values (use constants)
- ✅ No magic numbers
- ✅ No TODO comments without tickets

---

## Testing Standards

### Testing Framework Strategy

This project uses a **hybrid testing approach**:

**Unit/Service Tests → Swift Testing Framework ⭐ REQUIRED**
- Modern `@Test("Display Name")` syntax with custom names
- Tests appear with readable names in test navigator
- Use `#expect` for assertions
- Best for service layer, business logic, data models

**UI Tests → XCTest Framework**
- Traditional `XCTestCase` with `XCUIApplication`
- Descriptive function names (e.g., `testLoginView_DisplaysCorrectly()`)
- Use `XCTAssert` for assertions
- Required for UI automation and app lifecycle

### Test Types Required

**1. Unit Tests (Swift Testing)** — Mandatory for all features
- Path: `PsstTests/{Feature}Tests.swift`
- Framework: Swift Testing
- Pattern: `@Test("Display Name")` with `#expect`
- Tests: Service method behavior, validation, Firebase operations
- Example: `PsstTests/AuthenticationServiceTests.swift`

**2. UI Tests (XCTest)** — Mandatory for user-facing features
- Path: `PsstUITests/{Feature}UITests.swift`
- Framework: XCTest
- Pattern: `class XCTestCase` with `func test...()`
- Tests: User interactions, navigation, state changes
- Example: `PsstUITests/AuthenticationUITests.swift`

**3. Service Tests (Swift Testing)** — If you created/modified service methods
- Path: `PsstTests/Services/{ServiceName}Tests.swift`
- Framework: Swift Testing
- Pattern: `@Test("Display Name")` with `#expect`
- Tests: Firebase interactions, async operations, error handling

### Test Coverage Requirements
- ✅ Happy path scenarios
- ✅ Edge cases (empty input, offline, errors)
- ✅ Multi-user scenarios
- ✅ Performance targets
- ✅ Real-time sync (<100ms)
- ✅ Offline persistence

### Multi-Device Testing Pattern (Swift Testing)
```swift
// Automated test simulating multiple devices
@Test("Message Sync Across Devices Completes Within 100ms")
func messageSyncAcrossDevicesCompletesWithin100ms() async throws {
    // Given: Two devices
    let device1Service = MessageService()
    let device2Service = MessageService()
    
    // When: Device 1 sends message
    let messageID = try await device1Service.sendMessage(
        chatID: "test-chat",
        text: "Hello from device 1"
    )
    
    // Wait for Firebase sync (should be <100ms)
    try await Task.sleep(nanoseconds: 100_000_000) // 100ms
    
    // Then: Device 2 receives the message
    let messages = try await device2Service.fetchMessages(chatID: "test-chat")
    #expect(messages.contains { $0.id == messageID })
}
```

---

## Data Model Examples

### Message Document
```swift
{
  id: String,
  text: String,
  senderID: String,
  timestamp: Timestamp,  // FieldValue.serverTimestamp()
  readBy: [String]  // Array of user IDs
}
```

### Chat Document
```swift
{
  id: String,
  members: [String],  // Array of user IDs
  lastMessage: String,
  lastMessageTimestamp: Timestamp,
  isGroupChat: Bool
}
```

---

## Service Contract Examples

```swift
// Message operations
func sendMessage(chatID: String, text: String) async throws -> String
func observeMessages(chatID: String, completion: @escaping ([Message]) -> Void) -> ListenerRegistration
func markMessageAsRead(messageID: String, userID: String) async throws

// Chat operations
func createChat(members: [String], isGroup: Bool) async throws -> String
```

---

## Git Branch Strategy

**Base Branch**: Always branch from `develop`  
**Branch Naming**: `feat/pr-{number}-{feature-name}`  
**PR Target**: Always target `develop`, NEVER `main`

Example:
```bash
git checkout develop
git pull origin develop
git checkout -b feat/pr-1-message-send
```

---

## Success Metrics Template

- **User-visible**: Time to complete task, number of taps, flow completion
- **System**: Message delivery latency, app load time, scrolling fps
- **Quality**: 0 blocking bugs, all acceptance gates pass, crash-free rate >99%

---

## Common Issues & Solutions

### Issue: Changes don't sync to Firebase
**Solution:** Call service methods, not just local state updates
```swift
// ❌ Wrong - only updates local state
messages.append(newMessage)

// ✅ Correct - saves to Firebase AND updates local state
Task {
    try await messageService.sendMessage(chatID: chatID, text: text)
}
```

### Issue: Performance slow with many messages
**Solution:** Use LazyVStack
```swift
ScrollView {
    LazyVStack {
        ForEach(messages) { message in
            MessageRow(message: message)
        }
    }
}
```

### Issue: Tests failing
**Check:**
1. Async operations properly awaited
2. Firebase emulator running
3. State updated before assertion
4. No race conditions in concurrent tests

### Issue: Real-time sync slow
**Solution:**
1. Optimize Firebase queries with indexes
2. Use Firebase batch writes
3. Ensure Firestore persistence enabled

