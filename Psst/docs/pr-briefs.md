# PR Briefs

This document contains high-level briefs for all Pull Requests in the Psst messaging app project. Each PR represents a logical, vertical slice of functionality that can be completed in 1-3 days.

**Status:** 🎯 9 In Progress/Todo

---

## 🎯 Todo / In Progress

### Phase 1: MVP Polish & UX Enhancement (Ordered by Criticality)

#### PR #001: profile-photo-upload-reliability-fix

**Brief:** Fix critical user experience issues with profile photo handling: (1) New users unable to upload profile photos on first attempt, requiring multiple retries due to threading problems in ProfilePhotoPicker, compression logic failures in UserService.uploadProfilePhoto(), insufficient error handling, potential Firebase Storage permission issues, and lack of network state validation. (2) Profile photos load every time the app opens instead of being cached, creating jarring loading experiences for users. (3) Add the ability for users to update AND delete their profile pictures (removing the photo and clearing the URL from Firestore). Implement comprehensive error handling with user-friendly error messages, add network connectivity checks before uploads, improve threading safety in image processing pipeline, add retry mechanisms for failed uploads, enhance compression logic with better error handling, add detailed logging for debugging upload failures, and implement local image caching with proper cache invalidation so profile photos load instantly from cache when available with background refresh for updated photos. Ensure the fix works reliably for all image types and sizes while maintaining the existing compression and storage security rules. NOTE: All profile photo editing functionality (upload, update, delete) should exist ONLY in the Profile tab, not in Settings.

**Dependencies:** PR #17 (user profile editing)

**Complexity:** Medium

**Phase:** 1 (MVP Polish)

**Status:** ✅ COMPLETED

---

#### PR #002: message-delivery-status-indicator-fix

**Brief:** Fix the "Delivered" status indicator to only show on the latest message instead of appearing under every message bubble, matching iOS Messages behavior. Currently, the delivery status appears under all sent messages which creates visual clutter and doesn't follow standard messaging app patterns. Implement logic to track the latest message in each conversation and only display the delivery status indicator on that message, automatically moving the indicator to newer messages as they are sent. This creates a cleaner, more professional chat experience that follows iOS design patterns.

**Dependencies:** PR #7 (chat view UI), PR #8 (messaging service)

**Complexity:** Medium

**Phase:** 1 (MVP Polish)

**Status:** ✅ COMPLETED

---

#### PR #003: presence-indicator-redesign-and-unread-badges

**Brief:** Redesign the presence indicator system to use a halo effect around user profile photos instead of the current online/offline circle. Implement unread message indicators that show a blue halo or badge when there are unread messages in a chat. Update the presence system to be more visually appealing and intuitive, with the halo effect providing a cleaner, more modern look. Ensure the unread indicators are clearly visible and update in real-time as messages are read or received. This redesign should improve the overall visual hierarchy and make it easier for users to quickly identify who is online and which chats have unread messages.

**Dependencies:** PR #12 (presence system), PR #14 (read receipts)

**Complexity:** Medium

**Phase:** 1 (MVP Polish)

**Status:** ✅ COMPLETED

---

#### PR #004: group-online-indicators-and-member-status

**Brief:** Implement comprehensive group chat online indicators that show which members are currently online, following WhatsApp/Signal conventions. Currently, the presence system only works for one user at a time, making it difficult to know who's active in group conversations. Add group member online status indicators that display next to each member's name in the group chat header or member list. Show a small green dot or halo effect for online members and gray for offline members. Implement real-time updates so the online status changes immediately when members come online or go offline. This should work seamlessly with the existing presence system and provide clear visual feedback about group activity.

**Dependencies:** PR #12 (presence system), PR #11 (group chat support)

**Complexity:** Medium

**Phase:** 1 (MVP Polish)

**Status:** ✅ COMPLETED

---

#### PR #005: group-read-receipts-detailed-view

**Brief:** Replace the generic "1/2 have read" read receipt display with detailed information showing exactly who has read each message in group chats. Currently, users only see a count of who has read messages, but not the specific names. Implement a detailed read receipt system that shows individual member names who have read each message, similar to WhatsApp's read receipt system. Allow users to tap on read receipts to see a detailed list of who has read the message and when. This should work for both sent and received messages, with clear visual indicators and smooth animations. The system should handle large groups efficiently and provide a professional, intuitive way to track message read status.

**Dependencies:** PR #14 (read receipts), PR #11 (group chat support)

**Complexity:** Medium

**Phase:** 1 (MVP Polish)

**Status:** ✅ COMPLETED

---

#### PR #006A: authentication-redesign-clean-ios-patterns

