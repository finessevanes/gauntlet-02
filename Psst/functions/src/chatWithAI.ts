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

/**
 * Callable Cloud Function for AI chat
 * 
 * @param data - Request data containing userId, message, and optional conversationId
 * @param context - Firebase Functions context with auth information
 * @returns ChatWithAIResponse with AI-generated response
 */
export const chatWithAIFunction = functions.https.onCall(
  async (data: ChatWithAIRequest, context): Promise<ChatWithAIResponse> => {
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
      
      const { message, conversationId } = data;

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
      // 4. GENERATE AI RESPONSE
      // ========================================
      
      let aiResponse: string;
      let tokensUsed: number;
      let modelUsed: string;

      try {
        const chatMessages = convertToOpenAIFormat(conversationContext);
        const result = await generateChatResponse(trimmedMessage, chatMessages);
        
        aiResponse = result.response;
        tokensUsed = result.tokensUsed;
        modelUsed = result.model;
        
        console.log(`[chatWithAI] ✅ AI response generated (${tokensUsed} tokens)`);
        
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
      // 5. SAVE TO FIRESTORE
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
      // 6. RETURN RESPONSE
      // ========================================
      
      const duration = Date.now() - startTime;
      console.log(`[chatWithAI] ✅ Request completed in ${duration}ms`);

      return {
        success: true,
        response: aiResponse,
        conversationId: finalConversationId,
        tokensUsed
      };

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

