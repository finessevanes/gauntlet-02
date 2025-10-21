# Testing Guidelines

**Current**: Manual testing validation (see `agents/shared-standards.md`)  
**Future**: Comprehensive testing strategy in `../docs/testing-strategy.md`

Reference this when validating features through manual testing.

---

## Manual Testing Strategy

This project uses **manual testing validation** to ensure features work correctly:

### Configuration Testing
- **Purpose**: Verify all Firebase services are properly connected
- **What to test**: Authentication, Firestore, FCM, environment variables
- **Success criteria**: All services respond correctly, no connection errors

### User Flow Testing
- **Purpose**: Verify complete user journeys work end-to-end
- **What to test**: Happy path scenarios, edge cases, error handling
- **Success criteria**: Users can complete intended actions successfully

### Multi-Device Testing
- **Purpose**: Verify real-time sync works across devices
- **What to test**: Message sync, presence indicators, concurrent actions
- **Success criteria**: Changes appear on all devices within 100ms

### Offline Behavior Testing
- **Purpose**: Verify app functions without internet connection
- **What to test**: Message queuing, offline functionality, reconnection
- **Success criteria**: App remains functional offline, syncs when reconnected

---

## Manual Testing Checklist

### 1. Configuration Testing ⭐ REQUIRED

**Purpose**: Verify Firebase services and environment setup

**What to test**:
- Firebase Authentication login/logout works
- Firestore database reads/writes succeed
- FCM push notifications configured
- All API keys and environment variables set correctly

**Success criteria**: No connection errors, all services respond properly

**Testing steps**:
1. Open app and attempt to sign in
2. Verify authentication succeeds without errors
3. Try to read/write data to Firestore
4. Check console for any Firebase connection errors
5. Verify all environment variables are loaded

---

### 2. User Flow Testing ⭐ REQUIRED

**Purpose**: Verify complete user journeys work end-to-end

**What to test**:
- Happy path: Complete main user journey from start to finish
- Edge cases: Invalid inputs, empty states, network issues
- Error handling: Network failures, permission errors, validation errors

**Success criteria**: Users can complete intended actions successfully

**Testing steps**:
1. **Happy Path**: Complete the main user flow without any issues
2. **Edge Cases**: 
   - Try submitting empty forms
   - Test with invalid data formats
   - Test with very long inputs
3. **Error Scenarios**:
   - Disconnect internet and try operations
   - Test with invalid permissions
   - Test with malformed data

---

### 3. Multi-Device Testing ⭐ REQUIRED

**Purpose**: Verify real-time sync works across devices

**What to test**:
- Message sync between devices
- Presence indicators (online/offline status)
- Concurrent actions from multiple devices
- Real-time updates

**Success criteria**: Changes appear on all devices within 100ms

**Testing steps**:
1. **Setup**: Open app on Device 1 (iPhone/Simulator)
2. **Setup**: Open app on Device 2 (different iPhone/Simulator)
3. **Test Sync**: Send message from Device 1, verify it appears on Device 2
4. **Test Reverse**: Send message from Device 2, verify it appears on Device 1
5. **Test Timing**: Use stopwatch to verify sync happens within 100ms
6. **Test Concurrent**: Send messages from both devices simultaneously
7. **Test Presence**: Verify online/offline indicators work correctly

---

### 4. Offline Behavior Testing ⭐ REQUIRED

**Purpose**: Verify app functions without internet connection

**What to test**:
- Message queuing when offline
- Offline functionality
- Reconnection and sync
- Data persistence

**Success criteria**: App remains functional offline, syncs when reconnected

**Testing steps**:
1. **Go Offline**: Disable internet connection (WiFi off, cellular off)
2. **Test Queuing**: Try to send messages (should queue locally)
3. **Test Offline Features**: Use any offline functionality
4. **Go Online**: Re-enable internet connection
5. **Verify Sync**: Check that queued messages send automatically
6. **Verify Real-time**: Test that real-time sync resumes

