# PR-009 TODO — Trainer-Client Relationship System & Contact Management

**Branch**: `feat/pr-009-trainer-client-relationships`
**Source PRD**: `Psst/docs/prds/pr-009-prd.md`
**Owner (Agent)**: Caleb

---

## 0. Clarifying Questions & Assumptions

**Questions:**
- Q: Should converted prospects remain in Firestore or be deleted?
  - Assumption: Keep with `convertedToClientId` set for conversion tracking (pending user confirmation)
- Q: Where should ContactsView be placed in navigation?
  - Assumption: TBD during implementation, can be adjusted based on UI testing

**Assumptions:**
- Users must have existing Psst accounts to be added as clients (no invitation system)
- Display names are read-only (auto-populated from user profiles)
- Clients are removed (deleted) not archived
- Minimal MVP: no tags, notes, phone fields

---

## 1. Setup

- [ ] Create branch `feat/pr-009-trainer-client-relationships` from develop
  - Test Gate: `git status` shows new branch
- [ ] Read PRD thoroughly (`Psst/docs/prds/pr-009-prd.md`)
- [ ] Read `Psst/agents/shared-standards.md` for patterns
- [ ] Read `Psst/docs/architecture.md` for brownfield context
- [ ] Confirm Xcode builds successfully on branch
  - Test Gate: Build succeeds, simulator launches

---

## 2. Data Models

### Client Model

- [ ] Create `Models/Client.swift`
  - Test Gate: File compiles, no errors
- [ ] Define `Client` struct with fields:
  - `id: String` (client user ID, same as in `/users`)
  - `clientId: String` (references `/users/{clientId}`)
  - `displayName: String` (auto-populated from user)
  - `email: String` (used for lookup)
  - `addedAt: Date`
  - `lastContactedAt: Date?` (optional)
  - Test Gate: Struct compiles with all fields
- [ ] Implement `Codable` conformance for Firestore serialization
  - Test Gate: Encoding/decoding works in playground or test
- [ ] Implement `Identifiable` conformance (id = clientId)
  - Test Gate: Can use in SwiftUI ForEach
- [ ] Add `toDictionary()` method for Firestore writes
  - Test Gate: Returns correct dictionary format

### Prospect Model

- [ ] Create `Models/Prospect.swift`
  - Test Gate: File compiles, no errors
- [ ] Define `Prospect` struct with fields:
  - `id: String` (prospect ID, auto-generated)
  - `prospectId: String` (same as id)
  - `displayName: String`
  - `placeholderEmail: String` (prospect-[name]@psst.app)
  - `addedAt: Date`
  - `convertedToClientId: String?` (set when upgraded)
  - Test Gate: Struct compiles with all fields
- [ ] Implement `Codable` conformance
  - Test Gate: Encoding/decoding works
- [ ] Implement `Identifiable` conformance
  - Test Gate: Can use in SwiftUI ForEach
- [ ] Add `toDictionary()` method for Firestore writes
  - Test Gate: Returns correct dictionary format

### Contact Protocol

- [ ] Create `Models/Contact.swift` protocol
  - Test Gate: File compiles
- [ ] Define `Contact` protocol with common properties:
  - `var id: String { get }`
  - `var displayName: String { get }`
  - `var addedAt: Date { get }`
  - Test Gate: Protocol compiles
- [ ] Make `Client` conform to `Contact` protocol
  - Test Gate: No compilation errors
- [ ] Make `Prospect` conform to `Contact` protocol
  - Test Gate: No compilation errors

---

## 3. Service Layer - UserService Email Lookup

- [ ] Open `Services/UserService.swift`
  - Test Gate: File opens, review existing methods
- [ ] Add `getUserByEmail(_ email: String)` method
  ```swift
  func getUserByEmail(_ email: String) async throws -> User?
  ```
  - Query Firestore `/users` where `email == email`
  - Return first match or nil if not found
  - Test Gate: Method compiles, proper async/await syntax
- [ ] Add error handling for invalid email format
  - Test Gate: Throws error for malformed emails
- [ ] Add error handling for network failures
  - Test Gate: Handles network errors gracefully

---

