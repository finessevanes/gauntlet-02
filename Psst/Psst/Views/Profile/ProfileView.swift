//
//  ProfileView.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #4
//  Placeholder for user profile (to be implemented in Phase 3)
//

import SwiftUI

/// Placeholder view for user profile
/// Will display user information and allow profile editing in Phase 3
struct ProfileView: View {
    // MARK: - Body

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()

                // Feature icon
                Image(systemName: "person.fill")
                    .font(.system(size: 72))
                    .foregroundColor(.purple)

                // Title
                Text("Profile")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                // Coming soon message
                Text("Coming Soon in Phase 3")
                    .font(.title3)
                    .foregroundColor(.secondary)

                // Description
                Text("This screen will display your profile information and allow you to edit your display name and profile picture.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()
            }
            .navigationTitle("Profile")
        }
    }
}

// MARK: - Preview

#Preview {
    ProfileView()
}
