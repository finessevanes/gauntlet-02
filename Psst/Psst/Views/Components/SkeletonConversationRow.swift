//
//  SkeletonConversationRow.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #007
//  Skeleton version of conversation row for loading screen
//

import SwiftUI

/// Skeleton version of ChatRowView for loading screen
/// Matches the layout and spacing of actual conversation rows
struct SkeletonConversationRow: View {
    // MARK: - State
    
    @State private var isAnimating = false
    
    // MARK: - Body
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Skeleton avatar (56pt to match ChatRowView)
            SkeletonCircle(size: 56)
            
            // Skeleton chat info
            VStack(alignment: .leading, spacing: 4) {
                // Name and timestamp row
                HStack {
                    // Skeleton unread dot
                    SkeletonCircle(size: 8)
                    
                    // Skeleton name
                    SkeletonRectangle(width: 120, height: 18)
                    
                    Spacer()
                    
                    // Skeleton timestamp
                    SkeletonRectangle(width: 40, height: 14)
                }
                
                // Skeleton member count (for group chats)
                SkeletonRectangle(width: 80, height: 14)
                
                // Skeleton last message
                SkeletonRectangle(width: 200, height: 16)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Skeleton Components

/// Skeleton circle for avatars
struct SkeletonCircle: View {
    let size: CGFloat
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .fill(Color(.systemGray5))
            .frame(width: size, height: size)
            .opacity(isAnimating ? 0.3 : 0.6)
            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: isAnimating)
            .onAppear {
                isAnimating = true
            }
    }
}

/// Skeleton rectangle for text and other elements
struct SkeletonRectangle: View {
    let width: CGFloat
    let height: CGFloat
    @State private var isAnimating = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: height / 2)
            .fill(Color(.systemGray5))
            .frame(width: width, height: height)
            .opacity(isAnimating ? 0.3 : 0.6)
            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: isAnimating)
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        SkeletonConversationRow()
        SkeletonConversationRow()
        SkeletonConversationRow()
    }
    .padding()
}
