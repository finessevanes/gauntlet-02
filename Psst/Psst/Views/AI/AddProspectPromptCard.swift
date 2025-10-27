//
//  AddProspectPromptCard.swift
//  Psst
//
//  Created for PR #010B: AI Scheduling + Conflict Detection
//  Prompt card for adding unknown clients as prospects
//

import SwiftUI

struct AddProspectPromptCard: View {
    // MARK: - Properties

    let clientName: String
    let onAddProspect: () -> Void
    let onCancel: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "person.crop.circle.badge.questionmark")
                    .foregroundColor(.blue)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Client Not Found")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Add as a prospect?")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            Divider()

            // Explanation
            VStack(alignment: .leading, spacing: 8) {
                Text("I don't see **\(clientName)** in your contacts.")
                    .font(.subheadline)
                    .foregroundColor(.primary)

                Text("Would you like to add them as a prospect? You can upgrade them to a client later when they join.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Action Buttons
            HStack(spacing: 12) {
                Button(action: onCancel) {
                    Text("No, cancel")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }

                Button(action: onAddProspect) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.crop.circle.badge.plus")
                        Text("Add prospect")
                    }
                    .font(.body.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        AddProspectPromptCard(
            clientName: "Sarah Williams",
            onAddProspect: {
                print("Adding Sarah as prospect")
            },
            onCancel: {
                print("Cancelled")
            }
        )

        AddProspectPromptCard(
            clientName: "John Smith",
            onAddProspect: {
                print("Adding John as prospect")
            },
            onCancel: {
                print("Cancelled")
            }
        )
    }
    .padding()
}
