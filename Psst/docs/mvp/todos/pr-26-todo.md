# PR-26 TODO — MessageInputView Refactor and Enhancements

**Branch**: `feat/pr-26-message-input-refactor`  
**Source PRD**: `Psst/docs/prds/pr-26-prd.md` (to be created)  
**Owner (Agent)**: Caleb

---

## 0. Clarifying Questions & Assumptions

- Questions: None - Requirements clear from code review
- Assumptions:
  - Enter key should send message (standard messaging behavior)
  - Keyboard should dismiss after sending (optional, configurable)
  - Haptic feedback on send improves UX
  - Task cleanup prevents memory leaks
  - Accessibility support is required for VoiceOver users
  - No breaking changes to existing MessageInputView API

---

## 1. Setup

- [x] Create branch `feat/pr-26-message-input-refactor` from develop
- [x] Read `Psst/agents/shared-standards.md` for patterns
- [x] Review current MessageInputView implementation at `Psst/Psst/Views/ChatList/MessageInputView.swift`
- [x] Confirm environment and test runner work
- [x] Review Swift threading rules for async operations

---

## 2. Add Enter Key Submission Support

Implement keyboard return key handling to send messages.

### 2.1: Add Submit Label

- [x] Open `Psst/Psst/Views/ChatList/MessageInputView.swift`
  - Test Gate: File opens successfully

- [x] Add `.submitLabel(.send)` modifier to TextField (line 44)
  ```swift
  TextField("Message...", text: $text, axis: .vertical)
      .textFieldStyle(.roundedBorder)
      .lineLimit(1...5)
      .submitLabel(.send)  // ← Add this line
      .padding(.leading, 4)
  ```
  - Test Gate: Code compiles without errors
  - Test Gate: On-screen keyboard shows "Send" instead of "return"

### 2.2: Add onSubmit Handler

- [x] Add `.onSubmit` modifier after `.submitLabel(.send)`
  ```swift
  .onSubmit {
      if isSendEnabled {
          handleSendButton()
      }
  }
  ```
  - Test Gate: Code compiles without errors
  - Test Gate: Handler only triggers when text is not empty

- [ ] Test in simulator
  - Test Gate: Pressing Enter on hardware keyboard sends message
  - Test Gate: Tapping "Send" on on-screen keyboard sends message
  - Test Gate: Submit is disabled when text field is empty

---

## 3. Add Focus State Management

Implement focus control to dismiss keyboard after sending.

### 3.1: Add FocusState Property

- [x] Add `@FocusState` property at top of MessageInputView struct
  ```swift
  @FocusState private var isTextFieldFocused: Bool
  ```
  - Test Gate: Code compiles without errors

### 3.2: Connect Focus to TextField

- [x] Add `.focused($isTextFieldFocused)` modifier to TextField
  ```swift
  TextField("Message...", text: $text, axis: .vertical)
      .textFieldStyle(.roundedBorder)
      .lineLimit(1...5)
      .submitLabel(.send)
      .focused($isTextFieldFocused)  // ← Add this
      .onSubmit { ... }
  ```
  - Test Gate: Code compiles without errors

### 3.3: Update handleSendButton to Dismiss Keyboard

- [x] Modify `handleSendButton()` to set focus to false
  ```swift
  private func handleSendButton() {
      // Clear typing status immediately before sending
      Task {
          try? await typingIndicatorService.stopTyping(chatID: chatID, userID: userID)
      }
      
      // Call original send handler
      onSend()
      
      // Dismiss keyboard after sending
      isTextFieldFocused = false  // ← Add this
  }
  ```
  - Test Gate: Code compiles without errors
  - Test Gate: Keyboard dismisses after sending message
  - Test Gate: User can tap field to bring keyboard back

---

## 4. Add Accessibility Support

Implement VoiceOver labels and hints.

### 4.1: Add TextField Accessibility

