//
//  CalendarViewModel.swift
//  Psst
//
//  Created for PR #010A: Calendar Foundation (Manual UI + CRUD)
//  Manages calendar state and event operations
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

/// ViewModel for managing calendar events
@MainActor
class CalendarViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var events: [CalendarEvent] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var currentWeekStart: Date
    @Published var selectedDate: Date = Date()
    @Published var showEventCreationSheet: Bool = false
    @Published var showEventDetailSheet: Bool = false
    @Published var selectedEvent: CalendarEvent?

    // MARK: - Dependencies

    private let calendarService: CalendarService
    private var eventListener: ListenerRegistration?

    // MARK: - Computed Properties

    /// Events for the current week
    var currentWeekEvents: [CalendarEvent] {
        events.filter { event in
            event.startTime >= currentWeekStart &&
            event.startTime < currentWeekStart.addingTimeInterval(7 * 24 * 3600)
        }
    }

    /// Today's events (scheduled status only, not cancelled, sorted by startTime)
    var todaysEvents: [CalendarEvent] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        return events
            .filter { event in
                event.startTime >= today &&
                event.startTime < tomorrow &&
                event.status == .scheduled
            }
            .sorted { $0.startTime < $1.startTime }
    }

    /// Today's upcoming events (from now onwards, max 3)
    var todaysUpcomingEvents: [CalendarEvent] {
        let now = Date()
        return todaysEvents
            .filter { $0.startTime >= now }
            .prefix(3)
            .map { $0 }
    }

    /// Count of today's events
    var todaysEventCount: Int {
        todaysEvents.count
    }

    /// Whether there are any upcoming events (not cancelled)
    var hasEventsThisWeek: Bool {
        // Check if there are any upcoming events (not ended yet and not cancelled)
        events.contains { event in
            event.endTime >= Date() && event.status != .cancelled
        }
    }

    // MARK: - Initialization

    init(calendarService: CalendarService = .shared) {
        self.calendarService = calendarService
        // Initialize currentWeekStart to the start of the current week (Sunday)
        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now)
        let daysFromSunday = weekday - 1
        self.currentWeekStart = calendar.date(byAdding: .day, value: -daysFromSunday, to: calendar.startOfDay(for: now))!
    }

    // MARK: - Public Methods

    /// Load events for the current week
    func loadEvents() async {
        guard let trainerId = Auth.auth().currentUser?.uid else {
            errorMessage = "Not authenticated"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            // Calculate date range (load from 1 week ago to 4 weeks ahead for vertical agenda)
            let startDate = currentWeekStart.addingTimeInterval(-7 * 24 * 3600)
            let endDate = currentWeekStart.addingTimeInterval(28 * 24 * 3600) // 4 weeks ahead

            // Stop existing listener
            eventListener?.remove()

            // Start real-time listener
            eventListener = calendarService.observeEvents(
                trainerId: trainerId,
                startDate: startDate,
                endDate: endDate
            ) { [weak self] events in
                Task { @MainActor in
                    self?.events = events
                    self?.isLoading = false
                }
            }

        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    /// Create a new event
    func createEvent(
        eventType: CalendarEvent.EventType,
        title: String,
        clientId: String? = nil,
        prospectId: String? = nil,
        startTime: Date,
        endTime: Date,
        location: String? = nil,
        notes: String? = nil
    ) async {
        guard let trainerId = Auth.auth().currentUser?.uid else {
            errorMessage = "Not authenticated"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            _ = try await calendarService.createEvent(
                trainerId: trainerId,
                eventType: eventType,
                title: title,
                clientId: clientId,
                prospectId: prospectId,
                startTime: startTime,
                endTime: endTime,
                location: location,
                notes: notes
            )
            // Event will be added automatically via real-time listener
            showEventCreationSheet = false
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Update an existing event
    func updateEvent(
        eventId: String,
        title: String? = nil,
        startTime: Date? = nil,
        endTime: Date? = nil,
        location: String? = nil,
        notes: String? = nil,
        status: CalendarEvent.EventStatus? = nil
    ) async {
        isLoading = true
        errorMessage = nil

        var updates: [String: Any] = [:]
        if let title = title { updates["title"] = title }
        if let startTime = startTime { updates["startTime"] = Timestamp(date: startTime) }
        if let endTime = endTime { updates["endTime"] = Timestamp(date: endTime) }
        if let location = location { updates["location"] = location }
        if let notes = notes { updates["notes"] = notes }
        if let status = status { updates["status"] = status.rawValue }

        do {
            try await calendarService.updateEvent(eventId: eventId, updates: updates)
            // Event will be updated automatically via real-time listener
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Delete an event (soft delete)
    func deleteEvent(eventId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            try await calendarService.deleteEvent(eventId: eventId)
            // Event will be updated automatically via real-time listener
            showEventDetailSheet = false
            selectedEvent = nil
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Mark an event as completed
    func markEventCompleted(eventId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            try await calendarService.markEventCompleted(eventId: eventId)
            // Event will be updated automatically via real-time listener
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Navigate to next week
    func nextWeek() {
        currentWeekStart = currentWeekStart.addingTimeInterval(7 * 24 * 3600)
        Task {
            await loadEvents()
        }
    }

    /// Navigate to previous week
    func previousWeek() {
        currentWeekStart = currentWeekStart.addingTimeInterval(-7 * 24 * 3600)
        Task {
            await loadEvents()
        }
    }

    /// Navigate to today's week
    func goToToday() {
        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now)
        let daysFromSunday = weekday - 1
        currentWeekStart = calendar.date(byAdding: .day, value: -daysFromSunday, to: calendar.startOfDay(for: now))!
        selectedDate = now
        Task {
            await loadEvents()
        }
    }

    /// Select an event to view details
    func selectEvent(_ event: CalendarEvent) {
        selectedEvent = event
        showEventDetailSheet = true
    }

    // MARK: - Cleanup

    deinit {
        eventListener?.remove()
    }
}

