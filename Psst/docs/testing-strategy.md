# Testing Strategy

**Last Updated**: October 23, 2025

**Philosophy:** User-centric manual validation for speed and quality. Ship features fast with pragmatic testing.

---

## Current Approach: Manual Flow Testing

Each PR ends with testing **3 critical scenarios:**

### 1. Happy Path (Required)
**What:** Main user flow from start to finish  
**Why:** Validates the feature works as intended for the primary use case

**Example (Message Send):**
1. User opens chat
2. Types message "Hello World"
3. Taps send button
4. Message appears in chat bubble
5. Other device receives message (if real-time feature)

**Pass Criteria:** 
- Flow completes without errors
- User sees expected outcome
- No console errors or warnings

---

### 2. Edge Cases (1-2 Required)
**What:** Non-standard inputs or conditions  
**Why:** Ensures feature degrades gracefully under unusual circumstances

**Common Edge Cases to Test:**
- **Empty input:** Send blank message → Shows "Message cannot be empty"
- **Long input:** 500+ character message → Handles without crash
- **Special characters:** Emojis, symbols, Unicode → Displays correctly
- **Rapid actions:** Spam send button 10x → Queues properly, no duplicates
- **Concurrent users:** 2 users act simultaneously → Both actions succeed
- **Boundary conditions:** Max group size, character limits → Enforced gracefully

**Pass Criteria:** 
- App doesn't crash
- Shows appropriate feedback to user
- Data remains consistent

---

### 3. Error Handling (Required)
**What:** How the feature behaves when things fail  
**Why:** Users must understand what went wrong and how to recover

**Common Error Scenarios:**

**Offline Mode:**
- Enable airplane mode
- Attempt action (send message, update profile)
- **Expected:** "No internet connection" message, action queues for retry

**Network Timeout:**
- Simulate slow network (or wait for natural timeout)
- **Expected:** Loading state → "Taking longer than expected" → retry option

**Invalid Data:**
- Submit empty required field
- Enter malformed email/phone
- **Expected:** Validation error inline, clear instruction to fix

**Permission Denied:**
- Attempt action user doesn't have rights for
- **Expected:** "You don't have permission to do this" message

**Pass Criteria:** 
- Clear, actionable error message shown
- User can retry or take alternative action
- No data corruption or partial writes
- App remains functional after error

---

## Testing Checklist (Copy to Each TODO)

**Before marking PR complete:**

- [ ] **Happy Path:** Main user flow works end-to-end without errors
- [ ] **Edge Case 1:** [Document specific scenario] handled gracefully
- [ ] **Edge Case 2:** [Document specific scenario] handled gracefully (optional but recommended)
- [ ] **Error Handling:** 
  - Offline mode shows clear message (test: airplane mode)
  - Invalid input shows validation error
  - Timeout shows retry option (if long-running operation)
- [ ] **No Console Errors:** Clean console during all test scenarios
- [ ] **Performance Check:** Feature feels responsive (subjective, no noticeable lag)

---

## Optional Testing (When Applicable)

### Multi-Device Testing
**When Required:** Real-time sync features (messaging, presence, typing indicators, read receipts)

**How to Test:**
1. Open app on Device 1 (iPhone or Simulator)
2. Open app on Device 2 (different device)
3. Perform action on Device 1 (send message, update status)
4. **Verify:** Change appears on Device 2 within ~500ms
5. Repeat in reverse (Device 2 → Device 1)

**Pass Criteria:** Sync happens quickly, no data loss

---

### Performance Testing
**When Required:** Lists with 50+ items, heavy animations, image loading

**How to Test:**
- **Scrolling:** Scroll through long list, verify smooth 60fps (no jank)
- **Loading:** Measure time from tap to screen display
- **Memory:** Check for leaks with large datasets

**Pass Criteria:** 
- Smooth scrolling (subjective)
- Fast load times (< 2-3 seconds)
- No memory warnings

---

## Testing Examples by Feature Type

### Messaging Features
**Happy Path:** Open chat → Type → Send → Message appears  
**Edge Case 1:** Send empty message → Blocked with error  
**Edge Case 2:** Send 1000-char message → Accepted or truncated with warning  
**Error:** Airplane mode → Queues message, sends on reconnect

---

### Profile Features
**Happy Path:** Tap Edit → Change name → Save → Name updates  
**Edge Case 1:** Save without changes → No API call, instant success  
**Edge Case 2:** Invalid email format → Validation error inline  
**Error:** Offline → "Can't update profile offline"

---

### List/Search Features
**Happy Path:** Open list → See items → Tap item → Detail loads  
**Edge Case 1:** Empty list → "No items yet" empty state  
**Edge Case 2:** Search no results → "No matches found"  
**Error:** Load fails → "Couldn't load items" with retry button

---

## Future: Automated Testing (Phase 6+)

**When to Add:** After MVP ships and revenue validates product direction

**Priorities:**
1. **Unit Tests:** Service layer business logic (high ROI)
2. **Integration Tests:** Critical user flows (signup, send message)
3. **UI Tests:** Smoke tests for major screens

