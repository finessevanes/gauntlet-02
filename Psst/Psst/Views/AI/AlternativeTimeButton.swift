//
//  AlternativeTimeButton.swift
//  Psst
//
//  Created for PR #010B: AI Scheduling + Conflict Detection
//  Button for selecting alternative time slots
//

import SwiftUI

struct AlternativeTimeButton: View {
    // MARK: - Properties

    let date: Date
    let duration: Int
    let isSelected: Bool
    let onTap: () -> Void

    // MARK: - Computed Properties

    private var formattedDate: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            formatter.dateFormat = "h:mm a"
            return "Today at " + formatter.string(from: date)
        } else if calendar.isDateInTomorrow(date) {
            formatter.dateFormat = "h:mm a"
            return "Tomorrow at " + formatter.string(from: date)
        } else {
            formatter.dateFormat = "EEE, MMM d 'at' h:mm a"
            return formatter.string(from: date)
        }
    }

    private var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short

        let endTime = date.addingTimeInterval(TimeInterval(duration * 60))
        return "\(formatter.string(from: date)) - \(formatter.string(from: endTime))"
    }

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Time Icon
                Image(systemName: isSelected ? "checkmark.circle.fill" : "clock")
                    .foregroundColor(isSelected ? .green : .blue)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 4) {
                    Text(formattedDate)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)

                    Text("\(duration) min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                        .font(.body.weight(.semibold))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.green.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(isSelected ? Color.green : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        AlternativeTimeButton(
            date: Date().addingTimeInterval(3600),
            duration: 60,
            isSelected: false,
            onTap: { print("Tapped 1 hour from now") }
        )

        AlternativeTimeButton(
            date: Date().addingTimeInterval(86400),
            duration: 60,
            isSelected: true,
            onTap: { print("Tapped tomorrow") }
        )

        AlternativeTimeButton(
            date: Date().addingTimeInterval(172800),
            duration: 30,
            isSelected: false,
            onTap: { print("Tapped 2 days from now") }
        )
    }
    .padding()
}
