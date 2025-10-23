//
//  GroupMemberStatusView.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #004
//  Full member list view showing all group chat participants with online status
//  Displays sortable list with online members first, updates in real-time
//

import SwiftUI
import FirebaseAuth

/// Full-screen member list for group chats showing all participants with online status
/// Automatically observes presence for all members and sorts by online status
/// Displays profile photos, names, and online indicators with real-time updates
struct GroupMemberStatusView: View {
    // MARK: - Properties
    
    /// The chat whose members to display
    let chat: Chat
    
    /// Presence tracker ViewModel
    @StateObject private var presenceTracker = GroupPresenceTracker()
    
    /// Loaded member User objects
    @State private var members: [User] = []
    
    /// Loading state
    @State private var isLoading: Bool = true
    
    /// Error message (if any)
    @State private var errorMessage: String?
    
    /// User service for fetching member profiles
    private let userService = UserService.shared
    
    /// Environment dismiss action
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Computed Properties
    
    /// Members sorted by online status (online first), then alphabetically
    private var sortedMembers: [User] {
        members.sorted { user1, user2 in
            let user1Online = presenceTracker.memberPresences[user1.id] ?? false
            let user2Online = presenceTracker.memberPresences[user2.id] ?? false
            
            // Online users first
            if user1Online != user2Online {
                return user1Online && !user2Online
            }
            
            // Then alphabetically by display name
            return user1.displayName < user2.displayName
        }
    }
    
    /// Online members only
    private var onlineMembers: [User] {
        sortedMembers.filter { presenceTracker.memberPresences[$0.id] ?? false }
    }
    
    /// Offline members only
    private var offlineMembers: [User] {
        sortedMembers.filter { !(presenceTracker.memberPresences[$0.id] ?? false) }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    loadingView
                } else if let error = errorMessage {
                    errorView(message: error)
                } else {
                    memberListView
                }
            }
            .navigationTitle(chat.groupName ?? "Group Members")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadMembers()
        }
        .onDisappear {
            presenceTracker.cleanup()
        }
    }
    
    // MARK: - Subviews
    
    /// Loading state view
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading members...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    /// Error state view
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            Text("Error")
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Retry") {
                loadMembers()
            }
            .buttonStyle(.bordered)
        }
    }
    
    /// Member list view with sections
    private var memberListView: some View {
        List {
            // Show sections for large groups (>10 members)
            if members.count > 10 {
                // Online section
                if !onlineMembers.isEmpty {
                    Section(header: Text("Online (\(onlineMembers.count))")) {
                        ForEach(onlineMembers) { member in
                            memberRow(member)
                        }
                    }
                }
                
                // Offline section
                if !offlineMembers.isEmpty {
                    Section(header: Text("Offline (\(offlineMembers.count))")) {
                        ForEach(offlineMembers) { member in
                            memberRow(member)
                        }
                    }
                }
            } else {
                // No sections for small groups - just show sorted list
                ForEach(sortedMembers) { member in
                    memberRow(member)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    /// Individual member row
    private func memberRow(_ member: User) -> some View {
        HStack(spacing: 12) {
            // Profile photo with online indicator
            ProfilePhotoWithPresence(
                userID: member.id,
                photoURL: member.photoURL,
                displayName: member.displayName,
                size: 50
            )
            
            // Member info
            VStack(alignment: .leading, spacing: 4) {
                Text(member.displayName)
                    .font(.headline)
                
                Text(member.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Online status text
            if let isOnline = presenceTracker.memberPresences[member.id] {
                Text(isOnline ? "Online" : "Offline")
                    .font(.caption)
                    .foregroundColor(isOnline ? .green : .secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Private Methods
    
    /// Load member User objects from UserService
    private func loadMembers() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Fetch User objects for all member IDs
                var loadedMembers: [User] = []
                
                for memberID in chat.members {
                    do {
                        let user = try await userService.getUser(id: memberID)
                        loadedMembers.append(user)
                    } catch {
                        print("⚠️ Failed to load member \(memberID): \(error.localizedDescription)")
                        // Continue loading other members even if one fails
                    }
                }
                
                // Update UI on main thread
                await MainActor.run {
                    self.members = loadedMembers
                    self.isLoading = false
                    
                    // Start observing presence for all loaded members
                    presenceTracker.observeMembers(userIDs: loadedMembers.map { $0.id })
                }
                
            } catch {
                // Handle overall error
                await MainActor.run {
                    self.errorMessage = "Failed to load members: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - GroupPresenceTracker ViewModel

/// ViewModel for tracking group presence
/// Manages Firebase listeners and aggregates online status for all group members
class GroupPresenceTracker: ObservableObject {
    /// Map of userID to online status
    @Published var memberPresences: [String: Bool] = [:]
    
    /// Map of userID to listenerID for cleanup
    private var listeners: [String: UUID] = [:]
    
    /// Presence service for Firebase listeners
    private let presenceService = PresenceService()
    
    /// Observe presence for multiple members
    /// - Parameter userIDs: Array of user IDs to track
    func observeMembers(userIDs: [String]) {
        // Clean up existing listeners first
        cleanup()
        
        // Observe each member's presence
        listeners = presenceService.observeGroupPresence(userIDs: userIDs) { [weak self] userID, isOnline in
            DispatchQueue.main.async {
                self?.memberPresences[userID] = isOnline
            }
        }
    }
    
    /// Clean up all presence listeners
    func cleanup() {
        guard !listeners.isEmpty else { return }
        
        presenceService.stopObservingGroup(listeners: listeners)
        listeners.removeAll()
        memberPresences.removeAll()
    }
    
    deinit {
        cleanup()
    }
}

// MARK: - SwiftUI Preview

#Preview("Group Members") {
    GroupMemberStatusView(chat: Chat(
        id: "preview_group",
        members: ["user1", "user2", "user3", "user4", "user5"],
        isGroupChat: true,
        groupName: "Team Chat"
    ))
    .environmentObject(PresenceService())
}

