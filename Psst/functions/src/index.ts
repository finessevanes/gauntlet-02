/**
 * Cloud Functions for Psst messaging app
 * 
 * Functions:
 * - onMessageCreate: Send push notifications when messages are created
 * - generateEmbedding: Generate and store AI embeddings for semantic search
 * - chatWithAI: AI chat assistant for trainers
 * - semanticSearch: Semantic search across message history using RAG
 */

import * as admin from 'firebase-admin';

// Initialize Firebase Admin SDK
admin.initializeApp();

// Export existing notification function (converted from index.js)
export { onMessageCreate } from './onMessageCreate';

// Export AI embedding function
export { generateEmbeddingFunction as generateEmbedding } from './generateEmbedding';

// Export AI chat function
export { chatWithAIFunction as chatWithAI } from './chatWithAI';

// Export semantic search function
export { semanticSearchFunction as semanticSearch } from './semanticSearch';

// Export function execution
export { executeFunctionCallFunction as executeFunctionCall } from './executeFunctionCall';

