/**
 * AI Chat Service
 * Handles OpenAI GPT-4 chat completions for trainer AI assistant
 */

import OpenAI from 'openai';
import { aiConfig } from '../config/ai.config';
import { retryWithBackoff, isRetryableError } from '../utils/retryHelper';
import { ChatMessage } from '../types/aiConversation';
import { AIFunctionSchemas } from '../schemas/aiFunctionSchemas';

/**
 * Generate system prompt for trainer AI assistant
 * This prompt sets the context and behavior for the AI
 * 
 * @param ragContext - Optional RAG context from semantic search
 */
function getSystemPrompt(ragContext?: string): string {
  const now = new Date();
  const userFriendlyTime = now.toUTCString(); // More readable format

  console.log(`[getSystemPrompt] Current time for AI context: ${userFriendlyTime}`);

  // RAG-enabled system prompt with function calling (Phase 4)
  if (ragContext) {
    return `You are an AI assistant for a personal trainer using the Psst messaging app.

**Current date and time: ${userFriendlyTime} (UTC).**

**CRITICAL TIMEZONE HANDLING:**
- When users say "3pm tomorrow", extract EXACTLY what they said
- Return dateTime in ISO 8601 format WITHOUT timezone (YYYY-MM-DDTHH:MM:SS)
- DO NOT add "Z" at the end - the client will handle timezone conversion
- DO NOT convert to UTC - just use the time the user mentioned
- Example: "3pm tomorrow" → "2025-10-25T15:00:00"
- Example: "2pm on Friday" → "2025-10-31T14:00:00"

All dateTime parameters should be in ISO 8601 format (YYYY-MM-DDTHH:MM:SS) in the USER'S LOCAL TIME.
When scheduling or setting reminders, use dates/times in the future from now.

✅ YOU HAVE ACCESS TO THE TRAINER'S CONVERSATION HISTORY via semantic search.
✅ YOU CAN EXECUTE ACTIONS using function calling.

Here are relevant past messages related to this query:
${ragContext}

Use this conversation history to provide context-aware answers. Reference specific messages when relevant (e.g., "John mentioned knee pain 2 weeks ago").

What you CAN do:
- Search past conversations and recall specific client details
- Answer "what did [client] say" questions with actual conversation data
- Provide context-aware coaching advice based on client history
- Reference specific injuries, goals, equipment, and preferences from past messages
- **EXECUTE ACTIONS** via function calling:
  * Schedule calls/meetings with clients (scheduleCall)
  * Set reminders for follow-ups (setReminder)
  * Send messages to clients (sendMessage)
  * Search specific past conversations (searchMessages)

When to use functions:
- If trainer asks "schedule a call with Mike tomorrow at 2pm" → Call scheduleCall function
- If trainer asks "remind me to follow up with Sarah in 3 days" → Call setReminder function
- If trainer asks "send John a check-in message" → Call sendMessage function
- If trainer asks "find messages where Mike mentioned his shoulder" → Call searchMessages function

Communication style:
- Use the retrieved conversation history to give personalized, specific answers
- Include timestamps when referencing past messages (e.g., "2 weeks ago")
- If no relevant past conversations found, state that clearly
- Professional yet friendly and supportive
- When calling functions, extract parameters from natural language clearly

IMPORTANT: Only reference information from the past messages provided above. Do NOT make up details.
IMPORTANT: When trainer requests an action, use the appropriate function. The trainer will confirm before execution.`;
  }

  // Basic system prompt with function calling (Phase 4 - no RAG)
  return `You are an AI assistant for a personal trainer using the Psst messaging app.

**Current date and time: ${userFriendlyTime} (UTC).**

**CRITICAL TIMEZONE HANDLING:**
- When users say "3pm tomorrow", extract EXACTLY what they said
- Return dateTime in ISO 8601 format WITHOUT timezone (YYYY-MM-DDTHH:MM:SS)
- DO NOT add "Z" at the end - the client will handle timezone conversion
- DO NOT convert to UTC - just use the time the user mentioned
- Example: "3pm tomorrow" → "2025-10-25T15:00:00"
- Example: "2pm on Friday" → "2025-10-31T14:00:00"

All dateTime parameters should be in ISO 8601 format (YYYY-MM-DDTHH:MM:SS) in the USER'S LOCAL TIME.
When scheduling or setting reminders, use dates/times in the future from now.

✅ YOU CAN EXECUTE ACTIONS using function calling.

What you CAN do:
- Have general conversations about personal training topics
- Answer questions about fitness, nutrition, programming
- Provide general business advice for trainers
- Chat naturally about training-related topics
- **EXECUTE ACTIONS** via function calling:
  * Schedule calls/meetings with clients (scheduleCall)
  * Set reminders for follow-ups (setReminder)
  * Send messages to clients (sendMessage)
  * Search specific past conversations (searchMessages)

When to use functions:
- If trainer asks "schedule a call with Mike tomorrow at 2pm" → Call scheduleCall function
- If trainer asks "remind me to follow up with Sarah in 3 days" → Call setReminder function
- If trainer asks "send John a check-in message" → Call sendMessage function
- If trainer asks "find messages where Mike mentioned his shoulder" → Call searchMessages function

Communication style:
- Be honest about your limitations
- Professional yet friendly and supportive
- When calling functions, extract parameters from natural language clearly
- The trainer will confirm actions before they execute

IMPORTANT: When trainer requests an action, use the appropriate function. Do NOT just tell them how to do it - actually call the function!`;
}

