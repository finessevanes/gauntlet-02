//
//  UserPresence.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #12
//  User presence data model for online/offline status tracking
//

import Foundation
import FirebaseDatabase

/// UserPresence model representing online/offline status
/// Uses Firebase Realtime Database for real-time presence tracking
struct UserPresence: Identifiable, Codable {
    /// Unique user identifier (Firebase UID)
    let id: String
    
    /// Online/offline status
    var isOnline: Bool
    
    /// Timestamp of last status change
    var lastChanged: Date
    
    /// Initialize UserPresence with explicit values
    /// - Parameters:
    ///   - id: User's Firebase UID
    ///   - isOnline: Online status (true = online, false = offline)
    ///   - lastChanged: Timestamp of last status change
    init(id: String, isOnline: Bool, lastChanged: Date = Date()) {
        self.id = id
        self.isOnline = isOnline
        self.lastChanged = lastChanged
    }
}

