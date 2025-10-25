/**
 * Function Execution Service
 *
 * Handles the execution of AI function calls:
 * - scheduleCall: Create calendar events
 * - setReminder: Create reminders
 * - sendMessage: Send messages to clients
 * - searchMessages: Semantic search of past conversations
 *
 * All functions include validation, error handling, and audit logging
 */

import * as admin from 'firebase-admin';
import {
  ScheduleCallParams,
  SetReminderParams,
  SendMessageParams,
  SearchMessagesParams
} from '../schemas/aiFunctionSchemas';
import { generateEmbedding } from './openaiService';
import { searchVectors } from './vectorSearchService';

/**
 * Result of a function execution
 */
export interface FunctionExecutionResult {
  success: boolean;
  data?: any;
  message?: string;
  error?: string;
}

/**
 * Calculate Levenshtein distance between two strings
 * Used for fuzzy name matching
 */
function levenshteinDistance(str1: string, str2: string): number {
  const len1 = str1.length;
  const len2 = str2.length;
  const matrix: number[][] = [];

  // Initialize matrix
  for (let i = 0; i <= len1; i++) {
    matrix[i] = [i];
  }
  for (let j = 0; j <= len2; j++) {
    matrix[0][j] = j;
  }

  // Fill matrix
  for (let i = 1; i <= len1; i++) {
    for (let j = 1; j <= len2; j++) {
      const cost = str1[i - 1] === str2[j - 1] ? 0 : 1;
      matrix[i][j] = Math.min(
        matrix[i - 1][j] + 1,      // deletion
        matrix[i][j - 1] + 1,      // insertion
        matrix[i - 1][j - 1] + cost // substitution
      );
    }
  }

  return matrix[len1][len2];
}

/**
 * Schedule a call with a client
 *
 * @param trainerId - ID of the trainer creating the event
 * @param params - Schedule call parameters
 * @returns Execution result with eventId if successful
 */
export async function executeScheduleCall(
  trainerId: string,
  params: ScheduleCallParams
): Promise<FunctionExecutionResult> {
  try {
    const { clientName, clientId: providedClientId, dateTime, duration = 30 } = params;

    // Validate dateTime is in the future
    const scheduledDate = new Date(dateTime);
    const now = new Date();

    if (scheduledDate <= now) {
      return {
        success: false,
        error: 'That time has already passed. Please provide a future date and time.'
      };
    }

    // Validate duration
    if (duration < 5 || duration > 480) {
      return {
        success: false,
        error: 'Call duration must be between 5 minutes and 8 hours.'
      };
    }

    // Determine clientId and clientDisplayName
    let clientId: string;
    let clientDisplayName: string;

    // If clientId was provided (after selection), use it directly
    if (providedClientId) {
      console.log(`[executeScheduleCall] Using provided clientId: ${providedClientId}`);
      clientId = providedClientId;
      clientDisplayName = clientName; // Use the exact name from selection
    } else {
      // Find matching contacts by name
      console.log(`[executeScheduleCall] Searching for contacts matching: ${clientName}`);
      const matchResults = await findContactMatches(trainerId, clientName);

      // Multiple matches -> return SELECTION_REQUIRED
      if (matchResults.length > 1) {
        console.log(`[executeScheduleCall] Found ${matchResults.length} matches, returning SELECTION_REQUIRED`);
        return {
          success: false,
          error: 'SELECTION_REQUIRED',
          data: {
            type: 'SELECTION_REQUIRED',
            selectionType: 'contact',
            prompt: 'Who did you mean?',
            options: matchResults.map(m => ({
              id: m.userId,
              title: m.displayName,
              subtitle: m.email,
              icon: '👤',
              metadata: { userId: m.userId, displayName: m.displayName }
            })),
            context: {
              originalFunction: 'scheduleCall',
              originalParameters: { clientName, dateTime, duration }
            }
          }
        };
      }

      // No matches
      if (matchResults.length === 0) {
        return {
          success: false,
          error: `I couldn't find '${clientName}' in your contacts.`
        };
      }

      // Single match -> proceed
      clientId = matchResults[0].userId;
      clientDisplayName = matchResults[0].displayName;
      console.log(`[executeScheduleCall] Single match found, using clientId: ${clientId}`);
    }

    const db = admin.firestore();

    // Create calendar event
    const calendarRef = db.collection('calendar');
    const eventData = {
      trainerId,
      clientId,
      clientName: clientDisplayName.toUpperCase(),
      title: `Call with ${clientDisplayName.toUpperCase()}`,
      dateTime: admin.firestore.Timestamp.fromDate(scheduledDate),
      duration,
      createdBy: 'ai',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'scheduled'
    };

    const eventDoc = await calendarRef.add(eventData);

    const formattedDate = scheduledDate.toLocaleString('en-US', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
      hour12: true
    });

    return {
      success: true,
      data: { eventId: eventDoc.id, ...eventData },
      message: `✓ Call scheduled with ${clientName} for ${formattedDate} (${duration} minutes)`
    };
  } catch (error: any) {
    console.error('[executeScheduleCall] Error:', error);
    return {
      success: false,
      error: `Failed to schedule call: ${error.message || 'Unknown error'}`
    };
  }
}

