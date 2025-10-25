//
//  ClientProfileDetailView.swift
//  Psst
//
//  Created by Caleb (Coder Agent) on 10/24/25.
//  PR #007: Contextual Intelligence (Auto Client Profiles)
//  Full profile modal with all categorized information
//

import SwiftUI

/// Full profile detail modal view
struct ClientProfileDetailView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: ClientProfileViewModel
    let clientId: String

    var body: some View {
        NavigationView {
            ScrollView {
                if viewModel.isLoading {
                    ProgressView("Loading profile...")
                        .padding()
                } else if let profile = viewModel.profile {
                    VStack(alignment: .leading, spacing: 20) {
                        // Show all categories with items using ForEach
                        ForEach(ProfileCategory.allCases, id: \.self) { category in
                            let items = profile.items(for: category).sorted { $0.timestamp > $1.timestamp }
                            if !items.isEmpty {
                                ProfileCategorySection(
                                    category: category,
                                    items: items,
                                    onDelete: { item in
                                        viewModel.deleteItem(itemId: item.id)
                                    }
                                )
                            }
                        }

                        // Empty state - show if no items across all categories
                        if profile.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "person.crop.circle.badge.questionmark")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary)

                                Text("No profile data yet")
                                    .font(.headline)

                                Text("As you chat, I'll remember important details automatically.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        }
                    }
                    .padding()
                } else {
                    // No profile found
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)

                        Text("No profile data yet")
                            .font(.headline)

                        Text("As you chat, I'll remember important details automatically.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            }
            .navigationTitle("Client Profile")
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
            viewModel.observeProfile(clientId: clientId)
        }
        .onDisappear {
            viewModel.stopObserving()
        }
    }
}

/// Category section with items
struct ProfileCategorySection: View {
    let category: ProfileCategory
    let items: [ProfileItem]
    let onDelete: (ProfileItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(category.icon)
                    .font(.title3)

                Text(category.displayName)
                    .font(.headline)

                Spacer()

                Text("\(items.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Items
            ForEach(items) { item in
                ProfileItemRow(item: item, onDelete: {
                    onDelete(item)
                })
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

/// Individual profile item row
struct ProfileItemRow: View {
    let item: ProfileItem
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.text)
                    .font(.body)

                HStack(spacing: 8) {
                    Text(item.relativeTimeString)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if item.isManuallyEdited {
                        Text("• Edited")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Confidence badge
                    if item.createdBy == .ai {
                        ConfidenceBadge(level: item.confidenceLevel)
                    }
                }
            }

            Spacer()

            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

/// Confidence level badge
struct ConfidenceBadge: View {
    let level: ConfidenceLevel

    var body: some View {
        Text(level.displayName)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(badgeColor)
            .foregroundColor(.white)
            .cornerRadius(4)
    }

    private var badgeColor: Color {
        switch level {
        case .high: return .green
        case .medium: return .orange
        case .low: return .red
        }
    }
}

#Preview {
    ClientProfileDetailView(
        viewModel: ClientProfileViewModel(),
        clientId: "test"
    )
}
