//
//  NotificationTestView.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #16
//  Test view for simulating push notifications on simulator
//

import SwiftUI

/// Test view for simulating push notifications and deep linking
/// Only shown in debug builds for testing purposes
struct NotificationTestView: View {
    @EnvironmentObject private var notificationService: NotificationService
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Notification Testing")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Simulator Testing Tools")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                // Test FCM Token
                Button("Show FCM Token") {
                    if let token = notificationService.fcmToken {
                        print("FCM Token: \(token)")
                    } else {
                        print("No FCM token available")
                    }
                }
                .buttonStyle(.bordered)
                
                // Test Deep Link (requires chat ID)
                Button("Test Deep Link") {
                    // You'll need to replace with actual chat ID
                    let testData = [
                        "data": [
                            "chatId": "test_chat_id",
                            "messageId": "test_message_id",
                            "senderId": "test_sender",
                            "type": "new_message"
                        ]
                    ]
                    let success = notificationService.handleNotificationTap(testData)
                    print("Deep link test result: \(success)")
                }
                .buttonStyle(.bordered)
            }
            
            Text("Note: Push notifications require physical device")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    NotificationTestView()
        .environmentObject(NotificationService())
}
