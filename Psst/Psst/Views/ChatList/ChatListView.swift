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
    @State private var showingAIAssistant = false
    @State private var showingProfile = false

    /// Navigation path for programmatic navigation control
    @State private var navigationPath = NavigationPath()

    /// Notification service for deep linking
    @EnvironmentObject private var notificationService: NotificationService

    /// Auth view model for current user
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
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
            .navigationDestination(for: Chat.self) { chat in
                ChatView(chat: chat)
            }
            .toolbar {
                // User avatar on left - taps to open Profile view
                ToolbarItem(placement: .navigationBarLeading) {
                    if let user = authViewModel.currentUser {
                        Button {
                            showingProfile = true
                        } label: {
                            ProfilePhotoPreview(
                                imageURL: user.photoURL,
                                userID: user.id,
                                selectedImage: nil,
                                isLoading: false,
                                size: 32
                            )
                        }
                    }
                }
            }
            .sheet(isPresented: $showingNewChatView) {
                UserSelectionView(onChatCreated: { chat in
                    // Navigate to the newly created chat
                    navigationPath.append(chat)
                    showingNewChatView = false
                })
            }
            .sheet(isPresented: $showingAIAssistant) {
                AIAssistantView()
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView()
            }
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
                        // Navigate to the chat via path
                        navigationPath.append(chat)
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
                NavigationLink(value: chat) {
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
    ChatListView()
        .environmentObject(AuthViewModel())
}

