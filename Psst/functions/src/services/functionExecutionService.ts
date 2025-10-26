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
import { DateTime } from 'luxon';
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
 * Detect event type from natural language query
 * PR #010B: AI Scheduling + Conflict Detection
 *
 * @param query - Natural language scheduling request
 * @returns Event type: 'training', 'call', or 'adhoc'
 */
function detectEventType(query: string): 'training' | 'call' | 'adhoc' {
  const lowercased = query.toLowerCase();

  // Training keywords
  if (
    lowercased.includes('session') ||
    lowercased.includes('training') ||
    lowercased.includes('workout') ||
    lowercased.includes('train')
  ) {
    return 'training';
  }

  // Call keywords
  if (
    lowercased.includes('call') ||
    lowercased.includes('phone') ||
    lowercased.includes('zoom') ||
    lowercased.includes('meet')
  ) {
    return 'call';
  }

  // Default to adhoc for appointments or when no specific keyword
  return 'adhoc';
}

/**
 * Detect conflicts in a time window (±30 minutes)
 * PR #010B: AI Scheduling + Conflict Detection
 *
 * @param trainerId - ID of the trainer
 * @param startTime - Requested start time
 * @param endTime - Requested end time
 * @returns Array of conflicting events
 */
async function detectConflicts(
  trainerId: string,
  startTime: Date,
  endTime: Date
): Promise<any[]> {
  const db = admin.firestore();

  // Query window: ±30 minutes from requested time
  const queryStartTime = new Date(startTime.getTime() - 30 * 60 * 1000);
  const queryEndTime = new Date(endTime.getTime() + 30 * 60 * 1000);

  const snapshot = await db.collection('calendar')
    .where('trainerId', '==', trainerId)
    .where('startTime', '>=', admin.firestore.Timestamp.fromDate(queryStartTime))
    .where('startTime', '<=', admin.firestore.Timestamp.fromDate(queryEndTime))
    .where('status', '!=', 'cancelled')
    .get();

  // Filter to find actual overlaps
  const conflicts = snapshot.docs
    .map(doc => ({ id: doc.id, ...doc.data() }))
    .filter((event: any) => {
      const eventStart = event.startTime.toDate();
      const eventEnd = event.endTime.toDate();
      // Event overlaps if it starts before requestedEnd AND ends after requestedStart
      return eventStart < endTime && eventEnd > startTime;
    });

  return conflicts;
}

/**
 * Suggest alternative times when conflict detected
 * PR #010B: AI Scheduling + Conflict Detection
 *
 * @param trainerId - ID of the trainer
 * @param preferredStartTime - Requested start time that had conflict
 * @param duration - Event duration in minutes
 * @returns Array of up to 3 alternative start times
 */
async function suggestAlternatives(
  trainerId: string,
  preferredStartTime: Date,
  duration: number
): Promise<Date[]> {
  const suggestions: Date[] = [];
  const workingStartHour = 9;
  const workingEndHour = 18;
  const maxDays = 7;

  let currentDate = new Date(preferredStartTime.getTime() + 60 * 60 * 1000); // +1 hour from preferred
  let daysChecked = 0;

  while (suggestions.length < 3 && daysChecked < maxDays) {
    const currentHour = currentDate.getHours();

    // Check if within working hours
    if (currentHour >= workingStartHour && currentHour < workingEndHour) {
      const proposedEndTime = new Date(currentDate.getTime() + duration * 60 * 1000);

      // Check for conflicts
      const conflicts = await detectConflicts(trainerId, currentDate, proposedEndTime);

      if (conflicts.length === 0) {
        suggestions.push(new Date(currentDate));
      }
    }

    // Move to next hour
    currentDate = new Date(currentDate.getTime() + 60 * 60 * 1000);

    // If past working hours, move to next day at 9 AM
    if (currentDate.getHours() >= workingEndHour) {
      const nextDay = new Date(currentDate);
      nextDay.setDate(nextDay.getDate() + 1);
      nextDay.setHours(workingStartHour, 0, 0, 0);
      currentDate = nextDay;
      daysChecked++;
    }
  }

  return suggestions;
}

