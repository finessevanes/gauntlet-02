//
//  ChatView.swift
//  Psst
//
//  Updated by Caleb (Coder Agent) - PR #10: Optimistic UI and offline persistence
//  Full chat view with message list, input bar, auto-scroll, and offline support
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

/// Main chat view displaying messages in a conversation
/// Shows message list with sent/received styling, presence indicator, and message input bar, offline support, and optimistic UI
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
    
    /// Contact's online status (for 1-on-1 chats)
    @State private var isContactOnline: Bool = false
    
    /// Other user's ID (for presence tracking)
    @State private var otherUserID: String?
    
    /// Scroll proxy for programmatic scrolling
    @State private var scrollProxy: ScrollViewProxy?
    
    /// Cache for sender names (userID -> displayName) for group chats
    @State private var senderNames: [String: String] = [:]
    
    /// Count of queued messages for this chat
    @State private var queueCount: Int = 0
    
    /// Network monitor for connection state
    @ObservedObject var networkMonitor = NetworkMonitor.shared
    
    /// Message service for real-time messaging
    private let messageService = MessageService()
    
    /// Presence service for online/offline status
    @EnvironmentObject private var presenceService: PresenceService
    
    /// Typing indicator service for real-time typing status
    @StateObject private var typingIndicatorService = TypingIndicatorService()
    
    /// User IDs currently typing in this chat
    @State private var typingUserIDs: [String] = []
    
    /// Display names of users currently typing
    @State private var typingUserNames: [String] = []
    /// Chat service for fetching user names
    private let chatService = ChatService()
    
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
            
            // Typing indicator (appears below messages, above input)
            TypingIndicatorView(typingUserNames: typingUserNames)
            
            // Message input bar
            MessageInputView(
                text: $inputText,
                onSend: handleSend,
                chatID: chat.id,
                userID: currentUserID,
                typingIndicatorService: typingIndicatorService
            )
        }
        .navigationTitle(chat.isGroupChat ? (chat.groupName ?? "Group Chat") : "Chat")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Show presence indicator in header for 1-on-1 chats
            if !chat.isGroupChat {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        PresenceIndicator(isOnline: isContactOnline)
                        Text("Chat")
                            .font(.headline)
                    }
                }
            } else {
                // Show member count for group chats
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 0) {
                        Text(chat.groupName ?? "Group Chat")
                            .font(.headline)
                        Text("\(chat.members.count) members")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .onAppear {
            // Get current user ID from Firebase Auth
            if let uid = Auth.auth().currentUser?.uid {
                currentUserID = uid
            }
            // Determine other user ID for presence tracking
            determineOtherUserID()
            // Start listening for real-time messages
            startListeningForMessages()
            // Update queue count for this chat
            updateQueueCount()
            // Attach presence listener
            attachPresenceListener()
            // Attach typing listener
            attachTypingListener()
            // Prefetch sender names for group chats
            if chat.isGroupChat {
                Task {
                    await prefetchSenderNames()
                }
            }
        }
        .onDisappear {
            // Stop listening to prevent memory leaks
            stopListeningForMessages()
            // Detach presence listener
            detachPresenceListener()
            // Detach typing listener and clear own typing status
            detachTypingListener()
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
                                isFromCurrentUser: message.isFromCurrentUser(currentUserID: currentUserID),
                                senderName: getSenderName(for: message)
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
    
    /// Determine the other user's ID in this chat (for 1-on-1 presence tracking)
    private func determineOtherUserID() {
        guard !chat.isGroupChat else { return }
        
        // Get other user's ID from chat members
        otherUserID = chat.otherUserID(currentUserID: currentUserID)
    }
    
    /// Attach presence listener for the contact in this chat
    private func attachPresenceListener() {
        guard !chat.isGroupChat, let contactID = otherUserID else { return }
        
        // Attach presence listener
        _ = presenceService.observePresence(userID: contactID) { isOnline in
            DispatchQueue.main.async {
                self.isContactOnline = isOnline
            }
        }
    }
    
    /// Detach presence listener to prevent memory leaks
    private func detachPresenceListener() {
        guard let contactID = otherUserID else { return }
        presenceService.stopObserving(userID: contactID)
    }
    
    /// Attach typing listener for this chat
    private func attachTypingListener() {
        _ = typingIndicatorService.observeTypingUsers(chatID: chat.id) { userIDs in
            DispatchQueue.main.async {
                // Filter out current user (don't show own typing status)
                let filteredIDs = userIDs.filter { $0 != self.currentUserID }
                self.typingUserIDs = filteredIDs
                self.fetchDisplayNames(for: filteredIDs)
            }
        }
    }
    
    /// Detach typing listener and clear own typing status
    private func detachTypingListener() {
        // Stop observing typing users
        typingIndicatorService.stopObserving(chatID: chat.id)
        
        // Clear own typing status when leaving chat
        Task {
            try? await typingIndicatorService.stopTyping(chatID: chat.id, userID: currentUserID)
        }
    }
    
    /// Fetch display names for typing users
    private func fetchDisplayNames(for userIDs: [String]) {
        Task {
            var names: [String] = []
            for userID in userIDs {
                if let user = try? await UserService.shared.getUser(id: userID) {
                    names.append(user.displayName)
                }
            }
            await MainActor.run {
                self.typingUserNames = names
    /// Get sender name for a message (for group chats only)
    /// - Parameter message: The message to get sender name for
    /// - Returns: Sender name or nil if not needed (1-on-1 chat or current user)
    private func getSenderName(for message: Message) -> String? {
        // Only show sender names in group chats
        guard chat.isGroupChat else { return nil }
        
        // Don't show sender name for current user's messages
        guard !message.isFromCurrentUser(currentUserID: currentUserID) else { return nil }
        
        // Check cache first
        if let cachedName = senderNames[message.senderID] {
            return cachedName
        }
        
        // If not cached, fetch asynchronously
        Task {
            await fetchSenderName(for: message.senderID)
        }
        
        // Return placeholder while fetching
        return "..."
    }
    
    /// Fetch sender name for a specific user ID and cache it
    /// - Parameter senderID: The user ID to fetch name for
    private func fetchSenderName(for senderID: String) async {
        // Don't fetch if already cached
        guard senderNames[senderID] == nil else { return }
        
        do {
            let name = try await chatService.fetchUserName(userID: senderID)
            await MainActor.run {
                senderNames[senderID] = name
            }
        } catch {
            print("⚠️ Failed to fetch sender name for \(senderID): \(error.localizedDescription)")
            await MainActor.run {
                senderNames[senderID] = "Unknown User"
            }
        }
    }
    
    /// Prefetch sender names for all unique senders in the chat
    private func prefetchSenderNames() async {
        // Get unique sender IDs from messages
        let uniqueSenderIDs = Set(messages.map { $0.senderID })
        
        // Fetch names for senders not yet cached
        for senderID in uniqueSenderIDs {
            if senderNames[senderID] == nil {
                await fetchSenderName(for: senderID)
            }
        }
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
