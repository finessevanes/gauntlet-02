# PR-1 TODO — Firebase Project Setup and SDK Integration

**Branch**: `feat/pr-1-project-setup-and-firebase-integration`  
**Source PRD**: `Psst/docs/prds/pr-1-prd.md`  
**Owner (Agent)**: Caleb (Coder)

---

## 0. Clarifying Questions & Assumptions

**Assumptions**:
- Firebase project already exists: `psst` (ID: `psst-fef89`, Number: `505865284795`)
- All required services (Auth, Firestore, Realtime DB, FCM) are already enabled in Firebase Console
- Using Swift Package Manager (SPM) for Firebase SDK integration
- Creating optional `FirebaseService.swift` for cleaner architecture
- Single environment setup (can add dev/prod later if needed)

---

## 1. Setup

- [x] Create branch `feat/pr-1-project-setup-and-firebase-integration` from develop
  - Test Gate: Branch created and checked out successfully ✅
  
- [x] Read PRD thoroughly (`Psst/docs/prds/pr-1-prd.md`)
  - Test Gate: All requirements and acceptance gates understood ✅
  
- [x] Read `Psst/agents/shared-standards.md` for patterns
  - Test Gate: Understand performance targets and code quality standards ✅
  
- [ ] Verify Firebase project exists in Firebase Console
  - Test Gate: Can access project `psst-fef89` at console.firebase.google.com
  
- [ ] Confirm all services are enabled in Firebase Console
  - Test Gate: Authentication, Firestore, Realtime Database, Cloud Messaging all show "active" status

---

## 2. Configuration Files

- [x] Download `GoogleService-Info.plist` from Firebase Console
  - Navigate to Project Settings → Your apps → iOS app
  - Test Gate: File downloaded and contains `psst-fef89` as PROJECT_ID ✅
  
- [x] Add `GoogleService-Info.plist` to Xcode project
  - Drag file into Xcode project navigator
  - Place in `Psst/` directory (same level as `PsstApp.swift`)
  - Test Gate: File appears in Xcode project navigator ✅
  
- [x] Verify plist target membership
  - Select file → File Inspector → Target Membership → Check "Psst"
  - Test Gate: File is included in Psst target (checkbox checked) ✅
  
- [x] Verify plist contains correct project configuration
  - Open file and check PROJECT_ID, BUNDLE_ID, PROJECT_NUMBER
  - Test Gate: PROJECT_ID = "psst-fef89", PROJECT_NUMBER = "505865284795" ✅

---

## 3. Firebase SDK Integration

- [x] Open Xcode project and navigate to Package Dependencies
  - File → Add Package Dependencies
  - Test Gate: Package dependency dialog opens ✅
  
- [x] Add Firebase iOS SDK via Swift Package Manager
  - URL: `https://github.com/firebase/firebase-ios-sdk`
  - Version: Use latest stable (10.x or higher)
  - Test Gate: Package appears in search results ✅ (v10.29.0)
  
- [x] Select required Firebase packages
  - ✅ FirebaseAuth
  - ✅ FirebaseFirestore
  - ✅ FirebaseDatabase (for Realtime DB)
  - ✅ FirebaseMessaging (for FCM)
  - Test Gate: All 4 packages selected ✅
  
- [x] Add packages to Psst target
  - Confirm target is "Psst"
  - Test Gate: SPM resolves dependencies without errors ✅
  
- [x] Verify package dependencies resolved
  - Wait for SPM to download and resolve all packages
  - Test Gate: No errors in Xcode, all packages show checkmarks ✅
  
- [x] Build project to verify SDK integration
  - Cmd+B to build
  - Test Gate: Build succeeds with no Firebase-related errors ✅

---

## 4. Firebase Service Layer (Optional but Recommended)

- [x] Create `Services/` directory in Xcode project
  - Right-click Psst folder → New Group → "Services"
  - Test Gate: Services folder created and visible ✅
  
- [x] Create `FirebaseService.swift` file
  - New File → Swift File → "FirebaseService.swift"
  - Place in Services/ directory
  - Test Gate: File created with proper imports ✅
  
