//
//  ProfileView.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #4
//  Updated by Caleb (Coder Agent) - PR #17 (Profile editing)
//

import SwiftUI

/// User profile view displaying profile information with edit functionality
struct ProfileView: View {
    // MARK: - Environment
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // MARK: - State
    
    /// Show edit profile sheet
    @State private var showEditProfile = false
    
    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Top spacing
                    Spacer()
                        .frame(height: 20)
                    
                    // Profile Photo
                    if let user = authViewModel.currentUser {
                        ProfilePhotoPreview(
                            imageURL: user.photoURL,
                            selectedImage: nil,
                            isLoading: false,
                            size: 140
                        )
                        .padding(.top, 32)
                        
                        // Display Name
                        Text(user.displayName)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        // Email
                        Text(user.email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // Edit Profile Button
                        Button(action: {
                            showEditProfile = true
                        }) {
                            HStack {
                                Image(systemName: "pencil")
                                Text("Edit Profile")
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        
                        // Account Info Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Account Information")
                                .font(.headline)
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
            .sheet(isPresented: $showEditProfile) {
                if let user = authViewModel.currentUser {
                    EditProfileView(user: user)
                }
            }
        }
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
