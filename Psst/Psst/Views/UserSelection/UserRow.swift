//
//  UserRow.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #9
//  Reusable user row component for contact selection
//

import SwiftUI

/// Reusable row component displaying user information
/// Shows user avatar with presence halo, display name, and email
/// Supports multi-select mode with checkbox
struct UserRow: View {
    // MARK: - Properties
    
    let user: User
    
    /// Whether to show checkbox (for group mode)
    var showCheckbox: Bool = false
    
    /// Whether this user is selected (for group mode)
    var isSelected: Bool = false
    
    /// User's online status
    @State private var isUserOnline: Bool = false
    
    /// Presence listener ID for cleanup (UUID-based tracking)
    @State private var presenceListenerID: UUID? = nil
    
    /// Presence service for online/offline status
    @EnvironmentObject private var presenceService: PresenceService
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile photo with presence halo
            ZStack {
                ProfilePhotoPreview(
                    imageURL: user.photoURL,
                    selectedImage: nil,
                    isLoading: false,
                    size: 40
                )
                
                // Green presence halo (only when online)
                PresenceHalo(isOnline: isUserOnline, size: 40)
                    .animation(.easeInOut(duration: 0.2), value: isUserOnline)
            }
            
            // User information
            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Checkbox for multi-select mode
            if showCheckbox {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .gray)
            }
        }
        .padding(.vertical, 8)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .onAppear {
            // Attach presence listener for this user
            attachPresenceListener()
        }
        .onDisappear {
            // Detach presence listener to prevent memory leaks
            detachPresenceListener()
        }
    }
    
    // MARK: - Helper Methods
    
    /// Extract initials from display name (max 2 characters)
    /// - Parameter name: Full display name
    /// - Returns: Initials (e.g., "John Doe" -> "JD")
    private func getInitials(from name: String) -> String {
        let components = name.split(separator: " ")
        if components.count >= 2 {
            // First letter of first name + first letter of last name
            let first = String(components[0].prefix(1))
            let last = String(components[1].prefix(1))
            return "\(first)\(last)".uppercased()
        } else if let first = components.first {
            // Just first letter of single name
            return String(first.prefix(1)).uppercased()
        } else {
            // Fallback for empty name
            return "?"
        }
    }
    
    /// Attach presence listener for this user
    private func attachPresenceListener() {
        presenceListenerID = presenceService.observePresence(userID: user.id) { isOnline in
            DispatchQueue.main.async {
                self.isUserOnline = isOnline
            }
        }
    }
    
    /// Detach presence listener to prevent memory leaks
    private func detachPresenceListener() {
        guard let listenerID = presenceListenerID else { return }
        presenceService.stopObserving(userID: user.id, listenerID: listenerID)
        presenceListenerID = nil
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        UserRow(user: User(
            id: "1",
            email: "alice@example.com",
            displayName: "Alice Johnson"
        ))
        
        Divider()
        
        UserRow(user: User(
            id: "2",
            email: "bob@example.com",
            displayName: "Bob Smith"
        ))
        
        Divider()
        
        UserRow(user: User(
            id: "3",
            email: "carol@example.com",
            displayName: "Carol"
        ))
    }
    .padding()
}

