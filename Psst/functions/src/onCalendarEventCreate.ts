/**
 * onCalendarEventCreate Firestore Trigger
 *
 * Automatically syncs new calendar events to Google Calendar.
 * This trigger fires whenever a document is created in the "calendar" collection.
 *
 * Handles events created from:
 * - Manual UI creation
 * - AI chatbot (scheduleCall function)
 * - Any future event creation method
 *
 * PR #010C: Google Calendar Integration
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { syncEventToGoogleCalendar } from './services/googleCalendarService';
import { googleClientSecret } from './config/secrets';

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
  createdBy: 'trainer' | 'ai';
  googleCalendarEventId?: string | null;
  syncedAt?: admin.firestore.Timestamp | null;
}

/**
 * Firestore trigger: Sync calendar events to Google Calendar on create
 *
 * This trigger runs whenever a new document is created in the "calendar" collection.
 * It attempts to sync the event to Google Calendar if the user has connected their account.
 */
export const onCalendarEventCreateFunction = functions
  .runWith({
    secrets: [googleClientSecret],
    timeoutSeconds: 60,
    memory: '256MB'
  })
  .firestore
  .document('calendar/{eventId}')
  .onCreate(async (snapshot, context) => {
    const eventId = context.params.eventId;
    const eventData = snapshot.data() as CalendarEvent;

    // Log event creation trigger
    functions.logger.info('Calendar event created, attempting Google Calendar sync', {
      eventId,
      trainerId: eventData.trainerId,
      title: eventData.title,
      eventType: eventData.eventType,
      createdBy: eventData.createdBy
    });

    // Check if already synced (shouldn't happen on onCreate, but safety check)
    if (eventData.googleCalendarEventId) {
      functions.logger.info('Event already synced to Google Calendar, skipping', {
        eventId,
        googleCalendarEventId: eventData.googleCalendarEventId
      });
      return null;
    }

    try {
      // Get client secret (optional - empty for iOS clients)
      const clientSecret = googleClientSecret.value();

      // Attempt to sync to Google Calendar
      const googleEventId = await syncEventToGoogleCalendar(
        {
          id: eventId,
          trainerId: eventData.trainerId,
          title: eventData.title,
          startTime: eventData.startTime,
          endTime: eventData.endTime,
          eventType: eventData.eventType,
          location: eventData.location,
          notes: eventData.notes,
          googleCalendarEventId: eventData.googleCalendarEventId
        },
        clientSecret
      );

      // Update Firestore with Google Calendar event ID
      await snapshot.ref.update({
        googleCalendarEventId: googleEventId,
        syncedAt: admin.firestore.FieldValue.serverTimestamp()
      });

      // Log successful sync
      functions.logger.info('Successfully synced event to Google Calendar', {
        eventId,
        trainerId: eventData.trainerId,
        googleCalendarEventId: googleEventId,
        title: eventData.title
      });

      return null;
    } catch (error: any) {
      // Log detailed error information
      const errorMessage = error?.message || 'Unknown error';
      const isCredentialsMissing = errorMessage.includes('Google Calendar not connected');

      if (isCredentialsMissing) {
        // User hasn't connected Google Calendar
        functions.logger.warn('Google Calendar sync skipped - user has not connected Google Calendar', {
          eventId,
          trainerId: eventData.trainerId,
          title: eventData.title,
          errorMessage
        });
      } else {
        // Actual Google Calendar API failure
        functions.logger.error('Failed to sync event to Google Calendar', {
          eventId,
          trainerId: eventData.trainerId,
          title: eventData.title,
          errorMessage,
          errorStack: error?.stack,
          // Include additional error details if available
          errorCode: error?.code,
          errorDetails: error?.errors || error?.details
        });
      }

      // Don't throw - we don't want to fail the event creation if Google sync fails
      // The event is still created in Psst, just not synced to Google Calendar
      // User can manually retry sync from the UI later
      return null;
    }
  });
