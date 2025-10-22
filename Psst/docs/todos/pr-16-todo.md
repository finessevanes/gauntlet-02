# PR-16 TODO — Cloud Functions and Notification Handling

**Branch**: `feat/pr-16-cloud-functions-and-notification-handling`  
**Source PRD**: `Psst/docs/prds/pr-16-prd.md`  
**Owner (Agent)**: Caleb

---

## 0. Clarifying Questions & Assumptions

- **Questions**: 
  - Should we implement notification grouping by chat or let iOS handle it automatically?
  - How should we handle users who have disabled notifications?
- **Assumptions (confirm in PR if needed)**:
  - Cloud Functions will be deployed to Firebase project
  - FCM tokens will be stored in user documents in Firestore
  - Deep linking will use URL schemes (not universal links for now)

---

## 1. Setup

- [ ] Create branch `feat/pr-16-cloud-functions-and-notification-handling` from develop
- [ ] Read PRD thoroughly
- [ ] Read `Psst/agents/shared-standards.md` for patterns
- [ ] Confirm Firebase project has Cloud Functions enabled
- [ ] Verify FCM configuration in existing Firebase setup

---

## 2. Cloud Functions Implementation

Implement serverless functions to trigger notifications on message creation.

- [ ] Create Cloud Functions project structure
  - Test Gate: Functions directory created with proper structure
- [ ] Implement `onMessageCreate` function
  - Test Gate: Function triggers when new message is created in Firestore
- [ ] Add helper function `getChatMembers(chatId: String)`
  - Test Gate: Returns array of user IDs for given chat
- [ ] Add helper function `getFCMTokens(userIds: [String])`
  - Test Gate: Returns array of valid FCM tokens for given user IDs
- [ ] Add helper function `sendNotification(tokens: [String], payload: [String: Any])`
  - Test Gate: Sends notification to all provided tokens
- [ ] Add error handling and logging
  - Test Gate: Invalid tokens are logged but don't stop processing
- [ ] Deploy Cloud Functions to Firebase
  - Test Gate: Functions are live and accessible in Firebase Console

---

## 3. iOS Notification Service

Create service to handle FCM registration and notification processing.

- [ ] Create `Services/NotificationService.swift`
  - Test Gate: Service compiles and can be instantiated
- [ ] Implement device token registration
  - Test Gate: Device token is registered with FCM and stored in Firestore
- [ ] Implement token refresh handling
  - Test Gate: Token updates are reflected in Firestore user document
- [ ] Add notification permission requests
  - Test Gate: App requests notification permissions on first launch
- [ ] Implement notification handling for foreground state
  - Test Gate: Foreground notifications display as in-app banners
- [ ] Implement notification handling for background state
  - Test Gate: Background notifications are processed correctly
- [ ] Implement notification handling for terminated state
  - Test Gate: Tapping notification opens app and navigates to chat

---

## 4. Deep Linking Implementation

Create deep linking system to navigate to specific chats.

- [ ] Create `Utilities/DeepLinkHandler.swift`
  - Test Gate: Deep link handler can parse notification data
- [ ] Implement chat navigation logic
  - Test Gate: Deep link opens correct chat conversation
- [ ] Add fallback navigation
  - Test Gate: Invalid deep links fall back to chat list
- [ ] Integrate with existing navigation system
  - Test Gate: Deep linking works with current navigation structure

---

## 5. Badge Count Management

Implement notification badge count tracking and updates.

- [ ] Add badge count tracking to user documents
  - Test Gate: Badge counts are stored and updated in Firestore
- [ ] Implement badge count calculation
  - Test Gate: Badge count reflects total unread messages across all chats
- [ ] Add badge count updates when messages are read
  - Test Gate: Reading messages decreases badge count
- [ ] Implement badge count clearing
  - Test Gate: Opening chat clears badge count for that chat
- [ ] Add real-time badge count updates
  - Test Gate: Badge count updates immediately when messages are read

---

## 6. UI Integration

Update existing views to support notification features.

