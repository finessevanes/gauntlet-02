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

**Philosophy:** User-centric manual validation. Each PR tests **3 scenarios:**

1. **Happy Path** - Main user flow works end-to-end
2. **Edge Cases** - 1-2 non-standard inputs handled gracefully
3. **Error Handling** - Offline/timeout/invalid input show clear messages

**📋 For detailed testing strategy and examples, see [Testing Strategy](../docs/testing-strategy.md)**

---

### Manual Testing Checklist

**Before marking feature complete, verify:**

- [ ] **Happy Path**: Main user flow works from start to finish without errors
- [ ] **Edge Case 1**: [Document specific scenario] handled gracefully
- [ ] **Edge Case 2**: [Document specific scenario] handled gracefully (optional but recommended)
- [ ] **Error Handling**: 
  - Offline mode shows clear message (test: enable airplane mode)
  - Invalid input shows validation error (test: empty/malformed data)
  - Timeout shows retry option (test: slow network, if applicable)
- [ ] **No Console Errors**: Clean console output during all test scenarios
- [ ] **Performance Check**: Feature feels responsive (subjective, no noticeable lag)

---

### Optional: Multi-Device Testing

**Only required for real-time sync features** (messaging, presence, typing indicators):

1. Open app on Device 1 (iPhone or Simulator)
2. Open app on Device 2 (different device)
3. Perform action on Device 1 (send message, update status)
4. Verify sync on Device 2 within ~500ms
5. Repeat in reverse (Device 2 → Device 1)

**Pass Criteria:** Sync happens quickly, no data loss

---

### Testing Examples by Feature Type

**Messaging Features:**
- Happy Path: Open chat → Type → Send → Message appears
- Edge Case 1: Send empty message → Shows "Message cannot be empty"
- Edge Case 2: Send 1000-character message → Handles without crash
- Error: Airplane mode → Message queues, shows "Sending..." then sends on reconnect

**Profile Features:**
- Happy Path: Tap Edit → Change name → Save → Name updates
- Edge Case 1: Save without changes → No API call, shows success
- Edge Case 2: Invalid email format → Shows validation error inline
- Error: Offline → Shows "Can't update profile offline, try again later"

**List Features:**
- Happy Path: Open list → See items → Tap item → Detail loads
- Edge Case 1: Empty list → Shows "No items yet" empty state
- Edge Case 2: Search no results → Shows "No matches found"
- Error: Load fails → Shows "Couldn't load items" with retry button

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

