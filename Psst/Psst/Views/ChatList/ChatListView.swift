//
//  ChatListView.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #6
//  Main conversation list screen with real-time updates
//

import SwiftUI
import FirebaseAuth

/// Main conversation list screen displaying all user chats
/// Shows chat previews sorted by most recent activity with real-time updates
struct ChatListView: View {
    // MARK: - State Management
    
    @StateObject private var viewModel = ChatListViewModel()
    @State private var showingNewChatView = false
    @State private var selectedChat: Chat?
    @State private var navigateToChat = false
    
    /// Notification service for deep linking
    @EnvironmentObject private var notificationService: NotificationService
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading && viewModel.chats.isEmpty {
                    // Loading state
                    ProgressView("Loading chats...")
                        .progressViewStyle(CircularProgressViewStyle())
                } else if viewModel.chats.isEmpty {
                    // Empty state
                    emptyStateView
                } else {
                    // Chat list
                    chatListView
                }
            }
            .navigationTitle("Messages")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingNewChatView = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingNewChatView) {
                UserSelectionView(onChatCreated: { chat in
                    // Store the chat and trigger immediate navigation
                    selectedChat = chat
                    navigateToChat = true
                    showingNewChatView = false
                })
            }
            .background(
                NavigationLink(
                    destination: selectedChat.map { ChatView(chat: $0) },
                    isActive: $navigateToChat
                ) {
                    EmptyView()
                }
                .hidden()
            )
            .onAppear {
                viewModel.observeChats()
            }
            .onDisappear {
                viewModel.stopObserving()
            }
            .onReceive(NotificationCenter.default.publisher(for: .userWillLogout)) { _ in
                // Cleanup Firestore listeners BEFORE auth token is invalidated
                print("[ChatListView] Received logout notification, cleaning up listeners...")
                viewModel.stopObserving()
            }
            .onChange(of: notificationService.deepLinkHandler.targetChatId) { oldChatId, newChatId in
                if let chatId = newChatId {
                    print("[ChatListView] 🧭 Deep link received for chat: \(chatId)")
                    
                    // Find the chat in the current list
                    if let chat = viewModel.chats.first(where: { $0.id == chatId }) {
                        selectedChat = chat
                        navigateToChat = true
                    } else {
                        print("[ChatListView] ❌ Chat not found in current list: \(chatId)")
                    }
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    /// Empty state view when no chats exist
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text("No conversations yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Tap the compose button above to start chatting")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    /// Chat list view with all conversations
    private var chatListView: some View {
        List {
            ForEach(viewModel.chats) { chat in
                NavigationLink(destination: ChatView(chat: chat)) {
                    ChatRowView(chat: chat)
                }
            }
        }
        .refreshable {
            // Pull to refresh triggers re-observation
            viewModel.observeChats()
        }
    }
}

// MARK: - Preview

#Preview {
    ChatListView()
}

