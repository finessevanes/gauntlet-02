//
//  EditProfileView.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #17
//  Profile editing screen with display name and photo upload
//

import SwiftUI
import PhotosUI

/// Profile editing view for updating display name and profile photo
/// Validates inputs, uploads photos to Firebase Storage, and updates Firestore
struct EditProfileView: View {
    // MARK: - Environment
    
    @Environment(\.dismiss) var dismiss
    
    // MARK: - State
    
    /// Current display name being edited
    @State private var displayName: String = ""
    
    /// Selected image from photo picker (not yet uploaded)
    @State private var selectedImage: UIImage? = nil
    
    /// Show photo picker sheet
    @State private var showPhotoPicker = false
    
    /// Loading state for initial data load
    @State private var isLoading = false
    
    /// Saving state during profile update
    @State private var isSaving = false
    
    /// Error message to display
    @State private var errorMessage: String? = nil
    
    /// Show error alert
    @State private var showError = false
    
    // MARK: - Properties
    
    /// User being edited
    var user: User
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            Form {
                // Profile Photo Section
                Section {
                    VStack(spacing: 16) {
                        // Photo Preview
                        ProfilePhotoPreview(
                            imageURL: user.photoURL,
                            selectedImage: selectedImage,
                            isLoading: isSaving && selectedImage != nil,
                            size: 120
                        )
                        .frame(maxWidth: .infinity, alignment: .center)
                        
                        // Change Photo Button
                        Button(action: {
                            showPhotoPicker = true
                        }) {
                            HStack {
                                Image(systemName: "photo")
                                Text("Change Photo")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(isSaving)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Profile Photo")
                }
                
                // Display Name Section
                Section {
                    TextField("Display Name", text: $displayName)
                        .textContentType(.name)
                        .autocapitalization(.words)
                        .disabled(isSaving)
                    
                    // Character counter
                    HStack {
                        Spacer()
                        Text("\(displayName.count)/50")
                            .font(.caption)
                            .foregroundColor(displayNameColor)
                    }
                    
                    // Validation error
                    if let validationError = displayNameValidationError {
                        Text(validationError)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                } header: {
                    Text("Display Name")
                } footer: {
                    Text("Your display name must be 2-50 characters")
                        .font(.caption)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveProfile()
                        }
                    }
                    .disabled(!canSave)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showPhotoPicker) {
                ProfilePhotoPicker(selectedImage: $selectedImage)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {
                    showError = false
                }
            } message: {
                Text(errorMessage ?? "An error occurred")
            }
            .onAppear {
                // Load current user data
                displayName = user.displayName
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// Whether the save button should be enabled
    private var canSave: Bool {
        return hasChanges && !isSaving && displayNameValidationError == nil
    }
    
    /// Whether there are unsaved changes
    private var hasChanges: Bool {
        return displayName != user.displayName || selectedImage != nil
    }
    
    /// Color for character counter (red if invalid, gray if valid)
    private var displayNameColor: Color {
        if displayName.count < 2 || displayName.count > 50 {
            return .red
        }
        return .secondary
    }
    
    /// Validation error message for display name
    private var displayNameValidationError: String? {
        if displayName.isEmpty {
            return "Display name cannot be empty"
        }
        if displayName.count < 2 {
            return "Display name must be at least 2 characters"
        }
        if displayName.count > 50 {
            return "Display name cannot exceed 50 characters"
        }
        return nil
    }
    
    // MARK: - Methods
    
    /// Saves profile changes to Firebase
    @MainActor
    private func saveProfile() async {
        // Set saving state
        isSaving = true
        defer { isSaving = false }
        
        // Validate display name
        guard displayNameValidationError == nil else {
            errorMessage = displayNameValidationError
            showError = true
            return
        }
        
        do {
            var photoURL: String? = nil
            
            // Upload photo if selected
            if let selectedImage = selectedImage,
               let imageData = selectedImage.jpegData(compressionQuality: 0.8) {
                print("[EditProfileView] Uploading profile photo...")
                photoURL = try await UserService.shared.uploadProfilePhoto(
                    uid: user.id,
                    imageData: imageData
                )
                print("[EditProfileView] ✅ Photo uploaded: \(photoURL ?? "nil")")
            }
            
            // Update profile
            let updatedDisplayName = displayName != user.displayName ? displayName : nil
            
            print("[EditProfileView] Updating profile...")
            try await UserService.shared.updateUserProfile(
                uid: user.id,
                displayName: updatedDisplayName,
                profilePhotoURL: photoURL
            )
            print("[EditProfileView] ✅ Profile updated successfully")
            
            // Dismiss view
            dismiss()
            
        } catch {
            print("[EditProfileView] ❌ Failed to save profile: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Preview

#Preview {
    EditProfileView(
        user: User(
            id: "preview-user",
            email: "user@example.com",
            displayName: "John Doe",
            photoURL: nil
        )
    )
}

