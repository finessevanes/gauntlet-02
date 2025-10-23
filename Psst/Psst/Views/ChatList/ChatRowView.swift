//
//  ChatRowView.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #6
//  Updated by Caleb (Coder Agent) - PR #12: Added presence indicators
//  Updated by Caleb (Coder Agent) - PR #17: Added profile photos
//  Individual chat preview row component
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

/// Individual chat row displaying preview information
/// Shows avatar, name, last message, timestamp, and presence indicator
struct ChatRowView: View {
    // MARK: - Properties
    
    let chat: Chat
    
    @State private var displayName: String = ""
    @State private var isLoadingName = true
    @State private var isContactOnline: Bool = false
    @State private var otherUserID: String?
    @State private var lastMessageSenderName: String? = nil
    @State private var otherUser: User? = nil
    @State private var userListener: ListenerRegistration? = nil
    @State private var unreadCount: Int = 0
    @State private var messageListener: ListenerRegistration? = nil
    
    /// Presence listener ID for cleanup (UUID-based tracking)
    @State private var presenceListenerID: UUID? = nil
    
    @EnvironmentObject private var presenceService: PresenceService
    
    private let chatService = ChatService()
    private let userService = UserService.shared
    
    // MARK: - Body
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar with profile photo for 1-on-1 or group indicator
            if chat.isGroupChat {
                // Group icon (no presence halo for groups)
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "person.3.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            } else {
                // Profile photo with presence halo for 1-on-1 chats
                ZStack {
                    ProfilePhotoPreview(
                        imageURL: otherUser?.photoURL,
                        selectedImage: nil,
                        isLoading: false,
                        size: 50
                    )
                    
                    // Green presence halo (only when online)
                    PresenceHalo(isOnline: isContactOnline, size: 50)
                        .animation(.easeInOut(duration: 0.2), value: isContactOnline)
                }
            }
            
