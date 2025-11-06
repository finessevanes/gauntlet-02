/**
 * OpenAI Service
 * Handles embedding generation using OpenAI's text-embedding-3-small model
 */

import OpenAI from 'openai';
import { aiConfig } from '../config/ai.config';
import { retryWithBackoff, isRetryableError } from '../utils/retryHelper';

/**
 * Generate embedding for text using OpenAI API
 * @param text - Text to embed
 * @param apiKey - OpenAI API key (passed from function handler)
 * @returns Array of 1536 floats representing the embedding
 */
export async function generateEmbedding(text: string, apiKey: string): Promise<number[] | null> {
  // Validate input
  if (!text || typeof text !== 'string') {
    console.warn('[OpenAIService] Invalid text provided for embedding');
    return null;
  }

  const trimmedText = text.trim();

  // Skip empty messages
  if (trimmedText.length === 0) {
    console.info('[OpenAIService] Skipping empty text');
    return null;
  }

  // Warn if text is very long (OpenAI limit is ~8000 tokens)
  if (trimmedText.length > 8000) {
    console.warn(`[OpenAIService] Text is very long (${trimmedText.length} characters). May exceed token limit.`);
  }

  try {
    // Validate API key
    if (!apiKey) {
      console.error('[OpenAIService] ❌ CRITICAL: API key not provided');
      throw new Error('OpenAI API key not provided. Check secret configuration.');
    }

    // Detailed API key validation
    console.log('[OpenAIService] 🔑 Validating OpenAI API Key');
    console.log(`[OpenAIService] Key length: ${apiKey.length} characters`);
    console.log(`[OpenAIService] Key starts with: ${apiKey.substring(0, 10)}`);
    console.log(`[OpenAIService] Key ends with: ${apiKey.substring(apiKey.length - 5)}`);

    if (!apiKey.startsWith('sk-proj-') && !apiKey.startsWith('sk-')) {
      console.error('[OpenAIService] ⚠️ WARNING: Key format looks invalid! Should start with sk-proj- or sk-');
    }

    // Initialize OpenAI client
    console.log('[OpenAIService] Initializing OpenAI client...');
    const openai = new OpenAI({
      apiKey: apiKey,
      timeout: aiConfig.openai.timeout
    });
    console.log(`[OpenAIService] ✅ OpenAI client initialized with timeout: ${aiConfig.openai.timeout}ms`);

    // Generate embedding with retry logic
    const embedding = await retryWithBackoff(async () => {
      try {
        console.log('[OpenAIService] Generating embedding...');
        
        const response = await openai.embeddings.create({
          model: aiConfig.openai.embeddingModel,
          input: trimmedText,
          dimensions: aiConfig.openai.dimensions
        });

        if (!response.data || response.data.length === 0) {
          throw new Error('Empty response from OpenAI API');
        }

        const embedding = response.data[0].embedding;
        
        console.log(`[OpenAIService] ✅ Embedding generated successfully (${embedding.length} dimensions)`);
        
        return embedding;
        
      } catch (error: any) {
        // Handle OpenAI-specific errors
        const status = error.status || error.statusCode;

        console.error('[OpenAIService] Request failed:', {
          status,
          message: error.message,
          code: error.code,
          type: error.constructor.name
        });

        if (status === 401) {
          // Invalid API key - don't retry
          const authError = new Error(`❌ OpenAI authentication failed. Check your API key. Error: ${error.message}`) as any;
          authError.code = 'OPENAI_AUTH_ERROR';
          console.error('[OpenAIService] AUTH ERROR - This typically means the API key is invalid or expired');
          throw authError;
        }

        if (status === 429) {
          // Rate limit - extract retry-after if available
          const retryAfter = error.headers?.['retry-after'];
          if (retryAfter) {
            const delayMs = parseInt(retryAfter) * 1000;
            console.warn(`[OpenAIService] Rate limited. Retry after ${retryAfter}s`);
            await new Promise(resolve => setTimeout(resolve, delayMs));
          }
          const rateLimitError = new Error('Rate limited by OpenAI') as any;
          rateLimitError.code = 'RATE_LIMIT_EXCEEDED';
          throw rateLimitError;
        }

        if (status === 400) {
          // Invalid request - don't retry
          const invalidError = new Error(`Invalid request to OpenAI: ${error.message}`) as any;
          invalidError.code = 'INVALID_REQUEST';
          throw invalidError;
        }

        if (status === 500 || status === 502 || status === 503 || status === 504) {
          console.warn(`[OpenAIService] OpenAI server error (${status}): ${error.message}`);
          const openaiError = new Error(`OpenAI service error (${status})`) as any;
          openaiError.code = 'OPENAI_ERROR';
          throw openaiError;
        }

        // Check if error is retryable
        if (isRetryableError(error)) {
          console.log('[OpenAIService] Retryable error encountered, will retry');
          throw error; // Will be retried
        }

        // Unknown error - log and rethrow
        console.error('[OpenAIService] Unknown error type encountered');
        throw error;
      }
    }, aiConfig.retry.maxAttempts, aiConfig.retry.initialDelay, aiConfig.retry.maxDelay);

    return embedding;

  } catch (error: any) {
    console.error('[OpenAIService] Failed to generate embedding after retries:', error.message);
    console.error('[OpenAIService] Error details:', error);
    throw error; // Re-throw to trigger Cloud Functions retry
  }
}

