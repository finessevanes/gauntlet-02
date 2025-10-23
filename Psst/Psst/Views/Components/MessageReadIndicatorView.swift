//
//  MessageReadIndicatorView.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #14
//  Displays read receipt status below message bubbles
//

import SwiftUI

/// Read receipt indicator showing message delivery and read status
/// Displays "Sending...", "Delivered", "Read", "Read by X/Y", or "Read by all"
/// with appropriate colors (gray for unread, blue for read)
/// In group chats (3+ members), tapping opens detailed read receipt view
struct MessageReadIndicatorView: View {
    // MARK: - Properties
    
    /// The message to show read status for
    let message: Message
    
    /// The chat containing this message
    let chat: Chat
    
    /// Current user ID for read status calculation
    let currentUserID: String
    
    /// State for showing read receipt detail modal (group chats only)
    @State private var isShowingReadReceipts = false
    
    /// State for tap animation
    @State private var isTapped = false
    
    // MARK: - Body
    
    var body: some View {
        Text(statusText)
            .font(.caption)
            .foregroundColor(statusColor)
            .italic(message.sendStatus == .sending || message.sendStatus == .queued)
            .animation(.easeInOut(duration: 0.2), value: statusText)
            .scaleEffect(isTapped ? 0.95 : 1.0)
            .animation(.spring(response: 0.2), value: isTapped)
            .onTapGesture {
                // Only open detail view for group chats (3+ members)
                if chat.isGroupChat {
                    // Tap animation feedback
                    isTapped = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isTapped = false
                    }
                    
                    // Open detail modal
                    isShowingReadReceipts = true
                }
            }
            .sheet(isPresented: $isShowingReadReceipts) {
                ReadReceiptDetailView(message: message, chat: chat)
            }
    }
    
    // MARK: - Computed Properties
    
    /// The status text to display based on message state
    private var statusText: String {
        // Handle sending status first
        if let sendStatus = message.sendStatus {
            switch sendStatus {
            case .sending:
                return "Sending..."
            case .queued:
                return "Queued"
            case .delivered:
                return statusTextForDelivered()
            case .failed:
                return "Failed"
            }
        }
        
        // Default to delivered/read logic
        return statusTextForDelivered()
    }
    
    /// Status text for delivered messages (handles read receipts)
    /// Differentiates between 1-on-1 and group chat logic
    private func statusTextForDelivered() -> String {
        // If no one has read it yet
        if message.readBy.isEmpty {
            return "Delivered"
        }
        
        // 1-on-1 chat logic (2 members)
        if chat.members.count == 2 {
            // Get the other user ID (not current user)
            let otherUserID = chat.members.first { $0 != currentUserID } ?? ""
            
            if message.readBy.contains(otherUserID) {
                return "Read"
            } else {
                return "Delivered"
            }
        }
        
        // Group chat logic (3+ members)
        // Recipients = all members except sender
        let recipients = chat.members.filter { $0 != message.senderID }
        let readCount = recipients.filter { message.readBy.contains($0) }.count
        let totalRecipients = recipients.count
        
        if readCount == 0 {
            return "Delivered"
        } else if readCount == totalRecipients {
            return "Read by all"
        } else {
            return "Read by \(readCount)/\(totalRecipients)"
        }
    }
    
    /// The color to display based on read status
    /// Blue for fully read, gray otherwise
    private var statusColor: Color {
        // Sending/queued states: gray
        if message.sendStatus == .sending || message.sendStatus == .queued {
            return .secondary
        }
        
        // Failed state: red
        if message.sendStatus == .failed {
            return .red
        }
        
        // Blue for fully read states
        if statusText == "Read" || statusText == "Read by all" {
            return .accentColor
        }
        
        // Gray for delivered or partial read states
        return .secondary
    }
}

// MARK: - Preview

#Preview("1-on-1 States") {
    let chat = Chat(
        id: "chat1",
        members: ["currentUser", "otherUser"],
        lastMessage: "",
        isGroupChat: false
    )
    
    VStack(alignment: .trailing, spacing: 16) {
        // Sending
        VStack(alignment: .trailing, spacing: 4) {
            Text("Hello!")
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(16)
            MessageReadIndicatorView(
                message: Message(
                    id: "1",
                    text: "Hello!",
                    senderID: "currentUser",
                    sendStatus: .sending
                ),
                chat: chat,
                currentUserID: "currentUser"
            )
        }
        
        // Delivered
        VStack(alignment: .trailing, spacing: 4) {
            Text("How are you?")
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(16)
            MessageReadIndicatorView(
                message: Message(
                    id: "2",
                    text: "How are you?",
                    senderID: "currentUser",
                    readBy: []
                ),
                chat: chat,
                currentUserID: "currentUser"
            )
        }
        
        // Read
        VStack(alignment: .trailing, spacing: 4) {
            Text("Great to hear!")
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(16)
            MessageReadIndicatorView(
                message: Message(
                    id: "3",
                    text: "Great to hear!",
                    senderID: "currentUser",
                    readBy: ["otherUser"]
                ),
                chat: chat,
                currentUserID: "currentUser"
            )
        }
    }
    .padding()
}

#Preview("Group Chat States") {
    let groupChat = Chat(
        id: "groupChat1",
        members: ["currentUser", "user2", "user3", "user4", "user5"],
        lastMessage: "",
        isGroupChat: true,
        groupName: "Team Chat"
    )
    
    VStack(alignment: .trailing, spacing: 16) {
        // Delivered (no reads)
        VStack(alignment: .trailing, spacing: 4) {
            Text("Hey team!")
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(16)
            MessageReadIndicatorView(
                message: Message(
                    id: "1",
                    text: "Hey team!",
                    senderID: "currentUser",
                    readBy: []
                ),
                chat: groupChat,
                currentUserID: "currentUser"
            )
        }
        
        // Read by 1/4
        VStack(alignment: .trailing, spacing: 4) {
            Text("Meeting at 3pm")
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(16)
            MessageReadIndicatorView(
                message: Message(
                    id: "2",
                    text: "Meeting at 3pm",
                    senderID: "currentUser",
                    readBy: ["user2"]
                ),
                chat: groupChat,
                currentUserID: "currentUser"
            )
        }
        
        // Read by 2/4
        VStack(alignment: .trailing, spacing: 4) {
            Text("See you there!")
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(16)
            MessageReadIndicatorView(
                message: Message(
                    id: "3",
                    text: "See you there!",
                    senderID: "currentUser",
                    readBy: ["user2", "user3"]
                ),
                chat: groupChat,
                currentUserID: "currentUser"
            )
        }
        
        // Read by all
        VStack(alignment: .trailing, spacing: 4) {
            Text("Thanks everyone!")
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(16)
            MessageReadIndicatorView(
                message: Message(
                    id: "4",
                    text: "Thanks everyone!",
                    senderID: "currentUser",
                    readBy: ["user2", "user3", "user4", "user5"]
                ),
                chat: groupChat,
                currentUserID: "currentUser"
            )
        }
    }
    .padding()
}

