Here is the completed Product Requirements Document (PRD) based on your outline and requirements.

# Simplified MessageAI — Product Requirements

**Tagline:** Building Cross-Platform Messaging Apps

---

## 🎯 What It Is

A native iOS chat application focused on simplicity, reliability, and a seamless user experience. It provides core messaging features, including one-on-one chats, group chats, and real-time synchronization, supported by robust offline capabilities.

---

## 👤 User Flow & Key Stories

The user journey is designed to be intuitive, from onboarding to active communication.

1.  **Onboarding:** A new user downloads the app, signs up for an account (using email/password or social auth), and logs in.
2.  **Home (Conversation List):** The user lands on a list of their existing conversations. They can see the most recent message from each chat, along with timestamps and the online/offline status of other users.
3.  **Initiate Chat:** The user can start a new conversation by selecting one user (for a 1-on-1 chat) or multiple users (for a group chat) from a contact list.
4.  **Conversation:** The user enters a chat screen.
    * They can type and send messages.
    * Messages appear instantly in the UI (**Optimistic UI**).
    * They see new messages arrive in **real-time**.
    * They can see **timestamps** for all messages.
    * They can see **read receipts** (e.g., "Read" or "Seen") under their sent messages.
5.  **Offline & Background:**
    * If the user closes the app, they receive **push notifications** for new messages.
    * If the user opens the app while offline, they can still read all **persisted** (downloaded) messages. They can also send new messages, which will be queued and sent automatically when they reconnect.

### Key User Story

* **Feature:** One-on-one Chat
* **Story:** "As a user, I want to select another user from my contacts and start a private, one-on-one conversation so that I can communicate with them directly and securely."

---

## 📐 Technical Specs

### iOS Native Framework: SwiftUI vs. UIKit

For this project, **SwiftUI is the recommended choice**.

* **SwiftUI:** A modern, declarative framework. You describe *what* your UI should look like, and the system handles *how* to make it happen.
    * **Pros:**
        * **Faster Development:** Requires significantly less code to build complex UIs.
        * **Data Binding:** Natively built to react to data changes, which is perfect for a real-time chat app (e.g., a new message automatically updates the view).
        * **Modern & Future-Proof:** This is the future of iOS development.
        * **Cross-Platform:** Aligns with the "Building Cross-Platform Messaging Apps" tagline, as SwiftUI code can be shared across iOS, iPadOS, macOS, and watchOS.
    * **Cons:**
        * **Minimum Target:** Requires iOS 13 or later (which has >90% market adoption in 2025).
        * **Less Mature:** Some highly complex, specific UI controls might still require falling back to a UIKit component.

**SwiftUI**. The speed of development and its native data-binding capabilities are ideal for a chat app where the UI must constantly react to new data.

### Technology Stack for Requirements

The most efficient way to meet all 10 hard requirements is by using a Backend-as-a-Service (BaaS) like **Firebase**, which bundles most of these features.

1.  **One-on-one Chat Functionality:**
    * **Tech:** **Firestore Database**. This is achieved by creating a "chat" document in a `chats` collection that contains a `members` array with the two user IDs.

    Service: FirebaseService?

2.  **Real-time Message Delivery (2+ users):**
    * **Tech:** **Firestore Snapshot Listeners**. On the client (SwiftUI), we will use `addSnapshotListener` to "listen" to the `messages` sub-collection for a specific chat. Any new message added to the database will be pushed to all listening clients instantly.

    Service: MessageService?

3.  **Message Persistence (Survives App Restarts):**
    * **Tech:** **Firestore Offline Cache**. By enabling `isPersistenceEnabled = true`, the Firebase SDK automatically caches all fetched data locally. This means the app can be restarted without an internet connection and still display all previously loaded conversations and messages.

    Service: 

4.  **Optimistic UI Updates:**
    * **Tech:** **SwiftUI State Management**. This is a client-side pattern.
        1.  User taps "Send."
        2.  The message is *immediately* added to the local SwiftUI `@State` array that powers the UI (marked as "sending...").
        3.  *Then*, the app makes the asynchronous call to write the message to Firestore.
        4.  When Firestore confirms the write, the local message's status is updated from "sending..." to "delivered" (or shows a timestamp).

5.  **Online/Offline Status Indicators:**
    * **Tech:** **Firebase Realtime Database (Presence)**. While Firestore is our main database, Firebase's *Realtime Database* has a superior `onDisconnect` hook. We will use this small part of Firebase to write a user's status (`online`) and set an `onDisconnect` trigger to automatically write `offline` if the app disconnects uncleanly.

