//
//  CalendarService.swift
//  Psst
//
//  Created for PR #010A: Calendar Foundation (Manual UI + CRUD)
//  Service layer for managing calendar events
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Service for managing calendar events
/// Handles CRUD operations for calendar collection
class CalendarService {

    // MARK: - Singleton

    static let shared = CalendarService()

    // MARK: - Properties

    private let db = Firestore.firestore()
    private let calendarCollection = "calendar"

    /// Private initializer to enforce singleton pattern
    private init() {}

    // MARK: - Public Methods - Event CRUD

    /// Create a new calendar event
    /// - Parameters:
    ///   - trainerId: ID of the trainer creating the event
    ///   - eventType: Type of event (training, call, adhoc)
    ///   - title: Event title
    ///   - clientId: Optional client ID (for training/call events)
    ///   - prospectId: Optional prospect ID (for training/call events)
    ///   - startTime: Event start time
    ///   - endTime: Event end time
    ///   - location: Optional location
    ///   - notes: Optional notes
    ///   - createdBy: Who created the event ("trainer" or "ai")
    /// - Returns: Created CalendarEvent
    /// - Throws: CalendarError
    func createEvent(
        trainerId: String,
        eventType: CalendarEvent.EventType,
        title: String,
        clientId: String? = nil,
        prospectId: String? = nil,
        startTime: Date,
        endTime: Date,
        location: String? = nil,
        notes: String? = nil,
        createdBy: String = "trainer"
    ) async throws -> CalendarEvent {
        // Validate authenticated user matches trainerId
        guard let currentUserId = Auth.auth().currentUser?.uid,
              currentUserId == trainerId else {
            throw CalendarError.unauthorized
        }

        // Validate startTime < endTime
        guard startTime < endTime else {
            throw CalendarError.invalidTimeRange
        }

        // Validate event type requirements
        switch eventType {
        case .training, .call:
            // Training/Call events require clientId or prospectId
            guard clientId != nil || prospectId != nil else {
                throw CalendarError.missingClient
            }
        case .adhoc:
            // Adhoc events should NOT have clientId or prospectId
            guard clientId == nil && prospectId == nil else {
                throw CalendarError.invalidEventType
            }
        }

        // Create event object
        let event = CalendarEvent(
            trainerId: trainerId,
            eventType: eventType,
            title: title,
            clientId: clientId,
            prospectId: prospectId,
            startTime: startTime,
            endTime: endTime,
            location: location,
            notes: notes,
            createdBy: createdBy,
            createdAt: Date(),
            status: .scheduled
        )

        // Write to Firestore
        let eventRef = db.collection(calendarCollection).document(event.id)
        try await eventRef.setData(event.toFirestore())

        return event
    }

    /// Get events for a date range
    /// - Parameters:
    ///   - trainerId: ID of the trainer
    ///   - startDate: Start of date range
    ///   - endDate: End of date range
    /// - Returns: Array of CalendarEvent sorted by startTime
    /// - Throws: CalendarError
    func getEvents(
        trainerId: String,
        startDate: Date,
        endDate: Date
    ) async throws -> [CalendarEvent] {
        // Validate authenticated user matches trainerId
        guard let currentUserId = Auth.auth().currentUser?.uid,
              currentUserId == trainerId else {
            throw CalendarError.unauthorized
        }

        // Query events in date range
        let snapshot = try await db.collection(calendarCollection)
            .whereField("trainerId", isEqualTo: trainerId)
            .whereField("startTime", isGreaterThanOrEqualTo: Timestamp(date: startDate))
            .whereField("startTime", isLessThanOrEqualTo: Timestamp(date: endDate))
            .order(by: "startTime", descending: false)
            .getDocuments()

        // Convert to CalendarEvent objects
        let events = snapshot.documents.compactMap { CalendarEvent(document: $0) }

        return events
    }

    /// Observe events in real-time for a date range
    /// - Parameters:
    ///   - trainerId: ID of the trainer
    ///   - startDate: Start of date range
    ///   - endDate: End of date range
    ///   - completion: Closure called with updated events array
    /// - Returns: ListenerRegistration to remove listener when done
    func observeEvents(
        trainerId: String,
        startDate: Date,
        endDate: Date,
        completion: @escaping ([CalendarEvent]) -> Void
    ) -> ListenerRegistration {
        let query = db.collection(calendarCollection)
            .whereField("trainerId", isEqualTo: trainerId)
            .whereField("startTime", isGreaterThanOrEqualTo: Timestamp(date: startDate))
            .whereField("startTime", isLessThanOrEqualTo: Timestamp(date: endDate))
            .order(by: "startTime", descending: false)

        return query.addSnapshotListener { snapshot, error in
            guard let snapshot = snapshot, error == nil else {
                completion([])
                return
            }

            let events = snapshot.documents.compactMap { CalendarEvent(document: $0) }
            completion(events)
        }
    }

    /// Update an existing event
    /// - Parameters:
    ///   - eventId: ID of the event to update
    ///   - updates: Dictionary of fields to update
    /// - Throws: CalendarError
    func updateEvent(
        eventId: String,
        updates: [String: Any]
    ) async throws {
        // Validate user is authenticated
        guard Auth.auth().currentUser != nil else {
            throw CalendarError.unauthorized
        }

        // Update in Firestore
        let eventRef = db.collection(calendarCollection).document(eventId)
        try await eventRef.updateData(updates)
    }

    /// Delete an event (hard delete - permanently removes from Firestore)
    /// - Parameter eventId: ID of the event to delete
    /// - Throws: CalendarError
    func deleteEvent(eventId: String) async throws {
        // Validate user is authenticated
        guard Auth.auth().currentUser != nil else {
            throw CalendarError.unauthorized
        }

        // Hard delete - permanently remove from Firestore
        let eventRef = db.collection(calendarCollection).document(eventId)
        try await eventRef.delete()
    }

    /// Mark an event as completed
    /// - Parameter eventId: ID of the event to mark completed
    /// - Throws: CalendarError
    func markEventCompleted(eventId: String) async throws {
        // Validate user is authenticated
        guard Auth.auth().currentUser != nil else {
            throw CalendarError.unauthorized
        }

        // Update status to completed
        try await updateEvent(eventId: eventId, updates: ["status": CalendarEvent.EventStatus.completed.rawValue])
    }

    // MARK: - Error Types

    enum CalendarError: LocalizedError {
        case unauthorized
        case notFound
        case invalidEventType
        case missingClient
        case invalidTimeRange
        case networkError(Error)

        var errorDescription: String? {
            switch self {
            case .unauthorized:
                return "You are not authorized to perform this action."
            case .notFound:
                return "Event not found."
            case .invalidEventType:
                return "Invalid event type. Adhoc events cannot have clients or prospects."
            case .missingClient:
                return "Training and call events require a client or prospect."
            case .invalidTimeRange:
                return "End time must be after start time."
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            }
        }
    }
}
