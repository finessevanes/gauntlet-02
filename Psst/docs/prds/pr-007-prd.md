# PRD: Contextual Intelligence (Auto Client Profiles)

**Feature**: Auto Client Profiles

**Version**: 1.0

**Status**: Draft

**Agent**: Caleb

**Target Release**: Phase 3 - Contextual Intelligence

**Links**: [PR Brief: ai-briefs.md#007], [TODO: pr-007-todo.md]

---

## 1. Summary

Automatically build rich client profiles from conversations without manual data entry. As trainers exchange messages with clients, AI extracts and categorizes key information (injuries, goals, equipment, preferences, travel, stress factors) and maintains a living knowledge base that grows automatically. When trainers open a conversation, relevant profile insights surface contextually, enabling personalized coaching at scale.

---

## 2. Problem & Goals

### Problem
Personal trainers manage 15-30+ clients, each with unique injuries, goals, equipment, preferences, and life situations. Currently, trainers must either:
- Manually track client details in spreadsheets or notes (time-consuming, often skipped)
- Rely on memory (mental gymnastics, details get lost)
- Re-ask clients about previously discussed information (unprofessional, breaks rapport)

**Result:** Generic advice, clients feel unheard, missed opportunities for personalization.

### Why Now?
This feature enables the **"second brain"** capability that differentiates Psst from basic messaging apps. It directly addresses the information overload problem (Problem #1 from AI-PRODUCT-VISION.md) and enables personalized coaching at scale.

### Goals (ordered, measurable):
- [ ] G1 — Automatically extract and categorize 95%+ of client information mentioned in conversations
- [ ] G2 — Surface relevant profile insights when trainer opens conversations (< 2 second load time)
- [ ] G3 — Allow manual edits/corrections to AI-extracted data with clear UI for override
- [ ] G4 — Reduce time trainers spend manually tracking client details from ~15 min/week to 0

---

## 3. Non-Goals / Out of Scope

- [ ] Manual profile creation forms (auto-extraction only in this PR)
- [ ] Client-facing profile views (trainer-only feature)
- [ ] Complex data visualizations (charts, graphs) - simple categorized list only
- [ ] Integration with external CRM systems (future PR)
- [ ] Workout plan generation based on profiles (deferred to Phase 6+)
- [ ] Nutrition tracking or meal plan generation
- [ ] Progress tracking dashboards or analytics

---

## 4. Success Metrics

### User-visible:
- **Time to view profile:** < 2 seconds from opening conversation
- **Profile completeness:** 95%+ of mentioned details extracted within 24 hours
- **Edit success rate:** Trainers can correct AI extractions in < 3 taps

### System:
- **Extraction accuracy:** 90%+ precision (AI correctly identifies relevant info)
- **Processing latency:** Profile updates within 60 seconds of message send
- **Profile load time:** < 500ms to display existing profile data
- **Storage efficiency:** < 50KB per client profile

### Quality:
- 0 blocking bugs before merging to develop
- All acceptance gates pass (defined in Section 12)
- Crash-free rate >99%
- Profile data never lost or corrupted

---

## 5. Users & Stories

**Primary User:** Alex (The Adaptive Trainer)
- Manages 20 clients with constantly changing contexts
- Does mental gymnastics tracking everyone's details
- Wants to provide personalized coaching without manual note-taking

**User Stories:**

1. As Alex, I want the AI to remember when Mike mentioned his shoulder injury, so I can reference it weeks later without scrolling through messages.

2. As Alex, I want to see a client's equipment list when opening their chat, so I can send appropriate workouts without asking "what do you have access to?" repeatedly.

3. As Alex, I want the AI to flag when a client mentions travel, so I can proactively prepare travel-friendly workouts.

4. As Alex, I want to correct AI mistakes when it misinterprets something, so the profile stays accurate over time.

5. As Alex, I want to see how long ago information was mentioned, so I can reference recent context or check if details are outdated.

---

## 6. Experience Specification (UX)

### Entry Points

**Primary Entry:**
- Trainer opens any conversation → Profile insights appear in header/banner above messages

**Secondary Entry:**
- Long-press message → "Add to Profile" contextual action (links to PR #006)
- AI Assistant suggests profile updates → Trainer reviews and approves

### Visual Behavior

**Profile Display (Conversation Header):**
```
┌──────────────────────────────────────────┐
│ 💪 Mike Thompson                          │
│ ────────────────────────────────────────  │
│ 🏋️ Goals: Lose 20 lbs, Marathon prep     │
│ 🩹 Injuries: Shoulder pain (2 weeks ago)  │
│ 🛠️ Equipment: Home gym, dumbbells only   │
│ ✈️ Travel: Dallas monthly                │
│ ⚙️ Prefs: Morning workouts, vegetarian   │
│                                           │
│ [View Full Profile →]                     │
└──────────────────────────────────────────┘
```

**Condensed View (Chat List):**
- Show 1-2 most relevant tags next to client name
- Example: "Mike Thompson 🩹 Shoulder • ✈️ Traveling"

**Full Profile Modal:**
- Categorized sections (Injuries, Goals, Equipment, Preferences, Travel, Stress Factors)
- Each item shows: text, timestamp, source message preview, edit/delete buttons
- "Add Manual Entry" button at bottom of each section

**Empty State:**
- "No profile data yet. As you chat, I'll remember important details automatically."

### States

1. **Loading:** Skeleton loader while fetching profile
2. **Empty:** No profile data extracted yet (first conversation)
3. **Populated:** Profile data displayed with categories
4. **Editing:** Inline edit mode for corrections
5. **Error:** "Couldn't load profile. Tap to retry."

### Animations

- Profile banner slides down smoothly when opening conversation (300ms ease-out)
- Category pills fade in sequentially (50ms stagger)
- Edit mode transitions with subtle scale animation

### Performance Targets (from shared-standards.md)

- Profile load time: < 500ms (no blocking of message view)
- Profile update after message: < 60 seconds (background processing)
- Smooth scrolling in full profile modal (60fps with 100+ items)
- No UI blocking during extraction or updates

---

## 7. Functional Requirements (Must/Should)

### MUST Requirements

**MUST #1: Automatic Extraction**
- AI extracts client information from conversations as messages are sent/received
- Categories tracked: injuries, goals, equipment, preferences, travel, stress factors
- Extraction happens asynchronously (no blocking of message send)
- [Gate] When client mentions "shoulder pain" → extracted and categorized as injury within 60 seconds

**MUST #2: Structured Storage**
- Profile data stored in Firestore under `clientProfiles/{clientId}`
- Each profile entry includes: category, text, timestamp, source message ID, confidence score
- Data persists across app sessions and device changes
- [Gate] Profile data survives app restart and is available offline (cached)

**MUST #3: Contextual Display**
- Profile insights displayed when trainer opens conversation (header banner)
- Most recent/relevant items shown first (recency + relevance scoring)
- Full profile accessible via modal/detail view
- [Gate] Opening conversation shows profile header within 500ms

**MUST #4: Manual Override**
- Trainers can edit or delete AI-extracted information
- Manual edits override AI suggestions (no re-extraction of edited items)
- Clear visual indicator for manually edited entries
- [Gate] Edit flow completes in < 3 taps (tap item → edit → save)

**MUST #5: Source Attribution**
- Each profile item links to original message where it was mentioned
- Timestamp shows "2 weeks ago" / "3 days ago" for recency context
- Tapping item scrolls to source message in conversation
- [Gate] Tapping profile item navigates to source message within 1 second

### SHOULD Requirements

**SHOULD #1: Smart Categorization**
- AI suggests appropriate category (auto-categorize with 90%+ accuracy)
- Trainers can recategorize items if AI makes mistakes

**SHOULD #2: Duplicate Detection**
- AI detects when same information is mentioned multiple times
- Updates timestamp to most recent mention (doesn't create duplicates)

**SHOULD #3: Confidence Indicators**
- Show confidence level for AI extractions (High/Medium/Low)
- Low confidence items flagged for trainer review

**SHOULD #4: Bulk Actions**
- Delete all profile data for a client (privacy)
- Export profile as text summary (copy to clipboard)

---

## 8. Data Model

### Firestore Schema

```typescript
// Collection: clientProfiles
/clientProfiles/{clientId}
{
  clientId: string,              // User ID of the client
  trainerId: string,             // User ID of the trainer
  createdAt: Timestamp,          // When profile was first created
  updatedAt: Timestamp,          // Last update time

  // Categorized information arrays
  injuries: ProfileItem[],
  goals: ProfileItem[],
  equipment: ProfileItem[],
  preferences: ProfileItem[],
  travel: ProfileItem[],
  stressFactors: ProfileItem[],

  // Metadata
  totalItems: number,            // Count of all items
  lastReviewedAt: Timestamp?     // Last time trainer viewed full profile
}

// ProfileItem structure (nested in arrays above)
interface ProfileItem {
  id: string,                    // Unique ID for this item
  text: string,                  // Extracted information
  category: ProfileCategory,     // injuries | goals | equipment | preferences | travel | stressFactors
  timestamp: Timestamp,          // When mentioned
  sourceMessageId: string,       // Link to original message
  sourceChatId: string,          // Chat where mentioned
  confidenceScore: number,       // 0.0-1.0 (AI confidence)
  isManuallyEdited: boolean,     // Trainer override flag
  editedAt: Timestamp?,          // When manually edited
  createdBy: 'ai' | 'manual'     // Source of entry
}

// Swift Models
struct ClientProfile: Codable, Identifiable {
    let id: String                          // clientId
    let clientId: String
    let trainerId: String
    let createdAt: Date
    let updatedAt: Date

    var injuries: [ProfileItem]
    var goals: [ProfileItem]
    var equipment: [ProfileItem]
    var preferences: [ProfileItem]
    var travel: [ProfileItem]
    var stressFactors: [ProfileItem]

    let totalItems: Int
    let lastReviewedAt: Date?
}

struct ProfileItem: Codable, Identifiable {
    let id: String
    let text: String
    let category: ProfileCategory
    let timestamp: Date
    let sourceMessageId: String
    let sourceChatId: String
    let confidenceScore: Double             // 0.0-1.0
    let isManuallyEdited: Bool
    let editedAt: Date?
    let createdBy: ProfileItemSource
}

enum ProfileCategory: String, Codable {
    case injuries
    case goals
    case equipment
    case preferences
    case travel
    case stressFactors
}

enum ProfileItemSource: String, Codable {
    case ai
    case manual
}
```

### Firebase Security Rules

```javascript
// Firestore Security Rules
match /clientProfiles/{clientId} {
  // Trainers can only read/write their own clients' profiles
  allow read: if request.auth != null &&
    (resource.data.trainerId == request.auth.uid ||
     resource.data.clientId == request.auth.uid);

  allow create: if request.auth != null &&
    request.resource.data.trainerId == request.auth.uid;

  allow update: if request.auth != null &&
    resource.data.trainerId == request.auth.uid;

  allow delete: if request.auth != null &&
    resource.data.trainerId == request.auth.uid;
}
```

### Indexing/Queries

**Firestore Composite Indexes:**
```
Collection: clientProfiles
Fields: trainerId (ASC), updatedAt (DESC)
Purpose: List all client profiles for trainer, sorted by recent updates
```

**Cache Strategy:**
- Profile data cached locally for offline access
- Firestore persistence enabled
- Cache invalidates after 24 hours or on manual refresh

---

## 9. API / Service Contracts

### Cloud Functions

```typescript
/**
 * Extracts profile information from a message and updates client profile
 * Triggered automatically when new messages are sent
 *
 * @param messageId - Firestore message ID
 * @param chatId - Firestore chat ID
 * @returns Updated profile items or null if nothing extracted
 */
export const extractProfileInfo = onMessageCreate(
  async (messageId: string, chatId: string): Promise<ProfileItem[] | null>
);

/**
 * Backfill existing messages to extract profile data
 * One-time migration for existing conversations
 *
 * @param trainerId - User ID of trainer
 * @param clientId - User ID of client
 * @returns Count of items extracted
 */
export const backfillClientProfile = onCall(
  async (trainerId: string, clientId: string): Promise<{ itemsExtracted: number }>
);
```

### iOS Service Layer

```swift
// ProfileService.swift - Service layer for client profiles

/**
 * Fetches client profile for a given client ID
 *
 * @param clientId - User ID of the client
 * @returns ClientProfile or nil if not found
 * @throws ProfileError if fetch fails
 */
func fetchClientProfile(clientId: String) async throws -> ClientProfile?

/**
 * Updates a specific profile item (manual edit)
 *
 * @param clientId - User ID of the client
 * @param itemId - ID of the profile item to update
 * @param newText - Updated text content
 * @returns Updated ProfileItem
 * @throws ProfileError if update fails
 */
func updateProfileItem(
    clientId: String,
    itemId: String,
    newText: String
) async throws -> ProfileItem

/**
 * Deletes a profile item
 *
 * @param clientId - User ID of the client
 * @param itemId - ID of the profile item to delete
 * @throws ProfileError if deletion fails
 */
func deleteProfileItem(clientId: String, itemId: String) async throws

/**
 * Adds a manual profile entry
 *
 * @param clientId - User ID of the client
 * @param category - Profile category (injuries, goals, etc.)
 * @param text - Profile item text
 * @returns Created ProfileItem
 * @throws ProfileError if creation fails
 */
func addManualProfileItem(
    clientId: String,
    category: ProfileCategory,
    text: String
) async throws -> ProfileItem

/**
 * Observes real-time updates to client profile
 *
 * @param clientId - User ID of the client
 * @param completion - Callback with updated ClientProfile
 * @returns Firestore listener registration (to cancel later)
 */
func observeClientProfile(
    clientId: String,
    completion: @escaping (ClientProfile?) -> Void
) -> ListenerRegistration

/**
 * Deletes entire profile for a client (privacy)
 *
 * @param clientId - User ID of the client
 * @throws ProfileError if deletion fails
 */
func deleteClientProfile(clientId: String) async throws
```

### Error Handling

```swift
enum ProfileError: LocalizedError {
    case notAuthenticated
    case notFound
    case extractionFailed(String)
    case updateFailed(String)
    case networkError
    case offline
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be logged in to access profiles"
        case .notFound:
            return "Client profile not found"
        case .extractionFailed(let reason):
            return "Failed to extract profile info: \(reason)"
        case .updateFailed(let reason):
            return "Failed to update profile: \(reason)"
        case .networkError:
            return "Network connection error"
        case .offline:
            return "You're offline. Profile updates will sync when connected."
        case .permissionDenied:
            return "You don't have permission to access this profile"
        }
    }
}
```

---

## 10. UI Components to Create/Modify

### New Components

- `Views/Profile/ClientProfileBannerView.swift` — Condensed profile header in conversation
- `Views/Profile/ClientProfileDetailView.swift` — Full profile modal with all categories
- `Views/Profile/ProfileItemRow.swift` — Individual profile item with edit/delete
- `Views/Profile/ProfileCategorySection.swift` — Categorized section (Injuries, Goals, etc.)
- `Views/Profile/AddManualProfileItemView.swift` — Form to manually add profile entry
- `Views/Profile/ProfileItemEditView.swift` — Inline edit view for existing items
- `Components/ProfileEmptyStateView.swift` — Empty state for new profiles
- `Components/ProfileLoadingView.swift` — Skeleton loader for profile data
- `Components/ProfileConfidenceBadge.swift` — Confidence level indicator (H/M/L)

### New ViewModels

- `ViewModels/ClientProfileViewModel.swift` — Manages profile state and operations
- `ViewModels/ProfileDetailViewModel.swift` — Manages full profile modal state

### New Services

- `Services/ProfileService.swift` — Firestore CRUD for client profiles
- `Services/ProfileExtractionService.swift` — Calls Cloud Function for extraction

### Modified Components

- `Views/ChatList/ChatView.swift` — Add ClientProfileBannerView to conversation header
- `Views/ChatList/MessageRow.swift` — Add "Add to Profile" contextual action (links to PR #006)
- `Views/ChatList/ChatRowView.swift` — Show profile tags next to client name

---

## 11. Integration Points

### Firebase
- **Firestore:** Read/write `/clientProfiles/{clientId}` collection
- **Cloud Functions:** Call `extractProfileInfo` for message processing
- **Firestore Listeners:** Real-time profile updates via `observeClientProfile`

### AI Services (PR #005 - RAG Pipeline)
- Uses semantic extraction to identify relevant client information
- Pinecone vector search for duplicate detection
- OpenAI GPT-4 for categorization and confidence scoring

### Existing Features
- **PR #003 (AI Chat Backend):** Uses profiles to personalize AI responses
- **PR #006 (Contextual AI Actions):** "Add to Profile" long-press action
- **MessageService:** Triggers profile extraction on message send

### State Management
- `@StateObject` for ClientProfileViewModel in conversation view
- `@EnvironmentObject` for shared profile data across views
- SwiftUI `@Published` properties for reactive updates

---

## 12. Testing Plan & Acceptance Gates

**See `Psst/docs/testing-strategy.md` for examples and detailed guidance.**

### Happy Path

- [ ] **User opens conversation → Profile banner displays with categorized information**
  - **Test:** Open chat with client who has existing profile data
  - **Gate:** Profile banner appears within 500ms with accurate categorized items
  - **Pass:** Profile loads quickly, shows injuries/goals/equipment correctly

- [ ] **Client mentions new information → AI extracts and updates profile**
  - **Test:** Send message "My shoulder has been hurting" as client
  - **Gate:** Within 60 seconds, profile updates to include "Shoulder pain" in Injuries category
  - **Pass:** Extraction successful, item appears in profile with timestamp

- [ ] **Trainer taps profile item → Navigates to source message**
  - **Test:** Tap "Shoulder pain" in profile banner
  - **Gate:** Chat scrolls to original message within 1 second
  - **Pass:** Correct message highlighted, smooth navigation

### Edge Cases

- [ ] **Edge Case 1: Empty profile (first conversation)**
  - **Test:** Open conversation with new client, no messages yet
  - **Expected:** Shows empty state: "No profile data yet. As you chat, I'll remember important details automatically."
  - **Pass:** Empty state displays, no crashes or loading errors

- [ ] **Edge Case 2: Duplicate information mentioned**
  - **Test:** Client mentions "shoulder pain" in two separate messages
  - **Expected:** Profile shows single "Shoulder pain" entry with most recent timestamp (no duplicates)
  - **Pass:** Duplicate detection works, only one entry created

- [ ] **Edge Case 3: Ambiguous information**
  - **Test:** Client says "I'm traveling next week" (no location specified)
  - **Expected:** AI extracts "Traveling next week" with Medium confidence, flags for review
  - **Pass:** Item extracted with confidence indicator, trainer can edit to add details

- [ ] **Edge Case 4: Very long profile (100+ items)**
  - **Test:** Open profile modal with 100+ items across all categories
  - **Expected:** Smooth scrolling, no lag, items load incrementally if needed
  - **Pass:** Performance acceptable (60fps), LazyVStack used for efficiency

### Error Handling

- [ ] **Offline Mode**
  - **Test:** Enable airplane mode → attempt to load profile
  - **Expected:** Cached profile displays instantly, banner shows "Offline - updates will sync when connected"
  - **Pass:** Offline access works, clear feedback provided

- [ ] **Extraction Failure**
  - **Test:** Simulate Cloud Function timeout during extraction
  - **Expected:** Message sends successfully, profile extraction retries in background, no user-facing error
  - **Pass:** Graceful degradation, extraction retries automatically

- [ ] **Invalid Profile Data**
  - **Test:** Corrupt profile data in Firestore (malformed JSON)
  - **Expected:** Shows error state: "Couldn't load profile. Tap to retry."
  - **Pass:** Error handled gracefully, retry button works

- [ ] **Permission Denied**
  - **Test:** Attempt to access profile for client not assigned to trainer
  - **Expected:** Shows "You don't have permission to view this profile"
  - **Pass:** Security rules enforced, clear error message

### Manual Editing

- [ ] **Trainer edits profile item → Updates persist**
  - **Test:** Tap "Shoulder pain" → Edit to "Shoulder impingement" → Save
  - **Gate:** Update saves within 1 second, new text displays immediately
  - **Pass:** Edit successful, marked as manually edited, no AI re-extraction

- [ ] **Trainer deletes profile item → Item removed**
  - **Test:** Swipe to delete "Shoulder pain" from profile
  - **Gate:** Item deleted within 1 second, disappears from UI
  - **Pass:** Deletion successful, UI updates smoothly

- [ ] **Trainer adds manual entry → Item created**
  - **Test:** Tap "Add Manual Entry" → Select "Goals" → Enter "Run 5K" → Save
  - **Gate:** Manual item created with "manual" source tag
  - **Pass:** Item appears in Goals section, marked as manually added

### Optional: Multi-Device Testing

**Not required for profile features** (profiles sync via Firestore, standard behavior)

### Performance Check

- [ ] **Profile loads quickly on first open** (< 500ms)
- [ ] **Profile banner doesn't block message scrolling** (independent loading)
- [ ] **Full profile modal scrolls smoothly** (60fps with 100+ items)
- [ ] **Background extraction doesn't impact message send performance** (< 100ms send time)

### No Console Errors

- [ ] Clean console output during all test scenarios
- [ ] No Firestore permission warnings
- [ ] No force unwrap crashes

---

## 13. Definition of Done

- [ ] `ProfileService.swift` implemented with all CRUD operations
- [ ] Cloud Function `extractProfileInfo` deployed and tested
- [ ] `ClientProfileBannerView` displays in conversation header
- [ ] `ClientProfileDetailView` shows full categorized profile
- [ ] Manual edit flow works (edit, delete, add entries)
- [ ] Real-time profile updates via Firestore listeners
- [ ] Offline profile access (cached data)
- [ ] All acceptance gates pass (Happy Path, Edge Cases, Error Handling, Manual Editing)
- [ ] Manual testing completed (configuration, user flows, offline)
- [ ] Code follows `Psst/agents/shared-standards.md` patterns
- [ ] TypeScript used for all Cloud Functions (NO JavaScript)
- [ ] Proper error handling for all failure scenarios
- [ ] No console warnings or errors
- [ ] Documentation updated (inline comments, architecture.md references)
- [ ] PR created targeting `develop` branch with comprehensive description

---

## 14. Risks & Mitigations

### Risk 1: Extraction Accuracy (AI misidentifies information)
**Impact:** HIGH - Incorrect profile data leads to wrong advice, trainer loses trust
**Mitigation:**
- Implement confidence scoring (0.0-1.0) for all extractions
- Flag low-confidence items for manual review
- Allow easy manual correction (< 3 taps to edit)
- Show source message for verification
- A/B test extraction prompts to improve accuracy
- Start with conservative extraction (high precision, lower recall)

### Risk 2: Over-Extraction (AI extracts too much irrelevant info)
**Impact:** MEDIUM - Profile becomes cluttered, harder to find useful information
**Mitigation:**
- Define clear extraction criteria (focus on actionable info only)
- Implement relevance scoring (only extract items > 0.7 relevance)
- Allow bulk deletion of low-value items
- Sort by recency + relevance (most useful items shown first)
- Add "Archive" feature to hide old/irrelevant items

### Risk 3: Privacy Concerns (sensitive client data)
**Impact:** HIGH - Legal/ethical issues, client trust violations
**Mitigation:**
- Clear privacy disclosure during onboarding ("AI remembers client details")
- Firestore security rules enforce trainer-only access
- Easy "Delete All Profile Data" button
- No client-facing profile views (trainer-only in this PR)
- Compliance with data retention policies (future: auto-delete after X months)

### Risk 4: Performance Degradation (large profiles slow down UI)
**Impact:** MEDIUM - Poor UX if profile with 500+ items takes >2 seconds to load
**Mitigation:**
- Use LazyVStack for profile modal (render only visible items)
- Pagination (show 50 items, load more on scroll)
- Background profile loading (don't block message view)
- Cache profile data locally (Firestore persistence)
- Limit profile to 500 items max (archive old entries)

### Risk 5: Extraction Cost (OpenAI API costs for every message)
**Impact:** MEDIUM - Costs scale with message volume
**Mitigation:**
- Batch extraction (process multiple messages in single API call)
- Only extract from client messages (skip trainer messages)
- Implement extraction throttling (max 1 extraction per 10 seconds per chat)
- Use GPT-4o-mini for extraction (cheaper than GPT-4)
- Monitor costs via OpenAI dashboard, set budget alerts

### Risk 6: Duplicate Detection Failures
**Impact:** LOW - Profile contains duplicate entries, cluttered UI
**Mitigation:**
- Semantic similarity check using embeddings (cosine similarity > 0.85 = duplicate)
- Update timestamp on duplicates rather than creating new entries
- Manual "Merge Duplicates" action in UI
- Periodic cleanup job to deduplicate (weekly background task)

---

## 15. Rollout & Telemetry

### Feature Flag
**Yes** - Gradual rollout to monitor extraction quality and performance

**Flag Name:** `client_profiles_enabled`
**Rollout Plan:**
1. **Week 1:** Internal testing (dev team only)
2. **Week 2:** 10% of trainers (monitor accuracy, performance)
3. **Week 3:** 50% of trainers (collect feedback)
4. **Week 4:** 100% rollout

### Metrics to Track

**Usage Metrics:**
- % of trainers who view client profiles (engagement)
- Average profile items per client (extraction volume)
- Manual edit rate (% of items manually edited) → extraction accuracy proxy
- Profile view frequency (how often trainers reference profiles)

**Performance Metrics:**
- Profile load time (p50, p95, p99)
- Extraction latency (time from message send to profile update)
- Firestore read/write counts (cost monitoring)
- Cloud Function execution time (optimization opportunities)

**Quality Metrics:**
- Extraction accuracy (manual validation sample: 100 messages)
- Duplicate rate (% of duplicate items created)
- Confidence score distribution (% high/medium/low)
- Error rate (extraction failures, API timeouts)

**Business Metrics:**
- Time saved on manual note-taking (user survey)
- Client satisfaction with personalization (trainer feedback)
- Trainer retention (do profiles reduce churn?)

### Manual Validation Steps

**Before launch:**
1. Extract profiles from 10 real conversations (trainer + client messages)
2. Manually review extraction accuracy (target: 90%+ precision)
3. Verify no sensitive data extracted inappropriately
4. Test performance with large profiles (100+ items)
5. Confirm offline access works (airplane mode test)

**After launch:**
1. Weekly review of low-confidence extractions (manual validation)
2. Monthly audit of extraction accuracy (sample 100 random items)
3. Quarterly user feedback surveys on profile usefulness

---

## 16. Open Questions

**Q1: Should clients see their own profiles?**
**Decision:** NO for this PR (trainer-only). Defer client-facing profiles to Phase 6+.
**Reason:** Focus on coach value first, privacy concerns, scope creep.

**Q2: How do we handle stale information? (goals change, injuries heal)**
**Decision:** Show timestamps ("mentioned 3 weeks ago"), allow manual archiving, but no auto-expiration yet.
**Reason:** Trainers need to see historical context, auto-deletion risky (might remove still-relevant info).

**Q3: Should we extract from trainer messages or only client messages?**
**Decision:** Client messages only for this PR.
**Reason:** Client messages contain the actionable info (injuries, goals). Trainer messages are instructions/advice (less useful to profile).

**Q4: What if extraction identifies conflicting information? (client says "knee hurts" then "knee is fine")**
**Decision:** Show both with timestamps, let trainer decide. No automatic conflict resolution.
**Reason:** Context matters (injury healing is valuable info). Trainer can manually archive resolved items.

**Q5: Should we integrate with Apple HealthKit or other fitness apps?**
**Decision:** NO, out of scope for this PR. Consider for Phase 6+.
**Reason:** Focus on conversation-based extraction first, external integrations add complexity.

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future PRs:

- [ ] **Client-facing profile views** (Phase 6+) - Clients see their own profiles
- [ ] **Profile sharing** - Export/share profiles with other trainers or coaches
- [ ] **Advanced analytics** - Charts, graphs, progress tracking over time
- [ ] **Conflict resolution** - Automatic handling of contradictory information
- [ ] **External integrations** - HealthKit, MyFitnessPal, Strava data imports
- [ ] **Profile templates** - Pre-built profile structures for different coaching styles
- [ ] **Bulk export** - Export all client profiles as CSV/PDF
- [ ] **Profile versioning** - Track changes to profiles over time (audit log)
- [ ] **Smart reminders** - "Mike mentioned shoulder pain 3 weeks ago, follow up?"
- [ ] **Profile-based workout generation** (Phase 6+) - Auto-create workouts from profile data

---

## Preflight Questionnaire

### 1. Smallest end-to-end user outcome for this PR?
Trainer opens conversation → sees automatically extracted client profile (injuries, goals, equipment) in header → taps item → jumps to source message.

### 2. Primary user and critical action?
**User:** Alex (Adaptive Trainer)
**Action:** View client profile to personalize coaching without manual note-taking

### 3. Must-have vs nice-to-have?
**Must-have:** Extraction, storage, display, manual edit
**Nice-to-have:** Confidence indicators, duplicate detection, bulk actions

### 4. Real-time requirements?
- Profile updates asynchronously (within 60 seconds, not instant)
- Profile loads quickly (< 500ms) but doesn't need real-time sync during conversation
- Firestore listener for profile updates (optional: real-time banner updates if client profile changes during conversation)

### 5. Performance constraints?
- Profile load: < 500ms (see shared-standards.md)
- Extraction: < 60 seconds background processing (no blocking)
- Full profile modal: 60fps scrolling with 100+ items (LazyVStack)
- No impact on message send performance (< 100ms)

### 6. Error/edge cases to handle?
- Empty profile (first conversation)
- Duplicate information mentioned
- Ambiguous information (low confidence)
- Extraction failure (Cloud Function timeout)
- Offline mode (cached profile access)
- Permission denied (security rules)
- Large profiles (100+ items, performance)

### 7. Data model changes?
**New Firestore collection:** `/clientProfiles/{clientId}`
**Structure:** categorized arrays (injuries, goals, equipment, etc.)
**Swift models:** `ClientProfile`, `ProfileItem`, `ProfileCategory`

### 8. Service APIs required?
**Cloud Functions:** `extractProfileInfo(messageId, chatId)`
**iOS Service:** `ProfileService` with fetch, update, delete, observe methods

### 9. UI entry points and states?
**Entry:** Conversation header (banner), full profile modal
**States:** Loading, empty, populated, editing, error

### 10. Security/permissions implications?
- Firestore security rules: Trainers can only access their own clients' profiles
- No client-facing profile views in this PR
- Easy deletion for privacy compliance
- Clear privacy disclosure during onboarding

### 11. Dependencies or blocking integrations?
**Depends on:**
- PR #005 (RAG Pipeline) - Semantic extraction and categorization
- PR #001 (AI Backend Infrastructure) - OpenAI and Pinecone setup
- PR #003 (AI Chat Backend) - GPT-4 integration

**Enables:**
- PR #009 (Proactive Assistant) - Uses profiles to identify at-risk clients
- PR #011 (User Preferences) - Similar pattern for trainer preferences
- PR #013 (Multi-Step Agent) - Uses profiles for personalized lead qualification

### 12. Rollout strategy and metrics?
**Strategy:** Feature flag, gradual rollout (10% → 50% → 100%)
**Metrics:** Extraction accuracy (90%+), profile load time (< 500ms), manual edit rate, engagement

### 13. What is explicitly out of scope?
- Client-facing profile views
- Workout plan generation from profiles
- External integrations (HealthKit, MyFitnessPal)
- Advanced analytics (charts, graphs)
- Profile sharing between trainers
- Automatic conflict resolution
- Profile versioning/audit log

---

## Authoring Notes

- **Vertical slice:** Focus on extraction → storage → display → edit flow (complete user journey)
- **Service layer:** ProfileService is deterministic, SwiftUI views are thin wrappers
- **Offline-first:** Profile data cached locally, Firestore persistence enabled
- **Test before code:** Define acceptance gates BEFORE implementation
- **Reference shared-standards.md:** Performance targets, testing approach, code quality standards
- **TypeScript-only:** All Cloud Functions use TypeScript (`.ts` files), NEVER JavaScript
- **Privacy-first:** Clear data ownership, easy deletion, security rules enforced

---

**Document Owner:** Pam (Planning Agent)
**Status:** Draft - Ready for Review
**Next Step:** User approval → Create TODO list (pr-007-todo.md)
