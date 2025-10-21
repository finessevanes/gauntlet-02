//
//  PresenceService.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #12
//  Service layer for Firebase Realtime Database presence tracking
//  Handles online/offline status with automatic disconnection handling
//

import Foundation
import FirebaseDatabase
import Combine

/// Service for managing user presence (online/offline) status
/// Uses Firebase Realtime Database for real-time presence tracking with onDisconnect() hooks
/// Automatically handles app crashes, network disconnections, and lifecycle events
///
/// Key Features:
/// - Real-time presence updates (<3 second latency)
/// - Automatic offline status on disconnect via Firebase onDisconnect()
/// - Listener lifecycle management to prevent memory leaks
/// - Offline persistence for cached presence data
class PresenceService: ObservableObject {
    
    // MARK: - Properties
    
    /// Firebase Realtime Database reference
    private let database = Database.database().reference()
    
    /// Active presence listeners keyed by userID
    /// Tracked for proper cleanup to prevent memory leaks
    private var presenceRefs: [String: DatabaseReference] = [:]
    
    // MARK: - Public Methods
    
    /// Set the current user's online status
    /// Configures Firebase onDisconnect() hook when going online to automatically set offline on disconnect
    /// - Parameters:
    ///   - userID: The user's Firebase UID
    ///   - isOnline: True for online, false for offline
    /// - Throws: Firebase database errors
    func setOnlineStatus(userID: String, isOnline: Bool) async throws {
        let presenceRef = database.child("presence").child(userID)
        
        let presenceData: [String: Any] = [
            "status": isOnline ? "online" : "offline",
            "lastChanged": ServerValue.timestamp()
        ]
        
        do {
            // Write presence data to Firebase
            try await presenceRef.setValue(presenceData)
            
            // Set up onDisconnect hook when going online
            // This ensures status automatically becomes "offline" if connection drops
            if isOnline {
                let offlineData: [String: Any] = [
                    "status": "offline",
                    "lastChanged": ServerValue.timestamp()
                ]
                try await presenceRef.onDisconnectSetValue(offlineData)
            }
            
            print("[PresenceService] Set \(userID) status to \(isOnline ? "online" : "offline")")
        } catch {
            print("[PresenceService] Error setting online status for \(userID): \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Observe presence status for a specific user
    /// Attaches a real-time listener to Firebase Realtime Database
    /// Listener fires immediately with current status and on every subsequent change
    /// - Parameters:
    ///   - userID: The user ID to observe
    ///   - completion: Callback with Bool (true = online, false = offline)
    /// - Returns: DatabaseReference for listener cleanup
    func observePresence(userID: String, completion: @escaping (Bool) -> Void) -> DatabaseReference {
        let presenceRef = database.child("presence").child(userID)
        
        presenceRef.observe(.value) { snapshot in
            guard let data = snapshot.value as? [String: Any],
                  let status = data["status"] as? String else {
                // Default to offline if data is missing or malformed
                completion(false)
                return
            }
            
            let isOnline = (status == "online")
            completion(isOnline)
        }
        
        // Store reference for cleanup
        presenceRefs[userID] = presenceRef
        return presenceRef
    }
    
    /// Stop observing presence for a specific user
    /// Removes Firebase listener and cleans up internal references
    /// - Parameter userID: The user ID to stop observing
    func stopObserving(userID: String) {
        if let ref = presenceRefs[userID] {
            ref.removeAllObservers()
            presenceRefs.removeValue(forKey: userID)
            print("[PresenceService] Stopped observing \(userID)")
        }
    }
    
    /// Stop all active presence listeners
    /// Called on logout or app termination to prevent memory leaks
    func stopAllObservers() {
        presenceRefs.forEach { userID, ref in
            ref.removeAllObservers()
        }
        presenceRefs.removeAll()
        print("[PresenceService] Stopped all presence observers (\(presenceRefs.count) listeners removed)")
    }
}

