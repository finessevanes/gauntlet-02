//
//  ChatView.swift
//  Psst
//
//  Updated by Caleb (Coder Agent) - PR #10: Optimistic UI and offline persistence
//  Updated by Caleb (Coder Agent) - PR #17: Added profile photos in header
//  Updated by Caleb (Coder Agent) - PR #2: Fix delivery status to show only on latest message
//  Refactored by Caleb (Coder Agent) - Split into focused view models
//  Full chat view with message list, input bar, auto-scroll, and offline support
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

/// Main chat view displaying messages in a conversation
/// Shows message list with sent/received styling, presence indicator, and message input bar, offline support, and optimistic UI
struct ChatView: View {
    // MARK: - Properties
    
    /// The chat being displayed
    let chat: Chat
    
    /// Current user ID from Firebase Auth
    @State private var currentUserID: String = ""
    
    /// Network monitor for connection state
    @ObservedObject var networkMonitor = NetworkMonitor.shared

    /// Presence service for online/offline status
    @EnvironmentObject private var presenceService: PresenceService

    /// Authentication service for user role checking (PR #007)
    private let authService = AuthenticationService.shared
    
    // MARK: - View Models
    
    /// Message management view model
    @StateObject private var messageViewModel: MessageManagementViewModel
    
    /// Presence tracking view model
    @StateObject private var presenceViewModel: PresenceTrackingViewModel
    
    /// Chat interaction view model
    @StateObject private var interactionViewModel: ChatInteractionViewModel
    
    /// Contextual AI view model (PR #006)
    @StateObject private var contextualAIViewModel = ContextualAIViewModel()

    /// Client profile view model (PR #007)
    @StateObject private var profileViewModel = ClientProfileViewModel()

    // MARK: - Contextual AI State (PR #006)

    /// ID of message showing contextual menu
    @State private var showingMenuForMessageID: String?

    // MARK: - Profile State (PR #007)

    /// Show full profile detail sheet
    @State private var showProfileDetail = false

    /// Check if current user is a trainer (only trainers see client profiles)
    private var isCurrentUserTrainer: Bool {
        authService.currentUser?.role == .trainer
    }

    /// Get the client ID for profile viewing (only if current user is trainer and other user is client)
    private var clientIdForProfile: String? {
        guard isCurrentUserTrainer,
              let otherUserID = presenceViewModel.otherUserID else {
            return nil
        }
        // TODO: We should check if the other user is actually a client
        // For now, assume they are (trainer-to-trainer chats are rare)
        return otherUserID
    }
    
    // MARK: - Initialization

    init(chat: Chat) {
        self.chat = chat
        self._messageViewModel = StateObject(wrappedValue: MessageManagementViewModel(chat: chat))
        self._presenceViewModel = StateObject(wrappedValue: PresenceTrackingViewModel(chat: chat))
        self._interactionViewModel = StateObject(wrappedValue: ChatInteractionViewModel())
    }
    
    // MARK: - Body
    
