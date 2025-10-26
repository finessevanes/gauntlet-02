//
//  Client.swift
//  Psst
//
//  Created for PR #009: Trainer-Client Relationship System
//

import Foundation
import FirebaseFirestore

/// Represents a trainer's client - an active relationship with a user who has a Psst account
struct Client: Contact, Codable, Identifiable {
    /// Client's user ID (references /users/{clientId})
    let id: String

    /// Same as id, for clarity
    let clientId: String

    /// Display name auto-populated from user's profile
    let displayName: String

    /// Email used for lookup (must match user's email in /users)
    let email: String

    /// When the client relationship was created
    let addedAt: Date

    /// Last time trainer messaged this client (optional)
    var lastContactedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case clientId
        case displayName
        case email
        case addedAt
        case lastContactedAt
    }

    /// Initialize a new client
    init(id: String, displayName: String, email: String, addedAt: Date = Date(), lastContactedAt: Date? = nil) {
        self.id = id
        self.clientId = id
        self.displayName = displayName
        self.email = email
        self.addedAt = addedAt
        self.lastContactedAt = lastContactedAt
    }

    /// Initialize from Firestore document
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Handle both 'id' and 'clientId' from Firestore
        if let clientId = try? container.decode(String.self, forKey: .clientId) {
            self.id = clientId
            self.clientId = clientId
        } else {
            let id = try container.decode(String.self, forKey: .id)
            self.id = id
            self.clientId = id
        }

        self.displayName = try container.decode(String.self, forKey: .displayName)
        self.email = try container.decode(String.self, forKey: .email)

        // Handle Firestore Timestamp
        if let timestamp = try? container.decode(Timestamp.self, forKey: .addedAt) {
            self.addedAt = timestamp.dateValue()
        } else {
            self.addedAt = try container.decode(Date.self, forKey: .addedAt)
        }

        // Handle optional lastContactedAt
        if let timestamp = try? container.decode(Timestamp.self, forKey: .lastContactedAt) {
            self.lastContactedAt = timestamp.dateValue()
        } else {
            self.lastContactedAt = try? container.decode(Date.self, forKey: .lastContactedAt)
        }
    }

    /// Convert to dictionary for Firestore writes
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "clientId": clientId,
            "displayName": displayName,
            "email": email,
            "addedAt": Timestamp(date: addedAt)
        ]

        if let lastContactedAt = lastContactedAt {
            dict["lastContactedAt"] = Timestamp(date: lastContactedAt)
        }

        return dict
    }
}