- [x] Add accessibility modifiers to TextField
  ```swift
  TextField("Message...", text: $text, axis: .vertical)
      .textFieldStyle(.roundedBorder)
      .lineLimit(1...5)
      .submitLabel(.send)
      .focused($isTextFieldFocused)
      .onSubmit { ... }
      .accessibilityLabel("Message input field")
      .accessibilityHint("Type your message here, then press send")
      .padding(.leading, 4)
  ```
  - Test Gate: Code compiles without errors

### 4.2: Add Send Button Accessibility

- [x] Add accessibility modifiers to send button
  ```swift
  Button(action: { ... }) {
      Image(systemName: "paperplane.fill")
          .font(.system(size: 20))
          .foregroundColor(isSendEnabled ? .blue : .gray)
          .frame(width: 36, height: 36)
  }
  .accessibilityLabel("Send message")
  .accessibilityHint(isSendEnabled ? "Send your message" : "Enter text to enable sending")
  .disabled(!isSendEnabled)
  ```
  - Test Gate: Code compiles without errors

- [ ] Test with VoiceOver in simulator
  - Test Gate: VoiceOver reads "Message input field"
  - Test Gate: VoiceOver provides helpful hints
  - Test Gate: Send button state is announced correctly

---

## 5. Add Task Lifecycle Management

Prevent memory leaks by managing async task lifecycle.

### 5.1: Add Task State Property

- [x] Add `@State` property for tracking typing task
  ```swift
  @State private var typingTask: Task<Void, Never>?
  ```
  - Test Gate: Code compiles without errors

### 5.2: Refactor handleTextChange with Task Management

- [x] Update `handleTextChange()` method
  ```swift
  private func handleTextChange(_ newText: String) {
      // Cancel previous task to prevent multiple simultaneous requests
      typingTask?.cancel()
      
      let trimmed = newText.trimmingCharacters(in: .whitespacesAndNewlines)
      
      typingTask = Task {
          do {
              if trimmed.isEmpty {
                  try await typingIndicatorService.stopTyping(chatID: chatID, userID: userID)
              } else {
                  try await typingIndicatorService.startTyping(chatID: chatID, userID: userID)
              }
          } catch {
              guard !Task.isCancelled else { return }
              print("[MessageInputView] Error updating typing status: \(error.localizedDescription)")
          }
      }
  }
  ```
  - Test Gate: Code compiles without errors
  - Test Gate: Previous tasks are cancelled when new ones start
  - Test Gate: No errors logged for cancelled tasks

---

## 6. Add Cleanup on View Disappear

Clear typing status and cancel tasks when view disappears.

### 6.1: Add onDisappear Modifier

- [x] Add `.onDisappear` to the body's HStack
  ```swift
  var body: some View {
      HStack(spacing: 12) {
          // ... existing content
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .background(Color(.systemBackground))
      .onDisappear {
          // Cancel any pending typing tasks
          typingTask?.cancel()
          
          // Clear typing status when view disappears
          Task {
              try? await typingIndicatorService.stopTyping(chatID: chatID, userID: userID)
          }
      }
  }
  ```
  - Test Gate: Code compiles without errors
  - Test Gate: Typing status clears when navigating away
  - Test Gate: Tasks are cancelled on view disappear

---

## 7. Add Haptic Feedback

Provide tactile feedback when sending messages.

### 7.1: Add Haptic Generator Import

- [x] Verify UIKit is imported (should already be available in SwiftUI)
  - Test Gate: UIImpactFeedbackGenerator is accessible

### 7.2: Add Haptic to handleSendButton

- [x] Update `handleSendButton()` to include haptic feedback
  ```swift
  private func handleSendButton() {
      // Add haptic feedback for better UX
      let generator = UIImpactFeedbackGenerator(style: .light)
      generator.impactOccurred()
      
      // Clear typing status immediately before sending
      Task {
          try? await typingIndicatorService.stopTyping(chatID: chatID, userID: userID)
      }
      
      // Call original send handler
      onSend()
      
      // Dismiss keyboard after sending
      isTextFieldFocused = false
  }
  ```
  - Test Gate: Code compiles without errors
  - Test Gate: Haptic feedback occurs when sending (test on real device)