/**
 * Set a reminder for the trainer
 *
 * @param trainerId - ID of the trainer
 * @param params - Reminder parameters
 * @returns Execution result with reminderId if successful
 */
export async function executeSetReminder(
  trainerId: string,
  params: SetReminderParams
): Promise<FunctionExecutionResult> {
  try {
    const { clientName, clientId: providedClientId, reminderText, dateTime } = params;

    // Validate dateTime
    const dueDate = new Date(dateTime);
    const now = new Date();

    // Allow reminders up to 7 days in the past (grace period)
    const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    if (dueDate < sevenDaysAgo) {
      return {
        success: false,
        error: 'Reminder date is too far in the past. Please provide a more recent date.'
      };
    }

    // Validate reminderText length
    if (reminderText.length > 500) {
      return {
        success: false,
        error: 'Reminder text is too long. Please keep it under 500 characters.'
      };
    }

    const db = admin.firestore();
    let clientId: string | null = null;

    // If clientId was provided (after selection), use it directly
    if (providedClientId) {
      console.log(`[executeSetReminder] Using provided clientId: ${providedClientId}`);
      clientId = providedClientId;
    } else if (clientName) {
      // Find client by name
      console.log(`[executeSetReminder] Searching for contacts matching: ${clientName}`);
      const matchResults = await findContactMatches(trainerId, clientName);

      // Multiple matches -> return SELECTION_REQUIRED
      if (matchResults.length > 1) {
        console.log(`[executeSetReminder] Found ${matchResults.length} matches, returning SELECTION_REQUIRED`);
        return {
          success: false,
          error: 'SELECTION_REQUIRED',
          data: {
            type: 'SELECTION_REQUIRED',
            selectionType: 'contact',
            prompt: 'Who did you mean?',
            options: matchResults.map(m => ({
              id: m.userId,
              title: m.displayName,
              subtitle: m.email,
              icon: '👤',
              metadata: { userId: m.userId, displayName: m.displayName }
            })),
            context: {
              originalFunction: 'setReminder',
              originalParameters: { clientName, reminderText, dateTime }
            }
          }
        };
      }

      // No matches
      if (matchResults.length === 0) {
        return {
          success: false,
          error: `I couldn't find '${clientName}' in your contacts.`
        };
      }

      // Single match -> proceed
      clientId = matchResults[0].userId;
      console.log(`[executeSetReminder] Single match found, using clientId: ${clientId}`);
    }

    // Create reminder
    const remindersRef = db.collection('reminders');
    const reminderData = {
      trainerId,
      clientId,
      clientName: clientName || null,
      reminderText,
      dueDate: admin.firestore.Timestamp.fromDate(dueDate),
      createdBy: 'ai',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      completed: false,
      completedAt: null
    };

    const reminderDoc = await remindersRef.add(reminderData);

    const formattedDate = dueDate.toLocaleString('en-US', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
      hour12: true
    });

    return {
      success: true,
      data: { reminderId: reminderDoc.id, ...reminderData },
      message: `✓ Reminder set for ${formattedDate}: "${reminderText}"`
    };
  } catch (error: any) {
    console.error('[executeSetReminder] Error:', error);
    return {
      success: false,
      error: `Failed to set reminder: ${error.message || 'Unknown error'}`
    };
  }
}

/**
 * Find chats for contacts matching a name
 *
 * @param trainerId - ID of the trainer
 * @param searchName - Name to search for
 * @returns Array of matching contacts with chat information
 */
