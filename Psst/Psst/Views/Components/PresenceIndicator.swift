//
//  PresenceIndicator.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #12
//  Reusable presence indicator component (green dot = online, gray dot = offline)
//

import SwiftUI

/// Visual indicator for user online/offline presence status
/// Displays a colored circle: green for online, gray for offline
/// Animates smoothly when status changes
struct PresenceIndicator: View {
    /// Online status (true = online/green, false = offline/gray)
    let isOnline: Bool
    
    var body: some View {
        Circle()
            .fill(isOnline ? Color.green : Color.gray)
            .frame(width: 8, height: 8)
            .animation(.easeInOut(duration: 0.3), value: isOnline)
    }
}

// MARK: - SwiftUI Preview

#Preview("Online") {
    PresenceIndicator(isOnline: true)
        .padding()
}

#Preview("Offline") {
    PresenceIndicator(isOnline: false)
        .padding()
}

