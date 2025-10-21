# PR Briefs

This document contains high-level briefs for all Pull Requests in the Psst messaging app project. Each PR represents a logical, vertical slice of functionality that can be completed in 1-3 days.

---

## Phase 1: Core Foundation

### PR #1: project-setup-and-firebase-integration

**Brief:** Set up the Firebase project and integrate Firebase SDK into the iOS application. This includes configuring Firebase Authentication, Firestore Database, Firebase Realtime Database (for presence), and Firebase Cloud Messaging. Create the necessary configuration files (GoogleService-Info.plist) and initialize Firebase in the app delegate. This PR establishes the foundation for all backend services.

**Dependencies:** None

**Complexity:** Simple

**Phase:** 1

**Status:** ✅ COMPLETED

---

### PR #2: user-authentication-flow

**Brief:** Implement complete user authentication flows including sign-up, login, logout, and password reset using Firebase Authentication. Create SwiftUI views for the authentication screens with email/password support. Build an AuthenticationService to handle all auth operations and state management. Include basic form validation and error handling for a smooth user experience.

**Dependencies:** PR #1

**Complexity:** Medium

**Phase:** 1

**Status:** ✅ COMPLETED

---

### PR #3: user-profile-model-and-firestore

**Brief:** Create the User model and establish the `users` collection in Firestore. Implement UserService to handle CRUD operations for user profiles including creating user documents on signup, fetching user data, and updating profile information. Define the user schema (uid, displayName, email, profilePhotoURL) and ensure proper data persistence in Firestore.

**Dependencies:** PR #1, PR #2

**Complexity:** Simple

**Phase:** 1

**Status:** ✅ COMPLETED

---

### PR #4: app-navigation-structure

**Brief:** Build the core SwiftUI navigation structure for the app including tab bar navigation, screen routing, and navigation state management. Create placeholder screens for main app sections (ConversationList, Profile, Settings). Implement navigation between authentication screens and main app screens based on authentication state. Ensure proper view lifecycle management and navigation patterns.

**Dependencies:** PR #2

**Complexity:** Simple

**Phase:** 1

**Status:** ✅ COMPLETED

---

## Phase 2: 1-on-1 Chat

### PR #5: chat-data-models-and-schema

**Brief:** Define the Chat and Message models along with their Firestore schema structure. Create the `chats` collection structure with fields for members, lastMessage, lastMessageTimestamp, and isGroupChat. Define the `messages` sub-collection structure with fields for text, senderID, timestamp, and readBy array. Build helper utilities for chat and message serialization/deserialization.

**Dependencies:** PR #3

**Complexity:** Simple

**Phase:** 2

**Status:** ✅ COMPLETED

---

### PR #6: conversation-list-screen

**Brief:** Build the Conversation List screen that displays all user chats in a scrollable list. Implement real-time Firestore listeners to fetch and update the list of chats. Display chat preview information including the other user's name, last message text, and timestamp. Handle empty states when no conversations exist. Implement pull-to-refresh functionality and proper loading states.

**Dependencies:** PR #4, PR #5

**Complexity:** Medium

**Phase:** 2

**Status:** ✅ COMPLETED

---

### PR #7: chat-view-screen-ui

**Brief:** Create the Chat View screen UI with a message list and input field. Build a scrollable message list that displays messages in chronological order with proper styling for sent vs received messages. Implement the message input bar with text field and send button. Add auto-scroll to bottom when new messages arrive and keyboard handling to avoid input obstruction.

**Dependencies:** PR #4, PR #5

**Complexity:** Medium

**Phase:** 2

**Status:** ✅ COMPLETED

---

### PR #8: real-time-messaging-service

**Brief:** Implement MessageService to handle real-time message sending and receiving using Firestore snapshot listeners. Build functionality to send messages to a chat, listen for new messages in real-time, and update the UI automatically when messages arrive. Implement proper listener lifecycle management to prevent memory leaks. Ensure sub-3-second message delivery latency.

**Dependencies:** PR #5, PR #7

**Complexity:** Complex

**Phase:** 2

**Status:** ✅ COMPLETED

---

## 🔄 Direction Change After PR #8

After completing PR #8, we identified a critical dependency issue in the original build order:

**The Problem:** PRs 6, 7, and 8 built screens to display and message in chats, but PR #12 (the ability to CREATE chats) wasn't scheduled until later. This meant we couldn't properly test PRs 6-8 without either:
- Manually creating chat documents in Firestore Console
- Using MockDataService (DEBUG-only fake data)

