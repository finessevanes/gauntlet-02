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
    
    /// Presence service for online/offline status (required by PresenceObserverModifier)
    @EnvironmentObject private var presenceService: PresenceService
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile photo with presence halo
            ZStack {
                ProfilePhotoPreview(
                    imageURL: user.photoURL,
                    userID: user.id,
                    selectedImage: nil,
                    isLoading: false,
                    size: 40,
                    displayName: user.displayName
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
        .observePresence(userID: user.id, isOnline: $isUserOnline)
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