async function findContactMatches(
  trainerId: string,
  searchName: string
): Promise<Array<{ userId: string; displayName: string; email: string; chatId: string }>> {
  console.log(`[findContactMatches] Starting search for: "${searchName}"`);
  console.log(`[findContactMatches] Trainer ID: ${trainerId}`);

  const db = admin.firestore();
  const usersRef = db.collection('users');
  const allUsersSnapshot = await usersRef.get();

  console.log(`[findContactMatches] Total users in database: ${allUsersSnapshot.docs.length}`);

  const matches: Array<{ userId: string; displayName: string; email: string; chatId: string }> = [];
  const allNames: string[] = [];

  for (const userDoc of allUsersSnapshot.docs) {
    const userData = userDoc.data();
    const displayName = userData.displayName;

    if (!displayName) {
      console.log(`[findContactMatches] User ${userDoc.id} has no displayName, skipping`);
      continue;
    }

    allNames.push(displayName);

    const nameLower = displayName.toLowerCase();
    const searchLower = searchName.toLowerCase();

    // Fuzzy match
    const exactMatch = nameLower === searchLower;
    const containsMatch = nameLower.includes(searchLower) || searchLower.includes(nameLower);
    const editDistance = levenshteinDistance(nameLower, searchLower);
    const distanceMatch = editDistance <= 2;

    const isMatch = exactMatch || containsMatch || distanceMatch;

    console.log(`[findContactMatches] Checking "${displayName}" (${userDoc.id}):`);
    console.log(`  - Exact match: ${exactMatch}`);
    console.log(`  - Contains match: ${containsMatch}`);
    console.log(`  - Edit distance: ${editDistance} (match: ${distanceMatch})`);
    console.log(`  - Overall match: ${isMatch}`);

    if (isMatch) {
      console.log(`[findContactMatches] ✅ "${displayName}" matches! Looking for chat...`);

      // Find chat between trainer and this user
      const chatsRef = db.collection('chats');
      const chatQuery = await chatsRef
        .where('members', 'array-contains', trainerId)
        .get();

      console.log(`[findContactMatches] Found ${chatQuery.docs.length} chats for trainer`);

      const matchingChat = chatQuery.docs.find(doc => {
        const members = doc.data().members || [];
        const hasUser = members.includes(userDoc.id);
        console.log(`  - Chat ${doc.id}: members=${members.join(',')}, includes ${userDoc.id}? ${hasUser}`);
        return hasUser;
      });

      if (matchingChat) {
        console.log(`[findContactMatches] ✅ Found chat ${matchingChat.id} with ${displayName}`);
        matches.push({
          userId: userDoc.id,
          displayName,
          email: userData.email || 'No email',
          chatId: matchingChat.id
        });
      } else {
        console.log(`[findContactMatches] ⚠️ No chat found with ${displayName}, skipping`);
      }
    }
  }

  console.log(`[findContactMatches] All user names in database: ${allNames.join(', ')}`);
  console.log(`[findContactMatches] FINAL RESULTS: Found ${matches.length} matching contacts`);
  matches.forEach((m, i) => {
    console.log(`  ${i + 1}. ${m.displayName} (${m.userId}) - ${m.email} - chat: ${m.chatId}`);
  });

  return matches;
}

/**
 * Send a message to a client
 *
 * @param trainerId - ID of the trainer sending the message
 * @param params - Message parameters
 * @returns Execution result with messageId if successful
 */
export async function executeSendMessage(
  trainerId: string,
  params: SendMessageParams
): Promise<FunctionExecutionResult> {
  try {
    const { chatId, clientName, messageText } = params;
    let resolvedChatId = chatId;

    // If only clientName provided, search for matching contacts
    if (!chatId && clientName) {
      console.log(`[executeSendMessage] Searching for contacts matching: ${clientName}`);
      const matchResults = await findContactMatches(trainerId, clientName);

      // Multiple matches -> return SELECTION_REQUIRED
      if (matchResults.length > 1) {
        console.log(`[executeSendMessage] Found ${matchResults.length} matches, returning SELECTION_REQUIRED`);
        return {
          success: false,
          error: 'SELECTION_REQUIRED',
          data: {
            type: 'SELECTION_REQUIRED',
            selectionType: 'contact',
            prompt: 'Who did you mean?',
            options: matchResults.map(m => ({
              id: m.userId,
              title: m.displayName,
              subtitle: m.email,
              icon: '👤',
              metadata: { chatId: m.chatId, displayName: m.displayName }
            })),
            context: {
              originalFunction: 'sendMessage',
              originalParameters: { clientName, messageText }
            }
          }
        };
      }

      // Single match -> proceed with this chat
      if (matchResults.length === 1) {
        resolvedChatId = matchResults[0].chatId;
        console.log(`[executeSendMessage] Single match found, using chatId: ${resolvedChatId}`);
      } else {
        // No matches
        return {
          success: false,
          error: `I couldn't find '${clientName}' in your contacts.`
        };
      }
    }

    // Validate chatId is present
    if (!resolvedChatId) {
      return {
        success: false,
        error: 'Either chatId or clientName must be provided.'
      };
    }

    const db = admin.firestore();
    const chatRef = db.collection('chats').doc(resolvedChatId);
    const chatDoc = await chatRef.get();

    if (!chatDoc.exists) {
      return {
        success: false,
        error: 'Chat not found.'
      };
    }

    const chatData = chatDoc.data();

    // Verify trainer is a member of the chat
    if (!chatData?.members || !chatData.members.includes(trainerId)) {
      console.warn(`[executeSendMessage] Unauthorized access attempt to chat ${resolvedChatId} by trainer ${trainerId}`);
      return {
        success: false,
        error: "You don't have access to this chat."
      };
    }

    // Create message
    const messagesRef = chatRef.collection('messages');
    const messageData = {
      text: messageText,
      senderID: trainerId,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      readBy: [trainerId]
    };

    const messageDoc = await messagesRef.add(messageData);

    // Update chat's lastMessage and lastMessageTimestamp
    await chatRef.update({
      lastMessage: messageText,
      lastMessageTimestamp: admin.firestore.FieldValue.serverTimestamp()
    });

    return {
      success: true,
      data: { messageId: messageDoc.id, chatId: resolvedChatId },
      message: '✓ Message sent successfully'
    };
  } catch (error: any) {
    console.error('[executeSendMessage] Error:', error);
    return {
      success: false,
      error: `Failed to send message: ${error.message || 'Unknown error'}`
    };
  }
}

