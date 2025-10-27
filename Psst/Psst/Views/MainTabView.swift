//
//  MainTabView.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #4
//  Main tab navigation for authenticated users
//

import SwiftUI

/// Main tab-based navigation for the authenticated app
/// Contains tabs for Calendar, Conversations, Contacts, and Settings
struct MainTabView: View {
    // MARK: - State Management

    /// Currently selected tab - persisted across app sessions
    @AppStorage("selectedTab") private var selectedTab: Int = 0

    /// Notification service for deep linking
    @EnvironmentObject private var notificationService: NotificationService

    /// Navigation state for deep linking
    @State private var navigateToChat: String? = nil

    // MARK: - Body

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Calendar (PR #010A - HOME PAGE)
            CalendarView()
                .tabItem {
                    Label("Cal", systemImage: "calendar")
                }
                .tag(0)

            // Tab 2: Conversations (PR #6)
            ChatListView()
                .tabItem {
                    Label("Chats", systemImage: "message.fill")
                }
                .tag(1)

            // Tab 3: Contacts (PR #009)
            ContactsView()
                .tabItem {
                    Label("Contacts", systemImage: "person.2.fill")
                }
                .tag(2)

            // Tab 4: Settings
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(.blue) // Blue accent color for tab bar (PR #006B)
        .onChange(of: notificationService.deepLinkHandler.targetChatId) { oldChatId, newChatId in
            if let chatId = newChatId {
                print("[MainTabView] 🧭 Deep link received for chat: \(chatId)")

                // Switch to conversations tab (now tab 1 instead of 0)
                selectedTab = 1

                // Set navigation target
                navigateToChat = chatId

                // Clear the deep link after processing
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    notificationService.clearDeepLink()
                    navigateToChat = nil
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
}
