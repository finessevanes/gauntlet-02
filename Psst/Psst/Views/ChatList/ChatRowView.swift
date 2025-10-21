//
//  ChatRowView.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #6
//  Individual chat preview row component
//

import SwiftUI
import FirebaseAuth

/// Individual chat row displaying preview information
/// Shows avatar, name, last message, and timestamp
struct ChatRowView: View {
    // MARK: - Properties
    
    let chat: Chat
    
    @State private var displayName: String = ""
    @State private var isLoadingName = true
    
    private let chatService = ChatService()
    
    // MARK: - Body
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar placeholder
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(displayName.prefix(1).uppercased())
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                )
            
            // Chat info
            VStack(alignment: .leading, spacing: 4) {
                // Name
                HStack {
                    if isLoadingName {
                        Text("Loading...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    } else {
                        Text(displayName)
                            .font(.headline)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Timestamp
                    Text(chat.lastMessageTimestamp.relativeTimeString())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Last message
                Text(chat.lastMessage.isEmpty ? "No messages yet" : chat.lastMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 8)
        .task {
            await loadDisplayName()
        }
    }
    
    // MARK: - Private Methods
    
    /// Load display name based on chat type
    /// For 1-on-1: fetch other user's name
    /// For group: show "Group Chat (X members)"
    private func loadDisplayName() async {
        // Handle group chat
        if chat.isGroupChat {
            displayName = "Group Chat (\(chat.members.count))"
            isLoadingName = false
            return
        }
        
        // Handle 1-on-1 chat
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            displayName = "Unknown User"
            isLoadingName = false
            return
        }
        
        // Get other user's ID
        guard let otherUserID = chat.otherUserID(currentUserID: currentUserID) else {
            displayName = "Unknown User"
            isLoadingName = false
            return
        }
        
        // Fetch other user's name
        do {
            let name = try await chatService.fetchUserName(userID: otherUserID)
            displayName = name
            isLoadingName = false
        } catch {
            print("❌ Error loading display name: \(error.localizedDescription)")
            displayName = "Unknown User"
            isLoadingName = false
        }
    }
}

// MARK: - Preview

#Preview {
    List {
        ChatRowView(chat: Chat(
            id: "preview_chat_1",
            members: ["user1", "user2"],
            lastMessage: "Hey, how are you doing today?",
            lastMessageTimestamp: Date().addingTimeInterval(-300), // 5 minutes ago
            isGroupChat: false
        ))
        
        ChatRowView(chat: Chat(
            id: "preview_chat_2",
            members: ["user1", "user2", "user3"],
            lastMessage: "Meeting at 3pm tomorrow",
            lastMessageTimestamp: Date().addingTimeInterval(-3600), // 1 hour ago
            isGroupChat: true
        ))
    }
}

