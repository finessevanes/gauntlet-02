//
//  ContactsView.swift
//  Psst
//
//  Created for PR #009: Trainer-Client Relationship System
//  Main contact management screen
//

import SwiftUI

struct ContactsView: View {

    // MARK: - Properties

    @StateObject private var viewModel = ContactsViewModel()
    @State private var showAddClientSheet = false
    @State private var showAddProspectSheet = false
    @State private var showSuccessToast = false
    @State private var showErrorToast = false

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                // Main content
                contentView

                // Success toast (top)
                if showSuccessToast, let message = viewModel.successMessage {
                    VStack {
                        HStack {
                            Text(message)
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding()
                        }
                        .background(Color.green)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .padding(.horizontal)
                        .transition(.move(edge: .top).combined(with: .opacity))

                        Spacer()
                    }
                    .padding(.top, 60)
                    .zIndex(1)
                }

                // Error toast (top)
                if showErrorToast, let message = viewModel.errorMessage {
                    VStack {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                            Text(message)
                                .font(.subheadline)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .padding(.horizontal)
                        .transition(.move(edge: .top).combined(with: .opacity))

                        Spacer()
                    }
                    .padding(.top, 60)
                    .zIndex(1)
                }
            }
            .navigationTitle("Contacts")
            .toolbar {
                // Only show "Add" button for trainers
                if viewModel.currentUserRole == .trainer {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button {
                                showAddClientSheet = true
                            } label: {
                                Label("Add Client", systemImage: "person.badge.plus")
                            }

                            Button {
                                showAddProspectSheet = true
                            } label: {
                                Label("Add Prospect", systemImage: "person.badge.clock")
                            }
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddClientSheet) {
                AddClientView(viewModel: viewModel)
            }
            .sheet(isPresented: $showAddProspectSheet) {
                AddProspectView(viewModel: viewModel)
            }
            .onChange(of: viewModel.successMessage) { newValue in
                if newValue != nil {
                    withAnimation {
                        showSuccessToast = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            showSuccessToast = false
                            viewModel.clearMessages()
                        }
                    }
                }
            }
            .onChange(of: viewModel.errorMessage) { newValue in
                if newValue != nil {
                    withAnimation {
                        showErrorToast = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                        withAnimation {
                            showErrorToast = false
                            viewModel.clearMessages()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading {
            // Loading state
            ProgressView("Loading contacts...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            if viewModel.currentUserRole == .client {
                // CLIENT VIEW: Show trainers only
                clientContactsView
            } else {
                // TRAINER VIEW: Show clients and prospects
                trainerContactsView
            }
        }
    }

    // MARK: - Client View (Trainers and Peer Clients)

    @ViewBuilder
    private var clientContactsView: some View {
        List {
            // Trainers section
            Section {
                if viewModel.filteredTrainers.isEmpty {
                    Text("No trainers assigned yet.")
                        .foregroundColor(.secondary)
                        .italic()
                        .padding(.vertical, 8)
                } else {
                    ForEach(viewModel.filteredTrainers) { trainer in
                        TrainerRowView(trainer: trainer)
                    }
                }
            } header: {
                HStack {
                    Text("MY TRAINERS")
                    Spacer()
                    Text("(\(viewModel.filteredTrainers.count))")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            // Peer Clients section (other clients in group chats)
            if !viewModel.peerClients.isEmpty {
                Section {
                    ForEach(viewModel.filteredPeerClients) { peerClient in
                        PeerClientRowView(peerClient: peerClient)
                    }
                } header: {
                    HStack {
                        Text("GROUP MEMBERS")
                        Spacer()
                        Text("(\(viewModel.filteredPeerClients.count))")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                } footer: {
                    Text("Other clients you share group chats with")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .searchable(text: $viewModel.searchQuery, prompt: "Search contacts")
        .refreshable {
            await viewModel.loadContacts()
        }
        .onAppear {
            Task {
                await viewModel.loadContactsOnAppear()
            }
        }
    }

    // MARK: - Trainer View (Clients and Prospects)

    @ViewBuilder
    private var trainerContactsView: some View {
        List {
            // Clients section
            Section {
                if viewModel.filteredClients.isEmpty {
                    Text("No clients yet. Add your first client to get started.")
                        .foregroundColor(.secondary)
                        .italic()
                        .padding(.vertical, 8)
                } else {
                    ForEach(viewModel.filteredClients) { client in
                        ClientRowView(client: client, viewModel: viewModel)
                    }
                }
            } header: {
                HStack {
                    Text("MY CLIENTS")
                    Spacer()
                    Text("(\(viewModel.filteredClients.count))")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            // Prospects section
            Section {
                if viewModel.filteredProspects.isEmpty {
                    Text("No prospects yet. Add prospects to track leads.")
                        .foregroundColor(.secondary)
                        .italic()
                        .padding(.vertical, 8)
                } else {
                    ForEach(viewModel.filteredProspects) { prospect in
                        ProspectRowView(prospect: prospect, viewModel: viewModel)
                    }
                }
            } header: {
                HStack {
                    Text("PROSPECTS")
                    Spacer()
                    Text("(\(viewModel.filteredProspects.count))")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .searchable(text: $viewModel.searchQuery, prompt: "Search contacts")
        .refreshable {
            await viewModel.loadContacts()
        }
        .onAppear {
            Task {
                await viewModel.loadContactsOnAppear()
            }
        }
    }
}

// MARK: - Trainer Row View (for clients)

struct TrainerRowView: View {
    let trainer: User

    var body: some View {
        HStack(spacing: 12) {
            // Avatar with profile photo
            ProfilePhotoPreview(
                imageURL: trainer.photoURL,
                userID: trainer.id,
                selectedImage: nil,
                isLoading: false,
                size: 44,
                displayName: trainer.displayName
            )

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(trainer.displayName)
                    .font(.headline)

                Text(trainer.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Peer Client Row View (for clients viewing other clients in group chats)

struct PeerClientRowView: View {
    let peerClient: User

    var body: some View {
        HStack(spacing: 12) {
            // Avatar with profile photo
            ProfilePhotoPreview(
                imageURL: peerClient.photoURL,
                userID: peerClient.id,
                selectedImage: nil,
                isLoading: false,
                size: 44,
                displayName: peerClient.displayName
            )

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(peerClient.displayName)
                    .font(.headline)

                Text(peerClient.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Client Row View

struct ClientRowView: View {
    let client: Client
    @ObservedObject var viewModel: ContactsViewModel
    @State private var showConfirmDelete = false

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(client.displayName.prefix(1).uppercased())
                        .font(.headline)
                        .foregroundColor(.blue)
                )

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(client.displayName)
                    .font(.headline)

                Text("Added \(timeAgo(client.addedAt))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                showConfirmDelete = true
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
        .confirmationDialog("Remove Client", isPresented: $showConfirmDelete) {
            Button("Remove", role: .destructive) {
                Task {
                    await viewModel.removeClient(clientId: client.id)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Remove \(client.displayName) from your client list? They will no longer be able to message you.")
        }
    }
}

// MARK: - Prospect Row View

struct ProspectRowView: View {
    let prospect: Prospect
    @ObservedObject var viewModel: ContactsViewModel
    @State private var showConfirmDelete = false
    @State private var showUpgradeSheet = false

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(prospect.displayName.prefix(1).uppercased())
                        .font(.headline)
                        .foregroundColor(.gray)
                )

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(prospect.displayName)
                        .font(.headline)

                    // Prospect badge
                    Text("👤 Prospect")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                }

                Text("Added \(timeAgo(prospect.addedAt))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                showConfirmDelete = true
            } label: {
                Label("Delete", systemImage: "trash")
            }

            Button {
                showUpgradeSheet = true
            } label: {
                Label("Upgrade", systemImage: "arrow.up.circle")
            }
            .tint(.blue)
        }
        .confirmationDialog("Delete Prospect", isPresented: $showConfirmDelete) {
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteProspect(prospectId: prospect.id)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Delete \(prospect.displayName) from your prospects?")
        }
        .sheet(isPresented: $showUpgradeSheet) {
            UpgradeProspectView(prospect: prospect, viewModel: viewModel)
        }
    }
}

// MARK: - Helper Functions

private func timeAgo(_ date: Date) -> String {
    let now = Date()
    let components = Calendar.current.dateComponents([.day, .hour, .minute], from: date, to: now)

    if let days = components.day, days > 0 {
        return days == 1 ? "1 day ago" : "\(days) days ago"
    } else if let hours = components.hour, hours > 0 {
        return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
    } else if let minutes = components.minute, minutes > 0 {
        return minutes == 1 ? "1 minute ago" : "\(minutes) minutes ago"
    } else {
        return "Just now"
    }
}

// MARK: - Preview

struct ContactsView_Previews: PreviewProvider {
    static var previews: some View {
        ContactsView()
    }
}
