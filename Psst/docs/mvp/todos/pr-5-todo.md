# PR-5 TODO — Chat Data Models and Firestore Schema

**Branch**: `feat/pr-5-chat-data-models-and-schema`  
**Source PRD**: `Psst/docs/prds/pr-5-prd.md`  
**Owner (Agent)**: Caleb (Building Agent)

---

## 0. Clarifying Questions & Assumptions

**Questions:**
- None outstanding — PRD is complete with all model specifications

**Assumptions (confirm during implementation):**
- Firebase SDK already integrated from PR #3 (User model)
- User.swift pattern from PR #3 should be referenced for consistency
- Testing via Firestore Console only (automated tests deferred to backlog per PRD Section 17)
- No services or UI components in this PR (models only)
- Models will be used by future services in PR #6, #7, #8

---

## 1. Setup

- [ ] Create branch `feat/pr-5-chat-data-models-and-schema` from develop
  - Test Gate: Branch created and checked out successfully

- [ ] Read PRD thoroughly (`Psst/docs/prds/pr-5-prd.md`)
  - Test Gate: Understand all model requirements, Firestore schema, and acceptance gates

- [ ] Read `Psst/agents/shared-standards.md` for patterns
  - Test Gate: Understand Swift best practices, Codable patterns, and data model standards

- [ ] Verify Firebase SDK is available and imported
  - Test Gate: Can import `FirebaseFirestore` and `FieldValue` in project

- [ ] Review User.swift pattern from PR #3 for consistency
  - Test Gate: Understand existing model structure and patterns

- [ ] Confirm app builds successfully
  - Test Gate: Existing code compiles without errors

---

## 2. Data Models Implementation

### 2.1 Create Chat Model

- [ ] Create `Psst/Psst/Models/Chat.swift`
  - Test Gate: File created in correct location

- [ ] Implement Chat struct with required conformance
  - Conform to `Identifiable`, `Codable`, `Equatable`
  - Import `Foundation` and `FirebaseFirestore`
  - Test Gate: Struct compiles without errors

- [ ] Define Chat properties with proper types
  - `id: String`
  - `members: [String]` (User IDs array)
  - `lastMessage: String`
  - `lastMessageTimestamp: Date`
  - `isGroupChat: Bool`
  - `createdAt: Date`
  - `updatedAt: Date`
  - Test Gate: All properties have correct types and access levels

- [ ] Implement Chat initializer
  - Default values for optional parameters
  - Auto-calculate `isGroupChat` based on member count (3+ = true)
  - Test Gate: Initializer compiles and handles edge cases

- [ ] Implement toDictionary() method
  - Use `FieldValue.serverTimestamp()` for timestamp fields
  - Return `[String: Any]` dictionary for Firestore writes
  - Test Gate: Method compiles and returns valid dictionary structure

- [ ] Implement otherUserID(currentUserID:) helper method
  - Return other user ID for 1-on-1 chats
  - Return nil for group chats or invalid member count
  - Test Gate: Helper method logic is correct

- [ ] Add comprehensive inline documentation
  - Document all properties with purpose and usage
  - Document method parameters and return values
  - Test Gate: All public APIs have clear documentation

### 2.2 Create Message Model

- [ ] Create `Psst/Psst/Models/Message.swift`
  - Test Gate: File created in correct location

- [ ] Implement Message struct with required conformance
  - Conform to `Identifiable`, `Codable`, `Equatable`
  - Import `Foundation` and `FirebaseFirestore`
  - Test Gate: Struct compiles without errors

- [ ] Define Message properties with proper types
  - `id: String`
  - `text: String`
  - `senderID: String`
  - `timestamp: Date`
  - `readBy: [String]` (User IDs who read this message)
  - Test Gate: All properties have correct types and access levels

- [ ] Implement Message initializer
  - Default values for timestamp and readBy
  - Test Gate: Initializer compiles and handles defaults

- [ ] Implement toDictionary() method
  - Use `FieldValue.serverTimestamp()` for timestamp field
  - Return `[String: Any]` dictionary for Firestore writes
  - Test Gate: Method compiles and returns valid dictionary structure

- [ ] Implement isReadBy(userID:) helper method
  - Check if specific user ID is in readBy array
  - Test Gate: Helper method logic is correct

