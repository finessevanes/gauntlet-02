//
//  CalendarConflictService.swift
//  Psst
//
//  Created for PR #010B: AI Scheduling + Conflict Detection
//  Service layer for detecting scheduling conflicts and suggesting alternatives
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Service for detecting calendar conflicts and suggesting alternative times
/// Used by AI scheduling to prevent double-booking and suggest available slots
class CalendarConflictService {

    // MARK: - Singleton

    static let shared = CalendarConflictService()

    // MARK: - Properties

    private let db = Firestore.firestore()
    private let calendarCollection = "calendar"

    /// Private initializer to enforce singleton pattern
    private init() {}

    // MARK: - Public Methods - Conflict Detection

    /// Detect conflicts in a given time window (±30 minutes)
    /// - Parameters:
    ///   - trainerId: ID of the trainer
    ///   - startTime: Requested start time
    ///   - endTime: Requested end time
    ///   - excludeEventId: Optional event ID to exclude (for rescheduling)
    /// - Returns: Array of conflicting CalendarEvent objects
    /// - Throws: ConflictError
    func detectConflicts(
        trainerId: String,
        startTime: Date,
        endTime: Date,
        excludeEventId: String? = nil
    ) async throws -> [CalendarEvent] {
        // Validate authenticated user matches trainerId
        guard let currentUserId = Auth.auth().currentUser?.uid,
              currentUserId == trainerId else {
            throw ConflictError.unauthorized
        }

        // Validate time range
        guard startTime < endTime else {
            throw ConflictError.invalidTimeRange
        }

        // Query window: ±30 minutes from requested time
        let queryStartTime = startTime.addingTimeInterval(-30 * 60)
        let queryEndTime = endTime.addingTimeInterval(30 * 60)

        // Query events in time range
        let snapshot = try await db.collection(calendarCollection)
            .whereField("trainerId", isEqualTo: trainerId)
            .whereField("startTime", isGreaterThanOrEqualTo: Timestamp(date: queryStartTime))
            .whereField("startTime", isLessThanOrEqualTo: Timestamp(date: queryEndTime))
            .whereField("status", isNotEqualTo: CalendarEvent.EventStatus.cancelled.rawValue)
            .getDocuments()

        // Convert to CalendarEvent objects
        let events = snapshot.documents.compactMap { CalendarEvent(document: $0) }

        // Filter to find actual overlaps
        let conflicts = events.filter { event in
            // Skip excluded event (for rescheduling)
            if let excludeId = excludeEventId, event.id == excludeId {
                return false
            }

            // Check for overlap: event overlaps if it starts before requestedEnd AND ends after requestedStart
            return event.startTime < endTime && event.endTime > startTime
        }

        return conflicts
    }

    /// Suggest alternative times when conflict detected
    /// - Parameters:
    ///   - trainerId: ID of the trainer
    ///   - preferredStartTime: Requested start time that had conflict
    ///   - duration: Event duration in minutes
    ///   - workingHours: Working hours range (start and end times in "HH:mm" format)
    /// - Returns: Array of 3 alternative Date objects (available start times)
    /// - Throws: ConflictError
    func suggestAlternatives(
        trainerId: String,
        preferredStartTime: Date,
        duration: Int,
        workingHours: (start: String, end: String) = ("09:00", "18:00")
    ) async throws -> [Date] {
        // Validate authenticated user matches trainerId
        guard let currentUserId = Auth.auth().currentUser?.uid,
              currentUserId == trainerId else {
            throw ConflictError.unauthorized
        }

        var suggestions: [Date] = []
        var currentDate = preferredStartTime
        let calendar = Calendar.current
        let maxDays = 7 // Look ahead up to 7 days
        var daysChecked = 0

        // Parse working hours
        let workingStartHour = parseWorkingHour(workingHours.start)
        let workingEndHour = parseWorkingHour(workingHours.end)

        while suggestions.count < 3 && daysChecked < maxDays {
            // Start from preferredStartTime + 1 hour on first iteration, then daily
            if daysChecked == 0 {
                currentDate = preferredStartTime.addingTimeInterval(60 * 60) // +1 hour
            } else {
                // Move to next day at working start time
                currentDate = calendar.startOfDay(for: currentDate).addingTimeInterval(24 * 60 * 60)
                let components = DateComponents(hour: workingStartHour.hour, minute: workingStartHour.minute)
                if let nextDayStart = calendar.date(byAdding: components, to: calendar.startOfDay(for: currentDate)) {
                    currentDate = nextDayStart
                }
            }

            // Check slots within working hours for current day
            let dayEnd = calendar.startOfDay(for: currentDate).addingTimeInterval(
                TimeInterval(workingEndHour.hour * 3600 + workingEndHour.minute * 60)
            )

            while currentDate < dayEnd && suggestions.count < 3 {
                // Get hour for time-of-day check
                let currentHour = calendar.component(.hour, from: currentDate)
                let currentMinute = calendar.component(.minute, from: currentDate)

                // Skip if outside working hours
                if currentHour < workingStartHour.hour ||
                   (currentHour == workingEndHour.hour && currentMinute > workingEndHour.minute) ||
                   currentHour >= workingEndHour.hour {
                    break
                }

                // Check if slot is available
                let proposedEndTime = currentDate.addingTimeInterval(TimeInterval(duration * 60))
                let conflicts = try await detectConflicts(
                    trainerId: trainerId,
                    startTime: currentDate,
                    endTime: proposedEndTime
                )

                if conflicts.isEmpty {
                    suggestions.append(currentDate)
                }

                // Move to next 1-hour slot
                currentDate = currentDate.addingTimeInterval(60 * 60)
            }

            daysChecked += 1
        }

        // Throw error if no alternatives found
        if suggestions.isEmpty {
            throw ConflictError.noAlternativesAvailable
        }

        return suggestions
    }

    // MARK: - Private Helper Methods

    /// Parse working hour string (e.g., "09:00") into (hour, minute)
    private func parseWorkingHour(_ timeString: String) -> (hour: Int, minute: Int) {
        let components = timeString.split(separator: ":")
        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else {
            return (hour: 9, minute: 0) // Default to 9:00 AM
        }
        return (hour: hour, minute: minute)
    }

    // MARK: - Error Types

    enum ConflictError: LocalizedError {
        case unauthorized
        case invalidTimeRange
        case noAlternativesAvailable
        case networkError(Error)

        var errorDescription: String? {
            switch self {
            case .unauthorized:
                return "You are not authorized to perform this action."
            case .invalidTimeRange:
                return "End time must be after start time."
            case .noAlternativesAvailable:
                return "No available times in the next week. Please choose a time manually."
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            }
        }
    }
}
