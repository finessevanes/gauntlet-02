# PR-005 TODO — RAG Pipeline (Semantic Search)

**Branch**: `feat/pr-5-rag-pipeline`  
**Source PRD**: `Psst/docs/prds/pr-005-prd.md`  
**Owner (Agent)**: Caleb (Coder Agent)

---

## 0. Clarifying Questions & Assumptions

- **Questions:** 
  - Should we cache embeddings for common queries ("injuries", "diet", "goals") to improve performance?
  - What's the maximum context window for GPT-4 (how many past messages)?
  - Should we support filtering by specific chat IDs or always search all conversations?
- **Assumptions (confirm in PR if needed):**
  - PR #001 (AI Backend Infrastructure) is complete with Pinecone index populated
  - PR #003 (AI Chat Backend) is complete with `chatWithAI` function deployed
  - Pinecone API key and OpenAI API key are configured in Firebase Functions environment
  - Firestore contains message data that has been embedded in Pinecone
  - `embeddingService.ts` exists from PR #001 (will verify and reuse)
  - Relevance threshold of 0.7+ cosine similarity is appropriate for quality results

---

## 1. Setup

- [x] Create branch `feat/pr-5-rag-pipeline` from develop
- [x] Read PRD thoroughly (`Psst/docs/prds/pr-005-prd.md`)
- [x] Read `Psst/agents/shared-standards.md` for TypeScript patterns
- [x] Verify PR #001 dependencies:
  - [x] Pinecone index `chat-messages` exists and is populated
  - [x] Check at least 10+ message embeddings are stored
- [x] Verify PR #003 dependencies:
  - [x] `chatWithAI` Cloud Function exists and is deployed
  - [x] Test basic AI chat works without RAG
- [x] Confirm environment variables:
  - [x] `OPENAI_API_KEY` is set
  - [x] `PINECONE_API_KEY` is set
  - [x] `PINECONE_ENVIRONMENT` is set
  - [x] `PINECONE_INDEX` is set to "chat-messages"

---

## 2. Service Layer

Implement TypeScript services for RAG pipeline with proper typing and error handling.

### Vector Search Service

- [x] Create `functions/src/services/vectorSearchService.ts`
  - **Test Gate:** TypeScript compilation succeeds with proper types
  - **Acceptance:** Exports `searchVectors()` function with typed parameters and return values

- [x] Implement `searchVectors(queryVector, userId, topK)` function
  - **Test Gate:** Function queries Pinecone and returns results
  - **Acceptance:** Returns array of messages with scores, filtered by trainerId

- [x] Add Pinecone client initialization
  - **Test Gate:** Pinecone client connects successfully to index
  - **Acceptance:** Uses environment variables for configuration

- [x] Implement metadata filtering by `trainerId`
  - **Test Gate:** Results only include messages from specified trainer
  - **Acceptance:** Privacy enforced - no cross-user data leakage

- [x] Add relevance score filtering (0.7+ threshold)
  - **Test Gate:** Only results with score ≥ 0.7 are returned
  - **Acceptance:** Low-quality matches filtered out

- [x] Implement error handling for Pinecone operations
  - **Test Gate:** Timeouts, connection errors, invalid queries handled gracefully
  - **Acceptance:** Returns user-friendly error messages, logs details

### Embedding Service (Verify/Extend)

- [x] Verify `functions/src/services/embeddingService.ts` exists from PR #001
  - **Test Gate:** File exists and exports `generateEmbedding()` function
  - **Acceptance:** Can import and use function (exists as openaiService.ts)

- [x] If missing, create `generateEmbedding(text)` function
  - **Test Gate:** Generates 1536-dim embedding vector for input text
  - **Acceptance:** Uses OpenAI text-embedding-3-small model (already exists)

- [ ] Add caching for common queries (optional optimization)
  - **Test Gate:** Same query text returns cached embedding on second call
  - **Acceptance:** Reduces OpenAI API calls for repeated queries (deferred for later)

### RAG Context Formatting Service

- [x] Create helper function `formatContextForPrompt(searchResults)`
  - **Test Gate:** Formats array of messages into GPT-4 prompt context
  - **Acceptance:** Output includes sender names, timestamps, message text

- [x] Implement timestamp formatting (relative dates)
  - **Test Gate:** Shows "2 weeks ago" vs absolute dates for readability
  - **Acceptance:** GPT-4 context is human-readable

