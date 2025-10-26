# PR #009 Implementation Quick-Reference Guide

**Feature:** Trainer-Client Relationship System & Contact Management
**For:** Caleb (Coder Agent)
**Date:** October 25, 2025
**Status:** Ready for Implementation

**Required Reading:**
- PRD: `Psst/docs/prds/pr-009-prd.md`
- TODO: `Psst/docs/todos/pr-009-todo.md`
- This guide (you're reading it)

**Reference Documents** (read if you hit questions):
- Arnold's Brownfield Analysis: `Psst/docs/brownfield-analysis-pr-009.md`
- Quinn's Risk Assessment: `Psst/docs/risk-assessment-pr-009.md`
- Claudia's UX Specs: `Psst/docs/ux-specs/pr-009-ux-spec.md`

---

## 1. Critical Integration Points (From Arnold)

### Files You MUST Modify

#### A. ChatService.swift (Lines 144-214)
**Location:** `/Users/finessevanes/Desktop/gauntlet-02/Psst/Psst/Services/ChatService.swift`

**Change:** Add relationship validation to `createChat(withUserID:)` method

**Critical Code Pattern:**
```swift
func createChat(withUserID targetUserID: String) async throws -> String {
    guard let currentUserID = Auth.auth().currentUser?.uid else {
        throw ChatError.notAuthenticated
    }

    guard targetUserID != currentUserID else {
        throw ChatError.cannotChatWithSelf
    }

    // NEW: Feature flag check (MANDATORY)
    if FeatureFlags.enableRelationshipValidation {
        // Get both users to determine roles
        let currentUser = try await UserService.shared.getUser(id: currentUserID)
        let targetUser = try await UserService.shared.getUser(id: targetUserID)

        // Determine trainer/client based on roles
        if currentUser.role == .trainer && targetUser.role == .client {
            // Validate trainer → client relationship
            let hasRelationship = try await contactService.validateRelationship(
                trainerId: currentUserID,
                clientId: targetUserID
            )
            if !hasRelationship {
                throw ChatError.relationshipNotFound
            }
        } else if currentUser.role == .client && targetUser.role == .trainer {
            // Validate client → trainer relationship (reversed)
            let hasRelationship = try await contactService.validateRelationship(
                trainerId: targetUserID,
                clientId: currentUserID
            )
            if !hasRelationship {
                throw ChatError.relationshipNotFound
            }
        }
        // Both trainers or both clients: no validation (business decision)
    }

    // Continue with existing duplicate check and chat creation...
}
```

**New Error Case:**
```swift
enum ChatError: LocalizedError {
    // ... existing cases ...
    case relationshipNotFound  // NEW

    var errorDescription: String? {
        switch self {
        // ... existing cases ...
        case .relationshipNotFound:
            return "This trainer hasn't added you as a client yet"
        }
    }
}
```

**⚠️ IMPORTANT:** Group chats bypass validation (by design).

---

#### B. UserService.swift (Add New Method)
**Location:** `/Users/finessevanes/Desktop/gauntlet-02/Psst/Psst/Services/UserService.swift`

**Change:** Add email lookup method

**New Method:**
```swift
/// Lookup user by email address
/// Used by ContactService when adding clients
/// - Parameter email: User's email address
/// - Returns: User object if found
/// - Throws: UserServiceError.userNotFound if no user with that email exists
func getUserByEmail(_ email: String) async throws -> User {
    // Validate email format
    guard email.contains("@") else {
        throw UserServiceError.invalidEmail
    }

    Log.i("UserService", "Looking up user by email: \(email)")

    do {
        // Query Firestore (REQUIRES INDEX - see section 2)
        let snapshot = try await db.collection(usersCollection)
            .whereField("email", isEqualTo: email)
            .limit(to: 1)
            .getDocuments()

        guard let document = snapshot.documents.first else {
            Log.w("UserService", "No user found with email: \(email)")
            throw UserServiceError.userNotFound
        }

        let user = try document.data(as: User.self)

        // Cache the user
        userCache[user.id] = user

        Log.i("UserService", "Found user by email: \(user.displayName)")
        return user

    } catch let error as UserServiceError {
        throw error
    } catch {
        Log.e("UserService", "Failed to lookup user by email: \(error.localizedDescription)")
        throw UserServiceError.fetchFailed(error)
    }
}
```

**Performance Target:** < 200ms (from PRD)

---

#### C. firestore.rules (Add New Rules)
**Location:** `/Users/finessevanes/Desktop/gauntlet-02/Psst/firestore.rules`

**Change:** Add security rules for new `/contacts` collections

**New Rules:**
```javascript
// Contacts collection - trainer-client relationships
match /contacts/{trainerId}/clients/{clientId} {
  // Only trainer can read/write their own clients
  allow read, write: if request.auth != null &&
                        request.auth.uid == trainerId;
}

match /contacts/{trainerId}/prospects/{prospectId} {
  // Only trainer can read/write their own prospects
  allow read, write: if request.auth != null &&
                        request.auth.uid == trainerId;
}
```

**⚠️ DO NOT** add complex relationship validation to security rules (Arnold recommends keeping rules simple).

**Deployment Command:**
```bash
cd /Users/finessevanes/Desktop/gauntlet-02/Psst
firebase deploy --only firestore:rules
```

---

## 2. Mandatory Pre-Deployment Checklist (From Quinn)

### P0 - MUST COMPLETE BEFORE PRODUCTION

#### ✅ 1. Create Firestore Index on Email Field
**CRITICAL:** Email lookup will FAIL without this index.

**Method 1: Automatic (Recommended)**
```bash
# Run email lookup once in development
# Firestore will throw error with index creation link
# Click link → Index auto-created in ~2 minutes
```

**Method 2: Manual**
Add to `firestore.indexes.json`:
```json
{
  "indexes": [
    {
      "collectionGroup": "users",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "email",
          "order": "ASCENDING"
        }
      ]
    }
  ]
}
```

Then deploy:
```bash
firebase deploy --only firestore:indexes
```

**Verification:**
- Firebase Console → Firestore → Indexes tab
- Look for `users` collection index on `email` field
- Status must be "Enabled" (not "Building")

**Performance Impact:**
- Without index: 2-5 seconds (UNACCEPTABLE)
- With index: 50-150ms (ACCEPTABLE)

---

#### ✅ 2. Implement Feature Flag for Relationship Validation
**CRITICAL:** Must allow instant rollback without code deployment.

**Setup: Firebase Remote Config**
1. Firebase Console → Remote Config
2. Add new parameter:
   - Key: `enable_relationship_validation`
   - Type: Boolean
   - Default value: `false`
   - Description: "Enable trainer-client relationship validation in ChatService"

**Implementation:**
```swift
// FeatureFlags.swift (NEW FILE)
import FirebaseRemoteConfig

struct FeatureFlags {
    static var enableRelationshipValidation: Bool {
        let remoteConfig = RemoteConfig.remoteConfig()
        return remoteConfig.configValue(forKey: "enable_relationship_validation").boolValue
    }
}
```

**Fetch Remote Config on App Launch:**
```swift
// AppDelegate.swift or PsstApp.swift
let remoteConfig = RemoteConfig.remoteConfig()
let settings = RemoteConfigSettings()
settings.minimumFetchInterval = 3600 // 1 hour in production, 0 in dev
remoteConfig.configSettings = settings

remoteConfig.fetch { status, error in
    if status == .success {
        remoteConfig.activate()
    }
}
```

**Testing:**
- [ ] Flag = false → Chat creation works without validation (old behavior)
- [ ] Flag = true → Chat creation validates relationships
- [ ] Toggle flag in Firebase Console → Verify app picks up change within 1 hour

**Rollback Time:** < 5 minutes (toggle flag + app fetches new value)

---

#### ✅ 3. Test Migration Script in Staging
**CRITICAL:** Migration failure = users locked out.

**Pre-Migration Steps:**
1. **Backup Firestore:**
   ```bash
   gcloud firestore export gs://[BUCKET_NAME]/backups/pr009-pre-migration
   ```

2. **Run Dry-Run Migration (Staging):**
   ```bash
   # Call Cloud Function with dryRun=true
   # Review logs for expected client counts
   # Verify no errors
   ```

3. **Run Real Migration (Staging):**
   ```bash
   # Call Cloud Function with dryRun=false
   # Monitor logs for completion
   # Verify contacts appear in ContactsView for test trainers
   ```

4. **Verify Migration Success:**
   - Open staging app
   - Log in as test trainer
   - Check ContactsView → Should show existing clients
   - Try creating chat → Should work

**Migration Script Location:** `/Users/finessevanes/Desktop/gauntlet-02/Psst/functions/migrations/migrateExistingChats.ts`

**Key Features:**
- Batch processing (50 trainers at a time)
- Checkpointing (resume from failures)
- Idempotent (safe to re-run)
- Dry-run mode (preview without writes)

**Estimated Time:**
- 1000 trainers: ~20 minutes
- 100 trainers: ~2 minutes

**Red Flags (Abort if you see these):**
- Error rate > 10% (data inconsistencies)
- Script timeout (batch size too large)
- Duplicate client errors (uniqueness constraint failing)

---

#### ✅ 4. Create Comprehensive Test Suite
**Target Coverage:** 90%+ for ContactService, ChatService modifications

**Critical Test Cases (Must Pass):**

**ContactService Tests:**
```swift
// ContactServiceTests.swift
func testAddClient_Success() async throws
func testAddClient_UserNotFound() async throws
func testAddClient_InvalidEmail() async throws
func testAddClient_DuplicateClient() async throws
func testValidateRelationship_Exists_ReturnsTrue() async throws
func testValidateRelationship_Missing_ReturnsFalse() async throws
```

**ChatService Tests (Modified):**
```swift
// ChatServiceTests.swift
func testCreateChat_WithValidRelationship_Succeeds() async throws
func testCreateChat_NoRelationship_ThrowsError() async throws
func testCreateChat_TrainerToClient_CorrectRoleDetection() async throws
func testCreateChat_ClientToTrainer_CorrectRoleDetection() async throws
func testCreateChat_BothTrainers_NoValidationNeeded() async throws
func testCreateChat_GroupChat_BypassesValidation() async throws
func testCreateChat_FeatureFlagDisabled_NoValidation() async throws
```

**UserService Tests:**
```swift
// UserServiceTests.swift
func testGetUserByEmail_Success() async throws
func testGetUserByEmail_NotFound() async throws
func testGetUserByEmail_InvalidEmail() async throws
func testGetUserByEmail_Performance() async throws // Must be < 200ms
```

**Run Tests:**
```bash
xcodebuild test \
  -scheme Psst \
  -destination 'platform=iOS Simulator,name=Vanes' \
  -only-testing:PsstTests/ContactServiceTests \
  -only-testing:PsstTests/ChatServiceTests \
  -only-testing:PsstTests/UserServiceTests
```

**Pass Criteria:** 100% of P0 tests pass, < 2 seconds total execution time

---

#### ✅ 5. Enable Firestore Offline Persistence
**Purpose:** Graceful degradation when network unavailable

**Implementation:**
```swift
// Already in AppDelegate or PsstApp initialization
let settings = FirestoreSettings()
settings.isPersistenceEnabled = true
Firestore.firestore().settings = settings
```

**Behavior:**
- ContactsView shows cached contacts when offline
- Add Client button disabled when offline
- Network banner: "Offline - Showing cached contacts"

**Testing:**
- [ ] Turn off WiFi/cellular
- [ ] Open ContactsView → Shows last cached contacts
- [ ] Try to add client → Button disabled or shows error
- [ ] Turn on network → Contacts refresh automatically

---

#### ✅ 6. Add Analytics Events for Monitoring
**Purpose:** Track validation failures, detect issues early

**Events to Track:**
```swift
// ContactService.swift
Analytics.logEvent("contact_added", parameters: [
    "contact_type": "client",  // or "prospect"
    "trainer_id": trainerId,
    "method": "email_lookup"  // or "manual"
])

// ChatService.swift (when validation fails)
Analytics.logEvent("relationship_validation_failed", parameters: [
    "trainer_id": trainerId,
    "client_id": clientId,
    "current_user_role": currentUser.role.rawValue,
    "target_user_role": targetUser.role.rawValue
])

// ChatService.swift (when validation succeeds)
Analytics.logEvent("relationship_validation_passed", parameters: [
    "trainer_id": trainerId,
    "client_id": clientId
])
```

**Monitoring Dashboard:**
- Firebase Console → Analytics → Events
- Watch for: `relationship_validation_failed` spike (indicates migration issue or bug)
- Target: < 1% failure rate

---

## 3. Top 3 Critical Risks (From Quinn)

### Risk #1: Breaking Existing Chat Functionality
**Severity:** CRITICAL | **Likelihood:** 70% → 15% (with mitigations)

**What Could Go Wrong:**
- Relationship validation blocks legitimate conversations
- Users see "This trainer hasn't added you yet" for existing clients
- Chat creation fails silently

**Mitigation Checklist:**
- [x] Feature flag implemented (section 2.2)
- [x] Gradual rollout plan: 10% → 50% → 100% over 4 weeks
- [x] Rollback procedure: Disable flag in < 5 minutes
- [x] Manual testing: 8 scenarios (see Arnold's doc section 5.5)
- [x] Enhanced logging (Analytics events)

**Rollback Trigger:** If chat creation error rate > 5%, immediately disable flag.

---

### Risk #2: Migration Script Failures
**Severity:** CRITICAL | **Likelihood:** 40% → 10% (with mitigations)

**What Could Go Wrong:**
- Script times out with large user base
- Incomplete migration (some trainers missing clients)
- Race conditions (users creating chats during migration)

**Mitigation Checklist:**
- [x] Batch processing with checkpoints (section 2.3)
- [x] Idempotent script (safe to re-run)
- [x] Dry-run testing in staging
- [x] Firestore backup before production migration
- [x] Monitoring: Review migration logs for errors

**Recovery Plan:**
- If < 10% trainers affected: Manually re-run script for those trainers
- If > 10% affected: Rollback entire migration, fix script, retry

**Estimated Migration Time:** 20 minutes for 1000 trainers

---

### Risk #3: Email Lookup Performance Degradation
**Severity:** HIGH | **Likelihood:** 60% → 5% (with Firestore index)

**What Could Go Wrong:**
- Email lookup takes > 5 seconds (timeout)
- Add Client form hangs, poor UX
- Firestore quota exceeded

**Mitigation Checklist:**
- [x] Firestore index on email field (section 2.1) - MANDATORY
- [x] 5-second timeout on lookup
- [x] Skeleton loader during lookup (from Claudia)
- [x] Performance test: Verify < 200ms with 10,000+ users

**Performance Targets:**
- Target: < 200ms
- Acceptable: 200-500ms
- Unacceptable: > 500ms (show timeout error)

**Monitoring:**
- Firebase Console → Firestore → Usage tab
- Watch for: Query time spike, quota warnings

---

## 4. Key UX Implementation Notes (From Claudia)

### Navigation: New 4th Tab
**Decision:** Add Contacts as dedicated tab in bottom navigation

**Tab Bar Order:**
1. 💬 Chats
2. 👥 Contacts (NEW)
3. 👤 Profile
4. ⚙️ Settings

**SF Symbol:** `person.2.fill`
**Active Color:** Blue (#007AFF)

**Implementation:**
```swift
// MainTabView.swift
TabView {
    ChatListView()
        .tabItem {
            Label("Chats", systemImage: "message.fill")
        }

    ContactsView()  // NEW
        .tabItem {
            Label("Contacts", systemImage: "person.2.fill")
        }

    ProfileView()
        .tabItem {
            Label("Profile", systemImage: "person.fill")
        }

    SettingsView()
        .tabItem {
            Label("Settings", systemImage: "gearshape.fill")
        }
}
```

---

### Email Lookup: Multi-Stage Progress
**Purpose:** Make 200ms lookup feel faster with staged feedback

**States:**
1. **User types email** (0ms)
   - Real-time validation (green checkmark if valid format)

2. **User taps "Add Client"** (0ms)
   - Button → "Looking up user..." + spinner

3. **Lookup in progress** (0-200ms)
   - Display Name field shows: "Looking up user..." + spinner

4. **User found** (200ms)
   - Display Name field animates:
     - "Jane Smith" fades in
     - Green checkmark appears (bounce animation)
     - Background flashes light green for 1 second
   - Button changes to: "Add Jane Smith"
   - Haptic feedback (light impact)

5. **Adding to Firestore** (200-500ms)
   - Button: "Adding..." + spinner

6. **Success** (500ms total)
   - Sheet dismisses
   - Client appears in list (top of "My Clients" section)
   - Toast: "✅ Added Jane Smith as client"
   - Haptic feedback (success)

**Total Time:** ~6 seconds from open sheet to success (feels faster due to progress stages)

---

### Two-Section List Design
**Purpose:** Clear visual distinction between clients and prospects

**Section 1: MY CLIENTS (count)**
- Font: SF Pro Text Semibold 13pt, ALL CAPS, Gray
- Rows: Avatar + Display Name + "Added X days ago"
- Swipe Action: [Remove] (red, destructive)

**Section 2: PROSPECTS (count)**
- Font: Same as MY CLIENTS
- Rows: Avatar + Display Name + "👤 Prospect · Added X days ago"
- Badge: "👤 Prospect" (inline, light gray background)
- Swipe Actions: [Upgrade] (blue, primary) + [Delete] (red, destructive)

**Visual Hierarchy:**
- Clients prioritized (shown first, above prospects)
- Prospect badge subtle (not distracting)

---

### Error Messaging: Empathetic & Actionable
**Principle:** Assume good intent, suggest next steps

**Example 1: User Not Found**
```
⚠️ User not found

This email isn't associated with a Psst account yet.
Add them as a prospect instead.

[Add as Prospect →]
```

**Example 2: Duplicate Client**
```
ℹ️ Already a client

Jane Smith is already in your client list.

[View Client →]
```

**Example 3: Network Error**
```
🌐 No internet connection

Please check your connection and try again.

[Retry]
```

**Toast Styling:**
- Background: Light color (orange for warnings, blue for info)
- Border: 1pt colored border
- Icon: Emoji or SF Symbol
- Duration: 3-4 seconds (auto-dismiss) or manual dismiss for errors

---

### Performance Perception Techniques
**Goal:** Make 300ms feel like 100ms

**1. Skeleton Loaders (Initial Load)**
- Show 8-10 gray rectangles shaped like contact rows
- Shimmer animation (gradient moves left → right)
- Transitions to real content with fade-in

**2. Optimistic UI Updates**
- Add client: Row appears immediately, API call in background
- Remove client: Row disappears immediately (slide-out animation)
- If API fails: Rollback change, show error toast

**3. Staggered Row Animations**
- Rows fade in with 50ms delay between each
- Creates smooth top-to-bottom flow
- Hides loading time (looks intentional)

**4. Haptic Feedback**
- Light impact on success (client added)
- Medium impact on button tap
- Error haptic on validation failure
- Makes actions feel instant (< 10ms feedback)

**5. No Debounce on Search**
- Filter results as user types (< 100ms response)
- In-memory array filter (not Firestore query)
- Feels more responsive than debounced search

---

## 5. Quick Troubleshooting Guide

### Issue: "The query requires an index" error
**Cause:** Firestore index not created on email field
**Fix:** See section 2.1 - Create Firestore Index
**Time to Fix:** 2-5 minutes (automatic index creation)

---

### Issue: Chat creation fails with "relationship not found"
**Cause:** Migration script didn't run or failed
**Fix:**
1. Check feature flag is disabled (immediate workaround)
2. Run migration script for affected trainers
3. Verify `/contacts/{trainerId}/clients/{clientId}` documents exist in Firestore
**Time to Fix:** 5 minutes (disable flag) or 30 minutes (re-run migration)

---

### Issue: Email lookup takes > 5 seconds
**Cause:** Firestore index missing or not enabled
**Fix:**
1. Verify index status in Firebase Console (must be "Enabled", not "Building")
2. If building: Wait 2-5 minutes for completion
3. If missing: Create index (see section 2.1)
**Time to Fix:** 2-10 minutes

---

### Issue: ContactsView shows 0 clients despite having chats
**Cause:** Migration script didn't run or user created chats after migration
**Fix:**
1. Check Firestore: `/contacts/{trainerId}/clients/` should have documents
2. If empty: Re-run migration script for that trainer
3. If documents exist but UI shows 0: Check ContactsViewModel logic
**Time to Fix:** 10-30 minutes

---

### Issue: Feature flag changes not picked up by app
**Cause:** Remote Config not fetching or fetch interval too long
**Fix:**
1. Force fetch on app launch (set `minimumFetchInterval = 0` in dev)
2. Verify Remote Config parameter name matches code: `enable_relationship_validation`
3. Force quit app and reopen (triggers fresh fetch)
**Time to Fix:** 1 minute (force quit) or adjust fetch interval in code

---

### Issue: Tests failing with "User not found" errors
**Cause:** Test Firestore database doesn't have test users seeded
**Fix:**
1. Create test users in setUp() method:
   ```swift
   let testTrainer = User(role: .trainer, email: "trainer@test.com")
   let testClient = User(role: .client, email: "client@test.com")
   ```
2. Use Firestore emulator for tests (avoid production database)
**Time to Fix:** 5 minutes (add test fixtures)

---

## 6. Deployment Checklist

### Pre-Deployment (Complete BEFORE merging PR)
- [ ] All P0 items from section 2 completed
- [ ] Unit tests passing (90%+ coverage)
- [ ] Manual testing completed (8 scenarios)
- [ ] Feature flag created in Firebase Remote Config (default: false)
- [ ] Firestore index on email field (status: Enabled)
- [ ] Migration script tested in staging (dry-run + real)
- [ ] Security rules deployed to staging
- [ ] Firestore backup created
- [ ] Analytics events configured

### Deployment Day (Production)
- [ ] Merge PR to develop branch
- [ ] Deploy security rules: `firebase deploy --only firestore:rules`
- [ ] Deploy Cloud Functions: `firebase deploy --only functions`
- [ ] Run migration script (dry-run first, then real)
- [ ] Verify migration logs (check error rate < 5%)
- [ ] Test manually: Add client, create chat (with flag disabled)
- [ ] Submit iOS app to App Store (if changes require app update)

### Post-Deployment (Week 1)
- [ ] Enable feature flag for internal accounts (5-10 users)
- [ ] Monitor chat creation error rate (target: < 1%)
- [ ] Monitor Analytics: `relationship_validation_failed` events
- [ ] Review user feedback (support tickets, app reviews)
- [ ] If stable: Enable for 10% of users (A/B test)

### Week 2-4 (Gradual Rollout)
- [ ] Week 2: 10% of users
- [ ] Week 3: 50% if error rate < 1%
- [ ] Week 4: 100% if error rate < 0.5%
- [ ] Monitor Firebase costs (expected: +$15-25/month)

---

## 7. Estimated Implementation Time

**Core Implementation (P0):**
- Data Models (Client, Prospect, Contact): 2 hours
- ContactService (10 methods): 4 hours
- UserService.getUserByEmail(): 1 hour
- ChatService modifications: 2 hours
- ContactsView + AddClientView + AddProspectView: 4 hours
- ContactsViewModel: 2 hours
- Security rules: 1 hour
- Feature flag setup: 1 hour
- **Total P0:** ~17 hours

**Polish (P1):**
- Swipe actions: 2 hours
- Skeleton loaders: 1 hour
- Staggered animations: 1 hour
- Search functionality: 2 hours
- Empty states: 1 hour
- Error handling: 2 hours
- **Total P1:** ~9 hours

**Testing:**
- Unit tests: 4 hours
- Manual testing: 2 hours
- Migration script testing: 2 hours
- **Total Testing:** ~8 hours

**Grand Total:** ~34 hours (4-5 days of focused work)

---

## 8. Success Criteria

**Definition of Done:**
- [ ] All files created as specified in TODO
- [ ] All P0 checklist items completed (section 2)
- [ ] Unit tests passing with 90%+ coverage
- [ ] Manual testing: All 8 scenarios pass
- [ ] Migration script tested and verified in staging
- [ ] Feature flag working (can toggle on/off)
- [ ] Firestore index created and enabled
- [ ] Security rules deployed and tested
- [ ] No regressions: Existing chats still work with flag disabled
- [ ] Performance: Email lookup < 200ms, contact list < 500ms
- [ ] UX: Matches Claudia's spec (navigation, animations, error messages)

**Ready for Production When:**
- [ ] All success criteria met
- [ ] User reviewed and approved implementation
- [ ] Migration script ran successfully in staging
- [ ] Rollback procedure documented and tested
- [ ] Monitoring dashboard configured (Analytics + Firestore)

---

## Need Help?

**Architecture Questions:** Read Arnold's full analysis (`brownfield-analysis-pr-009.md`)
**Risk/Testing Questions:** Read Quinn's assessment (`risk-assessment-pr-009.md`)
**UX/Design Questions:** Read Claudia's specs (`ux-specs/pr-009-ux-spec.md`)
**Feature Questions:** Read PRD (`prds/pr-009-prd.md`)
**Implementation Steps:** Follow TODO (`todos/pr-009-todo.md`)

**Critical Reminders:**
1. 🚨 Feature flag is MANDATORY (allows instant rollback)
2. 🚨 Firestore index on email is MANDATORY (lookup will fail without it)
3. 🚨 Test migration script in staging BEFORE production
4. 🚨 Deploy with flag DISABLED, enable gradually (10% → 50% → 100%)

**You've got this! 💪**

---

**Document Version:** 1.0
**Created:** October 25, 2025
**Author:** Pam (Product Manager Agent)
**Purpose:** Consolidate 3 analysis docs into actionable implementation guide for Caleb
