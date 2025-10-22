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
/// Shows sender names for group chat messages and read receipts for sent messages (PR #14)
/// Supports swipe gestures to reveal timestamps (PR #21)
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
                    
                    // Message bubble
                    Text(message.text)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .foregroundColor(isFromCurrentUser ? .white : .primary)
                        .background(isFromCurrentUser ? Color.blue : Color(.systemGray5))
                        .cornerRadius(16)
                        .frame(maxWidth: 250, alignment: isFromCurrentUser ? .trailing : .leading)
                        .fixedSize(horizontal: false, vertical: true)
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
                if isFromCurrentUser, let chat = chat, let currentUserID = currentUserID {
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

