# PR-15 TODO — Push Notifications Setup [NOT STARTED]

**Branch**: `feat/pr-15-push-notifications-setup`  
**Source PRD**: `Psst/docs/prds/pr-15-prd.md`  
**Owner (Agent)**: Caleb

---

## 0. Clarifying Questions & Assumptions

- Questions: None - PRD is comprehensive
- Assumptions (confirm in PR if needed):
  - Physical iOS device available for testing (Simulator doesn't support APNs)
  - Single FCM token per user for MVP (multi-device support deferred to future PR)
  - Permission requested on first launch after authentication, not during signup
  - APNs authentication key (.p8) preferred over certificates for Firebase integration
  - Development and production environments use same APNs key (configured in Firebase)

---

## 1. Setup

- [ ] Create branch `feat/pr-15-push-notifications-setup` from develop
- [ ] Read PRD thoroughly (`Psst/docs/prds/pr-15-prd.md`)
- [ ] Read `Psst/agents/shared-standards.md` for threading patterns
- [ ] Verify Firebase project exists and is configured (from PR #1)
- [ ] Confirm physical iOS device available for testing
  - Test Gate: Device connected to Xcode
  - Test Gate: Device can run builds successfully
- [ ] Confirm Apple Developer account access
  - Test Gate: Can access developer.apple.com
  - Test Gate: Have admin or developer role on team

---

## 2. Apple Developer Portal Configuration

Configure app identifier with push notification capability.

- [ ] Log in to Apple Developer Portal (developer.apple.com)
  - Test Gate: Successfully logged in

- [ ] Navigate to Certificates, Identifiers & Profiles
  - Test Gate: Section accessible

- [ ] Locate app identifier (Bundle ID should match Xcode project)
  - Navigate to Identifiers section
  - Find identifier matching `com.yourcompany.Psst` (or actual bundle ID)
  - Test Gate: App identifier exists

- [ ] Enable Push Notifications capability
  - Edit app identifier
  - Check "Push Notifications" capability
  - Save changes
  - Test Gate: Push Notifications capability enabled and shows checkmark

- [ ] Generate APNs Authentication Key (.p8 file)
  - Navigate to Keys section
  - Click "+" to create new key
  - Name: "Psst APNs Key" (or similar)
  - Check "Apple Push Notifications service (APNs)"
  - Click Continue, then Register
  - Test Gate: Key created successfully

- [ ] Download APNs key file
  - Download the .p8 file (only available once!)
  - Save to secure location (e.g., project root or password manager)
  - Note: File named like `AuthKey_ABC123XYZ.p8`
  - Test Gate: .p8 file downloaded and saved securely

- [ ] Record key information for Firebase
  - Note Key ID (10-character string, e.g., "ABC123XYZ")
  - Note Team ID (10-character string, visible in top-right of portal)
  - Store in secure notes or password manager
  - Test Gate: Key ID and Team ID recorded

---

## 3. Xcode Project Configuration

Add push notification capabilities to Xcode project.

- [ ] Open Xcode project (`Psst/Psst.xcodeproj`)
  - Test Gate: Project opens without errors

- [ ] Select Psst target in project navigator
  - Click project name in navigator
  - Select "Psst" under TARGETS
  - Test Gate: Target settings visible

- [ ] Navigate to "Signing & Capabilities" tab
  - Test Gate: Tab visible

- [ ] Add "Push Notifications" capability
  - Click "+ Capability" button
  - Search for "Push Notifications"
  - Double-click to add
  - Test Gate: "Push Notifications" section appears in capabilities list
  - Test Gate: No red error indicators

- [ ] Add "Background Modes" capability
  - Click "+ Capability" button again
  - Search for "Background Modes"
  - Double-click to add
  - Test Gate: "Background Modes" section appears

- [ ] Enable "Remote notifications" background mode
  - In Background Modes section, check "Remote notifications"
  - Test Gate: Checkbox selected

- [ ] Verify entitlements file created/updated
  - Check project navigator for `Psst.entitlements` file
  - Open file and verify it contains:
    - `aps-environment` key (development or production)
    - `com.apple.developer.push-notification-environment` (if present)
  - Test Gate: Entitlements file exists and contains push notification keys

- [ ] Update provisioning profile (if using manual signing)
  - If using automatic signing: Xcode handles this
  - If manual: Download updated provisioning profile from developer portal
  - Test Gate: No provisioning profile errors in Xcode

- [ ] Build project to verify configuration
  - Clean build folder (Cmd+Shift+K)
  - Build project (Cmd+B)
  - Test Gate: Build succeeds with 0 errors
  - Test Gate: No entitlement warnings in build log

---

## 4. Firebase Console Configuration

Upload APNs key to Firebase for FCM integration.

- [ ] Log in to Firebase Console (console.firebase.google.com)
  - Test Gate: Successfully logged in to correct project

- [ ] Select the Psst Firebase project
  - Test Gate: Correct project selected (verify project ID)

- [ ] Navigate to Project Settings
  - Click gear icon → Project settings
  - Test Gate: Project settings page opens

- [ ] Navigate to Cloud Messaging tab
  - Click "Cloud Messaging" tab in Project Settings
  - Test Gate: Cloud Messaging configuration page visible

- [ ] Scroll to "Apple app configuration" section
  - Test Gate: iOS app listed (should exist from PR #1)

- [ ] Upload APNs authentication key
  - Click "Upload" button in APNs Authentication Key section
  - Select the .p8 file downloaded earlier
  - Test Gate: File uploaded successfully

- [ ] Enter Key ID
  - Paste the 10-character Key ID from Apple Developer Portal
  - Test Gate: Key ID entered (e.g., "ABC123XYZ")

- [ ] Enter Team ID
  - Paste the 10-character Team ID from Apple Developer Portal
  - Test Gate: Team ID entered

- [ ] Save APNs configuration
  - Click "Save" or "Upload" button
  - Test Gate: Configuration saved successfully
  - Test Gate: Green checkmark or success message appears

- [ ] Verify configuration status
  - APNs status should show as "Configured" or similar
  - Test Gate: No error messages in Firebase Console

---

## 5. Data Model Update

Add fcmToken field to User model.

- [ ] Open `Models/User.swift`
  - Test Gate: File exists from PR #3

- [ ] Add fcmToken property to User struct
  - Add below existing properties (uid, displayName, email, profilePhotoURL)
  - Add line: `var fcmToken: String?`
  - Make it optional (nullable) since users might deny permission
  - Test Gate: Property compiles without errors

- [ ] Verify Codable conformance still works
  - User struct should already conform to Codable
  - New property automatically included in encoding/decoding
  - Test Gate: No compiler errors about Codable

- [ ] Add documentation comment
  - Above fcmToken property, add comment:
  ```swift
  /// Firebase Cloud Messaging device token for push notifications
  /// Nil if user hasn't granted notification permission or token not yet generated
  ```
  - Test Gate: Comment added

- [ ] Build project to verify changes
  - Build project (Cmd+B)
  - Test Gate: Build succeeds with 0 errors

---

## 6. Service Layer - NotificationService Creation

Create NotificationService to handle all push notification logic.

- [ ] Create new file `Services/NotificationService.swift`
  - In Xcode: Right-click Services folder → New File → Swift File
  - Name: `NotificationService.swift`
  - Test Gate: File created in Services directory
  - Test Gate: File appears in Xcode project navigator

- [ ] Add necessary imports
  ```swift
  import Foundation
  import FirebaseMessaging
  import FirebaseFirestore
  import FirebaseAuth
  import UserNotifications
  ```
  - Test Gate: Imports compile without errors

- [ ] Create NotificationService class skeleton
  ```swift
  class NotificationService: NSObject, ObservableObject {
      // Properties will go here
  }
  ```
  - Inherit from NSObject (required for delegate protocols)
  - Conform to ObservableObject (for SwiftUI state management)
  - Test Gate: Class definition compiles

- [ ] Add published properties
  ```swift
  @Published var isPermissionGranted: Bool = false
  @Published var fcmToken: String?
  ```
  - Test Gate: Properties compile
  - Test Gate: @Published requires import Combine (add if needed)

- [ ] Add private property for UserNotificationCenter
  ```swift
  private let notificationCenter = UNUserNotificationCenter.current()
  ```
  - Test Gate: Property compiles

- [ ] Add initializer
  ```swift
  override init() {
      super.init()
      setupMessagingDelegate()
  }
  
  private func setupMessagingDelegate() {
      Messaging.messaging().delegate = self
  }
  ```
  - Test Gate: Initializer compiles (delegate conformance added later)

---

## 7. Service Layer - Permission Management

Implement permission request methods in NotificationService.

- [ ] Implement requestPermission() method
  ```swift
  func requestPermission() async throws -> Bool {
      let options: UNAuthorizationOptions = [.alert, .sound, .badge]
      let granted = try await notificationCenter.requestAuthorization(options: options)
      
      await MainActor.run {
          self.isPermissionGranted = granted
      }
      
      if granted {
          print("[NotificationService] ✅ Notification permission granted")
          await MainActor.run {
              registerForPushNotifications()
          }
      } else {
          print("[NotificationService] ❌ Notification permission denied")
      }
      
      return granted
  }
  ```
  - Request .alert, .sound, and .badge permissions
  - Update published property on main thread
  - If granted, automatically trigger APNs registration
  - Test Gate: Method compiles
  - Test Gate: Uses async/await properly
  - Test Gate: MainActor.run used for UI updates

- [ ] Implement checkPermissionStatus() method
  ```swift
  func checkPermissionStatus() async -> UNAuthorizationStatus {
      let settings = await notificationCenter.notificationSettings()
      let status = settings.authorizationStatus
      
      await MainActor.run {
          self.isPermissionGranted = (status == .authorized)
      }
      
      print("[NotificationService] Permission status: \(status.rawValue)")
      return status
  }
  ```
  - Check current authorization status
  - Update published property
  - Test Gate: Method compiles
  - Test Gate: Returns UNAuthorizationStatus

- [ ] Build project to verify
  - Build project (Cmd+B)
  - Test Gate: Build succeeds

---

## 8. Service Layer - APNs Registration

Implement APNs device token registration in NotificationService.

- [ ] Implement registerForPushNotifications() method
  ```swift
  func registerForPushNotifications() {
      DispatchQueue.main.async {
          UIApplication.shared.registerForRemoteNotifications()
      }
      print("[NotificationService] 📲 Registering for remote notifications...")
  }
  ```
  - Must be called on main thread
  - Triggers APNs registration
  - Test Gate: Method compiles
  - Test Gate: Uses DispatchQueue.main for UIApplication call

- [ ] Add import for UIKit
  - At top of file, add: `import UIKit`
  - Test Gate: Import added, UIApplication accessible

- [ ] Implement didReceiveAPNsToken() method
  ```swift
  func didReceiveAPNsToken(_ token: Data) {
      let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
      print("[NotificationService] 📱 APNs token received: \(tokenString)")
      
      // FCM SDK will automatically exchange this for FCM token via MessagingDelegate
  }
  ```
  - Convert Data to hex string for logging
  - Log token for debugging
  - Note: FCM handles token exchange automatically
  - Test Gate: Method compiles

- [ ] Implement didFailToRegister() method
  ```swift
  func didFailToRegister(error: Error) {
      print("[NotificationService] ❌ Failed to register for remote notifications: \(error.localizedDescription)")
      
      // Check if running on simulator
      #if targetEnvironment(simulator)
      print("[NotificationService] ⚠️ Note: Push notifications are not supported on iOS Simulator. Please test on a physical device.")
      #endif
  }
  ```
  - Log error for debugging
  - Special message for simulator
  - Test Gate: Method compiles
  - Test Gate: Simulator check works

- [ ] Build project to verify
  - Build project (Cmd+B)
  - Test Gate: Build succeeds

---

## 9. Service Layer - FCM Token Management

Implement FCM token handling and Firestore storage.

- [ ] Implement didReceiveFCMToken() method
  ```swift
  func didReceiveFCMToken(_ token: String) {
      print("[NotificationService] 🔥 FCM token received: \(token)")
      
      Task {
          await MainActor.run {
              self.fcmToken = token
          }
          
          do {
              try await saveFCMTokenToFirestore(token)
              print("[NotificationService] ✅ FCM token saved to Firestore")
          } catch {
              print("[NotificationService] ❌ Failed to save FCM token to Firestore: \(error.localizedDescription)")
          }
      }
  }
  ```
  - Update published property on main thread
  - Save token to Firestore asynchronously
  - Handle errors gracefully
  - Test Gate: Method compiles
  - Test Gate: Uses Task for async work

- [ ] Implement saveFCMTokenToFirestore() method
  ```swift
  func saveFCMTokenToFirestore(_ token: String) async throws {
      guard let userID = Auth.auth().currentUser?.uid else {
          print("[NotificationService] ⚠️ Cannot save token - user not authenticated")
          throw NSError(domain: "NotificationService", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
      }
      
      let db = Firestore.firestore()
      try await db.collection("users").document(userID).updateData([
          "fcmToken": token
      ])
      
      print("[NotificationService] ✅ Saved token for user: \(userID)")
  }
  ```
  - Verify user is authenticated
  - Update user document with fcmToken field
  - Use updateData (not setData) to avoid overwriting other fields
  - Log success/failure
  - Test Gate: Method compiles
  - Test Gate: Uses async/await properly
  - Test Gate: Throws errors for error handling

- [ ] Implement refreshFCMToken() method
  ```swift
  func refreshFCMToken() async {
      print("[NotificationService] 🔄 Refreshing FCM token...")
      
      do {
          let token = try await Messaging.messaging().token()
          print("[NotificationService] 🔥 Refreshed FCM token: \(token)")
          didReceiveFCMToken(token)
      } catch {
          print("[NotificationService] ❌ Failed to refresh FCM token: \(error.localizedDescription)")
      }
  }
  ```
  - Fetch latest token from FCM SDK
  - Call didReceiveFCMToken to save
  - Handle errors gracefully
  - Test Gate: Method compiles
  - Test Gate: Uses async/await

- [ ] Build project to verify
  - Build project (Cmd+B)
  - Test Gate: Build succeeds

---

## 10. Service Layer - Delegate Conformance

Implement MessagingDelegate protocol in NotificationService.

- [ ] Add MessagingDelegate conformance
  - After class declaration, add extension:
  ```swift
  extension NotificationService: MessagingDelegate {
      // Delegate methods will go here
  }
  ```
  - Test Gate: Extension compiles

- [ ] Implement messaging(_:didReceiveRegistrationToken:) delegate method
  ```swift
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
      print("[NotificationService] 📬 MessagingDelegate: FCM token received")
      
      guard let token = fcmToken else {
          print("[NotificationService] ⚠️ FCM token is nil")
          return
      }
      
      didReceiveFCMToken(token)
  }
  ```
  - Called when FCM token is generated or refreshed
  - Forward to didReceiveFCMToken method
  - Test Gate: Method compiles
  - Test Gate: Method signature matches MessagingDelegate protocol

- [ ] Build project to verify
  - Build project (Cmd+B)
  - Test Gate: Build succeeds with 0 errors
  - Test Gate: No protocol conformance warnings

---

## 11. App Lifecycle Integration - PsstApp Setup

Configure app delegate methods for push notifications in PsstApp.swift.

- [ ] Open `Psst/PsstApp.swift`
  - Test Gate: File exists (main app entry point)

- [ ] Add necessary imports at top of file
  ```swift
  import FirebaseMessaging
  import UserNotifications
  ```
  - Test Gate: Imports compile

- [ ] Create NotificationService instance as @StateObject
  - After Firebase.configure() or in PsstApp struct:
  ```swift
  @StateObject private var notificationService = NotificationService()
  ```
  - Test Gate: Property compiles
  - Test Gate: @StateObject used for lifecycle management

- [ ] Add UIApplicationDelegateAdaptor
  - In PsstApp struct, add:
  ```swift
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  ```
  - Test Gate: Property compiles

- [ ] Create AppDelegate class
  - At bottom of PsstApp.swift file (or separate file), add:
  ```swift
  class AppDelegate: NSObject, UIApplicationDelegate {
      func application(_ application: UIApplication, 
                      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
          
          // Set notification center delegate
          UNUserNotificationCenter.current().delegate = self
          
          return true
      }
      
      func application(_ application: UIApplication,
                      didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
          // Forward to NotificationService
          // Note: We'll need to access NotificationService instance here
          print("[AppDelegate] 📱 APNs device token received")
          
          // Let FCM SDK know about the token
          Messaging.messaging().apnsToken = deviceToken
      }
      
      func application(_ application: UIApplication,
                      didFailToRegisterForRemoteNotificationsWithError error: Error) {
          print("[AppDelegate] ❌ Failed to register: \(error.localizedDescription)")
      }
  }
  ```
  - Test Gate: Class compiles
  - Test Gate: UIApplicationDelegate methods defined

- [ ] Add UNUserNotificationCenterDelegate conformance
  - Add extension to AppDelegate:
  ```swift
  extension AppDelegate: UNUserNotificationCenterDelegate {
      // Handle notifications when app is in foreground
      func userNotificationCenter(_ center: UNUserNotificationCenter,
                                 willPresent notification: UNNotification,
                                 withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
          print("[AppDelegate] 📬 Notification received in foreground")
          
          // Show notification even when app is in foreground
          completionHandler([.banner, .sound, .badge])
      }
      
      // Handle notification tap
      func userNotificationCenter(_ center: UNUserNotificationCenter,
                                 didReceive response: UNNotificationResponse,
                                 withCompletionHandler completionHandler: @escaping () -> Void) {
          print("[AppDelegate] 👆 User tapped notification")
          
          // Deep linking logic will go here in PR #16
          
          completionHandler()
      }
  }
  ```
  - Test Gate: Extension compiles
  - Test Gate: Delegate methods defined

- [ ] Inject NotificationService into environment
  - In PsstApp body, add .environmentObject modifier:
  ```swift
  var body: some Scene {
      WindowGroup {
          ContentView()
              .environmentObject(notificationService)
      }
  }
  ```
  - Test Gate: Modifier added
  - Test Gate: NotificationService accessible in child views

- [ ] Add token refresh on app launch
  - In PsstApp body, add .onAppear modifier:
  ```swift
  ContentView()
      .environmentObject(notificationService)
      .onAppear {
          Task {
              await notificationService.refreshFCMToken()
          }
      }
  ```
  - Test Gate: Modifier added
  - Test Gate: Refresh called on app launch

- [ ] Build project to verify
  - Build project (Cmd+B)
  - Test Gate: Build succeeds with 0 errors

---

## 12. Permission Request Integration - AuthViewModel

Trigger permission request after successful authentication.

- [ ] Open `ViewModels/AuthViewModel.swift`
  - Test Gate: File exists from PR #2

- [ ] Add NotificationService reference
  - Option 1: Pass via initializer
  - Option 2: Access via @EnvironmentObject in view, then pass to method
  - For simplicity, we'll trigger from the view after login
  - Test Gate: Plan decided

- [ ] Update login/signup success handling
  - After successful authentication, trigger permission request
  - This will be done in the view layer (next step)
  - Test Gate: Login/signup flows identified

- [ ] Document where permission will be requested
  - Add comment in signIn or signUp methods:
  ```swift
  // Note: Notification permission will be requested in view layer after successful auth
  ```
  - Test Gate: Comment added

---

## 13. Permission Request Integration - View Layer

Add permission request to authentication success flow.

- [ ] Open `Views/Authentication/LoginView.swift`
  - Test Gate: File exists from PR #2

- [ ] Add NotificationService environment object
  ```swift
  @EnvironmentObject var notificationService: NotificationService
  ```
  - Test Gate: Property compiles

- [ ] Add state for tracking if permission was requested
  ```swift
  @AppStorage("hasRequestedNotificationPermission") private var hasRequestedPermission = false
  ```
  - Uses UserDefaults to persist across app launches
  - Test Gate: Property compiles

- [ ] Trigger permission request after successful login
  - In login success handler (after signIn succeeds):
  ```swift
  // After successful login
  if !hasRequestedPermission {
      Task {
          do {
              let granted = try await notificationService.requestPermission()
              hasRequestedPermission = true
              print("[LoginView] Notification permission: \(granted ? "granted" : "denied")")
          } catch {
              print("[LoginView] Error requesting permission: \(error.localizedDescription)")
              hasRequestedPermission = true // Don't ask again even if error
          }
      }
  }
  ```
  - Only request once per user
  - Handle errors gracefully
  - Test Gate: Code compiles
  - Test Gate: Uses Task for async work

- [ ] Repeat for SignUpView if separate file
  - Open `Views/Authentication/SignUpView.swift`
  - Add same @EnvironmentObject and @AppStorage properties
  - Add same permission request logic after signup success
  - Test Gate: SignUpView updated (if exists as separate file)

- [ ] Build project to verify
  - Build project (Cmd+B)
  - Test Gate: Build succeeds with 0 errors

---

## 14. UserService Extension - FCM Token Support

Update UserService to support fcmToken field writes.

- [ ] Open `Services/UserService.swift`
  - Test Gate: File exists from PR #3

- [ ] Check if updateUser method exists
  - Search for method that updates user documents
  - Test Gate: Identified existing update methods

- [ ] Add updateFCMToken method (if not already covered)
  ```swift
  func updateFCMToken(_ token: String) async throws {
      guard let userID = Auth.auth().currentUser?.uid else {
          throw NSError(domain: "UserService", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
      }
      
      let db = Firestore.firestore()
      try await db.collection("users").document(userID).updateData([
          "fcmToken": token
      ])
      
      print("[UserService] ✅ Updated FCM token for user: \(userID)")
  }
  ```
  - Note: This duplicates logic in NotificationService for separation of concerns
  - Alternative: Call NotificationService from UserService (decide based on architecture)
  - Test Gate: Method compiles

- [ ] Verify createUser includes fcmToken field
  - Check createUser or similar method
  - Ensure it doesn't overwrite fcmToken when creating users
  - Use setData with merge: true or handle separately
  - Test Gate: createUser doesn't overwrite fcmToken

- [ ] Build project to verify
  - Build project (Cmd+B)
  - Test Gate: Build succeeds

---

## 15. Firestore Security Rules Update

Update Firestore security rules to allow users to update their fcmToken field.

- [ ] Open Firebase Console
  - Navigate to Firestore Database → Rules tab
  - Test Gate: Rules editor visible

- [ ] Locate rules for users collection
  - Find section like:
  ```javascript
  match /users/{userID} {
    // existing rules
  }
  ```
  - Test Gate: Users collection rules found

- [ ] Add or update rule to allow fcmToken updates
  ```javascript
  match /users/{userID} {
    allow read: if request.auth != null;
    allow create: if request.auth != null && request.auth.uid == userID;
    allow update: if request.auth != null && request.auth.uid == userID;
    
    // Specifically allow fcmToken updates
    allow update: if request.auth != null 
                  && request.auth.uid == userID
                  && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['fcmToken']);
  }
  ```
  - Allows users to update only their own fcmToken
  - Doesn't allow modifying other user fields without full update permissions
  - Test Gate: Rule syntax valid (Firebase Console validates)

- [ ] Publish rules
  - Click "Publish" button in Firebase Console
  - Test Gate: Rules published successfully
  - Test Gate: No validation errors

- [ ] Test rules in Firebase Rules Playground (optional)
  - Click "Rules Playground" tab
  - Simulate update to /users/{userID} with fcmToken field
  - Verify rule allows authenticated user
  - Test Gate: Playground shows "Allow" for valid requests

- [ ] Document rules update in PR
  - Note: Firestore security rules updated to allow fcmToken writes
  - Test Gate: Noted for PR description

---

## 16. Manual Validation Testing - Configuration

Verify all configuration steps completed correctly.

### Apple Developer Portal Configuration

- [ ] Verify app identifier has Push Notifications enabled
  - Log in to developer.apple.com
  - Navigate to Identifiers
  - Check app identifier
  - Test Gate: Push Notifications capability shows green checkmark

- [ ] Verify APNs key exists and is active
  - Navigate to Keys section
  - Find Psst APNs Key
  - Test Gate: Key status is "Active"
  - Test Gate: Key ID matches what was uploaded to Firebase

### Xcode Configuration

- [ ] Verify Push Notifications capability in Xcode
  - Open project → Target → Signing & Capabilities
  - Test Gate: "Push Notifications" section present
  - Test Gate: No red error indicators

- [ ] Verify Background Modes capability
  - Same tab as above
  - Test Gate: "Background Modes" section present
  - Test Gate: "Remote notifications" checkbox selected

- [ ] Verify entitlements file
  - Check Psst.entitlements in project navigator
  - Test Gate: File contains aps-environment key
  - Test Gate: No entitlement errors when building

- [ ] Build on physical device
  - Connect iPhone/iPad via USB
  - Select device in Xcode
  - Build and run (Cmd+R)
  - Test Gate: Build succeeds
  - Test Gate: App launches on device
  - Test Gate: No provisioning errors

### Firebase Configuration

- [ ] Verify APNs key uploaded to Firebase
  - Log in to Firebase Console
  - Project Settings → Cloud Messaging
  - Test Gate: APNs Authentication Key shows as "Configured"
  - Test Gate: Key ID matches Apple Developer Portal

- [ ] Verify Firebase Messaging SDK added
  - Check Package.swift or project dependencies
  - Test Gate: FirebaseMessaging package present
  - Test Gate: No dependency resolution errors

### General Configuration

- [ ] No console errors when app launches
  - Run app on device
  - Open Xcode console (View → Debug Area → Activate Console)
  - Test Gate: No Firebase configuration errors
  - Test Gate: No push notification setup errors

---

## 17. Manual Validation Testing - Happy Path

Test the complete flow from permission request to notification delivery.

### Step 1: Permission Request

- [ ] Clean app install
  - Delete app from device if previously installed
  - Cmd+R to build and install fresh
  - Test Gate: Fresh install (no cached permissions)

- [ ] Launch app and log in with test account
  - Use existing test account or create new one
  - Complete login flow
  - Test Gate: Login succeeds, main screen appears

- [ ] Verify permission prompt appears
  - After login, iOS permission alert should appear
  - Alert text: "Psst would like to send you notifications"
  - Test Gate: Alert appears within 5 seconds of login
  - Test Gate: Alert shows two buttons: "Don't Allow" and "Allow"

- [ ] Grant permission
  - Tap "Allow" button
  - Test Gate: Alert dismisses
  - Test Gate: App continues to function normally

### Step 2: Token Registration

- [ ] Check Xcode console for APNs token
  - Look for log: "[AppDelegate] 📱 APNs device token received"
  - Test Gate: APNs token received within 2 seconds of permission grant
  - Test Gate: Token is non-empty hex string

- [ ] Check Xcode console for FCM token
  - Look for log: "[NotificationService] 🔥 FCM token received: ..."
  - Copy the full FCM token from console (long string)
  - Test Gate: FCM token received within 2 seconds of APNs token
  - Test Gate: Token is non-empty string (140+ characters)

- [ ] Verify token saved to Firestore
  - Open Firebase Console
  - Navigate to Firestore Database
  - Find user document: `users/{test-user-uid}`
  - Test Gate: Document has `fcmToken` field
  - Test Gate: `fcmToken` value matches token from console logs

### Step 3: Test Notification from Firebase Console

- [ ] Navigate to Firebase Console → Cloud Messaging
  - Click "Send your first message" or "New notification"
  - Test Gate: Notification composer opens

- [ ] Create test notification
  - Notification title: "Test Notification"
  - Notification text: "This is a test from Firebase Console"
  - Test Gate: Fields filled

- [ ] Select target: Single device
  - Choose "Send test message" option
  - Paste FCM token copied from Xcode console
  - Click "Test" button
  - Test Gate: Token pasted correctly
  - Test Gate: No validation errors

- [ ] Send notification with app in FOREGROUND
  - Ensure app is open and active on device
  - Click "Test" in Firebase Console
  - Test Gate: Notification appears as banner at top of screen
  - Test Gate: Notification received within 3 seconds
  - Test Gate: Title and text display correctly

- [ ] Send notification with app in BACKGROUND
  - Press Home button to background app
  - Send another test notification from Firebase Console
  - Test Gate: Notification appears in notification center
  - Test Gate: Notification received within 3 seconds
  - Test Gate: Sound plays (if not in silent mode)

- [ ] Send notification with app TERMINATED
  - Swipe up to force-quit app
  - Send another test notification from Firebase Console
  - Test Gate: Notification appears in notification center
  - Test Gate: Notification received within 3 seconds
  - Test Gate: Badge count increases (if configured)

- [ ] Tap notification to open app
  - Tap notification from notification center
  - Test Gate: App launches/opens
  - Test Gate: Console shows: "[AppDelegate] 👆 User tapped notification"

### Step 4: Verify Complete Flow

- [ ] End-to-end timing
  - From permission grant to test notification received
  - Test Gate: Total time < 5 seconds (excluding manual Firebase Console steps)

- [ ] All console logs present
  - Test Gate: Permission granted log
  - Test Gate: APNs token log
  - Test Gate: FCM token log
  - Test Gate: Firestore save success log

- [ ] No errors in console
  - Test Gate: No red error messages
  - Test Gate: No Firebase errors
  - Test Gate: No Firestore write errors

---

## 18. Manual Validation Testing - Edge Cases

Test error scenarios and edge cases.

### Permission Denied Scenario

- [ ] Clean install (delete and reinstall app)
  - Test Gate: Fresh install

- [ ] Log in and deny notification permission
  - When permission alert appears, tap "Don't Allow"
  - Test Gate: Alert dismisses

- [ ] Verify app continues to function
  - Navigate around app (ConversationListView, ChatView, etc.)
  - Test Gate: App doesn't crash
  - Test Gate: No blocking errors
  - Test Gate: User can still send/receive messages (real-time)

- [ ] Verify console logs
  - Look for: "[NotificationService] ❌ Notification permission denied"
  - Test Gate: Log present

- [ ] Verify no FCM token in Firestore
  - Check user document in Firebase Console
  - Test Gate: `fcmToken` field is absent or nil

- [ ] Verify no duplicate permission requests
  - Close and reopen app multiple times
  - Test Gate: Permission alert does NOT appear again
  - Test Gate: hasRequestedPermission = true in UserDefaults

### APNs Registration Failure (Simulator Test)

- [ ] Build and run on iOS Simulator
  - Select simulator in Xcode
  - Run app (Cmd+R)
  - Test Gate: App runs in simulator

- [ ] Log in and grant permission (if prompted)
  - Test Gate: Login works

- [ ] Check console for simulator warning
  - Look for: "[NotificationService] ⚠️ Note: Push notifications are not supported on iOS Simulator"
  - Test Gate: Warning log present
  - Test Gate: App doesn't crash

- [ ] Verify graceful degradation
  - App should continue to function normally
  - Test Gate: No blocking errors
  - Test Gate: Real-time messaging still works

### Firestore Write Failure

- [ ] Simulate offline mode
  - On device, enable Airplane Mode
  - Or: In Firebase Console, temporarily block write access in rules
  - Test Gate: Offline/blocked

- [ ] Trigger token registration
  - Log out and log back in (or reinstall app)
  - Grant permission
  - Test Gate: Token generation attempted

- [ ] Check console for Firestore error
  - Look for: "[NotificationService] ❌ Failed to save FCM token to Firestore"
  - Test Gate: Error logged
  - Test Gate: App doesn't crash

- [ ] Verify Firestore offline persistence
  - Token write should be queued locally
  - Test Gate: No user-facing error (silent failure)

- [ ] Restore connectivity and verify retry
  - Disable Airplane Mode
  - Restart app or wait for background refresh
  - Check Firestore - token should be written
  - Test Gate: Token appears in Firestore after reconnect

### Token Already Exists

- [ ] Launch app multiple times
  - Close and reopen app 3-5 times
  - Test Gate: Each launch succeeds

- [ ] Verify token not duplicated
  - Check Firestore user document
  - Test Gate: Only one `fcmToken` field value
  - Test Gate: Token value may update but not duplicate

- [ ] Check console logs
  - Each launch should show: "[NotificationService] 🔄 Refreshing FCM token..."
  - Test Gate: Logs present for each launch
  - Test Gate: No errors about duplicate tokens

### No Internet Connection

- [ ] Enable Airplane Mode before launching app
  - Test Gate: Device offline

- [ ] Launch app and log in (if cached)
  - Firestore offline persistence should allow login
  - Test Gate: App launches

- [ ] Grant notification permission
  - Permission request should still work (local)
  - Test Gate: Permission granted

- [ ] Verify APNs registration fails gracefully
  - Device can't reach APNs servers
  - Test Gate: No user-visible error
  - Test Gate: App continues to function

- [ ] Disable Airplane Mode
  - Wait 5-10 seconds
  - Test Gate: Token registration completes automatically
  - Test Gate: Token appears in Firestore

---

## 19. Manual Validation Testing - Token Refresh

Test token refresh lifecycle events.

### App Launch Token Refresh

- [ ] Launch app with existing account (already granted permission)
  - Open app normally
  - Test Gate: App launches

- [ ] Check console for refresh log
  - Look for: "[NotificationService] 🔄 Refreshing FCM token..."
  - Test Gate: Log appears within 2 seconds of launch

- [ ] Verify non-blocking behavior
  - Token refresh should not delay UI
  - Test Gate: App is immediately interactive (< 100ms)
  - Test Gate: No loading spinners or delays

- [ ] Check if token updated in Firestore
  - View user document in Firebase Console
  - Test Gate: `fcmToken` field present
  - Test Gate: Token value matches console log (if changed)

### Token Refresh After Reinstall

- [ ] Note current FCM token
  - Check Xcode console or Firestore
  - Copy token value for comparison
  - Test Gate: Token recorded

- [ ] Delete app from device
  - Long-press app icon → Remove App → Delete App
  - Test Gate: App deleted

- [ ] Reinstall app from Xcode
  - Cmd+R to build and install
  - Test Gate: App installed

- [ ] Log in with same account
  - Enter credentials
  - Grant permission again (new install)
  - Test Gate: Login succeeds

- [ ] Check for new FCM token
  - View console logs
  - Test Gate: New FCM token generated
  - Test Gate: New token is DIFFERENT from old token

- [ ] Verify new token in Firestore
  - Check user document
  - Test Gate: `fcmToken` updated to new value
  - Test Gate: Old token replaced (not duplicated)

### Background Token Refresh

- [ ] Launch app and verify token exists
  - Test Gate: Token in Firestore

- [ ] Background app for extended period
  - Press Home button
  - Wait 10+ minutes (or simulate iOS update)
  - Test Gate: App backgrounded

- [ ] Return to app
  - Tap app icon to foreground
  - Test Gate: App resumes

- [ ] Check console for refresh
  - May see token refresh log on resume
  - Test Gate: Token refresh attempted (if FCM triggers)
  - Test Gate: No errors

---

## 20. Manual Validation Testing - Performance

Verify performance targets from PRD.

### Permission Request Performance

- [ ] Measure time to show permission prompt
  - Clean install and log in
  - Note time from login success to prompt appearance
  - Test Gate: Prompt appears in < 100ms after login

- [ ] Verify no UI blocking
  - App should remain responsive during request
  - Test Gate: Can still interact with UI (though prompt is modal)

### Token Registration Performance

- [ ] Measure APNs registration time
  - From permission grant to APNs token received
  - Check console timestamps
  - Test Gate: < 2 seconds

- [ ] Measure FCM token generation time
  - From APNs token to FCM token received
  - Check console timestamps
  - Test Gate: < 2 seconds

- [ ] Measure Firestore write time
  - From FCM token received to Firestore save success
  - Check console timestamps
  - Test Gate: < 1 second

- [ ] Total flow timing
  - From permission grant to token stored in Firestore
  - Test Gate: < 5 seconds total

### Token Refresh Performance

- [ ] Measure refresh on app launch
  - Close and reopen app
  - Check time from launch to refresh complete
  - Test Gate: < 2 seconds
  - Test Gate: Refresh happens in background (doesn't block UI)

- [ ] Verify main thread not blocked
  - App should be immediately interactive on launch
  - Test Gate: Can tap buttons immediately (no lag)
  - Test Gate: No ANR (Application Not Responding) warnings

### No Main Thread Blocking

- [ ] Verify all async operations
  - Review code: All Firestore writes use async/await
  - Review code: All network calls on background threads
  - Test Gate: Code review confirms no blocking calls

- [ ] Test app responsiveness
  - During token registration, try interacting with UI
  - Test Gate: UI remains responsive
  - Test Gate: Scrolling is smooth
  - Test Gate: Buttons respond immediately

---

## 21. Manual Validation Testing - Physical Device

Verify all tests specifically on physical device.

### Confirm Physical Device Testing

- [ ] Physical iOS device available
  - iPhone or iPad
  - iOS 13+ minimum
  - Test Gate: Device connected to Xcode

- [ ] Device properly provisioned
  - Valid provisioning profile installed
  - Test Gate: No signing errors when building

- [ ] Build and run on device
  - Select device in Xcode
  - Cmd+R to build and run
  - Test Gate: Build succeeds
  - Test Gate: App launches on device

### Repeat Core Tests on Device

- [ ] Permission request test (from Section 17)
  - Test Gate: Permission prompt appears
  - Test Gate: Can grant/deny permission

- [ ] Token registration test (from Section 17)
  - Test Gate: APNs token received
  - Test Gate: FCM token received
  - Test Gate: Token saved to Firestore

- [ ] Test notification delivery (from Section 17)
  - Test Gate: Foreground notification received
  - Test Gate: Background notification received
  - Test Gate: Terminated notification received

- [ ] Token refresh test (from Section 19)
  - Test Gate: Token refreshes on app launch

### Confirm Simulator Limitations

- [ ] Document that Simulator cannot be used for full testing
  - APNs device tokens cannot be generated on Simulator
  - Test notifications cannot be received on Simulator
  - Test Gate: Noted in PR documentation

---

## 22. Acceptance Gates

Check every gate from PRD Section 12:

### Configuration Gates

- [ ] "Push Notifications" capability enabled in Xcode
- [ ] "Background Modes" capability enabled with "Remote notifications" checked
- [ ] Provisioning profile includes push notification entitlement
- [ ] App builds successfully without entitlement errors
- [ ] Firebase Messaging SDK added to project
- [ ] APNs authentication key uploaded to Firebase Console
- [ ] Firebase Console shows app is configured for iOS push
- [ ] No Firebase configuration errors in console logs
- [ ] App identifier registered with push notification capability
- [ ] APNs key (.p8 file) generated and downloaded
- [ ] Provisioning profile updated and downloaded

### Happy Path Gates

- [ ] After login, permission prompt appears exactly once
- [ ] User can tap "Allow" and permission is granted
- [ ] isPermissionGranted state updates to true
- [ ] No crashes or errors after permission grant
- [ ] APNs device token received within 2 seconds of permission grant
- [ ] APNs token logged to console (visible in Xcode debug logs)
- [ ] FCM token generated and logged to console
- [ ] FCM token stored in Firestore at users/{uid}/fcmToken
- [ ] Token is non-empty string and properly formatted
- [ ] Copy FCM token from console logs successful
- [ ] Send test notification from Firebase Console successful
- [ ] Notification received on device when app in foreground
- [ ] Notification received on device when app in background
- [ ] Notification received on device when app terminated

### Edge Case Gates

- [ ] User can tap "Don't Allow" on permission prompt
- [ ] App continues to function normally if permission denied
- [ ] No infinite permission request loops
- [ ] isPermissionGranted state updates to false if denied
- [ ] fcmToken remains nil in Firestore if permission denied
- [ ] If APNs registration fails, error logged to console
- [ ] Error is descriptive (shows reason for failure)
- [ ] App doesn't crash on registration failure
- [ ] User can still use app (messaging works without push)
- [ ] Simulate Firestore offline - token write fails gracefully
- [ ] Error logged to console for Firestore failures
- [ ] App continues to function after Firestore write failure
- [ ] Token write retried on next app launch
- [ ] Launch app multiple times - token not duplicated
- [ ] Latest token overwrites old token correctly

### Token Refresh Gates

- [ ] Close app completely (terminate) and reopen
- [ ] FCM token refresh triggered in background
- [ ] Token updated in Firestore if changed
- [ ] Token refresh completes in < 2 seconds
- [ ] Main thread not blocked during refresh
- [ ] Note current FCM token from Firestore
- [ ] Delete app from device then reinstall
- [ ] Log in with same account
- [ ] New FCM token generated (different from previous)
- [ ] New token stored in Firestore

### Performance Gates

- [ ] Permission prompt appears in < 100ms after trigger
- [ ] No UI lag or freezing during permission request
- [ ] APNs registration completes in < 2 seconds
- [ ] FCM token generation completes in < 2 seconds
- [ ] Firestore write completes in < 1 second
- [ ] Total flow (permission → token stored) completes in < 5 seconds
- [ ] All network calls (Firestore writes) on background thread
- [ ] App remains responsive during token registration
- [ ] No ANR (Application Not Responding) warnings

---

## 23. Documentation & PR

Document changes and create pull request.

- [ ] Add inline code comments for complex logic
  - APNs/FCM token exchange flow
  - Permission request timing logic
  - Token refresh lifecycle
  - Delegate method implementations
  - Test Gate: Comments are clear and helpful

- [ ] Update README with push notification setup instructions
  - Add section: "Push Notifications Setup"
  - Document requirements:
    - Physical iOS device required for testing
    - APNs key must be generated and uploaded to Firebase
    - Push Notifications capability must be enabled in Xcode
  - Document limitations:
    - Simulator does not support push notifications
    - Single device token per user (multi-device in future)
  - Test Gate: README updated with clear instructions

- [ ] Create PR description with following format:
  ```markdown
  # PR #15: Push Notifications Setup
  
  ## Overview
  Configures Apple Push Notification service (APNs) and Firebase Cloud Messaging (FCM) for the iOS app. Establishes infrastructure for push notifications including device token registration, permission management, and token storage in Firestore. Cloud Functions and full notification handling will come in PR #16.
  
  ## Changes
  - Added "Push Notifications" and "Background Modes" capabilities in Xcode
  - Configured APNs authentication key in Apple Developer Portal and Firebase Console
  - Created NotificationService to handle token registration and lifecycle
  - Added `fcmToken` field to User model and Firestore schema
  - Implemented permission request flow (triggered after authentication)
  - Integrated FCM token refresh on app launch
  - Updated Firestore security rules to allow fcmToken updates
  - Configured AppDelegate for APNs and notification handling
  
  ## Testing
  - Manual testing completed on physical iOS device (required - Simulator does not support APNs)
  - Permission request flow verified (grant and deny scenarios)
  - Token registration verified (APNs → FCM → Firestore)
  - Test notifications successfully sent from Firebase Console
  - Notifications received in foreground, background, and terminated states
  - Token refresh verified on app launch and after reinstall
  - Performance targets met (< 5 seconds total flow, non-blocking)
  - All edge cases tested (permission denied, registration failure, offline)
  
  ## Configuration Required
  **Before merging, ensure:**
  1. APNs authentication key (.p8) generated in Apple Developer Portal
  2. APNs key uploaded to Firebase Console (Project Settings → Cloud Messaging)
  3. App identifier has "Push Notifications" capability enabled
  4. Provisioning profiles updated and installed in Xcode
  
  ## Known Limitations
  - Simulator does not support push notifications (physical device required)
  - Single FCM token per user (last device overwrites previous)
  - Multi-device support deferred to future enhancement
  
  ## Related
  - PRD: Psst/docs/prds/pr-15-prd.md
  - TODO: Psst/docs/todos/pr-15-todo.md
  - Depends on: PR #1 (Firebase setup)
  - Blocks: PR #16 (Cloud Functions and notification handling)
  ```
  - Test Gate: PR description is comprehensive

- [ ] Verify with user before creating PR
  - Review all changes
  - Confirm all acceptance gates pass
  - Confirm all tests completed on physical device
  - Test Gate: User approval received

- [ ] Open PR targeting develop branch
  - Base branch: develop
  - Compare branch: feat/pr-15-push-notifications-setup
  - Test Gate: PR created successfully

- [ ] Link PRD and TODO in PR description
  - Test Gate: Links work correctly

---

## Copyable Checklist (for PR description)

```markdown
- [ ] Branch created from develop
- [ ] All TODO tasks completed
- [ ] Apple Developer Portal configured (app identifier, APNs key)
- [ ] Xcode project configured (Push Notifications capability, Background Modes)
- [ ] Firebase Console configured (APNs key uploaded)
- [ ] NotificationService implemented with all required methods
- [ ] User model updated with fcmToken field
- [ ] PsstApp.swift updated with FCM Messaging delegate
- [ ] AppDelegate implemented with APNs callbacks
- [ ] Permission request flow integrated (triggered after authentication)
- [ ] Token refresh implemented on app launch
- [ ] Firestore security rules updated for fcmToken writes
- [ ] Firebase integration verified (token registration, storage, refresh)
- [ ] Manual testing completed on physical iOS device
- [ ] Permission flow tested (grant and deny scenarios)
- [ ] Token registration tested (APNs → FCM → Firestore)
- [ ] Test notifications delivered from Firebase Console (foreground, background, terminated)
- [ ] Token refresh tested (app launch, reinstall)
- [ ] Edge cases tested (permission denied, registration failure, offline)
- [ ] Performance targets met (< 5 seconds total flow, non-blocking)
- [ ] All acceptance gates pass
- [ ] Code follows Psst/agents/shared-standards.md patterns
- [ ] No console warnings or errors
- [ ] Documentation updated (inline comments, README)
```

---

## Notes

- **CRITICAL**: Physical iOS device required - Simulator does not support APNs device tokens
- Break tasks into <30 min chunks
- Complete tasks sequentially (configuration before coding)
- Check off after completion
- Document blockers immediately
- Reference `Psst/agents/shared-standards.md` for threading patterns
- All async operations must not block main thread
- Token registration and refresh happen in background
- Permission request is one-time per user (respect their choice)
- Test notifications thoroughly in all app states (foreground, background, terminated)
- APNs key (.p8 file) can only be downloaded once - store securely
- Key ID and Team ID required for Firebase configuration - record before leaving Apple Developer Portal

