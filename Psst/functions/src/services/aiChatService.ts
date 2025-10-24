/**
 * AI Chat Service
 * Handles OpenAI GPT-4 chat completions for trainer AI assistant
 */

import OpenAI from 'openai';
import * as functions from 'firebase-functions';
import { aiConfig } from '../config/ai.config';
import { retryWithBackoff, isRetryableError } from '../utils/retryHelper';
import { ChatMessage } from '../types/aiConversation';

/**
 * Generate system prompt for trainer AI assistant
 * This prompt sets the context and behavior for the AI
 */
function getSystemPrompt(): string {
  return `You are an AI assistant for a personal trainer using the Psst messaging app. Your role is to help trainers manage their client conversations and business.

Key responsibilities:
- Answer questions about past client conversations and interactions
- Provide insights into client goals, injuries, equipment, and preferences
- Help trainers recall important details about their clients
- Suggest relevant follow-up actions

Communication style:
- Professional yet friendly and supportive
- Clear and concise responses
- Focus on actionable information
- Use trainer-appropriate language

Context:
- You have access to the trainer's message history with clients
- When asked about a client, search past conversations for relevant information
- If you don't have enough information, say so clearly
- Never make up information about clients

Remember: You're a tool to help trainers be more effective, not a replacement for their expertise.`;
}

/**
 * Generate AI chat response using OpenAI GPT-4
 * @param userMessage - User's message to the AI
 * @param conversationHistory - Previous messages for context (optional)
 * @returns AI response object with text and metadata
 */
export async function generateChatResponse(
  userMessage: string,
  conversationHistory: ChatMessage[] = []
): Promise<{ response: string; tokensUsed: number; model: string }> {
  // Validate input
  if (!userMessage || typeof userMessage !== 'string') {
    throw new Error('Invalid message: must be a non-empty string');
  }

  const trimmedMessage = userMessage.trim();
  
  if (trimmedMessage.length === 0) {
    throw new Error('Message cannot be empty');
  }

  if (trimmedMessage.length > aiConfig.chat.messageMaxLength) {
    throw new Error(`Message too long. Maximum ${aiConfig.chat.messageMaxLength} characters allowed.`);
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

    // Build conversation messages array
    const messages: ChatMessage[] = [
      {
        role: 'system',
        content: getSystemPrompt()
      },
      ...conversationHistory,
      {
        role: 'user',
        content: trimmedMessage
      }
    ];

    console.log(`[AIChatService] Generating chat response with ${messages.length} messages in context`);

    // Generate chat completion with retry logic
    const result = await retryWithBackoff(async () => {
      try {
        const completion = await openai.chat.completions.create({
          model: aiConfig.openai.chatModel,
          messages: messages,
          max_tokens: aiConfig.openai.maxTokens,
          temperature: aiConfig.openai.temperature
        });

        if (!completion.choices || completion.choices.length === 0) {
          throw new Error('No response generated from OpenAI');
        }

        const responseText = completion.choices[0].message?.content || '';
        const tokensUsed = completion.usage?.total_tokens || 0;
        const modelUsed = completion.model;

        console.log(`[AIChatService] ✅ Chat response generated (${tokensUsed} tokens, model: ${modelUsed})`);

        return {
          response: responseText,
          tokensUsed,
          model: modelUsed
        };

      } catch (error: any) {
        // Handle OpenAI-specific errors
        
        // Authentication errors - don't retry
        if (error.status === 401 || error.statusCode === 401) {
          const authError = new Error('OpenAI authentication failed. Check API key.');
          (authError as any).code = 'OPENAI_ERROR';
          throw authError;
        }
        
        // Rate limit errors - retry with backoff
        if (error.status === 429 || error.statusCode === 429) {
          console.warn('[AIChatService] Rate limit hit, will retry...');
          const rateLimitError = new Error('Rate limit exceeded. Please wait a moment.');
          (rateLimitError as any).code = 'RATE_LIMIT_EXCEEDED';
          
          // Extract retry-after header if available
          const retryAfter = error.headers?.['retry-after'];
          if (retryAfter) {
            const delayMs = parseInt(retryAfter) * 1000;
            console.log(`[AIChatService] Retry after ${retryAfter}s`);
            await new Promise(resolve => setTimeout(resolve, delayMs));
          }
          
          throw rateLimitError; // Will be retried by retryWithBackoff
        }
        
        // Invalid request errors - don't retry
        if (error.status === 400 || error.statusCode === 400) {
          const invalidError = new Error(`Invalid request: ${error.message}`);
          (invalidError as any).code = 'INVALID_REQUEST';
          throw invalidError;
        }
        
        // Timeout errors
        if (error.code === 'ETIMEDOUT' || error.message?.includes('timeout')) {
          const timeoutError = new Error('Request timed out. AI is taking too long to respond.');
          (timeoutError as any).code = 'OPENAI_TIMEOUT';
          throw timeoutError;
        }
        
        // Check if error is retryable (network issues, 5xx errors)
        if (isRetryableError(error)) {
          console.log('[AIChatService] Retryable error encountered, will retry...');
          throw error; // Will be retried
        }
        
        // Unknown error - don't retry
        console.error('[AIChatService] Non-retryable error:', error);
        const unknownError = new Error(`AI service error: ${error.message}`);
        (unknownError as any).code = 'OPENAI_ERROR';
        throw unknownError;
      }
    }, aiConfig.retry.maxAttempts, aiConfig.retry.initialDelay, aiConfig.retry.maxDelay);

    return result;

  } catch (error: any) {
    console.error('[AIChatService] Failed to generate chat response:', error.message);
    
    // Preserve error code if it exists
    if (error.code) {
      throw error;
    }
    
    // Default to internal error
    const internalError = new Error(`Failed to generate AI response: ${error.message}`);
    (internalError as any).code = 'INTERNAL_ERROR';
    throw internalError;
  }
}

/**
 * Convert Firestore messages to OpenAI chat format
 * Limits conversation history to most recent messages for context management
 */
export function convertToOpenAIFormat(
  messages: Array<{ role: 'user' | 'assistant'; content: string }>
): ChatMessage[] {
  // Limit to recent messages for context window management
  const recentMessages = messages.slice(-aiConfig.chat.conversationContextLimit);
  
  return recentMessages.map(msg => ({
    role: msg.role,
    content: msg.content
  }));
}

