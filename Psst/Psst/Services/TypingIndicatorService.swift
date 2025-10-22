//
//  TypingIndicatorService.swift
//  Psst
//
//  Created by Caleb Agent on PR-13
//  Copyright © 2024 Psst. All rights reserved.
//

import Foundation
import FirebaseDatabase

/// Service to manage real-time typing indicators using Firebase Realtime Database
/// Handles broadcasting typing status, automatic timeouts, and observing other users' typing
class TypingIndicatorService: ObservableObject {
    // MARK: - Properties
    
    /// Firebase Realtime Database reference
    private let database = Database.database().reference()
    
    /// Dictionary tracking active typing listeners by chat ID
    private var typingRefs: [String: DatabaseReference] = [:]
    
    /// Dictionary tracking automatic timeout timers for typing status
    private var typingTimers: [String: Timer] = [:]
    
    /// Dictionary tracking last broadcast time per chat (for throttling)
    private var lastBroadcastTime: [String: Date] = [:]
    
    /// Automatic timeout duration (3 seconds)
    private let typingTimeout: TimeInterval = 3.0
    
    /// Broadcast throttle interval (500ms - max 2 writes per second)
    private let broadcastThrottle: TimeInterval = 0.5
    
    // MARK: - Public Methods
    
    /// Broadcast typing status for the current user in a chat
    /// Automatically sets expiration for 3 seconds and throttles broadcasts
    /// - Parameters:
    ///   - chatID: The chat ID where user is typing
    ///   - userID: The user's Firebase UID
    /// - Throws: Firebase database errors
    func startTyping(chatID: String, userID: String) async throws {
        // Validate parameters
        guard !chatID.isEmpty, !userID.isEmpty else {
            print("[TypingIndicatorService] ✗ Invalid parameters: chatID=\(chatID), userID=\(userID)")
            return
        }
        
        // Debounce: Check if we recently broadcasted
        let key = "\(chatID)_\(userID)"
        if let lastBroadcast = lastBroadcastTime[key],
           Date().timeIntervalSince(lastBroadcast) < broadcastThrottle {
            // Skip this broadcast (too soon after last one)
            return
        }
        
        let typingRef = database.child("typing").child(chatID).child(userID)
        
        // Calculate expiration time (current time + 3 seconds in milliseconds)
        let currentTime = Date().timeIntervalSince1970 * 1000
        let expirationTime = currentTime + 3000
        
        let typingData: [String: Any] = [
            "status": "typing",
            "timestamp": ServerValue.timestamp(),
            "expiresAt": expirationTime
        ]
        
        do {
            try await typingRef.setValue(typingData)
            lastBroadcastTime[key] = Date()
            
            print("[TypingIndicatorService] ✓ Started typing status for user \(userID) in chat \(chatID)")
            
            // Set up auto-clear after 3 seconds (client-side timeout)
            setupTypingTimeout(chatID: chatID, userID: userID)
        } catch {
            print("[TypingIndicatorService] ✗ Error starting typing: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Clear typing status for the current user
    /// - Parameters:
    ///   - chatID: The chat ID
    ///   - userID: The user's Firebase UID
    /// - Throws: Firebase database errors
    func stopTyping(chatID: String, userID: String) async throws {
        // Validate parameters
        guard !chatID.isEmpty, !userID.isEmpty else {
            print("[TypingIndicatorService] ✗ Invalid parameters: chatID=\(chatID), userID=\(userID)")
            return
        }
        
        let typingRef = database.child("typing").child(chatID).child(userID)
        
        do {
            // Remove typing data from Firebase
            try await typingRef.removeValue()
            
            // Cancel timer
            let key = "\(chatID)_\(userID)"
            typingTimers[key]?.invalidate()
            typingTimers.removeValue(forKey: key)
            
            print("[TypingIndicatorService] ✓ Stopped typing status for user \(userID) in chat \(chatID)")
        } catch {
            print("[TypingIndicatorService] ✗ Error stopping typing: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Observe typing users in a specific chat
    /// - Parameters:
    ///   - chatID: The chat ID to observe
    ///   - completion: Callback with array of user IDs currently typing
    /// - Returns: DatabaseReference for listener cleanup
    func observeTypingUsers(chatID: String, completion: @escaping ([String]) -> Void) -> DatabaseReference {
        let typingRef = database.child("typing").child(chatID)
        
        typingRef.observe(.value) { snapshot in
            guard let typingData = snapshot.value as? [String: Any] else {
                completion([])
                return
            }
            
            // Extract user IDs currently typing and filter out expired ones
            let currentTime = Date().timeIntervalSince1970 * 1000
            let typingUserIDs = typingData.keys.filter { userID in
                // Check if not expired
                if let userData = typingData[userID] as? [String: Any],
                   let expiresAt = userData["expiresAt"] as? Double {
                    return expiresAt > currentTime
                }
                return true  // Include if no expiration data (backward compatible)
            }
            
            print("[TypingIndicatorService] 👀 Observed \(typingUserIDs.count) typing users in chat \(chatID)")
            completion(Array(typingUserIDs))
        }
        
        // Store reference for cleanup
        typingRefs[chatID] = typingRef
        return typingRef
    }
    
    /// Stop observing typing users for a chat
    /// - Parameter chatID: The chat ID to stop observing
    func stopObserving(chatID: String) {
        if let ref = typingRefs[chatID] {
            ref.removeAllObservers()
            typingRefs.removeValue(forKey: chatID)
            print("[TypingIndicatorService] ✓ Stopped observing typing for chat \(chatID)")
        }
    }
    
    /// Stop all active typing listeners (call on logout)
    func stopAllObservers() {
        typingRefs.forEach { _, ref in
            ref.removeAllObservers()
        }
        typingRefs.removeAll()
        
        // Cancel all timers
        typingTimers.forEach { _, timer in
            timer.invalidate()
        }
        typingTimers.removeAll()
        
        print("[TypingIndicatorService] ✓ Stopped all typing observers and timers")
    }
    
    // MARK: - Private Methods
    
    /// Set up automatic timeout to clear typing status after 3 seconds
    private func setupTypingTimeout(chatID: String, userID: String) {
        let key = "\(chatID)_\(userID)"
        
        // Cancel existing timer for this chat/user
        typingTimers[key]?.invalidate()
        
        // Create new timer
        let timer = Timer.scheduledTimer(withTimeInterval: typingTimeout, repeats: false) { [weak self] _ in
            Task {
                do {
                    try await self?.stopTyping(chatID: chatID, userID: userID)
                    print("[TypingIndicatorService] ⏱️ Auto-cleared typing after timeout")
                } catch {
                    print("[TypingIndicatorService] ✗ Error in auto-clear: \(error.localizedDescription)")
                }
            }
        }
        
        typingTimers[key] = timer
    }
}

