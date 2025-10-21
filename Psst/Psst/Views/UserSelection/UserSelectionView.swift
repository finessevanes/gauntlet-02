//
//  UserSelectionView.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #9
//  Main contact selection screen with search functionality
//

import SwiftUI
import FirebaseAuth

/// User selection screen for creating new chats
/// Displays all users with real-time search and handles chat creation
struct UserSelectionView: View {
    // MARK: - Properties
    
    /// Callback when a chat is created/found
    var onChatCreated: ((Chat) -> Void)?
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State Properties
    
    @State private var users: [User] = []
    @State private var searchQuery: String = ""
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?
    @State private var isCreatingChat: Bool = false
    @State private var showError: Bool = false
    
    // MARK: - Service Instances
    
    private let userService = UserService.shared
    private let chatService = ChatService()
    
    // MARK: - Computed Properties
    
    /// Filtered users based on search query, excluding current user
    private var filteredUsers: [User] {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return []
        }
        
        // Exclude current user
        let usersWithoutSelf = users.filter { $0.id != currentUserID }
        
        // Apply search filter if query is not empty
        if searchQuery.isEmpty {
            return usersWithoutSelf.sorted { $0.displayName.lowercased() < $1.displayName.lowercased() }
        } else {
            let query = searchQuery.lowercased()
            return usersWithoutSelf.filter { user in
                user.displayName.lowercased().contains(query) ||
                user.email.lowercased().contains(query)
            }.sorted { $0.displayName.lowercased() < $1.displayName.lowercased() }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                if isLoading {
                    // Loading state
                    loadingView
                } else if users.isEmpty {
                    // Empty state - no users in database
                    emptyStateView
                } else if filteredUsers.isEmpty {
                    // Empty state - no search results
                    noResultsView
                } else {
                    // User list
                    userListView
                }
            }
            .navigationTitle("New Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Text("\(filteredUsers.count) users")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .searchable(text: $searchQuery, prompt: "Search by name or email")
            .onAppear {
                Task {
                    await fetchUsers()
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
                Button("Retry") {
                    Task {
                        await fetchUsers()
                    }
                }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    /// Loading state view
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
            
            Text("Loading users...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    /// Empty state when no users exist in database
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text("No users found")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Invite friends to join Psst!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    /// Empty state when search returns no results
    private var noResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text("No results for '\(searchQuery)'")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Try searching for a different name or email")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    /// User list view with search results
    private var userListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filteredUsers) { user in
                    Button {
                        Task {
                            await createAndNavigateToChat(with: user)
                        }
                    } label: {
                        UserRow(user: user)
                            .padding(.horizontal)
                    }
                    .disabled(isCreatingChat)
                    .buttonStyle(PlainButtonStyle())
                    
                    Divider()
                        .padding(.leading, 76) // Align with text, not avatar
                }
            }
        }
        .overlay {
            if isCreatingChat {
                // Loading overlay during chat creation
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    
                    Text("Creating chat...")
                        .foregroundColor(.white)
                        .font(.subheadline)
                        .padding(.top, 8)
                }
            }
        }
    }
    
    // MARK: - Methods
    
    /// Fetch all users from Firestore
    private func fetchUsers() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedUsers = try await userService.fetchAllUsers()
            
            await MainActor.run {
                self.users = fetchedUsers
                self.isLoading = false
                print("✅ Loaded \(fetchedUsers.count) users")
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Unable to load users. Check your connection."
                self.showError = true
                self.isLoading = false
                print("❌ Error fetching users: \(error.localizedDescription)")
            }
        }
    }
    
    /// Create chat with selected user and navigate to ChatView
    /// - Parameter user: The user to create a chat with
    private func createAndNavigateToChat(with user: User) async {
        // Prevent multiple rapid taps
        guard !isCreatingChat else { return }
        
        await MainActor.run {
            isCreatingChat = true
            errorMessage = nil
        }
        
        do {
            // Create or get existing chat
            let chatID = try await chatService.createChat(withUserID: user.id)
            
            // Fetch the full chat object
            let chat = try await chatService.fetchChat(chatID: chatID)
            
            await MainActor.run {
                isCreatingChat = false
                
                print("✅ Chat created/found: \(chatID)")
                
                // Call callback and dismiss
                onChatCreated?(chat)
                dismiss()
            }
        } catch {
            await MainActor.run {
                isCreatingChat = false
                
                // Handle specific errors
                if let chatError = error as? ChatError {
                    switch chatError {
                    case .cannotChatWithSelf:
                        errorMessage = "You cannot create a chat with yourself"
                    case .notAuthenticated:
                        errorMessage = "Please log in to create chats"
                    case .invalidUserID:
                        errorMessage = "Invalid user selected"
                    case .firestoreError(let firestoreError):
                        errorMessage = "Failed to create chat: \(firestoreError.localizedDescription)"
                    }
                } else {
                    errorMessage = "Failed to create chat. Please try again."
                }
                
                showError = true
                print("❌ Error creating chat: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    UserSelectionView(onChatCreated: nil)
}