**See below for AI feature integration test templates when Phase 6 begins.**

### 1. Unit Testing Framework

**Recommended Framework**: Swift Testing (Modern)
- **Path**: `PsstTests/{Feature}Tests.swift`
- **Syntax**: `@Test("Display Name")` with `#expect`
- **Benefits**: Readable test names, modern async/await support

**What to Test:**
- Service layer business logic
- Data model validation
- Error handling and edge cases
- Firebase operations (with emulator)
- Authentication flows
- Message processing logic

**Example Structure:**
```swift
import Testing
@testable import Psst

@Suite("Message Service Tests")
struct MessageServiceTests {
    
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
    }
}
```

### 2. Integration Testing

**Recommended Framework**: XCTest + Firebase Emulator
- **Path**: `PsstTests/Integration/{Feature}IntegrationTests.swift`
- **Purpose**: Test Firebase integrations, multi-service workflows
- **Setup**: Firebase emulator suite for isolated testing

**What to Test:**
- Auth + Firestore integration flows
- End-to-end user journeys
- Multi-device sync scenarios
- Offline/online state transitions
- Security rules validation
- Performance benchmarks

**Example Structure:**
```swift
import XCTest
@testable import Psst

class AuthFirestoreIntegrationTests: XCTestCase {
    
    func testSignupCreatesBothAuthAndFirestoreUser() async throws {
        // Given: Clean state
        // When: User signs up
        // Then: Both Firebase Auth and Firestore user created
        // And: UIDs match between services
    }
}
```

### 3. UI Testing

**Recommended Framework**: XCTest (XCUITest)
- **Path**: `PsstUITests/{Feature}UITests.swift`
- **Purpose**: Automated user interaction testing
- **Benefits**: Full app lifecycle testing, accessibility validation

**What to Test:**
- Complete user flows (login → chat → logout)
- Navigation between screens
- Form interactions and validation
- Accessibility compliance
- Visual regression (screenshots)
- Performance under load

**Example Structure:**
```swift
import XCTest

class ChatFlowUITests: XCTestCase {
    var app: XCUIApplication!
    
    func testCompleteChatFlow() throws {
        // Login
        app.buttons["loginButton"].tap()
        app.textFields["emailField"].typeText("test@example.com")
        app.secureTextFields["passwordField"].typeText("password")
        app.buttons["submitButton"].tap()
        
        // Send message
        app.textFields["messageInput"].typeText("Hello World")
        app.buttons["sendButton"].tap()
        
        // Verify message appears
        XCTAssertTrue(app.staticTexts["Hello World"].exists)
    }
}
```

### 4. Multi-Device Testing

**Recommended Approach**: Firebase Test Lab + Custom Framework
- **Purpose**: Test real-time sync across multiple devices
- **Setup**: Automated device orchestration
- **Coverage**: 2-5 devices, different OS versions

**What to Test:**
- Real-time message sync (< 100ms)
- Concurrent user actions
- Offline queue synchronization
- Presence indicators
- Conflict resolution

### 5. Performance Testing

**Recommended Tools**: XCTest + Instruments
- **Purpose**: Validate performance targets
- **Metrics**: Load times, memory usage, CPU usage, network efficiency

**What to Test:**
- App launch time (< 2-3 seconds)
- Message delivery latency (< 100ms)
- Scrolling performance (60fps with 100+ messages)
- Memory usage under load
- Battery efficiency
- Network optimization

---

## Testing Implementation Roadmap

### Phase 1: Foundation (Current)
- ✅ Manual testing validation
- ✅ Performance monitoring
- ✅ Multi-device manual testing

### Phase 2: Unit Testing (PR #15-20)
- [ ] Service layer unit tests
- [ ] Data model validation tests
- [ ] Error handling tests
- [ ] Firebase emulator setup

### Phase 3: Integration Testing (PR #21-24)
- [ ] Auth + Firestore integration tests
- [ ] End-to-end user flow tests
- [ ] Multi-device sync tests
- [ ] Security rules validation

### Phase 4: Comprehensive Testing (PR #25)
- [ ] Full UI test suite
- [ ] Performance benchmarking
- [ ] Accessibility testing
- [ ] Visual regression testing
- [ ] Load testing

---

## Testing Best Practices

### Test Organization
```
PsstTests/
├── Unit/
│   ├── Services/
│   ├── Models/
│   └── Utils/
├── Integration/
│   ├── Auth/
│   ├── Firestore/
│   └── MultiDevice/
└── Performance/

PsstUITests/
├── Flows/
├── Components/
└── Accessibility/
```

### Test Data Management
- Use Firebase emulator for isolated testing
- Implement test data factories
- Clean up test data after each test
- Use unique identifiers to avoid conflicts

### Continuous Integration
- Run unit tests on every commit
- Run integration tests on pull requests
- Run full test suite before deployment
- Performance regression detection

