//
//  SkeletonNavigationBar.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #007
//  Skeleton version of navigation bar for loading screen
//

import SwiftUI

/// Skeleton version of navigation bar for loading screen
/// Matches the layout and spacing of actual navigation bar
struct SkeletonNavigationBar: View {
    // MARK: - State
    
    @State private var isAnimating = false
    
    // MARK: - Body
    
    var body: some View {
        HStack {
            // Skeleton user avatar (left side)
            SkeletonCircle(size: 32)
            
            Spacer()
            
            // Skeleton title
            SkeletonRectangle(width: 100, height: 20)
            
            Spacer()
            
            // Skeleton action button (right side)
            SkeletonCircle(size: 32)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        SkeletonNavigationBar()
        Spacer()
    }
    .background(Color(.systemBackground))
}
