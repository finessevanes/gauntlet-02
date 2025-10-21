//
//  MessageInputView.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #7
//  Message input bar with text field and send button
//

import SwiftUI

/// Message input bar component for composing and sending messages
/// Includes text field with placeholder and send button that enables/disables based on content
/// Broadcasts typing status to other chat participants
struct MessageInputView: View {
    // MARK: - Properties
    
    /// Binding to the input text field
    @Binding var text: String
    
    /// Closure called when send button is tapped
    let onSend: () -> Void
    
    /// Chat ID for typing status
    let chatID: String
    
    /// Current user ID for typing status
    let userID: String
    
    /// Typing indicator service for broadcasting typing status
    let typingIndicatorService: TypingIndicatorService
    
    // MARK: - Computed Properties
    
    /// Whether the send button should be enabled (text is not empty)
    private var isSendEnabled: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 12) {
            // Text input field
            TextField("Message...", text: $text, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...5)
                .padding(.leading, 4)
                .onChange(of: text) { oldValue, newValue in
                    handleTextChange(newValue)
                }
            
            // Send button
            Button(action: {
                if isSendEnabled {
                    handleSendButton()
                }
            }) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 20))
                    .foregroundColor(isSendEnabled ? .blue : .gray)
                    .frame(width: 36, height: 36)
            }
            .disabled(!isSendEnabled)
            .padding(.trailing, 4)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Actions
    
    /// Handle text change to broadcast typing status
    private func handleTextChange(_ newText: String) {
        let trimmed = newText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            // User deleted all text - stop typing
            Task {
                try? await typingIndicatorService.stopTyping(chatID: chatID, userID: userID)
            }
        } else {
            // User is typing - broadcast status (throttled automatically)
            Task {
                try? await typingIndicatorService.startTyping(chatID: chatID, userID: userID)
            }
        }
    }
    
    /// Handle send button tap - clear typing status before sending
    private func handleSendButton() {
        // Clear typing status immediately before sending
        Task {
            try? await typingIndicatorService.stopTyping(chatID: chatID, userID: userID)
        }
        
        // Call original send handler
        onSend()
    }
}

// MARK: - Preview

#Preview("Empty Input") {
    VStack {
        Spacer()
        MessageInputView(
            text: .constant(""),
            onSend: { print("Send tapped") },
            chatID: "preview_chat",
            userID: "preview_user",
            typingIndicatorService: TypingIndicatorService()
        )
        .background(Color(.systemGray6))
    }
}

#Preview("With Text") {
    VStack {
        Spacer()
        MessageInputView(
            text: .constant("Hello there!"),
            onSend: { print("Send tapped") },
            chatID: "preview_chat",
            userID: "preview_user",
            typingIndicatorService: TypingIndicatorService()
        )
        .background(Color(.systemGray6))
    }
}

#Preview("Long Text") {
    VStack {
        Spacer()
        MessageInputView(
            text: .constant("This is a longer message that should demonstrate how the text field wraps when there's more content than fits on a single line."),
            onSend: { print("Send tapped") },
            chatID: "preview_chat",
            userID: "preview_user",
            typingIndicatorService: TypingIndicatorService()
        )
        .background(Color(.systemGray6))
    }
}

