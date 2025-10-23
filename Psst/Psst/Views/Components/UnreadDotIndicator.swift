//
//  UnreadDotIndicator.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #003
//  Blue dot indicator for unread messages
//  Appears next to chat names when there are unread messages
//

import SwiftUI

/// Visual indicator for unread messages
/// Displays a small blue circle (8px) next to chat names
/// Fades in/out smoothly when unread status changes
struct UnreadDotIndicator: View {
    // MARK: - Properties
    
    /// Whether there are unread messages (true = show blue dot, false = hide)
    let hasUnread: Bool
    
    // MARK: - Body
    
    var body: some View {
        if hasUnread {
            Circle()
                .fill(Color.blue)
                .frame(width: 8, height: 8)
                .transition(.opacity)
        }
    }
}

// MARK: - SwiftUI Preview

#Preview("Has Unread") {
    HStack {
        UnreadDotIndicator(hasUnread: true)
        Text("Test Chat")
    }
    .padding()
}

#Preview("No Unread") {
    HStack {
        UnreadDotIndicator(hasUnread: false)
        Text("Test Chat")
    }
    .padding()
}

