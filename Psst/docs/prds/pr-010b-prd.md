# PRD: AI Scheduling + Conflict Detection

**Feature**: AI Natural Language Scheduling with Smart Conflict Detection

**Version**: 1.0

**Status**: Draft

**Agent**: Pam (Planning Agent)

**Target Release**: Phase 4 (Part 2 of 3)

**Dependencies**:
- PR #010A (Calendar Foundation - REQUIRED)
- PR #009 (Contacts - for client lookup)
- PR #008 (AI Function Calling - `scheduleCall()` foundation)

**Links**: [PR Brief](../ai-briefs.md#pr-010), [TODO](../todos/pr-010b-todo.md)

---

## 1. Summary

Add AI natural language scheduling on top of the calendar foundation from PR #010A. Trainers can say "schedule a session with Sam tomorrow at 6pm" and AI auto-detects event type (Training/Call/Adhoc), validates client exists via ContactService, detects scheduling conflicts, suggests alternative times, and creates the event. Also handles rescheduling ("move Sam to 7pm") and cancellation ("cancel Sam's session").

---

## 2. Problem & Goals

**Problem:**
Manual event creation (from 010A) requires multiple taps and form fields. Trainers want to schedule quickly using natural language while messaging clients. The existing `scheduleCall()` function from PR #008 is basic - it doesn't detect event types, validate clients, or check for conflicts.

**Why Now:**
PR #010A provides the calendar foundation. PR #009 provides ContactService for client lookup. PR #008 provides basic AI function calling. This PR connects them with intelligent scheduling logic.

**Goals:**
- [x] G1 — Trainers can schedule events using natural language ("schedule Sam tomorrow at 6pm")
- [x] G2 — AI auto-detects event type from keywords (session→Training, call→Call, appointment→Adhoc)
- [x] G3 — AI validates client exists and auto-creates prospect if not found
- [x] G4 — AI detects scheduling conflicts and suggests alternative times

---

## 3. Non-Goals / Out of Scope

- [ ] **NOT doing** Google Calendar sync → Deferred to PR #010C
- [ ] **NOT doing** YOLO mode (auto-confirm without user approval) → Deferred to PR #013
- [ ] **NOT doing** Recurring event detection → Phase 5
- [ ] **NOT doing** Multi-client scheduling ("schedule Sam and John") → Phase 5

---

## 4. Success Metrics

**User-visible:**
- Time to schedule via AI: < 10 seconds (command to confirmation)
- Event type detection accuracy: >95% (correct type from keywords)
- Conflict detection time: < 500ms

**System:**
- AI response time: < 3 seconds (with conflict check)
- Client name resolution accuracy: >90%

**Quality:**
- 0 false negatives in conflict detection
- All acceptance gates pass
- Crash-free rate >99%

---

## 5. Users & Stories

**User: Alex (Trainer)**

1. **As a trainer,** I want to schedule sessions by saying "schedule Sam tomorrow at 6pm" **so that** I can quickly book without opening forms.

2. **As a trainer,** I want AI to detect event type automatically **so that** I don't have to specify "Training" vs "Call" every time.

3. **As a trainer,** I want AI to warn me when I'm double-booking **so that** I can avoid scheduling conflicts.

4. **As a trainer,** I want to reschedule by saying "move Sam to 7pm" **so that** I can adjust plans quickly.

---

## 5b. Affected Existing Code (Brownfield)

### Modified Files

**`AIService.swift`** (EXISTING - ENHANCE):
- Current: `chatWithAI()`, `executeFunctionCall()` from PR #006-008
- **ADD**: `detectEventType()` method
- **ENHANCE**: `scheduleCall()` function with event type detection, client validation, conflict checking

**`ContactService.swift`** (EXISTING from PR #009 - ADD METHODS):
- **ADD**: `findContactByName(_ name: String)` → Resolves "Sam" to Client/Prospect
- **ADD**: `suggestContactMatches(_ name: String)` → Handles ambiguous names (multiple "Sam"s)

**`AIAssistantView.swift`** (EXISTING from PR #006 - INTEGRATE):
- Show EventConfirmationCard when AI detects scheduling intent
- Show ConflictWarningCard when conflict detected
- Show AddProspectPromptCard when unknown client

**`FunctionCall.swift`** (EXISTING from PR #008 - EXTEND):
- **ADD**: `rescheduleEvent()` function
- **ADD**: `cancelEvent()` function
- **ENHANCE**: `scheduleCall()` parameters to include eventType, location, notes

---

## 6. Experience Specification (UX)

### Entry Point

**AI Assistant Chat** (existing 🤖 button from PR #006)

### Flow Example

**Scenario: Schedule Training Session**

1. Trainer: "schedule a session with Sam tomorrow at 6pm"
2. AI detects: event type = Training, client = "Sam", time = tomorrow 6pm
3. AI checks ContactService → Finds Sam (client)
4. AI checks calendar for conflicts → None found
5. AI shows EventConfirmationCard:
   ```
   📅 Schedule Event
   🏋️ Training Session
   Client: Sam
   Time: Tomorrow, 6:00 PM - 7:00 PM (1 hour)

   [Confirm] [Cancel]
   ```
6. Trainer taps [Confirm]
7. Event created → AI confirms: "✅ Scheduled session with Sam for tomorrow at 6:00 PM"

**Scenario: Conflict Detected**

1. Trainer: "schedule a call with John tomorrow at 6pm"
2. AI detects conflict (Sam's session already at 6pm)
3. AI shows ConflictWarningCard:
   ```
   ⚠️ Scheduling Conflict
   You already have: Session with Sam
   Time: Tomorrow, 6:00 PM

   Suggested times:
   • 7:00 PM tomorrow
   • 8:00 PM tomorrow
   • 6:00 PM day after tomorrow

   [Pick 7:00 PM] [Pick 8:00 PM] [Pick day after] [Cancel]
   ```
4. Trainer picks alternative → Event created at chosen time

**Scenario: Unknown Client (Auto-Create Prospect)**

1. Trainer: "schedule a call with Sarah tomorrow at 4pm"
2. AI checks ContactService → Sarah not found
3. AI shows AddProspectPromptCard:
   ```
   👤 Client Not Found
   I don't see "Sarah" in your contacts.

   Add Sarah as a prospect?

   [Yes, add prospect] [No, cancel]
   ```
4. Trainer taps [Yes, add prospect]
5. Prospect created with `prospect-sarah@psst.app`
6. Event linked to new prospect
7. AI confirms: "✅ Added Sarah as prospect and scheduled call for tomorrow at 4:00 PM"

### Visual Behavior

**Event Type Detection Keywords:**
- **Training**: "session", "training", "workout", "train"
- **Call**: "call", "phone", "zoom", "meet"
- **Adhoc**: "appointment", "doctor", "oil change" OR no client name mentioned

**Confirmation Cards:**
- EventConfirmationCard: Blue/green/gray based on event type, shows icon + summary
- ConflictWarningCard: Yellow warning banner, lists conflicting event, 3 suggested alternatives
- AddProspectPromptCard: Gray card, simple yes/no choice

---

## 7. Functional Requirements

### AI Event Type Detection

**MUST:**
- **REQ-1**: Parse natural language to detect event type
  - [Gate] "schedule a session with Sam" → Detects Training
  - [Gate] "schedule a call with John" → Detects Call
  - [Gate] "I have a doctor appointment at 2pm" → Detects Adhoc

### Client Validation

**MUST:**
- **REQ-2**: Resolve client name via ContactService
  - If client found → Link event with clientId
  - If prospect found → Link event with prospectId
  - If not found → Prompt to add as prospect
  - [Gate] "schedule Sam" → ContactService finds Sam → Event linked to Sam's clientId

- **REQ-3**: Handle ambiguous names
  - If multiple matches → Ask user to clarify
  - [Gate] "schedule Sam" (2 Sams exist) → AI asks "Which Sam? Sam Jones or Sam Smith?"

- **REQ-4**: Auto-create prospect when not found
  - User confirms → Create prospect with `prospect-[name]@psst.app`
  - Link event to new prospectId
  - [Gate] Unknown "Sarah" → User confirms → Prospect created → Event linked

### Conflict Detection

**MUST:**
- **REQ-5**: Detect scheduling conflicts
  - Query existing events in ±30min window
  - If overlap → Show warning + suggestions
  - [Gate] Event at 6pm exists → Try to schedule 6pm → Conflict detected

- **REQ-6**: Suggest alternative times
  - Find next 3 available slots within working hours (9am-6pm default)
  - Same day if possible, next day otherwise
  - [Gate] Conflict at 6pm → AI suggests 7pm, 8pm, tomorrow 6pm

### Rescheduling & Cancellation

**MUST:**
- **REQ-7**: Handle reschedule via natural language
  - Parse which event (by client name + date)
  - Update startTime/endTime
  - [Gate] "move Sam's session to 7pm" → Event rescheduled → Confirmation shown

- **REQ-8**: Handle cancellation via natural language
  - Parse which event
  - Update status to "cancelled"
  - [Gate] "cancel Sam's session tomorrow" → Event cancelled → Confirmation shown

---

## 8. Data Model

No new collections or fields needed - uses existing schema from PR #010A.

**Data Flow:**
1. AI parses natural language → Extracts parameters
2. ContactService resolves client name → Returns clientId or prospectId
3. CalendarService checks conflicts → Returns conflicting events
4. CalendarService creates event → Event saved to `/calendar/{eventId}`

---

## 9. API / Service Contracts

### Enhanced AIService

```swift
extension AIService {

    /// Detect event type from natural language
    func detectEventType(from query: String) -> EventType {
        let lowercased = query.lowercased()

        if lowercased.contains("session") || lowercased.contains("training") {
            return .training
        }
        if lowercased.contains("call") || lowercased.contains("phone") {
            return .call
        }
        return .adhoc
    }

    /// Enhanced scheduling with conflict detection
    func scheduleWithConflictCheck(
        query: String,
        trainerId: String
    ) async throws -> SchedulingResult
}

enum SchedulingResult {
    case success(CalendarEvent)
    case conflict(existing: CalendarEvent, suggestions: [Date])
    case clientNotFound(name: String)
    case clientAmbiguous(matches: [Contact])
}
```

### Enhanced ContactService

```swift
extension ContactService {

    /// Find client or prospect by name
    func findContactByName(
        _ name: String,
        trainerId: String
    ) async throws -> Contact?

    /// Suggest matches for ambiguous names
    func suggestContactMatches(
        _ name: String,
        trainerId: String
    ) async throws -> [Contact]
}
```

### New Service: CalendarConflictService

```swift
class CalendarConflictService {

    /// Detect conflicts in time window
    func detectConflicts(
        trainerId: String,
        startTime: Date,
        endTime: Date,
        excludeEventId: String? = nil
    ) async throws -> [CalendarEvent]

    /// Suggest alternative times (3 suggestions)
    func suggestAlternatives(
        trainerId: String,
        preferredStartTime: Date,
        duration: Int,
        workingHours: (start: String, end: String)
    ) async throws -> [Date]
}
```

---

## 10. UI Components to Create

### NEW VIEWS (4 files)

1. **`EventConfirmationCard.swift`** - AI event creation confirmation in chat
2. **`ConflictWarningCard.swift`** - Warning when conflict detected
3. **`AddProspectPromptCard.swift`** - Prompt to add unknown client as prospect
4. **`AlternativeTimeButton.swift`** - Button for alternative time selection

### MODIFIED VIEWS (1 file)

1. **`AIAssistantView.swift`** - Integrate confirmation cards + conflict warnings

---

## 11. Testing Plan

### Happy Path

**Scenario: AI scheduling (Training session)**
- [ ] Say "schedule a session with Sam tomorrow at 6pm"
- [ ] **Gate**: AI detects Training, finds Sam via ContactService, no conflicts
- [ ] **Gate**: EventConfirmationCard shown → Tap Confirm → Event created
- [ ] **Pass**: Event appears in CalendarView (from 010A)

### Edge Cases

**Edge Case 1: Ambiguous client name**
- [ ] **Test**: "schedule Sam" when 2 Sams exist
- [ ] **Expected**: AI asks "Which Sam? Sam Jones or Sam Smith?"
- [ ] **Pass**: User picks Sam Jones → Event linked to correct client

**Edge Case 2: Unknown client (auto-create prospect)**
- [ ] **Test**: "schedule a call with Sarah" (Sarah doesn't exist)
- [ ] **Expected**: Prompt to add Sarah as prospect → User confirms → Prospect created
- [ ] **Pass**: Event linked to new prospect

**Edge Case 3: Conflict detected**
- [ ] **Test**: "schedule John at 6pm" when Sam's session exists at 6pm
- [ ] **Expected**: ConflictWarningCard shows → Suggests 7pm, 8pm alternatives
- [ ] **Pass**: User picks 7pm → Event created at 7pm

**Edge Case 4: Reschedule**
- [ ] **Test**: "move Sam's session to 7pm"
- [ ] **Expected**: AI finds Sam's event → Updates time to 7pm → Confirms
- [ ] **Pass**: Event time updated in CalendarView

**Edge Case 5: Cancel**
- [ ] **Test**: "cancel Sam's session tomorrow"
- [ ] **Expected**: AI finds event → Updates status to cancelled → Confirms
- [ ] **Pass**: Event removed from CalendarView (or grayed out)

### Error Handling

**Invalid date**
- [ ] **Test**: "schedule Sam yesterday"
- [ ] **Expected**: AI responds "I can't schedule in the past. Did you mean tomorrow?"
- [ ] **Pass**: No event created, clear error message

---

## 12. Definition of Done

- [ ] AIService.detectEventType() implemented
- [ ] ContactService.findContactByName() implemented
- [ ] CalendarConflictService implemented (conflict detection + suggestions)
- [ ] 4 new confirmation/warning card views created
- [ ] AIAssistantView integrated with confirmation flow
- [ ] All acceptance gates pass (happy path + 5 edge cases + error handling)
- [ ] Conflict detection < 500ms
- [ ] Event type detection >95% accuracy
- [ ] PR created targeting develop

---

## 13. Risks & Mitigations

**Risk 1: Event type detection ambiguity**
- **Mitigation**: Keyword hierarchy (prefer specific over generic), show confirmation before creating

**Risk 2: Client name resolution failures (typos, nicknames)**
- **Mitigation**: Fuzzy matching in findContactByName(), show suggestions when uncertain

**Risk 3: Conflict detection performance (100+ events)**
- **Mitigation**: Query only ±30min window (not all events), use composite index

**Risk 4: Breaking existing scheduleCall() from PR #008**
- **Mitigation**: Extend function, don't replace. Test old AI prompts after enhancement.

---

## 14. Out of Scope (Deferred)

- [ ] Google Calendar sync → **PR #010C**
- [ ] YOLO mode (auto-confirm) → PR #013
- [ ] Multi-client scheduling → Phase 5
- [ ] Recurring event detection → Phase 5

---

**PRD Author**: Pam (Planning Agent)
**Date**: October 25, 2025
**Status**: Draft - Ready for Review
**Depends On**: PR #010A (Calendar Foundation) must be merged first
**Next**: PR #010C (Google Calendar Integration) adds external sync
