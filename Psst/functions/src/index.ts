/**
 * Cloud Functions for Psst messaging app
 * 
 * Functions:
 * - onMessageCreate: Send push notifications when messages are created
 * - generateEmbedding: Generate and store AI embeddings for semantic search
 */

import * as admin from 'firebase-admin';

// Initialize Firebase Admin SDK
admin.initializeApp();

// Export existing notification function (converted from index.js)
export { onMessageCreate } from './onMessageCreate';

// Export new AI embedding function
export { generateEmbeddingFunction as generateEmbedding } from './generateEmbedding';

