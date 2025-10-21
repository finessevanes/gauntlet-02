//
//  ChatListViewModel.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #6
//  ViewModel managing chat list state and Firestore listener
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

/// ViewModel managing the conversation list screen state
/// Follows MVVM pattern: handles business logic and state management
class ChatListViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Array of chats sorted by most recent activity
    @Published var chats: [Chat] = []
    
    /// Loading state for initial fetch
    @Published var isLoading = false
    
    /// Error message to display to user (if any)
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let chatService = ChatService()
    private var listener: ListenerRegistration?
    
    // MARK: - Public Methods
    
    /// Start observing chats for the current authenticated user
    /// Sets up real-time Firestore listener that updates chats automatically
    func observeChats() {
        // Get current user ID
        guard let userID = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated"
            print("❌ Cannot observe chats: user not authenticated")
            return
        }
        
        // Set loading state
        isLoading = true
        errorMessage = nil
        
        // Remove existing listener if any
        listener?.remove()
        
        // Set up new listener
        listener = chatService.observeUserChats(userID: userID) { [weak self] chats in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.chats = chats
                print("✅ Chats updated: \(chats.count) chats loaded")
            }
        }
    }
    
    /// Stop observing chats (cleanup)
    /// Should be called when view disappears to prevent memory leaks
    func stopObserving() {
        listener?.remove()
        listener = nil
        print("🧹 Stopped observing chats")
    }
    
    // MARK: - Lifecycle
    
    deinit {
        stopObserving()
    }
}

