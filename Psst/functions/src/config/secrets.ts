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
