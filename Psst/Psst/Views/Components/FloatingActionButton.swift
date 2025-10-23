//
//  FloatingActionButton.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #006B
//  Reusable Floating Action Button (FAB) component
//

import SwiftUI

/// Floating Action Button (FAB) for primary actions
/// Displays a circular button with plus icon, positioned bottom-right
struct FloatingActionButton: View {
    // MARK: - Properties
    
    /// Action to perform when FAB is tapped
    let action: () -> Void
    
    /// Button is pressed state for animation
    @State private var isPressed = false
    
    // MARK: - Body
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color.blue)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(FABButtonStyle())
    }
}

// MARK: - FAB Button Style

/// Custom button style for FAB with scale animation
private struct FABButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("FAB Light Mode") {
    ZStack {
        Color(.systemBackground)
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            HStack {
                Spacer()
                FloatingActionButton {
                    print("FAB tapped")
                }
                .padding(16)
            }
        }
    }
}

#Preview("FAB Dark Mode") {
    ZStack {
        Color(.systemBackground)
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            HStack {
                Spacer()
                FloatingActionButton {
                    print("FAB tapped")
                }
                .padding(16)
            }
        }
    }
    .preferredColorScheme(.dark)
}