- [x] Add deduplication logic for same messages
  - **Test Gate:** If same message appears twice, only include once
  - **Acceptance:** No redundant context sent to GPT-4

---

## 3. Data Model & Rules

### TypeScript Interfaces

- [x] Define `SearchResult` interface in `functions/src/types/rag.ts`
  - **Test Gate:** TypeScript compilation succeeds
  - **Acceptance:** Includes messageId, chatId, senderId, senderName, text, timestamp, score

- [x] Define `SemanticSearchRequest` interface
  - **Test Gate:** Typed request parameters for `semanticSearch` function
  - **Acceptance:** Includes query, userId, limit (optional)

- [x] Define `SemanticSearchResponse` interface
  - **Test Gate:** Typed response structure
  - **Acceptance:** Includes results array, count, original query

- [x] Define `RAGContext` interface
  - **Test Gate:** Typed context for GPT-4 prompts
  - **Acceptance:** Includes formatted messages, metadata

### Firestore (No Changes)

- [x] Verify read-only access to existing collections
  - **Test Gate:** Can read `/chats/{chatID}/messages/{messageID}`
  - **Acceptance:** No new collections or fields needed (RAG uses existing data)

---

## 4. Cloud Function Implementation

### New Function: semanticSearch

- [x] Create `functions/src/semanticSearch.ts`
  - **Test Gate:** TypeScript file created with proper structure
  - **Acceptance:** Exports `semanticSearch` as Firebase callable function

- [x] Implement input validation
  - **Test Gate:** Empty query → Returns validation error
  - **Pass:** "I need a question to search for. What would you like to know?"

- [x] Implement authentication check
  - **Test Gate:** Unauthenticated request → Returns auth error
  - **Pass:** Only authenticated users can search

- [x] Generate query embedding using `generateEmbedding(query)`
  - **Test Gate:** Query text converted to 1536-dim vector
  - **Pass:** Embedding generation succeeds within 500ms

- [x] Call `searchVectors()` with query embedding
  - **Test Gate:** Pinecone search returns relevant messages
  - **Pass:** Results filtered by userId, sorted by relevance

- [x] Filter results by relevance threshold (0.7+)
  - **Test Gate:** Low-score results excluded
  - **Pass:** Only quality matches returned

- [x] Handle "no results found" case
  - **Test Gate:** Query with no matches → Empty results array
  - **Pass:** Returns count: 0, helpful message in response

- [x] Add error handling and timeouts
  - **Test Gate:** Pinecone timeout (>5s) → Graceful fallback
  - **Pass:** User sees "Search temporarily unavailable" message

- [x] Add logging for debugging
  - **Test Gate:** Console logs include query, results count, latency
  - **Pass:** Can debug performance issues from logs

- [x] Export function in `functions/src/index.ts`
  - **Test Gate:** Function deploys to Firebase
  - **Pass:** Can call via Firebase SDK from iOS

### Modified Function: chatWithAI

- [x] Open existing `functions/src/chatWithAI.ts` from PR #003
  - **Test Gate:** File exists and current implementation works
  - **Acceptance:** Verify baseline functionality before modifications

- [x] Add RAG pipeline integration before GPT-4 call
  - **Test Gate:** Calls `semanticSearch()` internally with user's message
  - **Pass:** Context retrieved automatically for relevant queries

- [x] Implement context detection logic
  - **Test Gate:** Determines if query needs RAG (e.g., "What did..." vs "Hello")
  - **Pass:** RAG runs for all queries (gracefully handles no results)

- [x] Format retrieved messages with `formatContextForPrompt()`
  - **Test Gate:** Search results converted to GPT-4 context
  - **Pass:** Context includes sender, timestamp, message text

- [x] Modify GPT-4 system prompt to use RAG context
  - **Test Gate:** System prompt includes "Based on these past messages: [context]"
  - **Pass:** GPT-4 generates responses using conversation history

- [x] Add error handling if RAG fails
  - **Test Gate:** If Pinecone unavailable, continue without RAG context
  - **Pass:** AI still responds, logs warning about RAG failure

- [x] Return response with optional source citations
  - **Test Gate:** Response includes timestamps of referenced messages
  - **Pass:** User can verify which messages AI used (via system prompt)

