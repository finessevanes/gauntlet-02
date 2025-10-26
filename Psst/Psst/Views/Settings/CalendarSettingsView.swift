//
//  CalendarSettingsView.swift
//  Psst
//
//  Created for PR #010C: Google Calendar Integration
//  Settings view for managing Google Calendar connection
//

import SwiftUI

struct CalendarSettingsView: View {

    // MARK: - State

    @StateObject private var googleCalendarService = GoogleCalendarSyncService.shared
    @State private var isConnecting = false
    @State private var errorMessage: String?
    @State private var showDisconnectAlert = false

    var body: some View {
        List {
            // Google Calendar Integration Section
            Section {
                if googleCalendarService.isConnected {
                    // Connected state
                    connectedView
                } else {
                    // Disconnected state
                    disconnectedView
                }
            } header: {
                Text("Google Calendar Integration")
            } footer: {
                Text("Sync your Psst events to Google Calendar automatically. Events will appear in your Google Calendar app within 5 seconds of creation.")
            }

            // Error message
            if let errorMessage = errorMessage {
                Section {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
        }
        .navigationTitle("Calendar Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Disconnect Google Calendar", isPresented: $showDisconnectAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Disconnect", role: .destructive) {
                Task {
                    await disconnectGoogleCalendar()
                }
            }
        } message: {
            Text("Your Psst events will no longer sync to Google Calendar. Events already synced will remain in your Google Calendar.")
        }
    }

    // MARK: - Connected View

    private var connectedView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Connection status
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Connected")
                    .font(.headline)
            }

            // Connected email
            if let email = googleCalendarService.connectedEmail {
                Text(email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Disconnect button
            Button(role: .destructive) {
                showDisconnectAlert = true
            } label: {
                Text("Disconnect")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Disconnected View

    private var disconnectedView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Status
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.gray)
                Text("Not Connected")
                    .font(.headline)
            }

            Text("Connect your Google Calendar to automatically sync all Psst events.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Connect button
            Button {
                Task {
                    await connectGoogleCalendar()
                }
            } label: {
                if isConnecting {
                    HStack {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.8)
                        Text("Connecting...")
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    Text("Connect to Google Calendar")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isConnecting)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Actions

    private func connectGoogleCalendar() async {
        isConnecting = true
        errorMessage = nil

        do {
            _ = try await googleCalendarService.connectGoogleCalendar()
            // Success - state will update via @Published properties
        } catch {
            errorMessage = error.localizedDescription
        }

        isConnecting = false
    }

    private func disconnectGoogleCalendar() async {
        do {
            try await googleCalendarService.disconnectGoogleCalendar()
            // Success - state will update via @Published properties
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Preview

struct CalendarSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CalendarSettingsView()
        }
    }
}
