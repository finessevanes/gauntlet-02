//
//  ProfilePhotoPreview.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #17
//  Updated by Caleb (Coder Agent) - PR #1 (Cache support)
//  Profile photo preview component with loading states and caching
//

import SwiftUI

/// Displays profile photo preview with support for local and remote images
/// Handles loading states, placeholder display, and cache-aware loading
struct ProfilePhotoPreview: View {
    // MARK: - Properties
    
    /// Remote image URL from Firebase Storage
    var imageURL: String?
    
    /// User ID for cache lookup (optional, enables caching)
    var userID: String?
    
    /// Local image selected by user (not yet uploaded)
    var selectedImage: UIImage?
    
    /// Whether image is currently uploading
    var isLoading: Bool = false
    
    /// Size of the circular preview
    var size: CGFloat = 120
    
    /// If true, force showing placeholder and clear any cached/remote image
    var forcePlaceholder: Bool = false
    
    // MARK: - State
    
    /// Cached image loaded from ImageCacheService
    @State private var cachedImage: UIImage?
    
    /// Loading state for cache/network fetch
    @State private var isLoadingImage = false
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            if forcePlaceholder {
                // Explicitly show placeholder (used for staged delete)
                placeholderView
            } else if isLoading {
                // Loading state - show spinner
                ZStack {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: size, height: size)
                    
                    ProgressView()
                        .scaleEffect(1.5)
                }
            } else if let selectedImage = selectedImage {
                // Local image selected (not yet uploaded) - highest priority
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .id(ObjectIdentifier(selectedImage))
            } else if let cachedImage = cachedImage {
                // Cached image - loads instantly
                Image(uiImage: cachedImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else if let imageURL = imageURL, !imageURL.isEmpty {
                // Remote image from Firebase Storage (fallback if no cache)
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
                            .onAppear {
                                // Cache the downloaded image if we have a userID
                                // Note: We cannot reliably extract UIImage from AsyncImage here; rely on cache via UserService paths.
                            }
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
        .task {
            // Load from cache on appear if userID is provided and not forced placeholder
            if !forcePlaceholder, let userID = userID, selectedImage == nil {
                await loadFromCache(userID: userID)
            }
        }
        .onChange(of: forcePlaceholder) { _, newValue in
            // Clear cached image when forcing placeholder to avoid stale display
            if newValue {
                cachedImage = nil
            }
        }
        .onChange(of: imageURL) { oldValue, newValue in
            // If URL changes or becomes nil, clear cached image to avoid mismatch
            if oldValue != newValue {
                cachedImage = nil
            }
        }
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
    
    // MARK: - Helper Methods
    
    /// Loads image from cache
    /// - Parameter userID: User ID to load cached image for
    private func loadFromCache(userID: String) async {
        isLoadingImage = true
        
        // Check cache first
        if let cached = await ImageCacheService.shared.getCachedProfilePhoto(userID: userID) {
            cachedImage = cached
        }
        
        isLoadingImage = false
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

