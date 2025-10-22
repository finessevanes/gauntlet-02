# Technical Backlog

This document tracks deferred items and "we'll get back to this" tasks that are intentionally postponed to maintain development velocity.

**Last Updated**: October 21, 2025

---

## 🧪 Deferred Testing

**📋 Testing Strategy**: See [Testing Strategy & Recommendations](testing-strategy.md) for comprehensive testing approach, current manual testing standards, and future automated testing roadmap.

### Integration Testing (End-to-End)
**Deferred from**: PR #3  
**Priority**: High  
**Target**: Phase 4 (PR #25 - Testing & QA)

**Description:**
Full integration tests that span multiple services and Firebase integrations. These are critical for production readiness but deferred during feature development to maintain velocity.

**Specific Items:**
- [ ] **Auth + Firestore Integration** (PR #3)
  - Test signup flow creates both Firebase Auth account AND Firestore user document
  - Verify Auth UID matches Firestore document ID
  - Verify email from Auth matches Firestore email field
  - Test race conditions (what if Firestore write fails but Auth succeeds?)

- [ ] **End-to-End Multi-Device Sync** (PR #3)
  - Device A updates profile → Device B sees update in < 100ms
  - Test with 3+ simultaneous devices
  - Verify offline queueing and sync on reconnect

- [ ] **Security Rules Comprehensive Testing** (PR #3)
  - Test all Firestore security rules with different user contexts
  - Verify unauthorized users cannot access restricted data
  - Test edge cases (deleted users, malformed data, etc.)

- [ ] **UserService Integration Tests with Firebase Emulator** (PR #3)
  - Current tests only validate error types, model encoding, and input validation
  - Need real Firestore integration tests with emulator:
    - createUser() actually writes to Firestore and returns correct data
    - getUser() fetches from Firestore and caches correctly
    - updateUser() persists changes and invalidates cache
    - observeUser() real-time listener receives updates
    - getUsers() batch fetch handles partial failures
    - Offline persistence returns cached data
    - Performance metrics (< 300ms create, < 200ms fetch, < 50ms cache hit)
  - Setup: Configure Firebase emulator suite
  - Use Swift Testing framework with emulator connection

**Notes:**
- These tests require Firebase emulator setup or dedicated test Firebase project
- Should use XCTest for UI-driven integration tests
- Consider using Firebase Test Lab for multi-device testing
- Document test data setup and teardown procedures

---

### Unit Tests - Navigation Structure (PR #4)
**Deferred from**: PR #4 (App Navigation Structure)
**Priority**: Medium
**Target**: Phase 4 (PR #25 - Testing & QA) or dedicated testing sprint

**Description:**
Unit and integration tests for core navigation infrastructure including RootView, MainTabView, and authentication-based navigation flows. Deferred to focus on feature delivery and allow navigation patterns to stabilize before writing tests.

**Specific Items:**

- [ ] **RootView Auth State Tests**
  - Test RootView displays LoginView when `isAuthenticated = false`
  - Test RootView displays MainTabView when `isAuthenticated = true`
  - Test navigation updates when auth state changes dynamically
  - Mock AuthViewModel to verify conditional rendering logic

- [ ] **MainTabView State Tests**
  - Test tab selection state changes correctly
  - Test all 3 tabs are properly configured
  - Test tab state persistence (if implemented)
  - Verify TabView initialization and lifecycle

- [ ] **Placeholder View Tests**
  - Test each placeholder view renders correctly (ConversationListView, ProfileView, SettingsView)
  - Verify SF Symbols and text display
  - Test logout button functionality in SettingsView

- [ ] **End-to-End Navigation Flow Tests (Integration)**
  - Test complete login → main app → logout → login cycle
  - Test tab navigation with actual FirebaseAuth integration
  - Test navigation state persistence across app lifecycle
  - Test memory management across multiple navigation cycles

- [ ] **UI Tests (SwiftUI Testing)**
  - Automated UI testing of navigation flows
  - Accessibility testing for navigation components
  - Screenshot testing for visual regression

**Rationale for Deferral:**
- Focus on delivering working navigation infrastructure first
- Manual testing is sufficient for foundational UI work that requires human UX validation
- Automated tests more valuable once navigation patterns are stable and features are built on top
- Avoid test rework as navigation patterns may evolve in Phase 2-3

**Manual Testing:**
- Comprehensive manual testing scenarios documented in PR #4 PRD Section 12
- All acceptance gates validated through manual testing

**Notes:**
- Use Swift Testing framework for unit tests
- Consider SwiftUI Preview testing for quick view validation
- Set up proper mocking infrastructure for AuthViewModel before writing tests

---

## 🎨 UI/UX Improvements

### Login & Signup Form Redesign
**Deferred from**: Current implementation
**Priority**: Medium
**Target**: Phase 2 or dedicated UI polish sprint

**Description:**
The current login and signup forms are cluttered and need a UI/UX refresh to improve usability and visual design. Forms should be streamlined, with better spacing, clearer visual hierarchy, and improved user experience.

**Specific Items:**
- [ ] Simplify form layout and reduce visual clutter
- [ ] Improve spacing and alignment between form elements
- [ ] Enhance input field styling and labels
- [ ] Review and improve error message display
- [ ] Consider separating login/signup into distinct flows if combined
- [ ] Add proper form validation feedback
- [ ] Improve button styling and placement
- [ ] Review accessibility (VoiceOver, Dynamic Type support)

**Notes:**
- Consider conducting user testing before finalizing redesign
- Review iOS Human Interface Guidelines for form best practices
- Ensure consistency with overall app design system

---

## 🤔 Open Questions / Design Decisions

### Presence Indicator in Airplane Mode
**Added**: October 21, 2025  
**Priority**: Medium  
**Relates to**: PR #7 (User Presence System)

**Question:**
Should a user see a green presence indicator (online status) for other users in their chat when they themselves are in airplane mode?

**Context:**
- User is offline (airplane mode, no network)
- They open a chat with another user
- Should they see that other user's last known presence state (e.g., green = online)?
- Or should all presence indicators be hidden/grayed out when the local user is offline?

**Considerations:**
- **Show Last Known State (Pros):**
  - Provides context even when offline
  - User can see who was recently online
  - Less jarring when connectivity restored
  
- **Show Last Known State (Cons):**
  - May be misleading (stale data, other user may have gone offline)
  - Could cause confusion about message delivery expectations
  
- **Hide/Gray Out All Indicators (Pros):**
  - Clearly communicates that presence data is not current
  - Avoids misleading users about delivery expectations
  - Aligns with network unavailability
  
- **Hide/Gray Out All Indicators (Cons):**
  - Loses context of who was recently online
  - More work to implement distinct "offline mode" UI state

**Decision Needed:**
- [ ] Determine desired behavior for presence indicators when user is offline
- [ ] Consider if this should be different for "last seen" vs "active now" states
- [ ] Update PresenceService and PresenceIndicator accordingly
- [ ] Document decision in PR #7 or follow-up PR

**Notes:**
- Consider how other messaging apps handle this (WhatsApp, iMessage, Signal)
- May want user feedback/testing to inform decision
- Could start with simpler approach and iterate based on user behavior

---

## 🎯 How to Use This Backlog

### Adding Items
When deferring work during a PR:
1. Add item to appropriate section with clear description
2. Reference source PR (e.g., "Deferred from PR #3")
3. Assign priority (High/Medium/Low)
4. Add to relevant PRD's "Out-of-Scope" section

### Completing Items
- Move completed items to "Done" section below
- Archive items if no longer relevant

---

## ✅ Done (Completed Backlog Items)

*(Items will move here when completed)*