    var body: some View {
        mainContent
            .aiContextualOverlays(viewModel: contextualAIViewModel, onSaveReminder: handleSaveReminder)
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            // Custom header for 1-on-1 chats (replaces toolbar to prevent pop-in)
            if !chat.isGroupChat {
                CustomChatHeader(
                    otherUser: presenceViewModel.otherUser,
                    isOnline: presenceViewModel.isContactOnline
                )
            }

            // Network status banner (offline/reconnecting/connected)
            NetworkStatusBanner(networkMonitor: networkMonitor, queueCount: $messageViewModel.queueCount)

            // Client profile banner (PR #007) - Only show for trainers viewing clients
            if !chat.isGroupChat, isCurrentUserTrainer, clientIdForProfile != nil {
                ClientProfileBannerView(
                    profile: profileViewModel.profile,
                    onTapViewFull: {
                        showProfileDetail = true
                    }
                )
            }

            // Message list
            if messageViewModel.messages.isEmpty {
                // Empty state
                emptyStateView
            } else {
                // Messages
                messageListView
            }
            
            // Typing indicator (appears below messages, above input)
            TypingIndicatorView(typingUserNames: presenceViewModel.typingUserNames)
            
            // Message input bar
            MessageInputView(
                text: $interactionViewModel.inputText,
                onSend: handleSend,
                onSendImage: { image in
                    handleSendImage(image)
                },
                chatID: chat.id,
                userID: currentUserID,
                typingIndicatorService: presenceViewModel.getTypingIndicatorService(),
                onError: { error in
                    print("[ChatView] Typing indicator error: \(error.localizedDescription)")
                }
            )
        }
        .navigationTitle(chat.isGroupChat ? (chat.groupName ?? "Group Chat") : "")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(!chat.isGroupChat) // Hide for 1-on-1, show for group
        .toolbar {
            // Show member photos for group chats (PR #004)
            if chat.isGroupChat {
                // Show member photos for group chats (PR #004)
                ToolbarItem(placement: .principal) {
                    Button(action: {
                        presenceViewModel.showMemberListSheet()
                    }) {
                        VStack(spacing: 4) {
                            // Group name
                            Text(chat.groupName ?? "Group Chat")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            // Member photos row (first 3-5 members)
                            HStack(spacing: -8) {
                                ForEach(Array(presenceViewModel.groupMembers.prefix(5).enumerated()), id: \.element.id) { index, member in
                                    ProfilePhotoWithPresence(
                                        userID: member.id,
                                        photoURL: member.photoURL,
                                        displayName: member.displayName,
                                        size: 24
                                    )
                                    .zIndex(Double(5 - index)) // Stack from left to right
                                }
                                
                                // Show "+X more" if there are more members
                                if presenceViewModel.groupMembers.count > 5 {
                                    Text("+\(presenceViewModel.groupMembers.count - 5)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $presenceViewModel.showMemberList) {
            // Group member list sheet (PR #004)
            GroupMemberStatusView(chat: chat)
                .environmentObject(presenceService)
        }
        .sheet(isPresented: $showProfileDetail) {
            // Client profile detail sheet (PR #007) - Only for trainers
            if !chat.isGroupChat, isCurrentUserTrainer, let clientId = clientIdForProfile {
                ClientProfileDetailView(
                    viewModel: profileViewModel,
                    clientId: clientId
                )
            }
        }
        .task {
            // Use .task instead of .onAppear
            // .task runs EARLIER in the view lifecycle (during navigation transition)
            // This ensures header data is loaded BEFORE the view fully appears

            // Get current user ID from Firebase Auth
            guard let uid = Auth.auth().currentUser?.uid else { return }

            currentUserID = uid

            // Initialize all view models
            messageViewModel.initialize(currentUserID: uid)
            presenceViewModel.initialize(currentUserID: uid, presenceService: presenceService)

            // Initialize profile view model for trainers viewing clients (PR #007)
            if !chat.isGroupChat, isCurrentUserTrainer, let clientId = clientIdForProfile {
                profileViewModel.observeProfile(clientId: clientId)
            }
        }
        .onAppear {
            // Setup keyboard notifications on appear (needs the view to be fully rendered)
            interactionViewModel.setupKeyboardNotifications()
        }
        .onDisappear {
            // Clean up all view models
            messageViewModel.cleanup()
            presenceViewModel.cleanup()
            interactionViewModel.cleanup()
            profileViewModel.stopObserving() // PR #007
        }
        .onChange(of: networkMonitor.isConnected) { oldValue, newValue in
            // Process queue when reconnected
            if !oldValue && newValue {
                Task {
                    await messageViewModel.processQueuedMessages()
                }
            }
        }
        // Observe presence for 1-on-1 chats (using PresenceObserverModifier)
        .background(
            Group {
                if !chat.isGroupChat, let contactID = presenceViewModel.otherUserID {
                    Color.clear
                        .observePresence(userID: contactID, isOnline: $presenceViewModel.isContactOnline)
                }
            }
        )
        // PR #006: Contextual AI menu overlay
        .overlay {
            if let messageID = showingMenuForMessageID,
               let message = messageViewModel.messages.first(where: { $0.id == messageID }) {
                contextualMenuOverlay(for: message)
            }
        }
    }
    
    // MARK: - Subviews
    
    /// Empty state view when no messages exist
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text("No messages yet")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Send a message to start the conversation.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
    }
    
    /// Message list view with scroll and auto-scroll functionality
    private var messageListView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(messageViewModel.messages) { message in
                        VStack(alignment: message.isFromCurrentUser(currentUserID: currentUserID) ? .trailing : .leading, spacing: 4) {
                            MessageRow(
                                message: message,
                                isFromCurrentUser: message.isFromCurrentUser(currentUserID: currentUserID),
                                senderName: messageViewModel.getSenderName(for: message),
                                chat: chat,
                                currentUserID: currentUserID,
                                isLatestReadMessage: message.id == messageViewModel.latestReadMessageID,      // PR #2: Timeline view
                                isLatestDeliveredMessage: message.id == messageViewModel.latestDeliveredMessageID,
                                isLatestFailedMessage: message.id == messageViewModel.latestFailedMessageID
                            )
                            .onLongPressGesture(minimumDuration: 0.5) {
                                // PR #006: Long-press to show AI contextual menu
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                showingMenuForMessageID = message.id
                            }
                            
                            // Show status indicator for sent messages only (offline/queued/failed states)
                            if message.isFromCurrentUser(currentUserID: currentUserID) {
                                MessageStatusIndicator(
                                    status: message.sendStatus,
                                    onRetry: {
                                        messageViewModel.retryMessage(message)
                                    }
                                )
                            }
                        }
                    }
                    
                    // Invisible anchor for auto-scroll
                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 8)
            }
            .onAppear {
                // Store proxy for keyboard handling
                interactionViewModel.setScrollProxy(proxy)
                // If messages are already loaded, scroll to bottom immediately
                if messageViewModel.messages.count > 0 {
                    interactionViewModel.scrollToBottomImmediately()
                }
            }
            .onChange(of: messageViewModel.messages.count) { _, _ in
                // Always scroll to bottom when messages are loaded
                if messageViewModel.messages.count > 0 {
                    interactionViewModel.handleInitialLoad()
                }
            }
            .onChange(of: interactionViewModel.isKeyboardVisible) { _, newValue in
                // Ensure latest message and status are visible when keyboard state changes
                if newValue {
                    // Keyboard appeared - scroll to bottom to keep latest message visible
                    interactionViewModel.scrollToBottom()
                }
            }
        }
    }
    
    // MARK: - Actions
    
    /// Handle send button tap with optimistic UI
    private func handleSend() {
        let text = interactionViewModel.handleSend()
        guard !text.isEmpty else { return }
        
        // Send message via view model
        Task {
            await messageViewModel.sendMessage(text: text)
                            // Scroll to bottom after adding message
            interactionViewModel.scrollToBottom()
        }
    }
    
    /// Handle image send using MessageService (PR #009)
    /// Accepts raw UIImage for optimal single-pass compression
    private func handleSendImage(_ image: UIImage) {
        Task {
            await messageViewModel.sendImageMessage(image)
                            // Scroll to bottom after adding message
            interactionViewModel.scrollToBottom()
        }
    }
    
    // MARK: - Contextual AI Actions (PR #006)
    
    /// Handle AI action selection
    private func handleAIAction(_ action: AIContextAction, for message: Message) {
        let senderName = messageViewModel.getSenderName(for: message) ?? "Client"
        
        Task {
            await contextualAIViewModel.performAction(
                action,
                on: message,
                in: chat.id,
                messages: messageViewModel.messages,
                senderName: senderName
            )
        }
    }
    
    /// Save reminder to Firestore
    private func handleSaveReminder(text: String, date: Date, sourceMessageID: String) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let reminder: [String: Any] = [
            "text": text,
            "reminderDate": Timestamp(date: date),
            "createdAt": FieldValue.serverTimestamp(),
            "completed": false,
            "sourceMessageID": sourceMessageID,
            "chatID": chat.id
        ]
        
        do {
            try await Firestore.firestore()
                .collection("users")
                .document(userId)
                .collection("reminders")
                .addDocument(data: reminder)
            
            // Dismiss the reminder sheet
            contextualAIViewModel.dismissResult()
            
        } catch {
            print("[ChatView] Error saving reminder: \(error.localizedDescription)")
            // Show error to user (could enhance with error state)
        }
    }
    
