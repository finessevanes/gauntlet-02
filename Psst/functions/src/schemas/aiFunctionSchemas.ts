/**
 * OpenAI Function Calling Schemas
 *
 * Defines the 4 core AI functions that can be executed by the assistant:
 * 1. scheduleCall - Schedule calendar events with clients
 * 2. setReminder - Create follow-up reminders
 * 3. sendMessage - Send messages on trainer's behalf
 * 4. searchMessages - Search past conversations
 */

/**
 * Function schema for scheduling calls with clients
 */
export const scheduleCallSchema = {
  name: 'scheduleCall',
  description: 'Schedule a call/meeting with a client. Creates a calendar event in the trainer\'s calendar.',
  parameters: {
    type: 'object',
    properties: {
      clientName: {
        type: 'string',
        description: 'Full name of the client to schedule the call with'
      },
      dateTime: {
        type: 'string',
        description:
          'ISO 8601 datetime string in the TRAINER\'S LOCAL TIME (YYYY-MM-DDTHH:MM:SS). Always mirror the exact time the user said (e.g., "3pm tomorrow" → "2025-10-27T15:00:00"). Do NOT convert to UTC, do NOT append a "Z", and let the backend handle any timezone math.'
      },
      timezone: {
        type: 'string',
        description:
          'Trainer timezone as an IANA identifier (e.g., "America/Phoenix"). Always include the timezone specified in the system prompt (or explicitly mentioned by the user) so the backend knows how to interpret the dateTime.'
      },
      duration: {
        type: 'number',
        description: 'Duration of the call in minutes (default: 30 minutes)',
        default: 30
      },
      query: {
        type: 'string',
        description: 'The original natural language request from the trainer (e.g., "schedule a training session with John tomorrow at 3pm"). This is used to detect the event type (training, call, or adhoc). ALWAYS include the exact user query.'
      }
    },
    required: ['clientName', 'dateTime', 'query']
  }
};

/**
 * Function schema for setting reminders
 */
export const setReminderSchema = {
  name: 'setReminder',
  description: 'Create a follow-up reminder for the trainer. Can be client-specific or general.',
  parameters: {
    type: 'object',
    properties: {
      clientName: {
        type: 'string',
        description: 'Client name if this is a client-specific reminder (optional)'
      },
      reminderText: {
        type: 'string',
        description: 'What to remind the trainer about (e.g., "Follow up about diet plan")'
      },
      dateTime: {
        type: 'string',
        description: 'ISO 8601 datetime string for when to show the reminder. Use the EXACT time the user said (e.g., if user says "3pm Friday" return "2024-01-17T15:00:00"). NO timezone conversion, NO "Z" suffix.'
      }
    },
    required: ['reminderText', 'dateTime']
  }
};

/**
 * Function schema for sending messages
 */
export const sendMessageSchema = {
  name: 'sendMessage',
  description: 'Send a message to a client on the trainer\'s behalf. You can specify either the client\'s name OR the chat ID. If using client name and multiple matches exist, user will be prompted to choose. Requires confirmation from trainer before sending.',
  parameters: {
    type: 'object',
    properties: {
      clientName: {
        type: 'string',
        description: 'Name of the client to send the message to (e.g., "Mike", "Mike Johnson"). System will find the matching chat. Use this when you know the client name but not the chat ID.'
      },
      chatId: {
        type: 'string',
        description: 'Firestore chat document ID to send the message to. Only use if you have the exact chat ID from previous context.'
      },
      messageText: {
        type: 'string',
        description: 'The message content to send to the client'
      }
    },
    required: ['messageText']
  }
};

/**
 * Function schema for searching messages
 */
export const searchMessagesSchema = {
  name: 'searchMessages',
  description: 'Search past messages using semantic search. Finds messages based on meaning, not just exact keyword matches.',
  parameters: {
    type: 'object',
    properties: {
      query: {
        type: 'string',
        description: 'Search query to find relevant messages (e.g., "shoulder pain" or "diet questions")'
      },
      chatId: {
        type: 'string',
        description: 'Optional: Limit search to a specific chat/client (Firestore chat ID)'
      },
      limit: {
        type: 'number',
        description: 'Maximum number of results to return (default: 10, max: 50)',
        default: 10
      }
    },
    required: ['query']
  }
};

/**
 * All available AI function schemas
 * Used by OpenAI GPT-4 function calling
 */
export const AIFunctionSchemas = [
  scheduleCallSchema,
  setReminderSchema,
  sendMessageSchema,
  searchMessagesSchema
];

/**
 * Type definitions for function parameters
 */
export interface ScheduleCallParams {
  clientName: string;
  clientId?: string; // Added: Resolved client ID (after selection disambiguation)
  dateTime: string; // Local time in user's timezone (e.g., "2025-10-27T21:00:00")
  duration?: number;
  query?: string; // PR #010B: Original natural language query for event type detection
  timezone?: string; // User's timezone (e.g., "America/Phoenix") - for UTC conversion
}

export interface SetReminderParams {
  clientName?: string;
  clientId?: string; // Added: Resolved client ID (after selection disambiguation)
  reminderText: string;
  dateTime: string;
}

export interface SendMessageParams {
  chatId?: string;
  clientName?: string;
  messageText: string;
}

export interface SearchMessagesParams {
  query: string;
  chatId?: string;
  limit?: number;
}

/**
 * Union type for all function parameters
 */
export type FunctionParams =
  | ScheduleCallParams
  | SetReminderParams
  | SendMessageParams
  | SearchMessagesParams;
