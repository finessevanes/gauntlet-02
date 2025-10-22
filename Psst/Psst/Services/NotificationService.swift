//
//  NotificationService.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #15
//  Service layer for push notification management and device token registration
//

import Foundation
import FirebaseMessaging
import FirebaseFirestore
import FirebaseAuth
import UserNotifications
import UIKit

/// Service for managing push notifications, device tokens, and permission requests
/// Handles APNs registration, FCM token management, and Firestore token storage
class NotificationService: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    /// Whether notification permission has been granted by user
    @Published var isPermissionGranted: Bool = false
    
    /// Firebase Cloud Messaging device token for push notifications
    @Published var fcmToken: String?
    
    // MARK: - Private Properties
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private let db = Firestore.firestore()
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupMessagingDelegate()
    }
    
    /// Set up Firebase Messaging delegate to receive token updates
    private func setupMessagingDelegate() {
        Messaging.messaging().delegate = self
    }
    
    // MARK: - Permission Management
    
    /// Request notification permission from user
    /// Should be called once after authentication
    /// - Returns: Bool indicating if permission was granted
    /// - Throws: Error if permission request fails
    func requestPermission() async throws -> Bool {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        let granted = try await notificationCenter.requestAuthorization(options: options)
        
        await MainActor.run {
            self.isPermissionGranted = granted
        }
        
        if granted {
            print("[NotificationService] ✅ Notification permission granted")
            await MainActor.run {
                registerForPushNotifications()
            }
        } else {
            print("[NotificationService] ❌ Notification permission denied")
        }
        
        return granted
    }
    
    /// Check current notification authorization status
    /// - Returns: UNAuthorizationStatus
    func checkPermissionStatus() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        let status = settings.authorizationStatus
        
        await MainActor.run {
            self.isPermissionGranted = (status == .authorized)
        }
        
        print("[NotificationService] Permission status: \(status.rawValue)")
        return status
    }
    
    // MARK: - APNs Registration
    
    /// Register for remote notifications with APNs
    /// Must be called on main thread
    func registerForPushNotifications() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
        print("[NotificationService] 📲 Registering for remote notifications...")
    }
    
    /// Handle successful APNs device token registration
    /// - Parameter token: Device token data from APNs
    func didReceiveAPNsToken(_ token: Data) {
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
        print("[NotificationService] 📱 APNs token received: \(tokenString)")
        
        // FCM SDK will automatically exchange this for FCM token via MessagingDelegate
    }
    
    /// Handle APNs registration failure
    /// - Parameter error: Registration error
    func didFailToRegister(error: Error) {
        print("[NotificationService] ❌ Failed to register for remote notifications: \(error.localizedDescription)")
        
        // Check if running on simulator
        #if targetEnvironment(simulator)
        print("[NotificationService] ⚠️ Note: Push notifications are not supported on iOS Simulator. Please test on a physical device.")
        #endif
    }
    
    // MARK: - FCM Token Management
    
    /// Handle FCM token received from Firebase Messaging
    /// - Parameter token: FCM device token
    func didReceiveFCMToken(_ token: String) {
        print("[NotificationService] 🔥 FCM token received: \(token)")
        
        Task {
            await MainActor.run {
                self.fcmToken = token
            }
            
            do {
                try await saveFCMTokenToFirestore(token)
                print("[NotificationService] ✅ FCM token saved to Firestore")
            } catch {
                print("[NotificationService] ❌ Failed to save FCM token to Firestore: \(error.localizedDescription)")
            }
        }
    }
    
    /// Save FCM token to user's Firestore document
    /// - Parameter token: FCM device token
    /// - Throws: Error if user not authenticated or Firestore write fails
    func saveFCMTokenToFirestore(_ token: String) async throws {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("[NotificationService] ⚠️ Cannot save token - user not authenticated")
            throw NSError(domain: "NotificationService", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        try await db.collection("users").document(userID).updateData([
            "fcmToken": token
        ])
        
        print("[NotificationService] ✅ Saved token for user: \(userID)")
    }
    
    /// Refresh FCM token (called on app launch)
    /// Fetches latest token from Firebase Messaging SDK
    func refreshFCMToken() async {
        print("[NotificationService] 🔄 Refreshing FCM token...")
        
        do {
            let token = try await Messaging.messaging().token()
            print("[NotificationService] 🔥 Refreshed FCM token: \(token)")
            didReceiveFCMToken(token)
        } catch {
            print("[NotificationService] ❌ Failed to refresh FCM token: \(error.localizedDescription)")
        }
    }
}

// MARK: - MessagingDelegate

extension NotificationService: MessagingDelegate {
    /// Called when FCM token is generated or refreshed
    /// - Parameters:
    ///   - messaging: Messaging instance
    ///   - fcmToken: Firebase Cloud Messaging token
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("[NotificationService] 📬 MessagingDelegate: FCM token received")
        
        guard let token = fcmToken else {
            print("[NotificationService] ⚠️ FCM token is nil")
            return
        }
        
        didReceiveFCMToken(token)
    }
}