- [ ] Implement isFromCurrentUser(currentUserID:) helper method
  - Compare senderID with current user ID
  - Test Gate: Helper method logic is correct

- [ ] Add comprehensive inline documentation
  - Document all properties with purpose and usage
  - Document method parameters and return values
  - Test Gate: All public APIs have clear documentation

---

## 3. Manual Validation (Primary Testing)

**IMPORTANT:** This section replaces traditional unit tests per PRD Section 17 decision. All validation is done via Firestore Console and manual verification.

### 3.0 Create Test File

- [ ] **TEST-FILE: Create TestChatMessage.swift**
  - **Create file:** `Psst/Psst/TestChatMessage.swift`
  - **Copy this complete test code:**
  ```swift
  import Foundation
  import FirebaseFirestore
  
  // MARK: - Complete Test Suite for Chat and Message Models
  
  // Production-safe test IDs
  let testChatID = UUID().uuidString
  let testMessageID = UUID().uuidString
  let testUser1 = "test-user-1-\(UUID().uuidString)"
  let testUser2 = "test-user-2-\(UUID().uuidString)"
  
  print("🧪 Starting Chat and Message Model Tests...")
  print("Test Chat ID: \(testChatID)")
  print("Test Message ID: \(testMessageID)")
  print("Test Users: \(testUser1), \(testUser2)")
  print("")
  
  // MARK: - Test 1: Model Conformance
  print("📋 TEST 1: Model Conformance")
  let chat = Chat(id: "test", members: ["user1", "user2"])
  let message = Message(id: "test", text: "Hello", senderID: "user1")
  
  // Test Identifiable
  print("Chat ID: \(chat.id)")
  print("Message ID: \(message.id)")
  
  // Test Equatable
  let chat2 = Chat(id: "test", members: ["user1", "user2"])
  print("Chats equal: \(chat == chat2)") // Should be true
  
  // Test Codable (encode/decode)
  let encoder = JSONEncoder()
  let decoder = JSONDecoder()
  
  do {
      let chatData = try encoder.encode(chat)
      let decodedChat = try decoder.decode(Chat.self, from: chatData)
      print("✅ Chat Codable test passed")
  } catch {
      print("❌ Chat Codable test failed: \(error)")
  }
  print("")
  
  // MARK: - Test 2: toDictionary() Methods
  print("📋 TEST 2: toDictionary() Methods")
  
  // Test Chat toDictionary()
  let chatDict = chat.toDictionary()
  print("Chat toDictionary() output:")
  print(chatDict)
  print("")
  
  // Test Message toDictionary()
  let messageDict = message.toDictionary()
  print("Message toDictionary() output:")
  print(messageDict)
  print("")
  
  // MARK: - Test 3: Helper Methods
  print("📋 TEST 3: Helper Methods")
  
  // Test otherUserID helper
  let chat1 = Chat(id: "chat1", members: ["user1", "user2"])
  let chat2 = Chat(id: "chat2", members: ["user1", "user2", "user3"])
  
  print("2-member chat otherUserID: \(chat1.otherUserID(currentUserID: "user1"))") // Should return "user2"
  print("3-member chat otherUserID: \(chat2.otherUserID(currentUserID: "user1"))") // Should return nil
  
  // Test isReadBy helper
  let messageWithReadBy = Message(id: "msg1", text: "Hello", senderID: "user1", readBy: ["user2"])
  print("Is read by user2: \(messageWithReadBy.isReadBy(userID: "user2"))") // Should return true
  print("Is read by user3: \(messageWithReadBy.isReadBy(userID: "user3"))") // Should return false
  
  // Test isFromCurrentUser helper
  print("Is from user1: \(message.isFromCurrentUser(currentUserID: "user1"))") // Should return true
  print("Is from user2: \(message.isFromCurrentUser(currentUserID: "user2"))") // Should return false
  print("")
  
  // MARK: - Test 4: Group Chat Detection
  print("📋 TEST 4: Group Chat Detection")
  let chat1Members = Chat(id: "chat1", members: ["user1", "user2"])
  let chat2Members = Chat(id: "chat2", members: ["user1", "user2", "user3"])
  let chat3Members = Chat(id: "chat3", members: ["user1", "user2", "user3", "user4"])
  
  print("2 members isGroupChat: \(chat1Members.isGroupChat)") // Should be false
  print("3 members isGroupChat: \(chat2Members.isGroupChat)") // Should be true
  print("4 members isGroupChat: \(chat3Members.isGroupChat)") // Should be true
  print("")
  
  // MARK: - Test 5: Firestore Write/Read (Production)
  print("📋 TEST 5: Firestore Write/Read (Production)")
  print("⚠️  WARNING: This will write to PRODUCTION Firestore!")
  print("Test Chat ID: \(testChatID)")
  print("Test Message ID: \(testMessageID)")
  print("")
  
  let db = Firestore.firestore()
  
  // Create production test objects
  let productionChat = Chat(id: testChatID, members: [testUser1, testUser2])
  let productionMessage = Message(id: testMessageID, text: "Test message from production test", senderID: testUser1)
  
  do {
      // Write Chat to Firestore
      try await db.collection("chats").document(productionChat.id).setData(productionChat.toDictionary())
      print("✅ Chat written to production Firestore with ID: \(testChatID)")
      
      // Write Message to sub-collection
      try await db.collection("chats/\(testChatID)/messages").document(productionMessage.id)
          .setData(productionMessage.toDictionary())
      print("✅ Message written to sub-collection with ID: \(testMessageID)")
      
      // Read Chat back
      let chatSnapshot = try await db.collection("chats").document(testChatID).getDocument()
      let readChat = try chatSnapshot.data(as: Chat.self)
      print("✅ Chat read from Firestore: \(readChat)")
      
      // Read Message back
      let messageSnapshot = try await db.collection("chats/\(testChatID)/messages").document(testMessageID).getDocument()
      let readMessage = try messageSnapshot.data(as: Message.self)
      print("✅ Message read from Firestore: \(readMessage)")
      
      // Clean up test data
      try await db.collection("chats").document(testChatID).delete()
      print("✅ Test data cleaned up from production")
      
  } catch {
      print("❌ Firestore test failed: \(error)")
  }
  
  print("")
  print("🎉 All tests completed!")
  print("📱 Check Firestore Console to verify documents were created and deleted")
  print("🔗 Firestore Console: https://console.firebase.google.com/")
  ```
  - **Test Gate:** File created with complete test suite

