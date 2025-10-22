//
//  ProfilePhotoError.swift
//  Psst
//
//  Created by Caleb (Coder Agent) - PR #1
//  Specific error types for profile photo operations
//

import Foundation

/// Specific errors that can occur during profile photo operations
/// Provides user-friendly error messages and troubleshooting guidance
enum ProfilePhotoError: Error, LocalizedError, Equatable {
    case networkUnavailable
    case imageTooLarge(sizeInMB: Double, maxSizeInMB: Double)
    case invalidFormat(format: String)
    case uploadFailed(reason: String)
    case compressionFailed
    case permissionDenied
    case cacheError(String)
    case invalidImageData
    
    /// User-friendly error description
    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "No internet connection. Please check your connection and try again."
            
        case .imageTooLarge(let sizeInMB, let maxSizeInMB):
            return "Image couldn't be compressed enough. Original size: \(String(format: "%.1f", sizeInMB))MB, but even after compression it exceeds \(String(format: "%.1f", maxSizeInMB))MB. Please select a smaller image."
            
        case .invalidFormat(let format):
            return "Image format '\(format)' is not supported. Please use JPEG, PNG, or HEIC format."
            
        case .uploadFailed(let reason):
            return "Failed to upload photo: \(reason). Please try again."
            
        case .compressionFailed:
            return "Failed to compress image. The image may be corrupted or in an unsupported format."
            
        case .permissionDenied:
            return "Permission denied. Please make sure you're logged in and try again. If the problem persists, try logging out and back in."
            
        case .cacheError(let message):
            return "Cache error: \(message)"
            
        case .invalidImageData:
            return "Invalid image data. Please select a different image."
        }
    }
    
    /// Troubleshooting guidance for the user
    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Connect to Wi-Fi or cellular data and try again."
            
        case .imageTooLarge:
            return "Try taking a new photo with your camera or selecting a smaller image from your library."
            
        case .invalidFormat:
            return "Supported formats: JPEG (.jpg), PNG (.png), HEIC (.heic)"
            
        case .uploadFailed:
            return "Check your internet connection and try again."
            
        case .compressionFailed:
            return "Try selecting a different image."
            
        case .permissionDenied:
            return "Log out and log back in, then try again. If the issue persists, contact support."
            
        case .cacheError:
            return "The photo should still be saved. Try refreshing the app."
            
        case .invalidImageData:
            return "Try taking a new photo or selecting a different one from your library."
        }
    }
}

