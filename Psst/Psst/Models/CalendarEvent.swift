//
//  CalendarEvent.swift
//  Psst
//
//  Created by AI Assistant for PR #008 - AI Function Calling
//

import Foundation
import FirebaseFirestore

/**
 * Calendar Event Model
 *
 * Represents a scheduled call/meeting with a client
 * Created by AI assistant via scheduleCall function
 */
struct CalendarEvent: Identifiable, Codable {
    let id: String
    let trainerId: String
    let clientId: String
    let clientName: String
    let title: String
    let dateTime: Date
    let duration: Int // minutes
    let createdBy: String // "ai" or "user"
    let createdAt: Date
    var status: EventStatus

    enum EventStatus: String, Codable {
        case scheduled = "scheduled"
        case completed = "completed"
        case cancelled = "cancelled"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case trainerId
        case clientId
        case clientName
        case title
        case dateTime
        case duration
        case createdBy
        case createdAt
        case status
    }

    init(
        id: String = UUID().uuidString,
        trainerId: String,
        clientId: String,
        clientName: String,
        title: String,
        dateTime: Date,
        duration: Int = 30,
        createdBy: String = "user",
        createdAt: Date = Date(),
        status: EventStatus = .scheduled
    ) {
        self.id = id
        self.trainerId = trainerId
        self.clientId = clientId
        self.clientName = clientName
        self.title = title
        self.dateTime = dateTime
        self.duration = duration
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.status = status
    }

    // Firestore conversion
    init?(document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }

        self.id = document.documentID
        self.trainerId = data["trainerId"] as? String ?? ""
        self.clientId = data["clientId"] as? String ?? ""
        self.clientName = data["clientName"] as? String ?? ""
        self.title = data["title"] as? String ?? ""

        if let timestamp = data["dateTime"] as? Timestamp {
            self.dateTime = timestamp.dateValue()
        } else {
            return nil
        }

        self.duration = data["duration"] as? Int ?? 30
        self.createdBy = data["createdBy"] as? String ?? "user"

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
    }

    // Convert to Firestore dictionary
    func toFirestore() -> [String: Any] {
        return [
            "trainerId": trainerId,
            "clientId": clientId,
            "clientName": clientName,
            "title": title,
            "dateTime": Timestamp(date: dateTime),
            "duration": duration,
            "createdBy": createdBy,
            "createdAt": Timestamp(date: createdAt),
            "status": status.rawValue
        ]
    }

    // Formatted date string for display
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: dateTime)
    }

    // Is event in the past?
    var isPast: Bool {
        dateTime < Date()
    }
}