### 3.1 Compilation and Basic Validation

- [ ] **COMP-1: Zero Compiler Warnings**
  - **Run this test:** Build project in Xcode
  - **Verify:** No warnings appear in build output
  - Test Gate: Clean build with zero warnings

- [ ] **COMP-2: Model Conformance Verification**
  - **Run this test:** Run the complete `TestChatMessage.swift` file
  - **Check output:** Look for "TEST 1: Model Conformance" section in console
  - **Verify:** All protocol requirements satisfied (Identifiable, Codable, Equatable)
  - Test Gate: All protocol requirements satisfied

### 3.2 toDictionary() Method Testing

- [ ] **DICT-1: Chat toDictionary() Output**
  - **Run this test:** Run the complete `TestChatMessage.swift` file
  - **Check output:** Look for "TEST 2: toDictionary() Methods" section in console
  - **Verify:** Dictionary contains all expected keys with correct types
  - Test Gate: Dictionary contains all expected keys with correct types

- [ ] **DICT-2: Message toDictionary() Output**
  - **Run this test:** Same as DICT-1 (included in complete test file)
  - **Check output:** Look for Message toDictionary() output in console
  - **Verify:** Dictionary contains all expected keys with correct types
  - Test Gate: Dictionary contains all expected keys with correct types

### 3.3 Firestore Write Testing

- [ ] **FIRE-1: Chat Document Write**
  - **Run this test:** Run the complete `TestChatMessage.swift` file
  - **Check output:** Look for "TEST 5: Firestore Write/Read (Production)" section in console
  - **Open Firestore Console** in browser → Navigate to `chats` collection → Find your test document
  - **Verify:** Document structure matches expected schema in Console
  - Test Gate: Document structure matches expected schema in Console

