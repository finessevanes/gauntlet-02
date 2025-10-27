//
//  ProfileView.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #4
//  Updated by Caleb (Coder Agent) - PR #17 (Profile editing)
//  Updated by Caleb (Coder Agent) - PR #006D (Profile UI polish)
//

import SwiftUI

/// User profile view displaying profile information with edit functionality
struct ProfileView: View {
    // MARK: - Environment

    @EnvironmentObject var authViewModel: AuthViewModel

    /// Dismiss action for when presented as sheet
    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    /// Show edit profile sheet
    @State private var showEditProfile = false

    /// Refresh trigger for profile photo (increments to force refresh)
    @State private var photoRefreshTrigger = 0

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Top spacing
                    Spacer()
                        .frame(height: 20)

                    // User Info Card
                    if let user = authViewModel.currentUser {
                        VStack(spacing: 16) {
                            // Profile Photo
                            ProfilePhotoPreview(
                                imageURL: user.photoURL,
                                userID: user.id,
                                selectedImage: nil,
                                isLoading: false,
                                size: 80,
                                displayName: user.displayName
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color(.quaternaryLabel), lineWidth: 1)
                            )
                            .id("\(user.id)-\(user.photoURL ?? "no-photo")-\(photoRefreshTrigger)")

                            // User Info
                            VStack(spacing: 4) {
                                // Display Name
                                Text(user.displayName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color(.label))

                                // Email
                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                // Role Badge
                                HStack(spacing: 4) {
                                    Image(systemName: user.role == .trainer ? "person.fill.checkmark" : "figure.walk")
                                        .font(.caption2)

                                    Text(user.role == .trainer ? "Trainer" : "Client")
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(user.role == .trainer ? Color.blue.opacity(0.15) : Color.green.opacity(0.15))
                                .foregroundColor(user.role == .trainer ? .blue : .green)
                                .cornerRadius(12)
                                .padding(.top, 4)
                            }
                        }
                        .padding(.vertical, 24)
                        .frame(maxWidth: .infinity)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(16)
                        .padding(.horizontal, 20)

                        // Edit Profile Button
                        Button(action: {
                            showEditProfile = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 16))
                                Text("Edit Profile")
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal, 24)
                        
                        // Account Info Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Account Information")
                                .font(.headline)
                                .foregroundColor(Color(.label))
                                .padding(.horizontal, 24)
                            
                            VStack(spacing: 0) {
                                ProfileInfoRow(
                                    icon: "person.fill",
                                    label: "User ID",
                                    value: String(user.id.prefix(8)) + "..."
                                )
                                
                                Divider()
                                    .padding(.leading, 56)
                                
                                ProfileInfoRow(
                                    icon: "calendar",
                                    label: "Member Since",
                                    value: user.createdAt.formatted(date: .abbreviated, time: .omitted)
                                )
                            }
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .padding(.horizontal, 24)
                        }
                        .padding(.top, 32)
                    } else {
                        // No user logged in (shouldn't happen)
                        VStack {
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 72))
                                .foregroundColor(.gray)
                            
                            Text("No user logged in")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 100)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                        }
                    }
                }
            }
            .sheet(isPresented: $showEditProfile, onDismiss: {
                // Refresh user data when EditProfileView dismisses
                Task {
                    await refreshUserData()
                }
            }) {
                if let user = authViewModel.currentUser {
                    EditProfileView(user: user)
                }
            }
        }
    }
    
    // MARK: - Methods
    
    /// Refreshes profile photo display after edit
    /// The AuthenticationService's Firestore listener will update the user data automatically
    /// This just forces the ProfilePhotoPreview to recreate and reload from cache
    @MainActor
    private func refreshUserData() async {
        // We rely on pre-caching after upload; avoid invalidating cache here to prevent flicker
        // Small delay to allow Firestore listener to update user model
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        // Nudge view to refresh
        photoRefreshTrigger += 1
        Log.i("ProfileView", "Profile photo refresh triggered (no cache invalidation)")
    }
}

// MARK: - Supporting Views

/// Row displaying profile information
struct ProfileInfoRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.body)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Preview

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
}

