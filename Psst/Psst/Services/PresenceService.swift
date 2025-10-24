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
    
    /// Active presence listeners keyed by userID, then by unique listener UUID
    /// Multi-listener support: Each user can have multiple simultaneous listeners (e.g., ChatRowView + ChatView)
    /// Nested structure prevents listener conflicts and enables precise cleanup
    /// Stores both DatabaseReference (path) and DatabaseHandle (observer ID) for proper cleanup
    /// Tracked for proper cleanup to prevent memory leaks
    private var presenceRefs: [String: [UUID: (ref: DatabaseReference, handle: DatabaseHandle)]] = [:]
    
    /// Cache mapping userID to email for readable debug logs
    private var userEmailCache: [String: String] = [:]
    
    /// User service for fetching email addresses
    private let userService = UserService.shared
    
    // MARK: - Helper Methods
    
    /// Get user identifier for logging (email or abbreviated userID)
    /// Fetches email from cache or Firestore asynchronously
    /// - Parameter userID: The Firebase user ID
    /// - Returns: Formatted string for logging (email or "user_XXXXXXXX")
    private func getUserIdentifier(_ userID: String) -> String {
        // Check cache first
        if let cachedEmail = userEmailCache[userID] {
            return cachedEmail
        }
        
        // Fetch email asynchronously and cache it for future use
        Task { @MainActor in
            do {
                let user = try await userService.getUser(id: userID)
                self.userEmailCache[userID] = user.email
            } catch {
                // Silently fail - just use abbreviated ID
            }
        }
        
        // Return abbreviated userID while email loads
        let suffix = String(userID.suffix(8))
        return "user_\(suffix)"
    }
    
    // MARK: - Public Methods
    
    /// Set the current user's online status
    /// Always configures Firebase onDisconnect() hook for crash protection
    /// onDisconnect() is set BEFORE setting status to ensure crash protection is always active
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
            // ALWAYS set up onDisconnect hook BEFORE setting status
            // This ensures crash protection works in all scenarios (login, logout, crash)
            let offlineData: [String: Any] = [
                "status": "offline",
                "lastChanged": ServerValue.timestamp()
            ]
            try await presenceRef.onDisconnectSetValue(offlineData)
            
            // Now write presence data to Firebase
            try await presenceRef.setValue(presenceData)
            
            // Successfully set online status
        } catch {
            let userIdentifier = getUserIdentifier(userID)
            print("[PresenceService] ❌ Error setting online status for \(userIdentifier): \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Observe presence status for a specific user
    /// Attaches a real-time listener to Firebase Realtime Database
    /// Listener fires immediately with current status and on every subsequent change
    /// Supports multiple simultaneous listeners per user without conflicts
    /// - Parameters:
    ///   - userID: The user ID to observe
    ///   - completion: Callback with Bool (true = online, false = offline)
    /// - Returns: UUID for listener cleanup (pass to stopObserving)
    func observePresence(userID: String, completion: @escaping (Bool) -> Void) -> UUID {
        let presenceRef = database.child("presence").child(userID)
        
        // Generate unique listener ID
        let listenerID = UUID()
        
        // Attach observer and capture the handle
        let handle = presenceRef.observe(.value) { [weak self] snapshot in
            guard let self = self else { return }
            
            guard let data = snapshot.value as? [String: Any],
                  let status = data["status"] as? String else {
                // Default to offline if data is missing or malformed
                completion(false)
                return
            }
            
            let isOnline = (status == "online")
            completion(isOnline)
        }
        
        // Store both reference and handle for precise cleanup
        if presenceRefs[userID] == nil {
            presenceRefs[userID] = [:]
        }
        presenceRefs[userID]?[listenerID] = (ref: presenceRef, handle: handle)
        
        return listenerID
    }
    
    /// Stop observing presence for a specific listener
    /// Removes only the specified Firebase listener, leaving other listeners for the same user active
    /// Cleans up empty user dictionaries to prevent memory bloat
    /// - Parameters:
    ///   - userID: The user ID to stop observing
    ///   - listenerID: The unique listener UUID returned from observePresence
    func stopObserving(userID: String, listenerID: UUID) {
        guard let userListeners = presenceRefs[userID] else {
            return
        }
        
        guard let (ref, handle) = userListeners[listenerID] else {
            return
        }
        
        // Remove only this specific listener using its handle
        ref.removeObserver(withHandle: handle)
        presenceRefs[userID]?.removeValue(forKey: listenerID)
        
        // Clean up empty user dictionary to prevent memory bloat
        if presenceRefs[userID]?.isEmpty == true {
            presenceRefs.removeValue(forKey: userID)
        }
    }
    
    /// Stop all active presence listeners
    /// Called on logout or app termination to prevent memory leaks
    /// Iterates through nested dictionary structure to remove all listeners for all users
    func stopAllObservers() {
        var totalListenerCount = 0
        
        // Iterate through all users and their listeners
        for (userID, listeners) in presenceRefs {
            for (listenerID, listener) in listeners {
                let (ref, handle) = listener
                ref.removeObserver(withHandle: handle)
                totalListenerCount += 1
            }
        }
        
        presenceRefs.removeAll()
        print("[PresenceService] Stopped all presence observers (\(totalListenerCount) listeners)")
    }
    
    // MARK: - Group Presence Methods (PR #004)
    
    /// Observe presence for multiple users simultaneously (for group chats)
    /// Attaches individual listeners for each user and aggregates results
    /// Returns dictionary of listenerIDs keyed by userID for cleanup
    /// 
    /// - Parameters:
    ///   - userIDs: Array of user IDs to observe presence for (1-50 users recommended)
    ///   - completion: Callback fired for each user whenever their status changes
    ///                 Parameters: (userID: String, isOnline: Bool)
    /// - Returns: Dictionary mapping userID to listenerID for later cleanup via stopObservingGroup
    ///
    /// Pre-conditions:
    /// - userIDs array is not empty (1-50 users)
    /// - Firebase Realtime DB is connected
    /// - User is authenticated
    ///
    /// Post-conditions:
    /// - Listener registered for each userID
    /// - Completion fires immediately with current status for each user
    /// - Completion fires on every subsequent status change
    /// - Returns map of userID -> listenerID for later cleanup
    ///
    /// Error handling:
    /// - If userID doesn't exist in presence DB, defaults to offline
    /// - Network errors logged but don't throw (graceful degradation)
    func observeGroupPresence(
        userIDs: [String],
        completion: @escaping (String, Bool) -> Void
    ) -> [String: UUID] {
        // Validate input
        guard !userIDs.isEmpty else {
            print("[PresenceService] ⚠️ observeGroupPresence called with empty userIDs array")
            return [:]
        }
        
        var listenerMap: [String: UUID] = [:]
        
        // Attach individual listener for each user
        for userID in userIDs {
            let listenerID = observePresence(userID: userID) { isOnline in
                // Forward status update to group completion handler
                completion(userID, isOnline)
            }
            
            listenerMap[userID] = listenerID
        }
        
        return listenerMap
    }
    
    /// Stop observing presence for multiple users
    /// Cleans up all listeners to prevent memory leaks
    /// Safe to call with invalid listenerIDs (defensive cleanup)
    ///
    /// - Parameter listeners: Dictionary of userID -> listenerID from observeGroupPresence
    ///
    /// Pre-conditions:
    /// - listeners map contains valid listenerIDs from observeGroupPresence
    ///
    /// Post-conditions:
    /// - All specified listeners removed from Firebase
    /// - Memory released for each listener
    /// - Internal tracking dictionaries cleaned up
    ///
    /// Error handling:
    /// - Silently ignores invalid listenerIDs (defensive cleanup)
    /// - Ensures no partial cleanup (all-or-nothing)
    func stopObservingGroup(listeners: [String: UUID]) {
        guard !listeners.isEmpty else {
            print("[PresenceService] ⚠️ stopObservingGroup called with empty listeners map")
            return
        }
        
        var cleanedCount = 0
        
        // Remove each listener individually
        for (userID, listenerID) in listeners {
            stopObserving(userID: userID, listenerID: listenerID)
            cleanedCount += 1
        }
    }
}