## 4. Service Layer - ContactService

### ContactService Core Structure

- [ ] Create `Services/ContactService.swift`
  - Test Gate: File created, imports Firebase
- [ ] Define `ContactError` enum
  ```swift
  enum ContactError: Error, LocalizedError {
    case invalidEmail
    case invalidName
    case userNotFound
    case alreadyExists
    case clientNotFound
    case prospectNotFound
    case networkError
    case unauthorized
  }
  ```
  - Test Gate: Enum compiles with all cases
- [ ] Add `errorDescription` computed property for user-friendly messages
  - Test Gate: Each case returns correct message string
- [ ] Create `ContactService` class with Firestore reference
  - Test Gate: Class initializes with `Firestore.firestore()`

### Add Client Method

- [ ] Implement `addClient(email: String) async throws -> Client`
  - Step 1: Validate email format (basic regex or EmailValidator)
  - Step 2: Get current trainer ID from AuthenticationService
  - Step 3: Call `userService.getUserByEmail(email)` to lookup user
  - Step 4: If user not found, throw `ContactError.userNotFound`
  - Step 5: Check if client already exists in `/contacts/{trainerId}/clients/{clientId}`
  - Step 6: If exists, throw `ContactError.alreadyExists`
  - Step 7: Create Client object with auto-populated displayName from user
  - Step 8: Write to Firestore `/contacts/{trainerId}/clients/{clientId}`
  - Step 9: Return created Client
  - Test Gate: Method compiles, follows proper error handling

### Add Prospect Method

- [ ] Implement `addProspect(name: String) async throws -> Prospect`
  - Step 1: Validate name is not empty
  - Step 2: Get current trainer ID
  - Step 3: Generate placeholder email: `prospect-[firstName-lastName]@psst.app`
  - Step 4: Create Prospect object with auto-generated ID
  - Step 5: Write to Firestore `/contacts/{trainerId}/prospects/{prospectId}`
  - Step 6: Return created Prospect
  - Test Gate: Method compiles, placeholder email format correct

### Upgrade Prospect Method

- [ ] Implement `upgradeProspectToClient(prospectId: String, email: String) async throws -> Client`
  - Step 1: Validate email format
  - Step 2: Get current trainer ID
  - Step 3: Fetch prospect from `/contacts/{trainerId}/prospects/{prospectId}`
  - Step 4: If not found, throw `ContactError.prospectNotFound`
  - Step 5: Call `userService.getUserByEmail(email)` to lookup user
  - Step 6: If user not found, throw `ContactError.userNotFound`
  - Step 7: Create Client with auto-populated displayName
  - Step 8: Write client to `/contacts/{trainerId}/clients/{clientId}`
  - Step 9: Update prospect document: set `convertedToClientId = clientId`
  - Step 10: Return created Client
  - Test Gate: Method compiles, handles all error cases

### Get Clients/Prospects Methods

- [ ] Implement `getClients() async throws -> [Client]`
  - Query `/contacts/{trainerId}/clients` ordered by `addedAt` descending
  - Map documents to Client objects
  - Test Gate: Returns array of clients
- [ ] Implement `getProspects() async throws -> [Prospect]`
  - Query `/contacts/{trainerId}/prospects` ordered by `addedAt` descending
  - Filter out converted prospects (where `convertedToClientId != nil`)? Or include all?
  - Map documents to Prospect objects
  - Test Gate: Returns array of prospects

### Remove/Delete Methods

- [ ] Implement `removeClient(clientId: String) async throws`
  - Get current trainer ID
  - Delete document from `/contacts/{trainerId}/clients/{clientId}`
  - Test Gate: Document deleted from Firestore
- [ ] Implement `deleteProspect(prospectId: String) async throws`
  - Get current trainer ID
  - Delete document from `/contacts/{trainerId}/prospects/{prospectId}`
  - Test Gate: Document deleted from Firestore

### Search Method

- [ ] Implement `searchContacts(query: String) async throws -> [Contact]`
  - Get all clients and prospects
  - Filter by displayName containing query (case-insensitive)
  - Combine into single array of Contact protocol types
  - Test Gate: Search returns matching clients and prospects

