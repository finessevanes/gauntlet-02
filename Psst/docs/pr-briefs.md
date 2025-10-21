# PR Briefs

This document contains high-level briefs for all Pull Requests in the Psst messaging app project. Each PR represents a logical, vertical slice of functionality that can be completed in 1-3 days.

---

## Phase 1: Core Foundation

### PR #1: project-setup-and-firebase-integration

**Brief:** Set up the Firebase project and integrate Firebase SDK into the iOS application. This includes configuring Firebase Authentication, Firestore Database, Firebase Realtime Database (for presence), and Firebase Cloud Messaging. Create the necessary configuration files (GoogleService-Info.plist) and initialize Firebase in the app delegate. This PR establishes the foundation for all backend services.

**Dependencies:** None

**Complexity:** Simple

**Phase:** 1

---

### PR #2: user-authentication-flow

**Brief:** Implement complete user authentication flows including sign-up, login, logout, and password reset using Firebase Authentication. Create SwiftUI views for the authentication screens with email/password support. Build an AuthenticationService to handle all auth operations and state management. Include basic form validation and error handling for a smooth user experience.

**Dependencies:** PR #1

**Complexity:** Medium

**Phase:** 1

---

### PR #3: user-profile-model-and-firestore

**Brief:** Create the User model and establish the `users` collection in Firestore. Implement UserService to handle CRUD operations for user profiles including creating user documents on signup, fetching user data, and updating profile information. Define the user schema (uid, displayName, email, profilePhotoURL) and ensure proper data persistence in Firestore.

**Dependencies:** PR #1, PR #2

**Complexity:** Simple

**Phase:** 1

---

### PR #4: app-navigation-structure

**Brief:** Build the core SwiftUI navigation structure for the app including tab bar navigation, screen routing, and navigation state management. Create placeholder screens for main app sections (ConversationList, Profile, Settings). Implement navigation between authentication screens and main app screens based on authentication state. Ensure proper view lifecycle management and navigation patterns.

**Dependencies:** PR #2

**Complexity:** Simple

**Phase:** 1

---

## Phase 2: 1-on-1 Chat

### PR #5: chat-data-models-and-schema

**Brief:** Define the Chat and Message models along with their Firestore schema structure. Create the `chats` collection structure with fields for members, lastMessage, lastMessageTimestamp, and isGroupChat. Define the `messages` sub-collection structure with fields for text, senderID, timestamp, and readBy array. Build helper utilities for chat and message serialization/deserialization.

**Dependencies:** PR #3

**Complexity:** Simple

**Phase:** 2

---

### PR #6: conversation-list-screen

**Brief:** Build the Conversation List screen that displays all user chats in a scrollable list. Implement real-time Firestore listeners to fetch and update the list of chats. Display chat preview information including the other user's name, last message text, and timestamp. Handle empty states when no conversations exist. Implement pull-to-refresh functionality and proper loading states.

**Dependencies:** PR #4, PR #5

**Complexity:** Medium

**Phase:** 2

---

### PR #7: chat-view-screen-ui

**Brief:** Create the Chat View screen UI with a message list and input field. Build a scrollable message list that displays messages in chronological order with proper styling for sent vs received messages. Implement the message input bar with text field and send button. Add auto-scroll to bottom when new messages arrive and keyboard handling to avoid input obstruction.

**Dependencies:** PR #4, PR #5

**Complexity:** Medium

**Phase:** 2

---

### PR #8: real-time-messaging-service

**Brief:** Implement MessageService to handle real-time message sending and receiving using Firestore snapshot listeners. Build functionality to send messages to a chat, listen for new messages in real-time, and update the UI automatically when messages arrive. Implement proper listener lifecycle management to prevent memory leaks. Ensure sub-3-second message delivery latency.

**Dependencies:** PR #5, PR #7

**Complexity:** Complex

**Phase:** 2

---

### PR #9: optimistic-ui-updates

