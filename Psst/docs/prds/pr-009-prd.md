# PRD: Trainer-Client Relationship System & Contact Management

**Feature**: Trainer-Client Relationships & Contacts

**Version**: 1.0

**Status**: Draft

**Agent**: Caleb

**Target Release**: Phase 0 (Prerequisite)

**Links**: [PR Brief](../ai-briefs.md#pr-009), [TODO](../todos/pr-009-todo.md), [Architecture](../architecture.md)

---

## 1. Summary

Replace the current "everyone can access everyone" architecture with explicit trainer-controlled client relationships, enabling trainers to manage their business roster through contact lists and ensuring clients can only message trainers who explicitly added them. This foundational access control system enables trainers to add/manage clients and prospects while establishing security boundaries for all future features.

---

## 2. Problem & Goals

**Problem:**
Currently, any user can message any other user, creating no business boundaries between trainers and clients. This prevents trainers from managing their professional roster, creates security concerns, and makes it impossible to implement trainer-specific features like client profiling or scheduling.

**Why Now:**
This is a prerequisite for PR #010 (Calendar System) and many AI features that require distinguishing trainer-client relationships.

**Goals:**
- [ ] G1 — Trainers can explicitly add clients by email, creating controlled access relationships
- [ ] G2 — Clients can only initiate chats with trainers who added them as clients
- [ ] G3 — Trainers can track prospects (lightweight contacts without email/invitation)
- [ ] G4 — Group chat peer discovery: clients in same group can message each other
- [ ] G5 — Trainers have a centralized ContactsView showing all clients and prospects

---

## 3. Non-Goals / Out of Scope

- [ ] Not implementing invitation email system (clients must already have accounts)
- [ ] Not implementing client-to-client referrals (only through shared groups)
- [ ] Not adding payment/billing features
- [ ] Not implementing client self-signup or onboarding
- [ ] Not building trainer marketplace or discovery
- [ ] Not implementing client-side contact management (only trainers manage relationships)
- [ ] Not adding tagging, notes, or phone fields (minimal MVP)

---

## 4. Success Metrics

**User-visible:**
- Time to add client: < 10 seconds (open form → enter email → submit → success)
- Clients appear in ContactsView within 1 second of adding
- Display name auto-populates from existing user data

**System:**
- Relationship validation happens in < 100ms
- Firebase security rules enforce access control
- Contact list loads in < 500ms
- User lookup by email completes in < 200ms

**Quality:**
- 0 blocking bugs in relationship creation
- All acceptance gates pass
- Crash-free rate >99%
- Existing chat functionality unaffected (backward compatibility)

---

## 5. Users & Stories

**As a trainer**, I want to add existing app users as clients by email so that I can manage my professional relationships and control who can message me.

**As a trainer**, I want to track prospects (leads) by name so that I can manage potential clients before they sign up for the app.

**As a trainer**, I want to upgrade prospects to clients by adding their email so that I can connect with them once they create an account.

**As a trainer**, I want to remove clients from my roster so that former clients no longer have access to message me.

**As a client**, I want clear feedback when I try to message a trainer who hasn't added me so that I understand why I can't initiate contact.

**As a client**, I want to message other clients I meet in group chats so that we can support each other in our fitness journey.

---

## 6. Experience Specification (UX)

### Entry Points

**For Trainers:**
1. **ContactsView** - New dedicated screen accessible from navigation (exact placement TBD - could be tab, menu item, or dedicated button)
2. **Add Client** button in ContactsView (primary action)
3. **Add Prospect** button in ContactsView (secondary action)

**For Clients:**
- Error message when attempting to chat with non-connected trainer
- Notification when trainer adds them as client (optional future enhancement)

### Visual Behavior

**ContactsView:**
- Two sections: "My Clients" and "Prospects"
- Search bar to filter by name
- Pull-to-refresh for sync
- Empty states for new trainers
- Swipe actions: Remove (delete client), Delete (delete prospect)

**Client List Items:**
- Avatar (profile photo or initials)
- Display name
- Last message timestamp

**Prospect List Items:**
- Name
- "👤 Prospect" badge
- "Upgrade to Client" button

**Add Client Form:**
- Display Name (optional, should auto populate once added in the conacts list)
- Email (required, validated) - this is what will be used to find the client in the db
- Success message: "✅ Added [Name] as client. Invitation sent!"

**Add Prospect Form:**
- Display Name (required)
- Success message: "✅ Added [Name] as prospect"

### States

**Loading:**
- Skeleton loaders for contact list
- Spinner during form submission
- "Looking up user..." while searching by email

**Error:**
- "This user is already in your client list" inline error
- "Invalid email format" validation error
- "User not found. Client must have a Psst account" toast error
- "Network error" toast with retry

**Empty:**
- "No clients yet. Add your first client to get started"
- "No prospects yet. Add prospects to track leads"

**Success:**
- "✅ Added [Name] as client" toast confirmation
- "✅ Added [Name] as prospect" toast confirmation
- Smooth animation as new item appears in list

### Performance Targets

See `Psst/agents/shared-standards.md`:
- Contact list loads in < 500ms
- Search filters in < 100ms
- Form submission completes in < 1 second
- Smooth 60fps scrolling with 100+ contacts

---

## 7. Functional Requirements (Must/Should)

### MUST Requirements

**Relationship Creation:**
- MUST allow trainers to add clients with email
- MUST validate email format before creating relationship
- MUST create Firestore document in `/contacts/{trainerId}/clients/{clientId}`
- MUST generate placeholder email `prospect-[name]@psst.app` for prospects

**Access Control:**
- MUST enforce Firebase security rules preventing unauthorized chats
- MUST validate relationship exists before allowing chat creation
- MUST allow clients in same group to message each other (peer discovery)
- MUST show error message when client tries to message unconnected trainer

**Contact Management:**
- MUST display all clients in ContactsView
- MUST display all prospects separately from clients
- MUST support deleting prospects (permanent removal)
- MUST allow searching contacts by name

**Prospect Workflow:**
- MUST support adding prospects with name only
- MUST allow upgrading prospect to client by adding email
- MUST maintain prospect history after conversion (set `convertedToClientId`)

**Group Chat Peer Discovery:**
- MUST detect when trainer adds multiple clients to group
- MUST update security rules to allow peer messaging
- MUST enable 1-on-1 DM between group members

### SHOULD Requirements

- SHOULD track last contacted timestamp
- SHOULD cache relationship status for offline validation

### Acceptance Gates

**Gate 1 - Client Addition:**
- When trainer adds client with valid email → Firestore document created in < 500ms
- When client exists in system → Client is auto added
- When client doesn't exist → Client has not signed up toast error

**Gate 2 - Access Control:**
- When client tries to message unconnected trainer → Error: "This trainer hasn't added you yet"
- When client tries to message connected trainer → Chat created successfully
- When client in group tries to message peer → Chat created successfully

**Gate 3 - Prospect Management:**
- When trainer adds prospect → Document created with placeholder email
- When trainer upgrades prospect → Moves to clients section
- When prospect upgraded → Original prospect record archived (not deleted) ? not sure about this one

**Gate 4 - Contact List:**
- When ContactsView loads → All clients visible in < 500ms
- When trainer searches "Sam" → Results filter in < 100ms
- When trainer removes client → Removed from active list, no longer can access chat

**Gate 5 - Group Peer Discovery:**
- When trainer creates group [Sara, Claudia] → Security rules updated
- When Sara views Claudia's profile in group → "Start Chat" button visible
- When Sara taps "Start Chat" → 1-on-1 DM created successfully

**Gate 6 - Migration:**
- When existing users updated → All current chat participants auto-added as clients
- When migration runs → No data loss, all chats remain accessible

---

## 8. Data Model

### New Firestore Collections

#### `/contacts/{trainerId}/clients/{clientId}`

```typescript
{
  clientId: string;           // References /users/{clientId}
  displayName: string;        // Auto-populated from /users/{clientId}
  email: string;              // Used for lookup
  addedAt: Timestamp;         // When relationship created
  lastContactedAt?: Timestamp; // Last message timestamp (optional)
}
```

**Notes:**
- Status field removed (clients are simply added or removed)
- Display name auto-populates from existing user's profile
- Minimal schema for MVP

#### `/contacts/{trainerId}/prospects/{prospectId}`

```typescript
{
  prospectId: string;         // Auto-generated
  displayName: string;        // Prospect's name
  placeholderEmail: string;   // prospect-[name]@psst.app
  addedAt: Timestamp;
  convertedToClientId?: string; // Set to clientId after upgrade
}
```

**Notes:**
- No notes field (minimal MVP)
- Converted prospects remain in collection for history tracking

### Modified Collections

#### `/users/{userID}` - Add Reference

**New Field:**
```typescript
{
  trainerId?: string;  // For clients: references their trainer
}
```

**Migration Note:** Existing users don't need this immediately. Optional field for future features.

### Indexes Required

```javascript
// Composite index for client queries
collection: "contacts"
fields: [
  { fieldPath: "trainerId", order: "ASCENDING" },
  { fieldPath: "addedAt", order: "DESCENDING" }
]
```

**Note:** Prospect queries don't need composite index (simple queries by trainerId only).

### Validation Rules

**Client Validation:**
- `displayName`: Auto-populated from `/users/{clientId}/displayName`
- `email`: Required, valid email format, must exist in `/users`
- `clientId`: Must reference valid user in `/users` collection

**Prospect Validation:**
- `displayName`: Required, 1-50 characters
- `placeholderEmail`: Auto-generated, format: `prospect-[name]@psst.app`

---

## 9. API / Service Contracts

### ContactService.swift

**Core Methods:**

```swift
/// Add an existing user as a client by email lookup
/// - Parameter email: Client's email address (must exist in /users)
/// - Returns: Client document with auto-populated display name
/// - Throws: ContactError (invalidEmail, userNotFound, alreadyExists, networkError)
func addClient(email: String) async throws -> Client

/// Add a prospect by name only (for leads without accounts)
/// - Parameter name: Prospect's display name
/// - Returns: Prospect document with generated placeholder email
/// - Throws: ContactError (invalidName, networkError)
func addProspect(name: String) async throws -> Prospect

/// Upgrade prospect to client by adding email and looking up existing user
/// - Parameters:
///   - prospectId: ID of prospect to upgrade
///   - email: Client's email address (must exist in /users)
/// - Returns: New Client document
/// - Throws: ContactError (prospectNotFound, invalidEmail, userNotFound, networkError)
func upgradeProspectToClient(
    prospectId: String,
    email: String
) async throws -> Client

/// Get all clients for the current trainer
/// - Returns: Array of Client documents
func getClients() async throws -> [Client]

/// Get all prospects for the current trainer
/// - Returns: Array of Prospect documents
func getProspects() async throws -> [Prospect]

/// Remove a client (deletes relationship, client loses chat access)
/// - Parameter clientId: Client's user ID
/// - Throws: ContactError (clientNotFound, networkError)
func removeClient(clientId: String) async throws

/// Delete a prospect permanently
/// - Parameter prospectId: Prospect's ID
/// - Throws: ContactError (prospectNotFound, networkError)
func deleteProspect(prospectId: String) async throws

/// Search clients and prospects by name
/// - Parameter query: Search query string
/// - Returns: Combined array of clients and prospects matching query
func searchContacts(query: String) async throws -> [Contact]

/// Validate if relationship exists between trainer and client
/// - Parameters:
///   - trainerId: Trainer's user ID
///   - clientId: Client's user ID
/// - Returns: True if active relationship exists
func validateRelationship(trainerId: String, clientId: String) async throws -> Bool

/// Lookup user by email to get display name and user ID
/// - Parameter email: User's email address
/// - Returns: User document if found
/// - Throws: ContactError (userNotFound, invalidEmail, networkError)
func lookupUserByEmail(email: String) async throws -> User
```

**Error Handling:**

```swift
enum ContactError: Error, LocalizedError {
    case invalidEmail
    case invalidName
    case userNotFound  // User doesn't exist in /users collection
    case alreadyExists
    case clientNotFound
    case prospectNotFound
    case networkError
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address"
        case .invalidName:
            return "Name is required"
        case .userNotFound:
            return "User not found. Client must have a Psst account"
        case .alreadyExists:
            return "This user is already in your client list"
        case .clientNotFound:
            return "Client not found in your contacts"
        case .prospectNotFound:
            return "Prospect not found"
        case .networkError:
            return "Network error. Please try again"
        case .unauthorized:
            return "You don't have permission to perform this action"
        }
    }
}
```

### ChatService.swift Updates

**Modified Methods:**

```swift
/// Create new chat with relationship validation
/// - Parameters:
///   - members: Array of user IDs
///   - isGroup: Whether this is a group chat
/// - Returns: Chat ID
/// - Throws: ChatError including .relationshipNotFound
func createChat(
    members: [String],
    isGroup: Bool
) async throws -> String {
    // NEW: Validate relationship exists before creating chat
    // If trainer-client chat, check ContactService
    // If group chat, allow (peer discovery handled separately)
}
```

**Pre-conditions:**
- User must be authenticated
- For 1-on-1 chats: relationship must exist via ContactService
- For group chats: creator must be trainer with relationships to all members

**Post-conditions:**
- Chat document created in Firestore
- All members can access chat
- Security rules validate relationship on every read/write

---

## 10. UI Components to Create/Modify

### New Components

**Views:**
- `Views/Contacts/ContactsView.swift` - Main contact management screen (list of clients and prospects)
- `Views/Contacts/ContactRowView.swift` - Individual contact list item
- `Views/Contacts/AddClientView.swift` - Form to add new client
- `Views/Contacts/AddProspectView.swift` - Form to add new prospect
- `Views/Contacts/ContactDetailView.swift` - View/edit contact details
- `Views/Contacts/UpgradeProspectView.swift` - Upgrade prospect to client form

**Components:**
- `Components/ContactSearchBar.swift` - Search contacts by name
- `Components/ContactSectionHeader.swift` - "My Clients" and "Prospects" headers
- `Components/ContactEmptyState.swift` - Empty state for no contacts

**Services:**
- `Services/ContactService.swift` - Contact CRUD operations and relationship validation

**Models:**
- `Models/Client.swift` - Client data model
- `Models/Prospect.swift` - Prospect data model
- `Models/Contact.swift` - Protocol for unified handling

**ViewModels:**
- `ViewModels/ContactsViewModel.swift` - Manages contact list state and operations

### Modified Components

**Services:**
- `Services/ChatService.swift` - Add relationship validation to `createChat()`
- `Services/UserService.swift` - Add email lookup functionality

**Views:**
- `Views/RootView.swift` or `MainTabView.swift` - Add navigation to ContactsView (exact placement TBD)
- `Views/ChatView.swift` - Show error when trying to chat without relationship

**ViewModels:**
- `ViewModels/ChatListViewModel.swift` - May need to check relationships when displaying chats

---

## 11. Integration Points

**Firebase Authentication:**
- No changes (no invitation flow)

**Firestore:**
- New collections: `/contacts/{trainerId}/clients`, `/contacts/{trainerId}/prospects`
- Query `/users` collection by email for client lookup
- Security rules: Relationship-based access control

**Firebase Realtime Database:**
- No changes (presence tracking unaffected)

**Firebase Cloud Messaging:**
- No changes (no invitation emails)

**State Management:**
- ContactsViewModel observes Firestore listeners
- Cache relationship status locally for offline validation
- Sync state when network reconnects

**UserService Integration:**
- ContactService queries UserService to lookup users by email
- Display name auto-populated from User document

---

## 12. Testing Plan & Acceptance Gates

See `Psst/docs/testing-strategy.md` for detailed guidance.

### Happy Path

**Scenario 1: Trainer Adds Existing Client**
- [ ] Trainer opens ContactsView → Taps "Add Client" → Enters email (existing user) → Taps Submit
- [ ] **Gate:** System looks up user by email and auto-populates display name
- [ ] **Gate:** Client appears in "My Clients" section within 1 second with correct name
- [ ] **Gate:** Firestore document created at `/contacts/{trainerId}/clients/{clientId}`
- [ ] **Pass:** No errors, display name matches user's profile, client visible in list

**Scenario 2: Trainer Adds Prospect**
- [ ] Trainer taps "Add Prospect" → Enters name → Taps Submit
- [ ] **Gate:** Prospect appears in "Prospects" section immediately
- [ ] **Gate:** Placeholder email `prospect-[name]@psst.app` generated
- [ ] **Pass:** No errors, prospect visible in list

**Scenario 3: Trainer Upgrades Prospect to Client**
- [ ] Trainer finds prospect → Taps "Upgrade to Client" → Enters existing user's email → Submits
- [ ] **Gate:** System looks up user, auto-populates display name
- [ ] **Gate:** Prospect moves from "Prospects" to "My Clients" section
- [ ] **Gate:** Original prospect record has `convertedToClientId` set
- [ ] **Pass:** Smooth transition, client now visible in clients list, can be messaged

**Scenario 4: Group Peer Discovery**
- [ ] Trainer creates group chat with Sara and Claudia
- [ ] **Gate:** Sara can view Claudia's profile in group
- [ ] **Gate:** Sara can tap "Start Chat" to DM Claudia
- [ ] **Gate:** 1-on-1 chat created successfully
- [ ] **Pass:** Sara and Claudia can message each other

**Scenario 5: Trainer Removes Client**
- [ ] Trainer swipes on client → Taps "Remove" → Confirms deletion
- [ ] **Gate:** Client disappears from list immediately
- [ ] **Gate:** Firestore document deleted from `/contacts/{trainerId}/clients`
- [ ] **Gate:** Client can no longer message trainer (security rules block)
- [ ] **Pass:** Removal works, relationship terminated, chat access revoked

### Edge Cases

**Edge Case 1: User Not Found**
- [ ] **Test:** Trainer enters email for user who doesn't have a Psst account
- [ ] **Expected:** Toast error: "User not found. Client must have a Psst account"
- [ ] **Pass:** Form not submitted, clear error message, trainer understands client must sign up first

**Edge Case 2: Duplicate Email**
- [ ] **Test:** Trainer tries to add client with email that already exists in client list
- [ ] **Expected:** Inline error: "This user is already in your client list"
- [ ] **Pass:** Form not submitted, error message clear, trainer can correct

**Edge Case 3: Invalid Email Format**
- [ ] **Test:** Trainer enters malformed email (e.g., "notanemail")
- [ ] **Expected:** Validation error: "Please enter a valid email address"
- [ ] **Pass:** Inline error shown, form not submitted

**Edge Case 4: Client Tries to Message Unconnected Trainer**
- [ ] **Test:** Client attempts to start chat with trainer who hasn't added them
- [ ] **Expected:** Error modal: "This trainer hasn't added you yet"
- [ ] **Pass:** Chat not created, clear explanation, no crash

**Edge Case 5: Upgrade Prospect - User Not Found**
- [ ] **Test:** Trainer upgrades prospect with email for non-existent user
- [ ] **Expected:** Toast error: "User not found. Client must have a Psst account"
- [ ] **Pass:** Prospect remains in prospects list, clear error, trainer can retry

**Edge Case 6: Multiple Clients Named "Sam"**
- [ ] **Test:** Trainer searches for "Sam" with 2 Sams in contacts
- [ ] **Expected:** Both Sams shown in search results, distinguishable by email display
- [ ] **Pass:** Search works, no confusion, trainer can identify correct client

### Error Handling

**Offline Mode:**
- [ ] **Test:** Enable airplane mode → Attempt to add client
- [ ] **Expected:** "No internet connection" toast, action queued for retry
- [ ] **Pass:** Clear error message, retry works when online

**Network Timeout:**
- [ ] **Test:** Slow network → Add client takes > 5 seconds
- [ ] **Expected:** Loading spinner → Success or timeout error
- [ ] **Pass:** Timeout handled gracefully, retry option provided

**Invalid Relationship:**
- [ ] **Test:** Client tries to create chat via deep manipulation (URL scheme)
- [ ] **Expected:** Firebase security rules block write, show error
- [ ] **Pass:** Security enforced at database level, no unauthorized access

### Multi-Device Testing (Optional)

**Not required for contacts (not real-time sync feature)**, but recommended:
- [ ] Add client on Device 1 → Verify appears on Device 2 (if same trainer logged in)
- [ ] Remove client on Device 1 → Verify removed on Device 2

### Performance Check

- [ ] Contact list with 50+ clients loads in < 500ms
- [ ] Search filters 100+ contacts in < 100ms
- [ ] Add client form submits in < 1 second
- [ ] Smooth 60fps scrolling with 100+ contacts

---

## 5b. Affected Existing Code

This is a **brownfield enhancement** that modifies existing security and chat creation logic.

### Services to Modify

**ChatService.swift:**
- **Method:** `createChat(members:isGroup:)`
- **Change:** Add relationship validation before creating chat
- **New Logic:**
  ```swift
  // Before creating chat, validate relationship
  if !isGroup && members.count == 2 {
      let trainerId = currentUserID // Assume current user is trainer
      let clientId = members.first(where: { $0 != currentUserID })!
      let hasRelationship = try await contactService.validateRelationship(
          trainerId: trainerId,
          clientId: clientId
      )
      if !hasRelationship {
          throw ChatError.relationshipNotFound
      }
  }
  ```
- **Risk:** Breaking existing chat creation. **Mitigation:** Add feature flag, test thoroughly

**UserService.swift:**
- **Method:** Add email lookup functionality
- **Change:** Create method `getUserByEmail(email: String) -> User?`
- **New Logic:** Query Firestore `/users` collection where `email == email`
- **Risk:** Performance with many users. **Mitigation:** Add Firestore index on email field

### Views to Modify

**RootView.swift or MainTabView.swift:**
- **Change:** Add navigation to ContactsView (exact placement TBD - could be new tab, menu item, or button in ChatListView)
- **Risk:** UI clutter. **Mitigation:** User testing to find best placement

**ChatView.swift:**
- **Change:** Show error modal when relationship validation fails
- **New UI:** Alert with message "This trainer hasn't added you yet"

### Security Rules to Add

**Firestore Rules (`firestore.rules`):**

**New `/contacts` Rules:**
```javascript
match /contacts/{trainerId}/clients/{clientId} {
  // Only trainer can read/write their own clients
  allow read, write: if request.auth != null && request.auth.uid == trainerId;
}

match /contacts/{trainerId}/prospects/{prospectId} {
  // Only trainer can read/write their own prospects
  allow read, write: if request.auth != null && request.auth.uid == trainerId;
}
```

**Modified `/chats` Rules:**
```javascript
match /chats/{chatId} {
  allow read: if request.auth != null &&
              request.auth.uid in resource.data.members;

  allow create: if request.auth != null &&
                 request.auth.uid in request.resource.data.members &&
                 // NEW: Validate relationship exists
                 (isGroupChat(request.resource.data) ||
                  hasTrainerClientRelationship(request.resource.data.members));

  allow update: if request.auth != null &&
                 request.auth.uid in resource.data.members;
}

function isGroupChat(chatData) {
  return chatData.isGroupChat == true;
}

function hasTrainerClientRelationship(members) {
  // Complex - may need to defer to backend validation
  // or check if relationship exists in /contacts
  return true; // Simplified for now
}
```

**Note:** Security rules for relationship validation may need to be simplified. Complex logic should be in backend.

### Integration Points

**New Dependencies:**
- ContactService → Firestore (`/contacts` collections)
- ContactService → UserService (email lookup)
- ChatService → ContactService (relationship validation)

**Backward Compatibility:**
- Migration script auto-adds existing chat participants as clients
- Existing chats remain accessible (no data loss)
- Security rules apply only to NEW chats

---

## 13. Definition of Done

See standards in `Psst/agents/shared-standards.md`:

- [ ] ContactService implemented with all CRUD methods (addClient, addProspect, upgradeProspect, getClients, getProspects, removeClient, deleteProspect, searchContacts, validateRelationship, lookupUserByEmail)
- [ ] ContactsView displays clients and prospects in separate sections
- [ ] Add client form looks up user by email and auto-populates display name
- [ ] Add prospect form creates prospect with placeholder email
- [ ] Upgrade prospect to client flow works end-to-end (lookup by email, move to clients section)
- [ ] Firebase security rules enforce relationship validation
- [ ] ChatService validates relationships before creating 1-on-1 chats
- [ ] UserService email lookup functionality added
- [ ] Search contacts by name works (filters both clients and prospects)
- [ ] Remove client deletes relationship and revokes chat access
- [ ] Group peer discovery enables 1-on-1 messaging between group members
- [ ] All acceptance gates pass
- [ ] Manual testing completed (add client, add prospect, upgrade, remove, group discovery)
- [ ] Migration script tested with existing users
- [ ] No console errors during all test scenarios
- [ ] Documentation updated (inline comments, README if needed)

---

## 14. Risks & Mitigations

**Risk 1: Breaking Existing Chat Functionality**
- **Impact:** High - Users can't create chats
- **Mitigation:** Feature flag for relationship validation, thorough testing, gradual rollout
- **Rollback Plan:** Disable validation, revert to open access

**Risk 2: Migration Script Fails**
- **Impact:** High - Existing users locked out of chats
- **Mitigation:** Test migration in staging environment, backup Firestore data, run in read-only mode first
- **Rollback Plan:** Restore from backup, fix script, re-run

**Risk 3: Security Rules Too Complex**
- **Impact:** Medium - Performance degradation, hard to maintain
- **Mitigation:** Keep rules simple, move complex validation to backend Cloud Functions
- **Rollback Plan:** Simplify rules to basic auth checks

**Risk 4: Email Lookup Performance**
- **Impact:** Medium - Slow client addition if many users
- **Mitigation:** Add Firestore index on email field, implement caching
- **Fallback:** Show loading spinner, implement timeout with retry

**Risk 5: Group Peer Discovery Permissions Too Broad**
- **Impact:** Medium - Clients can message anyone in any shared group
- **Mitigation:** Limit peer discovery to groups created by trainer (not client-created groups)
- **Rollback Plan:** Disable peer discovery, require trainer approval for peer chats

**Risk 6: Firestore Query Performance with Large Contact Lists**
- **Impact:** Low - Slow contact list loading
- **Mitigation:** Proper indexing, pagination for 100+ contacts, client-side caching
- **Optimization:** Lazy loading, virtual scrolling

---

## 15. Rollout & Telemetry

**Feature Flag:**
- `enable_relationship_validation` - Default: `false` initially, gradually enable

**Metrics to Track:**
- Number of clients added per trainer (daily, weekly)
- Number of prospects added per trainer
- Prospect → client conversion rate
- "User not found" error rate (clients without accounts)
- Chat creation failures due to relationship validation
- Contact list load time
- Email lookup latency
- Search query latency

**Manual Validation Steps:**
1. Create new trainer account → Add client by email (existing user) → Verify Firestore document and auto-populated name
2. Add client with non-existent email → Verify "User not found" error
3. Client tries to message unconnected trainer → Verify error shown
4. Trainer creates group with 2 clients → Verify peer messaging works
5. Run migration script → Verify existing chats still accessible
6. Remove client → Verify removed from list and chat access revoked

**Gradual Rollout Plan:**
1. Deploy with feature flag disabled (no behavior change)
2. Enable for internal testing accounts
3. Enable for 10% of trainers
4. Monitor metrics for 1 week
5. If stable, enable for 50%, then 100%

---

## 16. Open Questions

**Q1: Where should ContactsView be placed in navigation?**
- Option A: New 4th tab in bottom navigation (Chats, Contacts, Profile, Settings)
- Option B: Menu item in settings or profile
- Option C: Floating action button in ChatListView
- **Decision Needed:** User testing to determine best UX

**Q2: Should clients be able to see their trainer's other clients?**
- Currently: No (privacy concern)
- Alternative: Show group members only
- **Decision:** Keep private for MVP, revisit based on feedback

**Q3: Should converted prospects be archived or deleted?**
- Option A: Set `convertedToClientId` and keep in prospects collection (history tracking)
- Option B: Delete prospect document entirely when upgraded
- **Decision Needed:** User noted "? not sure about this one" - need to decide
- **Recommendation:** Keep for history (Option A) - allows tracking conversion metrics

**Q4: Should display name be editable after auto-population?**
- Currently: Auto-populated from `/users/{clientId}/displayName`
- Alternative: Allow trainer to override display name (nickname)
- **Decision:** Auto-populate only for MVP, make read-only (matches user's actual name)

**Q5: Should clients be notified when trainer adds them?**
- Option A: No notification (silent addition)
- Option B: Push notification: "[Trainer] added you as a client"
- **Decision Needed:** Future enhancement or MVP feature?
- **Recommendation:** Future enhancement (not blocking)

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future:
- [ ] Invitation email system (send email invites to clients without accounts)
- [ ] Push notifications when trainer adds client
- [ ] Client-side contact management (clients managing their trainers)
- [ ] Client referral system (clients inviting other clients)
- [ ] Payment/billing integration with client relationships
- [ ] Bulk client import (CSV upload)
- [ ] Client groups/segments (advanced tagging, notes, phone numbers)
- [ ] Relationship analytics (client engagement scores, churn prediction)
- [ ] Automated client onboarding workflows
- [ ] Client self-signup with trainer approval
- [ ] Multi-trainer support (clients working with multiple trainers)
- [ ] Display name nicknames (trainer overrides auto-populated name)

---

## Preflight Questionnaire

**1. Smallest end-to-end user outcome for this PR?**
Trainer adds existing user as client by email (display name auto-populates), relationship created, both can now message each other.

**2. Primary user and critical action?**
Trainers are primary users. Critical action: Adding existing users as clients to establish controlled relationships.

**3. Must-have vs nice-to-have?**
Must-have: Add client (email lookup), add prospect, upgrade prospect, relationship validation, security rules, migration script
Nice-to-have: Push notifications when added, invitation email system

**4. Real-time requirements?**
No real-time sync needed (contact list is relatively static). Standard Firestore listeners sufficient.

**5. Performance constraints?**
Contact list must load in < 500ms, email lookup must complete in < 200ms, search must filter in < 100ms. See `shared-standards.md`.

**6. Error/edge cases to handle?**
User not found (no account), duplicate emails, invalid formats, offline mode, client tries to message unconnected trainer, migration failures.

**7. Data model changes?**
New collections: `/contacts/{trainerId}/clients`, `/contacts/{trainerId}/prospects`
Modified: `/users` (add optional `trainerId` field), UserService (add email lookup)

**8. Service APIs required?**
ContactService: addClient (email only), addProspect (name only), upgradeProspectToClient, getClients, getProspects, removeClient, deleteProspect, searchContacts, validateRelationship, lookupUserByEmail

**9. UI entry points and states?**
Entry: ContactsView (new screen)
States: Loading (skeleton, email lookup spinner), empty (no contacts), list (clients + prospects), error (network, user not found), success (confirmation toast)

**10. Security/permissions implications?**
Major: New Firebase security rules for relationship-based access control. Affects all chat creation.

**11. Dependencies or blocking integrations?**
Depends on: PR #006.5 (User Roles - need to distinguish trainers from clients)
Blocks: PR #010 (Calendar - needs client/prospect lists)

**12. Rollout strategy and metrics?**
Feature flag rollout: internal → 10% → 50% → 100%
Metrics: clients added, "user not found" error rate, email lookup latency, chat creation failures

**13. What is explicitly out of scope?**
No invitation emails, no client-side contact management, no payments, no client self-signup, no referrals, no trainer marketplace, no tagging/notes/phone fields.

---

## Authoring Notes

- This is a **brownfield PR** - modifies existing chat creation and security logic
- Read `Psst/docs/architecture.md` for current system structure
- Affects core access control - test thoroughly before release
- Migration script is critical - backup Firestore before running
- Reference `Psst/agents/shared-standards.md` for code patterns and performance targets
- Feature flag recommended for safe rollout
- Consider UI placement carefully (new tab vs menu item)
