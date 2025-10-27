//
//  MainTabView.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #4
//  Main tab navigation for authenticated users
//

import SwiftUI

/// Main tab-based navigation for the authenticated app
/// Contains tabs for Conversations and Settings
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
            // Tab 1: Conversations (PR #6)
            ChatListView()
                .tabItem {
                    Label("Conversations", systemImage: "message.fill")
                }
                .tag(0)

            // Tab 2: Settings
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(1)
        }
        .tint(.blue) // Blue accent color for tab bar (PR #006B)
        .onChange(of: notificationService.deepLinkHandler.targetChatId) { oldChatId, newChatId in
            if let chatId = newChatId {
                print("[MainTabView] 🧭 Deep link received for chat: \(chatId)")
                
                // Switch to conversations tab
                selectedTab = 0
                
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
