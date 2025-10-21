//
//  MessageRow.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #7
//  Individual message bubble component with sent/received styling
//

import SwiftUI

/// Message row component that displays individual message bubbles
/// Supports both sent (right-aligned, blue) and received (left-aligned, gray) styling
struct MessageRow: View {
    // MARK: - Properties
    
    /// The message to display
    let message: Message
    
    /// Whether this message is from the current user
    let isFromCurrentUser: Bool
    
    // MARK: - Body
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            // Left spacer for sent messages (right-aligned)
            if isFromCurrentUser {
                Spacer(minLength: 60)
            }
            
            // Message bubble
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .foregroundColor(isFromCurrentUser ? .white : .primary)
                    .background(isFromCurrentUser ? Color.blue : Color(.systemGray5))
                    .cornerRadius(16)
                    .frame(maxWidth: 250, alignment: isFromCurrentUser ? .trailing : .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Right spacer for received messages (left-aligned)
            if !isFromCurrentUser {
                Spacer(minLength: 60)
            }
        }
    }
}

// MARK: - Preview

#Preview("Sent Message") {
    VStack(spacing: 12) {
        MessageRow(
            message: Message(
                id: "1",
                text: "Hey! How are you doing?",
                senderID: "currentUser",
                timestamp: Date()
            ),
            isFromCurrentUser: true
        )
        
        MessageRow(
            message: Message(
                id: "2",
                text: "This is a much longer message to test how the bubble expands to accommodate more text content. It should wrap nicely within the maximum width constraint.",
                senderID: "currentUser",
                timestamp: Date()
            ),
            isFromCurrentUser: true
        )
    }
    .padding()
}

#Preview("Received Message") {
    VStack(spacing: 12) {
        MessageRow(
            message: Message(
                id: "3",
                text: "I'm doing great, thanks for asking!",
                senderID: "otherUser",
                timestamp: Date()
            ),
            isFromCurrentUser: false
        )
        
        MessageRow(
            message: Message(
                id: "4",
                text: "Here's another longer message from the other person to see how received messages look with more content. The gray background should wrap nicely.",
                senderID: "otherUser",
                timestamp: Date()
            ),
            isFromCurrentUser: false
        )
    }
    .padding()
}

