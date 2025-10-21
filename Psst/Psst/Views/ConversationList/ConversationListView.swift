//
//  ConversationListView.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #4
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

                Spacer()
            }
            .navigationTitle("Conversations")
        }
    }
}

// MARK: - Preview

#Preview {
    ConversationListView()
}