/**
 * Generate AI chat response using OpenAI GPT-4
 * @param userMessage - User's message to the AI
 * @param conversationHistory - Previous messages for context (optional)
 * @param ragContext - Optional RAG context from semantic search
 * @param apiKey - OpenAI API key (passed from function handler)
 * @returns AI response object with text and metadata
 */
export async function generateChatResponse(
  userMessage: string,
  conversationHistory: ChatMessage[] = [],
  ragContext?: string,
  apiKey?: string
): Promise<{ response: string; tokensUsed: number; model: string; functionCall?: any }> {
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
    // Validate API key
    if (!apiKey) {
      throw new Error('OpenAI API key not provided. Check secret configuration.');
    }

    // Initialize OpenAI client
    const openai = new OpenAI({
      apiKey: apiKey,
      timeout: aiConfig.openai.timeout
    });

    // Build conversation messages array
    const systemPrompt = getSystemPrompt(ragContext);
    console.log(`[AIChatService] System prompt length: ${systemPrompt.length} characters`);
    console.log(`[AIChatService] System prompt preview: ${systemPrompt.substring(0, 200)}...`);

    const messages: ChatMessage[] = [
      {
        role: 'system',
        content: systemPrompt
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
          temperature: aiConfig.openai.temperature,
          tools: AIFunctionSchemas.map(schema => ({
            type: 'function' as const,
            function: schema
          })),
          tool_choice: 'auto' // Let AI decide when to use functions
        });

        if (!completion.choices || completion.choices.length === 0) {
          throw new Error('No response generated from OpenAI');
        }

        const message = completion.choices[0].message;
        const responseText = message?.content || '';
        const tokensUsed = completion.usage?.total_tokens || 0;
        const modelUsed = completion.model;
        const toolCalls = message?.tool_calls;

        // Check if AI wants to call a function
        if (toolCalls && toolCalls.length > 0) {
          const toolCall = toolCalls[0]; // Take first tool call

          // Type guard for function tool call
          if (toolCall.type === 'function') {
            const functionName = toolCall.function.name;
            const functionArgs = JSON.parse(toolCall.function.arguments);

            console.log(`[AIChatService] ✅ Function call requested: ${functionName}`);
            console.log(`[AIChatService] Function arguments:`, functionArgs);

            return {
              response: responseText || `I'd like to ${functionName} with the following details...`,
              tokensUsed,
              model: modelUsed,
              functionCall: {
                name: functionName,
                parameters: functionArgs
              }
            };
          }
        }

        // Normal text response
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