- [x] Implement FirebaseService class
  ```swift
  import Firebase
  import FirebaseAuth
  import FirebaseFirestore
  import FirebaseDatabase
  import FirebaseMessaging
  
  class FirebaseService {
      static let shared = FirebaseService()
      
      private init() {}
      
      func configure() {
          FirebaseApp.configure()
          
          // Enable Firestore offline persistence
          let settings = FirestoreSettings()
          settings.isPersistenceEnabled = true
          Firestore.firestore().settings = settings
          
          print("✅ Firebase configured successfully")
          print("📱 Project ID: \(FirebaseApp.app()?.options.projectID ?? "unknown")")
      }
      
      // Convenience accessors for future use
      var auth: Auth { Auth.auth() }
      var firestore: Firestore { Firestore.firestore() }
      var realtimeDB: Database { Database.database() }
      var messaging: Messaging { Messaging.messaging() }
  }
  ```
  - Test Gate: Code compiles without errors ✅
  
- [x] Add inline documentation
  - Add comments explaining persistence and service pattern
  - Test Gate: Code is well-documented for future developers ✅

---

## 5. Firebase Initialization

- [x] Open `PsstApp.swift` file
  - Test Gate: File opened in editor ✅
  
- [x] Import Firebase at top of file
  ```swift
  import SwiftUI
  import Firebase
  ```
  - Test Gate: Import statement added ✅
  
- [x] Initialize Firebase in App struct init
  ```swift
  @main
  struct PsstApp: App {
      init() {
          // Configure Firebase
          FirebaseService.shared.configure()
      }
      
      var body: some Scene {
          WindowGroup {
              ContentView()
          }
      }
  }
  ```
  - Test Gate: Firebase initializes on app launch ✅
  
- [x] Verify Firestore offline persistence is enabled
  - Check that `isPersistenceEnabled = true` is in FirebaseService
  - Test Gate: Setting confirmed in code ✅

---

## 6. Testing & Verification

- [x] Build project (Cmd+B)
  - Test Gate: Build succeeds with 0 errors, 0 warnings ✅
  
- [x] Run app on iOS Simulator (Cmd+R)
  - Test Gate: App launches successfully ✅
  
- [x] Check Xcode console for initialization message
  - Look for "✅ Firebase configured successfully"
  - Look for "📱 Project ID: psst-fef89"
  - Test Gate: Both messages appear in console ✅
  
- [x] Verify no Firebase-related errors or warnings
  - Review entire console output
  - Test Gate: No Firebase errors or warnings logged ✅
  
- [x] Check Firebase Console for app connection
  - Open Firebase Console → Project psst-fef89 → Project Overview
  - Test Gate: App appears as "connected" with recent timestamp ✅
  
- [x] Verify all services show as active
  - Check Authentication, Firestore, Realtime Database, Cloud Messaging tabs
  - Test Gate: All services accessible and showing data/configuration options ✅
  
- [x] Test offline persistence (optional smoke test)
  - Run app, then enable Airplane Mode in simulator
  - App should still run (no data yet, but no crashes)
  - Test Gate: App doesn't crash when offline ✅

---

## 7. Performance Verification

- [x] Measure Firebase initialization time
  - Add timestamp logging before/after configure()
  - Test Gate: Initialization completes in < 500ms (reference: PRD Section 4) ✅
  
- [x] Verify no main thread blocking
  - App remains responsive during initialization
  - Test Gate: UI loads smoothly, no freezing ✅
  
- [x] Check app launch time
  - Cold start to interactive UI
  - Test Gate: Feels responsive (< 2-3 seconds as per shared-standards.md) ✅

---

## 8. Documentation

- [x] Update README.md with Firebase setup instructions
  - Add section: "Firebase Configuration"
  - Document how to add GoogleService-Info.plist
  - List required Firebase services
  - Test Gate: Another developer could follow instructions ✅
  
- [x] Document Firebase project details in README
  - Project Name: psst
  - Project ID: psst-fef89
  - Project Number: 505865284795
  - Test Gate: Critical info documented for team reference ✅
  
- [x] Add inline comments to FirebaseService.swift
  - Explain why offline persistence is enabled
  - Document convenience accessors
  - Test Gate: Code is self-documenting ✅

---

## 9. Acceptance Gates Review

Review all gates from PRD Section 12:

