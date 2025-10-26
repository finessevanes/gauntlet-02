//
//  UserSelectionView.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #9
//  Updated by Caleb (Coder Agent) - PR #006E
//  New Chat sheet with redesigned UI/UX: search at top, checkmarks, auto-navigation
//

import SwiftUI
import FirebaseAuth

/// User selection screen for creating new chats
/// Displays all users with search at top, selection checkmarks, and smart 1-on-1 auto-navigation
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
    
    // Chat type state (1-on-1 vs Group)
    @State private var chatType: ChatType = .oneOnOne
    @State private var selectedUserIDs: Set<String> = []
    @State private var showGroupNamingSheet: Bool = false
    @State private var groupName: String = ""
    
    // MARK: - Chat Type Enum
    
    enum ChatType: String, CaseIterable {
        case oneOnOne = "1-on-1"
        case group = "Group"
    }
    
    // MARK: - Service Instances

    private let userService = UserService.shared
    private let chatService = ChatService()
    private let contactService = ContactService.shared
    
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
                // Segmented Control (1-on-1 vs Group)
                Picker("Chat Type", selection: $chatType) {
                    ForEach(ChatType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 12)
                .onChange(of: chatType) { _, _ in
                    // Clear selection when switching modes
                    selectedUserIDs.removeAll()
                }
                
                // Search Bar (NEW: Moved to top, below segmented control)
                searchBarView
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                
                // Content (Loading, Empty, or User List)
                ZStack {
                    if isLoading {
                        loadingView
                    } else if users.isEmpty {
                        emptyStateView
                    } else if filteredUsers.isEmpty {
                        noResultsView
                    } else {
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
                
                // Done button (only in Group mode with 2+ users selected)
                if chatType == .group && selectedUserIDs.count >= 2 {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showGroupNamingSheet = true
                        }
                        .fontWeight(.bold)
                    }
                }
            }
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
    
    /// Custom search bar at top (NEW: Moved from bottom to top)
    private var searchBarView: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.body)
            
            TextField("Search by name or email", text: $searchQuery)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
            
            if !searchQuery.isEmpty {
                Button(action: {
                    searchQuery = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.body)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
    
    /// Loading state view with skeleton rows
    private var loadingView: some View {
        VStack(spacing: 16) {
            ForEach(0..<5, id: \.self) { _ in
                HStack(spacing: 16) {
                    // Skeleton avatar
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 56, height: 56)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        // Skeleton name
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .frame(height: 16)
                        
                        // Skeleton email
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray6))
                            .frame(height: 12)
                            .frame(maxWidth: 200)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.top, 16)
    }
    
    /// Empty state when no users exist in database
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3")
                .font(.system(size: 96))
                .foregroundColor(.gray)
            
            Text("No users available")
                .font(.title3)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// Empty state when search returns no results
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 96))
                .foregroundColor(.gray)
            
            Text("No results for '\(searchQuery)'")
                .font(.title3)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// User list view with section header and redesigned rows
    private var userListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Section header with user count (NEW: Moved from nav bar)
                HStack {
                    Text("\(filteredUsers.count) People")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
                // User rows
                ForEach(filteredUsers) { user in
                    Button(action: {
                        handleUserTap(user)
                    }) {
                        RedesignedUserRow(
                            user: user,
                            isSelected: selectedUserIDs.contains(user.id)
                        )
                    }
                    .buttonStyle(UserRowButtonStyle())
                    
                    if user.id != filteredUsers.last?.id {
                        Divider()
                            .padding(.leading, 72) // After 56pt avatar + 16pt spacing
                    }
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
                    
                    Text(chatType == .group ? "Creating group..." : "Creating chat...")
                        .foregroundColor(.white)
                        .font(.subheadline)
                        .padding(.top, 8)
                }
            }
        }
    }
    
    // MARK: - Methods
    
    /// Handle user tap with haptic feedback and smart behavior based on chat type
    /// 1-on-1 mode: Auto-navigate to chat immediately
    /// Group mode: Toggle selection with checkmark animation
    private func handleUserTap(_ user: User) {
        // Haptic feedback on tap
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        if chatType == .oneOnOne {
            // 1-on-1 mode: Auto-navigate to chat (NEW BEHAVIOR)
            Task {
                await createAndNavigateToChat(with: user)
            }
        } else {
            // Group mode: Toggle selection with animation
            withAnimation(.easeInOut(duration: 0.2)) {
                toggleUserSelection(user)
            }
        }
    }
    
    /// Fetch users based on current user's role and relationships
    /// - Clients: Show their assigned trainer(s) AND peer clients from group chats
    /// - Trainers: Only see their clients
    private func fetchUsers() async {
        isLoading = true
        errorMessage = nil

        do {
            // Get current user's profile to check role
            let currentUser = try await userService.getCurrentUserProfile()

            let fetchedUsers: [User]

            if currentUser.role == .client {
                // CLIENT: Show both trainers AND peer clients from group chats
                async let trainersTask = contactService.getMyTrainers()
                async let peerClientsTask = contactService.getPeerClients()

                let trainers = try await trainersTask
                let peerClients = try await peerClientsTask

                // Combine trainers and peer clients, removing duplicates
                var allUsers: [User] = trainers
                for peerClient in peerClients {
                    if !allUsers.contains(where: { $0.id == peerClient.id }) {
                        allUsers.append(peerClient)
                    }
                }

                fetchedUsers = allUsers
                print("✅ [CLIENT] Loaded \(trainers.count) trainer(s) and \(peerClients.count) peer client(s)")
            } else {
                // TRAINER: Only show their clients
                let clients = try await contactService.getClients()

                // Convert Client objects to User objects
                var clientUsers: [User] = []
                for client in clients {
                    if let user = try? await userService.getUser(id: client.id) {
                        clientUsers.append(user)
                    }
                }

                fetchedUsers = clientUsers
                print("✅ [TRAINER] Loaded \(fetchedUsers.count) client(s)")
            }

            await MainActor.run {
                self.users = fetchedUsers
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Unable to load contacts. Check your connection."
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
                    case .relationshipNotFound:
                        errorMessage = "This trainer hasn't added you as a client yet"
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
                    case .cannotChatWithSelf:
                        errorMessage = "You cannot create a group with yourself"
                    case .invalidUserID:
                        errorMessage = "Invalid user selected"
                    case .relationshipNotFound:
                        errorMessage = "This trainer hasn't added you as a client yet"
                    case .firestoreError(let firestoreError):
                        errorMessage = "Failed to create group: \(firestoreError.localizedDescription)"
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

// MARK: - Redesigned User Row Component

/// Redesigned user row with 56pt avatar, larger spacing, and checkmark selection
struct RedesignedUserRow: View {
    let user: User
    let isSelected: Bool
    
    @State private var isUserOnline: Bool = false
    @State private var presenceListenerID: UUID? = nil
    
    @EnvironmentObject private var presenceService: PresenceService
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar with online status (56pt - larger than before)
            ZStack(alignment: .bottomTrailing) {
                ProfilePhotoPreview(
                    imageURL: user.photoURL,
                    userID: user.id,
                    selectedImage: nil,
                    isLoading: false,
                    size: 56,
                    displayName: user.displayName
                )
                
                // Green presence halo (online status indicator)
                PresenceHalo(isOnline: isUserOnline, size: 56)
                    .animation(.easeInOut(duration: 0.2), value: isUserOnline)
            }
            
            // User info
            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayName)
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Checkmark (NEW: Blue filled circle instead of checkbox)
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .onAppear {
            attachPresenceListener()
        }
        .onDisappear {
            detachPresenceListener()
        }
    }
    
    // MARK: - Presence Methods
    
    private func attachPresenceListener() {
        presenceListenerID = presenceService.observePresence(userID: user.id) { isOnline in
            DispatchQueue.main.async {
                self.isUserOnline = isOnline
            }
        }
    }
    
    private func detachPresenceListener() {
        guard let listenerID = presenceListenerID else { return }
        presenceService.stopObserving(userID: user.id, listenerID: listenerID)
        presenceListenerID = nil
    }
}

// MARK: - Custom Button Style for User Rows

/// Custom button style for user rows with scale and background animations
struct UserRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color(.systemGray6) : Color(.systemBackground))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    UserSelectionView(onChatCreated: nil)
}