    // MARK: - AI Overlay Views (PR #006)
    
    /// Contextual menu overlay for a message
    private func contextualMenuOverlay(for message: Message) -> some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    showingMenuForMessageID = nil
                }
            
            // Contextual AI menu
            ContextualAIMenu(
                message: message,
                onActionSelected: { action in
                    showingMenuForMessageID = nil
                    handleAIAction(action, for: message)
                },
                onDismiss: {
                    showingMenuForMessageID = nil
                }
            )
            .padding()
        }
    }
}

// MARK: - AI Contextual Overlays View Modifier (PR #006)

extension View {
    /// Applies AI contextual action overlays, sheets, and alerts
    func aiContextualOverlays(
        viewModel: ContextualAIViewModel,
        onSaveReminder: @escaping (String, Date, String) async -> Void
    ) -> some View {
        self
            .overlay {
                if viewModel.isLoading {
                    AILoadingIndicator()
                }
            }
            .overlay {
                if let result = viewModel.currentResult,
                   case .relatedMessages(let messages) = result.result {
                    AIRelatedMessagesView(
                        relatedMessages: messages,
                        onMessageTap: nil,
                        onDismiss: {
                            viewModel.dismissResult()
                        }
                    )
                    .padding()
                }
            }
            .sheet(item: summaryBinding(for: viewModel)) { result in
                if case .summary(let text, let keyPoints) = result.result {
                    AISummaryView(
                        summary: text,
                        keyPoints: keyPoints,
                        onDismiss: {
                            viewModel.dismissResult()
                        }
                    )
                }
            }
            .sheet(item: reminderBinding(for: viewModel)) { result in
                if case .reminder(let suggestion) = result.result {
                    AIReminderSheet(
                        suggestion: suggestion,
                        onSave: { text, date in
                            Task {
                                await onSaveReminder(text, date, result.sourceMessageID)
                            }
                        },
                        onCancel: {
                            viewModel.dismissResult()
                        }
                    )
                }
            }
            .alert("AI Error", isPresented: errorBinding(for: viewModel)) {
                Button("Dismiss") {
                    viewModel.error = nil
                }
                if viewModel.error != .invalidRequest {
                    Button("Retry") {
                        Task {
                            await viewModel.retryLastAction()
                        }
                    }
                }
            } message: {
                Text(viewModel.error?.errorDescription ?? "Unknown error")
            }
    }
    
