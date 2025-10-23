//
//  NotificationsSettingsView.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #006C
//  Placeholder view for notifications settings (to be implemented in Phase 2)
//

import SwiftUI

/// Placeholder view for notification settings
/// Full implementation deferred to Phase 2
struct NotificationsSettingsView: View {
    var body: some View {
        List {
            Section {
                Text("Notification settings coming soon")
                    .foregroundColor(.secondary)
                    .font(.body)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        NotificationsSettingsView()
    }
}

