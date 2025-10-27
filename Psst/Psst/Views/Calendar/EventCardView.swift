//
//  EventCardView.swift
//  Psst
//
//  Created for PR #010A: Calendar Foundation
//  Event card displayed in calendar timeline
//

import SwiftUI

struct EventCardView: View {

    let event: CalendarEvent
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                // Event type icon and time
                HStack {
                    Text(event.eventTypeIcon)
                        .font(.caption)

                    Text(event.formattedStartTime)
                        .font(.caption2)
                        .fontWeight(.medium)

                    Spacer()

                    // Duration
                    Text("\(event.durationMinutes)min")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                }

                // Event title
                Text(event.displayTitle)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // Location if present
                if let location = event.location, !location.isEmpty {
                    HStack(spacing: 2) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 8))
                        Text(location)
                            .font(.system(size: 9))
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
            }
            .foregroundColor(.white)
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(event.eventTypeColor)
            .cornerRadius(6)
            .opacity(event.status == .cancelled ? 0.5 : 1.0)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(event.isNow ? Color.white : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

struct EventCardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 12) {
            // Training event
            EventCardView(event: CalendarEvent(
                trainerId: "trainer1",
                eventType: .training,
                title: "Session with Sam",
                clientId: "client1",
                startTime: Date(),
                endTime: Date().addingTimeInterval(3600),
                location: "Main Gym"
            ), onTap: {})

            // Call event
            EventCardView(event: CalendarEvent(
                trainerId: "trainer1",
                eventType: .call,
                title: "Call with John",
                clientId: "client2",
                startTime: Date().addingTimeInterval(3600),
                endTime: Date().addingTimeInterval(5400)
            ), onTap: {})

            // Adhoc event
            EventCardView(event: CalendarEvent(
                trainerId: "trainer1",
                eventType: .adhoc,
                title: "Doctor Appointment",
                startTime: Date().addingTimeInterval(7200),
                endTime: Date().addingTimeInterval(9000),
                location: "Medical Center"
            ), onTap: {})
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
