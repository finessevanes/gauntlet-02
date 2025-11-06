/**
 * chatWithAI Cloud Function
 * Main endpoint for AI chat functionality
 *
 * Handles:
 * - User authentication
 * - Input validation
 * - Conversation management
 * - OpenAI GPT-4 integration
 * - Error handling
 */

import * as functions from 'firebase-functions';
import { ChatWithAIRequest, ChatWithAIResponse, AIErrorCode } from './types/aiConversation';
import { generateChatResponse, convertToOpenAIFormat } from './services/aiChatService';
import {
  saveConversation,
  saveUserMessage,
  saveAssistantMessage,
  getConversationHistory,
  verifyConversationOwnership
} from './services/conversationService';
import { generateEmbedding } from './services/openaiService';
import { searchVectors, formatContextForPrompt } from './services/vectorSearchService';
import { openaiApiKey, pineconeApiKey } from './config/secrets';

/**
 * Callable Cloud Function for AI chat
 *
 * @param data - Request data containing userId, message, and optional conversationId
 * @param context - Firebase Functions context with auth information
 * @returns ChatWithAIResponse with AI-generated response
 */
export const chatWithAIFunction = functions
  .runWith({
    secrets: [openaiApiKey, pineconeApiKey],
    timeoutSeconds: 540,
    memory: '512MB'
  })
  .https.onCall(
  async (data: ChatWithAIRequest, context): Promise<ChatWithAIResponse> => {
    const startTime = Date.now();

    // Get secret values
    console.log('[chatWithAI] 🔑 LOADING SECRETS FROM FIREBASE');
    const openaiKey = openaiApiKey.value();
    const pineconeKey = pineconeApiKey.value();

    // Log API key status for debugging
    console.log('[chatWithAI] Initializing AI chat function');

    // More detailed key logging
    if (!openaiKey) {
      console.error('[chatWithAI] ❌ CRITICAL: OpenAI API key is MISSING or EMPTY');
      console.error('[chatWithAI] Check Firebase config: firebase functions:config:get openai');
    } else {
      console.log(`[chatWithAI] ✅ OpenAI key loaded: ${openaiKey.length} characters`);
      console.log(`[chatWithAI] Key starts with: ${openaiKey.substring(0, 10)}`);
      console.log(`[chatWithAI] Key ends with: ${openaiKey.substring(openaiKey.length - 5)}`);

      // Warn if key format looks wrong
      if (!openaiKey.startsWith('sk-')) {
        console.error('[chatWithAI] ⚠️ WARNING: OpenAI key does not start with "sk-"! This is likely invalid!');
      }
    }

    console.log(`[chatWithAI] Pinecone key configured: ${pineconeKey ? 'YES' : 'NO'}`);
    
    try {
      // ========================================
      // 1. AUTHENTICATION
      // ========================================
      
      if (!context.auth) {
        console.warn('[chatWithAI] Unauthenticated request rejected');
        throw new functions.https.HttpsError(
          'unauthenticated',
          'You must be authenticated to use AI chat'
        );
      }

      const authenticatedUserId = context.auth.uid;
      
      // Verify userId matches authenticated user
      if (data.userId !== authenticatedUserId) {
        console.warn(`[chatWithAI] User ID mismatch: ${data.userId} vs ${authenticatedUserId}`);
        throw new functions.https.HttpsError(
          'permission-denied',
          'User ID does not match authenticated user'
        );
      }

      // ========================================
      // 2. INPUT VALIDATION
      // ========================================

      const { message, conversationId, timezone } = data;
      console.log(`[chatWithAI] Incoming timezone: ${timezone || 'none provided'}`);

      // Validate message
      if (!message || typeof message !== 'string') {
        console.warn('[chatWithAI] Invalid message format');
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Message must be a non-empty string'
        );
      }

      const trimmedMessage = message.trim();

      if (trimmedMessage.length === 0) {
        console.warn('[chatWithAI] Empty message rejected');
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Message cannot be empty'
        );
      }

      if (trimmedMessage.length > 4000) {
        console.warn(`[chatWithAI] Message too long: ${trimmedMessage.length} characters`);
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Message is too long. Maximum 4000 characters allowed.'
        );
      }

      // Validate conversationId if provided
      if (conversationId) {
        const hasAccess = await verifyConversationOwnership(conversationId, authenticatedUserId);
        if (!hasAccess) {
          console.warn(`[chatWithAI] Unauthorized access to conversation ${conversationId}`);
          throw new functions.https.HttpsError(
            'permission-denied',
            'You do not have access to this conversation'
          );
        }
      }

      // ========================================
      // 3. GET CONVERSATION HISTORY (if existing conversation)
      // ========================================
      
      let conversationContext: Array<{ role: 'user' | 'assistant'; content: string }> = [];

      if (conversationId) {
        try {
          const history = await getConversationHistory(conversationId, 10);
          conversationContext = history.map(msg => ({
            role: msg.role,
            content: msg.content
          }));
        } catch (error: any) {
          console.error('[chatWithAI] Failed to load conversation history:', error);
          // Continue without context rather than failing
          conversationContext = [];
        }
      }

      // ========================================
      // 4. RAG PIPELINE - SEMANTIC SEARCH FOR CONTEXT
      // ========================================
      
      let ragContext: string | undefined;
      const ragStartTime = Date.now();

      try {
        // Generate embedding for user's query
        const queryEmbedding = await generateEmbedding(trimmedMessage, openaiKey);

        if (queryEmbedding) {
          // Search for relevant past messages
          // Lowered threshold to 0.2 to catch semantic variations in queries
          const searchResults = await searchVectors(queryEmbedding, authenticatedUserId, pineconeKey, {
            topK: 10,
            relevanceThreshold: 0.2
          });

          if (searchResults && searchResults.length > 0) {
            // Format results for GPT-4 prompt
            ragContext = formatContextForPrompt(searchResults);
          } else {
            ragContext = undefined;
          }
        } else {
          ragContext = undefined;
        }
      } catch (error: any) {
        // RAG failure should not block the AI response
        // Continue without RAG context
        const ragDuration = Date.now() - ragStartTime;
        console.error('[chatWithAI] ========================================');
        console.error('[chatWithAI] ❌ RAG PIPELINE FAILED');
        console.error('[chatWithAI] Duration before failure:', ragDuration, 'ms');
        console.error('[chatWithAI] Error:', error.message);
        console.error('[chatWithAI] Stack:', error.stack);
        console.error('[chatWithAI] ========================================');
        ragContext = undefined;
      }

      // ========================================
      // 5. GENERATE AI RESPONSE (with optional RAG context)
      // ========================================
      
      let aiResponse: string;
      let tokensUsed: number;
      let modelUsed: string;
      let functionCall: any = undefined;

      try {
        const chatMessages = convertToOpenAIFormat(conversationContext);
        const result = await generateChatResponse(trimmedMessage, chatMessages, ragContext, openaiKey, timezone);

        aiResponse = result.response;
        tokensUsed = result.tokensUsed;
        modelUsed = result.model;
        functionCall = result.functionCall;

        if (functionCall) {
          console.log('[chatWithAI] Function call detected from OpenAI:');
          console.log(`  - Name: ${functionCall.name}`);
          console.log(`  - Parameters: ${JSON.stringify(functionCall.parameters)}`);
        } else {
          console.log('[chatWithAI] No function call detected for this response.');
        }
        
      } catch (error: any) {
        console.error('[chatWithAI] ❌ AI generation failed:', {
          errorCode: error.code,
          errorMessage: error.message,
          errorStatus: error.status || error.statusCode,
          errorType: error.constructor.name,
          fullError: JSON.stringify(error, null, 2)
        });

        // Map error codes to user-friendly messages
        const errorCode = error.code || AIErrorCode.INTERNAL_ERROR;
        const errorMessage = error.message || 'Unknown error';

        switch (errorCode) {
          case AIErrorCode.RATE_LIMIT_EXCEEDED:
            console.warn('[chatWithAI] Rate limit hit');
            throw new functions.https.HttpsError(
              'resource-exhausted',
              'Too many requests. Please wait 30 seconds and try again.'
            );

          case AIErrorCode.OPENAI_TIMEOUT:
            console.warn('[chatWithAI] OpenAI timeout');
            throw new functions.https.HttpsError(
              'deadline-exceeded',
              'AI is taking too long to respond. Please try again in a moment.'
            );

          case AIErrorCode.INVALID_REQUEST:
            console.warn('[chatWithAI] Invalid request to OpenAI');
            throw new functions.https.HttpsError(
              'invalid-argument',
              'Invalid request format. Please try rephrasing your message.'
            );

          case AIErrorCode.OPENAI_ERROR:
            console.warn('[chatWithAI] OpenAI service error:', errorMessage);
            throw new functions.https.HttpsError(
              'unavailable',
              'AI service is temporarily unavailable. Please try again later.'
            );

          default:
            // Check for authentication error specifically
            if (errorMessage.includes('authentication') || errorMessage.includes('401')) {
              console.error('[chatWithAI] ⚠️ OpenAI AUTHENTICATION ERROR - Check your API key!');
              throw new functions.https.HttpsError(
                'unauthenticated',
                'OpenAI authentication failed. Please check your API key configuration.'
              );
            }

            // Log unexpected errors with details
            console.error('[chatWithAI] Unexpected error type. Details logged above.');
            throw new functions.https.HttpsError(
              'internal',
              `An unexpected error occurred: ${errorMessage}`
            );
        }
      }

      // ========================================
      // 6. SAVE TO FIRESTORE
      // ========================================
      
      let finalConversationId: string;

      try {
        // Save or update conversation
        finalConversationId = await saveConversation(
          conversationId,
          authenticatedUserId,
          trimmedMessage,
          aiResponse
        );

        // Save user message
        await saveUserMessage(finalConversationId, trimmedMessage);

        // Save assistant message
        await saveAssistantMessage(
          finalConversationId,
          aiResponse,
          modelUsed,
          tokensUsed
        );

      } catch (error: any) {
        console.error('[chatWithAI] Failed to save conversation:', error);
        // Continue and return response even if save fails
        // This ensures user gets the AI response
        finalConversationId = conversationId || 'error-saving';
      }

      // ========================================
      // 7. RETURN RESPONSE
      // ========================================

      const response: ChatWithAIResponse = {
        success: true,
        response: aiResponse,
        conversationId: finalConversationId,
        tokensUsed
      };

      // Include function call info if present
      if (functionCall) {
        response.functionCall = functionCall;
      }

      return response;

    } catch (error: any) {
      const duration = Date.now() - startTime;
      console.error(`[chatWithAI] ❌ Request failed after ${duration}ms:`, error);
      
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
