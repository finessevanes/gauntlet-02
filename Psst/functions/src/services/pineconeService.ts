/**
 * Pinecone Service
 * Handles vector storage and retrieval in Pinecone serverless index
 */

import { Pinecone } from '@pinecone-database/pinecone';
import * as functions from 'firebase-functions';
import { aiConfig } from '../config/ai.config';
import { retryWithBackoff, isRetryableError } from '../utils/retryHelper';

/**
 * Metadata for Pinecone vectors
 */
export interface PineconeMetadata {
  chatId: string;
  senderId: string;
  members: string[];  // All participants in the chat (for RAG filtering)
  timestamp: number;
  text: string;
}

/**
 * Upsert embedding to Pinecone index
 * @param messageId - Unique message ID (used as vector ID)
 * @param embedding - Array of 1536 floats
 * @param metadata - Message metadata
 * @returns True if successful, false otherwise
 */
export async function upsertEmbedding(
  messageId: string,
  embedding: number[],
  metadata: PineconeMetadata
): Promise<boolean> {
  // Validate inputs
  if (!messageId || typeof messageId !== 'string') {
    console.error('[PineconeService] Invalid messageId');
    return false;
  }

  if (!Array.isArray(embedding)) {
    console.error('[PineconeService] Embedding must be an array');
    return false;
  }

  if (embedding.length !== aiConfig.pinecone.dimensions) {
    console.error(`[PineconeService] Invalid embedding dimensions: ${embedding.length} (expected ${aiConfig.pinecone.dimensions})`);
    return false;
  }

  if (!metadata || !metadata.chatId || !metadata.senderId) {
    console.error('[PineconeService] Invalid metadata');
    return false;
  }

  try {
    // Get API key from Firebase config
    const apiKey = functions.config().pinecone?.api_key;
    
    if (!apiKey) {
      throw new Error('Pinecone API key not configured. Set with: firebase functions:config:set pinecone.api_key="..."');
    }

    // Initialize Pinecone client (serverless mode)
    const pinecone = new Pinecone({
      apiKey: apiKey
    });

    // Get index reference
    const index = pinecone.index(aiConfig.pinecone.indexName);

    // Upsert vector with retry logic
    await retryWithBackoff(async () => {
      try {
        console.log(`[PineconeService] Upserting vector for message: ${messageId}`);
        
        await index.upsert([
          {
            id: messageId,
            values: embedding,
            metadata: {
              chatId: metadata.chatId,
              senderId: metadata.senderId,
              members: metadata.members,  // Store all chat participants
              timestamp: metadata.timestamp,
              text: metadata.text
            }
          }
        ]);

        console.log(`[PineconeService] ✅ Vector upserted successfully: ${messageId}`);
        
      } catch (error: any) {
        // Handle Pinecone-specific errors
        if (error.status === 401 || error.statusCode === 401) {
          // Invalid API key - don't retry
          throw new Error(`Pinecone authentication failed. Check API key. Error: ${error.message}`);
        }
        
        if (error.status === 400 || error.statusCode === 400) {
          // Invalid request - don't retry
          throw new Error(`Invalid request to Pinecone: ${error.message}`);
        }
        
        if (error.status === 429 || error.statusCode === 429) {
          // Quota exceeded
          console.log('[PineconeService] Quota exceeded. Retrying...');
          throw error; // Will be retried
        }
        
        // Check if error is retryable
        if (isRetryableError(error)) {
          console.log('[PineconeService] Retryable error encountered');
          throw error; // Will be retried
        }
        
        // Unknown error - don't retry
        throw error;
      }
    }, aiConfig.retry.maxAttempts, aiConfig.retry.initialDelay, aiConfig.retry.maxDelay);

    return true;

  } catch (error: any) {
    console.error('[PineconeService] Failed to upsert embedding after retries:', error.message);
    console.error('[PineconeService] Error details:', error);
    return false;
  }
}

/**
 * Query Pinecone for similar vectors
 * @param embedding - Query embedding vector
 * @param topK - Number of results to return
 * @param filter - Optional metadata filter
 * @returns Array of matching vectors with scores
 */
export async function queryEmbeddings(
  embedding: number[],
  topK: number = 5,
  filter?: Record<string, any>
): Promise<any[]> {
  try {
    const apiKey = functions.config().pinecone?.api_key;
    
    if (!apiKey) {
      throw new Error('Pinecone API key not configured');
    }

    const pinecone = new Pinecone({
      apiKey: apiKey
    });

    const index = pinecone.index(aiConfig.pinecone.indexName);

    console.log(`[PineconeService] Querying for top ${topK} similar vectors`);
    
    const queryResponse = await index.query({
      vector: embedding,
      topK: topK,
      includeMetadata: true,
      filter: filter
    });

    console.log(`[PineconeService] ✅ Found ${queryResponse.matches?.length || 0} matches`);
    
    return queryResponse.matches || [];

  } catch (error: any) {
    console.error('[PineconeService] Failed to query embeddings:', error.message);
    console.error('[PineconeService] Error details:', error);
    return [];
  }
}

