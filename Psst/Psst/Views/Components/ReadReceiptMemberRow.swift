//
//  ReadReceiptMemberRow.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #5
//  Individual row component for displaying a member's read receipt status
//

import SwiftUI

/// Row view displaying a single member's read receipt status
/// Shows profile photo, name, and checkmark (if read)
struct ReadReceiptMemberRow: View {
    // MARK: - Properties
    
    /// Read receipt detail containing user info and read status
    let detail: ReadReceiptDetail
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile photo (40pt circular)
            profilePhoto
            
            // Member name
            Text(detail.userName)
                .font(.body)
                .foregroundColor(detail.hasRead ? .primary : .secondary)
            
            Spacer()
            
            // Checkmark for read members
            if detail.hasRead {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 20))
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Subviews
    
    /// Profile photo with fallback to initials
    private var profilePhoto: some View {
        ProfilePhotoPreview(
            imageURL: detail.userPhotoURL,
            userID: detail.userID,
            selectedImage: nil,
            isLoading: false,
            size: 40,
            displayName: detail.userName
        )
    }
}

// MARK: - Preview

#Preview("Read Member") {
    ReadReceiptMemberRow(
        detail: ReadReceiptDetail(
            id: "user1",
            userID: "user1",
            userName: "Alice Johnson",
            userPhotoURL: nil,
            hasRead: true
        )
    )
    .padding()
}

#Preview("Unread Member") {
    ReadReceiptMemberRow(
        detail: ReadReceiptDetail(
            id: "user2",
            userID: "user2",
            userName: "Bob Smith",
            userPhotoURL: nil,
            hasRead: false
        )
    )
    .padding()
}

#Preview("With Photo URL") {
    ReadReceiptMemberRow(
        detail: ReadReceiptDetail(
            id: "user3",
            userID: "user3",
            userName: "Carol Williams",
            userPhotoURL: "https://example.com/photo.jpg",
            hasRead: true
        )
    )
    .padding()
}

