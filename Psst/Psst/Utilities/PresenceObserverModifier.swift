//
//  PresenceObserverModifier.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - Refactoring
//  Reusable ViewModifier for attaching/detaching presence listeners
//  Eliminates duplicate presence logic across components
//

import SwiftUI

/// ViewModifier that automatically observes user presence and updates a binding
/// Handles listener attachment on appear, detachment on disappear, and proper cleanup
///
/// Usage:
/// ```swift
/// @State private var isOnline: Bool = false
/// var body: some View {
///     Text("User Status")
///         .observePresence(userID: "user123", isOnline: $isOnline)
/// }
/// ```
///
/// Benefits:
/// - Eliminates 40+ lines of boilerplate per component
/// - Consistent error handling across all presence observers
/// - Centralized memory leak prevention
/// - Single source of truth for presence observation logic
struct PresenceObserverModifier: ViewModifier {
    // MARK: - Properties
    
    /// User ID to observe presence for
    let userID: String
    
    /// Binding to online status (updated by listener)
    @Binding var isOnline: Bool
    
    /// Presence listener ID for cleanup (UUID-based tracking)
    @State private var presenceListenerID: UUID? = nil
    
    /// Presence service for online/offline status
    @EnvironmentObject private var presenceService: PresenceService
    
    // MARK: - Body
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                attachPresenceListener()
            }
            .onDisappear {
                detachPresenceListener()
            }
    }
    
    // MARK: - Private Methods
    
    /// Attach presence listener for the user
    /// Listener fires immediately with current status and on every subsequent change
    private func attachPresenceListener() {
        presenceListenerID = presenceService.observePresence(userID: userID) { online in
            DispatchQueue.main.async {
                self.isOnline = online
            }
        }
    }
    
    /// Detach presence listener to prevent memory leaks
    /// Called automatically on view disappear
    private func detachPresenceListener() {
        guard let listenerID = presenceListenerID else { return }
        presenceService.stopObserving(userID: userID, listenerID: listenerID)
        presenceListenerID = nil
    }
}

// MARK: - View Extension

extension View {
    /// Observe presence status for a user
    /// Automatically attaches listener on appear and detaches on disappear
    ///
    /// - Parameters:
    ///   - userID: The user ID to observe presence for
    ///   - isOnline: Binding to Bool that will be updated with online status
    /// - Returns: Modified view with presence observation
    ///
    /// Example:
    /// ```swift
    /// @State private var isUserOnline: Bool = false
    /// Text("Status: \(isUserOnline ? "Online" : "Offline")")
    ///     .observePresence(userID: user.id, isOnline: $isUserOnline)
    /// ```
    func observePresence(userID: String, isOnline: Binding<Bool>) -> some View {
        self.modifier(PresenceObserverModifier(userID: userID, isOnline: isOnline))
    }
}