    /// Binding for summary sheet
    private func summaryBinding(for viewModel: ContextualAIViewModel) -> Binding<AIContextResult?> {
        Binding(
            get: {
                guard let result = viewModel.currentResult,
                      case .summary = result.result else { return nil }
                return result
            },
            set: { _ in viewModel.dismissResult() }
        )
    }
    
    /// Binding for reminder sheet
    private func reminderBinding(for viewModel: ContextualAIViewModel) -> Binding<AIContextResult?> {
        Binding(
            get: {
                guard let result = viewModel.currentResult,
                      case .reminder = result.result else { return nil }
                return result
            },
            set: { _ in viewModel.dismissResult() }
        )
    }
    
    /// Binding for error alert
    private func errorBinding(for viewModel: ContextualAIViewModel) -> Binding<Bool> {
        Binding(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )
    }
}

// MARK: - Preview

#Preview("With Messages") {
    NavigationView {
        ChatView(chat: Chat(
            id: "preview_chat",
            members: ["currentUser", "otherUser"],
            lastMessage: "Hey there!",
            lastMessageTimestamp: Date(),
            isGroupChat: false
        ))
    }
}

#Preview("Empty Chat") {
    NavigationView {
        ChatView(chat: Chat(
            id: "empty_chat",
            members: ["currentUser", "otherUser"],
            lastMessage: "",
            lastMessageTimestamp: Date(),
            isGroupChat: false
        ))
    }
    .onAppear {
        // Override to show empty state
    }
}
