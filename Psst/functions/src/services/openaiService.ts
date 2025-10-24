/**
 * OpenAI Service
 * Handles embedding generation using OpenAI's text-embedding-3-small model
 */

import OpenAI from 'openai';
import * as functions from 'firebase-functions';
import { aiConfig } from '../config/ai.config';
import { retryWithBackoff, isRetryableError } from '../utils/retryHelper';

/**
 * Generate embedding for text using OpenAI API
 * @param text - Text to embed
 * @returns Array of 1536 floats representing the embedding
 */
export async function generateEmbedding(text: string): Promise<number[] | null> {
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
    // Get API key from Firebase config
    const apiKey = functions.config().openai?.api_key;
    
    if (!apiKey) {
      throw new Error('OpenAI API key not configured. Set with: firebase functions:config:set openai.api_key="sk-..."');
    }

    // Initialize OpenAI client
    const openai = new OpenAI({
      apiKey: apiKey,
      timeout: aiConfig.openai.timeout
    });

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
        if (error.status === 401 || error.statusCode === 401) {
          // Invalid API key - don't retry
          throw new Error(`OpenAI authentication failed. Check API key. Error: ${error.message}`);
        }
        
        if (error.status === 429 || error.statusCode === 429) {
          // Rate limit - extract retry-after if available
          const retryAfter = error.headers?.['retry-after'];
          if (retryAfter) {
            const delayMs = parseInt(retryAfter) * 1000;
            console.log(`[OpenAIService] Rate limited. Retry after ${retryAfter}s`);
            await new Promise(resolve => setTimeout(resolve, delayMs));
          }
          throw error; // Will be retried by retryWithBackoff
        }
        
        if (error.status === 400 || error.statusCode === 400) {
          // Invalid request - don't retry
          throw new Error(`Invalid request to OpenAI: ${error.message}`);
        }
        
        // Check if error is retryable
        if (isRetryableError(error)) {
          console.log('[OpenAIService] Retryable error encountered');
          throw error; // Will be retried
        }
        
        // Unknown error - don't retry
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