6.  **Message Timestamps:**
    * **Tech:** **Firestore Server Timestamps**. When creating a message document, we will use `FieldValue.serverTimestamp()`. This ensures the timestamp is set by Google's servers, not the user's device, preventing time-sync issues across different time zones or if a user's clock is wrong.

7.  **User Authentication (Accounts/Profiles):**
    * **Tech:** **Firebase Authentication**. This service provides a complete, secure solution for user sign-up, log-in, password reset, and session management (including providers like Apple Sign-In and Google Sign-In).

8.  **Basic Group Chat Functionality (3+ users):**
    * **Tech:** **Firestore**. The data model is identical to a 1-on-1 chat. A "chat" document is created, but the `members` array simply contains 3+ user IDs instead of just two. All real-time and persistence logic works exactly the same.

9.  **Message Read Receipts:**
    * **Tech:** **Firestore Field Updates**. When a user *views* a message, the client will update the message document in Firestore. A simple way is to add a `readBy: [UserID]` array to the message document. When User B reads a message, User B's ID is added to that array. The UI can then check if that array contains the *other* user's ID.

10. **Push Notifications (Foreground):**
    * **Tech:** **Firebase Cloud Messaging (FCM)** + **Apple Push Notification service (APNs)**.
        1.  The iOS app registers with APNs and gets a device token, which is sent to FCM.
        2.  We will use **Cloud Functions** (serverless backend code) triggered by a new message write in Firestore.
        3.  This function will craft a notification payload and use FCM to send it to the correct device tokens for all other members of the chat.

---

## 📊 Database Schema (Firestore NoSQL)

This is a simplified NoSQL structure.

* `users` (Collection)
    * `{userID}` (Document)
        * `uid`: "string"
        * `displayName`: "string"
        * `email`: "string"
        * `profilePhotoURL`: "string" (optional)

* `chats` (Collection)
    * `{chatID}` (Document)
        * `members`: ["userID_A", "userID_B", "userID_C"] (Array of user IDs)
        * `lastMessage`: "string" (for preview in chat list)
        * `lastMessageTimestamp`: Timestamp
        * `isGroupChat`: true/false

    * `messages` (Sub-collection under each `chatID` document)
        * `{messageID}` (Document)
            * `text`: "string"
            * `senderID`: "string"
            * `timestamp`: Timestamp (from `FieldValue.serverTimestamp()`)
            * `readBy`: ["userID_A", "userID_B"] (Array of user IDs who have read it)

---

## 🚀 Implementation Plan (Milestones)

* **Phase 1: Core Foundation**
    * Setup Firebase project (Auth, Firestore, FCM).
    * Implement User Authentication (Sign up, Log in, Log out).
    * Create basic SwiftUI app structure and navigation.
    * Build `users` collection and basic user profile model.

* **Phase 2: 1-on-1 Chat**
    * Build the Conversation List screen (displays `chats`).
    * Build the Chat View screen (displays `messages`).
    * Implement real-time message sending/receiving using Firestore listeners.
    * Implement Optimistic UI and server timestamps.
    * Implement Firestore offline persistence.

* **Phase 3: Group Chats & Presence**
    * Implement "Create New Chat" flow (selecting 1 or 3+ users).
    * Ensure group chat logic works (sending to N members).
    * Integrate Firebase Realtime Database for online/offline presence indicators.

* **Phase 4: Polish & Notifications**
    * Implement message read receipts logic (client-side and Firestore updates).
    * Configure APNs and Firebase Cloud Messaging.
    * Write and deploy Cloud Function to trigger push notifications.
    * Test notifications (foreground, background, terminated).
    * Bug fixing and UI polish.

---

## 🎯 Success Criteria

### Must Have (P0 - MVP)

These are the non-negotiable features for launch, corresponding to the 10 hard requirements.

* ✅ Users can successfully create an account and log in.
* ✅ Users can start and participate in 1-on-1 conversations.
* ✅ Users can start and participate in group (3+ user) conversations.
* ✅ New messages are delivered in real-time (sub-3-second latency) to all participants.
* ✅ Messages are persisted locally; all chats are viewable on app restart with no internet.
* ✅ Sent messages appear in the UI instantly (Optimistic UI).
* ✅ Users can see "online" or "offline" status for other users.
* ✅ All messages display an accurate, server-synced timestamp.
* ✅ Users can see "Read" receipts on messages they have sent.
* ✅ Users receive a push notification when the app is in the foreground or background.

### Should Have (P1)

* Users can see an "is typing..." indicator.
* Users can edit their display name and profile picture.
* Users can search their contact list to start a new chat.

### Could Have (P2)

* Image and media message sharing.
* Emoji reactions to messages.
* Search conversation history.