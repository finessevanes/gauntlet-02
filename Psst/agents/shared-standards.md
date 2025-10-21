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

### Current Testing Approach

This project uses **manual testing validation** to ensure features work correctly before deployment.

**📋 For comprehensive testing strategy and future automated testing recommendations, see [Testing Strategy & Recommendations](../docs/testing-strategy.md)**

### Manual Testing Requirements

**For each feature, the user must verify:**

**1. Configuration Testing**
- Firebase Authentication setup works
- Firestore database connection established
- FCM push notifications configured
- All environment variables and API keys properly set

**2. User Flow Testing**
- Happy path: Complete the main user journey end-to-end
- Edge cases: Test with invalid inputs, empty states, network issues
- Multi-user scenarios: Test real-time sync across 2+ devices
- Offline behavior: Test app functionality without internet connection

**3. Performance Validation**
- App loads in < 2-3 seconds (cold start to interactive UI)
- Messages sync across devices in < 100ms
- Smooth 60fps scrolling with 100+ messages
- No UI blocking or freezing during operations

**4. Visual State Verification**
- Empty states display correctly
- Loading states show appropriate indicators
- Error states provide clear feedback
- Success states confirm completed actions

### Manual Testing Checklist Template

**Before marking feature complete, verify:**

- [ ] **Configuration**: All Firebase services connected and working
- [ ] **Happy Path**: Main user flow works from start to finish
- [ ] **Edge Cases**: Invalid inputs handled gracefully
- [ ] **Multi-Device**: Real-time sync works across 2+ devices
- [ ] **Offline**: App functions properly without internet
- [ ] **Performance**: App loads quickly, smooth scrolling, fast sync
- [ ] **Visual States**: All UI states (empty, loading, error, success) display correctly
- [ ] **No Console Errors**: Clean console output during testing

### Multi-Device Testing Instructions

**To test real-time sync:**
1. Open app on Device 1 (iPhone/Simulator)
2. Open app on Device 2 (different iPhone/Simulator)
3. Send message from Device 1
4. Verify message appears on Device 2 within 100ms
5. Send message from Device 2
6. Verify message appears on Device 1 within 100ms
7. Test with 3+ devices if available

**To test offline behavior:**
1. Disable internet connection
2. Attempt to send messages (should queue locally)
3. Re-enable internet connection
4. Verify queued messages send automatically
5. Verify real-time sync resumes

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

