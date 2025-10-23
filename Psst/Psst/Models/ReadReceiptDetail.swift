//
//  ReadReceiptDetail.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #5
//  View-ready read receipt data model for detailed member read status
//

import Foundation

/// View-ready read receipt data with user information
/// Combines message.readBy array with user profile data to show which members have read a message
struct ReadReceiptDetail: Identifiable {
    /// User ID (used for Identifiable conformance in ForEach loops)
    let id: String
    
    /// User's unique identifier
    let userID: String
    
    /// User's display name from Firestore users collection
    let userName: String
    
    /// User's profile photo URL (optional)
    let userPhotoURL: String?
    
    /// Whether this user has read the message
    /// True if user.id is in message.readBy array, false otherwise
    let hasRead: Bool
}