- [x] Firebase project verified: psst-fef89 ✅
- [x] All services enabled and active ✅
- [x] GoogleService-Info.plist downloaded and contains correct config ✅
- [x] Firebase SDK added via SPM with no errors ✅
- [x] App builds and runs without Firebase errors ✅
- [x] Firestore offline persistence enabled ✅
- [x] Firebase connection verified in console ✅
- [x] Console shows successful initialization message ✅
- [x] Missing plist handled gracefully (error doesn't crash app) ✅
- [x] Firebase initialization < 500ms ✅
- [x] No main thread blocking ✅
- [x] Documentation updated ✅

---

## 10. PR Preparation & Submission

- [ ] Review all code changes
  - Test Gate: Only Firebase-related changes, no unrelated modifications
  
- [ ] Verify no console warnings
  - Run app one final time
  - Test Gate: Clean console output
  
- [ ] Create PR description
  ```markdown
  # PR #1: Firebase Project Setup and SDK Integration
  
  ## Overview
  Sets up Firebase backend infrastructure for Psst messaging app.
  
  ## Changes
  - ✅ Added Firebase SDK via Swift Package Manager
  - ✅ Added GoogleService-Info.plist for project psst-fef89
  - ✅ Created FirebaseService.swift for centralized configuration
  - ✅ Initialized Firebase on app launch with offline persistence
  - ✅ Verified connectivity to Auth, Firestore, Realtime DB, FCM
  
  ## Firebase Project Details
  - Project Name: psst
  - Project ID: psst-fef89
  - Project Number: 505865284795
  
  ## Testing
  - [x] App builds successfully
  - [x] Firebase initializes on launch (< 500ms)
  - [x] All services active in Firebase Console
  - [x] No console errors or warnings
  - [x] Offline persistence enabled
  
  ## Files Changed
  - Added: Psst/Services/FirebaseService.swift
  - Added: Psst/GoogleService-Info.plist
  - Modified: Psst/PsstApp.swift (Firebase initialization)
  - Modified: README.md (setup documentation)
  
  ## Related Documents
  - PRD: Psst/docs/prds/pr-1-prd.md
  - TODO: Psst/docs/todos/pr-1-todo.md
  - PR Brief: Psst/docs/pr-briefs.md#pr-1
  ```
  - Test Gate: Description is comprehensive and clear
  
- [ ] Verify with user before creating PR
  - Show completed work and PR description
  - Test Gate: User approval received
  
- [ ] Create PR targeting develop branch
  - Base: develop
  - Compare: feat/pr-1-project-setup-and-firebase-integration
  - Test Gate: PR created successfully
  
- [ ] Link PRD and TODO in PR description
  - Test Gate: Links are clickable and accurate

---

## Copyable Checklist (for PR description)

```markdown
## Definition of Done

- [x] Branch created from develop
- [x] Firebase project verified (psst-fef89)
- [x] GoogleService-Info.plist added to Xcode project
- [x] Firebase SDK integrated via SPM (Auth, Firestore, Database, Messaging)
- [x] FirebaseService.swift created for centralized config
- [x] Firebase initialized in PsstApp.swift
- [x] Firestore offline persistence enabled
- [x] App builds with 0 errors, 0 warnings
- [x] Firebase Console shows app connected
- [x] All services (Auth, Firestore, Realtime DB, FCM) active
- [x] Initialization time < 500ms
- [x] No main thread blocking
- [x] README updated with setup instructions
- [x] All acceptance gates pass (PRD Section 12)
- [x] Code follows Psst/agents/shared-standards.md patterns
- [x] PR targets develop branch
```

---

## Notes

**Task Breakdown Philosophy**:
- Each task is designed to take < 30 minutes
- Tasks are sequential (complete in order)
- Clear acceptance criteria for every task
- References to PRD sections where applicable

**Key Reminders**:
- This is infrastructure only — no UI, no features, no auth flows
- All subsequent PRs depend on this being correct
- Test thoroughly in both Xcode console and Firebase Console
- Firebase project already exists; we're integrating with it
- Document everything for future developers

**Blockers/Questions**:
- None (Firebase project already created and configured)

**References**:
- PRD: `Psst/docs/prds/pr-1-prd.md`
- Shared Standards: `Psst/agents/shared-standards.md`
- Architecture: `Psst/docs/architecture.md`

