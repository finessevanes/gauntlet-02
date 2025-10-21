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
    
    // Group mode state
    @State private var isGroupMode: Bool = false
    @State private var selectedUserIDs: Set<String> = []
    @State private var showGroupNamingSheet: Bool = false
    @State private var groupName: String = ""
    
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
            VStack(spacing: 0) {
                // Mode toggle (1-on-1 vs Group)
                Picker("Chat Type", selection: $isGroupMode) {
                    Text("1-on-1").tag(false)
                    Text("Group").tag(true)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .onChange(of: isGroupMode) { _, _ in
                    // Clear selection when switching modes
                    selectedUserIDs.removeAll()
                }
                
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
                    if isGroupMode {
                        Text("\(selectedUserIDs.count) selected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(filteredUsers.count) users")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
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
            .sheet(isPresented: $showGroupNamingSheet) {
                GroupNamingView(
                    groupName: $groupName,
                    selectedUserIDs: Array(selectedUserIDs),
                    onCancel: {
                        showGroupNamingSheet = false
                        groupName = ""
                    },
                    onCreate: { name in
                        Task {
                            await createGroup(withName: name)
                        }
                    }
                )
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
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filteredUsers) { user in
                        Button {
                            if isGroupMode {
                                // Toggle selection in group mode
                                toggleUserSelection(user)
                            } else {
                                // Create 1-on-1 chat
                                Task {
                                    await createAndNavigateToChat(with: user)
                                }
                            }
                        } label: {
                            UserRow(
                                user: user,
                                showCheckbox: isGroupMode,
                                isSelected: selectedUserIDs.contains(user.id)
                            )
                            .padding(.horizontal)
                        }
                        .disabled(isCreatingChat)
                        .buttonStyle(PlainButtonStyle())
                        
                        Divider()
                            .padding(.leading, 76) // Align with text, not avatar
                    }
                }
            }
            
            // Create Group button (only visible in group mode)
            if isGroupMode {
                VStack(spacing: 8) {
                    // Validation hint
                    if selectedUserIDs.count < 2 {
                        Text("Select 2 or more members")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: {
                        showGroupNamingSheet = true
                    }) {
                        Text("Create Group")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedUserIDs.count >= 2 ? Color.blue : Color(.systemGray4))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(selectedUserIDs.count < 2)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                .background(Color(.systemBackground))
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
                    
                    Text(isGroupMode ? "Creating group..." : "Creating chat...")
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
                    case .invalidGroupName:
                        errorMessage = "Invalid group name"
                    case .insufficientMembers:
                        errorMessage = "Groups require at least 3 members"
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
    
    /// Toggle user selection in group mode
    /// - Parameter user: The user to toggle selection for
    private func toggleUserSelection(_ user: User) {
        if selectedUserIDs.contains(user.id) {
            selectedUserIDs.remove(user.id)
        } else {
            selectedUserIDs.insert(user.id)
        }
    }
    
    /// Create group chat with selected users
    /// - Parameter name: The group name
    private func createGroup(withName name: String) async {
        // Prevent multiple rapid taps
        guard !isCreatingChat else { return }
        
        await MainActor.run {
            isCreatingChat = true
            errorMessage = nil
            showGroupNamingSheet = false
        }
        
        do {
            // Create group chat
            let chatID = try await chatService.createGroupChat(
                withMembers: Array(selectedUserIDs),
                groupName: name
            )
            
            // Fetch the full chat object
            let chat = try await chatService.fetchChat(chatID: chatID)
            
            await MainActor.run {
                isCreatingChat = false
                
                print("✅ Group chat created: \(chatID)")
                
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
                    case .notAuthenticated:
                        errorMessage = "Please log in to create groups"
                    case .invalidGroupName:
                        errorMessage = "Group name must be 1-50 characters"
                    case .insufficientMembers:
                        errorMessage = "Groups require at least 3 members"
                    case .firestoreError(let firestoreError):
                        errorMessage = "Failed to create group: \(firestoreError.localizedDescription)"
                    default:
                        errorMessage = "Failed to create group. Please try again."
                    }
                } else {
                    errorMessage = "Failed to create group. Please try again."
                }
                
                showError = true
                print("❌ Error creating group: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    UserSelectionView(onChatCreated: nil)
}

