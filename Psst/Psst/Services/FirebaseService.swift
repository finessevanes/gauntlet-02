//
//  FirebaseService.swift
//  Psst
//
//  Created by Caleb (Coder Agent)
//  Firebase configuration and centralized service access
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseDatabase

/// Centralized Firebase configuration and service access
/// Singleton pattern ensures Firebase is configured once on app launch
class FirebaseService {
    /// Shared instance for app-wide access
    static let shared = FirebaseService()
    
    /// Private initializer to enforce singleton pattern
    private init() {}
    
    /// Configure Firebase and enable Firestore offline persistence
    /// Should be called once on app launch in PsstApp.init()
    func configure() {
        // Initialize Firebase with GoogleService-Info.plist
        FirebaseApp.configure()
        
        // Enable Firestore offline persistence for offline-first architecture
        // This allows users to read cached data and queue writes when offline
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings()
        Firestore.firestore().settings = settings
        
        // Configuration complete
    }
    
    // MARK: - Convenience Accessors
    
    /// Access to Firebase Authentication
    var auth: Auth {
        Auth.auth()
    }
    
    /// Access to Firestore Database (primary data store)
    var firestore: Firestore {
        Firestore.firestore()
    }
    
    /// Access to Realtime Database (for presence/typing indicators)
    var realtimeDB: Database {
        Database.database()
    }
}

