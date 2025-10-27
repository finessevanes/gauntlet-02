# PRD: Calendar Foundation (Manual UI + CRUD)

**Feature**: Calendar Foundation - Visual Calendar with Manual Event Management

**Version**: 1.0

**Status**: Draft

**Agent**: Pam (Planning Agent)

**Target Release**: Phase 4 (Part 1 of 3)

**Dependencies**: PR #009 (Contacts - for client/prospect linking)

**Links**: [PR Brief](../ai-briefs.md#pr-010), [TODO](../todos/pr-010a-todo.md)

---

## 1. Summary

Build foundational calendar system with visual week view, manual event creation/editing, and Today's Schedule widget. Trainers can manually create Training/Call/Adhoc events linked to clients/prospects, view them in a timeline, and see today's schedule on the chat list. This establishes the calendar infrastructure that AI scheduling (010B) and Google Calendar sync (010C) will build upon.

---

## 2. Problem & Goals

**Problem:**
Trainers currently track client sessions in external calendars or paper notes. They need a visual calendar inside Psst to manage their training schedule alongside their client conversations.

**Why Now:**
PR #008 created `/calendar` collection for AI-scheduled events, but no UI to view/manage them. PR #009 provides client/prospect contacts needed for event linking. This PR makes the calendar visible and manually usable.

**Goals:**
- [x] G1 — Trainers can manually create events (Training/Call/Adhoc) with client/prospect linking
- [x] G2 — Trainers can view all events in visual week timeline calendar
- [x] G3 — Trainers see today's upcoming sessions on chat list (widget)
- [x] G4 — Trainers can edit/delete events through UI
- [x] G5 - Trainers see cal as the 'Home Page' of the app

---

## 3. Non-Goals / Out of Scope

- [ ] **NOT doing** AI natural language scheduling → Deferred to PR #010B
- [ ] **NOT doing** Google Calendar sync → Deferred to PR #010C
- [ ] **NOT doing** Conflict detection/suggestions → Deferred to PR #010B
- [ ] **NOT doing** Recurring events → Deferred to Phase 5
- [ ] **NOT doing** Client-side calendar access → Trainer-only feature

---

## 4. Success Metrics

**User-visible:**
- Manual event creation: ≤ 5 taps from Cal tab to saved event
- Calendar view load time: < 1 second (week view with 50 events)
- Widget load time: < 200ms

**System:**
- App load time: < 2-3 seconds (no impact from calendar)
- Smooth 60fps scrolling in week view
- No UI blocking during Firestore operations

**Quality:**
- 0 blocking bugs in event CRUD
- All acceptance gates pass
- Crash-free rate >99%

---

## 5. Users & Stories

**User: Alex (Trainer)**

1. **As a trainer,** I want to create events manually (session with Sam, doctor appointment) **so that** I can track my full schedule in one place.

2. **As a trainer,** I want to see all my events in a week view **so that** I can visualize my schedule at a glance.

3. **As a trainer,** I want to see today's upcoming sessions on my chat list **so that** I know who I'm training today without opening calendar.

4. **As a trainer,** I want to edit or delete events **so that** I can adjust my schedule when plans change.

---

## 5b. Affected Existing Code (Brownfield)

### Modified Files

**`CalendarEvent.swift`** (EXISTING from PR #008 - EXTEND):
- Current: id, trainerId, clientId, title, startTime, endTime, createdBy
- **ADD**: eventType, prospectId?, location?, notes?, status, createdAt

**`MainTabView.swift`** (EXISTING - ADD 4TH TAB):
- Add Cal tab to bottom navigation
- Badge showing today's event count

**`ChatListView.swift`** (EXISTING - ADD WIDGET):
- Insert TodaysScheduleWidget at top of chat list
- Conditionally shown based on settings

**Firestore `/calendar/{eventId}`** (EXISTING - EXTEND SCHEMA):
- Add new fields: eventType, prospectId, location, notes, status, createdAt

**`firestore.rules`** (EXISTING - ADD RULES):
- Add read/write rules for `/calendar` collection
- Validate trainerId matches auth.uid

---

## 6. Experience Specification (UX)

### Entry Points

1. **Cal Tab** (Primary) - 1st tab in MainTabView, opens CalendarView
2. **Today's Schedule Widget** - Tap widget on ChatListView → Opens CalendarView
3. **Floating "+" button** - In CalendarView → Opens event creation sheet

### Visual Behavior

**Event Type Visual Differentiation:**
- **Training**: 🏋️ Blue (#007AFF), "Session: [Client]"
- **Call**: 📞 Green (#34C759), "Call: [Client]"
- **Adhoc**: 📅 Gray (#8E8E93), custom title

**Week Timeline:**
- Horizontal scrolling week grid (Sun-Sat)
- Hourly rows (6am-10pm default)
- Current time indicator (red line)
- Event cards in time slots (colored by type)

**Today's Schedule Widget:**
- Shows next 3 upcoming events
- Format: `2:00 PM 🏋️ Session: Sam`
- Tap event → Opens EventDetailView
- Auto-collapses when no events today

### States

**Loading**: Skeleton grid with shimmer
**Empty**: "No events this week. Create your first event." + illustration
**Populated**: Event cards in timeline
**Error**: "Couldn't load calendar. [Retry]"

---

## 7. Functional Requirements

### Manual Event Creation

**MUST:**
- **REQ-1**: Event creation form with fields:
  - Event Type (segmented: Training | Call | Adhoc)
  - Client/Prospect picker (shown for Training/Call, hidden for Adhoc)
  - Title (auto-filled for Training/Call, manual for Adhoc)
  - Date, Start Time, Duration (30min/1hr/1.5hr/2hr)
  - Location, Notes (optional)
  - [Gate] Fill all required fields → Tap Save → Event created in Firestore → Appears in CalendarView

- **REQ-2**: Validation:
  - Training/Call requires client or prospect selection
  - Adhoc requires custom title
  - startTime < endTime
  - No past dates allowed
  - [Gate] Try to save invalid event → Save button disabled + inline error

### Calendar Viewing

**MUST:**
- **REQ-3**: Week view with scrollable timeline
  - [Gate] Open CalendarView → See current week with all events positioned correctly

- **REQ-4**: Real-time event updates via Firestore listener
  - [Gate] Create event → Immediately appears in CalendarView without refresh

- **REQ-5**: Today's Schedule widget on ChatListView
  - [Gate] 3 events today → Widget shows all 3 → Tap event → EventDetailView opens

### Event Editing & Deletion

**MUST:**
- **REQ-6**: EventDetailView with edit/delete actions
  - Tap event → Detail sheet opens → Shows all event info
  - [Edit] button → Opens edit form (pre-filled)
  - [Delete] button → Confirmation alert → Deletes from Firestore
  - [Gate] Edit event time → Save → CalendarView updates immediately

---

## 8. Data Model

### Firestore Schema Extension

**`/calendar/{eventId}` (EXTEND EXISTING)**

```swift
{
  // Existing fields (keep)
  id: String,
  trainerId: String,
  clientId: String?,  // Make optional
  title: String,
  startTime: Timestamp,
  endTime: Timestamp,
  createdBy: "ai" | "trainer",

  // NEW FIELDS
  eventType: "training" | "call" | "adhoc",  // Required
  prospectId: String?,  // Optional (alternative to clientId)
  location: String?,  // Optional
  notes: String?,  // Optional
  status: "scheduled" | "completed" | "cancelled",  // Required
  createdAt: Timestamp  // Required
}
```

**Indexes:**
- Composite: `trainerId ASC, startTime ASC`

**Validation:**
- `trainerId` must match auth.uid
- `startTime < endTime`
- Training/Call: must have `clientId` XOR `prospectId`
- Adhoc: `clientId` and `prospectId` must be null

---

### Swift Model Extension

**`CalendarEvent.swift` (EXTEND)**

```swift
enum EventType: String, Codable {
    case training, call, adhoc
}

enum EventStatus: String, Codable {
    case scheduled, completed, cancelled
}

struct CalendarEvent: Identifiable, Codable {
    let id: String
    let trainerId: String
    let clientId: String?
    let prospectId: String?
    let title: String
    let startTime: Date
    let endTime: Date
    let createdBy: String

    // NEW
    let eventType: EventType
    let location: String?
    let notes: String?
    let status: EventStatus
    let createdAt: Date

    var eventTypeIcon: String {
        switch eventType {
        case .training: return "🏋️"
        case .call: return "📞"
        case .adhoc: return "📅"
        }
    }

    var eventTypeColor: Color {
        switch eventType {
        case .training: return .blue
        case .call: return .green
        case .adhoc: return .gray
        }
    }
}
```

---

## 9. API / Service Contracts

### New Service: `CalendarService.swift`

```swift
class CalendarService: ObservableObject {

    /// Create calendar event
    func createEvent(
        trainerId: String,
        eventType: EventType,
        title: String,
        clientId: String? = nil,
        prospectId: String? = nil,
        startTime: Date,
        endTime: Date,
        location: String? = nil,
        notes: String? = nil,
        createdBy: String = "trainer"
    ) async throws -> CalendarEvent

    /// Get events for date range
    func getEvents(
        trainerId: String,
        startDate: Date,
        endDate: Date
    ) async throws -> [CalendarEvent]

    /// Observe events real-time
    func observeEvents(
        trainerId: String,
        startDate: Date,
        endDate: Date,
        completion: @escaping ([CalendarEvent]) -> Void
    ) -> ListenerRegistration

    /// Update event
    func updateEvent(
        eventId: String,
        updates: [String: Any]
    ) async throws

    /// Delete event
    func deleteEvent(eventId: String) async throws

    /// Mark event completed
    func markEventCompleted(eventId: String) async throws

    enum CalendarError: Error {
        case notAuthenticated
        case notFound
        case invalidEventType
        case missingClient
        case invalidTimeRange
    }
}
```

---

## 10. UI Components to Create

### NEW VIEWS (10 files)

1. **`CalendarView.swift`** - Main calendar with week timeline
2. **`WeekTimelineView.swift`** - Week grid component
3. **`EventCardView.swift`** - Event card in timeline
4. **`TodaysScheduleWidget.swift`** - Widget for ChatListView
5. **`EventDetailView.swift`** - Event detail sheet
6. **`EventCreationSheet.swift`** - Manual event creation form
7. **`EventEditSheet.swift`** - Edit existing event
8. **`ClientPickerView.swift`** - Client/prospect picker
9. **`CurrentTimeIndicatorView.swift`** - Red line in timeline
10. **`CalendarEmptyStateView.swift`** - Empty state

### MODIFIED VIEWS (2 files)

1. **`MainTabView.swift`** - Add Cal tab
2. **`ChatListView.swift`** - Add TodaysScheduleWidget

---

## 11. Testing Plan

### Happy Path

**Scenario: Manual event creation**
- [ ] Tap Cal tab → Tap + → Select Training → Pick client Sam → Set tomorrow 6pm, 1hr → Save
- [ ] **Gate**: Event created in Firestore with correct fields
- [ ] **Gate**: Event appears in CalendarView (blue card)
- [ ] **Pass**: Complete flow works, event visible

### Edge Cases

**Edge Case 1: Invalid event (missing client)**
- [ ] **Test**: Create Training event without selecting client → Tap Save
- [ ] **Expected**: Save disabled + error "Training events require a client"
- [ ] **Pass**: Validation prevents invalid event

**Edge Case 2: Past date**
- [ ] **Test**: Try to create event yesterday
- [ ] **Expected**: Date picker blocks past dates OR save shows error
- [ ] **Pass**: Cannot create past events

### Error Handling

**Offline mode**
- [ ] **Test**: Enable airplane mode → Create event → Disable airplane mode
- [ ] **Expected**: Event saves to Firestore offline → Syncs when online
- [ ] **Pass**: Offline creation works, no data loss

---

## 12. Definition of Done

- [ ] CalendarService.swift implemented with CRUD methods
- [ ] 10 new SwiftUI views created
- [ ] 2 existing views modified (MainTabView, ChatListView)
- [ ] CalendarEvent model extended
- [ ] Firestore schema updated
- [ ] Security rules for /calendar collection
- [ ] All acceptance gates pass
- [ ] Manual testing completed (happy path, edge cases, error handling)
- [ ] Performance: Calendar loads < 1s, widget < 200ms
- [ ] PR created targeting develop

---

## 13. Risks & Mitigations

**Risk 1: Firestore query performance (100+ events)**
- **Mitigation**: Composite index, query only visible date range, LazyVStack rendering

**Risk 2: Breaking existing /calendar collection (PR #008)**
- **Mitigation**: Make new fields optional, default to reasonable values, test old events

**Risk 3: Today's widget clutters ChatListView**
- **Mitigation**: Auto-collapse when no events, max 3 events shown, toggle in settings

---

## 14. Out of Scope (Deferred)

- [ ] AI natural language scheduling → **PR #010B**
- [ ] Conflict detection → **PR #010B**
- [ ] Google Calendar sync → **PR #010C**
- [ ] Event filters, recurring events → Phase 5

---

**PRD Author**: Pam (Planning Agent)
**Date**: October 25, 2025
**Status**: Draft - Ready for Review
**Next**: PR #010B (AI Scheduling) builds on this foundation