---

## 8. Extract Magic Numbers to Constants

Improve code maintainability by using named constants.

### 8.1: Add Constants Enum

- [x] Add Constants enum before the body property
  ```swift
  struct MessageInputView: View {
      // MARK: - Constants
      
      private enum Constants {
          static let horizontalPadding: CGFloat = 12
          static let verticalPadding: CGFloat = 8
          static let interItemSpacing: CGFloat = 12
          static let leadingPadding: CGFloat = 4
          static let trailingPadding: CGFloat = 4
          static let sendIconSize: CGFloat = 20
          static let sendButtonSize: CGFloat = 36
          static let minLineLimit = 1
          static let maxLineLimit = 5
      }
      
      // MARK: - Properties
      // ... existing properties
  }
  ```
  - Test Gate: Code compiles without errors

### 8.2: Replace Magic Numbers with Constants

- [x] Update HStack spacing
  ```swift
  HStack(spacing: Constants.interItemSpacing) {
  ```
  - Test Gate: Code compiles

- [x] Update TextField lineLimit
  ```swift
  .lineLimit(Constants.minLineLimit...Constants.maxLineLimit)
  ```
  - Test Gate: Code compiles

- [x] Update padding values
  ```swift
  .padding(.leading, Constants.leadingPadding)
  // ...
  .padding(.trailing, Constants.trailingPadding)
  // ...
  .padding(.horizontal, Constants.horizontalPadding)
  .padding(.vertical, Constants.verticalPadding)
  ```
  - Test Gate: Code compiles

- [x] Update button icon size and frame
  ```swift
  .font(.system(size: Constants.sendIconSize))
  .frame(width: Constants.sendButtonSize, height: Constants.sendButtonSize)
  ```
  - Test Gate: Code compiles
  - Test Gate: UI appears identical to before refactor

---

## 9. Improve Error Handling

Add optional error callback for parent views.

### 9.1: Add Error Callback Property

- [x] Add optional error handler property
  ```swift
  /// Optional callback for handling typing service errors
  let onError: ((Error) -> Void)?
  ```
  - Test Gate: Code compiles without errors

### 9.2: Update Error Handling in handleTextChange

- [x] Call onError callback when errors occur
  ```swift
  } catch {
      guard !Task.isCancelled else { return }
      print("[MessageInputView] Error updating typing status: \(error.localizedDescription)")
      onError?(error)  // ← Add this
  }
  ```
  - Test Gate: Code compiles without errors
  - Test Gate: Error callback is optional (no breaking changes)

---

## 10. Update Preview Providers

Improve previews with proper mock services.

### 10.1: Create Mock Typing Indicator Service

- [x] Add mock class before previews
  ```swift
  // MARK: - Mock Services for Previews

  private class MockTypingIndicatorService: TypingIndicatorService {
      override func startTyping(chatID: String, userID: String) async throws {
          print("Mock: Start typing in chat \(chatID)")
      }
      
      override func stopTyping(chatID: String, userID: String) async throws {
          print("Mock: Stop typing in chat \(chatID)")
      }
  }
  ```
  - Test Gate: Code compiles without errors

### 10.2: Update All Previews

- [x] Update all three preview providers to use mock service
  ```swift
  #Preview("Empty Input") {
      VStack {
          Spacer()
          MessageInputView(
              text: .constant(""),
              onSend: { print("Send tapped") },
              chatID: "preview_chat",
              userID: "preview_user",
              typingIndicatorService: MockTypingIndicatorService(),
              onError: { error in print("Error: \(error)") }
          )
          .background(Color(.systemGray6))
      }
  }
  ```
  - Test Gate: All three previews compile and render
  - Test Gate: Mock services print to console during preview interaction
  - Test Gate: No Firebase connection required for previews

---

## 11. Keyboard Testing - Simulator

Comprehensive keyboard testing in iOS Simulator.

### 11.1: Hardware Keyboard Testing (Command+K)

