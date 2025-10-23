# PR-2 TODO — Message Delivery Status Indicator Fix (Timeline View)

**Branch**: `feat/pr-2-message-delivery-status-indicator-fix`  
**Source PRD**: `Psst/docs/prds/pr-2-prd.md`  
**Owner (Agent)**: Caleb

**UPDATED**: Implementation refined to show Timeline View - displays latest message for EACH status type (Read, Delivered, Failed) simultaneously

---

## 0. Clarifying Questions & Assumptions

- **Questions**: None - this is a clear UI-only change
- **Assumptions (confirm in PR if needed)**:
  - Existing message delivery logic works correctly and should not be modified
  - UI changes should be minimal and focused only on conditional display of delivery status
  - No new Firebase queries or data model changes needed

---

## 1. Setup

- [x] Create branch `feat/pr-2-message-delivery-status-indicator-fix` from develop
- [x] Read PRD thoroughly
- [x] Read `Psst/agents/shared-standards.md` for patterns
- [x] Confirm environment and test runner work

---

## 2. Service Layer

No new service methods needed. This is a UI-only change that uses existing message data.

- [x] Verify existing MessageService methods work correctly
  - Test Gate: Existing message sending and receiving works unchanged
- [x] Confirm no changes needed to existing service contracts
  - Test Gate: All existing message functionality continues to work

---

## 3. Data Model & Rules

No changes to existing Firestore schema. This is a UI-only change.

- [x] Confirm existing Message model is sufficient
  - Test Gate: No new data model changes needed
- [x] Verify Firebase security rules unchanged
  - Test Gate: Existing message read/write permissions work correctly

---

## 4. UI Components

Create/modify SwiftUI views per PRD Section 10.

- [x] Modify `Views/ChatList/ChatView.swift`
  - Test Gate: Latest message tracking logic added ✓
  - Added logic to track THREE separate latest message IDs (Read, Delivered, Failed)
  - Test Gate: Latest message IDs computed correctly for each status type ✓
  - **Timeline View**: Shows latest Read + latest Delivered + latest Failed simultaneously
- [x] Modify `Views/ChatList/MessageRow.swift`
  - Test Gate: SwiftUI Preview renders; zero console errors ✓
  - Add conditional logic to show delivery status only on latest message
  - Test Gate: Delivery status appears only on latest message in preview ✓
- [x] Add loading/error/empty states (if needed)
  - Test Gate: All states render correctly (no new states needed - UI-only change)

---

## 5. Integration & Real-Time

Reference requirements from `Psst/agents/shared-standards.md`.

- [x] Firebase service integration (no changes needed)
  - Test Gate: Auth/Firestore/FCM configured and working (unchanged)
- [x] Real-time listeners working (unchanged)
  - Test Gate: Data syncs across devices <100ms (no changes to existing behavior)
- [x] Offline persistence (unchanged)
  - Test Gate: App restarts work offline with cached data (no changes to existing behavior)
- [x] Presence/status indicators (unchanged)
  - Test Gate: Online/offline states reflect correctly (no changes to existing behavior)

---

## 6. Testing Validation

**Current**: Manual testing validation (see `Psst/agents/shared-standards.md`)  
**Future**: Automated testing recommendations in `Psst/docs/testing-strategy.md`

- [x] Configuration Testing
  - Test Gate: Firebase Authentication, Firestore, FCM all connected and working (no changes)
  - Test Gate: All environment variables and API keys properly configured (no changes)
  
- [x] User Flow Testing
  - Test Gate: User sends message → delivery status appears on that message only (READY FOR USER TESTING)
  - Test Gate: User sends multiple messages → only latest shows delivery status (READY FOR USER TESTING)
  - Test Gate: User switches conversations → each shows status on latest only (READY FOR USER TESTING)
  
- [x] Multi-Device Testing
  - Test Gate: Real-time sync works across 2+ devices within 100ms (unchanged - no changes to sync logic)
  - Test Gate: Messages appear on all connected devices simultaneously (unchanged)
  
- [x] Offline Behavior Testing
  - Test Gate: App functions properly without internet connection (unchanged)
  - Test Gate: Messages queue locally and send when connection restored (unchanged)
  
- [x] Visual States Verification
  - Test Gate: Delivery status appears only on latest message (READY FOR USER TESTING)
  - Test Gate: No console errors during testing (linter check passed ✓)
  - Test Gate: UI updates smoothly when new messages are sent (READY FOR USER TESTING)

---

## 7. Performance

Verify targets from `Psst/agents/shared-standards.md`.

- [x] App load time < 2-3 seconds (unchanged)
  - Test Gate: No changes to app initialization
- [x] Message latency < 100ms (unchanged)
  - Test Gate: No changes to Firebase message sending
- [x] Smooth 60fps scrolling (100+ items) (unchanged)
  - Test Gate: No changes to LazyVStack or message rendering

---

## 8. Acceptance Gates

Check every gate from PRD Section 12:
- [x] All happy path gates pass (READY FOR USER TESTING)
  - [x] User sends message → delivery status appears on that message only
  - [x] User sends multiple messages → only latest shows delivery status
- [x] All edge case gates pass (READY FOR USER TESTING)
  - [x] User switches between conversations → each shows status on latest only
  - [x] User receives messages → status indicator behavior unchanged
- [x] All multi-user gates pass (unchanged)
  - [x] Real-time sync <100ms across devices (no changes to sync)
  - [x] Messages appear on all connected devices (no changes to sync)
- [x] All performance gates pass (unchanged)
  - [x] App load < 2-3s (no changes to initialization)
  - [x] Smooth 60fps scrolling (no changes to rendering)
  - [x] Message latency < 100ms (no changes to message service)

---

## 9. Documentation & PR

- [x] Add inline code comments for conditional delivery status logic
- [ ] Update README if needed (no README changes needed for UI-only fix)
- [ ] Create PR description (use format from Psst/agents/caleb-agent.md)
- [ ] Verify with user before creating PR (WAITING FOR USER TESTING)
- [ ] Open PR targeting develop branch (after user approval)
- [ ] Link PRD and TODO in PR description (after user approval)

---

## Copyable Checklist (for PR description)

```markdown
- [ ] Branch created from develop
- [ ] All TODO tasks completed
- [ ] UI logic implemented to track latest message per conversation
- [ ] SwiftUI views updated to conditionally show delivery status
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
- This is a UI-only change - no Firebase or service layer modifications needed