**The Solution:** Restructure remaining PRs to:
1. Prioritize chat creation (move PR #12 logic to NEW PR #9)
2. Consolidate related features to reduce context switching
3. Build features in dependency order (create → display → enhance)

**Changes Made:**
- Original PRs 9-25 (17 PRs) → Consolidated to NEW PRs 9-18 (10 PRs)
- Chat creation moved from old PR #12 to NEW PR #9 (next immediate task)
- Related features bundled (e.g., optimistic UI + offline persistence)
- Server timestamps already implemented in PR #8, so old PR #10 is effectively done

**Result:** More logical build order with fewer, more complete PRs.

---

### PR #9: chat-creation-and-contact-selection

**Brief:** Build the complete "Start New Chat" flow with user selection, search, and chat creation. Add createChat() method to ChatService that checks for existing chats before creating duplicates. Create a user selection screen displaying all available users from the `users` collection with real-time search functionality to filter by display name or email. Implement chat creation logic for 1-on-1 conversations and navigate to the new chat. Remove MockDataService after completion since users can now create real chats.

**Dependencies:** PRs 1-8 (completed)

**Complexity:** Medium

**Phase:** 2

**Status:** ✅ COMPLETED

---

### PR #10: optimistic-ui-and-offline-persistence

**Brief:** Implement optimistic UI pattern for instant message feedback and enable full offline support. When users send messages, immediately add them to local SwiftUI state with "sending" status before Firestore confirms. Update status to "delivered" once confirmed. Enable Firestore offline persistence (isPersistenceEnabled = true) so users can view previously loaded messages without internet. Implement message queueing for offline sends with automatic sync on reconnection. Add offline mode indicators and handle network state transitions gracefully.

**Dependencies:** PR #8

**Complexity:** Medium

**Phase:** 2

**Status:** ✅ COMPLETED

---

## Phase 3: Group Chats & Presence

### PR #11: group-chat-support

**Brief:** Extend chat functionality to support group conversations with 3+ users. Update the user selection screen from PR #9 to support multi-select mode for choosing multiple contacts. Implement group chat creation logic in ChatService that sets isGroupChat to true and supports multiple members in the members array. Add group chat naming functionality. Update ChatView UI to display sender names with each message in group conversations (instead of just sent/received styling). Update MessageService to properly handle sending to and receiving from multiple group members with real-time synchronization for all participants. Display group member avatars in the conversation list.

**Dependencies:** PR #9 (chat creation)

**Complexity:** Medium

**Phase:** 3

**Status:** ✅ COMPLETED

---

### PR #12: online-offline-presence-system

**Brief:** Integrate Firebase Realtime Database to implement online/offline presence indicators for users. Create a PresenceService that writes a user's online status when they open the app and uses Firebase's onDisconnect() hook to automatically set offline status when the app disconnects or crashes. Update presence on app lifecycle events (foreground, background, terminate). Display presence indicators (green dot for online, gray dot for offline) next to user names in the conversation list and chat view header. Handle presence updates in real-time across all users.

**Dependencies:** PR #1, PR #6

**Complexity:** Complex

**Phase:** 3

**Status:** ✅ COMPLETED

---

### PR #13: typing-indicators

**Brief:** Implement "is typing..." indicators to show when other users are composing messages in a conversation. Use Firebase Realtime Database to broadcast typing status with automatic 3-second timeout. Display typing indicator in the chat view below the message list when one or more users are typing. Ensure typing status is automatically cleared when messages are sent or after inactivity timeout. Handle multiple simultaneous typers in group chats (e.g., "Alice and 2 others are typing...").

**Dependencies:** PR #12 (presence system)

**Complexity:** Medium

**Phase:** 3

**Status:** ✅ COMPLETED

---

## Phase 4: Polish & Notifications

### PR #14: message-read-receipts

**Brief:** Implement read receipts to show when messages have been seen by recipients. Update message documents in Firestore with a readBy array when users view messages in the chat view. Create logic to automatically mark messages as read when the chat view is opened and messages become visible on screen. Display "Read", "Delivered", or "Seen" indicators under sent messages in the UI with appropriate visual styling. Handle read receipts correctly for both 1-on-1 and group chats (showing individual read status per recipient in groups).

**Dependencies:** PR #8 (messaging service)

**Complexity:** Medium

**Phase:** 4

---

### PR #15: push-notifications-setup

**Brief:** Configure Apple Push Notification service (APNs) and Firebase Cloud Messaging (FCM) for the iOS app. Register the app with APNs to receive device tokens and upload them to Firebase. Configure push notification capabilities in Xcode, add necessary entitlements, and update provisioning profiles. Create NotificationService to handle device token registration, notification permission requests, and token refresh. Store device tokens in user documents in Firestore. Test basic notification reception from Firebase Console.

**Dependencies:** PR #1 (Firebase setup)

**Complexity:** Medium

**Phase:** 4

---

### PR #16: cloud-functions-and-notification-handling

**Brief:** Write and deploy Firebase Cloud Functions that trigger when new messages are written to Firestore. Functions should identify all chat recipients (excluding sender), fetch their FCM device tokens, and send push notifications with message content and sender information. Implement notification handling on iOS to process received notifications in foreground, background, and terminated app states. Create deep linking logic to navigate users directly to the relevant chat when tapping a notification. Display foreground notifications as in-app banners. Implement notification badge count management and clear notifications when messages are read. Handle both 1-on-1 and group chat notification scenarios.

**Dependencies:** PR #15 (push setup), PR #8 (messaging)

**Complexity:** Complex

**Phase:** 4

---

### PR #17: user-profile-editing

**Brief:** Build a profile editing screen where users can update their display name and profile picture. Implement PHPicker integration to allow users to select photos from their device photo library. Upload profile photos to Firebase Storage with proper compression and store the download URL in the user's Firestore document. Add form validation for display name (character limits, empty checks). Implement real-time profile updates across all app screens (conversation list, chat view, settings). Add loading states during image upload and save operations.

**Dependencies:** PR #3 (user profiles), PR #4 (navigation)

**Complexity:** Medium

**Phase:** 4

---

### PR #18: final-polish-and-testing

**Brief:** Complete all remaining polish, error handling, accessibility, and testing tasks. Polish the entire app UI with consistent styling, smooth animations, and iOS Human Interface Guidelines compliance. Implement comprehensive accessibility features (VoiceOver support, Dynamic Type, color contrast, accessible labels). Add haptic feedback for key interactions. Implement thorough error handling for network errors, Firebase errors, authentication failures, and permission denials with user-friendly error messages and retry mechanisms. Handle edge cases (deleted users, deleted chats, malformed data, concurrent modifications). Create comprehensive test coverage including unit tests for all services (AuthenticationService, MessageService, UserService, PresenceService, ChatService), UI tests for critical user flows (auth, messaging, chat creation), and integration tests for Firebase interactions. Test offline scenarios and edge conditions. Perform end-to-end testing of all 10 core MVP requirements. Document test results and fix all discovered bugs.

**Dependencies:** All previous PRs (1-17)

**Complexity:** Complex

**Phase:** 4

---

## Summary

### Original Plan
- **Total PRs:** 25
- **Phase 1 (Foundation):** 4 PRs
- **Phase 2 (1-on-1 Chat):** 8 PRs
- **Phase 3 (Group Chats & Presence):** 4 PRs
- **Phase 4 (Polish & Notifications):** 9 PRs

### Revised Plan (After PR #8)
- **Total PRs:** 18 (consolidated from 25)
- **Phase 1 (Foundation):** 4 PRs - ✅ **COMPLETED** (PRs 1-4)
- **Phase 2 (Core Chat):** 6 PRs - ✅ **5 COMPLETED** (PRs 5-8), 🎯 **2 TODO** (PRs 9-10)
- **Phase 3 (Group Chats & Presence):** 3 PRs (PRs 11-13)
- **Phase 4 (Polish & Notifications):** 5 PRs (PRs 14-18)

### Why the Change?
After completing PR #8, we realized the original order had us building display/messaging features before the ability to create chats. The revised plan:
- **Prioritizes chat creation** (moved to PR #9)
- **Consolidates related features** (e.g., optimistic UI + offline persistence)
- **Reduces context switching** (10 focused PRs instead of 17 scattered ones)
- **Maintains momentum** (each PR delivers complete, testable functionality)

Each PR is designed to deliver a complete, testable piece of functionality that builds incrementally toward the full MVP as defined in the Product Requirements Document.

