//
//  DeepLinkHandler.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #16
//  Handles deep linking from push notifications to navigate to specific chats
//

import Foundation
import SwiftUI
import FirebaseFirestore

/// Handles deep linking from push notifications to navigate to specific chats
/// Processes notification data and provides navigation actions
class DeepLinkHandler: ObservableObject {
    
    // MARK: - Published Properties
    
    /// The chat ID to navigate to from deep link
    @Published var targetChatId: String?
    
    /// Whether a deep link is currently being processed
    @Published var isProcessingDeepLink: Bool = false
    
    // MARK: - Private Properties
    
    private let db = Firestore.firestore()
    
    // MARK: - Deep Link Processing
    
    /// Process notification data and extract chat information
    /// - Parameter userInfo: Notification user info dictionary
    /// - Returns: Bool indicating if deep link was successfully processed
    func processNotificationData(_ userInfo: [AnyHashable: Any]) -> Bool {
        print("[DeepLinkHandler] 🔗 Processing notification data")
        
        guard let data = userInfo["data"] as? [String: Any] else {
            print("[DeepLinkHandler] ❌ No data found in notification")
            return false
        }
        
        guard let chatId = data["chatId"] as? String else {
            print("[DeepLinkHandler] ❌ No chatId found in notification data")
            return false
        }
        
        guard let type = data["type"] as? String, type == "new_message" else {
            print("[DeepLinkHandler] ❌ Invalid notification type: \(data["type"] ?? "unknown")")
            return false
        }
        
        print("[DeepLinkHandler] ✅ Valid deep link data - Chat ID: \(chatId)")
        
        Task {
            await MainActor.run {
                self.isProcessingDeepLink = true
                self.targetChatId = chatId
            }
        }
        
        return true
    }
    
    /// Navigate to the target chat
    /// - Parameter chatId: The chat ID to navigate to
    func navigateToChat(_ chatId: String) {
        print("[DeepLinkHandler] 🧭 Navigating to chat: \(chatId)")
        
        Task {
            await MainActor.run {
                self.targetChatId = chatId
            }
        }
    }
    
    /// Clear the current deep link target
    func clearDeepLink() {
        print("[DeepLinkHandler] 🧹 Clearing deep link target")
        
        Task {
            await MainActor.run {
                self.targetChatId = nil
                self.isProcessingDeepLink = false
            }
        }
    }
    
    /// Validate that a chat exists before navigation
    /// - Parameter chatId: The chat ID to validate
    /// - Returns: Bool indicating if chat exists
    func validateChatExists(_ chatId: String) async -> Bool {
        do {
            let chatDoc = try await db.collection("chats").document(chatId).getDocument()
            return chatDoc.exists
        } catch {
            print("[DeepLinkHandler] ❌ Error validating chat: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Get chat information for deep link navigation
    /// - Parameter chatId: The chat ID
    /// - Returns: Chat information or nil if not found
    func getChatInfo(_ chatId: String) async -> [String: Any]? {
        do {
            let chatDoc = try await db.collection("chats").document(chatId).getDocument()
            
            guard chatDoc.exists, let data = chatDoc.data() else {
                print("[DeepLinkHandler] ❌ Chat not found: \(chatId)")
                return nil
            }
            
            return data
        } catch {
            print("[DeepLinkHandler] ❌ Error getting chat info: \(error.localizedDescription)")
            return nil
        }
    }
}
