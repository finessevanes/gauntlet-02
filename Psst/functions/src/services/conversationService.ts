/**
 * Conversation Service
 * Manages AI conversation and message storage in Firestore
 */

import * as admin from 'firebase-admin';
import { AIConversation, AIMessage } from '../types/aiConversation';

const db = admin.firestore();

/**
 * Create or update an AI conversation
 * @param conversationId - Conversation ID (auto-generated if creating new)
 * @param trainerId - Firebase Auth UID of the trainer
 * @param userMessage - User's latest message
 * @param aiResponse - AI's latest response
 * @returns Conversation ID
 */
export async function saveConversation(
  conversationId: string | undefined,
  trainerId: string,
  userMessage: string,
  aiResponse: string
): Promise<string> {
  const now = admin.firestore.Timestamp.now();
  
  // Create new conversation if no ID provided
  if (!conversationId) {
    const conversationRef = db.collection('ai_conversations').doc();
    const newConversation: AIConversation = {
      id: conversationRef.id,
      trainerId,
      createdAt: now,
      updatedAt: now,
      messageCount: 2, // User message + AI response
      lastMessage: userMessage,
      lastResponse: aiResponse,
      isActive: true
    };
    
    await conversationRef.set(newConversation);
    console.log(`[ConversationService] ✅ Created new conversation: ${conversationRef.id}`);
    
    return conversationRef.id;
  }
  
  // Update existing conversation
  const conversationRef = db.collection('ai_conversations').doc(conversationId);
  const conversationDoc = await conversationRef.get();
  
  if (!conversationDoc.exists) {
    throw new Error(`Conversation ${conversationId} not found`);
  }
  
  const conversation = conversationDoc.data() as AIConversation;
  
  // Verify ownership
  if (conversation.trainerId !== trainerId) {
    throw new Error('Unauthorized: Conversation does not belong to this trainer');
  }
  
  // Update conversation metadata
  await conversationRef.update({
    updatedAt: now,
    messageCount: admin.firestore.FieldValue.increment(2),
    lastMessage: userMessage,
    lastResponse: aiResponse,
    isActive: true
  });
  
  console.log(`[ConversationService] ✅ Updated conversation: ${conversationId}`);
  
  return conversationId;
}

/**
 * Save a user message to Firestore
 * @param conversationId - Conversation ID
 * @param content - Message content
 * @returns Message ID
 */
export async function saveUserMessage(
  conversationId: string,
  content: string
): Promise<string> {
  const messageRef = db
    .collection('ai_conversations')
    .doc(conversationId)
    .collection('messages')
    .doc();
    
  const message: AIMessage = {
    id: messageRef.id,
    conversationId,
    role: 'user',
    content,
    timestamp: admin.firestore.Timestamp.now(),
    model: 'N/A' // User messages don't have a model
  };
  
  await messageRef.set(message);
  console.log(`[ConversationService] ✅ Saved user message: ${messageRef.id}`);
  
  return messageRef.id;
}

/**
 * Save an AI assistant message to Firestore
 * @param conversationId - Conversation ID
 * @param content - Message content
 * @param model - OpenAI model used
 * @param tokensUsed - Number of tokens consumed
 * @param error - Optional error message
 * @returns Message ID
 */
export async function saveAssistantMessage(
  conversationId: string,
  content: string,
  model: string,
  tokensUsed?: number,
  error?: string
): Promise<string> {
  const messageRef = db
    .collection('ai_conversations')
    .doc(conversationId)
    .collection('messages')
    .doc();
    
  const message: Partial<AIMessage> = {
    id: messageRef.id,
    conversationId,
    role: 'assistant',
    content,
    timestamp: admin.firestore.Timestamp.now(),
    model
  };
  
  // Only include optional fields if they have values (Firestore doesn't accept undefined)
  if (tokensUsed !== undefined) {
    message.tokensUsed = tokensUsed;
  }
  if (error !== undefined) {
    message.error = error;
  }
  
  await messageRef.set(message as AIMessage);
  console.log(`[ConversationService] ✅ Saved assistant message: ${messageRef.id}`);
  
  return messageRef.id;
}

/**
 * Retrieve conversation history for context
 * @param conversationId - Conversation ID
 * @param limit - Maximum number of messages to retrieve (default: 10)
 * @returns Array of messages ordered by timestamp
 */
export async function getConversationHistory(
  conversationId: string,
  limit: number = 10
): Promise<AIMessage[]> {
  const messagesSnapshot = await db
    .collection('ai_conversations')
    .doc(conversationId)
    .collection('messages')
    .orderBy('timestamp', 'desc')
    .limit(limit)
    .get();
    
  const messages: AIMessage[] = [];
  
  messagesSnapshot.forEach((doc) => {
    messages.push(doc.data() as AIMessage);
  });
  
  // Reverse to get chronological order (oldest first)
  messages.reverse();
  
  console.log(`[ConversationService] Retrieved ${messages.length} messages from conversation ${conversationId}`);
  
  return messages;
}

/**
 * Verify conversation ownership
 * @param conversationId - Conversation ID
 * @param trainerId - Firebase Auth UID
 * @returns True if trainer owns the conversation
 */
export async function verifyConversationOwnership(
  conversationId: string,
  trainerId: string
): Promise<boolean> {
  const conversationDoc = await db
    .collection('ai_conversations')
    .doc(conversationId)
    .get();
    
  if (!conversationDoc.exists) {
    return false;
  }
  
  const conversation = conversationDoc.data() as AIConversation;
  return conversation.trainerId === trainerId;
}

