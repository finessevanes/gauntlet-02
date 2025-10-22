# PRD: Push Notifications Setup

**Feature**: APNs and FCM Configuration [NOT STARTED]

**Version**: 1.0

**Status**: Ready for Development

**Agent**: Pam

**Target Release**: Phase 4

**Links**: 
- PR Brief: `Psst/docs/pr-briefs.md` (PR #15)
- TODO: `Psst/docs/todos/pr-15-todo.md` (to be created after PRD approval)

---

## 1. Summary

Configure Apple Push Notification service (APNs) and Firebase Cloud Messaging (FCM) to enable the iOS app to receive push notifications. This PR focuses on the infrastructure setup (device token registration, permissions, Xcode configuration) without implementing Cloud Functions or full notification handling logic—those will come in PR #16.

---

## 2. Problem & Goals

**Problem:** Users currently have no way to receive notifications when new messages arrive while the app is in the background or terminated. Without push notifications, users miss important messages and engagement drops significantly.

**Why now:** Phase 4 is focused on polish and notifications. Push notification setup is a prerequisite for PR #16 (Cloud Functions and notification handling), which completes the full notification pipeline.

**Goals:**
- [ ] G1 — Successfully register iOS app with APNs and receive device tokens
- [ ] G2 — Store device tokens in Firestore user documents for later use by Cloud Functions
- [ ] G3 — Request and handle notification permissions with proper user prompts
- [ ] G4 — Test basic notification delivery from Firebase Console to verify setup

---

## 3. Non-Goals / Out of Scope

These features are intentionally excluded to avoid scope creep:

- [ ] Cloud Functions to trigger notifications on new messages (PR #16)
- [ ] Deep linking from notifications to specific chats (PR #16)
- [ ] Notification badge count management (PR #16)
- [ ] Notification content customization (rich media, actions) (PR #16)
- [ ] Local notifications (we're only doing push from server)
- [ ] Notification settings/preferences UI (future enhancement)
- [ ] Silent notifications or background fetch (future enhancement)

---

## 4. Success Metrics

Reference `Psst/agents/shared-standards.md` for metric templates:

**User-visible:**
- Time to grant notification permission: < 5 seconds from prompt
- Success rate of permission grant: Track for analytics
- Time for token refresh on app launch: < 2 seconds

**System:**
- APNs registration success rate: > 99%
- Device token stored in Firestore: 100% of successful registrations
- Token refresh on app lifecycle events: Works reliably
- Test notification delivery from Firebase Console: 100% success

**Quality:**
- 0 blocking bugs in permission flow
- All acceptance gates pass
- Crash-free rate > 99.9%
- No permission prompt loops or errors

---

## 5. Users & Stories

**Primary User:** Any authenticated app user who wants to stay updated on messages

**User Stories:**

1. As a user, I want to be asked for notification permission when I first log in, so I can choose whether to receive alerts about new messages.

2. As a user, I want the app to handle my notification preferences gracefully, so if I deny permission initially, I can still use the app without errors.

3. As a developer, I want device tokens automatically registered and refreshed, so users always receive notifications without manual intervention.

4. As a developer, I want to test notification delivery from Firebase Console before building Cloud Functions, so I can verify the infrastructure works correctly.

5. As a system, I want to automatically refresh device tokens when they expire or change, so notifications continue working after iOS updates or app reinstalls.

---

## 6. Experience Specification (UX)

### Entry Points and Flows

**Permission Request Flow:**
1. User completes authentication (PR #2) and enters main app
2. On first launch after login, system requests notification permission
3. iOS shows native permission alert: "Psst would like to send you notifications"
4. User taps "Allow" or "Don't Allow"
5. App continues to main screen regardless of choice

**Token Registration Flow (Background):**
1. If permission granted: App registers with APNs automatically
2. APNs returns device token
3. App uploads token to Firebase via FCM SDK
4. Token stored in user's Firestore document under `fcmToken` field

**Token Refresh Flow (Background):**
1. On every app launch, check if FCM token needs refresh
2. If refreshed, update Firestore user document with new token
3. Handle edge cases: app reinstall, iOS version upgrade, etc.

### Visual Behavior

**Permission Prompt:**
- Native iOS alert (system-controlled, cannot be customized)
- Clear messaging: "Allow Psst to send you notifications?"
- Two buttons: "Don't Allow" | "Allow"

**No Custom UI Required:**
- This PR focuses on backend setup
- All UI is native iOS permission dialogs
- No loading states or custom screens

### States

**Permission States:**
- **Not Determined:** User hasn't been asked yet (initial state)
- **Denied:** User explicitly declined permission
- **Authorized:** User granted permission
- **Provisional:** (iOS 12+) Quiet notifications without explicit permission

**Registration States:**
- **Registering:** App is requesting device token from APNs
- **Registered:** Successfully received and stored token
- **Failed:** APNs registration failed (handle gracefully)

### Performance

See targets in `Psst/agents/shared-standards.md`:
- Permission request: Immediate (< 100ms to show prompt)
- Token registration: < 2 seconds after permission grant
- Token upload to Firestore: < 1 second
- Token refresh on app launch: < 2 seconds (background, non-blocking)

---

## 7. Functional Requirements (Must/Should)

### MUST Requirements

**M1: Xcode Configuration**
- MUST: Add "Push Notifications" capability in Xcode project settings
- MUST: Add "Background Modes" capability and enable "Remote notifications"
- MUST: Configure provisioning profile with push notification entitlement
- MUST: Register app identifier with APNs in Apple Developer Portal
- [Gate] Xcode builds successfully with push capabilities enabled
- [Gate] No entitlement errors in console logs

**M2: Notification Permission Request**
- MUST: Request notification permission on first app launch after authentication
- MUST: Use `UNUserNotificationCenter.requestAuthorization` with appropriate options
- MUST: Handle all permission states (authorized, denied, not determined)
- MUST: Never request permission more than once (respect user's choice)
- [Gate] Permission prompt appears exactly once per user
- [Gate] App continues functioning if permission denied
- [Gate] No crashes or errors regardless of permission choice

**M3: APNs Device Token Registration**
- MUST: Call `UIApplication.registerForRemoteNotifications()` after permission granted
- MUST: Implement `didRegisterForRemoteNotificationsWithDeviceToken` callback
- MUST: Implement `didFailToRegisterForRemoteNotificationsWithError` callback
- MUST: Handle registration failures gracefully with error logging
- [Gate] Device token received successfully when permission granted
- [Gate] Error logged if registration fails (for debugging)
- [Gate] No app crashes on registration failure

**M4: FCM Token Integration**
- MUST: Configure Firebase Cloud Messaging SDK in project
- MUST: Let FCM SDK automatically exchange APNs token for FCM token
- MUST: Implement FCM token refresh callback via MessagingDelegate
- MUST: Log FCM token to console for manual testing verification
- [Gate] FCM token generated successfully
- [Gate] Token logged to console (for copy/paste testing)
- [Gate] Token refreshes when needed

**M5: Token Storage in Firestore**
- MUST: Store FCM token in user's Firestore document under `fcmToken` field
- MUST: Update token in Firestore on every refresh
- MUST: Write token atomically (no partial updates)
- MUST: Handle Firestore write errors gracefully
- [Gate] Token successfully written to `users/{uid}/fcmToken` field
- [Gate] Token updates correctly on refresh
- [Gate] No Firestore errors block app functionality

**M6: Token Refresh Lifecycle**
- MUST: Check and refresh token on every app launch (foreground)
- MUST: Refresh token when Firebase Messaging reports change
- MUST: Refresh token after app reinstall
- MUST: Handle token refresh in background (non-blocking to UI)
- [Gate] Token updates after app reinstall
- [Gate] Token updates after iOS version upgrade
- [Gate] Token refresh doesn't block main thread

### SHOULD Requirements

**S1: Error Handling**
- SHOULD: Log detailed errors for APNs registration failures
- SHOULD: Log detailed errors for Firestore token write failures
- SHOULD: Provide helpful debugging information in console

**S2: Testing Support**
- SHOULD: Provide easy way to copy FCM token from console
- SHOULD: Log all token lifecycle events for debugging

---

## 8. Data Model

### Firestore Schema Changes

**Collection:** `users`  
**Document:** `{userID}`

**New Field:**
```swift
fcmToken: String?  // Optional - FCM device token for push notifications
```

**Example User Document After Update:**
```swift
{
  uid: "user123",
  displayName: "Alice Smith",
  email: "alice@example.com",
  profilePhotoURL: "https://...",
  fcmToken: "fJ3k2l5m6n7o8p9q0r1s2t3u4v5w6x7y8z9..."  // NEW FIELD
}
```

### Validation Rules

**Field Constraints:**
- `fcmToken` is optional (nullable) - users might deny permission
- `fcmToken` is a string (Firebase Messaging token format)
- `fcmToken` can change over time (updates on refresh)
- No uniqueness constraint needed (same token shouldn't appear twice, but Firestore doesn't enforce)

**Security Rules Update:**
```javascript
// Firestore Security Rules
match /users/{userID} {
  allow read: if request.auth != null;
  allow write: if request.auth != null && request.auth.uid == userID;
  
  // Allow user to update their own fcmToken
  allow update: if request.auth != null 
                && request.auth.uid == userID
                && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['fcmToken']);
}
```

### Indexing/Queries

**No new indexes needed** - we'll only ever query FCM tokens by userID (document lookup), never across all users.

---

## 9. API / Service Contracts

### NotificationService

Create new service: `Services/NotificationService.swift`

```swift
class NotificationService: NSObject, ObservableObject {
    
    // MARK: - Properties
    @Published var isPermissionGranted: Bool = false
    @Published var fcmToken: String?
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupMessagingDelegate()
    }
    
    // MARK: - Permission Management
    
    /// Request notification permission from user
    /// Should be called once after authentication
    func requestPermission() async throws -> Bool
    
    /// Check current notification authorization status
    func checkPermissionStatus() async -> UNAuthorizationStatus
    
    // MARK: - Token Management
    
    /// Register for remote notifications with APNs
    func registerForPushNotifications()
    
    /// Handle successful APNs registration
    func didReceiveAPNsToken(_ token: Data)
    
    /// Handle APNs registration failure
    func didFailToRegister(error: Error)
    
    /// Handle FCM token refresh
    func didReceiveFCMToken(_ token: String)
    
    /// Store FCM token in Firestore user document
    func saveFCMTokenToFirestore(_ token: String) async throws
    
    /// Refresh FCM token (called on app launch)
    func refreshFCMToken() async
}
```

### Method Details

**requestPermission()**
- **Pre-conditions:** User is authenticated
- **Post-conditions:** Permission prompt shown to user
- **Returns:** Bool indicating if permission was granted
- **Errors:** Throws if permission check fails
- **Side effects:** Updates `isPermissionGranted` published property

**registerForPushNotifications()**
- **Pre-conditions:** Permission granted
- **Post-conditions:** APNs registration initiated
- **Returns:** Void
- **Errors:** Failures handled in delegate callback
- **Side effects:** Triggers APNs registration flow

**didReceiveFCMToken()**
- **Pre-conditions:** APNs token received and exchanged by FCM SDK
- **Post-conditions:** Token stored in Firestore
- **Parameters:** `token: String` - FCM device token
- **Returns:** Void
- **Errors:** Handled internally, logged to console
- **Side effects:** Writes to Firestore, updates `fcmToken` published property

**saveFCMTokenToFirestore()**
- **Pre-conditions:** User authenticated, valid FCM token
- **Post-conditions:** Token written to user document in Firestore
- **Parameters:** `token: String` - FCM device token
- **Returns:** Void
- **Errors:** Throws FirestoreError if write fails
- **Side effects:** Updates Firestore `users/{uid}/fcmToken` field

**refreshFCMToken()**
- **Pre-conditions:** App is active, user authenticated
- **Post-conditions:** Latest token retrieved and stored
- **Returns:** Void (async)
- **Errors:** Handled internally
- **Side effects:** May trigger token update in Firestore

---

## 10. UI Components to Create/Modify

### New Files

- `Services/NotificationService.swift` — Handles all push notification setup, token management, and permission requests

### Modified Files

- `PsstApp.swift` — Add FCM Messaging delegate setup and notification registration on app launch
- `Models/User.swift` — Add `fcmToken: String?` property to User model
- `Services/UserService.swift` — Update user document writes to support `fcmToken` field
- `ViewModels/AuthViewModel.swift` — Trigger permission request after successful authentication

### No UI Views Required

This PR is purely infrastructure—no custom SwiftUI views needed. All UI is native iOS permission prompts.

---

## 11. Integration Points

### Firebase Cloud Messaging (FCM)
- Add `FirebaseMessaging` SDK to project dependencies
- Configure messaging delegate to receive token updates
- Exchange APNs tokens for FCM tokens automatically

### Apple Push Notification service (APNs)
- Register app with Apple Developer Portal
- Add push notification capability in Xcode
- Handle APNs device token callbacks in AppDelegate

### Firestore
- Write FCM tokens to user documents
- Update tokens on refresh
- Handle write failures gracefully

### State Management (SwiftUI)
- Use `@ObservableObject` for NotificationService
- Publish `isPermissionGranted` and `fcmToken` states
- Inject NotificationService via `@EnvironmentObject` if needed

### App Lifecycle
- Request permissions after authentication
- Refresh tokens on app launch (foreground)
- Handle token updates in background

---

## 12. Testing Plan & Acceptance Gates

**Current**: Manual testing validation (see `Psst/agents/shared-standards.md`)  
**Future**: Automated testing recommendations in `Psst/docs/testing-strategy.md`

### Configuration Testing

- [ ] **Xcode Configuration**
  - Gate: "Push Notifications" capability enabled in Xcode
  - Gate: "Background Modes" capability enabled with "Remote notifications" checked
  - Gate: Provisioning profile includes push notification entitlement
  - Gate: App builds successfully without entitlement errors
  
- [ ] **Firebase Configuration**
  - Gate: Firebase Messaging SDK added to project
  - Gate: APNs authentication key uploaded to Firebase Console
  - Gate: Firebase Console shows app is configured for iOS push
  - Gate: No Firebase configuration errors in console logs

- [ ] **Apple Developer Portal**
  - Gate: App identifier registered with push notification capability
  - Gate: APNs key (.p8 file) generated and downloaded
  - Gate: Provisioning profile updated and downloaded

### Happy Path Testing

- [ ] **Permission Request Flow**
  - Gate: After login, permission prompt appears exactly once
  - Gate: User can tap "Allow" and permission is granted
  - Gate: `isPermissionGranted` state updates to true
  - Gate: No crashes or errors after permission grant
  
- [ ] **Token Registration Flow**
  - Gate: APNs device token received within 2 seconds of permission grant
  - Gate: APNs token logged to console (visible in Xcode debug logs)
  - Gate: FCM token generated and logged to console
  - Gate: FCM token stored in Firestore at `users/{uid}/fcmToken`
  - Gate: Token is non-empty string and properly formatted

- [ ] **Test Notification from Firebase Console**
  - Gate: Copy FCM token from console logs
  - Gate: Send test notification from Firebase Console → Notifications → New Notification
  - Gate: Notification received on device when app in foreground
  - Gate: Notification received on device when app in background
  - Gate: Notification received on device when app terminated

### Edge Cases Testing

- [ ] **Permission Denied**
  - Gate: User can tap "Don't Allow"
  - Gate: App continues to function normally (no crashes)
  - Gate: No infinite permission request loops
  - Gate: `isPermissionGranted` state updates to false
  - Gate: `fcmToken` remains nil in Firestore (or not written)
  
- [ ] **APNs Registration Failure**
  - Gate: If registration fails, error logged to console
  - Gate: Error is descriptive (shows reason for failure)
  - Gate: App doesn't crash on registration failure
  - Gate: User can still use app (messaging works without push)
  
- [ ] **Firestore Write Failure**
  - Gate: Simulate Firestore offline - token write fails gracefully
  - Gate: Error logged to console
  - Gate: App continues to function
  - Gate: Token write retried on next app launch

- [ ] **Token Already Exists**
  - Gate: Launch app multiple times
  - Gate: Token not duplicated in Firestore
  - Gate: Latest token overwrites old token correctly

### Multi-Device Testing

- [ ] **Token Unique Per Device**
  - Gate: Log in to same account on Device 1
  - Gate: Log in to same account on Device 2
  - Gate: Each device gets unique FCM token
  - Gate: Both tokens stored somewhere (NOTE: Current data model only stores one token per user—future enhancement needed for multi-device support)

### Offline Behavior Testing

- [ ] **Offline Token Storage**
  - Gate: Receive FCM token while online
  - Gate: Disable internet connection
  - Gate: Restart app
  - Gate: Token write queued (Firestore offline persistence)
  - Gate: Re-enable internet
  - Gate: Token write completes successfully

### Token Refresh Testing

- [ ] **Token Refresh on App Launch**
  - Gate: Close app completely (terminate)
  - Gate: Reopen app
  - Gate: FCM token refresh triggered in background
  - Gate: Token updated in Firestore if changed
  - Gate: Token refresh completes in < 2 seconds
  - Gate: Main thread not blocked during refresh

- [ ] **Token Refresh After Reinstall**
  - Gate: Note current FCM token from Firestore
  - Gate: Delete app from device
  - Gate: Reinstall app from Xcode
  - Gate: Log in with same account
  - Gate: New FCM token generated (different from previous)
  - Gate: New token stored in Firestore

### Performance Testing

- [ ] **Permission Request Performance**
  - Gate: Permission prompt appears in < 100ms after trigger
  - Gate: No UI lag or freezing
  
- [ ] **Token Registration Performance**
  - Gate: APNs registration completes in < 2 seconds
  - Gate: FCM token generation completes in < 2 seconds
  - Gate: Firestore write completes in < 1 second
  - Gate: Total flow (permission → token stored) completes in < 5 seconds

- [ ] **No Main Thread Blocking**
  - Gate: All network calls (Firestore writes) on background thread
  - Gate: App remains responsive during token registration
  - Gate: No ANR (Application Not Responding) warnings

### Visual States Verification

- [ ] **Permission Prompt**
  - Gate: Native iOS permission alert displays correctly
  - Gate: Alert text is clear: "Psst would like to send you notifications"
  - Gate: Buttons display correctly: "Don't Allow" and "Allow"

- [ ] **Console Logs**
  - Gate: Clear log message when FCM token received (e.g., "FCM Token: fJ3k2l5...")
  - Gate: Clear log message on token refresh (e.g., "FCM Token refreshed")
  - Gate: Clear error messages if registration fails
  - Gate: No excessive or spammy logs

---

## 13. Definition of Done

See standards in `Psst/agents/shared-standards.md`:

- [ ] Xcode project configured with push notification capabilities
- [ ] APNs key uploaded to Firebase Console
- [ ] NotificationService implemented with all required methods
- [ ] FCM token registration working and logged to console
- [ ] FCM token stored in Firestore user document
- [ ] Token refresh implemented on app launch
- [ ] Permission request flow working (grant and deny cases)
- [ ] Test notification successfully sent from Firebase Console
- [ ] Test notification received on device (foreground, background, terminated)
- [ ] All edge cases handled (permission denied, registration failure, Firestore errors)
- [ ] Token lifecycle tested (refresh, reinstall)
- [ ] All acceptance gates pass
- [ ] Manual testing completed (configuration, user flows, multi-device, offline)
- [ ] No crashes or console errors
- [ ] Code follows `Psst/agents/shared-standards.md` patterns
- [ ] Documentation updated (inline comments, README if needed)

---

## 14. Risks & Mitigations

**Risk 1: APNs Registration Failure (Simulator Issues)**
- **Problem:** iOS Simulator does not support push notifications—device tokens cannot be generated
- **Impact:** Cannot test full flow without physical device
- **Mitigation:** 
  - Always test on physical iOS device (iPhone/iPad)
  - Add clear console logs indicating simulator limitations
  - Document requirement for physical device testing in README
  - For CI/CD, mock token generation in unit tests

**Risk 2: Provisioning Profile / Entitlement Errors**
- **Problem:** Missing or incorrect push notification entitlements cause APNs registration to fail silently
- **Impact:** No device tokens generated, no notifications work
- **Mitigation:**
  - Follow Xcode prompts to automatically manage signing
  - Verify entitlements file contains push notification capability
  - Check Apple Developer Portal for app identifier configuration
  - Test with development AND production APNs certificates

**Risk 3: FCM Token Not Stored (Firestore Write Failure)**
- **Problem:** Firestore write fails due to network issues or security rules
- **Impact:** Token not stored, Cloud Functions can't send notifications
- **Mitigation:**
  - Implement retry logic for Firestore writes
  - Use Firestore offline persistence to queue writes
  - Log errors clearly to console for debugging
  - Verify Firestore security rules allow token writes

**Risk 4: Multiple Tokens Per User (Multi-Device)**
- **Problem:** Current data model stores only one `fcmToken` per user—doesn't support multiple devices
- **Impact:** If user logs in on two devices, second device overwrites first device's token
- **Mitigation:**
  - Document limitation in PRD and README
  - For MVP, accept single-device limitation
  - Future enhancement: Change `fcmToken` to `fcmTokens: [String]` array (PR #16 or later)

**Risk 5: Permission Denied - No Recovery Path**
- **Problem:** If user denies notification permission, there's no in-app way to re-prompt
- **Impact:** User must go to iOS Settings → Psst → Notifications to manually enable
- **Mitigation:**
  - Accept this iOS limitation for MVP
  - Future enhancement: Add "Enable Notifications" button in Settings screen that opens iOS Settings app
  - Display helpful message if permission denied: "To receive notifications, enable them in Settings"

---

## 15. Rollout & Telemetry

### Feature Flag
**No** - This is core infrastructure, not a user-facing feature that needs gradual rollout

### Metrics to Track
- **Permission Grant Rate:** % of users who grant notification permission
- **Token Registration Success Rate:** % of successful APNs registrations
- **Token Storage Success Rate:** % of successful Firestore writes
- **Test Notification Success Rate:** % of test notifications delivered

### Manual Validation Steps
1. Build app on physical iOS device
2. Authenticate with test account
3. Verify permission prompt appears
4. Grant permission
5. Check Xcode console for FCM token
6. Verify token stored in Firestore (Firebase Console → Firestore → users → {uid} → fcmToken)
7. Copy FCM token from console
8. Send test notification from Firebase Console
9. Verify notification received on device (foreground, background, terminated states)
10. Restart app - verify token refresh works
11. Reinstall app - verify new token generated and stored

---

## 16. Open Questions

**Q1: Should we support multiple FCM tokens per user (multi-device)?**
- **Answer:** Not in this PR. Current implementation stores single token. Multi-device support (storing array of tokens) deferred to future PR (likely PR #16 when building Cloud Functions).

**Q2: What happens if user denies permission?**
- **Answer:** App continues to function normally. Real-time messaging still works (Firestore listeners). User just won't receive push notifications when app is backgrounded/terminated.

**Q3: How do we test on iOS Simulator?**
- **Answer:** We can't—Simulator doesn't support APNs. Physical device required for full testing. For development, we can add mock token generation for simulator builds (DEBUG-only).

**Q4: Do we need to handle token expiration?**
- **Answer:** Yes—FCM SDK handles this automatically via MessagingDelegate token refresh callback. We just need to implement the callback and update Firestore.

**Q5: Should we request permission immediately after signup or wait?**
- **Answer:** Request on first app launch after authentication (best practice). Don't request during signup—users are more likely to grant permission after they've seen the app's value.

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future PRs:

- [ ] **Multi-device support** - Store array of FCM tokens instead of single token (PR #16 or later)
- [ ] **Settings screen** - UI to re-enable notifications if denied (Phase 4+)
- [ ] **Custom notification sounds** - App-specific notification sounds (Future)
- [ ] **Notification categories** - Custom actions on notifications (Future)
- [ ] **Rich notifications** - Images, videos in notifications (Future)
- [ ] **Silent notifications** - Background data sync (Future)
- [ ] **Local notifications** - Scheduled or triggered locally (Future)
- [ ] **Notification preferences** - Per-chat mute settings (Future)

---

## Preflight Questionnaire

1. **Smallest end-to-end user outcome for this PR?**
   - User receives a test notification from Firebase Console on their iOS device

2. **Primary user and critical action?**
   - Primary: Any authenticated user
   - Critical: Grant notification permission → Receive test notification

3. **Must-have vs nice-to-have?**
   - Must-have: APNs registration, FCM token storage, permission request, test notification
   - Nice-to-have: Multi-device support, settings UI, detailed analytics

4. **Real-time requirements?**
   - Token registration: < 2 seconds
   - Token storage: < 1 second
   - Token refresh: < 2 seconds (background, non-blocking)

5. **Performance constraints?**
   - Permission prompt: < 100ms
   - No main thread blocking during token registration
   - Token refresh on app launch: must not delay UI

6. **Error/edge cases to handle?**
   - Permission denied
   - APNs registration failure
   - Firestore write failure
   - Token refresh failure
   - Simulator (no APNs support)
   - App reinstall (new token)

7. **Data model changes?**
   - Add `fcmToken: String?` field to User model and Firestore schema

8. **Service APIs required?**
   - New NotificationService with token management methods

9. **UI entry points and states?**
   - No custom UI—native iOS permission prompt only

10. **Security/permissions implications?**
    - Requires "Push Notifications" capability in Xcode
    - Requires APNs key in Apple Developer Portal
    - Firestore security rules must allow users to update their own `fcmToken` field

11. **Dependencies or blocking integrations?**
    - Depends on PR #1 (Firebase setup)
    - Required for PR #16 (Cloud Functions and notification handling)

12. **Rollout strategy and metrics?**
    - No gradual rollout (core infrastructure)
    - Track permission grant rate, registration success rate, test notification delivery

13. **What is explicitly out of scope?**
    - Cloud Functions to trigger notifications (PR #16)
    - Deep linking from notifications (PR #16)
    - Notification badge management (PR #16)
    - Multi-device token storage (Future)
    - Settings UI for notification preferences (Future)

---

## Authoring Notes

- **Test on physical device** - iOS Simulator does not support APNs (device tokens cannot be generated)
- **Write Test Plan before coding** - All acceptance gates defined above
- **Vertical slice** - This PR delivers testable push notification infrastructure (Firebase Console → iOS device)
- **Service layer is deterministic** - NotificationService methods have clear pre/post-conditions
- **Token refresh is critical** - Must handle on app launch, reinstall, and iOS updates
- **Reference** `Psst/agents/shared-standards.md` for threading (background token registration, main thread UI updates)

