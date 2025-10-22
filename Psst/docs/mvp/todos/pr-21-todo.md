# PR-21 TODO — Message Status and Timestamp UI Polish

**Branch**: `feat/pr-21-message-status-and-timestamp-ui-polish`  
**Source PRD**: `Psst/docs/prds/pr-21-prd.md`  
**Owner (Agent)**: Caleb

---

## 0. Clarifying Questions & Assumptions

- **Questions**: None - requirements are clear from PRD
- **Assumptions** (confirm in PR if needed):
  - iOS Messages swipe behavior is the target UX pattern
  - "Delivered" text visibility issue is specific to real devices in dark mode
  - Swipe gestures should not interfere with message list scrolling

---

## 1. Setup

- [ ] Create branch `feat/pr-21-message-status-and-timestamp-ui-polish` from develop
- [ ] Read PRD thoroughly
- [ ] Read `Psst/agents/shared-standards.md` for patterns
- [ ] Confirm environment and test runner work
- [ ] Test current "Delivered" text visibility on real device in dark mode

---

## 2. Service Layer

No new service methods required. This enhancement uses existing message data.

- [ ] Verify existing MessageService methods work correctly
  - Test Gate: Message sending and receiving still works as expected
- [ ] Confirm no changes needed to service layer
  - Test Gate: All existing functionality preserved

---

## 3. Data Model & Rules

No changes to Firestore schema required. This is purely a UI enhancement.

- [ ] Confirm existing Message model is sufficient
  - Test Gate: Message data structure supports timestamp display
- [ ] Verify no new Firestore rules needed
  - Test Gate: Existing read/write permissions work correctly

---

## 4. UI Components

Create/modify SwiftUI views per PRD Section 10.

- [ ] Modify `Views/ChatList/MessageRow.swift`
  - Add swipe gesture handling for timestamp reveal
  - Implement left swipe for own messages, right swipe for others
  - Test Gate: SwiftUI Preview renders; zero console errors
- [ ] Update `Views/ChatList/ChatView.swift`
  - Modify message status display logic to show only on latest message
  - Test Gate: Status only appears under most recent sent message
- [ ] Enhance `Components/MessageStatusIndicator.swift`
  - Update to show status only on latest message
  - Fix dark mode visibility issue for "Delivered" text
  - Test Gate: "Delivered" text visible on real device in dark mode
- [ ] Create/update `Utilities/Date+Extensions.swift`
  - Add timestamp formatting for display (e.g., "2:30 PM", "Yesterday")
  - Test Gate: Timestamps format correctly for display

---

## 5. Integration & Real-Time

Reference requirements from `Psst/agents/shared-standards.md`.

- [ ] Verify Firebase service integration still works
  - Test Gate: Auth/Firestore configured and working
- [ ] Confirm real-time listeners still working
  - Test Gate: Data syncs across devices <100ms
- [ ] Verify offline persistence still works
  - Test Gate: App restarts work offline with cached data
- [ ] Test message status updates in real-time
  - Test Gate: Status changes appear on all connected devices

---

## 6. Testing Validation

**Current**: Manual testing validation (see `Psst/agents/shared-standards.md`)  
**Future**: Automated testing recommendations in `Psst/docs/testing-strategy.md`

- [ ] Configuration Testing
  - Test Gate: Firebase Authentication, Firestore, FCM all connected and working
  - Test Gate: All environment variables and API keys properly configured
  
- [ ] User Flow Testing
  - Test Gate: Send multiple messages, verify only latest shows "Delivered"
  - Test Gate: Swipe left on own messages reveals timestamp smoothly
  - Test Gate: Swipe right on other's messages reveals timestamp smoothly
  - Test Gate: Swipe gestures don't interfere with message list scrolling
  
- [ ] Multi-Device Testing
  - Test Gate: Real-time sync works across 2+ devices within 100ms
  - Test Gate: Status updates appear on all connected devices simultaneously
  - Test Gate: Swipe gestures work on all connected devices
  
- [ ] Offline Behavior Testing
  - Test Gate: App functions properly without internet connection
  - Test Gate: Message status updates work offline and sync when reconnected
  
- [ ] Visual States Verification
  - Test Gate: "Delivered" text visible on real device in dark mode
  - Test Gate: Timestamp animations smooth and responsive
  - Test Gate: No console errors during testing

---

## 7. Performance

Verify targets from `Psst/agents/shared-standards.md`.

- [ ] App load time < 2-3 seconds
  - Test Gate: Cold start to interactive measured
- [ ] Message latency < 100ms
  - Test Gate: Firebase calls measured
- [ ] Smooth 60fps scrolling with swipe animations
  - Test Gate: Use LazyVStack, verify with instruments
- [ ] Swipe gesture performance
  - Test Gate: Gestures respond smoothly without lag

---

## 8. Acceptance Gates

Check every gate from PRD Section 12:
- [ ] All happy path gates pass
- [ ] All edge case gates pass
- [ ] All multi-user gates pass
- [ ] All performance gates pass
- [ ] Dark mode visibility issue resolved

---

## 9. Documentation & PR

- [ ] Add inline code comments for swipe gesture handling
- [ ] Add comments for timestamp formatting logic
- [ ] Update README if needed
- [ ] Create PR description (use format from Psst/agents/caleb-agent.md)
- [ ] Verify with user before creating PR
- [ ] Open PR targeting develop branch
- [ ] Link PRD and TODO in PR description

---

## Copyable Checklist (for PR description)

```markdown
- [ ] Branch created from develop
- [ ] All TODO tasks completed
- [ ] Message status only shows on latest message
- [ ] Swipe gestures implemented with smooth animations
- [ ] "Delivered" text visible on real devices in dark mode
- [ ] Firebase integration verified (real-time sync, offline)
- [ ] Manual testing completed (configuration, user flows, multi-device, offline)
- [ ] Multi-device sync verified (<100ms)
- [ ] Performance targets met (see Psst/agents/shared-standards.md)
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
- **Critical**: Test "Delivered" text visibility on real devices in dark mode
- Focus on iOS Messages UX patterns for swipe gestures