---

### 5. Visual States Verification ⭐ REQUIRED

**Purpose**: Verify all UI states render correctly

**What to test**:
- Empty states (no data)
- Loading states (data fetching)
- Error states (network errors, validation errors)
- Success states (completed actions)

**Success criteria**: All states display appropriate content and styling

**Testing steps**:
1. **Empty State**: Clear all data and verify empty state displays
2. **Loading State**: Trigger data loading and verify loading indicators
3. **Error State**: Trigger errors and verify error messages display
4. **Success State**: Complete actions and verify success feedback
5. **Visual Quality**: Check colors, fonts, spacing, animations look correct

---

### 6. Performance Testing ⭐ REQUIRED

**Purpose**: Verify performance targets are met

**What to test**:
- App load time
- Message delivery latency
- Scrolling performance
- UI responsiveness

**Success criteria**: Performance meets targets in shared-standards.md

**Testing steps**:
1. **Load Time**: Measure cold start to interactive UI (< 2-3 seconds)
2. **Message Latency**: Send message and measure delivery time (< 100ms)
3. **Scrolling**: Test with 100+ messages, verify smooth 60fps
4. **UI Response**: Test tap feedback (< 50ms response time)

---

## Testing Environment Setup

### Required Devices
- **Primary Device**: iPhone/Simulator for main testing
- **Secondary Device**: Different iPhone/Simulator for multi-device testing
- **Network Control**: Ability to disable/enable internet connection

### Testing Tools
- **Stopwatch**: For timing measurements (100ms sync, 2-3s load time)
- **Console**: For monitoring errors and Firebase connection status
- **Network Inspector**: For verifying Firebase connections

### Test Data
- **Clean State**: Start with fresh app installation
- **Test Accounts**: Use dedicated test user accounts
- **Test Content**: Use consistent test messages and data

---

## Manual Testing Best Practices

### Before Testing
- [ ] Ensure Firebase services are properly configured
- [ ] Clear app data for clean testing
- [ ] Have multiple devices ready for multi-device testing
- [ ] Prepare test data and scenarios

### During Testing
- [ ] Test systematically through each category
- [ ] Document any issues or unexpected behavior
- [ ] Take screenshots of visual issues
- [ ] Note timing measurements for performance tests

### After Testing
- [ ] Verify all acceptance gates pass
- [ ] Document any configuration issues found
- [ ] Clean up test data
- [ ] Report any bugs or issues discovered

---

## Common Issues & Solutions

### Issue: Firebase connection errors
**Check**: 
- GoogleService-Info.plist is properly configured
- Firebase project settings match app bundle ID
- Network connectivity is working

### Issue: Real-time sync slow
**Check**:
- Firebase project is in same region as users
- Firestore indexes are properly configured
- Network latency between devices

### Issue: App crashes during testing
**Check**:
- Console logs for error details
- Firebase service configuration
- Memory usage during testing

### Issue: Visual elements not displaying
**Check**:
- SwiftUI preview rendering
- Asset catalog configuration
- Font and color resources

---

## Testing Completion Criteria

**Feature is ready when ALL of the following pass:**

- [ ] **Configuration**: All Firebase services connected and working
- [ ] **Happy Path**: Main user flow works from start to finish
- [ ] **Edge Cases**: Invalid inputs handled gracefully
- [ ] **Multi-Device**: Real-time sync works across 2+ devices
- [ ] **Offline**: App functions properly without internet
- [ ] **Performance**: App loads quickly, smooth scrolling, fast sync
- [ ] **Visual States**: All UI states (empty, loading, error, success) display correctly
- [ ] **No Console Errors**: Clean console output during testing

---

## Notes

- **Visual appearance** (colors, spacing, fonts, animations) is verified manually by user
- **Performance measurements** should be done with realistic data loads
- **Multi-device testing** requires physical devices or multiple simulators
- **Offline testing** requires ability to control network connectivity
- All testing is done manually by the user to verify functionality works correctly