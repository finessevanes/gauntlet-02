//
//  EventDetailView.swift
//  Psst
//
//  Created for PR #010A: Calendar Foundation
//  Detail view for viewing/editing/deleting calendar events
//

import SwiftUI

struct EventDetailView: View {

    let eventId: String
    @ObservedObject var viewModel: CalendarViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false

    /// Get the latest version of the event from ViewModel
    private var event: CalendarEvent? {
        viewModel.events.first(where: { $0.id == eventId })
    }

    var body: some View {
        if let event = event {
            content(for: event)
        } else {
            Text("Event not found")
                .navigationTitle("Event Details")
        }
    }

    @ViewBuilder
    private func content(for event: CalendarEvent) -> some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Event type header with color
                    HStack {
                        Text(event.eventTypeIcon)
                            .font(.largeTitle)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.displayTitle)
                                .font(.title2)
                                .fontWeight(.bold)

                            Text(eventTypeLabel(for: event))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding()
                    .background(event.eventTypeColor.opacity(0.2))
                    .cornerRadius(12)

                    // Event details
                    VStack(alignment: .leading, spacing: 16) {
                        // Date and time
                        DetailRow(icon: "calendar", title: "Date", value: formattedDate(for: event))
                        DetailRow(icon: "clock", title: "Time", value: event.formattedTimeRange)
                        DetailRow(icon: "hourglass", title: "Duration", value: "\(event.durationMinutes) minutes")

                        // Location
                        if let location = event.location, !location.isEmpty {
                            DetailRow(icon: "location.fill", title: "Location", value: location)
                        }

                        // Notes
                        if let notes = event.notes, !notes.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Notes", systemImage: "note.text")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                Text(notes)
                                    .font(.body)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }

                        // Status
                        DetailRow(icon: "checkmark.circle", title: "Status", value: event.status.rawValue.capitalized)

                        // Created by
                        DetailRow(icon: "person.fill", title: "Created by", value: event.createdBy.capitalized)
                    }
                    .padding(.horizontal)

                    // Action buttons
                    VStack(spacing: 12) {
                        // Edit button
                        Button(action: {
                            showEditSheet = true
                        }) {
                            HStack {
                                Image(systemName: "pencil")
                                Text("Edit Event")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                        }

                        // Delete button
                        Button(action: {
                            showDeleteAlert = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Event")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(10)
                        }

                        // Mark completed (if not already)
                        if event.status == .scheduled {
                            Button(action: {
                                Task {
                                    await viewModel.markEventCompleted(eventId: event.id)
                                    dismiss()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Mark Completed")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                }
                .padding(.vertical)
            }
            .navigationTitle("Event Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert("Delete Event", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task {
                        await viewModel.deleteEvent(eventId: event.id)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this event? This action cannot be undone.")
            }
            .sheet(isPresented: $showEditSheet) {
                EventEditSheet(event: event, viewModel: viewModel)
            }
        }
    }

    // MARK: - Helper Methods

    private func eventTypeLabel(for event: CalendarEvent) -> String {
        switch event.eventType {
        case .training: return "Training Session"
        case .call: return "Call"
        case .adhoc: return "Personal Event"
        }
    }

    private func formattedDate(for event: CalendarEvent) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: event.startTime)
    }
}

// MARK: - Detail Row Component

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
            }

            Spacer()
        }
    }
}

// MARK: - Preview

struct EventDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = CalendarViewModel()
        let mockEvent = CalendarEvent(
            id: "preview-1",
            trainerId: "trainer1",
            eventType: .training,
            title: "Session with Sam",
            clientId: "client1",
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600),
            location: "Main Gym",
            notes: "Focus on upper body strength training"
        )
        viewModel.events = [mockEvent]

        return EventDetailView(
            eventId: "preview-1",
            viewModel: viewModel
        )
    }
}
