//
//  MessageInputView.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #7
//  Message input bar with text field and send button
//

import SwiftUI
import PhotosUI

/// Message input bar component for composing and sending messages
/// Includes text field with placeholder and send button that enables/disables based on content
/// Broadcasts typing status to other chat participants
struct MessageInputView: View {
    // MARK: - Properties
    
    /// Binding to the input text field
    @Binding var text: String
    
    /// Closure called when send button is tapped
    let onSend: () -> Void
    
    /// Closure called when an image is selected to send
    /// Passes raw UIImage for optimal single-pass compression
    let onSendImage: (UIImage) -> Void
    
    /// Chat ID for typing status
    let chatID: String
    
    /// Current user ID for typing status
    let userID: String
    
    /// Typing indicator service for broadcasting typing status
    let typingIndicatorService: TypingIndicatorService
    
    /// Optional callback for handling typing service errors
    let onError: ((Error) -> Void)?
    
    /// Focus state for keyboard management
    @FocusState private var isTextFieldFocused: Bool
    
    /// Task state for managing typing indicator operations
    @State private var typingTask: Task<Void, Never>?
    
    /// Image picking state (PR #009)
    @State private var showPhotoSourcePicker: Bool = false
    @State private var showLibraryPicker: Bool = false
    @State private var showCameraPicker: Bool = false
    @State private var selectedImage: UIImage? = nil
    @State private var previewImage: UIImage? = nil  // Image ready to send (with preview)
    @State private var imageError: ProfilePhotoError? = nil
    @State private var isSendingImage: Bool = false  // Prevent duplicate sends
    
    // MARK: - Constants
    
    private enum Constants {
        static let horizontalPadding: CGFloat = 12
        static let verticalPadding: CGFloat = 8
        static let interItemSpacing: CGFloat = 12
        static let leadingPadding: CGFloat = 4
        static let trailingPadding: CGFloat = 4
        static let sendIconSize: CGFloat = 20
        static let sendButtonSize: CGFloat = 36
        static let minLineLimit = 1
        static let maxLineLimit = 5
    }
    
    // MARK: - Computed Properties
    
