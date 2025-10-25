//
//  ActionConfirmationCard.swift
//  Psst
//
//  Created by AI Assistant for PR #008 - AI Function Calling
//

import SwiftUI

/// Confirmation card for AI function calls
/// Shows action details with confirm/cancel/edit options
struct ActionConfirmationCard: View {
    let action: PendingAction
    let isExecuting: Bool
    let onConfirm: () -> Void
    let onCancel: () -> Void
    let onEdit: () -> Void

    @State private var showEditSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: functionIcon)
                    .foregroundColor(.blue)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 4) {
                    Text("I'd like to:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(functionTitle)
                        .font(.headline)
                }

                Spacer()
            }

            // Parameters
            VStack(alignment: .leading, spacing: 8) {
                ForEach(action.getFormattedParameters(), id: \.0) { param in
                    HStack(alignment: .top, spacing: 8) {
                        Text(param.0 + ":")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(width: 90, alignment: .leading)

                        Text(param.1)
                            .font(.subheadline)
                            .foregroundColor(.primary)

                        Spacer()
                    }
                }
            }
            .padding(.vertical, 8)

            // Action buttons
            HStack(spacing: 12) {
                // Cancel button
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .disabled(isExecuting)

                // Edit button
                Button(action: {
                    showEditSheet = true
                }) {
                    Text("Edit")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                .disabled(isExecuting)

                // Confirm button
                Button(action: onConfirm) {
                    HStack(spacing: 4) {
                        if isExecuting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text(isExecuting ? "Executing..." : "Confirm")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(isExecuting ? Color.blue.opacity(0.6) : Color.blue)
                    .cornerRadius(8)
                }
                .disabled(isExecuting)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 20, y: 10)
        .padding(.horizontal, 20)
        .sheet(isPresented: $showEditSheet) {
            ActionEditSheet(action: action, onSave: onEdit)
        }
    }

    // Function-specific icon
    private var functionIcon: String {
        switch action.functionName {
        case "scheduleCall":
            return "calendar.badge.plus"
        case "setReminder":
            return "bell.badge.fill"
        case "sendMessage":
            return "paperplane.fill"
        case "searchMessages":
            return "magnifyingglass"
        default:
            return "bolt.fill"
        }
    }

    // Function-specific title
    private var functionTitle: String {
        switch action.functionName {
        case "scheduleCall":
            return "Schedule Call"
        case "setReminder":
            return "Set Reminder"
        case "sendMessage":
            return "Send Message"
        case "searchMessages":
            return "Search Messages"
        default:
            return action.functionName
        }
    }
}

/// Edit sheet for action parameters (simplified version)
struct ActionEditSheet: View {
    let action: PendingAction
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Edit Action")
                    .font(.headline)

                Text("Editing parameters is coming soon.")
                    .foregroundColor(.secondary)

                Spacer()

                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Preview

struct ActionConfirmationCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()

            ActionConfirmationCard(
                action: PendingAction(
                    functionName: "scheduleCall",
                    parameters: [
                        "clientName": "Mike Johnson",
                        "dateTime": "2024-10-25T14:00:00Z",
                        "duration": 30
                    ]
                ),
                isExecuting: false,
                onConfirm: {},
                onCancel: {},
                onEdit: {}
            )

            Spacer()
        }
        .background(Color(.systemGroupedBackground))
    }
}
