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

    /// Display name for showing initials when no photo is available
    var displayName: String?
    
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
                await loadImage(userID: userID)
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
        .onChange(of: userID) { oldValue, newValue in
            // If userID changes from nil to a value, trigger image loading
            if oldValue == nil, let newUserID = newValue {
                Task {
                    await loadImage(userID: newUserID)
                }
            }
        }
    }
    
    // MARK: - Placeholder View

    private var placeholderView: some View {
        ZStack {
            Circle()
                .fill(initialsBackgroundColor)
                .frame(width: size, height: size)

            if let displayName = displayName, !displayName.isEmpty {
                // Show initials
                Text(getInitials(from: displayName))
                    .font(.system(size: size * 0.4, weight: .medium))
                    .foregroundColor(initialsForegroundColor)
            } else {
                // Fallback to person icon if no display name
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.6, height: size * 0.6)
                    .foregroundColor(Color(.systemGray3))
            }
        }
    }

    // MARK: - Color Helpers

    /// Background color for initials based on display name hash
    private var initialsBackgroundColor: Color {
        guard let displayName = displayName, !displayName.isEmpty else {
            return Color(.systemGray5)
        }

        // Generate consistent color based on display name
        let colors: [Color] = [
            Color(red: 0.4, green: 0.8, blue: 0.6), // Green (like in screenshot)
            Color(red: 0.4, green: 0.6, blue: 1.0), // Blue
            Color(red: 1.0, green: 0.6, blue: 0.4), // Orange
            Color(red: 0.8, green: 0.4, blue: 0.8), // Purple
            Color(red: 1.0, green: 0.8, blue: 0.4), // Yellow
            Color(red: 0.6, green: 0.8, blue: 1.0)  // Light blue
        ]

        let hash = abs(displayName.hashValue)
        return colors[hash % colors.count]
    }

    /// Foreground color for initials
    private var initialsForegroundColor: Color {
        guard displayName != nil else {
            return Color(.systemGray3)
        }
        return .white
    }

    /// Extract initials from display name (first letter)
    private func getInitials(from name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return "?" }
        return String(trimmed.prefix(1).uppercased())
    }
    
    // MARK: - Helper Methods
    
    /// Loads image from cache or network via UserService
    /// - Parameter userID: User ID to load cached image for
    private func loadImage(userID: String) async {
        isLoadingImage = true
        
        // Use UserService to load image (handles cache + network)
        do {
            let image = try await UserService.shared.loadProfilePhoto(userID: userID)
            cachedImage = image
        } catch {
            // Handle error silently - will show placeholder
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

