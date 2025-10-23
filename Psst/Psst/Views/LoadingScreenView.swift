//
//  LoadingScreenView.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #007
//  App launch loading screen with skeleton UI
//

import SwiftUI

/// Loading screen displayed during app launch while Firebase Authentication checks user status
/// Shows app branding and skeleton UI that matches the main app layout
struct LoadingScreenView: View {
    // MARK: - State
    
    @State private var isAnimating = false
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // iOS system background
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // App branding
                VStack(spacing: 16) {
                    // App icon placeholder
                    ZStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "message.fill")
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(isAnimating ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
                    
                    // App name
                    Text("Psst")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .opacity(isAnimating ? 0.8 : 1.0)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)
                }
                
                Spacer()
                
                // Skeleton UI that matches main app layout
                VStack(spacing: 16) {
                    // Skeleton navigation bar
                    SkeletonNavigationBar()
                    
                    // Skeleton conversation rows
                    VStack(spacing: 12) {
                        ForEach(0..<3) { _ in
                            SkeletonConversationRow()
                        }
                    }
                }
                .padding(.horizontal, 16)
                
                Spacer()
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Preview

#Preview {
    LoadingScreenView()
}