- [ ] **FIRE-2: Message Sub-collection Write**
  - **Run this test:** Same as FIRE-1 (included in complete test file)
  - **Check output:** Look for Message write success message in console
  - **Open Firestore Console** → Navigate to `chats` → `{testChatID}` → `messages` → Find your test message
  - **Verify:** Sub-collection document structure matches expected schema
  - Test Gate: Sub-collection document structure matches expected schema

### 3.4 Firestore Read Testing

- [ ] **READ-1: Chat Document Read**
  - **Run this test:** Same as FIRE-1 (included in complete test file)
  - **Check output:** Look for "Chat read from Firestore" success message in console
  - **Verify:** Decoded Chat matches original data
  - Test Gate: Decoded Chat matches original data

- [ ] **READ-2: Message Document Read**
  - **Run this test:** Same as FIRE-1 (included in complete test file)
  - **Check output:** Look for "Message read from Firestore" success message in console
  - **Verify:** Decoded Message matches original data
  - Test Gate: Decoded Message matches original data

### 3.5 Helper Method Testing

- [ ] **HELP-1: Chat.otherUserID() Testing**
  - **Run this test:** Run the complete `TestChatMessage.swift` file
  - **Check output:** Look for "TEST 3: Helper Methods" section in console
  - **Verify:** Helper method returns correct values for all scenarios
  - Test Gate: Helper method returns correct values for all scenarios

- [ ] **HELP-2: Message.isReadBy() Testing**
  - **Run this test:** Same as HELP-1 (included in complete test file)
  - **Check output:** Look for isReadBy test results in console
  - **Verify:** Helper method returns correct boolean values
  - Test Gate: Helper method returns correct boolean values

- [ ] **HELP-3: Message.isFromCurrentUser() Testing**
  - **Run this test:** Same as HELP-1 (included in complete test file)
  - **Check output:** Look for isFromCurrentUser test results in console
  - **Verify:** Helper method returns correct boolean values
  - Test Gate: Helper method returns correct boolean values

### 3.6 Group Chat Detection Testing

- [ ] **GROUP-1: isGroupChat Auto-Detection**
  - **Run this test:** Run the complete `TestChatMessage.swift` file
  - **Check output:** Look for "TEST 4: Group Chat Detection" section in console
  - **Verify:** isGroupChat correctly calculated based on member count
  - Test Gate: isGroupChat correctly calculated based on member count

### 3.7 Server Timestamp Verification

- [ ] **TIME-1: Server Timestamps in Firestore**
  - **Run this test:** Same as FIRE-1 (included in complete test file)
  - **Check output:** Look for successful write messages in console
  - **Open Firestore Console** → Navigate to your test documents
  - **Verify:** Server timestamps are properly set in Firestore documents
  - Test Gate: Server timestamps are properly set in Firestore documents

---

## 4. Acceptance Gates Verification

**Cross-reference all gates from PRD Section 7:**

- [ ] **GATE-1: Model Conformance**
  - Chat conforms to Identifiable, Codable, Equatable
  - Message conforms to Identifiable, Codable, Equatable
  - Test Gate: All protocol requirements verified

- [ ] **GATE-2: toDictionary() Validity**
  - Chat.toDictionary() returns valid Firestore dictionary
  - Message.toDictionary() returns valid Firestore dictionary
  - Test Gate: Dictionaries successfully written to Firestore

- [ ] **GATE-3: Firestore Structure Verification**
  - Chat document structure verified in Console
  - Message sub-collection structure verified in Console
  - Test Gate: Console shows correct document structure

- [ ] **GATE-4: Codable Decoding**
  - Chat decodes successfully from Firestore
  - Message decodes successfully from Firestore
  - Test Gate: All fields decode without errors

- [ ] **GATE-5: Group Chat Detection**
  - 2 members → isGroupChat = false
  - 3+ members → isGroupChat = true
  - Test Gate: Logic verified with multiple test cases

---

## 5. Documentation & Code Quality

- [ ] **DOC-1: Inline Comments**
  - All Chat properties documented with purpose
  - All Message properties documented with purpose
  - All methods documented with parameters and return values
  - Test Gate: Code is self-documenting and clear

- [ ] **DOC-2: Code Standards Compliance**
  - Code follows `Psst/agents/shared-standards.md` patterns
  - Proper Swift naming conventions
  - No hardcoded values or magic numbers
  - Test Gate: Code adheres to project standards

