//
//  MessageRow.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #7
//  Updated by Caleb (Coder Agent) - PR #2: Fix delivery status to show timeline view per status type
//  Individual message bubble component with sent/received styling
//

import SwiftUI

/// Message row component that displays individual message bubbles
/// Supports both sent (right-aligned, blue) and received (left-aligned, gray) styling
/// Shows sender names for group chat messages and read receipts for sent messages (PR #14)
/// Supports swipe gestures to reveal timestamps (PR #21)
/// Shows delivery status timeline: latest Read, latest Delivered, latest Failed (PR #2)
struct MessageRow: View {
    // MARK: - Properties
    
    /// The message to display
    let message: Message
    
    /// Whether this message is from the current user
    let isFromCurrentUser: Bool
    
    /// Sender name to display (for group chats, nil for 1-on-1 or current user)
    var senderName: String? = nil
    
    /// The chat containing this message (for read receipts)
    var chat: Chat? = nil
    
    /// Current user ID (for read receipts)
    var currentUserID: String? = nil
    
    /// Whether this is the latest READ message from current user (PR #2 - Timeline View)
    var isLatestReadMessage: Bool = false
    
    /// Whether this is the latest DELIVERED message from current user (PR #2 - Timeline View)
    var isLatestDeliveredMessage: Bool = false
    
    /// Whether this is the latest FAILED message from current user (PR #2 - Timeline View)
    var isLatestFailedMessage: Bool = false
    
    // MARK: - State for Swipe Gestures (PR #21)
    
    /// Whether the timestamp is currently revealed via swipe
    @State private var isTimestampRevealed: Bool = false
    
    /// Current drag offset for swipe gesture
    @State private var dragOffset: CGFloat = 0
    
    // MARK: - Computed Properties
    