/**
 * Schedule a call with a client
 * ENHANCED in PR #010B: Now includes event type detection, conflict checking, and alternative suggestions
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
    console.log('\n========================================');
    console.log('[executeScheduleCall] 🎯 STARTING SCHEDULE CALL');
    console.log('[executeScheduleCall] TrainerId:', trainerId);
    console.log('[executeScheduleCall] Params:', JSON.stringify(params, null, 2));
    console.log('========================================\n');

    const { clientName, clientId: providedClientId, dateTime, duration = 60, query, timezone } = params;
    console.log('[executeScheduleCall] 📝 Raw parameters received:');
    console.log('  - clientName:', clientName);
    console.log('  - dateTime (raw):', dateTime);
    console.log('  - timezone:', timezone || '(none)');
    console.log('  - duration:', duration);

    // Parse dateTime in user's timezone and convert to UTC using Luxon
    let scheduledDate: Date;

    if (timezone) {
      // DateTime is in local time (e.g., "2025-10-27T21:00:00") - convert to UTC
      console.log('[executeScheduleCall] 📅 Parsing local time with Luxon:');
      console.log('  - Local time string:', dateTime);
      console.log('  - Timezone:', timezone);

      // Parse the datetime in the user's timezone
      const luxonDate = DateTime.fromISO(dateTime, { zone: timezone });

      if (!luxonDate.isValid) {
        console.log('[executeScheduleCall] ❌ Invalid datetime format');
        console.log('  - Error:', luxonDate.invalidReason);
        return {
          success: false,
          error: `Invalid date/time format: ${dateTime}`
        };
      }

      // Convert to JavaScript Date (automatically in UTC)
      scheduledDate = luxonDate.toJSDate();

      console.log('  - Parsed in timezone:', luxonDate.toISO());
      console.log('  - Converted to UTC:', scheduledDate.toISOString());
      console.log('  - Local display:', luxonDate.toFormat('yyyy-MM-dd HH:mm:ss ZZZZ'));
    } else {
      // Fallback: treat as UTC
      console.log('[executeScheduleCall] 📅 No timezone provided, treating as UTC');
      scheduledDate = new Date(dateTime);
    }

    const now = new Date();

    console.log('[executeScheduleCall] 📅 Date validation:');
    console.log('  - Requested time (UTC):', scheduledDate.toISOString());
    console.log('  - Current time (UTC):', now.toISOString());
    console.log('  - Is future?:', scheduledDate > now);

    if (scheduledDate <= now) {
      console.log('[executeScheduleCall] ❌ Date is in the past');
      return {
        success: false,
        error: 'That time has already passed. Please provide a future date and time.'
      };
    }

    // Validate duration
    console.log('[executeScheduleCall] ⏱️ Duration validation:', duration);
    if (duration < 5 || duration > 480) {
      console.log('[executeScheduleCall] ❌ Invalid duration');
      return {
        success: false,
        error: 'Call duration must be between 5 minutes and 8 hours.'
      };
    }

    // PR #010B: Detect event type from natural language query
    const eventType = query ? detectEventType(query) : 'call';
    console.log('[executeScheduleCall] 🏷️ Event Type Detection:');
    console.log('  - Query:', query || '(no query provided)');
    console.log('  - Detected type:', eventType);

    // Determine clientId and clientDisplayName
    let clientId: string;
    let clientDisplayName: string;

    console.log('[executeScheduleCall] 👤 Client Resolution:');
    console.log('  - Provided clientId:', providedClientId || '(none)');
    console.log('  - Client name:', clientName);

    // If clientId was provided (after selection), use it directly
    if (providedClientId) {
      clientId = providedClientId;
      clientDisplayName = clientName; // Use the exact name from selection
      console.log('  - ✅ Using provided clientId:', clientId);
    } else {
      // Find matching contacts by name
      console.log('  - 🔍 Searching for contacts...');
      const matchResults = await findContactMatches(trainerId, clientName);
      console.log('  - Found', matchResults.length, 'matches');

      // Multiple matches -> return SELECTION_REQUIRED
      if (matchResults.length > 1) {
        console.log('  - ⚠️ Multiple matches found, requiring selection');
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
              originalParameters: { clientName, dateTime, duration, query }
            }
          }
        };
      }

      // No matches
      if (matchResults.length === 0) {
        console.log('  - ❌ No matches found');
        return {
          success: false,
          error: `I couldn't find '${clientName}' in your contacts.`
        };
      }

      // Single match -> proceed
      clientId = matchResults[0].userId;
      clientDisplayName = matchResults[0].displayName;
      console.log('  - ✅ Single match found:', clientDisplayName, '(', clientId, ')');
    }

    // PR #010B: Check for scheduling conflicts
    const endTime = new Date(scheduledDate.getTime() + duration * 60 * 1000);
    console.log('\n[executeScheduleCall] 🔍 CONFLICT DETECTION:');
    console.log('  - Start time:', scheduledDate.toISOString());
    console.log('  - End time:', endTime.toISOString());
    console.log('  - Duration:', duration, 'minutes');
    console.log('  - Checking for conflicts...');

    const conflicts = await detectConflicts(trainerId, scheduledDate, endTime);
    console.log('  - Found', conflicts.length, 'conflict(s)');

    if (conflicts.length > 0) {
      console.log('  - ⚠️ CONFLICTS DETECTED:');
      conflicts.forEach((c, idx) => {
        console.log(`    ${idx + 1}. ${c.title} (${c.startTime?.toDate?.()?.toISOString() || 'no time'})`);
      });

      // Conflict detected - suggest alternatives
      console.log('  - 🔄 Generating alternative suggestions...');
      const suggestions = await suggestAlternatives(trainerId, scheduledDate, duration);
      console.log('  - Generated', suggestions.length, 'suggestion(s)');

      if (suggestions.length === 0) {
        console.log('  - ❌ No alternative times found');
        return {
          success: false,
          error: 'No available times in the next week. Please choose a time manually.'
        };
      }

      const conflictingEvent = conflicts[0];
      console.log('  - 📋 Returning conflict response with', suggestions.length, 'alternatives');
      suggestions.forEach((s, idx) => {
        console.log(`    ${idx + 1}. ${s.toISOString()}`);
      });

      console.log('  - 🟠 ===== CREATING CONFLICT_DETECTED RESPONSE =====');
      console.log('  - 🟠 Response structure:');
      console.log('    - success: false');
      console.log('    - error: "CONFLICT_DETECTED"');
      console.log('    - data.type: "CONFLICT_DETECTED"');
      console.log('    - data.conflictingEvent.id:', conflictingEvent.id);
      console.log('    - data.conflictingEvent.title:', conflictingEvent.title);
      console.log('    - data.suggestions.length:', suggestions.length);
      console.log('    - data.originalRequest.clientName:', clientName);
      console.log('    - data.originalRequest.clientId:', clientId);
      console.log('    - data.originalRequest.eventType:', eventType);
      console.log('    - data.originalRequest.duration:', duration);

      const conflictResponse = {
        success: false,
        error: 'CONFLICT_DETECTED',
        data: {
          type: 'CONFLICT_DETECTED',
          conflictingEvent: {
            id: conflictingEvent.id,
            title: conflictingEvent.title,
            startTime: conflictingEvent.startTime.toDate().toISOString(),
            endTime: conflictingEvent.endTime.toDate().toISOString()
          },
          suggestions: suggestions.map(date => date.toISOString()),
          originalRequest: {
            clientName,
            clientId,
            dateTime,
            duration,
            eventType
          }
        }
      };

      console.log('  - 🟠 Full response object:', JSON.stringify(conflictResponse, null, 2));
      console.log('  - 🟠 ===== RETURNING TO FRONTEND =====');
      return conflictResponse;
    }

    console.log('  - ✅ No conflicts detected, proceeding to create event');

    const db = admin.firestore();

    // Create calendar event with new PR #010A/010B schema
    const calendarRef = db.collection('calendar');
    const eventDoc = calendarRef.doc(); // Generate document ID first

    // Event type display names
    const eventTypeNames: Record<string, string> = {
      training: 'Training Session',
      call: 'Call',
      adhoc: 'Appointment'
    };

    const eventData = {
      id: eventDoc.id,
      trainerId,
      clientId,
      prospectId: null, // Can be enhanced later for prospects
      title: `${eventTypeNames[eventType]} with ${clientDisplayName}`,
      startTime: admin.firestore.Timestamp.fromDate(scheduledDate),
      endTime: admin.firestore.Timestamp.fromDate(endTime),
      eventType,
      location: null,
      notes: null,
      createdBy: 'ai',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'scheduled'
    };

    console.log('\n[executeScheduleCall] 💾 CREATING EVENT:');
    console.log('  - Event ID:', eventDoc.id);
    console.log('  - Event Type:', eventType);
    console.log('  - Title:', eventData.title);
    console.log('  - Client ID:', clientId);
    console.log('  - Start Time:', scheduledDate.toISOString());
    console.log('  - End Time:', endTime.toISOString());
    console.log('  - Duration:', duration, 'minutes');

    await eventDoc.set(eventData); // Use set() instead of add() since we pre-generated the ID

    console.log('  - ✅ Event saved to Firestore');

    // Present confirmation in the user's timezone when available so AI replies match what the trainer expects
    const displayDateTime = timezone
      ? DateTime.fromJSDate(scheduledDate, { zone: timezone })
      : DateTime.fromJSDate(scheduledDate);
    const formattedDate = displayDateTime.toFormat('EEEE, LLLL d, yyyy h:mm a');

    console.log('\n[executeScheduleCall] ✅ SUCCESS!');
    console.log('  - Message:', `${eventTypeNames[eventType]} scheduled with ${clientName} for ${formattedDate} (${timezone || 'UTC'})`);
    console.log('========================================\n');

    return {
      success: true,
      data: { eventId: eventDoc.id, ...eventData },
      message: `✓ ${eventTypeNames[eventType]} scheduled with ${clientName} for ${formattedDate} (${duration} minutes)`
    };
  } catch (error: any) {
    console.error('\n========================================');
    console.error('[executeScheduleCall] ❌ ERROR:');
    console.error('  - Message:', error.message);
    console.error('  - Stack:', error.stack);
    console.error('========================================\n');
    return {
      success: false,
      error: `Failed to schedule: ${error.message || 'Unknown error'}`
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
      clientId = providedClientId;
    } else if (clientName) {
      // Find client by name
      const matchResults = await findContactMatches(trainerId, clientName);

      // Multiple matches -> return SELECTION_REQUIRED
      if (matchResults.length > 1) {
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
    }

    // Create reminder
    const remindersRef = db.collection('reminders');
    const reminderDoc = remindersRef.doc(); // Generate document ID first

    const reminderData = {
      id: reminderDoc.id, // Include the document ID as a field (matches iOS app pattern)
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

    await reminderDoc.set(reminderData); // Use set() instead of add() since we pre-generated the ID

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
  const db = admin.firestore();
  const usersRef = db.collection('users');
  const allUsersSnapshot = await usersRef.get();

  const matches: Array<{ userId: string; displayName: string; email: string; chatId: string }> = [];

  for (const userDoc of allUsersSnapshot.docs) {
    const userData = userDoc.data();
    const displayName = userData.displayName;

    if (!displayName) {
      continue;
    }

    const nameLower = displayName.toLowerCase();
    const searchLower = searchName.toLowerCase();

    // Fuzzy match
    const exactMatch = nameLower === searchLower;
    const containsMatch = nameLower.includes(searchLower) || searchLower.includes(nameLower);
    const editDistance = levenshteinDistance(nameLower, searchLower);
    const distanceMatch = editDistance <= 2;

    const isMatch = exactMatch || containsMatch || distanceMatch;

    if (isMatch) {
      // Find chat between trainer and this user
      const chatsRef = db.collection('chats');
      const chatQuery = await chatsRef
        .where('members', 'array-contains', trainerId)
        .get();

      const matchingChat = chatQuery.docs.find(doc => {
        const members = doc.data().members || [];
        const hasUser = members.includes(userDoc.id);
        return hasUser;
      });

      if (matchingChat) {
        matches.push({
          userId: userDoc.id,
          displayName,
          email: userData.email || 'No email',
          chatId: matchingChat.id
        });
      }
    }
  }

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
      const matchResults = await findContactMatches(trainerId, clientName);

      // Multiple matches -> return SELECTION_REQUIRED
      if (matchResults.length > 1) {
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
    const messageDoc = messagesRef.doc(); // Generate document ID first

    const messageData = {
      id: messageDoc.id, // Include the document ID as a field (matches iOS app pattern)
      text: messageText,
      senderID: trainerId,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      readBy: [trainerId]
    };

    await messageDoc.set(messageData); // Use set() instead of add() since we pre-generated the ID

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
 * Reschedule an existing event
 * PR #010B: AI Scheduling + Conflict Detection
 *
 * @param trainerId - ID of the trainer
 * @param params - Reschedule parameters
 * @returns Execution result
 */
