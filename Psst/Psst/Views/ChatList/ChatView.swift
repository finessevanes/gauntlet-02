//
//  ChatView.swift
//  Psst
//
//  Updated by Caleb (Coder Agent) - PR #10: Optimistic UI and offline persistence
//  Updated by Caleb (Coder Agent) - PR #17: Added profile photos in header
//  Updated by Caleb (Coder Agent) - PR #2: Fix delivery status to show only on latest message
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
    
    /// Latest message IDs for each status type (PR #2 - Timeline View)
    /// Shows status on the latest message of each type for complete status visibility
    @State private var latestReadMessageID: String? = nil
    @State private var latestDeliveredMessageID: String? = nil
    @State private var latestFailedMessageID: String? = nil
    
    /// Input text field value
    @State private var inputText = ""
    
    /// Current user ID from Firebase Auth
    @State private var currentUserID: String = ""
    
    /// Contact's online status (for 1-on-1 chats)
    @State private var isContactOnline: Bool = false
    
    /// Other user's ID (for presence tracking)
    @State private var otherUserID: String?
    
    /// Other user's profile (for displaying photo in header)
    @State private var otherUser: User? = nil
    
    /// User profile listener for real-time updates
    @State private var userListener: ListenerRegistration? = nil
    
    /// Presence listener ID for cleanup (UUID-based tracking)
    @State private var presenceListenerID: UUID? = nil
    
    /// Scroll proxy for programmatic scrolling
    @State private var scrollProxy: ScrollViewProxy?
    
    /// Track if this is the initial load to prevent unwanted scrolling
    @State private var isInitialLoad: Bool = true
    
    /// Track keyboard state for proper scrolling
    @State private var isKeyboardVisible: Bool = false
    
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
    
    /// User service for fetching user profiles
    private let userService = UserService.shared
    
    /// Firestore listener registration for cleanup (wrapped in State for mutability)
    @State private var messageListener: ListenerRegistration?
    
    // MARK: - Group Presence (PR #004)
    
    /// Group member presence tracking (userID -> isOnline)
    @State private var memberPresences: [String: Bool] = [:]
    
    /// Group presence listeners for cleanup
    @State private var presenceListeners: [String: UUID] = [:]
    
    /// Show member list sheet
    @State private var showMemberList: Bool = false
    
    /// Loaded group member profiles (for header display)
    @State private var groupMembers: [User] = []
    
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
                onSendImage: { image in
                    handleSendImage(image)
                },
                chatID: chat.id,
                userID: currentUserID,
                typingIndicatorService: typingIndicatorService,
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
                                imageURL: otherUser?.photoURL,
                                selectedImage: nil,
                                isLoading: false,
                                size: 32
                            )
                            
                            // Green presence halo (only when online)
                            PresenceHalo(isOnline: isContactOnline, size: 32)
                                .animation(.easeInOut(duration: 0.2), value: isContactOnline)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(otherUser?.displayName ?? "Chat")
                                .font(.headline)
                            Text(isContactOnline ? "Online" : "Offline")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } else {
                // Show member photos for group chats (PR #004)
                ToolbarItem(placement: .principal) {
                    Button(action: {
                        showMemberList = true
                    }) {
                        VStack(spacing: 4) {
                            // Group name
                            Text(chat.groupName ?? "Group Chat")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            // Member photos row (first 3-5 members)
                            HStack(spacing: -8) {
                                ForEach(Array(groupMembers.prefix(5).enumerated()), id: \.element.id) { index, member in
                                    ProfilePhotoWithPresence(
                                        userID: member.id,
                                        photoURL: member.photoURL,
                                        displayName: member.displayName,
                                        size: 24
                                    )
                                    .zIndex(Double(5 - index)) // Stack from left to right
                                }
                                
                                // Show "+X more" if there are more members
                                if groupMembers.count > 5 {
                                    Text("+\(groupMembers.count - 5)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showMemberList) {
            // Group member list sheet (PR #004)
            GroupMemberStatusView(chat: chat)
                .environmentObject(presenceService)
        }
        .onAppear {
            print("📱 [CHAT VIEW] User entered chat: \(chat.id)")
            print("📱 [CHAT VIEW] Chat type: \(chat.isGroupChat ? "Group" : "1-on-1")")
            print("📱 [CHAT VIEW] Current message count: \(messages.count)")
            
            // Get current user ID from Firebase Auth
            if let uid = Auth.auth().currentUser?.uid {
                currentUserID = uid
                print("📱 [CHAT VIEW] Current user ID: \(uid)")
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
            // Load group members and observe presence (PR #004)
            if chat.isGroupChat {
                Task {
                    await loadGroupMembers()
                }
                attachGroupPresenceListeners()
            }
            // Mark messages as read when chat opens (PR #14)
            markMessagesAsRead()
            // Set up keyboard notifications
            setupKeyboardNotifications()
        }
        .onDisappear {
            print("📱 [CHAT VIEW] User left chat: \(chat.id)")
            print("📱 [CHAT VIEW] Final message count: \(messages.count)")
            
            // Stop listening to prevent memory leaks
            stopListeningForMessages()
            // Detach presence listener
            detachPresenceListener()
            // Detach typing listener and clear own typing status
            detachTypingListener()
            // Detach group presence listeners (PR #004)
            if chat.isGroupChat {
                detachGroupPresenceListeners()
            }
            // Remove keyboard notifications
            removeKeyboardNotifications()
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
                                senderName: getSenderName(for: message),
                                chat: chat,
                                currentUserID: currentUserID,
                                isLatestReadMessage: message.id == latestReadMessageID,      // PR #2: Timeline view
                                isLatestDeliveredMessage: message.id == latestDeliveredMessageID,
                                isLatestFailedMessage: message.id == latestFailedMessageID
                            )
                            
                            // Show status indicator for sent messages only (offline/queued/failed states)
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
                // Store proxy for keyboard handling
                scrollProxy = proxy
                // If messages are already loaded, scroll to bottom immediately
                if messages.count > 0 {
                    scrollToBottomImmediately(proxy: proxy)
                }
            }
            .onChange(of: messages.count) { _, _ in
                // Always scroll to bottom when messages are loaded
                if messages.count > 0 {
                    if isInitialLoad {
                        // First load - scroll immediately without delay
                        scrollToBottomImmediately(proxy: proxy)
                        isInitialLoad = false
                    } else {
                        // New messages - scroll with small delay
                        scrollToBottom(proxy: proxy)
                    }
                }
                
                // Mark new messages as read (for messages that arrive while chat is open)
                markMessagesAsRead()
            }
            .onChange(of: isKeyboardVisible) { _, newValue in
                // Ensure latest message and status are visible when keyboard state changes
                if newValue {
                    // Keyboard appeared - scroll to bottom to keep latest message visible
                    scrollToBottom(proxy: proxy)
                }
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
                            // PR #2: Update latest message IDs when new message is added
                            self.updateLatestMessageIDs()
                            // Scroll to bottom after adding message
                            if let proxy = self.scrollProxy {
                                self.scrollToBottom(proxy: proxy)
                            }
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
    
    /// Handle image send using MessageService (PR #009)
    /// Accepts raw UIImage for optimal single-pass compression
    private func handleSendImage(_ image: UIImage) {
        Task {
            do {
                _ = try await messageService.sendImageMessage(
                    chatID: chat.id,
                    image: image,
                    optimisticCompletion: { optimisticMessage in
                        DispatchQueue.main.async {
                            self.messages.append(optimisticMessage)
                            self.updateLatestMessageIDs()
                            // Scroll to bottom after adding message
                            if let proxy = self.scrollProxy {
                                self.scrollToBottom(proxy: proxy)
                            }
                        }
                    }
                )
            } catch MessageError.offline {
                await MainActor.run {
                    if let index = self.messages.firstIndex(where: { $0.sendStatus == .sending }) {
                        self.messages[index].sendStatus = .queued
                    }
                    self.updateQueueCount()
                }
            } catch {
                print("❌ Error sending image: \(error.localizedDescription)")
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
        // Check if this is an image message
        if message.mediaType == "image" {
            // Cannot retry image messages - original image data is lost
            // User should delete and resend the image
            print("⚠️ Cannot retry image message - please delete and resend the image")
            
            // Remove the failed message from the UI
            if let index = messages.firstIndex(where: { $0.id == message.id }) {
                messages.remove(at: index)
            }
            
            return
        }
        
        // Update failed message to sending status
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
            messages[index].sendStatus = .sending
        }
        
        // Retry send (text messages only)
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
    
    /// Scroll to bottom of message list (for new messages)
    private func scrollToBottom(proxy: ScrollViewProxy) {
        // Small delay to ensure layout updates complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Remove animation to prevent "weird scrolling thing"
            proxy.scrollTo("bottom", anchor: .bottom)
        }
    }
    
    /// Scroll to bottom immediately (for initial load)
    private func scrollToBottomImmediately(proxy: ScrollViewProxy) {
        // Small delay to ensure layout is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            proxy.scrollTo("bottom", anchor: .bottom)
        }
    }
    
    /// Start listening for real-time messages
    private func startListeningForMessages() {
        print("👂 [CHAT VIEW] Starting message listener for chat: \(chat.id)")
        
        // Attach Firestore snapshot listener
        messageListener = messageService.observeMessages(chatID: chat.id) { firestoreMessages in
            print("📨 [CHAT VIEW] Received \(firestoreMessages.count) messages from Firestore")
            
            // Log image messages specifically
            let imageMessages = firestoreMessages.filter { $0.mediaType == "image" }
            if !imageMessages.isEmpty {
                print("🖼️ [CHAT VIEW] Found \(imageMessages.count) image messages:")
                for message in imageMessages {
                    print("🖼️ [CHAT VIEW] Image message \(message.id):")
                    print("🔗 [CHAT VIEW]   Media URL: \(message.mediaURL ?? "nil")")
                    print("🔗 [CHAT VIEW]   Thumbnail URL: \(message.mediaThumbnailURL ?? "nil")")
                }
            }
            
            // Merge Firestore messages with optimistic messages
            // Strategy: Update existing messages, add new ones
            var updatedMessages = self.messages
            
            for firestoreMessage in firestoreMessages {
                if let index = updatedMessages.firstIndex(where: { $0.id == firestoreMessage.id }) {
                    // Message exists (was optimistic) - update it and remove status
                    var updated = firestoreMessage
                    updated.sendStatus = nil  // Confirmed, no status indicator needed
                    updatedMessages[index] = updated
                    print("🔄 [CHAT VIEW] Updated existing message: \(firestoreMessage.id)")
                } else {
                    // New message from Firestore - add it
                    updatedMessages.append(firestoreMessage)
                    print("➕ [CHAT VIEW] Added new message: \(firestoreMessage.id)")
                }
            }
            
            // Remove messages that no longer exist in Firestore
            // (Keep optimistic messages with status != nil for retry)
            updatedMessages = updatedMessages.filter { message in
                message.sendStatus != nil || firestoreMessages.contains(where: { $0.id == message.id })
            }
            
            // Sort by timestamp
            updatedMessages.sort { $0.timestamp < $1.timestamp }
            
            print("📨 [CHAT VIEW] Final message count: \(updatedMessages.count)")
            self.messages = updatedMessages
            
            // PR #2: Update latest message IDs for each status type
            self.updateLatestMessageIDs()
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
        
        // Attach user profile listener for real-time updates
        if let otherUserID = otherUserID {
            attachUserProfileListener(userID: otherUserID)
        }
    }
    
    /// Attach user profile listener for real-time profile updates
    private func attachUserProfileListener(userID: String) {
        userListener = userService.observeUser(id: userID) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let user):
                    self.otherUser = user
                case .failure(let error):
                    print("❌ Error observing user profile: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Attach presence listener for the contact in this chat
    private func attachPresenceListener() {
        guard !chat.isGroupChat, let contactID = otherUserID else { return }
        
        // Attach presence listener and store UUID for cleanup
        presenceListenerID = presenceService.observePresence(userID: contactID) { isOnline in
            DispatchQueue.main.async {
                self.isContactOnline = isOnline
            }
        }
    }
    
    /// Detach presence listener to prevent memory leaks
    private func detachPresenceListener() {
        guard let contactID = otherUserID, let listenerID = presenceListenerID else { return }
        
        presenceService.stopObserving(userID: contactID, listenerID: listenerID)
        presenceListenerID = nil
        
        // Remove user profile listener
        userListener?.remove()
        userListener = nil
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
            }
        }
    }
    
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
    
    // MARK: - Group Presence (PR #004)
    
    /// Load group member profiles for header display
    private func loadGroupMembers() async {
        guard chat.isGroupChat else { return }
        
        var members: [User] = []
        
        for memberID in chat.members {
            do {
                let user = try await userService.getUser(id: memberID)
                members.append(user)
            } catch {
                print("⚠️ Failed to load group member \(memberID): \(error.localizedDescription)")
            }
        }
        
        await MainActor.run {
            self.groupMembers = members
        }
    }
    
    /// Attach group presence listeners for all members
    private func attachGroupPresenceListeners() {
        guard chat.isGroupChat else { return }
        
        presenceListeners = presenceService.observeGroupPresence(userIDs: chat.members) { userID, isOnline in
            DispatchQueue.main.async {
                self.memberPresences[userID] = isOnline
            }
        }
    }
    
    /// Detach all group presence listeners
    private func detachGroupPresenceListeners() {
        guard !presenceListeners.isEmpty else { return }
        
        presenceService.stopObservingGroup(listeners: presenceListeners)
        presenceListeners.removeAll()
        memberPresences.removeAll()
    }
    
    // MARK: - Read Receipts (PR #14)
    
    /// Updates the latest message IDs for each status type (PR #2 - Timeline View)
    /// Tracks the latest message for Read, Delivered, and Failed statuses independently
    /// This provides a complete status timeline showing when last message was read, delivered, or failed
    private func updateLatestMessageIDs() {
        // Filter to current user's messages only
        let currentUserMessages = messages.filter { $0.isFromCurrentUser(currentUserID: currentUserID) }
        
        // Find latest READ message (has read receipts from other users)
        latestReadMessageID = currentUserMessages.last { message in
            !message.readBy.isEmpty
        }?.id
        
        // Find latest DELIVERED message (no read receipts yet, successfully delivered)
        latestDeliveredMessageID = currentUserMessages.last { message in
            message.readBy.isEmpty && (message.sendStatus == nil || message.sendStatus == .delivered)
        }?.id
        
        // Find latest FAILED message (send failed, needs retry)
        latestFailedMessageID = currentUserMessages.last { message in
            message.sendStatus == .failed
        }?.id
        
        // Debug logging
        print("📊 [PR #2 Status Timeline]")
        print("   Latest Read: \(latestReadMessageID ?? "none")")
        print("   Latest Delivered: \(latestDeliveredMessageID ?? "none")")
        print("   Latest Failed: \(latestFailedMessageID ?? "none")")
    }
    
    /// Marks all unread messages in this chat as read by the current user
    /// Called automatically when chat view appears
    /// Runs asynchronously to avoid blocking UI
    private func markMessagesAsRead() {
        Task {
            do {
                // Validate current user ID
                guard !currentUserID.isEmpty else {
                    print("⚠️ Cannot mark messages as read: no current user ID")
                    return
                }
                
                try await messageService.markChatMessagesAsRead(chatID: chat.id)
            } catch {
                // Fail silently - read receipts are non-critical
                print("❌ Failed to mark messages as read: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Keyboard Handling
    
    /// Set up keyboard notifications to handle scrolling when keyboard appears/disappears
    private func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { _ in
            isKeyboardVisible = true
            // Scroll to bottom when keyboard appears to keep latest message visible
            if let proxy = scrollProxy {
                scrollToBottom(proxy: proxy)
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            isKeyboardVisible = false
            // Scroll to bottom when keyboard disappears to ensure latest message is visible
            if let proxy = scrollProxy {
                scrollToBottom(proxy: proxy)
            }
        }
    }
    
    /// Remove keyboard notifications to prevent memory leaks
    private func removeKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
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