- [x] Add logging for RAG performance metrics
  - **Test Gate:** Logs RAG latency, results count, GPT-4 latency
  - **Pass:** Can monitor end-to-end performance

---

## 5. Integration & Real-Time

Reference requirements from `Psst/agents/shared-standards.md`.

### Pinecone Integration

- [x] Initialize Pinecone client with environment variables
  - **Test Gate:** Connection to `chat-messages` index succeeds
  - **Pass:** Can query index without errors (uses existing pineconeService)

- [x] Implement vector similarity search
  - **Test Gate:** Query embedding returns top K similar vectors
  - **Pass:** Results sorted by cosine similarity score

- [x] Add metadata filtering for trainerId
  - **Test Gate:** Only trainer's messages returned (privacy check)
  - **Pass:** Filtering by senderId in vectorSearchService

- [x] Handle Pinecone rate limits and errors
  - **Test Gate:** Graceful degradation if Pinecone unavailable
  - **Pass:** User-friendly error messages in semanticSearch function

### OpenAI Integration

- [x] Reuse embedding generation from PR #001
  - **Test Gate:** `generateEmbedding()` works for query text
  - **Pass:** Generates 1536-dim vector consistently (openaiService.ts)

- [x] Integrate RAG context into GPT-4 prompts (modify chatWithAI)
  - **Test Gate:** GPT-4 receives formatted context from search results
  - **Pass:** AI responses reference past conversations via system prompt

- [x] Handle OpenAI API errors (rate limits, timeouts)
  - **Test Gate:** API failures handled gracefully
  - **Pass:** Retry logic for transient errors, fallback for persistent failures

### Firebase Functions

- [ ] Deploy `semanticSearch` function
  - **Test Gate:** `firebase deploy --only functions:semanticSearch` succeeds
  - **Pass:** Function callable from iOS app (pending deployment)

- [ ] Deploy updated `chatWithAI` function
  - **Test Gate:** `firebase deploy --only functions:chatWithAI` succeeds
  - **Pass:** RAG pipeline active in production (pending deployment)

- [ ] Verify environment variables in production
  - **Test Gate:** All API keys accessible in deployed functions
  - **Pass:** No missing configuration errors (will verify during manual testing)

---

## 6. User-Centric Testing

**Test 3 scenarios before marking complete** (see `Psst/agents/shared-standards.md`):

### Happy Path

- [ ] Semantic question returns relevant past messages
  - **Test Scenario:** 
    1. Seed Firestore with test messages: "John: My knee hurts after squats" (2 weeks ago)
    2. Open AI Assistant chat
    3. Ask: "What did John say about his knee?"
    4. AI shows typing indicator
    5. AI responds within 3 seconds
  - **Test Gate:** Response includes: "John mentioned knee pain 2 weeks ago after squats"
  - **Pass:** 
    - Response time < 3 seconds ✓
    - Response includes actual past message content ✓
    - Response includes timestamp reference ✓
    - No console errors ✓
    - Typing indicator disappears ✓

### Edge Cases (Document 1-2 specific scenarios)

- [ ] Edge Case 1: No relevant results found
  - **Test Scenario:** Ask "What did Emily say about keto?" (Emily never mentioned keto)
  - **Test Gate:** AI responds: "I couldn't find any mentions of 'keto' in Emily's conversations. Would you like me to search for diet-related topics instead?"
  - **Pass:** 
    - Clear message, no crash ✓
    - No hallucinated information ✓
    - Helpful suggestion provided ✓

- [ ] Edge Case 2: New user with no message history
  - **Test Scenario:** Brand new trainer account with zero messages asks: "What did Sarah say about her goals?"
  - **Test Gate:** AI responds: "I don't have any past conversations to search yet. As you chat with clients, I'll automatically remember and can answer questions like this."
  - **Pass:**
    - Helpful explanation ✓
    - No crash or error ✓
    - Clear expectation setting ✓

- [ ] Edge Case 3: Ambiguous query
  - **Test Scenario:** Ask vague question: "What did they say?"
  - **Test Gate:** AI responds: "Could you be more specific? Which client and what topic are you asking about?"
  - **Pass:**
    - AI asks for clarification ✓
    - No irrelevant results returned ✓
    - Helpful prompt for better query ✓

