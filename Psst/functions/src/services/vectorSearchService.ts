/**
 * Vector Search Service
 * Handles semantic search operations via Pinecone with filtering and relevance scoring
 */

import { queryEmbeddings } from './pineconeService';
import { SearchResult, VectorSearchOptions } from '../types/rag';
import { aiConfig } from '../config/ai.config';

/**
 * Default relevance threshold - only return results with similarity ≥ 0.7
 * This ensures high-quality matches and prevents irrelevant results
 */
const DEFAULT_RELEVANCE_THRESHOLD = 0.7;

/**
 * Default number of results to return
 */
const DEFAULT_TOP_K = 10;

import * as admin from 'firebase-admin';

/**
 * Search Pinecone for semantically similar messages
 *
 * @param queryEmbedding - 1536-dimensional embedding vector for the search query
 * @param userId - User ID to filter results (trainers only see their own conversations)
 * @param pineconeApiKey - Pinecone API key (passed from function handler)
 * @param options - Search options (topK, relevance threshold, additional filters)
 * @returns Array of search results with scores ≥ relevance threshold
 */
export async function searchVectors(
  queryEmbedding: number[],
  userId: string,
  pineconeApiKey: string,
  options?: Partial<VectorSearchOptions>
): Promise<SearchResult[]> {
  // Merge options with defaults
  const topK = options?.topK || DEFAULT_TOP_K;
  const relevanceThreshold = options?.relevanceThreshold || DEFAULT_RELEVANCE_THRESHOLD;

  // Validate inputs
  if (!queryEmbedding || !Array.isArray(queryEmbedding)) {
    console.error('[VectorSearchService] Invalid query embedding');
    return [];
  }

  if (queryEmbedding.length !== aiConfig.pinecone.dimensions) {
    console.error(`[VectorSearchService] Invalid embedding dimensions: ${queryEmbedding.length}`);
    return [];
  }

  if (!userId || typeof userId !== 'string') {
    console.error('[VectorSearchService] Invalid userId');
    return [];
  }

  try {
    console.log(`[VectorSearchService] Searching for top ${topK} vectors for user: ${userId}`);

    // Build metadata filter to ensure privacy
    // CRITICAL: Filter by members array - user must be a participant in the chat
    // This allows finding messages sent BY the user AND messages sent TO the user
    const filter: Record<string, any> = {
      members: { $in: [userId] },  // User is in the chat members array
      ...options?.filter
    };

    // Query Pinecone
    const matches = await queryEmbeddings(queryEmbedding, topK, filter, pineconeApiKey);

    console.log('[VectorSearchService] 📋 RAW PINECONE RESULTS:');
    if (!matches || matches.length === 0) {
      console.log('[VectorSearchService] No matches found');
      return [];
    }
    
    // Log what Pinecone actually returned
    matches.forEach((match: any, index: number) => {
      console.log(`[VectorSearchService] Match ${index + 1}:`, {
        id: match.id,
        score: match.score,
        metadata: match.metadata
      });
    });

    // Transform Pinecone matches to SearchResult format
    const results: SearchResult[] = matches
      .map((match: any) => {
        // Extract metadata
        const metadata = match.metadata || {};

        return {
          messageId: match.id,
          chatId: metadata.chatId || '',
          senderId: metadata.senderId || '',
          senderName: metadata.senderName || 'Unknown',
          text: metadata.text || '',
          timestamp: metadata.timestamp || 0,
          score: match.score || 0
        };
      })
      // Filter by relevance threshold
      .filter((result: SearchResult) => result.score >= relevanceThreshold)
      // Sort by score (highest first)
      .sort((a: SearchResult, b: SearchResult) => b.score - a.score);

    // Remove duplicates (same message appearing multiple times)
    const uniqueResults = deduplicateResults(results);

    // Fetch sender names from Firestore for better context
    const resultsWithNames = await enrichResultsWithUserNames(uniqueResults);

    console.log(`[VectorSearchService] ✅ Found ${resultsWithNames.length} relevant results (threshold: ${relevanceThreshold})`);

    // Log top scores for debugging
    if (resultsWithNames.length > 0) {
      const topScores = resultsWithNames.slice(0, 3).map(r => r.score.toFixed(3));
      console.log(`[VectorSearchService] Top scores: ${topScores.join(', ')}`);
    }

    return resultsWithNames;

  } catch (error: any) {
    console.error('[VectorSearchService] Search failed:', error.message);
    console.error('[VectorSearchService] Error details:', error);
    return [];
  }
}

