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
    @State private var showingAIAssistant = false
    
    /// Notification service for deep linking
    @EnvironmentObject private var notificationService: NotificationService
    
    /// Auth view model for current user
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    /// Selected tab binding for navigation
    @Binding var selectedTab: Int
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                // Main content
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
                
                // Floating Buttons - positioned bottom-right
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 16) {
                            // AI Assistant Button
                            FloatingAIButton {
                                showingAIAssistant = true
                            }
                            
                            // New Chat Button
                            FloatingActionButton {
                                showingNewChatView = true
                            }
                        }
                        .padding(.trailing, 16)
                        .padding(.bottom, 16)
                    }
                }
            }
            .navigationTitle("Messages")
            .toolbar {
                // User avatar on left - taps to navigate to Profile tab
                ToolbarItem(placement: .navigationBarLeading) {
                    if let user = authViewModel.currentUser {
                        Button {
                            selectedTab = 1 // Navigate to Profile tab
                        } label: {
                            ProfilePhotoPreview(
                                imageURL: user.photoURL,
                                userID: user.id,
                                selectedImage: nil,
                                isLoading: false,
                                size: 32,
                                displayName: user.displayName
                            )
                        }
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
            .sheet(isPresented: $showingAIAssistant) {
                AIAssistantView()
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
            Image(systemName: "message")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text("No conversations yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Tap + to start messaging")
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
        .listStyle(.plain)
        .padding(.bottom, 72) // Prevent FAB from overlapping last chat row
        .refreshable {
            // Pull to refresh triggers re-observation
            viewModel.observeChats()
        }
    }
}

// MARK: - Preview

#Preview {
    ChatListView(selectedTab: .constant(0))
        .environmentObject(AuthViewModel())
}

