# PRD: AI Chat Backend

**Feature**: AI Chat Backend

**Version**: 1.0

**Status**: Draft

**Agent**: Pam (Planning Agent)

**Target Release**: Phase 2

**Links**: [PR Brief], [TODO], [Architecture]

---

## 1. Summary

Implement the core AI chat functionality on the backend including the `chatWithAI` Cloud Function and OpenAI ChatGPT integration. This backend powers the dedicated AI Assistant chat that trainers can use as their "second brain" for client management and conversation insights.

---

## 2. Problem & Goals

**Problem:** Trainers need an AI assistant to help manage client conversations, answer questions about past interactions, and provide contextual insights without manually searching through chat history.

**Why now:** Foundation infrastructure (PR #001) is complete, enabling vector embeddings and semantic search capabilities.

**Goals:**
- [ ] G1 — Backend can process AI chat requests and generate contextual responses using OpenAI GPT-4
- [ ] G2 — AI conversations are stored separately from regular chats with proper context management
- [ ] G3 — System handles API timeouts, rate limits, and errors gracefully with fallback responses

---

## 3. Non-Goals / Out of Scope

- [ ] Not implementing RAG pipeline (semantic search) - that's PR #005
- [ ] Not creating iOS UI components - that's PR #004  
- [ ] Not implementing function calling/tools - that's PR #008
- [ ] Not adding voice interface - that's PR #010
- [ ] Not implementing proactive suggestions - that's PR #009

---

## 4. Success Metrics

**User-visible:**
- AI responses generated within 3 seconds for simple queries
- 95% of valid requests receive successful AI responses
- Clear error messages when AI is unavailable

**System:**
- Cloud Function response time < 2 seconds (excluding OpenAI API time)
- OpenAI API timeout handling (30 second limit)
- Rate limit management (requests per minute tracking)

**Quality:**
- 0 blocking bugs in AI chat flow
- All acceptance gates pass
- Graceful degradation when OpenAI is unavailable

---

## 5. Users & Stories

- As a **personal trainer**, I want to ask my AI assistant questions about my clients so that I can quickly recall important information without scrolling through chat history.
- As a **personal trainer**, I want the AI to remember our conversation context so that I can have natural back-and-forth discussions about my business.
- As a **personal trainer**, I want clear feedback when the AI is unavailable so that I know to try again later or use alternative methods.

---

## 5b. Affected Existing Code

**Services:**
- `Services/AIService.swift` - Add new method `chatWithAI(userId, message, conversationId)`
- `Services/FirebaseService.swift` - No changes (uses existing Firebase setup)

**Views:**
- No iOS views affected (backend-only PR)

**ViewModels:**
- No ViewModels affected (backend-only PR)

**Models:**
- No existing models modified (creates new AI conversation storage)

---

## 6. Experience Specification (UX)

**Entry points:** iOS app calls Cloud Function via AIService (not implemented in this PR)

**Visual behavior:** Backend-only - no UI changes

**Loading/disabled/error states:**
- Loading: AI processing indicator (handled in PR #004)
- Error: "AI is temporarily unavailable. Please try again in a moment."
- Timeout: "This is taking longer than expected. Would you like to try again?"

**Performance:** Cloud Function responds within 2 seconds, OpenAI API calls may take 3-10 seconds

---

## 7. Functional Requirements (Must/Should)

**MUST:**
- Cloud Function `chatWithAI` accepts `userId`, `message`, and `conversationId` parameters
- Integrate OpenAI GPT-4 API with trainer-focused system prompts
- Store AI conversation history in Firestore under `/ai_conversations/{conversationId}`
- Return AI-generated responses as JSON
- Handle OpenAI API timeouts (30 second limit)
- Handle rate limit errors (429 status) with retry logic
- Handle invalid requests with clear error messages

**SHOULD:**
- Support response streaming for real-time updates (future enhancement)
- Include conversation context in AI prompts
- Log AI requests for debugging and cost tracking

**Acceptance gates:**
- [Gate] When valid request sent → AI response returned within 10 seconds
- [Gate] When OpenAI times out → Returns "AI is taking too long" error message
- [Gate] When rate limit hit → Returns "Too many requests, please wait" with retry suggestion
- [Gate] When invalid request → Returns specific validation error message

---

## 8. Data Model

**New Firestore Collection: `/ai_conversations/{conversationId}`**

```typescript
{
  id: string,                    // conversationId
  trainerId: string,             // Firebase Auth UID
  createdAt: Timestamp,          // First message timestamp
  updatedAt: Timestamp,          // Last message timestamp
  messageCount: number,          // Total messages in conversation
  lastMessage: string,           // Most recent user message
  lastResponse: string,           // Most recent AI response
  isActive: boolean              // Whether conversation is ongoing
}
```

**New Firestore Collection: `/ai_conversations/{conversationId}/messages/{messageId}`**

```typescript
{
  id: string,                    // messageId
  conversationId: string,       // Parent conversation ID
  role: "user" | "assistant",   // Message sender
  content: string,               // Message text
  timestamp: Timestamp,         // Message creation time
  tokensUsed?: number,           // OpenAI token count (for cost tracking)
  model: string,                 // OpenAI model used (e.g., "gpt-4")
  error?: string                 // Error message if AI call failed
}
```

**Validation rules:**
- All fields required except `tokensUsed`, `error`
- `role` must be either "user" or "assistant"
- `content` must be non-empty string
- `trainerId` must match authenticated user

**Indexing:**
- Composite index on `trainerId` + `updatedAt` for conversation list queries
- Single field index on `conversationId` for message queries

---

## 9. API / Service Contracts

**Cloud Function: `chatWithAI`**

```typescript
// Input parameters
interface ChatWithAIRequest {
  userId: string;           // Firebase Auth UID
  message: string;          // User's message to AI
  conversationId?: string;   // Optional: existing conversation ID
}

// Response
interface ChatWithAIResponse {
  success: boolean;
  response?: string;        // AI-generated response
  conversationId: string;   // Conversation ID (new or existing)
  error?: string;          // Error message if failed
  tokensUsed?: number;     // OpenAI tokens consumed
}
```

**Pre-conditions:**
- User must be authenticated
- `message` must be non-empty string (1-4000 characters)
- `userId` must match authenticated user

**Post-conditions:**
- AI conversation stored in Firestore
- Response returned to client
- Error logged if OpenAI call fails

**Error handling:**
- `INVALID_REQUEST`: Empty message, invalid userId
- `OPENAI_TIMEOUT`: OpenAI API timeout (30s)
- `RATE_LIMIT_EXCEEDED`: OpenAI rate limit hit
- `OPENAI_ERROR`: OpenAI API error (invalid key, quota exceeded)
- `INTERNAL_ERROR`: Unexpected server error

---

## 10. UI Components to Create/Modify

**Backend-only PR - no iOS components created/modified**

**Cloud Functions to create:**
- `functions/chatWithAI.ts` — Main AI chat endpoint
- `functions/services/aiService.ts` — OpenAI integration service
- `functions/services/conversationService.ts` — Firestore conversation management

---

## 11. Integration Points

**Firebase Authentication:**
- Verify user authentication before processing requests
- Use authenticated user ID for conversation isolation

**Firestore:**
- Store AI conversations in separate collection from regular chats
- Maintain conversation history for context

**OpenAI API:**
- GPT-4 model for response generation
- System prompts tailored for personal trainer context
- Token usage tracking for cost monitoring

**Cloud Functions:**
- Deploy as callable function
- Environment variables for OpenAI API key
- Error handling and logging

---

## 12. Testing Plan & Acceptance Gates

### Happy Path
- [ ] User sends valid message to AI → AI responds with relevant answer
- **Gate:** AI response received within 10 seconds, stored in Firestore
- **Pass Criteria:** Response is coherent and relevant to trainer context

**Example (AI Chat):**
- Send message "What did John say about his knee?" → AI responds with relevant information
- Gate: Response stored in `/ai_conversations/{id}/messages/{id}` with proper metadata
- Pass: Response is helpful and contextually appropriate

---

### Edge Cases

- [ ] **Edge Case 1:** Very long message (4000+ characters)
  - **Test:** Send message with 4000+ characters
  - **Expected:** Message truncated or rejected with character limit error
  - **Pass:** Handled gracefully, clear feedback provided

- [ ] **Edge Case 2:** Empty or whitespace-only message
  - **Test:** Send empty string or only whitespace
  - **Expected:** Returns "Message cannot be empty" error
  - **Pass:** Clear validation error, no AI API call made

---

### Error Handling

- [ ] **OpenAI API Timeout**
  - **Test:** Simulate slow OpenAI response (>30 seconds)
  - **Expected:** Returns "AI is taking too long. Please try again."
  - **Pass:** Timeout handled gracefully, no partial data stored

- [ ] **Rate Limit Exceeded**
  - **Test:** Send multiple requests rapidly to trigger rate limit
  - **Expected:** Returns "Too many requests. Please wait 30 seconds."
  - **Pass:** Rate limit detected, retry suggestion provided

- [ ] **Invalid OpenAI API Key**
  - **Test:** Use invalid API key in environment
  - **Expected:** Returns "AI service unavailable. Please try again later."
  - **Pass:** API error handled gracefully, no crash

- [ ] **Network Failure**
  - **Test:** Disconnect internet during OpenAI call
  - **Expected:** Returns "Network error. Please check your connection."
  - **Pass:** Network error caught, retry option provided

---

### Performance Check

- [ ] Cloud Function responds within 2 seconds (excluding OpenAI time)
- [ ] Firestore writes complete within 500ms
- [ ] No memory leaks during concurrent requests

---

## 13. Definition of Done

- [ ] Cloud Function `chatWithAI` implemented with proper error handling
- [ ] OpenAI GPT-4 integration working with trainer-focused prompts
- [ ] Firestore conversation storage implemented
- [ ] All error scenarios handled gracefully
- [ ] Manual testing completed (happy path, edge cases, error handling)
- [ ] Environment variables configured for OpenAI API
- [ ] Function deployed and accessible via Firebase
- [ ] Documentation updated with API usage examples

---

## 14. Risks & Mitigations

- **Risk:** OpenAI API costs → **Mitigation:** Token usage tracking, rate limiting, cost alerts
- **Risk:** OpenAI API downtime → **Mitigation:** Graceful error handling, fallback messages
- **Risk:** Rate limit exceeded → **Mitigation:** Request queuing, retry logic with exponential backoff
- **Risk:** Long response times → **Mitigation:** 30-second timeout, progress indicators
- **Risk:** Inappropriate AI responses → **Mitigation:** System prompts focused on trainer context, content filtering

---

## 15. Rollout & Telemetry

- **Feature flag:** No (backend-only, controlled by iOS app usage)
- **Metrics:** Response time, success rate, error rate, token usage
- **Manual validation:** Test with various message types and error scenarios

---

## 16. Open Questions

- Q1: Should we implement conversation context limits (e.g., last 10 messages)?
- Q2: What system prompts work best for personal trainer context?

---

## 17. Appendix: Out-of-Scope Backlog

**Future enhancements:**
- [ ] Response streaming for real-time updates
- [ ] Conversation context optimization
- [ ] Advanced error recovery
- [ ] AI response quality scoring

---

## Preflight Questionnaire

1. **Smallest end-to-end user outcome for this PR?** Backend can receive AI chat requests and return contextual responses
2. **Primary user and critical action?** Personal trainer asking AI questions about their business
3. **Must-have vs nice-to-have?** Must: Basic AI responses. Nice: Streaming, advanced context
4. **Real-time requirements?** No real-time sync needed (backend-only)
5. **Performance constraints?** <2s Cloud Function response, <10s total including OpenAI
6. **Error/edge cases to handle?** Timeouts, rate limits, invalid requests, API failures
7. **Data model changes?** New Firestore collections for AI conversations
8. **Service APIs required?** OpenAI GPT-4 API, Firestore for storage
9. **UI entry points and states?** None (backend-only PR)
10. **Security/permissions implications?** User authentication required, conversation isolation
11. **Dependencies or blocking integrations?** Requires PR #001 (AI Backend Infrastructure)
12. **Rollout strategy and metrics?** Deploy Cloud Function, monitor OpenAI usage
13. **What is explicitly out of scope?** iOS UI, RAG pipeline, function calling, voice interface

---

## Authoring Notes

- Backend-only implementation - no iOS changes
- Focus on robust error handling for external API dependencies
- Design for future enhancements (streaming, context optimization)
- Reference `Psst/agents/shared-standards.md` for TypeScript requirements
- Test OpenAI integration thoroughly before deployment
