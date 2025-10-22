/**
 * Cloud Functions for Psst messaging app
 * Handles push notification triggers when new messages are created
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
admin.initializeApp();

/**
 * Triggered when a new message is created in Firestore
 * Sends push notifications to all chat members except the sender
 */
exports.onMessageCreate = functions.firestore
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
 * @param {string} chatId - The chat document ID
 * @returns {Promise<string[]>} Array of user IDs
 */
async function getChatMembers(chatId) {
  try {
    const chatDoc = await admin.firestore().collection('chats').doc(chatId).get();
    
    if (!chatDoc.exists) {
      console.error('[CloudFunction] Chat not found:', chatId);
      return [];
    }
    
    const chatData = chatDoc.data();
    return chatData.members || [];
    
  } catch (error) {
    console.error('[CloudFunction] Error getting chat members:', error);
    return [];
  }
}

/**
 * Get FCM tokens for a list of user IDs
 * @param {string[]} userIds - Array of user IDs
 * @returns {Promise<string[]>} Array of valid FCM tokens
 */
async function getFCMTokens(userIds) {
  try {
    const tokens = [];
    
    // Get user documents in parallel
    const userPromises = userIds.map(userId => 
      admin.firestore().collection('users').doc(userId).get()
    );
    
    const userDocs = await Promise.all(userPromises);
    
    for (const userDoc of userDocs) {
      if (userDoc.exists) {
        const userData = userDoc.data();
        if (userData.fcmToken) {
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
 * @param {string} senderId - The sender's user ID
 * @returns {Promise<string>} Sender's display name
 */
async function getSenderName(senderId) {
  try {
    const userDoc = await admin.firestore().collection('users').doc(senderId).get();
    
    if (userDoc.exists) {
      const userData = userDoc.data();
      return userData.displayName || userData.email || 'Unknown User';
    }
    
    return 'Unknown User';
    
  } catch (error) {
    console.error('[CloudFunction] Error getting sender name:', error);
    return 'Unknown User';
  }
}

/**
 * Send push notifications to FCM tokens
 * @param {string[]} tokens - Array of FCM tokens
 * @param {Object} payload - Notification payload
 */
async function sendNotifications(tokens, payload) {
  try {
    if (tokens.length === 0) {
      console.log('[CloudFunction] No tokens to send notifications to');
      return;
    }
    
    console.log(`[CloudFunction] Sending notifications to ${tokens.length} tokens`);
    console.log(`[CloudFunction] Payload:`, JSON.stringify(payload, null, 2));
    
    // Try sending individual messages first to isolate issues
    const results = [];
    
    for (let i = 0; i < tokens.length; i++) {
      const token = tokens[i];
      console.log(`[CloudFunction] Sending to token ${i + 1}/${tokens.length}: ${token.substring(0, 20)}...`);
      
      try {
        const message = {
          token: token,
          notification: payload.notification,
          data: payload.data,
          android: {
            priority: 'high'
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
        results.push({ success: true, token: token.substring(0, 20) + '...' });
        
      } catch (tokenError) {
        console.error(`[CloudFunction] ❌ Failed to send to token ${i + 1}:`, tokenError.message);
        results.push({ success: false, token: token.substring(0, 20) + '...', error: tokenError.message });
      }
    }
    
    const successCount = results.filter(r => r.success).length;
    const failureCount = results.filter(r => !r.success).length;
    
    console.log(`[CloudFunction] Final results: ${successCount} successful, ${failureCount} failed`);
    
    if (failureCount > 0) {
      console.log('[CloudFunction] Failed tokens:', results.filter(r => !r.success));
    }
    
  } catch (error) {
    console.error('[CloudFunction] Error sending notifications:', error);
    console.error('[CloudFunction] Error details:', error.message);
    console.error('[CloudFunction] Error stack:', error.stack);
  }
}
