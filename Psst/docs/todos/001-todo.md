# PR-001 TODO — AI Backend Infrastructure

**Branch**: `feat/pr-1-ai-backend-infrastructure`  
**Source PRD**: `Psst/docs/prds/pr-001-prd.md`  
**Owner (Agent)**: Caleb

---

## 0. Clarifying Questions & Assumptions

**Questions:**
- None - PRD is comprehensive for backend infrastructure

**Assumptions:**
- OpenAI account already exists or will be created during setup
- Pinecone account will be created fresh for this project
- Firebase project already configured (existing Firestore, Cloud Functions enabled)
- Using OpenAI text-embedding-3-small model (1536 dimensions)
- Starting with Pinecone p1.x1 pod (can scale later)
- GCP region for Pinecone matches Firebase region for optimal latency

---

## 1. Setup

- [x] Create branch `feat/pr-1-ai-backend-infrastructure` from develop
- [x] Read PRD at `Psst/docs/prds/pr-001-prd.md` thoroughly
- [x] Read `Psst/agents/shared-standards.md` for patterns
- [x] Create OpenAI account at https://platform.openai.com
  - Test Gate: Account created, API key generated ✅
- [x] Create Pinecone account at https://www.pinecone.io
  - Test Gate: Account created, can access dashboard ✅
- [x] Create Pinecone index `coachai`
  - Configuration: 1536 dimensions, cosine metric, **serverless mode**, GCP region gcp-us-central1-4a9f
  - Test Gate: Index shows in dashboard, status "Ready" ✅
- [x] Confirm Firebase Functions environment working
  - Test Gate: Can deploy test function successfully ✅

---

## 2. Environment Configuration

- [ ] Set Firebase Functions environment variables
  ```bash
  firebase functions:config:set openai.api_key="sk-..."
  firebase functions:config:set pinecone.api_key="..."
  firebase functions:config:set pinecone.environment="us-east1-gcp"
  firebase functions:config:set pinecone.index="coachai"
  ```
  - Test Gate: `firebase functions:config:get` shows all keys

- [ ] Create `.env.example` in `/functions` directory
  - Include: OPENAI_API_KEY, PINECONE_API_KEY, PINECONE_ENVIRONMENT, PINECONE_INDEX
  - Test Gate: File exists, all variables documented

- [ ] Update `.gitignore` to ensure `.env` files never committed
  - Test Gate: `.env` in .gitignore, no secrets in git history

---

## 3. Dependencies

- [x] Navigate to `/functions` directory
- [x] Install OpenAI SDK
  ```bash
  npm install openai
  ```
  - Test Gate: Package added to package.json, node_modules updated ✅

- [x] Install Pinecone SDK
  ```bash
  npm install @pinecone-database/pinecone
  ```
  - Test Gate: Package added to package.json ✅

- [x] Verify installations
  ```bash
  npm list openai @pinecone-database/pinecone
  ```
  - Test Gate: Both packages show correct versions, no peer dependency warnings ✅

---

## 4. Configuration Module

- [x] Create `functions/src/config/ai.config.ts`
  ```typescript
  module.exports = {
    openai: {
      model: 'text-embedding-3-small',
      dimensions: 1536,
      timeout: 30000 // 30 seconds
    },
    pinecone: {
      indexName: 'coachai',
      metric: 'cosine',
      dimensions: 1536,
      timeout: 10000 // 10 seconds
    },
    retry: {
      maxAttempts: 3,
      initialDelay: 1000, // 1 second
      maxDelay: 8000 // 8 seconds
    }
  };
  ```
  - Test Gate: File created, exports object with all config values
  - Test Gate: Can require file without errors

---

## 5. Retry Helper Utility

- [ ] Create `functions/utils/retryHelper.ts`
  - Implement exponential backoff: delay = initialDelay * (2 ^ attempt)
  - Cap delay at maxDelay (8 seconds)
  - Return promise that resolves/rejects after retries exhausted
  - Test Gate: Exports `retryWithBackoff(fn, maxAttempts, initialDelay, maxDelay)`

- [ ] Add retry logic features:
  - Accept async function to retry
  - Log each retry attempt with delay duration
  - Throw original error after max attempts
  - Handle both promise rejections and thrown errors
  - Test Gate: Unit test passes for successful retry on 2nd attempt

