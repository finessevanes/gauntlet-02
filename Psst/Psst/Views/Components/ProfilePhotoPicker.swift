//
//  ProfilePhotoPicker.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #17
//  Updated by Caleb (Coder Agent) - PR #1 (Error handling)
//  Photo picker component for selecting profile photos from device library
//

import SwiftUI
import PhotosUI

/// UIKit-based photo picker for selecting profile photos
/// Wraps PHPickerViewController for use in SwiftUI with error handling
struct ProfilePhotoPicker: UIViewControllerRepresentable {
    // MARK: - Properties
    
    /// Binding to store the selected image
    @Binding var selectedImage: UIImage?
    
    /// Binding to store any error that occurs during image loading
    @Binding var error: ProfilePhotoError?
    
    /// Environment dismiss action
    @Environment(\.dismiss) var dismiss
    
    // MARK: - UIViewControllerRepresentable
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        // Configure picker to only show images
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        
        // Create picker
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    // MARK: - Coordinator
    
    /// Coordinator to handle PHPickerViewController delegate callbacks
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ProfilePhotoPicker
        
        init(_ parent: ProfilePhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            // Dismiss picker
            picker.dismiss(animated: true)
            
            // Get first result (we only allow single selection)
            guard let result = results.first else {
                print("[ProfilePhotoPicker] No image selected")
                return
            }
            
            // Load image from result on background thread
            if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                    // Handle loading errors
                    if let error = error {
                        print("[ProfilePhotoPicker] ❌ Failed to load image: \(error.localizedDescription)")
                        
                        // Update error binding on main thread
                        DispatchQueue.main.async {
                            self?.parent.error = ProfilePhotoError.invalidImageData
                        }
                        return
                    }
                    
                    // Validate that we got a UIImage
                    guard let uiImage = image as? UIImage else {
                        print("[ProfilePhotoPicker] ❌ Invalid image type")
                        
                        DispatchQueue.main.async {
                            self?.parent.error = ProfilePhotoError.invalidImageData
                        }
                        return
                    }
                    
                    // Success - image loaded
                    // Note: We don't validate size here because compression will handle it
                    // Only format validation happens during upload
                    print("[ProfilePhotoPicker] ✅ Image loaded successfully")
                    
                    DispatchQueue.main.async {
                        self?.parent.selectedImage = uiImage
                        self?.parent.error = nil
                        print("[ProfilePhotoPicker] ✅ Image selected successfully")
                    }
                }
            }
        }
    }
}

// MARK: - Default Binding Extension

extension ProfilePhotoPicker {
    /// Convenience initializer for backward compatibility (no error binding)
    init(selectedImage: Binding<UIImage?>) {
        self._selectedImage = selectedImage
        self._error = .constant(nil)
    }
}