    /// Whether the send button should be enabled (text is not empty)
    private var isSendEnabled: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Whether there's an image ready to send
    private var hasImageToSend: Bool {
        previewImage != nil
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Image preview (if image selected)
            if let image = previewImage {
                imagePreviewView(image: image)
            }
            
            HStack(spacing: Constants.interItemSpacing) {
                // Camera button
                Button(action: {
                    showPhotoSourcePicker = true
                }) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: Constants.sendIconSize))
                        .foregroundColor(.blue)
                        .frame(width: Constants.sendButtonSize, height: Constants.sendButtonSize)
                }
                .accessibilityLabel("Add photo")
                .accessibilityHint("Open photo options")
                // Text input field
                TextField("Message...", text: $text, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(Constants.minLineLimit...Constants.maxLineLimit)
                    .submitLabel(.send)
                    .focused($isTextFieldFocused)
                    .onSubmit {
                        // Handle Enter key submission only when text is present
                        // This should not interfere with system keyboard shortcuts like Cmd+V
                        if isSendEnabled || hasImageToSend {
                            handleSendButton()
                        }
                    }
                    .accessibilityLabel("Message input field")
                    .accessibilityHint("Type your message here, then press send")
                    .padding(.leading, Constants.leadingPadding)
                    .onChange(of: text) { oldValue, newValue in
                        print("[MessageInputView] Text changed from '\(oldValue)' to '\(newValue)'")
                        handleTextChange(newValue)
                    }
                    .textInputAutocapitalization(.sentences)
                    .autocorrectionDisabled(false)
                    .keyboardType(.default)
                    .textContentType(.none)
                
                // Send button
                Button(action: {
                    if isSendEnabled || hasImageToSend {
                        handleSendButton()
                    }
                }) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: Constants.sendIconSize))
                        .foregroundColor((isSendEnabled || hasImageToSend) ? .blue : .gray)
                        .frame(width: Constants.sendButtonSize, height: Constants.sendButtonSize)
                }
                .accessibilityLabel("Send message")
                .accessibilityHint((isSendEnabled || hasImageToSend) ? "Send your message" : "Enter text or select image to enable sending")
                .disabled(!isSendEnabled && !hasImageToSend)
                .padding(.trailing, Constants.trailingPadding)
            }
            .padding(.horizontal, Constants.horizontalPadding)
            .padding(.vertical, Constants.verticalPadding)
            .background(Color(.systemBackground))
        }
        // Confirmation dialog with explicit actions (prevents empty-actions warning)
        .confirmationDialog(
            "Choose Photo Source",
            isPresented: $showPhotoSourcePicker,
            titleVisibility: .visible
        ) {
            Button("Take Photo") { showCameraPicker = true }
            Button("Choose from Library") { showLibraryPicker = true }
            Button("Cancel", role: .cancel) { }
        }
        // Library picker sheet
        .sheet(isPresented: $showLibraryPicker) {
            ProfilePhotoPicker(selectedImage: $selectedImage, error: $imageError)
                .onChange(of: selectedImage) { _, newValue in
                    guard let image = newValue else { return }
                    
                    // Set preview image (user can review before sending)
                    withAnimation(.easeInOut(duration: 0.2)) {
                        previewImage = image
                    }
                    
                    // Reset selection to allow re-picking
                    selectedImage = nil
                }
        }
        // Camera picker sheet
        .sheet(isPresented: $showCameraPicker) {
            CameraPicker(selectedImage: $selectedImage, error: $imageError)
                .onChange(of: selectedImage) { _, newValue in
                    guard let image = newValue else { return }
                    
                    // Set preview image (user can review before sending)
                    withAnimation(.easeInOut(duration: 0.2)) {
                        previewImage = image
                    }
                    
                    // Reset selection
                    selectedImage = nil
                }
        }
        .onDisappear {
            // Cancel any pending typing tasks
            typingTask?.cancel()
            
            // Clear typing status when view disappears
            Task {
                try? await typingIndicatorService.stopTyping(chatID: chatID, userID: userID)
            }
        }
    }
    
    // MARK: - Actions
    
    /// Handle text change to broadcast typing status
    private func handleTextChange(_ newText: String) {
        // Cancel previous task to prevent multiple simultaneous requests
        typingTask?.cancel()
        
        let trimmed = newText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        typingTask = Task {
            do {
                if trimmed.isEmpty {
                    try await typingIndicatorService.stopTyping(chatID: chatID, userID: userID)
                } else {
                    try await typingIndicatorService.startTyping(chatID: chatID, userID: userID)
                }
            } catch {
                guard !Task.isCancelled else { return }
                print("[MessageInputView] Error updating typing status: \(error.localizedDescription)")
                onError?(error)
            }
        }
    }
    
    /// Handle send button tap - clear typing status before sending
    private func handleSendButton() {
        // Add haptic feedback for better UX
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        // Clear typing status immediately before sending
        Task {
            try? await typingIndicatorService.stopTyping(chatID: chatID, userID: userID)
        }
        
        // Send image if one is selected
        if let image = previewImage {
            onSendImage(image)
            previewImage = nil  // Clear preview after sending
        }
        
        // Send text message if text exists
        if isSendEnabled {
            onSend()
        }
        
        // Don't automatically dismiss keyboard to allow for paste operations
        // User can manually dismiss by tapping outside or using keyboard shortcuts
    }
    
    /// Image preview view with remove button - iMessage style
    private func imagePreviewView(image: UIImage) -> some View {
        ZStack(alignment: .topTrailing) {
            // Image preview with natural rounded corners
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: 280, maxHeight: 280)
                .clipped()
                .cornerRadius(18)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
            
            // Remove button - positioned in top-right corner
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    previewImage = nil
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.5))
                            .frame(width: 28, height: 28)
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .padding(12)
            .accessibilityLabel("Remove photo")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

// MARK: - Mock Services for Previews

private class MockTypingIndicatorService: TypingIndicatorService {
    override func startTyping(chatID: String, userID: String) async throws {
        print("Mock: Start typing in chat \(chatID)")
    }
    
    override func stopTyping(chatID: String, userID: String) async throws {
        print("Mock: Stop typing in chat \(chatID)")
    }
}

// MARK: - Preview

#Preview("Empty Input") {
    VStack {
        Spacer()
        MessageInputView(
            text: .constant(""),
            onSend: { print("Send tapped") },
            onSendImage: { image in print("Send image: \(image.size)") },
            chatID: "preview_chat",
            userID: "preview_user",
            typingIndicatorService: MockTypingIndicatorService(),
            onError: { error in print("Error: \(error)") }
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
            onSendImage: { image in print("Send image: \(image.size)") },
            chatID: "preview_chat",
            userID: "preview_user",
            typingIndicatorService: MockTypingIndicatorService(),
            onError: { error in print("Error: \(error)") }
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
            onSendImage: { image in print("Send image: \(image.size)") },
            chatID: "preview_chat",
            userID: "preview_user",
            typingIndicatorService: MockTypingIndicatorService(),
            onError: { error in print("Error: \(error)") }
        )
        .background(Color(.systemGray6))
    }
}

