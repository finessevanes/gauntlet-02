//
//  GroupPresence.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #004
//  Group presence data model for tracking multiple user presences in group chats
//  Ephemeral UI state only - not stored in Firebase
//

import Foundation

/// Convenience model for tracking multiple user presences in a group chat
/// Not stored in Firebase - ephemeral UI state only for group chat presence indicators
/// Manages listener lifecycle and aggregates online/offline status for all group members
struct GroupPresence {
    /// Unique chat identifier this group presence belongs to
    let chatID: String
    
    /// Map of userID to online status (true = online, false = offline)
    var memberPresences: [String: Bool]
    
    /// Map of userID to listenerID for cleanup
    /// Tracks listener UUIDs for each member to enable proper cleanup when leaving group
    var listeners: [String: UUID]
    
    /// Count of online members in this group
    var onlineCount: Int {
        memberPresences.values.filter { $0 }.count
    }
    
    /// Count of offline members in this group
    var offlineCount: Int {
        memberPresences.count - onlineCount
    }
    
    /// Initialize empty GroupPresence for a chat
    /// - Parameter chatID: The chat ID this group presence tracks
    init(chatID: String) {
        self.chatID = chatID
        self.memberPresences = [:]
        self.listeners = [:]
    }
    
    /// Initialize GroupPresence with existing member list
    /// All members default to offline until presence updates arrive
    /// - Parameters:
    ///   - chatID: The chat ID this group presence tracks
    ///   - memberIDs: Array of user IDs to track presence for
    init(chatID: String, memberIDs: [String]) {
        self.chatID = chatID
        // Initialize all members as offline
        self.memberPresences = Dictionary(uniqueKeysWithValues: memberIDs.map { ($0, false) })
        self.listeners = [:]
    }
}

