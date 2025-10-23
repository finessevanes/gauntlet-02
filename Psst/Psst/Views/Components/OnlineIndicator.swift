//
//  OnlineIndicator.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #004
//  Small dot indicator for online/offline status in group chats
//  Displays at bottom-right of profile photos (green for online, gray for offline)
//

import SwiftUI

/// Small circular dot indicating online/offline status for group chat members
/// Shows green dot (8pt) for online members, gray dot (50% opacity) for offline
/// Positioned at bottom-right corner of profile photos with 2pt overlap
struct OnlineIndicator: View {
    // MARK: - Properties
    
    /// Online status (true = green dot, false = gray dot)
    let isOnline: Bool
    
    /// Dot size in points (default: 8pt per PRD specification)
    let size: CGFloat
    
    // MARK: - Initializer
    
    /// Create online indicator with custom size
    /// - Parameters:
    ///   - isOnline: True for online (green), false for offline (gray)
    ///   - size: Dot diameter in points (default: 8)
    init(isOnline: Bool, size: CGFloat = 8) {
        self.isOnline = isOnline
        self.size = size
    }
    
    // MARK: - Body
    
    var body: some View {
        Circle()
            .fill(isOnline ? Color.green : Color.gray.opacity(0.5))
            .frame(width: size, height: size)
            .overlay(
                // White border for better visibility on colored backgrounds
                Circle()
                    .stroke(Color.white, lineWidth: 1.5)
            )
            .animation(.easeInOut(duration: 0.3), value: isOnline)
            .accessibilityLabel(isOnline ? "Online" : "Offline")
    }
}

// MARK: - SwiftUI Preview

#Preview("Online") {
    VStack(spacing: 20) {
        // Standard size (8pt)
        OnlineIndicator(isOnline: true)
        
        // Larger size for visibility
        OnlineIndicator(isOnline: true, size: 16)
    }
    .padding()
}

#Preview("Offline") {
    VStack(spacing: 20) {
        // Standard size (8pt)
        OnlineIndicator(isOnline: false)
        
        // Larger size for visibility
        OnlineIndicator(isOnline: false, size: 16)
    }
    .padding()
}

#Preview("On Profile Photo") {
    ZStack(alignment: .bottomTrailing) {
        // Profile photo placeholder
        Circle()
            .fill(Color.blue.opacity(0.3))
            .frame(width: 50, height: 50)
        
        // Online indicator positioned at bottom-right
        OnlineIndicator(isOnline: true)
            .offset(x: 2, y: 2)
    }
    .padding()
}

