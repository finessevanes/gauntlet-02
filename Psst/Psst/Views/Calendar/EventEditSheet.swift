//
//  EventEditSheet.swift
//  Psst
//
//  Created for PR #010A: Calendar Foundation
//  Form for editing existing calendar events
//

import SwiftUI
import FirebaseFirestore

struct EventEditSheet: View {

    let event: CalendarEvent
    @ObservedObject var viewModel: CalendarViewModel
    @Environment(\.dismiss) var dismiss

    @State private var title: String = ""
    @State private var selectedDate: Date = Date()
    @State private var startTime: Date = Date()
    @State private var duration: TimeInterval = 3600
    @State private var location: String = ""
    @State private var notes: String = ""

    var body: some View {
        NavigationView {
            Form {
                // Event Type (read-only)
                Section(header: Text("Event Type")) {
                    HStack {
                        Text(event.eventTypeIcon)
                        Text(eventTypeLabel)
                        Spacer()
                        Text("(Cannot change)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Title Section
                Section(header: Text("Title")) {
                    if event.eventType == .adhoc {
                        TextField("Event title", text: $title)
                    } else {
                        Text(title)
                            .foregroundColor(.secondary)
                        Text("(Auto-generated from client)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Date & Time Section
                Section(header: Text("Date & Time")) {
                    DatePicker("Date", selection: $selectedDate, in: Date()..., displayedComponents: .date)
                        .datePickerStyle(.compact)

                    DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)

                    Picker("Duration", selection: $duration) {
                        Text("30 minutes").tag(TimeInterval(1800))
                        Text("1 hour").tag(TimeInterval(3600))
                        Text("1.5 hours").tag(TimeInterval(5400))
                        Text("2 hours").tag(TimeInterval(7200))
                    }
                }

                // Optional Details Section
                Section(header: Text("Optional Details")) {
                    TextField("Location (optional)", text: $location)

                    VStack(alignment: .leading) {
                        Text("Notes (optional)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextEditor(text: $notes)
                            .frame(height: 100)
                    }
                }

                // Validation Error
                if !validationError.isEmpty {
                    Section {
                        Text(validationError)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        updateEvent()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                loadEventData()
            }
        }
    }

    // MARK: - Computed Properties

    private var eventTypeLabel: String {
        switch event.eventType {
        case .training: return "Training Session"
        case .call: return "Call"
        case .adhoc: return "Personal Event"
        }
    }

    private var isValid: Bool {
        validationError.isEmpty
    }

    private var validationError: String {
        // Adhoc requires custom title
        if event.eventType == .adhoc && title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Personal events require a title"
        }

        return ""
    }

    private var combinedStartTime: Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: startTime)

        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute

        return calendar.date(from: combined) ?? Date()
    }

    private var endTime: Date {
        combinedStartTime.addingTimeInterval(duration)
    }

    // MARK: - Actions

    private func loadEventData() {
        title = event.title
        selectedDate = event.startTime
        startTime = event.startTime
        duration = event.endTime.timeIntervalSince(event.startTime)
        location = event.location ?? ""
        notes = event.notes ?? ""
    }

    private func updateEvent() {
        print("[EventEditSheet] 💾 Updating event:")
        print("  - Original startTime: \(event.startTime)")
        print("  - New startTime: \(combinedStartTime)")
        print("  - Original endTime: \(event.endTime)")
        print("  - New endTime: \(endTime)")

        // Round dates to minute precision for comparison
        let originalStart = roundToMinute(event.startTime)
        let newStart = roundToMinute(combinedStartTime)
        let originalEnd = roundToMinute(event.endTime)
        let newEnd = roundToMinute(endTime)

        let newLocation = location.isEmpty ? nil : location
        let newNotes = notes.isEmpty ? nil : notes

        // Check if anything changed
        let hasChanges = (event.eventType == .adhoc && title != event.title) ||
                        originalStart != newStart ||
                        originalEnd != newEnd ||
                        newLocation != event.location ||
                        newNotes != event.notes

        guard hasChanges else {
            print("[EventEditSheet] ℹ️ No changes detected, dismissing")
            dismiss()
            return
        }

        Task {
            await viewModel.updateEvent(
                eventId: event.id,
                title: event.eventType == .adhoc && title != event.title ? title : nil,
                startTime: originalStart != newStart ? combinedStartTime : nil,
                endTime: originalEnd != newEnd ? endTime : nil,
                location: newLocation != event.location ? newLocation : nil,
                notes: newNotes != event.notes ? newNotes : nil
            )

            if viewModel.errorMessage == nil {
                print("[EventEditSheet] ✅ Event updated successfully")
                dismiss()
            } else {
                print("[EventEditSheet] ❌ Error updating event: \(viewModel.errorMessage ?? "unknown")")
            }
        }
    }

    /// Round date to minute precision for accurate comparison
    private func roundToMinute(_ date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        return calendar.date(from: components) ?? date
    }
}

// MARK: - Preview

struct EventEditSheet_Previews: PreviewProvider {
    static var previews: some View {
        EventEditSheet(
            event: CalendarEvent(
                trainerId: "trainer1",
                eventType: .training,
                title: "Session with Sam",
                clientId: "client1",
                startTime: Date(),
                endTime: Date().addingTimeInterval(3600),
                location: "Main Gym",
                notes: "Focus on upper body"
            ),
            viewModel: CalendarViewModel()
        )
    }
}
