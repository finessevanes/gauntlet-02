//
//  ChatView.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #7
//  Updated by Caleb (Coder Agent) - PR #8: Real-time messaging integration
//  Full chat view with message list, input bar, and auto-scroll
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

/// Main chat view displaying messages in a conversation
/// Shows message list with sent/received styling and message input bar
struct ChatView: View {
    // MARK: - Properties
    
    /// The chat being displayed
    let chat: Chat
    
    /// Messages to display (real-time from Firestore)
    @State private var messages: [Message] = []
    
    /// Input text field value
    @State private var inputText = ""
    
    /// Current user ID from Firebase Auth
    @State private var currentUserID: String = ""
    
    /// Scroll proxy for programmatic scrolling
    @State private var scrollProxy: ScrollViewProxy?
    
    /// Message service for real-time messaging
    private let messageService = MessageService()
    
    /// Firestore listener registration for cleanup (wrapped in State for mutability)
    @State private var messageListener: ListenerRegistration?
    
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
        }
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Get current user ID from Firebase Auth
            if let uid = Auth.auth().currentUser?.uid {
                currentUserID = uid
            }
            // Start listening for real-time messages
            startListeningForMessages()
        }
        .onDisappear {
            // Stop listening to prevent memory leaks
            stopListeningForMessages()
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
        
        // Send message via MessageService
        Task {
            do {
                _ = try await messageService.sendMessage(chatID: chat.id, text: trimmedText)
                
                // Clear input field on success
                await MainActor.run {
                    self.inputText = ""
                }
            } catch {
                print("❌ Error sending message: \(error.localizedDescription)")
                // TODO: Show error alert to user in PR #24
            }
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
    
    /// Start listening for real-time messages
    private func startListeningForMessages() {
        // Attach Firestore snapshot listener
        messageListener = messageService.observeMessages(chatID: chat.id) { updatedMessages in
            self.messages = updatedMessages
        }
    }
    
    /// Stop listening for messages to prevent memory leaks
    private func stopListeningForMessages() {
        // Remove Firestore listener
        messageListener?.remove()
        messageListener = nil
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