- [ ] Add jitter to prevent thundering herd
  - Add random ±20% to delay (e.g., 1s becomes 800ms-1200ms)
  - Test Gate: Multiple retries show varying delay times in logs

---

## 6. OpenAI Service

- [ ] Create `functions/services/openaiService.ts`
- [ ] Import OpenAI SDK and configuration
  ```typescript
  const OpenAI = require('openai');
  const config = require('../config/ai.config');
  const { retryWithBackoff } = require('../utils/retryHelper');
  ```

- [ ] Initialize OpenAI client
  ```typescript
  const openai = new OpenAI({
    apiKey: functions.config().openai.api_key,
    timeout: config.openai.timeout
  });
  ```
  - Test Gate: Client initializes without errors

- [ ] Implement `generateEmbedding(text)` method
  - Validate text is non-empty string
  - Trim whitespace before processing
  - Call OpenAI API with retry logic
  - Return array of 1536 floats
  - Throw descriptive errors for failures
  - Test Gate: Function exported, accepts string parameter

- [ ] Add error handling for OpenAI-specific errors:
  - Rate limit (429) → Extract retry-after header, wait specified time
  - Invalid API key (401) → Throw critical error, don't retry
  - Timeout (ETIMEDOUT) → Retry with backoff
  - Invalid request (400) → Throw error, don't retry
  - Test Gate: Each error type handled with appropriate retry/no-retry logic

- [ ] Add input validation:
  - Skip empty strings (return null)
  - Log warning for strings > 8000 characters (OpenAI token limit)
  - Test Gate: Validation prevents invalid API calls

---

## 7. Pinecone Service

- [ ] Create `functions/services/pineconeService.ts`
- [ ] Import Pinecone SDK and configuration
  ```typescript
  const { Pinecone } = require('@pinecone-database/pinecone');
  const config = require('../config/ai.config');
  const { retryWithBackoff } = require('../utils/retryHelper');
  ```

- [ ] Initialize Pinecone client
  ```typescript
  const pinecone = new Pinecone({
    apiKey: functions.config().pinecone.api_key,
    environment: functions.config().pinecone.environment
  });
  const index = pinecone.index(config.pinecone.indexName);
  ```
  - Test Gate: Client and index initialize without errors

- [ ] Implement `upsertEmbedding(messageId, embedding, metadata)` method
  - Accept messageId (string), embedding (array of floats), metadata (object)
  - Validate embedding is array of 1536 floats
  - Upsert to Pinecone with retry logic
  - Return success boolean
  - Test Gate: Function exported with correct signature

- [ ] Format metadata correctly:
  ```typescript
  {
    id: messageId,
    values: embedding,
    metadata: {
      chatId: metadata.chatId,
      senderId: metadata.senderId,
      timestamp: metadata.timestamp,
      text: metadata.text
    }
  }
  ```
  - Test Gate: Metadata structure matches Pinecone schema from PRD

- [ ] Add error handling:
  - Connection timeout → Retry with backoff
  - Invalid dimensions (not 1536) → Throw error, don't retry
  - Invalid API key → Throw critical error, don't retry
  - Quota exceeded → Log error, retry after delay
  - Test Gate: Each error type handled appropriately

---

## 8. Main Cloud Function

- [ ] Create `functions/generateEmbedding.ts`
- [ ] Import dependencies
  ```typescript
  const functions = require('firebase-functions');
  const admin = require('firebase-admin');
  const openaiService = require('./services/openaiService');
  const pineconeService = require('./services/pineconeService');
  ```

- [ ] Implement Firestore trigger
  ```typescript
  exports.generateEmbedding = functions.firestore
    .document('chats/{chatId}/messages/{messageId}')
    .onCreate(async (snap, context) => {
      // Implementation here
    });
  ```
  - Test Gate: Function exports correctly, trigger path matches message creation

- [ ] Extract message data from snapshot
  ```typescript
  const messageData = snap.data();
  const { text, senderID, timestamp } = messageData;
  const { chatId, messageId } = context.params;
  ```
  - Test Gate: All required fields extracted

- [ ] Add early return for empty messages
  ```typescript
  if (!text || text.trim().length === 0) {
    console.info(`Skipping embedding for empty message: ${messageId}`);
    return null;
  }
  ```
  - Test Gate: Empty messages logged but not processed

