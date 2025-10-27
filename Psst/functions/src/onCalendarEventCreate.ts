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
export const onCalendarEventCreateFunction = functions.firestore
  .document('calendar/{eventId}')
  .onCreate(async (snapshot, context) => {
    const eventId = context.params.eventId;
    const eventData = snapshot.data() as CalendarEvent;

    // Check if already synced (shouldn't happen on onCreate, but safety check)
    if (eventData.googleCalendarEventId) {
      return null;
    }

    try {
      // Attempt to sync to Google Calendar
      const googleEventId = await syncEventToGoogleCalendar({
        id: eventId,
        trainerId: eventData.trainerId,
        title: eventData.title,
        startTime: eventData.startTime,
        endTime: eventData.endTime,
        eventType: eventData.eventType,
        location: eventData.location,
        notes: eventData.notes,
        googleCalendarEventId: eventData.googleCalendarEventId
      });

      // Update Firestore with Google Calendar event ID
      await snapshot.ref.update({
        googleCalendarEventId: googleEventId,
        syncedAt: admin.firestore.FieldValue.serverTimestamp()
      });

      return null;
    } catch (error: any) {
      // Don't throw - we don't want to fail the event creation if Google sync fails
      // The event is still created in Psst, just not synced to Google Calendar
      // User can manually retry sync from the UI later
      return null;
    }
  });
