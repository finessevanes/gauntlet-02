//
//  User.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #2
//  User data model matching Firebase Auth structure
//

import Foundation
import FirebaseAuth

/// User model representing authenticated users
/// Matches Firebase Auth user structure for consistency
struct User: Identifiable, Codable, Equatable {
    /// Unique user identifier from Firebase Auth
    let id: String
    
    /// User's email address
    let email: String?
    
    /// User's display name (optional)
    var displayName: String?
    
    /// Profile photo URL (optional)
    var photoURL: String?
    
    /// Timestamp of account creation
    let createdAt: Date
    
    /// Initialize User from Firebase Auth User object
    /// - Parameter firebaseUser: Firebase Auth User object
    init(from firebaseUser: FirebaseAuth.User) {
        self.id = firebaseUser.uid
        self.email = firebaseUser.email
        self.displayName = firebaseUser.displayName
        self.photoURL = firebaseUser.photoURL?.absoluteString
        self.createdAt = firebaseUser.metadata.creationDate ?? Date()
    }
    
    /// Manual initializer for testing or custom user creation
    /// - Parameters:
    ///   - id: Unique user identifier
    ///   - email: User's email address
    ///   - displayName: User's display name
    ///   - photoURL: Profile photo URL string
    ///   - createdAt: Account creation date
    init(id: String, email: String?, displayName: String? = nil, photoURL: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.createdAt = createdAt
    }
}

