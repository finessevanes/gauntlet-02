/**
 * semanticSearch Cloud Function
 * Performs semantic search across trainer's message history using Pinecone vector database
 * 
 * This function enables AI to find contextually relevant past conversations by:
 * 1. Generating an embedding for the search query
 * 2. Querying Pinecone for similar message embeddings
 * 3. Filtering results by user ID for privacy
 * 4. Returning only high-relevance matches (score ≥ 0.7)
 */

import * as functions from 'firebase-functions';
import { generateEmbedding } from './services/openaiService';
import { searchVectors } from './services/vectorSearchService';
import {
  SemanticSearchRequest,
  SemanticSearchResponse,
  SearchResult
} from './types/rag';

/**
 * Callable Cloud Function: Semantic Search
 * 
 * @param data - Request containing query, userId, and optional limit
 * @param context - Firebase Functions context with auth information
 * @returns SemanticSearchResponse with relevant past messages
 */
export const semanticSearchFunction = functions.https.onCall(
  async (data: SemanticSearchRequest, context): Promise<SemanticSearchResponse> => {
    const startTime = Date.now();

    try {
      // ========================================
      // 1. AUTHENTICATION
      // ========================================

      if (!context.auth) {
        console.warn('[SemanticSearch] Unauthenticated request rejected');
        throw new functions.https.HttpsError(
          'unauthenticated',
          'You must be authenticated to perform semantic search'
        );
      }

      const authenticatedUserId = context.auth.uid;

      // Verify userId matches authenticated user
      if (data.userId !== authenticatedUserId) {
        console.warn(`[SemanticSearch] User ID mismatch: ${data.userId} vs ${authenticatedUserId}`);
        throw new functions.https.HttpsError(
          'permission-denied',
          'User ID does not match authenticated user'
        );
      }

      console.log(`[SemanticSearch] Request from user: ${authenticatedUserId}`);

      // ========================================
      // 2. INPUT VALIDATION
      // ========================================

      const { query, limit = 10 } = data;

      // Validate query
      if (!query || typeof query !== 'string') {
        console.warn('[SemanticSearch] Invalid query format');
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Query must be a non-empty string'
        );
      }

      const trimmedQuery = query.trim();

      if (trimmedQuery.length === 0) {
        console.warn('[SemanticSearch] Empty query rejected');
        throw new functions.https.HttpsError(
          'invalid-argument',
          'I need a question to search for. What would you like to know?'
        );
      }

      if (trimmedQuery.length > 500) {
        console.warn(`[SemanticSearch] Query too long: ${trimmedQuery.length} characters`);
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Query is too long. Maximum 500 characters allowed.'
        );
      }

      // Validate limit
      if (limit < 1 || limit > 50) {
        console.warn(`[SemanticSearch] Invalid limit: ${limit}`);
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Limit must be between 1 and 50'
        );
      }

      console.log(`[SemanticSearch] Searching for: "${trimmedQuery}" (limit: ${limit})`);

      // ========================================
      // 3. GENERATE QUERY EMBEDDING
      // ========================================

      let queryEmbedding: number[];

      try {
        const embeddingStartTime = Date.now();

        const embedding = await generateEmbedding(trimmedQuery);

        if (!embedding) {
          throw new Error('Failed to generate embedding');
        }

        queryEmbedding = embedding;

        const embeddingDuration = Date.now() - embeddingStartTime;
        console.log(`[SemanticSearch] ✅ Query embedding generated (${embeddingDuration}ms)`);

      } catch (error: any) {
        console.error('[SemanticSearch] Embedding generation failed:', error);

        throw new functions.https.HttpsError(
          'internal',
          'I\'m having trouble searching right now. Please try again in a few moments.'
        );
      }

      // ========================================
      // 4. SEARCH PINECONE
      // ========================================

      let results: SearchResult[];

      try {
        const searchStartTime = Date.now();

        results = await searchVectors(queryEmbedding, authenticatedUserId, {
          topK: limit,
          relevanceThreshold: 0.7 // Only return high-quality matches
        });

        const searchDuration = Date.now() - searchStartTime;
        console.log(`[SemanticSearch] ✅ Pinecone search complete (${searchDuration}ms, ${results.length} results)`);

      } catch (error: any) {
        console.error('[SemanticSearch] Vector search failed:', error);

        // Check if timeout
        if (error.code === 'ETIMEDOUT' || error.message?.includes('timeout')) {
          throw new functions.https.HttpsError(
            'deadline-exceeded',
            'Search is taking too long. Please try again in a moment.'
          );
        }

        throw new functions.https.HttpsError(
          'unavailable',
          'Search temporarily unavailable. Please try again later.'
        );
      }

      // ========================================
      // 5. HANDLE NO RESULTS
      // ========================================

      if (results.length === 0) {
        console.log('[SemanticSearch] No relevant results found');

        const duration = Date.now() - startTime;
        console.log(`[SemanticSearch] ✅ Request completed in ${duration}ms (0 results)`);

        return {
          success: true,
          results: [],
          count: 0,
          query: trimmedQuery
        };
      }

      // ========================================
      // 6. RETURN RESULTS
      // ========================================

      const duration = Date.now() - startTime;

      // Log performance metrics
      console.log(`[SemanticSearch] ✅ Request completed in ${duration}ms`);
      console.log(`[SemanticSearch] Results: ${results.length}, Top score: ${results[0]?.score.toFixed(3) || 'N/A'}`);

      return {
        success: true,
        results,
        count: results.length,
        query: trimmedQuery
      };

    } catch (error: any) {
      const duration = Date.now() - startTime;
      console.error(`[SemanticSearch] ❌ Request failed after ${duration}ms:`, error);

      // If error is already a Firebase HttpsError, re-throw it
      if (error.code && error.message) {
        throw error;
      }

      // Otherwise, wrap in a generic internal error
      throw new functions.https.HttpsError(
        'internal',
        `Unexpected error: ${error.message}`
      );
    }
  }
);


