//
//  PsstApp.swift
//  Psst
//
//  Created by Vanessa Mercado on 10/20/25.
//

import SwiftUI
import Firebase
import GoogleSignIn

@main
struct PsstApp: App {

    // Initialize Firebase and NetworkMonitor on app launch
    init() {
        // Configure Firebase with GoogleService-Info.plist
        FirebaseService.shared.configure()
        
        // Initialize NetworkMonitor to start monitoring network state
        _ = NetworkMonitor.shared
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .onOpenURL { url in
                    // Handle Google Sign-In callback URL
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