**Brief:** Redesign all authentication screens (LoginView, SignUpView, EmailSignInView) to use clean iOS patterns instead of elaborate gradients and weather-app styling. Remove all custom gradient backgrounds, card containers, decorative shadows, and colored icon circles. Replace with clean white backgrounds using iOS system colors, standard text fields, and consistent button styling. Create a unified auth design system that matches the main app aesthetic with Signal-like simplicity. This sets the foundation for consistent design patterns across the entire app. All existing functionality remains - just presented with a cleaner, more trustworthy iOS-native appearance.

**Dependencies:** PR #2 (authentication flow)

**Complexity:** Medium

**Phase:** 1 (MVP Polish)

**Status:** 🎯 IN PROGRESS

---

#### PR #006B: main-app-ui-polish-conversations-profile

**Brief:** Polish the main app experience (Conversations tab and Profile tab) with improved visual hierarchy and better UX patterns. In Conversations: move "new message" button from nav bar to a Floating Action Button (FAB) for better discoverability and thumb-friendliness, increase avatar sizes (50pt → 56pt), add user avatar to nav bar, improve spacing and layout while keeping all existing features (online status, unread badges, sender names) functional. In Profile: increase profile photo size (120pt → 140pt), improve layout and visual hierarchy, ensure button styling matches new design system. Update tab bar with consistent blue accent color. The result is a more polished, professional main app experience following modern messaging app patterns.

**Dependencies:** PR #006A (authentication redesign - establishes design system)

**Complexity:** Medium

**Phase:** 1 (MVP Polish)

**Status:** 🎯 TODO

---

#### PR #006C: settings-redesign-ios-grouped-list

**Brief:** Complete redesign of the Settings tab from basic centered placeholder to professional iOS-style grouped list following native iOS Settings app patterns. Implement user info section at top with profile photo and email, create "Account" section with Edit Profile and Notifications links, add "Support" section with Help & Support and About links, and keep red destructive-style Log Out button. Use iOS List with grouped style, NavigationLink for navigation, Label with SF Symbols for icons, and proper section headers. This completes the app-wide design system overhaul by bringing Settings up to the same professional standard as the rest of the app.

**Dependencies:** PR #006B (main app polish - establishes tab bar styling)

**Complexity:** Medium

**Phase:** 1 (MVP Polish)

**Status:** 🎯 TODO

---

#### PR #007: app-launch-loading-screen-and-skeleton

**Brief:** Implement a smooth app launch experience by replacing the brief login screen flash with a proper loading screen or skeleton UI when users reopen the app. Currently, users who were previously logged in see the login screen for a second before being redirected to the main app, creating a jarring user experience. Create a loading screen with app branding, skeleton UI components that match the main app layout, and smooth transitions. The loading screen should appear immediately on app launch while Firebase Authentication checks the user's login status in the background. Once authentication is confirmed, smoothly transition to the main app without showing the login screen. This creates a more professional, seamless user experience that matches modern app standards.

**Dependencies:** PR #2 (authentication flow), PR #4 (app navigation)

**Complexity:** Medium

**Phase:** 1 (MVP Polish)

**Status:** 🎯 TODO

---

#### PR #008: message-timestamp-tap-to-reveal

**Brief:** Replace the current swipe gesture for viewing message timestamps with a simple tap interaction. Currently, users must swipe left or right on messages to reveal timestamps, which is not intuitive and can be difficult to discover. Implement a tap-to-reveal system where users can tap on any message to show its timestamp for a few seconds before it automatically fades back. This should work for both sent and received messages, with smooth animations for the timestamp appearance and disappearance. The timestamp should be clearly visible and positioned appropriately relative to the message bubble. This creates a more discoverable and user-friendly way to view message timing information, following modern messaging app patterns.

**Dependencies:** PR #7 (chat view UI), PR #8 (messaging service)

**Complexity:** Simple

**Phase:** 1 (MVP Polish)

**Status:** 🎯 TODO

---

#### PR #009: basic-media-support-and-image-messaging

**Brief:** Implement basic media support to allow users to send and receive images in conversations. This includes adding image picker functionality to the message input, uploading images to Firebase Storage, displaying images in chat messages, and handling image compression for optimal performance. Users should be able to select images from their photo library or take new photos with the camera. Implement proper image loading states, error handling for failed uploads, and thumbnail generation for better performance. Images should display inline within the chat conversation with proper sizing and aspect ratio handling. This basic media support is essential for a complete messaging experience and addresses a core requirement for modern messaging apps.

**Dependencies:** PR #8 (messaging service), PR #17 (user profile editing for image handling)

**Complexity:** Medium

**Phase:** 1 (MVP Polish)

**Status:** 🎯 TODO

---

## 📊 Summary

### Project Progress
- **Phase 1 (MVP Polish):** 🎯 0/9 Complete

### Overall Status
- **Total PRs:** 9
- **Completed:** 0 (0%)
- **Remaining:** 9 (100%)

---

Each PR is designed to deliver a complete, testable piece of functionality that builds incrementally toward a polished MVP before adding AI features.
