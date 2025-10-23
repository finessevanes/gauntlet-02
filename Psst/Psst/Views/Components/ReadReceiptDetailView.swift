//
//  ReadReceiptDetailView.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #5
//  Modal sheet showing detailed read receipt information for group messages
//

import SwiftUI

/// Modal view displaying detailed read receipt information
/// Shows which members have read a message and which haven't
/// Only used in group chats (3+ members)
struct ReadReceiptDetailView: View {
    // MARK: - Properties
    
    /// The message to show read receipt details for
    let message: Message
    
    /// The chat containing this message
    let chat: Chat
    
    /// Environment dismiss action
    @Environment(\.dismiss) var dismiss
    
    /// ViewModel managing state and data fetching
    @StateObject private var viewModel = ReadReceiptDetailViewModel()
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    loadingView
                } else if let errorMessage = viewModel.errorMessage {
                    errorView(message: errorMessage)
                } else {
                    contentView
                }
            }
            .navigationTitle("Read By")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .task {
            // Load read receipts when view appears
            viewModel.loadReadReceipts(for: message, in: chat)
        }
    }
    
    // MARK: - Subviews
    
    /// Main content view showing read/unread sections
    private var contentView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                // Subtitle showing count
                subtitleView
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                
                // Read section
                if !readDetails.isEmpty {
                    readSection
                }
                
                // Not Read Yet section
                if !unreadDetails.isEmpty {
                    notReadSection
                }
            }
        }
    }
    
    /// Subtitle showing read count
    private var subtitleView: some View {
        Text(subtitleText)
            .font(.subheadline)
            .foregroundColor(.secondary)
    }
    
    /// Subtitle text based on read status
    private var subtitleText: String {
        let readCount = readDetails.count
        let totalCount = viewModel.details.count
        
        if readCount == totalCount {
            return "All members"
        } else {
            return "\(readCount) of \(totalCount) members"
        }
    }
    
    /// Read section showing members who have read the message
    private var readSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            Text("Read")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal)
                .padding(.vertical, 12)
            
            // Member rows
            ForEach(readDetails) { detail in
                ReadReceiptMemberRow(detail: detail)
                    .padding(.horizontal)
                
                if detail.id != readDetails.last?.id {
                    Divider()
                        .padding(.leading, 64)
                }
            }
            
            // Spacer before next section
            if !unreadDetails.isEmpty {
                Divider()
                    .padding(.top, 8)
            }
        }
    }
    
    /// Not Read Yet section showing members who haven't read the message
    private var notReadSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            Text("Not Read Yet")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.vertical, 12)
            
            // Member rows
            ForEach(unreadDetails) { detail in
                ReadReceiptMemberRow(detail: detail)
                    .padding(.horizontal)
                
                if detail.id != unreadDetails.last?.id {
                    Divider()
                        .padding(.leading, 64)
                }
            }
        }
    }
    
    /// Loading view with skeleton placeholders
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading read receipts...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    /// Error view with retry button
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button(action: {
                viewModel.retry()
            }) {
                Text("Retry")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// Members who have read the message (sorted alphabetically)
    private var readDetails: [ReadReceiptDetail] {
        viewModel.details.filter { $0.hasRead }
    }
    
    /// Members who haven't read the message (sorted alphabetically)
    private var unreadDetails: [ReadReceiptDetail] {
        viewModel.details.filter { !$0.hasRead }
    }
}

// MARK: - Preview

#Preview("Partial Read") {
    ReadReceiptDetailView(
        message: Message(
            id: "msg1",
            text: "Hey team!",
            senderID: "currentUser",
            readBy: ["user2", "user3"]
        ),
        chat: Chat(
            id: "chat1",
            members: ["currentUser", "user2", "user3", "user4", "user5"],
            isGroupChat: true,
            groupName: "Team Chat"
        )
    )
}

#Preview("All Read") {
    ReadReceiptDetailView(
        message: Message(
            id: "msg2",
            text: "Meeting at 3pm",
            senderID: "currentUser",
            readBy: ["user2", "user3", "user4"]
        ),
        chat: Chat(
            id: "chat2",
            members: ["currentUser", "user2", "user3", "user4"],
            isGroupChat: true,
            groupName: "Project Team"
        )
    )
}

#Preview("None Read") {
    ReadReceiptDetailView(
        message: Message(
            id: "msg3",
            text: "Important announcement",
            senderID: "currentUser",
            readBy: []
        ),
        chat: Chat(
            id: "chat3",
            members: ["currentUser", "user2", "user3"],
            isGroupChat: true,
            groupName: "Announcements"
        )
    )
}

