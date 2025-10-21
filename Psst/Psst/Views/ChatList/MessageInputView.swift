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
struct MessageInputView: View {
    // MARK: - Properties
    
    /// Binding to the input text field
    @Binding var text: String
    
    /// Closure called when send button is tapped
    let onSend: () -> Void
    
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
            
            // Send button
            Button(action: {
                if isSendEnabled {
                    onSend()
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
}

// MARK: - Preview

#Preview("Empty Input") {
    VStack {
        Spacer()
        MessageInputView(text: .constant(""), onSend: {
            print("Send tapped")
        })
        .background(Color(.systemGray6))
    }
}

#Preview("With Text") {
    VStack {
        Spacer()
        MessageInputView(text: .constant("Hello there!"), onSend: {
            print("Send tapped")
        })
        .background(Color(.systemGray6))
    }
}

#Preview("Long Text") {
    VStack {
        Spacer()
        MessageInputView(text: .constant("This is a longer message that should demonstrate how the text field wraps when there's more content than fits on a single line."), onSend: {
            print("Send tapped")
        })
        .background(Color(.systemGray6))
    }
}

