//
//  MockDataService.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #6
//  DEBUG-only service for seeding test data with one-tap button
//  This file will be removed in PR #8 when real messaging works
//

#if DEBUG
import Foundation
import FirebaseFirestore

/// Service for seeding and clearing mock data for testing purposes
/// Only available in DEBUG builds - will not ship to production
class MockDataService {
    // MARK: - Properties
    
    private let db = Firestore.firestore()
    
    // MARK: - Public Methods
    
    /// Seed Firestore with mock users and chats for testing
    /// Creates 4 mock users and 3 mock chats (2 one-on-one, 1 group)
    /// - Parameter currentUserID: The current authenticated user's ID
    /// - Throws: Firestore errors if write operations fail
    func seedMockData(currentUserID: String) async throws {
        // Create mock users
        let mockUsers = [
            [
                "uid": "mock_user_1",
                "displayName": "Alice Johnson",
                "email": "alice@example.com",
                "createdAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp()
            ],
            [
                "uid": "mock_user_2",
                "displayName": "Bob Smith",
                "email": "bob@example.com",
                "createdAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp()
            ],
            [
                "uid": "mock_user_3",
                "displayName": "Carol White",
                "email": "carol@example.com",
                "createdAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp()
            ],
            [
                "uid": "mock_user_4",
                "displayName": "David Brown",
                "email": "david@example.com",
                "createdAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp()
            ]
        ] as [[String: Any]]
        
        // Write mock users to Firestore
        for user in mockUsers {
            let userID = user["uid"] as! String
            try await db.collection("users").document(userID).setData(user)
        }
        
        // Create mock chats with varying timestamps for sorting tests
        // Chat 1: 1-on-1 with Alice (2 hours ago - middle position)
        let chat1 = [
            "id": "mock_chat_1",
            "members": [currentUserID, "mock_user_1"],
            "lastMessage": "Hey, how are you?",
            "lastMessageTimestamp": Timestamp(date: Date().addingTimeInterval(-7200)), // 2 hours ago
            "isGroupChat": false,
            "createdAt": Timestamp(date: Date().addingTimeInterval(-86400)), // 1 day ago
            "updatedAt": Timestamp(date: Date().addingTimeInterval(-7200))
        ] as [String: Any]
        
        // Chat 2: 1-on-1 with Bob (5 minutes ago - most recent)
        let chat2 = [
            "id": "mock_chat_2",
            "members": [currentUserID, "mock_user_2"],
            "lastMessage": "See you tomorrow!",
            "lastMessageTimestamp": Timestamp(date: Date().addingTimeInterval(-300)), // 5 minutes ago
            "isGroupChat": false,
            "createdAt": Timestamp(date: Date().addingTimeInterval(-259200)), // 3 days ago
            "updatedAt": Timestamp(date: Date().addingTimeInterval(-300))
        ] as [String: Any]
        
        // Chat 3: Group with Carol & David (1 hour ago - second position)
        let chat3 = [
            "id": "mock_chat_3",
            "members": [currentUserID, "mock_user_3", "mock_user_4"],
            "lastMessage": "Group meeting at 3pm",
            "lastMessageTimestamp": Timestamp(date: Date().addingTimeInterval(-3600)), // 1 hour ago
            "isGroupChat": true,
            "createdAt": Timestamp(date: Date().addingTimeInterval(-604800)), // 1 week ago
            "updatedAt": Timestamp(date: Date().addingTimeInterval(-3600))
        ] as [String: Any]
        
        // Write mock chats to Firestore
        try await db.collection("chats").document("mock_chat_1").setData(chat1)
        try await db.collection("chats").document("mock_chat_2").setData(chat2)
        try await db.collection("chats").document("mock_chat_3").setData(chat3)
    }
    
    /// Clear all mock data from Firestore
    /// Removes all mock users and chats created by seedMockData()
    /// - Throws: Firestore errors if delete operations fail
    func clearMockData() async throws {
        // Delete mock users
        let mockUserIDs = ["mock_user_1", "mock_user_2", "mock_user_3", "mock_user_4"]
        for userID in mockUserIDs {
            try await db.collection("users").document(userID).delete()
        }
        
        // Delete mock chats
        let mockChatIDs = ["mock_chat_1", "mock_chat_2", "mock_chat_3"]
        for chatID in mockChatIDs {
            try await db.collection("chats").document(chatID).delete()
        }
    }
}
#endif