/**
 * Search past messages using semantic search
 *
 * @param trainerId - ID of the trainer performing the search
 * @param params - Search parameters
 * @param openaiApiKey - OpenAI API key (passed from function handler)
 * @param pineconeApiKey - Pinecone API key (passed from function handler)
 * @returns Execution result with matching messages if successful
 */
export async function executeSearchMessages(
  trainerId: string,
  params: SearchMessagesParams,
  openaiApiKey: string,
  pineconeApiKey: string
): Promise<FunctionExecutionResult> {
  try {
    const { query, chatId, limit = 10 } = params;

    // Validate limit
    const searchLimit = Math.min(limit, 50);

    // Generate embedding for the query
    const embedding = await generateEmbedding(query, openaiApiKey);

    if (!embedding || embedding.length === 0) {
      return {
        success: false,
        error: 'Failed to generate search embedding.'
      };
    }

    // Build search options
    const searchOptions: any = {
      topK: searchLimit
    };

    // Add chatId filter if provided
    if (chatId) {
      searchOptions.filter = {
        firestoreChatId: chatId
      };
    }

    // Search Pinecone (userId filter is built into searchVectors)
    const searchResults = await searchVectors(
      embedding,
      trainerId,
      pineconeApiKey,
      searchOptions
    );

    if (!searchResults || searchResults.length === 0) {
      return {
        success: true,
        data: { messages: [] },
        message: `No messages found matching "${query}".`
      };
    }

    // Format results
    const messages = searchResults.map((result: any) => ({
      text: result.metadata.text,
      senderName: result.metadata.senderName,
      timestamp: result.metadata.timestamp,
      chatId: result.metadata.firestoreChatId,
      score: result.score
    }));

    return {
      success: true,
      data: { messages, count: messages.length },
      message: `Found ${messages.length} message(s) matching "${query}"`
    };
  } catch (error: any) {
    console.error('[executeSearchMessages] Error:', error);
    return {
      success: false,
      error: `Failed to search messages: ${error.message || 'Unknown error'}`
    };
  }
}

/**
 * Execute any AI function by name
 *
 * @param functionName - Name of the function to execute
 * @param trainerId - ID of the trainer
 * @param parameters - Function parameters
 * @param openaiApiKey - OpenAI API key (passed from function handler)
 * @param pineconeApiKey - Pinecone API key (passed from function handler)
 * @returns Execution result
 */
export async function executeFunctionCall(
  functionName: string,
  trainerId: string,
  parameters: any,
  openaiApiKey: string,
  pineconeApiKey: string
): Promise<FunctionExecutionResult> {
  switch (functionName) {
    case 'scheduleCall':
      return executeScheduleCall(trainerId, parameters);
    case 'setReminder':
      return executeSetReminder(trainerId, parameters);
    case 'sendMessage':
      return executeSendMessage(trainerId, parameters);
    case 'searchMessages':
      return executeSearchMessages(trainerId, parameters, openaiApiKey, pineconeApiKey);
    default:
      return {
        success: false,
        error: `Unknown function: ${functionName}`
      };
  }
}
