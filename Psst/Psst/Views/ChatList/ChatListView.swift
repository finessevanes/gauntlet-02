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
    
    // DEBUG: Mock data controls
    #if DEBUG
    @State private var showMockDataAlert = false
    @State private var mockDataMessage = ""
    #endif
    
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
                #if DEBUG
                ToolbarItem(placement: .navigationBarTrailing) {
                    debugToolbarButton
                }
                #endif
            }
            .onAppear {
                viewModel.observeChats()
            }
            .onDisappear {
                viewModel.stopObserving()
            }
            #if DEBUG
            .alert("Mock Data", isPresented: $showMockDataAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(mockDataMessage)
            }
            #endif
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
            
            Text("Tap the + button to start chatting")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            #if DEBUG
            Text("💡 Tap the hammer icon above to seed test data")
                .font(.caption)
                .foregroundColor(.blue)
                .padding(.top, 20)
            #endif
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
    
    // MARK: - DEBUG Toolbar
    
    #if DEBUG
    /// Debug toolbar button for seeding/clearing test data
    private var debugToolbarButton: some View {
        Menu {
            Button {
                Task {
                    await seedMockData()
                }
            } label: {
                Label("Seed Mock Data", systemImage: "plus.circle")
            }
            
            Button(role: .destructive) {
                Task {
                    await clearMockData()
                }
            } label: {
                Label("Clear Mock Data", systemImage: "trash")
            }
        } label: {
            Image(systemName: "hammer.fill")
                .foregroundColor(.blue)
        }
    }
    
    /// Seed mock data using MockDataService
    private func seedMockData() async {
        guard let userID = Auth.auth().currentUser?.uid else {
            mockDataMessage = "❌ Error: User not authenticated"
            showMockDataAlert = true
            return
        }
        
        do {
            try await MockDataService().seedMockData(currentUserID: userID)
            mockDataMessage = "✅ Mock data seeded successfully!\n\n3 chats created:\n• Bob Smith (5m ago)\n• Group Chat (1h ago)\n• Alice Johnson (2h ago)"
            showMockDataAlert = true
            print("✅ Mock data seeded successfully")
        } catch {
            mockDataMessage = "❌ Error seeding data:\n\(error.localizedDescription)"
            showMockDataAlert = true
            print("❌ Error seeding mock data: \(error)")
        }
    }
    
    /// Clear all mock data
    private func clearMockData() async {
        do {
            try await MockDataService().clearMockData()
            mockDataMessage = "✅ Mock data cleared successfully!"
            showMockDataAlert = true
            print("✅ Mock data cleared")
        } catch {
            mockDataMessage = "❌ Error clearing data:\n\(error.localizedDescription)"
            showMockDataAlert = true
            print("❌ Error clearing mock data: \(error)")
        }
    }
    #endif
}

// MARK: - Preview

#Preview {
    ChatListView()
}

