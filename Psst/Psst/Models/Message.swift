//
//  Message.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #5
//  Message data model matching Firestore schema for individual messages
//

import Foundation
import FirebaseFirestore

/// Message send status for optimistic UI
/// Tracks the delivery state of a message from client to server
enum MessageSendStatus: String, Codable {
    case sending    // Message being sent to Firestore
    case queued     // Message queued for offline sync
    case delivered  // Message confirmed by Firestore
    case failed     // Message send failed
}

/// Message model representing individual messages within a chat
/// Supports read receipts, sender identification, and optimistic UI status
struct Message: Identifiable, Codable, Equatable {
    /// Unique message identifier
    let id: String
    
    /// Text content of the message (1-10,000 characters)
    let text: String
    
    /// User ID of the message sender
    let senderID: String
    
    /// Timestamp when the message was sent
    let timestamp: Date
    
    /// Array of user IDs who have read this message
    var readBy: [String]
    
    /// Send status for optimistic UI (client-side only, not persisted to Firestore)
    var sendStatus: MessageSendStatus?
    
    /// Media support (PR #009)
    /// Optional fields for image messages
    var mediaType: String?              // e.g., "image"
    var mediaURL: String?               // Download URL from Firebase Storage
    var mediaThumbnailURL: String?      // Thumbnail URL for performance
    var mediaSize: Int?                 // File size in bytes
    var mediaDimensions: [String: Int]? // {"width": 1920, "height": 1080}
    
    /// CodingKeys to exclude sendStatus from Firestore serialization
    enum CodingKeys: String, CodingKey {
        case id, text, senderID, timestamp, readBy
        case mediaType, mediaURL, mediaThumbnailURL, mediaSize, mediaDimensions
    }
    
    /// Custom decoder to handle Firestore serverTimestamp (which is null initially)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        senderID = try container.decode(String.self, forKey: .senderID)

        // Handle null timestamp from Firestore serverTimestamp
        // Use current date as fallback if timestamp is null
        timestamp = (try? container.decode(Date.self, forKey: .timestamp)) ?? Date()

        readBy = try container.decode([String].self, forKey: .readBy)

        // Media fields (optional)
        mediaType = try? container.decode(String.self, forKey: .mediaType)
        mediaURL = try? container.decode(String.self, forKey: .mediaURL)
        mediaThumbnailURL = try? container.decode(String.self, forKey: .mediaThumbnailURL)
        mediaSize = try? container.decode(Int.self, forKey: .mediaSize)
        mediaDimensions = try? container.decode([String: Int].self, forKey: .mediaDimensions)

        // sendStatus is client-only, not decoded from Firestore
        sendStatus = nil
    }
    
    /// Initialize Message with default values
    /// - Parameters:
    ///   - id: Unique message identifier
    ///   - text: Message text content
    ///   - senderID: User ID of the sender
    ///   - timestamp: Message timestamp (default: now)
    ///   - readBy: Array of user IDs who read the message (default: empty)
    ///   - sendStatus: Send status for optimistic UI (default: nil)
    init(id: String, text: String, senderID: String,
         timestamp: Date = Date(), readBy: [String] = [],
         sendStatus: MessageSendStatus? = nil,
         mediaType: String? = nil,
         mediaURL: String? = nil,
         mediaThumbnailURL: String? = nil,
         mediaSize: Int? = nil,
         mediaDimensions: [String: Int]? = nil) {
        self.id = id
        self.text = text
        self.senderID = senderID
        self.timestamp = timestamp
        self.readBy = readBy
        self.sendStatus = sendStatus
        self.mediaType = mediaType
        self.mediaURL = mediaURL
        self.mediaThumbnailURL = mediaThumbnailURL
        self.mediaSize = mediaSize
        self.mediaDimensions = mediaDimensions
    }
    
    /// Convert Message model to dictionary for Firestore writes
    /// Uses server timestamps for consistency across devices
    /// - Returns: Dictionary representation suitable for Firestore setData/updateData
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "text": text,
            "senderID": senderID,
            "timestamp": FieldValue.serverTimestamp(),
            "readBy": readBy
        ]
        
        // Include media fields if present
        if let mediaType = mediaType { dict["mediaType"] = mediaType }
        if let mediaURL = mediaURL { dict["mediaURL"] = mediaURL }
        if let mediaThumbnailURL = mediaThumbnailURL { dict["mediaThumbnailURL"] = mediaThumbnailURL }
        if let mediaSize = mediaSize { dict["mediaSize"] = mediaSize }
        if let mediaDimensions = mediaDimensions { dict["mediaDimensions"] = mediaDimensions }
        
        return dict
    }

    /// Whether this message contains an image payload
    func isImageMessage() -> Bool {
        return mediaType == "image" && (mediaURL?.isEmpty == false)
    }
    
    /// Check if a specific user has read this message
    /// - Parameter userID: The user ID to check
    /// - Returns: True if the user has read this message, false otherwise
    func isReadBy(userID: String) -> Bool {
        return readBy.contains(userID)
    }
    
    /// Check if this message was sent by the current user
    /// - Parameter currentUserID: The current user's ID
    /// - Returns: True if the current user sent this message, false otherwise
    func isFromCurrentUser(currentUserID: String) -> Bool {
        return senderID == currentUserID
    }
    
    /// Check if this message has been delivered successfully
    /// - Returns: True if the message is delivered or has no status (Firestore messages)
    func isDelivered() -> Bool {
        return sendStatus == .delivered || sendStatus == nil
    }
}