### Validate Relationship Method

- [ ] Implement `validateRelationship(trainerId: String, clientId: String) async throws -> Bool`
  - Check if document exists at `/contacts/{trainerId}/clients/{clientId}`
  - Return true if exists, false otherwise
  - Test Gate: Correctly validates relationships

---

## 5. UI Components - Models & ViewModels

### ContactsViewModel

- [ ] Create `ViewModels/ContactsViewModel.swift`
  - Test Gate: File compiles, imports Combine
- [ ] Define `@Published` properties:
  - `clients: [Client] = []`
  - `prospects: [Prospect] = []`
  - `searchQuery: String = ""`
  - `isLoading: Bool = false`
  - `errorMessage: String?`
  - Test Gate: Properties compile, observable
- [ ] Add `contactService: ContactService` dependency
  - Test Gate: Initializes with ContactService
- [ ] Implement `loadContacts()` method
  - Calls `contactService.getClients()` and `contactService.getProspects()`
  - Updates `@Published` properties
  - Handles errors and sets `errorMessage`
  - Test Gate: Method compiles, async/await correct
- [ ] Implement `addClient(email: String)` method
  - Calls `contactService.addClient(email)`
  - On success: reload contacts, clear form, show success message
  - On error: set `errorMessage` with user-friendly text
  - Test Gate: Handles all error cases (userNotFound, alreadyExists, etc.)
- [ ] Implement `addProspect(name: String)` method
  - Calls `contactService.addProspect(name)`
  - On success: reload prospects, clear form
  - Test Gate: Method works end-to-end
- [ ] Implement `upgradeProspect(prospectId: String, email: String)` method
  - Calls `contactService.upgradeProspectToClient()`
  - On success: reload both lists
  - Test Gate: Prospect moves to clients section
- [ ] Implement `removeClient(clientId: String)` method
  - Calls `contactService.removeClient()`
  - On success: reload clients
  - Test Gate: Client removed from list
- [ ] Implement `deleteProspect(prospectId: String)` method
  - Calls `contactService.deleteProspect()`
  - On success: reload prospects
  - Test Gate: Prospect removed from list
- [ ] Implement computed property `filteredClients`
  - Filters `clients` by `searchQuery`
  - Test Gate: Search works in real-time
- [ ] Implement computed property `filteredProspects`
  - Filters `prospects` by `searchQuery`
  - Test Gate: Search works in real-time

---

## 6. UI Components - Views

### ContactsView (Main Screen)

- [ ] Create `Views/Contacts/ContactsView.swift`
  - Test Gate: File compiles, SwiftUI preview renders
- [ ] Add `@StateObject var viewModel = ContactsViewModel()`
  - Test Gate: ViewModel initializes
- [ ] Add `@State var showAddClientSheet = false`
  - Test Gate: State variable works
- [ ] Add `@State var showAddProspectSheet = false`
  - Test Gate: State variable works
- [ ] Create navigation view with title "Contacts"
  - Test Gate: Title appears in preview
- [ ] Add search bar at top (binds to `viewModel.searchQuery`)
  - Test Gate: Search bar appears, typing updates query
- [ ] Create two sections: "My Clients" and "Prospects"
  - Use `Section` with headers
  - Test Gate: Both sections visible in preview
- [ ] Display `viewModel.filteredClients` in "My Clients" section
  - Use `ForEach` with `ContactRowView`
  - Test Gate: Clients render (use mock data initially)
- [ ] Display `viewModel.filteredProspects` in "Prospects" section
  - Use `ForEach` with `ContactRowView`
  - Test Gate: Prospects render (use mock data initially)
- [ ] Add empty states for each section
  - "No clients yet. Add your first client to get started"
  - "No prospects yet. Add prospects to track leads"
  - Test Gate: Empty states show when lists are empty
- [ ] Add loading state (skeleton loaders or progress view)
  - Show when `viewModel.isLoading == true`
  - Test Gate: Loading state displays
- [ ] Add toolbar with "Add Client" and "Add Prospect" buttons
  - Test Gate: Buttons trigger sheets
- [ ] Implement `.sheet` for `showAddClientSheet`
  - Presents `AddClientView`
  - Test Gate: Sheet appears when button tapped