            // Chat info
            VStack(alignment: .leading, spacing: 4) {
                // Name with unread dot indicator
                HStack {
                    // Blue dot for unread messages (all chat types)
                    UnreadDotIndicator(hasUnread: unreadCount > 0)
                        .animation(.easeInOut(duration: 0.3), value: unreadCount > 0)
                    
                    if isLoadingName {
                        Text("Loading...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    } else {
                        Text(displayName)
                            .font(.headline)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Timestamp
                    Text(chat.lastMessageTimestamp.relativeTimeString())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Member count (for group chats)
                if chat.isGroupChat {
                    Text("\(chat.members.count) members")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Last message (with sender name for groups)
                // Only show if there's actually a message
                if !chat.lastMessage.isEmpty {
                    if chat.isGroupChat, let senderName = lastMessageSenderName {
                        Text("\(senderName): \(chat.lastMessage)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    } else {
                        Text(chat.lastMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .task {
            await loadDisplayName()
        }
        .onAppear {
            // Attach presence listener for 1-on-1 chats
            attachPresenceListener()
            // Load unread count (refreshes every time row appears)
            Task {
                await loadUnreadCount()
            }
            // Attach real-time listener for unread count updates
            attachUnreadListener()
        }
        .onDisappear {
            // Detach presence listener to prevent memory leaks
            detachPresenceListener()
            // Detach unread listener
            detachUnreadListener()
        }
    }
    
    // MARK: - Private Methods
    
    /// Load display name and profile photo based on chat type
    /// For 1-on-1: fetch other user's profile with real-time updates
    /// For group: show group name
    private func loadDisplayName() async {
        // Handle group chat
        if chat.isGroupChat {
            displayName = chat.groupName ?? "Group Chat"
            isLoadingName = false
            
            // Fetch last message sender name for groups (if message exists)
            if !chat.lastMessage.isEmpty {
                await fetchLastMessageSenderName()
            }
            return
        }
        
        // Handle 1-on-1 chat
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            displayName = "Unknown User"
            isLoadingName = false
            return
        }
        
        // Get other user's ID
        guard let otherUserID = chat.otherUserID(currentUserID: currentUserID) else {
            displayName = "Unknown User"
            isLoadingName = false
            return
        }
        
        // Store otherUserID for presence listener
        self.otherUserID = otherUserID
        
        // Set up real-time listener for user profile updates
        userListener = userService.observeUser(id: otherUserID) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let user):
                    self.otherUser = user
                    self.displayName = user.displayName
                    self.isLoadingName = false
                case .failure(let error):
                    print("❌ Error observing user profile: \(error.localizedDescription)")
                    self.displayName = "Unknown User"
                    self.isLoadingName = false
                }
            }
        }
    }
    
    /// Attach presence listener for the contact in this chat
    private func attachPresenceListener() {
        // Only attach for 1-on-1 chats
        guard !chat.isGroupChat else { return }
        
        // Wait for otherUserID to be set (loadDisplayName runs asynchronously)
        // Listener will be attached when otherUserID is available
        Task {
            // Poll until otherUserID is set (simple approach for async coordination)
            while otherUserID == nil && !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
            }
            
            guard let contactID = otherUserID, !Task.isCancelled else { return }
            
            // Attach presence listener on main thread and store UUID
            await MainActor.run {
                presenceListenerID = presenceService.observePresence(userID: contactID) { isOnline in
                    DispatchQueue.main.async {
                        self.isContactOnline = isOnline
                    }
                }
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
    
    /// Attach real-time listener for messages to update unread count
    private func attachUnreadListener() {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        
        // Listen to messages subcollection for changes
        messageListener = db.collection("chats")
            .document(chat.id)
            .collection("messages")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ Error listening to messages: \(error.localizedDescription)")
                    return
                }
                
                // When messages change, reload unread count
                Task {
                    await self.loadUnreadCount()
                }
            }
    }
    
    /// Detach unread listener to prevent memory leaks
    private func detachUnreadListener() {
        messageListener?.remove()
        messageListener = nil
    }
    
    /// Fetch sender name for the last message in a group chat
    /// This requires querying the messages sub-collection to get the last message's senderID
    private func fetchLastMessageSenderName() async {
        // For MVP, we can skip this feature or implement it later
        // It would require fetching the last message document to get the senderID
        // For now, we'll just show the message without sender name prefix in conversation list
        // The full sender names will be visible in the ChatView
        
        // Future implementation:
        // 1. Query messages sub-collection ordered by timestamp desc, limit 1
        // 2. Get senderID from that message
        // 3. Fetch user name using chatService.fetchUserName(userID:)
        // 4. Update lastMessageSenderName state
        
        // For now, we'll leave this as a placeholder
        // The group chat will still work, just without sender names in conversation list preview
    }
    
    /// Load unread message count for this chat
    /// Queries Firestore messages where currentUserID is NOT in readBy array
    private func loadUnreadCount() async {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            print("⚠️ Cannot load unread count: user not authenticated")
            return
        }
        
        do {
            let count = try await chatService.getUnreadMessageCount(
                chatID: chat.id,
                currentUserID: currentUserID
            )
            
            // Update state on main thread
            await MainActor.run {
                self.unreadCount = count
            }
        } catch {
            print("❌ Error loading unread count for chat \(chat.id): \(error.localizedDescription)")
            // Default to 0 on error
            await MainActor.run {
                self.unreadCount = 0
            }
        }
    }
}

// MARK: - Preview

#Preview {
    List {
        ChatRowView(chat: Chat(
            id: "preview_chat_1",
            members: ["user1", "user2"],
            lastMessage: "Hey, how are you doing today?",
            lastMessageTimestamp: Date().addingTimeInterval(-300), // 5 minutes ago
            isGroupChat: false
        ))
        
        ChatRowView(chat: Chat(
            id: "preview_chat_2",
            members: ["user1", "user2", "user3"],
            lastMessage: "Meeting at 3pm tomorrow",
            lastMessageTimestamp: Date().addingTimeInterval(-3600), // 1 hour ago
            isGroupChat: true
        ))
    }
}

