//
//  CustomGroupChatHeader.swift
//  Psst
//
//  Custom group chat header that renders as part of view content (not toolbar)
//  This prevents the pop-in issue by rendering synchronously with the view
//

import SwiftUI

/// Custom header for group chat view that displays group info without toolbar delays
struct CustomGroupChatHeader: View {
    let groupName: String
    let groupMembers: [User]
    let onTapMembers: () -> Void

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

            // Centered group info
            Button(action: onTapMembers) {
                VStack(spacing: 4) {
                    // Group name
                    Text(groupName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    // Member photos row (first 3-5 members)
                    HStack(spacing: -8) {
                        ForEach(Array(groupMembers.prefix(5).enumerated()), id: \.element.id) { index, member in
                            ProfilePhotoWithPresence(
                                userID: member.id,
                                photoURL: member.photoURL,
                                displayName: member.displayName,
                                size: 24
                            )
                            .zIndex(Double(5 - index)) // Stack from left to right
                        }

                        // Show "+X more" if there are more members
                        if groupMembers.count > 5 {
                            Text("+\(groupMembers.count - 5)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
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
    CustomGroupChatHeader(
        groupName: "Team Chat",
        groupMembers: [
            User(
                id: "user1",
                email: "user1@example.com",
                displayName: "John Doe",
                role: .client,
                photoURL: nil,
                createdAt: Date(),
                updatedAt: Date()
            ),
            User(
                id: "user2",
                email: "user2@example.com",
                displayName: "Jane Smith",
                role: .client,
                photoURL: nil,
                createdAt: Date(),
                updatedAt: Date()
            ),
            User(
                id: "user3",
                email: "user3@example.com",
                displayName: "Bob Johnson",
                role: .trainer,
                photoURL: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
        ],
        onTapMembers: {}
    )
}
