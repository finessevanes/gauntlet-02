//
//  VerticalAgendaView.swift
//  Psst
//
//  Created for PR #010A: Calendar Foundation
//  Vertical agenda view showing upcoming events chronologically
//

import SwiftUI

struct VerticalAgendaView: View {

    @ObservedObject var viewModel: CalendarViewModel

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Group events by day
                ForEach(groupedEvents, id: \.date) { group in
                    VStack(alignment: .leading, spacing: 0) {
                        // Day header
                        DayHeaderView(date: group.date)
                            .padding(.top, 16)
                            .padding(.horizontal, 16)

                        // Events for this day
                        ForEach(group.events) { event in
                            EventRowView(event: event) {
                                viewModel.selectEvent(event)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }

                        // Divider between days
                        Divider()
                            .padding(.top, 8)
                    }
                }
            }
            .padding(.bottom, 80) // Space for FAB
        }
        .refreshable {
            await viewModel.loadEvents()
        }
    }

    // MARK: - Computed Properties

    /// Group events by day, sorted chronologically
    private var groupedEvents: [DayGroup] {
        let calendar = Calendar.current
        let now = Date()

        // Filter to only show upcoming and ongoing events (exclude cancelled)
        let upcomingEvents = viewModel.events.filter { event in
            event.endTime >= now && event.status != .cancelled
        }
        .sorted { $0.startTime < $1.startTime }

        // Group by day
        var groups: [Date: [CalendarEvent]] = [:]

        for event in upcomingEvents {
            let dayStart = calendar.startOfDay(for: event.startTime)

            if groups[dayStart] == nil {
                groups[dayStart] = []
            }
            groups[dayStart]?.append(event)
        }

        // Convert to array and sort by date
        return groups.map { date, events in
            DayGroup(date: date, events: events.sorted { $0.startTime < $1.startTime })
        }
        .sorted { $0.date < $1.date }
    }
}

// MARK: - Day Group Model

struct DayGroup {
    let date: Date
    let events: [CalendarEvent]
}

// MARK: - Day Header View

struct DayHeaderView: View {
    let date: Date

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(dayName)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(isToday ? .blue : .primary)

            Text(formattedDate)
                .font(.subheadline)
                .foregroundColor(.secondary)

            if isToday {
                Text("Today")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .cornerRadius(8)
            }

            Spacer()
        }
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE" // Full day name
        return formatter.string(from: date)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Event Row View

struct EventRowView: View {
    let event: CalendarEvent
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Time column
                VStack(alignment: .trailing, spacing: 2) {
                    Text(startTimeFormatted)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text(durationFormatted)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(width: 60)

                // Event card
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        // Event type icon
                        Text(event.eventTypeIcon)
                            .font(.title3)

                        // Title
                        Text(event.title)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Spacer()

                        // Status indicator
                        if event.isNow {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                        }
                    }

                    // Details row
                    HStack(spacing: 8) {
                        if let location = event.location, !location.isEmpty {
                            Label(location, systemImage: "location.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }

                        if event.notes != nil {
                            Image(systemName: "note.text")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(event.isNow ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(event.isNow ? Color.green : event.eventTypeColor.opacity(0.3), lineWidth: 2)
                )
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var startTimeFormatted: String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current  // Explicitly use local timezone
        formatter.timeStyle = .short
        return formatter.string(from: event.startTime)
    }

    private var durationFormatted: String {
        let minutes = event.durationMinutes
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h \(remainingMinutes)m"
            }
        }
    }
}

// MARK: - Preview

struct VerticalAgendaView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = CalendarViewModel()

        // Mock some events
        viewModel.events = [
            CalendarEvent(
                trainerId: "trainer1",
                eventType: .training,
                title: "Session with Sam",
                clientId: "client1",
                startTime: Date(),
                endTime: Date().addingTimeInterval(3600),
                location: "Main Gym",
                notes: "Focus on upper body"
            ),
            CalendarEvent(
                trainerId: "trainer1",
                eventType: .call,
                title: "Call with John",
                clientId: "client2",
                startTime: Date().addingTimeInterval(7200),
                endTime: Date().addingTimeInterval(9000)
            ),
            CalendarEvent(
                trainerId: "trainer1",
                eventType: .adhoc,
                title: "Meal Prep",
                startTime: Calendar.current.date(byAdding: .day, value: 1, to: Date())!,
                endTime: Calendar.current.date(byAdding: .day, value: 1, to: Date())!.addingTimeInterval(3600)
            )
        ]

        return VerticalAgendaView(viewModel: viewModel)
    }
}
