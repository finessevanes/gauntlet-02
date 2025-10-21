//
//  ChatView.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #7
//  Updated by Caleb (Coder Agent) - PR #8: Real-time messaging integration
//  Updated by Caleb (Coder Agent) - PR #10: Optimistic UI and offline persistence
//  Full chat view with message list, input bar, auto-scroll, and offline support
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

/// Main chat view displaying messages in a conversation
/// Shows message list with sent/received styling, message input bar, offline support, and optimistic UI
struct ChatView: View {
    // MARK: - Properties
    
    /// The chat being displayed
    let chat: Chat
    
    /// All messages (includes both optimistic and confirmed from Firestore)
    @State private var messages: [Message] = []
    
    /// Input text field value
    @State private var inputText = ""
    
    /// Current user ID from Firebase Auth
    @State private var currentUserID: String = ""
    
    /// Scroll proxy for programmatic scrolling
    @State private var scrollProxy: ScrollViewProxy?
    
    /// Count of queued messages for this chat
    @State private var queueCount: Int = 0
    
    /// Network monitor for connection state
    @ObservedObject var networkMonitor = NetworkMonitor.shared
    
    /// Message service for real-time messaging
    private let messageService = MessageService()
    
    /// Firestore listener registration for cleanup (wrapped in State for mutability)
    @State private var messageListener: ListenerRegistration?
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Network status banner (offline/reconnecting/connected)
            NetworkStatusBanner(networkMonitor: networkMonitor, queueCount: $queueCount)
            
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
            // Update queue count for this chat
            updateQueueCount()
        }
        .onDisappear {
            // Stop listening to prevent memory leaks
            stopListeningForMessages()
        }
        .onChange(of: networkMonitor.isConnected) { oldValue, newValue in
            // Process queue when reconnected
            if !oldValue && newValue {
                Task {
                    // Get IDs of queued messages for this chat
                    let queuedMessageIDs = MessageQueue.shared.getQueuedMessages(for: chat.id).map { $0.id }
                    
                    // Update their status from .queued to .sending
                    await MainActor.run {
                        for id in queuedMessageIDs {
                            if let index = self.messages.firstIndex(where: { $0.id == id }) {
                                self.messages[index].sendStatus = .sending
                            }
                        }
                    }
                    
                    // Process the queue (sends messages to Firestore)
                    await MessageQueue.shared.processQueue()
                    
                    // Update queue count
                    await MainActor.run {
                        self.updateQueueCount()
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
                        VStack(alignment: message.isFromCurrentUser(currentUserID: currentUserID) ? .trailing : .leading, spacing: 4) {
                            MessageRow(
                                message: message,
                                isFromCurrentUser: message.isFromCurrentUser(currentUserID: currentUserID)
                            )
                            
                            // Show status indicator for sent messages only
                            if message.isFromCurrentUser(currentUserID: currentUserID) {
                                MessageStatusIndicator(
                                    status: message.sendStatus,
                                    onRetry: {
                                        retryMessage(message)
                                    }
                                )
                            }
                        }
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
    
    /// Handle send button tap with optimistic UI
    private func handleSend() {
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedText.isEmpty else { return }
        
        // Clear input field immediately
        inputText = ""
        
        // Send message via MessageService with optimistic completion
        Task {
            var messageID: String?
            
            do {
                messageID = try await messageService.sendMessage(
                    chatID: chat.id,
                    text: trimmedText,
                    optimisticCompletion: { optimisticMessage in
                        // Add message to UI immediately (before Firestore confirms)
                        DispatchQueue.main.async {
                            self.messages.append(optimisticMessage)
                        }
                    }
                )
                
                // Success! Message will be updated when Firestore listener confirms
                
            } catch MessageError.offline {
                // Message queued for offline send - update status to .queued
                await MainActor.run {
                    if let index = self.messages.firstIndex(where: { $0.sendStatus == .sending }) {
                        self.messages[index].sendStatus = .queued
                    }
                    // Update queue count
                    self.updateQueueCount()
                }
                
            } catch {
                // Send failed - update status to .failed
                print("❌ Error sending message: \(error.localizedDescription)")
                await MainActor.run {
                    if let index = self.messages.firstIndex(where: { $0.sendStatus == .sending }) {
                        self.messages[index].sendStatus = .failed
                    }
                }
            }
        }
    }
    
    /// Retry sending a failed message
    private func retryMessage(_ message: Message) {
        // Update failed message to sending status
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
            messages[index].sendStatus = .sending
        }
        
        // Retry send
        Task {
            do {
                _ = try await messageService.sendMessage(
                    chatID: chat.id,
                    text: message.text
                )
                
                // Success! Message status will be updated when Firestore confirms
                
            } catch {
                // Failed again - update to failed status
                print("❌ Retry failed: \(error.localizedDescription)")
                await MainActor.run {
                    if let index = self.messages.firstIndex(where: { $0.id == message.id }) {
                        self.messages[index].sendStatus = .failed
                    }
                }
            }
        }
    }
    
    /// Update queue count for this chat
    private func updateQueueCount() {
        queueCount = MessageQueue.shared.getQueueCount(for: chat.id)
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
        messageListener = messageService.observeMessages(chatID: chat.id) { firestoreMessages in
            // Merge Firestore messages with optimistic messages
            // Strategy: Update existing messages, add new ones
            var updatedMessages = self.messages
            
            for firestoreMessage in firestoreMessages {
                if let index = updatedMessages.firstIndex(where: { $0.id == firestoreMessage.id }) {
                    // Message exists (was optimistic) - update it and remove status
                    var updated = firestoreMessage
                    updated.sendStatus = nil  // Confirmed, no status indicator needed
                    updatedMessages[index] = updated
                } else {
                    // New message from Firestore - add it
                    updatedMessages.append(firestoreMessage)
                }
            }
            
            // Remove messages that no longer exist in Firestore
            // (Keep optimistic messages with status != nil for retry)
            updatedMessages = updatedMessages.filter { message in
                message.sendStatus != nil || firestoreMessages.contains(where: { $0.id == message.id })
            }
            
            // Sort by timestamp
            updatedMessages.sort { $0.timestamp < $1.timestamp }
            
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
