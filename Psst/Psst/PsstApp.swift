//
//  PsstApp.swift
//  Psst
//
//  Created by Vanessa Mercado on 10/20/25.
//  Updated by Caleb (Coder Agent) - PR #12: Added presence service and lifecycle monitoring
//

import SwiftUI
import Firebase
import FirebaseDatabase
import FirebaseMessaging
import GoogleSignIn
import UserNotifications

@main
struct PsstApp: App {
    
    // MARK: - State Objects
    
    @StateObject private var authService = AuthenticationService.shared
    @StateObject private var presenceService = PresenceService()
    @StateObject private var notificationService = NotificationService()
    
    // MARK: - App Delegate
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // MARK: - Environment
    
    @Environment(\.scenePhase) private var scenePhase
    
    // MARK: - State for Debouncing
    
    /// Track last user ID to prevent duplicate auth state changes
    @State private var lastUserID: String?

    // Initialize Firebase and NetworkMonitor on app launch
    // MARK: - Initialization
    
    init() {
        // Configure Firebase with GoogleService-Info.plist
        FirebaseService.shared.configure()
        
        // Initialize NetworkMonitor to start monitoring network state
        _ = NetworkMonitor.shared
        // Enable Firebase Realtime Database offline persistence for presence caching
        Database.database().isPersistenceEnabled = true
    }

    // MARK: - Scene
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authService)
                .environmentObject(presenceService)
                .environmentObject(notificationService)
                .onOpenURL { url in
                    // Handle Google Sign-In callback URL
                    GIDSignIn.sharedInstance.handle(url)
                }
                .onChange(of: notificationService.deepLinkHandler.targetChatId) { oldChatId, newChatId in
                    if let chatId = newChatId {
                        print("[PsstApp] 🧭 Deep link target chat: \(chatId)")
                        // Navigation will be handled by the UI layer
                    }
                }
                .onAppear {
                    // FCM token will be refreshed after APNs token is received
                    print("[PsstApp] 📱 App appeared, waiting for APNs token...")
                }
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    handleScenePhaseChange(newPhase)
                }
                .onChange(of: authService.currentUser) { oldUser, newUser in
                    // Debounce: Only call if userID actually changed to prevent triple login
                    let newUserID = newUser?.id
                    if newUserID != lastUserID {
                        lastUserID = newUserID
                        handleAuthStateChange(oldUser: oldUser, newUser: newUser)
                    }
                }
        }
    }
    
    // MARK: - Private Methods
    
    /// Handle app lifecycle phase changes (foreground, background, inactive)
    /// Updates user's online/offline presence status in Firebase Realtime Database
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        guard let userID = authService.currentUser?.id else { return }
        
        switch phase {
        case .active:
            // User brought app to foreground → Set status to online
            Task {
                do {
                    try await presenceService.setOnlineStatus(userID: userID, isOnline: true)
                    let email = authService.currentUser?.email ?? "user_\(String(userID.suffix(8)))"
                    print("[PsstApp] User \(email) is now online")
                } catch {
                    print("[PsstApp] Error setting online status: \(error.localizedDescription)")
                }
            }
            
        case .background, .inactive:
            // User sent app to background or it became inactive → Set status to offline
            Task {
                do {
                    try await presenceService.setOnlineStatus(userID: userID, isOnline: false)
                    let email = authService.currentUser?.email ?? "user_\(String(userID.suffix(8)))"
                    print("[PsstApp] User \(email) is now offline")
                } catch {
                    print("[PsstApp] Error setting offline status: \(error.localizedDescription)")
                }
            }
            
        @unknown default:
            break
        }
    }
    
    /// Handle authentication state changes (login, logout)
    /// Sets presence and manages listeners based on auth status
    private func handleAuthStateChange(oldUser: User?, newUser: User?) {
        if let user = newUser {
            // User logged in → Reconnect to Firebase Database and set online status
            // (Database might be offline from previous logout)
            Database.database().goOnline()
            
            Task {
                do {
                    try await presenceService.setOnlineStatus(userID: user.id, isOnline: true)
                    let email = user.email
                    print("[PsstApp] User \(email) logged in and set to online")
                } catch {
                    print("[PsstApp] Error setting online status on login: \(error.localizedDescription)")
                }
            }
        } else if let oldUser = oldUser {
            // User logged out → Just clean up listeners
            // (Offline status was already set via onDisconnect() hook in AuthViewModel)
            presenceService.stopAllObservers()
            print("[PsstApp] User logged out, presence listeners cleaned up")
            print("[PsstApp] Offline status was set via Firebase onDisconnect() hook")
        }
    }
}

// MARK: - AppDelegate

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, 
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Set notification center delegate
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }
    
    func application(_ application: UIApplication,
                    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Forward to NotificationService
        print("[AppDelegate] 📱 APNs device token received")
        
        // Let FCM SDK know about the token
        Messaging.messaging().apnsToken = deviceToken
        
        // Now that we have the APNs token, refresh the FCM token
        Task {
            await NotificationService().refreshFCMToken()
        }
    }
    
    func application(_ application: UIApplication,
                    didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("[AppDelegate] ❌ Failed to register: \(error.localizedDescription)")
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    /// Handle notifications when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               willPresent notification: UNNotification,
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("[AppDelegate] 📬 Notification received in foreground")
        
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound])
    }
    
    /// Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               didReceive response: UNNotificationResponse,
                               withCompletionHandler completionHandler: @escaping () -> Void) {
        print("[AppDelegate] 👆 User tapped notification")
        
        // Process deep link through NotificationService
        let userInfo = response.notification.request.content.userInfo
        let notificationService = NotificationService()
        let success = notificationService.handleNotificationTap(userInfo)
        
        if success {
            print("[AppDelegate] ✅ Deep link processed successfully")
        } else {
            print("[AppDelegate] ❌ Failed to process deep link")
        }
        
        completionHandler()
    }
}

