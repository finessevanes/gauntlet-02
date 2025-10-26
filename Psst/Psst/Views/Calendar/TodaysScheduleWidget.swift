//
//  TodaysScheduleWidget.swift
//  Psst
//
//  Created for PR #010A: Calendar Foundation
//  Widget showing today's upcoming events on ChatListView
//

import SwiftUI

struct TodaysScheduleWidget: View {

    @ObservedObject var viewModel: CalendarViewModel
    @State private var isExpanded = true

    var body: some View {
        if !viewModel.todaysUpcomingEvents.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)

                    Text("Today's Schedule")
                        .font(.headline)
                        .fontWeight(.semibold)

                    Spacer()

                    // Event count badge
                    Text("\(viewModel.todaysEventCount)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .cornerRadius(12)

                    // Expand/collapse button
                    Button(action: {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))

                // Event list (collapsible)
                if isExpanded {
                    VStack(spacing: 0) {
                        ForEach(viewModel.todaysUpcomingEvents) { event in
                            Button(action: {
                                viewModel.selectEvent(event)
                            }) {
                                TodayEventRow(event: event)
                            }
                            .buttonStyle(PlainButtonStyle())

                            if event.id != viewModel.todaysUpcomingEvents.last?.id {
                                Divider()
                                    .padding(.leading, 56)
                            }
                        }
                    }
                    .background(Color.white)
                }
            }
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
}

// MARK: - Today Event Row Component

struct TodayEventRow: View {
    let event: CalendarEvent

    var body: some View {
        HStack(spacing: 12) {
            // Time
            VStack(alignment: .trailing, spacing: 2) {
                Text(formattedTime)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                if event.isNow {
                    Text("Now")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .cornerRadius(4)
                }
            }
            .frame(width: 60, alignment: .trailing)

            // Event type icon
            Text(event.eventTypeIcon)
                .font(.title3)

            // Event details
            VStack(alignment: .leading, spacing: 4) {
                Text(event.displayTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text("\(event.durationMinutes) min")
                        .font(.caption)

                    if let location = event.location, !location.isEmpty {
                        Text("•")
                            .font(.caption2)
                        Image(systemName: "location.fill")
                            .font(.caption2)
                        Text(location)
                            .font(.caption)
                            .lineLimit(1)
                    }
                }
                .foregroundColor(.secondary)
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(event.isNow ? Color.blue.opacity(0.05) : Color.clear)
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: event.startTime)
    }
}

// MARK: - Preview

struct TodaysScheduleWidget_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = CalendarViewModel()

        // Mock some events
        viewModel.events = [
            CalendarEvent(
                trainerId: "trainer1",
                eventType: .training,
                title: "Session with Sam",
                clientId: "client1",
                startTime: Date().addingTimeInterval(3600),
                endTime: Date().addingTimeInterval(7200),
                location: "Main Gym"
            ),
            CalendarEvent(
                trainerId: "trainer1",
                eventType: .call,
                title: "Call with John",
                clientId: "client2",
                startTime: Date().addingTimeInterval(10800),
                endTime: Date().addingTimeInterval(12600)
            ),
            CalendarEvent(
                trainerId: "trainer1",
                eventType: .adhoc,
                title: "Lunch Break",
                startTime: Date().addingTimeInterval(14400),
                endTime: Date().addingTimeInterval(18000)
            )
        ]

        return TodaysScheduleWidget(viewModel: viewModel)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
