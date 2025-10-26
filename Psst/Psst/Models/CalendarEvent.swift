//
//  CalendarEvent.swift
//  Psst
//
//  Created by AI Assistant for PR #008 - AI Function Calling
//  Extended by PR #010A - Calendar Foundation
//

import Foundation
import SwiftUI
import FirebaseFirestore

/**
 * Calendar Event Model
 *
 * Represents a scheduled event: Training session, Call, or Adhoc appointment
 * Created by AI assistant or manually by trainer
 */
struct CalendarEvent: Identifiable, Codable {
    let id: String
    let trainerId: String
    let clientId: String?  // Optional - only for training/call events
    let prospectId: String?  // Optional - for events with prospects
    let title: String
    let startTime: Date  // Changed from dateTime to startTime/endTime
    let endTime: Date
    let eventType: EventType  // NEW: training, call, or adhoc
    let location: String?  // NEW: optional location
    let notes: String?  // NEW: optional notes
    let createdBy: String // "ai" or "trainer"
    let createdAt: Date
    var status: EventStatus

    // MARK: - Google Calendar Sync Fields (PR #010C)
    var googleCalendarEventId: String?  // Google Calendar event ID for updates/deletes
    var syncedAt: Date?  // Last successful sync timestamp

    // DEPRECATED: Kept for backward compatibility with PR #008
    var dateTime: Date { startTime }
    var duration: Int { Int(endTime.timeIntervalSince(startTime) / 60) }
    var clientName: String { title }  // Deprecated, use title instead

    enum EventType: String, Codable {
        case training = "training"
        case call = "call"
        case adhoc = "adhoc"
    }

    enum EventStatus: String, Codable {
        case scheduled = "scheduled"
        case completed = "completed"
        case cancelled = "cancelled"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case trainerId
        case clientId
        case prospectId
        case title
        case startTime
        case endTime
        case eventType
        case location
        case notes
        case createdBy
        case createdAt
        case status
        case googleCalendarEventId
        case syncedAt
    }

    // MARK: - Computed Properties

    /// Icon for event type (🏋️ for training, 📞 for call, 📅 for adhoc)
    var eventTypeIcon: String {
        switch eventType {
        case .training: return "🏋️"
        case .call: return "📞"
        case .adhoc: return "📅"
        }
    }

    /// Color for event type (blue for training, green for call, gray for adhoc)
    var eventTypeColor: Color {
        switch eventType {
        case .training: return .blue
        case .call: return .green
        case .adhoc: return .gray
        }
    }

    /// Formatted display title based on event type
    var displayTitle: String {
        return title
    }

    /// Duration in minutes
    var durationMinutes: Int {
        Int(endTime.timeIntervalSince(startTime) / 60)
    }

    // MARK: - Google Calendar Sync Computed Properties (PR #010C)

    /// Whether event is synced to Google Calendar
    var isSynced: Bool {
        googleCalendarEventId != nil
    }

