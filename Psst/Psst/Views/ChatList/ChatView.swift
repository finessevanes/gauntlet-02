//
//  ChatView.swift
//  Psst
//
//  Updated by Caleb (Coder Agent) - PR #10: Optimistic UI and offline persistence
//  Updated by Caleb (Coder Agent) - PR #17: Added profile photos in header
//  Updated by Caleb (Coder Agent) - PR #2: Fix delivery status to show only on latest message
//  Refactored by Caleb (Coder Agent) - Split into focused view models
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
    
    /// Current user ID from Firebase Auth
    @State private var currentUserID: String = ""
    
    /// Network monitor for connection state
    @ObservedObject var networkMonitor = NetworkMonitor.shared
    
    /// Presence service for online/offline status
    @EnvironmentObject private var presenceService: PresenceService
    
    // MARK: - View Models
    
    /// Message management view model
    @StateObject private var messageViewModel: MessageManagementViewModel
    
    /// Presence tracking view model
    @StateObject private var presenceViewModel: PresenceTrackingViewModel
    
    /// Chat interaction view model
    @StateObject private var interactionViewModel: ChatInteractionViewModel
    
    // MARK: - Initialization
    
    init(chat: Chat) {
        self.chat = chat
        self._messageViewModel = StateObject(wrappedValue: MessageManagementViewModel(chat: chat))
        self._presenceViewModel = StateObject(wrappedValue: PresenceTrackingViewModel(chat: chat))
        self._interactionViewModel = StateObject(wrappedValue: ChatInteractionViewModel())
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Network status banner (offline/reconnecting/connected)
            NetworkStatusBanner(networkMonitor: networkMonitor, queueCount: $messageViewModel.queueCount)
            
            // Message list
            if messageViewModel.messages.isEmpty {
                // Empty state
                emptyStateView
            } else {
                // Messages
                messageListView
            }
            
            // Typing indicator (appears below messages, above input)
            TypingIndicatorView(typingUserNames: presenceViewModel.typingUserNames)
            
            // Message input bar
            MessageInputView(
                text: $interactionViewModel.inputText,
                onSend: handleSend,
                onSendImage: { image in
                    handleSendImage(image)
                },
                chatID: chat.id,
                userID: currentUserID,
                typingIndicatorService: presenceViewModel.getTypingIndicatorService(),
                onError: { error in
                    print("[ChatView] Typing indicator error: \(error.localizedDescription)")
                }
            )
        }
        .navigationTitle(chat.isGroupChat ? (chat.groupName ?? "Group Chat") : "Chat")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Show presence halo and profile photo in header for 1-on-1 chats
            if !chat.isGroupChat {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        // Profile photo with presence halo
                        ZStack {
                            ProfilePhotoPreview(
                                imageURL: presenceViewModel.otherUser?.photoURL,
                                userID: presenceViewModel.otherUser?.id,
                                selectedImage: nil,
                                isLoading: false,
                                size: 32
                            )
                            
                            // Green presence halo (only when online)
                            PresenceHalo(isOnline: presenceViewModel.isContactOnline, size: 32)
                                .animation(.easeInOut(duration: 0.2), value: presenceViewModel.isContactOnline)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(presenceViewModel.otherUser?.displayName ?? "Chat")
                                .font(.headline)
                            Text(presenceViewModel.isContactOnline ? "Online" : "Offline")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } else {
                // Show member photos for group chats (PR #004)
                ToolbarItem(placement: .principal) {
                    Button(action: {
                        presenceViewModel.showMemberListSheet()
                    }) {
                        VStack(spacing: 4) {
                            // Group name
                            Text(chat.groupName ?? "Group Chat")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            // Member photos row (first 3-5 members)
                            HStack(spacing: -8) {
                                ForEach(Array(presenceViewModel.groupMembers.prefix(5).enumerated()), id: \.element.id) { index, member in
                                    ProfilePhotoWithPresence(
                                        userID: member.id,
                                        photoURL: member.photoURL,
                                        displayName: member.displayName,
                                        size: 24
                                    )
                                    .zIndex(Double(5 - index)) // Stack from left to right
                                }
                                
                                // Show "+X more" if there are more members
                                if presenceViewModel.groupMembers.count > 5 {
                                    Text("+\(presenceViewModel.groupMembers.count - 5)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $presenceViewModel.showMemberList) {
            // Group member list sheet (PR #004)
            GroupMemberStatusView(chat: chat)
                .environmentObject(presenceService)
        }
        .onAppear {
            // Get current user ID from Firebase Auth
            if let uid = Auth.auth().currentUser?.uid {
                currentUserID = uid
                
                // Initialize all view models
                messageViewModel.initialize(currentUserID: uid)
                presenceViewModel.initialize(currentUserID: uid, presenceService: presenceService)
                interactionViewModel.setupKeyboardNotifications()
            }
        }
        .onDisappear {
            // Clean up all view models
            messageViewModel.cleanup()
            presenceViewModel.cleanup()
            interactionViewModel.cleanup()
        }
        .onChange(of: networkMonitor.isConnected) { oldValue, newValue in
            // Process queue when reconnected
            if !oldValue && newValue {
                Task {
                    await messageViewModel.processQueuedMessages()
                }
            }
        }
        // Observe presence for 1-on-1 chats (using PresenceObserverModifier)
        .background(
            Group {
                if !chat.isGroupChat, let contactID = presenceViewModel.otherUserID {
                    Color.clear
                        .observePresence(userID: contactID, isOnline: $presenceViewModel.isContactOnline)
                }
            }
        )
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
                    ForEach(messageViewModel.messages) { message in
                        VStack(alignment: message.isFromCurrentUser(currentUserID: currentUserID) ? .trailing : .leading, spacing: 4) {
                            MessageRow(
                                message: message,
                                isFromCurrentUser: message.isFromCurrentUser(currentUserID: currentUserID),
                                senderName: messageViewModel.getSenderName(for: message),
                                chat: chat,
                                currentUserID: currentUserID,
                                isLatestReadMessage: message.id == messageViewModel.latestReadMessageID,      // PR #2: Timeline view
                                isLatestDeliveredMessage: message.id == messageViewModel.latestDeliveredMessageID,
                                isLatestFailedMessage: message.id == messageViewModel.latestFailedMessageID
                            )
                            
                            // Show status indicator for sent messages only (offline/queued/failed states)
                            if message.isFromCurrentUser(currentUserID: currentUserID) {
                                MessageStatusIndicator(
                                    status: message.sendStatus,
                                    onRetry: {
                                        messageViewModel.retryMessage(message)
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
                // Store proxy for keyboard handling
                interactionViewModel.setScrollProxy(proxy)
                // If messages are already loaded, scroll to bottom immediately
                if messageViewModel.messages.count > 0 {
                    interactionViewModel.scrollToBottomImmediately()
                }
            }
            .onChange(of: messageViewModel.messages.count) { _, _ in
                // Always scroll to bottom when messages are loaded
                if messageViewModel.messages.count > 0 {
                    interactionViewModel.handleInitialLoad()
                }
            }
            .onChange(of: interactionViewModel.isKeyboardVisible) { _, newValue in
                // Ensure latest message and status are visible when keyboard state changes
                if newValue {
                    // Keyboard appeared - scroll to bottom to keep latest message visible
                    interactionViewModel.scrollToBottom()
                }
            }
        }
    }
    
    // MARK: - Actions
    
    /// Handle send button tap with optimistic UI
    private func handleSend() {
        let text = interactionViewModel.handleSend()
        guard !text.isEmpty else { return }
        
        // Send message via view model
        Task {
            await messageViewModel.sendMessage(text: text)
                            // Scroll to bottom after adding message
            interactionViewModel.scrollToBottom()
        }
    }
    
    /// Handle image send using MessageService (PR #009)
    /// Accepts raw UIImage for optimal single-pass compression
    private func handleSendImage(_ image: UIImage) {
        Task {
            await messageViewModel.sendImageMessage(image)
                            // Scroll to bottom after adding message
            interactionViewModel.scrollToBottom()
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
