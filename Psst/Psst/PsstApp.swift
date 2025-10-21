//
//  PsstApp.swift
//  Psst
//
//  Created by Vanessa Mercado on 10/20/25.
//

import SwiftUI
import Firebase

@main
struct PsstApp: App {
    
    // Initialize Firebase on app launch
    init() {
        // Configure Firebase with GoogleService-Info.plist
        FirebaseService.shared.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
