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
import GoogleSignIn

@main
struct PsstApp: App {
    
    // MARK: - State Objects
    
    @StateObject private var authService = AuthenticationService.shared
    @StateObject private var presenceService = PresenceService()
    
    // MARK: - Environment
    
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - Initialization
    
    init() {
        // Configure Firebase with GoogleService-Info.plist
        FirebaseService.shared.configure()
        
        // Enable Firebase Realtime Database offline persistence for presence caching
        Database.database().isPersistenceEnabled = true
    }

    // MARK: - Scene
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authService)
                .environmentObject(presenceService)
                .onOpenURL { url in
                    // Handle Google Sign-In callback URL
                    GIDSignIn.sharedInstance.handle(url)
                }
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    handleScenePhaseChange(newPhase)
                }
                .onChange(of: authService.currentUser) { oldUser, newUser in
                    handleAuthStateChange(newUser)
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
                    print("[PsstApp] User \(userID) is now online")
                } catch {
                    print("[PsstApp] Error setting online status: \(error.localizedDescription)")
                }
            }
            
        case .background, .inactive:
            // User sent app to background or it became inactive → Set status to offline
            Task {
                do {
                    try await presenceService.setOnlineStatus(userID: userID, isOnline: false)
                    print("[PsstApp] User \(userID) is now offline")
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
    private func handleAuthStateChange(_ user: User?) {
        if let userID = user?.id {
            // User logged in → Set online status
            Task {
                do {
                    try await presenceService.setOnlineStatus(userID: userID, isOnline: true)
                    print("[PsstApp] User \(userID) logged in and set to online")
                } catch {
                    print("[PsstApp] Error setting online status on login: \(error.localizedDescription)")
                }
            }
        } else {
            // User logged out → Clean up all presence listeners
            presenceService.stopAllObservers()
            print("[PsstApp] User logged out, presence listeners cleaned up")
        }
    }
}
