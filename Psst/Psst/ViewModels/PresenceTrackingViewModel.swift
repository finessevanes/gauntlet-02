//
//  PresenceTrackingViewModel.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - Refactored from ChatView
//  Handles user presence, typing indicators, and group member management
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

/// View model responsible for presence tracking in chat
/// Handles user presence, typing indicators, and group member management
@MainActor
class PresenceTrackingViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Contact's online status (for 1-on-1 chats)
    @Published var isContactOnline: Bool = false
    
    /// Other user's ID (for presence tracking)
    @Published var otherUserID: String?
    
    /// Other user's profile (for displaying photo in header)
    @Published var otherUser: User? = nil
    
    /// User IDs currently typing in this chat
    @Published var typingUserIDs: [String] = []
    
    /// Display names of users currently typing
    @Published var typingUserNames: [String] = []
    
    /// Group member presence tracking (userID -> isOnline)
    @Published var memberPresences: [String: Bool] = [:]
    
    /// Loaded group member profiles (for header display)
    @Published var groupMembers: [User] = []
    
    /// Show member list sheet
    @Published var showMemberList: Bool = false
    
    // MARK: - Private Properties
    
    /// The chat being managed
    private let chat: Chat
    
    /// Current user ID from Firebase Auth
    private var currentUserID: String = ""
    
    /// Presence service for online/offline status
    private var presenceService: PresenceService?
    
    /// Typing indicator service for real-time typing status
    @Published private var typingIndicatorService = TypingIndicatorService()
    
    /// User service for fetching user profiles
    private let userService = UserService.shared
    
    /// User profile listener for real-time updates
    private var userListener: ListenerRegistration? = nil
    
    /// Group presence listeners for cleanup
    private var presenceListeners: [String: UUID] = [:]
    
    // MARK: - Initialization

    init(chat: Chat) {
        self.chat = chat

        // For 1-on-1 chats, eagerly load cached user data in init() BEFORE view renders
        // This prevents the header from popping in after the view appears
        if !chat.isGroupChat, let currentUserID = Auth.auth().currentUser?.uid {
            if let otherUserID = chat.otherUserID(currentUserID: currentUserID) {
                if let cachedUser = userService.getCachedUser(id: otherUserID) {
                    self.otherUser = cachedUser
                    self.otherUserID = otherUserID
                }
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Initialize the view model with current user ID and presence service
    func initialize(currentUserID: String, presenceService: PresenceService) {
        self.currentUserID = currentUserID
        self.presenceService = presenceService

        // Determine other user ID for presence tracking
        determineOtherUserID()

        // For 1-on-1 chats, immediately check cache and set otherUser BEFORE async listener
        // This prevents header pop-in by showing cached data on first render
        if !chat.isGroupChat, let otherUserID = otherUserID {
            if let cachedUser = userService.getCachedUser(id: otherUserID) {
                self.otherUser = cachedUser
            }
        }

        // Attach typing listener
        attachTypingListener()

        // Load group members and observe presence (PR #004)
        if chat.isGroupChat {
            Task {
                await loadGroupMembers()
            }
            attachGroupPresenceListeners()
        }
    }
    
    /// Clean up resources when chat is closed
    func cleanup() {
        // Remove user profile listener
        userListener?.remove()
        userListener = nil
        
        // Detach typing listener and clear own typing status
        detachTypingListener()
        
        // Detach group presence listeners (PR #004)
        if chat.isGroupChat {
            detachGroupPresenceListeners()
        }
    }
    
    /// Get typing indicator service for input view
    func getTypingIndicatorService() -> TypingIndicatorService {
        return typingIndicatorService
    }
    
    /// Show member list sheet
    func showMemberListSheet() {
        showMemberList = true
    }
    
    // MARK: - Private Methods
    
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
            // UserService now guarantees completion is called on main thread
            // No need for DispatchQueue.main.async - execute immediately
            switch result {
            case .success(let user):
                self.otherUser = user
            case .failure(let error):
                print("❌ Error observing user profile: \(error.localizedDescription)")
            }
        }
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
        guard chat.isGroupChat, let presenceService = presenceService else { return }
        
        presenceListeners = presenceService.observeGroupPresence(userIDs: chat.members) { userID, isOnline in
            DispatchQueue.main.async {
                self.memberPresences[userID] = isOnline
            }
        }
    }
    
    /// Detach all group presence listeners
    private func detachGroupPresenceListeners() {
        guard !presenceListeners.isEmpty, let presenceService = presenceService else { return }
        
        presenceService.stopObservingGroup(listeners: presenceListeners)
        presenceListeners.removeAll()
        memberPresences.removeAll()
    }
}
