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

/// User role enum - distinguishes between trainers and clients
/// Roles are immutable after account creation
enum UserRole: String, Codable {
    case trainer = "trainer"
    case client = "client"
}

/// User model representing authenticated users
/// Matches Firebase Auth user structure for consistency
struct User: Identifiable, Codable, Equatable {
    /// Unique user identifier from Firebase Auth
    let id: String

    /// User's email address
    let email: String

    /// User's display name
    var displayName: String

    /// User's role (trainer or client)
    /// Immutable after account creation - used for role-based AI features
    var role: UserRole

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
        case role
        case photoURL
        case createdAt
        case updatedAt
        case fcmToken
    }
    
    /// Custom decoder to handle missing timestamp fields and role gracefully
    /// Backward compatibility: defaults to .trainer role for existing users
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        displayName = try container.decode(String.self, forKey: .displayName)

        // Backward compatibility: default to trainer for existing users without role field
        role = try container.decodeIfPresent(UserRole.self, forKey: .role) ?? .trainer

        photoURL = try container.decodeIfPresent(String.self, forKey: .photoURL)
        fcmToken = try container.decodeIfPresent(String.self, forKey: .fcmToken)

        // Decode timestamps with fallback to current date if missing
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }

    /// Initialize User from Firebase Auth User object
    /// - Parameters:
    ///   - firebaseUser: Firebase Auth User object
    ///   - role: User's role (defaults to .trainer for backward compatibility)
    init(from firebaseUser: FirebaseAuth.User, role: UserRole = .trainer) {
        let now = Date()
        self.id = firebaseUser.uid
        self.email = firebaseUser.email ?? ""
        self.displayName = firebaseUser.displayName ?? firebaseUser.email?.components(separatedBy: "@").first ?? "User"
        self.role = role
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
    ///   - role: User's role (trainer or client)
    ///   - photoURL: Profile photo URL string
    ///   - createdAt: Account creation date
    ///   - updatedAt: Last update timestamp
    ///   - fcmToken: Firebase Cloud Messaging token (optional)
    init(id: String, email: String, displayName: String, role: UserRole = .trainer, photoURL: String? = nil, createdAt: Date = Date(), updatedAt: Date = Date(), fcmToken: String? = nil) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.role = role
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
            "role": role.rawValue,
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

