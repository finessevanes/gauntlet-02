//
//  EventConfirmationCard.swift
//  Psst
//
//  Created for PR #010B: AI Scheduling + Conflict Detection
//  Inline card for confirming AI-suggested calendar events
//

import SwiftUI

struct EventConfirmationCard: View {
    // MARK: - Properties

    let eventType: CalendarEvent.EventType
    let clientName: String
    let startTime: Date
    let duration: Int
    let location: String?
    let notes: String?

    let onConfirm: () -> Void
    let onCancel: () -> Void

    // MARK: - Computed Properties

    private var eventIcon: String {
        switch eventType {
        case .training: return "🏋️"
        case .call: return "📞"
        case .adhoc: return "📅"
        }
    }

    private var eventTypeText: String {
        switch eventType {
        case .training: return "Training Session"
        case .call: return "Call"
        case .adhoc: return "Appointment"
        }
    }

    private var eventColor: Color {
        switch eventType {
        case .training: return .blue
        case .call: return .green
        case .adhoc: return .gray
        }
    }

    private var formattedDateTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: startTime)
    }

    private var endTime: Date {
        startTime.addingTimeInterval(TimeInterval(duration * 60))
    }

    private var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Text(eventIcon)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Schedule Event")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(eventTypeText)
                        .font(.headline)
                        .foregroundColor(eventColor)
                }

                Spacer()
            }

            Divider()

            // Event Details
            VStack(alignment: .leading, spacing: 8) {
                EventDetailRow(label: "Client", value: clientName)
                EventDetailRow(label: "Date", value: formattedDateTime)
                EventDetailRow(label: "Time", value: formattedTimeRange)
                EventDetailRow(label: "Duration", value: "\(duration) minutes")

                if let location = location {
                    EventDetailRow(label: "Location", value: location)
                }

                if let notes = notes {
                    EventDetailRow(label: "Notes", value: notes)
                }
            }

            // Action Buttons
            HStack(spacing: 12) {
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }

                Button(action: onConfirm) {
                    Text("Confirm")
                        .font(.body.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(eventColor)
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

// MARK: - Event Detail Row Component

private struct EventDetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label + ":")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)

            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Training Session
        EventConfirmationCard(
            eventType: .training,
            clientName: "Sam Johnson",
            startTime: Date().addingTimeInterval(86400), // Tomorrow
            duration: 60,
            location: "Main Gym",
            notes: "Focus on upper body",
            onConfirm: { print("Confirmed training") },
            onCancel: { print("Cancelled") }
        )

        // Call
        EventConfirmationCard(
            eventType: .call,
            clientName: "Sarah Williams",
            startTime: Date().addingTimeInterval(3600), // 1 hour from now
            duration: 30,
            location: nil,
            notes: nil,
            onConfirm: { print("Confirmed call") },
            onCancel: { print("Cancelled") }
        )
    }
    .padding()
}
