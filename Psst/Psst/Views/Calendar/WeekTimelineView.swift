//
//  WeekTimelineView.swift
//  Psst
//
//  Created for PR #010A: Calendar Foundation
//  Week timeline grid showing events in time slots
//

import SwiftUI

struct WeekTimelineView: View {

    @ObservedObject var viewModel: CalendarViewModel
    let weekStart: Date

    private let hourHeight: CGFloat = 60
    private let startHour = 6 // 6am
    private let endHour = 22 // 10pm
    private let daysInWeek = 7

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            HStack(spacing: 0) {
                // Time labels column
                VStack(spacing: 0) {
                    // Header spacer
                    Text("")
                        .frame(height: 44)

                    ForEach(startHour..<endHour, id: \.self) { hour in
                        Text(formatHour(hour))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 50, height: hourHeight, alignment: .top)
                    }
                }

                // Days columns
                ForEach(0..<daysInWeek, id: \.self) { dayIndex in
                    let date = Calendar.current.date(byAdding: .day, value: dayIndex, to: weekStart)!
                    DayColumn(
                        date: date,
                        events: eventsForDay(date),
                        hourHeight: hourHeight,
                        startHour: startHour,
                        endHour: endHour,
                        isToday: isToday(date),
                        onEventTap: { event in
                            viewModel.selectEvent(event)
                        }
                    )
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func eventsForDay(_ date: Date) -> [CalendarEvent] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

        return viewModel.currentWeekEvents.filter { event in
            event.startTime >= dayStart && event.startTime < dayEnd
        }
        .sorted { $0.startTime < $1.startTime }
    }

    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"

        var components = DateComponents()
        components.hour = hour
        components.minute = 0

        let date = Calendar.current.date(from: components) ?? Date()
        return formatter.string(from: date)
    }
}

// MARK: - Day Column Component

struct DayColumn: View {
    let date: Date
    let events: [CalendarEvent]
    let hourHeight: CGFloat
    let startHour: Int
    let endHour: Int
    let isToday: Bool
    let onEventTap: (CalendarEvent) -> Void

    private let columnWidth: CGFloat = 120

    var body: some View {
        VStack(spacing: 0) {
            // Day header
            VStack(spacing: 4) {
                Text(dayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isToday ? .blue : .primary)

                Text("\(dayNumber)")
                    .font(.title3)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundColor(isToday ? .white : .primary)
                    .frame(width: 32, height: 32)
                    .background(isToday ? Color.blue : Color.clear)
                    .cornerRadius(16)
            }
            .frame(height: 44)

            // Timeline grid
            ZStack(alignment: .topLeading) {
                // Grid lines
                VStack(spacing: 0) {
                    ForEach(startHour..<endHour, id: \.self) { _ in
                        Rectangle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                            .frame(height: hourHeight)
                    }
                }

                // Current time indicator (only for today)
                if isToday {
                    GeometryReader { geometry in
                        if let yPosition = currentTimeYPosition() {
                            CurrentTimeIndicatorView()
                                .offset(y: yPosition)
                        }
                    }
                }

                // Event cards
                ForEach(events) { event in
                    EventCardView(event: event) {
                        onEventTap(event)
                    }
                    .frame(width: columnWidth - 8)
                    .offset(y: yPositionForEvent(event))
                    .frame(height: heightForEvent(event))
                    .padding(.horizontal, 4)
                }
            }
        }
        .frame(width: columnWidth)
        .background(isToday ? Color.blue.opacity(0.05) : Color.clear)
    }

    // MARK: - Computed Properties

    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private var dayNumber: Int {
        Calendar.current.component(.day, from: date)
    }

    // MARK: - Positioning Helpers

    private func yPositionForEvent(_ event: CalendarEvent) -> CGFloat {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: event.startTime)
        let minute = calendar.component(.minute, from: event.startTime)

        // Calculate hours from start hour
        let hoursFromStart = Double(hour - startHour)
        let minuteFraction = Double(minute) / 60.0

        return CGFloat((hoursFromStart + minuteFraction) * Double(hourHeight))
    }

    private func heightForEvent(_ event: CalendarEvent) -> CGFloat {
        let durationMinutes = event.durationMinutes
        let hours = Double(durationMinutes) / 60.0
        return CGFloat(hours * Double(hourHeight))
    }

    private func currentTimeYPosition() -> CGFloat? {
        let now = Date()
        let calendar = Calendar.current

        // Only show if current time is within our hour range
        let currentHour = calendar.component(.hour, from: now)
        guard currentHour >= startHour && currentHour < endHour else {
            return nil
        }

        let minute = calendar.component(.minute, from: now)
        let hoursFromStart = Double(currentHour - startHour)
        let minuteFraction = Double(minute) / 60.0

        return CGFloat((hoursFromStart + minuteFraction) * Double(hourHeight))
    }
}

// MARK: - Preview

struct WeekTimelineView_Previews: PreviewProvider {
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
                location: "Main Gym"
            ),
            CalendarEvent(
                trainerId: "trainer1",
                eventType: .call,
                title: "Call with John",
                clientId: "client2",
                startTime: Date().addingTimeInterval(7200),
                endTime: Date().addingTimeInterval(9000)
            )
        ]

        return WeekTimelineView(viewModel: viewModel, weekStart: viewModel.currentWeekStart)
            .previewLayout(.sizeThatFits)
    }
}
