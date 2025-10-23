//
//  ChatInteractionViewModel.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - Refactored from ChatView
//  Handles keyboard, scrolling, and UI interaction state
//

import SwiftUI

/// View model responsible for chat interaction state
/// Handles keyboard, scrolling, and UI interaction management
@MainActor
class ChatInteractionViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Input text field value
    @Published var inputText = ""
    
    /// Track if this is the initial load to prevent unwanted scrolling
    @Published var isInitialLoad: Bool = true
    
    /// Track keyboard state for proper scrolling
    @Published var isKeyboardVisible: Bool = false
    
    // MARK: - Private Properties
    
    /// Scroll proxy for programmatic scrolling
    private var scrollProxy: ScrollViewProxy?
    
    // MARK: - Public Methods
    
    /// Set the scroll proxy for programmatic scrolling
    func setScrollProxy(_ proxy: ScrollViewProxy) {
        scrollProxy = proxy
    }
    
    /// Get the current scroll proxy
    func getScrollProxy() -> ScrollViewProxy? {
        return scrollProxy
    }
    
    /// Handle send button tap - clears input and returns the text
    func handleSend() -> String {
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        inputText = "" // Clear input field immediately
        return trimmedText
    }
    
    /// Scroll to bottom of message list (for new messages)
    func scrollToBottom() {
        guard let proxy = scrollProxy else { return }
        
        // Small delay to ensure layout updates complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Remove animation to prevent "weird scrolling thing"
            proxy.scrollTo("bottom", anchor: .bottom)
        }
    }
    
    /// Scroll to bottom immediately (for initial load)
    func scrollToBottomImmediately() {
        guard let proxy = scrollProxy else { return }
        
        // Small delay to ensure layout is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            proxy.scrollTo("bottom", anchor: .bottom)
        }
    }
    
    /// Handle initial load scrolling
    func handleInitialLoad() {
        if isInitialLoad {
            // First load - scroll immediately without delay
            scrollToBottomImmediately()
            isInitialLoad = false
        } else {
            // New messages - scroll with small delay
            scrollToBottom()
        }
    }
    
    /// Handle keyboard visibility changes
    func handleKeyboardVisibilityChange() {
        if isKeyboardVisible {
            // Keyboard appeared - scroll to bottom to keep latest message visible
            scrollToBottom()
        }
    }
    
    /// Set up keyboard notifications to handle scrolling when keyboard appears/disappears
    func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.isKeyboardVisible = true
            // Scroll to bottom when keyboard appears to keep latest message visible
            self.scrollToBottom()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.isKeyboardVisible = false
            // Scroll to bottom when keyboard disappears to ensure latest message is visible
            self.scrollToBottom()
        }
    }
    
    /// Remove keyboard notifications to prevent memory leaks
    func removeKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    /// Clean up resources when chat is closed
    func cleanup() {
        removeKeyboardNotifications()
        scrollProxy = nil
    }
}
