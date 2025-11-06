/**
 * Google Calendar Service
 *
 * Handles syncing Psst calendar events to Google Calendar.
 * Uses OAuth 2.0 refresh tokens stored in Firestore to authenticate.
 */

import { google } from 'googleapis';
import * as admin from 'firebase-admin';

/**
 * Calendar event data from Firestore
 */
interface CalendarEvent {
  id: string;
  trainerId: string;
  title: string;
  startTime: admin.firestore.Timestamp;
  endTime: admin.firestore.Timestamp;
  eventType: 'training' | 'call' | 'adhoc';
  location?: string | null;
  notes?: string | null;
  googleCalendarEventId?: string | null;
}

/**
 * Google OAuth credentials for a user
 */
interface GoogleCredentials {
  refreshToken: string;
  connectedEmail: string;
}

/**
 * Get Google OAuth credentials for a user from Firestore
 * @param userId - User ID
 * @returns Google credentials or null if not connected
 */
export async function getGoogleCredentials(userId: string): Promise<GoogleCredentials | null> {
  const db = admin.firestore();

  try {
    console.log(`[getGoogleCredentials] Fetching credentials for user: ${userId}`);
    const userDoc = await db.collection('users').doc(userId).get();
    const userData = userDoc.data();

    if (!userData) {
      console.log(`[getGoogleCredentials] ❌ User document not found for: ${userId}`);
      return null;
    }

    // Read nested structure: integrations.googleCalendar
    const integrations = userData.integrations as Record<string, any> | undefined;
    const googleCalendar = integrations?.googleCalendar as Record<string, any> | undefined;
    const refreshToken = googleCalendar?.refreshToken as string | undefined;
    const connectedEmail = googleCalendar?.connectedEmail as string | undefined;

    console.log(`[getGoogleCredentials] Has integrations: ${!!integrations}`);
    console.log(`[getGoogleCredentials] Has googleCalendar: ${!!googleCalendar}`);
    console.log(`[getGoogleCredentials] Has refreshToken: ${!!refreshToken}`);
    console.log(`[getGoogleCredentials] Connected email: ${connectedEmail || 'none'}`);

    if (!refreshToken) {
      console.log(`[getGoogleCredentials] ❌ No refresh token found for user: ${userId}`);
      return null;
    }

    console.log(`[getGoogleCredentials] ✅ Credentials found for: ${connectedEmail}`);
    return {
      refreshToken,
      connectedEmail: connectedEmail || 'unknown@gmail.com'
    };
  } catch (error) {
    console.error(`[getGoogleCredentials] ❌ Error fetching credentials:`, error);
    return null;
  }
}

/**
 * Create Google OAuth2 client with refresh token
 * @param refreshToken - OAuth2 refresh token
 * @param clientSecret - Optional OAuth2 client secret (empty for iOS clients)
 * @returns Configured OAuth2 client
 */
function createOAuth2Client(refreshToken: string, clientSecret?: string) {
  // NOTE: For backend OAuth refresh, we use the same iOS client ID
  // iOS clients typically don't need a secret, but we set an empty string for compatibility
  // If you encounter auth issues, you may need to create a separate Web OAuth client with a secret
  const clientId = '505865284795-inggmn5im1kb68ogljqp6cp0oucap8r4.apps.googleusercontent.com';
  const secret = clientSecret || ''; // Empty for iOS clients
  const redirectUri = 'com.googleusercontent.apps.505865284795-inggmn5im1kb68ogljqp6cp0oucap8r4:/oauth2callback';

  console.log(`[createOAuth2Client] Client ID: ${clientId}`);
  console.log(`[createOAuth2Client] Has client secret: ${!!clientSecret}`);
  console.log(`[createOAuth2Client] Redirect URI: ${redirectUri}`);
  console.log(`[createOAuth2Client] Refresh token (first 20 chars): ${refreshToken.substring(0, 20)}...`);

  const oauth2Client = new google.auth.OAuth2(
    clientId,
    secret,
    redirectUri
  );

  oauth2Client.setCredentials({
    refresh_token: refreshToken
  });

  console.log(`[createOAuth2Client] ✅ OAuth2 client created`);
  return oauth2Client;
}

/**
 * Convert Psst CalendarEvent to Google Calendar event format
 * @param event - Psst calendar event
 * @returns Google Calendar event object
 */
