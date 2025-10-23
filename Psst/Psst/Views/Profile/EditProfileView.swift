//
//  EditProfileView.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #17
//  Profile editing screen with display name and photo upload
//

import SwiftUI
import PhotosUI
import FirebaseFirestore
import FirebaseStorage

/// Profile editing view for updating display name and profile photo
/// Validates inputs, uploads photos to Firebase Storage, and updates Firestore
struct EditProfileView: View {
    // MARK: - Environment
    
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    
    // MARK: - State
    
    /// Current display name being edited
    @State private var displayName: String = ""
    
    /// Selected image from photo picker (not yet uploaded)
    @State private var selectedImage: UIImage? = nil
    
    /// Bumps to force ProfilePhotoPreview to reset its internal cache state
    @State private var previewVersion: Int = 0
    
    /// URL produced by pre-upload; staged until Save commits
    @State private var pendingPhotoURL: String? = nil
    
    /// True while pre-upload is in progress
    @State private var isUploading = false
    
    /// If true, commit profile update once upload completes (Save tapped during upload)
    @State private var commitAfterUpload = false
    
    /// If true, user requested delete (staged until Save)
    @State private var pendingDeletion = false
    
    /// Existing photo URL to delete in background after Save
    @State private var oldPhotoURL: String? = nil
    
    /// Show photo source picker (camera/library/delete)
    @State private var showPhotoSourcePicker = false
    
    /// Show photo library picker
    @State private var showPhotoPicker = false
    
    /// Show camera picker
    @State private var showCameraPicker = false
    
    /// Show delete confirmation dialog
    @State private var showDeleteConfirmation = false
    
    /// Loading state for initial data load
    @State private var isLoading = false
    
    /// Saving state during profile update
    @State private var isSaving = false
    
    /// Deleting state during photo deletion
    @State private var isDeleting = false
    
    /// Error from photo picker (validation errors)
    @State private var pickerError: ProfilePhotoError? = nil
    
    /// Error message to display
    @State private var errorMessage: String? = nil
    
    /// Show error alert
    @State private var showError = false
    
