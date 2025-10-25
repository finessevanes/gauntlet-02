/**
 * TypeScript interfaces for AI conversation data models
 * Defines the structure of AI conversations and messages stored in Firestore
 */

import { Timestamp } from 'firebase-admin/firestore';

/**
 * AI Conversation document stored in Firestore
 * Collection path: /ai_conversations/{conversationId}
 */
export interface AIConversation {
  id: string;
  trainerId: string;
  createdAt: Timestamp;
  updatedAt: Timestamp;
  messageCount: number;
  lastMessage: string;
  lastResponse: string;
  isActive: boolean;
}

/**
 * AI Message document stored in Firestore
 * Collection path: /ai_conversations/{conversationId}/messages/{messageId}
 */
export interface AIMessage {
  id: string;
  conversationId: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: Timestamp;
  tokensUsed?: number;
  model: string;
  error?: string;
}

/**
 * Request payload for chatWithAI Cloud Function
 */
export interface ChatWithAIRequest {
  userId: string;
  message: string;
  conversationId?: string;
  timezone?: string; // IANA timezone identifier (e.g., "America/Los_Angeles")
}

/**
 * Function call information from AI
 */
export interface FunctionCallInfo {
  name: string;
  parameters: Record<string, any>;
}

/**
 * Response from chatWithAI Cloud Function
 */
export interface ChatWithAIResponse {
  success: boolean;
  response?: string;
  conversationId: string;
  error?: string;
  tokensUsed?: number;
  functionCall?: FunctionCallInfo;
}

/**
 * OpenAI Chat Message format for API requests
 */
export interface ChatMessage {
  role: 'system' | 'user' | 'assistant';
  content: string;
}

/**
 * Error codes for AI chat operations
 */
export enum AIErrorCode {
  INVALID_REQUEST = 'INVALID_REQUEST',
  OPENAI_TIMEOUT = 'OPENAI_TIMEOUT',
  RATE_LIMIT_EXCEEDED = 'RATE_LIMIT_EXCEEDED',
  OPENAI_ERROR = 'OPENAI_ERROR',
  INTERNAL_ERROR = 'INTERNAL_ERROR',
  UNAUTHORIZED = 'UNAUTHORIZED'
}