- [ ] Implement `.sheet` for `showAddProspectSheet`
  - Presents `AddProspectView`
  - Test Gate: Sheet appears when button tapped
- [ ] Add `.onAppear` to call `viewModel.loadContacts()`
  - Test Gate: Contacts load when view appears
- [ ] Add `.refreshable` for pull-to-refresh
  - Calls `viewModel.loadContacts()`
  - Test Gate: Pull-to-refresh works

### ContactRowView (List Item)

- [ ] Create `Views/Contacts/ContactRowView.swift`
  - Test Gate: File compiles, accepts `Contact` protocol
- [ ] Display avatar (profile photo or initials)
  - Use AsyncImage or placeholder circle
  - Test Gate: Avatar displays correctly
- [ ] Display `contact.displayName`
  - Test Gate: Name appears
- [ ] Display `contact.addedAt` formatted (e.g., "Added 3 days ago")
  - Use `Date+Extensions.swift` helper
  - Test Gate: Date formats correctly
- [ ] Add prospect badge for prospects ("👤 Prospect")
  - Only show if `contact is Prospect`
  - Test Gate: Badge appears for prospects only
- [ ] Add swipe actions:
  - For clients: "Remove" (red, destructive)
  - For prospects: "Delete" (red, destructive), "Upgrade" (blue)
  - Test Gate: Swipe actions work, call appropriate ViewModel methods
- [ ] Style row with proper padding and spacing
  - Test Gate: Row looks clean in preview

### AddClientView (Form)

- [ ] Create `Views/Contacts/AddClientView.swift`
  - Test Gate: File compiles, SwiftUI preview renders
- [ ] Add `@Environment(\.dismiss) var dismiss`
  - Test Gate: Can dismiss sheet
- [ ] Add `@EnvironmentObject var viewModel: ContactsViewModel`
  - Test Gate: Receives ViewModel from parent
- [ ] Add `@State var email = ""`
  - Test Gate: State variable works
- [ ] Add `@State var isLookingUp = false`
  - For loading state during email lookup
  - Test Gate: Loading state works
- [ ] Create form with navigation view and title "Add Client"
  - Test Gate: Title appears
- [ ] Add email TextField with validation
  - Keyboard type: `.emailAddress`
  - Autocapitalization: `.none`
  - Test Gate: TextField works, keyboard correct
- [ ] Add submit button "Add Client"
  - Disabled if email is empty or invalid format
  - Test Gate: Button enables/disables correctly
- [ ] Implement submit action:
  - Set `isLookingUp = true`
  - Call `viewModel.addClient(email)`
  - On success: dismiss sheet
  - On error: show error alert with `viewModel.errorMessage`
  - Set `isLookingUp = false`
  - Test Gate: Full flow works end-to-end
- [ ] Add loading spinner when `isLookingUp == true`
  - Test Gate: Spinner shows during lookup
- [ ] Add cancel button in toolbar
  - Dismisses sheet
  - Test Gate: Cancel works

### AddProspectView (Form)

- [ ] Create `Views/Contacts/AddProspectView.swift`
  - Test Gate: File compiles, SwiftUI preview renders
- [ ] Add `@Environment(\.dismiss) var dismiss`
  - Test Gate: Dismiss works
- [ ] Add `@EnvironmentObject var viewModel: ContactsViewModel`
  - Test Gate: ViewModel injected
- [ ] Add `@State var name = ""`
  - Test Gate: State variable works
- [ ] Create form with title "Add Prospect"
  - Test Gate: Title appears
- [ ] Add name TextField
  - Test Gate: TextField works
- [ ] Add submit button "Add Prospect"
  - Disabled if name is empty
  - Test Gate: Button validation works
- [ ] Implement submit action:
  - Call `viewModel.addProspect(name)`
  - On success: dismiss sheet
  - On error: show error alert
  - Test Gate: Full flow works
- [ ] Add cancel button
  - Test Gate: Cancel dismisses sheet

### UpgradeProspectView (Form)

- [ ] Create `Views/Contacts/UpgradeProspectView.swift`
  - Test Gate: File compiles
