//
//  MainTabView.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #4
//  Main tab navigation for authenticated users
//

import SwiftUI

/// Main tab-based navigation for the authenticated app
/// Contains tabs for Conversations, Profile, and Settings
struct MainTabView: View {
    // MARK: - State Management

    /// Currently selected tab - persisted across app sessions
    @AppStorage("selectedTab") private var selectedTab: Int = 0

    // MARK: - Body

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Conversations (TEMPORARY: Using ConversationListView for PR #8 testing)
            // TODO: Switch back to ChatListView after PR #8 is complete
            ConversationListView()
                .tabItem {
                    Label("Conversations", systemImage: "message.fill")
                }
                .tag(0)

            // Tab 2: Profile
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(1)

            // Tab 3: Settings
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
}
