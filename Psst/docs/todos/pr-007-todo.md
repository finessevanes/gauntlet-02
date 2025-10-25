# PR-007 TODO — Contextual Intelligence (Auto Client Profiles)

**Branch**: `feat/pr-007-contextual-intelligence`
**Source PRD**: `Psst/docs/prds/pr-007-prd.md`
**Owner (Agent)**: Caleb

---

## 0. Clarifying Questions & Assumptions

### Questions
- None - PRD is comprehensive and approved

### Assumptions (confirm in PR if needed):
- Cloud Functions environment already has OpenAI and Pinecone configured (from PR #001)
- RAG Pipeline is functional (PR #005 completed)
- AI Chat Backend is operational (PR #003 completed)
- Extraction uses GPT-4o-mini for cost efficiency (cheaper than GPT-4)
- Client messages only (no extraction from trainer messages)
- No auto-expiration of profile items (trainer manually archives)

---

## 1. Setup

- [ ] Create branch `feat/pr-007-contextual-intelligence` from develop
- [ ] Read PRD thoroughly (`Psst/docs/prds/pr-007-prd.md`)
- [ ] Read `Psst/agents/shared-standards.md` for patterns
- [ ] Read architecture.md for AI integration patterns
- [ ] Confirm Firebase emulator works for Cloud Functions testing
- [ ] Confirm Xcode builds successfully with default simulator: Vanes

---

## 2. Data Model & Firebase Schema

### Swift Models

- [ ] Create `Models/ClientProfile.swift`
  - Define `ClientProfile` struct with Codable, Identifiable
  - Include: clientId, trainerId, createdAt, updatedAt, categorized arrays, metadata
  - Test Gate: Model compiles, Codable encoding/decoding works

- [ ] Create `Models/ProfileItem.swift`
  - Define `ProfileItem` struct with Codable, Identifiable
  - Include: id, text, category, timestamp, sourceMessageId, confidenceScore, isManuallyEdited, etc.
  - Test Gate: Model compiles, all properties properly typed

- [ ] Create `Models/ProfileCategory.swift`
  - Define `ProfileCategory` enum: injuries, goals, equipment, preferences, travel, stressFactors
  - Confirm Codable conformance
  - Test Gate: Enum works in switch statements, raw values correct

- [ ] Create `Models/ProfileItemSource.swift`
  - Define `ProfileItemSource` enum: ai, manual
  - Test Gate: Enum compiles and encodes/decodes correctly

### Firestore Schema

- [ ] Document Firestore schema in PRD (already done, verify implementation)
- [ ] Plan security rules for `/clientProfiles/{clientId}`
  - Trainers can only access their own clients' profiles
  - Write rules to `firestore.rules` file
  - Test Gate: Rules written and ready for deployment

---

## 3. Cloud Functions (Backend)

### Environment Setup

- [ ] Navigate to `Psst/functions/` directory
- [ ] Verify `package.json` has required dependencies:
  - `@pinecone-database/pinecone`
  - `ai` (Vercel AI SDK)
  - `@ai-sdk/openai`
  - `firebase-admin`
  - `firebase-functions`
- [ ] Run `npm install` if dependencies missing
  - Test Gate: `npm install` completes without errors

### Extraction Service

- [ ] Create `functions/services/profileExtractionService.ts`
  - Implement `extractProfileInfo(messageText: string, messageId: string, chatId: string)`
  - Use OpenAI GPT-4o-mini to extract profile information
  - Return categorized ProfileItem[] or null if nothing extracted
  - Test Gate: Function compiles, TypeScript types correct

- [ ] Add categorization logic to extraction service
  - Map extracted info to categories (injuries, goals, equipment, etc.)
  - Assign confidence scores (0.0-1.0)
  - Test Gate: Categorization logic returns correct category enums

- [ ] Add duplicate detection logic
  - Check if similar info already exists in profile (semantic similarity via embeddings)
  - Update timestamp if duplicate found (don't create new entry)
  - Test Gate: Duplicate detection logic implemented

### Cloud Function Endpoints

- [ ] Create `functions/functions/extractProfileInfo.ts`
  - Implement Firestore trigger: `onMessageCreate` → extract profile info
  - Call `profileExtractionService.extractProfileInfo()`
  - Write extracted items to Firestore `/clientProfiles/{clientId}`
  - Test Gate: Function deploys successfully, trigger fires on new messages

- [ ] Add error handling to Cloud Function
  - Handle OpenAI API failures (timeout, rate limit)
  - Handle Firestore write failures
  - Log errors for debugging
  - Test Gate: Error cases handled gracefully, no crashes

- [ ] Create `functions/functions/backfillClientProfile.ts` (optional for migration)
  - Implement `onCall` function to backfill existing messages
  - Takes trainerId and clientId as parameters
  - Processes all past messages in conversation
  - Test Gate: Backfill function works for test conversation

### Deploy Cloud Functions

- [ ] Deploy Cloud Functions to Firebase
  - Run `firebase deploy --only functions`
  - Test Gate: Deployment succeeds, functions visible in Firebase Console

---

## 4. iOS Service Layer

### ProfileService Implementation

- [ ] Create `Services/ProfileService.swift`
  - Add Firebase imports and initialization
  - Test Gate: Service file compiles

- [ ] Implement `fetchClientProfile(clientId:) async throws -> ClientProfile?`
  - Query Firestore `/clientProfiles/{clientId}`
  - Decode to ClientProfile model
  - Return nil if not found
  - Test Gate: Fetch returns mock profile data from Firestore

- [ ] Implement `updateProfileItem(clientId:itemId:newText:) async throws -> ProfileItem`
  - Update specific item in profile array
  - Set `isManuallyEdited = true`, `editedAt = now`
  - Test Gate: Update persists to Firestore, returns updated item

- [ ] Implement `deleteProfileItem(clientId:itemId:) async throws`
  - Remove item from appropriate category array
  - Update `updatedAt` timestamp
  - Test Gate: Delete removes item from Firestore

- [ ] Implement `addManualProfileItem(clientId:category:text:) async throws -> ProfileItem`
  - Create new ProfileItem with `createdBy = .manual`
  - Add to appropriate category array
  - Test Gate: Manual item created and persisted

- [ ] Implement `observeClientProfile(clientId:completion:) -> ListenerRegistration`
  - Set up Firestore snapshot listener
  - Call completion handler on profile updates
  - Test Gate: Listener fires when profile changes in Firestore

- [ ] Implement `deleteClientProfile(clientId:) async throws`
  - Delete entire profile document
  - Test Gate: Profile deleted from Firestore

- [ ] Add error handling to ProfileService
  - Define `ProfileError` enum (notAuthenticated, notFound, updateFailed, etc.)
  - Throw appropriate errors
  - Test Gate: Error cases handled with clear messages

---

## 5. UI Components

### Profile Banner (Conversation Header)

- [ ] Create `Views/Profile/ClientProfileBannerView.swift`
  - Display condensed profile info (top 3-5 items)
  - Show categories with icons (🏋️ Goals, 🩹 Injuries, 🛠️ Equipment, etc.)
  - Add "View Full Profile" button
  - Test Gate: SwiftUI Preview renders, no console errors

- [ ] Add animations to profile banner
  - Slide down on appear (300ms ease-out)
  - Category pills fade in sequentially (50ms stagger)
  - Test Gate: Animations smooth, no lag

- [ ] Integrate banner into `ChatView.swift`
  - Add ClientProfileBannerView to top of message list
  - Pass clientId to banner
  - Test Gate: Banner displays in conversation, doesn't block scrolling

### Profile Detail Modal

- [ ] Create `Views/Profile/ClientProfileDetailView.swift`
  - Full-screen modal with categorized sections
  - ScrollView with LazyVStack for performance
  - Close button in navigation bar
  - Test Gate: Modal displays, scrolls smoothly with 100+ items

- [ ] Create `Views/Profile/ProfileCategorySection.swift`
  - Section header with category name and icon
  - List of ProfileItemRow components
  - "Add Manual Entry" button at bottom
  - Test Gate: Section renders with items

- [ ] Create `Views/Profile/ProfileItemRow.swift`
  - Display: item text, timestamp ("2 weeks ago"), confidence badge
  - Tap gesture → navigate to source message
  - Swipe actions: Edit, Delete
  - Test Gate: Row displays correctly, tap/swipe gestures work

### Profile Item Management

- [ ] Create `Views/Profile/ProfileItemEditView.swift`
  - Inline edit form (TextField with Save/Cancel buttons)
  - Validation (non-empty text)
  - Loading state during save
  - Test Gate: Edit saves successfully, UI updates

- [ ] Create `Views/Profile/AddManualProfileItemView.swift`
  - Form: category picker, text field, save button
  - Validation and error handling
  - Test Gate: Manual entry created and appears in profile

### Supporting Components

- [ ] Create `Components/ProfileEmptyStateView.swift`
  - Message: "No profile data yet. As you chat, I'll remember important details automatically."
  - Icon and helpful text
  - Test Gate: Empty state displays for new profiles

- [ ] Create `Components/ProfileLoadingView.swift`
  - Skeleton loader for profile data
  - Shimmer animation
  - Test Gate: Loading state displays during fetch

- [ ] Create `Components/ProfileConfidenceBadge.swift`
  - Visual indicator: High (green), Medium (yellow), Low (red)
  - Small badge next to profile items
  - Test Gate: Badge displays with correct colors

---

## 6. ViewModels

### ClientProfileViewModel

- [ ] Create `ViewModels/ClientProfileViewModel.swift`
  - `@Published var profile: ClientProfile?`
  - `@Published var isLoading: Bool`
  - `@Published var errorMessage: String?`
  - Test Gate: ViewModel compiles, properties work

- [ ] Implement `loadProfile(clientId:)` method
  - Call ProfileService.fetchClientProfile
  - Update @Published properties
  - Handle errors
  - Test Gate: Profile loads and UI updates

- [ ] Implement `observeProfile(clientId:)` method
  - Set up Firestore listener via ProfileService
  - Update profile on changes
  - Test Gate: Profile updates in real-time when Firestore changes

- [ ] Implement `updateItem(itemId:newText:)` method
  - Call ProfileService.updateProfileItem
  - Optimistic UI update
  - Test Gate: Edit persists, UI updates immediately

- [ ] Implement `deleteItem(itemId:)` method
  - Call ProfileService.deleteProfileItem
  - Remove from local state
  - Test Gate: Delete works, UI updates

- [ ] Implement `addManualItem(category:text:)` method
  - Call ProfileService.addManualProfileItem
  - Add to local state optimistically
  - Test Gate: Manual item created, appears in UI

### ProfileDetailViewModel

- [ ] Create `ViewModels/ProfileDetailViewModel.swift`
  - Manages full profile modal state
  - Filtering, sorting logic
  - Test Gate: ViewModel compiles

- [ ] Implement filtering by category
  - Allow viewing single category at a time
  - Test Gate: Filtering works correctly

- [ ] Implement sorting options
  - Sort by recency (most recent first)
  - Sort by relevance (confidence score)
  - Test Gate: Sorting changes item order

---

## 7. Integration & Real-Time

### Firestore Integration

- [ ] Update Firestore security rules
  - Deploy rules from `firestore.rules`
  - Test Gate: Rules enforce trainer-only access (test with different user IDs)

- [ ] Enable Firestore persistence for offline access
  - Verify persistence enabled in FirebaseService initialization
  - Test Gate: Profiles accessible offline (airplane mode test)

### Real-Time Listeners

- [ ] Set up profile listener in ChatView
  - Call viewModel.observeProfile(clientId:) on appear
  - Cancel listener on disappear
  - Test Gate: Profile updates in real-time during conversation

### Message Integration

- [ ] Test extraction trigger on message send
  - Send test message as client: "My knee hurts"
  - Verify Cloud Function fires
  - Verify profile updates within 60 seconds
  - Test Gate: Extraction works end-to-end

---

## 8. User-Centric Testing

### Happy Path

- [ ] **User opens conversation → Profile banner displays**
  - Test: Open chat with client who has existing profile
  - Expected: Profile banner appears within 500ms with categorized info
  - Pass: ✅ Profile loads quickly, shows injuries/goals/equipment

- [ ] **Client mentions new information → AI extracts and updates**
  - Test: Send "My shoulder has been hurting" as client
  - Expected: Within 60 seconds, profile shows "Shoulder pain" in Injuries
  - Pass: ✅ Extraction successful, item appears with timestamp

- [ ] **Trainer taps profile item → Navigates to source message**
  - Test: Tap "Shoulder pain" in profile banner
  - Expected: Chat scrolls to original message within 1 second
  - Pass: ✅ Navigation works, message highlighted

### Edge Cases

- [ ] **Edge Case 1: Empty profile (first conversation)**
  - Test: Open conversation with new client, no messages yet
  - Expected: Shows empty state: "No profile data yet..."
  - Pass: ✅ Empty state displays, no errors

- [ ] **Edge Case 2: Duplicate information mentioned**
  - Test: Client mentions "shoulder pain" twice
  - Expected: Profile shows single entry with most recent timestamp
  - Pass: ✅ Duplicate detection works

- [ ] **Edge Case 3: Ambiguous information**
  - Test: Client says "I'm traveling next week"
  - Expected: Extracted with Medium confidence, flagged for review
  - Pass: ✅ Confidence indicator shows, trainer can edit

- [ ] **Edge Case 4: Very long profile (100+ items)**
  - Test: Open profile modal with 100+ items
  - Expected: Smooth scrolling, no lag
  - Pass: ✅ LazyVStack used, performance acceptable

### Error Handling

- [ ] **Offline Mode**
  - Test: Enable airplane mode → load profile
  - Expected: Cached profile displays, "Offline" banner shown
  - Pass: ✅ Offline access works

- [ ] **Extraction Failure**
  - Test: Simulate Cloud Function timeout
  - Expected: Message sends successfully, extraction retries in background
  - Pass: ✅ Graceful degradation, no user-facing error

- [ ] **Invalid Profile Data**
  - Test: Corrupt profile data in Firestore
  - Expected: Error state: "Couldn't load profile. Tap to retry."
  - Pass: ✅ Error handled gracefully

- [ ] **Permission Denied**
  - Test: Attempt to access profile for non-assigned client
  - Expected: "You don't have permission" message
  - Pass: ✅ Security rules enforced

### Manual Editing

- [ ] **Trainer edits profile item**
  - Test: Edit "Shoulder pain" → "Shoulder impingement" → Save
  - Expected: Update saves within 1 second, new text displays
  - Pass: ✅ Edit successful, marked as manually edited

- [ ] **Trainer deletes profile item**
  - Test: Swipe to delete "Shoulder pain"
  - Expected: Item deleted within 1 second, disappears from UI
  - Pass: ✅ Deletion successful

- [ ] **Trainer adds manual entry**
  - Test: Add manual "Goals" entry: "Run 5K"
  - Expected: Item created with "manual" source tag
  - Pass: ✅ Manual item appears in Goals section

### Final Checks

- [ ] **No console errors** during all test scenarios
- [ ] **Feature feels responsive** (no noticeable lag)
- [ ] **Multi-device sync works** (optional: verify profile updates across devices)

---

## 9. Performance

### Verify Targets from PRD

- [ ] **Profile load time < 500ms**
  - Test: Measure time from opening conversation to banner display
  - Tool: Add print statements with timestamps
  - Test Gate: Consistently under 500ms

- [ ] **Extraction latency < 60 seconds**
  - Test: Send message, wait for profile update
  - Measure: Time from message send to profile update
  - Test Gate: Updates appear within 60 seconds

- [ ] **Smooth 60fps scrolling (100+ items)**
  - Test: Open full profile modal with 100+ items
  - Verify: Smooth scrolling with no dropped frames
  - Test Gate: LazyVStack used, performance acceptable

- [ ] **No impact on message send performance**
  - Test: Send message, measure time to "delivered" status
  - Verify: < 100ms (same as without profile extraction)
  - Test Gate: Message send unaffected by background extraction

---

## 10. Acceptance Gates

### From PRD Section 12 - Verify All Gates Pass

- [ ] **Happy Path Gate 1:** Profile banner appears within 500ms with accurate data
- [ ] **Happy Path Gate 2:** Client mention extracted and categorized within 60 seconds
- [ ] **Happy Path Gate 3:** Tapping profile item navigates to source message within 1 second
- [ ] **Edge Case Gate 1:** Empty state displays for new profiles
- [ ] **Edge Case Gate 2:** Duplicate detection prevents duplicate entries
- [ ] **Edge Case Gate 3:** Ambiguous info extracted with confidence indicator
- [ ] **Edge Case Gate 4:** Large profiles (100+) scroll smoothly
- [ ] **Error Gate 1:** Offline mode shows cached profile
- [ ] **Error Gate 2:** Extraction failures don't block message send
- [ ] **Error Gate 3:** Invalid data shows retry option
- [ ] **Error Gate 4:** Permission denied handled gracefully
- [ ] **Edit Gate 1:** Edit saves within 1 second
- [ ] **Edit Gate 2:** Delete removes item within 1 second
- [ ] **Edit Gate 3:** Manual entry created successfully

---

## 11. Documentation & PR

### Code Documentation

- [ ] Add inline comments for complex extraction logic (Cloud Functions)
- [ ] Add TSDoc comments to Cloud Function exports
- [ ] Add Swift documentation comments to ProfileService public methods
- [ ] Document ProfileItem structure in architecture.md
  - Update "AI System Integration Plan" section
  - Add ProfileService to service layer documentation

### README Updates

- [ ] Update root README.md if needed (likely no changes needed)
- [ ] Consider adding profile extraction examples to AI-BUILD-PLAN.md

### PR Description

- [ ] Draft PR description using format from `Psst/agents/caleb-agent.md`:
  ```markdown
  # PR #007: Contextual Intelligence (Auto Client Profiles)

  ## Summary
  [Brief description of feature]

  ## Changes
  - New Firestore collection: `/clientProfiles/{clientId}`
  - Cloud Function: `extractProfileInfo` (auto-extraction on message send)
  - iOS Service: `ProfileService.swift` (CRUD operations)
  - UI Components: 9 new views + 3 modified
  - ViewModels: ClientProfileViewModel, ProfileDetailViewModel

  ## Testing
  - [x] All acceptance gates pass
  - [x] Manual testing completed (happy path, edge cases, errors)
  - [x] Performance targets met (<500ms load, <60s extraction)
  - [x] Offline access works
  - [x] Security rules enforced

  ## Screenshots
  [Add screenshots of profile banner, detail view, edit flow]

  ## Related
  - PRD: `Psst/docs/prds/pr-007-prd.md`
  - TODO: `Psst/docs/todos/pr-007-todo.md`
  - Depends on: PR #005 (RAG Pipeline), PR #001 (AI Infrastructure)
  ```

### Final Review

- [ ] Verify with user before creating PR
  - Show demo of profile extraction working
  - Walk through edit/delete flows
  - Show offline access
  - Confirm all features working as expected

### Create PR

- [ ] Open PR targeting `develop` branch
- [ ] Link PRD and TODO in PR description
- [ ] Add labels: `enhancement`, `ai-features`, `phase-3`
- [ ] Request code review
- [ ] Address review feedback
- [ ] Merge when approved

---

## Copyable Checklist (for PR description)

```markdown
## Definition of Done

- [ ] Branch created from develop (`feat/pr-007-contextual-intelligence`)
- [ ] All TODO tasks completed (72 tasks total)
- [ ] Cloud Functions implemented with TypeScript (extractProfileInfo, backfillClientProfile)
- [ ] ProfileService implemented with all CRUD operations
- [ ] Swift models created (ClientProfile, ProfileItem, ProfileCategory, ProfileItemSource)
- [ ] UI components implemented (banner, detail view, edit forms, empty state)
- [ ] ViewModels implemented (ClientProfileViewModel, ProfileDetailViewModel)
- [ ] Firebase security rules deployed (trainer-only access)
- [ ] Real-time Firestore listeners working
- [ ] Offline profile access (Firestore persistence)
- [ ] Manual testing completed:
  - [x] Happy path (extraction, display, navigation)
  - [x] Edge cases (empty, duplicates, ambiguous, large profiles)
  - [x] Error handling (offline, extraction failure, invalid data, permissions)
  - [x] Manual editing (edit, delete, add entries)
- [ ] Performance targets met:
  - [x] Profile load < 500ms
  - [x] Extraction < 60 seconds
  - [x] Smooth scrolling with 100+ items
- [ ] All acceptance gates pass (14 gates from PRD)
- [ ] Code follows `Psst/agents/shared-standards.md` patterns
- [ ] TypeScript used for ALL Cloud Functions (NO JavaScript)
- [ ] No console warnings or errors
- [ ] Documentation updated (inline comments, architecture.md)
```

---

## Notes

- **Task Size:** Each task < 30 min (if larger, break down further)
- **Sequential Execution:** Complete tasks in order (dependencies matter)
- **Check Off After Completion:** Mark [ ] → [x] immediately after finishing
- **Document Blockers:** If stuck, document issue and flag for help
- **Reference Standards:** Use `Psst/agents/shared-standards.md` for patterns and solutions
- **TypeScript Only:** ALL Cloud Functions use `.ts` files (NEVER `.js`)
- **Test As You Go:** Don't save all testing for the end
- **Commit Often:** Small, focused commits with clear messages

---

**Total Tasks:** 72 (broken into < 30 min chunks)
**Estimated Time:** 24-36 hours (depends on complexity of extraction logic)
**Dependencies:** PR #001, PR #003, PR #005 must be completed first
**Blocker Risk:** Extraction accuracy may require prompt iteration (budget extra time)

---

**Document Owner:** Pam (Planning Agent)
**Status:** Ready for Caleb (Coder Agent)
**Next Step:** `/caleb 007` to begin implementation