**Brief:** Implement optimistic UI pattern for message sending to provide instant feedback to users. When a user sends a message, immediately add it to the local SwiftUI state with a "sending" status before the Firestore write completes. Update the message status to "delivered" once Firestore confirms the write. Handle error cases where message sending fails and allow retry functionality.

**Dependencies:** PR #8

**Complexity:** Medium

**Phase:** 2

---

### PR #10: server-timestamps-and-sync

**Brief:** Implement Firestore server timestamps for all messages using FieldValue.serverTimestamp() to ensure accurate, synchronized timestamps across all devices. Update the message model to handle server timestamp conversion. Display timestamps in the UI with proper formatting (relative time for recent messages, absolute time for older ones). Ensure timestamps are timezone-aware and display correctly.

**Dependencies:** PR #8

**Complexity:** Simple

**Phase:** 2

---

### PR #11: offline-persistence-and-caching

**Brief:** Enable Firestore offline persistence by setting isPersistenceEnabled = true in the Firebase configuration. Implement logic to handle offline scenarios gracefully, allowing users to view previously loaded messages without internet. Implement message queueing for messages sent while offline, ensuring they're sent automatically when connectivity is restored. Add UI indicators for offline mode.

**Dependencies:** PR #8

**Complexity:** Medium

**Phase:** 2

---

### PR #12: start-new-chat-flow

**Brief:** Build the "Start New Chat" flow that allows users to select another user from their contacts to begin a 1-on-1 conversation. Create a user selection screen that displays all available users from the `users` collection. Implement chat creation logic that checks if a chat already exists between two users, and if not, creates a new chat document in Firestore. Navigate to the new chat after creation.

**Dependencies:** PR #6, PR #7

**Complexity:** Medium

**Phase:** 2

---

## Phase 3: Group Chats & Presence

### PR #13: group-chat-creation-flow

**Brief:** Extend the "Start New Chat" flow to support group chat creation with 3+ users. Build a multi-select user picker interface that allows selecting multiple contacts. Implement group chat creation logic that creates a chat document with multiple members in the members array and sets isGroupChat to true. Add group chat naming functionality and display group member avatars in the conversation list.

**Dependencies:** PR #12

**Complexity:** Medium

**Phase:** 3

---

### PR #14: group-chat-messaging

**Brief:** Ensure messaging functionality works correctly for group chats with 3+ members. Update MessageService to handle sending messages to all group members and receiving messages from multiple senders. Update the Chat View UI to clearly distinguish between different senders in group conversations (display sender names with each message). Implement proper real-time synchronization for all group members.

**Dependencies:** PR #13, PR #8

**Complexity:** Medium

**Phase:** 3

---

### PR #15: online-offline-presence-system

**Brief:** Integrate Firebase Realtime Database to implement online/offline presence indicators for users. Create a PresenceService that writes a user's online status when they open the app and uses Firebase's onDisconnect() hook to automatically set offline status when the app disconnects. Display presence indicators (green dot for online, gray for offline) next to user names in the conversation list and chat view.

**Dependencies:** PR #1, PR #6

**Complexity:** Complex

**Phase:** 3

---

### PR #16: typing-indicators

**Brief:** Implement "is typing..." indicators to show when other users are composing messages in a conversation. Use Firebase Realtime Database to broadcast typing status with automatic timeout. Display typing indicator in the chat view when one or more users are typing. Ensure typing status is cleared when messages are sent or after inactivity timeout. Handle multiple simultaneous typers in group chats.

**Dependencies:** PR #15

**Complexity:** Medium

**Phase:** 3

---

## Phase 4: Polish & Notifications

### PR #17: message-read-receipts

**Brief:** Implement read receipts to show when messages have been seen by recipients. Update message documents in Firestore with a readBy array when users view messages. Create logic to mark messages as read when the chat view is opened and messages are visible. Display "Read" or "Seen" indicators under sent messages in the UI. Handle read receipts for both 1-on-1 and group chats.

**Dependencies:** PR #8

**Complexity:** Medium

**Phase:** 4

---

