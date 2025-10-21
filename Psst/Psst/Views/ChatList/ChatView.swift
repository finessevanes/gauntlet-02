//
//  ChatView.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #6
//  PLACEHOLDER: Full implementation coming in PR #7
//

import SwiftUI

/// Placeholder chat view for navigation testing
/// Full implementation with messaging will be in PR #7
struct ChatView: View {
    // MARK: - Properties
    
    let chat: Chat
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 72))
                .foregroundColor(.blue)
            
            Text("Chat View")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Coming in PR #7")
                .font(.headline)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Chat Info:")
                    .font(.headline)
                    .padding(.top)
                
                Text("Chat ID: \(chat.id)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Members: \(chat.members.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Group Chat: \(chat.isGroupChat ? "Yes" : "No")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Last Message: \(chat.lastMessage)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .padding()
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        ChatView(chat: Chat(
            id: "preview_chat",
            members: ["user1", "user2"],
            lastMessage: "Hey there!",
            lastMessageTimestamp: Date(),
            isGroupChat: false
        ))
    }
}

