//
//  EventSyncStatusBadge.swift
//  Psst
//
//  Created for PR #010C: Google Calendar Integration
//  Visual badge showing Google Calendar sync status
//

import SwiftUI

struct EventSyncStatusBadge: View {

    // MARK: - Properties

    let event: CalendarEvent
    @StateObject private var googleCalendarService = GoogleCalendarSyncService.shared

    // MARK: - Body

    var body: some View {
        // Only show badge if Google Calendar is connected
        guard googleCalendarService.isConnected else {
            return AnyView(EmptyView())
        }

        return AnyView(badge)
    }

    private var badge: some View {
        HStack(spacing: 4) {
            statusIcon
            Text(statusText)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(backgroundColor)
        .foregroundColor(foregroundColor)
        .cornerRadius(4)
    }

    // MARK: - Status Helpers

    private var statusIcon: some View {
        Group {
            switch syncStatus {
            case .synced:
                Image(systemName: "checkmark.circle.fill")
            case .syncing:
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(0.7)
            case .failed:
                Image(systemName: "exclamationmark.circle.fill")
            case .notSynced:
                Image(systemName: "clock.fill")
            }
        }
        .font(.caption2)
    }

    private var statusText: String {
        switch syncStatus {
        case .synced:
            return "Synced"
        case .syncing:
            return "Syncing..."
        case .failed:
            return "Sync failed"
        case .notSynced:
            return "Pending"
        }
    }

    private var backgroundColor: Color {
        switch syncStatus {
        case .synced:
            return Color.green.opacity(0.2)
        case .syncing:
            return Color.yellow.opacity(0.2)
        case .failed:
            return Color.red.opacity(0.2)
        case .notSynced:
            return Color.gray.opacity(0.2)
        }
    }

    private var foregroundColor: Color {
        switch syncStatus {
        case .synced:
            return .green
        case .syncing:
            return .orange
        case .failed:
            return .red
        case .notSynced:
            return .gray
        }
    }

    private var syncStatus: SyncStatus {
        // Use Google Calendar service sync status for real-time updates
        if googleCalendarService.syncStatus == .syncing {
            return .syncing
        } else if event.isSynced {
            return .synced
        } else if googleCalendarService.syncStatus == .failed {
            return .failed
        } else {
            return .notSynced
        }
    }

    // MARK: - Status Enum

    enum SyncStatus {
        case synced
        case syncing
        case failed
        case notSynced
    }
}

// MARK: - Preview

struct EventSyncStatusBadge_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            // Synced
            EventSyncStatusBadge(
                event: CalendarEvent(
                    trainerId: "test",
                    eventType: .training,
                    title: "Session with John",
                    startTime: Date(),
                    endTime: Date().addingTimeInterval(3600),
                    googleCalendarEventId: "google-123",
                    syncedAt: Date()
                )
            )

            // Syncing (would need to mock service state)

            // Not synced
            EventSyncStatusBadge(
                event: CalendarEvent(
                    trainerId: "test",
                    eventType: .training,
                    title: "Session with Sarah",
                    startTime: Date(),
                    endTime: Date().addingTimeInterval(3600)
                )
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