- [ ] Update `App/PsstApp.swift` for notification permissions
  - Test Gate: App requests permissions on launch
- [ ] Update `Views/ConversationView.swift` for badge clearing
  - Test Gate: Opening chat clears badge count
- [ ] Update `Views/ChatListView.swift` for individual chat badges
  - Test Gate: Each chat shows correct unread count
- [ ] Add notification state indicators
  - Test Gate: UI shows notification permission status

---

## 7. Testing Validation

**Current**: Manual testing validation (see `Psst/agents/shared-standards.md`)  
**Future**: Automated testing recommendations in `Psst/docs/testing-strategy.md`

- [ ] **Configuration Testing**
  - Test Gate: Cloud Functions deployed and accessible
  - Test Gate: FCM configuration working in iOS app
  - Test Gate: Device tokens registered in Firestore
  - Test Gate: Notification permissions granted
  
- [ ] **User Flow Testing**
  - Test Gate: Send message → Recipient receives notification within 5 seconds
  - Test Gate: Tapping notification opens correct chat conversation
  - Test Gate: Badge counts update correctly when messages are read
  
- [ ] **Multi-Device Testing**
  - Test Gate: Notifications work across multiple devices
  - Test Gate: Group chat notifications work for all members
  - Test Gate: Deep links work correctly on all devices
  
- [ ] **Edge Cases Testing**
  - Test Gate: Invalid FCM tokens handled gracefully
  - Test Gate: Offline users receive notifications when back online
  - Test Gate: Notification permission denied scenarios handled
  - Test Gate: Deep link failures fall back gracefully
  
- [ ] **Visual States Verification**
  - Test Gate: Notification banners display correctly
  - Test Gate: Badge counts show accurate numbers
  - Test Gate: No console errors during notification processing

---

## 8. Performance

Verify targets from `Psst/agents/shared-standards.md`.

- [ ] Cloud Function execution < 3 seconds
  - Test Gate: Function completes within time limit
- [ ] FCM delivery success rate > 95%
  - Test Gate: Notifications delivered successfully
- [ ] Badge count updates in real-time
  - Test Gate: Badge counts update immediately when messages are read
- [ ] Deep link navigation < 1 second
  - Test Gate: Tapping notification opens chat quickly

---

## 9. Acceptance Gates

Check every gate from PRD Section 12:
- [ ] All happy path gates pass (notification delivery, deep linking)
- [ ] All edge case gates pass (invalid tokens, offline scenarios)
- [ ] All multi-user gates pass (group notifications, multiple devices)
- [ ] All performance gates pass (execution time, delivery rate)

---

## 10. Documentation & PR

- [ ] Add inline code comments for complex logic
- [ ] Document Cloud Functions deployment process
- [ ] Create PR description (use format from Psst/agents/caleb-agent.md)
- [ ] Verify with user before creating PR
- [ ] Open PR targeting develop branch
- [ ] Link PRD and TODO in PR description

---

## Copyable Checklist (for PR description)

```markdown
- [ ] Branch created from develop
- [ ] All TODO tasks completed
- [ ] Cloud Functions implemented and deployed
- [ ] FCM integration working with device token registration
- [ ] Deep linking navigates to correct chats
- [ ] Badge count management working correctly
- [ ] Manual testing completed (configuration, user flows, multi-device, notifications)
- [ ] Multi-device notification delivery verified
- [ ] Performance targets met (Cloud Function < 3s, FCM > 95% success)
- [ ] All acceptance gates pass
- [ ] Code follows Psst/agents/shared-standards.md patterns
- [ ] No console warnings
- [ ] Documentation updated
```

---

## Notes

- Break tasks into <30 min chunks
- Complete tasks sequentially
- Check off after completion
- Document blockers immediately
- Reference `Psst/agents/shared-standards.md` for common patterns and solutions
- Cloud Functions require Firebase CLI and proper project configuration
- FCM tokens need to be stored securely in user documents
- Deep linking requires careful integration with existing navigation
