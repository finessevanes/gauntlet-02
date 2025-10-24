/**
 * Push Notification Cloud Function
 * Sends push notifications when new messages are created
 * (Converted from original index.js)
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

/**
 * Triggered when a new message is created in Firestore
 * Sends push notifications to all chat members except the sender
 */
export const onMessageCreate = functions.firestore
  .document('chats/{chatId}/messages/{messageId}')
  .onCreate(async (snapshot, context) => {
    try {
      console.log('[CloudFunction] New message created:', context.params.messageId);
      
      const messageData = snapshot.data();
      const messageId = context.params.messageId;
      const chatId = context.params.chatId;
      const senderId = messageData.senderID;
      const messageText = messageData.text;
      
      // Validate required fields
      if (!chatId || !senderId || !messageText) {
        console.error('[CloudFunction] Missing required message fields');
        return null;
      }
      
      // Get chat members
      const chatMembers = await getChatMembers(chatId);
      if (!chatMembers || chatMembers.length === 0) {
        console.error('[CloudFunction] No chat members found for chat:', chatId);
        return null;
      }
      
      // Remove sender from recipients
      const recipients = chatMembers.filter(memberId => memberId !== senderId);
      if (recipients.length === 0) {
        console.log('[CloudFunction] No recipients (sender is the only member)');
        return null;
      }
      
      // Get FCM tokens for all recipients
      const fcmTokens = await getFCMTokens(recipients);
      if (fcmTokens.length === 0) {
        console.log('[CloudFunction] No FCM tokens found for recipients');
        return null;
      }
      
      // Get sender name for notification
      const senderName = await getSenderName(senderId);
      
      // Create notification payload
      const payload = {
        notification: {
          title: `New message from ${senderName}`,
          body: messageText
        },
        data: {
          chatId: chatId,
          messageId: messageId,
          senderId: senderId,
          type: 'new_message'
        }
      };
      
      // Send notifications
      await sendNotifications(fcmTokens, payload);
      
      console.log(`[CloudFunction] Notifications sent to ${fcmTokens.length} recipients`);
      return null;
      
    } catch (error) {
      console.error('[CloudFunction] Error in onMessageCreate:', error);
      return null;
    }
  });

/**
 * Get all members of a chat
 */
async function getChatMembers(chatId: string): Promise<string[]> {
  try {
    const chatDoc = await admin.firestore().collection('chats').doc(chatId).get();
    
    if (!chatDoc.exists) {
      console.error('[CloudFunction] Chat not found:', chatId);
      return [];
    }
    
    const chatData = chatDoc.data();
    return chatData?.members || [];
    
  } catch (error) {
    console.error('[CloudFunction] Error getting chat members:', error);
    return [];
  }
}

/**
 * Get FCM tokens for a list of user IDs
 */
async function getFCMTokens(userIds: string[]): Promise<string[]> {
  try {
    const tokens: string[] = [];
    
    // Get user documents in parallel
    const userPromises = userIds.map(userId => 
      admin.firestore().collection('users').doc(userId).get()
    );
    
    const userDocs = await Promise.all(userPromises);
    
    for (const userDoc of userDocs) {
      if (userDoc.exists) {
        const userData = userDoc.data();
        if (userData?.fcmToken) {
          tokens.push(userData.fcmToken);
        }
      }
    }
    
    console.log(`[CloudFunction] Found ${tokens.length} FCM tokens for ${userIds.length} users`);
    return tokens;
    
  } catch (error) {
    console.error('[CloudFunction] Error getting FCM tokens:', error);
    return [];
  }
}

/**
 * Get sender's display name
 */
async function getSenderName(senderId: string): Promise<string> {
  try {
    const userDoc = await admin.firestore().collection('users').doc(senderId).get();
    
    if (userDoc.exists) {
      const userData = userDoc.data();
      return userData?.displayName || userData?.email || 'Unknown User';
    }
    
    return 'Unknown User';
    
  } catch (error) {
    console.error('[CloudFunction] Error getting sender name:', error);
    return 'Unknown User';
  }
}

/**
 * Send push notifications to FCM tokens
 */
async function sendNotifications(tokens: string[], payload: any): Promise<void> {
  try {
    if (tokens.length === 0) {
      console.log('[CloudFunction] No tokens to send notifications to');
      return;
    }
    
    console.log(`[CloudFunction] Sending notifications to ${tokens.length} tokens`);
    
    const results = [];
    
    for (let i = 0; i < tokens.length; i++) {
      const token = tokens[i];
      
      try {
        const message = {
          token: token,
          notification: payload.notification,
          data: payload.data,
          android: {
            priority: 'high' as const
          },
          apns: {
            payload: {
              aps: {
                badge: 1,
                sound: 'default'
              }
            }
          }
        };
        
        const response = await admin.messaging().send(message);
        console.log(`[CloudFunction] ✅ Successfully sent to token ${i + 1}: ${response}`);
        results.push({ success: true });
        
      } catch (tokenError: any) {
        console.error(`[CloudFunction] ❌ Failed to send to token ${i + 1}:`, tokenError.message);
        results.push({ success: false, error: tokenError.message });
      }
    }
    
    const successCount = results.filter(r => r.success).length;
    const failureCount = results.filter(r => !r.success).length;
    
    console.log(`[CloudFunction] Final results: ${successCount} successful, ${failureCount} failed`);
    
  } catch (error: any) {
    console.error('[CloudFunction] Error sending notifications:', error);
  }
}