- [ ] Accept `prospect: Prospect` parameter
  - Test Gate: Initializes with prospect
- [ ] Add `@Environment(\.dismiss) var dismiss`
  - Test Gate: Dismiss works
- [ ] Add `@EnvironmentObject var viewModel: ContactsViewModel`
  - Test Gate: ViewModel injected
- [ ] Add `@State var email = ""`
  - Test Gate: State variable works
- [ ] Create form with title "Upgrade Prospect"
  - Display prospect name (read-only)
  - Test Gate: Name displays
- [ ] Add email TextField
  - Test Gate: TextField works
- [ ] Add submit button "Upgrade to Client"
  - Disabled if email empty or invalid
  - Test Gate: Validation works
- [ ] Implement submit action:
  - Call `viewModel.upgradeProspect(prospectId, email)`
  - On success: dismiss sheet
  - On error: show error alert (especially userNotFound)
  - Test Gate: Upgrade flow works end-to-end
- [ ] Update `ContactRowView` to show "Upgrade" action for prospects
  - Opens `UpgradeProspectView` sheet
  - Test Gate: Swipe action opens upgrade form

### Empty State Component

- [ ] Create `Components/ContactEmptyState.swift`
  - Test Gate: File compiles
- [ ] Accept `message: String` parameter
  - Test Gate: Displays custom message
- [ ] Display icon (📋 or similar)
  - Test Gate: Icon visible
- [ ] Display message text
  - Test Gate: Text styled correctly
- [ ] Center content vertically and horizontally
  - Test Gate: Centered in preview

---

## 7. Navigation Integration

- [ ] Decide on ContactsView placement (see Open Questions in PRD)
  - Option A: New 4th tab in MainTabView
  - Option B: Menu item in Settings
  - Option C: Button in ChatListView
  - **Decision:** Start with Option A (new tab), can adjust later
  - Test Gate: User approves placement

### If Option A (New Tab):

- [ ] Open `Views/MainTabView.swift`
  - Test Gate: File opens
- [ ] Add 4th tab for Contacts
  - Icon: `person.2` or `person.crop.circle.badge.checkmark`
  - Label: "Contacts"
  - Destination: `ContactsView()`
  - Test Gate: Tab appears in tab bar
- [ ] Test navigation flow
  - Test Gate: Tapping tab navigates to ContactsView

---

## 8. ChatService Relationship Validation

- [ ] Open `Services/ChatService.swift`
  - Test Gate: File opens, review existing `createChat` method
- [ ] Add `contactService: ContactService` dependency
  - Test Gate: Initialized in init method
- [ ] Locate `createChat(members: [String], isGroup: Bool)` method
  - Test Gate: Method found
- [ ] Add relationship validation for 1-on-1 chats (before Firestore write):
  ```swift
  // Only validate for 1-on-1 chats
  if !isGroup && members.count == 2 {
      // Determine who is trainer and who is client (requires role field from PR #006.5)
      // For now, assume current user is trainer, other is client
      let currentUserID = AuthenticationService.shared.currentUser?.id ?? ""
      let otherUserID = members.first(where: { $0 != currentUserID }) ?? ""

      // Validate relationship exists
      let hasRelationship = try await contactService.validateRelationship(
          trainerId: currentUserID,
          clientId: otherUserID
      )

      if !hasRelationship {
          throw ChatError.relationshipNotFound
      }
  }
  ```
  - Test Gate: Code compiles, validation logic correct
- [ ] Add `ChatError.relationshipNotFound` case
  - Test Gate: Error case added to enum
- [ ] Add error message for `relationshipNotFound`
  - "This trainer hasn't added you yet"
  - Test Gate: Error message displays correctly
- [ ] Test validation logic manually:
  - Create relationship → Chat works
  - No relationship → Chat blocked
  - Test Gate: Validation enforces access control

---

## 9. Firebase Security Rules

- [ ] Open `Psst/firestore.rules`
  - Test Gate: File opens