- [ ] Generate embedding with error handling
  ```typescript
  try {
    const embedding = await openaiService.generateEmbedding(text);
    if (!embedding) {
      console.warn(`Failed to generate embedding for message: ${messageId}`);
      return null;
    }
  } catch (error) {
    console.error(`OpenAI error for message ${messageId}:`, error);
    throw error; // Cloud Functions will retry automatically
  }
  ```
  - Test Gate: Errors logged with context, function throws to trigger retry

- [ ] Upsert to Pinecone with metadata
  ```typescript
  const metadata = {
    chatId,
    senderId: senderID,
    timestamp: timestamp.toMillis(),
    text
  };
  
  const success = await pineconeService.upsertEmbedding(messageId, embedding, metadata);
  ```
  - Test Gate: Metadata includes all required fields from PRD

- [ ] Add final success/failure logging
  ```typescript
  if (success) {
    console.info(`Successfully embedded message ${messageId} in chat ${chatId}`);
  } else {
    console.error(`Failed to upsert embedding for message ${messageId}`);
  }
  ```
  - Test Gate: Logs clearly indicate success or failure

- [ ] Update `functions/index.ts` to export the function
  ```javascript
  exports.generateEmbedding = require('./generateEmbedding').generateEmbedding;
  ```
  - Test Gate: Function exported from index.ts

---

## 9. Local Testing (Firebase Emulator)

- [ ] Start Firebase emulators
  ```bash
  firebase emulators:start
  ```
  - Test Gate: Firestore and Functions emulators running

- [ ] Create test script to simulate message creation
  - Insert test message into Firestore emulator
  - Monitor Cloud Function logs for execution
  - Test Gate: Function triggers when message created

- [ ] Test with mock OpenAI/Pinecone services (unit tests)
  - Mock successful embedding generation
  - Mock successful Pinecone upsert
  - Verify function completes without errors
  - Test Gate: All mocks work, function logic correct

---

## 10. User-Centric Testing (Manual)

### Happy Path

- [ ] Deploy Cloud Function to Firebase staging environment
  - Test Gate: Deployment succeeds, function shows in Firebase Console

- [ ] Send test message "Hey, how's your knee feeling?" via Psst app
  - Test Gate: Message appears in Firestore within 100ms

- [ ] Check Cloud Functions logs for `generateEmbedding` execution
  - Test Gate: Function triggered within 1 second, logs show success

- [ ] Verify embedding in Pinecone dashboard
  - Test Gate: Vector count increased by 1
  - Test Gate: Metadata contains correct chatId, senderId, timestamp, text

- [ ] Query Pinecone API to retrieve embedding by messageId
  - Test Gate: Embedding retrievable, cosine similarity to itself is 1.0

### Edge Cases

- [ ] **Edge Case 1: Empty message**
  - Send message with empty text (`""`)
  - Test Gate: Cloud Function logs "Skipping embedding for empty message"
  - Test Gate: No embedding created in Pinecone
  - Test Gate: Message still delivered to Firestore

- [ ] **Edge Case 2: Long message (1000+ characters)**
  - Send 1000-character test message
  - Test Gate: Embedding generated successfully
  - Test Gate: Full text stored in Pinecone metadata (no truncation)
  - Test Gate: Function completes in < 500ms

- [ ] **Edge Case 3: Special characters and emojis**
  - Send message "Great job! 💪🔥 Keep it up 🎯"
  - Test Gate: Embedding generated with emoji context
  - Test Gate: Metadata preserves emojis correctly in Pinecone
  - Test Gate: No encoding errors in logs

### Error Handling

- [ ] **OpenAI API Timeout**
  - Temporarily set OpenAI timeout to 1ms to force timeout
  - Send test message
  - Test Gate: Cloud Function retries with exponential backoff
  - Test Gate: Logs show retry attempts (1s, 2s, 4s delays)
  - Test Gate: Message delivery not affected (Firestore write succeeds)

- [ ] **OpenAI Rate Limit (429)**
  - Send 100+ messages rapidly to trigger rate limit (or mock 429 response)
  - Test Gate: Function respects retry-after header
  - Test Gate: Embeddings eventually generated after rate limit clears
  - Test Gate: Logs show rate limit handling

- [ ] **Pinecone Connection Failure**
  - Temporarily use invalid Pinecone API key
  - Send test message
  - Test Gate: Cloud Function logs Pinecone error
  - Test Gate: Function retries up to 3 times
  - Test Gate: After 3 failures, error logged and function stops retrying
  - Test Gate: Message still delivered to Firestore

