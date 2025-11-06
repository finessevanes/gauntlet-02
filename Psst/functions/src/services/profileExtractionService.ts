/**
 * Profile Extraction Service
 * Extracts client profile information from conversations using OpenAI GPT-4o-mini
 * PR #007: Contextual Intelligence (Auto Client Profiles)
 */

import OpenAI from 'openai';
import * as admin from 'firebase-admin';
import { retryWithBackoff, isRetryableError } from '../utils/retryHelper';

/**
 * Categories for profile information
 */
export enum ProfileCategory {
  INJURIES = 'injuries',
  GOALS = 'goals',
  EQUIPMENT = 'equipment',
  PREFERENCES = 'preferences',
  TRAVEL = 'travel',
  STRESS_FACTORS = 'stressFactors'
}

/**
 * Extracted profile item
 */
export interface ProfileItem {
  id: string;
  text: string;
  category: ProfileCategory;
  timestamp: admin.firestore.Timestamp;
  sourceMessageId: string;
  sourceChatId: string;
  confidenceScore: number; // 0.0-1.0
  isManuallyEdited: boolean;
  editedAt: admin.firestore.Timestamp | null;
  createdBy: 'ai' | 'manual';
}

/**
 * Extraction result from OpenAI
 */
interface ExtractionResult {
  items: Array<{
    text: string;
    category: ProfileCategory;
    confidence: number;
  }>;
}

/**
 * Extract profile information from a message using OpenAI GPT-4o-mini
 * @param messageText - Text of the message to analyze
 * @param messageId - Firestore message ID
 * @param chatId - Firestore chat ID
 * @param apiKey - OpenAI API key
 * @returns Array of ProfileItem or null if nothing extracted
 */