### PR #18: push-notifications-setup

**Brief:** Configure Apple Push Notification service (APNs) and Firebase Cloud Messaging (FCM) for the iOS app. Register the app with APNs to receive device tokens and upload them to Firebase. Configure push notification capabilities in Xcode and add the necessary entitlements. Create NotificationService to handle device token registration and notification permission requests. Test basic notification reception.

**Dependencies:** PR #1

**Complexity:** Medium

**Phase:** 4

---

### PR #19: cloud-functions-for-notifications

**Brief:** Write and deploy Firebase Cloud Functions that trigger when new messages are written to Firestore. The function should identify all recipients in a chat (excluding the sender), fetch their FCM device tokens, and send push notifications with the message content and sender information. Handle both 1-on-1 and group chat scenarios. Implement notification prioritization and ensure foreground notifications work correctly.

**Dependencies:** PR #18, PR #8

**Complexity:** Complex

**Phase:** 4

---

### PR #20: notification-handling-and-deep-linking

**Brief:** Implement notification handling to properly process received push notifications when the app is in foreground, background, or terminated states. Create deep linking logic to navigate users directly to the relevant chat when they tap a notification. Display foreground notifications as in-app banners. Update notification badge counts and clear notifications when messages are read.

**Dependencies:** PR #19

**Complexity:** Medium

**Phase:** 4

---

### PR #21: user-profile-editing

**Brief:** Build a profile editing screen where users can update their display name and profile picture. Implement image picker integration to allow users to select photos from their device. Upload profile photos to Firebase Storage and store the download URL in the user's Firestore document. Add form validation for display name and implement real-time profile updates across all screens.

**Dependencies:** PR #3, PR #4

**Complexity:** Medium

**Phase:** 4

---

### PR #22: contact-search-functionality

**Brief:** Add search functionality to the user selection screens (new chat and new group chat flows). Implement a search bar that filters the user list by display name or email in real-time as users type. Optimize search performance for large user lists and add debouncing to reduce unnecessary queries. Display search results with highlighting of matched terms.

**Dependencies:** PR #12

**Complexity:** Simple

**Phase:** 4

---

### PR #23: ui-polish-and-accessibility

**Brief:** Polish the entire app UI with consistent styling, animations, and transitions. Implement proper accessibility features including VoiceOver support, Dynamic Type, sufficient color contrast, and accessible labels. Add haptic feedback for key interactions. Refine animations for message sending, screen transitions, and loading states. Ensure the app follows iOS Human Interface Guidelines.

**Dependencies:** PR #6, PR #7

**Complexity:** Medium

**Phase:** 4

---

### PR #24: error-handling-and-edge-cases

**Brief:** Implement comprehensive error handling throughout the app including network errors, Firebase errors, authentication errors, and permission denials. Add user-friendly error messages and retry mechanisms where appropriate. Handle edge cases such as deleted users, deleted chats, malformed data, and concurrent modifications. Add error logging for debugging and analytics.

**Dependencies:** PR #2, PR #8, PR #15

**Complexity:** Medium

**Phase:** 4

---

### PR #25: testing-and-qa

**Brief:** Create comprehensive test coverage including unit tests for services (AuthenticationService, MessageService, UserService, PresenceService), UI tests for critical user flows (authentication, sending messages, creating chats), and integration tests for Firebase interactions. Test offline scenarios, error cases, and edge conditions. Perform end-to-end testing of all 10 core requirements. Document test results and fix any discovered bugs.

**Dependencies:** All previous PRs

**Complexity:** Complex

**Phase:** 4

---

## Summary

- **Total PRs:** 25
- **Phase 1 (Foundation):** 4 PRs
- **Phase 2 (1-on-1 Chat):** 8 PRs
- **Phase 3 (Group Chats & Presence):** 4 PRs
- **Phase 4 (Polish & Notifications):** 9 PRs

Each PR is designed to deliver a complete, testable piece of functionality that builds incrementally toward the full MVP as defined in the Product Requirements Document.