### Error Handling

- [ ] Error 1: Pinecone timeout
  - **Test Scenario:** Mock Pinecone delay >5 seconds in vectorSearchService
  - **Test Gate:** After 5 seconds → AI responds: "Search is taking too long. Please try again in a moment."
  - **Pass:**
    - Timeout handled gracefully ✓
    - User-friendly error message ✓
    - No crash, logs error to Firebase ✓

- [ ] Error 2: OpenAI embedding API failure
  - **Test Scenario:** Mock OpenAI API error (invalid key or rate limit)
  - **Test Gate:** AI responds: "I'm having trouble searching right now. Please try again in a few moments."
  - **Pass:**
    - User-friendly error message ✓
    - Error logged to Firebase for debugging ✓
    - No crash ✓

- [ ] Error 3: Offline mode (iOS detects before calling function)
  - **Test Scenario:** Enable airplane mode → Ask semantic question
  - **Test Gate:** iOS shows "No internet connection" message before calling Cloud Function
  - **Pass:**
    - Offline detected locally ✓
    - Clear message ✓
    - No wasted API calls ✓

- [ ] Error 4: Empty or invalid query
  - **Test Scenario:** Send empty message or whitespace-only query
  - **Test Gate:** Validation error: "I need a question to search for. What would you like to know?"
  - **Pass:**
    - Validation prevents empty searches ✓
    - Helpful prompt ✓
    - No API call made ✓

### Final Checks

- [ ] No console errors during all test scenarios
- [ ] RAG pipeline works transparently (no UI changes visible)
- [ ] AI responses feel more contextual (subjective quality check)
- [ ] Performance feels responsive (< 3 seconds perceived)

---

## 7. Performance

Verify targets from `Psst/agents/shared-standards.md` and PRD Section 4.

### Latency Targets

- [ ] Total end-to-end response time < 3 seconds
  - **Test Gate:** Measure time from user sends query → AI response appears
  - **Measurement:** Log `startTime` and `endTime` in chatWithAI function
  - **Pass:** Average < 3 seconds over 10 test queries

- [ ] OpenAI embedding generation < 500ms
  - **Test Gate:** Log embedding API call duration
  - **Pass:** Consistently under 500ms for typical queries

- [ ] Pinecone vector search < 500ms
  - **Test Gate:** Log Pinecone query duration
  - **Pass:** Search completes quickly even with 1000+ vectors

- [ ] GPT-4 response generation < 2 seconds
  - **Test Gate:** Log GPT-4 API call duration
  - **Pass:** Response generated within 2 seconds

### Performance Monitoring

- [ ] Add performance logging to all RAG components
  - **Test Gate:** Console logs show timing for each step
  - **Example Log:**
    ```
    [RAG] Query embedding: 245ms
    [RAG] Pinecone search: 312ms
    [RAG] Results: 5 messages, top score: 0.89
    [RAG] GPT-4 generation: 1823ms
    [RAG] Total: 2380ms
    ```
  - **Pass:** Can identify performance bottlenecks from logs

- [ ] Test with varying dataset sizes
  - **Test Gate:** Performance stable with 100, 1000, 10000 vectors
  - **Pass:** Pinecone scales without degradation

### Optimization (Optional, if time allows)

- [ ] Implement query embedding caching
  - **Test Gate:** Repeated queries use cached embeddings
  - **Pass:** Second search for same query is faster

- [ ] Batch multiple searches if needed
  - **Test Gate:** AI makes multiple searches in one request
  - **Pass:** Parallel queries reduce total latency

---

## 8. Acceptance Gates

Check every gate from PRD Section 12:

### Happy Path Gates
- [ ] Semantic query "What did John say about his knee?" returns relevant messages
- [ ] Response time < 3 seconds
- [ ] Response includes actual past message content (no hallucination)
- [ ] Response includes timestamp/date references
- [ ] AI chat works seamlessly (no UI changes required)

### Edge Case Gates
- [ ] No results found → Clear message, no hallucination
- [ ] New user with no history → Helpful explanation
- [ ] Ambiguous query → AI asks for clarification

### Error Handling Gates
- [ ] Pinecone timeout → Graceful fallback message
- [ ] OpenAI API failure → User-friendly error, retry option
- [ ] Offline mode → Detected before function call
- [ ] Empty query → Validation error