export async function extractProfileInfo(
  messageText: string,
  messageId: string,
  chatId: string,
  apiKey: string
): Promise<ProfileItem[] | null> {
  // Validate input
  if (!messageText || typeof messageText !== 'string') {
    console.warn('[ProfileExtractionService] Invalid message text provided');
    return null;
  }

  const trimmedText = messageText.trim();

  // Skip empty messages
  if (trimmedText.length === 0) {
    console.info('[ProfileExtractionService] Skipping empty message');
    return null;
  }

  // Skip very short messages (< 10 characters)
  if (trimmedText.length < 10) {
    console.info('[ProfileExtractionService] Skipping short message');
    return null;
  }

  try {
    // Validate API key
    if (!apiKey) {
      throw new Error('OpenAI API key not provided');
    }

    // Initialize OpenAI client
    const openai = new OpenAI({
      apiKey: apiKey,
      timeout: 60000 // 60 second timeout
    });

    // Extract profile information with retry logic
    const extractionResult = await retryWithBackoff(async () => {
      try {
        console.log('[ProfileExtractionService] Analyzing message for profile info...');

        // GPT-4o-mini prompt for profile extraction
        const response = await openai.chat.completions.create({
          model: 'gpt-4o-mini',
          messages: [
            {
              role: 'system',
              content: `You are an AI assistant that extracts key client information from fitness trainer conversations.

Extract only factual, actionable information in these categories:
- injuries: Physical injuries, pain, limitations (e.g., "shoulder pain", "knee injury")
- goals: Fitness goals, targets (e.g., "lose 20 lbs", "run marathon")
- equipment: Available equipment (e.g., "home gym", "dumbbells only")
- preferences: Workout preferences, dietary restrictions (e.g., "prefers morning workouts", "vegetarian")
- travel: Travel schedules, location changes (e.g., "in Dallas monthly", "traveling next week")
- stressFactors: Life stress, busy periods (e.g., "new job", "finals week")

Rules:
1. Extract ONLY from CLIENT messages (not trainer instructions)
2. Be specific and concise (5-15 words per item)
3. Assign confidence: 0.9-1.0 (explicit), 0.7-0.9 (implied), 0.5-0.7 (ambiguous)
4. Skip greetings, small talk, and non-actionable info
5. Extract multiple items if present in one message

Return a JSON object with this structure:
{
  "items": [
    {"text": "extracted info", "category": "injuries", "confidence": 0.9},
    ...
  ]
}

If no relevant information, return {"items": []}`
            },
            {
              role: 'user',
              content: messageText
            }
          ],
          temperature: 0.1, // Low temperature for consistency
          max_tokens: 500,
          response_format: { type: 'json_object' }
        });

        const content = response.choices[0]?.message?.content;

        if (!content) {
          console.log('[ProfileExtractionService] No content in response');
          return null;
        }

        // Parse JSON response
        const parsed: ExtractionResult = JSON.parse(content);

        if (!parsed.items || parsed.items.length === 0) {
          console.log('[ProfileExtractionService] No profile items extracted');
          return null;
        }

        // Filter items with confidence >= 0.5
        const validItems = parsed.items.filter(item => item.confidence >= 0.5);

        if (validItems.length === 0) {
          console.log('[ProfileExtractionService] All items below confidence threshold');
          return null;
        }

        console.log(`[ProfileExtractionService] ✅ Extracted ${validItems.length} profile items`);

        // Convert to ProfileItem format
        const profileItems: ProfileItem[] = validItems.map(item => ({
          id: `${messageId}_${Math.random().toString(36).substring(7)}`,
          text: item.text,
          category: item.category,
          timestamp: admin.firestore.Timestamp.now(),
          sourceMessageId: messageId,
          sourceChatId: chatId,
          confidenceScore: item.confidence,
          isManuallyEdited: false,
          editedAt: null,
          createdBy: 'ai' as const
        }));

        return profileItems;

      } catch (error: any) {
        // Handle OpenAI-specific errors
        if (error.status === 401 || error.statusCode === 401) {
          throw new Error(`OpenAI authentication failed: ${error.message}`);
        }

        if (error.status === 429 || error.statusCode === 429) {
          // Rate limit
          const retryAfter = error.headers?.['retry-after'];
          if (retryAfter) {
            const delayMs = parseInt(retryAfter) * 1000;
            console.log(`[ProfileExtractionService] Rate limited. Retry after ${retryAfter}s`);
            await new Promise(resolve => setTimeout(resolve, delayMs));
          }
          throw error;
        }

        if (error.status === 400 || error.statusCode === 400) {
          throw new Error(`Invalid request to OpenAI: ${error.message}`);
        }

        if (isRetryableError(error)) {
          console.log('[ProfileExtractionService] Retryable error encountered');
          throw error;
        }

        throw error;
      }
    }, 3, 1000, 10000); // 3 attempts, 1s initial delay, 10s max delay

    return extractionResult;

  } catch (error: any) {
    console.error('[ProfileExtractionService] Failed to extract profile info:', error.message);
    console.error('[ProfileExtractionService] Error details:', error);
    // Return null instead of throwing - extraction failure shouldn't break message send
    return null;
  }
}

/**
 * Check if similar profile item already exists (duplicate detection)
 * Uses simple text matching for now (can be enhanced with embeddings later)
 * @param newItem - New profile item to check
 * @param existingItems - Existing profile items in the category
 * @returns Existing item if duplicate found, null otherwise
 */
export function findDuplicateItem(
  newItem: ProfileItem,
  existingItems: ProfileItem[]
): ProfileItem | null {
  for (const existing of existingItems) {
    // Simple duplicate detection: check if text is very similar
    const newTextLower = newItem.text.toLowerCase();
    const existingTextLower = existing.text.toLowerCase();

    // Exact match
    if (newTextLower === existingTextLower) {
      return existing;
    }

    // Substring match (one contains the other)
    if (newTextLower.includes(existingTextLower) || existingTextLower.includes(newTextLower)) {
      // Check if they're at least 70% similar in length
      const lengthRatio = Math.min(newTextLower.length, existingTextLower.length) /
        Math.max(newTextLower.length, existingTextLower.length);

      if (lengthRatio >= 0.7) {
        return existing;
      }
    }
  }

  return null;
}
