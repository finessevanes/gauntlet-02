//
//  PhotoSourcePicker.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #1
//  Action sheet for selecting photo source (camera, library, or delete)
//

import SwiftUI
import UIKit
import AVFoundation
import Photos

/// Action sheet picker for choosing photo source (camera or library) or deleting photo
/// Handles camera and photo library permissions with clear error messaging
struct PhotoSourcePicker: View {
    // MARK: - Properties
    
    /// Whether a photo currently exists (determines if delete option is shown)
    var hasPhoto: Bool
    
    /// Callback when camera is selected
    var onCameraSelected: () -> Void
    
    /// Callback when library is selected
    var onLibrarySelected: () -> Void
    
    /// Callback when delete is selected
    var onDeleteSelected: () -> Void
    
    /// Binding to control visibility of action sheet
    @Binding var isPresented: Bool
    
    // MARK: - State
    
    /// Show permission error alert
    @State private var showPermissionError = false
    
    /// Permission error message
    @State private var permissionErrorMessage = ""
    
    // MARK: - Body
    
    var body: some View {
        VStack {
            // This is just a placeholder - actual action sheet shown via .confirmationDialog
        }
        .confirmationDialog(
            "Choose Photo Source",
            isPresented: $isPresented,
            titleVisibility: .visible
        ) {
            // Camera option
            Button("Take Photo") {
                handleCameraSelection()
            }
            
            // Library option
            Button("Choose from Library") {
                handleLibrarySelection()
            }
            
            // Delete option (only if photo exists)
            if hasPhoto {
                Button("Delete Photo", role: .destructive) {
                    onDeleteSelected()
                }
            }
            
            // Cancel button
            Button("Cancel", role: .cancel) {
                isPresented = false
            }
        }
        .alert("Permission Required", isPresented: $showPermissionError) {
            Button("Cancel", role: .cancel) {
                showPermissionError = false
            }
            
            Button("Open Settings") {
                openSettings()
            }
        } message: {
            Text(permissionErrorMessage)
        }
    }
    
    // MARK: - Methods
    
    /// Handles camera selection with permission checking
    private func handleCameraSelection() {
        // Check if camera is available
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            permissionErrorMessage = "Camera is not available on this device. Please use the photo library instead."
            showPermissionError = true
            return
        }
        
        // Check camera permission
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch authStatus {
        case .authorized:
            // Permission already granted
            isPresented = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                onCameraSelected()
            }
            
        case .notDetermined:
            // Request permission
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.isPresented = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            onCameraSelected()
                        }
                    } else {
                        permissionErrorMessage = "Camera access is required to take photos. Please enable camera access in Settings → Psst → Camera."
                        showPermissionError = true
                    }
                }
            }
            
        case .denied, .restricted:
            // Permission denied or restricted
            permissionErrorMessage = "Camera access is denied. Please enable camera access in Settings → Psst → Camera to take photos."
            showPermissionError = true
            
        @unknown default:
            permissionErrorMessage = "Unknown camera permission status."
            showPermissionError = true
        }
    }
    
    /// Handles library selection with permission checking
    private func handleLibrarySelection() {
        // Check photo library permission
        let authStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        switch authStatus {
        case .authorized, .limited:
            // Permission already granted (limited access is fine for selecting photos)
            isPresented = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                onLibrarySelected()
            }
            
        case .notDetermined:
            // Request permission
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                DispatchQueue.main.async {
                    if status == .authorized || status == .limited {
                        self.isPresented = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            onLibrarySelected()
                        }
                    } else {
                        permissionErrorMessage = "Photo library access is required to select photos. Please enable photo library access in Settings → Psst → Photos."
                        showPermissionError = true
                    }
                }
            }
            
        case .denied, .restricted:
            // Permission denied or restricted
            permissionErrorMessage = "Photo library access is denied. Please enable photo library access in Settings → Psst → Photos to select photos."
            showPermissionError = true
            
        @unknown default:
            permissionErrorMessage = "Unknown photo library permission status."
            showPermissionError = true
        }
    }
    
    /// Opens app settings
    private func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL)
        }
    }
}

// MARK: - Preview

#Preview {
    PhotoSourcePicker(
        hasPhoto: true,
        onCameraSelected: { print("Camera selected") },
        onLibrarySelected: { print("Library selected") },
        onDeleteSelected: { print("Delete selected") },
        isPresented: .constant(true)
    )
}
