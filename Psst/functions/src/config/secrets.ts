/**
 * Cloud Functions Secrets Configuration
 *
 * Uses Firebase Functions v2 defineSecret() for secure secret management:
 * - In development: Reads from .env file
 * - In production: Reads from Google Secret Manager (encrypted)
 *
 * Migration from functions.config():
 * - OLD: functions.config().openai?.api_key
 * - NEW: openaiApiKey.value() inside Cloud Function
 */

import { defineSecret } from 'firebase-functions/params';

/**
 * OpenAI API Key
 * Used for GPT-4 chat completions and text embeddings
 *
 * Setup:
 * 1. Development: Add OPENAI_API_KEY=sk-... to functions/.env
 * 2. Production: firebase functions:secrets:set OPENAI_API_KEY
 */
export const openaiApiKey = defineSecret('OPENAI_API_KEY');

/**
 * Pinecone API Key
 * Used for vector database operations (semantic search)
 *
 * Setup:
 * 1. Development: Add PINECONE_API_KEY=... to functions/.env
 * 2. Production: firebase functions:secrets:set PINECONE_API_KEY
 */
export const pineconeApiKey = defineSecret('PINECONE_API_KEY');

/**
 * Google OAuth Client Secret
 * Used for Google Calendar integration (backend OAuth token refresh)
 *
 * NOTE: iOS clients typically don't require a secret for OAuth refresh.
 * This is OPTIONAL - only needed if you encounter auth issues with Google Calendar.
 *
 * Setup:
 * 1. Development: Add GOOGLE_CLIENT_SECRET=... to functions/.env (optional)
 * 2. Production: firebase functions:secrets:set GOOGLE_CLIENT_SECRET (if needed)
 */
export const googleClientSecret = defineSecret('GOOGLE_CLIENT_SECRET');