export async function executeRescheduleEvent(
  trainerId: string,
  params: { eventId: string; newDateTime: string; newDuration?: number }
): Promise<FunctionExecutionResult> {
  try {
    const { eventId, newDateTime, newDuration } = params;

    const db = admin.firestore();
    const eventRef = db.collection('calendar').doc(eventId);
    const eventDoc = await eventRef.get();

    if (!eventDoc.exists) {
      return {
        success: false,
        error: 'Event not found.'
      };
    }

    const eventData = eventDoc.data();

    // Verify trainer owns this event
    if (eventData?.trainerId !== trainerId) {
      return {
        success: false,
        error: "You don't have permission to modify this event."
      };
    }

    // Validate new date is in the future
    const newStartTime = new Date(newDateTime);
    const now = new Date();

    if (newStartTime <= now) {
      return {
        success: false,
        error: 'New time must be in the future.'
      };
    }

    // Calculate new end time
    const duration = newDuration || eventData.duration || 60;
    const newEndTime = new Date(newStartTime.getTime() + duration * 60 * 1000);

    // Check for conflicts (excluding this event)
    const conflicts = await detectConflicts(trainerId, newStartTime, newEndTime);
    const filteredConflicts = conflicts.filter(c => c.id !== eventId);

    if (filteredConflicts.length > 0) {
      return {
        success: false,
        error: `Cannot reschedule: conflicts with "${filteredConflicts[0].title}"`
      };
    }

    // Update event
    await eventRef.update({
      startTime: admin.firestore.Timestamp.fromDate(newStartTime),
      endTime: admin.firestore.Timestamp.fromDate(newEndTime)
    });

    const formattedDate = newStartTime.toLocaleString('en-US', {
      weekday: 'long',
      month: 'long',
      day: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
      hour12: true
    });

    return {
      success: true,
      data: { eventId, newStartTime: newStartTime.toISOString() },
      message: `✓ Event rescheduled to ${formattedDate}`
    };
  } catch (error: any) {
    console.error('[executeRescheduleEvent] Error:', error);
    return {
      success: false,
      error: `Failed to reschedule event: ${error.message || 'Unknown error'}`
    };
  }
}

