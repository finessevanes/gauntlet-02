/**
 * Generate Embedding Cloud Function
 * Automatically generates and stores vector embeddings when messages are created
 * Triggered by Firestore onCreate event: /chats/{chatId}/messages/{messageId}
 */

import * as functions from 'firebase-functions';
import { generateEmbedding } from './services/openaiService';
import { upsertEmbedding, PineconeMetadata } from './services/pineconeService';

/**
 * Cloud Function: Generate and store embedding for new messages
 * 
 * Trigger: Firestore onCreate for /chats/{chatId}/messages/{messageId}
 * 
 * Flow:
 * 1. Extract message data from Firestore snapshot
 * 2. Validate message has non-empty text
 * 3. Generate embedding using OpenAI API
 * 4. Store embedding in Pinecone with metadata
 * 5. Log success/failure
 * 
 * Error Handling:
 * - Empty messages: Skip gracefully
 * - OpenAI failures: Retry with backoff, then throw to trigger Cloud Functions retry
 * - Pinecone failures: Log error but don't block (message already delivered)
 */
export const generateEmbeddingFunction = functions.firestore
  .document('chats/{chatId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    const startTime = Date.now();
    
    try {
      // Extract message data
      const messageData = snap.data();
      const { text, senderID, timestamp } = messageData;
      const { chatId, messageId } = context.params;

      console.log(`[GenerateEmbedding] Processing message ${messageId} in chat ${chatId}`);

      // Validate message has text
      if (!text || typeof text !== 'string') {
        console.warn(`[GenerateEmbedding] Message ${messageId} has no text field`);
        return null;
      }

      // Skip empty messages
      if (text.trim().length === 0) {
        console.info(`[GenerateEmbedding] Skipping empty message: ${messageId}`);
        return null;
      }

      // Validate required fields
      if (!senderID) {
        console.error(`[GenerateEmbedding] Message ${messageId} missing senderID`);
        return null;
      }

      if (!timestamp) {
        console.error(`[GenerateEmbedding] Message ${messageId} missing timestamp`);
        return null;
      }

      // Generate embedding
      let embedding: number[] | null;
      
      try {
        embedding = await generateEmbedding(text);
      } catch (error: any) {
        console.error(`[GenerateEmbedding] OpenAI error for message ${messageId}:`, error.message);
        // Re-throw to trigger Cloud Functions automatic retry
        throw new functions.https.HttpsError('internal', `Failed to generate embedding: ${error.message}`);
      }

      if (!embedding) {
        console.warn(`[GenerateEmbedding] Failed to generate embedding for message ${messageId}`);
        return null;
      }

      // Prepare metadata for Pinecone
      const metadata: PineconeMetadata = {
        chatId: chatId,
        senderId: senderID,
        timestamp: timestamp.toMillis ? timestamp.toMillis() : Date.now(),
        text: text
      };

      // Upsert to Pinecone
      const success = await upsertEmbedding(messageId, embedding, metadata);

      if (success) {
        const duration = Date.now() - startTime;
        console.log(`[GenerateEmbedding] ✅ Successfully embedded message ${messageId} in chat ${chatId} (${duration}ms)`);
      } else {
        console.error(`[GenerateEmbedding] ❌ Failed to upsert embedding for message ${messageId}`);
        // Note: We don't throw here because the message was already delivered to Firestore
        // Pinecone failure shouldn't block the messaging flow
      }

      return null;

    } catch (error: any) {
      const duration = Date.now() - startTime;
      console.error(`[GenerateEmbedding] Error processing message (${duration}ms):`, error);
      
      // If it's already an HttpsError, re-throw it
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      
      // Otherwise, wrap it in an HttpsError to trigger retry
      throw new functions.https.HttpsError('internal', error.message || 'Unknown error');
    }
  });