- [ ] Add rules for `/contacts/{trainerId}/clients/{clientId}`:
  ```javascript
  match /contacts/{trainerId}/clients/{clientId} {
    // Only trainer can read/write their own clients
    allow read, write: if request.auth != null && request.auth.uid == trainerId;
  }
  ```
  - Test Gate: Rules syntax correct
- [ ] Add rules for `/contacts/{trainerId}/prospects/{prospectId}`:
  ```javascript
  match /contacts/{trainerId}/prospects/{prospectId} {
    // Only trainer can read/write their own prospects
    allow read, write: if request.auth != null && request.auth.uid == trainerId;
  }
  ```
  - Test Gate: Rules syntax correct
- [ ] Consider adding relationship validation to `/chats` rules (optional for MVP):
  - Can be simplified: allow all authenticated users for now
  - Backend validation in ChatService is primary enforcement
  - Test Gate: Decision made on rule complexity
- [ ] Deploy Firestore rules:
  ```bash
  firebase deploy --only firestore:rules
  ```
  - Test Gate: Rules deployed successfully, no errors
- [ ] Test rules in Firebase Console Simulator
  - Trainer can read/write own contacts: Pass
  - Different trainer cannot read others' contacts: Fail (expected)
  - Test Gate: Rules enforce ownership correctly

---

## 10. Firestore Indexes

- [ ] Create composite index for client queries:
  - Collection: `contacts`
  - Fields: `trainerId` (Ascending), `addedAt` (Descending)
  - Test Gate: Index created in Firebase Console
- [ ] Test query performance with index
  - Load ContactsView with 10+ clients
  - Test Gate: Loads in < 500ms

---

## 11. Migration Script (Existing Users)

- [ ] Create migration script file (TypeScript Cloud Function or Swift script)
  - **Option A:** Cloud Function `functions/migrateExistingChats.ts`
  - **Option B:** Swift command-line script
  - **Decision:** Use Cloud Function for consistency
  - Test Gate: File created
- [ ] Implement migration logic:
  ```typescript
  // For each user with role = "trainer"
  //   Get all chats where user is member
  //   Extract unique participant IDs (exclude trainer)
  //   For each participant:
  //     Check if already in /contacts/{trainerId}/clients
  //     If not: create client relationship
  //       - Get user data from /users/{clientId}
  //       - Create client document with displayName from user
  ```
  - Test Gate: Logic compiles, no errors
- [ ] Add dry-run mode (logs actions without writing)
  - Test Gate: Dry-run outputs expected changes
- [ ] Add safety checks:
  - Backup Firestore before running
  - Run dry-run first
  - Confirm with user before executing
  - Test Gate: Safety checks implemented
- [ ] Test migration on development environment
  - Create test users and chats
  - Run migration
  - Verify all chat participants added as clients
  - Test Gate: Migration works, no data loss
- [ ] Document migration steps in README or migration doc
  - Test Gate: Documentation clear and complete

---

## 12. User-Centric Testing

### Happy Path

- [x] **Test: Trainer Adds Existing Client**
  - Open ContactsView → Tap "Add Client" → Enter email of existing user → Submit
  - **Gate:** System looks up user, auto-populates display name
  - **Gate:** Client appears in "My Clients" section within 1 second
  - **Gate:** Firestore document created at `/contacts/{trainerId}/clients/{clientId}`
  - **Pass:** No errors, display name matches user profile, client visible in list

- [x] **Test: Trainer Adds Prospect**
  - Tap "Add Prospect" → Enter name "John Doe" → Submit
  - **Gate:** Prospect appears in "Prospects" section immediately
  - **Gate:** Placeholder email `prospect-john-doe@psst.app` generated
  - **Pass:** No errors, prospect visible in list

- [x] **Test: Trainer Upgrades Prospect to Client**
  - Find prospect → Swipe → Tap "Upgrade" → Enter existing user email → Submit
  - **Gate:** System looks up user, auto-populates display name
  - **Gate:** Prospect moves from "Prospects" to "My Clients" section
  - **Gate:** Original prospect record has `convertedToClientId` set
  - **Pass:** Smooth transition, client visible in clients list

- [x] **Test: Group Peer Discovery**
  - Trainer creates group chat with Sara and Claudia
  - Sara views group → Taps Claudia's profile → Sees "Start Chat" button
  - Sara taps "Start Chat" → 1-on-1 chat created successfully
  - **Pass:** Sara and Claudia can message each other