- [ ] **DOC-3: No Console Warnings**
  - Build project and verify zero warnings
  - Test Gate: Clean compilation with no warnings

---

## 6. PR Preparation

- [ ] **PR-1: Manual Validation Summary**
  - Document all manual test results
  - Note any issues found and resolved
  - Test Gate: All manual tests completed successfully

- [ ] **PR-2: Create PR Description**
  - Reference PRD: `Psst/docs/prds/pr-5-prd.md`
  - Reference TODO: `Psst/docs/todos/pr-5-todo.md`
  - List files created: `Models/Chat.swift`, `Models/Message.swift`
  - Include manual validation evidence
  - Note: Automated tests deferred to backlog
  - Test Gate: PR description is complete and clear

- [ ] **PR-3: Verify Branch Status**
  - Ensure branch is up to date with develop
  - `git fetch origin develop`
  - `git rebase origin/develop` (resolve conflicts if any)
  - Test Gate: Branch rebased successfully, no conflicts

- [ ] **PR-4: Push and Create PR**
  - `git push -u origin feat/pr-5-chat-data-models-and-schema`
  - Open PR targeting develop branch
  - Link PRD and TODO in PR description
  - Test Gate: PR created successfully with proper links

---

## Copyable Checklist (for PR description)

```markdown
## PR #5: Chat Data Models and Firestore Schema — Checklist

### Implementation
- [ ] Branch created from develop
- [ ] All TODO tasks completed
- [ ] Models/Chat.swift created with full conformance
- [ ] Models/Message.swift created with full conformance
- [ ] toDictionary() methods implemented with server timestamps
- [ ] Helper methods implemented (otherUserID, isReadBy, isFromCurrentUser)
- [ ] Inline documentation added for all properties and methods

### Manual Validation (Primary Testing)
- [ ] All compilation tests passed (COMP-1, COMP-2)
- [ ] All toDictionary() tests passed (DICT-1, DICT-2)
- [ ] All Firestore write tests passed (FIRE-1, FIRE-2)
- [ ] All Firestore read tests passed (READ-1, READ-2)
- [ ] All helper method tests passed (HELP-1, HELP-2, HELP-3)
- [ ] Group chat detection verified (GROUP-1)
- [ ] Server timestamps verified (TIME-1)

### Acceptance Gates
- [ ] All acceptance gates verified (GATE-1 through GATE-5)
- [ ] Models conform to Identifiable, Codable, Equatable
- [ ] toDictionary() returns valid Firestore dictionaries
- [ ] Firestore write/read cycle successful
- [ ] Group chat detection logic correct

### Code Quality
- [ ] Code follows `Psst/agents/shared-standards.md` patterns
- [ ] No console warnings or errors
- [ ] All fields documented with inline comments
- [ ] Zero compiler warnings

### References
- [ ] PRD: `Psst/docs/prds/pr-5-prd.md`
- [ ] TODO: `Psst/docs/todos/pr-5-todo.md`

**Testing Strategy:** Manual validation via Firestore Console. Automated tests deferred to backlog (see PRD Section 17).
```

---

## Notes

- **Task Size:** Each task designed to take < 30 min
- **Sequential Execution:** Complete tasks in order (Setup → Models → Manual Testing → Documentation)
- **Testing Strategy:** Manual testing only via Firestore Console (automated tests deferred to backlog per PRD Section 17)
- **Dependencies:** Requires PR #3 (User model pattern) for consistency
- **Scope:** Models only - no services, no UI components
- **Reference:** See `Psst/agents/shared-standards.md` for Swift patterns and data model standards

---

## Definition of Done (from PRD Section 13)

- [ ] Models/Chat.swift created with full conformance
- [ ] Models/Message.swift created with full conformance
- [ ] Both models conform to Identifiable, Codable, Equatable
- [ ] toDictionary() implemented with server timestamps
- [ ] Helper methods implemented and tested
- [ ] All fields documented with inline comments
- [ ] All manual validation steps completed successfully
- [ ] No compiler warnings
- [ ] Code follows shared-standards.md patterns
- [ ] PR merged to develop