    /// Timestamp view for swipe reveal (PR #21)
    private var timestampView: some View {
        Text(message.timestamp.formattedTimestamp())
            .font(.caption2)
            .foregroundColor(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.systemGray6))
            .cornerRadius(8)
    }
    
    /// Uploading image placeholder (PR #009)
    private var uploadingImagePlaceholder: some View {
        ZStack {
            Rectangle()
                .fill(isFromCurrentUser ? Color.blue.opacity(0.3) : Color(.systemGray5))
                .frame(width: 200, height: 150)
                .cornerRadius(12)
            
            VStack(spacing: 8) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: isFromCurrentUser ? .white : .gray))
                Text("Uploading...")
                    .font(.caption)
                    .foregroundColor(isFromCurrentUser ? .white : .secondary)
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            // Left spacer for sent messages (right-aligned)
            if isFromCurrentUser {
                Spacer(minLength: 60)
            }
            
            // Message bubble with optional sender name and read indicator
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                // Sender name label (only for group messages from others)
                if let senderName = senderName, !isFromCurrentUser {
                    Text(senderName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)
                }
                
                // Message bubble with swipe gesture support (PR #21)
                HStack(spacing: 8) {
                    // Timestamp reveal area (left side for received messages)
                    if !isFromCurrentUser && (isTimestampRevealed || dragOffset > 0) {
                        timestampView
                            .transition(.asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    }
                    
                    // Message content (text or image)
                    Group {
                        if message.mediaType == "image" {
                            // Image message (may be uploading if mediaURL is nil)
                            if let url = message.mediaURL {
                                // Image uploaded successfully - show image
                                ImageMessageView(
                                    imageURL: url,
                                    thumbnailURL: message.mediaThumbnailURL,
                                    width: message.mediaDimensions?["width"],
                                    height: message.mediaDimensions?["height"]
                                )
                                .onAppear {
                                    print("🖼️ [MESSAGE ROW] Rendering image message: \(message.id)")
                                    print("🔗 [MESSAGE ROW] Media URL: \(message.mediaURL ?? "nil")")
                                    print("🔗 [MESSAGE ROW] Thumbnail URL: \(message.mediaThumbnailURL ?? "nil")")
                                    print("✅ [MESSAGE ROW] Image uploaded successfully - showing ImageMessageView")
                                }
                            } else {
                                // Image is still uploading - show loading placeholder
                                uploadingImagePlaceholder
                                    .onAppear {
                                        print("🖼️ [MESSAGE ROW] Rendering image message: \(message.id)")
                                        print("🔗 [MESSAGE ROW] Media URL: \(message.mediaURL ?? "nil")")
                                        print("🔗 [MESSAGE ROW] Thumbnail URL: \(message.mediaThumbnailURL ?? "nil")")
                                        print("⏳ [MESSAGE ROW] Image still uploading - showing placeholder")
                                    }
                            }
                        } else {
                            Text(message.text)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .foregroundColor(isFromCurrentUser ? .white : .primary)
                                .background(isFromCurrentUser ? Color.blue : Color(.systemGray5))
                                .cornerRadius(16)
                                .frame(maxWidth: 250, alignment: isFromCurrentUser ? .trailing : .leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .offset(x: dragOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                // Only allow swipe in appropriate direction
                                let allowedDirection: CGFloat = isFromCurrentUser ? -1 : 1
                                if value.translation.width * allowedDirection > 0 {
                                    dragOffset = value.translation.width * 0.3 // Dampen the drag
                                }
                            }
                            .onEnded { value in
                                let threshold: CGFloat = 50
                                let allowedDirection: CGFloat = isFromCurrentUser ? -1 : 1
                                
                                // Check if swipe was sufficient to reveal timestamp
                                if value.translation.width * allowedDirection > threshold {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        isTimestampRevealed = true
                                        dragOffset = 0
                                    }
                                    
                                    // Auto-hide after 3 seconds
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            isTimestampRevealed = false
                                        }
                                    }
                                } else {
                                    // Snap back to original position
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        dragOffset = 0
                                    }
                                }
                            }
                    )
                    
                    // Timestamp reveal area (right side for sent messages)
                    if isFromCurrentUser && (isTimestampRevealed || dragOffset < 0) {
                        timestampView
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            ))
                    }
                }
                
                // Read receipt indicator (only for sent messages) - PR #14
                // PR #2: Show status if this is the latest message of ANY status type (Timeline View)
                // This allows users to see: latest Read, latest Delivered, and latest Failed simultaneously
                let shouldShowStatus = isLatestReadMessage || isLatestDeliveredMessage || isLatestFailedMessage
                
                if isFromCurrentUser, shouldShowStatus, let chat = chat, let currentUserID = currentUserID {
                    MessageReadIndicatorView(
                        message: message,
                        chat: chat,
                        currentUserID: currentUserID
                    )
                }
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
            isFromCurrentUser: true,
            isLatestReadMessage: false  // PR #2: Not latest - no delivery status
        )
        
        MessageRow(
            message: Message(
                id: "2",
                text: "This is a much longer message to test how the bubble expands to accommodate more text content. It should wrap nicely within the maximum width constraint.",
                senderID: "currentUser",
                timestamp: Date()
            ),
            isFromCurrentUser: true,
            chat: Chat(id: "preview_chat", members: ["currentUser", "otherUser"], lastMessage: "", isGroupChat: false),
            currentUserID: "currentUser",
            isLatestDeliveredMessage: true  // PR #2: Latest delivered - shows delivery status
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

#Preview("Multiple Sent Messages - PR #2 Timeline View") {
    // This preview demonstrates PR #2 fix: shows latest message for EACH status type
    // Timeline view: latest Read, latest Delivered, latest Failed all visible
    let chat = Chat(
        id: "preview_chat",
        members: ["currentUser", "otherUser"],
        lastMessage: "Last message",
        isGroupChat: false
    )
    
    VStack(spacing: 12) {
        Text("PR #2 Timeline View: Show Latest of Each Status")
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.bottom, 8)
        
        // Message 1-2: Read (only #2 shows "Read")
        MessageRow(
            message: Message(
                id: "1",
                text: "First message",
                senderID: "currentUser",
                timestamp: Date().addingTimeInterval(-120),
                readBy: ["otherUser"]
            ),
            isFromCurrentUser: true,
            chat: chat,
            currentUserID: "currentUser",
            isLatestReadMessage: false  // Not latest read
        )
        
        MessageRow(
            message: Message(
                id: "2",
                text: "Second message - READ",
                senderID: "currentUser",
                timestamp: Date().addingTimeInterval(-90),
                readBy: ["otherUser"]
            ),
            isFromCurrentUser: true,
            chat: chat,
            currentUserID: "currentUser",
            isLatestReadMessage: true  // Latest read ✓ shows "Read"
        )
        
        // Message 3-4: Delivered (only #4 shows "Delivered")
        MessageRow(
            message: Message(
                id: "3",
                text: "Third message",
                senderID: "currentUser",
                timestamp: Date().addingTimeInterval(-60),
                readBy: []
            ),
            isFromCurrentUser: true,
            chat: chat,
            currentUserID: "currentUser",
            isLatestDeliveredMessage: false  // Not latest delivered
        )
        
        MessageRow(
            message: Message(
                id: "4",
                text: "Fourth message - DELIVERED",
                senderID: "currentUser",
                timestamp: Date().addingTimeInterval(-30),
                readBy: []
            ),
            isFromCurrentUser: true,
            chat: chat,
            currentUserID: "currentUser",
            isLatestDeliveredMessage: true  // Latest delivered ✓ shows "Delivered"
        )
        
        // Message 5: Failed (shows "Failed")
        MessageRow(
            message: Message(
                id: "5",
                text: "Fifth message - FAILED",
                senderID: "currentUser",
                timestamp: Date(),
                readBy: [],
                sendStatus: .failed
            ),
            isFromCurrentUser: true,
            chat: chat,
            currentUserID: "currentUser",
            isLatestFailedMessage: true  // Latest failed ✓ shows "Failed"
        )
        
        Text("Result: 3 statuses visible simultaneously!")
            .font(.caption)
            .foregroundColor(.green)
            .padding(.top, 8)
    }
    .padding()
}