- [ ] Launch app in simulator
  - Test Gate: App runs without crashes

- [ ] Enable hardware keyboard (Command+K or I/O > Keyboard > Connect Hardware Keyboard)
  - Test Gate: Hardware keyboard enabled (checkmark visible in menu)

- [ ] Open chat view and focus message input field
  - Test Gate: Input field accepts focus

- [ ] Type message using hardware keyboard
  - Test Gate: Text appears in input field
  - Test Gate: Typing indicator shows for other user

- [ ] Press Enter key with text in field
  - Test Gate: Message sends successfully
  - Test Gate: Input field clears after send
  - Test Gate: Keyboard focus remains (or dismisses based on implementation)
  - Test Gate: No duplicate sends

- [ ] Press Enter key with empty field
  - Test Gate: Nothing happens (submit disabled)
  - Test Gate: No error messages

- [ ] Type multi-line message using Option+Return
  - Test Gate: New line inserted (if supported)
  - Test Gate: Message doesn't send on Option+Return

### 11.2: On-Screen Keyboard Testing

- [ ] Disable hardware keyboard (Command+K)
  - Test Gate: On-screen keyboard appears when tapping input field

- [ ] Tap message input field
  - Test Gate: On-screen keyboard slides up
  - Test Gate: View scrolls to keep input visible

- [ ] Check return key label
  - Test Gate: Return key shows "Send" label (not "return")

- [ ] Type message and tap "Send" key on keyboard
  - Test Gate: Message sends successfully
  - Test Gate: Keyboard dismisses after send
  - Test Gate: Input field clears

- [ ] Tap "Send" key with empty field
  - Test Gate: Key is disabled or does nothing
  - Test Gate: No crash or error

### 11.3: Focus State Testing

- [ ] Send a message using Enter key
  - Test Gate: Keyboard dismisses automatically

- [ ] Tap input field again
  - Test Gate: Keyboard reappears
  - Test Gate: Can type new message

- [ ] Tap outside input field
  - Test Gate: Keyboard dismisses
  - Test Gate: Message draft preserved

### 11.4: Submit Label Verification

- [ ] With on-screen keyboard visible, observe return key
  - Test Gate: Key shows "Send" icon or text
  - Test Gate: Key matches iOS Messages app style

- [ ] Type text and watch send button
  - Test Gate: Send button enables when text present
  - Test Gate: Send button disables when text cleared

---

## 12. Keyboard Testing - Real Phone

Physical device testing to validate real-world behavior.

### 12.1: External Bluetooth Keyboard Testing

- [x] Connect Bluetooth keyboard to iPhone/iPad
  - Test Gate: Keyboard pairs successfully

- [x] Open app and navigate to chat
  - Test Gate: App works normally with external keyboard

- [x] Type message using Bluetooth keyboard
  - Test Gate: Text appears correctly
  - Test Gate: No input lag

- [x] Press Enter/Return key on Bluetooth keyboard
  - Test Gate: Message sends
  - Test Gate: Haptic feedback occurs (if device supports)
  - Test Gate: Input field clears

- [x] Press Enter with empty field
  - Test Gate: Nothing happens
  - Test Gate: No error or crash

- [ ] Test keyboard shortcuts (if implemented)
  - Test Gate: Command+V pastes (standard iOS behavior)
  - Test Gate: Other shortcuts work as expected

### 12.2: On-Screen Keyboard - Real Device

- [x] Disconnect external keyboard
  - Test Gate: On-screen keyboard available

- [x] Tap message input field
  - Test Gate: Keyboard appears smoothly
  - Test Gate: No animation glitches

- [x] Verify "Send" label on return key
  - Test Gate: Label clearly visible
  - Test Gate: Label updates immediately when typing starts

- [x] Tap "Send" key on keyboard
  - Test Gate: Message sends
  - Test Gate: Haptic feedback feels appropriate
  - Test Gate: Keyboard dismisses

- [ ] Test with different keyboard heights
  - Enable one-handed keyboard (hold globe icon)
  - Test Gate: Input remains accessible
  - Test Gate: Send button still works