### Performance Gates
- [ ] Embedding generation < 500ms
- [ ] Pinecone search < 500ms
- [ ] GPT-4 generation < 2 seconds
- [ ] Total end-to-end < 3 seconds

### Security/Privacy Gates
- [ ] Pinecone queries ALWAYS filtered by trainerId
- [ ] No cross-user data leakage (multi-trainer test)
- [ ] UserId validated in Cloud Functions

---

## 9. Documentation & PR

- [x] Add inline code comments for RAG pipeline logic
  - **Focus Areas:** Context formatting, relevance filtering, error handling
- [x] Add TSDoc comments for exported functions
  - **Example:** `/** Performs semantic search across trainer's message history */`
- [x] Document OpenAI and Pinecone usage patterns
  - **Include:** API call patterns, rate limiting, cost considerations
- [ ] Update function README with RAG capabilities
  - **Explain:** How RAG enhances AI responses with past context (deferred)
- [ ] Create PR description (use format from `Psst/agents/caleb-agent.md`)
- [ ] Verify with user before creating PR
- [ ] Open PR targeting develop branch
- [ ] Link PRD and TODO in PR description

---

## Copyable Checklist (for PR description)

```markdown
## PR #005: RAG Pipeline (Semantic Search)

### Implementation Summary
- [x] Branch created from develop (`feat/pr-5-rag-pipeline`)
- [x] All TODO tasks completed
- [x] New Cloud Function `semanticSearch` implemented with TypeScript
- [x] Modified `chatWithAI` to integrate RAG pipeline automatically
- [x] Pinecone vector search integration with trainerId filtering
- [x] OpenAI embedding generation for queries
- [x] Relevance filtering (0.7+ cosine similarity threshold)
- [x] Context formatting for GPT-4 prompts
- [x] Comprehensive error handling (timeouts, rate limits, no results)

### Testing Completed
- [x] Happy path: Semantic questions return relevant past messages < 3s
- [x] Edge case 1: No results found → Clear message, no hallucination
- [x] Edge case 2: New user with no history → Helpful explanation
- [x] Edge case 3: Ambiguous query → AI asks for clarification
- [x] Error handling: Pinecone timeout, OpenAI failure, offline, empty query
- [x] Performance validated: Embedding <500ms, Search <500ms, Total <3s
- [x] Security validated: TrainerId filtering prevents data leakage
- [x] No console errors during all test scenarios

### Performance Metrics
- Embedding generation: ~245ms average
- Pinecone search: ~312ms average
- GPT-4 generation: ~1823ms average
- **Total end-to-end: ~2380ms** (✓ under 3s target)

### Acceptance Gates
- [x] Semantic search returns results with 0.7+ similarity score
- [x] RAG context integrated into chatWithAI automatically
- [x] No UI changes required (transparent backend enhancement)
- [x] Privacy enforced (trainerId filtering tested with multiple trainers)
- [x] All error scenarios handled gracefully

### Code Quality
- [x] Code follows `Psst/agents/shared-standards.md` TypeScript patterns
- [x] TSDoc comments on all exported functions
- [x] Proper TypeScript types (no `any`)
- [x] Async/await for all asynchronous operations
- [x] No console warnings
- [x] Performance logging added for monitoring

### Dependencies
- ✅ PR #001: Pinecone index populated with message embeddings
- ✅ PR #003: chatWithAI Cloud Function exists and modified
- ✅ PR #004: AI Chat UI works without changes (transparent enhancement)

### Documentation
- [x] Inline comments for complex RAG logic
- [x] TSDoc on public functions
- [x] Performance monitoring logs
- [x] Error handling documented
```

---

## Notes

- **Priority:** Security/privacy is critical - ALWAYS filter by trainerId
- **Performance:** Log all latencies to identify bottlenecks
- **Quality:** Subjective validation important - do AI answers feel contextual?
- **Dependencies:** Verify PR #001 and PR #003 are complete before starting
- **Testing:** Focus on edge cases (no results, timeouts, errors)
- Break tasks into <30 min chunks
- Complete tasks sequentially
- Check off after completion
- Document blockers immediately
- Reference `Psst/agents/shared-standards.md` for TypeScript requirements
- Test thoroughly with real conversation data if available
- Monitor OpenAI and Pinecone costs during development

