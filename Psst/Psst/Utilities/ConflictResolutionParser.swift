//
//  ConflictResolutionParser.swift
//  Psst
//
//  Refactored from PR #018
//  Parses conflict detection responses from backend
//

import Foundation
import FirebaseAuth

/// Utility for parsing conflict detection responses
struct ConflictResolutionParser {

    /// Parse conflict data from backend response
    /// - Parameters:
    ///   - data: Response data dictionary
    ///   - originalParameters: Original scheduling parameters
    /// - Returns: PendingConflictResolution if parsing succeeds, nil otherwise
    static func parse(data: [String: Any], originalParameters: [String: Any]) -> PendingConflictResolution? {
        // Parse required fields
        guard let conflictingEventData = data["conflictingEvent"] as? [String: Any],
              let suggestionsData = data["suggestions"] as? [String],
              let originalRequest = data["originalRequest"] as? [String: Any] else {
            return nil
        }

        guard let eventId = conflictingEventData["id"] as? String,
              let eventTitle = conflictingEventData["title"] as? String,
              let startTimeString = conflictingEventData["startTime"] as? String,
              let endTimeString = conflictingEventData["endTime"] as? String else {
            return nil
        }

        // Parse dates
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let startTime = isoFormatter.date(from: startTimeString),
              let endTime = isoFormatter.date(from: endTimeString) else {
            return nil
        }

        // Create CalendarEvent for the conflicting event
        let trainerId = Auth.auth().currentUser?.uid ?? ""
        let conflictingEvent = CalendarEvent(
            id: eventId,
            trainerId: trainerId,
            eventType: .adhoc,
            title: eventTitle,
            startTime: startTime,
            endTime: endTime
        )

        // Parse suggested times
        let suggestedTimes = suggestionsData.compactMap { isoFormatter.date(from: $0) }
        guard suggestedTimes.count == suggestionsData.count else {
            return nil
        }

        // Extract original request details
        guard let clientName = originalRequest["clientName"] as? String,
              let duration = originalRequest["duration"] as? Int,
              let eventTypeString = originalRequest["eventType"] as? String else {
            return nil
        }

        let eventType = CalendarEvent.EventType(rawValue: eventTypeString) ?? .adhoc
        let clientId = originalRequest["clientId"] as? String
        let prospectId = originalRequest["prospectId"] as? String
        let location = originalRequest["location"] as? String
        let notes = originalRequest["notes"] as? String

        let title = "\(eventType.rawValue.capitalized) with \(clientName)"

        // Create and return conflict resolution
        return PendingConflictResolution(
            conflictingEvent: conflictingEvent,
            suggestedTimes: suggestedTimes,
            eventType: eventType,
            clientName: clientName,
            clientId: clientId,
            prospectId: prospectId,
            title: title,
            duration: duration,
            location: location,
            notes: notes
        )
    }
}
