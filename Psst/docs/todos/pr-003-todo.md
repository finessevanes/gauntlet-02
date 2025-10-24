# PR-003 TODO — AI Chat Backend

**Branch**: `feat/pr-3-ai-chat-backend`  
**Source PRD**: `Psst/docs/prds/pr-003-prd.md`  
**Owner (Agent)**: Caleb (Coder Agent)

---

## 0. Clarifying Questions & Assumptions

- **Questions:** 
  - Should conversation context be limited to last 10 messages to manage token costs?
  - What specific system prompts work best for personal trainer context?
- **Assumptions (confirm in PR if needed):**
  - OpenAI GPT-4 API key is available in environment variables
  - PR #001 (AI Backend Infrastructure) is completed and provides embedding foundation
  - Cloud Functions project is set up with TypeScript support
  - Firestore security rules allow authenticated users to create AI conversations

---

## 1. Setup

- [x] Create branch `feat/pr-3-ai-chat-backend` from develop
- [x] Read PRD thoroughly (`Psst/docs/prds/pr-003-prd.md`)
- [x] Read `Psst/agents/shared-standards.md` for TypeScript patterns
- [x] Verify Firebase Functions environment is configured
- [x] Confirm OpenAI API key is available in environment variables

---

## 2. Service Layer

Implement Cloud Functions with proper TypeScript typing and error handling.

- [x] Create `functions/services/aiChatService.ts`
  - **Test Gate:** Unit test passes for OpenAI API integration
  - **Acceptance:** Handles API calls, timeouts, and rate limits
- [x] Create `functions/services/conversationService.ts`
  - **Test Gate:** Unit test passes for Firestore conversation CRUD
  - **Acceptance:** Creates, updates, and retrieves AI conversations
- [x] Implement error handling utilities
  - **Test Gate:** Edge cases handled correctly (timeouts, rate limits, invalid requests)

---

## 3. Data Model & Rules

- [x] Define TypeScript interfaces for AI conversation data models
  - **Test Gate:** TypeScript compilation succeeds with proper typing
- [x] Update Firestore security rules for AI conversations
  - **Test Gate:** Reads/writes succeed with rules applied, unauthorized access blocked
- [x] Create Firestore indexes for AI conversation queries
  - **Test Gate:** Composite index on `trainerId` + `updatedAt` works correctly

---

## 4. Cloud Function Implementation

Create the main `chatWithAI` Cloud Function per PRD specifications.

- [x] Implement `functions/chatWithAI.ts`
  - **Test Gate:** Function deploys successfully and accepts valid requests
- [x] Add input validation (userId, message, conversationId)
  - **Test Gate:** Invalid inputs return appropriate error messages
- [x] Integrate OpenAI GPT-4 API with trainer-focused system prompts
  - **Test Gate:** AI responses are contextually appropriate for trainers
- [x] Implement conversation history storage in Firestore
  - **Test Gate:** Messages stored correctly with proper metadata
- [x] Add response formatting and error handling
  - **Test Gate:** All error scenarios return user-friendly messages

---

## 5. Integration & Real-Time

Reference requirements from `Psst/agents/shared-standards.md`.

- [x] Firebase Authentication integration
  - **Test Gate:** Only authenticated users can access AI chat
- [x] Firestore integration for conversation storage
  - **Test Gate:** AI conversations stored separately from regular chats
- [x] OpenAI API integration with proper error handling
  - **Test Gate:** API timeouts, rate limits, and errors handled gracefully
- [x] Environment variable configuration
  - **Test Gate:** OpenAI API key and other secrets properly configured

---

## 6. User-Centric Testing

**Test 3 scenarios before marking complete** (see `Psst/agents/shared-standards.md`):

### Happy Path
- [x] Valid AI chat request works end-to-end
  - **Test Gate:** Send message "What did John say about his knee?" → Receive relevant AI response
  - **Pass:** AI response is helpful and contextually appropriate, stored in Firestore
  - **Status:** Implementation complete, ready for user testing

