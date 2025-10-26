//
//  CustomChatHeader.swift
//  Psst
//
//  Custom chat header that renders as part of view content (not toolbar)
//  This prevents the pop-in issue by rendering synchronously with the view
//

import SwiftUI

/// Custom header for chat view that displays user info without toolbar delays
struct CustomChatHeader: View {
    let otherUser: User?
    let isOnline: Bool

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Back button (left side)
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.blue)
                }
                Spacer()
            }

            // Centered user info
            HStack(spacing: 8) {
                // Profile photo with presence halo
                ZStack {
                    ProfilePhotoPreview(
                        imageURL: otherUser?.photoURL,
                        userID: otherUser?.id,
                        selectedImage: nil,
                        isLoading: false,
                        size: 40
                    )

                    // Green presence halo (only when online)
                    PresenceHalo(isOnline: isOnline, size: 40)
                }

                // User info
                VStack(alignment: .leading, spacing: 2) {
                    Text(otherUser?.displayName ?? "Chat")
                        .font(.headline)
                    Text(isOnline ? "Online" : "Offline")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .overlay(
            // Bottom divider
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
}

#Preview {
    CustomChatHeader(
        otherUser: User(
            id: "preview",
            email: "test@example.com",
            displayName: "John Doe",
            role: .client,
            photoURL: nil,
            createdAt: Date(),
            updatedAt: Date()
        ),
        isOnline: true
    )
}
