//
//  ProfilePhotoWithPresence.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #004
//  Profile photo component with online/offline presence indicator overlay
//  Automatically observes user presence and displays online indicator
//

import SwiftUI

/// Profile photo with real-time online/offline indicator overlay
/// Combines profile photo image with OnlineIndicator positioned at bottom-right
/// Automatically attaches/detaches Firebase presence listener
struct ProfilePhotoWithPresence: View {
    // MARK: - Properties
    
    /// User ID to display photo and presence for
    let userID: String
    
    /// URL to profile photo image (nil for placeholder)
    let photoURL: String?
    
    /// Photo size in points
    let size: CGFloat
    
    /// User's display name for placeholder (first letter)
    let displayName: String?
    
    /// Current online status
    @State private var isOnline: Bool = false
    
    /// Presence service for observing online status (required by PresenceObserverModifier)
    @EnvironmentObject private var presenceService: PresenceService
    
    // MARK: - Initializer
    
    /// Create profile photo with presence indicator
    /// - Parameters:
    ///   - userID: User ID to observe presence for
    ///   - photoURL: URL to profile photo (nil for placeholder)
    ///   - displayName: User's display name for placeholder initial
    ///   - size: Photo diameter in points
    init(userID: String, photoURL: String?, displayName: String? = nil, size: CGFloat) {
        self.userID = userID
        self.photoURL = photoURL
        self.displayName = displayName
        self.size = size
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Profile photo
            ProfilePhotoPreview(
                imageURL: photoURL,
                userID: userID,
                selectedImage: nil,
                isLoading: false,
                size: size,
                displayName: displayName
            )
            .clipShape(Circle())
            
            // Online indicator overlay (bottom-right)
            OnlineIndicator(isOnline: isOnline)
                .offset(x: 2, y: 2)
        }
        .frame(width: size, height: size)
        .observePresence(userID: userID, isOnline: $isOnline)
    }
}

// MARK: - SwiftUI Preview

#Preview("Online User") {
    ProfilePhotoWithPresence(
        userID: "preview_user_online",
        photoURL: nil,
        displayName: "John Doe",
        size: 50
    )
    .environmentObject(PresenceService())
    .padding()
}

#Preview("Group Header (Multiple Users)") {
    HStack(spacing: 8) {
        ForEach(0..<4) { index in
            ProfilePhotoWithPresence(
                userID: "user_\(index)",
                photoURL: nil,
                displayName: "User \(index)",
                size: 40
            )
        }
    }
    .environmentObject(PresenceService())
    .padding()
}

