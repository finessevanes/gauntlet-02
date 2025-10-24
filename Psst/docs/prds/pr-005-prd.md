# PRD: RAG Pipeline (Semantic Search)

**Feature**: RAG Pipeline - Enable AI to search past conversations and provide context-aware answers

**Version**: 1.0

**Status**: Draft

**Agent**: Caleb

**Target Release**: Phase 3 - RAG + Contextual Intelligence

**Links**: [PR Brief #005](../ai-briefs.md) | [TODO](../todos/pr-005-todo.md)

---

## 1. Summary

Implement Retrieval Augmented Generation (RAG) to transform the AI Assistant from a simple chatbot into a "second brain" that remembers everything clients have said. The AI can now semantically search past conversations and answer questions like "What did Sarah say about her diet?" with instant, context-aware responses.

---

## 2. Problem & Goals

**What user problem are we solving?**

Personal trainers manage 20-30+ clients with hundreds of messages daily. Important context gets buried - injury warnings, dietary restrictions, goals, equipment availability, travel schedules. Result: Trainers give generic advice, clients feel unheard, important details fall through the cracks.

**Why now?**

This builds on the foundation from PR #001 (AI Backend Infrastructure with Pinecone) and PR #003 (AI Chat Backend). The embedding pipeline is ready; now we connect it to the AI's intelligence to enable semantic search.

**Goals (ordered, measurable):**

- [X] G1 — AI can semantically search all past conversations and return relevant messages within 2 seconds
- [X] G2 — AI provides context-aware answers using retrieved conversation history (vs. generic responses)
- [X] G3 — Trainers can ask natural language questions about client history and get accurate answers

---

## 3. Non-Goals / Out of Scope

Call out what's intentionally excluded to avoid scope creep.

- [ ] **Not** building UI for visualizing search results (handled in PR #004 AI Chat UI - already built)
- [ ] **Not** implementing manual search interface (AI handles semantic search automatically)
- [ ] **Not** building client profile extraction (that's PR #007 - Contextual Intelligence)
- [ ] **Not** implementing proactive suggestions (that's PR #009 - Proactive Assistant)
- [ ] **Not** adding voice interface (that's PR #010 - Voice AI Interface)

---

## 4. Success Metrics

**User-visible:**
- Time for AI to answer context-based question: < 3 seconds (query → RAG search → GPT-4 → response)
- AI answer accuracy: Subjective validation (does the answer include relevant past messages?)
- Trainer workflow: Ask question in natural language → Get answer with context (0 manual searching)

**System:**
- Vector search latency: < 500ms per Pinecone query
- Relevance scoring threshold: 0.7+ cosine similarity for returned messages
- Context window: Top 5-10 most relevant messages sent to GPT-4

**Quality:**
- 0 blocking bugs in RAG pipeline
- All acceptance gates pass
- Graceful degradation if Pinecone unavailable (AI says "Search temporarily unavailable")
- Crash-free rate >99%

---

## 5. Users & Stories

**Primary User: Alex (The Adaptive Trainer)**

As Alex, I want to ask "What did Sarah say about her knee?" and get instant answers from past conversations, so I can provide personalized coaching without manually searching hundreds of messages.

**Primary User: Marcus (The Remote Worker Trainer)**

As Marcus, I want the AI to remember what leads have said in previous messages, so it can qualify them intelligently and book intro calls with full context.

**Edge Case User:**

As a new trainer with no message history, I want the AI to explain that no past conversations exist yet, so I understand why context isn't available.

---

## 6. Experience Specification (UX)

### Entry Points and Flows

**Entry Point:** AI Assistant chat (floating 🤖 button from ChatListView)

**Flow 1: Semantic Question**
1. Trainer opens AI Assistant chat
2. Trainer asks: "What did John say about his shoulder pain?"
3. AI shows typing indicator (3 dots animation)
4. AI searches past conversations via RAG pipeline
5. AI responds: "John mentioned shoulder pain 2 weeks ago during bench press. He said it's a sharp pain during overhead movements. (See message from Oct 10)"
6. Response appears in chat bubble (gray background for AI messages)

**Flow 2: No Results Found**
1. Trainer asks: "What did Emily say about keto?"
2. AI searches, finds no relevant messages
3. AI responds: "I couldn't find any mentions of 'keto' in Emily's conversations. Would you like me to search for diet-related topics instead?"

**Flow 3: New User (No History)**
1. Trainer asks: "What did Sarah say about her goals?"
2. AI detects no message history exists yet
3. AI responds: "I don't have any past conversations to search yet. As you chat with clients, I'll automatically remember and can answer questions like this."

### Visual Behavior

- **Loading State:** Typing indicator (animated dots) while AI searches and generates response
- **AI Message Styling:** Gray background bubble (vs. blue for user messages), robot icon avatar
- **Inline Context References:** AI responses include timestamps/dates for referenced messages
- **Error State:** If Pinecone fails → Red banner: "Search temporarily unavailable. Try again in a moment."

### Performance Targets

See `Psst/agents/shared-standards.md`:
- Total response time: < 3 seconds (query → search → GPT-4 → response)
- Vector search: < 500ms
- GPT-4 generation: < 2 seconds
- No UI blocking during search

---

## 7. Functional Requirements (Must/Should)

### MUST Requirements

**MUST #1: Semantic Search Cloud Function**
- Create `semanticSearch` Cloud Function that accepts query, userId, and optional limit
- Generate embedding for query using OpenAI text-embedding-3-small
- Query Pinecone vector database with cosine similarity
- Filter results by userId (trainers only see their conversations)
- Return top 5-10 most relevant messages with scores 0.7+
- Handle timeouts (5 second max), rate limits, and empty results

[Gate] Query "shoulder pain" → Returns messages containing "hurt shoulder", "rotator cuff", "overhead press injury" (semantic similarity, not exact match)

**MUST #2: RAG Integration in chatWithAI**
- Modify existing `chatWithAI` Cloud Function to use RAG pipeline
- Before calling GPT-4: Execute semantic search for relevant context
- Format retrieved messages for GPT-4 prompt (sender, timestamp, text)
- Include context in system prompt: "Based on these past messages: [context]"
- GPT-4 generates response using conversation history
- Return AI response to iOS app with citations (timestamps)

[Gate] AI Chat Assistant uses RAG automatically for contextual questions

**MUST #3: Relevance Scoring & Filtering**
- Only include messages with cosine similarity score ≥ 0.7
- Sort results by score (highest first)
- Limit to top 10 messages max (avoid token limit for GPT-4)
- Deduplicate if same message appears multiple times
- Include metadata: sender name, chat ID, timestamp

[Gate] AI doesn't hallucinate - only uses actual past messages with sufficient relevance

**MUST #4: Error Handling**
- Handle Pinecone timeout (> 5 seconds) → Fallback: "Search unavailable, try again"
- Handle no results found → AI says "No relevant conversations found"
- Handle OpenAI embedding failure → Retry once, then fail gracefully
- Handle rate limit errors → User-friendly message with wait time
- Log all errors to Firebase for debugging

[Gate] Offline mode or Pinecone down → AI says "Search temporarily unavailable" (doesn't crash)

### SHOULD Requirements

**SHOULD #1: Query Optimization**
- Cache embeddings for common queries ("injuries", "diet", "goals")
- Batch multiple searches if AI needs to look up multiple topics
- Use metadata filtering in Pinecone (filter by chat ID if known)

**SHOULD #2: Context Formatting**
- Format retrieved messages clearly for GPT-4:
  ```
  Past conversations:
  - [Oct 10, 2025] John: "My shoulder hurts during bench press"
  - [Oct 8, 2025] John: "Sharp pain overhead movements"
  ```
- Include sender names for group chats
- Show relative dates ("2 weeks ago" vs "Oct 10")

---

## 8. Data Model

### Pinecone Vector Index (Existing from PR #001)

**Index Name:** `chat-messages`  
**Dimensions:** 1536 (OpenAI text-embedding-3-small)  
**Metric:** Cosine similarity  

**Vector Metadata Structure:**
```typescript
{
  id: messageId,  // Pinecone vector ID (same as Firestore message ID)
  values: [0.123, -0.456, ...],  // 1536-dim embedding vector
  metadata: {
    firestoreMessageId: "msg_abc123",
    firestoreChatId: "chat_xyz789",
    trainerId: "user_123",           // CRITICAL: Filter by this
    senderId: "user_456",
    senderName: "John Doe",
    text: "My knee hurts after squats",
    timestamp: 1729789200000,        // Unix timestamp (ms)
    isGroupChat: false
  }
}
```

**Query Example:**
```typescript
const results = await pineconeIndex.query({
  vector: queryEmbedding,      // [1536 dimensions]
  topK: 10,                     // Return top 10 results
  filter: {
    trainerId: { $eq: "user_123" }  // Only trainer's conversations
  },
  includeMetadata: true
});
```

### Firestore (No Changes)

Reads from existing collections (read-only):
- `/chats/{chatID}/messages/{messageID}` - Message text already embedded in Pinecone
- `/users/{userID}` - For sender name lookups (if needed)

### Cloud Function Request/Response

**Request to `semanticSearch`:**
```typescript
{
  query: string,        // "What did John say about his knee?"
  userId: string,       // Trainer's user ID (for filtering)
  limit?: number        // Optional, default 10
}
```

**Response from `semanticSearch`:**
```typescript
{
  results: [
    {
      messageId: "msg_abc123",
      chatId: "chat_xyz789",
      senderId: "user_456",
      senderName: "John Doe",
      text: "My knee hurts after squats",
      timestamp: 1729789200000,
      score: 0.89             // Cosine similarity
    },
    // ... more results
  ],
  count: 5,                   // Number of results
  query: "knee pain"          // Original query
}
```

---

## 9. API / Service Contracts

### Cloud Functions (TypeScript)

**New Function: `semanticSearch`**

```typescript
/**
 * Performs semantic search across trainer's message history
 * @param query - Natural language search query
 * @param userId - Trainer's user ID (for filtering)
 * @param limit - Max results to return (default 10)
 * @returns Array of relevant messages with similarity scores
 */
export const semanticSearch = onCall(async (request) => {
  const { query, userId, limit = 10 } = request.data;
  
  // 1. Generate embedding for query
  const queryEmbedding = await generateEmbedding(query);
  
  // 2. Search Pinecone
  const results = await searchVectors(queryEmbedding, userId, limit);
  
  // 3. Filter by relevance threshold (0.7+)
  const relevantResults = results.filter(r => r.score >= 0.7);
  
  return { results: relevantResults, count: relevantResults.length, query };
});
```

**Modified Function: `chatWithAI` (from PR #003)**

```typescript
/**
 * AI chat endpoint with RAG integration
 * @param message - User's message to AI
 * @param userId - Trainer's user ID
 * @param conversationId - Optional conversation ID for context
 */
export const chatWithAI = onCall(async (request) => {
  const { message, userId, conversationId } = request.data;
  
  // NEW: Perform semantic search for context
  const searchResults = await semanticSearch({ 
    query: message, 
    userId, 
    limit: 10 
  });
  
  // Format context for GPT-4 prompt
  const context = formatContextForPrompt(searchResults.results);
  
  // Generate AI response with context
  const response = await generateAIResponse(message, context, userId);
  
  return { response, sources: searchResults.results };
});
```

**Helper: `generateEmbedding` (Reuse from PR #001)**

```typescript
/**
 * Generate embedding vector for text using OpenAI
 * @param text - Text to embed
 * @returns 1536-dimensional embedding vector
 */
async function generateEmbedding(text: string): Promise<number[]> {
  const response = await openai.embeddings.create({
    model: "text-embedding-3-small",
    input: text
  });
  return response.data[0].embedding;
}
```

**Helper: `searchVectors` (New)**

```typescript
/**
 * Search Pinecone for similar message vectors
 * @param queryVector - 1536-dim embedding vector
 * @param userId - Trainer's user ID (for filtering)
 * @param topK - Number of results to return
 */
async function searchVectors(
  queryVector: number[], 
  userId: string, 
  topK: number
): Promise<SearchResult[]> {
  const pinecone = new PineconeClient();
  const index = pinecone.Index("chat-messages");
  
  const results = await index.query({
    vector: queryVector,
    topK,
    filter: { trainerId: { $eq: userId } },
    includeMetadata: true
  });
  
  return results.matches.map(match => ({
    messageId: match.id,
    chatId: match.metadata.firestoreChatId,
    senderId: match.metadata.senderId,
    senderName: match.metadata.senderName,
    text: match.metadata.text,
    timestamp: match.metadata.timestamp,
    score: match.score
  }));
}
```

### iOS Service Layer (No Changes)

AIService.swift already exists from PR #004. No changes needed - it calls Cloud Functions generically.

---

## 10. UI Components to Create/Modify

### No UI Changes Required

All UI already exists from PR #004 (AI Chat UI). RAG pipeline works transparently behind the scenes.

**Existing Components (No Modifications):**
- `Views/AI/AIAssistantView.swift` - AI chat interface (already displays responses)
- `ViewModels/AIAssistantViewModel.swift` - Manages AI chat state
- `Services/AIService.swift` - Calls Cloud Functions (generic, works with RAG responses)

**User Experience:** Trainer asks question → AI uses RAG automatically → Response appears in chat. No visible change to UI, just smarter answers.

---

## 11. Integration Points

**Primary Integrations:**

1. **Pinecone Vector Database**
   - Query existing embeddings created by PR #001's auto-embedding pipeline
   - Use cosine similarity search
   - Filter by `trainerId` metadata

2. **OpenAI API**
   - Generate query embeddings (text-embedding-3-small)
   - GPT-4 response generation with RAG context (existing from PR #003)

3. **Firebase Firestore (Read-Only)**
   - No writes required
   - Optional: Fetch additional message details if needed

4. **Cloud Functions**
   - Modify existing `chatWithAI` function
   - Create new `semanticSearch` function

5. **iOS AIService**
   - No changes - already calls Cloud Functions generically

---

## 12. Testing Plan & Acceptance Gates

**Define these 3 scenarios BEFORE implementation.**

See `Psst/docs/testing-strategy.md` for detailed guidance.

---

### Happy Path

**Scenario:** Trainer asks semantic question about client history

- [ ] **Steps:**
  1. Open AI Assistant chat
  2. Type: "What did John say about his knee?"
  3. Tap send
  4. AI shows typing indicator
  5. AI responds with relevant past messages and answer

- [ ] **Gate:** AI returns response within 3 seconds with relevant past messages (e.g., "John mentioned knee pain 2 weeks ago during squats")

- [ ] **Pass Criteria:** 
  - Response time < 3 seconds
  - Response includes actual past message content
  - Response includes timestamp/date reference
  - No console errors
  - Typing indicator disappears when complete

---

### Edge Cases

**Edge Case 1: No Relevant Results Found**

- [ ] **Test:** Ask about topic that doesn't exist in conversation history
  - Example: "What did Sarah say about marathon training?" (Sarah never mentioned marathons)

- [ ] **Expected:** AI responds: "I couldn't find any mentions of 'marathon training' in Sarah's conversations. Would you like me to search for related topics?"

- [ ] **Pass:** Clear message, no crash, no hallucinated information

**Edge Case 2: New User with No Message History**

- [ ] **Test:** Brand new trainer with zero messages asks semantic question

- [ ] **Expected:** AI responds: "I don't have any past conversations to search yet. As you chat with clients, I'll automatically remember and can answer questions like this."

- [ ] **Pass:** Helpful explanation, no crash, clear next steps

**Edge Case 3: Ambiguous Query**

- [ ] **Test:** Ask vague question: "What did they say?"

- [ ] **Expected:** AI responds: "Could you be more specific? Which client and what topic are you asking about?"

- [ ] **Pass:** AI asks for clarification instead of returning irrelevant results

---

### Error Handling

**Error 1: Pinecone Timeout**

- [ ] **Test:** Simulate Pinecone timeout (mock 6-second delay in Cloud Function)

- [ ] **Expected:** After 5 seconds → AI responds: "Search is taking too long. Please try again in a moment."

- [ ] **Pass:** Timeout handled gracefully, retry option provided, no crash

**Error 2: OpenAI Embedding Failure**

- [ ] **Test:** Simulate OpenAI API error (invalid API key or rate limit)

- [ ] **Expected:** AI responds: "I'm having trouble searching right now. Please try again in a few moments."

- [ ] **Pass:** User-friendly error message, logs error to Firebase for debugging

**Error 3: Offline Mode**

- [ ] **Test:** Enable airplane mode → Ask semantic question

- [ ] **Expected:** iOS shows "No internet connection" message before calling Cloud Function

- [ ] **Pass:** Offline detected, clear message, no wasted API calls

**Error 4: Invalid Query (Empty)**

- [ ] **Test:** Send empty message or whitespace-only query

- [ ] **Expected:** AI responds: "I need a question to search for. What would you like to know?"

- [ ] **Pass:** Validation prevents empty searches, helpful prompt

---

### Performance Check

**Subjective Check:**

- [ ] AI responses feel fast (< 3 seconds perceived)
- [ ] No UI freezing during search
- [ ] Smooth typing indicator animation
- [ ] No noticeable lag between sending query and seeing typing indicator

**Objective Metrics (Log to Console):**

- [ ] Embedding generation: < 500ms
- [ ] Pinecone vector search: < 500ms
- [ ] GPT-4 response generation: < 2 seconds
- [ ] Total end-to-end: < 3 seconds

**If Performance is Slow:**
- Check Pinecone index latency
- Reduce topK (number of results returned)
- Cache common query embeddings
- Optimize GPT-4 prompt length

---

## 13. Definition of Done

**Backend:**
- [ ] `semanticSearch` Cloud Function implemented with TypeScript
- [ ] `chatWithAI` modified to use RAG pipeline automatically
- [ ] Pinecone integration tested (query, filter, relevance scoring)
- [ ] OpenAI embedding generation working for queries
- [ ] Error handling for timeouts, rate limits, no results, invalid input
- [ ] Logging added for debugging (query, results count, latency)

**Testing:**
- [ ] All acceptance gates pass (happy path, edge cases, errors)
- [ ] Manual testing completed:
  - [ ] Ask semantic questions with relevant results
  - [ ] Ask questions with no results
  - [ ] Test with new user (no history)
  - [ ] Test Pinecone timeout handling
  - [ ] Test offline behavior
- [ ] Performance validated (< 3 seconds end-to-end)
- [ ] No console errors during all test scenarios

**Integration:**
- [ ] RAG works seamlessly in AI Assistant chat (no UI changes needed)
- [ ] Results filtered by trainer (no cross-user data leakage)
- [ ] Relevance threshold (0.7+) enforced
- [ ] AI responses include timestamps/citations for retrieved messages

**Documentation:**
- [ ] Code comments added for complex RAG logic
- [ ] Error handling documented
- [ ] Performance metrics logged

---

## 14. Risks & Mitigations

**Risk 1: Pinecone Latency Too High**
- **Mitigation:** Set aggressive timeout (5 seconds), cache common queries, reduce topK if needed
- **Fallback:** If search times out, AI responds without RAG context (generic answer + "Search unavailable")

**Risk 2: Irrelevant Search Results (Low Quality)**
- **Mitigation:** Enforce 0.7+ similarity threshold, limit to top 10 results, allow AI to say "no relevant results"
- **Validation:** Manual testing with real trainer conversations

**Risk 3: OpenAI API Rate Limits**
- **Mitigation:** Implement exponential backoff, cache embeddings for common queries, show user-friendly message
- **Monitoring:** Log rate limit errors to Firebase

**Risk 4: Token Limit for GPT-4 (Too Much Context)**
- **Mitigation:** Limit RAG results to top 10 messages, truncate very long messages, prioritize by relevance score
- **Calculation:** 10 messages × ~100 tokens each = ~1000 tokens context (well below GPT-4's 8k limit)

**Risk 5: Privacy Leakage (Trainer Sees Other Trainers' Data)**
- **Mitigation:** ALWAYS filter Pinecone queries by `trainerId` metadata, validate userId in Cloud Functions
- **Testing:** Create multiple test trainers, verify results are isolated

---

## 15. Rollout & Telemetry

**Feature Flag:** No - RAG is transparent enhancement to existing AI Chat (PR #003)

**Manual Validation Steps:**

1. **Pre-Deployment:**
   - [ ] Test Cloud Functions locally with Firebase emulator
   - [ ] Verify Pinecone index populated with messages (from PR #001)
   - [ ] Test semantic search with sample queries

2. **Post-Deployment:**
   - [ ] Ask 5 semantic questions, verify responses use past context
   - [ ] Monitor Cloud Function logs for errors
   - [ ] Check Pinecone dashboard for query latency

**Metrics to Monitor:**

- **Usage:** Number of semantic searches per day
- **Performance:** Average RAG query latency (Pinecone + OpenAI)
- **Errors:** Pinecone timeouts, OpenAI failures, empty results rate
- **Quality:** Subjective - do AI answers feel more contextual?

**Logs to Capture:**

```typescript
logger.info("RAG Search", {
  query: query,
  userId: userId,
  resultsCount: results.length,
  latencyMs: endTime - startTime,
  topScore: results[0]?.score || 0
});
```

---

## 16. Open Questions

**Q1: Should we support multi-language queries?**
- **Decision:** No - English only for MVP. OpenAI embeddings work cross-language but quality varies. Defer to future.

**Q2: Should we cache query embeddings?**
- **Decision:** Yes for common queries ("injuries", "diet", "goals"). Implement in PR #005 if time allows, otherwise defer.

**Q3: How to handle group chats vs 1-on-1?**
- **Decision:** Search across ALL conversations (group + 1-on-1). Use metadata to show sender name in results.

**Q4: Should trainers see similarity scores?**
- **Decision:** No - internal only. Just show AI's natural language answer with timestamps.

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future PRs:

- [ ] **Manual Search UI** - Trainers manually search without AI (could be useful, but AI-first for now)
- [ ] **Search Filters** - Filter by date range, client, chat type (defer to PR #007+ if needed)
- [ ] **Search Analytics** - Dashboard showing most searched topics (not needed for MVP)
- [ ] **Multi-Language Support** - Non-English queries (future internationalization)
- [ ] **Advanced Relevance Tuning** - A/B test similarity thresholds, reranking algorithms (optimization phase)

---

## Preflight Questionnaire

**Answered to drive vertical slice and acceptance gates:**

1. **Smallest end-to-end user outcome for this PR?**
   - Trainer asks "What did [client] say about [topic]?" → AI returns answer with past message context

2. **Primary user and critical action?**
   - Alex (Adaptive Trainer) asks semantic question about client history → Gets instant answer

3. **Must-have vs nice-to-have?**
   - **Must:** Semantic search working, RAG in chatWithAI, relevance threshold, error handling
   - **Nice:** Query caching, advanced filtering, multi-language

4. **Real-time requirements?**
   - No real-time sync needed - Cloud Function request/response pattern

5. **Performance constraints?**
   - < 3 seconds total (embedding + search + GPT-4)
   - < 500ms for Pinecone query alone

6. **Error/edge cases to handle?**
   - Pinecone timeout, no results, new user, empty query, rate limits, offline

7. **Data model changes?**
   - None - reads from existing Pinecone index (PR #001) and Firestore

8. **Service APIs required?**
   - `semanticSearch` Cloud Function (new)
   - `chatWithAI` Cloud Function (modified to use RAG)

9. **UI entry points and states?**
   - No UI changes - works through existing AIAssistantView
   - States: loading (typing indicator), success (response), error (message)

10. **Security/permissions implications?**
    - CRITICAL: Filter Pinecone by `trainerId` to prevent data leakage
    - Validate userId in Cloud Functions

11. **Dependencies or blocking integrations?**
    - **BLOCKS:** PR #001 (Pinecone index must be populated)
    - **BLOCKS:** PR #003 (chatWithAI function must exist)
    - **REQUIRES:** Pinecone API key, OpenAI API key (already set up in PR #001)

12. **Rollout strategy and metrics?**
    - No feature flag - transparent enhancement
    - Monitor: query latency, error rate, results count

13. **What is explicitly out of scope?**
    - Manual search UI, client profile extraction, proactive suggestions, voice interface

---

## Authoring Notes

- RAG is the "killer feature" that makes AI useful - without it, AI can't remember client context
- This PR is backend-heavy (Cloud Functions + Pinecone integration)
- No iOS changes needed - existing UI handles RAG responses automatically
- Key success metric: Subjective quality of AI answers (do they include relevant past context?)
- Performance is critical - trainers expect instant answers (< 3 seconds)
- Privacy is paramount - ALWAYS filter by trainerId in Pinecone queries

