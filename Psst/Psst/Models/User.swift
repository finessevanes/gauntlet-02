//
//  User.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #2
//  Updated by Caleb (Coder Agent) - PR #3 (Firestore integration)
//  User data model matching Firebase Auth structure
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

/// User model representing authenticated users
/// Matches Firebase Auth user structure for consistency
struct User: Identifiable, Codable, Equatable {
    /// Unique user identifier from Firebase Auth
    let id: String

    /// User's email address
    let email: String

    /// User's display name
    var displayName: String

    /// Profile photo URL (optional)
    var photoURL: String?

    /// Timestamp of account creation
    let createdAt: Date

    /// Timestamp of last profile update
    var updatedAt: Date
    
    /// Firebase Cloud Messaging device token for push notifications
    /// Nil if user hasn't granted notification permission or token not yet generated
    var fcmToken: String?

    /// CodingKeys enum to map Swift property names to Firestore field names
    /// Maps 'id' property to 'uid' in Firestore for consistency with Firebase Auth
    enum CodingKeys: String, CodingKey {
        case id = "uid"
        case email
        case displayName
        case photoURL
        case createdAt
        case updatedAt
        case fcmToken
    }

    /// Initialize User from Firebase Auth User object
    /// - Parameter firebaseUser: Firebase Auth User object
    init(from firebaseUser: FirebaseAuth.User) {
        let now = Date()
        self.id = firebaseUser.uid
        self.email = firebaseUser.email ?? ""
        self.displayName = firebaseUser.displayName ?? firebaseUser.email?.components(separatedBy: "@").first ?? "User"
        self.photoURL = firebaseUser.photoURL?.absoluteString
        self.createdAt = firebaseUser.metadata.creationDate ?? now
        self.updatedAt = now
        self.fcmToken = nil
    }

    /// Manual initializer for testing or custom user creation
    /// - Parameters:
    ///   - id: Unique user identifier
    ///   - email: User's email address
    ///   - displayName: User's display name
    ///   - photoURL: Profile photo URL string
    ///   - createdAt: Account creation date
    ///   - updatedAt: Last update timestamp
    ///   - fcmToken: Firebase Cloud Messaging token (optional)
    init(id: String, email: String, displayName: String, photoURL: String? = nil, createdAt: Date = Date(), updatedAt: Date = Date(), fcmToken: String? = nil) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.fcmToken = fcmToken
    }

    /// Convert User model to dictionary for Firestore writes
    /// Uses server timestamps for createdAt and updatedAt to ensure consistency across clients
    /// - Returns: Dictionary representation suitable for Firestore setData/updateData
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "uid": id,
            "email": email,
            "displayName": displayName,
            "updatedAt": FieldValue.serverTimestamp()
        ]

        // Add optional photoURL if present
        if let photoURL = photoURL {
            dict["photoURL"] = photoURL
        }

        // For new document creation, include createdAt
        // For updates, this will be ignored if field already exists
        dict["createdAt"] = FieldValue.serverTimestamp()

        return dict
    }
}

