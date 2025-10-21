//
//  ConversationListView.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #4
//  Updated by Caleb (Coder Agent) - PR #8: Added temporary test chat button
//  Placeholder for conversation list (to be implemented in Phase 2)
//

import SwiftUI

/// Placeholder view for the conversation list
/// Will display all user conversations in Phase 2
struct ConversationListView: View {
    // MARK: - Body

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()

                // Feature icon
                Image(systemName: "message.fill")
                    .font(.system(size: 72))
                    .foregroundColor(.blue)

                // Title
                Text("Conversations")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                // Coming soon message
                Text("Coming Soon in Phase 2")
                    .font(.title3)
                    .foregroundColor(.secondary)

                // Description
                Text("This screen will display all your conversations and allow you to start new chats.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                // TEMPORARY: Test button for PR #8 - Remove before merge
                VStack(spacing: 16) {
                    Text("🧪 Testing (PR #8)")
                        .font(.headline)
                        .foregroundColor(.orange)
                    
                    // Direct link to test chat
                    NavigationLink(destination: testChatView) {
                        HStack {
                            Image(systemName: "message.badge.filled.fill")
                            Text("Open Test Chat")
                        }
                        .font(.body)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    
                    Text("Vanes ↔️ Jameson")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 32)

                Spacer()
            }
            .navigationTitle("Conversations")
        }
    }
    
    // MARK: - Test Chat View (TEMPORARY for PR #8)
    
    /// Temporary test chat view for manual testing
    /// Creates a test chat between vanes and jameson
    private var testChatView: some View {
        let testChat = Chat(
            id: "test_chat_vanes_jameson",
            members: ["OUv2v5intnP7kHXv7rh550GQn6o1", "wOh11I865XTWQVTmd1RfWsB9sBD3"],
            lastMessage: "",
            lastMessageTimestamp: Date(),
            isGroupChat: false
        )
        
        return ChatView(chat: testChat)
    }
}

// MARK: - Preview

#Preview {
    ConversationListView()
}
