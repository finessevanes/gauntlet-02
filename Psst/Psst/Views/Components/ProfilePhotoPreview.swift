//
//  ProfilePhotoPreview.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #17
//  Profile photo preview component with loading states
//

import SwiftUI

/// Displays profile photo preview with support for local and remote images
/// Handles loading states and placeholder display
struct ProfilePhotoPreview: View {
    // MARK: - Properties
    
    /// Remote image URL from Firebase Storage
    var imageURL: String?
    
    /// Local image selected by user (not yet uploaded)
    var selectedImage: UIImage?
    
    /// Whether image is currently uploading
    var isLoading: Bool = false
    
    /// Size of the circular preview
    var size: CGFloat = 120
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            if isLoading {
                // Loading state - show spinner
                ZStack {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: size, height: size)
                    
                    ProgressView()
                        .scaleEffect(1.5)
                }
            } else if let selectedImage = selectedImage {
                // Local image selected (not yet uploaded)
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else if let imageURL = imageURL, !imageURL.isEmpty {
                // Remote image from Firebase Storage
                AsyncImage(url: URL(string: imageURL)) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            Circle()
                                .fill(Color(.systemGray5))
                                .frame(width: size, height: size)
                            
                            ProgressView()
                        }
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                    case .failure:
                        placeholderView
                    @unknown default:
                        placeholderView
                    }
                }
            } else {
                // No image - show placeholder
                placeholderView
            }
        }
        .overlay(
            Circle()
                .stroke(Color(.systemGray4), lineWidth: 2)
        )
    }
    
    // MARK: - Placeholder View
    
    private var placeholderView: some View {
        ZStack {
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: size, height: size)
            
            Image(systemName: "person.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: size * 0.6, height: size * 0.6)
                .foregroundColor(Color(.systemGray3))
        }
    }
}

// MARK: - Preview

#Preview("No Image") {
    ProfilePhotoPreview(imageURL: nil, selectedImage: nil)
}

#Preview("Loading") {
    ProfilePhotoPreview(imageURL: nil, selectedImage: nil, isLoading: true)
}

#Preview("With URL") {
    ProfilePhotoPreview(imageURL: "https://via.placeholder.com/150")
}

