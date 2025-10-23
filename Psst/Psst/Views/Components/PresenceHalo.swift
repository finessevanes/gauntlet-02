//
//  PresenceHalo.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #003
//  Green circular halo effect for online presence status
//  Renders as semi-transparent glow around profile photos
//

import SwiftUI

/// Visual halo effect indicating online presence status
/// Displays green circular glow around profile photos when user is online
/// Fades in/out smoothly when status changes
struct PresenceHalo: View {
    // MARK: - Properties
    
    /// Online status (true = show green halo, false = hide)
    let isOnline: Bool
    
    /// Size of the profile photo this halo wraps around
    let size: CGFloat
    
    // MARK: - Body
    
    var body: some View {
        if isOnline {
            // Green halo around entire circle
            Circle()
                .stroke(Color.green.opacity(0.6), lineWidth: 3)
                .frame(width: size, height: size)
                .transition(.opacity)
        }
    }
}

// MARK: - SwiftUI Preview

#Preview("Online") {
    ZStack {
        Circle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: 50, height: 50)
        
        PresenceHalo(isOnline: true, size: 50)
    }
    .padding()
}

#Preview("Offline") {
    ZStack {
        Circle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: 50, height: 50)
        
        PresenceHalo(isOnline: false, size: 50)
    }
    .padding()
}