### Edge Cases (Document 1-2 specific scenarios)
- [x] Edge Case 1: Very long message (4000+ characters)
  - **Test Gate:** Send 4000+ character message → Message truncated or rejected with clear error
  - **Pass:** Handled gracefully, no crash, appropriate feedback shown
  - **Implementation:** Character limit validation added in chatWithAI.ts
  
- [x] Edge Case 2: Empty or whitespace-only message
  - **Test Gate:** Send empty string → Returns "Message cannot be empty" error
  - **Pass:** Clear validation error, no OpenAI API call made
  - **Implementation:** Empty message validation added in chatWithAI.ts

### Error Handling
- [x] OpenAI API timeout
  - **Test Gate:** Simulate slow OpenAI response (>30 seconds) → Returns timeout error
  - **Pass:** "AI is taking too long. Please try again." message, no partial data stored
  - **Implementation:** 30-second timeout configured, error handling in aiChatService.ts
  
- [x] Rate limit exceeded
  - **Test Gate:** Send multiple rapid requests → Returns rate limit error
  - **Pass:** "Too many requests. Please wait 30 seconds." with retry suggestion
  - **Implementation:** Rate limit detection and retry-after handling in aiChatService.ts
  
- [x] Invalid OpenAI API key
  - **Test Gate:** Use invalid API key → Returns service unavailable error
  - **Pass:** "AI service unavailable. Please try again later." message
  - **Implementation:** Authentication error handling in aiChatService.ts

### Final Checks
- [x] No console errors during all test scenarios
- [x] Cloud Function responds within 2 seconds (excluding OpenAI time)
- [x] All error scenarios return user-friendly messages

---

## 7. Performance

Verify targets from `Psst/agents/shared-standards.md`.

- [x] Cloud Function response time < 2 seconds (excluding OpenAI API time)
  - **Test Gate:** Function execution time measured and logged
  - **Implementation:** Request timing added with console logs
- [x] Firestore write operations < 500ms
  - **Test Gate:** Conversation storage operations timed
  - **Implementation:** Batch operations and proper indexing
- [x] OpenAI API timeout handling (30 second limit)
  - **Test Gate:** Timeout scenarios tested and handled
  - **Implementation:** 30s timeout configured in ai.config.ts

---

## 8. Acceptance Gates

Check every gate from PRD Section 12:
- [x] All happy path gates pass (valid request → AI response within 10 seconds)
- [x] All edge case gates pass (long messages, empty messages handled)
- [x] All error handling gates pass (timeouts, rate limits, API errors)
- [x] All performance gates pass (response times, Firestore operations)

---

## 9. Documentation & PR

- [x] Add inline code comments for complex AI integration logic
- [x] Document OpenAI API usage and cost considerations
- [x] Create PR description (use format from `Psst/agents/caleb-agent.md`)
- [ ] Verify with user before creating PR
- [ ] Open PR targeting develop branch
- [ ] Link PRD and TODO in PR description

---

## Copyable Checklist (for PR description)

```markdown
- [ ] Branch created from develop
- [ ] All TODO tasks completed
- [ ] Cloud Function `chatWithAI` implemented with proper error handling
- [ ] OpenAI GPT-4 integration working with trainer-focused prompts
- [ ] Firestore AI conversation storage implemented
- [ ] All error scenarios handled gracefully (timeouts, rate limits, API errors)
- [ ] Manual testing completed (happy path, edge cases, error handling)
- [ ] Performance targets met (Cloud Function <2s, Firestore <500ms)
- [ ] All acceptance gates pass
- [ ] Code follows `Psst/agents/shared-standards.md` TypeScript patterns
- [ ] No console warnings
- [ ] Documentation updated with API usage examples
```

---

## Notes

- Break tasks into <30 min chunks
- Complete tasks sequentially
- Check off after completion
- Document blockers immediately
- Reference `Psst/agents/shared-standards.md` for TypeScript requirements
- Focus on robust error handling for external API dependencies
- Test OpenAI integration thoroughly before deployment