- [ ] **Test: Trainer Removes Client**
  - Swipe on client → Tap "Remove" → Confirm deletion
  - **Gate:** Client disappears from list immediately
  - **Gate:** Firestore document deleted
  - **Gate:** Client can no longer message trainer (validation blocks)
  - **Pass:** Removal works, relationship terminated

### Edge Cases

- [] **Edge Case 1: User Not Found**
  - Enter email for user without Psst account
  - **Expected:** Toast error: "User not found. Client must have a Psst account"
  - **Pass:** Clear error message, trainer understands client must sign up first

- [ ] **Edge Case 2: Duplicate Email**
  - Try to add client with email already in client list
  - **Expected:** Inline error: "This user is already in your client list"
  - **Pass:** Form not submitted, error clear

- [ ] **Edge Case 3: Invalid Email Format**
  - Enter malformed email "notanemail"
  - **Expected:** Validation error: "Please enter a valid email address"
  - **Pass:** Inline error shown, form not submitted

- [ ] **Edge Case 4: Client Tries to Message Unconnected Trainer**
  - Client attempts to start chat with trainer who hasn't added them
  - **Expected:** Error modal: "This trainer hasn't added you yet"
  - **Pass:** Chat not created, clear explanation

- [x] **Edge Case 5: Upgrade Prospect - User Not Found**
  - Upgrade prospect with email for non-existent user
  - **Expected:** Toast error: "User not found. Client must have a Psst account"
  - **Pass:** Prospect remains in prospects list, clear error

- [ ] **Edge Case 6: Multiple Clients Named "Sam"**
  - Search for "Sam" with 2 Sams in contacts
  - **Expected:** Both Sams shown, distinguishable by email display or last name
  - **Pass:** Search works, no confusion

### Error Handling

- [ ] **Offline Mode**
  - Enable airplane mode → Attempt to add client
  - **Expected:** "No internet connection" toast
  - **Pass:** Clear error message, action fails gracefully
  - Re-enable network → Retry → Works

- [ ] **Network Timeout**
  - Slow network → Add client takes > 5 seconds
  - **Expected:** Loading spinner → Success or timeout error
  - **Pass:** Timeout handled gracefully, retry option works

- [ ] **Invalid Relationship (Security Test)**
  - Client tries to create chat via URL manipulation (if possible)
  - **Expected:** Firebase security rules block write OR ChatService validation throws error
  - **Pass:** Security enforced, no unauthorized access

### Performance Check

- [ ] **Contact List Performance**
  - Create 50+ mock clients
  - Open ContactsView
  - **Target:** Loads in < 500ms
  - **Pass:** List loads quickly, smooth scrolling

- [ ] **Email Lookup Performance**
  - Add client (email lookup)
  - **Target:** Lookup completes in < 200ms
  - **Pass:** Feels instant, no noticeable delay

- [ ] **Search Performance**
  - Search with 100+ contacts
  - **Target:** Filter results in < 100ms
  - **Pass:** Search feels instant

---

## 13. Final Checks & Documentation

- [ ] Run full build in Xcode
  - Test Gate: 0 compilation errors
- [ ] Test on iOS Simulator (Vanes)
  - Test Gate: All flows work end-to-end
- [ ] Check console for errors during all test scenarios
  - Test Gate: No console errors or warnings
- [ ] Review code for hardcoded values
  - Test Gate: All values are constants or configurable
- [ ] Add inline comments for complex logic
  - ContactService email lookup logic
  - Relationship validation in ChatService
  - Migration script logic
  - Test Gate: Code is well-documented
- [ ] Update README if needed (migration instructions)
  - Test Gate: Migration steps documented
- [ ] Create PR description (use format from Caleb agent instructions)
  - Include: What changed, why, testing done, screenshots
  - Test Gate: PR description complete

---

## 14. PR Creation (After User Approval)

- [ ] Verify with user before creating PR
  - Confirm all features working
  - Confirm all tests passing
  - Get explicit approval to create PR
  - Test Gate: User says "yes, create PR"