    /// Sync status text for display (e.g., "Synced 2 minutes ago")
    var syncStatusText: String {
        guard let syncedAt = syncedAt else { return "Not synced" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return "Synced \(formatter.localizedString(for: syncedAt, relativeTo: Date()))"
    }

    init(
        id: String = UUID().uuidString,
        trainerId: String,
        eventType: EventType,
        title: String,
        clientId: String? = nil,
        prospectId: String? = nil,
        startTime: Date,
        endTime: Date,
        location: String? = nil,
        notes: String? = nil,
        createdBy: String = "trainer",
        createdAt: Date = Date(),
        status: EventStatus = .scheduled,
        googleCalendarEventId: String? = nil,
        syncedAt: Date? = nil
    ) {
        self.id = id
        self.trainerId = trainerId
        self.eventType = eventType
        self.title = title
        self.clientId = clientId
        self.prospectId = prospectId
        self.startTime = startTime
        self.endTime = endTime
        self.location = location
        self.notes = notes
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.status = status
        self.googleCalendarEventId = googleCalendarEventId
        self.syncedAt = syncedAt
    }

    // Firestore conversion with backward compatibility for PR #008
    init?(document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }

        self.id = document.documentID
        self.trainerId = data["trainerId"] as? String ?? ""
        self.clientId = data["clientId"] as? String
        self.prospectId = data["prospectId"] as? String
        self.title = data["title"] as? String ?? ""
        self.location = data["location"] as? String
        self.notes = data["notes"] as? String

        // Handle new startTime/endTime format
        if let startTimestamp = data["startTime"] as? Timestamp {
            self.startTime = startTimestamp.dateValue()
        } else if let dateTime = data["dateTime"] as? Timestamp {
            // Backward compatibility: use old dateTime field
            self.startTime = dateTime.dateValue()
        } else {
            return nil
        }

        if let endTimestamp = data["endTime"] as? Timestamp {
            self.endTime = endTimestamp.dateValue()
        } else if let dateTime = data["dateTime"] as? Timestamp,
                  let duration = data["duration"] as? Int {
            // Backward compatibility: calculate endTime from dateTime + duration
            self.endTime = dateTime.dateValue().addingTimeInterval(TimeInterval(duration * 60))
        } else {
            // Default to 1 hour if no endTime
            self.endTime = self.startTime.addingTimeInterval(3600)
        }

        // Handle eventType (new field)
        if let eventTypeString = data["eventType"] as? String,
           let eventType = EventType(rawValue: eventTypeString) {
            self.eventType = eventType
        } else {
            // Backward compatibility: default to .call for old events from PR #008
            self.eventType = .call
        }

        self.createdBy = data["createdBy"] as? String ?? "trainer"

        if let timestamp = data["createdAt"] as? Timestamp {
            self.createdAt = timestamp.dateValue()
        } else {
            self.createdAt = Date()
        }

        if let statusString = data["status"] as? String,
           let eventStatus = EventStatus(rawValue: statusString) {
            self.status = eventStatus
        } else {
            self.status = .scheduled
        }

        // PR #010C: Google Calendar sync fields (optional)
        self.googleCalendarEventId = data["googleCalendarEventId"] as? String
        if let syncedAtTimestamp = data["syncedAt"] as? Timestamp {
            self.syncedAt = syncedAtTimestamp.dateValue()
        } else {
            self.syncedAt = nil
        }
    }

    // Convert to Firestore dictionary
    func toFirestore() -> [String: Any] {
        var dict: [String: Any] = [
            "trainerId": trainerId,
            "title": title,
            "startTime": Timestamp(date: startTime),
            "endTime": Timestamp(date: endTime),
            "eventType": eventType.rawValue,
            "createdBy": createdBy,
            "createdAt": Timestamp(date: createdAt),
            "status": status.rawValue
        ]

        // Add optional fields if present
        if let clientId = clientId {
            dict["clientId"] = clientId
        }
        if let prospectId = prospectId {
            dict["prospectId"] = prospectId
        }
        if let location = location {
            dict["location"] = location
        }
        if let notes = notes {
            dict["notes"] = notes
        }

        // PR #010C: Google Calendar sync fields (optional)
        if let googleCalendarEventId = googleCalendarEventId {
            dict["googleCalendarEventId"] = googleCalendarEventId
        }
        if let syncedAt = syncedAt {
            dict["syncedAt"] = Timestamp(date: syncedAt)
        }

        return dict
    }

    // Formatted date string for display
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: startTime)
    }

    // Formatted start time for display (e.g., "2:00 PM")
    var formattedStartTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: startTime)
    }

    // Formatted time range for display (e.g., "2:00 PM - 3:00 PM")
    var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }

    // Is event in the past?
    var isPast: Bool {
        endTime < Date()
    }

    // Is event happening now?
    var isNow: Bool {
        let now = Date()
        return now >= startTime && now <= endTime
    }
}
