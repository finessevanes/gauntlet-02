//
//  CameraPicker.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #1
//  UIImagePickerController wrapper for camera capture
//

import SwiftUI
import UIKit

/// UIImagePickerController wrapper for capturing photos with device camera
/// Handles camera capture and returns selected image to SwiftUI
struct CameraPicker: UIViewControllerRepresentable {
    // MARK: - Properties
    
    /// Binding to store the captured image
    @Binding var selectedImage: UIImage?
    
    /// Binding to store any error that occurs
    @Binding var error: ProfilePhotoError?
    
    /// Environment dismiss action
    @Environment(\.dismiss) var dismiss
    
    // MARK: - UIViewControllerRepresentable
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        picker.modalPresentationStyle = .fullScreen
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    // MARK: - Coordinator
    
    /// Coordinator to handle UIImagePickerControllerDelegate callbacks
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        
        init(_ parent: CameraPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            // Dismiss picker
            picker.dismiss(animated: true)
            
            // Get the captured image
            guard let image = info[.originalImage] as? UIImage else {
                Log.e("CameraPicker", "Failed to get captured image")
                
                DispatchQueue.main.async {
                    self.parent.error = ProfilePhotoError.invalidImageData
                }
                return
            }
            
            Log.i("CameraPicker", "Image captured successfully")
            
            // Update parent binding on main thread
            DispatchQueue.main.async {
                self.parent.selectedImage = image
                self.parent.error = nil
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            // User canceled - just dismiss
            Log.i("CameraPicker", "User canceled camera capture")
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Default Binding Extension

extension CameraPicker {
    /// Convenience initializer for backward compatibility (no error binding)
    init(selectedImage: Binding<UIImage?>) {
        self._selectedImage = selectedImage
        self._error = .constant(nil)
    }
}

