//
//  ReadReceiptDetailViewModel.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #5
//  ViewModel for managing read receipt detail view state and real-time updates
//

import Foundation
import FirebaseFirestore

/// ViewModel for ReadReceiptDetailView
/// Manages state, data fetching, and real-time listeners for read receipt details
@MainActor
class ReadReceiptDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Array of read receipt details (sorted: read members first, then unread)
    @Published var details: [ReadReceiptDetail] = []
    
    /// Loading state indicator
    @Published var isLoading: Bool = false
    
    /// Error message for display (nil if no error)
    @Published var errorMessage: String? = nil
    
    // MARK: - Private Properties
    
    /// Firestore listener for real-time message updates
    private var messageListener: ListenerRegistration?
    
    /// MessageService instance for data fetching
    private let messageService = MessageService()
    
    /// Current message being observed
    private var currentMessage: Message?
    
    /// Current chat context
    private var currentChat: Chat?
    
    // MARK: - Public Methods
    
    /// Loads read receipt details for a message and sets up real-time listener
    /// - Parameters:
    ///   - message: The message to load read receipt details for
    ///   - chat: The chat containing the message
    func loadReadReceipts(for message: Message, in chat: Chat) {
        print("[ReadReceiptDetailViewModel] Loading read receipts for message: \(message.id)")
        
        // Store message and chat for listener updates
        currentMessage = message
        currentChat = chat
        
        // Start loading
        isLoading = true
        errorMessage = nil
        
        // Fetch read receipt details on background thread
        Task {
            do {
                let fetchedDetails = try await messageService.fetchReadReceiptDetails(for: message, in: chat)
                
                // Update UI on main thread
                await MainActor.run {
                    self.details = fetchedDetails
                    self.isLoading = false
                    print("[ReadReceiptDetailViewModel] ✅ Loaded \(fetchedDetails.count) read receipt details")
                }
                
                // Set up real-time listener after initial load
                setupRealtimeListener(chatID: chat.id)
                
            } catch {
                // Handle errors
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Unable to load read receipts. Please try again."
                    print("[ReadReceiptDetailViewModel] ❌ Failed to load read receipts: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Retries loading read receipts after an error
    func retry() {
        guard let message = currentMessage, let chat = currentChat else {
            print("[ReadReceiptDetailViewModel] ⚠️ Cannot retry - no message/chat context")
            return
        }
        
        print("[ReadReceiptDetailViewModel] Retrying read receipt load")
        loadReadReceipts(for: message, in: chat)
    }
    
    // MARK: - Private Methods
    
    /// Sets up real-time listener for message updates
    /// Updates details array when message.readBy changes
    /// - Parameter chatID: The chat ID containing the message
    private func setupRealtimeListener(chatID: String) {
        guard let message = currentMessage, let chat = currentChat else {
            print("[ReadReceiptDetailViewModel] ⚠️ Cannot set up listener - no message/chat context")
            return
        }
        
        print("[ReadReceiptDetailViewModel] 👂 Setting up real-time listener for message: \(message.id)")
        
        // Remove existing listener if any
        messageListener?.remove()
        
        // Listen to the specific message document
        let messageRef = Firestore.firestore()
            .collection("chats")
            .document(chatID)
            .collection("messages")
            .document(message.id)
        
        messageListener = messageRef.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("[ReadReceiptDetailViewModel] ❌ Listener error: \(error.localizedDescription)")
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists else {
                print("[ReadReceiptDetailViewModel] ⚠️ Message document doesn't exist")
                return
            }
            
            // Decode updated message
            do {
                let updatedMessage = try snapshot.data(as: Message.self)
                print("[ReadReceiptDetailViewModel] 📨 Received message update, readBy count: \(updatedMessage.readBy.count)")
                
                // Update current message
                self.currentMessage = updatedMessage
                
                // Refresh read receipt details with updated message
                Task {
                    do {
                        let updatedDetails = try await self.messageService.fetchReadReceiptDetails(
                            for: updatedMessage,
                            in: chat
                        )
                        
                        await MainActor.run {
                            self.details = updatedDetails
                            print("[ReadReceiptDetailViewModel] ✅ Updated read receipt details in real-time")
                        }
                    } catch {
                        print("[ReadReceiptDetailViewModel] ❌ Failed to update read receipts: \(error.localizedDescription)")
                    }
                }
            } catch {
                print("[ReadReceiptDetailViewModel] ❌ Failed to decode message: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Cleanup
    
    /// Cleanup when ViewModel is deallocated
    deinit {
        print("[ReadReceiptDetailViewModel] 🧹 Cleaning up - removing listener")
        messageListener?.remove()
    }
}

