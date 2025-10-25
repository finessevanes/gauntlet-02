# Migration Guide: functions.config() → defineSecret()

## Overview

Successfully migrated all Cloud Functions from deprecated `functions.config()` to modern `defineSecret()` from `firebase-functions/params`.

**Why this matters:**
- `functions.config()` is deprecated and will stop working after March 2026
- `defineSecret()` uses Google Secret Manager (encrypted, secure)
- Works seamlessly in both development and production

---

## What Changed

### ✅ Files Updated

**Service Layer:**
- `src/services/openaiService.ts` - Now accepts `apiKey` parameter
- `src/services/aiChatService.ts` - Now accepts `apiKey` parameter
- `src/services/pineconeService.ts` - Now accepts `apiKey` parameter
- `src/services/vectorSearchService.ts` - Now accepts `pineconeApiKey` parameter
- `src/services/functionExecutionService.ts` - Now accepts both API keys

**Cloud Functions:**
- `src/chatWithAI.ts` - Uses secrets, passes to services
- `src/semanticSearch.ts` - Uses secrets, passes to services
- `src/generateEmbedding.ts` - Uses secrets (Firestore trigger)
- `src/executeFunctionCall.ts` - Uses secrets, passes to services

**Configuration:**
- `src/config/secrets.ts` - **NEW** - Centralized secret definitions
- `.env.example` - **NEW** - Template for environment variables
- `.gitignore` - Updated to exclude `.env` files

---

## How It Works

### Development (Local)

1. **Copy the template:**
   ```bash
   cd functions
   cp .env.example .env
   ```

2. **Add your API keys to `.env`:**
   ```env
   OPENAI_API_KEY=sk-your-openai-key-here
   PINECONE_API_KEY=your-pinecone-key-here
   ```

3. **Run locally:**
   ```bash
   npm run serve
   ```
   Firebase automatically reads from `.env` file.

### Production (Deployment)

1. **Set secrets in Google Secret Manager:**
   ```bash
   firebase functions:secrets:set OPENAI_API_KEY
   # Paste your key when prompted

   firebase functions:secrets:set PINECONE_API_KEY
   # Paste your key when prompted
   ```

2. **Deploy:**
   ```bash
   npm run deploy
   ```
   Functions automatically access secrets from Secret Manager.

---

## Key Differences

| Aspect | OLD (`functions.config()`) | NEW (`defineSecret()`) |
|--------|---------------------------|------------------------|
| **Storage** | Firebase config (plain text) | Google Secret Manager (encrypted) |
| **Security** | ❌ Visible in Firebase Console | ✅ Encrypted at rest |
| **Local Dev** | `.runtimeconfig.json` | `.env` file |
| **Production** | `firebase functions:config:set` | `firebase functions:secrets:set` |
| **Access** | `functions.config().openai?.api_key` | `openaiApiKey.value()` |
| **Rotation** | Requires redeployment | ✅ Update secret without redeploy |
| **Audit Trail** | ❌ None | ✅ Who accessed secrets |

---

## Code Pattern

### Before (Deprecated ❌)
```typescript
import * as functions from 'firebase-functions';

export const myFunction = functions.https.onCall(async (data, context) => {
  const apiKey = functions.config().openai?.api_key; // Deprecated!
  // Use apiKey...
});
```

### After (Modern ✅)
```typescript
import * as functions from 'firebase-functions';
import { openaiApiKey } from './config/secrets';

export const myFunction = functions
  .runWith({
    secrets: [openaiApiKey], // Inject secret
    timeoutSeconds: 60,
    memory: '256MB'
  })
  .https.onCall(async (data, context) => {
    const apiKey = openaiApiKey.value(); // Access secret value
    // Use apiKey...
  });
```

---

## Verification

### Test Locally

1. Ensure `.env` file exists with valid keys
2. Run the emulator:
   ```bash
   npm run serve
   ```
3. Test a function (e.g., call `chatWithAI`)
4. Check logs for successful API calls

### Test Production

1. Set secrets:
   ```bash
   firebase functions:secrets:access OPENAI_API_KEY
   firebase functions:secrets:access PINECONE_API_KEY
   ```
2. Deploy:
   ```bash
   npm run deploy
   ```
3. Check Cloud Functions logs for successful execution

---

## Troubleshooting

### Error: "Secret not found"
- **Local:** Check `.env` file exists and has correct key names
- **Production:** Run `firebase functions:secrets:set OPENAI_API_KEY`

### Error: "OpenAI API key not provided"
- **Local:** Verify `.env` file is in `functions/` directory (not root)
- **Production:** Check secret is set: `firebase functions:secrets:access OPENAI_API_KEY`

### Error: "Permission denied" on secrets
- Run: `gcloud auth login` and ensure you have Secret Manager permissions

---

## Rollback (if needed)

If you need to rollback to `functions.config()` temporarily:

1. Revert service files to accept no `apiKey` parameter
2. Change back to `functions.config().openai?.api_key`
3. Set config: `firebase functions:config:set openai.api_key="sk-..."`

**Not recommended** - The old approach is deprecated and will stop working soon.

---

## Summary

✅ All Cloud Functions migrated to `defineSecret()`
✅ Secrets stored securely in Google Secret Manager
✅ Works in both development (`.env`) and production
✅ No more deprecation warnings
✅ Future-proof until at least 2026+

**Next Steps:**
1. Copy `.env.example` to `.env`
2. Add your API keys
3. Test locally with `npm run serve`
4. Deploy to production with secret manager