- [ ] Stage all changes: `git add .`
- [ ] Commit with message:
  ```
  feat(contacts): implement trainer-client relationship system

  - Add ContactService for client/prospect management
  - Add ContactsView with client and prospect lists
  - Add email lookup functionality to UserService
  - Add relationship validation to ChatService
  - Implement Firebase security rules for contacts
  - Create migration script for existing users
  - Support group peer discovery

  Tests completed:
  - Add client (email lookup, auto-populate name)
  - Add prospect (placeholder email generation)
  - Upgrade prospect to client
  - Remove client (relationship terminated)
  - Group peer discovery (1-on-1 messaging enabled)
  - All error cases (user not found, duplicate, invalid email)
  - Offline mode, performance checks

  🤖 Generated with [Claude Code](https://claude.com/claude-code)

  Co-Authored-By: Claude <noreply@anthropic.com>
  ```
  - Test Gate: Commit created with descriptive message
- [ ] Push branch: `git push -u origin feat/pr-009-trainer-client-relationships`
  - Test Gate: Branch pushed to remote
- [ ] Create PR using GitHub CLI or web interface:
  ```bash
  gh pr create --base develop --title "feat(contacts): Trainer-Client Relationship System (PR #009)" --body "$(cat <<'EOF'
  ## Summary
  Implements explicit trainer-client relationships with contact management, replacing the "everyone can access everyone" architecture with controlled access.

  ## Changes
  - ✅ ContactService with email lookup for clients
  - ✅ Add/remove clients, add/delete prospects, upgrade prospects
  - ✅ ContactsView with client and prospect lists
  - ✅ UserService email lookup functionality
  - ✅ ChatService relationship validation
  - ✅ Firebase security rules for contacts
  - ✅ Migration script for existing users
  - ✅ Group peer discovery support

  ## Testing
  - [x] Happy path: Add client, add prospect, upgrade prospect, remove client
  - [x] Edge cases: User not found, duplicate email, invalid format
  - [x] Error handling: Offline mode, network timeout
  - [x] Performance: Contact list < 500ms, email lookup < 200ms, search < 100ms
  - [x] Security: Relationship validation enforced
  - [x] Migration: Existing users auto-added as clients

  ## Screenshots
  [Add screenshots of ContactsView, Add Client form, etc.]

  ## Related
  - Depends on: PR #006.5 (User Roles)
  - Blocks: PR #010 (Calendar System)
  - PRD: `Psst/docs/prds/pr-009-prd.md`
  - TODO: `Psst/docs/todos/pr-009-todo.md`

  🤖 Generated with [Claude Code](https://claude.com/claude-code)
  EOF
  )"
  ```
  - Test Gate: PR created targeting `develop` branch
- [ ] Notify user PR is ready for review
  - Provide PR URL
  - Test Gate: User acknowledges

---

## Copyable Checklist (for PR description)

```markdown
- [ ] Branch created from develop
- [ ] All TODO tasks completed
- [ ] ContactService implemented with all methods
- [ ] UserService email lookup added
- [ ] ContactsView displays clients and prospects
- [ ] Add client form with email lookup
- [ ] Add prospect form with placeholder email
- [ ] Upgrade prospect to client flow
- [ ] Remove client / delete prospect actions
- [ ] ChatService relationship validation
- [ ] Firebase security rules deployed
- [ ] Firestore indexes created
- [ ] Migration script tested
- [ ] Manual testing completed (all scenarios)
- [ ] Performance targets met (< 500ms load, < 200ms lookup, < 100ms search)
- [ ] All acceptance gates pass
- [ ] Code follows Psst/agents/shared-standards.md patterns
- [ ] No console warnings or errors
- [ ] Documentation updated
```

---

## Notes

- Break tasks into < 30 min chunks
- Complete tasks sequentially
- Check off after completion
- Document blockers immediately
- Reference `Psst/agents/shared-standards.md` for common patterns
- This is a **brownfield PR** - affects existing ChatService and security rules
- Test thoroughly before creating PR
- Migration script is critical - backup Firestore first
- Feature flag recommended for gradual rollout (can be added later)
