//
//  Prospect.swift
//  Psst
//
//  Created for PR #009: Trainer-Client Relationship System
//

import Foundation
import FirebaseFirestore

/// Represents a prospect - a lead who doesn't have a Psst account yet
struct Prospect: Contact, Codable, Identifiable {
    /// Prospect's auto-generated ID
    let id: String

    /// Same as id, for clarity
    let prospectId: String

    /// Prospect's name
    let displayName: String

    /// Placeholder email (prospect-[name]@psst.app)
    let placeholderEmail: String

    /// When the prospect was added
    let addedAt: Date

    /// Set to clientId when prospect is upgraded to client
    var convertedToClientId: String?

    enum CodingKeys: String, CodingKey {
        case id
        case prospectId
        case displayName
        case placeholderEmail
        case addedAt
        case convertedToClientId
    }

    /// Initialize a new prospect
    init(id: String = UUID().uuidString, displayName: String, addedAt: Date = Date(), convertedToClientId: String? = nil) {
        self.id = id
        self.prospectId = id
        self.displayName = displayName
        // Generate placeholder email from display name
        let sanitizedName = displayName
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "[^a-z0-9-]", with: "", options: .regularExpression)
        self.placeholderEmail = "prospect-\(sanitizedName)@psst.app"
        self.addedAt = addedAt
        self.convertedToClientId = convertedToClientId
    }

    /// Initialize from Firestore document
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Handle both 'id' and 'prospectId' from Firestore
        if let prospectId = try? container.decode(String.self, forKey: .prospectId) {
            self.id = prospectId
            self.prospectId = prospectId
        } else {
            let id = try container.decode(String.self, forKey: .id)
            self.id = id
            self.prospectId = id
        }

        self.displayName = try container.decode(String.self, forKey: .displayName)
        self.placeholderEmail = try container.decode(String.self, forKey: .placeholderEmail)

        // Handle Firestore Timestamp
        if let timestamp = try? container.decode(Timestamp.self, forKey: .addedAt) {
            self.addedAt = timestamp.dateValue()
        } else {
            self.addedAt = try container.decode(Date.self, forKey: .addedAt)
        }

        self.convertedToClientId = try? container.decode(String.self, forKey: .convertedToClientId)
    }

    /// Convert to dictionary for Firestore writes
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "prospectId": prospectId,
            "displayName": displayName,
            "placeholderEmail": placeholderEmail,
            "addedAt": Timestamp(date: addedAt)
        ]

        if let convertedToClientId = convertedToClientId {
            dict["convertedToClientId"] = convertedToClientId
        }

        return dict
    }
}

