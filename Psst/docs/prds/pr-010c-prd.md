# PRD: Google Calendar Integration (One-Way Sync)

**Feature**: Google Calendar One-Way Sync (Psst → Google)

**Version**: 1.0

**Status**: Draft

**Agent**: Pam (Planning Agent)

**Target Release**: Phase 4 (Part 3 of 3)

**Dependencies**:
- PR #010A (Calendar Foundation - REQUIRED)
- PR #010B (AI Scheduling - Optional but recommended)

**Links**: [PR Brief](../ai-briefs.md#pr-010), [TODO](../todos/pr-010c-todo.md)

---

## 1. Summary

Add one-way sync from Psst to Google Calendar so trainers see their Psst events (Training sessions, Calls, Adhoc appointments) in their actual Google Calendar app alongside other life appointments. Uses OAuth 2.0 for authentication, automatically syncs created/updated/deleted events within 5 seconds, handles token refresh automatically, and provides clear sync status feedback (✅ Synced, ⏳ Syncing, ❌ Failed).

---

## 2. Problem & Goals

**Problem:**
Trainers manage their life across multiple calendars - Psst for client sessions, Google Calendar for doctor appointments, personal events, etc. Switching between apps creates friction. They want all events in one place: their Google Calendar app.

**Why Now:**
PR #010A provides calendar foundation. PR #010B adds AI scheduling. But events only exist in Psst - trainers can't see their training schedule in the calendar app they already use daily (Google Calendar). One-way sync (Psst → Google) makes Psst events visible everywhere.

**Goals:**
- [x] G1 — All Psst events automatically sync to trainer's Google Calendar within 5 seconds
- [x] G2 — OAuth connection flow is smooth (one-time setup, auto-refresh after)
- [x] G3 — Sync failures handled gracefully with retry options
- [x] G4 — Trainers can disconnect Google Calendar anytime

---

## 3. Non-Goals / Out of Scope

- [ ] **NOT doing** two-way sync (Google → Psst) → Too complex, risk of conflicts and overwrites
- [ ] **NOT doing** sync from other calendar services (iCloud, Outlook) → Google only for Phase 4
- [ ] **NOT doing** calendar import/merge → One-way: Psst → Google only
- [ ] **NOT doing** selective sync (some events synced, others not) → All events sync

---

## 4. Success Metrics

**User-visible:**
- Sync latency: < 5 seconds (Psst event created → appears in Google Calendar)
- OAuth connection time: < 30 seconds (full flow)
- Sync success rate: >99%

**System:**
- Token refresh success: >99% (automatic, no user intervention)
- Retry success rate: >90% (after transient failures)
- API error rate: <1% (excluding user-caused errors like invalid tokens)

**Quality:**
- 0 duplicate events in Google Calendar
- All acceptance gates pass
- Crash-free rate >99%

---

## 5. Users & Stories

**User: Alex (Trainer)**

1. **As a trainer,** I want my Psst sessions to appear in Google Calendar **so that** I see training appointments alongside my doctor visits, errands, and personal events.

2. **As a trainer,** I want Google Calendar sync to happen automatically **so that** I don't have to manually copy events.

3. **As a trainer,** I want to know when sync fails **so that** I can retry or reconnect my account.

4. **As a trainer,** I want to disconnect Google Calendar anytime **so that** I have control over my data.

---

## 5b. Affected Existing Code (Brownfield)

### Modified Files

**`CalendarEvent.swift`** (EXISTING from PR #010A - ADD FIELDS):
- **ADD**: `googleCalendarEventId: String?` (stores Google event ID for updates/deletes)
- **ADD**: `syncedAt: Date?` (last successful sync timestamp)

**`User.swift`** (EXISTING - ADD FIELDS):
- **ADD**: `integrations.googleCalendar.refreshToken: String?` (OAuth refresh token)
- **ADD**: `integrations.googleCalendar.connectedAt: Date?`
- **ADD**: `integrations.googleCalendar.connectedEmail: String?`

**`SettingsView.swift`** (EXISTING - ADD SECTION):
- Add "Calendar" section with Google Calendar connection status
- [Connect to Google Calendar] button → OAuth flow
- [Disconnect] button when connected

**`CalendarService.swift`** (EXISTING from PR #010A - INTEGRATE SYNC):
- After createEvent() → Call GoogleCalendarSyncService.syncEventToGoogle()
- After updateEvent() → Re-sync to Google Calendar
- After deleteEvent() → Delete from Google Calendar

**Firestore `/calendar/{eventId}`** (EXISTING - ADD FIELDS):
- Add `googleCalendarEventId` and `syncedAt` fields

**Firestore `/users/{uid}`** (EXISTING - ADD NESTED OBJECT):
- Add `integrations.googleCalendar` nested object

---

## 6. Experience Specification (UX)

### Entry Point

**Settings → Calendar → Google Calendar**

### OAuth Connection Flow

1. Tap **[Connect to Google Calendar]** in Settings → Calendar
2. Google Sign-In sheet appears
3. User selects Google account
4. Google permission screen: "Psst wants to manage your calendar events"
5. User taps [Allow]
6. OAuth completes → Refresh token stored in Firestore
7. Settings shows: "✅ Connected: alex@gmail.com" with [Disconnect] button
8. All existing Psst events sync to Google Calendar (one-time backfill)

### Sync Behavior

**Event Creation:**
1. User creates event in Psst (manual or AI)
2. Event saves to Firestore `/calendar/{eventId}`
3. Background: GoogleCalendarSyncService.syncEventToGoogle() called
4. Event card shows "⏳ Syncing..." badge
5. Google Calendar API creates event → Returns Google event ID
6. Update Firestore with `googleCalendarEventId` and `syncedAt`
7. Event card shows "✅ Synced" badge
8. Total time: < 5 seconds

**Event Update (Reschedule):**
1. User edits event time in Psst
2. Firestore updated
3. Background: Re-sync using existing `googleCalendarEventId` (UPDATE, not create new)
4. Google Calendar event updated with new time
5. "✅ Synced" badge shown

**Event Deletion:**
1. User deletes event in Psst
2. Firestore event deleted (or status = cancelled)
3. Background: Delete from Google Calendar using `googleCalendarEventId`
4. Google Calendar event removed

### Sync Status Indicators

**Event Card Badges:**
- **✅ Synced** (green) - Last synced timestamp shown in EventDetailView
- **⏳ Syncing...** (yellow, animated) - Sync in progress
- **❌ Sync failed** (red) - With [Retry] button

**Settings Status:**
- **Connected**: "✅ Connected: alex@gmail.com"
- **Disconnected**: "⚠️ Google Calendar disconnected. [Reconnect]"
- **Last sync**: "Last synced: 2 minutes ago"

### Error States

**OAuth Token Expired:**
- Banner in CalendarView: "⚠️ Google Calendar disconnected. [Reconnect]"
- Events still save to Psst (calendar functional)
- Sync queued for retry after reconnection

**Network Failure:**
- "⏳ Syncing..." status persists
- Retry with exponential backoff (5s, 10s, 30s)
- After 3 failures → "❌ Sync failed. [Retry]"

**Rate Limit (429 from Google):**
- Automatic retry after rate limit window (check Retry-After header)
- User sees "⏳ Syncing..." (no error shown)
- Transparent handling

---

## 7. Functional Requirements

### OAuth 2.0 Authentication

**MUST:**
- **REQ-1**: OAuth 2.0 connection flow
  - Scope: `https://www.googleapis.com/auth/calendar.events`
  - Store refresh token in Firestore `/users/{uid}/integrations/googleCalendar/refreshToken`
  - [Gate] Complete OAuth → Refresh token stored → Settings shows "✅ Connected"

- **REQ-2**: Automatic token refresh
  - Detect expired access token (401 response)
  - Use refresh token to get new access token
  - No user intervention required
  - [Gate] Access token expires → Auto-refreshes → Sync continues without user action

- **REQ-3**: Token expiration handling
  - If refresh token invalid (user revoked access) → Show reconnect prompt
  - Banner: "⚠️ Google Calendar disconnected. [Reconnect]"
  - [Gate] Revoked token → Reconnect prompt shown → User reconnects → Sync resumes

### Event Sync (Create, Update, Delete)

**MUST:**
- **REQ-4**: One-way sync on event creation
  - Event created in Psst → Immediately sync to Google Calendar
  - Store `googleCalendarEventId` in Firestore
  - Update `syncedAt` timestamp
  - [Gate] Create event in Psst → Appears in Google Calendar within 5 seconds

- **REQ-5**: One-way sync on event update
  - Event updated in Psst (reschedule, edit title, etc.) → Update in Google Calendar
  - Use existing `googleCalendarEventId` (UPDATE, not duplicate)
  - [Gate] Reschedule event in Psst → Google Calendar event updated (not duplicated)

- **REQ-6**: One-way sync on event deletion
  - Event deleted in Psst → Delete from Google Calendar using `googleCalendarEventId`
  - [Gate] Delete event in Psst → Google Calendar event removed

### Sync Retry & Error Handling

**MUST:**
- **REQ-7**: Retry failed syncs with exponential backoff
  - Network failure → Retry after 5s, 10s, 30s
  - After 3 attempts → Show "❌ Sync failed. [Retry]" with manual retry button
  - [Gate] Network failure → Retries 3 times → Shows retry button if still failing

- **REQ-8**: Handle rate limiting (429 errors)
  - Detect 429 response from Google API
  - Check `Retry-After` header → Wait specified time
  - Retry automatically → User sees "⏳ Syncing..." (no error)
  - [Gate] Rate limit hit → Waits for window → Retries successfully

**SHOULD:**
- **REQ-9**: Backfill existing events on initial connection
  - When user connects Google Calendar for first time
  - Sync all existing Psst events (last 30 days) to Google Calendar
  - [Gate] Connect Google Calendar → All recent events appear in Google Calendar

### Disconnection

**MUST:**
- **REQ-10**: Disconnect Google Calendar
  - [Disconnect] button in Settings → Confirmation alert
  - Revoke OAuth token
  - Clear refresh token from Firestore
  - Events remain in Google Calendar (don't delete user's data)
  - Future events don't sync until reconnected
  - [Gate] Tap Disconnect → Confirmation → Token revoked → Settings shows [Connect] button

---

## 8. Data Model

### Firestore Schema Extensions

**`/calendar/{eventId}` (ADD FIELDS)**

```swift
{
  // Existing fields from 010A...

  // NEW FIELDS
  googleCalendarEventId: String?,  // Google Calendar event ID (for updates/deletes)
  syncedAt: Timestamp?  // Last successful sync timestamp
}
```

**`/users/{uid}` (ADD NESTED OBJECT)**

```swift
{
  // Existing fields...

  // NEW NESTED OBJECT
  integrations: {
    googleCalendar: {
      refreshToken: String?,  // OAuth refresh token (encrypted by Firestore)
      connectedAt: Timestamp?,
      connectedEmail: String?  // Google account email
    }
  }
}
```

---

### Swift Model Extensions

**`CalendarEvent.swift` (ADD FIELDS)**

```swift
struct CalendarEvent: Identifiable, Codable {
    // Existing fields from 010A...

    // NEW
    let googleCalendarEventId: String?
    let syncedAt: Date?

    var isSynced: Bool {
        googleCalendarEventId != nil
    }

    var syncStatusText: String {
        guard let syncedAt = syncedAt else { return "Not synced" }
        let formatter = RelativeDateTimeFormatter()
        return "Synced \(formatter.localizedString(for: syncedAt, relativeTo: Date()))"
    }
}
```

**`User.swift` (ADD FIELDS)**

```swift
struct User: Identifiable, Codable {
    // Existing fields...

    var integrations: UserIntegrations?

    struct UserIntegrations: Codable {
        var googleCalendar: GoogleCalendarIntegration?

        struct GoogleCalendarIntegration: Codable {
            var refreshToken: String?
            var connectedAt: Date?
            var connectedEmail: String?
        }
    }

    var isGoogleCalendarConnected: Bool {
        integrations?.googleCalendar?.refreshToken != nil
    }
}
```

---

## 9. API / Service Contracts

### New Service: GoogleCalendarSyncService.swift

```swift
import Foundation
import GoogleSignIn

class GoogleCalendarSyncService: ObservableObject {
    @Published var isConnected: Bool = false
    @Published var connectedEmail: String?

    // MARK: - OAuth

    /// Connect Google Calendar via OAuth 2.0
    func connectGoogleCalendar() async throws -> Bool

    /// Disconnect (revoke OAuth token)
    func disconnectGoogleCalendar() async throws

    /// Check connection status
    func checkConnectionStatus() async -> Bool

    // MARK: - Sync

    /// Sync event to Google Calendar (create or update)
    /// - Returns: Google Calendar event ID
    func syncEventToGoogle(event: CalendarEvent) async throws -> String

    /// Delete event from Google Calendar
    func deleteEventFromGoogle(googleEventId: String) async throws

    /// Retry sync with exponential backoff (internal)
    func retrySyncWithBackoff(event: CalendarEvent, attempt: Int = 1) async throws -> String

    // MARK: - Backfill

    /// Backfill existing Psst events to Google Calendar (on first connection)
    func backfillExistingEvents(trainerId: String) async throws

    // MARK: - Token Management (Internal)

    private func refreshAccessToken() async throws -> String

    // MARK: - Errors

    enum GoogleCalendarError: Error, LocalizedError {
        case notConnected
        case authFailed(String)
        case permissionDenied
        case syncFailed(String)
        case rateLimitExceeded(retryAfter: Int)
        case tokenRefreshFailed
        case networkError

        var errorDescription: String? {
            // ... error messages
        }
    }
}
```

---

### Enhanced CalendarService (Integrate Sync)

```swift
extension CalendarService {

    /// Create event and sync to Google Calendar
    func createEvent(...) async throws -> CalendarEvent {
        // 1. Create in Firestore (existing logic from 010A)
        let event = try await createEventInFirestore(...)

        // 2. Sync to Google Calendar (NEW)
        if googleCalendarService.isConnected {
            Task {
                do {
                    let googleEventId = try await googleCalendarService.syncEventToGoogle(event: event)
                    // Update Firestore with googleCalendarEventId
                    try await updateEvent(eventId: event.id, updates: [
                        "googleCalendarEventId": googleEventId,
                        "syncedAt": FieldValue.serverTimestamp()
                    ])
                } catch {
                    // Log error, show sync failed badge
                    print("Google Calendar sync failed: \(error)")
                }
            }
        }

        return event
    }

    // Similar integration for updateEvent() and deleteEvent()
}
```

---

## 10. UI Components to Create

### NEW VIEWS (5 files)

1. **`GoogleCalendarConnectionView.swift`** - OAuth connection UI in Settings → Calendar
2. **`GoogleCalendarStatusBanner.swift`** - "Disconnected" banner in CalendarView
3. **`EventSyncStatusBadge.swift`** - ✅/⏳/❌ badges on event cards
4. **`SyncRetryButton.swift`** - [Retry] button for failed syncs
5. **`CalendarSettingsView.swift`** - Calendar settings page with Google connection

### MODIFIED VIEWS (3 files)

1. **`SettingsView.swift`** - Add Calendar section
2. **`EventDetailView.swift`** - Show sync status + last synced timestamp
3. **`EventCardView.swift`** - Show sync status badge

---

## 11. Testing Plan

### Happy Path

**Scenario: First-time Google Calendar connection**
- [ ] Open Settings → Calendar → Tap [Connect to Google Calendar]
- [ ] Google Sign-In sheet → Select account → Allow permissions
- [ ] **Gate**: OAuth completes → Refresh token stored in Firestore
- [ ] **Gate**: Settings shows "✅ Connected: alex@gmail.com"
- [ ] **Gate**: All existing Psst events (last 30 days) sync to Google Calendar
- [ ] **Pass**: Connection successful, backfill works

**Scenario: Event creation with sync**
- [ ] Create event in Psst (manual or AI)
- [ ] **Gate**: Event saved to Firestore
- [ ] **Gate**: Event syncs to Google Calendar within 5 seconds
- [ ] **Gate**: Event card shows "✅ Synced" badge
- [ ] **Gate**: Open Google Calendar app → Event visible with correct title, time, description
- [ ] **Pass**: Sync works end-to-end

**Scenario: Event update (reschedule)**
- [ ] Reschedule event in Psst (change time from 6pm to 7pm)
- [ ] **Gate**: Firestore updated
- [ ] **Gate**: Google Calendar event updated (same event, not duplicate)
- [ ] **Gate**: Open Google Calendar → Event shows new time (7pm)
- [ ] **Pass**: Update syncs correctly, no duplicates

**Scenario: Event deletion**
- [ ] Delete event in Psst
- [ ] **Gate**: Firestore event deleted
- [ ] **Gate**: Google Calendar event removed
- [ ] **Gate**: Open Google Calendar → Event gone
- [ ] **Pass**: Deletion syncs correctly

### Edge Cases

**Edge Case 1: OAuth token expiration**
- [ ] **Test**: Manually expire access token (or wait for natural expiration ~1 hour)
- [ ] **Expected**: Create event → Sync detects expired token → Auto-refreshes using refresh token → Sync succeeds
- [ ] **Pass**: Token refresh automatic, no user interruption

**Edge Case 2: Refresh token revoked**
- [ ] **Test**: User revokes Psst access in Google Account settings
- [ ] **Expected**: Create event → Sync fails → Banner: "⚠️ Google Calendar disconnected. [Reconnect]"
- [ ] **Pass**: Clear reconnect prompt, event still saved in Psst

**Edge Case 3: Network failure during sync**
- [ ] **Test**: Enable airplane mode → Create event → Disable airplane mode
- [ ] **Expected**: Event saved in Psst → "⏳ Syncing..." → Retries when online → "✅ Synced"
- [ ] **Pass**: Automatic retry works, eventual success

**Edge Case 4: Rate limit (429 error)**
- [ ] **Test**: (Mock) Create 20 events rapidly to trigger rate limit
- [ ] **Expected**: First N events sync → Rate limit hit → System waits (Retry-After header) → Retries → All events eventually synced
- [ ] **Pass**: Rate limit handled transparently, no user-facing error

### Error Handling

**Sync failure after 3 retries**
- [ ] **Test**: (Mock) Network failure persists for 3 retry attempts
- [ ] **Expected**: "❌ Sync failed. [Retry]" badge shown with manual retry button
- [ ] **Pass**: Clear error state, retry option provided

**Disconnect Google Calendar**
- [ ] **Test**: Tap [Disconnect] in Settings → Confirm alert
- [ ] **Expected**: Refresh token deleted → Settings shows [Connect] button → Future events don't sync → Existing Google Calendar events remain
- [ ] **Pass**: Disconnection works, doesn't delete user's calendar data

---

## 12. Definition of Done

- [ ] GoogleCalendarSyncService.swift implemented (OAuth, sync, retry, token refresh)
- [ ] CalendarService.swift enhanced (integrate sync after create/update/delete)
- [ ] 5 new UI components created (connection view, status badges, retry button, settings)
- [ ] 3 existing views modified (SettingsView, EventDetailView, EventCardView)
- [ ] CalendarEvent model extended (googleCalendarEventId, syncedAt fields)
- [ ] User model extended (integrations.googleCalendar)
- [ ] OAuth flow functional (connect, disconnect, auto-refresh)
- [ ] One-way sync working (create, update, delete)
- [ ] Backfill existing events on first connection
- [ ] All acceptance gates pass (happy path + edge cases + error handling)
- [ ] Sync latency < 5 seconds (p95)
- [ ] Sync success rate >99%
- [ ] PR created targeting develop

---

## 13. Risks & Mitigations

**Risk 1: Google Calendar API rate limiting**
- **Impact**: Medium (sync delays during high event creation)
- **Mitigation**: Exponential backoff, respect Retry-After header, queue retries, transparent handling

**Risk 2: OAuth token management complexity**
- **Impact**: High (sync fails if tokens not refreshed)
- **Mitigation**: Use Google Sign-In SDK (handles refresh automatically), clear reconnect UI when tokens invalid

**Risk 3: Duplicate events in Google Calendar**
- **Impact**: Medium (poor UX if events duplicated on update)
- **Mitigation**: Store `googleCalendarEventId`, always UPDATE using event ID (never create duplicate)

**Risk 4: Firestore security - refresh tokens exposed**
- **Impact**: High (token compromise allows unauthorized calendar access)
- **Mitigation**: Firestore encrypts at rest, security rules (only owner can read/write), never send tokens to client

**Risk 5: Sync failures causing user confusion**
- **Impact**: Low (users expect events in Google Calendar)
- **Mitigation**: Clear sync status badges (✅/⏳/❌), retry button, "last synced" timestamp, reconnect prompts

---

## 14. Out of Scope (Deferred)

- [ ] Two-way sync (Google → Psst) → Too complex, conflict resolution required
- [ ] iCloud/Outlook calendar integrations → Google only for Phase 4
- [ ] Selective sync (some events synced, others not) → All events sync
- [ ] Calendar import/merge → One-way: Psst → Google only

---

**PRD Author**: Pam (Planning Agent)
**Date**: October 25, 2025
**Status**: Draft - Ready for Review
**Depends On**: PR #010A (Calendar Foundation) must be merged first
**Optional**: PR #010B (AI Scheduling) enhances experience but not required for sync
