//
//  Reminder.swift
//  Psst
//
//  Created by AI Assistant for PR #008 - AI Function Calling
//

import Foundation
import FirebaseFirestore

/**
 * Reminder Model
 *
 * Represents a follow-up reminder for the trainer
 * Created by AI assistant via setReminder function
 */
struct Reminder: Identifiable, Codable {
    let id: String
    let trainerId: String
    let clientId: String?
    let clientName: String?
    let reminderText: String
    let dueDate: Date
    let createdBy: String // "ai" or "user"
    let createdAt: Date
    var completed: Bool
    var completedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case trainerId
        case clientId
        case clientName
        case reminderText
        case dueDate
        case createdBy
        case createdAt
        case completed
        case completedAt
    }

    init(
        id: String = UUID().uuidString,
        trainerId: String,
        clientId: String? = nil,
        clientName: String? = nil,
        reminderText: String,
        dueDate: Date,
        createdBy: String = "user",
        createdAt: Date = Date(),
        completed: Bool = false,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.trainerId = trainerId
        self.clientId = clientId
        self.clientName = clientName
        self.reminderText = reminderText
        self.dueDate = dueDate
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.completed = completed
        self.completedAt = completedAt
    }

    // Firestore conversion
    init?(document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }

        self.id = document.documentID
        self.trainerId = data["trainerId"] as? String ?? ""
        self.clientId = data["clientId"] as? String
        self.clientName = data["clientName"] as? String
        self.reminderText = data["reminderText"] as? String ?? ""

        if let timestamp = data["dueDate"] as? Timestamp {
            self.dueDate = timestamp.dateValue()
        } else {
            return nil
        }

        self.createdBy = data["createdBy"] as? String ?? "user"

        if let timestamp = data["createdAt"] as? Timestamp {
            self.createdAt = timestamp.dateValue()
        } else {
            self.createdAt = Date()
        }

        self.completed = data["completed"] as? Bool ?? false

        if let timestamp = data["completedAt"] as? Timestamp {
            self.completedAt = timestamp.dateValue()
        } else {
            self.completedAt = nil
        }
    }

    // Convert to Firestore dictionary
    func toFirestore() -> [String: Any] {
        var dict: [String: Any] = [
            "trainerId": trainerId,
            "reminderText": reminderText,
            "dueDate": Timestamp(date: dueDate),
            "createdBy": createdBy,
            "createdAt": Timestamp(date: createdAt),
            "completed": completed
        ]

        if let clientId = clientId {
            dict["clientId"] = clientId
        }

        if let clientName = clientName {
            dict["clientName"] = clientName
        }

        if let completedAt = completedAt {
            dict["completedAt"] = Timestamp(date: completedAt)
        }

        return dict
    }

    // Formatted date string for display
    var formattedDueDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: dueDate)
    }

    // Is reminder overdue?
    var isOverdue: Bool {
        !completed && dueDate < Date()
    }

    // Is reminder due soon (within 24 hours)?
    var isDueSoon: Bool {
        if completed { return false }
        let tomorrow = Date().addingTimeInterval(24 * 60 * 60)
        return dueDate <= tomorrow && dueDate >= Date()
    }
}
