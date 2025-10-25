//
//  ClientProfileBannerView.swift
//  Psst
//
//  Created by Caleb (Coder Agent) on 10/24/25.
//  PR #007: Contextual Intelligence (Auto Client Profiles)
//  Condensed profile header displayed in conversation
//

import SwiftUI

/// Condensed profile banner shown at top of conversation
struct ClientProfileBannerView: View {
    let profile: ClientProfile?
    let onTapViewFull: () -> Void

    var body: some View {
        if let profile = profile, !profile.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                // Top items (max 5)
                ForEach(profile.topItems(limit: 5)) { item in
                    HStack(spacing: 6) {
                        Text(item.category.icon)
                            .font(.caption)

                        Text(item.text)
                            .font(.caption)
                            .lineLimit(1)

                        Spacer()

                        Text(item.relativeTimeString)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                // View Full Profile button
                Button(action: onTapViewFull) {
                    HStack {
                        Text("View Full Profile")
                            .font(.caption)
                            .bold()

                        Image(systemName: "chevron.right")
                            .font(.caption2)
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(.blue)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            .padding(.horizontal)
            .padding(.top, 8)
        } else {
            // Empty state
            VStack(spacing: 4) {
                Text("No profile data yet")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("As you chat, I'll remember important details automatically")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }
}

#Preview {
    ClientProfileBannerView(
        profile: ClientProfile(
            id: "test",
            clientId: "test",
            trainerId: "test",
            injuries: [ProfileItem(text: "Shoulder pain", category: .injuries, sourceMessageId: "test", sourceChatId: "test", createdBy: .ai)],
            goals: [ProfileItem(text: "Lose 20 lbs", category: .goals, sourceMessageId: "test", sourceChatId: "test", createdBy: .ai)],
            totalItems: 2
        ),
        onTapViewFull: {}
    )
}