### 12.3: Dictation Testing

- [ ] Tap microphone button on keyboard
  - Test Gate: Dictation activates

- [ ] Speak a message
  - Test Gate: Text appears in input field
  - Test Gate: Typing indicator shows during dictation

- [ ] Tap "Send" key after dictation
  - Test Gate: Message sends correctly
  - Test Gate: Dictated text preserved

- [ ] Try saying "send" or "new line" during dictation
  - Test Gate: Behavior matches iOS standard (doesn't trigger send)

### 12.4: Different Keyboard Languages

- [ ] Switch to non-English keyboard (Settings > General > Keyboard)
  - Test Gate: Can switch keyboards

- [ ] Type message in different language
  - Test Gate: Characters appear correctly
  - Test Gate: Return key still labeled appropriately

- [ ] Send message using return key
  - Test Gate: Message sends regardless of keyboard language
  - Test Gate: No encoding issues

### 12.5: Accessibility Keyboard

- [ ] Enable VoiceOver (Settings > Accessibility > VoiceOver)
  - Test Gate: VoiceOver activates

- [ ] Navigate to message input field
  - Test Gate: VoiceOver reads "Message input field"
  - Test Gate: Hint explains how to use

- [ ] Type message with VoiceOver enabled
  - Test Gate: Each character announced
  - Test Gate: Can send message

- [ ] Focus send button
  - Test Gate: VoiceOver reads "Send message"
  - Test Gate: Hint updates based on enabled state

### 12.6: iPad Hardware Keyboard (if available)

- [ ] Test on iPad with Magic Keyboard or Smart Keyboard
  - Test Gate: All keyboard features work on iPad
  - Test Gate: Return key sends message
  - Test Gate: Keyboard shortcuts function properly

---

## 13. Multi-Device Sync Testing

Verify typing indicators and messages sync correctly.

### 13.1: Two Device Testing

- [ ] Open app on Device 1 (simulator or phone)
  - Test Gate: Logged into same chat

- [ ] Open app on Device 2 (different simulator or phone)
  - Test Gate: Logged into same chat

- [ ] Type message on Device 1 using Enter key
  - Test Gate: Message appears on Device 2 within 100ms
  - Test Gate: Typing indicator clears on both devices

- [ ] Verify typing indicator behavior
  - Device 1 types message
  - Test Gate: Device 2 shows typing indicator
  - Device 1 presses Enter
  - Test Gate: Typing indicator clears immediately on both devices

---

## 14. Performance Validation

Ensure refactor doesn't introduce performance regression.

### 14.1: Verify No UI Blocking

- [ ] Type rapidly in message input
  - Test Gate: No keyboard lag
  - Test Gate: Characters appear immediately
  - Test Gate: UI remains responsive

- [ ] Send multiple messages quickly
  - Test Gate: No freezing or stuttering
  - Test Gate: All messages send successfully
  - Test Gate: Keyboard behavior consistent

### 14.2: Memory Leak Verification

- [ ] Open chat, type, and send 20 messages
  - Test Gate: App memory usage stays stable

- [ ] Navigate away and back to chat multiple times
  - Test Gate: No memory increase
  - Test Gate: Tasks properly cancelled

- [ ] Check Xcode Instruments if available
  - Test Gate: No retain cycles
  - Test Gate: Tasks released properly

### 14.3: Typing Indicator Performance

- [ ] Type continuously for 10 seconds
  - Test Gate: Typing indicator updates throttled (not every keystroke)
  - Test Gate: No excessive Firebase calls
  - Test Gate: Task cancellation works correctly

---

## 15. Visual States Verification

Confirm all UI states render correctly.

### 15.1: Empty State

- [ ] View message input with no text
  - Test Gate: Placeholder visible ("Message...")
  - Test Gate: Send button disabled (gray)
  - Test Gate: Return key disabled or does nothing

### 15.2: Typing State

- [ ] Type text in input field
  - Test Gate: Text visible and formatted correctly
  - Test Gate: Send button enabled (blue)
  - Test Gate: Return key shows "Send"
  - Test Gate: Line wrapping works (1-5 lines)

### 15.3: Multi-line State

- [ ] Type long message that wraps
  - Test Gate: TextField expands vertically
  - Test Gate: Maximum 5 lines enforced
  - Test Gate: Scrolling works beyond 5 lines

### 15.4: After Send State

- [ ] Send a message
  - Test Gate: Input field clears immediately
  - Test Gate: Keyboard dismisses (or stays based on focus)
  - Test Gate: Send button returns to disabled state
  - Test Gate: Ready for next message

---

## 16. Edge Cases Testing

Test unusual scenarios and error conditions.

### 16.1: Rapid Submissions

- [ ] Type message and press Enter repeatedly
  - Test Gate: Only one message sends
  - Test Gate: No duplicate sends
  - Test Gate: Input clears once

### 16.2: Whitespace-Only Messages

- [ ] Type only spaces and press Enter
  - Test Gate: Message doesn't send (validation works)
  - Test Gate: Send button disabled
  - Test Gate: No empty message created

### 16.3: Typing Service Errors

- [ ] Simulate Firebase offline
  - Airplane mode or disconnect internet
  - Type message
  - Test Gate: Typing indicator fails gracefully
  - Test Gate: Error logged (optional callback triggered)
  - Test Gate: Can still send message when reconnected

### 16.4: Focus State Edge Cases

- [ ] Send message and immediately start typing
  - Test Gate: Focus behavior predictable
  - Test Gate: No race conditions

- [ ] Switch apps while typing
  - Test Gate: Typing status clears on background
  - Test Gate: Draft preserved
  - Test Gate: Can resume typing on return

---

## 17. Acceptance Gates

Verify all PRD requirements met (when PRD is created).

- [ ] Enter key sends message on hardware keyboard
  - Test Gate: ✓ Verified in simulator and device

- [ ] "Send" label shows on on-screen keyboard
  - Test Gate: ✓ Verified on real device

- [ ] Keyboard dismisses after sending (optional)
  - Test Gate: ✓ Configurable via focus state

- [ ] Accessibility support complete
  - Test Gate: ✓ VoiceOver tested

- [ ] No memory leaks
  - Test Gate: ✓ Tasks cancelled properly

- [ ] No performance regression
  - Test Gate: ✓ Typing smooth, no lag

- [ ] Haptic feedback on send
  - Test Gate: ✓ Tested on real device

- [ ] Code quality improved
  - Test Gate: ✓ Constants, error handling, cleanup

---

## 18. Documentation & PR

### 18.1: Add Code Comments

- [ ] Review MessageInputView
  - Add comments explaining Constants enum
  - Document focus state behavior
  - Explain task cancellation logic
  - Document error callback usage
  - Test Gate: All complex logic commented

### 18.2: Update Comments for New Features

- [ ] Document Enter key behavior
  ```swift
  /// Handles keyboard return key submission
  /// When user presses Enter/Return, message sends if text is valid
  .onSubmit { ... }
  ```
  - Test Gate: Comments clear and helpful

### 18.3: Create PR Description

- [ ] Write comprehensive PR description
  ```markdown
  # PR #26: MessageInputView Refactor and Enhancements
  
  ## Summary
  Refactors MessageInputView to add Enter key submission, improve accessibility,
  and enhance code quality with better lifecycle management.
  
  ## Changes
  - ✅ Add Enter key submission support (.submitLabel + .onSubmit)
  - ✅ Add focus state management for keyboard dismissal
  - ✅ Add comprehensive accessibility labels and hints
  - ✅ Add task lifecycle management to prevent memory leaks
  - ✅ Add cleanup on view disappear
  - ✅ Add haptic feedback on send
  - ✅ Extract magic numbers to Constants enum
  - ✅ Improve error handling with optional callback
  - ✅ Update preview providers with mock services
  
  ## Testing
  - ✅ Simulator: Hardware keyboard, on-screen keyboard, focus states
  - ✅ Real Device: Bluetooth keyboard, dictation, accessibility
  - ✅ Multi-device sync: Typing indicators, message delivery
  - ✅ Performance: No regression, no memory leaks
  - ✅ Accessibility: VoiceOver tested and working
  
  ## Keyboard Testing Summary
  **Simulator:**
  - Hardware keyboard (Cmd+K): Enter sends message ✓
  - On-screen keyboard: "Send" label visible ✓
  - Focus management: Keyboard dismisses after send ✓
  
  **Real Phone:**
  - Bluetooth keyboard: Enter key works ✓
  - Dictation: Compatible ✓
  - Multiple languages: Tested ✓
  - VoiceOver: Accessible ✓
  
  ## Links
  - PR Brief: Psst/docs/pr-briefs.md#pr-26
  - TODO: Psst/docs/todos/pr-26-todo.md
  ```
  - Test Gate: Description complete and accurate

### 18.4: Verify with User

- [ ] Present completed work to user
  - Demonstrate Enter key functionality in simulator
  - Demonstrate on real device with external keyboard
  - Show accessibility improvements
  - Show code quality improvements
  - Test Gate: User reviews and approves

### 18.5: Create PR

- [ ] Verify all TODO tasks completed
  - Test Gate: All checkboxes checked above

- [ ] Commit changes with clear message
  ```bash
  git add .
  git commit -m "feat(pr-26): Refactor MessageInputView with Enter key support
  
  - Add Enter key submission (.submitLabel + .onSubmit)
  - Add focus state management for keyboard control
  - Add comprehensive accessibility support
  - Add task lifecycle management (prevent memory leaks)
  - Add cleanup on view disappear
  - Add haptic feedback on send
  - Extract magic numbers to Constants enum
  - Improve error handling with optional callback
  - Update preview providers with mock services
  
  Testing:
  - Simulator keyboard (hardware + on-screen) ✓
  - Real device keyboard (Bluetooth + on-screen) ✓
  - Multi-device sync maintained ✓
  - Performance validated (no regression) ✓
  - Accessibility tested with VoiceOver ✓
  
  Fixes: PR #26"
  ```
  - Test Gate: Changes committed successfully

- [ ] Push branch to remote
  ```bash
  git push origin feat/pr-26-message-input-refactor
  ```
  - Test Gate: Branch pushed successfully

- [ ] Create pull request on GitHub
  - Target branch: `develop`
  - Title: "PR #26: MessageInputView Refactor and Enhancements"
  - Description: Use prepared PR description above
  - Test Gate: PR created successfully

---

## Copyable Checklist (for PR description)

```markdown
- [ ] Branch created from develop
- [ ] All TODO tasks completed
- [ ] Enter key submission implemented (.submitLabel + .onSubmit)
- [ ] Focus state management added (@FocusState)
- [ ] Accessibility labels and hints added
- [ ] Task lifecycle management implemented
- [ ] Cleanup on view disappear added
- [ ] Haptic feedback on send added
- [ ] Magic numbers extracted to Constants
- [ ] Error handling improved with optional callback
- [ ] Preview providers updated with mock services
- [ ] Simulator keyboard tested (hardware + on-screen)
- [ ] Real device keyboard tested (Bluetooth + on-screen + dictation)
- [ ] Accessibility tested with VoiceOver
- [ ] Multi-device sync verified (<100ms)
- [ ] Performance validated (no regression, no leaks)
- [ ] Code follows Psst/agents/shared-standards.md patterns
- [ ] No console warnings or errors
- [ ] Documentation and code comments added
```

---

## Notes

- Break tasks into <30 min chunks
- Complete tasks sequentially
- Check off after completion
- Document blockers immediately
- Reference `Psst/agents/shared-standards.md` for common patterns
- Test keyboard behavior on BOTH simulator AND real device
- Verify all async operations use proper threading (background → main)
- Ensure no breaking changes to existing MessageInputView API
- Optional error callback is backward compatible (nil by default)

