# PRD: Firebase Project Setup and SDK Integration

**Feature**: project-setup-and-firebase-integration

**Version**: 1.0

**Status**: Ready for Development

**Agent**: Pam (Planning)

**Target Release**: Phase 1 - Foundation

**Links**: [PR Brief - PR #1](../pr-briefs.md#pr-1-project-setup-and-firebase-integration)

---

## 1. Summary

Set up the Firebase backend infrastructure for the Psst messaging app by integrating Firebase Authentication, Firestore Database, Firebase Realtime Database, and Firebase Cloud Messaging into the iOS application. This PR establishes the foundation that all subsequent features will build upon, enabling real-time messaging, authentication, and push notifications.

---

## 2. Problem & Goals

**Problem**: The Psst iOS app needs a robust, scalable backend infrastructure to support real-time messaging, user authentication, data persistence, and push notifications. Setting up these services manually would be time-consuming and complex.

**Why now**: This is PR #1 with no dependencies, making it the critical foundation that must be completed before any other features can be developed.

**Goals** (ordered, measurable):
  - [x] G1 — Firebase project created and all required services enabled (Auth, Firestore, Realtime DB, FCM)
  - [x] G2 — Firebase SDK successfully integrated into iOS app with proper configuration files
  - [x] G3 — Firebase initialized on app launch with verified connectivity to all services
  - [x] G4 — Development environment ready for subsequent PRs (emulators optional but recommended)

---

## 3. Non-Goals / Out of Scope

Call out what's intentionally excluded to avoid scope creep.

- [ ] Not implementing any UI components (handled in PR #2 and beyond)
- [ ] Not implementing actual authentication flows (PR #2)
- [ ] Not creating any data models or services (PR #3+)
- [ ] Not implementing security rules for Firestore/Realtime DB (handled per feature)
- [ ] Not deploying Cloud Functions (PR #19)
- [ ] Not configuring APNs certificates (PR #18)

---

## 4. Success Metrics

Reference `Psst/agents/shared-standards.md` for metric templates:

**User-visible**: 
- No direct user-facing impact (infrastructure setup)

**System**: 
- Firebase SDK initializes in < 500ms on app launch
- Firebase configuration files properly validated
- All Firebase services accessible and responding

**Quality**: 
- 0 blocking bugs
- All acceptance gates pass
- Firebase console shows app successfully connected
- No console warnings or errors related to Firebase initialization

---

## 5. Users & Stories

- As a **developer**, I want Firebase properly configured so that I can build authentication and messaging features on a reliable backend.
- As a **developer**, I want clear Firebase initialization so that I can debug connection issues easily.
- As a **future user** (indirect), I want a robust backend foundation so that my messages are delivered reliably and my data is secure.

---

## 6. Experience Specification (UX)

**Entry points and flows**:
- App launch → Firebase auto-initializes in `AppDelegate` or `App` struct
- No user-visible UI for this PR
- Developers can verify setup via Firebase console and Xcode console logs

**Visual behavior**: 
- No visual components in this PR
- Console logs should show successful Firebase initialization

**Loading/disabled/error states**: 
- If Firebase fails to initialize, log clear error to console (don't crash app)
- Add basic error handling for missing configuration file

**Performance**: 
- Firebase initialization must complete in < 500ms
- No blocking of main thread during initialization
- App should remain responsive during Firebase setup

---

## 7. Functional Requirements (Must/Should)

**MUST**:
- MUST create Firebase project in Firebase Console with all required services enabled
- MUST download and add `GoogleService-Info.plist` to Xcode project
- MUST integrate Firebase SDK via Swift Package Manager (SPM)
- MUST initialize Firebase on app launch using `FirebaseApp.configure()`
- MUST enable Firestore offline persistence (`isPersistenceEnabled = true`)
- MUST verify all services are accessible (Auth, Firestore, Realtime DB, FCM)

**SHOULD**:
- SHOULD create `FirebaseService.swift` as central configuration point
- SHOULD add environment-specific configurations (dev vs prod) if using multiple Firebase projects
- SHOULD document Firebase project structure and service organization
- SHOULD set up Firebase emulators for local development (optional but recommended)

**Acceptance gates per requirement**:
- [Gate] Firebase project exists with Auth, Firestore, Realtime DB, FCM enabled
- [Gate] `GoogleService-Info.plist` added to Xcode project and included in target
- [Gate] Firebase SDK dependencies resolved via SPM with no errors
- [Gate] App launches successfully with Firebase initialized
- [Gate] Xcode console shows "Firebase configured successfully" or equivalent
- [Gate] Firebase console shows app as "connected" with recent activity timestamp
- [Gate] No Firebase-related warnings or errors in console

---

## 8. Data Model

**No data models created in this PR**. This PR only sets up infrastructure.

**Firebase Project Details**:
- Project Name: `psst`
- Project ID: `psst-fef89`
- Project Number: `505865284795`

**Firebase Project Structure**:
```
Firebase Project: psst (psst-fef89)
├── Authentication (enabled)
├── Firestore Database (enabled, production mode initially)
├── Realtime Database (enabled, for presence)
└── Cloud Messaging (enabled)
```

**Firestore Configuration**:
- Offline persistence: `enabled`
- Cache size: default (40 MB)
- Server timestamps: enabled by default

**Realtime Database Configuration**:
- Location: Choose closest region (e.g., `us-central1`)
- Rules: Start in test mode (will be secured in later PRs)

---

## 9. API / Service Contracts

**FirebaseService.swift** — Central configuration point (optional but recommended)

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
    }
    
    // Convenience accessors
    var auth: Auth { Auth.auth() }
    var firestore: Firestore { Firestore.firestore() }
    var realtimeDB: Database { Database.database() }
    var messaging: Messaging { Messaging.messaging() }
}
```

**Pre/post-conditions**:
- Pre: `GoogleService-Info.plist` must exist in project
- Post: All Firebase services accessible via `FirebaseService.shared`

**Error handling strategy**:
- Log errors to console
- Don't crash app if Firebase fails to initialize
- Gracefully degrade if services unavailable

---

## 10. UI Components to Create/Modify

**Files to Create**:
- `App/FirebaseService.swift` — Central Firebase configuration (optional but recommended)

**Files to Modify**:
- `PsstApp.swift` — Initialize Firebase on app launch
- `project.pbxproj` — Add `GoogleService-Info.plist` to project

**No SwiftUI views created in this PR**.

---

## 11. Integration Points

**External Services**:
- Firebase Console (web) — Create project and enable services
- Firebase Authentication — Service enabled, no configuration yet
- Firestore Database — Service enabled with offline persistence
- Firebase Realtime Database — Service enabled for future presence tracking
- Firebase Cloud Messaging — Service enabled for future push notifications

**iOS Integrations**:
- Swift Package Manager — Firebase SDK dependency management
- Xcode Project — Configuration file integration
- App lifecycle — Firebase initialization on launch

---

## 12. Test Plan & Acceptance Gates

Define BEFORE implementation. Use checkboxes.

### Happy Path
- [ ] Firebase project verified: `psst` (ID: `psst-fef89`, Number: `505865284795`)
- [ ] All required services enabled (Auth, Firestore, Realtime DB, FCM)
- [ ] Gate: All services show "active" status in Firebase Console for project `psst-fef89`

- [ ] `GoogleService-Info.plist` downloaded from Firebase Console
- [ ] Gate: File contains valid project configuration

- [ ] Firebase SDK added via Swift Package Manager
- [ ] Gate: SPM resolves all dependencies without errors

- [ ] Firebase initialized in `PsstApp.swift`
- [ ] Gate: App builds and runs without Firebase-related errors

- [ ] Firestore offline persistence enabled
- [ ] Gate: `isPersistenceEnabled = true` in code

- [ ] Firebase connection verified
- [ ] Gate: Firebase Console shows app as "connected"
- [ ] Gate: Xcode console shows successful initialization message

### Edge Cases
- [ ] Missing `GoogleService-Info.plist` handled gracefully
- [ ] Gate: App doesn't crash, logs clear error message

- [ ] Invalid configuration file handled
- [ ] Gate: Error logged with actionable message

- [ ] Network unavailable during initialization
- [ ] Gate: App continues to run, Firebase retries connection

### Performance (see shared-standards.md)
- [ ] Firebase initialization < 500ms
- [ ] Gate: Measured via instruments or console timestamps

- [ ] No main thread blocking
- [ ] Gate: App remains responsive during initialization

### Development Setup
- [ ] Documentation added for Firebase setup process
- [ ] Gate: README or docs explain how to add `GoogleService-Info.plist`

- [ ] Firebase Emulators configured (optional)
- [ ] Gate: Local development possible without touching production

---

## 13. Definition of Done

See standards in `Psst/agents/shared-standards.md`:

- [ ] Firebase project created with all services enabled
- [ ] `GoogleService-Info.plist` added to Xcode project
- [ ] Firebase SDK integrated via SPM
- [ ] Firebase initialized on app launch
- [ ] Firestore offline persistence enabled
- [ ] All acceptance gates pass
- [ ] No console warnings or errors
- [ ] Firebase Console shows app connected
- [ ] Documentation updated (README with setup instructions)
- [ ] Code reviewed and merged to `develop` branch

---

## 14. Risks & Mitigations

**Risk: Wrong `GoogleService-Info.plist` file** (e.g., dev vs prod)
→ Mitigation: Clearly document which Firebase project to use; consider using Xcode schemes for multiple environments

**Risk: Firebase SDK version conflicts**
→ Mitigation: Use SPM with specific version constraints; test on clean build

**Risk: Firestore rules too permissive in test mode**
→ Mitigation: Document that rules will be tightened in subsequent PRs; add reminder to update rules

**Risk: Missing required iOS capabilities/entitlements**
→ Mitigation: Background modes and push notification capabilities will be added in PR #18

**Risk: Firebase initialization failure on app launch**
→ Mitigation: Add error handling and clear logging; app should degrade gracefully

---

## 15. Rollout & Telemetry

**Feature flag**: N/A (infrastructure setup)

**Metrics**: 
- Firebase Console analytics (free tier) shows app connected
- Track initialization time via console logs

**Manual validation steps**:
1. Verify Firebase project exists: `psst` (ID: `psst-fef89`, Number: `505865284795`)
2. Download `GoogleService-Info.plist` from this specific Firebase project
3. Build and run app on simulator
4. Check Xcode console for "Firebase configured successfully"
5. Open Firebase Console → Project `psst-fef89` → Project Overview → check app appears as connected
6. Verify Authentication, Firestore, Realtime DB, FCM all show "active" status

---

## 16. Open Questions

**Q1**: Should we set up multiple Firebase projects (dev, staging, prod)?
→ **Answer**: Start with single project; can add environments later if needed

**Q2**: Should we enable Firebase Analytics?
→ **Answer**: Yes, it's free and useful for debugging; minimal setup required

**Q3**: Should we use CocoaPods or Swift Package Manager?
→ **Answer**: Swift Package Manager (SPM) is modern and integrated into Xcode

**Q4**: Should we set up Firebase Emulators for local development?
→ **Answer**: Recommended but optional; document setup for developers who want it

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future PRs:
- [ ] Firebase security rules (per-feature basis)
- [ ] APNs certificate configuration (PR #18)
- [ ] Cloud Functions deployment (PR #19)
- [ ] Firebase Performance Monitoring (optional)
- [ ] Firebase Crashlytics (optional)
- [ ] Multi-environment setup (dev/prod)

---

## Preflight Questionnaire

**1. Smallest end-to-end user outcome for this PR?**
→ Firebase fully integrated and ready for feature development (no user-facing changes)

**2. Primary user and critical action?**
→ Developers; critical action is initializing Firebase on app launch

**3. Must-have vs nice-to-have?**
→ Must-have: Firebase project, SDK integration, initialization, offline persistence
→ Nice-to-have: Emulators, multi-environment setup, dedicated `FirebaseService` class

**4. Real-time requirements?**
→ Not applicable for this PR (infrastructure only)

**5. Performance constraints?**
→ Firebase initialization < 500ms, no main thread blocking

**6. Error/edge cases to handle?**
→ Missing config file, invalid config, network unavailable

**7. Data model changes?**
→ None (infrastructure only)

**8. Service APIs required?**
→ Optional: `FirebaseService.swift` for centralized access

**9. UI entry points and states?**
→ None (no UI in this PR)

**10. Security/permissions implications?**
→ Firebase security rules will be added per-feature; start in test mode

**11. Dependencies or blocking integrations?**
→ None (this is PR #1)

**12. Rollout strategy and metrics?**
→ Direct rollout; verify via Firebase Console connection status

**13. What is explicitly out of scope?**
→ All feature development, UI components, authentication flows, data models

---

## Authoring Notes

- ✅ This is a foundation PR — no user-facing features
- ✅ Keep it simple: Firebase project + SDK integration + initialization
- ✅ All subsequent PRs depend on this being done correctly
- ✅ Test thoroughly in Firebase Console and Xcode console
- ✅ Document setup process for other developers
- ✅ Consider creating a dedicated `FirebaseService.swift` for cleaner architecture