### Coverage Targets
- **Unit Tests**: 80%+ code coverage
- **Integration Tests**: 100% critical user flows
- **UI Tests**: 100% main user journeys
- **Performance Tests**: All performance targets validated

---

## Testing Tools & Setup

### Required Tools
- **Xcode**: Native testing frameworks
- **Firebase Emulator**: Local Firebase testing
- **Firebase Test Lab**: Multi-device testing
- **Instruments**: Performance profiling
- **Accessibility Inspector**: Accessibility testing

### Test Environment Setup
```bash
# Install Firebase emulator
npm install -g firebase-tools
firebase init emulators

# Configure emulators
firebase emulators:start --only firestore,auth
```

### CI/CD Integration
- GitHub Actions for automated testing
- Firebase Test Lab integration
- Performance regression detection
- Automated deployment gates

---

## Testing Metrics & Success Criteria

### Quality Gates
- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] All UI tests pass
- [ ] Performance targets met
- [ ] No critical bugs in production
- [ ] 99%+ uptime

### Performance Targets
- App launch: < 2-3 seconds
- Message delivery: < 100ms
- UI responsiveness: < 50ms
- Memory usage: < 100MB baseline
- Battery efficiency: < 5% per hour

### Coverage Requirements
- Unit test coverage: 80%+
- Integration test coverage: 100% critical paths
- UI test coverage: 100% main flows
- Performance test coverage: All targets validated

---

## Migration Strategy

### From Manual to Automated Testing

**Phase 1**: Continue manual testing, document patterns
**Phase 2**: Implement unit tests for new features
**Phase 3**: Add integration tests for critical flows
**Phase 4**: Full automated test suite

**Key Principles:**
- Don't break existing manual testing
- Add automated tests incrementally
- Maintain test quality over quantity
- Focus on high-value test cases first

---

## Resources & References

### Documentation
- [Swift Testing Framework](https://developer.apple.com/documentation/testing)
- [XCTest Framework](https://developer.apple.com/documentation/xctest)
- [Firebase Emulator Suite](https://firebase.google.com/docs/emulator-suite)
- [Firebase Test Lab](https://firebase.google.com/docs/test-lab)

### Testing Patterns
- See `Psst/agents/shared-standards.md` for current manual testing standards
- See `Psst/agents/test-template.md` for testing guidelines
- See `Psst/docs/backlog.md` for deferred testing items

### Community Resources
- iOS Testing Best Practices
- Firebase Testing Patterns
- SwiftUI Testing Strategies
- Performance Testing Guidelines

---

---

## AI Feature Integration Tests (Phase 6+)

When AI features are implemented, use these happy path demos as integration test templates.

### Happy Path 1: YOLO Mode Lead Qualification
**Tests:** User Preferences, Function Calling, Memory/State, Error Handling

**Setup:**
- Coach has YOLO mode enabled 8pm-7am
- Preferences stored: rates=$150/hr, friendly tone

**Flow:**
1. New lead DMs at 11pm: "What are your rates?"
2. **VERIFY:** AI responds within 5 seconds with correct rates
3. Lead: "What's your availability?"
4. **VERIFY:** AI checks calendar, suggests 3 available slots
5. Lead picks: "2pm tomorrow works"
6. **VERIFY:** Calendar event created in Firestore
7. **VERIFY:** Coach sees notification next morning

**Expected Result:** Lead qualified and booked without coach intervention

**Success Criteria:**
- AI response time < 5 seconds
- Rates match User Preferences exactly
- Calendar event persisted correctly in Firestore
- Multi-turn conversation state maintained across messages
- Coach notification triggered and delivered

---

### Happy Path 2: Second Brain Context Recall
**Tests:** RAG Pipeline, Memory/State, Function Calling, User Preferences

**Setup:**
- Existing conversation history for client Mike
- Mike previously mentioned: "I travel to Dallas monthly"
- Vector embeddings generated for all past messages

**Flow:**
1. Mike messages: "Traveling to Dallas next week, hotel gym only"
2. Coach asks AI: "What did Mike say about travel before?"
3. **VERIFY:** RAG searches conversations, returns relevant messages
4. **VERIFY:** AI surfaces: "Mike mentioned Dallas 3 weeks ago, liked DB workouts"
5. **VERIFY:** AI drafts suggested workout message
6. Coach reviews, optionally edits
7. Coach sends (or AI sends if approved as-is)
8. Mike replies: "Perfect! You remembered 🙌"

**Expected Result:** Semantic search finds relevant context, AI personalizes response

**Success Criteria:**
- Semantic search returns messages about "travel" and "Dallas"
- Similarity score > 0.7 for relevant messages
- AI draft includes personalized details from past conversations
- Coach maintains control (can edit before sending)
- Client feels remembered and valued

---

## Notes

- **Current Priority**: Manual testing validation for feature delivery
- **Future Priority**: Comprehensive automated testing for production readiness
- **Testing Philosophy**: Quality over speed, but speed enables quality
- **Human Validation**: Always required for UX/UI, even with automated tests