    /// If true, auto-save will run when network reconnects
    @State private var pendingAutoSave = false
    
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
                        // Photo Preview with Delete Button Overlay
                        ZStack(alignment: .topTrailing) {
                            ProfilePhotoPreview(
                                imageURL: pendingDeletion ? nil : user.photoURL,
                                userID: user.id,
                                selectedImage: selectedImage,
                                isLoading: false,
                                size: 120,
                                forcePlaceholder: pendingDeletion
                            )
                            
                            // Delete Button (only show if photo exists)
                            if user.photoURL != nil && !user.photoURL!.isEmpty && selectedImage == nil && !pendingDeletion {
                                Button(action: {
                                    showDeleteConfirmation = true
                                }) {
                                    Image(systemName: "trash.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                        .frame(width: 32, height: 32)
                                        .background(Color.red)
                                        .clipShape(Circle())
                                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                                }
                                .offset(x: 8, y: -8)
                                .disabled(isSaving || isDeleting)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        
                        // Change Photo Button (or Add Photo if no photo exists)
                        Button(action: {
                            showPhotoSourcePicker = true
                        }) {
                            HStack {
                                Image(systemName: user.photoURL == nil ? "photo.badge.plus" : "photo")
                                Text(user.photoURL == nil ? "Add Photo" : "Change Photo")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(isSaving || isDeleting)
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
                    .disabled(!canSave || !networkMonitor.isConnected)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showPhotoPicker) {
                ProfilePhotoPicker(selectedImage: $selectedImage, error: $pickerError)
            }
            .sheet(isPresented: $showCameraPicker) {
                CameraPicker(selectedImage: $selectedImage, error: $pickerError)
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
            .confirmationDialog(
                "Are you sure you want to remove your profile photo?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Photo", role: .destructive) {
                    // Stage deletion; do not hit the network yet
                    Log.i("EditProfileView", "Stage delete tapped")
                    pendingDeletion = true
                    oldPhotoURL = user.photoURL
                    selectedImage = nil
                    pendingPhotoURL = nil
                    previewVersion += 1
                    Task {
                        await ImageCacheService.shared.invalidateProfilePhotoCache(userID: user.id)
                    }
                }
                
                Button("Cancel", role: .cancel) {
                    showDeleteConfirmation = false
                }
            }
            .overlay {
                // Photo Source Picker (camera/library only - delete is on avatar)
                PhotoSourcePicker(
                    hasPhoto: false, // Don't show delete option - we have dedicated button
                    onCameraSelected: {
                        showCameraPicker = true
                    },
                    onLibrarySelected: {
                        showPhotoPicker = true
                    },
                    onDeleteSelected: {
                        // Not used - delete button is on avatar
                    },
                    isPresented: $showPhotoSourcePicker
                )
                .frame(width: 0, height: 0) // Hidden - only shows action sheet
            }
            .safeAreaInset(edge: .top) {
                NetworkStatusBanner(
                    networkMonitor: networkMonitor,
                    queueCount: .constant(0)
                )
            }
            .onAppear {
                // Load current user data
                displayName = user.displayName
            }
            .onChange(of: selectedImage) { _, newImage in
                // Pre-upload selected image for instant Save later
                guard let image = newImage else { return }
                Log.i("EditProfileView", "Pre-upload start")
                // If user previously staged a deletion, selecting a new image cancels it
                pendingDeletion = false
                isUploading = true
                pendingPhotoURL = nil
                // Queue auto-save if changes made while offline
                if !networkMonitor.isConnected { pendingAutoSave = true }
                
                // Convert to data; allow HEIC/PNG by using PNG as source then compress in service
                guard let imageData = image.pngData() else {
                    Log.e("EditProfileView", "Invalid image data during pre-upload")
                    pickerError = .invalidImageData
                    isUploading = false
                    return
                }
                
                Task.detached { [userID = user.id, weakNetwork = networkMonitor.isConnected] in
                    do {
                        let url = try await UserService.shared.uploadProfilePhoto(uid: userID, imageData: imageData)
                        await ImageCacheService.shared.cacheProfilePhoto(image, userID: userID)
                        await MainActor.run {
                            Log.i("EditProfileView", "Pre-upload complete url set")
                            pendingPhotoURL = url
                            isUploading = false
                        }
                        // If Save was tapped during upload, commit now
                        if let commit = await CommitCoordinator.shared.getPending(for: userID) {
                            await MainActor.run {
                                Log.i("EditProfileView", "Commit-after-upload trigger")
                            }
                            do {
                                try await UserService.shared.updateUserProfile(
                                    uid: userID,
                                    displayName: commit.updatedDisplayName,
                                    profilePhotoURL: url
                                )
                                // Best-effort old blob deletion if we were replacing or staged a delete
                                if commit.pendingDeletion, let old = commit.oldPhotoURL, !old.isEmpty {
                                    await backgroundDeleteBlob(byURL: old)
                                }
                            } catch {
                                Log.e("EditProfileView", "Commit-after-upload failed: \(error.localizedDescription)")
                            }
                            await CommitCoordinator.shared.clear(for: userID)
                        }
                    } catch let error as ProfilePhotoError {
                        await MainActor.run {
                            Log.e("EditProfileView", "Pre-upload failed: \(error.localizedDescription)")
                            pickerError = error
                            isUploading = false
                        }
                    } catch {
                        await MainActor.run {
                            Log.e("EditProfileView", "Pre-upload failed: \(error.localizedDescription)")
                            errorMessage = error.localizedDescription
                            showError = true
                            isUploading = false
                        }
                    }
                }
            }
            .onChange(of: displayName) { oldValue, newValue in
                if newValue != user.displayName && !networkMonitor.isConnected {
                    pendingAutoSave = true
                }
            }
            .onChange(of: networkMonitor.isConnected) { wasConnected, isConnected in
                // When network comes back, auto-save pending changes
                if isConnected && pendingAutoSave && hasChanges && !isSaving {
                    Task {
                        await saveProfile()
                        pendingAutoSave = false
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// Whether the save button should be enabled
    private var canSave: Bool {
        let displayNameChanged = displayName != user.displayName
        let photoChanged = selectedImage != nil || pendingPhotoURL != nil || pendingDeletion
        // Only require name validation if the name actually changed
        if displayNameChanged && displayNameValidationError != nil { return false }
        return (displayNameChanged || photoChanged) && !isSaving
    }
    
    /// Whether there are unsaved changes
    private var hasChanges: Bool {
        return displayName != user.displayName || selectedImage != nil || pendingPhotoURL != nil || pendingDeletion
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
        Log.i("EditProfileView", "Save tapped")
        // Set saving state (but keep Save responsive by minimizing work here)
        isSaving = true
        defer { isSaving = false }
        
        // Validate display name
        guard displayNameValidationError == nil else {
            errorMessage = displayNameValidationError
            showError = true
            return
        }
        
        let updatedDisplayName = displayName != user.displayName ? displayName : nil
        
        do {
            // Branching per staged state
            if let url = pendingPhotoURL {
                Log.i("EditProfileView", "Save path: pendingPhotoURL commit")
                try await UserService.shared.updateUserProfile(
                    uid: user.id,
                    displayName: updatedDisplayName,
                    profilePhotoURL: url
                )
                if pendingDeletion, let old = oldPhotoURL, !old.isEmpty {
                    Log.i("EditProfileView", "Background delete old blob after replace")
                    await backgroundDeleteBlob(byURL: old)
                }
                resetStagedState()
                dismiss()
                return
            }
            
            if isUploading {
                Log.i("EditProfileView", "Save path: commit-later (upload in-flight)")
                commitAfterUpload = true
                let commit = PendingCommit(
                    updatedDisplayName: updatedDisplayName,
                    pendingDeletion: pendingDeletion,
                    oldPhotoURL: oldPhotoURL
                )
                await CommitCoordinator.shared.setPending(commit, for: user.id)
                dismiss()
                return
            }
            
            if pendingDeletion && pendingPhotoURL == nil {
                Log.i("EditProfileView", "Save path: deletion only")
                var data: [String: Any] = [
                    "updatedAt": FieldValue.serverTimestamp(),
                    "photoURL": FieldValue.delete()
                ]
                if let name = updatedDisplayName { data["displayName"] = name }
                try await UserService.shared.updateUser(id: user.id, data: data)
                if let old = oldPhotoURL, !old.isEmpty {
                    Log.i("EditProfileView", "Background delete old blob (deletion)")
                    await backgroundDeleteBlob(byURL: old)
                }
                resetStagedState()
                dismiss()
                return
            }
            
            if selectedImage != nil {
                // Fallback: should rarely happen since we pre-upload on selection
                Log.i("EditProfileView", "Save path: fallback upload now")
                if let image = selectedImage, let data = image.pngData() {
                    let url = try await UserService.shared.uploadProfilePhoto(uid: user.id, imageData: data)
                    await ImageCacheService.shared.cacheProfilePhoto(image, userID: user.id)
                    try await UserService.shared.updateUserProfile(
                        uid: user.id,
                        displayName: updatedDisplayName,
                        profilePhotoURL: url
                    )
                    if pendingDeletion, let old = oldPhotoURL, !old.isEmpty {
                        await backgroundDeleteBlob(byURL: old)
                    }
                }
                resetStagedState()
                dismiss()
                return
            }
            
            // Name only
            if updatedDisplayName != nil {
                Log.i("EditProfileView", "Save path: name only")
                try await UserService.shared.updateUserProfile(
                    uid: user.id,
                    displayName: updatedDisplayName,
                    profilePhotoURL: nil
                )
            }
            resetStagedState()
            dismiss()
        } catch let error as ProfilePhotoError {
            Log.e("EditProfileView", "Save failed (photo): \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            if let suggestion = error.recoverySuggestion {
                errorMessage = (errorMessage ?? "") + "\n\n" + suggestion
            }
            showError = true
        } catch {
            Log.e("EditProfileView", "Save failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    /// Best-effort background deletion of a Storage blob by its download URL
    private func backgroundDeleteBlob(byURL urlString: String) async {
        Log.i("EditProfileView", "Background deletion start")
        do {
            let storage = Storage.storage()
            let ref = storage.reference(forURL: urlString)
            try await ref.delete()
            Log.i("EditProfileView", "Background deletion complete")
        } catch {
            Log.e("EditProfileView", "Background deletion failed: \(error.localizedDescription)")
        }
    }
    
    /// Resets staged state flags after commit
    @MainActor
    private func resetStagedState() {
        pendingPhotoURL = nil
        commitAfterUpload = false
        pendingDeletion = false
        oldPhotoURL = nil
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

// MARK: - Commit Coordinator (commit-after-upload)

fileprivate struct PendingCommit {
    let updatedDisplayName: String?
    let pendingDeletion: Bool
    let oldPhotoURL: String?
}

fileprivate actor CommitCoordinator {
    static let shared = CommitCoordinator()
    private var pending: [String: PendingCommit] = [:]
    
    func setPending(_ commit: PendingCommit, for userID: String) {
        pending[userID] = commit
    }
    
    func getPending(for userID: String) -> PendingCommit? {
        return pending[userID]
    }
    
    func clear(for userID: String) {
        pending[userID] = nil
    }
}

