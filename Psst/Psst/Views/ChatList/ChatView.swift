//
//  ChatView.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #7
//  Full chat view with message list, input bar, and auto-scroll
//

import SwiftUI

/// Main chat view displaying messages in a conversation
/// Shows message list with sent/received styling and message input bar
struct ChatView: View {
    // MARK: - Properties
    
    /// The chat being displayed
    let chat: Chat
    
    /// Messages to display (mock data for now, real-time in PR #8)
    @State private var messages: [Message] = []
    
    /// Input text field value
    @State private var inputText = ""
    
    /// Focus state for keyboard handling
    @FocusState private var isInputFocused: Bool
    
    /// Current user ID (mock for now)
    @State private var currentUserID = "currentUser"
    
    /// Scroll proxy for programmatic scrolling
    @State private var scrollProxy: ScrollViewProxy?
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Message list
            if messages.isEmpty {
                // Empty state
                emptyStateView
            } else {
                // Messages
                messageListView
            }
            
            // Message input bar
            MessageInputView(text: $inputText, onSend: handleSend)
                .focused($isInputFocused)
        }
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadMockMessages()
        }
        .onChange(of: isInputFocused) { _, isFocused in
            // When keyboard appears, scroll to bottom to keep latest message visible
            if isFocused, let proxy = scrollProxy {
                // Delay to allow keyboard animation to complete (0.35s)
                // This prevents the keyboard from blocking the latest message
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    /// Empty state view when no messages exist
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text("No messages yet")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Send a message to start the conversation.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
    }
    
    /// Message list view with scroll and auto-scroll functionality
    private var messageListView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(messages) { message in
                        MessageRow(
                            message: message,
                            isFromCurrentUser: message.isFromCurrentUser(currentUserID: currentUserID)
                        )
                    }
                    
                    // Invisible anchor for auto-scroll
                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 8)
            }
            .onAppear {
                // Store proxy for keyboard handling and scroll to bottom on initial load
                scrollProxy = proxy
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: messages.count) { _, _ in
                // Scroll to bottom when new messages arrive
                scrollToBottom(proxy: proxy)
            }
        }
    }
    
    // MARK: - Actions
    
    /// Handle send button tap
    private func handleSend() {
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedText.isEmpty else { return }
        
        // Create new message (optimistic UI)
        let newMessage = Message(
            id: UUID().uuidString,
            text: trimmedText,
            senderID: currentUserID,
            timestamp: Date()
        )
        
        // Add to local array (actual Firebase sending in PR #8)
        messages.append(newMessage)
        
        // Clear input field but KEEP keyboard visible for quick replies
        DispatchQueue.main.async {
            self.inputText = ""
            // Note: isInputFocused stays true so user can keep typing
        }
    }
    
    /// Scroll to bottom of message list
    private func scrollToBottom(proxy: ScrollViewProxy) {
        // Small delay to ensure layout updates complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.2)) {
                proxy.scrollTo("bottom", anchor: .bottom)
            }
        }
    }
    
    /// Load mock messages for testing
    private func loadMockMessages() {
        messages = [
            Message(
                id: "1",
                text: "Hey! How are you doing?",
                senderID: currentUserID,
                timestamp: Date().addingTimeInterval(-3600)
            ),
            Message(
                id: "2",
                text: "I'm doing great, thanks for asking! How about you?",
                senderID: "otherUser",
                timestamp: Date().addingTimeInterval(-3500)
            ),
            Message(
                id: "3",
                text: "Pretty good! Working on this new messaging app.",
                senderID: currentUserID,
                timestamp: Date().addingTimeInterval(-3400)
            ),
            Message(
                id: "4",
                text: "That sounds exciting! Tell me more about it.",
                senderID: "otherUser",
                timestamp: Date().addingTimeInterval(-3300)
            ),
            Message(
                id: "5",
                text: "It's a secure messaging platform with real-time sync across devices. We're building it with SwiftUI and Firebase.",
                senderID: currentUserID,
                timestamp: Date().addingTimeInterval(-3200)
            ),
            Message(
                id: "6",
                text: "Wow, that's really cool! I'd love to try it out when it's ready.",
                senderID: "otherUser",
                timestamp: Date().addingTimeInterval(-3100)
            ),
            Message(
                id: "7",
                text: "Will do! I'll let you know as soon as we have a beta version available.",
                senderID: currentUserID,
                timestamp: Date().addingTimeInterval(-3000)
            )
        ]
    }
}

// MARK: - Preview

#Preview("With Messages") {
    NavigationView {
        ChatView(chat: Chat(
            id: "preview_chat",
            members: ["currentUser", "otherUser"],
            lastMessage: "Hey there!",
            lastMessageTimestamp: Date(),
            isGroupChat: false
        ))
    }
}

#Preview("Empty Chat") {
    NavigationView {
        ChatView(chat: Chat(
            id: "empty_chat",
            members: ["currentUser", "otherUser"],
            lastMessage: "",
            lastMessageTimestamp: Date(),
            isGroupChat: false
        ))
    }
    .onAppear {
        // Override to show empty state
    }
}