function convertToGoogleCalendarFormat(event: CalendarEvent) {
  return {
    summary: event.title,
    description: event.notes || `Psst ${event.eventType} event`,
    start: {
      dateTime: event.startTime.toDate().toISOString(),
      timeZone: 'UTC'
    },
    end: {
      dateTime: event.endTime.toDate().toISOString(),
      timeZone: 'UTC'
    },
    location: event.location || undefined,
    source: {
      title: 'Psst',
      url: 'https://psst.app'
    },
    extendedProperties: {
      private: {
        psstEventId: event.id,
        psstEventType: event.eventType
      }
    }
  };
}

/**
 * Sync a calendar event to Google Calendar
 * @param event - Calendar event to sync
 * @param clientSecret - Optional OAuth2 client secret (empty for iOS clients)
 * @returns Google Calendar event ID
 */
export async function syncEventToGoogleCalendar(
  event: CalendarEvent,
  clientSecret?: string
): Promise<string> {
  console.log(`[syncEventToGoogleCalendar] Starting sync for event: ${event.id}`);
  console.log(`[syncEventToGoogleCalendar] Trainer ID: ${event.trainerId}`);
  console.log(`[syncEventToGoogleCalendar] Event title: ${event.title}`);

  // Get user's Google credentials
  const credentials = await getGoogleCredentials(event.trainerId);

  if (!credentials) {
    console.log(`[syncEventToGoogleCalendar] ❌ No credentials found - Google Calendar not connected`);
    throw new Error('Google Calendar not connected');
  }

  console.log(`[syncEventToGoogleCalendar] ✅ Credentials retrieved for: ${credentials.connectedEmail}`);

  // Create OAuth2 client
  const oauth2Client = createOAuth2Client(credentials.refreshToken, clientSecret);

  // Create calendar API client
  const calendar = google.calendar({ version: 'v3', auth: oauth2Client });
  console.log(`[syncEventToGoogleCalendar] ✅ Calendar API client created`);

  try {
    // Convert event to Google Calendar format
    const googleEvent = convertToGoogleCalendarFormat(event);
    console.log(`[syncEventToGoogleCalendar] Event converted to Google format`);
    console.log(`[syncEventToGoogleCalendar] Summary: ${googleEvent.summary}`);
    console.log(`[syncEventToGoogleCalendar] Start: ${googleEvent.start.dateTime}`);

    // Check if event already exists (UPDATE case)
    if (event.googleCalendarEventId) {
      console.log(`[syncEventToGoogleCalendar] Updating existing event: ${event.googleCalendarEventId}`);
      const response = await calendar.events.update({
        calendarId: 'primary',
        eventId: event.googleCalendarEventId,
        requestBody: googleEvent
      });

      console.log(`[syncEventToGoogleCalendar] ✅ Event updated successfully: ${response.data.id}`);
      return response.data.id!;
    } else {
      // CREATE new event
      console.log(`[syncEventToGoogleCalendar] Creating new event in Google Calendar`);
      const response = await calendar.events.insert({
        calendarId: 'primary',
        requestBody: googleEvent
      });

      console.log(`[syncEventToGoogleCalendar] ✅ Event created successfully: ${response.data.id}`);
      return response.data.id!;
    }
  } catch (error: any) {
    console.error(`[syncEventToGoogleCalendar] ❌ Error syncing to Google Calendar:`, error);
    console.error(`[syncEventToGoogleCalendar] Error code: ${error.code}`);
    console.error(`[syncEventToGoogleCalendar] Error message: ${error.message}`);
    console.error(`[syncEventToGoogleCalendar] Full error:`, JSON.stringify(error, null, 2));
    throw new Error(`Failed to sync to Google Calendar: ${error.message}`);
  }
}

/**
 * Delete an event from Google Calendar
 * @param trainerId - ID of the trainer/user
 * @param googleEventId - Google Calendar event ID
 * @param clientSecret - Optional OAuth2 client secret (empty for iOS clients)
 */
export async function deleteEventFromGoogleCalendar(
  trainerId: string,
  googleEventId: string,
  clientSecret?: string
): Promise<void> {
  // Get user's Google credentials
  const credentials = await getGoogleCredentials(trainerId);

  if (!credentials) {
    return;
  }

  // Create OAuth2 client
  const oauth2Client = createOAuth2Client(credentials.refreshToken, clientSecret);

  // Create calendar API client
  const calendar = google.calendar({ version: 'v3', auth: oauth2Client });

  try {
    await calendar.events.delete({
      calendarId: 'primary',
      eventId: googleEventId
    });
  } catch (error: any) {
    // Don't throw - deletion is not critical
  }
}
