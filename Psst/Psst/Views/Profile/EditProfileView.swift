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
    
    /// Error from photo picker (validation errors)
    @State private var pickerError: ProfilePhotoError? = nil
    
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
                        // Photo Preview (with cache support)
                        ProfilePhotoPreview(
                            imageURL: user.photoURL,
                            userID: user.id,
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }
                
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
                ProfilePhotoPicker(selectedImage: $selectedImage, error: $pickerError)
            }
            .onChange(of: pickerError) { oldValue, newValue in
                // Show error alert if picker error occurs
                if let error = newValue {
                    errorMessage = error.localizedDescription
                    showError = true
                }
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
    /// All image processing happens on background threads via UserService
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
            if let selectedImage = selectedImage {
                print("[EditProfileView] Uploading profile photo...")
                
                // Convert image to data on background thread (handled in UserService)
                // No compression here - UserService handles all image processing on background threads
                guard let imageData = selectedImage.pngData() else {
                    throw ProfilePhotoError.invalidImageData
                }
                
                // Upload (UserService will validate, compress on background thread, and upload)
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
            
        } catch let error as ProfilePhotoError {
            // Handle specific profile photo errors with user-friendly messages
            print("[EditProfileView] ❌ Profile photo error: \(error.localizedDescription ?? "unknown")")
            
            errorMessage = error.localizedDescription
            
            // Add recovery suggestion if available
            if let suggestion = error.recoverySuggestion {
                errorMessage = (errorMessage ?? "") + "\n\n" + suggestion
            }
            
            showError = true
            
        } catch {
            // Handle other errors
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

