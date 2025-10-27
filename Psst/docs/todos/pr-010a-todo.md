# PR-010A TODO — Calendar Foundation (Manual UI + CRUD)

**Branch**: `feat/pr-010a-calendar-foundation`
**Source PRD**: `Psst/docs/prds/pr-010a-prd.md`
**Owner (Agent)**: Caleb

---

## 0. Clarifying Questions & Assumptions

**Assumptions:**
- Cal tab becomes 1st tab (home page) in MainTabView
- Today's Schedule widget shows max 3 upcoming events
- Week view displays 6am-10pm by default (16 hours)
- Events can be created for past dates (for record-keeping), but validation should warn user
- Event deletion is soft delete (status = cancelled) to preserve history

---

## 1. Setup

- [ ] Create branch `feat/pr-010a-calendar-foundation` from develop
- [ ] Read PRD thoroughly (`Psst/docs/prds/pr-010a-prd.md`)
- [ ] Read `Psst/agents/shared-standards.md` for patterns
- [ ] Confirm Xcode builds successfully on Vanes simulator

---

## 2. Data Model & Firestore Schema

### Extend CalendarEvent Model

- [ ] Open `Psst/Psst/Models/CalendarEvent.swift` (existing file from PR #008)
  - **Test Gate**: File exists and compiles

- [ ] Add EventType enum: `training`, `call`, `adhoc`
  - **Test Gate**: EventType enum compiles with 3 cases

- [ ] Add EventStatus enum: `scheduled`, `completed`, `cancelled`
  - **Test Gate**: EventStatus enum compiles with 3 cases

- [ ] Extend CalendarEvent struct with new fields:
  - `eventType: EventType`
  - `prospectId: String?`
  - `location: String?`
  - `notes: String?`
  - `status: EventStatus`
  - `createdAt: Date`
  - Make `clientId` optional (was required in PR #008)
  - **Test Gate**: Compiles without errors, old CalendarEvent init still works (backward compatible)

- [ ] Add computed properties:
  - `eventTypeIcon: String` (returns 🏋️/📞/📅)
  - `eventTypeColor: Color` (returns blue/green/gray)
  - `displayTitle: String` (formats title based on event type)
  - **Test Gate**: SwiftUI Preview shows correct icons/colors for each event type

### Update Firestore Security Rules

- [ ] Open `firestore.rules`
  - **Test Gate**: File exists

- [ ] Add read/write rules for `/calendar/{eventId}` collection:
  ```
  match /calendar/{eventId} {
    allow read: if request.auth != null &&
                request.auth.uid == resource.data.trainerId;
    allow create: if request.auth != null &&
                  request.auth.uid == request.resource.data.trainerId;
    allow update, delete: if request.auth != null &&
                          request.auth.uid == resource.data.trainerId;
  }
  ```
  - **Test Gate**: Rules validate in Firebase console (no syntax errors)

- [ ] Add validation for event fields in rules:
  - `startTime < endTime`
  - `eventType in ['training', 'call', 'adhoc']`
  - Training/Call: `clientId != null || prospectId != null`
  - Adhoc: `clientId == null && prospectId == null`
  - **Test Gate**: Rules deployed successfully: `firebase deploy --only firestore:rules`

---

## 3. Service Layer - CalendarService

### Create CalendarService.swift

- [ ] Create new file: `Psst/Psst/Services/CalendarService.swift`
  - **Test Gate**: File created, imports Foundation and FirebaseFirestore

- [ ] Implement `createEvent()` method:
  - Parameters: trainerId, eventType, title, clientId?, prospectId?, startTime, endTime, location?, notes?, createdBy
  - Returns: CalendarEvent
  - Throws: CalendarError
  - Validation: startTime < endTime, Training/Call requires client/prospect
  - Write to Firestore `/calendar/{eventId}`
  - **Test Gate**: Create test event → Appears in Firestore console

- [ ] Implement `getEvents()` method:
  - Parameters: trainerId, startDate, endDate
  - Returns: [CalendarEvent] sorted by startTime
  - Query: `trainerId == uid AND startTime >= startDate AND startTime <= endDate`
  - **Test Gate**: Query returns correct events for date range

- [ ] Implement `observeEvents()` method (real-time listener):
  - Parameters: trainerId, startDate, endDate, completion closure
  - Returns: ListenerRegistration
  - Uses Firestore snapshot listener
  - **Test Gate**: Create event → Listener fires with updated array

- [ ] Implement `updateEvent()` method:
  - Parameters: eventId, updates dictionary
  - Updates specific fields in Firestore
  - **Test Gate**: Update event title → Firestore updated

- [ ] Implement `deleteEvent()` method:
  - Parameters: eventId
  - Sets `status = cancelled` (soft delete)
  - **Test Gate**: Delete event → Status changed to cancelled in Firestore

- [ ] Implement `markEventCompleted()` method:
  - Parameters: eventId
  - Sets `status = completed`
  - **Test Gate**: Mark event completed → Status updated

- [ ] Add CalendarError enum:
  - Cases: notAuthenticated, notFound, invalidEventType, missingClient, invalidTimeRange
  - LocalizedError descriptions
  - **Test Gate**: Error enum conforms to LocalizedError

---

## 4. UI Components - Calendar Views

### CalendarView (Main Calendar)

- [ ] Create `Psst/Psst/Views/Calendar/CalendarView.swift`
  - **Test Gate**: File created with basic SwiftUI View

- [ ] Add @StateObject for CalendarViewModel
  - **Test Gate**: ViewModel injected and initialized

- [ ] Implement week view with WeekTimelineView component
  - Shows 7 days (Sun-Sat)
  - Scrollable horizontally
  - **Test Gate**: SwiftUI Preview shows 7-day grid

- [ ] Add floating "+" button (bottom-right)
  - Opens EventCreationSheet on tap
  - **Test Gate**: Tap + → Sheet appears

- [ ] Add empty state (CalendarEmptyStateView)
  - Shows when no events in current week
  - Message: "No events this week. Create your first event."
  - **Test Gate**: Empty calendar shows empty state

- [ ] Add loading state (skeleton grid with shimmer)
  - **Test Gate**: Loading state visible before events load

### WeekTimelineView Component

- [ ] Create `Psst/Psst/Views/Calendar/WeekTimelineView.swift`
  - **Test Gate**: File created

- [ ] Implement 7-column grid (Sun-Sat):
  - Day headers with day name + date
  - **Test Gate**: Grid shows 7 columns with correct labels

- [ ] Implement hourly rows (6am-10pm = 16 hours):
  - Time labels on left
  - Grid lines for each hour
  - **Test Gate**: 16 hour rows visible

- [ ] Render EventCardView in correct time slots:
  - Calculate position based on startTime
  - Calculate height based on duration
  - **Test Gate**: Event at 2pm shows in correct row

- [ ] Add CurrentTimeIndicatorView (red line):
  - Positioned at current time
  - Updates every minute
  - **Test Gate**: Red line visible at current time

### EventCardView Component

- [ ] Create `Psst/Psst/Views/Calendar/EventCardView.swift`
  - **Test Gate**: File created

- [ ] Implement colored card based on eventType:
  - Training: Blue background (#007AFF)
  - Call: Green background (#34C759)
  - Adhoc: Gray background (#8E8E93)
  - **Test Gate**: Preview shows 3 cards with different colors

- [ ] Add event type icon (🏋️/📞/📅)
  - **Test Gate**: Icons display correctly

- [ ] Add title (e.g., "Session: Sam" or "Doctor Appointment")
  - **Test Gate**: Title formatted correctly for each type

- [ ] Add start time (e.g., "2:00 PM")
  - **Test Gate**: Time formatted correctly

- [ ] Add tap gesture → Opens EventDetailView sheet
  - **Test Gate**: Tap card → Detail sheet opens

### TodaysScheduleWidget (ChatListView Widget)

- [ ] Create `Psst/Psst/Views/Calendar/TodaysScheduleWidget.swift`
  - **Test Gate**: File created

- [ ] Fetch next 3 upcoming events for today
  - Query: `startTime >= now AND startTime < endOfDay`, limit 3, order by startTime
  - **Test Gate**: Query returns correct events

- [ ] Implement compact format:
  - Row format: `2:00 PM 🏋️ Session: Sam`
  - Max 3 events shown
  - **Test Gate**: Widget shows max 3 events in compact format

- [ ] Add tap gesture → Opens CalendarView
  - **Test Gate**: Tap "See All" → CalendarView opens

- [ ] Auto-collapse when no events today
  - **Test Gate**: 0 events → Widget not visible

- [ ] Real-time updates (remove events as they pass)
  - Use Firestore listener
  - **Test Gate**: Event at 2pm → 3pm passes → Event removed from widget

### EventDetailView (Detail Sheet)

- [ ] Create `Psst/Psst/Views/Calendar/EventDetailView.swift`
  - **Test Gate**: File created

- [ ] Display event details:
  - Event type icon + color header
  - Title
  - Client name (if applicable)
  - Date, start time, end time, duration
  - Location, notes
  - **Test Gate**: All fields display correctly

- [ ] Add [Edit] button → Opens EventEditSheet
  - **Test Gate**: Tap Edit → Edit sheet opens with pre-filled data

- [ ] Add [Delete] button → Shows confirmation alert
  - Confirmation: "Are you sure you want to delete this event?"
  - On confirm → Call CalendarService.deleteEvent()
  - **Test Gate**: Delete event → Confirmation alert → Event deleted from Firestore

- [ ] Add [Close] button to dismiss sheet
  - **Test Gate**: Tap Close → Sheet dismisses

### EventCreationSheet (Manual Event Creation)

- [ ] Create `Psst/Psst/Views/Calendar/EventCreationSheet.swift`
  - **Test Gate**: File created

- [ ] Add event type segmented control:
  - Options: Training 🏋️ | Call 📞 | Adhoc 📅
  - **Test Gate**: Segmented control switches between 3 types

- [ ] Add ClientPickerView (conditionally shown):
  - Visible for Training and Call
  - Hidden for Adhoc
  - **Test Gate**: Training selected → Picker visible, Adhoc selected → Picker hidden

- [ ] Add title text field:
  - Auto-filled for Training/Call: "Session with [Client]" or "Call with [Client]"
  - Manual entry required for Adhoc
  - **Test Gate**: Select client "Sam" for Training → Title auto-fills "Session with Sam"

- [ ] Add date picker (defaults to today)
  - **Test Gate**: Picker defaults to today's date

- [ ] Add start time picker (defaults to next hour)
  - **Test Gate**: Picker defaults to next round hour

- [ ] Add duration picker:
  - Options: 30min, 1hr, 1.5hr, 2hr
  - Calculates endTime automatically
  - **Test Gate**: Select 1hr duration → endTime = startTime + 1hr

- [ ] Add location text field (optional)
  - **Test Gate**: Field accepts text input

- [ ] Add notes text area (optional)
  - **Test Gate**: Text area accepts multi-line input

- [ ] Add validation:
  - Training/Call requires client selection
  - Adhoc requires custom title
  - Save button disabled until valid
  - **Test Gate**: Training without client → Save disabled + error shown

- [ ] Add [Cancel] and [Save] buttons:
  - Cancel → Dismiss sheet
  - Save → Call CalendarService.createEvent() → Dismiss sheet
  - **Test Gate**: Save → Event created in Firestore → Sheet dismisses

### EventEditSheet (Edit Existing Event)

- [ ] Create `Psst/Psst/Views/Calendar/EventEditSheet.swift`
  - **Test Gate**: File created

- [ ] Pre-fill all fields from existing event:
  - Event type, client, title, date, time, duration, location, notes
  - **Test Gate**: Edit sheet opens with all fields pre-filled correctly

- [ ] Allow editing all fields except event type and client (locked after creation)
  - **Test Gate**: Event type and client pickers disabled

- [ ] Add [Cancel] and [Save] buttons:
  - Save → Call CalendarService.updateEvent() → Dismiss sheet
  - **Test Gate**: Edit time → Save → Event updated in Firestore

### ClientPickerView (Client/Prospect Selection)

- [ ] Create `Psst/Psst/Views/Calendar/ClientPickerView.swift`
  - **Test Gate**: File created

- [ ] Fetch clients from ContactService:
  - Query `/contacts/{trainerId}/clients`
  - **Test Gate**: Clients list populated from Firestore

- [ ] Fetch prospects from ContactService:
  - Query `/contacts/{trainerId}/prospects`
  - **Test Gate**: Prospects list populated from Firestore

- [ ] Display two sections: "My Clients" and "Prospects"
  - **Test Gate**: Two sections visible with correct headers

- [ ] Add search bar for filtering by name
  - **Test Gate**: Type "Sam" → Filters to clients/prospects named Sam

- [ ] Show client avatar + name
  - **Test Gate**: Avatar and name display correctly

- [ ] Single selection (radio button style)
  - **Test Gate**: Select client → Updates selection state

- [ ] Empty state: "No clients yet. Add clients in Contacts."
  - **Test Gate**: 0 clients → Empty state shown

### CurrentTimeIndicatorView Component

- [ ] Create `Psst/Psst/Views/Calendar/CurrentTimeIndicatorView.swift`
  - **Test Gate**: File created

- [ ] Implement red horizontal line
  - Color: Red (#FF0000)
  - Width: Full timeline width
  - Height: 2pt
  - **Test Gate**: Red line visible in preview

- [ ] Position at current time in timeline
  - Calculate Y offset based on hour (e.g., 2:30pm → 40% down from 2pm row)
  - **Test Gate**: Line positioned correctly at current time

- [ ] Update position every minute
  - Use Timer.publish(every: 60, on: .main, in: .common)
  - **Test Gate**: Line moves down after 1 minute

### CalendarEmptyStateView Component

- [ ] Create `Psst/Psst/Views/Calendar/CalendarEmptyStateView.swift`
  - **Test Gate**: File created

- [ ] Add calendar icon illustration
  - Use SF Symbol: `calendar`
  - **Test Gate**: Icon visible

- [ ] Add message: "No events this week"
  - **Test Gate**: Message displays

- [ ] Add suggestion: "Create your first event."
  - **Test Gate**: Suggestion displays

- [ ] Add [Create Event] button → Opens EventCreationSheet
  - **Test Gate**: Tap button → Creation sheet opens

---

## 5. ViewModel - CalendarViewModel

- [ ] Create `Psst/Psst/ViewModels/CalendarViewModel.swift`
  - **Test Gate**: File created

- [ ] Add @Published properties:
  - `events: [CalendarEvent] = []`
  - `isLoading: Bool = false`
  - `currentWeekStart: Date` (start of current week)
  - `selectedDate: Date = Date()` (for highlighting today)
  - **Test Gate**: Properties compile and initialize correctly

- [ ] Inject CalendarService dependency
  - **Test Gate**: CalendarService injected via init or @EnvironmentObject

- [ ] Implement `loadEvents(for weekStart: Date)` method:
  - Calculate weekStart and weekEnd (7 days)
  - Call CalendarService.observeEvents()
  - Update @Published events array
  - **Test Gate**: Load events → events array populated

- [ ] Implement `createEvent()` method:
  - Call CalendarService.createEvent()
  - Handle success/error
  - **Test Gate**: Create event → Event added to events array

- [ ] Implement `updateEvent()` method:
  - Call CalendarService.updateEvent()
  - **Test Gate**: Update event → events array updated

- [ ] Implement `deleteEvent()` method:
  - Call CalendarService.deleteEvent()
  - **Test Gate**: Delete event → Event removed from events array

- [ ] Implement `nextWeek()` and `previousWeek()` methods:
  - Adjust currentWeekStart by ±7 days
  - Reload events for new week
  - **Test Gate**: Swipe week view → Next week's events load

- [ ] Implement `getTodaysEvents()` method:
  - Filter events where startTime is today and >= now
  - Sort by startTime
  - Limit to 3 events
  - **Test Gate**: Method returns correct events for Today's Schedule widget

---

## 6. Integration - MainTabView (Make Cal 1st Tab)

- [ ] Open `Psst/Psst/Views/MainTabView.swift`
  - **Test Gate**: File exists

- [ ] Reorder tabs to make CalendarView 1st tab:
  ```swift
  TabView(selection: $selectedTab) {
      // FIRST TAB - Calendar (Home Page)
      CalendarView()
          .tabItem {
              Label("Cal", systemImage: "calendar")
          }
          .tag(0)

      // SECOND TAB - Chats
      ChatListView()
          .tabItem {
              Label("Chats", systemImage: "message")
          }
          .tag(1)

      // THIRD TAB - Profile (or Settings)
      // ... existing tabs
  }
  ```
  - **Test Gate**: App launches → Cal tab visible first

- [ ] Add badge to Cal tab showing today's event count:
  - Use `.badge(todaysEventCount)`
  - **Test Gate**: 3 events today → Badge shows "3"

---

## 7. Integration - ChatListView (Add Widget)

- [ ] Open `Psst/Psst/Views/ChatList/ChatListView.swift`
  - **Test Gate**: File exists

- [ ] Add TodaysScheduleWidget at top of VStack:
  ```swift
  VStack(spacing: 0) {
      // NEW WIDGET
      TodaysScheduleWidget()
          .padding(.horizontal)
          .padding(.top, 8)

      // Existing chat list
      ScrollView {
          LazyVStack {
              ForEach(chats) { chat in
                  ChatRowView(chat: chat)
              }
          }
      }
  }
  ```
  - **Test Gate**: ChatListView shows widget above chat list

- [ ] Widget should auto-collapse when no events today:
  - Conditional rendering: `if viewModel.hasTodaysEvents { TodaysScheduleWidget() }`
  - **Test Gate**: 0 events → Widget not visible

---

## 8. User-Centric Testing

### Happy Path: Manual Event Creation

- [ ] Open app → Cal tab is first screen
  - **Test Gate**: Cal tab visible on launch

- [ ] Tap + button → Event creation sheet opens
  - **Test Gate**: Sheet opens

- [ ] Select Training → Pick client "Sam" → Set tomorrow 6pm, 1hr → Tap Save
  - **Test Gate**: Event created in Firestore

- [ ] Event appears in CalendarView as blue card with 🏋️ icon
  - **Test Gate**: Event visible in calendar at correct time slot

- [ ] Event appears in Today's Schedule widget (if tomorrow = today)
  - **Test Gate**: Widget shows event

- [ ] **Pass Criteria**: Complete flow works without errors, event visible in all places

### Edge Case 1: Invalid Event (Missing Client)

- [ ] Create Training event without selecting client
  - **Test Gate**: Save button disabled

- [ ] Try to save → Inline error: "Training events require a client"
  - **Test Gate**: Error message shown, cannot proceed

- [ ] Select client → Save button enabled → Save succeeds
  - **Test Gate**: Validation prevents invalid event, allows valid event

### Edge Case 2: Edit Event

- [ ] Tap event in calendar → EventDetailView opens
  - **Test Gate**: Detail view shows correct event data

- [ ] Tap [Edit] → EventEditSheet opens with pre-filled data
  - **Test Gate**: All fields pre-filled correctly

- [ ] Change time from 6pm to 7pm → Save
  - **Test Gate**: Event time updated in Firestore

- [ ] Calendar updates to show new time
  - **Test Gate**: Event moved to 7pm slot in calendar

### Edge Case 3: Delete Event

- [ ] Tap event → Tap [Delete]
  - **Test Gate**: Confirmation alert appears

- [ ] Confirm deletion
  - **Test Gate**: Event status changed to "cancelled" in Firestore

- [ ] Event removed from CalendarView
  - **Test Gate**: Event no longer visible (or grayed out if showing cancelled events)

### Error Handling: Offline Mode

- [ ] Enable airplane mode
  - **Test Gate**: Network disconnected

- [ ] Create event → Tap Save
  - **Test Gate**: Event saves to Firestore (offline persistence)

- [ ] Disable airplane mode
  - **Test Gate**: Event syncs to Firestore when online

- [ ] **Pass Criteria**: Offline event creation works, no data loss

### Final Checks

- [ ] No console errors during all test scenarios
  - **Test Gate**: Clean console output

- [ ] Calendar loads in < 1 second (with 50 events)
  - **Test Gate**: Measured with Xcode Instruments

- [ ] Today's Schedule widget loads in < 200ms
  - **Test Gate**: Measured with Xcode Instruments

- [ ] Smooth 60fps scrolling in week view
  - **Test Gate**: Visual inspection, no jank

---

## 9. Performance

- [ ] Calendar view load time < 1 second
  - Test: Open CalendarView with 50 events → Measure time to interactive
  - **Test Gate**: Loads in < 1 second

- [ ] Use LazyVStack for efficient rendering
  - **Test Gate**: Scroll performance remains smooth with 100+ events

- [ ] Query only visible date range (current week ±1 week)
  - Don't load all events, only ~14 days worth
  - **Test Gate**: Query limits results to visible range

- [ ] Real-time listener efficient (single connection)
  - Don't create new listener on each render
  - **Test Gate**: Single Firestore listener active

---

## 10. Documentation & PR

- [ ] Add inline code comments for complex logic:
  - Time slot positioning calculations
  - Date range queries
  - Event validation rules
  - **Test Gate**: Code comments explain non-obvious logic

- [ ] Update `Psst/docs/architecture.md`:
  - Add CalendarService to Services section
  - Add Calendar views to Views section
  - Document /calendar Firestore collection schema
  - **Test Gate**: Architecture doc updated with calendar details

- [ ] Create PR description:
  ```markdown
  # PR #010A: Calendar Foundation (Manual UI + CRUD)

  ## Summary
  Implements foundational calendar system with visual week view, manual event creation/editing, and Today's Schedule widget. Cal tab is now the home page (1st tab).

  ## Changes
  - Extended CalendarEvent model with eventType, status, location, notes
  - Created CalendarService for event CRUD operations
  - Built 10 new calendar views (CalendarView, EventCreationSheet, etc.)
  - Made Cal tab 1st tab in MainTabView (home page)
  - Added Today's Schedule widget to ChatListView
  - Updated Firestore security rules for /calendar collection

  ## Testing
  - [x] Manual event creation works (Training/Call/Adhoc)
  - [x] Calendar view displays events correctly
  - [x] Today's Schedule widget shows next 3 events
  - [x] Event editing and deletion work
  - [x] Offline event creation supported
  - [x] Performance: Calendar loads < 1s, widget < 200ms

  ## Screenshots
  [Attach screenshots of CalendarView, EventCreationSheet, Today's widget]

  ## Related
  - PRD: `Psst/docs/prds/pr-010a-prd.md`
  - TODO: `Psst/docs/todos/pr-010a-todo.md`
  - Next: PR #010B (AI Scheduling) builds on this foundation
  ```
  - **Test Gate**: PR description complete with checklist

- [ ] Verify with user before creating PR
  - **Test Gate**: User confirms PR is ready

- [ ] Open PR targeting `develop` branch
  - **Test Gate**: PR created, CI passes

---

## Notes

- Break tasks into <30 min chunks ✅ (already done in this TODO)
- Complete tasks sequentially (data model → service → UI → integration)
- Check off after completion
- Document blockers immediately
- Reference `Psst/agents/shared-standards.md` for code patterns

**Estimated Total Time**: ~12-16 hours (can be done in 2-3 work sessions)

---

**TODO Author**: Pam (Planning Agent)
**Date**: October 25, 2025
**Status**: Ready for Caleb
**Next**: Run `/caleb pr-010a` to start implementation
