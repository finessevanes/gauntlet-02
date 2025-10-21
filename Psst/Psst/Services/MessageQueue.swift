//
//  MessageQueue.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #10
//  Offline message queue manager with UserDefaults persistence
//

import Foundation

/// Manages queue of messages sent while offline
/// Persists queue in UserDefaults across app restarts
/// Automatically processes queue when network reconnects
class MessageQueue {
    /// Shared singleton instance for app-wide queue access
    static let shared = MessageQueue()
    
    /// UserDefaults key for persisting message queue
    private let queueKey = "com.psst.messageQueue"
    
    /// MessageService for sending queued messages
    private let messageService = MessageService()
    
    /// Private initializer to enforce singleton pattern
    private init() {}
    
    // MARK: - Queue Operations
    
    /// Add message to queue
    /// - Parameter message: The QueuedMessage to add
    /// - Throws: Error if encoding fails
    func enqueue(_ message: QueuedMessage) throws {
        var queue = getQueue()
        queue.append(message)
        saveQueue(queue)
        print("📥 Message queued: \(message.id) for chat: \(message.chatID)")
    }
    
    /// Remove message from queue by ID
    /// - Parameter id: The message ID to remove
    func dequeue(id: String) {
        var queue = getQueue()
        queue.removeAll { $0.id == id }
        saveQueue(queue)
        print("✅ Message dequeued: \(id)")
    }
    
    /// Get all queued messages for a specific chat
    /// - Parameter chatID: The chat ID to filter by
    /// - Returns: Array of queued messages for this chat
    func getQueuedMessages(for chatID: String) -> [QueuedMessage] {
        return getQueue().filter { $0.chatID == chatID }
    }
    
    /// Get count of all queued messages
    /// - Returns: Total number of queued messages
    func getQueueCount() -> Int {
        return getQueue().count
    }
    
    /// Get count of queued messages for a specific chat
    /// - Parameter chatID: The chat ID to count
    /// - Returns: Number of queued messages for this chat
    func getQueueCount(for chatID: String) -> Int {
        return getQueuedMessages(for: chatID).count
    }
    
    // MARK: - Queue Processing
    
    /// Process entire queue by attempting to send all queued messages
    /// Called automatically when network reconnects
    /// Uses exponential backoff for retries (immediate, 1s, 3s)
    func processQueue() async {
        let queue = getQueue()
        
        guard !queue.isEmpty else {
            print("📤 Queue empty - nothing to process")
            return
        }
        
        print("📤 Processing message queue: \(queue.count) messages")
        
        for queuedMessage in queue {
            // Add delay for retry attempts (exponential backoff)
            if queuedMessage.retryCount > 0 {
                let delay = pow(2.0, Double(queuedMessage.retryCount)) // 2^retryCount seconds
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
            
            do {
                // Attempt to send message using the ORIGINAL queued message ID
                // This prevents creating duplicate messages with new IDs
                _ = try await messageService.sendMessage(
                    chatID: queuedMessage.chatID,
                    text: queuedMessage.text,
                    messageID: queuedMessage.id  // ← Use original ID!
                )
                
                // Success - remove from queue
                dequeue(id: queuedMessage.id)
                print("✅ Queued message sent successfully: \(queuedMessage.id)")
                
            } catch {
                print("❌ Failed to send queued message \(queuedMessage.id): \(error.localizedDescription)")
                
                // Update retry count
                var updated = queuedMessage
                updated.retryCount += 1
                
                if updated.retryCount >= 3 {
                    // Max retries reached - mark as failed and remove
                    dequeue(id: queuedMessage.id)
                    print("❌ Message \(queuedMessage.id) failed after 3 retries - removed from queue")
                } else {
                    // Update retry count and keep in queue
                    var queue = getQueue()
                    if let index = queue.firstIndex(where: { $0.id == queuedMessage.id }) {
                        queue[index] = updated
                        saveQueue(queue)
                        print("🔄 Retry count updated: \(queuedMessage.id) (attempt \(updated.retryCount))")
                    }
                }
            }
        }
        
        print("✅ Queue processing complete")
    }
    
    // MARK: - Private Helpers
    
    /// Load queue from UserDefaults
    /// - Returns: Array of queued messages (empty if none)
    private func getQueue() -> [QueuedMessage] {
        guard let data = UserDefaults.standard.data(forKey: queueKey),
              let queue = try? JSONDecoder().decode([QueuedMessage].self, from: data) else {
            return []
        }
        return queue
    }
    
    /// Save queue to UserDefaults
    /// - Parameter queue: Array of queued messages to persist
    private func saveQueue(_ queue: [QueuedMessage]) {
        if let data = try? JSONEncoder().encode(queue) {
            UserDefaults.standard.set(data, forKey: queueKey)
        }
    }
}

