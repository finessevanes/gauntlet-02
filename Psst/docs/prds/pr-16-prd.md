# PRD: Cloud Functions and Notification Handling

**Feature**: cloud-functions-and-notification-handling

**Version**: 1.0

**Status**: Draft

**Agent**: Pam

**Target Release**: Phase 4

**Links**: [PR Brief], [TODO], [Designs], [Tracking Issue]

---

## 1. Summary

Implement Firebase Cloud Functions to automatically send push notifications when new messages are created, and handle notification processing on iOS including deep linking to specific chats and badge count management.

---

## 2. Problem & Goals

- **User Problem**: Users miss messages when the app is closed or in background, leading to delayed responses and poor user experience
- **Why Now**: Core messaging functionality is complete (PRs 1-15), now need to ensure users are notified of new messages regardless of app state
- **Goals (ordered, measurable)**:
  - [ ] G1 — Users receive push notifications for new messages within 5 seconds of message creation
  - [ ] G2 — Tapping notifications opens the correct chat conversation
  - [ ] G3 — Notification badge counts accurately reflect unread messages

---

## 3. Non-Goals / Out of Scope

- [ ] Not implementing custom notification sounds (using system defaults)
- [ ] Not building notification scheduling or delayed delivery
- [ ] Not implementing notification grouping by chat (iOS handles this automatically)
- [ ] Not building notification history or management screens

---

## 4. Success Metrics

Reference `Psst/agents/shared-standards.md` for metric templates:
- **User-visible**: Notification delivery time < 5 seconds, successful deep link navigation, accurate badge counts
- **System**: Cloud Function execution time < 3 seconds, FCM delivery success rate > 95%
- **Quality**: 0 blocking bugs, all gates pass, crash-free >99%

---

## 5. Users & Stories

- As a **message recipient**, I want to receive push notifications for new messages so that I don't miss important conversations
- As a **user with multiple chats**, I want notifications to open the correct chat so that I can respond immediately
- As a **group chat participant**, I want to see who sent the message in the notification so that I can prioritize my response
- As a **mobile user**, I want notification badges to show accurate unread counts so that I know how many messages I need to check

---

## 6. Experience Specification (UX)

- **Entry points and flows**: 
  - Notifications appear when new messages are sent to chats where user is a member
  - Tapping notification opens app and navigates to specific chat
  - Badge counts update in real-time as messages are read
- **Visual behavior**: 
  - Standard iOS notification banners with message preview
  - Badge count on app icon shows total unread messages
  - Foreground notifications show as in-app banners
- **Loading/disabled/error states**: 
  - Graceful handling when FCM tokens are invalid
  - Fallback to silent notifications if user has disabled notifications
- **Performance**: See targets in `Psst/agents/shared-standards.md`

---

## 7. Functional Requirements (Must/Should)

- **MUST**: Cloud Function triggers on new message creation in Firestore
- **MUST**: Function identifies all chat recipients excluding sender
- **MUST**: Function fetches FCM device tokens for all recipients
- **MUST**: Function sends push notifications with message content and sender info
- **MUST**: iOS handles notifications in foreground, background, and terminated states
- **MUST**: Deep linking navigates to correct chat when notification tapped
- **MUST**: Badge count management updates as messages are read
- **SHOULD**: Foreground notifications display as in-app banners
- **SHOULD**: Handle both 1-on-1 and group chat notification scenarios

**Acceptance gates per requirement**:
- [Gate] When User A sends message → User B receives notification within 5 seconds
- [Gate] Tapping notification → Opens correct chat conversation
- [Gate] Reading messages → Badge count decreases accordingly
- [Gate] Group chat notifications → Show sender name in notification text

---

## 8. Data Model

### Cloud Function Data Access
```swift
// Function reads from existing Firestore collections:
// - messages/{messageId} - to get message content and sender
// - chats/{chatId} - to get chat members
// - users/{userId} - to get FCM device tokens
```

### FCM Notification Payload
```swift
{
  "notification": {
    "title": "New message from [senderName]",
    "body": "[messageText]",
    "badge": "[unreadCount]"
  },
  "data": {
    "chatId": "[chatId]",
    "messageId": "[messageId]",
    "senderId": "[senderId]",
    "type": "new_message"
  }
}
```

### iOS Notification Handling
```swift
// NotificationService handles:
// - Device token registration/refresh
// - Notification permission requests
// - Deep link processing
// - Badge count management
```

- **Validation rules**: FCM tokens must be valid, chat members must exist
- **Indexing/queries**: Cloud Function queries users collection by member IDs

---

## 9. API / Service Contracts

### Cloud Function API
```swift
// Triggered automatically on Firestore write
func onMessageCreate(snapshot: DocumentSnapshot, context: EventContext) -> Promise<Void>

// Helper functions:
func getChatMembers(chatId: String) -> Promise<[String]>
func getFCMTokens(userIds: [String]) -> Promise<[String]>
func sendNotification(tokens: [String], payload: [String: Any]) -> Promise<Void>
```

### iOS NotificationService
```swift
// Device token management
func registerForRemoteNotifications() async throws
func updateDeviceToken(_ token: String) async throws

// Notification handling
func handleNotification(_ userInfo: [AnyHashable: Any]) -> Bool
func processDeepLink(chatId: String) async throws

// Badge management
func updateBadgeCount() async throws
func clearBadgeCount() async throws
```