/**
 * Cancel an existing event
 * PR #010B: AI Scheduling + Conflict Detection
 *
 * @param trainerId - ID of the trainer
 * @param params - Cancel parameters
 * @returns Execution result
 */
export async function executeCancelEvent(
  trainerId: string,
  params: { eventId: string }
): Promise<FunctionExecutionResult> {
  try {
    const { eventId } = params;

    const db = admin.firestore();
    const eventRef = db.collection('calendar').doc(eventId);
    const eventDoc = await eventRef.get();

    if (!eventDoc.exists) {
      return {
        success: false,
        error: 'Event not found.'
      };
    }

    const eventData = eventDoc.data();

    // Verify trainer owns this event
    if (eventData?.trainerId !== trainerId) {
      return {
        success: false,
        error: "You don't have permission to cancel this event."
      };
    }

    // Update status to cancelled
    await eventRef.update({
      status: 'cancelled'
    });

    return {
      success: true,
      data: { eventId },
      message: `✓ Event "${eventData.title}" cancelled`
    };
  } catch (error: any) {
    console.error('[executeCancelEvent] Error:', error);
    return {
      success: false,
      error: `Failed to cancel event: ${error.message || 'Unknown error'}`
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
    case 'rescheduleEvent':
      return executeRescheduleEvent(trainerId, parameters);
    case 'cancelEvent':
      return executeCancelEvent(trainerId, parameters);
    default:
      return {
        success: false,
        error: `Unknown function: ${functionName}`
      };
  }
}
