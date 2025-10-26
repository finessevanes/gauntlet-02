//
//  ConflictWarningCard.swift
//  Psst
//
//  Created for PR #010B: AI Scheduling + Conflict Detection
//  Warning card shown when scheduling conflict is detected
//

import SwiftUI

struct ConflictWarningCard: View {
    // MARK: - Properties

    let conflictingEvent: CalendarEvent
    let suggestedTimes: [Date]
    let requestedDuration: Int

    let onSelectTime: (Date) -> Void
    let onCancel: () -> Void

    // MARK: - State

    @State private var selectedSuggestionIndex: Int? = nil

    // MARK: - Computed Properties

    private var formattedConflictTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: conflictingEvent.startTime)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Warning Header
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Scheduling Conflict")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("You already have an event at this time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            // Conflicting Event Details
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(conflictingEvent.eventTypeIcon)
                        .font(.body)

                    Text(conflictingEvent.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                }

                Text(formattedConflictTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .padding(.horizontal, 16)

            // Suggested Times
            VStack(alignment: .leading, spacing: 12) {
                Text("Suggested times:")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)

                VStack(spacing: 8) {
                    ForEach(Array(suggestedTimes.enumerated()), id: \.offset) { index, suggestedTime in
                        AlternativeTimeButton(
                            date: suggestedTime,
                            duration: requestedDuration,
                            isSelected: selectedSuggestionIndex == index,
                            onTap: {
                                selectedSuggestionIndex = index
                                onSelectTime(suggestedTime)
                            }
                        )
                    }
                }
            }
            .padding(.horizontal, 16)

            // Cancel Button
            Button(action: onCancel) {
                Text("Cancel")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.orange.opacity(0.3), lineWidth: 2)
                )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        ConflictWarningCard(
            conflictingEvent: CalendarEvent(
                trainerId: "trainer123",
                eventType: .training,
                title: "Session with Sam Johnson",
                clientId: "client123",
                startTime: Date(),
                endTime: Date().addingTimeInterval(3600)
            ),
            suggestedTimes: [
                Date().addingTimeInterval(7200),    // 2 hours later
                Date().addingTimeInterval(10800),   // 3 hours later
                Date().addingTimeInterval(90000)    // Tomorrow
            ],
            requestedDuration: 60,
            onSelectTime: { time in
                print("Selected time: \(time)")
            },
            onCancel: {
                print("Cancelled")
            }
        )
    }
    .padding()
}