/**
 * Remove duplicate search results (same messageId)
 * Keeps the result with the highest score
 * 
 * @param results - Array of search results
 * @returns Deduplicated array
 */
function deduplicateResults(results: SearchResult[]): SearchResult[] {
  const seen = new Map<string, SearchResult>();

  for (const result of results) {
    const existing = seen.get(result.messageId);

    // Keep the result with higher score
    if (!existing || result.score > existing.score) {
      seen.set(result.messageId, result);
    }
  }

  return Array.from(seen.values());
}

/**
 * Fetch user display names from Firestore and add to results
 * 
 * @param results - Search results with senderId
 * @returns Results enriched with senderName
 */
async function enrichResultsWithUserNames(results: SearchResult[]): Promise<SearchResult[]> {
  if (results.length === 0) {
    return results;
  }

  try {
    // Get unique sender IDs
    const senderIds = [...new Set(results.map(r => r.senderId))];
    
    console.log(`[VectorSearchService] Fetching names for ${senderIds.length} users`);

    // Fetch all users in parallel
    const userPromises = senderIds.map(async (senderId) => {
      try {
        const userDoc = await admin.firestore().collection('users').doc(senderId).get();
        if (userDoc.exists) {
          const userData = userDoc.data();
          return { senderId, displayName: userData?.displayName || 'Unknown User' };
        }
        return { senderId, displayName: 'Unknown User' };
      } catch (error) {
        console.error(`[VectorSearchService] Failed to fetch user ${senderId}:`, error);
        return { senderId, displayName: 'Unknown User' };
      }
    });

    const users = await Promise.all(userPromises);
    const userMap = new Map(users.map(u => [u.senderId, u.displayName]));

    // Enrich results with names
    return results.map(result => ({
      ...result,
      senderName: userMap.get(result.senderId) || 'Unknown User'
    }));

  } catch (error: any) {
    console.error('[VectorSearchService] Failed to enrich with user names:', error);
    // Return original results if enrichment fails
    return results;
  }
}

/**
 * Format timestamp for human-readable display
 * 
 * @param timestamp - Unix timestamp in milliseconds
 * @returns Formatted date string (e.g., "Oct 10, 2025" or "2 weeks ago")
 */
export function formatTimestamp(timestamp: number): string {
  const date = new Date(timestamp);
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));

  // Show relative dates for recent messages
  if (diffDays === 0) {
    return 'today';
  } else if (diffDays === 1) {
    return 'yesterday';
  } else if (diffDays < 7) {
    return `${diffDays} days ago`;
  } else if (diffDays < 14) {
    return '1 week ago';
  } else if (diffDays < 30) {
    return `${Math.floor(diffDays / 7)} weeks ago`;
  } else if (diffDays < 60) {
    return '1 month ago';
  }

  // Show absolute dates for older messages
  const options: Intl.DateTimeFormatOptions = {
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  };

  return date.toLocaleDateString('en-US', options);
}

/**
 * Format search results for GPT-4 prompt context
 * 
 * @param results - Array of search results
 * @returns Formatted string for AI context
 */
export function formatContextForPrompt(results: SearchResult[]): string {
  if (!results || results.length === 0) {
    return '';
  }

  const formattedMessages = results.map((result) => {
    const date = formatTimestamp(result.timestamp);
    const sender = result.senderName || 'Unknown';
    const score = (result.score * 100).toFixed(1);
    
    return `- [${date}] ${sender}: "${result.text}" (relevance: ${score}%)`;
  });

  return `Past conversations:\n${formattedMessages.join('\n')}`;
}


