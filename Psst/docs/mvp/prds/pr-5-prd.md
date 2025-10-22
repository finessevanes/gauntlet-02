# PRD: Chat Data Models and Firestore Schema

**Feature**: chat-data-models-and-schema

**Version**: 1.0

**Status**: Draft

**Agent**: Pam

**Target Release**: Phase 2 - 1-on-1 Chat

**Links**: [PR Brief](../pr-briefs.md#pr-5-chat-data-models-and-schema) | [TODO](../todos/pr-5-todo.md) | [Architecture](../architecture.md)

---

## 1. Summary

Define Chat and Message data models with Firestore schema structure. Per architecture.md: "Models are Simple: Just data structures matching your Firestore schema." This establishes the data layer for all Phase 2-3 chat features, supporting both 1-on-1 and group conversations.

---

## 2. Problem & Goals

**Problem**: Need well-defined data models and Firestore schema before implementing chat features (conversation list, message sending, real-time sync).

**Why now**: Phase 2 foundation. PR #6 (conversation list), PR #7 (chat view), PR #8 (messaging service) depend on these models.

**Goals**:
- [ ] G1 — Chat model defined with Codable support matching Firestore `chats` collection
- [ ] G2 — Message model defined with Codable support matching `messages` sub-collection
- [ ] G3 — Schema supports both 1-on-1 and group chats
- [ ] G4 — Models include serialization helpers (`toDictionary()`) for Firestore writes

---

## 3. Non-Goals / Out of Scope

- [ ] Not implementing ChatService or MessageService (PR #8, PR #12)
- [ ] Not implementing real-time listeners (PR #8)
- [ ] Not implementing UI components (PR #6, PR #7)
- [ ] Not implementing media messages, encryption, editing, deletion (future)
- [ ] Not implementing automated tests (deferred to backlog)

---

## 4. Success Metrics

**User-visible**: N/A (no UI in this PR)

**System**:
- Models correctly serialize to/from Firestore
- Schema supports message delivery < 100ms (tested in PR #8)
- Schema supports offline persistence

**Quality**:
- 0 blocking bugs
- Models follow Swift best practices (Codable, Identifiable, Equatable)
- All gates pass via manual Firestore Console validation

---

## 5. Users & Stories

- As a **developer**, I want well-defined Chat and Message models so I can build services consistently
- As a **developer**, I want Codable models so Firestore serialization is automatic and type-safe
- As a **developer**, I want toDictionary() helpers for easy Firestore writes with server timestamps
- As a **developer**, I want schema to support both 1-on-1 and group chats without refactoring

---

## 6. Experience Specification (UX)

**Entry points**: Developer imports Chat/Message models in services and ViewModels

**Visual behavior**: No UI (models only)

**Performance**: Per shared-standards.md - no UI blocking, serialization extremely fast

---

## 7. Functional Requirements (Must/Should)

**MUST**:
- MUST define Chat struct: Identifiable, Codable, Equatable
- MUST define Message struct: Identifiable, Codable, Equatable
- MUST implement toDictionary() for both models using FieldValue.serverTimestamp()
- MUST place in `Models/` folder per architecture.md
- MUST keep models simple (no business logic)

**Chat fields**: id, members, lastMessage, lastMessageTimestamp, isGroupChat, createdAt, updatedAt

**Message fields**: id, text, senderID, timestamp, readBy

**SHOULD**:
- SHOULD include helper methods (otherUserID, isReadBy, isFromCurrentUser)
- SHOULD document all fields with inline comments

**Acceptance gates**:
- [Gate] Both models compile with zero warnings
- [Gate] Models conform to Identifiable, Codable, Equatable
- [Gate] toDictionary() returns valid Firestore dictionaries
- [Gate] Write to Firestore → structure verified in Console
- [Gate] Read from Firestore → models decode successfully
- [Gate] Chat with 2 members → isGroupChat = false
- [Gate] Chat with 3+ members → isGroupChat = true

---

## 8. Data Model

### Firestore Schema

**Collection**: `chats`
**Sub-collection**: `chats/{chatID}/messages`

**Chat Document**:
```swift
{
  id: String,
  members: [String],              // User IDs (2 for 1-on-1, 3+ for group)
  lastMessage: String,
  lastMessageTimestamp: Timestamp,
  isGroupChat: Bool,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

**Message Document**:
```swift
{
  id: String,
  text: String,                   // 1-10,000 chars (validated in PR #8)
  senderID: String,
  timestamp: Timestamp,
  readBy: [String]                // User IDs who read this message
}
```

### Swift Models

**Models/Chat.swift**:
```swift
import Foundation
import FirebaseFirestore

struct Chat: Identifiable, Codable, Equatable {
    let id: String
    let members: [String]
    var lastMessage: String
    var lastMessageTimestamp: Date
    var isGroupChat: Bool
    let createdAt: Date
    var updatedAt: Date

    init(id: String, members: [String], lastMessage: String = "",
         lastMessageTimestamp: Date = Date(), isGroupChat: Bool? = nil,
         createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.members = members
        self.lastMessage = lastMessage
        self.lastMessageTimestamp = lastMessageTimestamp
        self.isGroupChat = isGroupChat ?? (members.count >= 3)
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "members": members,
            "lastMessage": lastMessage,
            "lastMessageTimestamp": FieldValue.serverTimestamp(),
            "isGroupChat": isGroupChat,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
    }

    func otherUserID(currentUserID: String) -> String? {
        guard !isGroupChat, members.count == 2 else { return nil }
        return members.first { $0 != currentUserID }
    }
}
```

**Models/Message.swift**:
```swift
import Foundation
import FirebaseFirestore

struct Message: Identifiable, Codable, Equatable {
    let id: String
    let text: String
    let senderID: String
    let timestamp: Date
    var readBy: [String]

    init(id: String, text: String, senderID: String,
         timestamp: Date = Date(), readBy: [String] = []) {
        self.id = id
        self.text = text
        self.senderID = senderID
        self.timestamp = timestamp
        self.readBy = readBy
    }

    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "text": text,
            "senderID": senderID,
            "timestamp": FieldValue.serverTimestamp(),
            "readBy": readBy
        ]
    }

    func isReadBy(userID: String) -> Bool {
        return readBy.contains(userID)
    }

    func isFromCurrentUser(currentUserID: String) -> Bool {
        return senderID == currentUserID
    }
}
```

---

## 9. API / Service Contracts

**No service methods in this PR** (models only per architecture.md).

**Usage by future services**:
```swift
// Example: ChatService (PR #12)
let chat = Chat(id: UUID().uuidString, members: [userID1, userID2])
try await db.collection("chats").document(chat.id).setData(chat.toDictionary())

// Example: MessageService (PR #8)
let message = Message(id: UUID().uuidString, text: "Hello", senderID: currentUserID)
try await db.collection("chats/\(chatID)/messages").document(message.id)
    .setData(message.toDictionary())

// Decoding from Firestore
let chat = try snapshot.data(as: Chat.self)
```

---

## 10. UI Components to Create/Modify

**Files to Create**:
- `Models/Chat.swift` — Chat data model (per architecture.md)
- `Models/Message.swift` — Message data model (per architecture.md)

**No UI components in this PR.**

---

## 11. Integration Points

- **Firestore Database**: Models map directly to collections/documents
- **Codable Protocol**: Automatic encoding/decoding
- **FieldValue.serverTimestamp()**: Synchronized timestamps across devices
- **Architecture**: Follows "Models are Simple" principle from architecture.md

---

## 12. Manual Validation Plan

**All testing via Firestore Console** (automated tests deferred to backlog).

### Validation Steps

- [ ] Build project → Zero compiler warnings
- [ ] Create Chat/Message objects → Call toDictionary() and verify output
- [ ] Write Chat to Firestore → Verify structure in Console
- [ ] Write Message to sub-collection → Verify structure in Console
- [ ] Read from Firestore → Decode using Codable successfully
- [ ] Test helper methods (otherUserID, isReadBy, isFromCurrentUser)
- [ ] Verify isGroupChat auto-detection (2 members = false, 3+ = true)

---

## 13. Definition of Done

- [ ] Models/Chat.swift created (per architecture.md)
- [ ] Models/Message.swift created (per architecture.md)
- [ ] Both models conform to Identifiable, Codable, Equatable
- [ ] toDictionary() implemented with server timestamps
- [ ] Helper methods implemented
- [ ] All fields documented
- [ ] All manual validation steps pass
- [ ] No compiler warnings
- [ ] Code follows shared-standards.md
- [ ] PR merged to develop

---

## 14. Risks & Mitigations

**Risk**: Firestore Timestamp conversion issues → **Mitigation**: Use Date type; SDK handles conversion

**Risk**: Model changes break existing data → **Mitigation**: Design for extensibility (optional fields)

**Risk**: Array fields (members, readBy) performance → **Mitigation**: Limit group size; readBy limited by member count

**Risk**: Server timestamp null during writes → **Mitigation**: Services handle in PR #8; optimistic UI uses local timestamps

---

## 15. Rollout & Telemetry

**Feature Flag**: N/A (infrastructure)

**Manual Validation**:
1. Create models → Verify toDictionary() in debugger
2. Write to Firestore → Verify in Console
3. Read from Firestore → Verify decoding works

---

## 16. Open Questions

- **Q1**: Add groupName field? → **Decision**: Defer to PR #13
- **Q2**: Add message status field? → **Decision**: Derive from readBy array
- **Q3**: Max text length? → **Decision**: 10,000 chars (validated in PR #8)

---

## 17. Appendix: Out-of-Scope Backlog

**Features Deferred**:
- [ ] Group chat names/metadata (PR #13)
- [ ] Media messages (future)
- [ ] Message editing/deletion (future)
- [ ] Message reactions, threading (future)

**Testing Deferred** (tracked in `/Psst/docs/backlog.md`):
- [ ] All automated tests (unit, integration, performance)
- [ ] Deferred to PR #25 or Phase 4 testing sprint

---

## Preflight Questionnaire

1. **Smallest outcome?** Developers can create and serialize Chat/Message models
2. **Primary user?** Developers building chat services
3. **Must-have?** Chat/Message models, toDictionary(), Codable
4. **Real-time requirements?** N/A (models only; sync in PR #8)
5. **Performance?** Per shared-standards.md - no UI blocking
6. **Error cases?** Invalid data handled gracefully
7. **Data model changes?** Create Chat/Message per architecture.md
8. **Service APIs?** None (models only)
9. **UI?** None
10. **Security?** Rules documented; implemented in PR #8
11. **Dependencies?** PR #3 (User model pattern)
12. **Rollout?** Manual validation via Firestore Console
13. **Out of scope?** Services, UI, media, encryption, tests

---

## Authoring Notes

- Follow architecture.md: "Models are Simple"
- Follow User.swift pattern from PR #3
- Use Codable + FieldValue.serverTimestamp()
- Keep models simple (no business logic)
- All validation via Firestore Console
- Testing deferred to backlog