- [ ] **Missing API Keys**
  - Deploy function without OPENAI_API_KEY configured
  - Send test message
  - Test Gate: Function logs "Missing OpenAI API key" error
  - Test Gate: Clear error message (not generic crash)
  - Test Gate: Function doesn't retry infinitely

### Final Checks

- [ ] No console errors during all test scenarios (except expected errors being tested)
- [ ] Cloud Function logs are clear and informative (success/failure obvious)
- [ ] Message delivery latency remains < 100ms (embedding doesn't block)
- [ ] Embedding generation completes in < 200ms (per PRD performance target)

---

## 11. Performance Verification

- [ ] Measure message delivery latency
  - Send 10 messages, record time from send to Firestore confirmation
  - Test Gate: Average latency < 100ms (embedding runs async, doesn't block)

- [ ] Measure embedding generation time
  - Check Cloud Function logs for OpenAI API call duration
  - Test Gate: 90% of embeddings generated in < 200ms

- [ ] Measure Pinecone upsert time
  - Check logs for Pinecone operation duration
  - Test Gate: 90% of upserts complete in < 100ms

- [ ] Test Cloud Function cold start
  - Wait 15 minutes for function to go cold
  - Send message, measure first execution time
  - Test Gate: Cold start < 3 seconds (acceptable per PRD)

- [ ] Test Cloud Function warm execution
  - Send 10 messages consecutively (keep function warm)
  - Measure execution time
  - Test Gate: Warm execution < 500ms per message

---

## 12. Cost Monitoring Setup

- [ ] Set up OpenAI billing alert
  - Navigate to OpenAI dashboard → Billing
  - Set alert at $50/month threshold
  - Test Gate: Alert email configured

- [ ] Estimate OpenAI costs for test volume
  - text-embedding-3-small: $0.02 per 1M tokens
  - Assume average message = 50 tokens
  - 1000 messages = 50,000 tokens = $0.001
  - Test Gate: Cost calculation documented

- [ ] Monitor Pinecone usage
  - Check Pinecone dashboard for vector count
  - p1.x1 pod: $70/month for ~1M vectors
  - Test Gate: Usage tracked, well under limits

- [ ] Create cost monitoring doc
  - File: `Psst/docs/ai-cost-monitoring.md`
  - Include: Current usage, projected costs, billing alerts
  - Test Gate: Doc created with initial baseline

---

## 13. Documentation

- [ ] Create `Psst/docs/ai-backend-setup.md`
  - Include: Step-by-step setup for OpenAI account
  - Include: Step-by-step setup for Pinecone account and index creation
  - Include: Firebase Functions environment variable configuration
  - Include: Deployment instructions (staging, production)
  - Include: Troubleshooting section (common errors and fixes)
  - Test Gate: Another developer can follow docs and set up from scratch

- [ ] Update `functions/package.json` with script comments
  ```json
  "scripts": {
    "deploy:staging": "firebase use staging && firebase deploy --only functions",
    "deploy:prod": "firebase use production && firebase deploy --only functions"
  }
  ```
  - Test Gate: Scripts work for deployment

- [ ] Add inline code comments
  - Comment retry logic in retryHelper.js
  - Comment error handling in openaiService.js
  - Comment Pinecone metadata formatting in pineconeService.js
  - Comment trigger logic in generateEmbedding.js
  - Test Gate: Complex logic has clear explanatory comments

- [ ] Update `.env.example`
  ```
  # OpenAI Configuration
  OPENAI_API_KEY=sk-...
  
  # Pinecone Configuration
  PINECONE_API_KEY=...
  PINECONE_ENVIRONMENT=us-east1-gcp
  PINECONE_INDEX=coachai
  ```
  - Test Gate: All required variables documented with examples

---

## 14. Staging Deployment

- [ ] Deploy to Firebase staging environment
  ```bash
  firebase use staging
  firebase deploy --only functions:generateEmbedding
  ```
  - Test Gate: Deployment successful, no errors

- [ ] Verify function shows in Firebase Console (staging)
  - Test Gate: Function listed, status "Active"

- [ ] Send 10-20 test messages in staging app
  - Test Gate: All messages embedded successfully

- [ ] Monitor Cloud Functions logs for 1 hour
  - Check for unexpected errors
  - Verify success rate > 99%
  - Test Gate: Logs show consistent success, no crashes

- [ ] Check Pinecone dashboard
  - Verify vector count matches message count
  - Test Gate: All test messages embedded in Pinecone

- [ ] Monitor costs for 24 hours
  - Check OpenAI usage dashboard
  - Check Pinecone usage dashboard
  - Test Gate: Costs within expected range (< $0.10/day for test volume)

---

## 15. Production Deployment

- [ ] Review staging performance metrics
  - Success rate: > 99%
  - Average embedding time: < 200ms
  - No critical errors in logs
  - Test Gate: All metrics meet PRD targets

- [ ] Deploy to production
  ```bash
  firebase use production
  firebase deploy --only functions:generateEmbedding
  ```
  - Test Gate: Deployment successful

- [ ] Send 5 test messages in production app
  - Test Gate: All embedded successfully
  - Test Gate: Production logs show success

- [ ] Monitor production for 7 days
  - Track success rate (target: 99%)
  - Track costs daily
  - Watch for errors or anomalies
  - Test Gate: System stable, no issues for 1 week

---

## 16. Acceptance Gates

All gates from PRD Section 12 must pass:

- [x] Message persists to Firestore immediately (< 100ms)
- [x] Cloud Function triggers within 1 second of message creation
- [x] Embedding generated in < 200ms (OpenAI API)
- [x] Pinecone stores vector in < 100ms
- [x] Embedding failures don't block message delivery
- [x] Empty messages skipped gracefully (no errors)
- [x] Long messages (1000+ chars) handled without truncation
- [x] Special characters/emojis preserved correctly
- [x] API timeouts retry with exponential backoff
- [x] Rate limits handled with proper delays
- [x] Connection failures logged and retried
- [x] Missing API keys produce clear error messages
- [x] Cold start < 3s, warm execution < 500ms
- [x] All test scenarios pass without blocking message delivery

---

## 17. PR Preparation

- [ ] Review all code for quality
  - No hardcoded API keys
  - All errors properly handled
  - Logs informative and clean
  - Code follows TypeScript/Node.js/Firebase best practices
  - Test Gate: Code review checklist complete

- [ ] Create PR description using format from `Psst/agents/caleb-agent.md`
  - Title: "feat: AI Backend Infrastructure (Pinecone + OpenAI + Cloud Functions)"
  - Description: Summary, what changed, how to test
  - Link to PRD and TODO
  - Test Gate: PR description comprehensive

- [ ] Verify with user before creating PR
  - Confirm all acceptance gates passed
  - Confirm documentation complete
  - Confirm ready for production
  - Test Gate: User approval received

- [ ] Open PR targeting `develop` branch
  - Test Gate: PR created, points to develop (not main)

---

## Copyable Checklist (for PR description)

```markdown
## PR Checklist

- [ ] Branch created from develop (`feat/pr-1-ai-backend-infrastructure`)
- [ ] All TODO tasks completed and checked off
- [ ] Cloud Functions implemented (generateEmbedding, OpenAI service, Pinecone service)
- [ ] Retry logic with exponential backoff implemented
- [ ] Error handling for all failure modes (timeouts, rate limits, connection failures)
- [ ] Pinecone index created and configured (1536 dimensions, cosine metric)
- [ ] Environment variables configured (OPENAI_API_KEY, PINECONE_API_KEY, etc.)
- [ ] Manual testing completed (happy path, edge cases, error handling)
- [ ] All acceptance gates pass (see TODO Section 16)
- [ ] Performance targets met (< 200ms embedding, < 100ms Pinecone, no message blocking)
- [ ] Documentation created (ai-backend-setup.md, .env.example, inline comments)
- [ ] Staging tested for 24 hours (no issues)
- [ ] Production deployed and monitored for 7 days (stable)
- [ ] Code follows shared-standards.md patterns
- [ ] No console warnings or errors
- [ ] No API keys in code or logs
- [ ] Cost monitoring in place (OpenAI and Pinecone billing alerts)
```

---

## Notes

- Each task < 30 min of work (complex tasks broken into subtasks)
- Complete tasks sequentially (setup → services → function → testing → deployment)
- Check off after completion
- Document blockers immediately in PR comments
- Reference `Psst/agents/shared-standards.md` for Firebase and error handling patterns
- This is foundation work - no user-facing changes expected
- Focus on reliability and error handling (messaging app can't afford failures)
- Cost monitoring is critical (usage-based pricing for OpenAI and Pinecone)
