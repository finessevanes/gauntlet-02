/**
 * TypeScript interfaces for RAG (Retrieval Augmented Generation) operations
 * Defines data structures for semantic search and context retrieval
 */

/**
 * Result from semantic search
 */
export interface SearchResult {
  messageId: string;
  chatId: string;
  senderId: string;
  senderName?: string;
  text: string;
  timestamp: number;
  score: number; // Cosine similarity score (0-1)
}

/**
 * Request payload for semanticSearch Cloud Function
 */
export interface SemanticSearchRequest {
  query: string;
  userId: string;
  limit?: number;
}

/**
 * Response from semanticSearch Cloud Function
 */
export interface SemanticSearchResponse {
  success: boolean;
  results: SearchResult[];
  count: number;
  query: string;
  error?: string;
}

/**
 * RAG context formatted for GPT-4 prompts
 */
export interface RAGContext {
  messages: Array<{
    sender: string;
    date: string;
    content: string;
  }>;
  totalMessages: number;
  relevanceThreshold: number;
}

/**
 * Vector search options
 */
export interface VectorSearchOptions {
  topK: number;
  relevanceThreshold: number;
  filter?: Record<string, any>;
}


