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
    // Get secret values
    const openaiKey = openaiApiKey.value();
    const pineconeKey = pineconeApiKey.value();
    const startTime = Date.now();
    
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

      console.log(`[chatWithAI] Request from user: ${authenticatedUserId}`);

      // ========================================
      // 2. INPUT VALIDATION
      // ========================================

      const { message, conversationId, timezone } = data;

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

      console.log(`[chatWithAI] Processing message (${trimmedMessage.length} chars, conversation: ${conversationId || 'new'})`);

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
          console.log(`[chatWithAI] Loaded ${conversationContext.length} messages for context`);
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
        console.log('[chatWithAI] ========================================');
        console.log('[chatWithAI] 🔍 STARTING RAG PIPELINE');
        console.log('[chatWithAI] Query:', trimmedMessage);
        console.log('[chatWithAI] User ID:', authenticatedUserId);
        console.log('[chatWithAI] ========================================');
        
        // Generate embedding for user's query
        const embeddingStartTime = Date.now();
        const queryEmbedding = await generateEmbedding(trimmedMessage, openaiKey);
        const embeddingDuration = Date.now() - embeddingStartTime;
        
        console.log(`[chatWithAI] ⏱️  Embedding generation: ${embeddingDuration}ms`);

        if (queryEmbedding) {
          console.log(`[chatWithAI] ✅ Generated embedding vector (${queryEmbedding.length} dimensions)`);
          
          // Search for relevant past messages
          const searchStartTime = Date.now();
          // Lowered threshold to 0.2 to catch semantic variations in queries
          const searchResults = await searchVectors(queryEmbedding, authenticatedUserId, pineconeKey, {
            topK: 10,
            relevanceThreshold: 0.2
          });
          const searchDuration = Date.now() - searchStartTime;
          
          console.log(`[chatWithAI] ⏱️  Vector search: ${searchDuration}ms`);
          console.log(`[chatWithAI] 📊 Search returned ${searchResults?.length || 0} results`);

          if (searchResults && searchResults.length > 0) {
            // Log each result for debugging
            searchResults.forEach((result, index) => {
              console.log(`[chatWithAI] Result ${index + 1}: "${result.text.substring(0, 50)}..." (score: ${result.score.toFixed(4)})`);
            });
            
            // Format results for GPT-4 prompt
            ragContext = formatContextForPrompt(searchResults);
            
            console.log('[chatWithAI] ========================================');
            console.log('[chatWithAI] 🎯 RAG CONTEXT FOR GPT-4:');
            console.log(ragContext);
            console.log('[chatWithAI] ========================================');
            
            const ragDuration = Date.now() - ragStartTime;
            console.log(`[chatWithAI] ✅ RAG pipeline complete: ${searchResults.length} relevant messages found (${ragDuration}ms total)`);
          } else {
            console.log('[chatWithAI] ⚠️  No relevant past messages found (all results below 0.7 threshold)');
            ragContext = undefined;
          }
        } else {
          console.log('[chatWithAI] ❌ Failed to generate embedding (returned null)');
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
        const gptStartTime = Date.now();

        console.log('[chatWithAI] ========================================');
        console.log('[chatWithAI] 🤖 CALLING GPT-4');
        console.log('[chatWithAI] RAG context available:', ragContext ? 'YES' : 'NO');
        console.log('[chatWithAI] Conversation context messages:', conversationContext.length);
        console.log('[chatWithAI] User timezone:', timezone || 'UTC (not provided)');
        console.log('[chatWithAI] ========================================');

        const chatMessages = convertToOpenAIFormat(conversationContext);
        const result = await generateChatResponse(trimmedMessage, chatMessages, ragContext, openaiKey, timezone);

        const gptDuration = Date.now() - gptStartTime;

        aiResponse = result.response;
        tokensUsed = result.tokensUsed;
        modelUsed = result.model;
        functionCall = result.functionCall;
        
        console.log('[chatWithAI] ========================================');
        console.log(`[chatWithAI] ✅ AI RESPONSE GENERATED`);
        console.log(`[chatWithAI] ⏱️  GPT-4 duration: ${gptDuration}ms`);
        console.log(`[chatWithAI] 📊 Tokens used: ${tokensUsed}`);
        console.log(`[chatWithAI] 🤖 Model: ${modelUsed}`);
        console.log(`[chatWithAI] 🎯 RAG was: ${ragContext ? 'ENABLED ✅' : 'DISABLED ❌'}`);
        console.log(`[chatWithAI] 🔧 Function call: ${functionCall ? `${functionCall.name}` : 'NONE'}`);
        console.log(`[chatWithAI] Response preview: "${aiResponse.substring(0, 100)}..."`);
        console.log('[chatWithAI] ========================================');
        
      } catch (error: any) {
        console.error('[chatWithAI] AI generation failed:', error);
        
        // Map error codes to user-friendly messages
        const errorCode = error.code || AIErrorCode.INTERNAL_ERROR;
        
        switch (errorCode) {
          case AIErrorCode.RATE_LIMIT_EXCEEDED:
            throw new functions.https.HttpsError(
              'resource-exhausted',
              'Too many requests. Please wait 30 seconds and try again.'
            );
          
          case AIErrorCode.OPENAI_TIMEOUT:
            throw new functions.https.HttpsError(
              'deadline-exceeded',
              'AI is taking too long to respond. Please try again in a moment.'
            );
          
          case AIErrorCode.INVALID_REQUEST:
            throw new functions.https.HttpsError(
              'invalid-argument',
              'Invalid request format. Please try rephrasing your message.'
            );
          
          case AIErrorCode.OPENAI_ERROR:
            throw new functions.https.HttpsError(
              'unavailable',
              'AI service is temporarily unavailable. Please try again later.'
            );
          
          default:
            throw new functions.https.HttpsError(
              'internal',
              'An unexpected error occurred. Please try again.'
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

        console.log(`[chatWithAI] ✅ Conversation saved: ${finalConversationId}`);
        
      } catch (error: any) {
        console.error('[chatWithAI] Failed to save conversation:', error);
        // Continue and return response even if save fails
        // This ensures user gets the AI response
        finalConversationId = conversationId || 'error-saving';
      }

      // ========================================
      // 7. RETURN RESPONSE
      // ========================================
      
      const duration = Date.now() - startTime;
      
      console.log('[chatWithAI] ========================================');
      console.log('[chatWithAI] 🎉 REQUEST COMPLETE');
      console.log(`[chatWithAI] ⏱️  Total duration: ${duration}ms`);
      console.log('[chatWithAI] Performance breakdown:');
      console.log('[chatWithAI]   - RAG pipeline:', ragContext ? 'enabled' : 'disabled');
      console.log('[chatWithAI]   - Total time:', duration, 'ms');
      if (duration > 3000) {
        console.warn('[chatWithAI] ⚠️  WARNING: Response time exceeded 3 second target!');
      }
      console.log('[chatWithAI] ========================================');

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