- **Pre/post-conditions**: Functions handle errors gracefully, tokens are validated
- **Error handling strategy**: Log errors, continue processing other recipients
- **Parameters and types**: All parameters explicitly typed
- **Return values**: Promise-based async operations

---

## 10. UI Components to Create/Modify

- `Services/NotificationService.swift` — Handle FCM registration and notification processing
- `Services/CloudFunctionsService.swift` — Manage Cloud Function deployment and monitoring
- `Utilities/DeepLinkHandler.swift` — Process notification deep links
- `App/PsstApp.swift` — Add notification permission requests
- `Views/ConversationView.swift` — Update badge count when messages read
- `Views/ChatListView.swift` — Update badge count for individual chats

---

## 11. Integration Points

- **Firebase Cloud Functions** - Serverless notification triggers
- **Firebase Cloud Messaging (FCM)** - Push notification delivery
- **Firestore** - Message and user data access
- **iOS Notification Center** - System notification handling
- **Deep Linking** - Navigation to specific chats
- **Badge Management** - Unread message counting

---

## 12. Testing Plan & Acceptance Gates

Define BEFORE implementation. Use checkboxes.

**Current**: Manual testing validation (see `Psst/agents/shared-standards.md`)  
**Future**: Automated testing recommendations in `Psst/docs/testing-strategy.md`

- **Configuration Testing**
  - [ ] Cloud Functions deployed successfully
  - [ ] FCM configuration working in iOS app
  - [ ] Device tokens registered in Firestore
  - [ ] Notification permissions granted
  
- **Happy Path Testing**
  - [ ] Send message → Recipient receives notification within 5 seconds
  - [ ] Gate: Notification contains correct message content and sender name
  
- **Edge Cases Testing**
  - [ ] Invalid FCM tokens handled gracefully
  - [ ] Offline users receive notifications when back online
  - [ ] Group chat notifications show correct sender
  - [ ] Badge counts update correctly when messages read
  
- **Multi-User Testing**
  - [ ] Multiple recipients receive notifications simultaneously
  - [ ] Group chat notifications work for all members
  - [ ] Deep links work correctly for all chat types
  
- **Performance Testing (see shared-standards.md)**
  - [ ] Cloud Function execution < 3 seconds
  - [ ] FCM delivery success rate > 95%
  - [ ] Badge count updates in real-time

---

## 13. Definition of Done

See standards in `Psst/agents/shared-standards.md`:
- [ ] Cloud Functions deployed and triggering on message creation
- [ ] FCM integration working with device token registration
- [ ] Deep linking navigates to correct chats
- [ ] Badge count management working correctly
- [ ] All acceptance gates pass
- [ ] Manual testing completed (configuration, user flows, multi-device, notifications)
- [ ] Docs updated

---

## 14. Risks & Mitigations

- **Risk**: FCM token expiration → **Mitigation**: Implement token refresh logic and handle invalid tokens gracefully
- **Risk**: Cloud Function timeouts → **Mitigation**: Optimize function performance, implement retry logic
- **Risk**: Deep linking failures → **Mitigation**: Add fallback navigation to chat list
- **Risk**: Badge count inconsistencies → **Mitigation**: Implement server-side badge tracking
- **Risk**: Notification delivery failures → **Mitigation**: Monitor FCM delivery rates, implement retry mechanism

---

## 15. Rollout & Telemetry

- **Feature flag?** No (core functionality)
- **Metrics**: Notification delivery rate, deep link success rate, badge accuracy
- **Manual validation steps**: Test with multiple devices, various notification states

---

## 16. Open Questions

- Q1: Should we implement notification grouping by chat?
- Q2: How to handle notification preferences per user?

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future:
- [ ] Custom notification sounds
- [ ] Notification scheduling
- [ ] Advanced notification management
- [ ] Notification analytics and reporting

---

## Preflight Questionnaire

Answer these to drive vertical slice and acceptance gates:

1. **Smallest end-to-end user outcome for this PR?** User receives push notification and can tap to open the correct chat
2. **Primary user and critical action?** Message recipient receiving and acting on notifications
3. **Must-have vs nice-to-have?** Must-have: notification delivery and deep linking. Nice-to-have: custom sounds, advanced grouping
4. **Real-time requirements?** Notifications must be delivered within 5 seconds of message creation
5. **Performance constraints?** Cloud Function execution < 3 seconds, FCM delivery > 95% success rate
6. **Error/edge cases to handle?** Invalid FCM tokens, offline users, deep link failures
7. **Data model changes?** Add FCM token storage to user documents
8. **Service APIs required?** Cloud Function triggers, FCM API, iOS notification handling
9. **UI entry points and states?** Notification banners, badge counts, deep link navigation
10. **Security/permissions implications?** Notification permissions, FCM token security
11. **Dependencies or blocking integrations?** Requires PR #15 (push setup) and PR #8 (messaging)
12. **Rollout strategy and metrics?** Deploy Cloud Functions, monitor delivery rates
13. **What is explicitly out of scope?** Custom sounds, notification scheduling, advanced management

---

## Authoring Notes

- Write Test Plan before coding
- Favor vertical slice that ships standalone
- Keep service layer deterministic
- SwiftUI views are thin wrappers
- Test offline/online thoroughly
- Reference `Psst/agents/shared-standards.md` throughout
